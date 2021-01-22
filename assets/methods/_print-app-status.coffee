###*
 * Print app status
###
printAppStatus: ->
	settings= @settings
	console.log Chalk.blueBright """
	╒═════════════════════════════════════════════════════════════════════════════╕

	\t\t  ██████╗ ██████╗ ██╗██████╗ ███████╗██╗    ██╗
	\t\t ██╔════╝ ██╔══██╗██║██╔══██╗██╔════╝██║    ██║
	\t\t ██║  ███╗██████╔╝██║██║  ██║█████╗  ██║ █╗ ██║
	\t\t ██║   ██║██╔══██╗██║██║  ██║██╔══╝  ██║███╗██║
	\t\t ╚██████╔╝██║  ██║██║██████╔╝██║     ╚███╔███╔╝
	\t\t  ╚═════╝ ╚═╝  ╚═╝╚═╝╚═════╝ ╚═╝      ╚══╝╚══╝
	\t\t\tFramework version: #{GridFw.version}

	\tREADY
	\t√ App name: #{settings.name or '<Unamed>'}
	\t√ App Author: #{settings.author or '<No author>'}
	\t√ Admin email: #{settings.email or '<No email>'}
	\t#{if settings.isProd then Chalk.green('√ Production Mode') else Chalk.keyword('orange')("[X] Development Mode.\n\t[!] Enable prodution mode to boost performance")}
	\t#{Chalk.green("█ Server listening At: #{@protocol}://#{@host}:#{@port}#{@path}")}
	╘═════════════════════════════════════════════════════════════════════════════╛
	"""
	return
