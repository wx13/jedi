#!/bin/bash
#
# Generate zsh completion file from help screen output.
#

editor=$1

$editor -h | tail -n+2 | sed 's/,//' | \

awk '
BEGIN{
	print "#compdef editor"
	print "typeset -A opt_args"
	print "local context state line"
	print "_arguments -s -S \\"
}
{
	short_opt = $1
	long_opt = $2
	if ($3=="FILE")
	{
		$3 = ""
		files = ": file:_files"
	}
	else if (($3=="N")||($3=="c"))
	{
		$3 = ""
		files = ""
	}
	else
	{
		files = ""
	}
	$1 = ""
	$2 = ""
	print "    \"" short_opt "[" $0 "]" files "\"\\"
	print "    \"" long_opt "[" $0 "]" files "\"\\"
}
END{
	print "    \"*: file:_files \"\\"
	print "    && return 0"
	print "return 1"
}
'

