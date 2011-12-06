#!/usr/bin/ruby
require 'curses'

#
#	editor.rb
#
#	There are 3 classes:
#	Screen -- for reading and writing to the screen (Curses)
#	FileBuffer -- for holding and manipulating the text of a file
#	BufferList -- for managing multiple file buffers
#	BufferHistory -- for undo/redo
#



# -----------------------------------------------------------------
# This section defines some global constants.  Don't change these
# unless you know what you're doing.
# -----------------------------------------------------------------

# control & meta chracters -- the \C-a type thing seems to only
# sometimes work
$ctrl_space = 0
$ctrl_a = 1
$ctrl_b = 2
$ctrl_c = 3
$ctrl_d = 4
$ctrl_e = 5
$ctrl_f = 6
$ctrl_g = 7
$ctrl_h = 8
$ctrl_i = 9
$ctrl_j = 10
$ctrl_k = 11
$ctrl_l = 12
$ctrl_m = 10
$enter = 10
$ctrl_n = 14
$ctrl_o = 15
$ctrl_p = 16
$ctrl_q = 17
$ctrl_r = 18
$ctrl_s = 19
$ctrl_t = 20
$ctrl_u = 21
$ctrl_v = 22
$ctrl_w = 23
$ctrl_x = 24
$ctrl_y = 25
$ctrl_z = 26
$ctrl_3 = 27
$ctrl_4 = 28
$ctrl_5 = 29
$ctrl_6 = 30
$ctrl_7 = 31
$ctrl_8 = 127
$backspace = 127
$backspace2 = 263
$space = 32

# color escape
$color = "\300"
$white = "\301"
$red = "\302"
$green = "\303"
$blue = "\304"
$cyan = "\305"
$magenta = "\306"
$yellow = "\307"
$black = "\308"
$default = $white
# highlighting
$normal = "\310"
$reverse = "\311"








# -----------------------------------------------------------------
# This section defines the keymapping.
# There are 3 sections:
#     1. commandlist -- universal keymapping
#     2. editmode_commandlist -- keymappings when in edit mode
#     3. viewmode_commandlist -- keymappings in view mode
# -----------------------------------------------------------------


$commandlist = {
	$ctrl_q => "buffer = buffers.close; if buffer == nil then exit end",
	Curses::Key::UP => "buffer.cursor_up(1)",
	Curses::Key::DOWN => "buffer.cursor_down(1)",
	Curses::Key::RIGHT => "buffer.cursor_right",
	Curses::Key::LEFT => "buffer.cursor_left",
	Curses::Key::NPAGE => "buffer.cursor_down($rows-3)",
	Curses::Key::PPAGE => "buffer.cursor_up($rows-3)",
	$ctrl_v => "buffer.cursor_down($rows-3)",
	$ctrl_y => "buffer.cursor_up($rows-3)",
	$ctrl_e => "buffer.cursor_eol",
	$ctrl_a => "buffer.cursor_sol",
	$ctrl_n => "buffer = buffers.next",
	$ctrl_b => "buffer = buffers.prev",
	$ctrl_x => "buffer.mark",
	$ctrl_p => "buffer.copy",
	$ctrl_w => "buffer.search(0)",
	$ctrl_g => "buffer.goto_line",
	$ctrl_o => "buffer.save",
	$ctrl_f => "buffer = buffers.open",
	$ctrl_z => "$screen.suspend",
	$ctrl_6 => "buffer.toggle"
	#$ctrl_s => "buffer.mark_columns"
}
$editmode_commandlist = {
	Curses::Key::BACKSPACE => "buffer.backspace",
	$backspace => "buffer.backspace",
	$backspace2 => "buffer.backspace",
	8 => "buffer.backspace",
	$enter => "buffer.newline",
	$ctrl_k => "buffer.cut",
	$ctrl_u => "buffer.paste",
	$ctrl_m => "buffer.newline",
	$ctrl_j => "buffer.newline",
	$ctrl_d => "buffer.delete",
	$ctrl_r => "buffer.search_and_replace",
	$ctrl_t => "buffer.block_comment",
	$ctrl_l => "buffer.justify",
	$ctrl_i => "buffer.indent",
	9 => "buffer.indent",
	32..127 => "buffer.addchar(c)"
}
$viewmode_commandlist = {
	?q => "buffer = buffers.close; if buffer == nil then exit end",
	?k => "buffer.cursor_up(1)",
	?j => "buffer.cursor_down(1)",
	?l => "buffer.cursor_right",
	?h => "buffer.cursor_left",
	$space => "buffer.cursor_down($rows-3)",
	?b => "buffer.cursor_up($rows-3)",
	?. => "buffer = buffers.next",
	?, => "buffer = buffers.prev",
	?/ => "buffer.search(0)",
	?n => "buffer.search(1)",
	?N => "buffer.search(-1)",
	?g => "buffer.goto_line",
	?i => "buffer.toggle_editmode",
	?[ => "buffer.undo",
	?] => "buffer.redo",
	?K => "buffer.screen_up",
	?J => "buffer.screen_down",
	?H => "buffer.screen_left",
	?L => "buffer.screen_right"
}








#----------------------------------------------------------
# This class will manage the curses screen output
#----------------------------------------------------------

