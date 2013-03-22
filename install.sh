# This script does the following:
#   1. copy jedi.rb to the specified executable directory.
#   2. create the specified startup script directory.
#   3. create a one-line shell script which tells jedi.rb where
#      to find the config files and where to place the history file.

# User configuration
# Set the executable and config directories,
# and set the executable name (you can call the editor
# anything you want).
exec_dir=$HOME/local/bin/
exec_name=jedi
config_dir=$HOME/.jedi

# Construct single file
bash make_jedi.sh > jedi.rb

# Copy files
mkdir -p $exec_dir
cp jedi.rb ${exec_dir}/
mkdir -p ${config_dir}

# Create the one-line shell script
sh="$(which sh)"
cat <<-EOF > ${exec_dir}/${exec_name}
	#!${sh}
	ruby ${exec_dir}/jedi.rb -s ${config_dir}/ -y ${config_dir}/history.yaml \$@
EOF
chmod a+x ${exec_dir}/${exec_name}

