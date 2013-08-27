#---------------------------------------------------------------------
# Window class
#
# This is a virtual window that fits inside of the screen.
# Each buffer has a window that it writes to, and each
# window keeps track of its position and size.
#---------------------------------------------------------------------

class Window

	# width, height, and position of the window
	attr_accessor :rows, :cols, :pos_row, :pos_col

	# Create a new window.
	# Optional dimensions are: upper left row, col; num rows, num cols.
	def initialize(screen,dimensions=[0,0,0,0])
		@screen = screen
		@pos_row = dimensions[0]
		@pos_col = dimensions[1]
		@rows = dimensions[2]
		@cols = dimensions[3]
		# if size is unset, set it to screen size minus 1 (top bar)
		@rows = @screen.rows - 1 if @rows <= 0
		@cols = @screen.cols if @cols <= 0
	end

	# These all translate window position to screen position,
	# and then pass off to screen class methods
	def write_info_line(l,c,r)
		@screen.write_info_line(l,c,r,@pos_row,@pos_col,@cols)
	end
	def write_line(row,colfeed,line)
		@screen.write_line(row+1+@pos_row,@pos_col,@cols,colfeed,line)
	end
	def write_string(row,col,str)
		@screen.write_string(@pos_row+row,@pos_col+col,str)
	end
	def write_string_colored(row,col,str,color)
		@screen.write_string_colored(@pos_row+row,@pos_col+col,str,color)
	end
	def setpos(r,c)
		@screen.setpos(r+@pos_row,c+@pos_col)
	end

	# Set the window size, where k is the number of windows
	# and j is the number of this window.
	def set_window_size(j,k,vh=:v)
		if vh == :v
			@pos_row = j*((@screen.rows+1)/k)
			@rows = (@screen.rows+1)/k - 1
			@pos_col = 0
			@cols = @screen.cols
		else
			@pos_row = 0
			@rows = @screen.rows - 1
			@pos_col = j*((@screen.cols+1)/k)
			@cols = (@screen.cols+1)/k - 1
		end
	end

	# Set the size of the last window to fit to the remainder of
	# the screen.
	def set_last_window_size(vh=:v)
		if vh == :v
			@rows = @screen.rows - @pos_row - 1
			@cols = @screen.cols
		else
			@cols = @screen.cols - @pos_col
			@rows = @screen.rows - 1
		end
	end



	# pass-through to screen class
	def method_missing(method,*args,&block)
		@screen.send method, *args, &block
	end

end

# end of Window class
#---------------------------------------------------------------------
