###*
 * Flags
###
_defineProperties GridFw.prototype,
	### if the server is listening ###
	listening: get: -> @server?.listening or false

	# Max connections
	maxConnections:
		get: -> @server?.maxConnections
		set: (value)->
			throw new Error "Server not yet set!" unless server= @server
			@server.maxConnections = value
			return
