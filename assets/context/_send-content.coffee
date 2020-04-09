###*
 * Content methods
###

### content type ###
type: (type)->
	throw new Error 'type expected string' unless typeof type is 'string'
	@contentType = type
	this

###* STATUS CODE ###
status: (code, msg='')->
	@statusCode= code
	@statusMessage= msg
	this # chain

### ends request ###
end: (data)->
	new Promise (resolve, reject)=>
		super.end data, (err)->
			if err then reject err
			else do resolve

### response.write(chunk[, encoding], cb) ###
write: (chunk, encoding)->
	new Promise (resolve, reject)=>
		super.write chunk, encoding || '<%= DEFAULT_ENCODING %>', (err)->
			if err then reject err
			else resolve()

###* SEND JSON ###
json: (data)->
	# Serialize
	data= if @settings.pretty then (JSON.stringify data, null, "\t") else (JSON.stringify data)
	# Send data
	@contentType?= 'application/json'
	@send data

###* SEND JSONP ###
jsonp: (data)->
	settings= @settings
	# Serialize
	data= if settings.pretty then (JSON.stringify data, null, "\t") else (JSON.stringify data)
	# add cb name
	data = "#{settings.jsonp(this)}(#{data});"
	# Send data
	@contentType?= 'application/javascript'
	@send data

###* SEND XML ###
xml: (data)->
	settings= @settings
	data= XMLConverter.js2xml(data, spaces: if settings.pretty then "\t" else 0)
	@contentType?= 'application/xml'
	@send data

###*
 * Send file to the user
 * @param {string} path - file path
 * @param {Boolean} options.inline - Inline or attachement
 * @param {String} options.name - override file name
 * @param {Object} options - npm send options @see https://www.npmjs.com/package/send
###
sendFile: (path, options)->
	new Promise (resolve, reject)=>
		throw new Error 'path expected string' unless typeof path is 'string'
		path = EncodeUrl path
		# Options
		if options
			options.headers?= {}
		else
			options= {headers:{}}
		# add file name and content disposition
		options.headers['Content-Disposition'] ?= ContentDisposition options.name || path, type: if options.inline is false then 'attachment' else 'inline'
		# Prepare file streaming
		file = SendFile @req, path, options
		# flags
		streaming = off
		# done = no
		# Add callbacks
		file.on 'directory', ->
			reject new GError 'EISDIR', 'Expected file not directory!', new Error 'Expected file not directory!'
		file.on 'stream', ->
			streaming = on
			return
		file.on 'file', ->
			streaming = off
			return
		file.on 'error', (err) ->
			unless err
				err = new GError 0, 'Uncknown Error', new Error 'Uncknown Error'
			else if err.status is 404
				err = new GError '404-file', err.message, err
			else
				err = new GError err.code, err.message, err
			reject err
		file.on 'end', (event)->
			streaming = off
		# 	resolve event
		# Execute a callback when a HTTP request closes, finishes, or errors.
		OnFinishLib this, (err)->
			# err.code = 'ECONNRESET'
			reject err if err
			setImmediate ->
				if streaming
					reject new GError 'ECONNABORTED', 'Request aborted', new Error 'Request aborted'
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

download: (path, options)->
	# options
	if options
		options.inline= no
	else
		options= {inline: no}
	# send
	return @sendFile path, options

###*
 * send data to the user
 * @param {string | buffer | object} data - data to send
 * @return {Promise}
###
send: (data)->
	encoding = @encoding
	settings= @settings
	# set content type
	contentType = @contentType
	if typeof contentType is 'string'
		# fix content type
		contentType = MimeType.lookup contentType unless ~contentType.indexOf('/')
	else
		contentType = null
	# native request
	req = @req
	switch typeof data
		when 'string'
			contentType ?= 'text/html'
			data = Buffer.from data, encoding
		when 'object'
			if Buffer.isBuffer data
				contentType ?= 'application/octet-stream'
			else
				# Serialize object
				switch contentType
					when 'application/json'
						data= if settings.pretty then (JSON.stringify data, null, "\t") else (JSON.stringify data)
					when 'application/javascript'	# JSONP
						data= if settings.pretty then (JSON.stringify data, null, "\t") else (JSON.stringify data)
						data= "#{settings.jsonp(this)}(#{data});"
					when 'application/xml'
						data= XMLConverter.js2xml(data, spaces: if settings.pretty then "\t" else 0)
					else # JSON
						contentType?= 'application/json'
						data= if settings.pretty then (JSON.stringify data, null, "\t") else (JSON.stringify data)
				# convert to buffer
				data = Buffer.from data, encoding
		when 'undefined'
			contentType ?= 'text/plain'
			data = ''
		else
			contentType ?= 'text/plain'
			data = Buffer.from data.toString(), encoding
	# send headers
	if @headersSent
		@error 'SEND_DATA', 'Headers already sent!'
	else
		# ETag
		unless @hasHeader 'ETag'
			etag = settings.etag data
			@setHeader 'ETag', etag if etag
		
		# freshness
		@statusCode = 304 if req.fresh

		# strip irrelevant headers
		if @statusCode in [204, 304]
			@removeHeader 'Content-Type'
			@removeHeader 'Content-Length'
			@removeHeader 'Transfer-Encoding'
			data = ''
		else
			# populate Content-Length
			@setHeader 'Content-Length', @contentLength = data.length
			# set as header
			@setHeader 'Content-Type', if contentType then "#{contentType}; charset=#{encoding}" else 'application/octet-stream'

	# send
	if req.method is 'HEAD'
		return @end()
	else
		return @end data, encoding



