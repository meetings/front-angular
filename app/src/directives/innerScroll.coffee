mtnInnerScroll = angular.module "mtnInnerScroll", []

# Ensures that the top and bottom of the element are never at 0 or 100% when user starts to scroll.
# This way scrolling will happen on the element that user has touched and not in any of it's parents.
#
mtnInnerScroll.directive "mtnInnerScroll", ->
  restrict: 'A'
  link: (scope, elem, attrs) ->

    element = elem[0]

    # Handle the start of interactions
    element.addEventListener('touchstart', (event) ->

      # Variables to track inputs
      startTopScroll = element.scrollTop

      # If no movement is possible, ignore it.
      if (element.scrollHeight != element.clientHeight)

        if(startTopScroll <= 0)
            element.scrollTop = 1

        if (startTopScroll + element.offsetHeight >= element.scrollHeight)
          element.scrollTop = element.scrollHeight - element.offsetHeight - 1

    , false)
