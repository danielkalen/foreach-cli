yargs = require('yargs')
		.usage("Usage: -g <glob> -x <command>  |or|  <glob> <command>\nPlaceholders can be either noted with double curly braces {{name}} or hash+surrounding curly braces \#{name}")
		.options(require './cliOptions')
		.help('h')
		.wrap(null)
		.version(()-> require('./package.json').version)
args = yargs.argv
requiresHelp = args.h or args.help
suppliedOptions =
	'glob': args.g or args.glob or args._[0]
	'command': args.x or args.execute or args._[1]
	'forceColor': args.c or args.forceColor
	'concurrent': args.C or args.concurrent

if requiresHelp or not suppliedOptions.glob or not suppliedOptions.command
	process.stdout.write(yargs.help());
	process.exit(0)


require('./foreach')(suppliedOptions)