###*
 * Upload
###

###*
 * Parse Range header field, capping to the given `size`.
 *
 * Unspecified ranges such as "0-" require knowledge of your resource length. In
 * the case of a byte range this is of course the total number of bytes. If the
 * Range header field is not given `undefined` is returned, `-1` when unsatisfiable,
 * and `-2` when syntactically invalid.
 *
 * When ranges are returned, the array has a "type" property which is the type of
 * range that is required (most commonly, "bytes"). Each array element is an object
 * with a "start" and "end" property for the portion of the range.
 *
 * The "combine" option can be set to `true` and overlapping & adjacent ranges
 * will be combined into a single range.
 *
 * NOTE: remember that ranges are inclusive, so for example "Range: users=0-3"
 * should respond with 4 users when available, not 3.
 *
 * @param {number} size
 * @param {object} [options]
 * @param {boolean} [options.combine=false]
 * @return {number|array}
 * @public
 ###
range: (size, options) ->
	range = @getHeader 'Range'
	if range
		ParseRange size, range, options

###*
 * Upload and parse post data
 * @optional @param {Object} options.limits - @see busboy limits
 * @optional @param {[type]} options.type - mimetype or list of mimetypes of uploaded data @default: undefined: all types are accepted
 * @optional @param {function} options.progress - Callback(chunkBytes, receivedBytes, totalBytes) for upload progress
 * 
 * @optional @param {function} options.onFile - Callback(filename, fileStream, fieldname, encoding, mimetype) add custom file upload behaviour and returns the path to that file (or any string)
 * @optional @param {function} options.filePath - Callback(filename, fieldname, mimetype) set target path to the uploaded file
 * @optional @param {Array<String>} options.extensions - List of accepted file extensions
 * @optional @param {Boolean} options.keepExtension - do not change file extension to ".tmp"
 * @optional @param {Array<String>} options.fileFields - list of accepted fields to contain files
 *
 * @optional @param {Boolean} parse - do parse JSON and XML. Save as file otherwise
 * 
