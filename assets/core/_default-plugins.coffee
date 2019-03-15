###*
 * Default plugins
###
_PLUGINS =
	# cookie manager
	cookie:
		require: 'gridfw-cookie'
		secret: 'gw'
	# render
	render:
		require: 'gridfw-render'
		views: 'views'
	# downloader
	downloader:
		require: 'gridfw-downloader'
		etag: true # add etag http header
		pretty: true # show json and xml in pretty format
		jsonp: (ctx)-> ctx.query.cb or 'callback' # jsonp callback name
	# uploader
	uploader:
		require: 'gridfw-uploader'
		timeout: 10 * 60 * 1000 # Upload timeout
		tmpDir: require('os').tmpdir() # where to store tmp files, default to os.tmp
		limits: # Upload limits
			size: 20 * (2**20) # Max body size (20M)
			fieldNameSize: 1000 # Max field name size (in bytes)
			fieldSize: 2**20 # Max field value size (default 1M)
			fields: 1000 # Max number of non-file fields
			fileSize: 10 * (2**20) # For multipart forms, the max file size (in bytes) (default 10M)
			files: 100 # For multipart forms, the max number of file fields
			parts: 1000 # For multipart forms, the max number of parts (fields + files) 
			headerPairs: 2000 # For multipart forms, the max number of header 

