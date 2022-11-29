nativeUi = angular.module 'nativeUi', []

# Toggle element visibility when defined event is received.
# For example: Native UI button toggles an input element's visibility.
#
# Usage: <input toggled-by-event="EVENT_DISPATCHED_BY_NATIVE_UI">
#
nativeUi.directive 'toggledByEvent', ($document) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    $document.on attrs.eventName, ->
      scope.$apply ->
        elem.toggleClass(attrs.eventClass)



# Display a native confirmation dialog. Binds to element's click action.
#
# Attributes:
#   mtn-confirm-click    = array of buttons. First button is will confirm the action, second button acts as cancel.
#   mtn-confirm-callback = function which will be called if confirmation was positive
#   mtn-confirm-message  = confirm message
#   mtn-confirm-title    = confirm dialog title
#
# Usage:
#
#  <button mtn-confirm-click="['Hide', 'Cancel']"
#          mtn-confirm-callback="parent.hideSuggested(meeting)"
#          mtn-confirm-message="This meeting will be permanently hidden from your timeline."
#          mtn-confirm-title="Hide this event?"
#          class="button-secondary">
#    Hide this event
#  </button>
#
nativeUi.directive 'mtnConfirmClick', ->
  priority: -1
  restrict: 'A'
  scope: {
    mtnConfirmCallback: '&'
    buttons: '=mtnConfirmClick'
  }

  link: (scope, element, attrs) ->

    element.bind 'click', (event) ->

      message = attrs.mtnConfirmMessage
      title = attrs.mtnConfirmTitle
      buttonOK = 1

      onConfirm = (button) ->
        if button == buttonOK
          scope.mtnConfirmCallback()

      navigator.notification.confirm(
        message,
        onConfirm,
        title,
        scope.buttons
      )

# Blur input when defined event is received.
#
# Usage: <input mtn-blur-on-event="EVENT_DISPATCHED_BY_NATIVE_UI">
#
# Attributes:
#   mtn-blur-on-event-query-selector = Element to be blurred (optional)
#
nativeUi.directive 'mtnBlurOnEvent', ($rootScope, $timeout) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    $rootScope.$on attrs.mtnBlurOnEvent, ->
      if attrs.mtnBlurOnEventQuerySelector? && document.querySelector(attrs.mtnBlurOnEventQuerySelector)?
        document.querySelector(attrs.mtnBlurOnEventQuerySelector).blur()
      else
        elem[0].blur()

# Focus input when defined event is received.
#
# Usage: <input mtn-focus-on-event="EVENT_DISPATCHED_BY_NATIVE_UI">
#
# Attributes:
#   mtn-focus-on-event-query-selector = Element to be foucsed (optional)
#
nativeUi.directive 'mtnFocusOnEvent', ($rootScope, $timeout) ->
  restrict: 'A'
  link: (scope, elem, attrs) ->
    $rootScope.$on attrs.mtnFocusOnEvent, ->
      if attrs.mtnFocusOnEventQuerySelector?
        document.querySelector(attrs.mtnFocusOnEventQuerySelector).focus()
      else
        elem[0].focus()
