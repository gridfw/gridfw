
_defineProperties CONTEXT_PROTO,
	###*
	 * set status code
	###
	status:		value: (status)->
		if typeof status is 'number'
			@statusCode = status
		else if typeof status is 'string'
			@statusMessage = status
		else
			throw new Error 'status expected number or string'
		this
	###*
	 * Send JSON
	 * @param {Object} data - data to parse
	###
	json: value: (data)->
		# stringify data
		if @app.s[<%= settings.pretty %>]
			data = JSON.stringify data, null, "\t"
		else
			data = JSON.stringify data
		# send data
		@contentType ?= 'application/json'
		@send data
	#TODO jsonp
	###*
	 * Send response
	 * @param {string | buffer | object} data - data to send
	###
	send:		value: (data)-> #TODO support user to specify if he wants JSON, Text, XML, ...
		encoding = @encoding
		# native request
		req = @req
		switch typeof data
			when 'string'
				@contentType ?= 'text/html'
				data = Buffer.from data, encoding
			when 'object'
				if Buffer.isBuffer data
					@contentType ?= 'application/octet-stream'
				else
					#TODO check accept header if we wants json or xml
					return @json data
			when 'undefined'
				@contentType ?= 'text/plain'
				data = ''
			else
				@contentType ?= 'text/plain'
				data = Buffer.from data.toString(), encoding
		# send headers
		if @headersSent
			@warn 'SEND_DATA', 'Headers already sent!'
		else
			# ETag
			unless @hasHeader 'ETag'
				etag = @s[<%= settings.etagFunction %>] data
				@setHeader 'ETag', etag if etag
			
			# freshness
			@statusCode = 304 if @statusCode isnt 304 and req.fresh

			# strip irrelevant headers
			if @statusCode in [204, 304]
				@removeHeader 'Content-Type'
				@removeHeader 'Content-Length'
				@removeHeader 'Transfer-Encoding'
				data = ''
			else
				# populate Content-Length
				@setHeader 'Content-Length', @contentLength = data.length
				# set content type
				contentType = @contentType
				if typeof contentType is 'string'
					# fix content type
					if contentType.indexOf('/') is -1
						contentType = mimeType.lookup contentType
						contentType = 'application/octet-stream' unless contentType
					# add encoding
					contentType = contentType.concat '; charset=', encoding
				else
					contentType = 'application/octet-stream'
				# set as header
				@setHeader 'Content-Type', contentType

		# send
		if req.method is 'HEAD'
			@end()
		else
			@end data, encoding

		# chain
		this
	###*
	 * Send file
	 * @param {string} path - file path
	 * @param {object} options - options
	###
	sendFile:	value: (path, options)->
		options ?= {}
		new Promise (resolve, reject)=>
			# control
			throw new Error 'path expected string' unless typeof path is 'string'
			path = encodeurl path

			# Prepare file streaming
			file = sendFile @req, path, options
			# flags
			streaming = off
			# done = no
			# Add callbacks
			file.on 'directory', ->
				reject new GError 'EISDIR', 'EISDIR, read'
			file.on 'stream', ->
				streaming = on
				return
			file.on 'file', ->
				streaming = off
				return
			file.on 'error', (err) ->
				unless err
					err = new GError 0, 'Uncknown Error'
				else if err.status is 404
					err = new GError '404-file', err.message, err
				else
					err = new GError err.code, err.message, err
				reject err
			file.on 'end', (event)->
				streaming = off
			# 	resolve event
			# Execute a callback when a HTTP request closes, finishes, or errors.
			onFinishLib this, (err)->
				# err.code = 'ECONNRESET'
				reject err if err
				setImmediate ->
					if streaming
						reject new GError 'ECONNABORTED', 'Request aborted'
					else
						resolve()
			# add headers
			if options.headers
				file.on 'headers', (res)->
					for k,v of options.headers
						res.setHeader k, v
			# pipe file
			file.pipe this
			return
	###*
	 * Download file
	 * @param {string} path - file path
	 * @optional @param {string} options.fileName - file name
	###
	download:	value: (path, options)->
		# set headers
		options ?= {}
		options.headers ?= {}
		options.headers['Content-Disposition'] = contentDisposition options.fileName || path
		# send
		@sendFile path, options

