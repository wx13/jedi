$screen = Antsy::Screen.new
$editor = Editor.new

$tester.test("SyntaxColors.new()"){
	syntax_colors = SyntaxColors.new
	syntax_colors
}

$tester.test("SyntaxColors.apply_rules"){
	sc = SyntaxColors.new
	$screen = Antsy::Screen.new
	$editor = Editor.new
	a,b,c = sc.apply_rules("foo ","bar baz",{/b/,/r/},:green)
	(a==("foo "+$color[:green]+"bar"+$color[:normal]))&&(b==" baz")&&(c)
}

$tester.test("SyntaxColors.apply_rules, no match"){
	sc = SyntaxColors.new
	a,b,c = sc.apply_rules("foo ","bar baz",{/B/,/r/},:green)
	(a=="foo ")&&(b=="bar baz")&&(!c)
}

$tester.test("SyntaxColors.syntax_color_string_comment"){
	sc = SyntaxColors.new
	a = sc.syntax_color_string_comment("foo bar baz", {/f/,/r/}, {/b/,/$/})
	a == $color[:string]+"foo bar"+$color[:normal]+" "+$color[:comment]\
		+ "baz" + $color[:normal]
}
