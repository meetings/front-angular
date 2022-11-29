sentryModule = angular.module "sentryModule", ["appConfig", "sessionModule", "currentUserModule", "mtnUtils"]

# Configure sentry parameters in app startup
sentryModule.service "sentry", ($window, appConfig, sessionService, currentUserService, deviceUtils) ->
  init: ->
    if appConfig.sentry.enabled

      user = if sessionService.isSignedIn() then currentUserService.get() else null
      userId    = user?.id || "Signed out"

      $window.Raven.setUserContext(
        id:    userId
      )

      $window.Raven.setTagsContext(
        version: appConfig.version
        appName: appConfig.appName
        build  : if deviceUtils.platform() == "web" then "web" else "mobile"
      )
