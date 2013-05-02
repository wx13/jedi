#---------------------------------------------------------------------
# Script to assemble Jedi from parts into a single file.
# Start by grabbing all required files from run_jedi.rb and dumping
# them into the file.  Then stick in the code that runs the editor.
#---------------------------------------------------------------------

File.open('jedi.rb','w'){|file|
	File.read('run_jedi.rb').split("\n").grep(/^require/).each{|line|
		line.strip!
		line.sub!(/^require '/,'')
		line.sub!(/'$/,'')
		file.puts File.read(line)
		file.puts "\n"*12
	}
	file.puts <<-EOF

#---------------------------------------------------------------------
# Run the editor
#---------------------------------------------------------------------
\$version = '0.4.2'
\$editor = Editor.new
\$editor.go

	EOF

}
