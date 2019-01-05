###
# Uncaugth Request Errors
###

GridFW::onUncaughtError = _uncaughtRequestErrorHandler = (err, ctx, app)->
	settings = app.s
	if err
		unless err.code?
			err = new GError 500, err.message, err
	else
		err = new GError 520, 'Unknown Error!'

	# everything unless 404 is a fatal error
	switch err.code
		when 404
			ctx.debug 'PAGE NOT FOUND', ctx.url
			errorKey = '404'
			statusCd = 404
		when '404-file'
			ctx.debug 'File NOT FOUND', ctx.url
			errorKey = '404-file'
			statusCd = 404
		else
			ctx.fatalError 'UNCAUGHT_ERROR', err
			errorKey = err.code or '500'
			statusCd = err.code
			statusCd = 500 unless typeof statusCd is 'number' and 400 <= statusCd < 600 and Number.isSafeInteger statusCd
	# render error
	unless ctx.finished
		# keys
		if app.mode is <%= app.DEV %>
			errorKey  =  'd' + errorKey
			defErrKey = 'd500'
		else
			defErrKey = '500'
		# status
		ctx.statusCode = statusCd
		ctx.contentType= 'html'
		# rener template
		errorTemplates = settings[<%= settings.errorTemplates %>]
		await ctx.render errorTemplates[errorKey] || errorTemplates[defErrKey], error: err
	return
