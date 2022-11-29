class PageWrapperCtrl

  @$inject =
    [
      "$scope"
      "$location"
      "$log"
      "appConfig"
      "deviceUtils"
      "jsonMsgChannel"
      "viewParams"
      "connectivity"
    ]

  constructor: (@scope
                @location
                @log
                @appConfig
                @deviceUtils
                @jsonMsgChannel
                @viewParams
                @connectivity) ->

    # ControllerAs doesn't play well with isolate scope, so copy properties manually to the right scope.
    # https://github.com/angular/angular.js/issues/7635
    @ngModel = @scope.ngModel
    @mtnPullToRefreshEnabled = @scope.mtnPullToRefreshEnabled
    @mtnPullToRefreshCallback = @scope.mtnPullToRefreshCallback
    @mtnShowNotification = @scope.mtnShowNotification()

    @connected = @connectivity.isOnline()
    @isIos = @deviceUtils.isIos()

    if @ngModel.delayedSpinner?
      @delayedSpinner = @ngModel.delayedSpinner

    @_initMessageListener()

  ############
  # PRIVATE
  ############

  _initMessageListener: ->
    @scope.$on "$destroy", =>
      @log.debug "[pageWrapper] destroyed, unsubscribing MsgChannel"
      @jsonMsgChannel.unsubscribe(@msgChannel)

    @msgChannel = @jsonMsgChannel.subscribe (data) =>
      @log.debug "[pageWrapper] received postmessage: ", data?.event, data

      if data?.event == "openNotification"
        @openNotification(data.notification.additionalData.nid)

        if !@scope.$$phase
          @scope.$apply()

      if data?.event == "newNotification"
        @notification = data.notification
        @_debouncePopupDestroy()

        if !@scope.$$phase
          @scope.$apply()

      if data?.event == "removeNotification"
        @_clearNotification()

      if data?.event == "connectionStatusChanged"
        @_changeConnectionStatus(data)

  _debouncePopupDestroy: ->
    debounce = _.debounce(
      =>
        @_clearNotification()
        @scope.$apply()

    , 10000)

    return debounce()

  _clearNotification: ->
    @notification = null

  _changeConnectionStatus: (data) ->
    @log.debug "Changing connection status, connected == ", data.connected

    @scope.$apply =>
      @connected = data.connected

  ############
  # PUBLIC
  ############

  showNotification: (notification) ->
    if !@mtnShowNotification?
      return true

    @mtnShowNotification(notification)

  openNotification: (nid) ->
    @jsonMsgChannel.publish JSON.stringify(event: "removeNotification")

    @viewParams.set("fetchAndOpenNotification": nid)
    @location.path("/notifications")

  dismissNotification: ->
    @jsonMsgChannel.publish JSON.stringify(event: "removeNotification")

pageWrapper = angular.module "pageWrapper", [
  "appConfig"
  "mtnSpinner"
  "mtnDialogs"
  "errorHandler"
  "mtnInnerScroll"
  "mtnUtils"
  "MsgChannel"
  "mtnPullToRefresh"
  "connectivity"
]

# Ensures that the top and bottom of the element are never at 0 or 100% when user starts to scroll.
# This way scrolling will happen on the element that user has touched and not in any of it's parents.
#
pageWrapper.directive "pageWrapper", ->
  restrict: 'E'
  transclude: true
  controller: 'PageWrapperCtrl'
  controllerAs: 'pageWrapper'
  scope:
    ngModel: '='
    mtnPullToRefreshEnabled: '=?'
    mtnPullToRefreshCallback: '&'
    mtnShowNotification: '&?'
  templateUrl: '/views/partials/_pageWrapper.html'
