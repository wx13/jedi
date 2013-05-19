class Test

	attr_accessor :verbose

	def initialize(options={})
		options = {:verbose=>false}.merge(options)
		@verbose = options[:verbose]
		@underline = "\e[4m"
		@green = "\e[32m"
		@red = "\e[31m"
		@normal = "\e[m"
		@error_count = 0
		@errors = []
		@test_count = 0
	end

	def section(name)
		puts @underline + name + @normal
	end

	def test(text="",options={})
		@test_count += 1
		options = {:verbose => @verbose,}.merge(options)
		print text + '...' if options[:verbose]
		if yield
			if options[:verbose]
				puts @green + "PASS" + @normal
			end
		else
			@error_count += 1
			@errors << text
			if options[:verbose]
				puts @red + "FAIL" + @normal
			else
				puts text + @red + " Failed" + @normal
			end
		end
	end

	def report
		puts @underline + "#{@test_count} tests" + @normal
		if @error_count == 0
			puts @green + "100% success" + @normal
		else
			puts @red + "#{@error_count} Failures" + @normal
			@errors.each{|str|
				puts "  #{str}"
			}
		end
	end

end


# Require all the files in 'src'.
Dir['../src/*.rb'].each{|src_file|
	require src_file
}

$tester = Test.new(:verbose=>false)

# Options
require 'optparse'
optparse = OptionParser.new{|opts|
	opts.on('-v','--verbose', 'verbose'){
		$tester.verbose = true
	}
}.parse!

if ARGV.empty?
	tests = Dir['*.rb']
	tests.delete(__FILE__)
else
	tests = ARGV
end

tests.each{|file|
	require file
}
$tester.report

