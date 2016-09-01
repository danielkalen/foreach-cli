#!/usr/bin/env coffee
options =
	'g': 
		alias: 'glob'
		describe: 'Specify the glob '
		type: 'string'
	'x': 
		alias: 'execute'
		describe: 'Command to execute upon file addition/change'
		type: 'string'
	'c': 
		alias: 'forceColor'
		describe: 'Force color TTY output (pass --no-c to disable)'
		type: 'boolean'
		default: true
	'C': 
		alias: 'concurrent'
		describe: 'Execute commands concurrently (pass --no-C to disable)'
		type: 'boolean'
		default: true


fs = require('fs')
path = require('path')
glob = require('glob')
chalk = require('chalk')
Listr = require '@danielkalen/listr'
exec = require('child_process').exec
yargs = require('yargs')
		.usage("Usage: -g <glob> -x <command>  |or|  <glob> <command>\nPlaceholders can be either noted with double curly braces {{name}} or hash+surrounding curly braces \#{name}")
		.options(options)
		.help('h')
		.wrap(null)
		.version()
args = yargs.argv
globToRun = args.g or args.glob or args._[0]
commandToExecute = args.x or args.execute or args._[1]
forceColor = args.c or args.forceColor
concurrent = args.C or args.concurrent
help = args.h or args.help
regEx = placeholder: /(?:\#\{|\{\{)([^\/\}]+)(?:\}\}|\})/ig
finalLogs = 'log':{}, 'error':{}

if help or not globToRun or not commandToExecute
	process.stdout.write(yargs.help());
	process.exit(0)






## ==========================================================================
## Logic
## ========================================================================== 
glob globToRun, (err, files)-> if err then return console.error(err) else
	tasks = new Listr files.map((file)=>
		title: "Executing command: #{chalk.dim(file)}"		
		task: ()=> executeCommand(file)
	), {concurrent}

	tasks.run().then(outputFinalLogs, outputFinalLogs)




executeCommand = (filePath)-> new Promise (resolve, reject)->
	pathParams = path.parse path.resolve(filePath)
	pathParams.reldir = getDirName(pathParams, path.resolve(filePath))

	command = commandToExecute.replace regEx.placeholder, (entire, placeholder)-> switch
		when placeholder is 'path' then filePath
		when pathParams[placeholder]? then pathParams[placeholder]
		else entire
	
	command = "FORCE_COLOR=true #{command}" if forceColor

	exec command, (err, stdout, stderr)->
		if stdout then finalLogs.log[filePath] = stdout

		if stderr and not err
			finalLogs.log[filePath] = err
		else if err
			finalLogs.error[filePath] = stderr or err

		if err then reject() else resolve()













## ==========================================================================
## Helpers
## ========================================================================== 
getDirName = (pathParams, filePath)->
	dirInGlob = globToRun.match(/^[^\*\/]*/)[0]
	dirInGlob += if dirInGlob then '/' else ''
	filePath
		.replace pathParams.base, ''
		.replace process.cwd()+"/#{dirInGlob}", ''
		.slice(0, -1)






outputFinalLogs = ()-> if Object.keys(finalLogs.log).length or Object.keys(finalLogs.error).length
	process.stdout.write '\n\n'
	for file,message of finalLogs.log
		console.log chalk.bgWhite.black.bold("Output")+' '+chalk.dim(file)
		console.log message
	
	for file,message of finalLogs.error
		console.log chalk.bgRed.white.bold("Error")+' '+chalk.dim(file)
		console.log message






