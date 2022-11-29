redirectModule = angular.module 'redirectModule', ['ngRoute', 'appConfig', 'viewParams']

redirectModule.service 'redirectService', ($location, sessionService, SessionRestangular, viewParams) ->

  cleanQueryParams: ->
    $location.search("user_id", null)
    $location.search("dic", null)
    $location.search("redirect_to_meeting", null)
    $location.search("redirect_to_scheduling", null)
    $location.search("redirect_to_scheduling_log", null)
    $location.search("redirect_to_material", null)

  redirectToAppstorePage: ->
    @cleanQueryParams()
    $location.path("/appStoreRedirect")

  redirectToScheduling: (meetingId, schedulingId, source) ->
    @cleanQueryParams()
    $location.search("utm_source", source).path("/timeline/meeting/#{meetingId}/scheduling/#{schedulingId}")

  redirectToSchedulingLog: (meetingId, schedulingId) ->
    @cleanQueryParams()
    viewParams.set({
      showMeetingDetailsButton: true
    })
    $location.path("/timeline/meeting/#{meetingId}/scheduling/#{schedulingId}/log")

  redirectToMaterial: (meetingId, materialId) ->
    @cleanQueryParams()
    $location.path("/timeline/meeting/#{meetingId}/material/#{materialId}")

  redirectToMeeting: (meetingId) ->
    @cleanQueryParams()
    $location.path("/timeline/meeting/#{meetingId}")

  handleQueryParams: (queryParams) ->
    queryParams ?= $location.search()

    if !sessionService.signInWithUserIdAndToken(queryParams.user_id, queryParams.dic)
      return false

    SessionRestangular.refreshDefaultHeaders()

    if queryParams.redirect_to_app_store?
      @redirectToAppstorePage()

    if queryParams.redirect_to_meeting? && queryParams.redirect_to_scheduling?
      @redirectToScheduling(
        queryParams.redirect_to_meeting
        queryParams.redirect_to_scheduling
        queryParams.utm_source
      )

    else if queryParams.redirect_to_meeting? && queryParams.redirect_to_scheduling_log?
      @redirectToSchedulingLog(
        queryParams.redirect_to_meeting
        queryParams.redirect_to_scheduling_log
      )

    else if queryParams.redirect_to_meeting? && queryParams.redirect_to_material?
      @redirectToMaterial(
        queryParams.redirect_to_meeting
        queryParams.redirect_to_material
      )

    else if queryParams.redirect_to_meeting?
      @redirectToMeeting(
        queryParams.redirect_to_meeting
      )
