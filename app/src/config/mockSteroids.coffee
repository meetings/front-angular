# Mock steroids in SPA
#
# Steroids.js is not required in web build, but because it is heavily used in controllers and services directly,
# removing all references to steroids would be difficult.
#
# Instead of steroids.js we use mock steroids object in web build to avoid undefined exceptions.
#
# If new steroids.js apis are used in MPA, this object should mock those apis as well.
#
if !window.steroids
  window.steroids = {
    openURL: -> null
    buttons: {
      NavigationBarButton: -> null
    }
    initialView: {
      show: -> null
      dismiss: -> null
    }
    view: {
      setBackgroundColor: -> null
      setAllowedRotations: -> null
      params: -> null
    }
    views: {
      WebView: -> null
    }
    layers: {
      push: -> null
      pop: -> null
      replace: -> null
    }
    tabBar: {
      update: -> null
      show: -> null
      hide: -> null
      on: -> null
      off: -> null
      selectTab: -> null
    }
    splashscreen:
      hide: -> null
  }
