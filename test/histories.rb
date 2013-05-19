require 'tempfile'

$tester.test("Histories.new()"){
	tempfile = Tempfile.new('foo')
	$histories_file = tempfile.path
	hist = Histories.new
	hist
}

$tester.test("Histories.read empty file"){
	tempfile = Tempfile.new('foo')
	$histories_file = tempfile.path
	hist = Histories.new
	hist.read
	hist.search == []
}

$tester.test("Histories.save empty history"){
	tempfile = Tempfile.new('foo')
	$histories_file = tempfile.path
	hist = Histories.new
	hist.read
	hist.save
	hist.read
	hist.search == []
}

$tester.test("Histories.save non-empty history"){
	tempfile = Tempfile.new('foo')
	$histories_file = tempfile.path
	hist = Histories.new
	hist.read
	hist.search = ["hello","goodbye"]
	hist.save
	hist.read
	hist.search == ["hello","goodbye"]
}

