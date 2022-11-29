pusherModule = angular.module "pusherModule", ["appConfig"]

pusherModule.service "pusherService", ($log, appConfig, sessionService) ->

  init: ->
    $log.debug "[Pusher] Initializing Pusher"

    pusherConfig = {
      authEndpoint: appConfig.pusher.authEndpoint
      auth:
        headers:
          user_id: sessionService.getUserId()
          dic: sessionService.getToken()
    }

    @pusher = new Pusher(appConfig.pusher.key, pusherConfig)

  destroy: ->
    $log.debug "[Pusher] Destroying Pusher"
    @pusher = null

  # Checks if channel with specified name exists and subscribes to it if necessary.
  getChannel: (channelName) ->
    existingChannel = @pusher.channel(channelName)

    if existingChannel?
      return existingChannel
    else
      return @pusher.subscribe(channelName)

  bind: (channel, eventName, callback) ->
    channel.bind(eventName, callback)

  unbind: (channelName, eventName, callback) ->
    channel = @pusher.channel(channelName)
    return unless channel?

    channel.unbind(eventName, callback)

  subscribeAndBind: (channelName, eventName, callback) ->
    if !@pusher?
      @init()

    channel = @getChannel(channelName)

    @bind(channel, eventName, callback)

