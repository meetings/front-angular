sessionModule = angular.module 'sessionModule', ['restangular', 'SessionModel', 'appConfig', 'mtnUtils']

sessionModule.service 'sessionService', (
  AuthenticationRestangular
  $log
  $rootScope
  $window
  $location
  appConfig
  deviceUtils
  cacheService) ->

  getShowCarousel: ->
    return false
    # return false if appConfig.appBrand == appConfig.appBrands.MEETINGS

    # showCarousel = JSON.parse localStorage.getItem("__show_carousel")

    # if !showCarousel?
    #   @setShowCarousel(false)
    #   return true

    # return showCarousel

  setShowCarousel: (value) ->
    localStorage.setItem("__show_carousel", value)

  getFirstAppLaunch: ->
    firstAppLaunch = JSON.parse localStorage.getItem("__first_app_launch")

    if !firstAppLaunch?
      return true

    return firstAppLaunch

  setFirstAppLaunch: (value) ->
    localStorage.setItem("__first_app_launch", value)

  getBypassCalendarConnectList: ->
    bypassCalendarConnectList = localStorage.getItem("__bypass_calendar_connect_list")
    if bypassCalendarConnectList
      return JSON.parse(bypassCalendarConnectList)
    else
      return []

  setBypassCalendarConnectList: (value) ->
     localStorage.setItem("__bypass_calendar_connect_list", JSON.stringify(value))

  getBypassCalendarConnectForUser: ->
    list = @getBypassCalendarConnectList()
    userId = @getUserId()

    return _.contains(list, userId)

  addUserToBypassCalendarConnectList: ->
    if !@getBypassCalendarConnectForUser()
      list = @getBypassCalendarConnectList()
      userId = @getUserId()
      list.push(userId)
      @setBypassCalendarConnectList(list)

  getBypassMeetmeWizard: ->
    bypassMeetmeWizard = localStorage.getItem("__bypass_meetme_wizard")
    return bypassMeetmeWizard? && bypassMeetmeWizard == "true"

  setBypassMeetmeWizard: (value) ->
     localStorage.setItem("__bypass_meetme_wizard", value)

  checkLogin: ->
    if !@isSignedIn()
      @showSignInView()

  getToken: () ->
    return localStorage.getItem "__session_token"

  setToken: (token) ->
    localStorage.setItem "__session_token", token

  getUserId: () ->
    userId = localStorage.getItem "__session_userId"
    if userId == "null"
      return null

    return userId

  setUserId: (userId) ->
    localStorage.setItem "__session_userId", userId

  setGoogleSignInSessionString: (sessionString) ->
    localStorage.setItem "__login_session_string", sessionString

  getGoogleSignInSessionString: () ->
    localStorage.getItem "__login_session_string"

  isSignedIn: () ->
    return @getUserId()?

  showSignInView: (opts) ->
    if $window.location.hash.indexOf("redirect_to_meeting") == -1
      $location.path("/signin")

  clear: ->
    $log.debug "[Session Service] Clearing local storage"
    localStorage.removeItem "__session_token"
    localStorage.removeItem "__session_userId"
    localStorage.removeItem "__session_currentUser"

    cacheService.removeAll()

  broadcastExpiry: () ->
    $log.debug "[Session Service] Broadcasting session expiry message"
    window.postMessage "__session_expired", "*"

  # Event callbacks for Sign In and Sign Out
  initEventListener: (onSignOut) ->
    window.addEventListener "message", (msg) =>
      onSignOut() if msg.data == "__session_expired"

  requestPin: (email) ->
    return AuthenticationRestangular.all("login").post({
      email: email,
      include_pin: "1",
      allow_register: "1"
      time_zone: jstz.determine().name()
    })

  requestPinWithPhonenumber: (phone) ->
    return AuthenticationRestangular.all("login").post({
      phone: phone,
      include_pin: "1",
      allow_register: "1"
      time_zone: jstz.determine().name()
    })

  signOut: ->
    @broadcastExpiry()

    setTimeout( =>
      @clear()
      @showSignInView()
      $rootScope.$apply()
    , 50)

  signInSuccess: (data) ->
    @setToken data.result.token
    @setUserId data.result.user_id

    return data

  signIn: (email, pin) ->
    AuthenticationRestangular.all("login").post({
      email: email,
      pin: pin
      device_type: deviceUtils.platform()
      beta: appConfig.isBetaEnvironment
    }).then(
      (data) =>
        @signInSuccess(data)
    )

  signInWithPhonenumber: (phone, pin) ->
    AuthenticationRestangular.all("login").post({
      phone: phone,
      pin: pin
      device_type: deviceUtils.platform()
      beta: appConfig.isBetaEnvironment
    }).then(
      (data) =>
        @signInSuccess(data)
    )

  signInWithGoogle: (code) ->
    AuthenticationRestangular.all("login").post({
      google_code: code
      google_redirect_uri: appConfig.googleSignIn.redirectUri
      device_type: deviceUtils.platform()
      beta: appConfig.isBetaEnvironment
      time_zone: jstz.determine().name()
    }).then(
      (data) =>
        @signInSuccess(data)
    )

  signInWithUserIdAndToken: (userId, token) ->
    if userId? && token?
      @setUserId(userId)
      @setToken(token)

      return true

    return false
