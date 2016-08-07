#!/usr/bin/env node
options =
	'g': 
		alias: 'glob'
		describe: 'Specify the glob '
		type: 'string'
		demand: true
	'x': 
		alias: 'execute'
		describe: 'Command to execute upon file addition/change'
		type: 'string'
		demand: true


fs = require('fs')
path = require('path')
glob = require('glob')
exec = require('child_process').exec
yargs = require('yargs')
		.usage("Usage: -g <glob> -x <command>")
		.options(options)
		.help('h')
		.alias('h', 'help')
args = yargs.argv

globToRun = args.g || args.glob || args[0]
commandToExecute = args.x || args.execute || args[1]
help = args.h || args.help

regEx =
	placeholder: /\#\{([^\/\}]+)\}/ig


if help
	process.stdout.write(yargs.help());
	process.exit(0)


glob globToRun, (err, files)->
	if err then return console.log(err)
	
	@queue = files.slice()
	processPath(@queue.pop())


processPath = (filePath)-> if filePath
	executeCommandFor(filePath).then ()-> processPath(@queue.pop())


executeCommandFor = (filePath)-> new Promsie (resolve)->
	pathParams = path.parse filePath
	pathParams.reldir = getDirName(pathParams, path.resolve(filePath))

	console.log "Executing command for: #{filePath}"

	command = commandToExecute.replace regEx.placeholder, (entire, placeholder)->
		if placeholder is 'path'
			return filePath
		
		else if pathParams[placeholder]?
			return pathParams[placeholder]
		
		else return entire


	exec command, (err, stdout, stderr)->
		if err then console.log(err)
		if stdout then console.log(stdout)
		if stderr then console.log(stderr)
		resolve()



getDirName = (pathParams, filePath)->
	dirInGlob = globToRun.match(/^[^\*\/]*/)[0]
	dirInGlob += if dirInGlob then '/' else ''
	filePath
		.replace pathParams.base, ''
		.replace process.cwd()+"/#{dirInGlob}", ''
		.slice(0, -1)







