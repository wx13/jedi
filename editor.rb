#!/usr/bin/ruby
#
# editor.rb
#
# Copyright (C) 2011-2012, Jason P. DeVita (jason@wx13.com)
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty or restriction. This file
# is offered as-is, without any warranty.
#
$version = "0.1.0"




#---------------------------------------------------------------------
# Terminal class defines the API for interacting with the terminal.
# Everything terminal specific belongs in here.  In theory, to change
# from ANSI to curses to tk, would require only changing this class.
#---------------------------------------------------------------------
class Terminal

	attr_accessor :colors, :keycodes, :escape

	def initialize
		define_colors
		define_keycodes
		@escape = ["\e","m"]
	end

	def define_colors
		@colors = {
			:red   => "\e[31m",
			:green => "\e[32m",
			:blue => "\e[34m",
			:cyan => "\e[36m",
			:magenta => "\e[35m",
			:yellow => "\e[33m",
			:normal => "\e[0m",
			:reverse => "\e[7m",
			:underline => "\e[4m",
			:bold => "\e[1m"
		}
	end

	def define_keycodes
		@keycodes =
		{
			"\001" => :ctrl_a,
			"\002" => :ctrl_b,
			"\003" => :ctrl_c,
			"\004" => :ctrl_d,
			"\005" => :ctrl_e,
			"\006" => :ctrl_f,
			"\a"   => :ctrl_g,
			"\b"   => :ctrl_h,
			"\n"   => :ctrl_j,
			"\v"   => :ctrl_k,
			"\f"   => :ctrl_l,
			"\r"   => :ctrl_m,
			"\016" => :ctrl_n,
			"\017" => :ctrl_o,
			"\020" => :ctrl_p,
			"\021" => :ctrl_q,
			"\022" => :ctrl_r,
			"\023" => :ctrl_s,
			"\024" => :ctrl_t,
			"\025" => :ctrl_u,
			"\026" => :ctrl_v,
			"\027" => :ctrl_w,
			"\030" => :ctrl_x,
			"\031" => :ctrl_y,
			"\032" => :ctrl_z,
			"\036" => :ctrl_6,
			"\r"   => :enter,
			"\177" => :backspace,
			"\037" => :backspace2,
			"\t"   => :tab,

			"\e[A"  => :up,
			"\e[B"  => :down,
			"\e[C"  => :right,
			"\e[D"  => :left,
			"\e[6~" => :pagedown,
			"\e[5~" => :pageup,
			"\e[H"  => :home,
			"\eOH"  => :home2,
			"\e[F"  => :end,
			"\eOF"  => :end2,

			"\e[2D" => :shift_left,
			"\e[2C" => :shift_right,
			"\e[2A" => :shift_up,
			"\e[2B" => :shift_down,
			"\e[5D" => :ctrl_left,
			"\e[5C" => :ctrl_right,
			"\e[5A" => :ctrl_up,
			"\e[5B" => :ctrl_down,
			"\e[6D" => :ctrlshift_left,
			"\e[6C" => :ctrlshift_right,
			"\e[6A" => :ctrlshift_up,
			"\e[6B" => :ctrlshift_down,
		}
	end

	def set_cursor_color
		print "\e]12;#{color}\007"
	end

	# Read a character from stdin. Handle escape codes.
	#
	# Returns a symbol if the character is a key in the keycodes hash,
	# otherwise returns the raw string.
	def getch
		c = STDIN.getc.chr
		if c=="\e"
			2.times{c += STDIN.getc.chr}
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


	def get_screen_size
		@rows,@cols = `stty size`.split
		return @rows,@cols
	end


	def set_raw
		system('stty raw -echo')
	end
	def unset_raw
		system('stty -raw echo')
	end
	def roll_screen_up(r)
		print "\e[#{r}S"
	end
	def clear_screen
		print "\e[2J"
	end
	def disable_linewrap
		print "\e[?7l"
	end
	def enable_linewrap
		print "\e[?7h"
	end
	def cursor(r,c)
		print "\e[#{r};#{c}H"
	end

	def write(text)
		print text
	end

	def clear_line
		print "\e[2K"
	end

	def hide_cursor
		print "\e[?25l"
	end
	def show_cursor
		puts "\e[?25h"
	end
	def save_cursor
		print "\e[s"
	end
	def restore_cursor
		print "\e[u"
	end

end

# end of Terminal class
#---------------------------------------------------------------------






#---------------------------------------------------------------------
# The Screen class manages the screen output and input.
# It sits in between the Terminal and the Windows.  Each window knows
# only about itself (position, width, etc).  The screen knows nothing
# about the buffers or windows; it only knows how to write and read
# from the terminal.  The Terminal class is the API for the terminal,
# which could be ANSI, curses, ncurses, etc.
#---------------------------------------------------------------------

