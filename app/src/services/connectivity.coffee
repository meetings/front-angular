# Include connectivity only in views where you need it, because it requires setting up a MsgChannel.
# Do not include it in appConfig!
connectivity = angular.module "connectivity", [ "mtnUtils", "MsgChannel"]

connectivity.service "connectivity", ($log, deviceUtils, jsonMsgChannel) ->
  @connected = false
  if window.mtnApp.fake_connectivity != null
    $log.debug "Faking connectivity ", window.mtnApp.fake_connectivity
    @connected = window.mtnApp.fake_connectivity == "online"

  _onDeviceReady = =>
    document.addEventListener("online", =>
      $log.debug "[connectivity] Received online event:", navigator.network.connection.type
      @connected = true
      jsonMsgChannel.publish JSON.stringify(event: "connectionStatusChanged", connected: true)
    , false)

    document.addEventListener("offline", =>
      $log.debug "[connectivity] Received offline event:", navigator.network.connection.type # none
      @connected = false
      jsonMsgChannel.publish JSON.stringify(event: "connectionStatusChanged", connected: false)
    , false)

    connectionType = navigator.network.connection.type.toLowerCase()
    if connectionType == "none" || connectionType == "unknown"
      $log.debug "[connectivity] Initially offline"
      @connected = false
      jsonMsgChannel.publish JSON.stringify(event: "connectionStatusChanged", connected: false)
    else
      $log.debug "[connectivity] Initially online"
      @connected = true
      jsonMsgChannel.publish JSON.stringify(event: "connectionStatusChanged", connected: true)

  document.addEventListener("deviceready", _onDeviceReady, false)

  isOnline: =>
    $log.debug "[connectivity]", ((if (@connected) then "On" else "Off")) + "line"
    return @connected

  isOffline: =>
    $log.debug "[connectivity]", ((if (@connected) then "On" else "Off")) + "line"
    return !@connected
