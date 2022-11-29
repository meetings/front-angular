class NavigationCtrl

  @$inject =
    [
      "$scope"
      "$rootScope"
      "$log"
      "$location"
      "$window"
      "appConfig"
      "deviceUtils"
      "sessionService"
      "currentUserService"
      "notificationService"
      "jsonMsgChannel"
      "navigationBarService"
      "deviceready"
    ]

  constructor: (@scope,
                @rootScope,
                @log,
                @location,
                @window,
                @appConfig,
                @deviceUtils,
                @sessionService,
                @currentUserService,
                @notificationService,
                @msgChannel,
                @navigationBarService,
                @deviceready) ->

    @menuVisible = true
    @leftButtonVisible = false
    @rightButtonVisible = false

    @platform = @deviceUtils.platform()

    @_initPathWatcher()
    @_initUserWatcher()
    @_initNotificationBadgeWatcher()
    @_initNavigationBarWatchers()

    @_initOffCanvas()

  ##############
  # PRIVATE
  ##############

  _initPathWatcher: ->
    @rootScope.$watch(
      =>
        return @location.path()
      (path) =>
        @activeTab = path.replace(/^(\/[^\/]*).*$/, "$1");
    )

  _initUserWatcher: ->
    @scope.$watch(
      =>
        @currentUserService.user
      (user) =>
        @user = user
    )

  _initNotificationBadgeWatcher: ->
    @scope.$watch(
      () =>
        return @notificationService.badge
      (value) =>
        @notificationBadge = value
    )

  _initNavigationBarWatchers: ->
    @scope.$watch(
      () =>
        return @navigationBarService.menuVisible
      (menuVisible) =>
        if menuVisible?
          @menuVisible = menuVisible
    )

    @scope.$watch(
      () =>
        return @navigationBarService.navBarVisible
      (navBarVisible) =>
        if navBarVisible?
          @navBarVisible = navBarVisible
    )

    @scope.$watch(
      () =>
        return @navigationBarService.rightButton
      (rightButton) =>
        if rightButton?
          @rightButtonVisible = true
          @rightButton = rightButton
        else
          @rightButtonVisible = false
    )

    @scope.$watch(
      () =>
        return @navigationBarService.leftButton
      (leftButton) =>
        if leftButton?
          @leftButtonVisible = true
          @leftButton = leftButton
        else
          @leftButtonVisible = false
    )

  _initOffCanvas: ->
    $(document).foundation(
      offcanvas:
        close_on_click : true
        open_method: "overlap"
    )

    $(document).on("open.fndtn.offcanvas", "[data-offcanvas]", () =>

      if !@window.history.state?.menu?
        @window.history.pushState({menu: "open"}, null, null)
    )

    @window.onpopstate = (event) =>
      $(".off-canvas-wrap").foundation("offcanvas", "hide", "offcanvas-overlap");


  toggleOffcanvas: ->
    $(".off-canvas-wrap").foundation("offcanvas", "toggle", "offcanvas-overlap");
    return false

  ##############
  # PUBLIC
  ##############

  closeNav: ->
    @window.history.back()

  path: (path) ->
    @toggleOffcanvas()

    @location.path(path)

  signOut: ->
    @sessionService.signOut()



navigationApp = angular.module "navigationApp",
  [
    "appConfig"
    "mtnFullHeight"
    "mtnDisableScroll"
  ]

navigationApp.controller("NavigationCtrl", NavigationCtrl)
