# Include all common module dependencies here in "appConfig".
# Then controllers only need to require "appConfig" instead of a long copypasted list of everything.
appConfig = angular.module "appConfig",
  [
    "angulartics"
    "angulartics.segment.io"

    "ngSanitize"

    "pageWrapper"
    "epochToMoment"
    "mtnAutofocus"
    "mtnAvatar"

    "mtnUtils"
    "breadcrumb"
    "analytics"
    "sentryModule"
    "materialModule"
    "sessionModule"
    "MsgChannel"
    "currentUserModule"
    "navigationBarModule"
    "viewParams"
    "cacheModule"
  ]

# Global application brand integer
#
# Usage through appConfig provider:
#   appConfig.appBrand
#
appConfig.constant "appBrand", mtnApp.appBrand

# Global application brands, constants to help clarify what appBrand integer means
#
# Usage through appConfig provider:
#   appConfig.appBrands
#
appConfig.constant "appBrands", mtnApp.appBrands

# Global application name
#
# Usage through appConfig provider:
#   appConfig.appName
#
appConfig.constant "appName", mtnApp.appName

# Choose app version.
#
# Usage through appConfig provider:
#   appConfig.version
#
appConfig.constant "appVersion", mtnApp.version

# Choose environment dependent API endpoints
# See "appEnvironments" for choices.
#
# Usage through appConfig provider:
#   appConfig.environment
#
appConfig.constant "appEnvironment", mtnApp.config.environment

# Choose application mode.
#
# Options:
#   development - debug log level, development menus
#   production  - debug log hidden, development menus hidden
#
# Usage through appConfig provider:
#   appConfig.isDevelopmentMode
#
# N.B. To select mode for a build, see "config/environment.js.example"
#
appConfig.constant "appMode", mtnApp.config.mode

# Application wide config settings.
# Define settings in appEnvironments.
#
# Usage:
#   appConfig.api.baseUrl       (see other options in appEnvironments)
#   appConfig.isDevelopmentMode (see definition in appMode constant)
#   appConfig.environment       (see definition in appEnvironment constant)
#   appConfig.version           (see definition in appVersion constant)
#
# N.B. Please document each value in appConfigSpec
#
appConfig.provider "appConfig", (appEnvironment,
                                 appMode,
                                 appVersion,
                                 appName,
                                 appBrand
                                 appBrands) ->
  accessors =
    isDevelopmentMode: appMode == "development"
    isBetaEnvironment: appEnvironment == "beta" || appEnvironment == "alpha"
    environment: appEnvironment
    version: appVersion
    appName: appName
    appBrand: appBrand
    appBrands: appBrands

  appEnvironments = window.appEnvironments[appEnvironment]
  commons = window.appEnvironments.commons
  appSettings = window.mtnApp.appSetting

  appConfig: _.extend appEnvironments, commons, accessors, appSettings

  $get: ->
    return @appConfig

appConfig.config ($analyticsProvider, appConfigProvider) ->
  $analyticsProvider.virtualPageviews(false)

appConfig.config [
  "$compileProvider", ($compileProvider) ->
    $compileProvider.aHrefSanitizationWhitelist(/^\s*(https?|tel|mailto|skype|sip|sips):/)
]

appConfig.config ($logProvider, appMode) ->
  if appMode == "production"
    $logProvider.debugEnabled(false)
