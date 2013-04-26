#---------------------------------------------------------------------
# Utils
#
# Various utility methods
#---------------------------------------------------------------------


class String

	# Given a two strings, find leading occurances of
	# the second string in the first, and return:
	#   - number of occurances
	#   - string that comes after leading occurances
	def leading_occurances(str)
		pattern = Regexp.escape(str)
		after = self.split(/^#{pattern}+/).last
		after = "" if after.nil?
		num = (self.length - after.length)/(str.length)
		return num, after
	end

	# Replace the contents of a string in-place.
	def replace(str)
		self.slice!(0..-1)
		self << str
	end

	def swap_indent_string(str1,str2)
		ni, after = self.leading_occurances(str1)
		self.replace(str2*ni + after)
	end

end



