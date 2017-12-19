global.Promise = require 'bluebird'
promiseBreak = require 'promise-break'
fs = require 'fs-jetpack'
execa = require 'execa'
chalk = require 'chalk'
docker = require 'docker-promise'
nginx = require './nginx'
regex = require './regex'

Promise.resolve()
	.then ()-> processFiles './config/conf.d'
	.each (file)-> fs.writeAsync "/etc/nginx/conf.d/#{file.name}", file.content
	.then ()-> processFile './config/nginx.conf'
	.then (conf)-> fs.writeAsync "/etc/nginx/nginx.conf", conf
	
	.then ()-> prepareConf()
	.tap ({hosts, conf})->
		if not hosts.length
			console.warn("#{chalk.red 'ERR'} no hosts provided under config/hosts.yml")

		nginx.updateConf(conf)
	
	.then (state)->
		nginx.start(state).on 'exit', handleNginxExit
		docker.events handleDockerEvent(state)
		startLogRotate()



handleNginxExit = ({err, signal})->
	if err
		console.error(err)
	else if signal
		console.error "nginx exited with signal #{signal}"

	process.exit(signal or 1)


handleDockerEvent = (state)-> (event)->
	changedHost = filterDockerEvent(event, state.hosts)
	return if not changedHost
	Promise.resolve()
		.tap ()-> console.log "container #{chalk.dim changedHost.name} has restarted"
		.then prepareConf
		.then (result)-> nginx.update(state = result)


startLogRotate = ()->
	CronJob = require('cron').CronJob
	new CronJob
		cronTime: '0 0 * * *'
		onTick: ()-> prepareConf().then (state)-> nginx.restart(state)
		start: true


prepareConf = ()->
	hosts = null
	Promise.resolve()
		.then require './resolveHosts'
		.then (result)-> hosts = result
		.then require './prepareConfFile'
		.then (conf)-> {hosts, conf}


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

filterDockerEvent = (event, hosts)->
	event.Type is 'container' and
	event.Action is 'start' and
	hosts.find((host)-> host.id is event.id)


