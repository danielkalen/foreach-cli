fs = require('fs')
path = require('path')
glob = require('glob')
chalk = require('chalk')
Listr = require '@danielkalen/listr'
exec = require('child_process').exec
regEx = require './regex'
module.exports = (options)-> new Promise (finish)->
	finalLogs = 'log':{}, 'error':{}

	glob options.glob, (err, files)-> if err then return console.error(err) else
		tasks = new Listr files.map((file)=>
			title: "Executing command: #{chalk.dim(file)}"		
			task: ()=> executeCommand(file)
		), options # same as {concurrent:options.concurrent}

		tasks.run().then(outputFinalLogs, outputFinalLogs)



	executeCommand = (filePath)-> new Promise (resolve, reject)->
		pathParams = path.parse path.resolve(filePath)
		pathParams.reldir = getDirName(pathParams, path.resolve(filePath))

		command = options.command.replace regEx.placeholder, (entire, placeholder)-> switch
			when placeholder is 'path' then filePath
			when pathParams[placeholder]? then pathParams[placeholder]
			else entire
		
		command = "FORCE_COLOR=true #{command}" if options.forceColor

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
		dirInGlob = options.glob.match(/^[^\*\/]*/)[0]
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

		finish()






