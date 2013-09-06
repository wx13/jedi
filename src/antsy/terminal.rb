#---------------------------------------------------------------------
# Terminal class defines the API for interacting with the terminal.
# Everything terminal-specific belongs in here.  In theory, to change
# from ANSI to curses to tk, would require only changing this class.
#
# The Terminal class uses ANSI escapes to interact with the terminal.
# This is a little less portable than curses (theoretically), but can
# be done without external libraries.
#---------------------------------------------------------------------
class Terminal

	attr_accessor :colors
	attr_accessor :escape_regexp
	attr_accessor :mouse_x, :mouse_y

	def initialize
		define_colors
		define_keycodes
		define_outputcodes
		# This is a regexp to recognize an ANSI escape:
		@escape_regexp = /\e\[.*?m/
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
			"\eOF"  => :end,
			"\e[4"   => :end,

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

			"\e[M32" => :left_click,
			"\e[M33" => :middle_click,
			"\e[M34" => :right_click,
			"\e[M96" => :scroll_down,
			"\e[M97" => :scroll_up,
			"\e[M112" => :ctrl_scroll_down,
			"\e[M113" => :ctrl_scroll_up,
		}
	end

	def set_cursor_color(color)
		print "\e]12;#{color}\007"
	end

	def get_mouse_code
		c = STDIN.getc
		if !c.is_a?(Fixnum)
			c = c.unpack('C')[0].to_s
		end
		return c.to_s
	end

	# Read a character from stdin. Handle escape codes.
	#
	# Returns a symbol if the character is a key in the keycodes hash,
	# otherwise returns the raw string.
	def getch(options={})
		show_cursor unless options[:hide_cursor]
		c = STDIN.getc.chr
		# Escape character
		if c=="\e"
			2.times{c += STDIN.getc.chr}
		end
		# Funky gnome-terminal issues
		if c[1,1] == "O"
			c[1] = "["
		end
		# Mouse
		if c[2,1] == "M"
			c += get_mouse_code
			@mouse_x = get_mouse_code.to_i - 33
			@mouse_y = get_mouse_code.to_i - 33
		end
		# Some sequences are extra long.
		if c == "\e[5" || c == "\e[6"
			c += STDIN.getc.chr
		end
		if c=="\e[1"
			c += STDIN.getc.chr
			c = "\e["
			2.times{c += STDIN.getc.chr}
		end
		# Don't accept raw escape characters.
		if ["\e","\e\e","\e\e\e","\e\e\e\e","\e[","\e[\e]"].index(c)
			return nil
		end
		# Return the user-friendly key name, if possible.
		d = @keycodes[c]
		d = c if d == nil
		return(d)
	ensure
		hide_cursor
	end

	def get_screen_size
		@rows,@cols = `stty size`.split
		return @rows,@cols
	end

	def get_cursor_row
		print "\e[6n"
		n = ''
		c = ''
		2.times{c = STDIN.getc}
		while(c!=';')
			c = STDIN.getc.chr
			n += c
		end
		n.chop!
		while(c!='R')
			c = STDIN.getc.chr
		end
		return n.to_i
	end

	def set_raw
		system('stty raw -echo')
	end
	def unset_raw
		system('stty -raw echo')
	end

	# Allow the user to toggle mouse support on/off.
	def toggle_mouse(mouse)
		print (mouse)?("\e[?9h"):("\e[?9l")
	end

	def write(text)
		print text
	end

	# Some commands just print a code to the screen.
	# Handle these here.
	def define_outputcodes
		@outputcodes =
		{
			:restore_cursor   => "u",
			:save_cursor      => "s",
			:hide_cursor      => "?25l",
			:show_cursor      => "?25h",
			:clear_line       => "2K",
			:cursor           => "%d;%dH",
			:enable_linewrap  => "?7h",
			:disable_linewrap => "?7l",
			:clear_screen     => "2J",
			:roll_screen_up   => "%dS",
		}
		@outputcodes.default = ""
	end
	def method_missing(method,*args,&block)
		print "\e[" + @outputcodes[method] % args
	end

end

# end of Terminal class
#---------------------------------------------------------------------
