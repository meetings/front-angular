msgChannel = angular.module "MsgChannel", []


# Each tab has its own post message channel.
# Channel name is usually given as a query parameter in WebVew load (see application.coffee).
# Messages are filtered so that only the subscribers of a channel receive it.
#
# This app uses the JsonMsgChannel version.
msgChannel.factory "MsgChannel", ($rootScope) ->

  class Channel
    constructor: (@name) ->

    _msgChannelEventCallback: (msg, listener) ->
      switch msg.data.channel
        when @name
          listener @parseMsg(msg.data.args...)

    parseMsg: (args...) ->
      args

    publish: (args...) =>
      $rootScope.$emit(@name, args: args)

    # Publish to another msgChannel, i.e. from menu to timeline
    publishTo: (msgChannel, args...) =>
      $rootScope.$emit(msgChannel, args: args)

    subscribe: (listener) =>
      return $rootScope.$on(@name, (event, msg) =>
        listener @parseMsg(msg.args...)
      )

    unsubscribe: (msgChannel) ->
      msgChannel()

# Like MsgChannel but messages are expected to be in Json format.
#
# Usage:
#
#  - send a message:
#
#     @jsonMsgChannel.publish JSON.stringify(
#       event: "loadMeetingShowView",
#       meeting: meeting
#    )
#
# - subscribe to a channel:
#
#     msgchannel = @jsonMsgChannel.subscribe (data) =>
#       @log.debug "received postmessage: ", data?.event, data
#
# - If using app in SPA mode, unsubscribe on controller $destroy
#
#     @scope.$on("$destroy", =>
#       @jsonMsgChannel.unsubscribe(msgchannel)
#     )
#
msgChannel.factory "JsonMsgChannel", (MsgChannel, $log) ->

  class JsonMsgChannel extends MsgChannel
    parseMsg: (msg) ->
      try
        return JSON.parse msg
      catch error
        $log.warn "[JsonMsgChannel #{@name}] received invalid json -- ", error


msgChannel.factory "jsonMsgChannel", (JsonMsgChannel, viewParams, $log) ->
  return new JsonMsgChannel("commonMsgChannel")
