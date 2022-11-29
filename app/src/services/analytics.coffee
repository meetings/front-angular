analyticsModule = angular.module "analytics", [ "appConfig", "mtnUtils" ]

analyticsModule.service "segment", (
  $rootScope
  $location
  $window
  $timeout
  $log
  $routeParams
  appConfig
  sessionService
  currentUserService
  deviceUtils
) ->

  init: ->
    if analytics?
      @identify()

      @initTrackListener()

    else
      $timeout(=>
        @init()
      , 100)

  identify: ->
    if sessionService.isSignedIn() && currentUserService.get()?
      analytics.identify( sessionService.getUserId(), _.extend( @getUser() , @getAppData() ) )
    else
      analytics.identify("signed out", @getAppData() )

  reset: ->
    analytics.reset()
    analytics.identify("signed out", @getAppData() )

  # Get user details to be sent with every event if user is logged in and has email, else returns {}
  getUser: ->
    user = currentUserService.get()
    return {} unless user?.email?

    return {
      name  : user.name
      email : user.email
      "Email confirmed"        : user.email_confirmed
      "Free trial has expired" : user.free_trial_has_expired
      "Google connected"       : user.google_connected
      "Organization"           : user.organization
      "Title"                  : user.organization_title
      "Presumed country code"  : user.presumed_country_code
      "Subscription type"      : user.subscription_type
      "TOS accepted"           : user.tos_accepted
    }

  # Get appName and appVersion to be sent with every event
  getAppData: ->
    return {
      appVersion: appConfig.version
      appName   : appConfig.appName
      build     : if deviceUtils.platform() == "web" then "web" else "mobile"
    }

  # Register custom view type parameter to make reading analytics easier.
  # Override default $analytics tracking to enable registering routeParams as super properties.
  initTrackListener: ->
    @trackRouteChangeSuccess()

  trackRouteChangeSuccess: ->
    $rootScope.$on('$routeChangeSuccess', (event, current) =>
      if current && (current.$$route || current).redirectTo
        return

      # Remove numbers (i.e. IDs) from path
      type = $location.path().replace(/\/[0-9]+/g, "")
      @registerExtraData( "View type": type )

      analytics.page(type)
    )

  registerExtraData: ( options ) ->
    if $routeParams["meetingId"]
      options["Meeting id"] = $routeParams["meetingId"]
    else
      options["Meeting id"] = ""

    if $routeParams["schedulingId"]
      options["Scheduling id"] = $routeParams["schedulingId"]
    else
      options["Scheduling id"] = ""

    if $location.search().utm_source?
      options["utm_source"] = $location.search().utm_source
    else
      options["utm_source"] = ""

    analytics.identify( options )
