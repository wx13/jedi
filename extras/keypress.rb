system('stty raw -echo')

print "\e[?9h"  # turn on mouse reporting

c = STDIN.getc.chr
if c=="\e"
	2.times{c += STDIN.getc.chr}
end
if c[2,1] == "M"  # mouse
	b = STDIN.getc
	x = STDIN.getc
	y = STDIN.getc
	puts b
	puts x
	puts y
end
if c == "\e[5" || c == "\e[6"
	c += STDIN.getc.chr
end
if c=="\e[1"
	c += STDIN.getc.chr
	c = "\e["
	2.times{c += STDIN.getc.chr}
end

puts c.inspect

print "\e[?9l"  # turn off mouse reporting

system('stty -raw echo')
