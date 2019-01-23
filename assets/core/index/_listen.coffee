
###*
 * Listen([port], options)
 * @optional @param {number} options.port - listening port @default to arbitrary generated one
 * @optional @param {string} options.protocol - if use 'http' or 'https' or 'http2' @default to http
 * @example
 * listen() # listen on arbitrary port
 * listen(3000) # listen on port 3000
 * listen
 * 		port: 3000
 * 		protocol: 'http' or 'https' or 'http2'
###
GridFW::listen= (options)->
	# waiting for app to be loaded
	await @[APP_STARTING_PROMISE]
	appSettings = @s
	# check options
	unless options
		options = {}
	else if typeof options is 'number'
		options= port: options
	else if typeof options is 'object'
		throw new Error 'Option.port expected positive integer' unless Number.isSafeInteger(options.port) and options.port >= 0
	else
		throw new Error 'Illegal argument'
	options.port ?= appSettings[<%= settings.port %>]
	options.protocol ?= appSettings[<%= settings.protocol %>]
	# get server factory
	protocol = options.protocol
	throw new Error "Protocol expected string" unless typeof protocol is 'string'
	protocol = protocol.toLowerCase()
	servFacto = SERVER_LISTENING_PROTOCOLS[protocol]
	throw new Error "Unsupported protocol: #{options.protocol}" unless servFacto
	# override server
	if @server
		@info 'CORE', 'Overriding underlying server'
		@server.close (err)=>
			if err
				@error 'CORE', err
			else
				@info 'CORE', 'Overrided server closed.'
	# create new server
	server = servFacto options, this
	# save infos
	@server= server
	@port= @ip= @ipType= @protocol= @host= @path= undefined
	# listen options
	listenOptions = if typeof options.port is 'number' then options.port else {}
	# run listener
	await new Promise (res, rej)=>
		server.listen listenOptions, (err)=>
			if err
				rej err
			else
				try
					# get port and host
					info = server.address()
					# bind basic data
					_defineProperties this,
						server	: value: server
						port	: value: info.port
						ip		: value: info.address
						ipType	: value: info.family
						host	: value: options.host || 'localhost'
						path	: value: options.path || '/'
						protocol: value: protocol
					# log
					_console_info this
					# resolve
					res this
				catch e
					rej e
	# enable the app
	await @enable()
	# ends
	return
				


### make server listening depending on the used protocol ###
SERVER_LISTENING_PROTOCOLS=
	http: (options, app)->
		app.debug 'CORE', 'Create HTTP server'
		http.createServer
			IncomingMessage : app.Request
			ServerResponse : app.Context
			# ,
			# app.handle.bind app