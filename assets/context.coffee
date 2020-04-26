'use strict'
###*
 * Request context == HTTP response
###
http		= require 'http'
URL			= require('url').URL
EncodeUrl	= require 'encodeurl'
Path		= require 'path'
MzFs		= require 'mz/fs'
Fs			= require 'fs'

ContentTypeParse = require('content-type').parse
proxyaddr  = require 'proxy-addr'
fresh		= require 'fresh'
Accepts		= require 'accepts'

# DOWNLOAD
ETag		= require 'etag'
SendFile	= require 'send'
ContentDisposition = require 'content-disposition'
MimeType	= require 'mime-types'
OnFinishLib	= require 'on-finished'
Buffer		= require('safe-buffer').Buffer
XMLConverter= require 'xml-js'

# UPLOAD
ParseRange = require 'range-parser'
Busboy = require 'busboy'
RawBody= require 'raw-body'
Zlib = require 'zlib'
Iconv= require 'iconv-lite'

# COOKIE
Cookie = require 'cookie'
CryptoJS = require('crypto-js')
AESCrypto = CryptoJS.AES

# LOCAL LIBs
GError= require './error'

#=include utils/_index.coffee

module.exports= class Context extends http.ServerResponse
	constructor: (socket)->
		super socket
		@app= null #current app
		@settings= null # current app settings
		@req= null # point current request object
		@request= null # alias of @req
		@locals= @data= null # TODO add locals when serving request
		# @timestamp= Date.now() # Current time
		@result= null # result to send to user: view to render, object to stringify, ...
		@contentLength= null # Content length
		@contentType= null # content type
		@encoding= null #TODO add app default encoding
		# URL data
		@route= null # current selected route
		@method= null
		@url= null
		@pathname= null
		@search= null
		@query= null
		@params= {} # Path params
		# I18N
		@locale= null # Current locale
		@i18n= null
		@session= null
		# Upload promise
		@_uploading= null
		return
	#=include context/_*.coffee

# GetterOnces
gettersOnce=
	#=include context/get-once/_*.coffee
_defineGettersOnce Context.prototype, gettersOnce
