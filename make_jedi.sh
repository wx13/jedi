#!/bin/bash

for file in src/*.rb
do
	if [ "$file" == "src/jedi.rb" ]
	then
		continue
	fi
	cat $file
	echo -e "\n\n\n\n\n\n\n\n\n\n\n"
done

cat <<-EOF

	#---------------------------------------------------------------------
	# Run the editor
	#---------------------------------------------------------------------
	\$version = '0.4.1'
	\$editor = Editor.new
	\$editor.go

EOF
