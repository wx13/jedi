require 'tempfile'

$tester.test("FileAccessor.new(non-existent file)"){
	file = FileAccessor.new('foo')
	text = file.read
	text == [""]
}

$tester.test("FileAccessor.new(empty file)"){
	tempfile = Tempfile.new('foo')
	file = FileAccessor.new(tempfile.path)
	text = file.read
	text == [""]
}

$tester.test("FileAccessor.read non-empty file"){
	tempfile = Tempfile.new('foo')
	File.open(tempfile.path,'w'){|f| f.print "foo\nbar"}
	file = FileAccessor.new(tempfile.path)
	text = file.read
	tempfile.unlink
	text == ["foo","bar"]
}

$tester.test("FileAccessor.save"){
	tempfile = Tempfile.new('foo')
	file = FileAccessor.new(tempfile.path)
	text = ["foo","bar"]
	file.save(TextBuffer.new(text))
	text2 = tempfile.read
	tempfile.unlink
	text2 == text.join("\n")
}

$tester.test("FileAccessor.update_indentation tabs"){
	tempfile = Tempfile.new('foo')
	text = [
		"  foo",
		"\tfoo",
		"\tfoo",
		"foo",
		"\t\tfoo",
		"\t\tfoo",
		"\t\tfoo",
		"\t\tfoo",
		"foo",
		"foo",
		"foo",
		"foo",
		"foo",
	]
	file = FileAccessor.new(tempfile.path)
	file.update_indentation(text)
	file.indentchar == "\t"
}

$tester.test("FileAccessor.update_indentation spaces"){
	tempfile = Tempfile.new('foo')
	text = [
		"\tfoo",
		"  foo",
		"  foo",
		"foo",
		"    foo",
		"    foo",
		"    foo",
		"    foo",
		"foo",
		"foo",
		"foo",
		"foo",
		"foo",
	]
	file = FileAccessor.new(tempfile.path)
	file.update_indentation(text)
	file.indentchar == " "
}


