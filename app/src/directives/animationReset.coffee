animationReset = angular.module "mtnAnimationReset", []

animationReset.directive "mtnAnimationReset", ($timeout) ->
  link:(scope, elem, attrs) ->
    # Force reload by adding timestamp to url
    elem[0].style["background"] = "white url('#{attrs.backgroundImage}?#{new Date().getTime()}') center center no-repeat"
    elem[0].style["backgroundSize"] = attrs.backgroundSize

