#---------------------------------------------------------------------
# FileAccessor class
#
# This class is called on by the FileBuffer class to handle
# interactions with the file: reading, writing, etc.
#---------------------------------------------------------------------

class FileAccessor

	attr_accessor :name, :indentchar, :indentstring, :bufferindentstring,
	:bufferindentchar, :mask

	def initialize(filename)
		@name = filename
		@eol = "\n"
		@indentchar = nil
		@indentstring = nil
		@bufferindentstring = nil
		@mask = {}
	end


	# Determine the primary indentation string of the file.
	def update_indentation(text)
		a = text.flatten.map{|line|
			if line[0] != nil
				line[0].chr
			end
		}
		numtabs = a.count("\t")
		numspaces = a.count(" ")
		if numtabs < (numspaces-4)
			@indentchar = " "
		elsif numtabs > (numspaces+4)
			@indentchar = "\t"
		else
			@indentchar = nil
		end
	end


	# Read file into an array.
	def read

		return([""]) if @name=="" || !File.exists?(@name) || File.directory?(@name)

		begin
			text = File.open(@name,"rb:UTF-8"){|f| f.read}
		rescue
			text = File.open(@name,"r"){|f| f.read}
		end

		# get rid of crlf
		temp = text.gsub!(/\r\n/,"\n")
		if temp == nil
			@eol = "\n"
		else
			@eol = "\r\n"
		end
		text.gsub!(/\r/,"\n")
		text = text.split("\n",-1)
		text = [""] if text.empty?
		update_indentation(text)

		if @indentstring != @bufferindentstring
			textb = TextBuffer.new(text)
			textb.swap_indent_string(@indentstring,@bufferindentstring)
			text = textb
		end

		unless @mask.empty?
			textb = TextBuffer.new(text)
			textb.gsub!(@mask)
			text = textb
		end

		return(text)

	end

	# Save buffer to a file.
	def save(textb)

		text = TextBuffer.new(textb.deep_copy)
		if @bufferindentstring != @indentstring
			text.swap_indent_string(@bufferindentstring,@indentstring)
		else
			update_indentation(text)
		end

		text.gsub!(@mask.invert)

		# Dump the text to the file.
		begin
			text = text.join(@eol)
			begin
				File.open(@name,"w:UTF-8"){|file|
					file.write(text)
				}
			rescue
				File.open(@name,"w"){|file|
					file.write(text)
				}
			end
		rescue
			return $!
		end

	end


end

# end of FileAccessor class
#---------------------------------------------------------------------
