# installation prefix
if [ -n "$1" ]
then
	prefix="$1"
else
	prefix=$HOME/local/
fi
exec_dir=$prefix/bin/
doc_dir=$prefix/share/

# Construct the single file executable
ruby make_jedi.rb

# Copy files
mkdir -p $exec_dir
cp jedi.rb ${exec_dir}/jedi
chmod a+x ${exec_dir}/jedi
mkdir -p ${doc_dir}/man/man1
mkdir -p ${doc_dir}/doc/jedi
cp doc/jedi.1 ${doc_dir}/man/man1/jedi.1

