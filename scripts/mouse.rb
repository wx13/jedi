# mouse.rb
#
# Extention to editor.rb which adds basic mouse support.
# Run editor.rb with "-s mouse.rb" to include it.
# Or to make it permanent, insert the contents of this file into exitor.rb
# anywhere after the keymap initialization ($keymap = KeyMap.new) and
# before the screen initialization ($screen = Screen.new).
#
# Copyright (C) 2012, Jason P. DeVita (jason@wx13.com)
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty or restriction. This file
# is offered as-is, without any warrenty.
#

class Screen

	# Allow public access to mouse position on the screen.
	attr_accessor :mouse_x, :mouse_y

	# Define the mouse keycodes.
	alias :old_init :initialize
	def initialize
		old_init
		@keycodes["\e[M32"] = :left_click
		@keycodes["\e[M33"] = :middle_click
	end

	# Redefind getch to look for mouse keycodes.
	alias :old_getch :getch
	def getch
		c = STDIN.getc.chr
		if c=="\e"
			2.times{c += STDIN.getc.chr}
		end

		# This is the only difference from the non-mouse getch.
		if c[2,1] == "M"
			c += STDIN.getc.to_s
			@mouse_x = STDIN.getc - 33
			@mouse_y = STDIN.getc - 33
		end

		if c == "\e[5" || c == "\e[6"
			c += STDIN.getc.chr
		end
		if c=="\e[1"
			c += STDIN.getc.chr
			c = "\e["
			2.times{c += STDIN.getc.chr}
		end
		if c == "\e" || c == "\e\e" || c == "\e\e\e" || c == "\e\e\e\e"
			return nil
		end
		d = @keycodes[c]
		d = c if d == nil
		return(d)
	end

	# Print magic codes to make terminal pass mouse information
	# to the editor.
	alias :old_start_screen :start_screen_loop
	def start_screen_loop
		system('stty raw -echo')
		print "\e[#{@rows}S"  # roll screen up (clear, but preserve)
		print "\e[?7l"  # disable line wrap
		toggle_mouse($mouse)
		begin
			yield
		ensure
			print "\e[2J"   # clear the screen
			print "\e[?7h"  # enable line wrap
			toggle_mouse(false)  # disable mouse
			system('stty -raw echo')
		end
	end

	# Allow the user to toggle mouse support on/off.
	def toggle_mouse(x=!$mouse)
		$mouse = x
		if $mouse
			print "\e[?9h"
		else
			print "\e[?9l"
		end
	end

end

class FileBuffer
	# Convert screen row/col to buffer row/col.
	def src2brc(sr,sc)
		@row = sr - @window.pos_row - 1 + @linefeed
		@col = sc2bc(@row,sc-@window.pos_col) + @colfeed
	end
end


class BuffersList

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

end

# Define actions for mouse clicks.
$keymap.commandlist[:left_click] = "$buffers.mouse_select"
$keymap.commandlist[:middle_click] = "$buffers.mouse_mark"

# Define toggle keys for turning mouse support on/off.
$keymap.togglelist["M"] = "$screen.toggle_mouse(true)"
$keymap.togglelist["m"] = "$screen.toggle_mouse(false)"

# Turn on mouse support by default.
$mouse = true

