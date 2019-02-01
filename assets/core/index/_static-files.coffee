###*
 * Serv static files
###
GridFW::static = (filePath, options)->
	# return controller
	(ctx)->
		fPath = filePath
		if ctx.params['*']
			fPath = Path.join filePath, ctx.params['*']
		# return send file promise
		ctx.sendFile fPath, options