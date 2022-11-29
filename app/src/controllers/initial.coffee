
class SignInBaseCtrl
  @$inject =
    [
      "$scope"
      "$rootScope"
      "$log"
      "$location"
      "$window"
      "$timeout"
      "appConfig"
      "SessionRestangular"
      "LocalDataRestangular"
      "sessionService"
      "currentUserService"
      "errorHandlerService"
      "navigationBarService"
      "suggestionService"
      "calendarService"
      "materialService"
      "notificationService"
      "javascriptUtils"
      "deviceUtils"
      "viewParams"
      "uncacheableUrl"
      "splashscreen"
      "deviceready"
      "connectivity"
      "mtnURL"
      "segment"
      "sentry"
      "appleWatchService"
      "contactService"
    ]

  constructor: (@scope
                @rootScope
                @log
                @location
                @window
                @timeout
                @appConfig
                @SessionRestangular
                @LocalDataRestangular
                @sessionService
                @currentUserService
                @errorHandlerService
                @navigationBarService
                @suggestionService
                @calendarService
                @materialService
                @notificationService
                @javascriptUtils
                @deviceUtils
                @viewParams
                @uncacheableUrl
                @splashscreen
                @deviceready
                @connectivity
                @mtnURL
                @segment
                @sentry
                @appleWatchService
                @contactService) ->

    @isDeveloperMenuVisible = @appConfig.isDevelopmentMode

    @navigationBarService.hideMenu()

  _reloadUser: ->
    return @currentUserService.reload({ image_size: @appConfig.thumbnail.large }).then(
      (user) =>
        @user = user
        return user

      (failure) =>
        @log.error "Failed to load user data"
        @error = @errorHandlerService.handle failure
    )

  _fetchSuggestionSources: ->
    return @currentUserService.getRoute().all("suggestion_sources").getList().then(
      (data) =>
        @suggestionSources = @suggestionService.selectEnabledSources(data, @user.source_settings)

        @sources = _.values(
          _(@suggestionSources).sortBy((source) -> source.name.toLowerCase())
                               .groupBy((source) -> source.container_id).value()
        )

        return @suggestionSources

      (failure) =>
        @log.error "fetching suggestion sources failed", failure
        @error = @errorHandlerService.handle failure

    )

  _signInSuccess: ->
    # Refresh restangular's default headers with new user id and token
    @SessionRestangular.refreshDefaultHeaders()

    # Reload user after sign in and check if extra login steps are required
    @_reloadUser().then(
      =>
        return @_checkCalendarConnection()
    ).then(
      (calendarStatus) =>

        notificationPermissionAsked = @notificationService.getPermissionAsked()

        if @currentUserService.isNewUser(@user)
          return "/signup"

        else if @deviceUtils.platform() != "web" &&
                (!@user.image? || @user.image == "") &&
                @signInStep < 3
          return "/signup/profileimage"

        else if !notificationPermissionAsked &&
                @signInStep < 4
          return "/signup/initPushNotifications"

        else if calendarStatus == "not connected" &&
                @signInStep < 5
          return "/signup/calendarConnect"

        else
          return "/signin"

    ).then(
      (path) =>
        @location.search({}).path(path)
    )

  _checkCalendarConnection: ->
    @_fetchSuggestionSources().then(
      (suggestionSources) =>
        # Skip calendar connection check in SPA
        if @deviceUtils.platform() == "web" ||
           @suggestionService.isCurrentDeviceCalendarConnected(suggestionSources) ||
           @sessionService.getBypassCalendarConnectForUser()

          @log.debug("Calendar connected or bypassed, closing initialView")

          # TODO Check current swipe and got straight to it if needed
          return "connected"

        else
          @log.debug("Calendar not connected, go to calendar connect view")
          return "not connected"
    )

  _initPushNotifications: ->
    @notificationService.initPushNotifications()

  handleError: ->
    @error = null

