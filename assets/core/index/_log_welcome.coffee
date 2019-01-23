# show welcome message if called directly
if require.main is module
	console.error "GridFW>>\tCould not be self run, See @Doc for more info, or run example"

# print console welcome message
_console_logo = (app) ->
	# print logo
	console.log """
\x1b[36m┌─────────────────────────────────────────────────────────────────────────────────────────┐

\t\t    _____ ______  _____ ______  _________ ___       ___  
\t\t   / ___ (   __ \\(_   _(_  __ \\(_   _____(  (       )  ) 
\t\t  / /   \\_) (__) ) | |   ) ) \\ \\ ) (___   \\  \\  _  /  /  
\t\t ( (  ___(    __/  | |  ( (   ) (   ___)   \\  \\/ \\/  /   
\t\t ( ( (__  ) \\ \\  _ | |   ) )  ) )) (        )   _   (    
\t\t  \\ \\__/ ( ( \\ \\_)_| |__/ /__/ /(   )       \\  ( )  /    
\t\t   \\____/ )_) \\__/_____(______/  \\_/         \\_/ \\_/ 

\t\t\tFramework version: #{app.version}
\x1b[36m ─────────────────────────────────────────────────────────────────────────────────────────\x1b[0m\n"""

_console_info = (app)->

	app.info 'CORE', '╒═════════════════════════════════════════════════════════════╕'
	app.info 'CORE', "\tREADY"
	# if dev mode or procution
	if app.mode is <%= app.PROD %>
		app.info 'CORE', "\t√ Production Mode"
	else
		app.warn 'CORE', "\tDeveloppement Mode."
		app.warn 'CORE', "\t[!] Enable prodution mode to boost performance"

	app.info 'CORE', "\t√ App name: #{app.s[<%=settings.name %>]}"
	app.info 'CORE', "\t√ App Author: #{app.s[<%=settings.author %>]}"
	app.info 'CORE', "\t√ Admin email: #{app.s[<%=settings.email %>]}"

	app.info 'CORE', "\t█ Server listening At: #{app.protocol}://#{app.host}:#{app.port}#{app.path}"
	app.info 'CORE', '╘═════════════════════════════════════════════════════════════╛'
	