class Screen

	attr_accessor :rows, :cols, :buffer, :color

	def initialize

		@terminal = Terminal.new

		# get and store screen size
		update_screen_size

		# This is for detecting changes to the displayed text,
		# so we don't have to redraw as frequently.
		@buffer = []

		# Define screen-specific color codes.
		@color = define_colors

		# Set cursor color if desired.
		set_cursor_color($cursor_color) if $cursor_color != nil

	end


	def define_colors
		color = @terminal.colors
		$color.each{|k,v|
			color[k] = ""
			[v].flatten.each{|c|
				color[k] += color[c]
			}
		}
		return color
	end


	def set_cursor_color(color=nil)
		if color.nil?
			color = ask("color:")
		end
		return if color.nil? || color==""
		@terminal.set_cursor_color(color)
		write_message("set cursor to #{color}")
	end


	def getch
		return @terminal.getch
	end


	# Call to stty utility for screen size update, and set
	# @rows and @cols.
	#
	# Returns nothing.
	def update_screen_size
		cols_old = @cols
		rows_old = @rows
		@rows,@cols = @terminal.get_screen_size
		@rows = @rows.to_i-1
		@cols = @cols.to_i
		if cols_old!=@cols || rows_old!=@rows
			return true
		else
			return false
		end
	end

	# This starts the interactive session.
	# When this exits, return screen to normal.
	#
	# Returns nothing.
	def start_screen
		@terminal.set_raw
		@terminal.roll_screen_up(@rows)
		@terminal.disable_linewrap
		begin
			yield
		ensure
			@terminal.unset_raw
			@terminal.cursor(0,0)
			@terminal.enable_linewrap
			@terminal.clear_screen
		end
	end

	# Suspend the editor, and refresh on return.
	#
	# buffer - the current buffer, so we can refresh upon return.
	#
	# Returns nothing.
	def suspend(buffers)
		@terminal.clear_screen
		@terminal.cursor(0,0)
		@terminal.unset_raw
		@terminal.enable_linewrap
		Process.kill("SIGSTOP",0)
		@terminal.set_raw
		@terminal.roll_screen_up(@rows)
		@terminal.disable_linewrap
		update_screen_size
		buffers.update_screen_size
	end

	# Set cursor position.
	#
	# row - screen row (0 = first line)
	# col - screen column (0 = first column)
	#
	# Returns nothing.
	def setpos(row,col)
		@terminal.cursor(row+1,col+1)
	end

	# Write a string at the current cursor position.
	# This was more complex when using curses, but now is trivial.
	#
	# text - a string to be printed, including escape codes
	#
	# Returns nothing.
	def addstr(text)
		@terminal.write(text)
	end

	# Write a string at a specified position.
	#
	# row - screen row
	# cow - screen column
	# text - string to be printed
	#
	# Returns nothing.
	def write_string(row,col,text)
		setpos(row,col)
		addstr(text)
	end
	# Write a colored string at a specified position.
	#
	# row - screen row
	# col - screen column
	# text - string to be printed
	# color
	#
	# Returns nothing.
	def write_string_colored(row,col,text,color)
		setpos(row,col)
		addstr(@color[color]+text+@color[:normal])
	end

	# Clear an entrire line on the screen.
	#
	# row - screen row
	#
	# Returns nothing.
	def clear_line(row)
		setpos(row,0)
		@terminal.clear_line
	end
	def clear_message_text
		clear_line(@rows)
	end

	# Write to the bottom line (full with).
	# Typically used for asking the user a question.
	#
	# str - string of text to write
	#
	# Returns nothing.
	def write_bottom_line(str)
		write_string_colored(@rows,0," "*@cols,:message)
		write_string_colored(@rows,0,str,:message)
	end

	# Write an entire line of text to the screen.
	# Handle horizontal shifts (colfeed), escape chars, and tab chars.
	#
	# row - screen row
	# col - screen column to start writing at
	# width - how many columns of text to write
	# lin - the entire line of text (a substring of which will be printed)
	#
	# Returns nothing.
	def write_line(row,col,width,colfeed,line)

		# clear the line
		setpos(row,col)
		if width == @cols
			clear_line(row)
		else
			write_string(row,col," "*width)
		end

		# Don't bother unless there is something to write
		return if line == nil || line == ""

		# If screen is shifted, we must be careful to:
		#   - shift by whole number of characters
		#     (including multibyte escape codes)
		#   - apply chopped-off escape codes (color codes) to the line
		code = ""
		esc = @terminal.escape
		while colfeed > 0
			j = line.index(esc[0])
			break if j==nil
			if j > colfeed
				line = line[colfeed..-1]
				break
			end
			line = line[j..-1]
			colfeed -= j
			j = line.index(esc[1])
			code += line[0..j]
			line = line[j+1..-1]
		end
		print code
		words = line.split(esc[0])
		return if words.length == 0
		word = words[0]
		write_string(row,col,word[0,width])
		col += word.length
		width -= word.length
		flag = true
		flag = false if width <= 0
		return if words.length <= 1  # in case file contains control characters
		words[1..-1].each{|word|
			j = word.index(esc[1])
			next if j.nil?
			print esc[0] + word[0..j]
			write_string(row,col,word[j+1,width]) if flag
			col += word[j+1..-1].length
			width -= word[j+1..-1].length
			flag = false if width <= 0
		}

	end


	# Write the info line at top of screen (or elsewhere).
	#
	# lstr - left justifed text
	# rstr - right justified text
	# cstr - centered text
	# row - screen row
	# col - screen column
	#
	# Returns nothing.
	def write_info_line(lstr,cstr,rstr,row,col,width)

		rstr = cstr + "  " + rstr
		ll = lstr.length
		lr = rstr.length

		# if line is too long, chop off start of left string
		if (ll+lr+3) > width
			xxx = width - lr - 8
			return if xxx < 0
			lstr = "..." + lstr[(-xxx)..-1]
			ll = lstr.length
		end

		nspaces = width - ll - lr
		return if nspaces < 0  # line is too long to write
		all = lstr + (" "*nspaces) + rstr
		write_string_colored(row,col,all,:status)

	end


	# Write a message at the bottom (centered, partial line).
	#
	# message - text to write
	#
	# Returns nothing.
	def write_message(message)
		@terminal.save_cursor
		xpos = (@cols - message.length)/2
		clear_line(@rows)
		write_string_colored(@rows,xpos,message,:message)
		@terminal.restore_cursor
	end


	# Do a reverese incremental search through a history.
	# This is a helper function for asking the user for input.
	#
	# hist - array of previously entered text
	#
	# Returns integer index into hist array.
	def reverse_incremental(hist)

		token = ""  # user's search token
		mline = token  # line which matches token
		ih = hist.length - 1  # position within history list

		# interact with user
		loop do

			# write out current match status
			write_bottom_line("(reverse-i-search) #{token}: #{mline}")

			# get user input
			c = getch until c!=nil
			case c
				when :backspace, :backspace2
					# chop off a character, and search for a new match
					token.chop!
					ih = hist.rindex{|x|x.match(/#{token}/)}
					if ih != nil
						mline = hist[ih]
					end
				when :ctrl_r
					# get next match in reverse list
					if ih == 0
						next
					end
					ih = hist[0..(ih-1)].rindex{|x|x.match(/#{token}/)}
				when :ctrl_c, :ctrl_g
					# 0 return value = cancelled search
					return 0
				when :enter,:ctrl_m,:ctrl_j
					# non-zero return value is index of the match.
					# We've been searching backwards, so must invert index.
					if hist.length > 0
						return hist.length - ih
					else
						return 0
					end
				when :up, :down
					# up/down treated same as enter
					if hist.length > 0
						return hist.length - ih
					else
						return 0
					end
				else
					# regular character
					token += c if c.is_a?(String)
					ih = hist[0..ih].rindex{|x|x.match(/#{token}/)}
			end
			# ajust string for next loop
			if ih != nil
				mline = hist[ih]
			else
				ih = hist.length - 1
			end
		end
	end



	# Ask the user a question, and return the response.
	#
	# question    - text to print when asking
	# hist        - array of strings (past answers)
	# last_answer - true/false (start with last hist item as default answer?)
	# file        = true/false (should we do tab-completion on files?)
	#
	# Returns the users answer as a string.
	def ask(question,hist=[],last_answer=false,file=false)

		# if last_answer is set, then set the current token to the last answer.
		# Otherwise, set token to empty string
		if last_answer && hist.length > 0
			token = hist[-1].dup
		else
			token = ''
		end

		# history index
		ih = 0

		# remember typed string, even if we move away
		token0 = token.dup

		# put cursor at end of string
		# Write questin and suggested answer
		col = token.length
		write_bottom_line(question + " " + token)
		shift = 0  # shift: in case we go past edge of screen
		idx = 0  # for tabbing through files

		# for file globbing
		glob = token

		# interact with user
		loop do

			c = getch until c!=nil
			case c

				# abort
				when :ctrl_c then return(nil)

				# allow for empty strings
				when :ctrl_n then return("")

				# cursor up scrolls through history
				when :up
					if hist.length == 0
						token = ''
					else
						ih += 1
						if ih > hist.length
							ih = hist.length
						end
						token = hist[-ih].dup
					end
					glob = token
					col = token.length
				when :down
					if hist.length == 0
						token = ''
					else
						ih -= 1
						if ih < 0
							ih = 0
						end
						if ih == 0
							token = token0
						else
							token = hist[-ih].dup
						end
					end
					glob = token
					col = token.length
				when :ctrl_r
					ih = reverse_incremental(hist)
					if ih == nil then ih = 0 end
					if ih == 0
						token = token0
					else
						token = hist[-ih].dup
					end
					glob = token
					col = token.length
				when :left
					col -= 1
					if col<0 then col=0 end
					glob = token
				when :right
					col += 1
					if col>token.length then col = token.length end
					glob = token
				when :ctrl_e
					col = token.length
					glob = token
				when :ctrl_a
					col = 0
					glob = token
				when :ctrl_u
					# cut to start-of-line
					token = token[col..-1]
					glob = token
					col = 0
				when :ctrl_k
					# cut to end-of-line
					token = token[0,col]
					glob = token
				when :ctrl_d
					# delete character at cursor
					if col < token.length
						token[col] = ""
					end
					token0 = token.dup
					glob = token
				when :ctrl_m, :enter, :ctrl_j then break
				when :backspace, :backspace2, :ctrl_h
					if col > 0
						token[col-1] = ""
						col -= 1
					end
					token0 = token.dup
					glob = token
				when :tab
					if file
						# find files that match typed string
						# Cycle through matches.
						list = Dir.glob(glob+"*")
						if list.length == 0
							next
						end
						idx = idx.modulo(list.length)
						token = list[idx]
						col = token.length
						idx += 1
					else
						# not a file, so insert literal tab character
						token.insert(col,"\t")
						token0 = token.dup
						col += 1
						glob = token
					end
				else
					# regular character
					if c.is_a?(String)
						token.insert(col,c)
						token0 = token.dup
						col += 1
					end
					glob = token
			end

			# display the answer so far
			if (col+question.length+2) > @cols
				shift = col - @cols + question.length + 2
			else
				shift = 0
			end
			write_bottom_line(question+" "+token[shift..-1])
			setpos(@rows,(col-shift)+question.length+1)

		end
		if token == "" && hist[-1] != nil
			token = hist[-1].dup
		end
		if token != hist[-1]
			hist << token
		end
		return(token)
	end




	# Ask a yes or no question.
	#
	# question - question to ask (string)
	#
	# Returns "yes" or "no".
	def ask_yesno(question)
		write_bottom_line(question)
		answer = "cancel"
		loop do
			c = getch until c!=nil
			if c == :ctrl_c
				answer = "cancel"
				break
			end
			next if c.is_a?(String) == false
			if c.downcase == "y"
				answer = "yes"
				break
			end
			if c.downcase == "n"
				answer = "no"
				break
			end
		end
		return answer
	end


	# Draw a vertical line on the screen.
	#
	# i,n - i/n is fraction of the screen width,
	#       and gives the location of the line.
	#
	# Returns nothing.
	def draw_vertical_line(i,n)
		c = i*((@cols+1)/n) - 1
		for r in 0..(@rows-1)
			write_string(r,c,"|")
		end
	end



	# Allow the use to choose from a menu of choices.
	def menu(items,header)

		@terminal.hide_cursor

		# how many rows should the menu take up (less than 1 screen)
		margin = 2
		nr = [rows-3*margin,items.length-1].min
		cols = @cols-2*margin

		# write a blank menu
		write_string(margin,margin+1,'-'*(cols-2))
		for r in (margin+1)..(margin+1+nr)
			write_string(r,margin,'|'+' '*(cols-2)+'|')
		end
		write_string(margin+nr+2,margin+1,'-'*(cols-2))

		# write out menu choices and interact
		selected = 0
		shift = 0
		selected_item = ''
		write_message(header)
		while true

			# shift menu if need be
			shift = selected-nr if selected-shift > nr
			shift = selected if selected < shift

			# loop over menu choices
			r = margin
			j = -1
			items.each{|k,v|

				j += 1
				next if j < shift
				r += 1
				break if r > (margin+1+nr)
				if j==selected
					pre = @color[:reverse]
					post = @color[:normal]
				else
					pre = ""
					post = ""
				end
				selected_item = v if j == selected
				write_string(r,margin+2,pre+' '*(cols-3))
				write_string(r,margin+2,k)
				write_string(r,margin+15,v+post)
			}
			c = getch
			case c
				when :up
					selected = [selected-1,0].max
				when :down
					selected = [selected+1,items.length-1].min
				when :pagedown
					selected = [selected+nr/2,items.length-1].min
				when :pageup
					selected = [selected-nr/2,0].max
				when 'g'
					selected = 0
				when 'G'
					selected = items.length-1
				when :enter,:ctrl_m,:ctrl_j
					break
				when :ctrl_c
					return('')
			end
		end

		return(selected_item)

	ensure

		@terminal.show_cursor

	end


end


# end of Screen class
#---------------------------------------------------------------------












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
	def initialize(dimensions=[0,0,0,0])
		@pos_row = dimensions[0]
		@pos_col = dimensions[1]
		@rows = dimensions[2]
		@cols = dimensions[3]
		# if size is unset, set it to screen size minus 1 (top bar)
		@rows = $screen.rows - 1 if @rows <= 0
		@cols = $screen.cols if @cols <= 0
		@stack = "v"  # vertical ("v") or horizontal ("h")
	end

	# These all translate window position to screen position,
	# and then pass off to screen class methods
	def write_info_line(l,c,r)
		$screen.write_info_line(l,c,r,@pos_row,@pos_col,@cols)
	end
	def write_line(row,colfeed,line)
		$screen.write_line(row+1+@pos_row,@pos_col,@cols,colfeed,line)
	end
	def write_string(row,col,str)
		$screen.write_string(@pos_row+row,@pos_col+col,str)
	end
	def write_string_colored(row,col,str,color)
		$screen.write_string_colored(@pos_row+row,@pos_col+col,str,color)
	end
	def setpos(r,c)
		$screen.setpos(r+@pos_row,c+@pos_col)
	end

	# Set the window size, where k is the number of windows
	# and j is the number of this window.
	def set_window_size(j,k,vh="v")
		if vh == "v"
			@pos_row = j*(($screen.rows+1)/k)
			@rows = ($screen.rows+1)/k - 1
			@pos_col = 0
			@cols = $screen.cols
		else
			@pos_row = 0
			@rows = $screen.rows - 1
			@pos_col = j*(($screen.cols+1)/k)
			@cols = ($screen.cols+1)/k - 1
		end
	end

	# Set the size of the last window to fit to the remainder of
	# the screen.
	def set_last_window_size(vh="v")
		if vh == "v"
			@rows = $screen.rows - @pos_row - 1
			@cols = $screen.cols
		else
			@cols = $screen.cols - @pos_col
			@rows = $screen.rows - 1
		end
	end



	# pass-through to screen class
	def method_missing(method,*args,&block)
		$screen.send method, *args, &block
	end

end

# end of Window class
#---------------------------------------------------------------------











#---------------------------------------------------------------------
# FileBuffer class
#
# This class manages everything about a single file buffer. It takes
# on input a filename and reads that file in. It keeps track of
# positions etc, and hosts all the methods for navigation and editing.
# It is a very big class, because the hosts most of the main
# functionality of the text editor.
#---------------------------------------------------------------------

class FileBuffer

	attr_accessor \
		:filename, :text, :editmode, :buffer_history, :extramode, \
		:cutscore, :window, :sticky_extramode, :row, :col

	def initialize(filename)

		# displayed width of a literal tab chracter
		@tabsize = $tabsize
		# what to insert when tab key is pressed
		@tabchar = $tabchar
		# char the file uses for indentation
		@fileindentchar = nil
		# char the editor uses for indentation
		@indentchar = @fileindentchar
		# full indentation string (could be multiple indentation chars)
		@fileindentstring = @tabchar
		@indentstring = @fileindentstring

		# for text justify
		# 0 means full screen width
		@linelength = $linelength

		# read in the file
		@filename = filename
		@text = [""]
		read_file
		# file type for syntax coloring
		set_filetype(@filename)

		# position of cursor in buffer
		@row = 0
		@col = 0
		# shifts of the buffer
		@linefeed = 0
		@colfeed = 0

		# remember if file was CRLF
		@eol = "\n"

		# copy,cut,paste stuff
		@marked = false
		@cutrow = -1  # keep track of last cut row, to check for consecutiveness
		@cutscore = 0  # don't let cuts be consecutive after lots of stuff has happened
		@mark_col = 0
		@mark_row = 0
		@mark_list = {}
		@multimarkmode = false

		# flags
		@autoindent = $autoindent
		@editmode = $editmode
		@extramode = false
		@sticky_extramode = false
		@insertmode = true
		@linewrap = $linewrap
		@cursormode = $cursormode
		@syntax_color = $syntax_color

		# undo-redo history
		@buffer_history = BufferHistory.new(@text,@row,@col)
		# save up info about screen to detect changes
		@colfeed_old = 0
		@marked_old = false

		# bookmarking stuff
		@bookmarks = {}
		@bookmarks_hist = [""]

		# grab a window to write to
		@window = Window.new

		# for marked text highlighting
		@buffer_marks = {}
		@buffer_marks.default = [-1,-1]

		# This does nothing, by default; it is here to allow
		# a user script to modify each text buffer that is opened.
		perbuffer_userscript

	end

	def perbuffer_userscript
	end



	# Enter arbitrary ruby command.
	def enter_command
		answer = @window.ask("command:",$histories.command)
		eval(answer)
		dump_to_screen(true)
		@window.write_message("done")
	rescue
		@window.write_message("Unknown command")
	end

	def update_indentation
		a = @text.map{|line|
			if line[0] != nil && !line[0].is_a?(String)
				line[0].chr
			end
		}
		@nleadingtabs = a.count("\t")
		@nleadingspaces = a.count(" ")
		if @nleadingtabs < (@nleadingspaces-4)
			@fileindentchar = " "
		elsif @nleadingtabs > (@nleadingspaces+4)
			@fileindentchar = "\t"
		else
			@fileindentchar = nil
		end
	end

	# run a script file of ruby commands
	def run_script
		file = @window.ask("run script file:",$histories.script,false,true)
		if (file==nil) || (file=="")
			@window.write_message("cancelled")
			return
		end
		if File.directory?(file)
			list = Dir.glob(file+"/*.rb")
			list.each{|f|
				script = File.read(f)
				eval(script)
				@window.write_message("done")
			}
		elsif File.exist?(file)
			script = File.read(file)
			eval(script)
			@window.write_message("done")
		else
			@window.write_message("script file #{file} doesn't exist")
		end
	rescue
		@window.write_message("Bad script")
	end


	# set the file type from the filename
	def set_filetype(filename)
		$syntax_colors.filetypes.each{|k,v|
			if filename.match(k) != nil
				@filetype = v
			end
		}
		# set up syntax coloring
		@syntax_color_lc = $syntax_colors.lc[@filetype]
		@syntax_color_bc = $syntax_colors.bc[@filetype]
		@syntax_color_regex = $syntax_colors.regex[@filetype]
	end


	# remember a position in the text
	def bookmark
		answer = @window.ask("bookmark:",@bookmarks_hist)
		if answer == nil
			@window.write_message("Cancelled");
		else
			@window.write_message("Bookmarked");
			@bookmarks[answer] = [@row,@col,@linefeed,@colfeed]
		end
	end

	def goto_bookmark
		answer = @window.ask("go to:",@bookmarks_hist)
		if answer == nil
			@window.write_message("Cancelled")
			return
		end
		rc = @bookmarks[answer]
		if rc == nil
			@window.write_message("Invalid bookmark")
			return
		end
		@row = rc[0]
		@col = rc[1]
		@linefeed = rc[2]
		@colfeed = rc[3]
		@window.write_message("found it")
	end



	# Toggle one of many states.
	def toggle
		# get answer and execute the code
		@window.write_message("Toggle")
		c = @window.getch until c!=nil
		if c == :tab
			cmd = @window.menu($keymap.togglelist,"Toggle")
			dump_to_screen(true)
		else
			cmd = $keymap.togglelist[c]
		end
		eval(cmd)
		dump_to_screen(true)
		@window.write_message(cmd)
	end

	# Go back to edit mode.
	def toggle_editmode
		@editmode = true
		@window.write_message("Edit mode")
	end


	# Read into buffer array.
	# Called by initialize -- shouldn't need to call
	# this directly.
	def read_file
		if @filename == ""
			@text.slice!(1..-1)
			@text[0] = ""
			return
		else
			if File.exists? @filename
				text = File.open(@filename,"rb"){|f| f.read}
			else
				@text.slice!(1..-1)
				@text[0] = ""
				return
			end
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
		@text.slice!(1..-1)
		text.each_index{|k|
			@text[k] = text[k]
		}
		if @text.empty?
			@text[0] = ""
		end
		update_indentation
		@indentchar = @fileindentchar
	end

	# Save buffer to a file.
	def save

		# Ask the user for a file.
		# Defaults to current file.
		ans = @window.ask("save to:",[@filename],true,true)
		if ans == nil
			@window.write_message("Cancelled")
			return
		end
		if ans == "" then ans = @filename end
		if ans == ""
			@window.write_message("Cancelled")
			return
		end

		# If name is different from current file name,
		# ask for verification.
		if ans != @filename
			yn = @window.ask_yesno("save to different file:"+ans+" ? [y/n]")
			if yn == "yes"
				@filename = ans
				set_filetype(@filename)
			else
				@window.write_message("aborted")
				return
			end
		end

		# Dump the text to the file.
		begin
			File.open(@filename,"w"){|file|
				text = @text.join(@eol)
				if @fileindentstring != @indentstring
					text = text.split(@eol)
					text.each{|line|
						after = line.split(/^(#{@indentstring})+/).last
						next if after.nil?
						ni = (line.length - after.length)/(@indentstring.length)
						line.slice!(0..-1)
						line << @fileindentstring * ni
						line << after
					}
					text = text.join(@eol)
				end
				file.write(text)
			}
		rescue
			@window.write_message($!.to_s)
			return
		end

		# Let the undo/redo history know that we have saved,
		# for revert-to-saved purposes.
		@buffer_history.save

		# Save the command/search histories.
		$histories.save

		update_indentation
		@indentchar = @fileindentchar
		@window.write_message("saved to: "+@filename)

	end

	# re-open current buffer from file
	def reload
		if modified?
			ans = @window.ask_yesno("Buffer has been modified. Continue anyway?")
			return unless ans == 'yes'
		end
		old_text = @text.dup
		read_file
		if @text != old_text
			ans = @window.ask_yesno("Buffer differs from file. Continue anyway?")
			if ans != 'yes'
				@text.slice!(1..-1)
				old_text.each_index{|k|
					@text[k] = old_text[k]
				}
			end
		end
	end

	# make sure file position is valid
	def sanitize
		if @text.length == 0
			@text[0] = ""
			@row = 0
			@col = 0
			return
		end
		if @row >= @text.length
			@row = @text.length - 1
		end
		if @text[@row].is_a?(String)
			len = @text[@row].length
		else
			len = 0
		end
		@col = [@col,len].min
	end


	def modified?
		@buffer_history.modified?
	end




	# -----------------------------------------------
	# low-level methods for modifying text
	# -----------------------------------------------

	# delete a character
	def delchar(row,col)
		return if @text[row].kind_of?(Array)
		if col == @text[row].length
			mergerows(row,row+1)
		else
			@text[row] = @text[row].dup
			@text[row][col] = ""
		end
	end
	# insert a character
	def insertchar(row,col,c)
		c = @tabchar if c == :tab
		return if @text[row].kind_of?(Array)
		return if c.is_a?(String) == false
		return if col > @text[row].length
		if @text[row] == nil
			@text[row] = c
			return
		end
		@text[row] = @text[row].dup
		if @insertmode || col == @text[row].length
			@text[row].insert(col,c)
		else
			@text[row][col] = c
		end
	end
	# delete a row
	def delrow(row)
		@text.delete_at(row)
	end
	# delete a range of rows (inclusive)
	def delrows(row1,row2)
		@text[row1..row2] = []
	end
	# merge two consecutive rows
	def mergerows(row1,row2)
		return if @text[row1] == nil || @text[row2] == nil
		if @text[row1] == ''
			@text[row1] = @text[row2]
			@text.delete_at(row2)
			return
		end
		if @text[row2] == ''
			@text[row2] = @text[row1]
			@text.delete_at(row1)
			return
		end
		return if @text[row1].kind_of?(Array)
		return if @text[row2].kind_of?(Array)
		if row2 >= @text.length
			return
		end
		col = @text[row1].length
		@text[row1] = @text[row1].dup
		@text[row1] += @text[row2]
		@text.delete_at(row2)
	end
	# split a row into two
	def splitrow(row,col)
		return if @text[row].kind_of?(Array)
		text = @text[row].dup
		@text[row] = text[(col)..-1]
		insertrow(row,text[0..(col-1)])
	end
	# new row
	def insertrow(row,text)
		@text.insert(row,text)
	end
	# insert a string
	def insert(row,col,text)
		return if @text[row].kind_of?(Array)
		@text[row] = @text[row].dup
		@text[row].insert(col,text)
	end
	# delete a column of text
	def column_delete(row1,row2,col)
		for r in row1..row2
			next if @text[r].kind_of?(Array)  # Skip folded text.
			next if @text[r].length < -col    # Skip too short lines.
			next if col >= @text[r].length    # Can't delete past end of line.
			@text[r] = @text[r].dup
			@text[r][col] = ""
		end
	end

	# end of low-level text modifiers
	# -----------------------------------------------






	# -----------------------------------------------
	# high-level text modifiers
	# (which call the low-level ones)
	# -----------------------------------------------

	# sort row & mark_row
	def ordered_mark_rows
		if @row < @mark_row
			row = @mark_row
			mark_row = @row
		else
			row = @row
			mark_row = @mark_row
		end
		return mark_row,row
	end

	# Delete a character.
	# Very simple, if text is not marked;
	# otherwise, much more complicated.
	# Four modes:
	# - col => delete text in range of rows at current column
	# - loc => same as col, but measure from end of line
	# - row => delete first character of each marked line
	# - multi => delete at each mark
	def delete
		return if @multimarkmode
		if @marked
			mark_row,row = ordered_mark_rows
			if @cursormode == 'col'
				column_delete(mark_row,row,@col)
			elsif @cursormode == 'row'
				column_delete(mark_row,row,0)
			elsif @cursormode == 'loc'
				n = @text[@row][@col..-1].length
				if n > 0
					column_delete(mark_row,row,-n)
				end
			else
				mark_list.each{|row,cols|
					# Loop over column positions starting from end,
					# because doing stuff at early in the line changes
					# positions later in the line.
					cols.uniq.sort.reverse.each{|col|
						column_delete(row,row,col)
						# Adjust mark positions due to changes to the left
						# of the mark.
						@mark_list[row-@row].map!{|x|
							if (x+@col) > col
								x-1
							else
								x
							end
						}
					}
				}
			end
		else
			delchar(@row,@col) if @text[@row].kind_of?(String)
		end
	end

	# Backspace over a character.
	# Similar to delete (above).
	def backspace
		return if @multimarkmode
		if @marked
			return if @col == 0
			mark_row,row = ordered_mark_rows
			if @cursormode == 'col'
				column_delete(mark_row,row,@col-1)
				cursor_left
			elsif @cursormode == 'row'
				column_delete(mark_row,row,0)
				cursor_left
			elsif @cursormode == 'loc'
				n = @text[@row][@col..-1].length + 1
				column_delete(mark_row,row,-n)
				cursor_left
			else
				mark_list.each{|row,cols|
					cols.uniq.sort.reverse.each{|col|
						column_delete(row,row,col-1)
						@mark_list[row-@row].map!{|x|
							if (x+@col) > col
								x-1
							else
								x
							end
						}
					}
				}
				cursor_left
			end
		else
			if (@col+@row)==0
				return
			end
			if @col == 0
				cursor_left
				mergerows(@row,@row+1)
				return
			end
			cursor_left
			delchar(@row,@col)
		end
	end

	# Insert a char and move to the right.
	# Very simple if text is not marked.
	# For marked text, issues are similar to delete method above.
	def addchar(c)
		return if @multimarkmode
		if c == :tab
			c = @tabchar
			c = " "*6 if @filetype == 'f' && @col == 0
		end
		return if ! c.is_a?(String)
		return if c.index("\e")
		if @marked == false
			insertchar(@row,@col,c)
		else
			mark_row,row = ordered_mark_rows
			if @cursormode == 'multi'
				list = mark_list
			elsif @cursormode == 'col'
				list = {}
				for r in mark_row..row
					list[r] = [@col] unless @col > @text[r].length
				end
			elsif @cursormode == 'loc'
				n = @text[@row][@col..-1].length
				list = {}
				for r in mark_row..row
					next if @text[r].length == 0
					list[r] = [@text[r].length-n] unless n > @text[r].length
				end
			else
				list = {}
				for r in mark_row..row
					list[r] = [0]
				end
			end
			list.each{|row,cols|

				# don't insert blanks at start of line
				if (@text[row].length==0)&&((c==?\s)||(c==?\t)||(c=="\t")||(c==" "))
					next
				end

				cols = cols.uniq.sort.reverse
				cols.each{|col|
					insertchar(row,col,c)
					if @cursormode == 'multi'
						@mark_list[row-@row].map!{|x|
							if (x+@col) > col
								x+1
							else
								x
							end
						}
					end
				}

			}
		end
		cursor_right(c.length)
		if @linewrap
			justify(true)
		end
	end

	# Add a line-break.
	# Pretty simple except for autoindent.
	def newline
		if @marked then return end
		if @col == 0
			insertrow(@row,"")
			cursor_down(1)
		else
			splitrow(@row,@col)
			ws = ""
			if @autoindent

				# snap shot, so we can undo auto-indent
				@buffer_history.add(@text,@row,@col)

				# Figure out leading "whitespace", where "whitespace"
				# now includes non-whitespace leading characters which are
				# the same on the last few lines.
				ws = ""
				if @row > 1
					s0 = @text[@row-2].dup
					s1 = @text[@row-1].dup
					s2 = @text[@row].dup
					ml = [s0.length,s1.length,s2.length].min
					s0 = s0[0,ml]
					s1 = s1[0,ml]
					s2 = s2[0,ml]
					until (s1==s2)&&(s0==s1)
						s0.chop!
						s1.chop!
						s2.chop!
					end
					ws = s2
				end
				a = @text[@row].match(/^\s*/)
				if a != nil
					ws2 = a[0]
				end
				ws = [ws,ws2].max
				# If current line is just whitespace, remove it.
				# Rule #1: no trailing whitespace.
				if @text[@row].match(/^\s*$/)
					@text[@row] = ""
				end
				insertchar(@row+1,0,ws) if ws.length > 0
			end
			@col = ws.length
			@row += 1
		end
	end

	# Justify a block of text.
	# If linewrap is false, we justify the marked text (or current line).
	# If linewrap is true, then we justify the current line, under
	# asumption that we want to wrap the line when it gets too long.
	def justify(linewrap=false,cursor=true)

		# If the linelength hasn't been specified, let it be the window width.
		if @linelength == 0 then @linelength = @window.cols end

		# If we are doing linewrap, use the current linelength,
		# otherwise ask for the linelength to use.
		if linewrap
			cols = @linelength
			# If line is short, nothing to be done.
			return if @text[@row].length < cols
		else
			# Ask for desired line length.
			# nil means cancel, empty means screen width
			ans = @window.ask("Justify width:",[@linelength.to_s],true)
			if ans == nil
				@window.write_message("Cancelled")
				return
			end
			if ans == ""
				cols = @linelength
			elsif ans == "0"
				cols = @window.cols
			elsif ans.to_i < 0
				cols = @window.cols + ans.to_i
			else
				cols = ans.to_i
			end
			@linelength = cols
		end

		# set start & end rows
		if @marked
			mark_row, row = ordered_mark_rows
		else
			mark_row = @row
			row = @row
		end
		nl = row - mark_row + 1

		# make one long line out of multiple lines
		text = @text[mark_row..row].join(" ")
		for r in mark_row..row
			delrow(mark_row)
		end

		# loop through words and check length
		c = 0
		r = mark_row
		loop do
			c2 = text.index(/([^\s]\s)|($)/,c)  # end of next word
			if c2 == nil then break end  # end, if no more words
			# if we are past the edge, then put it in the next row
			# Otherwise, keep going.
			if c2 >= (cols-1)
				if c == 0 then c = c2+1 end  # careful about long words
				insertrow(r,text[0,c])
				text = text[c..-1]
				if text == nil then text = "" end
				text.lstrip!
				r += 1
				c = 0
			else
				c = c2+1
			end
			if text == nil || text == ""
				text = ""
				break
			end
		end
		# If we are linewrapping, then stick the overflow at the start
		# of the following line, and justify that line (recursive).
		# Otherwise, create a new row for the overflow.
		if linewrap && @text[r].is_a?(String)
			if @text[r] == nil || @text[r] == ""
				insertrow(r,text)
			else
				@text[r] = text + " " + @text[r]
				@row += 1
				justify(true,false)
				@row -= 1
			end
		else
			insertrow(r,text)
		end

		# If we are line-wrapping, we must be careful to place the cursor
		# at the correct position.
		if linewrap
			if cursor && @col >= @text[@row].length+1
				@col = @col - @text[@row].length - 1
				@row += 1
			end
		else
			@row = r
			@col = 0
		end
		@marked = false

		if !linewrap
			@window.write_message("Justified to "+cols.to_s+" columns")
		end

	end


	# end of high-level text modifiers
	# -----------------------------------------------




	#
	# Undo / redo
	#
	# Each one of these does:
	#   - set history buffer to new/old buffer
	#   - text buffer text to the historical one
	#   - set cursor position to historical one
	#   - sanitize the cursor position
	#
	def better_cursor_position
		if @row-@linefeed >= @window.rows
			center_screen
		end
		if @row - @linefeed < 0
			center_screen
		end
	end
	def undo
		if @buffer_history.prev != nil
			@buffer_history.tree = @buffer_history.prev  # set pointer back
			@text.delete_if{|x|true}
			@text.concat(@buffer_history.copy)
			@row = @buffer_history.next.row
			@col = @buffer_history.next.col
			better_cursor_position
		end
	end
	def redo
		if @buffer_history.next != nil
			@buffer_history.tree = @buffer_history.next
			@text.delete_if{|x|true}
			@text.concat(@buffer_history.copy)
			@row = @buffer_history.row
			@col = @buffer_history.col
			better_cursor_position
		end
	end
	def revert_to_saved
		@text.delete_if{|x|true}
		@text.concat(@buffer_history.revert_to_saved)
		@row = @buffer_history.next.row
		@col = @buffer_history.next.col
		better_cursor_position
	end
	def unrevert_to_saved
		@text.delete_if{|x|true}
		@text.concat(@buffer_history.unrevert_to_saved)
		@row = @buffer_history.row
		@col = @buffer_history.col
		better_cursor_position
	end






	#
	# Navigation stuff
	#

	# handles folded text arrays
	def linelength(line)
		if line.kind_of?(Array)
			return 0
		else
			return line.length
		end
	end
	def cursor_right(n=1)
		@col += n
		if @col > linelength(@text[@row])
			if @row < (@text.length-1)
				@col = 0
				@row += 1
			else
				@col -= n
			end
		end
	end
	def cursor_left(n=1)
		@col -= n
		if @col < 0
			if @row > 0
				@col = linelength(@text[@row-1])
				@row -= 1
			else
				@col = 0
			end
		end
	end
	def cursor_eol
		@col = linelength(@text[@row])
	end
	def cursor_sol
		if @text[@row].kind_of?(Array)
			@col = 0
			return
		end
		ws = @text[@row].match(/^\s+/)
		if ws == nil
			ns = 0
		else
			ns = ws[0].length
		end
		if @col > ns
			@col = ns
		elsif @col == 0
			@col = ns
		else
			@col = 0
		end
	end
	def cursor_down(n)
		sc = bc2sc(@row,@col)
		@row += n
		if @row >= @text.length
			@row = @text.length-1
		end
		@col = sc2bc(@row,sc)
	end
	def cursor_up(n)
		sc = bc2sc(@row,@col)
		@row -= n
		if @row < 0
			@row = 0
		end
		@col = sc2bc(@row,sc)
	end
	def page_down
		r = @row - @linefeed
		if r < (@window.rows/2)
			cursor_down(@window.rows/2-r)
		elsif r < (@window.rows-1)
			cursor_down(@window.rows - 1 - r)
		else
			cursor_down(@window.rows-1)
		end
	end
	def page_up
		r = @row - @linefeed
		if r > (@window.rows/2)
			cursor_up(r-@window.rows/2)
		elsif r > 0
			cursor_up(r)
		else
			cursor_up(@window.rows-1)
		end
	end
	# go to a line in the buffer
	def goto_line(num=nil)
		if num==nil
			num = @window.ask("go to line:",$histories.line_number)
			if num == nil
				@window.write_message("Cancelled")
				return
			end
		end
		@row = num.to_i
		@col = 0
		if @row < 0
			@row = @text.length + @row
		end
		if @row >= @text.length
			@row = @text.length - 1
		end
		# only center, if we go off the screen
		r = @row - @linefeed
		if r > (@window.rows-1) || r < 0
			center_screen
		end
		@window.write_message("went to line "+@row.to_s)
	end
	def screen_left(n=1)
		@colfeed += n
	end
	def screen_right(n=1)
		@colfeed = [0,@colfeed-n].max
	end
	def screen_down(n=1)
		@linefeed = [0,@linefeed-n].max
		@row = [@row,@linefeed+@window.rows-1].min
	end
	def screen_up(n=1)
		@linefeed += n
		@row = [@row,@linefeed].max
	end
	def center_screen(r=@row)
		@linefeed = @row - @window.rows/2
		@linefeed = 0 if @linefeed < 0
	end




	#
	# search
	#
	def search(p)
		if p == 0
			# get search string from user
			token = @window.ask("Search:",$histories.search)
		elsif
			token = $histories.search[-1]
		end
		if token == nil || token == ""
			@window.write_message("Cancelled")
			return
		end
		# is it a regexp
		if token.match(/^\/.*\/$/) != nil
			token = eval(token)
		end
		nlines = @text.length
		row = @row
		if p >= 0
			# find first match from this line down
			# start with current line
			idx = nil
			idx = @text[row].index(token,@col+1) if @text[row].kind_of?(String)
			while(idx==nil)
				row = (row+1).modulo(nlines)  # next line
				idx = nil
				idx = @text[row].index(token) if @text[row].kind_of?(String)
				if (row == @row) && (idx==nil)  # stop if we wrap back around
					@window.write_message("No matches")
					return
				end
			end
		else
			if @col > 0 && @text[row].kind_of?(String)
				idx = @text[row].rindex(token,@col-1)
			else
				idx = nil
			end
			while(idx==nil)
				row = (row-1)
				if row < 0 then row = nlines-1 end
				idx = nil
				idx = @text[row].rindex(token) if @text[row].kind_of?(String)
				if (row == @row) && (idx==nil)
					@window.write_message("No matches")
					return
				end
			end
		end
		@window.write_message("Found match")
		@row = row
		@col = idx
		# recenter screen, when we have gone off page
		if ((@row - @linefeed) > (@window.rows - 1)) || ((@row - @linefeed) < (0))
			center_screen(@row)
		end
	end


	def search_and_replace

		# Get the current position, so we can return when we're done.
		row0 = @row
		col0 = @col
		@linefeed0 = @linefeed
		@colfeed0 = @colfeed

		# Get the search string from the user.
		token = @window.ask("Search:",$histories.search)
		if token == nil
			@window.write_message("Cancelled")
			return
		end
		# Is it a regexp?
		if token.match(/^\/.*\/$/) != nil
			token = eval(token)
		end

		# Get the replace string from the user.
		replacement = @window.ask("Replace:",$histories.replace)
		if replacement == nil
			@window.write_message("Cancelled")
			return
		end

		# Start at current position.
		if @marked
			row,sr = @mark_row,@row
			col,sc = @mark_col,@col
			@marked = false
			if row == sr
				search_and_replace_single_line(token,replacement,row,col,sc)
				return
			end
		else
			row = @row
			col = @col
			sr = @row
			sc = @col
		end
		loop do
			nlines = @text.length
			a = search_and_replace_single_line(token,replacement,row,col)
			break if a==-1
			row = (row+1).modulo(nlines)
			if row == sr
				# When we return to the original line, do the start of the
				# line (which we missed the first time around).
				search_and_replace_single_line(token,replacement,row,col,sc)
				break
			end
			col = 0
		end
	ensure
		@row = row0
		@col = col0
		@linefeed = @linefeed0
		@colfeed = @colfeed0
		dump_to_screen(true)
		@window.write_message("Done.")
	end



	# Execute a search and replace on a single line.
	def search_and_replace_single_line(token,replacement,row,col,endcol=nil)
		return if @text[row].kind_of?(Array)
		idx = @text[row].index(token,col)
		while(idx!=nil)
			return if endcol!=nil && idx >= endcol
			str = @text[row][idx..-1].scan(token)[0]
			@row = row
			@col = idx
			# recenter sreen, when we have gone off page
			if ((@row - @linefeed) > (@window.rows - 1)) || ((@row - @linefeed) < (0))
				center_screen(@row)
			end
			dump_to_screen(true)
			highlight(row,idx,idx+str.length-1)
			yn = @window.ask_yesno("Replace this occurance?")
			l = str.length
			if yn == "yes"
				temp = @text[row].dup
				@text[row] = temp[0,idx]+replacement+temp[(idx+l)..-1]
				col = idx+replacement.length
			elsif yn == "cancel"
				return -1
			else
				col = idx+replacement.length
			end
			if col > @text[row].length
				break
			end
			idx = @text[row].index(token,col)
		end
	end





	# -----------------------------------------------
	# copy/paste and text marking
	# -----------------------------------------------

	# When we have list of marked positions:
	# if we are still selecting (@multimarkmode),
	# then return the truth (absolute positions);
	# otherwise, we have stored up the distance from
	# the cursor, so we must add that back into
	# the answer.
	def mark_list
		if @multimarkmode
			ans = @mark_list
		else
			ans = {}
			@mark_list.each{|k,v|
				k = k + @row
				v = v.map{|x| x+=@col}
				ans[k] = v.map{|x| x if x >= 0}.compact
			}
		end
		return ans
	end

	# Set a mark at the current cursor position.
	def mark
		# For multiple, manually placed, marks:
		if @multimarkmode
			@marked = true
			if @mark_list[@row] == nil
				@mark_list[@row] = [@col]
			else
				@mark_list[@row] += [@col]
				@mark_list[@row].uniq!
			end
		# otherwise toggle marked state:
		elsif @marked
			unmark
		else
			@marked = true
			@window.write_message("Marked")
			@mark_col = @col
			@mark_row = @row
		end
	end

	def unmark
		@marked = false
		@mark_list = {}
		@cursormode = $cursormode if @cursormode == 'multi'
		@window.write_message("Unmarked")
	end

	# Enter or exit multimark mode.
	# In multimark mode, we manually select many marks.
	def multimark
		if @multimarkmode
			@multimarkmode = false
			nml = {}
			@mark_list.each{|k,v|
				nml[k-@row] = v.map{|x| x -= @col}
			}
			@mark_list = nml
			@marked = true
		else
			@multimarkmode = true
			@marked = false
			@cursormode = 'multi'
			@mark_list = {}
		end
	end

	def copy(cut=0)
		return if @cursormode == 'multi'
		# if this is continuation of a line by line copy
		# then we add to the copy buffer
		if @marked
			return if @cursormode == 'col' || @cursormode == 'loc'
			$copy_buffer = []
			@marked = false
		else
			if @row!=(@cutrow+1-cut) || @cutscore <= 0
				$copy_buffer = []
			else
				$copy_buffer.pop  # remove the newline
			end
			@cutrow = @row
			@cutscore = 25
			@mark_row = @row
			@mark_col = 0
			@col = @text[@row].length
		end

		# rectify row, mark_row order
		if @row == @mark_row
			if @col < @mark_col
				@mark_col,@col = @col, @mark_col
			end
		elsif @row < @mark_row
			@mark_row,@row = @row,@mark_row
			@mark_col,@col = @col,@mark_col
		end



		#
		#	add to copy buffer
		#
		if @mark_row == @row

			# single line cut/copy

			line = @text[@row] # the line of interest

			if line.kind_of?(Array)  # folded text
				$copy_buffer += [line] + ['']
				if cut == 1
					@text[@row] = ''
					mergerows(@row,@row+1)
				end
			else  # regular text
				@text[@row] = line[0,@mark_col] if cut == 1
				if @col < line.length
					@text[@mark_row] += line[@col+1..-1] if cut == 1
					$copy_buffer += [line[@mark_col..@col]]
				else
					# include line ending in cut/copy
					$copy_buffer += [line[@mark_col..@col]] + ['']
					mergerows(@row,@row+1) if cut == 1
				end
			end

		else

			# multi-line cut/copy

			firstline = @text[@mark_row]
			if firstline.kind_of?(Array)
				$copy_buffer += [firstline]
				@text[@mark_row] = '' if cut == 1
			else
				$copy_buffer += [firstline[@mark_col..-1]]
				@text[@mark_row] = firstline[0,@mark_col] if cut == 1
			end
			$copy_buffer += @text[@mark_row+1..@row-1]
			lastline = @text[@row]
			if lastline.kind_of?(Array)
				$copy_buffer += [lastline]
				@text[@mark_row] += '' if cut == 1
			else
				$copy_buffer += [lastline[0..@col]]
				tail = lastline[@col+1..-1]
				@text[@mark_row] += tail if cut == 1 && tail != nil
			end
			delrows(@mark_row+1,@row) if cut == 1

		end

		# position cursor
		if cut == 1
			@row = @mark_row
			@col = @mark_col
		else
			@row = @mark_row + 1
			@col = 0
		end

	end


	def cut
		copy(1)
	end


	def paste
		@cutrow = -1
		@cutscore = 0

		return if @text[@row].kind_of?(Array)
		return if $copy_buffer.empty?

		if $copy_buffer.length > 1  # multi-line paste

			# text up to cursor
			text = @text[0,@row]
			if @col > 0
				text += [@text[@row][0,@col]]
			else
				text += ['']
			end

			# inserted text
			firstline = $copy_buffer[0]
			if firstline.kind_of?(Array)
				if text[-1] == ''
					text[-1] = firstline
				else
					text += [firstline]
				end
			else
				text[-1] += firstline
			end
			text += $copy_buffer[1..-2] if $copy_buffer.length > 2
			lastline = $copy_buffer[-1]
			text += [lastline]

			# text from cursor on
			if @text[@row].kind_of?(Array)
				text[-1] =  @text[@row]
			else
				text[-1] += @text[@row][@col..-1]
			end

			# Copy new text to @text, but do so in a way
			# which keeps the pointer the same. This is in case
			# we are editing the file in multiple windows.
			@text.shift(@row+1)
			text.reverse.each{|line|
				@text.unshift(line)
			}

		else  # single line paste
			if $copy_buffer[0].kind_of?(String)
				@text[@row] = @text[@row][0,@col] + $copy_buffer[0] + @text[@row][@col..-1]
			else
				@text.insert(@row,$copy_buffer)
			end
		end

		@row += $copy_buffer.length - 1
		@col += $copy_buffer[-1].length

	end

	# end of copy/paste stuff
	# -----------------------------------------------









	# -----------------------------------------------
	# display text
	# -----------------------------------------------

	def get_cursor_position
		ypos = @row - @linefeed
		if ypos <= 0
			@linefeed += ypos
			ypos = 0
		elsif ypos >= @window.rows
			@linefeed += ypos + 1 - @window.rows
			ypos = @window.rows - 1
		end
		cursrow = ypos+1
		curscol = bc2sc(@row,@col) - @colfeed
		if curscol > (@window.cols-1)
			@colfeed += curscol - @window.cols + 1
			curscol = @window.cols - 1
		end
		if curscol < 0
			@colfeed += curscol
			curscol = 0
		end
		return cursrow,curscol
	end

	def update_top_line(cursrow,curscol)
		# report on cursor position
		r = (@linefeed+cursrow-1)
		c = (@colfeed+curscol)
		r0 = @text.length - 1
		position = r.to_s + "/" + r0.to_s + "," + c.to_s
		if @buffer_history.modified?
			status = "Modified"
		else
			status = ""
		end
		if !@editmode
			status = status + "  VIEW"
		end
		# report on number of open buffers
		if $buffers.npage <= 1
			lstr = @filename
		else
			nb = $buffers.npage
			ib = $buffers.ipage
			lstr = sprintf("%s (%d/%d)",@filename,ib+1,nb)
		end
		@window.write_info_line(lstr,status,position)
	end



	# write everything, including status lines
	def dump_to_screen(refresh=false)
		cursrow,curscol = get_cursor_position
		# write the text to the screen
		dump_text(refresh)
		if @extramode
			@window.write_message("EXTRAMODE")
		end
		# set cursor position
		update_top_line(cursrow,curscol)
		@window.clear_message_text if refresh
		@window.setpos(cursrow,curscol)
	end


	#
	# just dump the buffer text to the screen
	#
	def dump_text(refresh=false)

		# get only the rows of interest
		text = @text[@linefeed,@window.rows].dup

		# by default, don't update any rows
		rows_to_update = []
		if refresh
			rows_to_update = (0..(@window.rows-1)).to_a
		end

		# update any rows that have changed
		text.each_index{|i|
			if text[i] != @window.buffer[i]
				rows_to_update << i
				@buffer_marks.delete(i+@linefeed)
			end
		}

		# screen snapshot for next go-around
		@window.buffer = text.dup

		# if colfeed changed, must update whole screen
		if @colfeed != @colfeed_old || refresh || @linefeed != @linefeed_old
			rows_to_update = Array(0..(text.length-1))
			@buffer_marks = {}
		end

		# Handle marked text highlighting
		#
		# Populate buffer_marks = {} with a list of start
		# and end points for highlighting, so that we
		# will know what needs to be updated.
		buffer_marks = {}
		if @marked
			mark_row,row = @mark_row,@row
			mark_row,row = row,mark_row if mark_row > row
			if @cursormode == 'col'
				for j in mark_row..row
					buffer_marks[j] = [[@col,@col]] unless j==@row
				end
			elsif @cursormode == 'loc'
				n =  @text[@row][@col..-1].length
				for j in mark_row..row
					m = @text[j].length - n
					buffer_marks[j] = [[m,m]] unless j==@row
				end
			elsif @cursormode == 'row'
				# Start with 'internal' rows (not first nor last.
				# Easy: do the whole row.
				for j in (mark_row+1)..(row-1)
					buffer_marks[j] = [[0,@text[j].length]]
				end
				if @row > @mark_row
					buffer_marks[@mark_row] = [[@mark_col,@text[@mark_row].length]]
					buffer_marks[@row] = [[0,@col-1]] unless @col == 0
				elsif @row == @mark_row
					if @col > @mark_col
						buffer_marks[@row] = [[@mark_col,@col-1]]
					elsif @col < @mark_col
						buffer_marks[@row] = [[@col+1,@mark_col]]
					end
				else
					buffer_marks[@mark_row] = [[0,@mark_col]]
					buffer_marks[@row] = [[@col+1,@text[@row].length]] unless @col==@text[@row].length
				end
			else  # multicursor mode
				mark_list.each{|r,v|
					v.each{|c|
						if buffer_marks[r] == nil
							buffer_marks[r] = [[c,c]] unless r==@row && c==@col
						else
							buffer_marks[r] << [c,c] unless r==@row && c==@col
						end
					}
				}
			end
		end
		if buffer_marks != @buffer_marks
			buffer_marks.merge(@buffer_marks).each_key{|k|
				if buffer_marks[k] != @buffer_marks[k]
					rows_to_update << k - @linefeed
				end
			}
		end

		rows_to_update = rows_to_update.uniq.delete_if{|x|x<0}

		# write out text
		for r in rows_to_update
			line = text[r]
			next if line == nil
			if line.kind_of?(String)
				if @syntax_color
					aline = syntax_color(line)
				else
					aline = line + $color[:normal]
				end
				aline = tabs2spaces(aline)
			else
				bline = tabs2spaces(line[0])
				descr = "[[" + line.length.to_s + " lines: "
				tail = "]]"
				aline = $color[:hiddentext] + descr + \
					bline[0,(@window.cols-descr.length-tail.length).floor] + \
					tail + $color[:normal]
			end
			@window.write_line(r,@colfeed,aline)
		end

		# now highlight text
		if buffer_marks != @buffer_marks
			buffer_marks.each_key{|k|
				if buffer_marks[k] != @buffer_marks[k]
					buffer_marks[k].each{|pair|
						highlight(k,pair[0],pair[1])
					}
				end
			}
		end
		@buffer_marks = buffer_marks.dup

		# vi-style blank lines
		r = text.length
		while r < (@window.rows)
			@window.write_line(r,0,'~')
			r += 1
		end

		@colfeed_old = @colfeed
		@linefeed_old = @linefeed
		@row_old = @row

	end


	# highlight a particular row, from scol to ecol
	# scol & ecol are columns in the text buffer
	def highlight(row,scol,ecol)
		# only do rows that are on the screen
		if row < @linefeed then return end
		if row > (@linefeed + @window.rows - 1) then return end

		#return if @text[row].length < 1
		return if @text[row].kind_of?(Array)

		# convert pos in text to pos on screen
		sc = bc2sc(row,scol)
		ec = bc2sc(row,ecol)

		# replace tabs with spaces
		sline = tabs2spaces(@text[row])
		# get just string of interest
		if sc < @colfeed then sc = @colfeed end
		if ec < @colfeed then return end
		str = sline[sc..ec]
		if ec == sline.length then str += " " end
		ssc = sc - @colfeed
		sec = ec - @colfeed

		if (str.length+ssc) >= @window.cols
			str = str[0,(@window.cols-ssc)]
		end

		@window.write_string_colored((row-@linefeed+1),ssc,str,:marked)
	end



	#
	# INPUT:
	#	bline -- string to add result to
	#	cline -- string to inspect
	#	cqc -- current quote character (to look for)
	# OUTPUT:
	#	bline -- updated bline string
	#	cline -- remainder of cline strin
	#
	def syntax_find_match(cline,cqc,bline)

		k = cline[1..-1].index(cqc)
		if k==nil
			# didn't find the character
			return nil
		end
		bline = cline[0].chr
		cline = cline[1..-1]
		while (k!=nil) && (k>0) && (cline[k-1].chr=="\\") do
			bline += cline[0,k+cqc.length]
			cline = cline[k+cqc.length..-1]
			break if cline == nil
			k = cline.index(cqc)
		end
		if k==nil
			bline += cline
			return(bline)
		end
		if cline == nil
			return(bline)
		end
		bline += cline[0..k+cqc.length-1]
		cline = cline[k+cqc.length..-1]
		return bline,cline
	end



	#
	# Do string and comment coloring.
	# INPUT:
	#   aline -- line of text to color
	#   lccs  -- line comment characters
	#            (list of characters that start comments to end-of-line)
	#   bccs  -- block comment characters
	#            (pairs of comment characters, such as /* */)
	# OUTPUT:
	#   line with color characters inserted
	#
	def syntax_color_string_comment(aline,lccs,bccs)

		dqc = '"'
		sqc = '\''
		rxc = '/'
		dquote = false
		squote = false
		regx = false
		comment = false
		bline = ""
		escape = false

		cline = aline.dup
		while (cline!=nil)&&(cline.length>0) do

			# find first occurance of special character
			all = Regexp.union([lccs,bccs.keys,dqc,sqc,rxc,"\\"].flatten)
			k = cline.index(all)
			if k==nil
				bline += cline
				break
			end
			bline += cline[0..(k-1)] if k > 0
			cline = cline[k..-1]

			# if it is an escape, then move down 2 chars
			if cline[0].chr == "\\"
				r = cline[0,2]
				if r != nil
					bline += r
				end
				cline = cline[2..-1]
				next
			end

			# if eol comment, then we are done
			flag = false
			lccs.each{|str|
				if cline.index(str)==0
					bline += $color[:comment]
					bline += cline
					bline += $color[:normal]
					flag = true
					break
				end
			}
			break if flag

			# block comments
			flag = false
			bccs.each{|sc,ec|
				if cline.index(sc)==0
					b,c = syntax_find_match(cline,ec,bline)
					if b != nil
						bline += $color[:comment]
						bline += b
						bline += $color[:normal]
						cline = c
						flag = true
					end
				end
			}
			next if flag

			# if quote, then look for match
			if (cline[0].chr == sqc) || (cline[0].chr == dqc)
				cqc = cline[0].chr
				b,c = syntax_find_match(cline,cqc,bline)
				if b != nil
					bline += $color[:string]
					bline += b
					bline += $color[:normal]
					cline = c
					next
				end
			end

			# if regex, look for match
			if (cline[0].chr == rxc)
				cqc = cline[0].chr
				b,c = syntax_find_match(cline,cqc,bline)
				if b != nil
					bline += $color[:regex]
					bline += b
					bline += $color[:normal]
					cline = c
					next
				end
			end

			bline += cline[0].chr
			cline = cline[1..-1]
		end

		aline = bline + $color[:normal]
		return aline
	end



	def syntax_color(sline)
		return(sline) if sline == ""
		aline = sline.dup
		# general regex coloring
		@syntax_color_regex.each{|k,v|
			aline.gsub!(k,$color[v]+"\\0"+$color[:normal])
		}
		# trailing whitespace
		aline.gsub!(/\s+$/,$color[:whitespace]+"\\0"+$color[:normal])
		# leading whitespace
		if @indentchar
			q = aline.partition(/\S/)
			q[0].gsub!(/([^#{@indentchar}]+)/,$color[:whitespace]+"\\0"+$color[:normal])
			aline = q.join
		end
		# comments & quotes
		aline = syntax_color_string_comment(aline,@syntax_color_lc,@syntax_color_bc)
		return(aline)
	end


	# functions for converting from column position in buffer
	# to column position on screen
	def bc2sc(row,col)
		return(0) if @text[row] == nil
		return(0) if @text[row].kind_of?(Array)
		text = @text[row][0,col]
		if text == nil
			return(0)
		end
		text2 = tabs2spaces(text)
		if text2 == nil
			n = 0
		else
			n = text2.length
		end
		return(n)
	end
	def sc2bc(row,col)
		bc = 0
		sc = 0
		return(bc) if @text[row] == nil
		return(bc) if @text[row].kind_of?(Array)
		@text[row].each_char{|c|
			if c == "\t"
				sc += @tabsize
				sc -= sc.modulo(@tabsize)
			else
				sc += 1
			end
			if sc > col then break end
			bc += 1
		}
		return(bc)
	end
	def tabs2spaces(line)
		return line if line == nil || line.length == 0
		a = line.split("\t",-1)
		ans = a[0]
		a = a[1..-1]
		return ans if a == nil
		a.each{|str|
			n = ans.gsub(/\e\[.*?m/,"").length
			m = @tabsize - (n+@tabsize).modulo(@tabsize)
			ans += " "*m + str
		}
		return(ans)
	end

	# end of text display stuff
	# -----------------------------------------------



	#
	# text folding/hiding
	#

	# Hide the text from srow to erow.
	def hide_lines_at(srow,erow)
		text = @text[srow..erow]  # grab the chosen lines
		@text[srow] = [text].flatten  # current row = array of marked text
		@text[(srow+1)..erow] = [] if srow < erow  # technically, can hide a single line, but why?
		return text.length
	end
	# Use marking to figure out which lines to hide.
	def hide_lines
		return if !@marked  # need multiple lines for folding
		return if @cursormode == 'multi'
		mark_row,row = ordered_mark_rows
		oldrow = mark_row  # so we can reposition the cursor
		hide_lines_at(mark_row,row)
		@marked = false
		@row = oldrow
	end
	# Ask the user for a start and end search pattern.
	# Hide all lines between start and end pattern.
	def hide_by_pattern
		pstart = @window.ask("start pattern:",$histories.start_folding)
		pend = @window.ask("end pattern:",$histories.end_folding)
		return if pstart == nil || pend == nil
		pstart = Regexp.new(pstart)
		pend = Regexp.new(pend)
		i = -1
		n = @text.length
		while i < n
			i += 1
			line = @text[i]
			next if line.kind_of?(Array)
			if line =~ pstart
				j = i
				while j < n
					j += 1
					line = @text[j]
					next if line.kind_of?(Array)
					if ((pend==//) && !(line=~pstart)) || ((pend!=//) && (line =~ pend))
						if pend == //
							x = hide_lines_at(i,j-1)
						else
							x = hide_lines_at(i,j)
						end
						i = j - x
						break
					end
				end
			end
		end
		@window.write_message("done")
	end
	def unhide_lines
		hidden_text = @text[@row]
		return if hidden_text.kind_of?(String)
		text = @text.dup
		@text.delete_if{|x|true}
		@text.concat(text[0,@row])
		@text.concat(hidden_text)
		@text.concat(text[(@row+1)..-1])
	end
	def unhide_all
		@text.flatten!
	end



	# Launch a menu to choose a command (in case user forgets what key to press).
	def menu(list,text)
		cmd = @window.menu(list,text)
		$buffers.update_screen_size
		cmd = '' if cmd == nil
		return(cmd)
	end




	# These functions allow a user to pretend the indentaion scheme is
	# different than it actually is.  For example, if a file is indented with
	# 4 spaces, and the user likes tabs.
	def indentation_facade

		# If we have already set up a facade, we must remove it
		# before continuing.
		if @fileindentstring != @indentstring
			ans = @window.ask_yesno("Reset indentation change?")
			return unless ans == "yes"
			indentation_real
		end

		# Grab all the indentation whitespace.
		iws = @text.map{|line|
			if line != nil && line.is_a?(String)
				line.partition(/\S/)[0]
			end
		}.join
		# If the file contains both spaces and tabs for indentation,
		# warn the users that this processes will change the file.
		if iws.count(" ")*iws.count("\t") != 0
			ans = @window.ask_yesno("WARNING: tab/space mix => IRREVERSIBLE! ok? ")
			if ans == "no"
				@window.write_message("Cancelled.")
				return
			end
		end

		# Ask the user for the indentation strings.
		# First the current one, then the desired one.
		fileindentstring = @window.ask("File indent string:")
		return if fileindentstring == "" || fileindentstring == nil
		if @fileindentchar != nil && fileindentstring[0] != @fileindentchar[0]
			ans = @window.ask_yesno("That seems wrong. Continue at your own risk?")
			return unless ans == "yes"
		end
		indentstring = @window.ask("User indent string:")
		return if indentstring == "" || indentstring == nil
		return if indentstring == fileindentstring

		# Replace one indentation with the other.
		@fileindentstring = fileindentstring
		@indentstring = indentstring
		@text.map{|line|
			if line.is_a?(Array)
				line.map{|sline|
					after = sline.split(/^(#{@fileindentstring})+/).last
					next if after.nil?
					ni = (sline.length - after.length)/(@fileindentstring.length)
					sline.slice!(0..-1)
					sline << @indentstring * ni
					sline << after
				}
			else
				after = line.split(/^(#{@fileindentstring})+/).last
				next if after.nil?
				ni = (line.length - after.length)/(@fileindentstring.length)
				line.slice!(0..-1)
				line << @indentstring * ni
				line << after
			end
		}

		# Set the tab-insert character to reflect new indentation.
		@indentchar = @indentstring[0].chr
		@tabchar = @indentstring

		dump_to_screen(true)
		@window.write_message("Indentation facade enabled")

	end


	# Remove the indentation facade.
	def indentation_real
		return if @indentstring == @fileindentstring
		@text.map{|line|
			if line.is_a?(Array)
				line.map{|sline|
					after = sline.split(/^(#{@indentstring})+/).last
					next if after.nil?
					ni = (sline.length - after.length)/(@indentstring.length)
					sline.slice!(0..-1)
					sline << @fileindentstring * ni
					sline << after
				}
			else
				after = line.split(/^(#{@indentstring})+/).last
				next if after.nil?
				ni = (line.length - after.length)/(@indentstring.length)
				line.slice!(0..-1)
				line << @fileindentstring * ni
				line << after
			end
		}
		@indentchar = @fileindentchar
		@indentstring = @fileindentstring
		@tabchar = @fileindentstring
		dump_to_screen(true)
		@window.write_message("Indentation facade disabled")
	end


end

# end of big buffer class
#---------------------------------------------------------------------








#---------------------------------------------------------------------
# BufferHistory class
#
# This class manages a linked list of buffer text states for
# undo/redo purposes.  The whole thing is a wrapper around a
# linked list of Node objects, which are defined inside this
# BufferHistory class.
#---------------------------------------------------------------------

class BufferHistory

	attr_accessor :tree

	def initialize(text,row,col)
		# create a root node, with no neighbors
		@tree = Node.new(text,row,col)
		@tree.next = nil
		@tree.prev = nil
		# these are for (un)reverting to saved copy
		@saved = @tree
		@old = @tree
	end

	class Node
		attr_accessor :next, :prev, :text, :row, :col
		def initialize(text,row,col)
			@text = []
			@text = text.dup
			@row = row
			@col = col
		end
		def delete
			@text = nil
			if @next != nil then @next.prev = @prev end
			if @prev != nil then @prev.next = @next end
		end
	end

	# add a new snapshot
	def add(text,row,col)

		# create a new node and set navigation pointers
		@old = @tree
		@tree = Node.new(text,row,col)
		@tree.next = @old.next
		if @old.next != nil
			@old.next.prev = @tree
		end
		@tree.prev = @old
		@old.next = @tree

		# Prune the tree, so it doesn't get too big.
		# Start by going back.
		n=0
		x = @tree
		while x != nil
			n += 1
			x0 = x
			x = x.prev
		end
		x = x0
		while n > 500
			n -= 1
			break if x == @saved
			x = x.next
			x.prev.delete
		end
		# now forward
		n=0
		x = @tree
		while x != nil
			n += 1
			x0 = x
			x = x.next
		end
		x = x0
		while n > 500
			n -= 1
			break if x == @saved
			x = x.prev
			x.next.delete
		end
	end

	# get the current text state
	def text
		@tree.text
	end
	def row
		@tree.row
	end
	def col
		@tree.col
	end

	# Shallow copy
	def copy
		atext = []
		atext = @tree.text.dup
		return(atext)
	end
	def prev
		if @tree.prev == nil
			return(@tree)
		else
			return(@tree.prev)
		end
	end
	def next
		if @tree.next == nil
			return(@tree)
		else
			return(@tree.next)
		end
	end
	def delete
		if (@tree.next==nil)&&(@tree.prev==nil)
			return(@tree)
		else
			@tree.delete
			if @tree.next == nil
				return(@tree.prev)
			else
				return(@tree.next)
			end
		end
	end
	def save
		@saved = @tree
	end
	def modified?
		@saved.text.flatten != @tree.text.flatten
	end
	def revert_to_saved
		@old = @tree
		@tree = @saved
		return(copy)
	end
	def unrevert_to_saved
		@tree = @old
		return(copy)
	end
end

# end of BufferHistory class
#---------------------------------------------------------------------







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

	attr_accessor :copy_buffer, :npage, :ipage

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
				@buffers.each{|buf| buf.dump_to_screen(true)}
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
		ans = $screen.ask("open file:",[""],false,true)
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
				move_to_page(@npage+1)
			end
		else
			while @npage > 1
				@ipage = @npage - 1
				move_to_page(1)
			end
		end
		@ipage = 0
		@pages[@ipage].ibuf = 0
	end

	# Move current buffer to page n.
	def move_to_page(n)

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
		@pages[@ipage].refresh_buffers

		return(@pages[@ipage].buffer)

	end

	# Shift all buffers on the screen up/down.
	def screen_up
		@pages[@ipage].buffers.each{|buf|
			buf.screen_up
		}
		@pages[@ipage].refresh_buffers
	end
	def screen_down
		@pages[@ipage].buffers.each{|buf|
			buf.screen_down
		}
		@pages[@ipage].refresh_buffers
	end

end

# end of BuffersList class
#---------------------------------------------------------------------











#---------------------------------------------------------------------
# KeyMap class
#
# This class defines the keymapping.
# There are 5 sections:
#     1. commandlist -- universal keymapping
#     2. editmode_commandlist -- keymappings when in edit mode
#     3. viewmode_commandlist -- keymappings in view mode
#     4. extra_commandlist -- ones that don't fit
#     5. togglelist -- for toggling states on/off
#     	 These get run when buffer.toggle is run.
#---------------------------------------------------------------------

class KeyMap

	attr_accessor \
		:commandlist, :editmode_commandlist, :extramode_commandlist, \
		:viewmode_commandlist, :togglelist

	def initialize

		@commandlist = {
			:ctrl_q => "buffer = $buffers.close",
			:up => "buffer.cursor_up(1)",
			:down => "buffer.cursor_down(1)",
			:right => "buffer.cursor_right",
			:left => "buffer.cursor_left",
			:pagedown => "buffer.page_down",
			:pageup => "buffer.page_up",
			:home => "buffer.goto_line(0)",
			:home2 => "buffer.goto_line(0)",
			:end => "buffer.goto_line(-1)",
			:end2 => "buffer.goto_line(-1)",
			:ctrl_v => "buffer.page_down",
			:ctrl_y => "buffer.page_up",
			:ctrl_e => "buffer.cursor_eol",
			:ctrl_a => "buffer.cursor_sol",
			:ctrl_n => "buffer = $buffers.next_page",
			:ctrl_b => "buffer = $buffers.prev_page",
			:ctrl_x => "buffer.mark",
			:ctrl_p => "buffer.copy",
			:ctrl_w => "buffer.search(0)",
			:ctrl_g => "buffer.goto_line",
			:ctrl_o => "buffer.save",
			:ctrl_f => "buffer = $buffers.open",
			:ctrl_z => "$screen.suspend($buffers)",
			:ctrl_t => "buffer.toggle",
			:ctrl_6 => "buffer.extramode = true",
			:ctrl_s => "buffer.enter_command",
			:ctrl_l => "$buffers.next_buffer",
			:shift_up => "buffer.screen_down",
			:shift_down => "buffer.screen_up",
			:shift_right => "buffer.screen_right",
			:shift_left => "buffer.screen_left",
			:ctrl_up => "$buffers.screen_down",
			:ctrl_down => "$buffers.screen_up",
			:ctrl_left => "buffer.undo",
			:ctrl_right => "buffer.redo",
			:ctrlshift_left => "buffer.revert_to_saved",
			:ctrlshift_right => "buffer.unrevert_to_saved"
		}
		@commandlist.default = ""
		@extramode_commandlist = {
			"b" => "buffer.bookmark",
			"g" => "buffer.goto_bookmark",
			"c" => "buffer.center_screen",
			"0" => "$buffers.all_on_one_page",
			"1" => "$buffers.move_to_page(1)",
			"2" => "$buffers.move_to_page(2)",
			"3" => "$buffers.move_to_page(3)",
			"4" => "$buffers.move_to_page(4)",
			"5" => "$buffers.move_to_page(5)",
			"6" => "$buffers.move_to_page(6)",
			"7" => "$buffers.move_to_page(7)",
			"8" => "$buffers.move_to_page(8)",
			"9" => "$buffers.move_to_page(9)",
			"[" => "buffer.undo",
			"]" => "buffer.redo",
			"{" => "buffer.revert_to_saved",
			"}" => "buffer.unrevert_to_saved",
			"l" => "buffer.justify",
			"s" => "buffer.run_script",
			"h" => "buffer.hide_lines",
			"u" => "buffer.unhide_lines",
			"U" => "buffer.unhide_all",
			"H" => "buffer.hide_by_pattern",
			"R" => "buffer.reload",
			"r" => "$screen.update_screen_size; $buffers.update_screen_size",
			"f" => "buffer = $buffers.duplicate",
			"i" => "buffer.indentation_facade",
			"I" => "buffer.indentation_real",
			"x" => "buffer.multimark",
			"C" => "$screen.set_cursor_color",
			:up => "buffer.cursor_up(1)",
			:down => "buffer.cursor_down(1)",
			:right => "buffer.cursor_right",
			:left => "buffer.cursor_left",
			:pagedown => "buffer.page_down",
			:pageup => "buffer.page_up",
			:home => "buffer.goto_line(0)",
			:end => "buffer.goto_line(-1)",
			:home2 => "buffer.goto_line(0)",
			:end2 => "buffer.goto_line(-1)",
			:ctrl_x => "buffer.mark",
			:ctrl_6 => "buffer.sticky_extramode ^= true",
			:tab => "eval(buffer.menu($keymap.extramode_commandlist,'extramode'))"
		}
		@extramode_commandlist.default = ""
		@editmode_commandlist = {
			:backspace => "buffer.backspace",
			:backspace2 => "buffer.backspace",
			:ctrl_h => "buffer.backspace",
			:enter => "buffer.newline",
			:ctrl_k => "buffer.cut",
			:ctrl_u => "buffer.paste",
			:ctrl_m => "buffer.newline",
			:ctrl_j => "buffer.newline",
			:ctrl_d => "buffer.delete",
			:ctrl_r => "buffer.search_and_replace",
			:tab => "buffer.addchar(c)",
		}
		@editmode_commandlist.default = ""
		@viewmode_commandlist = {
			"q" => "buffer = $buffers.close",
			"k" => "buffer.cursor_up(1)",
			"j" => "buffer.cursor_down(1)",
			"l" => "buffer.cursor_right",
			"h" => "buffer.cursor_left",
			" " => "buffer.page_down",
			"b" => "buffer.page_up",
			"." => "buffer = $buffers.next_buffer",
			"," => "buffer = $buffers.prev_buffer",
			"/" => "buffer.search(0)",
			"n" => "buffer.search(1)",
			"N" => "buffer.search(-1)",
			"g" => "buffer.goto_line",
			"i" => "buffer.toggle_editmode",
			"[" => "buffer.undo",
			"]" => "buffer.redo",
			"{" => "buffer.revert_to_saved",
			"}" => "buffer.unrevert_to_saved",
			"J" => "buffer.screen_up",
			"K" => "buffer.screen_down",
			"H" => "buffer.screen_left",
			"L" => "buffer.screen_right",
			":" => "buffer.enter_command"
		}
		@viewmode_commandlist.default = ""


		@togglelist = {
			"E" => "@editmode = true",
			"e" => "@editmode = false",
			"A" => "@autoindent = true",
			"a" => "@autoindent = false",
			"I" => "@insertmode = true",
			"i" => "@insertmode = false",
			"W" => "@linewrap = true",
			"w" => "@linewrap = false",
			"c" => "@cursormode = 'col'",
			"C" => "@cursormode = 'loc'",
			"r" => "@cursormode = 'row'",
			"f" => "@cursormode = 'multi'",
			"S" => "@syntax_color = true",
			"s" => "@syntax_color = false",
			"-" => "$buffers.vstack",
			"|" => "$buffers.hstack"
		}
		@togglelist.default = ""

	end


	def extramode_command(keycode)
		cmd = @extramode_commandlist[keycode]
		return(cmd)
	end

	def command(keycode, editmode)
		cmd = @commandlist[keycode]
		if cmd == ""
			if editmode
				cmd = @editmode_commandlist[keycode]
			else
				cmd = @viewmode_commandlist[keycode]
			end
		end
		if cmd == ""
			return nil
		else
			return cmd
		end
	end

end

# end of KeyMap class
#---------------------------------------------------------------------




#---------------------------------------------------------------------
# Histories class
#
# This class stores up various histories, such as search term history,
# command history, and folding history. It saves and loads histories
# from the history file.
#---------------------------------------------------------------------

class Histories

	require 'yaml'

	attr_accessor :file, :search, :replace, :line_number, \
	:command, :script, :start_folding, :end_folding

	def initialize
		@file = $histories_file
		@search = []
		@replace = []
		@line_number = []
		@script = []
		@command = []
		@start_folding = []
		@end_folding = []
		read
	end

	# Save histories to the file.
	def save
		return if @file.nil?
		# If file exists, read first so we can append changes.
		read if File.exist?(@file)
		# Only save some of them.
		hists = {
			"search" => @search.last(1000),
			"replace" => @replace.last(1000),
			"command" => @command.last(1000),
			"script" => @script.last(1000),
			"start_folding" => @start_folding.last(1000),
			"end_folding" => @end_folding.last(1000)
		}
		File.open(@file,"w"){|file|
			YAML.dump(hists,file)
		}
	end

	# Read histories from the file.
	def read
		if (@file.nil?) || (!File.exist?(@file))
			return
		end
		hists = YAML.load_file(@file)
		if !hists
			return
		end
		hists.default = []
		@search = @search.reverse.concat(hists["search"].reverse).uniq.reverse
		@replace = @replace.reverse.concat(hists["replace"].reverse).uniq.reverse
		@command = @command.reverse.concat(hists["command"].reverse).uniq.reverse
		@script = @script.reverse.concat(hists["script"].reverse).uniq.reverse
		@start_folding = @start_folding.reverse.concat(hists["start_folding"].reverse).uniq.reverse
		@end_folding = @end_folding.reverse.concat(hists["end_folding"].reverse).uniq.reverse
	end

end

# end of Histories class
#---------------------------------------------------------------------



#---------------------------------------------------------------------
# SyntaxColors class
#
# This class defines the default syntax colors.
# This is just a container class.
#---------------------------------------------------------------------

class SyntaxColors
	attr_accessor :filetypes, :lc, :bc, :regex
	def initialize
		@filetypes = {
			/\.(sh|csh|rb|py)$/ => "shell",
			/\.([cCh]|cpp)$/ => "c",
			"COMMIT_EDITMSG" => "shell",
			/\.m$/ => "m",
			/\.pro$/ => "idl",
			/\.[fF]$/ => "f"
		}
		# Define per-language from-here-to-end-of-line comments.
		@lc = {
			"shell" => ["#"],
			"ruby" => ["#"],
			"c" => ["//"],
			"f" => ["!",/^c/],
			"m" => ["#","%"],
			"idl" => [";"]
		}
		@lc.default = []
		# Define per-language block comments.
		@bc = {
			"c" => {"/*"=>"*/"},
		}
		@bc.default = {}
		# Define generic regexp syntax rules.
		@regex = {
			# Colorize long lines in fortran.
			"f" => {/^[^cC][^!]{71,}.*$/=>:magenta}
		}
		@regex.default = {}
	end
end

# end of SyntaxColors class
#---------------------------------------------------------------------




#---------------------------------------------------------------------
# Editor class
#
# This is the main class which runs the text editor. It contains a
# hodgepodge of methods and defines some globals for other classes to
# use.  Its main job is to orchestrate everything.
#---------------------------------------------------------------------

class Editor

	require 'optparse'

	def initialize

		# Define some general default parameters. These are set as
		# global variables because they are used all over the place,
		# and because it makes it easier to reset them on the fly.
		$tabsize = 4           # Tab character display width
		$tabchar = "\t"        # What to insert when tab key is pressed
		$autoindent = true
		$linewrap = false
		$cursormode = 'row'    # Default text selection mode
		$syntax_color = true
		$editmode = true       # false = start in view mode
		$linelength = 0        # 0 = terminal width

		# Define the key mapping and colors up front, so that they
		# can be modified by config files and start-up scripts.
		$keymap = KeyMap.new
		$color = define_colors
		$syntax_colors = SyntaxColors.new
		$cursor_color = nil

		# Parse input options after keymap and colors are defined, but before
		# we initialize any of the big classes.  This way, a user script can
		# modify the screen/buffer/etc classes on start-up.
		parse_options

		# Initialize the interactive screen environment, and set the color
		# global to point to the one that screen defines.  This will keep
		# everything in the same place, but allow easy on-the-fly color changes.
		$screen = Screen.new
		$color = $screen.color

		# Read the specified files into the list of buffers.
		$buffers = BuffersList.new(ARGV)

		# Copy buffer and histories are global, so we can copy from one
		# buffer to another.
		$copy_buffer = ""
		$histories = Histories.new

	end

	# Define universal text decorations
	def define_colors
		color = {
			:comment => :cyan,
			:string => :yellow,
			:whitespace => [:red,:reverse],
			:hiddentext => :green,
			:regex => :normal,
			:marked => [:reverse,:blue],
			:message => :yellow,
			:status => :underline,
		}
		return color
	end

	# This is a function which runs an arbitrary ruby script.
	# It can read from a file or from user input.
	def run_script(file=nil)
		# If not file is specified, ask the user for one.
		if file == nil
			file = $screen.ask("run script file:",[""],false,true)
			if (file==nil) || (file=="")
				$screen.write_message("cancelled")
				return
			end
		end
		# If file is a directory, run all *.rb files in the directory.
		if File.directory?(file)
			list = Dir.glob(file+"/*.rb")
			list.each{|f|
				script = File.read(f)
				eval(script,TOPLEVEL_BINDING)
				if $screen != nil
					$screen.write_message("done")
				end
			}
		# If the file exists, run it.
		elsif File.exist?(file)
			script = File.read(file)
			eval(script,TOPLEVEL_BINDING)
			if $screen != nil
				$screen.write_message("done")
			end
		# Complain if the file doesn't exist.
		else
			puts "Script file #{file} doesn't exist."
			puts "Press any key to continue anyway."
			STDIN.getc
		end
	rescue
		if $screen != nil
			$screen.write_message("Bad script")
		else
			puts "Bad script file: #{file}"
			puts "Press any key to continue anyway."
			STDIN.getc
		end
	end
	# --------------------------------------------------------



	# Parse the command line inputs.
	def parse_options
		optparse = OptionParser.new{|opts|
			opts.banner = "Usage: editor [options] file1 file2 ..."
			opts.on('-s', '--script FILE', 'Run this script at startup'){|file|
				run_script(file)
			}
			opts.on('-h', '--help', 'Display this screen'){
				puts opts
				exit
			}
			opts.on('-t', '--tabsize N', Integer, 'Set tabsize'){|n|
				$tabsize = n
			}
			opts.on('-T', '--tabchar c', 'Set tab character'){|c|
				$tabchar = c
			}
			opts.on('-A', '--autoindent', 'Turn on autoindent'){
				$autoindent = true
			}
			opts.on('-a', '--no-autoindent', 'Turn off autoindent'){
				$autoindent = false
			}
			opts.on('-y', '--save-hist FILE', 'Save history in this file'){|file|
				$histories_file = file
			}
			opts.on('-E', '--edit', 'Start in edit mode'){
				$editmode = false
			}
			opts.on('-e', '--no-edit', 'Start in view mode'){
				$editmode = false
			}
			opts.on('-W', '--linewrap [n]', Integer, 'Turn on linewrap'){|n|
				$linewrap = true
				if n.nil?
					$linelength = 0
				else
					$linelength = n
				end
			}
			opts.on('-w', '--no-linewrap', 'Turn off linewrap'){
				$linewrap = false
			}
			opts.on('-C', '--color', 'Turn on syntax coloring'){
				$syntax_color = true
			}
			opts.on('-c', '--no-color', 'Turn off syntax coloring'){
				$syntax_color = false
			}
			opts.on('-v', '--version', 'Print version number'){
				puts $version
				exit
			}
		}
		begin
			optparse.parse!
		rescue
			puts "Error: bad option(s)"
			puts optparse
			exit
		end
	end


	# Run with it.
	def go

		# Catch screen resizes.
		trap("WINCH"){
			$screen.update_screen_size
			$buffers.update_screen_size
		}

		# Start the interactive screen session.
		$screen.start_screen do

			# Dump the text to the screen (true => forced update).
			$buffers.current.dump_to_screen(true)

			# This is the main action loop.
			loop do

				# Make sure we are on the current buffer.
				buffer = $buffers.current

				# Reduce time proximity for cuts.
				# Successive line cuts are grouped together, unless
				# enough time (i.e. keypresses) has elapsed.
				buffer.cutscore -= 1

				# Take a snapshot of the buffer text for undo/redo purposes.
				if buffer.buffer_history.text != buffer.text
					buffer.buffer_history.add(buffer.text,buffer.row,buffer.col)
				end

				# Display the current buffer.
				buffer.dump_to_screen

				# Wait for a valid key press.
				c = $screen.getch until c!=nil

				# Clear old message text.
				buffer.window.clear_message_text

				# Process a key press (run the associated command).
				if buffer.extramode
					command = $keymap.extramode_command(c)
					eval($keymap.extramode_command(c))
					buffer.extramode = false if ! buffer.sticky_extramode
				else
					command = $keymap.command(c,buffer.editmode)
					if command == nil
						buffer.addchar(c) if buffer.editmode && c.is_a?(String)
					else
						eval(command)
					end
				end

				# Make sure cursor is in a good place.
				buffer.sanitize

			end
			# end of main action loop

		end

	end

end

# end of Editor class
#---------------------------------------------------------------------










#---------------------------------------------------------------------
# Run the editor
#---------------------------------------------------------------------
$editor = Editor.new
$editor.go

