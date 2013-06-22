$tester.test("TextBuffer.new"){
	t = TextBuffer.new(["foo","bar"])
	t == ["foo","bar"]
}

$tester.test("TextBuffer.replace"){
	t = TextBuffer.new(["foo","bar"])
	a = t
	t.replace(["foo","baz"])
	a == ["foo","baz"]
}

$tester.test("TextBuffer.delchar"){
	t = TextBuffer.new(["foo","bar"])
	t.delchar(1,1)
	t == ["foo","br"]
}

$tester.test("TextBuffer.insertchar"){
	t = TextBuffer.new(["foo","bar"])
	t.insertchar(1,1,'x')
	t == ["foo","bxar"]
}

$tester.test("TextBuffer.delrow"){
	t = TextBuffer.new(["foo","bar"])
	t.delrow(0)
	t == ["bar"]
}

$tester.test("TextBuffer.delrows"){
	t = TextBuffer.new(["foo","bar"])
	t.delrows(1,3)
	t == ["foo"]
}

$tester.test("TextBuffer.mergerows"){
	t = TextBuffer.new(["foo","bar"])
	t.mergerows(0,1)
	t == ["foobar"]
}

$tester.test("TextBuffer.splitrow"){
	t = TextBuffer.new(["foo","bar"])
	t.splitrow(0,1)
	t == ["f","oo","bar"]
}

$tester.test("TextBuffer.insertrow"){
	t = TextBuffer.new(["foo","bar"])
	t.insertrow(0,"hello")
	t == ["hello","foo","bar"]
}

$tester.test("TextBuffer.insertstr"){
	t = TextBuffer.new(["foo","bar"])
	t.insertstr(1,3,"xx")
	t == ["foo","barxx"]
}

$tester.test("TextBuffer.column_delete"){
	t = TextBuffer.new(["foo","bar","baz","buz"])
	t.column_delete(1,2,1)
	t == ["foo","br","bz","buz"]
}

$tester.test("TextBuffer.column_delete, folded"){
	t = TextBuffer.new(["foo","bar",["baz"],"buz"])
	t.column_delete(1,2,1)
	t == ["foo","br",["baz"],"buz"]
}

$tester.test("TextBuffer.hide_lines_at"){
	t = TextBuffer.new(["foo","bar","baz","buz"])
	t.hide_lines_at(1,2)
	t == ["foo",["bar","baz"],"buz"]
}

$tester.test("TextBuffer.hide_by_pattern"){
	t = TextBuffer.new(["foo","bar","baz","buz"])
	t.hide_by_pattern(/b../,/b../)
	t == ["foo",["bar","baz"],"buz"]
}

$tester.test("TextBuffer.unhide_lines"){
	t = TextBuffer.new(["foo","bar","baz","buz"])
	t.hide_by_pattern(/b../,/b../)
	t.unhide_lines(1)
	t == ["foo","bar","baz","buz"]
}

$tester.test("TextBuffer.unhide_all"){
	t = TextBuffer.new(["foo","bar","baz","buz"])
	t.hide_by_pattern(/b../,/b../)
	t.unhide_all
	t == ["foo","bar","baz","buz"]
}

$tester.test("TextBuffer.swap_indent_string"){
	t = TextBuffer.new(["foo","bar","baz","buz"])
	t.swap_indent_string("b","x")
	t == ["foo","xar","xaz","xuz"]
}

$tester.test("TextBuffer.get_leading_whitespace"){
	t = TextBuffer.new([" foo"," bar"," baz"," buz"])
	s = t.get_leading_whitespace(3)
	s == " b"
}

$tester.test("TextBuffer.justify"){
	t = TextBuffer.new([
		"foo bar baz buz",
		"foo bar baz buz"])
	t.justify(0,0,9,false)
	t == ["foo bar","baz buz","foo bar baz buz"]
}

$tester.test("TextBuffer.justify, linewrap"){
	t = TextBuffer.new([
		"foo bar baz buz",
		"foo bar baz buz"])
	t.justify(0,0,13,true)
	t == ["foo bar baz","buz foo bar", "baz buz"]
}

$tester.test("TextBuffer.justify, linewrap, long word"){
	t = TextBuffer.new(["-"*50])
	t2 = t.dup
	t.justify(0,0,25,true)
	t == t2
}

$tester.test("TextBuffer.next_match"){
	t = TextBuffer.new([
		"foo bar baz buz",
		"foo bar baz buz"])
	status, r, c, len = t.next_match(0,4,"foo")
	status == "Found match" && r == 1 && c == 0 && len == 3
}

$tester.test("TextBuffer.next_match, backward"){
	t = TextBuffer.new([
		"foo bar baz buz",
		"foo bar baz buz"])
	status, r, c, len = t.next_match(0,4,"foo",:dir=>:backward)
	status == "Found match" && r == 0 && c == 0 && len == 3
}


