###
# Uncaugth Request Errors
###

# GridFW::onUncaughtError = 
_uncaughtRequestErrorHandler = (err, ctx, app)->
	# Get error code
	if typeof err is 'object'
		if err
			errCode = err.code or 500
		else
			err = 'Unknown Error!'
			errCode = 520
	else 
		errCode = err
	# Get error handler
	loop
		errorMap = ctx.app.s[<%= settings.errors %>]
		errorHandler= errorMap[errCode]
		break if errorHandler
		err = new GError errCode, "Error in sub app: #{ctx.app.name}", err
		ctx2 = ctx.parentCtx
		if ctx2
			ctx = ctx2
		else
			errorHandler= errorMap.else
			break
	# exec error handler
	v = await errorHandler ctx, errCode, err
	# post process
	await _handleRequestPostProcess ctx, v unless ctx.finished
	return
