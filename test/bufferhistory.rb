require 'tempfile'

$tester.test("BufferHistory.new()"){
	bh = BufferHistory.new(["foo","bar"],0,0)
	bh
}

$tester.test("BufferHistory.text"){
	bh = BufferHistory.new(["foo","bar"],0,0)
	bh.text == ["foo","bar"]
}

$tester.test("BufferHistory.add"){
	bh = BufferHistory.new(["foo","bar"],0,0)
	bh.add(["foo","bar","baz"],0,1)
	bh.add(["foo","bar","buz"],1,1)
	bh.add(["foo"],0,1)
	bh.text == ["foo"] && bh.row == 0 && bh.col == 1
}

$tester.test("BufferHistory.undo"){
	bh = BufferHistory.new(["foo","bar"],0,0)
	bh.add(["foo","bar","baz"],0,1)
	bh.add(["foo","bar","buz"],1,1)
	bh.add(["foo"],0,1)
	bh.undo(0,1)
	bh.text == ["foo","bar","buz"] && bh.row == 1 && bh.col == 1
}

$tester.test("BufferHistory.redo"){
	bh = BufferHistory.new(["foo","bar"],0,0)
	bh.add(["foo","bar","baz"],0,1)
	bh.add(["foo","bar","buz"],1,1)
	bh.add(["foo"],0,1)
	bh.undo(0,1)
	bh.redo(0,1)
	bh.text == ["foo"] && bh.row == 0 && bh.col == 1
}

$tester.test("BufferHistory.save/revert"){
	bh = BufferHistory.new(["foo","bar"],0,0)
	bh.add(["foo","bar","buz"],1,1)
	bh.save
	bh.add(["foo"],0,1)
	bh.add(["foo","bar","baz"],0,1)
	bh.revert_to_saved
	bh.text == ["foo","bar","buz"] && bh.row == 1 && bh.col == 1
}

$tester.test("BufferHistory.modified?"){
	bh = BufferHistory.new(["foo","bar"],0,0)
	bh.add(["foo","bar","buz"],1,1)
	bh.save
	bh.add(["foo"],0,1)
	bh.add(["foo","bar","baz"],0,1)
	bh.modified?
}

$tester.test("BufferHistory.backup/load"){
	tempfile = Tempfile.new('test')
	bh = BufferHistory.new(["foo","bar"],0,0)
	bh.add(["foo","bar","buz"],1,1)
	bh.save
	bh.add(["foo"],0,1)
	bh.backup(tempfile.path)
	bh = BufferHistory.new([],0,0)
	bh.load(tempfile.path)
	bh.revert_to_saved
	bh.text == ["foo","bar","buz"]
}

$tester.test("BufferHistory.swap_indent_string"){
	text = ["foo","    bar"]
	bh = BufferHistory.new(text,0,0)
	text[0] = "  foo"
	bh.add(text,0,0)
	bh.swap_indent_string("  ","\t")
	bh.undo(0,0)
	bh.text == ["foo","\t\tbar"]
}

