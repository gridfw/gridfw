# show welcome message if called directly
if require.main is module
	console.error "GridFW>>\tCould not be self run, See @Doc for more info, or run example"

# print console welcome message
_console_welcome = (app) ->
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
\x1b[0m"""
	# if dev mode or procution
	if app.mode is <%= app.PROD %>
		console.log "\tGridFW>> ✔ Production Mode"
	else
		console.log "\t\x1b[33mGridFW>> Developpement Mode\n\t[!] Do not forget to enable production mode to boost performance\x1b[0m"
	# running
	# console.log "\tGridFW>> Server listening At: #{app.protocol}://#{app.host}:#{app.port}#{app.path}"
	# server params
	console.log """

\tGridFW>> Running As:
\t\t✔︎ Name:\t\t #{app.s[<%=settings.name %>]}
\t\t✔︎ Autor:\t\t #{app.s[<%=settings.author %>]}
\t\t✔︎ Admin Email:\t\t #{app.s[<%=settings.email %>]}
\t\t✔︎ Framework version:\t #{app.version}
\x1b[36m└─────────────────────────────────────────────────────────────────────────────────────────┘\x1b[0m\n
"""
