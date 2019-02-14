###* wrapping context for sub apps ###
_defineProperty = Object.defineProperty
_create = Object.create
_assign= Object.assign
_getCtxOnce= (attr)->
	get: ->
		v = @parentCtx[attr]
		_defineProperty this, attr, value: v
		return v

#####################
# 	Context			#
#####################
exports.context= CTX_SUB_APP_WRAPPER= _create null
# Getters/Setters for attributes
['finished', 'headersSent', 'sendDate', 'statusCode', 'statusMessage', 'encoding', 'contentType', 'contentLength'].forEach (el)->
	CTX_SUB_APP_WRAPPER[el] =
		get: -> @parentCtx[el]
		set: (value)->
			@parentCtx[el] = value
			return
# getter once
['connection', 'socket', 'rawQuery'].forEach (el)->
	CTX_SUB_APP_WRAPPER[el] =
		get: ->
			parentCtx = @parentCtx
			v = parentCtx[el]
			_defineProperty this, el, value: v
			return v

# Wrappers for functions
['on', 'once', 'off', 'addTrailers', 'getHeader', 'getHeaderNames', 'getHeaders', 'hasHeader', 'removeHeader', 'setHeader', 'setTimeout', 'writeContinue', 'writeHead', 'writeProcessing'].forEach (el)->
	CTX_SUB_APP_WRAPPER[el] =
		get: ->
			parentCtx = @parentCtx
			fx = parentCtx[el].bind parentCtx
			_defineProperty this, el, value: fx
			return fx

# locals
CTX_SUB_APP_WRAPPER.locals= CTX_SUB_APP_WRAPPER.data= get: ->
	locals = _create @app.locals,
		ctx: value: this
	_assign locals, @parentCtx.locals # add specifique added info of parent context
	_defineProperty this, 'locals', value: locals
	return locals

#####################
# 	Request			#
#####################
exports.request= REQ_SUB_APP_WRAPPER= _create null
# Getters/Setters for attributes
['aborted', 'complete', 'headers', 'httpVersion', 'method', 'rawHeaders', 'rawTrailers', 'socket', 'statusCode', 'statusMessage', 'trailers', 'url'].forEach (el)->
	REQ_SUB_APP_WRAPPER[el] =
		get: -> @parentReq[el]
# Wrappers for functions
['on', 'once', 'off', 'destroy', 'setTimeout'].forEach (el)->
	REQ_SUB_APP_WRAPPER[el] =
		get: ->
			parentReq = @parentReq
			fx = parentReq[el].bind parentReq
			_defineProperty this, el, value: fx
			return fx
