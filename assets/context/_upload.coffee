###*
 * Upload and parse post data
 * @param {Object} options.limits - @see busboy limits
 * @param {function} options.onError(error, ctx) - do what ever when got error, reject error to cancel process
###

_uploadPostData= (options)->
	if @_uploadP
		return @_uploadP
	else
		# options
		req = @req
		contentType = req.contentType?.type
		return Promise.reject new Error 'Content-type header is missing' unless contentType
		# limits
		options ?= _create null
		limits = options.uploadLimits
		if typeof limits is 'object' and limits
			Object.setPrototypeOf limits, @s[<%= settings.uploadLimits %>]
		else
			limits = options.uploadLimits = @s[<%= settings.uploadLimits %>]
		# body size limit
		bodySize = req.headers['content-length']
		throw new Error "Content length #{bodySize} exceeds #{limits.size}Bytes" if bodySize and bodySize > limits.size
		# switch content type
		console.log '----- contentType--------', contentType
		switch contentType
			when 'multipart/form-data', 'application/x-www-form-urlencoded'
				resultPromise = _uploadPostDataForm this, options
			when 'application/json'
				resultPromise = _uploadPostDataJSON this, options
			else # raw: application/octet-stream
				resultPromise = _uploadPostDataRaw this, options
		# return promise
		@_uploadP = resultPromise
		return resultPromise
###*
 * Upload form URL encoded and multipart data
###
_uploadPostDataForm = (ctx, options)->
	new Promise (resolve, reject)=>
		# options
		limits = options.uploadLimits
		uploadDir= options.dir || ctx.s[<%= settings.uploadDir %>]
		# result
		result = _create null
		errorHandle = options.onError
		files = []
		# busboy instance
		req = ctx.req
		busboy = new Busboy
			headers: req.headers
			limits: limits
		# error handling
		errorHandle = (err)->
			# abort all files loading
			for file in files
				try
					file.resume()
				catch err
					ctx.error 'busboy', err
			# reject
			reject err
			return
		# on finish
		busboy.on 'finish', ->
			clearTimeout uptimeout
			resolve result
		# when receive field
		busboy.on 'field', (fieldname, val, fieldnameTruncated, valTruncated)->
			try
				# handle error
				if fieldnameTruncated or valTruncated
					err = 
						fieldname: fieldname
						error: if fieldnameTruncated then 'fieldname truncated' else 'value truncated'
					if errorHandle
						errorHandle err
					else
						throw err
				# add value
				result[fieldname] = val
			catch err
				errorHandle err
		# when receive files
		onFile = options.onFile
		filePath= options.filePath
		busboy.on 'file', (fieldname, file, filename, encoding, mimetype) ->
			try
				# save file stream
				files.push file
				# process
				if onFile
					fPath = onFile filename, file, fieldname, encoding, mimetype
					throw new Error "onFile must returns a file path" unless typeof fPath is 'string'
				else
					# file path
					if filePath
						fPath = filePath filename
					else
						fPath = await _getTmpFileName uploadDir
					# pipe stream
					file.pipe NativeFs.createWriteStream fPath
				# create file descriptor
				result[fieldname] = 
					path:  fPath
					name:  filename
					encoding:  encoding
					mimetype:  mimetype
			catch err
				errorHandle err
			return
			
			# add to file
					# _uploadFile fd, filename, file, fieldname, encoding, mimetype
			# console.log 'File [' + fieldname + ']: filename: ' + filename + ', encoding: ' + encoding + ', mimetype: ' + mimetype
			# file.on 'data', (data)->
			# 	console.log "-------------( #{fieldname} ) : #{data.length}Bytes"
			# file.on 'end', ->
			# 	console.log " file recieved. #{fieldname} "
		# pipe busboy
		req.pipe busboy
		# timeout
		uptimeout = setTimeout (->
			errorHandle 'upload timeout'
		), options.timeout || ctx.s[<%= settings.uploadTimeout %>]
		return
###*
 * Text
###
_uploadPostDataText = (ctx, options)->
	new Promise (resolve, reject)=>
		# options
		limits = options.uploadLimits
		# upload all data
		getBody ctx.req, limits.size, (err, data)->
			if err
				reject err
			else
				try
					unless typeof data is 'string'
						data = data.toString 'utf-8'
					resolve data
				catch err
					reject err
				
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
		try
			# options
			limits = options.uploadLimits
			filePath= options.filePath
			onFile = options.onFile
			req = ctx.req
			uploadDir= options.dir || ctx.s[<%= settings.uploadDir %>]
			# stream
			stream = createStream req
			encoding = null
			mimetype = null
			filename = null
			# stream end
			stream.on 'end', ->
				resolve result
			# process
			if onFile
				fPath = onFile (_rand() + '.tmp'), stream, null, encoding, mimetype
				throw new Error "onFile must returns a file path" unless typeof fPath is 'string'
			else
				# file path
				if filePath
					fPath = filePath filename
				else
					fPath = await _getTmpFileName uploadDir
				# pipe stream
				console.log '----- fPath', fPath
				stream.pipe NativeFs.createWriteStream fPath
			# create file descriptor
			result = _create null,
				path: value: fPath
				name: value: filename
				encoding: value: encoding
				mimetype: value: mimetype
			# timeout
			uptimeout = setTimeout (->
				stream.resume()
				reject 'upload timeout'
			), options.timeout || ctx.s[<%= settings.uploadTimeout %>]
		catch err
			reject err
			stream.resume() if stream
		return
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
		charset = req.contentType?.charset
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
# saveFile = (stream, filePath, maxSize, cb) ->
# 	try
# 		# file stream
# 		fileStream = NativeFs.createWriteStream file
# 		# read stream
# 		state = stream._readableState
# 		throw new Error 'stream encoding should not be set' if (stream._decoder || (state && (state.encoding || state.decoder)))

# 		# listeners
# 		onAborted = -> cb 'aborted'
# 		cleanup= ->
# 			stream.removeListener 'aborted', onAborted
# 			stream.removeListener 'end', cb
# 			stream.removeListener 'close', cleanup
# 			return
# 		# add listeners
# 		stream.on 'aborted', onAborted
# 		stream.on 'end', cb
# 		stream.on 'close', cleanup
# 		# pipe stream
# 		stream.pipe fileStream
# 	catch err
# 		cb err

# create file tmp name
TMP_FILE_MAX_LOOP = 1000
TMP_FILE_CREATE_FLAGS= 'wx+'
TMP_FILE_MODE = 0o600
_getTmpFileName = (dir)->
	i = 0
	loop
		try
			fPath = Path.join dir, _rand() + 'tmp'
			fd= await fs.open fPath, TMP_FILE_CREATE_FLAGS, TMP_FILE_MODE
			await fs.close fd
			return fPath
		catch err
			throw err unless err.code is 'EEXIST'
		throw new Error "Fail to create file, loop out" if i > TMP_FILE_MAX_LOOP
	return

_rand = ->
	process.pid + Math.random().toString(36).substr(2)