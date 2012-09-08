#!/usr/bin/ruby
#
#	editor.rb
#
#	Copyright (C) 2011-2012, Jason P. DeVita (jason@wx13.com)
#
#	Copying and distribution of this file, with or without modification,
#	are permitted in any medium without royalty or restriction. This file
#	is offered as-is, without any warranty.
#
$version = "editor.rb 0.0.0"


require 'optparse'
require 'yaml'



#------------------------------------------------------------
# The Screen class manages the screen output and input.
# It includes all the user interface stuff, such as:
#   - write text to a position on the screen
#   - write status line
#   - ask user a question
# It does not deal with text buffer management or the like.
#------------------------------------------------------------

class Screen

	attr_accessor :rows, :cols

	def initialize

		# get and store screen size
		update_screen_size

		# define keycodes
		@keycodes = {
		:ctrl_a => "\001",
		:ctrl_b => "\002",
		:ctrl_c => "\003",
		:ctrl_d => "\004",
		:ctrl_e => "\005",
		:ctrl_f => "\006",
		:ctrl_g => "\a",
		:ctrl_h => "\b",
		:ctrl_j => "\n",
		:ctrl_k => "\v",
		:ctrl_l => "\f",
		:ctrl_m => "\r",
		:ctrl_n => "\016",
		:ctrl_o => "\017",
		:ctrl_p => "\020",
		:ctrl_q => "\021",
		:ctrl_r => "\022",
		:ctrl_s => "\023",
		:ctrl_t => "\024",
		:ctrl_u => "\025",
		:ctrl_v => "\026",
		:ctrl_w => "\027",
		:ctrl_x => "\030",
		:ctrl_y => "\031",
		:ctrl_z => "\032",
		:ctrl_6 => "\036",
		:enter => "\r",
		:backspace => "\177",
		:backspace2 => "\037",
		:tab => "\t",

		:up => "\e[A",
		:down => "\e[B",
		:right => "\e[C",
		:left => "\e[D",
		:pagedown => "\e[6~",
		:pageup => "\e[5~",
		:home => "\e[H",
		:home2 => "\eOH",
		:end => "\e[F",
		:end2 => "\eOF",

		:shift_left => "\e[2D",
		:shift_right => "\e[2C",
		:shift_up => "\e[2A",
		:shift_down => "\e[2B",
		:ctrl_left => "\e[5D",
		:ctrl_right => "\e[5C",
		:ctrl_up => "\e[5A",
		:ctrl_down => "\e[5B",
		:ctrlshift_left => "\e[6D",
		:ctrlshift_right => "\e[6C",
		:ctrlshift_up => "\e[6A",
		:ctrlshift_down => "\e[6B"
		}
		@keycodes = @keycodes.invert

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

	# Call to stty utility for screen size update, and set
	# @rows and @cols.
	#
	# Returns nothing.
	def update_screen_size
		cols_old = @cols
		rows_old = @rows
		@rows,@cols = `stty size`.split
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
	def start_screen_loop
		system('stty raw -echo')
		print "\e[#{@rows}S"  # roll screen up (clear, but preserve)
		print "\e[?7l"  # disable line wrap
		begin
			yield
		ensure
			print "\e[2J"   # clear the screen
			print "\e[?7h"  # enable line wrap
			system('stty -raw echo')
		end
	end

	# Suspend the editor, and refresh on return.
	#
	# buffer - the current buffer, so we can refresh upon return.
	#
	# Returns nothing.
	def suspend(buffer)
		system('stty -raw echo')
		Process.kill("SIGSTOP",0)
		system('stty raw -echo')
		buffer.dump_to_screen(true)
	end

	# Set cursor position.
	#
	# row - screen row (0 = first line)
	# col - screen column (0 = first column)
	#
	# Returns nothing.
	def setpos(row,col)
		print "\e[#{row+1};#{col+1}H"
	end

	# Write a string at the current cursor position.
	# This was more complex when using curses, but now is trivial.
	#
	# text - a string to be printed, including escape codes
	#
	# Returns nothing.
	def addstr(text)
		print text
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
	# Write a reverse-text string at a specified position.
	#
	# row - screen row
	# col - screen column
	# text - string to be printed
	#
	# Returns nothing.
	def write_string_reversed(row,col,text)
		setpos(row,col)
		addstr($color[:reverse]+text+$color[:normal])
	end

	# Clear an entrire line on the screen.
	#
	# row - screen row
	#
	# Returns nothing.
	def clear_line(row)
		setpos(row,0)
		print "\e[2K"
	end

	# Write to the bottom line (full with).
	# Typically used for asking the user a question.
	#
	# str - string of text to write
	#
	# Returns nothing.
	def write_bottom_line(str)
		write_string_reversed(@rows,0," "*@cols)
		write_string_reversed(@rows,0,str)
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
		while colfeed > 0
			j = line.index("\e")
			break if j==nil
			if j > colfeed
				line = line[colfeed..-1]
				break
			end
			line = line[j..-1]
			colfeed -= j
			j = line.index("m")
			code = line[0..j]
			line = line[j+1..-1]
		end
		print code
		words = line.split("\e")
		return if words.length == 0
		word = words[0]
		write_string(row,col,word[0,width])
		col += word.length
		width -= word.length
		flag = true
		flag = false if width <= 0
		words[1..-1].each{|word|
			j = word.index("m")
			print "\e" + word[0..j]
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
		write_string_reversed(row,col,all)

	end


	# Write a message at the bottom (centered, partial line).
	#
	# message - text to write
	#
	# Returns nothing.
	def write_message(message)
		print "\e[s"
		xpos = (@cols - message.length)/2
		clear_line(@rows)
		write_string_reversed(@rows,xpos,message)
		print "\e[u"
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
						token.insert(col,$tabchar)
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
			$screen.setpos(@rows,(col-shift)+question.length+1)

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
			c = $screen.getch until c!=nil
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
		c = i*@cols/n - 1
		for r in 1..(@rows-1)
			write_string(r,c,"|")
		end
	end


end


# end of Screen class
#----------------------------------------------------------












# ---------------------------------------------------------
# Window class
#
# This is a virtual window that fits inside of the screen.
# Each buffer has a window that it writes to, and each
# window keeps track of its position and size.
# ---------------------------------------------------------

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
	def write_string_reversed(row,col,str)
		$screen.write_string_reversed(@pos_row+row,@pos_col+col,str)
	end
	def setpos(r,c)
		$screen.setpos(r+@pos_row,c+@pos_col)
	end

	# Set the window size, where k is the number of windows
	# and j is the number of this window.
	def set_window_size(j,k,vh="v")
		if vh == "v"
			@pos_row = j*($screen.rows)/k
			@rows = ($screen.rows)/k - 1
			@pos_col = 0
			@cols = $screen.cols
		else
			@pos_row = 0
			@rows = $screen.rows - 1
			@pos_col = j*($screen.cols)/k
			@cols = ($screen.cols)/k - 1
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



	# Allow the use to choose from a menu of choices.
	def menu(items,header)

		# hide the cursor
		puts "\e[?25l"

		# how many rows should the menu take up (less than 1 screen)
		margin = 2
		nr = [rows-2*margin,items.length-1].min
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
					pre = $color[:reverse]
					post = $color[:normal]
				else
					pre = ""
					post = ""
				end
				selected_item = v if j == selected
				write_string(r,margin+2,pre+' '*(cols-3))
				write_string(r,margin+2,k)
				write_string(r,margin+15,v+post)
			}
			c = getch until c!=nil
			case c
				when :up
					selected = [selected-1,0].max
				when :down
					selected = [selected+1,items.length-1].min
				when :pagedown
					selected = [selected+nr/2,items.length-1].min
				when :pageup
					selected = [selected-nr/2,0].max
				when :enter,:ctrl_m,:ctrl_j
					break
				when :ctrl_c
					return('')
			end
		end

		return(selected_item)

	ensure

		# show the cursor
		puts "\e[?25h"

	end



	# pass-through to screen class
	def method_missing(method,*args,&block)
		$screen.send method, *args, &block
	end

