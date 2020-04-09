'use strict'

http = require 'http'
Path = require 'path'
URL	 = require('url').URL
Fs	 = require 'fs'
MzFs = require 'mz/fs'

LRU	 = require('lru-ttl-cache')
ModuleCache= require 'module-cache'
FastDecode	= require 'fast-decode-uri-component'
EncodeUrl	= require 'encodeurl'

URLQueryParser= require 'querystringparser'
Chalk= require 'chalk'
PrettyFormat = require 'pretty-format'

# DOWNLOADER
ETag		= require 'etag'

# LOCAL LIBs
PKG=		require '../package.json'
GError=		require './error'
Context=	require './context'
Request=	require './request'

# CONSTS
ROUTER_MAX_LOOP= 10000 # max loop when seeking inside Router tree
PATH_PARAM= 0
QUERY_PARAM= 1

#=include utils/_index.coffee
#=include router/_index.coffee
module.exports= class GridFw
	# framework version
	@version: PKG.version
	###*
	 * app= new GridFw()
	 * app= new GridFw(require('path_to_cfg_file.json'))
	 * app= new GridFw(require('path_to_cfg_file.js'))
	 * app= new GridFw({options})
	###
	constructor: (options)->
		# LOG functions
		@debug=	LOG_IGNORE
		@info=	LOG_IGNORE
		@warn=	LOG_IGNORE
		@error=	LOG_IGNORE
		@fatalError=	LOG_IGNORE
		@_logLevel= null

		# locals
		@locals= @data= locals =
			app: this
			baseURL: null # app baseURL
		### App connection ###
		@server=	null
		@protocol=	null
		@host=		null
		@port=		null
		@path=		null
		@ip=		null
		@ipType=	null
		# @errors=	appOptions.errors
		# Request root wrappers
		@_wrappers= []
		# Routes
		# @_static= _create null # store static routes
		@_routes= _createMainRouteNode() # Router tree
		@_params= {} # Path params resolvers
		@_handler= null # Handler used as wrapper with the HTTP server

		# I18N
		@defaultLocale= null # Default locale
		@locales= []
		@_i18nPaths= {} # Map locals to filePaths

		# ROUTER CACHE
		@_routerCache= new LRU()
		# JS CACHE
		@_viewCache= new ModuleCache() # store view JS files
		@_i18nCache= new ModuleCache() # store view JS files

		# set config
		options?= {}
		@settings= GridFw._loadDefaultOptions(options.isProd)
		@setConfig options
		return
	# Router methods
	#=include router/_index-methods.coffee
	#=include methods/_*.coffee

	# CONSTS
	PATH_PARAM: PATH_PARAM
	QUERY_PARAM: QUERY_PARAM
#=include core/_index.coffee
