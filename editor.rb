#!/usr/bin/ruby

require 'curses'


def write_str(line, column, text)
	Curses.setpos(line,column)
	Curses.addstr(text)
end

def write_top_line(lstr,cstr,rstr)
	ll = lstr.length
	lc = cstr.length
	lr = rstr.length
	x1 = (($cols/2)-lc).floor
	lllc = lstr + (" "*x1) + cstr
	x2 = $cols - lllc.length - lr
	all = lllc + (" "*x2) + rstr
	$screen.attron Curses::A_REVERSE
	write_str(0,0,all)
	$screen.attroff Curses::A_REVERSE
end

def init_screen
	Curses.noecho
	$screen = Curses.init_screen
	Curses.stdscr.keypad(true)
	begin
		yield
	ensure
		Curses.close_screen
	end
end



class FileBuffer
	attr_accessor :filename, :text
	def initialize(filename)
		@filename = filename
		@status = ""
		read_file
		@cursor_row = 1
		@cursor_col = 0
		@linefeed = 0
		@colfeed = 0
		@filepos = 0
	end
	def read_file
		@text = IO.read(@filename)
		if @text[-1,1] =~ /\n/
		else
			@text = @text + "\n"
		end
	end
	def dump_to_screen
		write_top_line("editor",@filename,@status)
		dump_text
		Curses.setpos(@cursor_row,@cursor_col)
	end
	def cursor_right
		@cursor_col += 1
		if @cursor_col >= $cols
			@cursor_col = $cols - 1
			@colfeed += 1
		end
	end
	def cursor_left
		@cursor_col -= 1
		if @cursor_col < 0
			@cursor_col = 0
			@colfeed -= 1
			if @colfeed < 0
				@colfeed = 0
			end
		end
	end
	def cursor_up
		@cursor_row -= 1
		if @cursor_row < 1
			@cursor_row = 1
			@linefeed -= 1
			if @linefeed < 0
				@linefeed = 0
			end
		end
	end
	def cursor_down
		@cursor_row += 1
		if @cursor_row >= $rows
			@cursor_row = $rows -1
			nl = @text.count("\n")
			if (@linefeed + @cursor_row) <= nl
				@linefeed += 1
			end
		end
	end
	def dump_text
		i = 0
		j = -1
		(@text+"\n").scan(/^.*$/){|line|
			j += 1
			if j < @linefeed
				next
			end
			i += 1
			if i >= $rows
				break
			end
			line.gsub!(/\t/,"    ")
			line = line[@colfeed,$cols]
			write_str(i,0," "*$cols)
			write_str(i,0,line)
		}
		while i < $rows
			write_str(i,0," "*$cols)
			i += 1
		end
	end
end




filename = ARGV[0]
puts filename

init_screen do
	$cols = $screen.maxx
	$rows = $screen.maxy
	buffer = FileBuffer.new(filename)
	buffer.dump_to_screen
	loop do
		$cols = $screen.maxx
		$rows = $screen.maxy
		case Curses.getch
			when ?q then break
			when Curses::Key::UP then buffer.cursor_up
			when Curses::Key::DOWN then buffer.cursor_down
			when Curses::Key::RIGHT then buffer.cursor_right
			when Curses::Key::LEFT then buffer.cursor_left
		end
		buffer.dump_to_screen
	end
end

