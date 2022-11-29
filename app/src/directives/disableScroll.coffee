disableScroll = angular.module "mtnDisableScroll", []

disableScroll.directive "mtnDisableScroll", ->
  link: (scope, elem, attrs) ->

    touchMove = (e) ->
      e.preventDefault()

    unbind = ->
      # Unbind touch listeners
      if (window.navigator.pointerEnabled)
        # IE touch listeners
        elem[0].removeEventListener "pointermove", touchMove, false

      # Normal touch listeners
      elem[0].removeEventListener "touchmove", touchMove, false
      elem[0].removeEventListener "mousemove", touchMove, false

    bind = ->
      # Unbind on $destroy
      scope.$on("$destroy", ->
        unbind()
      )

      # Bind touch listener
      if (window.navigator.pointerEnabled)
        # IE touch listeners
        elem[0].addEventListener "pointermove", touchMove, false

      # Normal touch listeners
      elem[0].addEventListener "touchmove", touchMove, false
      elem[0].addEventListener "mousemove", touchMove, false

    bind()