class Screen

	attr_accessor :rows, :cols

	def initialize
		Curses.raw
		Curses.noecho
	end

	def update_screen_size
		@cols = @screen.maxx
		@rows = @screen.maxy
	end

	# This starts the curses session.
	# When this exists, screen closes.
	def init_screen
		@screen = Curses.init_screen
		Curses.start_color
		Curses.stdscr.keypad(true)
		Curses.init_pair(Curses::COLOR_GREEN, Curses::COLOR_GREEN, Curses::COLOR_BLACK)
		Curses.init_pair(Curses::COLOR_RED, Curses::COLOR_RED, Curses::COLOR_BLACK)
		Curses.init_pair(Curses::COLOR_WHITE, Curses::COLOR_WHITE, Curses::COLOR_BLACK)
		Curses.init_pair(Curses::COLOR_CYAN, Curses::COLOR_CYAN, Curses::COLOR_BLACK)
		Curses.init_pair(Curses::COLOR_BLUE, Curses::COLOR_BLUE, Curses::COLOR_BLACK)
		Curses.init_pair(Curses::COLOR_YELLOW, Curses::COLOR_YELLOW, Curses::COLOR_BLACK)
		Curses.init_pair(Curses::COLOR_MAGENTA, Curses::COLOR_MAGENTA, Curses::COLOR_BLACK)
		begin
			yield
		ensure
			Curses.close_screen
		end
	end

	def suspend
		Curses.close_screen
		Process.kill("SIGSTOP",0)
		Curses.refresh
	end

	# write a string at a position
	def write_str(line,column,text)
		if text == nil
			return
		end
		Curses.setpos(line,column)
		Curses.addstr(text)
	end

	# ---------------------------------------------------
	# write a line of text
	# 1. split string at each color escape (\300)
	# 2. after each color escape is a color specifiyer (e.g. \301)
	# 3. remove color specifier and issue a set_color command
	# 4. don't print any characters before colfeed
	# ---------------------------------------------------
	def write_line(row,colfeed,line)
		if line == nil
			return
		end

		# split at color escape
		a = line.split($color)
		# don't do anything for empty rows
		if a[0] == nil
			return
		end
		pos = 0
		s = colfeed
		# start at edge of screen
		s = colfeed
		# write up to first color escape
		write_str(row,0,a[0][s,(@cols-pos)])
		pos += a[0].length
		a = a[1..-1]
		if a == nil
			return
		end
		# loop over remaining parts, and process colors
		color_stack = []
		a.each{|str|
			c = str[0].chr
			d = str[1..-1]
			color_stack.push(c)
			if c == $default
				color_stack.pop
				color_stack.pop
				c = color_stack[0]
				if c == nil then c = $white end
			end
			case c
				when $white then set_color(Curses::COLOR_WHITE)
				when $red then set_color(Curses::COLOR_RED)
				when $green then set_color(Curses::COLOR_GREEN)
				when $yellow then set_color(Curses::COLOR_YELLOW)
				when $blue then set_color(Curses::COLOR_BLUE)
				when $magenta then set_color(Curses::COLOR_MAGENTA)
				when $cyan then set_color(Curses::COLOR_CYAN)
				when $reverse then @screen.attron(Curses::A_REVERSE)
				when $normal then @screen.attroff(Curses::A_REVERSE)
			end
			s = 0
			c = pos - colfeed
			if pos < colfeed
				s = colfeed - pos
				c = 0
			end
			if d == nil
				next
			end
			write_str(row,c,d[s,(@cols-c)])
			pos += d.length
		}
	end

	def set_color(color)
		@screen.color_set(color)
	end

	# write the info line at top of screen
	def write_top_line(lstr,cstr,rstr)
		update_screen_size
		rstr = cstr + "  " + rstr
		ll = lstr.length
		lr = rstr.length
		if (ll+lr+3) > @cols
			xxx = @cols - lr - 8
			lstr = "..." + lstr[(-xxx)..-1]
		end
		ll = lstr.length
		lr = rstr.length
		xx = @cols - ll - lr
		all = lstr + (" "*xx) + rstr
		@screen.attron Curses::A_REVERSE
		write_str(0,0,all)
		@screen.attroff Curses::A_REVERSE
	end

	# toggle reverse text
	def text_reverse(val)
		if val
			@screen.attron Curses::A_REVERSE
		else
			@screen.attroff Curses::A_REVERSE
		end
	end

	# write a message at the bottom
	def write_message(message)
		update_screen_size
		xpos = (@cols - message.length)/2
		@screen.attroff Curses::A_REVERSE
		write_str(@rows-1,0," "*@cols)
		@screen.attron Curses::A_REVERSE
		write_str(@rows-1,xpos,message)
		@screen.attroff Curses::A_REVERSE
	end

	# get a string from the user, allowing for cancellation,
	# and weird character stuff
	def getstr(question,instring="")
		answer = instring.dup
		$screen.write_str(@rows-1,question.length,answer)
		loop do
			c = Curses.getch
			$screen.write_str(@rows-1,question.length," "*(answer.length))
			if c.is_a?(String) then c = c.unpack('C')[0] end
			case c
				when $ctrl_c
					answer=nil
					break
				when $ctrl_m then break
				when $ctrl_h, $backspace, $backspace2
					answer.chop!
				when 32..127
					answer += c.chr
				when /[a-zA-Z0-9]/ then answer += (c.unpack('C')[0])
				when /[`~!@\#$%^&*()-_=+]/ then answer += (c.unpack('C')[0])
				when /[\[\]{}|\\;':",.<>\/?]/ then answer += (c.unpack('C')[0])
			end
			$screen.write_str(@rows-1,question.length,answer)
		end
		return(answer)
	end

	# get the name of a file, allowing for tab completion
	def getstr_file(ll)
		answer=""
		glob=answer
		idx = 0
		loop do
			c = Curses.getch
			if c.is_a?(String) then c = c.unpack('C')[0] end
			case c
				when $ctrl_c
					answer=nil
					break
				when $ctrl_m then break
				when $ctrl_h, $backspace, 263
					answer.chop!
					glob = answer
				when 32..127
					answer += c.chr
					glob = answer
				when ?\t, $ctrl_i
					# circulate through possible file matches
					list = Dir.glob(glob+"*")
					if list.length == 0
						next
					end
					idx = idx.modulo(list.length)
					answer = list[idx]
					idx += 1
			end
			write_str(@rows-1,ll," "*(@cols-ll))
			write_str(@rows-1,ll,answer)
		end
		return(answer)
	end

	# ask a question of the user
	def ask(question,answer="")
		update_screen_size
		@screen.attron Curses::A_REVERSE
		write_str(@rows-1,0," "*@cols)
		write_str(@rows-1,0,question)
		answer = getstr(question,answer)
		@screen.attroff Curses::A_REVERSE
		return(answer)
	end

	# ask for a file to open
	def ask_for_file(question)
		update_screen_size
		@screen.attron Curses::A_REVERSE
		write_str(@rows-1,0," "*@cols)
		write_str(@rows-1,0,question)
		answer = getstr_file(question.length)
		@screen.attroff Curses::A_REVERSE
		return(answer)
	end


	# ask for a string, allowing for choosing from past values
	# Used for search/replace.
	def askhist(question,hist)
		update_screen_size
		@screen.attron Curses::A_REVERSE
		write_str(@rows-1,0," "*@cols)
		ih = 0
		write_str(@rows-1,0,question+" ["+hist[-1]+"]: ")
		token = ""
		loop do
			c = Curses.getch
			if c.is_a?(String) then c = c.unpack('C')[0] end
			case c
				when $ctrl_c then return(nil)
				when Curses::Key::UP
					ih += 1
					if ih >= hist.length
						ih = hist.length-1
					end
					token = hist[-ih]
				when Curses::Key::DOWN
					ih -= 1
					if ih < 1
						ih = 1
					end
					token = hist[-ih].dup
				when $ctrl_m, Curses::Key::ENTER then break
				when 9..127
					token += c.chr
				when Curses::Key::BACKSPACE, $backspace, $backspace2, 8
					token.chop!
			end
			write_str(@rows-1,0," "*$cols)
			write_str(@rows-1,0,question+" ["+hist[-1]+"]: "+token)
		end
		@screen.attroff Curses::A_REVERSE
		if token == ""
			token = hist[-1].dup
		end
		if token != hist[-1]
			hist << token
		end
		return(token)
	end


	# ask a yes or no question
	def ask_yesno(question)
		update_screen_size
		@screen.attron Curses::A_REVERSE
		write_str(@rows-1,0," "*@cols)
		write_str(@rows-1,0,question)
		answer = "cancel"
		loop do
			c = Curses.getch
			if c.chr.downcase == "y"
				answer = "yes"
				break
			end
			if c.chr.downcase == "n"
				answer = "no"
				break
			end
			if c == $ctrl_c
				answer = "cancel"
				break
			end
		end
		@screen.attroff Curses::A_REVERSE
		return answer
	end


end



#----------------------------------------------------------



#
# This is the big main class, which handles a file
# buffer.  Does everything from screen dumps to
# searching etc.
#
class FileBuffer

	attr_accessor :filename, :text, :status, :editmode, :buffer_history

	def initialize(filename)
		@tabsize = 2
		@filename = filename
		@status = ""
		read_file
		# position of cursor in buffer
		@row = 0
		@col = 0
		# position of cursor on screen
		@cursrow = 0
		@curscol = 0
		# shifts of the buffer
		@linefeed = 0
		@colfeed = 0
		# where we are in the linear file text buffer
		@filepos = 0
		# remember if file was CRLF
		@eol = "\n"
		# copy,cut,paste stuff
		@marked = false
		@cutrow = -2
		@mark_col = 0
		@mark_row = 0
		# flags
		@autoindent = true
		@editmode = true
		@insertmode = true
		@linewrap = false
		@colmode = false
		# undo-redo history
		@buffer_history = BufferHistory.new(@text)
		# file type for syntax coloring
		get_filetype(@filename)
	end


	# get the file type from the extension
	def get_filetype(filename)
		extension = filename.split(".")[-1]
		case extension
			when "sh","csh" then @filetype = "shell"
			when "c","cpp","cc","C" then @filetype = "c"
			when "f","F","fort" then @filetype = "f"
			when "m" then @filetype = "m"
			when "rb" then @filetype = "ruby"
			else @filetype = ""
		end
	end


	# toggle one of many states
	def toggle
		$screen.write_message("ed,vu,auto,man,ins,ovrw,wrap,long,col,row")
		c = Curses.getch
		case c
			when ?e
				@editmode = true
				$screen.write_message("Edit mode")
			when ?v
				@editmode = false
				$screen.write_message("View mode")
			when ?a
				@autoindent = true
				$screen.write_message("Autoindent")
			when ?m
				@autoindent = false
				$screen.write_message("Manual indent")
			when ?i
				@insertmode = true
				$screen.write_message("Insert mode")
			when ?o
				@insertmode = false
				$screen.write_message("Overwrite mode")
			when ?w
				@linewrap = true
				$screen.write_message("Line wrapping")
			when ?l
				@linewrap = false
				$screen.write_message("No line wrapping")
			when ?c
				@colmode = true
				$screen.write_message("Column mode")
			when ?r
				@colmode = false
				$screen.write_message("Row mode")
		end
	end

	def toggle_editmode
		@editmode = true
		$screen.write_message("Edit mode")
	end


	# read into buffer array
	# Called by initialize -- shouldn't need to call
	# this directly
	def read_file
		if @filename == ""
			@text = [""]
			return
		else
			if File.exists? @filename
				text = IO.read(@filename)
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

	def save
		ans = $screen.ask("save to: ",@filename)
		if ans == nil
			$screen.write_message("Cancelled")
			return
		end
		if ans == "" then ans = @filename end
		if ans != @filename
			yn = $screen.ask_yesno("save to different file: "+ans+" ? [y/n]")
			if yn == "yes"
				@filename = ans
				@filetype = get_filetype(@filename)
			else
				$screen.write_message("aborted")
				return
			end
		end
		File.open(@filename,"w"){|file|
			text = @text.join(@eol)
			file.write(text)
		}
		@status = ""
		$screen.write_message("saved to: "+@filename)
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
			@col = @text[@row].length - 1
		end
	end





	#
	# Modifying text
	#

	# these are the functions which do the mods
	# Everything else calls these

	# delete a character
	def delchar(row,col)
		if col == @text[row].length
			mergerows(row,row+1)
		else
			@text[row] = @text[row].dup
			@text[row][col] = ""
		end
		@status = "Modified"
	end
	# insert a character
	def insertchar(row,col,c)
		@text[row] = @text[row].dup
		if @insertmode || col == @text[row].length
			@text[row].insert(col,c)
		else
			@text[row][col] = c
		end
		@status = "Modified"
	end
	# delete a row
	def delrow(row)
		@text.delete_at(row)
		@status = "Modified"
	end
	# merge two consecutive rows
	def mergerows(row1,row2)
		if row2 >= @text.length
			return
		end
		col = @text[row1].length
		@text[row1] = @text[row1].dup
		@text[row1] += @text[row2]
		@text.delete_at(row2)
		@status = "Modified"
	end
	# split a row into two
	def splitrow(row,col)
		text = @text[row].dup
		@text[row] = text[(col)..-1]
		insertrow(row,text[0..(col-1)])
		@status = "Modified"
	end
	# new row
	def insertrow(row,text)
		@text.insert(row,text)
		@status = "Modified"
	end
	# completely change a row's text
	def setrow(row,text)
		old = @text[row]
		@text[row] = text
		@status = "Modified"
	end
	# add to the end of a line
	def append(row,text)
		@text[row] = @text[row].dup
		@text[row] += text
		@status = "Modified"
	end
	# insert a string
	def insert(row,col,text)
		@text[row] = @text[row].dup
		@text[row].insert(col,text)
		@status = "Modified"
	end
	# backspace a column of text
	def column_backspace(row1,row2)
		sc = bc2sc(@row,@col)
		for r in row1..row2
			c = sc2bc(r,sc)
			if c<=0 then next end
			@text[r] = @text[r].dup
			@text[r][c-1] = ""
		end
		cursor_left
		@status = "Modified"
	end
	# indent a block of text
	def block_indent(row1,row2)
		for r in row1..row2
			if @text[r].length > 0
				@text[r] = @text[r].dup
				@text[r].insert(0,"\t")
			end
		end
		@status = "Modified"
	end
	# unindent a block of text
	def block_unindent(row1,row2)
		for r in row1..row2
			if @text[r].length == 0
				next
			end
			t = @text[r][0].chr
			if t != "\t"
				block_unspace(row1,row2)
				return
			end
		end
		for r in row1..row2
			if @text[r][0] != nil
				@text[r] = @text[r].dup
				@text[r][0] = ""
			end
		end
		@status = "Modified"
	end
	# same as above, but if spaces are used
	def block_unspace(row1,row2)
		for r in row1..row2
			if @text[r].length == 0
				next
			end
			s = @text[r][0].chr
			if s != " "
				block_uncomment(row1,row2)
				return
			end
		end
		for r in row1..row2
			if @text[r][0] != nil
				@text[r] = @text[r].dup
				@text[r][0] = ""
			end
		end
		@status = "Modified"
	end
	# uncomment a block
	def block_uncomment(row1,row2)
		c = ""
		case @filetype
			when "shell","m","ruby" then c = "#"
			when "c" then c = "//"
			when "f" then c = "!"
		end
		for r in row1..row2
			if @text[r].length == 0
				next
			end
			s = @text[r][0].chr
			if s != c
				return
			end
		end
		for r in row1..row2
			if @text[r][0] != nil
				@text[r] = @text[r].dup
				@text[r][0] = ""
			end
		end
		@status = "Modified"
	end


	#
	# Undo / redo
	#
	def undo
		if @buffer_history.prev != nil
			@buffer_history.tree = @buffer_history.prev
			@text = @buffer_history.copy(@text)
			@col = 0
			@row = row_changed(@text,@buffer_history.next.text,@row)
		end
	end
	def redo
		if @buffer_history.next != nil
			@buffer_history.tree = @buffer_history.next
			@text = @buffer_history.copy(@text)
			@col = 0
			@row = row_changed(@text,@buffer_history.prev.text,@row)
		end
	end
	def row_changed(text1,text2,r)
		n = [text1.length,text2.length].min
		text1.each_index{|i|
			if i >= n then break end
			if text1[i] != text2[i]
				return(i)
			end
		}
		return(r)
	end



	# these functions all call the mod function
	# but don't modify the buffer directly

	# delete a character
	def delete
		delchar(@row,@col)
	end
	# backspace over a character
	def backspace
		if @marked
			if @row < @mark_row
				row = @mark_row
				mark_row = @row
			else
				row = @row
				mark_row = @mark_row
			end
			if @colmode
				column_backspace(mark_row,row)
			else
				block_unindent(mark_row,row)
			end
			return
		end
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
	# indent a line or block of text
	def indent
		if @marked
			if @row < @mark_row
				row = @mark_row
				mark_row = @row
			else
				row = @row
				mark_row = @mark_row
			end
			block_indent(mark_row,row)
		else
			addchar(?\t)
		end
	end
	# comment a block of text
	def block_comment
		if @marked == false
			return
		end
		if @row < @mark_row
			row = @mark_row
			mark_row = @row
		else
			row = @row
			mark_row = @mark_row
		end
		s = $screen.ask("Indent string: ")
		if s == nil then
			$screen.write_message("Cancelled")
			return
		end
		if s == ""
			case @filetype
				when "shell","m","ruby" then s = "#"
				when "c" then s = "//"
				when "f" then s = "!"
			end
		end
		for r in mark_row..row
			if (@text[r].length == 0)&&(s=~/^\s*$/)
				next
			end
			if @colmode
				sc = bc2sc(@row,@col)
				c = sc2bc(r,sc)
				if(c>=@text[r].length) then next end
				insertchar(r,c,s)
			else
				insertchar(r,0,s)
			end
		end
		$screen.write_message("done")
	end
	# insert a char and move to the right
	def addchar(c)
		insertchar(@row,@col,c.chr)
		cursor_right
	end
	# add a line-break
	def newline
		if @col == 0
			insertrow(@row,"")
			cursor_down(1)
		else
			splitrow(@row,@col)
			ws = ""
			if @autoindent
				case @filetype
					when "shell","m","ruby"
						ws = @text[@row].match(/^[\s#]*/)[0]
					when "f"
						ws = @text[@row].match(/^c?[\s!&]*/)[0]
					when "c"
						ws = @text[@row].match(/^[\s\/*]*/)[0]
					else
						ws = @text[@row].match(/^\s*/)[0]
				end
				insertchar(@row+1,0,ws)
			end
			@col = ws.length
			@row += 1
		end
	end

	# justify a block of text
	def justify

		# ask for screen width
		# nil means cancel, empty means screen width
		ans = $screen.ask("Justify width: ",$screen.cols.to_s)
		if ans == nil
			$screen.write_message("Cancelled")
			return
		end
		if ans == ""
			cols = $screen.cols
		else
			cols = ans.to_i
		end

		# set start & end rows
		if @marked
			if @row < @mark_row
				row = @mark_row
				mark_row = @row
			else
				row = @row
				mark_row = @mark_row
			end
		else
			row = @row
			mark_row = @row
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
		$screen.write_message("Justified to "+cols.to_s+" columns")
		@marked = false
		@row = r
		@col = 0
	end


	#
	# Navigation stuff
	#

	def cursor_right
		@col += 1
		if @col > @text[@row].length
			if @row < (@text.length-1)
				@col = 0
				@row += 1
			else
				@col -= 1
			end
		end
	end
	def cursor_left
		@col -= 1
		if @col < 0
			if @row > 0
				@col = @text[@row-1].length
				@row -= 1
			else
				@col = 0
			end
		end
	end
	def cursor_eol
		@col = @text[@row].length
	end
	def cursor_sol
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
	def goto_line
		num = $screen.ask("go to line: ")
		if num == nil
			$screen.write_message("Cancelled")
			return
		end
		@row = num.to_i
		@col = 0
		if @row > @text.length
			@row = @text.length
		end
		$screen.write_message("went to line "+@row.to_s)
	end
	def screen_left
		@colfeed += 1
	end
	def screen_right
		@colfeed = [0,@colfeed-1].max
	end
	def screen_up
		@linefeed = [0,@linefeed-1].max
	end
	def screen_down
		@linefeed += 1
	end


	#
	# search
	#
	def search(p)
		if p == 0
			# get search string from user
			token = $screen.askhist("Search",$search_hist)
		elsif
			token = $search_hist[-1]
		end
		if token == nil || token == ""
			$screen.write_message("Cancelled")
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
			idx = @text[row].index(token,@col+1)
			while(idx==nil)
				row = (row+1).modulo(nlines)  # next line
				if row == @row  # stop if we wrap back around
					$screen.write_message("No matches")
					return
				end
				idx = @text[row].index(token)
			end
		else
			if @col > 0
				idx = @text[row].rindex(token,@col-1)
			else
				idx = nil
			end
			while(idx==nil)
				row = (row-1)
				if row < 0 then row = nlines-1 end
				if row == @row
					$screen.write_message("No matches")
					return
				end
				idx = @text[row].rindex(token)
			end
		end
		$screen.write_message("Found match")
		@row = row
		@col = idx
	end
	def search_and_replace
		# get search string from user
		token = $screen.askhist("Search:",$search_hist)
		if token == nil
			$screen.write_message("Cancelled")
			return
		end
		# is it a regexp
		if token.match(/^\/.*\/$/) != nil
			token = eval(token)
		end
		# get replace string from user
		replacement = $screen.askhist("Replace:",$replace_hist)
		if replacement == nil
			$screen.write_message("Cancelled")
			return
		end
		row = @row
		col = @col
		sr = @row
		sc = @col
		loop do
			nlines = @text.length
			idx = @text[row].index(token,col)
			while(idx!=nil)
				str = @text[row][idx..-1].match(token)[0]
				@row = row
				@col = idx
				dump_to_screen($screen)
				highlight(row,idx,idx+str.length-1)
				yn = $screen.ask_yesno("Replace this occurance?")
				l = str.length
				if yn == "yes"
					temp = @text[row].dup
					@text[row] = temp[0,idx]+replacement+temp[(idx+l)..-1]
					@status = "Modified"
					col = idx+replacement.length
				elsif yn == "cancel"
					$screen.write_message("Cancelled")
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
		$screen.write_message("No more matches")
	end


	#
	# copy/paste
	#
	def mark
		if @marked
			@marked = false
			$screen.write_message("Unmarked")
			return
		end
		@marked = true
		$screen.write_message("Marked")
		@mark_col = @col
		@mark_row = @row
	end
	def cut
		if @marked
			# single line stuff
			@marked = false
			if @row == @mark_row
				# single row
				if @col < @mark_col
					temp = @col
					@col = @mark_col
					@mark_col = temp
				end
				$screen.write_message(@mark_col.to_s+" "+@col.to_s)
				$copy_buffer = @text[@row][@mark_col..@col]
				if @col >= @text[@row].length
					@col -= 1
				end
				setrow(@row,@text[@row][0..@mark_col].chop+@text[@row][(@col+1)..-1])
				@col = @mark_col
			else
				# multiple rows
				if @row < @mark_row
					temp = @row
					@row = @mark_row
					@mark_row = temp
					temp = @col
					@col = @mark_col
					@mark_col = temp
				end
				$copy_buffer = @text[@mark_row][@mark_col..-1] + "\n"
				setrow(@mark_row,@text[@mark_row][0..@mark_col].chop)
				row = @mark_row + 1
				while row < @row
					$copy_buffer += @text[@mark_row+1] + "\n"
					delrow(@mark_row+1)
					row += 1
				end
				if @col >= @text[@mark_row+1].length
					@col -= 1
				end
				$copy_buffer += @text[@mark_row+1][0..@col]
				append(@mark_row,@text[@mark_row+1][(@col+1)..-1])
				delrow(@mark_row+1)
				@row = @mark_row
				@col = @mark_col
				if @col > @text[@row].length
					@col = @text[@row].length
				end
			end
		else
			# unmarked text (check for consecutive lines)
			if @row == (@cutrow)
				$copy_buffer += @text[@row] + "\n"
			else
				$copy_buffer = @text[@row] + "\n"
			end
			@cutrow = @row
			delrow(@row)
			@col = 0
		end
	end
	# same as cut, but no cutting
	def copy
		if @marked
			@marked = false
			# single line stuff
			if @row == @mark_row
				if @col < @mark_col
					temp = @col
					@col = @mark_col
					@mark_col = temp
				end
				$copy_buffer = @text[@row][@mark_col..@col]
			else
				if @row < @mark_row
					temp = @row
					@row = @mark_row
					@mark_row = temp
				end
				$copy_buffer = @text[@mark_row][@mark_col..-1] + "\n"
				row = @mark_row + 1
				while row < @row
					$copy_buffer += @text[row] + "\n"
					row += 1
				end
				$copy_buffer += @text[row][0..@col]
			end
		else
			if @row == (@cutrow+1)
				$copy_buffer += @text[@row] + "\n"
			else
				$copy_buffer = @text[@row] + "\n"
			end
			@cutrow = @row
			@row += 1
			@col = 0
			if @row >= @text.length
				@row -= 1
			end
		end
	end
	def paste
		insert(@row,@col,$copy_buffer)
		@cutrow = -2
		n = @text[@row].count("\n")
		temp = @text[@row].split("\n")
		if temp[0] == nil
			temp[0] = ""
		end
		setrow(@row,temp[0])
		temp[1..-1].each{|line|
			@row += 1
			insertrow(@row,line)
		}
		while n >= temp.length
			@row += 1
			n -= 1
			insertrow(@row,"")
		end
		if n > 0
			@col = 0
		end
	end





	#
	# display text
	#

	# write everything, including status lines
	def dump_to_screen(screen)
		# get cursor position
		ypos = @row - @linefeed
		if ypos < 0
			@linefeed += ypos
			ypos = 0
		elsif ypos >= screen.rows - 3
			@linefeed += ypos + 3 - screen.rows
			ypos = screen.rows - 3
		end
		@cursrow = ypos+1
		@curscol = bc2sc(@row,@col) - @colfeed
		if @curscol > (screen.cols-1)
			@colfeed += @curscol - screen.cols + 1
			@curscol = screen.cols - 1
		end
		if @curscol < 0
			@colfeed += @curscol
			@curscol = 0
		end
		# report on cursor position
		r = (@linefeed+@cursrow-1)
		c = (@colfeed+@curscol)
		r0 = @text.length - 1
		position = r.to_s + "," + c.to_s + "/" + r0.to_s
		if @editmode
			status = @status
		else
			status = @status + "  VIEW"
		end
		screen.write_top_line(@filename,position,status)
		# write the text to the screen
		dump_text(screen)
		# set cursor position
		Curses.setpos(@cursrow,@curscol)
	end
	#
	# just dump the buffer text to the screen
	#
	def dump_text(screen)
		# get only the rows of interest
		text = @text[@linefeed,screen.rows-2]
		# clear screen
		for ir in 1..(screen.rows-2)
			screen.write_str(ir,0," "*screen.cols)
		end
		#write out the text
		ir = 0
		text.each { |line|
			ir += 1
			sline = tabs2spaces(line)
			aline = syntax_color(sline)
			screen.write_line(ir,@colfeed,aline)
		}
		# vi-style blank lines
		ir+=1
		while ir < (screen.rows-1)
			screen.write_str(ir,0,"~"+" "*(screen.cols-1))
			ir += 1
		end
		# now go back and do marked text highlighting
		if @marked
			if @row == @mark_row
				if @col < @mark_col
					col = @mark_col
					mark_col = @col
				else
					col = @col
					mark_col = @mark_col
				end
				if @colmode == false
					highlight(@row,mark_col,col)
				end
			else
				if @row < @mark_row
					row = @mark_row
					mark_row = @row
					col = @mark_col
					mark_col = @col
				else
					row = @row
					mark_row = @mark_row
					col = @col
					mark_col = @mark_col
				end
				if @colmode
					sc = bc2sc(@row,@col)
					for r in mark_row..row
						c = sc2bc(r,sc)
						highlight(r,c,c)
					end
				else
					sl = @text[mark_row].length-1
					highlight(mark_row,mark_col,sl)
					for r in (mark_row+1)..(row-1)
						sl = @text[r].length-1
						highlight(r,0,sl)
					end
					highlight(row,0,col)
				end
			end
		end
	end

	# highlight a particular row, from scol to ecol
	# scol & ecol are columns in the text buffer
	def highlight(row,scol,ecol)
		# only do rows that are on the screen
		if row < @linefeed then return end
		if row > (@linefeed + $screen.rows - 2) then return end

		if @text[row].length < 1 then return end

		# convert pos in text to pos on screen
		sc = bc2sc(row,scol)
		ec = bc2sc(row,ecol)

		# replace tabs with spaces
		sline = tabs2spaces(@text[row])
		# get just string of interest
		if sc < @colfeed then sc = @colfeed end
		if ec < @colfeed then return end
		str = sline[sc..ec]
		ssc = sc - @colfeed
		sec = ec - @colfeed

		if (str.length+ssc) >=$screen.cols
			str = str[0,($screen.cols-ssc)]
		end

		$screen.text_reverse(true)
		$screen.write_str((row-@linefeed+1),ssc,str)
		$screen.text_reverse(false)
	end

	def syntax_color(sline)
		aline = sline.dup
		# trailing whitespace
		aline.gsub!(/\s+$/,$color+$red+$color+$reverse+"\\0"+$color+$normal+$color+$default)
		case @filetype
			when "shell","ruby"
				aline.gsub!(/['][^']*[']/,$color+$yellow+"\\0"+$color+$default)
				aline.gsub!(/["][^"]*["]/,$color+$yellow+"\\0"+$color+$default)
				aline.gsub!(/\#.*$/,$color+$cyan+"\\0"+$color+$default)
			when "m"
				aline.gsub!(/['][^']*[']/,$color+$yellow+"\\0"+$color+$default)
				aline.gsub!(/["][^"]*["]/,$color+$yellow+"\\0"+$color+$default)
				aline.gsub!(/\#.*$/,$color+$cyan+"\\0"+$color+$default)
				aline.gsub!(/\%.*$/,$color+$cyan+"\\0"+$color+$default)
			when "f"
				aline.gsub!(/['][^']*[']/,$color+$yellow+"\\0"+$color+$default)
				aline.gsub!(/["][^"]*["]/,$color+$yellow+"\\0"+$color+$default)
				aline.gsub!(/^c.*$/,$color+$cyan+"\\0"+$color+$default)
				aline.gsub!(/!.*$/,$color+$cyan+"\\0"+$color+$default)
			when "c"
				aline.gsub!(/['][^']*[']/,$color+$yellow+"\\0"+$color+$default)
				aline.gsub!(/["][^"]*["]/,$color+$yellow+"\\0"+$color+$default)
				# // style comments
				aline.gsub!(/\/\/.*$/,$color+$cyan+"\\0"+$color+$default)
				# /* comment */
				aline.gsub!(/\/\*.*\*\//,$color+$cyan+"\\0"+$color+$default)
				# /* comment
				aline.gsub!(/\/\*(?:(?!\*\/).)*$/,$color+$cyan+"\\0"+$color+$default)
				# comment */
				aline.gsub!(/^(?:(?!\/\*).)*\*\//,$color+$cyan+"\\0"+$color+$default)
			else
				aline.gsub!(/['][^']*[']/,$color+$yellow+"\\0"+$color+$default)
				aline.gsub!(/["][^"]*["]/,$color+$yellow+"\\0"+$color+$default)
		end
		return(aline)
	end

	# functions for converting from column position in buffer
	# to column position on screen
	def bc2sc(row,col)
		if @text[row] == nil
			return(0)
		end
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
		if line == nil then return(nil) end
		if line.length == 0 then return(line) end
		a = line.split("\t",-1)
		ans = a[0]
		a = a[1..-1]
		if a == nil then return(ans) end
		a.each{|str|
			n = ans.length
			m = @tabsize - (n+@tabsize).modulo(@tabsize)
			ans += " "*m + str
		}
		return(ans)
	end

end






#
# Linked list of buffer text states
# for undo/redo
#
class BufferHistory
	attr_accessor :tree
	def initialize(text)
		@tree = Node.new(text)
		@tree.next = nil
		@tree.prev = nil
	end
	class Node
		attr_accessor :next, :prev, :text
		def initialize(text)
			@text = []
			for k in 0..(text.length-1)
				@text[k] = text[k]
			end
		end
		def delete
			@text = nil
			if @next != nil then @next.prev = @prev end
			if @prev != nil then @prev.next = @next end
		end
	end
	def add(text)
		old = @tree
		@tree = Node.new(text)
		@tree.next = old.next
		if old.next != nil
			old.next.prev = @tree
		end
		@tree.prev = old
		old.next = @tree
		# prune the tree, so it doesn't get too big
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
			x = x.prev
			x.next.delete
		end
	end
	def text
		@tree.text
	end
	def copy(atext)
		atext = []
		for k in 0..(@tree.text.length-1)
			atext[k] = @tree.text[k]
		end
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
end





#
# this is a list of buffers
#
class BuffersList

	attr_accessor :copy_buffer

	# Read in all input files into buffers.
	# One buffer for each file.
	def initialize(files)
		@buffers = []
		@nbuf = 0
		@ibuf = 0
		@copy_buffer = ""
		for filename in files
			@buffers[@nbuf] = FileBuffer.new(filename)
			@nbuf += 1
		end
		if @nbuf == 0
			@buffers[@nbuf] = FileBuffer.new("")
			@nbuf += 1
		end
	end

	# return next, previous, or current buffer
	def next
		@ibuf = (@ibuf+1).modulo(@nbuf)
		@buffers[@ibuf]
	end
	def prev
		@ibuf = (@ibuf-1).modulo(@nbuf)
		@buffers[@ibuf]
	end
	def current
		@buffers[@ibuf]
	end

	# close a buffer
	def close
		if @buffers[@ibuf].status != ""
			ys = $screen.ask_yesno("Save changes?")
			if ys == "yes"
				@buffers[@ibuf].save
			elsif ys == "cancel"
				$screen.write_message("Cancelled")
				return(@buffers[@ibuf])
			end
		end
		@buffers.delete_at(@ibuf)
		@nbuf -= 1
		@ibuf = 0
		$screen.write_message("")
		@buffers[0]
	end

	def open
		ans = $screen.ask_for_file("open file: ")
		if (ans==nil) || (ans == "")
			$screen.write_message("cancelled")
			return(@buffers[@ibuf])
		end
		@buffers[@nbuf] = FileBuffer.new(ans)
		@nbuf += 1
		@ibuf = @nbuf-1
		$screen.write_message("Opened file: "+ans)
		return(@buffers[@ibuf])
	end

end



#----------------------------------------------------------



# -------------- main code ----------------


# read specified files into buffers of buffer list
buffers = BuffersList.new(ARGV)

# store up search history
$search_hist = [""]
$replace_hist = [""]

# copy buffer
$copy_buffer = ""


# create the case statement from list of keybindings
$case_then = "case c\n"
$commandlist.each{|key|
	$case_then += "when "+key[0].to_s+" then "+key[1]+"\n"
}
$case_then += "end\n"
$case_then += "if buffer.editmode\n"
$case_then += "case c\n"
$editmode_commandlist.each{|key|
	$case_then += "when "+key[0].to_s+" then "+key[1]+"\n"
}
$case_then += "end\n"
$case_then += "else\n"
$case_then += "case c\n"
$viewmode_commandlist.each{|key|
	if key[0].is_a?(String) then key[0] = key[0].unpack('C')[0] end
	$case_then += "when "+key[0].to_s+" then "+key[1]+"\n"
}
$case_then += "end\n"
$case_then += "end\n"




# initialize curses screen and run with it
$screen = Screen.new
$screen.init_screen do

	# this is the main action loop
	loop do

		# allow for resizes
		$screen.update_screen_size
		$cols = $screen.cols
		$rows = $screen.rows

		# display the current buffer
		buffer = buffers.current
		buffer.dump_to_screen($screen)

		# take a snapshot of the buffer text,
		# for undo/redo purposes
		if buffer.buffer_history.text != buffer.text
			buffer.buffer_history.add(buffer.text)
		end

		# wait for a key press
		c = Curses.getch
		if c.is_a?(String) then c = c.unpack('C')[0] end

		# execute case statement
		eval $case_then

		buffer.sanitize

	end
	# end of main action loop

end
