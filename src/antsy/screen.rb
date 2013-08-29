#---------------------------------------------------------------------
# The Screen class manages the screen output and input.
# It sits in between the Terminal and the Windows.  Each window knows
# only about itself (position, width, etc).  The screen knows nothing
# about the buffers or windows; it only knows how to write and read
# from the terminal.  The Terminal class is the API for the terminal,
# which could be ANSI, curses, ncurses, etc.
#---------------------------------------------------------------------

class Screen

	attr_accessor :rows, :cols, :buffer, :color, :lastline

	def initialize

		@terminal = Terminal.new

		# get and store screen size
		update_screen_size

		# This is for detecting changes to the displayed text,
		# so we don't have to redraw as frequently.
		@buffer = []
		@lastline = @rows

		# Define screen-specific color codes.
		@color = @terminal.colors

		# Define status and message colors
		add_colors({:status=>:underline,:message=>:yellow})

		# Do this to prevent thread locking problems from printing.
		$stdout.sync = true

	end


	# Allow the addition of meta colors.  The terminal class
	# defines @terminal.colors to contain a mapping between raw
	# codes (e.g. \e[31m) and nice names (e.g. :red).  This method
	# allows a user to define meta mappings (e.g. from :comment to
	# :cyan).
	def add_colors(new_colors)
		new_colors.each{|k,v|
			@color[k] = ""
			[v].flatten.each{|c|
				@color[k] += @color[c] if @color[c]
			}
		}
		return @color
	end


	def set_cursor_color(color=nil)
		if color.nil?
			color = ask("color:")
		end
		return if color.nil? || color==""
		@terminal.set_cursor_color(color)
		write_message("set cursor to #{color}")
	end



	# Call to stty utility for screen size update, and set
	# @rows and @cols.
	def update_screen_size
		cols_old = @cols
		rows_old = @rows
		@rows,@cols = @terminal.get_screen_size
		@rows = [@rows.to_i-1,1].max
		@cols = @cols.to_i
		if cols_old!=@cols || rows_old!=@rows
			return true
		else
			return false
		end
	end

	# This starts the interactive session.
	# When this exits, return screen to normal.
	def start_screen
		@terminal.set_raw
		@nroll = @terminal.get_cursor_row
		@terminal.roll_screen_up(@nroll)
		@terminal.disable_linewrap
		begin
			yield
		ensure
			@terminal.unset_raw
			@terminal.cursor(0,0)
			@terminal.enable_linewrap
			@terminal.clear_screen
			@terminal.show_cursor
			@terminal.toggle_mouse(false)
		end
	end

	def suspend_screen
		@terminal.enable_linewrap
		@terminal.clear_screen
		@terminal.show_cursor
		@terminal.cursor(0,0)
		@terminal.unset_raw
	end

	def restart_screen
		@terminal.set_raw
		@nroll = @terminal.get_cursor_row
		@terminal.roll_screen_up(@nroll)
		@terminal.disable_linewrap
		update_screen_size
	end

	# Suspend the editor, and refresh on return.
	def suspend
		suspend_screen
		Process.kill("SIGSTOP",0)
		restart_screen
	end

	# Set cursor position.
	def setpos(row,col)
		@terminal.cursor(row+1,col+1)
	end

	# Write a string at the current cursor position.
	# This was more complex when using curses, but now is trivial.
	def addstr(text)
		@terminal.write(text)
	end

	# Write a string at a specified position.
	def write_string(row,col,text)
		setpos(row,col)
		addstr(text)
	end

	# Write a colored string at a specified position.
	def write_string_colored(row,col,text,color)
		setpos(row,col)
		addstr(@color[color]+text+@color[:normal])
	end

	# Clear an entrire line on the screen.
	def clear_line(row)
		setpos(row,0)
		@terminal.clear_line
	end
	def clear_message_text
		clear_line(@rows)
	end

	# Write to the bottom line (full with).
	# Typically used for asking the user a question.
	def write_bottom_line(str)
		write_string_colored(@rows,0," "*@cols,:message)
		write_string_colored(@rows,0,str.gsub(/	/,' '),:message)
	end

	# Write an entire line of text to the screen.
	# Handle horizontal shifts (colfeed), escape chars, and tab chars.
	def write_line(row,col,width,colfeed,line)

		# clear the line
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

		# Code is the text decoration code that would get chopped off;
		# but we want to save it.
		code = ""

		esc = @terminal.escape_regexp
		while colfeed > 0
			a,b,c = line.partition(esc)
			break if b.length == 0
			if a.length > colfeed
				line = line[colfeed..-1]
				break
			end
			line = c
			colfeed -= a.length
			code += b
		end

		k=width
		pline = ""
		while k > 0
			a,b,line = line.partition(esc)
			if a.length > k
				pline += a[0,k] + b
				break
			end
			pline += a + b
			k -= a.length
			break if b.length == 0
		end

		# Find escape sequences chopped off at end, as well.
		code2 = ""
		line.scan(esc){|e|
			code2 += e
		}

		write_string(row,col,code + pline + code2)

	end


	# Write the info line at top of screen (or elsewhere).
	#
	# lstr - left justifed text
	# rstr - right justified text
	# cstr - centered text
	# row - screen row
	# col - screen column
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
	def write_message(message)
		message = message.inspect unless message.is_a?(String)
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
					mline = hist[ih] if ih
				when :ctrl_r
					# get next match in reverse list
					next if ih == 0
					ih = hist[0..(ih-1)].rindex{|x|x.match(/#{token}/)}
				when :ctrl_c, :ctrl_g
					# 0 return value = cancelled search
					return 0
				when :enter,:ctrl_m,:ctrl_j, :up, :down, :left, :right
					return [0,hist.length-ih].max
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
	class AskHist
		def initialize(hist,last_answer)
			@hist = hist
			@idx = 0
			if last_answer && @hist.length > 0
				@idx = 1
			else
				@idx = 0
			end
		end
		def token(default='')
			if @idx == 0
				return(default)
			else
				token = @hist[-@idx]
				if token.nil?
					return(default)
				else
					return(@hist[-@idx].dup)
				end
			end
		end
		def scroll(n)
			if @hist.length == 0
				@idx = 0
			else
				@idx = [[@idx+n,0].max,@hist.length].min
			end
			return(token)
		end
		def reverse_i(parent)
			idx = parent.reverse_incremental(@hist)
			if idx != nil && idx > 0
				@idx = idx
			end
			return(token)
		end
		def add(token)
			if token != @hist[-1] && token != "" && token != nil
				@hist << token
			end
		end
	end
	def ask(question,hist=[],user_flags={})
		flags = {
			:display_last_answer=>false,
			:file=>false,
			:return_empty=>false
		}.merge(user_flags)

		ask_hist = AskHist.new(hist,flags[:display_last_answer])

		# remember typed string, even if we move away
		token = ask_hist.token
		token0 = token.dup

		# put cursor at end of string
		# Write questin and suggested answer
		col = token.length
		write_bottom_line(question + " " + token)
		shift = 0  # shift: in case we go past edge of screen
		idx = 0  # for tabbing through files

		# for file globbing
		glob = token.dup

		# interact with user
		loop do

			c = getch until c!=nil
			if c==:tab && flags[:file]
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
				case c

					# abort
					when :ctrl_c then return(nil)

					# allow for empty strings
					when :ctrl_n then return("")

					# cursor up scrolls through history
					when :up
						token = ask_hist.scroll(1)
						col = token.length
					when :down
						token = ask_hist.scroll(-1)
						col = token.length
					when :ctrl_r
						token = ask_hist.reverse_i(self)
						col = token.length
					when :left
						col = [col-1,0].max
					when :right
						col = [col+1,token.length].min
					when :ctrl_e
						col = token.length
					when :ctrl_a
						col = 0
					when :ctrl_u
						# cut to start-of-line
						token = token[col..-1]
						col = 0
					when :ctrl_k
						# cut to end-of-line
						token = token[0,col]
					when :ctrl_d
						# delete character at cursor
						if col < token.length
							token[col] = ""
						end
					when :ctrl_m, :enter, :ctrl_j
						break
					when :backspace, :backspace2, :ctrl_h
						if col > 0
							token[col-1] = ""
							col -= 1
						end
					when :tab
						# not a file, so insert literal tab character
						token.insert(col,"\t")
						col += 1
					else
						# regular character
						if c.is_a?(String)
							token.insert(col,c)
							col += 1
						end
				end
				glob = token.dup
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
		if token == "" && !flags[:return_empty]
			token = ask_hist.scroll(1)
		end
		ask_hist.add(token)
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
			return "cancel" if c == :ctrl_c
			return "all" if c == :ctrl_y
			next if c.is_a?(String) == false
			return "yes" if c.downcase == "y"
			return "no" if c.downcase == "n"
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

		choices = items.to_a

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
		write_message(header)
		idx = 0
		shift = 0
		while true

			# Shift choices if idx is off the screen.
			shift = idx-nr if idx-shift > nr
			shift = idx if idx < shift

			# Print the choices.
			s = choices[shift..(nr+shift)]
			s.each_index{|j|

				# Highlight the current selection.
				if j==idx-shift
					pre = @color[:reverse]
					post = @color[:normal]
				else
					pre = ""
					post = ""
				end

				# Write each choice.
				r = margin + j + 1
				write_string(r,margin+2,pre+' '*(cols-3))
				write_string(r,margin+2,s[j].join('  ')+post)
			}

			# Interact.
			c = getch({:hide_cursor=>true})
			case c
				when :up
					idx = [idx-1,0].max
				when :down
					idx = [idx+1,choices.length-1].min
				when :pagedown
					idx = [idx+nr/2,choices.length-1].min
				when :pageup
					idx = [idx-nr/2,0].max
				when '/'
					term = ask("Search:")
					idx = search_array(term,choices,idx) unless term.nil?
				when 'n'
					idx = search_array(term,choices,idx)
				when 'g'
					idx = 0
				when 'G'
					idx = choices.length-1
				when :enter,:ctrl_m,:ctrl_j
					break
				when :ctrl_c
					return([''])
			end
		end

		return(choices[idx])

	end


	# Search an array of choices for a term. Start at
	# idx and search to the end.  Then wrap back to the start
	# and search from start to idx.
	# Return nil if not found, otherwise return idx.
	def search_array(term,choices,idx)
		idx2 = search_array_from_idx(term,choices,idx)
		if idx2==idx
			idx = search_array_from_idx(term,choices,0)
		else
			idx = idx2
		end
		return idx
	end


	# Search for term in choices, but only looking from
	# idx on down.
	# Return nil if term is not found, otherwise return
	# the index it is found at.
	def search_array_from_idx(term,choices,idx)
		return if term.nil?
		choices[idx+1..-1].each_index{|k|
			if choices[idx+k+1].join(" ").index(term)
				idx = idx + k + 1
				break
				exit
			end
		}
		return(idx)
	end


	# pass-through to terminal class
	def method_missing(method,*args,&block)
		@terminal.send method, *args, &block
	end

end


# end of Screen class
#---------------------------------------------------------------------
