### build config file ###
data= require './settings'
fs = require 'fs'
path = require 'path'

# settings
appSettings = []
appSettingsCheck = []
appSettingsDefault = []

# replace settings with an array, with is faster at runtime
i=0
settings = data.settings
for k,v of settings
	settings[k] = i++
	appSettings.push v.value
	appSettingsCheck.push "#{k}: #{v.check.toString()}"
	if v.default
		appSettingsDefault.push "#{k}: #{v.default.toString()}"
# save build config
fnts = []
i=0
# stringify
appSettings = JSON.stringify appSettings, (k, v)->
	if typeof v is 'function'
		fnts.push v
		v = "__fx#{i}__"
		++i
	v
# replace with function expression
appSettings= appSettings.replace /"__fx(\d+)__"/g, (_, i)->
	fnts[i].toString()

appSettings = """
const path = require('path');
exports.config= #{appSettings};
exports.kies= #{JSON.stringify(settings)};
exports.check = {#{appSettingsCheck.join(',')}};
exports.default = {#{appSettingsDefault.join(',')}};
"""

# save
fs.writeFileSync path.join(__dirname, 'config.js') , appSettings

