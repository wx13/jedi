#---------------------------------------------------------------------
# Utils
#
# Various utility methods
#---------------------------------------------------------------------


class String

	#
	# Find leading occurances of one string in another.
	#
	# INPUT:
	# self    the string to search.
	# str     the string to find.
	#
	# RETURNS:
	# num     number of occurances
	# after   string that follows the leading occurances
	#
	# EXAMPLE:
	# "foo foo foo bar baz".leading_occurances("foo ")
	# returns: 3, "bar baz"
	#
	def leading_occurances(str)
		pattern = Regexp.escape(str)
		a,b,c = self.partition(/^(#{pattern})+/)
		if a.length > 0
			num = 0
			after = a
		else
			after = c
			num = (self.length - after.length)/str.length
		end
		return num, after
	end

	# Replace the contents of a string in-place (same memory location).
	def replace(str)
		self.slice!(0..-1)
		self << str
	end

	# Swap out leading occurances of one string for another.
	def swap_indent_string(str1,str2)
		ni, after = self.leading_occurances(str1)
		self.replace(str2*ni + after)
	end

	# Find the next match within a string.
	# Handle both forward and backward searches.
	def search_string(token,dir=:forward,pos=nil)
		return nil if pos && pos >= self.length
		if dir == :forward
			pos = 0 unless pos
			a,b,c = self[pos..-1].partition(token)
		else
			pos = self.length - 1 unless pos
			a,b,c = self[0..pos].rpartition(token)
		end
		if b.length > 0
			if dir == :forward
				return([pos+a.length,b.length])
			else
				return([a.length,b.length])
			end
		else
			return nil
		end
	end

	# "normal string"        => /normal string/
	# "special/chars"        => /special\/chars/
	# "/regex/", escape=nil  => /regex/
	# "/regex/", escape=true => /\/regex\//
	def to_regex(escape=nil)
		if self[0]=="/" && self[-1]=="/" && escape.nil?
			begin
				return(eval(self))
			rescue SyntaxError => se
				return(nil)
			end
		else
			return Regexp.new(Regexp.escape(self))
		end
	end

end


class Array
	def count(pattern)
		self.grep(pattern).length
	end
	# Convert all elements of the array to regexp
	def to_regex(escape)
		self.map{|x| x.to_regex(escape)}
	end
end

class Regexp
	def to_regex(escape)
		self
	end
end
