#---------------------------------------------------------------------
# Compatibility code.
#
# Backports of some string and array functionality to help
# with old versions of ruby.
#---------------------------------------------------------------------

if RUBY_VERSION < "1.8.7"
class String
	def partition(pattern,index=:index)
		x = self.send(index,pattern)
		#x = self.index(pattern)
		return self, "", "" if x.nil?
		c = self[x..-1].match(pattern)[0]
		cn = c.length
		return self[0,x], c, self[x+cn..-1]
	end
	def rpartition(pattern)
		partition(pattern,:rindex)
		#x = self.rindex(pattern)
		#return self, "", "" if x.nil?
		#c = self[x..-1].match(pattern)[0]
		#cn = c.length
		#return self[0,x], c, self[x+cn..-1]
	end
	def each_char
		self.each_byte{|b| yield b.chr}
	end
end
class Array
	alias_method :slice_orig!, :slice!
	def slice!(*args)
		self.slice_orig!(*args)
		self.delete_if{|x|x.nil?}
	end
end
end

# end of compatibility code
#---------------------------------------------------------------------
