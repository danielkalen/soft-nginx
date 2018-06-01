fs = require 'fs-jetpack'
execa = require 'execa'
chalk = require 'chalk'
nginx = require('which').sync if process.env.NGINX_DEBUG then 'nginx-debug' else 'nginx'
isEqual = require 'sugar/object/isEqual'
promiseEvent = require 'p-event'
{Tail} = require 'tail'
{ERROR_LOG, CONF_FILE} = require './constants'

class Nginx extends require('events')
	constructor: ()->
		@state = null
		@task = null
		super

	start: (@state)->
		@followErrors()
		@task = task = execa(nginx, ['-g','daemon off;'], {stdio:'inherit'})
		@task.on 'error', (err)=> @emit 'exit', {err} unless task.killed
		@task.on 'exit', (code)=> @emit 'exit', {code} unless task.killed
		console.log 'nginx - starting' unless process.env.SILENT
		return @

	stop: ()-> if @task
		promise = promiseEvent @task, 'exit'
		@task.killed = true
		@task.kill()
		@unfollowErrors()
		return promise

	restart: (state=@state)->
		Promise.bind(@)
			.tap ()-> console.log 'nginx - restarting' unless process.env.SILENT
			.then ()-> @stop()
			.then ()-> @start(state)

	update: (state)->
		return if isEqual(state, @state)
		Promise.resolve(state).bind(@)
			.tap ({conf})-> @updateConf(conf)
			.then @restart

	updateConf: (conf='')->
		fs.writeAsync CONF_FILE, conf

	followErrors: ()->
		fs.file(ERROR_LOG)
		@createTail()
	
	unfollowErrors: ()->
		@tail?.unwatch()

	createTail: ()-> unless @tail
		@tail = new Tail(ERROR_LOG)
		@tail.on 'line', console.log
		@tail.on 'error', console.error


module.exports = new Nginx