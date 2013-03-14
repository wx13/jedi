#---------------------------------------------------------------------
# BufferList class
#
# This class manages a list of buffers (each buffer is a file).
# Each buffer resides on a page.  Each page can contain
# multiple buffers. Pages are handled by the page class, which
# is defined within this class.
#
# Methods include opening and closing buffers, toggling
# the view among pages, moving buffers between pages, etc.
#---------------------------------------------------------------------

class BuffersList

	attr_accessor :npage, :ipage

	# This subclass contains a set of buffers that reside
	# on a single page.
	class Page
		attr_accessor :buffers, :nbuf, :ibuf, :stack_orientation
		def initialize(buffers=[])
			@buffers = buffers
			@nbuf = @buffers.length
			@ibuf = 0
			@stack_orientation = "v"
			resize_buffers
		end
		def delete_buffer(n=@ibuf)
			@buffers.delete_at(n)
			@nbuf = @buffers.length
			if @ibuf >= @nbuf
				@ibuf = 0
			end
		end
		def add_buffer(buffer)
			@buffers += [buffer]
			@nbuf = @buffers.length
			@ibuf = @nbuf - 1
			resize_buffers
		end
		def buffer
			@buffers[@ibuf]
		end
		def next_buffer
			@ibuf = (@ibuf+1).modulo(@nbuf)
			@buffers[@ibuf]
		end
		def prev_buffer
			@ibuf = (@ibuf-1).modulo(@nbuf)
			@buffers[@ibuf]
		end
		def resize_buffers
			j = 0;
			@buffers.each{|buf|
				buf.window.set_window_size(j,@nbuf,@stack_orientation)
				j += 1
			}
			buf = @buffers[@nbuf-1]
			buf.window.set_last_window_size(@stack_orientation)
		end
		def refresh_buffers
			if @stack_orientation == "v"
				@buffers.each{|buf|
					buf.dump_to_screen(true)
					buf.update_top_line(nil,nil,true)
				}
			else
				@buffers.each_index{|i|
					if i > 0
						$screen.draw_vertical_line(i,@nbuf)
					end
					@buffers[i].dump_to_screen(true)
				}
			end
		end
		def vstack
			@stack_orientation = "v"
			resize_buffers
			refresh_buffers
		end
		def hstack
			@stack_orientation = "h"
			resize_buffers
			refresh_buffers
		end
	end

	# Read in all input files into buffers.
	# One buffer for each file.
	def initialize(files)

		@pages = []  # big list of buffers (stored per page)
		@npage = 0   # number of pages
		@ipage = 0   # current page number

		# For each file on the command line, put text on its own page
		for filename in files
			next if File.directory?(filename)
			@pages[@npage] = Page.new([FileBuffer.new(filename)])
			@npage += 1
		end
		# If no pages exist, then open a blank file.
		if @npage == 0
			@pages[@npage] = Page.new([FileBuffer.new("")])
			@npage += 1
		end
		@ipage = 0  # Start on the first buffer.

	end

	def update_screen_size
		@pages[@ipage].resize_buffers
		@pages[@ipage].refresh_buffers
	end

	def suspend
		$screen.suspend
		update_screen_size
	end

	# Return next, previous, or current buffer.
	def next_page
		@ipage = (@ipage+1).modulo(@npage)
		@pages[@ipage].refresh_buffers
		@pages[@ipage].buffer
	end
	def prev_page
		@ipage = (@ipage-1).modulo(@npage)
		@pages[@ipage].refresh_buffers
		@pages[@ipage].buffer
	end
	def next_buffer
		@pages[@ipage].refresh_buffers
		@pages[@ipage].next_buffer
	end
	def prev_buffer
		@pages[@ipage].refresh_buffers
		@pages[@ipage].prev_buffer
	end
	def current
		@pages[@ipage].buffer
	end

	def vstack
		@pages[@ipage].vstack
	end
	def hstack
		@pages[@ipage].hstack
	end


	# Close the current buffer.
	def close

		buf = @pages[@ipage].buffer  # current buffer

		# If modified, ask about saving to file.
		if buf.modified?
			ys = $screen.ask_yesno("Save changes?")
			if ys == "yes"
				buf.save
			elsif ys == "cancel"
				$screen.write_message("Cancelled")
				return(buf)
			end
		end

		# Delete the current buffer from the current page.
		@pages[@ipage].delete_buffer

		# If no buffers left on page, then remove the page.
		if @pages[@ipage].nbuf == 0
			@pages.delete_at(@ipage)
			@npage -= 1
			@ipage = 0
		end


		# Clear the message area.
		$screen.write_message("")

		# If no pages left, or if only buffer is nil,
		# then exit the editor.
		if @npage == 0 || @pages[0].buffer == nil
			$histories.save
			exit
		end

		@pages[@ipage].resize_buffers
		@pages[@ipage].refresh_buffers

		# Return the (new) current buffer.
		@pages[@ipage].buffer

	end


	# Open a new file into a new buffer.
	def open

		# Ask for the file to open.
		ans = $screen.ask("open file:",[""],:file=>true)
		if (ans==nil) || (ans == "")
			$screen.write_message("cancelled")
			return(@pages[@ipage].buffer)
		end

		# Create a new page at the end of the list.
		@pages[@npage] = Page.new([FileBuffer.new(ans)])
		@npage += 1
		@ipage = @npage-1

		# Report that the file has been opened,
		# and return the new file as the current buffer.
		$screen.write_message("Opened file: "+ans)
		return(@pages[@ipage].buffer)

	end


	# Create a new buffer which shares its text with the current buffer.
	# This way, we can edit the same file in two (or more) diffrent
	# views.
	def duplicate
		@pages[@npage] = Page.new([@pages[@ipage].buffer.dup])
		@pages[@npage].buffer.window = @pages[@npage].buffer.window.dup
		@npage += 1
		@pages[@ipage].buffer.extramode = false
		@ipage = @npage - 1
		@pages[@ipage].buffer.extramode = false
		return(@pages[@ipage].buffer)
	end


	# Put all the buffers on the same page;
	# unlesss they already are => then spread them out.
	def all_on_one_page
		if @npage == 1
			while @pages[0].nbuf > 1
				move_to_page(@npage+1,false)
			end
		else
			while @npage > 1
				@ipage = @npage - 1
				move_to_page(1,false)
			end
		end
		@pages[@ipage].refresh_buffers
		@ipage = 0
		@pages[@ipage].ibuf = 0
	end

	# Move current buffer to page n.
	def move_to_page(n,refresh=true)

		# Adjust for zero-based indexing.
		n -= 1

		# If same page, don't do anything.
		return if n == @ipage

		buf = @pages[@ipage].buffer

		# Delete the current buffer from current page.
		@pages[@ipage].delete_buffer

		# If no buffers left on page, then remove the page.
		if @pages[@ipage].nbuf == 0
			@pages.delete_at(@ipage)
			if n >= @ipage
				n -= 1
			end
			@npage -= 1
			@ipage = 0
		end

		# Put the buffer on the new page.
		if @npage > n
			@pages[n].add_buffer(buf)
		else
			@pages[@npage] = Page.new([buf])
			@npage += 1
		end

		# Refresh
		@pages[@ipage].resize_buffers
		@pages[@ipage].refresh_buffers if refresh

		return(@pages[@ipage].buffer)

	end

	# Shift all buffers on the screen up/down.
	def screen_up(n=1)
		@pages[@ipage].buffers.each{|buf|
			buf.screen_up(n)
		}
		@pages[@ipage].refresh_buffers
	end
	def screen_down(n=1)
		@pages[@ipage].buffers.each{|buf|
			buf.screen_down(n)
		}
		@pages[@ipage].refresh_buffers
	end

	# Use the mouse position to select a buffer.
	def mouse_select
		# find out the screen position
		sr = $screen.mouse_y
		sc = $screen.mouse_x
		# find window
		@pages[@ipage].buffers.each_index{|i|
			r0 = @pages[@ipage].buffers[i].window.pos_row
			c0 = @pages[@ipage].buffers[i].window.pos_col
			r1 = @pages[@ipage].buffers[i].window.rows + r0
			c1 = @pages[@ipage].buffers[i].window.cols + c0
			if sr.between?(r0,r1) && sc.between?(c0,c1)
				@pages[@ipage].ibuf = i
				break
			end
		}
		# find position in window
		buffer = current
		buffer.src2brc(sr,sc)
	end

	# Set marked text mark at current mouse position.
	def mouse_mark
		mouse_select
		buffer = current
		buffer.mark
	end

	def menu
		list = []
		ipage = 0
		@pages.each{|page|
			ibuf = 0
			page.buffers.each{|buffer|
				number = [ipage,ibuf].join('.')
				name = buffer.filename
				list << [number,name]
				ibuf += 1
			}
			ipage += 1
		}
		ans = $screen.menu(list,"buffers")
		ipage,ibuf = ans[0].split('.')
		@ipage = ipage.to_i
		@ibuf = ibuf.to_i
		buffer = @pages[@ipage].buffers[@ibuf]
		@pages[@ipage].refresh_buffers
	end

end

# end of BuffersList class
#---------------------------------------------------------------------











#---------------------------------------------------------------------
# CopyBuffer class
#
# Store up a history of copy/paste buffers.
#---------------------------------------------------------------------
class CopyBuffer
	attr_accessor :text
	def initialize
		@text = []
		@hist = []
	end
	def clear
		@hist.unshift @text.dup
		@hist.slice!(-50..-1)
		@hist.delete_if{|x|x.empty?}
		@hist.uniq!
		@text = []
	end
	def menu
		selection = @hist.dup
		selection.unshift @text.dup
		text = $screen.menu(selection,"CopyBuffer")
		$buffers.update_screen_size
		clear
		@text = text
		$buffers.current.paste
	end
end
# end of CopyBuffer class
#---------------------------------------------------------------------

