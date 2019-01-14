###*
 * Upload and parse post data
 * @param {Object} options.limits - @see busboy limits
###
Busboy = require 'busboy'
RawBody= require 'raw-body'
Zlib = require 'zlib'
Iconv= require 'iconv-lite'
NativeFs = require 'fs'

_uploadPostData= (options)->
	if @_body
		Promise.resolve @_body
	else
		# options
		req = ctx.req
		options ?= _create null
		contentType = ctx.contentType?.type
		return Promise.reject new Error 'Content-type header is missing' unless contentType
		# limits
		limits = options.uploadLimits
		if typeof limits is 'object' and limits
			Object.setPrototypeOf limits, ctx.s[<%= settings.uploadLimits %>]
		else
			options.uploadLimits = ctx.s[<%= settings.uploadLimits %>]
		# body size limit
		bodySize = req.headers['content-length']
		throw new Error "Content length #{bodySize} exceeds #{limits.size}Bytes" if bodySize and bodySize > limits.size
		# switch content type
		switch contentType
			when 'multipart/form-data', 'application/x-www-form-urlencoded'
				resultPromise = _uploadPostDataForm this, options
			when 'application/json'
				resultPromise = _uploadPostDataJSON this, options
			else # raw: application/octet-stream
				resultPromise = _uploadPostDataRaw this, options
		# return promise
		return resultPromise
###*
 * Upload form URL encoded and multipart data
###
_uploadPostDataForm = (ctx, options)->
	new Promise (resolve, reject)=>
		# options
		limits = options.uploadLimits
		# result
		@body= result = _create null 
		errors = []
		# busboy instance
		req = @req
		busboy = new Busboy
			headers: req.headers
			limits: limits
		# on finish
		busboy.on 'finish', ->
			resolve
				body: result
				errors: errors
		# when receive field
		busboy.on 'field', (fieldname, val, fieldnameTruncated, valTruncated)->
			result[fieldname] = val
			# if has errors
			if fieldnameTruncated
				errors.push
					field: fieldname,
					error: "field name truncated"
			if valTruncated
				errors.push
					field: fieldname,
					error: "field data truncated"
		# when receive files
		busboy.on 'file', (fieldname, file, filename, encoding, mimetype) ->
			console.log 'File [' + fieldname + ']: filename: ' + filename + ', encoding: ' + encoding + ', mimetype: ' + mimetype
			file.on 'data', (data)->
				console.log "-------------( #{fieldname} ) : #{data.length}Bytes"
			file.on 'end', ->
				console.log " file recieved. #{fieldname} "
		# pipe busboy
		req.pipe busboy


###*
 * Text
###
_uploadPostDataText = (ctx, options)->
	new Promise (resolve, reject)=>
		# options
		limits = options.uploadLimits
		# upload all data
		getBody ctx.req, options.limits.size, (err, data)->
			if err
				reject err
			else
				resolve data
###*
 * Upload and parse JSON
###
_uploadPostDataJSON = (ctx, options) ->
	_uploadPostDataText(ctx, options)
		.then (data)->
			if data.length
				JSON.parse data
			else
				{}
###*
 * Raw
###
_uploadPostDataRaw = (ctx, options)->
	new Promise (resolve, reject)=>
		# options
		limits = options.uploadLimits
		# save to file

### create stream ###
createStream = (req) ->
	# encoding
	encoding = req.headers['content-encoding']
	if encoding
		encoding = encoding.toLowerCase()
	else
		encoding = 'identity'
	# create stream
	switch encoding
		when 'deflate'
			stream = Zlib.createInflate()
			req.pipe stream
			bodySize = stream.length
		when 'gzip'
			stream = zlib.createGunzip()
			req.pipe stream
			bodySize = stream.length
		when 'identity'
			stream = req
			bodySize = req.headers['content-length']
		else
			throw new Error "Unsupported encoding: #{encoding}"
	return stream
### read request data ###
getBody = (req, maxSize, cb) ->
	try
		# charset
		charset = req.contentType.charset
		if charset
			throw new Error "Usupported charset: #{charset}" unless Iconv.encodingExists charset
		# stream
		stream = createStream req
		# upload
		RawBody stream, {limit: maxSize}, (err, body)->
			if err
				stream.resume() # read off entire request
				cb err
			else
				# decode
				unless typeof body is 'string' or not charset
					body = Iconv.decode body, charset
				cb null, body
	catch err
		cb err
	
### save to temp file ###
saveFile = (req, filePath, maxSize, cb) ->
	try
		# stream
		stream = createStream req
		# file stream
		fileStream = NativeFs.createWriteStream file
		# read stream
		state = stream._readableState
		throw new Error 'stream encoding should not be set' if (stream._decoder || (state && (state.encoding || state.decoder)))

		# listeners
		onAborted = -> cb 'aborted'
		cleanup= ->
			stream.removeListener 'aborted', onAborted
			stream.removeListener 'end', cb
			stream.removeListener 'close', cleanup
		# add listeners
		stream.on 'aborted', onAborted
		stream.on 'end', cb
		stream.on 'close', cleanup
		# pipe stream
		stream.pipe fileStream
	catch err
		cb err
	