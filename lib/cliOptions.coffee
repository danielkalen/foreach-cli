module.exports =
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