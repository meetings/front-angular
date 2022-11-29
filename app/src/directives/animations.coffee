animations = angular.module 'animations', []



animations.directive "scrollIntoView", () ->
  restrict: 'AE'
  scope:
    ngShow: '='
  link: (scope, elem, attrs) ->
    element = elem[0]
    scope.$watch(
      'ngShow',
      (visible) ->
        if visible
          scrollIntoView(element)
    )

    scrollIntoView = (element) ->

      windowHeight = window.innerHeight
      elementHeight = element.clientHeight
      elementTop = element.getBoundingClientRect().top

      elementVisible = windowHeight - elementTop
      elementHidden = elementHeight - elementVisible

      scrollAmount = elementHidden

      if windowHeight - elementHeight < elementTop
        top = document.body.scrollTop + scrollAmount
        TweenLite.to(document.body, .5, {scrollTop:top, ease: Power2.easeInOut});