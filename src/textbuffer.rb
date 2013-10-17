#---------------------------------------------------------------------
# TextBuffer class
#
# This class manages the actual text of a buffer.  All other
# information is stored elsewhere.  This class litterally just
# maintains the text.
#---------------------------------------------------------------------

class TextBuffer < Array

	# Replace the text buffer with a whole new array of strings.
	# This is different than an assignment (which should never be
	# done) because it keeps the array intact, and only replaces
	# the strings.
	def replace(text)
		self.slice!(1..-1)
		text.each_index{|k|
			self[k] = text[k]
		}
	end

	# Return a deep copy of the text buffer.
	def deep_copy
		text = self.flatten
		rtext = []
		text.each_index{|k|
			rtext[k] = text[k].dup
		}
		return rtext
	end

	# Delete a character at a (row,col) location.
	def delchar(row,col)
		return if self[row].kind_of?(Array)
		if col == self[row].length
			mergerows(row,row+1)
		else
			self[row] = self[row].dup
			self[row][col] = ""
		end
	end

	# Insert a character at a (row,col) locatation.
	# If insertmode is true, the character is inserted,
	# otherwise it replaces the current character.
	def insertchar(row,col,c,insertmode=true)
		return if self[row].kind_of?(Array)
		return if c.is_a?(String) == false
		return if col > self[row].length
		if self[row] == nil
			self[row] = c
			return
		end
		self[row] = self[row].dup
		if insertmode || col == self[row].length
			self[row].insert(col,c)
		else
			self[row][col] = c
		end
	end

	# Delete a row.
	def delrow(row)
		self.delete_at(row)
	end

	# Delete a range of rows (inclusive).
	def delrows(row1,row2)
		self[row1..row2] = []
	end

	# Merge two consecutive rows.
	def mergerows(row1,row2,joiner="")

		return if self[row1] == nil || self[row2] == nil

		# Special case: one of the rows is empty.
		# This is special, because the other row is unmodified, and
		# we don't want to dup the string.
		case
			when self[row1]==''
				self.delete_at(row1)
				self[row1] = joiner + self[row1]
				return
			when self[row2]==''
				self.delete_at(row2)
				return
		end

		# We can merge a folded block with an empty line, but not with
		# non-full lines.
		return if self[row1].kind_of?(Array)
		return if self[row2].kind_of?(Array)

		# Normal merge
		col = self[row1].length
		self[row1] = self[row1].dup + joiner + self[row2]
		self.delete_at(row2)

	end

	# Split a row into two.
	def splitrow(row,col)
		return if self[row].kind_of?(Array)
		text = self[row].dup
		self[row] = text[(col)..-1]
		insertrow(row,text[0..(col-1)])
	end

	# Insert a new row.
	def insertrow(row,text)
		self.insert(row,text)
	end

	# Insert a string at a (row,col) position).
	def insertstr(row,col,text)
		return if self[row].kind_of?(Array)
		self[row] = self[row].dup
		self[row].insert(col,text)
	end

	# Delete a column of text.
	def column_delete(row1,row2,col)
		for r in row1..row2
			next if self[r].kind_of?(Array)  # Skip folded text.
			next if self[r].length < -col    # Skip too short lines.
			next if col >= self[r].length    # Can't delete past end of line.
			self[r] = self[r].dup
			self[r][col] = ""
		end
	end

	# Hide the text from srow to erow.
	def hide_lines_at(srow,erow)
		text = self[srow..erow]  # grab the chosen lines
		self[srow] = [text].flatten  # current row = array of marked text
		self[(srow+1)..erow] = [] if srow < erow  # technically, can hide a single line, but why?
		return text.length
	end

	# Hide all text between a start pattern and an end pattern.
	# Do it for all matches.
	def hide_by_pattern(pstart,pend)
		i = -1
		n = self.length
		while i < n
			i += 1
			line = self[i]
			next if line.kind_of?(Array)
			if line =~ pstart
				j = i
				while j < n
					j += 1
					line = self[j]
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
	end

	# Unhide the lines folded into row 'row'.
	def unhide_lines(row)
		hidden_text = self[row]
		return if hidden_text.kind_of?(String)
		text = self.dup
		self.delete_if{|x|true}
		self.concat(text[0,row])
		self.concat(hidden_text)
		self.concat(text[(row+1)..-1])
	end

	# Unhide all folded lines.
	def unhide_all
		self.flatten!
	end

	def swap_indent_string(str1,str2)
		self.map{|line| line.swap_indent_string(str1,str2)}
	end


	# Figure out leading "whitespace", where "whitespace"
	# now includes non-whitespace leading characters which are
	# the same on the last few lines.
	def get_leading_whitespace(row)
		ws = ""
		if row > 1
			s0 = self[row-2].dup
			s1 = self[row-1].dup
			s2 = self[row].dup
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
		a = self[row].match(/^\s*/)
		if a != nil
			ws2 = a[0]
		end
		ws = [ws,ws2].max
		return(ws)
	end


	def justify(row0,row1,width,linewrap)

		# If first line is indented, make all lines indented.
		indent = self[row0].gsub(/[^\s].*$/,'')
		self[row0].gsub!(/^\s+/,'')

		# make one long line out of multiple lines
		text = self[row0..row1].join(" ")
		self[row0..row1] = []

		r = row0
		while text.length >= width
			k = text[0,width].index(/\s+[^\s]*$/)
			k = text.index(/\s+[^\s]*$/) if k.nil?
			break if k.nil?
			t1 = text[0,k]
			text = text[k..-1].gsub(/^\s+/,'')
			self.insertrow(r,indent+t1)
			r += 1
		end
		self.insertrow(r,indent+text)
		r += 1

		if linewrap && self[r] && self[r].length > 0
			r -= 1
			self.mergerows(r,r+1," ")
			if self[r].length >= width
				r, junk = self.justify(r,r,width,linewrap)
			end
		end

		return r, indent

	end

	# Blank for now, which means we don't search
	# folded lines.  Ultimately, this should call next_match
	# in its lines.
	def search_string(token,pos=0)
		return nil
	end


	# Search for the next occurance.
	def next_match(row,col,token,params={})
		dir = (params[:dir])?(params[:dir]):(:forward)
		rows = params[:rows]

		# Handle bad cursor positions.
		row = row % (self.length)
		col = [col,self[row].length-1].min

		# If we are limiting the rows to search, then create a text
		# array containing just the desired lines.
		if rows
			if rows[0] < rows[1]
				text = self[row..rows[1]]
			else
				text = self[row..-1] + self[0..rows[1]]
				text = [] if (row < rows[0]) && (row > rows[1])
				text = self[row,1] if (row == rows[1])
			end
			return(["No match",row,col,0]) if text.length == 0
			offset = row
		else
			offset = row
			text = self[row..-1] + self[0..row]
		end

		# First line
		if a = text[0].search_string(token,dir,col+1)
			return(["Found match",offset,a[0],a[1]])
		end

		# Rest of the lines
		text.reverse! if dir != :forward
		text = text[1..-1]
		offset += (dir==:forward)?(1):(-1)
		text.each_index{|k|
			if a = text[k].search_string(token,dir)
				r = (dir==:forward)?(k+offset):(offset-k)
				return(["Found match", r%self.length, a[0], a[1]])
			end
		}

		return(["No match",row,col,0])

	end

	def gsub!(rules)
		self.map{|line|
			rules.each{|k,v|
				line.gsub!(k,v)
			}
			line
		}
	end

end

# end of text buffer class
#---------------------------------------------------------------------
