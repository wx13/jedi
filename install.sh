# This script does the following:
#   1. copy jedi.rb to the specified executable directory.
#   2. create the specified startup script directory.
#   3. create a one-line shell script which tells jedi.rb where
#      to find the config files and where to place the history file.

# Set the default installation prefix here.
prefix="$HOME/local/"

# Set the default config directory.
config_dir='$HOME/.jedi'

# Set the name of the excutable here.
exec_name=jedi

# First item on commandline overrides the default prefix.
if [ -n "$1" ]
then
	prefix="$1"
fi
exec_dir=$prefix/bin/
doc_dir=$prefix/share/

# Construct single file
ruby make_jedi.rb

# Copy files
mkdir -p $exec_dir
cp jedi.rb ${exec_dir}/
eval "mkdir -p ${config_dir}"
mkdir -p ${doc_dir}/man/man1
mkdir -p ${doc_dir}/doc/jedi
cp doc/manual.md ${doc_dir}/doc/jedi/manual.md
cp doc/jedi.1 ${doc_dir}/man/man1/jedi.1

# Create the one-line shell script
sh="$(which sh)"
cat <<-EOF > ${exec_dir}/${exec_name}
	#!${sh}
	ruby ${exec_dir}/jedi.rb -s ${config_dir}/ -y ${config_dir}/history.yaml \$@
EOF
chmod a+x ${exec_dir}/${exec_name}

