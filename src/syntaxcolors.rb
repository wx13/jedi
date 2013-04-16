#---------------------------------------------------------------------
# SyntaxColors class
#
# 1. Defines the syntax coloring
# 2. Contains methods for coloring lines of text.
#---------------------------------------------------------------------

class SyntaxColors

	attr_accessor :lc, :bc, :regex

	def initialize

		# Comments and strings are different than other regex's,
		# because they block each other.
		@strings = {}
		@strings.default = {'"'=>'"', "'"=>"'", '/'=>'/'}

		@comments = {
			:shell   => {'#'=>/$/},
			:ruby    => {'#'=>/$/},
			:perl    => {'#'=>/$/},
			:git     => {'#'=>/$/},
			:python  => {'#'=>/$/},
			:c       => {'//'=>/$/,'/*'=>'*/'},
			:fortran => {'!'=>/$/,/^[cC]/=>/$/},
			:idl     => {';'=>/$/},
			:latex   => {'%'=>/$/},
			:octave  => {'#'=>/$/,'%'=>/$/},
			:html    => {'<!--'=>'-->'},
		}
		@comments.default = {}

		# Define generic regexp syntax rules.
		@regex = {
			# Colorize long lines in fortran.
			:fortran => {/^[^cC][^!]{71,}.*$/=>:magenta},
			:latex => {/\\[^\s\{\\\[]*/ => :green},
		}
		@regex.default = {}

	end



	def apply_rules(bline,cline,rules,color)

		flag = false
		ere = $screen.escape_regexp

		rules.each{|sc,ec|
			if cline.index(sc)==0
				bline += $color[color]
				a,b,c = cline.partition(sc)
				bline += b
				a,b,c = c.partition(ec)
				bline += a.gsub(ere,'') + b + $color[:normal]
				cline = c
				flag = true
				break
			end
		}

		return bline, cline, flag

	end



	#
	# Do string and comment coloring.
	#
	def syntax_color_string_comment(aline,strings,comments)

		# Escape characters
		ere = $screen.escape_regexp

		# Temporaray string variables that we can chop apart without
		# messing with the real line.
		# cline will start as aline but get chopped up.
		# bline will start empty, and get filled up.
		cline = aline.dup
		bline = ""

		# Slowly much through cline until it is gone.
		while (cline)&&(cline.length>0) do

			# find first occurance of special character
			all = Regexp.union([strings.keys,comments.keys,ere].flatten)
			a,b,c = cline.partition(all)

			# Add uninteresting part to bline.
			bline += a
			break if b == ""

			# If the special string is a terminal escape sequence, then skip.
			if b.match(ere)
				bline += b
				cline = c
				next
			end

			cline = b + c

			bline,cline,flag = apply_rules(bline,cline,comments,:comment)
			next if flag
			bline,cline,flag = apply_rules(bline,cline,strings,:string)

		end
		aline = bline + $color[:normal]
		return aline
	end

	def syntax_color(sline,filetype,indentchar)

		# Don't waste time on empty lines.
		return(sline) if sline == ""

		# Make a copy that we can muck with.
		aline = sline.dup

		# general regex coloring
		@regex[filetype].each{|k,v|
			aline.gsub!(k,$color[v]+"\\0"+$color[:normal])
		}

		# leading whitespace
		if indentchar
			q = aline.partition(/\S/)
			q[0].gsub!(/([^#{indentchar}]+)/,$color[:whitespace]+"\\0"+$color[:normal])
			aline = q.join
		end

		# comments & quotes
		aline = syntax_color_string_comment(aline,@strings[filetype],@comments[filetype])

		# trailing whitespace
		ere = Regexp.escape($color[:normal])
		re = Regexp.new /\s+/.source + "\(" + ere + "\)+" + /$/.source
		aline.gsub!(re,$color[:whitespace]+"\\0"+$color[:normal])

		return(aline)

	end

end

# end of SyntaxColors class
#---------------------------------------------------------------------


