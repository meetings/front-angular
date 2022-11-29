class AppStoreRedirectCtrl

  @$inject = [
    "$log"
    "appConfig"
    "deviceUtils"
  ]

  constructor: (@log
                @appConfig
                @deviceUtils) ->

    if @deviceUtils.isIos()
      window.location = @appConfig.appStoreUrls.ios
    if @deviceUtils.isAndroid()
      window.location = @appConfig.appStoreUrls.android


  ##############
  # PRIVATE
  ##############

appStoreRedirectApp = angular.module "appStoreRedirectApp",
[
  "appConfig"
  "mtnUtils"
  "partials"
]

appStoreRedirectApp.controller "AppStoreRedirectCtrl", AppStoreRedirectCtrl
