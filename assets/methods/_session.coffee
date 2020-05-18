###***********
 * START SESSION
###
startSession: (ctx)->
	# Prepare
	request= ctx.request
	settings= request.settings
	cookieName= settings.sessionCookie
	cookie= request.cookies[cookieName]
	# create/get session
	session= await @getSessionDoc cookie, ctx
	ctx.session= session
	# if renew session cookie
	if session.renew
		ctx.setCookie? cookieName, session.id,
			expires: session.expires
			httpOnly: yes
			secure: settings.isProd # in prod, do not send this cookie unless https
	return


###***********
 * GET USER DOC
 * @param {String or null} id - session id or null if not yet started
 * @return {Object} session document: {renew:Boolean, expires: Number, ...}
 * @return {null} if session not found
###
getSessionDoc: (id, ctx)-> throw new Error "Please implement 'app.getSessionDoc(id)' to enable session"