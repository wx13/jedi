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
		:file, :text, :editmode, :buffer_history, :extramode, \
		:cutscore, :window, :sticky_extramode, :row, :col

	def initialize(filename)

		# read in the file
		@file = FileAccessor.new(filename)
		@text = TextBuffer.new(@file.read)

		# file type for syntax coloring
		@filetype = get_filetype(@file.name)

		# position of cursor in buffer
		@row = 0
		@col = 0
		# Desired column (memory of where we used to be)
		@usedescol = false
		@descol = false
		# shifts of the buffer
		@linefeed = 0
		@colfeed = 0

		# copy,cut,paste stuff
		@marked = false
		@cutrow = -1  # keep track of last cut row, to check for consecutiveness
		@cutscore = 0  # don't let cuts be consecutive after lots of stuff has happened
		@mark_col = 0
		@mark_row = 0
		@mark_list = {}
		@multimarkmode = false


		# displayed width of a literal tab chracter
		@tabsize = $tabsize[@filetype]
		# what to insert when tab key is pressed
		@tabchar = $tabchar[@filetype]
		# char the editor uses for indentation
		@indentchar = @file.indentchar
		@indentstring = @file.indentstring

		# for text justify
		# 0 means full screen width
		@linelength = $linelength[@filetype]


		# flags
		@autoindent = $autoindent[@filetype]
		@editmode = $editmode[@filetype]
		@extramode = false
		@sticky_extramode = false
		@insertmode = true
		@linewrap = $linewrap[@filetype]
		@cursormode = $cursormode[@filetype]
		@syntax_color = $syntax_color[@filetype]
		@backups = $backups[@filetype]
		@enforce_ascii = $enforce_ascii[@filetype]
		@horiz_scroll = $horiz_scroll[@filetype]

		# undo-redo history
		@buffer_history = BufferHistory.new(@text,@row,@col)
		@buffer_history.load(@file.name.rpartition('/').insert(2,@backups).join) if @backups
		# save up info about screen to detect changes
		@colfeed_old = 0
		@marked_old = false

		# bookmarking stuff
		@bookmarks = {}
		@bookmarks_hist = [""]

		# grab a window to write to
		@window = Antsy::Window.new($screen)

		# for marked text highlighting
		@buffer_marks = {}
		@buffer_marks.default = [-1,-1]

		# Time of the last status bar update
		@last_status_update = 0.0
		@min_status_update = 0.1

		# This does nothing, by default; it is here to allow
		# a user script to modify each text buffer that is opened.
		perbuffer_userscript

	end

	# Empty method which gets called by initialize.
	# This is so the user can include (in a startup script)
	# code which runs everytime we open a new buffer.
	def perbuffer_userscript
	end



	# Set the file type from the filename.
	def get_filetype(filename)
		filetype = nil
		$filetypes.each{|k,v|
			if filename.match(k) != nil
				filetype = v
			end
		}
		return filetype
	end


	# Remember a position in the text.
	def bookmark
		answer = @window.ask("bookmark:",@bookmarks_hist)
		if answer == nil
			@window.write_message("Cancelled");
		else
			@window.write_message("Bookmarked");
			@bookmarks[answer] = [@row,@col,@linefeed,@colfeed]
		end
	end

	# Go to a remembered position.
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
			cmd = @window.menu($keymap.togglelist,"Toggle").last
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
		@editmode = :edit
		@window.write_message("Edit mode")
	end




	def save

		# Ask the user for a file.
		# Defaults to current file.
		ans = @window.ask("save to:",[@file.name],:display_last_answer=>true,:file=>true)
		if ans == nil
			@window.write_message("Cancelled")
			return
		end
		if ans == "" then ans = @file.name end
		if ans == ""
			@window.write_message("Cancelled")
			return
		end

		# If name is different from current file name,
		# ask for verification.
		if ans != @file.name
			yn = @window.ask_yesno("save to different file:"+ans+" ? [y/n]")
			if yn == "yes"
				@file.name = ans
				@filetype = get_filetype(@file.name)
			else
				@window.write_message("aborted")
				return
			end
		end

		if @file.save(@text).to_s.index('incompatible character encodings')
			if fix_encoding('mixed char encodings')
				if @file.save(@text)
					@window.write_message('Cannot save! ')
					return
				end
			else
				@window.write_message('cancelled')
				return
			end
		end

		# Let the undo/redo history know that we have saved,
		# for revert-to-saved purposes.
		@buffer_history.save

		# Store file history in a backup file.
		@buffer_history.backup(@file.name.rpartition('/').insert(2,@backups).join) if @backups

		# Save the command/search histories.
		$histories.save

		@indentchar = @file.indentchar
		@window.write_message("saved to: "+@file.name)

	end

	# re-open current buffer from file
	def reload
		if modified?
			ans = @window.ask_yesno("Buffer has been modified. Continue anyway?")
			return unless ans == 'yes'
		end
		text = @file.read
		if @text != text
			ans = @window.ask_yesno("Buffer differs from file. Continue anyway?")
			if ans == 'yes'
				@text.replace(text)
			end
		end
	end



	def fix_encoding(msg)
		ans = $screen.ask_yesno(msg+'. convert to unicode? ')
		if ans == 'yes'
			text.each_index{|k|
				@text[k] = @text[k].force_encoding('UTF-8')
			}
			return true
		else
			return false
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

		# Desired column.
		# If usedescol is set, then unset it, but leave the descol
		# alone.
		# If unset, then we did something other than up/down, so we
		# should unset the disired column.
		if @usedescol
			@usedescol = false
		else
			@descol = false
		end

	end


	# Has the buffer been modified from the saved version?
	def modified?
		@buffer_history.modified?
	end

	# If changed, take a snapshot of the new buffer.
	def snapshot
		if @buffer_history.text != @text
			@buffer_history.add(@text,@row,@col)
		end
	end



	# -----------------------------------------------
	# high-level text modifiers
	# (which call the low-level ones)
	# -----------------------------------------------

	# sort row & mark_row
	def ordered_marks
		mark_row,row,mark_col,col = @mark_row,@row,@mark_col,@col
		if @row == @mark_row
			if @col < @mark_col
				mark_col,col = @col, @mark_col
			end
		elsif @row < @mark_row
			mark_row,row = @row,@mark_row
			mark_col,col = @col,@mark_col
		end
		return mark_row,row, mark_col, col
	end

	# Delete a character.
	# Very simple, if text is not marked;
	# otherwise, much more complicated.
	# Four modes:
	# - col => delete text in range of rows at current column
	# - loc => same as col, but measure from end of line
	# - row => delete first character of each marked line
	# - multi => delete at each mark
	def delete(backspace=0)
		return if @multimarkmode
		if @marked
			return if backspace==1 && @col==0
			mark_row,row = ordered_marks()
			if @cursormode == :col
				c = (mark_row==row)?(0):(@col-backspace)
				@text.column_delete(mark_row,row,c)
			elsif @cursormode == :row
				@text.column_delete(mark_row,row,0)
			elsif @cursormode == :loc
				n = @text[@row][@col..-1].length + backspace
				if n > 0
					@text.column_delete(mark_row,row,-n)
				end
			else
				mark_list.each{|row,cols|
					# Loop over column positions starting from end,
					# because doing stuff at early in the line changes
					# positions later in the line.
					cols.uniq.sort.reverse.each{|col|
						@text.column_delete(row,row,col-backspace)
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
			cursor_left(backspace)
		else
			if backspace == 1
				return if (@col+@row)==0
				if @col == 0
					cursor_left
					@text.mergerows(@row,@row+1)
					return
				end
			end
			cursor_left(backspace)
			@text.delchar(@row,@col) if @text[@row].kind_of?(String)
		end
	end

	def backspace
		delete(1)
	end

	# Insert a char and move to the right.
	# Very simple if text is not marked.
	# For marked text, issues are similar to delete method above.
	def addchar(c)

		return if @multimarkmode

		# Handle the tab character.
		if c == :tab
			c = @tabchar
			# Fortran hack.
			c = " "*6 if @filetype == 'f' && @col == 0
		end

		# Catch problem characters.
		return if ! c.is_a?(String)
		return if c.index('\e')

		# If text is not marked, we just add the character.
		# Otherwise, things are much more complicated.
		if @marked == false
			@text.insertchar(@row,@col,c,@insertmode)
		else

			mark_row,row = ordered_marks()

			# Construct list of cursor positions, depending on mark mode.
			if @cursormode == :multi
				list = mark_list
			elsif @cursormode == :col && mark_row != row
				list = {}
				for r in mark_row..row
					list[r] = [@col] unless @col > @text[r].length
				end
			elsif @cursormode == :loc && mark_row != row
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

			# Now that we have a list of cursor positions, add the character
			# at each cursor poition.
			list.each{|row,cols|

				# don't insert blanks at start of line
				if (@text[row].length==0)&&((c==?\s)||(c==?\t)||(c=="\t")||(c==" "))
					next
				end

				cols = cols.uniq.sort.reverse
				cols.each{|col|
					@text.insertchar(row,col,c,@insertmode)
					if @cursormode == :multi
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
			@text.insertrow(@row,"")
			cursor_down(1)
		else
			@text.splitrow(@row,@col)
			ws = ""
			if @autoindent

				# snap shot, so we can undo auto-indent
				@buffer_history.add(@text,@row+1,0)

				ws = @text.get_leading_whitespace(@row)

				# If current line is just whitespace, remove it.
				# Rule #1: no trailing whitespace.
				if @text[@row].match(/^\s*$/)
					@text[@row] = ""
				end
				c = 0
				ws.partition(/\s+/).each{|w|
					next if w.nil? || w.length==0
					@text.insertchar(@row+1,c,w)
					c += w.length
					@buffer_history.add(@text,@row+1,c)
				}
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
			return if @text[@row].nil?
			cols = @linelength
			# If line is short, nothing to be done.
			return if @text[@row].length < cols
		else
			# Ask for desired line length.
			# nil means cancel, empty means screen width
			ans = @window.ask("Justify width:",[@linelength.to_s],:display_last_answer=>true)
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
			mark_row, row = ordered_marks()
		else
			mark_row = @row
			row = @row
		end
		nl = row - mark_row + 1

		r, indent = @text.justify(mark_row,row,cols,linewrap)


		# If we are line-wrapping, we must be careful to place the cursor
		# at the correct position.
		if linewrap
			if cursor && @col >= @text[@row].length+1
				@col = @col - @text[@row].length - 1 + indent.length
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
	def undo(method=:undo)
		changed,@row,@col = @buffer_history.send(method,@row,@col)
		if changed
			@text = @buffer_history.copy
		end
		better_cursor_position
	end
	def redo
		undo(:redo)
	end
	def revert_to_saved(method=:revert_to_saved)
		@text.delete_if{|x|true}
		@text.concat(@buffer_history.send(method))
		@row = @buffer_history.row
		@col = @buffer_history.col
		better_cursor_position
	end
	def unrevert_to_saved
		revert_to_saved(:unrevert_to_saved)
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
	def handle_desired_column(sc)
		if @descol
			sc = @descol
		else
			@descol = sc
		end
		@usedescol = true
		return(sc)
	end
	def cursor_down(n=1)
		sc = bc2sc(@row,@col)
		@row += n
		@row = [@row, 0].max
		@row = [@row, @text.length-1].min
		sc = handle_desired_column(sc)
		@col = sc2bc(@row,sc)
	end
	def cursor_up(n=1)
		cursor_down(-n)
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
			@row = [@text.length+@row,0].max
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
		screen_right(-n)
	end
	def screen_right(n=1)
		@colfeed = [0,@colfeed-n].max
	end
	def screen_down(n=1)
		@linefeed = [0,@linefeed-n].max
		@row = [@row,@linefeed+@window.rows-1].min
		@row = [@row,@linefeed].max
	end
	def screen_up(n=1)
		screen_down(-n)
	end
	def center_screen(r=@row)
		@linefeed = @row - @window.rows/2
		@linefeed = 0 if @linefeed < 0
	end



	#
	# search
	#
	def search(mode=:ask)

		if mode == :ask
			# get search string from user
			token = @window.ask("Search:",$histories.search)
			mode = :forward
		else
			token = $histories.search[-1]
		end
		if token && token.match(/^\/.*\/$/)
			token = token.to_regexp
		end
		if token == nil || token == ""
			@window.write_message("Cancelled")
			return
		end

		status, row, col = @text.next_match(@row,@col,token,:dir=>mode)

		@window.write_message(status)
		@row = row
		@col = col

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
		if token && token.match(/^\/.*\/$/)
			token = token.to_regexp
		end
		if token == nil || token == ""
			@window.write_message("Cancelled")
			return
		end

		# Get the replace string from the user.
		replacement = @window.ask("Replace:",$histories.replace,:return_empty=>true)
		if replacement == nil
			@window.write_message("Cancelled")
			return
		end

		@yes_to_all = false

		# Start at current position.
		if @marked
			rows = [@mark_row,@row]
			@row = @mark_row
			@marked = false
		else
			rows = [@row,(@row-1)%@text.length]
		end

		loop do

			params = {:rows=>rows}
			status, @row, @col, len = @text.next_match(@row,@col,token,params)
			break if status != "Found match"

			# Recenter screen, when we have gone off page
			if ((@row - @linefeed) > (@window.rows - 1)) || ((@row - @linefeed) < (0))
				center_screen(@row)
			end

			# Highlight the match, and ask for confirmation.
			if @yes_to_all
				yn = 'yes'
			else
				dump_to_screen(true)
				highlight(@row,@col,@col+len-1)
				yn = @window.ask_yesno("Replace this occurance?")
				if yn == "all"
					yn = 'yes'
					@yes_to_all = true
				end
			end

			# Do the replacement.
			if yn == "yes"
				@text[@row] = @text[@row][0,@col] + @text[@row][@col..-1].sub(token,replacement)
				@col += replacement.length - 1
			elsif yn == "cancel"
				break
			else
				@col += 1
			end
		end
	ensure
		@row = row0
		@col = col0
		@linefeed = @linefeed0
		@colfeed = @colfeed0
		dump_to_screen(true)
		@window.write_message("Done.")
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
		@cursormode = $cursormode if @cursormode == :multi
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
			@cursormode = :multi
			@mark_list = {}
		end
	end

	def copy(cut=0)

		return if @cursormode == :multi

		# if this is continuation of a line by line copy
		# then we add to the copy buffer
		if @marked
			return if ((@cursormode!=:row)&&(@mark_row!=@row))
			$copy_buffer.clear
			@marked = false
		else
			if @row!=(@cutrow+1-cut) || @cutscore <= 0
				$copy_buffer.clear
			else
				$copy_buffer.text.pop  # remove the newline
			end
			@cutrow = @row
			@cutscore = 25
			@mark_row = @row
			@mark_col = 0
			@col = @text[@row].length
		end

		@mark_row,@row,@mark_col,@col = ordered_marks()

		if @mark_row == @row
			single_line_copy(cut)
		else
			multi_line_copy(cut)
		end

		# position cursor
		if cut == 1
			@row,@col = @mark_row,@mark_col
		else
			@row,@col = @mark_row + 1, 0
		end

	end


	def single_line_copy(cut)

		line = @text[@row] # the line of interest

		if line.kind_of?(Array)  # folded text
			$copy_buffer.text += [line] + ['']
			if cut == 1
				@text[@row] = ''
				@text.mergerows(@row,@row+1)
			end
		else  # regular text
			@text[@row] = line[0,@mark_col] if cut == 1
			if @col < line.length
				@text[@mark_row] += line[@col+1..-1] if cut == 1
				$copy_buffer.text += [line[@mark_col..@col]]
			else
				# include line ending in cut/copy
				$copy_buffer.text += [line[@mark_col..@col]] + ['']
				@text.mergerows(@row,@row+1) if cut == 1
			end
		end

	end


	def multi_line_copy(cut)

		firstline = @text[@mark_row]
		if firstline.kind_of?(Array)
			$copy_buffer.text += [firstline]
			@text[@mark_row] = '' if cut == 1
		else
			$copy_buffer.text += [firstline[@mark_col..-1]]
			@text[@mark_row] = firstline[0,@mark_col] if cut == 1
		end
		$copy_buffer.text += @text[@mark_row+1..@row-1]
		lastline = @text[@row]
		if lastline.kind_of?(Array)
			$copy_buffer.text += [lastline]
			@text[@mark_row] += '' if cut == 1
		else
			$copy_buffer.text += [lastline[0..@col]]
			tail = lastline[@col+1..-1]
			@text[@mark_row] += tail if cut == 1 && tail != nil
		end
		@text.delrows(@mark_row+1,@row) if cut == 1

	end


	def cut
		copy(1)
	end


	def paste
		@cutrow = -1
		@cutscore = 0

		return if @text[@row].kind_of?(Array)
		return if $copy_buffer.text.empty?
		copy_string = $copy_buffer.text.join("\n")
		text = @text[@row][0,@col] + copy_string + @text[@row][@col..-1]
		@text.delete_at(@row)
		text.split("\n",-1).reverse.each{|line|
			@text.insert(@row,line)
		}

		@row += $copy_buffer.text.length - 1
		@col += $copy_buffer.text[-1].length

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

	def update_top_line(cursrow,curscol,force=false)

		if cursrow.nil? || curscol.nil?
			cursrow,curscol = get_cursor_position
		end

		t = Time.now.to_f
		unless force
			return if (t-@min_status_update) < @last_status_update
		end
		@last_status_update = t

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
		status += "  " + @editmode.to_s
		# report on number of open buffers
		if $buffers.npage <= 1
			lstr = @file.name
		else
			nb = $buffers.npage
			ib = $buffers.ipage
			lstr = sprintf("%s (%d/%d)",@file.name,ib+1,nb)
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


	def get_buffer_marks
		buffer_marks = {}
		return buffer_marks unless @marked
		mark_row,row = @mark_row,@row
		mark_row,row = row,mark_row if mark_row > row
		if @cursormode == :col && mark_row != row
			for j in mark_row..row
				buffer_marks[j] = [[@col,@col]] unless j==@row
			end
		elsif @cursormode == :loc && mark_row != row
			n =  @text[@row][@col..-1].length
			for j in mark_row..row
				m = @text[j].length - n
				buffer_marks[j] = [[m,m]] unless j==@row
			end
		elsif @cursormode == :row || ((@cursormode!=:row)&&(mark_row==row))
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
		return(buffer_marks)
	end


	def write_line(text,r)
		line = text[r]
		return if line.nil?
		if line.kind_of?(String)
			line = line.bytes.to_a.map{|b|[b,126].min.chr}.join if @enforce_ascii
			if @syntax_color
				aline = $syntax_colors.syntax_color(line,@filetype,@indentchar)
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
		if @horiz_scroll==:screen || r==(@row-@linefeed)
			@window.write_line(r,@colfeed,aline)
		else
			@window.write_line(r,0,aline)
		end
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
		full_screen_update = (@colfeed != @colfeed_old)&&(@horiz_scroll==:screen)
		full_screen_update ||= refresh
		full_screen_update ||= @linefeed != @linefeed_old
		line_update = (@colfeed != @colfeed_old) && (@horiz_scroll==:line)
		if full_screen_update
			rows_to_update = Array(0..(text.length-1))
			@buffer_marks = {}
		elsif line_update
			rows_to_update = [@row-@linefeed]
			@buffer_marks = {}
		end

		# Handle marked text highlighting
		#
		# Populate buffer_marks = {} with a list of start
		# and end points for highlighting, so that we
		# will know what needs to be updated.
		buffer_marks = get_buffer_marks()
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
			write_line(text,r)
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
		if refresh
			@window.lastline = @window.rows
		else
			@window.lastline = [@window.lastline,@window.rows].min
		end
		while r < (@window.lastline)
			@window.write_line(r,0,'~')
			r += 1
		end
		@window.lastline = text.length

		@colfeed_old = @colfeed
		@linefeed_old = @linefeed
		@row_old = @row

	end


	# highlight a particular row, from scol to ecol
	# scol & ecol are columns in the text buffer
	def highlight(row,scol,ecol)
		# only do rows that are on the screen
		return if row < @linefeed
		return if row > (@linefeed + @window.rows - 1)

		#return if @text[row].length < 1
		return if @text[row].kind_of?(Array)

		# convert pos in text to pos on screen
		sc = bc2sc(row,scol)
		ec = bc2sc(row,ecol)

		# replace tabs with spaces
		sline = tabs2spaces(@text[row])
		# get just string of interest
		sc = @colfeed if sc < @colfeed
		return if ec < @colfeed
		str = sline[sc..ec]
		if ec == sline.length then str += " " end
		ssc = sc - @colfeed
		return if ssc >= @window.cols
		sec = ec - @colfeed

		if (str.length+ssc) >= @window.cols
			str = str[0,(@window.cols-ssc)]
		end

		@window.write_string_colored((row-@linefeed+1),ssc,str,:marked)
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
	# Convert screen row/col to buffer row/col.
	def src2brc(sr,sc)
		@row = sr - @window.pos_row - 1 + @linefeed
		@col = sc2bc(@row,sc-@window.pos_col) + @colfeed
	end
	def tabs2spaces(line)
		return line if line == nil || line.length == 0
		a = line.split("\t",-1)
		ans = a[0]
		a = a[1..-1]
		return ans if a == nil
		a.each{|str|
			n = ans.gsub(@window.escape_regexp,"").length
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

	# Use marking to figure out which lines to hide.
	def hide_lines
		return if !@marked  # need multiple lines for folding
		return if @cursormode == :multi
		mark_row,row = ordered_marks()
		oldrow = mark_row  # so we can reposition the cursor
		@text.hide_lines_at(mark_row,row)
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
		@text.hide_by_pattern(pstart,pend)
		@window.write_message("done")
	end
	def unhide_lines
		@text.unhide_lines(@row)
	end
	def unhide_all
		@text.unhide_all
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
		if @file.indentstring != @indentstring
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
		if @file.indentchar != nil && fileindentstring[0] != @file.indentchar[0]
			ans = @window.ask_yesno("That seems wrong. Continue at your own risk?")
			return unless ans == "yes"
		end
		indentstring = @window.ask("User indent string:")
		return if indentstring == "" || indentstring == nil
		return if indentstring == fileindentstring

		# Replace one indentation with the other.
		@file.indentstring = fileindentstring
		@file.bufferindentstring = indentstring
		@indentstring = indentstring
		@buffer_history.swap_indent_string(@file.indentstring, @indentstring)

		# Set the tab-insert character to reflect new indentation.
		@indentchar = @indentstring[0].chr
		@tabchar = @indentstring

		dump_to_screen(true)
		@window.write_message("Indentation facade enabled")

	end


	# Remove the indentation facade.
	def indentation_real
		return if @indentstring == @file.indentstring
		@buffer_history.swap_indent_string(@indentstring, @file.indentstring)
		@indentchar = @file.indentchar
		@indentstring = @file.indentstring
		@file.bufferindentstring = @file.indentstring
		@tabchar = @file.indentstring
		dump_to_screen(true)
		@window.write_message("Indentation facade disabled")
	end

	def set_tabchar
		ans = @window.ask("set the tab character:")
		if ans.nil? || ans.empty?
			@window.write_message("Cancelled.")
		else
			@tabchar = ans
			@window.write_message("New indent char: " + @tabchar.inspect)
		end
	end

end

# end of big buffer class
#---------------------------------------------------------------------
