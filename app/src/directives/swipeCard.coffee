mtnSwipeCard = angular.module "mtnSwipeCard", [ 'appConfig' ]

mtnSwipeCard.directive "mtnSwipeCard", ($timeout, jsonMsgChannel, javascriptUtils) ->
  restrict: 'E'
  scope:
    onAccept           : "&mtnSwipeOnAccept"
    onReject           : "&mtnSwipeOnReject"
    onElementYes       : "&mtnSwipeOnElementYes"
    onElementNo        : "&mtnSwipeOnElementNo"
    enabled            : "=mtnSwipeEnabled"
    data               : "=mtnSwipeData"
    isFirstSwipeAction : "=mtnIsFirstSwipeAction"
    firstSwipeDialog   : "&mtnFirstSwipeDialog"
  link: (scope, elem, attrs) ->

    msgChannel = null

    SWIPE_THRESHOLD = 22
    dX = 0
    dY = 0
    oldX = 0
    oldY = 0
    elemPosX = 0
    elemPosY = 0
    answeringEnabled = false

    swiping = false

    setElemTransform = (translateX, translateY, rotate) ->
      javascriptUtils.vendorPrefixAttr(elem[0], "transform", "translate3d(" + translateX + ", " + translateY + ", 0) rotate(" + rotate + ")")

    swipeStart = (e) ->

      elem.removeClass("static")
      swiping = true

      dX = 0
      dY = 0
      oldX = 0
      oldY = 0
      elemPosX = 0
      elemPosY = 0

      if e.touches?
        oldX = e.touches?[0].pageX || e.pageX
        oldY = e.touches?[0].pageY || e.pageY

      answeringEnabled = scope.data.yes_option?.begin_epoch?

    swipeEnd = (e) ->
      swiping = false

      if elemPosX > SWIPE_THRESHOLD && answeringEnabled
        if scope.isFirstSwipeAction
          elem.addClass("static")
          scope.firstSwipeDialog()(true, true)
          scope.$apply()

        else
          TweenLite.to(elem, 0.1, { css: { x: window.innerWidth, z: 0.01, rotation: 0 }, ease: Power2.linear, onComplete: scope.onAccept } )

      else if elemPosX < -SWIPE_THRESHOLD && answeringEnabled
        if scope.isFirstSwipeAction
          elem.addClass("static")
          scope.firstSwipeDialog()(false, true)
          scope.$apply()

        else
           TweenLite.to(elem, 0.1, { css: { x: -window.innerWidth, z: 0.01, rotation: 0 }, ease: Power2.linear, onComplete: scope.onReject } )

      else
        elem.addClass("static")
        javascriptUtils.vendorPrefixAttr(elem[0], "transform", "")

    swipeMove = (e) ->
      return unless swiping

      e.preventDefault()

      pageX = e.touches?[0].pageX || e.pageX
      pageY = e.touches?[0].pageY || e.pageY

      if oldX != 0
        dX = pageX - oldX
        dY = pageY - oldY

      elemPosX += dX
      elemPosY += dY
      setElemTransform(elemPosX + "px", elemPosY + "px", (0 - elemPosX / 10) + "deg")

      oldX = pageX
      oldY = pageY

      if elemPosX > SWIPE_THRESHOLD && answeringEnabled
        if !elem.hasClass("yes")
          elem.addClass("yes")
          elem.removeClass("no")
          scope.onElementYes()

      else if elemPosX < -SWIPE_THRESHOLD && answeringEnabled
        if !elem.hasClass("no")
          elem.addClass("no")
          elem.removeClass("yes")
          scope.onElementNo()

      else
        elem.removeClass("yes")
        elem.removeClass("no")

    unbind = ->
      # Unbind touch listeners
      if (window.navigator.pointerEnabled)
        # IE touch listeners
        elem[0].removeEventListener "pointerdown", swipeStart, false
        elem[0].removeEventListener "pointermove", swipeMove, false
        elem[0].removeEventListener "pointerup", swipeEnd, false
        elem[0].removeEventListener "pointerleave", swipeEnd, false

      # Normal touch listeners
      elem[0].removeEventListener "touchstart", swipeStart, false
      elem[0].removeEventListener "touchmove", swipeMove, false
      elem[0].removeEventListener "touchend", swipeEnd, false
      elem[0].removeEventListener "touchcancel", swipeEnd, false

      elem[0].removeEventListener "mousedown", swipeStart, false
      elem[0].removeEventListener "mousemove", swipeMove, false
      elem[0].removeEventListener "mouseup", swipeEnd, false

      # Unsubscribe msgChannel
      jsonMsgChannel.unsubscribe(msgChannel)

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

      # Normal touch listeners
      elem[0].addEventListener "touchstart", swipeStart, false
      elem[0].addEventListener "touchmove", swipeMove, false
      elem[0].addEventListener "touchend", swipeEnd, false
      elem[0].addEventListener "touchcancel", swipeEnd, false

      elem[0].addEventListener "mousedown", swipeStart, false
      elem[0].addEventListener "mousemove", swipeMove, false
      elem[0].addEventListener "mouseup", swipeEnd, false

      # Subscribe to msgChannel
      msgChannel = jsonMsgChannel.subscribe (data) =>
        if data?.event == "swipeYes" && data.optionId == elem.attr("id")
          elem.addClass("yes")
          elem.removeClass("no")
          $timeout(->
            setElemTransform("100%", elemPosY + "px", 25 + "deg")
          ,5)

        if data?.event == "swipeNo" && data.optionId == elem.attr("id")
          elem.addClass("no")
          elem.removeClass("yes")
          $timeout(->
            setElemTransform("-100%", elemPosY + "px", -25 + "deg")
          ,5)

        if data?.event == "cancelSwipe"
          elem.removeClass("yes")
          elem.removeClass("no")
          javascriptUtils.vendorPrefixAttr(elem[0], "transform", "")

    # Watch for scope.enabled and bind eventlistener when element becomes enabled
    if !scope.enabled
      scope.$watch("enabled", (val) ->
        if val
          bind()
      )
    else
      bind()
