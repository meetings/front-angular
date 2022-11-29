class pushNotificationService

  @$inject = [
    "$log"
    "$timeout"
    "appConfig"
    "jsonMsgChannel"
    "currentUserService"
    "sessionService"
  ]

  constructor: (@log
                @timeout
                @appConfig
                @jsonMsgChannel
                @currentUserService
                @sessionService ) ->


  ################
  # PRIVATE
  ################

  _onRegistration: (data) =>
    @log.debug "Registation result", data
    @registrationId = data.registrationId

    @_sendTestPush(@registrationId)

  _onPushReceived: (notification) =>
    @log.debug "[Push notifications] Got incoming push notification", notification

    return unless notification?

    if notification.additionalData.push_test?
      @_setDevicePushStatus(1)
      return

    isForeground = notification.additionalData.foreground

    if notification.message
      @jsonMsgChannel.publish JSON.stringify(
        event: "fetchNotifications"
      )

      @jsonMsgChannel.publish JSON.stringify(
        event: if isForeground then "newNotification" else "openNotification"
        notification:
          message: notification.message
          additionalData: notification.additionalData
      )

  _sendTestPush: ->
    return unless @sessionService.isSignedIn()

    if @testPushCounter < @appConfig.pushNotifications.testPushRetryCount
      @currentUserService.sendTestPush(@registrationId).then(
        (data) =>
          @log.debug "[Push notifications] Sent test push succesfully"

          # Sometimes test push notification is received before api responds to this query.
          # Check that device push status has not been set to 1 already before setting retry timeout.
          if @pushNotificationStatus != 1
            @testPushTimeout = @timeout( =>
              @log.debug "[Push notifications] Retrying test push"
              ++@testPushCounter
              @_sendTestPush()
            , @appConfig.pushNotifications.testPushRetryInterval)

        (failure) =>
          @log.debug "[Push notifications] Failed to send test push", failure
          @testPushTimeout = @timeout( =>
            @log.debug "[Push notifications] Retrying test push"
            ++@testPushCounter
            @_sendTestPush()
          , @appConfig.pushNotifications.testPushRetryInterval)
      )
    else
      @_setDevicePushStatus(0)

  _setDevicePushStatus: (status) ->
    return unless @sessionService.isSignedIn()

    @timeout.cancel(@testPushTimeout)
    @pushNotificationStatus = status

    @currentUserService.setDevicePushStatus(@registrationId, status).then(
      (data) =>
        @log.debug "[Push notifications] Device push status set succesfully", data

      (failure) =>
        @log.debug "[Push notifications] Setting device push status failed", failure
        status = 0
    ).finally(
      =>
        @pushNotificationStatus = status
        @jsonMsgChannel.publish JSON.stringify(
          event: "pushNotificationStatusChanged"
          status: status
        ))

  ################
  # PUBLIC
  ################

  init: ->
    return unless PushNotification?

    @testPushCounter = 0

    @push = PushNotification.init(
      android:
        senderID: @appConfig.GCM.id
        icon: "notifications"
        iconColor: "#FF67CFE9"
      ios:
        alert: true
        badge: true
        sound: true
      windows: {}
    )

    @push.on("registration", @_onRegistration)
    @push.on("notification", @_onPushReceived)

    @push.on("error", (error) ->
      @log.error "push notification error", error
    )

  unregister: ->
    return unless PushNotification?

    @_setDevicePushStatus(0)

    @push.unregister(
      =>
        @log.debug "Device unregistered"

      (error) =>
        @log.error "Failed to unregister device", error
    )

  setBadgeNumber: (badge) ->
    @push.setApplicationIconBadgeNumber(
      =>
        @log.debug "Badge numer set to", badge

      (error) =>
        @log.error "Failed to set badge number", error

      , badge)

  testPushNotifications: ->
    @testPushCounter = 0
    @_sendTestPush()

pushNotifications = angular.module "pushNotificationModule", [
  "appConfig"
  "mtnUtils"
  "MsgChannel"
  "currentUserModule"
  "sessionModule"
]

pushNotifications.service "pushNotificationService", pushNotificationService
