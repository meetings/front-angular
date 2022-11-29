
# Notification tab
#
# Has two preloaded WebViews:
# 1) notificationMeetingShowView - displays meeting#show
# 2) notificationShowView        - displays notification#show
#
class NotificationBaseCtrl
  @$inject =
    [ "$scope"
      "$location"
      "$log"
      "$timeout"
      "appConfig"
      "SessionRestangular"
      "sessionService"
      "currentUserService"
      "notificationService"
      "errorHandlerService"
      "meetingService"
      "navigationBarService"
      "viewParams"
      "dateHelper"
      "connectivity"
      "jsonMsgChannel"
      "deviceUtils"
    ]

  constructor: (@scope
                @location
                @log
                @timeout
                @appConfig
                @SessionRestangular
                @sessionService
                @currentUserService
                @notificationService
                @errorHandlerService
                @meetingService
                @navigationBarService
                @viewParams
                @dateHelper
                @connectivity
                @jsonMsgChannel
                @deviceUtils) ->

    @navigationBarService.showMenu()

class NotificationIndexCtrl extends NotificationBaseCtrl

  constructor: ->
    super

    @_initNotificationWatcher()

    nid = @viewParams.get("fetchAndOpenNotification")
    if nid?
      @viewParams.remove("fetchAndOpenNotification")
      @_fetchAndOpen(nid, "push")
    else
      @_initNotifications()

    @_initMessageListener()
    @_setLayout()

  ##############
  # PRIVATE
  ##############

  _setLayout: ->
    @navigationBarService.update(
      title: "Notifications"
    )

  _initMessageListener: ->
    @scope.$on "$destroy", =>
      @log.debug "[notification] destroyed, unsubscribing MsgChannel"
      @jsonMsgChannel.unsubscribe(@msgChannel)

    @msgChannel = @jsonMsgChannel.subscribe (data) =>
      @log.debug "[notification] received postmessage: ", data?.event, data

      if data?.event == "openNotification"
        @_fetchAndOpen(data.notification.additionalData.nid, "push")

  # Reset tab bar badge and mark all notifications seen (when view becomes visible).
  _markNotificationsSeen: =>
    @log.debug "[badges] Reset tab and app badges regardless of whether the API call is performed"
    @notificationService.resetBadges()

    return unless @notificationService.hasUnseenNotifications(@notifications)

    @notificationService.markAllSeen(@notifications).then(
      (data) =>
        @log.debug "All notifications marked as seen", data

      (failure) =>
        @log.debug "Failed marking all notifications as seen (non-important, not displaying error)", failure
    )

  _initNotificationWatcher: ->
    @scope.$watch(
      =>
        return @notificationService.notifications
      (notifications) =>
        @notifications = notifications

        if document.visibilityState == "visible" && !document.hidden
          @_markNotificationsSeen()
    )

  _initNotifications: ->
    @notificationService.notifications = @notificationService.getCache()

    if !@notificationService.notifications?
      @loading = true
      @_fetchAll()

    else
      @timeout( =>
        @_fetchAll()
      , 1000)

  _fetchAll: ->
    @notificationService.fetchAll().then(
      (data) =>
        @log.debug "[notifications] notifications fetched successfully"

      (failure) =>
        @log.error "[notifications] fetching failed", failure

        if @connectivity.isOnline() || !@notificationService.notifications?
          @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false

        @jsonMsgChannel.publishTo "PullToRefresh", JSON.stringify(
          event: "didFecthAll",
        )
    )

  _fetchAndOpen: (nid, utmSource) ->
    @loading = true

    @notificationService.fetchNotification(nid).then(

      (data) =>
        @log.debug "[notification] received:", {data}
        @_markNotificationsSeen()
        @open(data, utmSource)

        # Update notification list after opening notification page
        @_fetchAll()

      (failure) =>
        @log.error "[notification] fetching failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  _openMaterial: (notification) ->
    parentMeeting = notification.meeting
    breadcrumb = encodeURIComponent(notification.meeting.title_value)

    @viewParams.set({
      breadcrumb: breadcrumb
      breadcrumbClickable: true
    })
    @location.path("/notifications/meeting/#{ parentMeeting.id}/material/#{notification.material.id}")

  _openSwipeToMeet: (notification, utmSource) ->
    @viewParams.set({ menuVisible: true })
    @location.search("utm_source", utmSource).path("/notifications/meeting/#{notification.meeting_id}/scheduling/#{notification.scheduling_id}")

  _openSchedulingProgress: (notification) ->
    @location.path("/notifications/meeting/#{notification.meeting_id}/scheduling/#{notification.scheduling_id}/log")

  _openMeeting: (meeting) ->
    @meetingService.setMeeting(meeting)
    @location.path("/notifications/meeting/" + meeting.id)

  _openCustomNotification: (notification) ->
    @viewParams.set({
      notification: notification
    })
    @location.path("/notifications/#{notification.id}")

  # Update notification according to changed data.
  #
  # (Sadly it is not feasible to update the element as a whole
  # because Restangular route is wrong in the replacement object.)
  _updateNotification: (replacement) ->
    index = _.findIndex @notifications, (original) ->
      original.id == replacement.id

    return unless index != -1

    @notifications[index].is_seen = replacement.is_seen
    @notifications[index].is_read = replacement.is_read

  ##############
  # PUBLIC
  ##############

  handleError: ->
    @reload()

  reload: ->
    @error = null

    if @connectivity.isOnline()
      @_initNotifications()

  ptrCallback: ->
    @_fetchAll()

  open: (notification, utmSource) =>
    utmSource ?= if @deviceUtils.platform() == "web" then "web" else "app"

    switch notification.action_type
      when "material"           then @_openMaterial(notification.data)
      when "scheduling_landing" then @_openSwipeToMeet(notification.data, utmSource)
      when "scheduling_log"     then @_openSchedulingProgress(notification.data)
      when "meeting"            then @_openMeeting(notification.data.meeting)
      else
        @_openCustomNotification(notification)

    @notificationService.markRead(notification).then(
      (data) =>
        @log.debug "Notification marked as read", data
        @_updateNotification data

      (failure) =>
        @log.debug "Failed marking notification as read (non-important, not displaying error)", failure
    )

class NotificationCustomCtrl extends NotificationBaseCtrl

  constructor: ->
    super

    @notificationId = @viewParams.get("notificationId")
    @notification = @viewParams.get("notification")

    if !@notification?
      @_fetchNotification(@notificationId)

    @_setLayout()

  ##############
  # PRIVATE
  ##############

  _setLayout: ->
    @navigationBarService.update
      title: "Notification"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null

  _fetchNotification: (nid) ->
    @loading = true

    @notificationService.fetchNotification(nid).then(

      (data) =>
        @log.debug "[notification] received:", {data}
        @notification = data

      (failure) =>
        @log.error "[notification] fetching failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )
  ##############
  # PUBLIC
  ##############


notificationApp = angular.module "notificationApp",
  [
    "appConfig"
    "currentUserModule"
    "notifications"
    "meetingModule"
    "mtnHideParent"
    "dateHelper"
    "react"
    "notificationComponents"
    "connectivity"
    "mtnUtils"
  ]

notificationApp.controller "NotificationIndexCtrl", NotificationIndexCtrl
notificationApp.controller "NotificationCustomCtrl", NotificationCustomCtrl
