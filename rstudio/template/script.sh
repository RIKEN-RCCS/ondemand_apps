#!/usr/bin/env bash
# https://gitlab.com/nmsu_hpc/ood_bc_rstudio

# Benchmark info
echo "TIMING - Starting main script at: $(date)"

ARCH=`arch`
if [ $ARCH = aarch64 ]; then
  IMAGE=/home/apps/singularity/ondemand/rstudio_ubi86_${ARCH}.sif
else
  IMAGE=/home/apps/singularity/ondemand/rstudio_ubi84_${ARCH}.sif
fi

export PATH=$PATH:/usr/lib/rstudio-server/bin
export SINGULARITYENV_PATH=$PATH
export SINGULARITYENV_LD_LIBRARY_PATH=$LD_LIBRARY_PATH
export SINGULARITYENV_XDG_DATA_HOME=${HOME}/ondemand/rstudio/`arch`
export TMPDIR=${SINGULARITYENV_XDG_DATA_HOME}/tmp
export SINGULARITYENV_TMPDIR=${TMPDIR}
export SINGULARITYENV_XDG_RUNTIME_DIR=${TMPDIR}
export SINGULARITYENV_MODULEPATH=$MODULEPATH

python3 -c 'from uuid import uuid4; print(uuid4())' > "${PWD}/secure-cookie-key"
chmod 0600 "$PWD/secure-cookie-key"

# Create Config File
cat <<-EOF >./rserver.conf
	www-port=${port}
	auth-none=0
	auth-pam-helper-path=${PWD}/bin/auth
	auth-encrypt-password=0
        server-data-dir=${TMPDIR}/rstudio-server
        secure-cookie-key-file=${PWD}/secure-cookie-key
        server-user=${USER}
	auth-timeout-minutes=0
	server-app-armor-enabled=0
EOF

# Create Session Config File
cat <<-EOF >./rsession.conf
	session-timeout-minutes=0
	session-save-action-default=no
EOF

# Create Log Config File (debug, info, warn, error)
mkdir -p $PWD/sessions
cat <<-EOF >./logging.conf
	[*]
	log-level=info
	logger-type=file
	log-dir=$PWD/sessions
EOF

# Create RStudio Writable Directories and Helper Files
mkdir -p "$TMPDIR/lib"
mkdir -p "$TMPDIR/run"

singularity exec --bind="$TMPDIR:/tmp" $IMAGE bash ./genenv.sh

renv_path="$(cat ./Renviron.path)"
echo MODULEPATH="$MODULEPATH" >> ./Renviron.site

# Setup Bind Mounts
NV_OPTION=""
CUDA_VERSION=11.5
if [ -e /usr/local/cuda-$CUDA_VERSION ]; then
  SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,/usr/local/cuda-$CUDA_VERSION:/usr/local/cuda
  NV_OPTION="--nv"
fi
for i in `ls -l /opt | grep ^d | awk '{print $9}'`; do
  SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,/opt/$i
done
for i in /vol0001 /vol0003 /vol0004 /vol0005 /vol0006 /lib64/liblustreapi.so /run/psv; do
    [ -e $i ] && SINGULARITY_BINDPATH=$SINGULARITY_BINDPATH,$i
done

export SINGULARITY_BINDPATH=${SINGULARITY_BINDPATH},${TMPDIR}:/tmp,${TMPDIR}/lib:/var/lib/rstudio-server,${TMPDIR}/run:/var/run/rstudio-server,logging.conf:/etc/rstudio/logging.conf,rsession.conf:/etc/rstudio/rsession.conf,rserver.conf:/etc/rstudio/rserver.conf,Renviron.site:$renv_path,/data,/work,/sys,/var/opt,/usr/share/Modules,/etc/profile.d/zFJSVlangload.sh

# Launch the RStudio Server
echo "TIMING - Starting RStudio Server at: $(date)"
singularity run $NV_OPTION $IMAGE rserver

echo 'Singularity as exited...'
