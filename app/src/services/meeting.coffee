meetingModule = angular.module 'meetingModule', ['ngRoute', 'appConfig']

meetingModule.service 'meetingService', ($log, $routeParams, SessionRestangular, appConfig, viewParams, cacheService) ->

  @meeting = null

  setCache: (meetings) ->
    cacheService.put("meetings", meetings)

  getCache: ->
    return cacheService.get("meetings")

  setMeeting: (meeting) ->
    @meeting = meeting

  getMeeting: ->
    if @meeting?
      return SessionRestangular.copy(@meeting)

    return @getEmptyMeeting()

  getEmptyMeeting: ->
    return {
      id: @getIdFromPath()
      meetingDataNotAvailable: true
      participants: []
    }

  getIdFromPath: ->
    id = $routeParams.meetingId
    if id == "undefined"
      return undefined
    return id

  generateTitle: (participants, base) ->
    if !base?
      base = "Meeting with"

    if participants.length == 2
      title = "#{base} #{participants[0].last_name} & #{participants[1].last_name}"
    else
      title = "#{base} #{participants[0].last_name} & #{participants.length - 1} others"

    return title

  meetingRoute: (meetingId) ->
    return SessionRestangular.one("meetings", meetingId)

  fetchMeeting: (meetingId, params) ->
    return @meetingRoute(meetingId).get(params)

  timelineFields: {
    "limit_fields": [
      "id"
      "title_value"
      "location_value"
      "begin_epoch"
      "end_epoch"
      "date_string"
      "is_draft"
      "matchmaking_accepted"
      "is_suggested_meeting"
      "matchmaking_requester_name"
      "source_name"
      "current_scheduling_id"
      "online_conferencing_option"
      "online_conferencing_data.*"
      "participants.*.user_id"
      "participants.*.image"
      "participants.*.initials"
      "participants.*.user_id_md5"
    ]
  }

  fetchUnscheduled: (user) ->
    return user.getList('unscheduled_meetings', _.extend({
      include_draft: 1
      image_size: appConfig.thumbnail.small
    }, @timelineFields))

  fetchScheduled: (user, params) ->
    return user.getList('meetings', _.extend(params, @timelineFields))

  fetchSuggested: (user, params) ->
    return user.getList('suggested_meetings', _.extend(params, @timelineFields))

  createSuggested: (meetingId) ->
    return SessionRestangular.all("meetings").customPOST({ from_suggestion_id: meetingId } )

  hideSuggested: (meetingId) ->
    return SessionRestangular.one("suggested_meetings", meetingId).customPUT( { disabled: 1 } )

  # Accepts meeting or matchmaker
  getTypeIconClass: (meeting) ->
      [
        "icon-meetings"
        "icon-coffee"
        "icon-dinner"
        "icon-drinks"
        "icon-workshop"
        "icon-sports"
        "icon-team"
        "icon-idea"
        "icon-material_presentation"
        "icon-calendars"
        "icon-handshake"
        "icon-call"
        "icon-tablet"
        "icon-teleconf"
        "icon-onlineconf"
        "icon-touch"
      ][parseInt(meeting.meeting_type)];

  # Accepts meeting or matchmaker
  getBackgroundImageUrl: (meeting) ->
    if !meeting?.background_theme? || meeting.background_theme == ""
      return ""
    else if meeting.background_theme != "c"
      return "images/matchmakers/theme"+(parseInt(meeting.background_theme)+1)+".jpg"
    else
      return meeting.background_image_url || ""

  isRemoved: (meeting) ->
    return meeting.removed_epoch? && parseInt(meeting.removed_epoch) != 0

  isSchedulingStarted: (meeting, scheduling) ->
    scheduling ?= meeting.current_scheduling

    return meeting.current_scheduling_id != 0 &&
           scheduling?.started_epoch? &&
           scheduling.started_epoch != 0

  isSchedulingCanceled: (meeting, scheduling) ->
    scheduling ?= meeting.current_scheduling

    return meeting.current_scheduling_id != 0 &&
           scheduling?.canceled_epoch? &&
           scheduling.canceled_epoch != 0

  isSchedulingFailed: (meeting, scheduling) ->
    scheduling ?= meeting.current_scheduling

    return meeting.current_scheduling_id != 0 &&
           scheduling?.failed_epoch? &&
           scheduling.failed_epoch != 0

  isSchedulingCompleted: (meeting, scheduling) ->
    scheduling ?= meeting.current_scheduling

    return scheduling?.completed_epoch? &&
           scheduling.completed_epoch != 0
