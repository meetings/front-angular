notifications = angular.module "notifications", [
    "currentUserModule"
    "sessionModule"
    "pushNotificationModule"
    "MsgChannel"
    "mtnUtils"
    "SessionModel"
  ]

notifications.service "notificationService", (
  $rootScope
  $q
  $log
  $interval
  currentUserService
  sessionService
  pushNotificationService
  appConfig
  cacheService
  deviceUtils
  vsprintfUtils
  ) ->

  setCache: (notifications) ->
    cacheService.put("notifications", notifications)

  getCache: ->
    return cacheService.get("notifications")

  getPermissionAsked: ->
    try
      return JSON.parse localStorage.getItem("__notification_permission_asked") ||
        deviceUtils.platform() != "ios"
    catch
      return undefined

  setPermissionAsked: (value) ->
    localStorage.setItem("__notification_permission_asked", value)

  initPushNotifications: ->
    return unless @getPermissionAsked()
    return pushNotificationService.init()

  unregisterPushNotications: ->
    pushNotificationService.unregister()

  indexRoute: ->
    currentUserService.getRoute().all("notifications")

  formatNotificationTemplates: (notifications) ->
    _.each(notifications, (notification) =>

      params = vsprintfUtils.formatParams(notification.data)

      notification.data.template = vsprintf(notification.data.template, params)
    )

    return notifications

  fetchAll: ->
    @indexRoute().getList().then(
      (notifications) =>
        $log.debug "[notifications] received:", {notifications}

        @setBadges(notifications)

        @notifications = @formatNotificationTemplates(notifications)
        @setCache(@notifications)

        return notifications
    )

  fetchNotification: (nid) ->
    currentUserService.getRoute().one("notifications", nid).get().then(
      (notification) =>
        $log.debug "[notifications] received:", {notification}

        return notification
    )

  markRead: (notification) ->
    currentUserService.getRoute().one("notifications", notification.id).customPOST({}, "mark_read")

  markAllSeen: (notifications) ->
    ids = _.map(notifications, (notification) -> notification.id)
    $log.debug "Mark these notifications as seen: ", ids

    @indexRoute().customPOST({id_list: ids}, "mark_seen")

  hasUnseenNotifications: (collection) ->
    unseen = _.find collection, (one) -> one.is_seen == 0

    unseen?

  # Initiate polling for new notifications
  pollForNewNotifications: ->
    @pollPromise = @poll =>
      $log.debug "Polling for new notifications"
      @fetchAll()

  # Cancel polling for new notifications
  stopPollingForNewNotifications: ->
    $log.debug "Polling for new notifications canceled"
    @cancelPoll(@pollPromise)
    @pollPromise = null

  poll: (callback) ->
    return $interval(callback, appConfig.notifications.pollInterval)

  cancelPoll: (pollPromise) ->
    $interval.cancel(pollPromise)

  # Sets all badges according to unseen notification count.
  setBadges: (notifications) ->
    count = (_.where notifications, { is_seen: 0 }).length

    @setBadgeValue count

  # Removes all badges
  resetBadges: ->
    @setBadgeValue(null)

  # Sets app and tab badge according to given value.
  setBadgeValue: (badge) ->
    if not badge? or badge == 0
      badge = ""

    @badge = badge

    if deviceUtils.platform() == "ios"
      @setAppBadge badge

  # Set app badge.
  # Empty string or 0 will remove badge.
  setAppBadge: (badge) ->
    pushNotificationService.setBadgeNumber(badge)
