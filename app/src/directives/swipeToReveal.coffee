mtnSwipeToReveal = angular.module "mtnSwipeToReveal", [ 'appConfig' ]

# Swipe element to reveal another element underneath it
#
# Usage:
#
#    <ANY mtn-swipe-to-reveal="element id"></ANY>
#
#
mtnSwipeToReveal.directive "mtnSwipeToReveal", (javascriptUtils) ->
  restrict: 'A'
  scope:
    mtnSwipeToRevealEnabled: '&'
    mtnOnRevealActions: '&'
    mtnOnHideActions: '&'

  link: (scope, elem, attrs) ->

    return unless scope.mtnSwipeToRevealEnabled()

    elem.addClass("static")

    MAX_SWIPE_WIDTH = 0
    dX = 0
    oldX = 0
    elemPos = 0

    active = false

    calculateMaxSwipeWidth = ->
      MAX_SWIPE_WIDTH = -100

      if attrs.mtnSwipeToReveal? && elem[0].parentElement.querySelector("#" + attrs.mtnSwipeToReveal)?
        MAX_SWIPE_WIDTH = 0 - elem[0].parentElement.querySelector("#"+attrs.mtnSwipeToReveal).getBoundingClientRect().width

    resetElemPosition = ->
      if !active
        elemPos = 0
        javascriptUtils.vendorPrefixAttr(elem[0], "transform", "translate3d( " + elemPos + "px, 0, 0 )")

        scope.$apply => scope.mtnOnHideActions()

    swipeStart = (e) ->
      active = true
      elem.removeClass("static")

      if MAX_SWIPE_WIDTH == 0
        calculateMaxSwipeWidth()

      oldX = e.touches?[0].pageX || e.pageX

    swipeEnd = ->
      active = false
      elem.addClass("static")

      if elemPos > MAX_SWIPE_WIDTH * 0.5
        resetElemPosition()

      else
        elemPos = MAX_SWIPE_WIDTH
        javascriptUtils.vendorPrefixAttr(elem[0], "transform", "translate3d( " + elemPos + "px, 0, 0 )")

        scope.$apply => scope.mtnOnRevealActions()

    swipeMove = (e) ->
      pageX = e.touches?[0].pageX || e.pageX

      dX = pageX - oldX

      elemLeft = elem[0].getBoundingClientRect().left

      if (elemLeft >= 0 && dX > 0)
        return true

      if elemLeft < MAX_SWIPE_WIDTH
        dist = Math.abs(MAX_SWIPE_WIDTH - elemLeft)
        mult = 1 / Math.pow(dist, 0.45)
        dX = (pageX - oldX) * mult

      elemPos += dX

      if elemPos > 0
        elemPos = 0

      javascriptUtils.vendorPrefixAttr(elem[0], "transform", "translate3d( " + elemPos + "px, 0, 0 )")

      oldX = pageX

    unbind = ->
      # Unbind touch listeners
      if (window.navigator.pointerEnabled)
        # IE touch listeners
        elem[0].removeEventListener "pointerdown", swipeStart, false
        elem[0].removeEventListener "pointermove", swipeMove, false
        elem[0].removeEventListener "pointerup", swipeEnd, false
        elem[0].removeEventListener "pointerleave", swipeEnd, false
        document.removeEventListener "pointerdown", resetElemPosition, false

      # Normal touch listeners
      elem[0].removeEventListener "touchstart", swipeStart, false
      elem[0].removeEventListener "touchmove", swipeMove, false
      elem[0].removeEventListener "touchend", swipeEnd, false
      elem[0].removeEventListener "touchcancel", swipeEnd, false
      document.removeEventListener "touchstart", resetElemPosition, false

    bind = ->
      # Unbind on $destroy
      scope.$on("$destroy", ->
        unbind()
      )

      # Bind touch listener
      if (window.navigator.pointerEnabled)
        # IE touch listeners
        elem[0].addEventListener "pointerdown", swipeStart, false
        elem[0].addEventListener "pointermove", swipeMove, false
        elem[0].addEventListener "pointerup", swipeEnd, false
        elem[0].addEventListener "pointerleave", swipeEnd, false
        document.addEventListener "pointerdown", resetElemPosition, false

      # Normal touch listeners
      elem[0].addEventListener "touchstart", swipeStart, false
      elem[0].addEventListener "touchmove", swipeMove, false
      elem[0].addEventListener "touchend", swipeEnd, false
      elem[0].addEventListener "touchcancel", swipeEnd, false
      document.addEventListener "touchstart", resetElemPosition, false

    bind()
