$tester.test("String.leading_occurances"){
	n,s = "foo foo foo bar baz".leading_occurances("foo ")
	(n==3) && (s=="bar baz")
}

$tester.test("String.leading_occurances (none)"){
	n,s = "foo foo foo bar baz".leading_occurances("food ")
	(n==0) && (s=="foo foo foo bar baz")
}

$tester.test("String.replace"){
	a = "cat"
	b = a
	b.replace("mouse")
	a == "mouse"
}

$tester.test("String.swap_indent_string"){
	s = "foo foo foo bar baz"
	s.swap_indent_string("foo ", "X")
	s == "XXXbar baz"
}

$tester.test("String.search_string, forward"){
	s = "How now brown cow?"
	n,m = s.search_string("brown")
	(n==8) && (m==5)
}

$tester.test("String.search_string, backward, regex"){
	s = "How now brown cow?"
	n,m = s.search_string(/.ow/,:backward)
	(n==14) && (m==3)
}

$tester.test("String.search_string, backward, regex, pos"){
	s = "How now brown cow?"
	n,m = s.search_string(/.ow/,:backward,10)
	(n==4) && (m==3)
}

$tester.test("Array.count"){
	a = ["a","b","c"]
	a.count(/[ab]/) == 2
}

