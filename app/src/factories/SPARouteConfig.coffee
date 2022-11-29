SPARouteConfig = angular.module 'SPARouteConfig', ['ngRoute', 'appConfig']

SPARouteConfig.run ($rootScope, $window, $route, $location) ->

  $rootScope.stackPosition = 0

  isViewAnimationDisabled = (oldLocation, newLocation) ->
    tabs = [
      "scheduling"
      "timeline"
      "notifications"
      "settings"
      "styleguide"
    ]
    # Gets the root (tab) part of the location
    locationRegExp = new RegExp("^/("+tabs.join("|")+")/?.*$")

    oldL = oldLocation.replace(locationRegExp, "$1")
    newL = newLocation.replace(locationRegExp, "$1")

    return (oldL != newL)


  onPathChange = (newLocation, oldLocation) ->
    $rootScope.disableViewAnimation = isViewAnimationDisabled(oldLocation, newLocation)

    elem = angular.element(document.getElementsByClassName('spa-page'))

    if $rootScope.actualLocation == newLocation
      historyState = $window.history.state

      back = !!(historyState && historyState.position <= $rootScope.stackPosition)

      if back
        # back button
        $rootScope.stackPosition--

        elem.addClass('spa-page-back')
        elem.removeClass('spa-page-forward')
      else
        # forward button
        $rootScope.stackPosition++

        elem.removeClass('spa-page-back')
        elem.addClass('spa-page-forward')

    else
      # normal-way change of page (via link click)
      if $route.current
        $window.history.replaceState({
            position: $rootScope.stackPosition
        }, "", "")

        $rootScope.stackPosition++

        elem.removeClass('spa-page-back')
        elem.addClass('spa-page-forward')

  $rootScope.$on('$locationChangeStart', () ->
    $rootScope.actualLocation = $location.path()
  )

  $rootScope.$watch(
    ->
      return $location.path()
    onPathChange
  )