###
upload: do ->
	###* create stream ###
	createStream = (req) ->
		# encoding
		if encoding = req.headers['content-encoding']
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
	# Upload post body to memory
	getBody= (req, maxSize, resolve, reject) ->
		try
			# charset
			if charset = req.contentType?.charset
				throw new Error "Usupported charset: #{charset}" unless Iconv.encodingExists charset
			# stream
			stream = createStream req
			# upload
			RawBody stream, {limit: maxSize}, (err, body)->
				try
					if err
						stream.resume() # read off entire request
						reject err
					else
						unless typeof body is 'string' or not charset
							body = Iconv.decode body, charset
						resolve body
				catch err
					reject err
		catch err
			reject err
			stream.resume() if stream
		return
	# Remove uploaded files
	_formDataRemoveFiles= ->
		if tmpFiles= @_tmpFiles
			await MzFs.unlink path for path in tmpFiles
		return
	# Create tmp file name
	TMP_FILE_MAX_LOOP = 1000
	_getTmpFileName = (dir, ext)->
		i= 0
		tmpf= "#{process.pid}-#{Date.now().toString(36)}"
		loop
			try
				fPath = Path.join dir, "#{tmpf}-#{i.toString(36)}#{ext}"
				fd= await MzFs.open fPath, 'wx+', 0o600
				await MzFs.close fd
				return fPath
			catch err
				throw err unless err.code is 'EEXIST'
			throw new Error "Fail to create file, loop out #{TMP_FILE_MAX_LOOP}" if i > TMP_FILE_MAX_LOOP
		return
	###* UPLOAD FORM URL ENCODED AND MULTIPART DATA ###
	_addField= (result, fieldname, value)->
		if vl= result[fieldname]
			if _isArray vl
				vl.push value
			else
				result[fieldname]= [vl, value]
		else
			result[fieldname]= value
		return
	# Upload form data
	_uploadFormData= (ctx, options, limits, settings, resolve, reject)->
		# Upload directory
		uploadDir= options.dir or settings.upload_dir
		# Result
		result=
			removeTmpFiles: _formDataRemoveFiles
			clear: _formDataRemoveFiles
			_tmpFiles: []
		# init
		files = []
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
				catch e
					ctx.error 'BUSBOY', e
			# reject
			reject err
			return
		# on finish
		busboy.on 'finish', ->
			clearTimeout uptimeout
			resolve result
			return
		# when receive field
		busboy.on 'field', (fieldname, val, fieldnameTruncated, valTruncated)->
			try
				# handle error
				throw {
					fieldname: fieldname
					error: if fieldnameTruncated then 'fieldname truncated' else 'value truncated'
				} if fieldnameTruncated or valTruncated
				# add value
				_addField result, fieldname, val
			catch err
				errorHandle err
			return
		# when receive files
		onFile = options.onFile
		filePath= options.filePath
		# file options
		fileExtensions= options.extensions
		keepExtension= options.keepExtension or false
		fileFields= options.fileFields
		# on file
		busboy.on 'file', (fieldname, file, filename, encoding, mimetype) ->
			try
				# check fieldname
				if fileFields and fieldname not in fileFields
					throw "Rejected file field: #{fieldname}"
				# save file stream
				files.push file
				# process
				if onFile
					fPath = onFile filename, file, fieldname, encoding, mimetype
					throw "Options.onFile expected to return a file path" unless typeof fPath is 'string'
				else
					# file path
					if filePath
						fPath = filePath filename, fieldname, mimetype
						throw "Options.filePath expected to return a file path" unless typeof fPath is 'string'
					else
						# check extension
						ext= Path.extname(filename).toLowerCase()
						if fileExtensions
							throw "Rejected extension: [#{ext}], accepted are: #{fileExtensions.join ','}" if ext not in fileExtensions
						fPath = await _getTmpFileName uploadDir, if keepExtension then ext else '.tmp'
						# add to tmp files array
						result._tmpFiles.push fPath
					# pipe stream
					file.pipe Fs.createWriteStream fPath
				# create file descriptor
				_addField result, fieldname,
					path:  fPath
					name:  filename
					encoding:  encoding
					mimetype:  mimetype
			catch err
				err= new Error err if typeof err is 'string'
				errorHandle err
			return
		# ERRORS
		busboy.on 'partsLimit', ->
			errorHandle('partsLimit')
			return
		busboy.on 'filesLimit', ->
			errorHandle('filesLimit')
			return
		busboy.on 'fieldsLimit', ->
			errorHandle('fieldsLimit')
			return
		# pipe busboy
		req.pipe busboy
		# timeout
		uptimeout = setTimeout (-> errorHandle 'upload timeout'), options.timeout || settings.upload_timeout
		return
	# # Upload Text data
	# _uploadText= (ctx, limits, resolve, reject)->
	# 	resolveData= (data)->
	# 		try
	# 			data = data.toString 'utf-8' unless typeof data is 'string'
	# 			resolve data
	# 		catch err
	# 			reject err
	# 	getBody ctx.req, limits.size, resolveData, reject
	# 	return
	# Upload JSON data
	_uploadJsonXml= (ctx, contentType, limits, resolve, reject)->
		resolveData= (data)->
			try
				data = data.toString 'utf-8' unless typeof data is 'string'
				if data.length
					if contentType is 'application/xml'
						data= XMLConverter.xml2js data
					else
						data= JSON.parse data
				else
					data= {}
				resolve data
			catch err
				reject err
		getBody ctx.req, limits.size, resolveData, reject
		return
	# Upload raw data
	_uploadRaw= (ctx, options, limits, settings, resolve, reject)->
		try
			# init
			filePath= options.filePath
			onFile = options.onFile
			req = ctx.req
			uploadDir= options.dir or settings.upload_dir
			# stream
			stream = createStream req
			# create file descriptor
			result =
				path: null
				name: 'untitled.tmp'
				encoding: null
				mimetype: null
			# stream end
			stream.on 'end', ->
				resolve result
				return
			# process
			if onFile
				fPath = onFile result.name, stream, null, result.encoding, result.mimetype
				throw new Error "Options.onFile expected to return a file path" unless typeof fPath is 'string'
			else
				# file path
				if filePath
					fPath = filePath result.name
					throw new Error "Options.filePath expected to return a file path" unless typeof fPath is 'string'
				else
					fPath = await _getTmpFileName uploadDir, '.tmp'
				# pipe stream
				stream.pipe Fs.createWriteStream fPath
			# create file descriptor
			result.path= fPath
			# timeout
			uptimeout = setTimeout (->
				stream.resume()
				reject 'upload timeout'
			), options.timeout or settings.upload_timeout
		catch err
			reject err
			stream.resume() if stream
		return
	# Interface
	return (options)->
		@_uploading or @_uploading= new Promise (resolve, reject)=>
			# options
			req = @req
			contentType = req.contentType?.type
			throw new Error 'Content-type header is missing' unless contentType
			# Options
			settings= @settings
			options?= {}
			# Limits
			if options.limits
				limits= _assign {}, options.limits, settings.upload_limits
			else
				limits= settings.upload_limits
			# body size limit
			bodySize = req.headers['content-length']
			throw new Error "data[ #{bodySize}B ] exceeds #{limits.size}B" if bodySize and bodySize > limits.size
			# upload progress
			if 'progress' of options
				onProgress = options.progress
				progressReceived = 0
				req.on 'data', (data)->
					len = data.length
					progressReceived += len
					onProgress len, progressReceived, bodySize
			# check options type
			if type= options.type
				if _isArray type
					for tp,i in type
						type[i]= MimeType.lookup tp unless ~tp.indexOf('/')
					throw new Error "Received type: #{contentType}. Expected: #{type.join ','}" unless contentType in type
				else
					type = MimeType.lookup type unless ~type.indexOf('/')
					throw new Error "Received type: #{contentType}. Expected: #{type}" unless contentType is type
			# Upload DATA
			switch contentType
				when 'multipart/form-data', 'application/x-www-form-urlencoded'
					_uploadFormData this, options, limits, settings, resolve, reject
				when 'application/json', 'application/xml'
					if (if typeof options.parse is 'boolean' then options.parse else settings.upload_parse)
						_uploadJsonXml this, contentType, limits, resolve, reject
					else
						_uploadRaw this, options, limits, settings, resolve, reject
				else # raw: application/octet-stream
					_uploadRaw this, options, limits, settings, resolve, reject
			return



