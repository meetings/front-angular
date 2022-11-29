
class MenuBaseCtrl
  @$inject =
    [
      "$scope"
      "$location"
      "$window"
      "$log"
      "$q"
      "appConfig"
      "SessionRestangular"
      "sessionService"
      "currentUserService"
      "errorHandlerService"
      "calendarService"
      "suggestionService"
      "navigationBarService"
      "accountService"
      "notificationService"
      "pushNotificationService"
      "viewParams"
      "deviceUtils"
      "stringUtils"
      "deviceready"
      "jsonMsgChannel"
      "dateHelper"
    ]

  constructor: (@scope
                @location
                @window
                @log
                @q
                @appConfig
                @SessionRestangular
                @sessionService
                @currentUserService
                @errorHandlerService
                @calendarService
                @suggestionService
                @navigationBarService
                @accountService
                @notificationService
                @pushNotificationService
                @viewParams
                @deviceUtils
                @stringUtils
                @deviceready
                @jsonMsgChannel
                @dateHelper) ->

  openAppSettings: ->
    window.OpenSettings.open()


class MenuIndexCtrl extends MenuBaseCtrl

  constructor: ->
    super

    @isDeveloperMenuVisible = @appConfig.isDevelopmentMode
    @appEnvironment = @appConfig.environment
    @appVersion = @appConfig.version

    @deviceready.then =>
      @openAppSettingsVisible = @deviceUtils.platform() == "ios" && @deviceUtils.version() >= 8

    @_setLayout()

  _setLayout: ->
    title = "Settings"

    @navigationBarService.update(
      title: title
    )

  signOut: ->
    @sessionService.signOut()

  openProfile: ->
    @location.path("/settings/profile/")

  openNotificationSettings: ->
    @location.path("/settings/notifications")

  openCalendarSettings: ->
    @location.path("/settings/timeline")

  openAccountSettings: ->
    @location.path("/settings/calendars")

  openRegionalSettings: ->
    @location.path("/settings/regional")

  openStyleguide: ->
    @location.path("/styleguide")

  handleError: ->
    @error = null

class MenuNotificationSettingsCtrl extends MenuBaseCtrl

  constructor: ->
    super

    @_setLayout()

  _setLayout: ->
    @navigationBarService.show("Notifications")

    @navigationBarService.update
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null


  openPushNotificationMenu: ->
    @location.path("/settings/notifications/push")

  openEmailNotificationMenu: ->
    @location.path("/settings/notifications/email")

  handleError: ->
    @error = null


