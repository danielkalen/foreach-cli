#!/usr/bin/env coffee
options =
	'g': 
		alias: 'glob'
		describe: 'Specify the glob '
		type: 'string'
		demand: false
	'x': 
		alias: 'execute'
		describe: 'Command to execute upon file addition/change'
		type: 'string'
		demand: false


fs = require('fs')
path = require('path')
glob = require('glob')
chalk = require('chalk')
statusBar = require('node-status')
console = statusBar.console()
exec = require('child_process').exec
yargs = require('yargs')
		.usage("Usage: -g <glob> -x <command>  |or|  <glob> <command>\nPlaceholders can be either noted with double curly braces {{name}} or hash+surrounding curly braces \#{name}")
		.options(options)
		.help('h')
		.wrap(null)
		.version()
args = yargs.argv
globToRun = args.g || args.glob || args._[0]
commandToExecute = args.x || args.execute || args._[1]
help = args.h || args.help
regEx = placeholder: /(?:\#\{|\{\{)([^\/\}]+)(?:\}\}|\})/ig
finalLogs = 'log':{}, 'warn':{}, 'error':{}

if help or not globToRun or not commandToExecute
	process.stdout.write(yargs.help());
	process.exit(0)






## ==========================================================================
## Logic
## ========================================================================== 
glob globToRun, (err, files)-> if err then return console.error(err) else
	@progress = statusBar.addItem
		'type': ['bar', 'percentage']
		'name': 'Processed'
		'max': files.length
		'color': 'green'
	
	@errorCount = statusBar.addItem
		'type': 'count'
		'name': 'Errors'
		'color': 'red'

	@totalTime = statusBar.addItem
		'type': 'time'
		'name': 'Time'
	
	statusBar.start('invert':false, 'interval':20, 'uptime':false)

	@queue = files.slice()
	processPath(@queue.pop())





processPath = (filePath)->
	if filePath
		executeCommandFor(filePath).then ()-> processPath(@queue.pop())
	else
		statusBar.stop()
		outputFinalLogs()




executeCommandFor = (filePath)-> new Promise (resolve)->
	pathParams = path.parse path.resolve(filePath)
	pathParams.reldir = getDirName(pathParams, path.resolve(filePath))

	console.log "Executing command for: #{filePath}"
	@progress.inc()
	@totalTime.count = process.uptime()*1000

	command = commandToExecute.replace regEx.placeholder, (entire, placeholder)-> switch
		when placeholder is 'path' then filePath
		when pathParams[placeholder]? then pathParams[placeholder]
		else entire
		

	exec command, (err, stdout, stderr)->
		if err then finalLogs.warn[filePath] = err
		if stdout then finalLogs.log[filePath] = stdout
		if stderr then @errorCount.inc(); finalLogs.error[filePath] = stderr
		resolve()













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






outputFinalLogs = ()->
	for file,message of finalLogs.log
		console.log chalk.bgWhite.black.bold.underline(file)
		console.log message
	
	for file,message of finalLogs.warn
		console.log chalk.bgYellow.white.bold.underline(file)
		console.warn message
	
	for file,message of finalLogs.error
		console.log chalk.bgRed.white.bold.underline(file)
		console.error message






