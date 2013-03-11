#---------------------------------------------------------------------
# BufferHistory class
#
# This class manages a list of buffer text states for
# undo/redo purposes.  The whole thing is a wrapper around a
# list of Node objects, which are defined inside this
# BufferHistory class.
#---------------------------------------------------------------------

class BufferHistory

	def initialize(text,row,col)
		@hist = [State.new(text,row,col)]
		@idx = 0
		# These are for (un)reverting to saved copy.
		@saved = [@idx]
		@saved_idx = 0
		@last_saved = @hist[@idx]
		@maxlength = 1000
	end

	def current
		@hist[@idx]
	end

	# Define a buffer state.
	class State
		attr_accessor :text, :row, :col
		def initialize(text,row,col)
			@text = []
			@text = text.dup
			@row = row
			@col = col
		end
	end


	# Keep the history from getting too long.
	def prune

		# First prune the saved buffer history.
		if @saved.length > @maxlength/4
			n0 = @saved_idx/2
			n1 = (@saved.length-@saved_idx)/2
			@saved.slice!(-n1..-1) if n1 > 0
			@saved.slice!(0..(n0-1))
			@saved_idx -= n0
		end


		# Now prune the full buffer history.
		if @hist.length > @maxlength
			n0 = @idx/2
			n1 = (@hist.length-@idx)/2
			@idx -= n0

			# Grab the saved buffer history states which would get
			# pruned.  We want to add those on to the ends of the
			# buffer history.
			pre_idx = @saved.select{|j|j<n0}
			post_idx = @saved.select{|j|j>(@saved.length-n1)}
			pre = pre_idx.map{|j|@hist[j]}
			post = post_idx.map{|j|@hist[j]}

			@hist.slice!(-n1..-1) if n1 > 0
			@hist.slice!(0..(n0-1))

			# Adjust the indexing of the saved states list,
			# because we have just chopped up the buffer history list.
			@saved.each_index{|j|
				if j < pre.length
					@saved[j] = j
				elsif j < (pre.length+@hist.length)
					@saved[j] = pre.length+@hist.length + j
				end
			}
			@hist = pre + @hist + post
		end

	end

	# Add a new snapshot.
	def add(text,row,col)
		@hist = @hist[0..@idx] + [State.new(text,row,col)] + @hist[@idx+1..-1]
		@idx += 1
		prune
	end

	# Return the current text state.
	def text
		@hist[@idx].text
	end
	# Bump forward by one.
	def row
		@hist[@idx].row
	end
	# Bump backward by one.
	def col
		@hist[@idx].col
	end

	# Make a shallow copy of the text.
	def copy
		@hist[@idx].text.dup
	end

	def undo
		if @idx == 0
			return(false)
		else
			@idx -= 1
			return(true)
		end
	end

	def redo
		if @idx == @hist.length-1
			return(false)
		else
			@idx += 1
			return(true)
		end
	end

	# This should get called only when the file is saved.
	# This makes a "saved" snapshot of the history,
	# *and* sets the "last_saved" state, which should track
	# the contents of the saved-to-disk file (assuming nobody
	# else has changed it).
	def save
		return if !modified?
		@saved = @saved[0..@saved_idx] + [@idx] + @saved[@saved_idx+1..-1]
		@saved_idx += 1
		@last_saved = @hist[@idx]
	end

	# Optional file history backup.  Write to a backup file all the saved
	# state history. The first line of the file will be the current
	# buffer history index. The second line of the file will be all of
	# the strings (lines) from all of the saved buffer states.  Each line
	# after that is the indices (into the first line array) for each
	# buffer state.
	def backup(filename)

		# Create a 'set' of lines (strings), so that we remove duplicates.
		require 'set'
		s = Set.new
		@saved.each{|k| s.merge(@hist[k].text)}

		# Convert to an array; create an index array; create a hash index
		# for the index array, so that we can find elements quickly.
		a = s.to_a
		ah = a.map{|x|x.hash}
		ah = Hash[*ah.zip(Array(0..(a.length-1))).flatten]

		# Write to the backup file.
		File.open(filename,'w'){|f|
			f.puts @saved_idx
			f.puts a.inspect
			@saved.each{|k|
				# Use the hash index to find the index into the lines array.
				b = @hist[k].text.map{|line|
					ah[line.hash]
				}
				# Prepend the row and column to the array of indices.
				r,c = @hist[k].row,@hist[k].col
				b = [r,c] + b
				f.puts b.inspect
			}
		}
	rescue
		$screen.write_message($!.to_s)
		return
	end

	# Read in the saved states from the backup file.
	def load(filename)
		return if !File.exist?(filename)
		File.open(filename){|f|

			k = f.readline.to_i
			begin
				a = eval(f.readline)
			rescue
				$screen.write_message($!.to_s)
				return
			end

			# Map the indices into the strings.
			b = []
			f.readlines.each{|line|
				begin
					s = eval(line)
				rescue
					$screen.write_message($!.to_s)
					return
				end
				r,c = s[0,2]
				text = s[2..-1].map{|x|a[x]}
				b << State.new(text,r,c)
			}

			# Create the buffer history list.
			if @hist[@idx].text.flatten == b[k].text.flatten
				@idx = k
				@hist = b.dup
			else
				@hist = b.dup + @hist
				@idx += b.length
				@saved_idx += b.length
			end
			@saved_idx = @idx
			@saved = (0..(@hist.length-1)).to_a

		}
	end

	# Is the text modified from the saved version?
	# Use flatten, so that folded text is seen as unchanged.
	def modified?
		@last_saved.text.flatten != @hist[@idx].text.flatten
	end


	# These bumps along the "saved" states of the buffer history.
	def revert_to_saved
		# Make a snapshot of the current state so we can come back to it.
		if @saved[@saved_idx] != @idx
			@saved = @saved[0..@saved_idx] + [@idx] + @saved[@saved_idx+1..-1]
		else
			@saved_idx = [@saved_idx-1,0].max
		end
		@idx = @saved[@saved_idx]
		return(copy)
	end
	def unrevert_to_saved
		@saved_idx = [@saved_idx+1,@saved.length-1].min
		@idx = @saved[@saved_idx]
		return(copy)
	end

end

# end of BufferHistory class
#---------------------------------------------------------------------
