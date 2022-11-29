carousel = angular.module "mtnCarousel", [ 'appConfig' ]

carousel.directive "mtnCarousel", (javascriptUtils) ->
  restrict: 'A'
  scope:
    afterLastSlide: "&mtnAfterLastSlide"
  link: (scope, elem, attrs) ->

    windowWidth = window.innerWidth
    carouselWidth = elem[0].getBoundingClientRect().width
    childCount = elem[0].childElementCount

    dX = 0
    oldX = 0
    elemPos = 0
    slide = 0
    active = false

    swipeStart = (e) ->
      active = true
      elem.removeClass("static")

      oldX = e.touches?[0].pageX || e.pageX

    swipeEnd = ->
      active = false
      elem.addClass("static")

      slide = Math.round(elemPos / (carouselWidth / childCount))
      if slide > 0
        slide = 0

      scrollPos = windowWidth * slide

      javascriptUtils.vendorPrefixAttr(elem[0], "transform", "translate3d( " + scrollPos + "px, 0, 0 )")
      elemPos = scrollPos

      if Math.abs(slide) == childCount
        scope.$apply -> scope.afterLastSlide()

    swipeMove = (e) ->
      e.preventDefault()
      return unless active

      pageX = e.touches?[0].pageX || e.pageX
      dX = pageX - oldX

      if elemPos > 0
        dist = elemPos
        mult = 1 / Math.pow(dist, 0.45)
        dX = (pageX - oldX) * mult

      elemPos += dX

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

      # Normal touch listeners
      elem[0].removeEventListener "touchstart", swipeStart, false
      elem[0].removeEventListener "touchmove", swipeMove, false
      elem[0].removeEventListener "touchend", swipeEnd, false
      elem[0].removeEventListener "touchcancel", swipeEnd, false

      elem[0].removeEventListener "mousedown", swipeStart, false
      elem[0].removeEventListener "mousemove", swipeMove, false
      elem[0].removeEventListener "mouseup", swipeEnd, false

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


    bind()
