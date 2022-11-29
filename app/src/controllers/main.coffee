class MainCtrl

  @$inject = [
    "$scope"
    "$log"
    "appConfig"
    "sessionService"
    "suggestionService"
    "calendarService"
    "deviceUtils"
    "navigationBarService"
    "notificationService"
    "jsonMsgChannel"
    "segment"
    "pusherService"
    "appleWatchService"
  ]

  constructor: (@scope
                @log
                @appConfig
                @sessionService
                @suggestionService
                @calendarService
                @deviceUtils
                @navigationBarService
                @notificationService
                @jsonMsgChannel
                @segment
                @pusherService
                @appleWatchService) ->

    @sessionService.initEventListener(@_onSignOut)

    @_initWatchers()
    @_initMessageListener()

    if @sessionService.isSignedIn()
      @_initNotifications()
      @_initAppleWatch()

    if @sessionService.isSignedIn() && @suggestionService.getCalendarSuggestionsEnabled()
      @_initCalendar()

  ##############
  # PRIVATE
  ##############

  _onSignOut: =>
    @log.debug "signing out"
    @suggestionService.stopPollingForSuggestions()

    @notificationService.stopPollingForNewNotifications()
    @notificationService.unregisterPushNotications()

    @appleWatchService.signOut()

    @segment.reset()
    @pusherService.destroy()

  _initMessageListener: ->
    @scope.$on "$destroy", =>
      @log.debug "[navigation] destroyed, unsubscribing MsgChannel"
      @jsonMsgChannel.unsubscribe(@msgChannel)

    @msgChannel = @jsonMsgChannel.subscribe (data) =>

      @log.debug "[navigation] received postmessage: ", data?.event, data

      @notificationService.fetchAll() if data?.event == "fetchNotifications"

  _initWatchers: ->
    @scope.$watch(
      () =>
        return @navigationBarService.title
      (title) =>
        @pageTitle = title
    )

  _initNotifications: ->
    @notificationService.fetchAll()
    @notificationService.pollForNewNotifications()

    @notificationService.initPushNotifications()

  _initAppleWatch: ->
    @appleWatchService.init().then(
      (success) =>
        @appleWatchService.signIn(@sessionService.getUserId(), @sessionService.getToken())

      (failure) =>
        @log.debug "Apple watch initialization failed", failure
    )

  _initCalendar: ->
    @calendarService.init().then(
      () =>
        @log.debug "Calendar initialized!"
        @suggestionService.syncCalendars()

        if @deviceUtils.platform() == "ios"
          @suggestionService.pollForSuggestions()
    )

mainApp = angular.module "mainApp",
[
  "ngRoute"
  "ngAnimate"
  "appConfig"
  "SPARouteConfig"
  "signInApp"
  "navigationApp"
  "meetingApp"
  "participantApp"
  "materialApp"
  "notificationApp"
  "appStoreRedirectApp"
  "menuApp"
  "profileApp"
  "schedulingApp"
  "swipeToMeetApp"
  "redirectModule"
  "suggestionModule"
  "calendarModule"
  "mtnUtils"
  "pusherModule"
  "appleWatchModule"
]

mainApp.controller "MainCtrl", MainCtrl

mainApp.run ($log
             $rootScope
             $location
             redirectService
             sessionService
             currentUserService
             deviceUtils
             segment
             sentry
             cacheService
             dateHelper) ->

  window.handleOpenURL = (url) ->
    #console.log("received url: " + url);
    if _.contains(url, "?")
      urlQueryString = url.split("?")[1]
      queryStrings = urlQueryString.split("&")
      queryParams = {}
      _.forEach(queryStrings, (queryString) ->
        qs = queryString.split('=')
        queryParams[qs[0]] = qs[1]
      )

      redirectService.handleQueryParams(queryParams)
      $rootScope.$apply()

  # Read query parameters to sign in and redirect if necessary
  redirectService.handleQueryParams()

  window.addEventListener("load", () ->
    FastClick.attach(document.body)
  , false)

  cacheService.init("SwipeToMeet")
  segment.init()
  sentry.init()

  dateHelper.initCustomLocales()
  currentUserTimeFormat = if currentUserService.get()? then currentUserService.get().time_display else "24h"
  moment.locale(currentUserTimeFormat)

  sessionService.checkLogin()

  $rootScope.$on('$locationChangeSuccess', (evt, location) ->
    currentUser = currentUserService.get()
    return unless currentUser?

    regex = new RegExp(/\/meeting\/\d+\/scheduling\/\d+.*/)
    path = $location.path()
    locationWithoutTab = path.substr(path.substr(1).indexOf("/"))

    if !regex.test(locationWithoutTab) && sessionService.isSignedIn() && currentUser.tos_accepted == 0
      $log.error "TOS is not accepted"

      $location.path("/signup")
  )
