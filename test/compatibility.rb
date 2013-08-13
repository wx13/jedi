$tester.test("string.partition"){
	x,y,z = "hello there, ned".partition(/,/)
	(x=="hello there") && (y==",") && (z==" ned")
}

$tester.test("string.partition 2"){
	x,y,z = "foo foo foo bar baz".partition(/^(foo )+/)
	(x=="") && (y=="foo foo foo ") && (z=="bar baz")
}

$tester.test("string.rpartition"){
	x,y,z = "hello there, ned".rpartition("he")
	(x=="hello t")&&(y=="he")&&(z=="re, ned")
}

