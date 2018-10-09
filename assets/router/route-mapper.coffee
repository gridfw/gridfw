'use strict'

RouteNode = require './route-node'

###*
 * Route Mapper
 * map each http method to some RouteNode
###
class RouteMapper
	constructor: (@app, @route)->
		# create Regex
	# append new node
	append: (method, attrs)->
		# check for node
		if routeNode
			throw new Error "A controller already set to this route: #{method} #{@route}" if attrs.c and routeNode.c
		else
			routeNode = @[method] = new RouteNode @app, this, method
	
		# add controler
		if attrs.c
			v = attrs.c
			throw new Error 'The controller expected function' unless typeof v is 'function'
			throw new Error 'The controller expect exactly one argument' if v.length > 1
			routeNode.c = v
		# add handlers
		for k, v of attrs
			if v
				if k in ['c', '$']
					continue
				else if typeof v is 'function'
					(routeNode[k] ?= []).push v
				else if Array.isArray v
					# check is array of functions
					for a in v
						throw new Error 'Handler expected function' unless typeof a is 'function'
					# add
					ref= routeNode[k]
					# append handlers
					if ref
						for a in v
							ref.push a
					# add the whole array
					else
						routeNode[k] = v
				else
					throw new Error "Illegal node attribute: #{k}"
		# param resolvers
		if attrs.$
			ref = if @route is '/' then @app.$ else routeNode.$
			for k,v of attrs.$
				throw new Error "Param [#{k}] already set to route #{method} #{@route}" if ref[k]
				unless Array.isArray(v) and v.length is 2 and (!v[0] or v[0] instanceof RegExp) and (!v[1] or typeof v[1] is 'function')
					throw new Error "Illegal param format"
				ref[k] = v
		# chain
		this

module.exports = RouteMapper