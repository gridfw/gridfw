###*
 * Start server listening
 * @example
 * 		app.listen()		# Start listening on specified port in configuration
 * 		app.listen(3000)	# Start listening on port 3000
 * 		app.listen({port:3000, protocol: 'http', baseURL: '/'})
###
listen: (options)->
	new Promise (resolve, reject)=>
		settings= @settings
		# Set configuration
		if options?
			if typeof options is 'number'
				@setConfig port: options
			else if typeof options is 'object'
				@setConfig options
			else
				throw new Error 'Illegal argument'
		# Close existing server
		if server= @server
			@info 'CORE', 'Changing underlying server'
			server.close (err)=>
				if err
					@fatalError 'CORE', err
				else
					@info 'CORE', 'Overrided underlying server is closed.'
		# create server
		@protocol= settings.protocol
		@path= @data.baseURL= settings.path
		switch @protocol
			when 'http'
				server= http.createServer
					IncomingMessage : Request
					ServerResponse : Context
			when 'https'
				#TODO
				throw new Error 'https not yeat supported'
			when 'http2'
				#TODO
				throw new Error 'http2 not yeat supported'
			else
				throw new Error "Unsupported protocol: #{settings.protocol}"
		@server= server
		# Start listening
		listeningOptions=
			port:		settings.port
			host:		settings.host
			ipv6Only:	settings.ipv6Only
		server.on 'request', @_handler= @handle.bind this
		server.listen listeningOptions, (err)=>
			if err
				reject err
			else
				try
					info = server.address()
					@port=	info.port
					@ip=	info.address
					@ipType=info.family
					@host=	listeningOptions.host
					@printAppStatus()
					resolve(this)
				catch err
					reject err
			return
		return

###*
 * Close server listening
###
close: ->
	new Promise (resolve, reject)=>
		if server= @server
			@info 'CORE', "Stopping listening at: #{@protocol}://#{@host}:#{@port}#{@path}"
			server.close (err)->
				if err then reject(err) else do resolve
				return
		else
			do resolve
		return