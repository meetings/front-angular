currentUserModule = angular.module 'currentUserModule', ['restangular', 'SessionModel', 'errorHandler', 'appConfig', 'mtnUtils']

currentUserModule.service 'currentUserService', ($log, sessionService, SessionRestangular, errorHandlerService, appConfig, deviceUtils) ->

  @user = null

  set: (user) ->
    @user = user
    return localStorage.setItem "__session_currentUser", JSON.stringify(user)

  get: ->
    return @user || @getRestangularized()

  getRestangularized: ->
    localStorageUser = @getFromLocalStorage()

    return unless localStorageUser?

    @user = SessionRestangular.restangularizeElement(null, localStorageUser, "users", null)
    return @user

  getFromLocalStorage: ->
    return JSON.parse localStorage.getItem "__session_currentUser"

  getRoute: ->
    return SessionRestangular.one('users', sessionService.getUserId())

  reload: (options) ->
    options = options || {}

    return @getRoute().get(options).then(
      (user) =>
        @set(user)
        return user
    )

  update: (userPromise) ->
    return userPromise.put().then(
      (user) =>
        @set user
        return user
    )

  confirmEmail: (email) ->
    return @getRoute().post('confirm_email', {
      user_id: sessionService.getUserId()
      email: email
      include_pin: 1
    })

  confirmPhone: (phone) ->
    return @getRoute().post('confirm_phone', {
      user_id: sessionService.getUserId()
      phone: phone
      include_pin: 1
    })

  startTrial: ->
    return @getRoute().post('start_free_trial')

  sendProFeaturesEmail: ->
    return @getRoute().post('send_pro_features_email')

  sendTestPush: (registrationId) ->
    @getRoute().post('send_test_push_notification', {
      registration_id: registrationId
      device_type: deviceUtils.platform()
      beta: appConfig.isBetaEnvironment
    })

  setDevicePushStatus: (registrationId, enabled) ->
    @getRoute().post('set_device_push_status', {
      registration_id: registrationId
      enabled: enabled
      device_type: deviceUtils.platform()
      beta: appConfig.isBetaEnvironment
    })

  isNewUser: (user) ->
    return (user.email_confirmed == 0 && user.phone_confirmed == 0) || user.tos_accepted == 0

  isPro: (user) ->
    return false unless user?
    return user.is_pro == 1 || user.is_trial_pro == 1

  isTrialExpired: (user) ->
    return user.is_free_trial_expired == 1

  getUserPhoneCountryId: (user) ->
    if _.contains(user.phone, "#")
      e164 = formatE164("null", user.phone.substr(0, user.phone.indexOf("#")))
    else
      e164 = formatE164("null", user.phone)
    return countryForE164Number(e164)

  getEmailSubmitted: ->
    return JSON.parse localStorage.getItem "__email_submitted"

  setEmailSubmitted: ( emailSubmitted ) ->
    return localStorage.setItem "__email_submitted", JSON.stringify( emailSubmitted )
