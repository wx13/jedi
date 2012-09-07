# Implement IDE-like functionality, where the user can send lines of code
# to a named pipe.
class FileBuffer

	def set_ide
		ans = @window.ask("fifo file:")
		return if ans == nil || ans == ""
		@fifofilename = ans
		@fifofile = File.open(@fifofilename,"w")
	end

	def end_ide
		@fifofile.close unless @fifofile == nil || @fifofile.closed?
	end

	def ide_all
		ide(true)
	end

	def ide_linebyline
		ide(false)
	end

	def ide(all)
		if @fifofile == nil
			set_ide
			return if @fifofile == nil
		end
		if @marked
			if @cursormode == 'multi'
				text = []
				@mark_list.each{|r,c|
					text << @text[r]
				}
			else
				srow,erow = ordered_mark_rows
				text = @text[srow..erow]
			end
		else
			srow = erow = @row
			text = @text[srow..erow]
		end
		if all
			@fifofile.puts text.join(',')
			@fifofile.puts ''
			@fifofile.flush
		else
			text.each{|line|
				@fifofile.puts line
				@fifofile.puts ''
				@fifofile.flush
			}
		end
		@marked = false
		@row = erow + 1
	end

end


$keymap.extramode_commandlist["E"] = "buffer.ide_linebyline"
$keymap.extramode_commandlist["e"] = "buffer.ide_all"
$keymap.extramode_commandlist[:ctrl_e] = "buffer.set_ide"
$keymap.extramode_commandlist[:ctrl_w] = "buffer.end_ide"
