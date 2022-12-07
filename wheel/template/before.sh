# This script (`before.sh.erb`) is sourced directly into the main Bash script
# that is run when the batch job starts up. It is called before the `script.sh`
# is forked off into a separate process.
#
# There are some helpful Bash functions that are made available to this script
# that encapsulate commonly used routines when initializing a web server:
#
#   - find_port
#       Find available port in range [$1..$2]
#       Default: 2000 65535
#
# We **MUST** supply the following environment variables in this
# `before.sh.erb` script so that a user can connect back to the web server when
# it is running (case-sensitive variable names):
#
#   - $host (already defined earlier, so no need to define again)
#       The host that the web server is listening on
#
#   - $port
#       The port that the web server is listening on


# Export the module function if it exists
[[ $(type -t module) == "function" ]] && export -f module

# Find available port to run server on
port=$(find_port)

# prepare config directory
config_dir=${HOME}/.wheel
mkdir ${config_dir} 2>/dev/null
cd ${config_dir}

#download server.json and jobScheduler.json from github
wget -nc https://raw.githubusercontent.com/RIKEN-RCCS/OPEN-WHEEL/master/server/app/config/server.json
wget -nc https://raw.githubusercontent.com/RIKEN-RCCS/OPEN-WHEEL/master/server/app/config/jobScheduler.json

######################
# When /home directory is nfs-mounted with lookupcache=none option,
# the error "/usr/bin/env: bad interpreter: Text file busy" occurs.
# This is because that the script.sh is not finished being copied in a compute node.
# To prevent that, change to a file with a different name in the compute node.
######################
cp script.sh tmp.sh
mv tmp.sh script.sh

#rewrite port
sed -i -e "/port/c \"port\": ${port}," server.json
echo port number is changed to ${port}
grep port server.json
