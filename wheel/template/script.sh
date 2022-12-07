#!/usr/bin/env bash
set +x
SIF=/home/apps/singularity/ondemand/wheel_debian10.13_x86_64.sif

# Set working directory to home directory
cd "${HOME}"

# Benchmark info
echo "TIMING - Starting WHEEL at: $(date)"

# Launch the Server
echo "port in main script = ${port}"
export WHEEL_USE_HTTP=1
export WHEEL_BASE_URL="/node/${host}/${port}/"
export WHEEL_TEMPD="${HOME}/.wheel"

singularity run --pwd /usr/src/server ${SIF}