class MenuNotificationCtrl extends MenuBaseCtrl

  constructor: ->
    super

  ############
  # PRIVATE
  ############

  _fetchNotifcationSettings: ->
    @loading = true

    @currentUserService.getRoute().all("notification_settings").getList().then(
      (data) =>
        @log.debug "fetching settings succesful", data

        data = _.filter(data, (setting) => setting.type == @type)

        _.each(data, (setting) ->
          setting.value = setting.value == 1
          return
        )

        @settings = _.values(_.groupBy(data, (setting) -> setting.header))

      (failure) =>
        @log.error "fetching settings failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  _update: (type, notification, value) ->
    @settings[type][notification].saving = true

    @settings[type][notification].put().then(
      (data) =>
        @log.debug "saving setting succesful", data
        @settings[type][notification].saving = false

      (failure) =>
        @log.error "saving setting failed", failure
        @error = @errorHandlerService.handle failure
    )

  _setLayout: (title) ->
    if !title?
      title = "Other"

    @navigationBarService.update
      title: title
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null

  ############
  # PUBLIC
  ############

  toggleNotificationValue: (type, notification) ->
    @settings[type][notification].value = !@settings[type][notification].value
    @_update(type, notification, @settings[type][notification].value)

  setNotificationValue: (type, notification, value) ->
    @settings[type][notification].value = value
    @_update(type, notification, @settings[type][notification].value)

  handleError: ->
    @reload()

  reload: ->
    @error = null
    @_fetchNotifcationSettings()

class MenuEmailNotificationCtrl extends MenuNotificationCtrl

  constructor: ->
    super

    @type = "email"
    @visibleSettings = "notificationSettings"

    @_fetchNotifcationSettings()

    @_setLayout(@type)

class MenuPushNotificationCtrl extends MenuNotificationCtrl

  constructor: ->
    super

    notificationPermissionAsked = @notificationService.getPermissionAsked()
    @pushTestButtonVisible = true
    @pushNotificationsEnabled = @pushNotificationService.pushNotificationStatus

    @type = "push"

    if !notificationPermissionAsked
      @visibleSettings = "askPermission"

    else
      @visibleSettings = "notificationSettings"

    @deviceready.then =>
      @openAppSettingsVisible = @deviceUtils.platform() == "ios" && @deviceUtils.version() >= 8

    @_fetchNotifcationSettings()
    @_initMessageListener()

    @_setLayout(@type)

  ############
  # PRIVATE
  ############

  _initMessageListener: ->
    @scope.$on "$destroy", =>
      @log.debug "[settings] destroyed, unsubscribing MsgChannel"
      @jsonMsgChannel.unsubscribe(@msgChannel)

    @msgChannel = @jsonMsgChannel.subscribe (data) =>
      @log.debug "[settings] received postmessage: ", data?.event, data

      if data?.event == "UAregistrationSuccess"
        @_registrationSuccess()

      if data?.event == "pushNotificationStatusChanged"
        @_pushNotificationStatusChanged(data.status)

  _registrationSuccess: ->
    @btnWorking = null
    @visibleSettings = "notificationSettings"
    @scope.$apply()

  _pushNotificationStatusChanged: (status) ->
    @log.debug "Push notification status changed", status
    @btnWorking = null
    @pushNotificationsEnabled = status

  ############
  # PUBLIC
  ############

  initPushNotifications: ->
    @btnWorking = "initPushNotifications"
    @notificationService.setPermissionAsked(true)

    @notificationService.initPushNotifications()

  testPushNotifications: ->
    @btnWorking = "testPushNotifications"
    @pushNotificationService.testPushNotifications()

class MenuDefaultCalendarsCtrl extends MenuBaseCtrl

  constructor: ->
    super

    @delayedSpinner = true

    @deviceId = @deviceUtils.uuid()

    @_fetchSuggestionSources()

    @_setLayout()

  _setLayout: ->
    @navigationBarService.update
      title: "Default calendars"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null

  _fetchSuggestionSources: ->
    @loading = true

    @q.all([
      @currentUserService.reload()
      @currentUserService.getRoute().all("suggestion_sources").getList()
    ]).then(
      (data) =>

        @user = data[0]

        userSourceSettings = @user.source_settings

        @suggestionSources = @suggestionService.selectEnabledSources(data[1], userSourceSettings)

        @sources = _.values(
          _(@suggestionSources).sortBy((source) -> source.name.toLowerCase())
                               .groupBy((source) -> source.container_id).value()
        )

      (failure) =>
        @log.error "fetching suggestion sources failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )


  ############
  # PUBLIC
  ############

  openAccountSettings: ->
    @location.path("/settings/calendars")

  toggleSourceValue: (type, source) ->
    @log.debug "attrs: ", type, source

    @sources[type][source].selected_by_default = !@sources[type][source].selected_by_default
    @sources[type][source].saving = true

    @suggestionService.updateSources(@user, @suggestionSources).then(
      (data) =>
        @log.debug "Updated source_settings successfully, got data:", data

      (failure) =>
        @log.debug "Failed updating source_settings", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @sources[type][source].saving = false
    )

  setSourceValue: (type, source) ->
    @log.debug "attrs: ", type, source, value

    @sources[type][source].selected_by_default = value
    @sources[type][source].saving = true

    @suggestionService.updateSources(@user, @suggestionSources).then(
      (data) =>
        @log.debug "Updated source_settings successfully, got data:", data

      (failure) =>
        @log.debug "Failed updating source_settings", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @sources[type][source].saving = false
    )

  handleError: ->
    @reload()

  reload: ->
    @error = null
    @delayedSpinner = true
    @_fetchSuggestionSources()

class MenuCalendarIntegrationCtrl extends MenuBaseCtrl

  constructor: ->
    super

    @loading = true
    @connectCalendarButtonVisible = true

    @emailSubmitted = @currentUserService.getEmailSubmitted()

    @deviceId = @deviceUtils.uuid()

    @_fetchSuggestionSources()

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.show("Calendar integration")

    @navigationBarService.update
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null

  _fetchSuggestionSources: ->
    @q.all([
      @currentUserService.reload()
      @currentUserService.getRoute().all("suggestion_sources").getList()
    ]).then(
      (data) =>

        @user = data[0]
        @suggestionSources = data[1]

        @connectGoogleAccountButtonVisible = @user.google_connected == 0

        groupedSources = _.groupBy(@suggestionSources, (source) -> source.container_id)

        @currentDeviceSource = groupedSources[@deviceId]

        if @currentDeviceSource?
          @currentDeviceContainerName = @currentDeviceSource[0].container_name
          @currentDeviceContainerId = @currentDeviceSource[0].container_id
          delete groupedSources[@deviceId]

          @connectCalendarButtonVisible = false

          lastUpdateEpoch = @currentDeviceSource[0].last_update_epoch
          @lastSyncOnCurrentDevice = @_formatSyncTime(lastUpdateEpoch)

        else
          @connectCalendarButtonVisible = true

        @sources = _.values(groupedSources)

      (failure) =>
        @log.error "fetching suggestion sources failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
        @btnWorking = null
    )

  _disconnectDeviceCalendar: (containerName, containerId, isCurrentDevice) ->
    @confirmDialog = null
    @btnWorking = containerName

    @suggestionService.disconnectDeviceCalendar(containerName, containerId, isCurrentDevice, @deviceUtils.platform()).then(
      (data) =>
        @log.debug "Phone sources removed"

        _.remove(@suggestionSources, { container_id: containerId } )

        groupedSources = _.groupBy(@suggestionSources, (source) -> source.container_id)

        delete groupedSources[@deviceId]

        @sources = _.values(groupedSources)

        return @suggestionService.updateSources(@user, @suggestionSources)

      (failure) =>
        @log.debug "Phone source removal failed", failure
    ).then(
      (data) =>
        @log.debug "Updated source_settings successfully, got data:", data

      (failure) =>
        @log.debug "Failed updating source_settings", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>

        if isCurrentDevice
          @connectCalendarButtonVisible = true

        @btnWorking = null
    )

  _disconnectGoogleAccount: ->
    @confirmDialog = null
    @btnWorking = "Google Calendar"

    @currentUserService.getRoute().one('service_accounts', 'google').post('disconnect').then(
      (data) =>
        @log.debug "Google account disconnected", data

        groupedSources = _.groupBy(@suggestionSources, (source) -> source.container_id)
        delete groupedSources["google"]
        @sources = _.values(groupedSources)

        @connectGoogleAccountButtonVisible = true

      (failure) =>
        @log.debug "Failed to disconnect Google account", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  _formatSyncTime: (syncTime) ->
    return "Unknown" if syncTime is 0

    rightNowEpoch = parseInt(moment().format("X"))
    return moment.duration(syncTime - rightNowEpoch, "seconds").humanize(true);

  ############
  # PUBLIC
  ############

   confirmCalendarDisconnect: (containerName, containerId, isCurrentDevice) ->
    if isCurrentDevice
      message = "Disconnect the calendar on this device from #{@appConfig.appName}?"
    else
      message = "Disconnected devices can only be reconnected using that device."
    @confirmDialog = {
      title: "Please confirm"
      message: message
      buttonConfirmCallback: => @_disconnectDeviceCalendar(containerName, containerId, isCurrentDevice)
      buttonConfirmCaption: "Disconnect"
      buttonCancelCallback: => @confirmDialog = null
      buttonCancelCaption: "Cancel"
    }

  confirmGoogleDisconnect: ->
    message = "You are about to disconnect your Google account. You will no longer be able to log in using it or see your events and contacts in Meetin.gs"
    @confirmDialog = {
      title: "Please confirm"
      message: message
      buttonConfirmCallback: => @_disconnectGoogleAccount()
      buttonConfirmCaption: "Disconnect"
      buttonCancelCallback: => @confirmDialog = null
      buttonCancelCaption: "Cancel"
    }

  connectGoogleAccount: ->
    sessionString = @stringUtils.generateRandomString(10)
    @sessionService.setGoogleSignInSessionString(sessionString)

    redirectUrl = @location.absUrl()
    state = { to: redirectUrl, session: sessionString }

    @window.location = @accountService.generateGoogleAuthUrl(state)

  connectOffice365Account: ->
    alert "Not implemented"

  initCalendarPlugin: ->
    @calendarService.init().then(
      () =>
        @log.debug "Calendar initialized!"
        @calendarService.setPermissionAsked(true)

      (failure) =>
        @btnWorking = null

        @log.error "Calendar connection failed", failure
        @error = @errorHandlerService.handle failure
    )

  syncCalendars: (btnWorking) ->
    @btnWorking = btnWorking

    return @initCalendarPlugin().then(
      () =>
        @suggestionService.syncCalendars()
    ).then(
      (data) =>
        @log.debug "Calendars synced, fetch sources"

        @_fetchSuggestionSources()

        return data
      (failure) =>
        @log.error "Connecting calendar failed", failure
        @error = @errorHandlerService.handle failure

        return failure
    ).finally(
      =>
        @btnWorking = null
    )

  connectDeviceCalendar: ->
    @syncCalendars('connect').then(
      (data) =>
        @log.debug "Connect succesful, update sources"
        return @suggestionService.updateSources(@user, @suggestionSources)

    ).then(
      (data) =>
        @log.debug "Updated source_settings successfully, got data:", data

      (failure) =>
        @log.debug "Failed updating source_settings", failure
        @error = @errorHandlerService.handle failure

    )

  removeSync: (sources) ->
    containerType = sources[0].container_type
    containerName = sources[0].container_name
    containerId = sources[0].container_id

    if containerType == "phone"
      @confirmCalendarDisconnect(containerName, containerId, false)

    else if containerType == "google"
      @confirmGoogleDisconnect()

    else alert "Not implemented"

  getLastSync: (containerId) ->
    container = _.where(@suggestionSources, { container_id: containerId })[0]
    lastUpdateEpoch = container.last_update_epoch

    return @_formatSyncTime(lastUpdateEpoch)

  handleError: ->
    @reload()

  reload: ->
    @error = null

class MenuRegionalSettingsCtrl extends MenuBaseCtrl

  constructor: ->
    super

    @timeFormatExample = moment().format(@dateHelper.formatTimeDayDate)
    @_fetchUser()
    @_setLayout()

  ############
  # PRIVATE
  ############


  _setLayout: ->
    @navigationBarService.update
      title: "Regional settings"
      buttons:
        left: if @deviceUtils.platform() != "web" then @navigationBarService.defaultBackButton() else null

  _fetchUser: ->
    @loading = true

    @currentUserService.reload().then(
      (data) =>
        @log.debug "User reloaded successfully", data

        @user = data
        @using24hTime = @user.time_display == "24h"

      (failure) =>
        @log.error "Reloading user failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @loading = false
    )

  _update: (type) ->
    @saving = type

    @currentUserService.update(@user).then(
      (data) =>
        @log.debug "saving setting succesful", data

        @user = data
        @using24hTime = @user.time_display == "24h"

        moment.locale(@user.time_display)

        @timeFormatExample = moment().format(@dateHelper.formatTimeDayDate)

      (failure) =>
        @log.error "saving setting failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @saving = null
    )

  ############
  # PUBLIC
  ############

  toggle24hValue: ->
    @user.time_display = if @using24hTime then "12h" else "24h"
    @_update("timeDisplay")

  set24hValue: (value) ->
    @user.time_display = value
    @_update("timeDisplay")

  handleError: ->
    @error = null
    @_fetchUser()

menuApp = angular.module "menuApp",
  [
    "appConfig"
    "mtnUtils"
    "mtnCheckbox"
    "calendarModule"
    "suggestionModule"
    "accountModule"
    "notifications"
    "pushNotificationModule"
    "mtnFloatLabel"
    "mtnA"
    "dateHelper"
  ]

menuApp.controller "MenuIndexCtrl", MenuIndexCtrl
menuApp.controller "MenuNotificationSettingsCtrl", MenuNotificationSettingsCtrl
menuApp.controller "MenuNotificationCtrl", MenuNotificationCtrl
menuApp.controller "MenuDefaultCalendarsCtrl", MenuDefaultCalendarsCtrl
menuApp.controller "MenuCalendarIntegrationCtrl", MenuCalendarIntegrationCtrl
menuApp.controller "MenuRegionalSettingsCtrl", MenuRegionalSettingsCtrl
