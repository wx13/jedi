# Installation is not necessary.  You can just run the code as
# a single-file stand-alone program.  This script does the following:
#   1. copy editor.rb to the specified executable directory.
#   2. copy the config.rb file to the specifed config directory.
#   3. create a one-line shell script which tells editor.rb where
#      to find the config files and where to place the history file.

# User configuration
# Set the executable and config directories,
# and set the executable name (you can call the editor
# anything you want).
exec_dir=$HOME/bin/
exec_name=editor
config_dir=$HOME/.editor

# Copy files
mkdir -p $exec_dir
cp editor.rb ${exec_dir}/
mkdir -p ${config_dir}
cp scripts/config.rb ${config_dir}/

# Create the one-line shell script
sh="$(which sh)"
cat <<-EOF > ${exec_dir}/${exec_name}
	#!${sh}
	ruby ${exec_dir}/editor.rb -s ${config_dir}/ -y ${config_dir}/history.yaml
EOF
chmod a+x ${exec_dir}/${exec_name}

