session = angular.module("SessionModel", ["restangular", "appConfig", "mtnUtils"])

session.run (Restangular, appConfig) ->
  Restangular.setBaseUrl appConfig.api.baseUrl


session.config (RestangularProvider) ->
  RestangularProvider.setDefaultHttpFields
    timeout: 20000 # Milliseconds

  RestangularProvider.setResponseInterceptor (data, operation, what, url, response, deferred) ->

    if !data || data.error
      deferred.reject(data)
    else
      deferred.resolve(data)

    return data

  # Include original unrestangularized element in the response
  RestangularProvider.setResponseExtractor (response) ->
    newResponse = response
    if (angular.isArray(response))
      angular.forEach(newResponse, (value, key) ->
        newResponse[key].originalElement = angular.copy(value)
      )
    else
      newResponse.originalElement = angular.copy(response)

    return newResponse

session.factory "SessionRestangular", (appConfig, Restangular, sessionService, deviceUtils) ->

  @sessionRestangular = Restangular.withConfig (RestangularConfigurer) ->

    RestangularConfigurer.setDefaultHeaders
      "user_id": sessionService.getUserId(),
      "dic": sessionService.getToken(),
      "x-meetings-app-version": appConfig.version + " " + appConfig.appName + " " + deviceUtils.platform()
      "x-expect-http-errors-for-rest": 1
      "x-expect-int-epochs": 1

  @sessionRestangular.refreshDefaultHeaders = =>
    @sessionRestangular.setDefaultHeaders
      "user_id": sessionService.getUserId(),
      "dic": sessionService.getToken(),
      "x-meetings-app-version": appConfig.version + " " + appConfig.appName + " " + deviceUtils.platform()
      "x-expect-http-errors-for-rest": 1
      "x-expect-int-epochs": 1

  return @sessionRestangular

session.factory "AuthenticationRestangular", (appConfig, Restangular, deviceUtils) ->

  authenticationRestangular = Restangular.withConfig (RestangularConfigurer) ->

    RestangularConfigurer.setDefaultHeaders
      "x-meetings-app-version": appConfig.version + " " + appConfig.appName + " " + deviceUtils.platform()
      "x-expect-int-epochs": 1

  return authenticationRestangular

session.factory "LocalDataRestangular", (appConfig, Restangular) ->

  return Restangular.withConfig (RestangularConfigurer) ->
    RestangularConfigurer.setBaseUrl("data")
    RestangularConfigurer.setRequestSuffix('.json')
