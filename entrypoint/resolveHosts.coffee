promiseBreak = require 'promise-break'
fs = require 'fs-jetpack'
chalk = require 'chalk'
docker = require 'docker-promise'
HOSTS_PATH = './config/hosts.yml'

module.exports = ()->
	Promise.resolve()
		.then ()-> fs.existsAsync HOSTS_PATH
		.then (exists)-> promiseBreak([]) if not exists
		.then ()-> fs.readAsync HOSTS_PATH
		.then require './resolveVariables'
		.then (content)-> require('js-yaml').safeLoad content
		.then (hosts)->
			containers = null
			Promise.resolve()
				.then ()-> docker.containers query:all:true
				.then (result)-> containers = result
				.return hosts
				.map (host)-> resolveHostData(host, containers)
				.then (hosts)-> hosts.filter (host)-> host.id?

		.catch promiseBreak.end


resolveHostData = (host, containers)->
	host.port ?= 80
	host.listenport ?= 80
	extraConf = "./config/vhost.d/#{host.host}.conf"
	
	Promise.resolve()
		.then ()-> matchContainerByName(host.name, containers)
		.tap (match)-> if not match
			promiseBreak console.error "#{chalk.red 'ERR'} no matching container found for '#{host.name}', skipping..."
		
		.then (match)->
			host.id = match.Id
			host.network = match.HostConfig.NetworkMode
			host.address = match.NetworkSettings.Networks[host.network]?.IPAddress
			if not host.address
				console.error "#{chalk.yellow 'WARN'} container ip address could not be resolved for '#{host.name}', skipping..."
				host.address = '127.0.0.1'
				host.exclude = true
		
		.then ()-> fs.existsAsync extraConf
		.then (exists)-> promiseBreak() if not exists
		.then ()-> fs.readAsync extraConf
		.then (extra)-> host.extra = extra
		.tapCatch {code:'EISDIR'}, (err)-> console.error "Your #{extraConf} file seems to be a directory and is invalid for use"
		.catch promiseBreak.end
		.return host


matchContainerByName = (name, containers)->
	containers.find (container)->
		container.Names.some (candidate)-> candidate.endsWith(name)