end

# end of Window class
#----------------------------------------------------------











# ---------------------------------------------------------
# This is the big main class, which handles a file
# buffer.  Does everything from screen dumps to
# searching etc.
#----------------------------------------------------------

class FileBuffer

	attr_accessor :filename, :text, :editmode, :buffer_history,\
	              :extramode, :cutscore, :window, :sticky_extramode,\
	              :row, :col

	def initialize(filename)

		# set some parameters
		@tabsize = $tabsize
		@tabchar = $tabchar
		@linelength = 0  # 0 means full screen width

		# read in the file
		@filename = filename
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
		@mark_list = []

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
		answer = @window.ask("command:",$command_hist)
		eval(answer)
		@window.write_message("done")
	rescue
		@window.write_message("Unknown command")
	end


	# run a script file of ruby commands
	def run_script
		file = @window.ask("run script file: ",$script_hist,false,true)
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
		@window.write_message('Toggle')
		# get answer and execute the code
		c = $screen.getch until c!=nil
		if c == :tab
			cmd = @window.menu($keymap.togglelist,"Toggle")
			dump_to_screen(true)
		else
			cmd = $keymap.togglelist[c]
		end
		eval(cmd)
		@window.write_message(cmd)
		dump_to_screen(true)
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
			@text = [""]
			return
		else
			if File.exists? @filename
				text = File.open(@filename,"rb"){|f| f.read}
			else
				@text = [""]
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
		@text = text.split("\n",-1)
	end

	# Save buffer to a file.
	def save
		# Ask the user for a file.
		# Defaults to current file.
		ans = @window.ask("save to: ",[@filename],true,true)
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
			yn = @window.ask_yesno("save to different file: "+ans+" ? [y/n]")
			if yn == "yes"
				@filename = ans
				set_filetype(@filename)
			else
				@window.write_message("aborted")
				return
			end
		end
		# Dump the text to the file.
		File.open(@filename,"w"){|file|
			text = @text.join(@eol)
			file.write(text)
		}
		# Let the undo/redo history know that we have saved,
		# for revert-to-saved purposes.
		@buffer_history.save
		# Save the command/search histories.
		if $hist_file != nil
			$buffers.save_hists
		end
		@window.write_message("saved to: "+@filename)
	end

	# re-open current buffer from file
	def reload
		if modified?
			ans = @window.ask_yesno("Buffer has been modified. Continue anyway?")
			return if ans != 'yes'
		end
		old_text = @text
		read_file
		if @text != old_text
			ans = @window.ask_yesno("Buffer differs from file. Continue anyway?")
			if ans != 'yes'
				@text = old_text
			end
		end
	end

	# make sure file position is valid
	def sanitize
		if @text.length == 0
			@text = [""]
			@row = 0
			@col = 0
			return
		end
		if @row >= @text.length
			@row = @text.length - 1
		end
		if @col > @text[@row].length
			@col = @text[@row].length
		end
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
	# multiple new rows
	def insertrows(row,text_array)
		@text = @text[0,row] + text_array + @text[row..-1]
	end
	# completely change a row's text
	def setrow(row,text)
		old = @text[row]
		@text[row] = text
	end
	# add to the end of a line
	def append(row,text)
		return if @text[row].kind_of?(Array)
		@text[row] = @text[row].dup
		@text[row] += text
	end
	# insert a string
	def insert(row,col,text)
		return if @text[row].kind_of?(Array)
		@text[row] = @text[row].dup
		@text[row].insert(col,text)
	end
	# backspace a column of text
	def column_backspace(row1,row2,col)
		if col == 0 then return end
		for r in row1..row2
			next if @text[r].kind_of?(Array)
			c = col
			if @text[r].length == 0 then next end
			if c<=0 then next end
			@text[r] = @text[r].dup
			@text[r][c-1] = ""
		end
	end
	# delete a column of text
	def column_delete(row1,row2,col)
		for r in row1..row2
			next if @text[r].kind_of?(Array)
			c = col
			if c<0 then next end
			if c==@text[r].length then next end
			@text[r] = @text[r].dup
			@text[r][c] = ""
		end
	end

	# end of low-level text modifiers
	# -----------------------------------------------






	# -----------------------------------------------
	# high-level text modifiers
	# (which call the low-level ones)
	# -----------------------------------------------

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
	# delete a character
	def delete
		if @marked
			mark_row,row = ordered_mark_rows
			if @cursormode == 'col'
				column_delete(mark_row,row,@col)
			elsif @cursormode == 'row'
				column_delete(mark_row,row,0)
			else
				@mark_list.each{|r,c|
					column_delete(r,r,c)
				}
			end
		else
			delchar(@row,@col) if @text[@row].kind_of?(String)
		end
	end
	# backspace over a character
	def backspace
		if @marked
			mark_row,row = ordered_mark_rows
			if @cursormode == 'col'
				column_backspace(mark_row,row,@col)
				cursor_left
			elsif @cursormode == 'row'
				column_backspace(mark_row,row,1)
				cursor_left
			else
				@mark_list.each{|r,c|
					column_backspace(r,r,c)
				}
				@mark_list.map!{|r,c|[r,[c-1,0].max]}
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
	# insert a char and move to the right
	def addchar(c)
		if c == :tab
			c = @tabchar
			c = " "*6 if @filetype == 'f' && @col == 0
		end
		return if ! c.is_a?(String)
		if @marked == false
			insertchar(@row,@col,c)
		else
			mark_row,row = ordered_mark_rows
			if @cursormode == 'multi'
				iter = @mark_list
			else
				iter = Array(mark_row..row)
			end
			for r in iter
				if @cursormode == 'multi'
					cc = r[1]
					r = r[0]
				end
				if (@text[r].length==0)&&((c==?\s)||(c==?\t)||(c=="\t")||(c==" "))
					next
				end
				if @cursormode == 'col'
					#sc = bc2sc(@row,@col)
					#cc = sc2bc(r,sc)
					if(@col>@text[r].length) then next end
					insertchar(r,@col,c)
				elsif @cursormode == 'row'
					insertchar(r,0,c)
				else
					insertchar(r,cc,c)
				end
			end
			@mark_list.map!{|r,c|[r,[c+1,@text[r].length].min]}
		end
		cursor_right(c.length) if @cursormode != 'multi' || !@marked
		if @linewrap
			justify(true)
		end
	end
	# add a line-break
	def newline
		if @marked then return end
		if @col == 0
			insertrow(@row,"")
			cursor_down(1)
		else
			splitrow(@row,@col)
			ws = ""
			if @autoindent
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
				# if current line is just whitespace, remove it
				if @text[@row].match(/^\s*$/)
					@text[@row] = ""
				end
				insertchar(@row+1,0,ws) if ws.length > 0
			end
			@col = ws.length
			@row += 1
		end
	end

	# justify a block of text
	def justify(linewrap=false)

		if @linelength == 0 then @linelength = @window.cols end

		if linewrap
			cols = @linelength
			if @text[@row].length < cols then return end
		else
			# ask for screen width
			# nil means cancel, empty means screen width
			ans = @window.ask("Justify width: ",[@linelength.to_s],true)
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
		insertrow(r,text)
		@window.write_message("Justified to "+cols.to_s+" columns")
		if linewrap
			if @col >= @text[@row].length+1
				@col = @col - @text[@row].length - 1
				@row += 1
			end
		else
			@row = r
			@col = 0
		end
		@marked = false
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
			@row = @buffer_history.row
			@col = @buffer_history.col
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
		@row = @buffer_history.row
		@col = @buffer_history.col
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
			num = @window.ask("go to line:",$lineno_hist)
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
	# go to a position on the screen
	def goto_position(r,c)
		@row = r+@linefeed
		@col = sc2bc(@row,c)+@colfeed
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
			token = @window.ask("Search:",$search_hist)
		elsif
			token = $search_hist[-1]
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
		# recenter sreen, when we have gone off page
		if ((@row - @linefeed) > (@window.rows - 1)) ||
		   ((@row - @linefeed) < (0))
			center_screen(@row)
		end
	end
	def search_and_replace
		# get starting point, so we can return
		row0 = @row
		col0 = @col
		@linefeed0 = @linefeed
		@colfeed0 = @colfeed
		# get search string from user
		token = @window.ask("Search:",$search_hist)
		if token == nil
			@window.write_message("Cancelled")
			return
		end
		# is it a regexp
		if token.match(/^\/.*\/$/) != nil
			token = eval(token)
		end
		# get replace string from user
		replacement = @window.ask("Replace:",$replace_hist)
		if replacement == nil
			@window.write_message("Cancelled")
			return
		end
		row = @row
		col = @col
		sr = @row
		sc = @col
		loop do
			nlines = @text.length
			idx = @text[row].index(token,col) if @text[row].kind_of?(String)
			while(idx!=nil)
				str = @text[row][idx..-1].scan(token)[0]
				@row = row
				@col = idx
				# recenter sreen, when we have gone off page
				if ((@row - @linefeed) > (@window.rows - 1)) ||
				   ((@row - @linefeed) < (0))
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
					dump_to_screen(true)
					@window.write_message("Cancelled")
					@row = row0
					@col = col0
					@linefeed = @linefeed0
					@colfeed = @colfeed0
					return
				else
					col = idx+replacement.length
				end
				if col > @text[row].length
					break
				end
				idx = @text[row].index(token,col)
			end
			row = (row+1).modulo(nlines)
			col = 0
			if row == sr then break end
		end
		@row = row0
		@col = col0
		@linefeed = @linefeed0
		@colfeed = @colfeed0
		dump_to_screen(true)
		@window.write_message("No more matches")
	end






	# -----------------------------------------------
	# copy/paste
	# -----------------------------------------------


	def mark
		if @cursormode == 'multi'
			@marked = true
			@mark_list << [@row,@col]
			return
		end
		if @marked
			@marked = false
			@mark_list = []
			@window.write_message("Unmarked")
			return
		end
		@marked = true
		@window.write_message("Marked")
		@mark_col = @col
		@mark_row = @row
	end


	def copy(cut=0)
		return if @cursormode == 'multi'
		# if this is continuation of a line by line copy
		# then we add to the copy buffer
		if @marked
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
				temp = @col
				@col = @mark_col
				@mark_col = temp
			end
		elsif @row < @mark_row
			temp = @row
			@row = @mark_row
			@mark_row = temp
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
			@text = text + @text[(@row+1)..-1]

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
		update_top_line(cursrow,curscol)
		# write the text to the screen
		dump_text(refresh)
		if @extramode
			@window.write_message("EXTRAMODE")
		end
		# set cursor position
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

		# update any rows that have changed
		text.each_index{|i|
			if text[i] != $screen_buffer[i]
				rows_to_update << i
				@buffer_marks.delete(i+@linefeed)
			end
		}

		# screen snapshot for next go-around
		$screen_buffer = text.dup

		# if colfeed changed, must update whole screen
		if @colfeed != @colfeed_old || refresh || @linefeed != @linefeed_old
			rows_to_update = Array(0..(text.length-1))
			@buffer_marks = {}
		end

		#
		# take into account highlighting
		#
		# 1. populate buffer_marks = {} with a list of start
		#    and end points for highlighting.
		# 2. if it is unchanged, do nothing.
		# 3. if it has changed, then update highlighting based on changes
		#
		buffer_marks = {}
		buffer_marks.default = [-1,-1]
		if @marked
			mark_row,row = @mark_row,@row
			mark_row,row = row,mark_row if mark_row > row
			if @cursormode == 'col'
				for j in mark_row..row
					buffer_marks[j] = [@col,@col] if j!=@row
				end
			elsif @cursormode == 'row'
				for j in (mark_row+1)..(row-1)
					buffer_marks[j] = [0,@text[j].length]
				end
				if @row > @mark_row
					buffer_marks[@mark_row] = [@mark_col,@text[@mark_row].length]
					buffer_marks[@row] = [0,@col-1] unless @col == 0
				elsif @row == @mark_row
					if @col > @mark_col
						buffer_marks[@row] = [@mark_col,@col-1]
					elsif @col < @mark_col
						buffer_marks[@row] = [@col+1,@mark_col]
					end
				else
					buffer_marks[@mark_row] = [0,@mark_col]
					buffer_marks[@row] = [@col+1,@text[@row].length] unless @col==@text[@row].length
				end
			else  # multicursor mode
				@mark_list.each{|r,c|
					buffer_marks[r] = [c,c] unless r==@row && c==@col
				}
			end
		end
		if buffer_marks != @buffer_marks
			buffer_marks.merge(@buffer_marks).each_key{|k|
				hpair = buffer_marks[k]
				upair = @buffer_marks[k]
				if hpair != upair
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
				sline = tabs2spaces(line)
				if @syntax_color
					aline = syntax_color(sline)
				else
					aline = sline + $color[:normal]
				end
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
				hpair = buffer_marks[k]
				upair = @buffer_marks[k]
				if hpair != upair
					highlight(k,hpair[0],hpair[1])
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
	def highlight(row,scol,ecol,un=false)
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

		if un
			@window.write_string((row-@linefeed+1),ssc,str)
			return
		else
			@window.write_string_reversed((row-@linefeed+1),ssc,str)
		end
	end
	def unhighlight(row,scol,ecol)
		highlight(row,scol,ecol,true)
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
		dquote = false
		squote = false
		comment = false
		bline = ""
		escape = false

		cline = aline.dup
		while (cline!=nil)&&(cline.length>0) do

			# find first occurance of special character
			all = Regexp.union([lccs,bccs.keys,dqc,sqc,"\\"].flatten)
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
		aline.gsub!(/\s+$/,$color[:whitespace]+$color[:reverse]+"\\0"+$color[:normal])
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
			n = ans.length
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
	def hide_lines_at(srow,erow)
		text = @text[srow..erow]  # grab the chosen lines
		@text[srow] = [text].flatten  # current row = array of marked text
		@text[(srow+1)..erow] = [] if srow < erow  # technically, can hide a single line, but why?
		return text.length
	end
	def hide_lines
		return if !@marked  # need multiple lines for folding
		return if @cursormode == 'multi'
		mark_row,row = ordered_mark_rows
		oldrow = mark_row  # so we can reposition the cursor
		hide_lines_at(mark_row,row)
		@marked = false
		@row = oldrow
	end
	def hide_by_pattern
		pstart = @window.ask("start pattern:",$startfolding_hist)
		pend = @window.ask("end pattern:",$endfolding_hist)
		return if pstart == nil || pend == nil
		if pstart[0,1] == '/'
			pstart = eval(pstart)
		else
			pstart = Regex.new(pstart)
		end
		if pend[0,1] == '/'
			pend = eval(pend)
		else
			pend = Regex.new(pend)
		end
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
					if line =~ pend
						x = hide_lines_at(i,j)
						i = j - x
						break
					end
				end
			end
		end
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




	def menu(list,text)
		cmd = @window.menu(list,text)
		dump_to_screen(true)
		cmd = '' if cmd == nil
		return(cmd)
	end



end

# end of big buffer class
# ---------------------------------------------------








# ---------------------------------------------------
# Linked list of buffer text states for undo/redo
#
# Whole thing is a wrapper around a linked list of Node objects,
# which are defined inside this BufferHistory class.
# ---------------------------------------------------
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
# ---------------------------------------------------







# ---------------------------------------------------
# This is a list of buffers.
# ---------------------------------------------------
class BuffersList

	attr_accessor :copy_buffer, :npage, :ipage

	class Page
		attr_accessor :buffers, :nbuf, :ibuf, :stack_orientation
		def initialize(buffers=[])
			@buffers = buffers
			@nbuf = @buffers.length
			@ibuf = 0
			@stack_orientation = "v"
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
		@npage = 0     # number of pages
		@ipage = 0     # current page number

		# for each file on the command line,
		# put text on its own page
		for filename in files
			@pages[@npage] = Page.new([FileBuffer.new(filename)])
			@npage += 1
		end
		# if no pages, then open a blank file
		if @npage == 0
			@pages[@npage] = Page.new([FileBuffer.new("")])
			@npage += 1
		end
		@ipage = 0  # start on the first buffer
		# read in histories
		if ($hist_file != nil) && (File.exist?($hist_file))
			read_hists
		end

	end

	def update_screen_size
		@pages[@ipage].resize_buffers
		@pages[@ipage].refresh_buffers
	end

	# return next, previous, or current buffer
	def next_page
		@ipage = (@ipage+1).modulo(@npage)
		@pages[@ipage].resize_buffers
		@pages[@ipage].refresh_buffers
		@pages[@ipage].buffer
	end
	def prev_page
		@ipage = (@ipage-1).modulo(@npage)
		@pages[@ipage].resize_buffers
		@pages[@ipage].refresh_buffers
		@pages[@ipage].buffer
	end
	def next_buffer
		@pages[@ipage].next_buffer
	end
	def prev_buffer
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


	# close a buffer
	def close

		buf = @pages[@ipage].buffer  # current buffer

		# if modified, ask about saving to file
		if buf.modified?
			ys = $screen.ask_yesno("Save changes?")
			if ys == "yes"
				buf.save
			elsif ys == "cancel"
				$screen.write_message("Cancelled")
				return(buf)
			end
		end

		# delete current buffer from current page
		@pages[@ipage].delete_buffer

		# if no buffers left on page,
		# then remove the page
		if @pages[@ipage].nbuf == 0
			@pages.delete_at(@ipage)
			@npage -= 1
			@ipage = 0
		end


		# clear message area
		$screen.write_message("")

		# if no pages left, or if only buffer is nil,
		# then exit the editor
		if @npage == 0 || @pages[0].buffer == nil
			if $hist_file != nil
				save_hists
			end
			exit
		end

		@pages[@ipage].resize_buffers
		@pages[@ipage].refresh_buffers

		# return the (new) current buffer
		@pages[@ipage].buffer

	end

	# save histories to histories file
	def save_hists
		if ($hist_file != nil) && (File.exist?($hist_file))
			read_hists
		end
		hists = {"search_hist" => $search_hist.last(1000),\
	             "replace_hist" => $replace_hist.last(1000),\
	             "command_hist" => $command_hist.last(1000),\
	             "script_hist" => $script_hist.last(1000),\
	             "startfolding_hist" => $startfolding_hist.last(1000),\
	             "endfolding_hist" => $endfolding_hist.last(1000)\
	            }
		File.open($hist_file,"w"){|file|
			YAML.dump(hists,file)
		}
	end



	# read histories from histories file
	def read_hists
		if ($hist_file == nil) || (!File.exist?($hist_file))
			return
		end
		hists = YAML.load_file($hist_file)
		if !hists
			return
		end
		hists.default = []
		$search_hist = $search_hist.reverse.concat(hists["search_hist"].reverse).uniq.reverse
		$replace_hist = $replace_hist.reverse.concat(hists["replace_hist"].reverse).uniq.reverse
		$command_hist = $command_hist.reverse.concat(hists["command_hist"].reverse).uniq.reverse
		$script_hist = $script_hist.reverse.concat(hists["script_hist"].reverse).uniq.reverse
		$startfolding_hist = $startfolding_hist.reverse.concat(hists["startfolding_hist"].reverse).uniq.reverse
		$endfolding_hist = $endfolding_hist.reverse.concat(hists["endfolding_hist"].reverse).uniq.reverse
	end


	# open a new file into a new buffer
	def open

		# ask for the file to open
		ans = $screen.ask("open file: ",[""],false,true)
		if (ans==nil) || (ans == "")
			$screen.write_message("cancelled")
			return(@pages[@ipage].buffer)
		end

		# create a new page at the end of the list
		@pages[@npage] = Page.new([FileBuffer.new(ans)])
		@npage += 1
		@ipage = @npage-1

		# report that the file has been opened,
		# and return the new file as the current buffer
		$screen.write_message("Opened file: "+ans)
		return(@pages[@ipage].buffer)

	end


	def duplicate
		@pages[@npage] = Page.new([@pages[@ipage].buffer.dup])
		@pages[@npage].buffer.window = @pages[@npage].buffer.window.dup
		@npage += 1
		@pages[@ipage].buffer.extramode = false
		@ipage = @npage - 1
		@pages[@ipage].buffer.extramode = false
		return(@pages[@ipage].buffer)
	end


	# put all buffers on the same page,
	# unlesss they already are => then spread them out
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

	# move buffer to page n
	def move_to_page(n)

		# adjust for zero indexing
		n -= 1

		# if same page, don't do anything
		if n == @ipage
			return
		end

		buf = @pages[@ipage].buffer

		# delete current buffer from current page
		@pages[@ipage].delete_buffer

		# if no buffers left on page,
		# then remove the page
		if @pages[@ipage].nbuf == 0
			@pages.delete_at(@ipage)
			if n >= @ipage
				n -= 1
			end
			@npage -= 1
			@ipage = 0
		end

		# put on new page
		if @npage > n
			@pages[n].add_buffer(buf)
		else
			@pages[@npage] = Page.new([buf])
			@npage += 1
		end

		@pages[@ipage].resize_buffers
		@pages[@ipage].refresh_buffers

		return(@pages[@ipage].buffer)

	end

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

# end of buffers list class
#----------------------------------------------------------











# -----------------------------------------------------------------
# This section defines the keymapping.
# There are 5 sections:
#     1. commandlist -- universal keymapping
#     2. editmode_commandlist -- keymappings when in edit mode
#     3. viewmode_commandlist -- keymappings in view mode
#     4. extra_commandlist -- ones that don't fit
#     5. togglelist -- for toggling states on/off
#     	 These get run when buffer.toggle is run.
# -----------------------------------------------------------------

class KeyMap

	attr_accessor :commandlist, :editmode_commandlist, \
	              :extramode_commandlist, :viewmode_commandlist, \
	              :togglelist

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
			:ctrl_z => "$screen.suspend(buffer)",
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
			"e" => "@editmode = true",
			"v" => "@editmode = false",
			"a" => "@autoindent = true",
			"n" => "@autoindent = false",
			"i" => "@insertmode = true",
			"o" => "@insertmode = false",
			"w" => "@linewrap = true",
			"l" => "@linewrap = false",
			"c" => "@cursormode = 'col'",
			"r" => "@cursormode = 'row'",
			"f" => "@cursormode = 'multi'",
			"s" => "@syntax_color = true",
			"b" => "@syntax_color = false",
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







# ----------------------------------------------------------
# This is a separate global function which runs an arbitrary
# ruby script.
# It can read from a file or from user input.
#
# It is global, because we want to be able to call it right
# at startup. That way a user can modify the editor's behavior
# before any buffers have been loaded.
# ----------------------------------------------------------
def run_script(file=nil)
	if file == nil
		file = $screen.ask("run script file: ",[""],false,true)
		if (file==nil) || (file=="")
			$screen.write_message("cancelled")
			return
		end
	end
	if File.directory?(file)
		list = Dir.glob(file+"/*.rb")
		list.each{|f|
			script = File.read(f)
			eval(script)
			if $screen != nil
				$screen.write_message("done")
			end
		}
	elsif File.exist?(file)
		script = File.read(file)
		eval(script)
		if $screen != nil
			$screen.write_message("done")
		end
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





# -------------------------------------------------------
# End of methods and classes definitions.
# -------------------------------------------------------






# -------------------------------------------------------
# Default configurations
# -------------------------------------------------------

# color escapes
$color = {
	:red   => "\e[31m",
	:green => "\e[32m",
	:blue => "\e[34m",
	:cyan => "\e[36m",
	:magenta => "\e[35m",
	:yellow => "\e[33m",
	:normal => "\e[0m",
	:reverse => "\e[7m",
}
$color[:comment] = $color[:cyan]
$color[:string] = $color[:yellow]
$color[:whitespace] = $color[:red]
$color[:hiddentext] = $color[:green]


# syntax color defaults
class SyntaxColors
	attr_accessor :filetypes, :lc, :bc, :regex
	def initialize
		@filetypes = {
			/\.sh$/ => "shell",
			/\.csh$/ => "shell",
			/\.rb$/ => "shell",
			/\.py$/ => "shell",
			/\.[cCh]$/ => "c",
			/\.cpp$/ => "c",
			"COMMIT_EDITMSG" => "shell",
			/\.m$/ => "m",
			/\.pro$/ => "idl",
			/\.[fF]$/ => "f"
		}
		@lc = {
			"shell" => ["#"],
			"ruby" => ["#"],
			"c" => ["//"],
			"f" => ["!",/^c/],
			"m" => ["#","%"],
			"idl" => [";"]
		}
		@lc.default = []
		@bc = {
			"c" => {"/*"=>"*/"},
		}
		@bc.default = {}
		@regex = {
			"f" => {/^[^cC][^!]{71,}.*$/=>:magenta}
		}
		@regex.default = {}
	end
end
$syntax_colors = SyntaxColors.new




$tabsize = 4
$tabchar = "\t"
$autoindent = true
$linewrap = false
$cursormode = 'row'
$syntax_color = true
$editmode = true

# -------------------------------------------------------
# end of default configuration
# -------------------------------------------------------








# -------------------------------------------------------
# Start of directly executed code
# -------------------------------------------------------


# define key mapping
$keymap = KeyMap.new


# parse the command line options
$hist_file = nil
optparse = OptionParser.new{|opts|
	opts.banner = "Usage: editor [options] file1 file2 ..."
	opts.on('-s', '--script FILE', 'Run this script at startup'){|file|
		run_script(file)
	}
	opts.on('-h', '--help', 'Display this screen'){
		puts opts
		exit
	}
	opts.on('-t', '--tabsize N', 'Set tabsize'){|n|
		$tabsize = n.to_i
	}
	opts.on('-T', '--tabchar c', 'Set tab character'){|c|
		$tabchar = c
	}
	opts.on('-a', '--autoindent', 'Turn on autoindent'){
		$autoindent = true
	}
	opts.on('-y', '--save-hist FILE', 'Save history in this file'){|file|
		$hist_file = file
	}
	opts.on('-n', '--noedit', 'Start in view mode'){
		$editmode = false
	}
	opts.on('-m', '--manualindent', 'Turn off autoindent'){
		$autoindent = false
	}
	opts.on('-w', '--linewrap', 'Turn on linewrap'){
		$linewrap = true
	}
	opts.on('-l', '--longlines', 'Turn off linewrap'){
		$linewrap = false
	}
	opts.on('-c', '--color', 'Turn on syntax coloring'){
		$syntax_color = true
	}
	opts.on('-b', '--nocolor', 'Turn off syntax coloring'){
		$syntax_color = false
	}
	opts.on('-v', '--version', 'Print version number'){
		puts $version
		exit
	}
}
optparse.parse!


# intitialize histories
$search_hist = []
$replace_hist = []
$lineno_hist = []
$command_hist = []
$script_hist = []
$startfolding_hist = []
$endfolding_hist = []

# start screen
$screen = Screen.new

# read specified files into buffers of buffer list
$buffers = BuffersList.new(ARGV)

# initialize copy buffer
$copy_buffer = ""

# for detecting changes to display,
# so we don't have to redraw as frequently
$screen_buffer = []

# catch screen resizes
trap("WINCH"){
	$screen.update_screen_size
	$buffers.update_screen_size
	$screen.write_message("resized")
}

# initialize curses screen and run with it
$screen.start_screen_loop do

	$buffers.current.dump_to_screen(true)

	# this is the main action loop
	loop do

		# make sure we are on the current buffer
		buffer = $buffers.current
		# reduce time proximity for cuts
		buffer.cutscore -= 1

		# take a snapshot of the buffer text,
		# for undo/redo purposes
		if buffer.buffer_history.text != buffer.text
			buffer.buffer_history.add(buffer.text,buffer.row,buffer.col)
		end

		# display the current buffer
		buffer.dump_to_screen

		# wait for a key press
		c = $screen.getch until c!=nil

		# process key press -- run associated command
		if buffer.extramode
			command = $keymap.extramode_command(c)
			eval($keymap.extramode_command(c))
			buffer.extramode = false if ! buffer.sticky_extramode
			$screen.write_message("")
		else
			command = $keymap.command(c,buffer.editmode)
			if command == nil
				buffer.addchar(c) if buffer.editmode && c.is_a?(String)
			else
				eval(command)
			end
		end

		# make sure cursor is in a good place
		buffer.sanitize

	end
	# end of main action loop

end
