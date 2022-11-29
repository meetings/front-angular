partials = angular.module 'partials', ['participantModule', 'appConfig', 'mtnUtils']

# Renders single participant's basic info
#
# Attributes:
#  show-rsvp : Show rsvp status color
#
# Usage:
#
#    <participant ng-model="participant"></participant>
#
#
partials.directive 'participant', ($log) ->
  restrict: 'E'
  require: 'ngModel'
  scope:
    showRsvp   : '@?'
  templateUrl: '/views/participant/_participant.html'
  link: (scope, elem, attrs, ngModel) ->
    scope.showRsvp ?= true

    ngModel.$formatters.push (data) ->
      scope.participant = data


# Renders a list of participants
#
# Attributes:
#  rsvp-property-name   : The name of the property that contains the answer data.
#                         Defaults to rsvp_status
#  show-rsvp            : Show rsvp status color
#
# Usage:
#
#    <participantlist participants="meeting.participants" rpvp-property-name="answer"></participantlist>
#
#
partials.directive 'participantlist', () ->
  restrict: 'E'
  scope:
    participants: '='
    rsvpPropertyName: '@'
  templateUrl: '/views/meeting/_participantlist.html'
  link: (scope, elem, attrs) ->
    scope.showRsvp = attrs.showRsvp || true
    scope.isDisabled = (participant) ->
      return participant[attrs.disabledPropertyName]


# Renders a summary of participants rsvp statuses
#
# Usage:
#
#    <participantsummary participants="meeting.participants"></participantsummary>
#
#
partials.directive 'participantsummary', (participantService) ->
  restrict: 'E'
  scope:
    participants: '='
    rsvpPropertyName: '@'
    hideZeroDeclined: '@'
  templateUrl: '/views/meeting/_participantsummary.html'
  link: (scope, elem, attrs) ->
    try
      scope.shortSummary = JSON.parse(attrs.shortSummary)
    catch
      scope.shortSummary = false

    update = ->
      scope.attending = participantService.getAttendingCount(
        scope.participants
        scope.rsvpPropertyName
        )
      scope.pending = participantService.getPendingCount(
        scope.participants
        scope.rsvpPropertyName
        )
      scope.declined = participantService.getDeclinedCount(
        scope.participants
        scope.rsvpPropertyName
        )

    scope.$watch(
      "participants"
      (value) ->
        update()
    )

    update()


# Participant invitation form
#
# Usage:
#
#    <participantinvitation parent="parentCtrl"></participantinvitation>
#
#
partials.directive 'participantinvitation', () ->
  restrict: 'E'
  scope:
    parent: '='
  templateUrl: '/views/participant/_participantinvitation.html'


# Swipe card option
#
# Usage:
#
#    <mtn-swipe-card-option ng-model="card.yes_option"></mtn-swipe-card-option>
#
#
partials.directive 'mtnSwipeCardOption', () ->
  restrict: 'E'
  scope:
    option: '=ngModel'
    parent: '='
  templateUrl: '/views/swipetomeet/_swipecardoption.html'


# App selling feature
#
# Usage:
#   <mtn-application-promo>
#     <div class="show-on-ios">
#      <p class="text-wrapper">Get smarter suggestions by connecting your calendar.</p>
#     </div>
#     <div class="show-on-android">
#       <p class="text-wrapper">Get smarter suggestions by connecting your calendar.</p>
#     </div>
#     <div class="show-on-unknown">
#       <p class="text-wrapper">Sorry, we support only iOS and Android devices at the moment.</p>
#     </div>
#   </mtn-application-promo>
#
# Please note that the contents are hidden with css.
partials.directive "mtnApplicationPromo", (appConfig, deviceUtils) ->
  restrict: "E"
  transclude: true
  templateUrl: "/views/partials/_applicationPromo.html"
  scope:
    phoneform: '@?'
  controller: ($scope) ->

    $scope.isIos = deviceUtils.isIos()
    $scope.isAndroid = deviceUtils.isAndroid()

    $scope.iosStoreUrl = appConfig.appStoreUrls.ios
    $scope.androidStoreUrl = appConfig.appStoreUrls.android

    # If both or neither match
    if ($scope.isIos && $scope.isAndroid) || (!$scope.isIos && !$scope.isAndroid)
      $scope.isUnknown = true
      $scope.isIos = false
      $scope.isAndroid = false

