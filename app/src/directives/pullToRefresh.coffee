mtnPullToRefresh = angular.module "mtnPullToRefresh", ['appConfig', 'MsgChannel']

# Adds position absolute and follows touchmove if element's scrollTop is 0
#
mtnPullToRefresh.directive "mtnPullToRefresh", ($log, $timeout, javascriptUtils, JsonMsgChannel) ->
  restrict: 'A'
  scope:
    mtnPullToRefreshCallback: '&'
  link: (scope, elem, attrs) ->
    enabled = attrs.mtnPullToRefresh == "true"

    ptrInfoElement = angular.element(document.getElementById("pull-to-refresh"))

    if enabled
      ptrInfoElement.addClass("ptr-show")
    else
      ptrInfoElement.removeClass("ptr-show")

    return unless enabled

    jsonMsgChannel = new JsonMsgChannel("PullToRefresh")
    msgChannel = null

    element = elem[0]
    dY = 0
    oldY = 0
    elemPosY = 0
    loading = false
    active = false

    swipeStart = (e) ->
      return if loading || active

      dY = 0
      elemPosY = 0
      oldY = e.touches?[0].pageY || e.pageY

      javascriptUtils.vendorPrefixAttr(ptrInfoElement[0], "transform", "translate3d( 0, 0px, 0 )")
      ptrInfoElement.addClass("ptr-animated")

      # < 2 because mtn-inner-scroll sets scrollTop to 1
      if element.scrollTop < 2
        active = true
        elem.addClass("ptr-active")

    ptrLength = 50

    swipeMove = (e) ->
      return unless active && !loading

      pageY = e.touches?[0].pageY || e.pageY

      dY = pageY - oldY

      if elemPosY > ptrLength
        dist = Math.abs(ptrLength - elemPosY)
        mult = 1 / Math.pow(dist, 0.25)
        dY = (pageY - oldY) * mult

      elemPosY += dY

      if elemPosY >= 0
        e.preventDefault()
        javascriptUtils.vendorPrefixAttr(element, "transform", "translate3d( 0, "+elemPosY+"px, 0 )")

      if elemPosY >= ptrLength
        javascriptUtils.vendorPrefixAttr(ptrInfoElement[0], "transform", "translate3d( 0, -44px, 0 )")

      oldY = pageY

    swipeEnd = (e) ->
      return unless active && !loading

      if elemPosY >= ptrLength
        loading = true
        javascriptUtils.vendorPrefixAttr(element, "transform", "translate3d( 0, "+ptrLength+"px, 0 )")

        javascriptUtils.vendorPrefixAttr(ptrInfoElement[0], "transform", "translate3d( 0, -44px, 0 )")

        scope.mtnPullToRefreshCallback()

      else
        javascriptUtils.vendorPrefixAttr(element, "transform", "translate3d( 0, 0px, 0 )")

      active = false
      elem.removeClass("ptr-active")

    unbind = ->
      # Unbind touch listeners
      if (window.navigator.pointerEnabled)
        # IE touch listeners
        elem[0].removeEventListener "pointerdown", swipeStart, false
        elem[0].removeEventListener "pointermove", swipeMove, false
        elem[0].removeEventListener "pointerup", swipeEnd, false
        elem[0].removeEventListener "pointerleave", swipeEnd, false

      # Normal touch listeners
      element.removeEventListener "touchstart", swipeStart, false
      element.removeEventListener "touchmove", swipeMove, false
      element.removeEventListener "touchend", swipeEnd, false
      element.removeEventListener "touchcancel", swipeEnd, false

      element.removeEventListener "mousedown", swipeStart, false
      element.removeEventListener "mousemove", swipeMove, false
      element.removeEventListener "mouseup", swipeEnd, false

      jsonMsgChannel.unsubscribe(msgChannel)

    bind = ->
      # Unbind on $destroy
      scope.$on("$destroy", ->
        unbind()
      )

      jsonMsgChannel = new JsonMsgChannel("PullToRefresh")

      msgChannel = jsonMsgChannel.subscribe (data) ->
        if data?.event == "didFecthAll"
          loading = false
          ptrInfoElement.removeClass("ptr-animated")
          javascriptUtils.vendorPrefixAttr(element, "transform", "translate3d( 0, 0px, 0 )")

          $timeout(->
            javascriptUtils.vendorPrefixAttr(ptrInfoElement[0], "transform", "translate3d( 0, 0px, 0 )")
          , 150)

      # Bind touch listener
      if (window.navigator.pointerEnabled)
        # IE touch listeners
        element.addEventListener "pointerdown", swipeStart, false
        element.addEventListener "pointermove", swipeMove, false
        element.addEventListener "pointerup", swipeEnd, false
        element.addEventListener "pointerleave", swipeEnd, false

      # Normal touch listeners
      element.addEventListener "touchstart", swipeStart, false
      element.addEventListener "touchmove", swipeMove, false
      element.addEventListener "touchend", swipeEnd, false
      element.addEventListener "touchcancel", swipeEnd, false

      element.addEventListener "mousedown", swipeStart, false
      element.addEventListener "mousemove", swipeMove, false
      element.addEventListener "mouseup", swipeEnd, false

    bind()
