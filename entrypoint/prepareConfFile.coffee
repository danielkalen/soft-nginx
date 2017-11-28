stringIndent = require 'indent-string'
resolveTemplate = require './resolveTemplate'

module.exports = (hosts)->
	Promise.resolve(hosts)
		.map (host)->
			host.extra = resolveTemplate.replace(host.extra, host, hosts) if host.extra
			Promise.props(
				upstream: resolveTemplate 'upstream', host
				server: resolveTemplate 'server', host
			).then ({upstream, server})-> "#{upstream}\n#{server}"

		.then (confs)-> confs.join '\n\n\n'



