mtnFullHeight = angular.module "mtnFullHeight", [ 'mtnUtils' ]

# Set window height as element's heigth.
#
mtnFullHeight.directive "mtnFullHeight", (deviceready) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->

    resize = ->
      height = document.documentElement.getBoundingClientRect().height
      elem[0].style.height = height + "px"

    window.addEventListener "resize", resize

    deviceready.then =>
      resize()

    resize()
