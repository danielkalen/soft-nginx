fs = require 'fs-jetpack'
memoize = require 'fast-memoize'
regex = require './regex'
TEMPLATES = './config/template'

resolveTemplate = (target, data, hosts)->
	Promise.resolve(target)
		.then getTemplate
		.then (template)-> replace(template, data, hosts)


replace = (content, data, hosts)->
	content.replace regex.placeholder, (e,placeholder)->
		if placeholder[0] is '@'
			match = hosts.find (host)-> host.name is placeholder.slice(1)
			return match?.address or ''
		
		return data[placeholder] or ''


getTemplate = memoize (target)->
	fs.readAsync "#{TEMPLATES}/#{target}.conf"


module.exports = resolveTemplate
module.exports.replace = replace