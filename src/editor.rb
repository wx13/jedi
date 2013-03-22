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
		$tabsize = Hash.new(4)           # Tab character display width
		$tabchar = Hash.new("\t")        # What to insert when tab key is pressed
		$autoindent = Hash.new(true)
		$linewrap = Hash.new(false)
		$cursormode = Hash.new('col')    # Default text selection mode
		$syntax_color = Hash.new(true)
		$editmode = Hash.new(:edit)      # false = start in view mode
		$linelength = Hash.new(0)        # 0 = terminal width
		$backups = Hash.new(false)

		# Define the key mapping and colors up front, so that they
		# can be modified by config files and start-up scripts.
		$keymap = KeyMap.new
		$color = define_colors
		$syntax_colors = SyntaxColors.new
		$cursor_color = ''
		$filetypes = define_filetypes
		$mouse = false

		# Parse input options after keymap and colors are defined, but before
		# we initialize any of the big classes.  This way, a user script can
		# modify the screen/buffer/etc classes on start-up.
		parse_options

		# Initialize the interactive screen environment, and set the color
		# global to point to the one that screen defines.  This will keep
		# everything in the same place, but allow easy on-the-fly color changes.
		$screen = Antsy::Screen.new
		$color = $screen.add_colors($color)
		$screen.set_cursor_color($cursor_color)
		$screen.toggle_mouse($mouse)

		# Read the specified files into the list of buffers.
		$buffers = BuffersList.new(ARGV)

		# Copy buffer and histories are global, so we can copy from one
		# buffer to another.
		$copy_buffer = CopyBuffer.new
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

	def define_filetypes
		filetypes = {
			/\.(sh|csh)$/ => :shell,
			/\.(rb)$/ => :ruby,
			/\.(py)$/ => :python,
			/\.([cCh]|cpp)$/ => :c,
			"COMMIT_EDITMSG" => :git,
			/\.m$/ => :matlab,
			/\.pro$/ => :idl,
			/\.[fF]$/ => :fortran,
			/\.yaml$/ => :yaml,
			/\.md$/ => :markdown,
			/\.txt$/ => :text,
			/\.pl$/ => :perl,
			/\.tex$/ => :latex,
			/\.html?$/ => :html,
		}
		return filetypes
	end


	# Enter arbitrary ruby command.
	def enter_command
		answer = $screen.ask("command:",$histories.command)
		if answer.nil?
			$screen.write_message("cancelled")
			return
		end
		eval(answer)
		$screen.write_message("done")
	rescue Exception => e
		$screen.write_message(e.to_s)
	end


	# This is a function which runs an arbitrary ruby script.
	# It can read from a file or from user input.
	def run_script(file=nil)
		# If not file is specified, ask the user for one.
		if file == nil
			file = $screen.ask("run script file:",[""],:file=>true)
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
				$tabsize = Hash.new(n)
			}
			opts.on('-T', '--tabchar c', 'Set tab character'){|c|
				$tabchar = Hash.new(c)
			}
			opts.on('-A', '--autoindent', 'Turn on autoindent'){
				$autoindent = Hash.new(true)
			}
			opts.on('-a', '--no-autoindent', 'Turn off autoindent'){
				$autoindent = Hash.new(false)
			}
			opts.on('-y', '--save-hist FILE', 'Save history in this file'){|file|
				$histories_file = file
			}
			opts.on('-E', '--edit', 'Start in edit mode'){
				$editmode = Hash.new(:edit)
			}
			opts.on('-e', '--no-edit', 'Start in view mode'){
				$editmode = Hash.new(:view)
			}
			opts.on('-W', '--linewrap [n]', Integer, 'Turn on linewrap'){|n|
				$linewrap = Hash.new(true)
				if n.nil?
					$linelength = Hash.new(0)
				else
					$linelength = Hash.new(n)
				end
			}
			opts.on('-w', '--no-linewrap', 'Turn off linewrap'){
				$linewrap = Hash.new(false)
			}
			opts.on('-C', '--color', 'Turn on syntax coloring'){
				$syntax_color = Hash.new(true)
			}
			opts.on('-c', '--no-color', 'Turn off syntax coloring'){
				$syntax_color = Hash.new(false)
			}
			opts.on('-m', '--no-mouse', 'Disable mouse support'){
				$mouse = false
			}
			opts.on('-M', '--mouse', 'Enable mouse interaction'){
				$mouse = true
			}
			opts.on('-B', '--backups', 'Enable file backupts'){
				$backups = Hash.new('...')
			}
			opts.on('-b', '--no-backups', 'Disable file backupts'){
				$backups = Hash.new(false)
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
				buffer.snapshot

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
						buffer.addchar(c) if buffer.editmode==:edit && c.is_a?(String)
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