class SignInIndexCtrl extends SignInBaseCtrl

  constructor: ->
    super

    @signInStep = 1
    @isFirstAppLaunch = @sessionService.getFirstAppLaunch()

    # Don't do anything until device is ready
    @deviceready.then =>
      @_init()
      @_setLayout()

  ################
  # PRIVATE
  ################

  _setLayout: ->
    if @feelGoodImageIsVisible
      @navigationBarService.hide()
    else
      @navigationBarService.show()

    backButton = {
      title: "Back"
      onClick: =>
        @feelGoodImageIsVisible = true
        @_setLayout()
    }

    @navigationBarService.update({
      title: if @isPinRequest then "Enter PIN" else @appConfig.appName
      buttons:
        left: if @isPinRequest then @navigationBarService.defaultBackButton() else backButton # null
    })

    @navigationBarService.hideMenu()

  _init: ->
    @signedIn = @sessionService.isSignedIn()

    if @signedIn
      @_signIn()

    else
      @feelGoodImageIsVisible = true
      @splashscreen.hide()

  _signIn: () ->
    @sessionService.setFirstAppLaunch(false)
    ongoingScheduling = @currentUserService.get().ongoing_scheduling

    @segment.identify()
    @sentry.init()

    currentUserTimeFormat = @currentUserService.get().time_display
    moment.locale(currentUserTimeFormat)

    @notificationService.fetchAll()
    @notificationService.pollForNewNotifications()

    @_initAppleWatch()
    @_initPushNotifications()

    if @deviceUtils.platform() != "web" && @appConfig.appBrand != @appConfig.appBrands.MEETINGS

      path = "/scheduling"
    else
      path = "/timeline"

    if @suggestionService.getCalendarSuggestionsEnabled()
      @_initCalendar()

    if @isFirstAppLaunch && ongoingScheduling?
      @sessionService.setShowCarousel(false)

      @viewParams.set({ menuVisible: true })
      path = "/timeline/meeting/#{ongoingScheduling.meeting_id}/scheduling/#{ongoingScheduling.id}"

    @navigationBarService.showMenu()
    @location.path(path)

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

  ################
  # PUBLIC
  ################

  hideFeelGoodImage: ->
    @feelGoodImageIsVisible = false
    @_setLayout()

  showFeelGoodImage: ->
    @feelGoodImageIsVisible = true
    @_setLayout()

  checkPhone: (phone) ->
    @formattedPhone = @contactService.formatPhone(phone, "null")

    if !@formattedPhone.valid
      @viewParams.set({
        phone: @formattedPhone.e164
      })
      @location.path("/signin/country")
    else
      @createPinRequest()

  createPinRequest: ->
    @btnWorking = "pinRequest"
    @sessionService.requestPinWithPhonenumber(@formattedPhone.e164).then(
      (data) =>
        @viewParams.set({
          phone: @formattedPhone.e164
        })
        @location.path("/signin/pin")

      (failure) =>
        @log.warn "Error requesting PIN: ", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  # Developer shortcut sign in
  devSignIn: (email, pin) ->
    @sessionService.signIn(email, pin).then(
      (data) =>
        # Add something to search so that it will be cleared in signInSuccess and redirect may happen.
        @location.search("devSignIn", "foo")
        @_signInSuccess()

      (failure) =>
        @log.warn "Error signing in: ", failure
        @error = @errorHandlerService.handle failure
    )

  clearLoginCheck: ->
    localStorage.clear()
    alert("Login check data removed")

class SignInCountryCodeCtrl extends SignInBaseCtrl

  constructor: ->
    super

    @signInStep = 1
    @phone = @viewParams.get("phone")
    @formattedPhone = @contactService.formatPhone(@phone, "null")

    if !@phone?
      @location.path("/signin")

    @_fetchCountryCodes()
    @_setLayout()

  ################
  # PRIVATE
  ################

  _setLayout: ->
    @navigationBarService.show()

    @navigationBarService.update({
      title: "Check your number"
      buttons:
        left: @navigationBarService.defaultBackButton()
    })

    @navigationBarService.hideMenu()

  _fetchCountryCodes: ->
    @LocalDataRestangular.all("countrycodes").getList().then(
      (data) =>
        @countryCodes = data
    )

  ################
  # PUBLIC
  ################

  validatePhone: ->
    @formattedPhone = @contactService.formatPhone(@phone, @countryCode.id)

  createPinRequest: ->
    @btnWorking = "pinRequest"
    @sessionService.requestPinWithPhonenumber(@formattedPhone.e164).then(
      (data) =>
        @viewParams.set({
          phone: @formattedPhone.e164
        })
        @location.path("/signin/pin")

      (failure) =>
        @log.warn "Error requesting PIN: ", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

class SignInPinCtrl extends SignInBaseCtrl

  constructor: ->
    super

    @signInStep = 1
    @phone = @viewParams.get("phone")

    if !@phone?
      @location.path("/signin")

    e164 = formatE164("null", @phone)
    countryId = countryForE164Number(e164)
    @internationalFormat = formatInternational(countryId, @phone)

    @_setLayout()

  ################
  # PRIVATE
  ################

  _setLayout: ->
    @navigationBarService.show()

    @navigationBarService.update({
      title: "Enter PIN"
      buttons:
        left: @navigationBarService.defaultBackButton()
    })

    @navigationBarService.hideMenu()

  ################
  # PUBLIC
  ################

  resendPin: ->
    @sessionService.requestPinWithPhonenumber(@phone).then(
      (data) =>
        @log.debug "PIN request sent"
        @pinReRequested = true

      (failure) =>
        @log.warn "Error requesting PIN: ", failure
        @error = @errorHandlerService.handle failure
    )

  signIn: ->
    @btnWorking = "signIn"
    @sessionService.signInWithPhonenumber(@phone, @pin).then(
      (data) =>
        @_signInSuccess()

      (failure) =>
        @log.warn "Error signing in: ", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

class SignUpCtrl extends SignInBaseCtrl

  constructor: ->
    super

    @signInStep = 2

    @splashscreen.hide()

    @TOSVisible = false

    @meetingId = @viewParams.get("meetingId")
    @schedulingId = @viewParams.get("schedulingId")
    @msgId = @viewParams.get("msgId")

    @user = @currentUserService.get()

    @_setLayout()

  ################
  # PRIVATE
  ################

  _setLayout: ->
    cancelButton = {
      title: "Cancel"
      onClick: =>
        @sessionService.signOut()
    }

    @navigationBarService.update({
      title: "Your profile"
      buttons:
        left: if @meetingId? then @navigationBarService.defaultBackButton() else cancelButton
    })

    @navigationBarService.hideMenu()

  _confirmEmail: (email) ->
    @currentUserService.confirmEmail(email).then(
      (success) =>
        # Confirm email is called only when email address already exists,
        # so this success callback should never be reached.
        # If for some reason this callback is called, just continue forward.
        @_signInSuccess()

      (failure) =>
        if failure?.error?.code == 1
          @log.debug "Existing email given, PIN code sent to email", failure

          @viewParams.set({
            email: @user.primary_email
          })
          @location.path("/signup/pin")

        else
          @log.warn "Failed email confirm: ", failure
          @error = @errorHandlerService.handle failure
    )

  _returnToScheduling: ->
    # Refresh restangular's default headers with new user id and token
    @SessionRestangular.refreshDefaultHeaders()

    # Reload user and return to scheduling
    @_reloadUser().then(
      () =>
        @location.search({}).path("/timeline/meeting/#{@meetingId}/scheduling/#{@schedulingId}/thanks/#{@msgId}")

      (failure) =>
        @log.debug "Failed to update user", failure
        @error = @errorHandlerService.handle failure
    )

  ################
  # PUBLIC
  ################

  disableSignUpButton: ->
    return !@registrationForm.$valid ||
            @btnWorking

  toggleTOS: ->
    @TOSVisible = !@TOSVisible

  signUp: ->
    @user.tos_accepted = 1
    @btnWorking = "signUp"

    @currentUserService.update(@user).then(
      (data) =>
        @log.debug "Updated user success, got data:", data

        if @meetingId?
          @_returnToScheduling()
        else
          @_signInSuccess()

      (failure) =>
        if failure?.error?.code == 503
          @log.warn "User already exists: ", failure
          @_confirmEmail(@user.primary_email)

        else
          @log.warn "Registration failed: ", failure
          @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

class SignUpPinCtrl extends SignInBaseCtrl

  constructor: ->
    super

    @signInStep = 2

    @email = @viewParams.get("email")

    @_setLayout()

  ################
  # PRIVATE
  ################

  _setLayout: ->
    cancelButton = {
      title: "Cancel"
      onClick: =>
        @sessionService.signOut()
    }

    @navigationBarService.update({
      title: "Enter PIN"
      buttons:
        left: @navigationBarService.defaultBackButton()
    })

    @navigationBarService.hideMenu()

  ################
  # PUBLIC
  ################

  verifyPin: ->
    @btnWorking = "signUp"
    @sessionService.signIn(@email, @pin).then(
      (data) =>

        @_signInSuccess()

      (failure) =>
        @log.warn "Error signing in: ", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  resendPin: ->
    @currentUserService.confirmEmail(@email).then(
      (success) =>
        @log.debug "No existing user found"

      (failure) =>
        if failure?.error?.code == 1
          @log.debug "Existing email given, PIN code sent to email", failure
          @pinReRequested = true
    )

class ProfileImageUploadCtrl extends SignInBaseCtrl

  constructor: ->
    super

    @signInStep = 3

    @splashscreen.hide()

    @user = @currentUserService.get()
    @profileImageUrl = @uncacheableUrl(@user.image)

    @_setLayout()

  ################
  # PRIVATE
  ################

  _setLayout: ->
    @navigationBarService.update({
      title: "Your photo"
      buttons:
        left: null
    })

    @navigationBarService.hideMenu()

  ################
  # PUBLIC
  ################

  addPhoto: ->
    if @uploadProgress? || @deviceUtils.platform() == "web"
      return

    @btnWorking = "uploading"

    @materialService.addPhoto(@appConfig.thumbnail.large).then(
      (data) =>
        @log.debug "Profile picture successfully uploaded"
        @user.upload_id = data.result.upload_id
        @profileImageUrl = @uncacheableUrl(data.result.upload_thumbnail_url)

        return @currentUserService.update(@user).then(
          (data) =>
            @log.debug "Updated user success, got data:", data
            @_signInSuccess()

          (failure) =>
            @log.error "Updating user profile failed", failure
            @error = @errorHandlerService.handle failure
        )

      (failure) =>
        @log.error "Failed to upload profile picture", failure
        @error = @errorHandlerService.handle failure

        return failure

      (progress) =>
        @uploadProgress = progress

    ).finally(
      =>
        @uploadProgress = null
        @btnWorking = null
    )

  skip: ->
    @_signInSuccess()

class CalendarConnectCtrl extends SignInBaseCtrl

  constructor: ->
    super

    @signInStep = 5

    @splashscreen.hide()

    if !@calendarService.getPermissionAsked()
      @connectionStep = "askPermission"

    else
      @connectionStep = "calendarConnect"

    @user = @currentUserService.get()

    @_setLayout()

  ################
  # PRIVATE
  ################

  _setLayout: ->
    @navigationBarService.update({
      title: "Connect your calendar"
      buttons:
        left: null
    })

    @navigationBarService.hideMenu()

  ################
  # PUBLIC
  ################

  initCalendarPlugin: ->
    @calendarService.init().then(
      () =>
        @log.debug "Calendar initialized!"
        @calendarService.setPermissionAsked(true)

        @connectionStep = "calendarConnect"

      (failure) =>
        @log.error "Calendar connection failed", failure
        @error = @errorHandlerService.handle failure
    )

  connectDeviceCalendar: ->
    @btnWorking = "fetchingSources"

    skipTimeout = @timeout(=>
      @skip()
      @scope.$apply()
    , 20000)

    @initCalendarPlugin().then(
      () =>
        @suggestionService.syncCalendars()

    ).then(
      (data) =>
        @log.debug "Calendar connected successfully", data

        @sessionService.addUserToBypassCalendarConnectList()

        @_fetchSuggestionSources()

    ).then(
      (data) =>
        @navigationBarService.show("Calendars")

        @timeout.cancel(skipTimeout)

        @connectionStep = "sourceSelection"

      (failure) =>
        @log.error "Calendar connection failed", failure
        @error = @errorHandlerService.handle failure

    ).finally(
      =>
        @btnWorking = null
    )

  suggestionSourcesSelected: ->
    @_signInSuccess()

  toggleSourceValue: (type, source) ->
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

  setSourceValue: (type, source, value) ->
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

  skip: ->
    @sessionService.addUserToBypassCalendarConnectList()
    @_signInSuccess()

class InitPushNotificationsCtrl extends SignInBaseCtrl

  constructor: ->
    super

    @signInStep = 4

    @splashscreen.hide()

    @_setLayout()

  ############
  # PRIVATE
  ############

  _setLayout: ->
    @navigationBarService.update({
      title: "Allow push notifications"
      buttons:
        left: null
    })

    @navigationBarService.hideMenu()

  ############
  # PUBLIC
  ############

  initPushNotifications: ->
    @btnWorking = "initPushNotifications"
    @notificationService.setPermissionAsked(true)

    @_initPushNotifications()

    @btnWorking = null
    @_signInSuccess()

  skip: ->
    @notificationService.setPermissionAsked(false)
    @_signInSuccess()

signInApp = angular.module 'signInApp',
  [
    'SPARouteConfig'
    'appConfig'
    'mtnUtils'
    'splashscreen'
    'SessionModel'
    'sessionModule'
    'currentUserModule'
    'errorHandler'
    'suggestionModule'
    'notifications'
    'calendarModule'
    'mtnCheckbox'
    'mtnFloatLabel'
    'connectivity'
    'mtnURL'
    'mtnA'
    'mtnDisableScroll'
    'appleWatchModule'
    'contactModule'
  ]

signInApp.controller "SignInIndexCtrl", SignInIndexCtrl
signInApp.controller "SignInCountryCodeCtrl", SignInCountryCodeCtrl
signInApp.controller "SignInPinCtrl", SignInPinCtrl
signInApp.controller "SignUpCtrl", SignUpCtrl
signInApp.controller "SignUpPinCtrl", SignUpPinCtrl
signInApp.controller "ProfileImageUploadCtrl", ProfileImageUploadCtrl
signInApp.controller "CalendarConnectCtrl", CalendarConnectCtrl
signInApp.controller "InitPushNotificationsCtrl", InitPushNotificationsCtrl
