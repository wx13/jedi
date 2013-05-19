$tester.test("initilize copybuffer"){
	copybuffer = CopyBuffer.new
	copybuffer
}

$tester.test("store text in the copy buffer"){
	copybuffer = CopyBuffer.new
	copybuffer.text += ["hello"]
	copybuffer.clear
	copybuffer.text += ["bye"]
	a = copybuffer.text
	a == ["bye"]
}
