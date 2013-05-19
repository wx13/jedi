require 'tempfile'
$editor = Editor.new

$tester.test("BuffersList.new, no list"){
	b = BuffersList.new
	b
}

$tester.test("BuffersList.new, non-existent file"){
	b = BuffersList.new(['foo123321123321'])
	b
}

$tester.test("BuffersList.new, existent file"){
	file = Tempfile.new(['foo'])
	b = BuffersList.new(file.path)
	b
}

$tester.test("BuffersList.new, multiple files"){
	b = BuffersList.new(['foo','bar','baz'])
	b
}

$tester.test("BuffersList.current"){
	b = BuffersList.new(['foo','bar','baz'])
	b.current.file.name == 'foo'
}

