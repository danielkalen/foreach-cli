fs = require 'fs-extra'
chai = require 'chai'
expect = chai.expect
should = chai.should()
exec = require('child_process').exec


suite "ForEach-cli", ()->
	suiteSetup (done)-> fs.ensureDir 'test/temp', done
	suiteTeardown (done)-> fs.remove 'test/temp', done
	
	test "Will execute a given command on all matched files/dirs in a given glob when using explicit arguments", (done)->
		exec "src/foreach.coffee -g 'test/samples/sass/css/*' -x 'echo {{base}} >> test/temp/one'", (err)->
			result = fs.readFileSync 'test/temp/one', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 2
			expect(resultLines[0]).to.equal 'main.css'
			expect(resultLines[1]).to.equal 'main.copy.css'
			done()
	

	
	test "Will execute a given command on all matched files/dirs in a given glob when using positional arguments", (done)->
		exec "src/foreach.coffee 'test/samples/sass/css/*' 'echo {{base}} >> test/temp/two'", (err)->
			result = fs.readFileSync 'test/temp/two', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 2
			expect(resultLines[0]).to.equal 'main.css'
			expect(resultLines[1]).to.equal 'main.copy.css'
			done()
	


	test "Placeholders can be used in the command which will be dynamically filled according to the subject path", (done)->
		exec "src/foreach.coffee -g 'test/samples/sass/css/*' -x 'echo \"{{name}} {{ext}} {{base}} {{reldir}} {{path}} {{dir}}\" >> test/temp/three'", (err)->
			result = fs.readFileSync 'test/temp/three', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 2
			expect(resultLines[0]).to.equal "main .css main.css samples/sass/css test/samples/sass/css/main.css #{process.cwd()}/test/samples/sass/css"
			expect(resultLines[1]).to.equal "main.copy .css main.copy.css samples/sass/css test/samples/sass/css/main.copy.css #{process.cwd()}/test/samples/sass/css"
			done()
	


	test "Placeholders can be denoted either with dual curly braces or a hash + single curly brace wrap", (done)->
		exec "src/foreach.coffee -g 'test/samples/sass/css/*' -x 'echo \"\#{name} \#{ext} \#{base} \#{reldir} \#{path} \#{dir}\" >> test/temp/four'", (err)->
			result = fs.readFileSync 'test/temp/four', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 2
			expect(resultLines[0]).to.equal "main .css main.css samples/sass/css test/samples/sass/css/main.css #{process.cwd()}/test/samples/sass/css"
			expect(resultLines[1]).to.equal "main.copy .css main.copy.css samples/sass/css test/samples/sass/css/main.copy.css #{process.cwd()}/test/samples/sass/css"
			done()

