SPARouteConfig.config [
  '$routeProvider', 'appConfigProvider', ($routeProvider, appConfigProvider) ->
    $routeProvider

      # Timeline
      .when('/timeline', {
        templateUrl: '/views/meeting/_timeline.html'
        controller: 'MeetingIndexCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId', {
        templateUrl: '/views/meeting/_meeting.html'
        controller: 'MeetingShowCtrl as show'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/edit/:editing', {
        templateUrl: '/views/meeting/_edit.html'
        controller: 'MeetingEditCtrl as show'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/controls', {
        templateUrl: '/views/meeting/_controls.html'
        controller: 'MeetingControlsCtrl as controls'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/log', {
        templateUrl: '/views/scheduling/_log.html'
        controller: 'SchedulingLogCtrl as log'
        reloadOnSearch: false
      })

      # Participant
      .when('/:tab/meeting/:meetingId/participants', {
        templateUrl: '/views/participant/_participantlist.html'
        controller: 'ParticipantIndexCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/participants/add', {
        templateUrl: '/views/participant/_new.html'
        controller: 'ParticipantNewCtrl as new'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/participants/invitation', {
        templateUrl: '/views/participant/_invitation.html'
        controller: 'ParticipantDraftInvitationCtrl as invitation'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/participants/:participantId', {
        templateUrl: '/views/participant/_participantshow.html'
        controller: 'ParticipantShowCtrl as show'
        reloadOnSearch: false
      })

      # Material
      .when('/:tab/meeting/:meetingId/material/:materialId', {
        templateUrl: '/views/material/_show.html'
        controller: 'MaterialShowCtrl as show'
        reloadOnSearch: false
      })

      # Notifications
      .when('/notifications', {
        templateUrl: '/views/notification/_notifications.html'
        controller: 'NotificationIndexCtrl as index'
        reloadOnSearch: false
      })
      .when('/notifications/:notificationId', {
        templateUrl: '/views/notification/_customNotification.html'
        controller: 'NotificationCustomCtrl as show'
        reloadOnSearch: false
      })

      # Menu
      .when('/settings', {
        templateUrl: '/views/menu/_menu.html'
        controller: 'MenuIndexCtrl as index'
        reloadOnSearch: false
      })
      .when('/settings/profile', {
        templateUrl: '/views/profile/_profile.html'
        controller: 'ProfileEditCtrl as edit'
        reloadOnSearch: false
      })
      .when('/settings/notifications', {
        templateUrl: '/views/menu/_notificationSettings.html'
        controller: 'MenuNotificationSettingsCtrl as index'
        reloadOnSearch: false
      })
      .when('/settings/notifications/email', {
        templateUrl: '/views/menu/_notifications.html'
        controller: 'MenuEmailNotificationCtrl as index'
        reloadOnSearch: false
      })
      .when('/settings/notifications/push', {
        templateUrl: '/views/menu/_notifications.html'
        controller: 'MenuPushNotificationCtrl as index'
        reloadOnSearch: false
      })
      .when('/settings/calendars', {
        templateUrl: '/views/menu/_calendarIntegration.html'
        controller: 'MenuCalendarIntegrationCtrl as index'
        reloadOnSearch: false
      })
      .when('/settings/timeline', {
        templateUrl: '/views/menu/_defaultCalendars.html'
        controller: 'MenuDefaultCalendarsCtrl as index'
        reloadOnSearch: false
      })
      .when('/settings/regional', {
        templateUrl: '/views/menu/_regionalSettings.html'
        controller: 'MenuRegionalSettingsCtrl as index'
        reloadOnSearch: false
      })

      # Trial
      .when('/:tab/starttrial', {
        templateUrl: '/views/trial/_startTrial.html'
        controller: 'TrialIndexCtrl as index'
        reloadOnSearch: false
      })

      # Scheduling Tab
      .when('/scheduling', {
        templateUrl: '/views/scheduling/_newScheduling.html'
        controller: 'SchedulingIndexCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/time', {
        templateUrl: '/views/scheduling/_time.html'
        controller: 'SchedulingTimeCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/customtime', {
        templateUrl: '/views/scheduling/_edit-time.html'
        controller: 'SchedulingEditTimeCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/duration', {
        templateUrl: '/views/scheduling/_duration.html'
        controller: 'SchedulingDurationCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/customduration', {
        templateUrl: '/views/scheduling/_edit-duration.html'
        controller: 'SchedulingEditDurationCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/location', {
        templateUrl: '/views/scheduling/_location.html'
        controller: 'SchedulingLocationCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/customlocation', {
        templateUrl: '/views/scheduling/_edit-location.html'
        controller: 'SchedulingEditLocationCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/participants', {
        templateUrl: '/views/scheduling/_select-participants.html'
        controller: 'SchedulingParticipantsCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/review', {
        templateUrl: '/views/scheduling/_review.html'
        controller: 'SchedulingReviewCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/timespan', {
        templateUrl: '/views/scheduling/_edit-date.html'
        controller: 'SchedulingEditTimespanCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/calendars', {
        templateUrl: '/views/scheduling/_edit-sources.html'
        controller: 'SchedulingEditSourcesCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/material', {
        templateUrl: '/views/material/_show.html'
        controller: 'MaterialShowCtrl as show'
        reloadOnSearch: false
      })
      .when('/:tab/done', {
        templateUrl: '/views/scheduling/_done.html'
        controller: 'SchedulingStartCtrl as index'
        reloadOnSearch: false
      })

      # Timeline scheduling
      .when('/:tab/meeting/:meetingId/scheduling', {
        templateUrl: '/views/scheduling/_newScheduling.html'
        controller: 'SchedulingIndexCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/review', {
        templateUrl: '/views/scheduling/_review.html'
        controller: 'SchedulingReviewCtrl as index'
        reloadOnSearch: false
      })

      # SwipeToMeet
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId', {
        templateUrl: '/views/swipetomeet/_swipeLanding.html'
        controller: 'SwipeToMeetLandingCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/suggestions', {
        templateUrl: '/views/swipetomeet/_swipeSuggestions.html'
        controller: 'SwipeToMeetShowCtrl as show'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/suggestions/connectCalendar', {
        templateUrl: '/views/swipetomeet/_calendarIntegration.html'
        controller: 'MenuCalendarIntegrationCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/suggestions/selectsources', {
        templateUrl: '/views/menu/_defaultCalendars.html'
        controller: 'MenuDefaultCalendarsCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/suggestions/info/:optionId', {
        templateUrl: '/views/swipetomeet/_swipeInfo.html'
        controller: 'SwipeToMeetInfoCtrl as info'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/thanks/:thanksMsg', {
        templateUrl: '/views/swipetomeet/_swipeThanks.html'
        controller: 'SwipeToMeetThanksCtrl as show'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/countryCode', {
        templateUrl: '/views/swipetomeet/_countryCode.html'
        controller: 'SwipeToMeetCountryCodeCtrl as show'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/confirmPhone', {
        templateUrl: '/views/swipetomeet/_confirmPhone.html'
        controller: 'SwipeToMeetConfirmPhoneCtrl as show'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/appDownloadGuide', {
        templateUrl: '/views/swipetomeet/_appDownloadGuide.html'
        controller: 'SwipeToMeetAppDownloadGuideCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/leave/confirm', {
        templateUrl: '/views/swipetomeet/_confirmLeaveScheduling.html'
        controller: 'SwipeToMeetConfirmLeaveCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/leave/invitesubstitute', {
        templateUrl: '/views/swipetomeet/_inviteSubstitute.html'
        controller: 'SwipeToMeetInviteSubsituteCtrl as index'
        reloadOnSearch: false
      })
      .when('/:tab/meeting/:meetingId/scheduling/:schedulingId/leave', {
        templateUrl: '/views/swipetomeet/_leaveScheduling.html'
        controller: 'SwipeToMeetLeaveCtrl as index'
        reloadOnSearch: false
      })

      # Styleguide
      .when('/styleguide', {
        templateUrl: '/views/styleguide/_index.html'
        controller: 'StyleguideIndexCtrl as index'
        reloadOnSearch: false
      })

      # Sign in
      .when('/signin', {
        templateUrl: '/views/initial/_signinPhone.html'
        controller: 'SignInIndexCtrl as signIn'
      })
      .when('/signin/country', {
        templateUrl: '/views/initial/_signinCountry.html'
        controller: 'SignInCountryCodeCtrl as signIn'
      })
      .when('/signin/pin', {
        templateUrl: '/views/initial/_signinPin.html'
        controller: 'SignInPinCtrl as signIn'
      })
      .when('/signup', {
        templateUrl: '/views/initial/_signup.html'
        controller: 'SignUpCtrl as signUp'
      })
      .when('/signup/pin', {
        templateUrl: '/views/initial/_signupPin.html'
        controller: 'SignUpPinCtrl as signUp'
      })
      .when('/signup/profileimage', {
        templateUrl: '/views/initial/_profileImage.html'
        controller: 'ProfileImageUploadCtrl as profile'
      })
      .when('/signup/calendarConnect', {
        templateUrl: '/views/initial/_calendarConnect.html'
        controller: 'CalendarConnectCtrl as calendarConnect'
      })
      .when('/signup/initPushNotifications', {
        templateUrl: '/views/initial/_initPushNotifications.html'
        controller: 'InitPushNotificationsCtrl as initPushNotifications'
      })


      .when('/appStoreRedirect', {
        templateUrl: '/views/appstoreredirect/_index.html'
        controller: 'AppStoreRedirectCtrl as index'
      })

    .otherwise({
      redirectTo: if cordova? && appConfigProvider.appConfig.appBrand != appConfigProvider.appConfig.appBrands.MEETINGS then '/scheduling' else '/timeline'
    })
]
