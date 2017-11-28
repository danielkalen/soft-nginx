fs = require 'fs-jetpack'
execa = require 'execa'
chalk = require 'chalk'
nginx = require('which').sync 'nginx'
isEqual = require 'sugar/object/isEqual'

class Nginx extends require('events')
	constructor: ()->
		@state = null
		@task = null
		super

	start: (@state)->
		@task = task = execa(nginx, ['-g','daemon off;'], {stdio:'inherit'})
		@task.on 'error', (err)=> @emit 'exit', {err} unless task.killed
		@task.on 'exit', (code)=> @emit 'exit', {code} unless task.killed
		return @

	stop: ()-> if @task
		@task.killed = true
		@task.kill()

	restart: (state)->
		Promise.bind(@)
			.tap ()-> console.log 'nginx - restarting'
			.then ()-> @stop()
			.then ()-> @start(state)

	update: (state)->
		return if isEqual(state, @state)
		Promise.resolve(state).bind(@)
			.tap ({conf})-> @updateConf(conf)
			.then @restart

	updateConf: (conf='')->
		fs.writeAsync '/etc/nginx/conf.d/default.conf', conf


module.exports = new Nginx