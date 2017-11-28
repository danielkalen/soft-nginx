global.Promise = require 'bluebird'
promiseBreak = require 'promise-break'
fs = require 'fs-jetpack'
execa = require 'execa'
chalk = require 'chalk'
nginx = require('which').sync 'nginx'
regex = require './regex'

Promise.resolve()
	.then ()-> processFiles './config/conf.d'
	.each (file)-> fs.writeAsync "/etc/nginx/conf.d/#{file.name}", file.content
	.then ()-> processFile './config/nginx.conf'
	.then (conf)-> fs.writeAsync "/etc/nginx/nginx.conf", conf
	# .then ()-> fs.copyAsync './config/conf.d', '/etc/nginx/conf.d', overwrite:true
	# .then ()-> fs.copyAsync './config/nginx', '/etc/nginx/nginx.conf', overwrite:true
	.then require './resolveHosts'
	.tap (hosts)-> if not hosts.length
		promiseBreak console.warn("#{chalk.red 'ERR'} no hosts provided under config/hosts.yml")
	
	.then require './prepareConfFile'
	
	.catch promiseBreak.end
	.then (conf='')-> fs.writeAsync '/etc/nginx/conf.d/default.conf', conf
	.then ()-> console.log fs.read('/etc/nginx/conf.d/default.conf')
	# .then ()->
	# 	task = execa(nginx, ['-g','daemon off;'], {stdio:'inherit'})
	# 	require('p-event')(task, 'exit')


processFile = (path)->
	Promise.resolve()
		.then ()-> fs.readAsync path
		.then require './resolveImports'
		.then require './resolveVariables'

processFiles = (dir)->
	Promise.resolve()
		.then ()-> fs.listAsync dir
		.map (file)-> Promise.props
			name: file
			path: "#{dir}/#{file}"
			content: processFile("#{dir}/#{file}")

