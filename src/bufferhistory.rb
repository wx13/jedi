#---------------------------------------------------------------------
# BufferHistory class
#
# This class manages a list of buffer text states for undo/redo purposes.
# It keeps a list a buffer states, and some indexes into the list.
# Each element of the buffer state list is an instance the class State
# (defined within the BufferHistory class).
# A state instance contains: a text buffer, row, and column.
#---------------------------------------------------------------------

class BufferHistory

	# BufferHistory must be initialized with a text state.
	def initialize(text,row,col)

		@hist = [State.new(text,row,col)]
		@idx = 0

		# This is an index of snapshots made each time the buffer is saved
		# to file.
		@saved = [@idx]
		@saved_idx = 0
		@last_saved = @hist[@idx]

		# Put some limits on the length of the state list:
		# both number of elements and byte size matter.
		@maxlength = 1000
		@maxbytes = 1e8
		@maxlength_saved = 100
		@maxbytes_saved = 1e6
	end



	# Let us directly access the current state.
	def text
		@hist[@idx].text
	end
	def row
		@hist[@idx].row
	end
	def col
		@hist[@idx].col
	end



	# Define a buffer state.
	class State
		attr_accessor :text, :row, :col
		def initialize(text,row,col)
			@text = text.dup
			@row = row
			@col = col
		end
	end



	# Keep the history from getting too long.
	def prune

		# First prune the saved buffer history.
		bs = @saved.length * @hist[@idx].text.inspect.length
		if @saved.length > @maxlength_saved || bs > @maxbytes_saved
			n0 = @saved_idx/2
			n1 = (@saved.length-@saved_idx)/2
			@saved.slice!(-n1..-1) if n1 > 0
			@saved.slice!(0..(n0-1))
			@saved_idx -= n0
		end


		# Now prune the full buffer history.
		bs = @hist.length * @hist[@idx].text.inspect.length
		if @hist.length > @maxlength || bs > @maxbytes
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



	# Make a shallow copy of the text.
	def copy
		@hist[@idx].text.dup
	end



	#
	# Bump to the next/previous item in the buffer history list.
	#
	# - If we are at the end/start of the list already, do nothing.
	# - If the current row is sufficiently different than the changed row, then
	#   move to the changed row, but don't make the change.
	# - If the changed row is the current row, then make the change.
	# A. Caveat, if we can't move to the appropriate row, make the change
	#    anyway.  Otherwise we could lose access to changes.
	#
	def undo(r,c,n=-1)
		unless (0..@hist.length-1).include?(@idx+n)
			return false, r, c
		end
		idx = @idx + (n+1)/2
		if r==@hist[idx].row
			@idx += n
			return true, r, c
		end
		if @hist[idx].row >= @hist[@idx].text.length
			@idx += n
			return true, @hist[idx].row, @hist[idx].col
		end
		return false, @hist[idx].row, @hist[idx].col
	end



	# This should get called only when the file is saved.
	# This makes a "saved" snapshot of the history,
	# *and* sets the "last_saved" state, which should track
	# the contents of the saved-to-disk file (assuming nobody
	# else has changed it).
	def save
		return if !modified?
		@saved = @saved[0..@saved_idx] + [@idx]
		if @saved_idx < @saved.length
			@saved += @saved[@saved_idx+1..-1]
		end
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
				b << State.new(TextBuffer.new(text),r,c)
			}

			# Create the buffer history list.
			if @hist[@idx] && b[k] && @hist[@idx].text.flatten == b[k].text.flatten
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


	# Change indentation string in text buffers.
	def swap_indent_string(str1, str2)
		each_line{|line|
			line.swap_indent_string(str1,str2)
		}
		#texts = @hist.map{|text| text.text}
		#ids = texts.flatten.map{|line| line.object_id}
		#require 'set'
		#s = Set.new(ids)
		#s.each{|id|
		#	ObjectSpace._id2ref(id).swap_indent_string(str1,str2)
		#}
	rescue
		$screen.write_message($!.to_s)
	end

	def each_line
		texts = @hist.map{|text| text.text}
		ids = texts.flatten.map{|line| line.object_id}
		require 'set'
		s = Set.new(ids)
		s.each{|id|
			yield ObjectSpace._id2ref(id)
		}
	rescue
		$screen.write_message($!.to_s)
	end

	def apply_mask(mask)
		each_line{|line|
			mask.each{|k,v|
				line.gsub!(k,v)
			}
		}
	end

	def unapply_mask(mask)
		each_line{|line|
			mask.each{|k,v|
				line.gsub!(v,k)
			}
		}
	end


end

# end of BufferHistory class
#---------------------------------------------------------------------
