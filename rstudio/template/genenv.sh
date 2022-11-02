#!/bin/bash

# Get R Home Etc Folder
spath="$(Rscript -e 'R.home(component = "etc")' | grep -o '".*"' | sed 's/"//g')"

# Get Renviron File
efile="$(find "$spath" -type f -name 'Renviron*' | head -n1)"

if [ -n "$efile" ]; then
	# Copy Environment File
	cp "$efile" ./Renviron.site

	# Store Path To Site Environment File
	echo "$efile" > ./Renviron.path
else
	# Create Environment File
	touch ./Renviron.site

	# Guess Path To Site Environment File
	echo "$spath/Renviron" > ./Renviron.path
fi

# Add Singularity, Slurm, end Cuda ENV Vars
printenv | grep -E '^SLURM|^SINGULARITY|^APPTAINER|^CUDA' | sed "s/=\([^' >][^ >]*\)/='\1'/g" >> ./Renviron.site
printenv | grep -E '^PJM|^FJ|^OMPI|^PLE|^XOS'             | sed "s/=\([^' >][^ >]*\)/='\1'/g" >> ./Renviron.site

# Add Timezone
if [ -z "$TZ" ]; then
 export TZ="Asia/Tokyo"
fi
echo "TZ='$TZ'" >> ./Renviron.site
