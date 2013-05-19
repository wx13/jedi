$tester.test("string.partition"){
	x,y,z = "hello there, ned".partition(/,/)
	(x=="hello there") && (y==",") && (z==" ned")
}

$tester.test("string.rpartition"){
	x,y,z = "hello there, ned".rpartition("he")
	(x=="hello t")&&(y=="he")&&(z=="re, ned")
}

