###*
 * HEADERS
###

### Append http header ###
addHeader: (name, value)->
	prev= @getHeader name
	unless prev
		prev = []
	else unless Array.isArray prev
		prev = [prev]
	prev.push value
	@setHeader name, prev
	# chain
	this

### request: return first accepted type based on accept header ###
accepts: (lst) -> @_accepts.types lst
### Request: Check if the given `encoding`s are accepted.###
acceptsEncodings: (lst)-> @_accepts.encodings lst
### Check if the given `charset`s are acceptable ###
acceptsCharsets: (lst)-> @_accepts.charsets lst
### Check if the given `lang`s are acceptable, ###
acceptsLanguages: (lgList)-> @_accepts.languages lgList

# Check if client supports webp images
acceptsWebp: -> !!((accept= @req.headers.accept) and ~accept.indexOf('image/webp'))
