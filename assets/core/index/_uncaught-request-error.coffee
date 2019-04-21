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
	else if typeof err is 'number'
		errCode = err
	else
		errCode= 500
	# check err code
	unless 400 <= errCode < 600
		errCode= 500
	# Get error handler
	loop
		errorMap = ctx.app.s[<%= settings.errors %>]
		errorHandler= errorMap[errCode]
		break if errorHandler
		ctx2 = ctx.parentCtx
		if ctx2
			err = new GError errCode, "Error @subApp: #{ctx.app.name}", err
			ctx = ctx2
		else
			errorHandler= errorMap.else
			break
	# exec error handler
	v = await errorHandler ctx, errCode, err
	# post process
	await _handleRequestPostProcess ctx, v unless ctx.finished
	return
