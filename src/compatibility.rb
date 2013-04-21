#---------------------------------------------------------------------
# Compatibility code.
#
# Backports of some string and array functionality to help
# with old versions of ruby.
#---------------------------------------------------------------------

if RUBY_VERSION < "1.9"
class String
	def partition(pattern)
		a,b = self.split(pattern,2)
		c = self.scan(pattern)[0]
		c = "" if c.nil?
		b = "" if b.nil?
		a = "" if a.nil?
		return a, c, b
	end
	def rpartition(pattern)
		x = self.split(pattern)
		b = x[-1]
		a = x[0..-2].join
		c = self.scan(pattern)[-1]
		c = "" if c.nil?
		b = "" if b.nil?
		a = "" if a.nil?
		return a, c, b
	end
	alias_method :each_char, :each_byte
end
class Array
	alias_method :slice_orig!, :slice!
	def slice!(*args)
		self.slice_orig!(*args)
		self.delete_if{|x|x.nil?}
	end
	def count(pattern)
		self.grep(pattern).length
	end
end
end

# end of compatibility code
#---------------------------------------------------------------------
