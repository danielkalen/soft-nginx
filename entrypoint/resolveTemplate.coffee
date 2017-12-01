fs = require 'fs-jetpack'
memoize = require 'fast-memoize'
regex = require './regex'
dateFormat = require 'sugar/date/format'
TEMPLATES = './config/template'
# indentString = require 'indent-string'
# indentString(result, 1, indent:whitespace)

resolveTemplate = (target, data, hosts)->
	Promise.resolve(target)
		.then getTemplate
		.then (template)-> replace(template, data, hosts)


replace = (content, data, hosts)->
	globals = datestamp:dateFormat(new Date, '%F')
	
	content.replace regex.placeholder, (e,placeholder)->
		if placeholder[0] is '@'
			match = hosts.find (host)-> host.name is placeholder.slice(1)
			return match?.address or ''
		
		return globals[placeholder] or data[placeholder] or ''


getTemplate = memoize (target)->
	fs.readAsync "#{TEMPLATES}/#{target}.conf"


module.exports = resolveTemplate
module.exports.replace = replace