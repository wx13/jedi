#---------------------------------------------------------------------
# Script to assemble Jedi from parts into a single file.
# Start by grabbing all required files from run_jedi.rb and dumping
# them into the file.  Then stick in the code that runs the editor.
#---------------------------------------------------------------------

File.open('jedi.rb','w'){|jedi_file|

	jedi_file.puts "#!/usr/bin/env ruby" + "\n"*2

	# Require all the files in 'src'.
	Dir[File.dirname(__FILE__) + '/src/*.rb'].each{|src_file|
		jedi_file.puts File.read(src_file)
		jedi_file.puts "\n"*10
	}

	jedi_file.puts <<-EOF

#---------------------------------------------------------------------
# Run the editor
#---------------------------------------------------------------------
\$version = '0.4.5'
\$editor = Editor.new
\$editor.go

	EOF

}

