chalk = require 'chalk'
regex = require './regex'

module.exports = (content)->
	content.replace regex.env_var, (e,variable)->
		console.warn("#{chalk.yellow 'WARN'} environment variable '#{variable}' is undefined") if not process.env[variable]?
		return process.env[variable] or ''

