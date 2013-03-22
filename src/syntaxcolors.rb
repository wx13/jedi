#---------------------------------------------------------------------
# SyntaxColors class
#
# 1. Defines the syntax coloring
# 2. Contains methods for coloring lines of text.
#---------------------------------------------------------------------

class SyntaxColors

	attr_accessor :lc, :bc, :regex

	def initialize
		# Define per-language from-here-to-end-of-line comments.
		@lc = {
			:shell => ["#"],
			:git => ["#"],
			:ruby => ["#"],
			:perl => ["#"],
			:python => ["#"],
			:c => ["//"],
			:fortran => ["!",/^c/],
			:matlab => ["#","%"],
			:idl => [";"],
			:latex => ["%"],
		}
		@lc.default = []
		# Define per-language block comments.
		@bc = {
			:c => {"/*"=>"*/"},
			:html => {'<!--'=>'-->'},
		}
		@bc.default = {}
		# Define generic regexp syntax rules.
		@regex = {
			# Colorize long lines in fortran.
			:fortran => {/^[^cC][^!]{71,}.*$/=>:magenta},
			:latex => {/\\[^\s\{\\\[]*/ => :green},
		}
		@regex.default = {}
	end


	#
	# INPUT:
	#	bline -- string to add result to
	#	cline -- string to inspect
	#	cqc -- current quote character (to look for)
	# OUTPUT:
	#	bline -- updated bline string
	#	cline -- remainder of cline strin
	#
	def syntax_find_match(cline,cqc,bline)

		k = cline[1..-1].index(cqc)
		if k==nil
			# didn't find the character
			return nil
		end
		bline = cline[0].chr
		cline = cline[1..-1]
		while (k!=nil) && (k>0) && (cline[k-1].chr=="\\") do
			bline += cline[0,k+cqc.length]
			cline = cline[k+cqc.length..-1]
			break if cline == nil
			k = cline.index(cqc)
		end
		if k==nil
			bline += cline
			return(bline)
		end
		if cline == nil
			return(bline)
		end
		bline += cline[0..k+cqc.length-1]
		cline = cline[k+cqc.length..-1]
		return bline,cline
	end



	#
	# Do string and comment coloring.
	# INPUT:
	#   aline -- line of text to color
	#   lccs  -- line comment characters
	#            (list of characters that start comments to end-of-line)
	#   bccs  -- block comment characters
	#            (pairs of comment characters, such as /* */)
	# OUTPUT:
	#   line with color characters inserted
	#
	def syntax_color_string_comment(aline,lccs,bccs)

		# quote and regex characters
		dqc, sqc, rxc = '"', '\'', '/'

		# Flags to tell if we are in the middle of something
		dquote = squote = regx = comment = escape = false

		# Escape characters
		ere = $screen.escape_regexp

		# Temporaray string variables that we can chop apart without
		# messing with the real line.
		# cline will start as aline but get chopped up.
		# bline will start empty, and get filled up.
		cline = aline.dup
		bline = ""

		# Slowly much through cline until it is gone.
		while (cline!=nil)&&(cline.length>0) do

			# find first occurance of special character
			all = Regexp.union([lccs,bccs.keys,dqc,sqc,rxc,ere].flatten)
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

			# if eol comment, then we are done
			flag = false
			lccs.each{|str|
				if cline.index(str)==0
					bline += $color[:comment]
					# remove any other colors inside of the comment
					bline += cline.gsub(ere,'')
					bline += $color[:normal]
					flag = true
					break
				end
			}
			break if flag

			# block comments
			flag = false
			bccs.each{|sc,ec|
				if cline.index(sc)==0
					b,c = syntax_find_match(cline,ec,bline)
					if b != nil
						bline += $color[:comment]
						# remove any other colors inside of the comment
						bline += b.gsub(ere,'')
						bline += $color[:normal]
						cline = c
						flag = true
					end
				end
			}
			next if flag

			# if quote, then look for match
			if (cline[0].chr == sqc) || (cline[0].chr == dqc)
				cqc = cline[0].chr
				b,c = syntax_find_match(cline,cqc,bline)
				if b != nil
					bline += $color[:string]
					# remove any other colors inside of the comment
					bline += b.gsub(ere,'')
					bline += $color[:normal]
					cline = c
					next
				end
			end

			# if regex, look for match
			if (cline[0].chr == rxc)
				cqc = cline[0].chr
				b,c = syntax_find_match(cline,cqc,bline)
				if b != nil
					bline += $color[:regex]
					# remove any other colors inside of the comment
					bline += b.gsub(ere,'')
					bline += $color[:normal]
					cline = c
					next
				end
			end

			bline += cline[0].chr
			cline = cline[1..-1]
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
		aline = syntax_color_string_comment(aline,@lc[filetype],@bc[filetype])

		# trailing whitespace
		ere = Regexp.escape($color[:normal])
		re = Regexp.new /\s+/.source + "\(" + ere + "\)+" + /$/.source
		aline.gsub!(re,$color[:whitespace]+"\\0"+$color[:normal])

		return(aline)

	end

end

# end of SyntaxColors class
#---------------------------------------------------------------------


