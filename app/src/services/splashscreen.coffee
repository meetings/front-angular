splashscreenModule = angular.module "splashscreen", [ "mtnUtils" ]

splashscreenModule.service "splashscreen", (deviceUtils) ->

  hide: ->
    return if deviceUtils.platform() == "web"

    navigator.splashscreen?.hide()

