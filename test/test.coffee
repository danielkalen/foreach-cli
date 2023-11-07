PATH = require 'path'
execa = require 'execa'
fs = require 'fs-extra'
chai = require 'chai'
expect = chai.expect
should = chai.should()
bin = PATH.resolve 'bin'

parsePlaceholdersResult = (result) ->
	parsedResults = { lines: undefined, linesMap: {} }
	parsedResults.lines = result.split('\n').filter (validLine)-> validLine
	
	parsedResults.lines.forEach (resultLine) ->
		placeHoldersObj = {}
		placeHolders = resultLine.split(' ')
		placeHoldersObj.name = placeHolders[0]
		placeHoldersObj.ext = placeHolders[1]
		placeHoldersObj.base = placeHolders[2]
		placeHoldersObj.reldir = placeHolders[3]
		placeHoldersObj.path = placeHolders[4]
		placeHoldersObj.dir = placeHolders[5]
		parsedResults.linesMap[placeHoldersObj.path] = placeHoldersObj

	return parsedResults


suite "ForEach-cli", ()->
	suiteSetup (done)-> fs.ensureDir 'test/temp', done
	suiteTeardown (done)-> fs.remove 'test/temp', done
	
	test "Will execute a given command on all matched files/dirs in a given glob when using explicit arguments", ()->
		execa(bin, ['-g', 'test/samples/sass/css/*', '-x', 'echo {{base}} >> test/temp/one']).then (err)->
			result = fs.readFileSync 'test/temp/one', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			# Because there is 3, and all of them are within the list of 3. Then each of them makes a line
			expect(resultLines.length).to.equal 3
			expect(resultLines.find (line) -> line == 'foldr.css').to.be.truthy
			expect(resultLines.find (line) -> line == 'main.copy.css').to.be.truthy
			expect(resultLines.find (line) -> line == 'main.css').to.be.truthy

	
	test "Will execute a given command on all matched files/dirs in a given glob when using positional arguments", ()->
		execa(bin, ['test/samples/sass/css/*', 'echo {{base}} >> test/temp/two']).then (err)->
			result = fs.readFileSync 'test/temp/two', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 3
			expect(resultLines.find (line) -> line == 'foldr.css').to.be.truthy
			expect(resultLines.find (line) -> line == 'main.copy.css').to.be.truthy
			expect(resultLines.find (line) -> line == 'main.css').to.be.truthy
	


	test "Placeholders can be used in the command which will be dynamically filled according to the subject path", ()->
		execa(bin, ['-g', 'test/samples/sass/css/**/*', '-x', 'echo "{{name}} {{ext}} {{base}} {{reldir}} {{path}} {{dir}}" >> test/temp/three']).then (err)->
			result = fs.readFileSync 'test/temp/three', {encoding:'utf8'}
			
			parsedResult = parsePlaceholdersResult(result)

			# Check length
			expect(parsedResult.lines.length).to.equal 4

			# Check the paths
			[
				' test/samples/sass/css/foldr.css ',
				' test/samples/sass/css/foldr.css/sub.css ',
				' test/samples/sass/css/main.copy.css ',
				' test/samples/sass/css/main.css '
			].forEach (path) -> expect(result.includes(path)).to.be.truthy
			
			
			# We are using mapping to make tests pure, as Listr run doesn't gurantee the order of execution
			expectedResults = [
				# folder file match
				{
					path: 'test/samples/sass/css/foldr.css',
					name: 'foldr',
					ext: '.css',
					base: 'foldr.css',
					reldir: '',
					dir: "#{process.cwd()}/test/samples/sass/css" # because a folder
				},
				# ✨ Nested folder, and reldir
				{
					path: 'test/samples/sass/css/foldr.css/sub.css',
					name: 'sub',
					ext: '.css',
					base: 'sub.css',
					reldir: 'foldr.css',
					dir: "#{process.cwd()}/test/samples/sass/css/foldr.css"
				},
				{
					path: 'test/samples/sass/css/main.copy.css',
					name: 'main.copy',
					ext: '.css',
					base: 'main.copy.css',
					reldir: '',
					dir: "#{process.cwd()}/test/samples/sass/css"
				},
				{
					path: 'test/samples/sass/css/main.css',
					name: 'main',
					ext: '.css',
					base: 'main.css',
					reldir: '',
					dir: "#{process.cwd()}/test/samples/sass/css"
				}
			]

			for expected in expectedResults
				m = parsedResult.linesMap[expected.path]
				expect(m.name).to.equal expected.name
				expect(m.ext).to.equal expected.ext
				expect(m.base).to.equal expected.base
				expect(m.reldir).to.equal expected.reldir
				expect(m.path).to.equal expected.path
				expect(m.dir).to.equal expected.dir
				
	test "Placeholders can be denoted either with dual curly braces or a hash + single curly brace wrap", ()->
		execa(bin, ['-g', 'test/samples/sass/css/**/*', '-x', 'echo "#{name} #{ext} #{base} #{reldir} #{path} #{dir}" >> test/temp/four']).then (err)->
			result = fs.readFileSync 'test/temp/four', {encoding:'utf8'}
			parsedResult = parsePlaceholdersResult(result)

			# Check length
			expect(parsedResult.lines.length).to.equal 4

			# Check the paths
			[
				' test/samples/sass/css/foldr.css ',
				' test/samples/sass/css/foldr.css/sub.css ',
				' test/samples/sass/css/main.copy.css ',
				' test/samples/sass/css/main.css '
			].forEach (path) -> expect(result.includes(path)).to.be.truthy
			
			# We are using mapping to make tests pure, as Listr run doesn't gurantee the order of execution
			expectedResults = [
				# folder file match
				{
					path: 'test/samples/sass/css/foldr.css',
					name: 'foldr',
					ext: '.css',
					base: 'foldr.css',
					reldir: '',
					dir: "#{process.cwd()}/test/samples/sass/css" # because a folder
				},
				# ✨ Nested folder, and reldir
				{
					path: 'test/samples/sass/css/foldr.css/sub.css',
					name: 'sub',
					ext: '.css',
					base: 'sub.css',
					reldir: 'foldr.css',
					dir: "#{process.cwd()}/test/samples/sass/css/foldr.css"
				},
				{
					path: 'test/samples/sass/css/main.copy.css',
					name: 'main.copy',
					ext: '.css',
					base: 'main.copy.css',
					reldir: '',
					dir: "#{process.cwd()}/test/samples/sass/css"
				},
				{
					path: 'test/samples/sass/css/main.css',
					name: 'main',
					ext: '.css',
					base: 'main.css',
					reldir: '',
					dir: "#{process.cwd()}/test/samples/sass/css"
				}
			]

			for expected in expectedResults
				m = parsedResult.linesMap[expected.path]
				expect(m.name).to.equal expected.name
				expect(m.ext).to.equal expected.ext
				expect(m.base).to.equal expected.base
				expect(m.reldir).to.equal expected.reldir
				expect(m.path).to.equal expected.path
				expect(m.dir).to.equal expected.dir


	test "Will execute a given command on all matched files/dirs in a given glob with ignore option", ()->
		execa(bin, ['-g', 'test/samples/sass/css/*', '-i', '**/*copy*', '-x', 'echo {{base}} >> test/temp/five']).then (err)->
			result = fs.readFileSync 'test/temp/five', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 2
			expect(resultLines.find (line) -> line == 'foldr.css').to.be.truthy
			expect(resultLines.find (line) -> line == 'main.css').to.be.truthy


	test "Will execute a given command on all matched files in a given glob but ignoring the folders", ()->
		execa(bin, ['-g', 'test/samples/sass/css/*', '--nodir', 'true', '-x', 'echo {{base}} >> test/temp/six']).then (err)->
			result = fs.readFileSync 'test/temp/six', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine

			expect(resultLines.length).to.equal 2
			expect(resultLines.find (line) -> line == 'main.copy.css').to.be.truthy
			expect(resultLines.find (line) -> line == 'main.css').to.be.truthy


	test "Will execute a given command on all matched `.css` files in a given glob with ** but ignoring the folders", ()->
		execa(bin, ['-g', 'test/samples/sass/css/**/*.css', '--nodir', 'true', '-x', 'echo {{base}} >> test/temp/seven']).then (err)->
			result = fs.readFileSync 'test/temp/seven', {encoding:'utf8'}
			resultLines = result.split('\n').filter (validLine)-> validLine
			
			expect(resultLines.length).to.equal 3
			expect(resultLines.find (line) -> line == 'sub.css').to.be.truthy
			expect(resultLines.find (line) -> line == 'main.copy.css').to.be.truthy
			expect(resultLines.find (line) -> line == 'main.css').to.be.truthy
