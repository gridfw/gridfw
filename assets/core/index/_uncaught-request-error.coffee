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
	# Get handler
	errorMap = app.s[<%= settings.errors %>]
	errorHandler= errorMap[errCode] || errorMap.else
	v = await errorHandler ctx, errCode, err
	# post process
	await _handleRequestPostProcess ctx, v unless ctx.finished
	return
