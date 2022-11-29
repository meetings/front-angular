participantModule = angular.module 'participantModule', ['SessionModel']

participantModule.service 'participantService', ($log, SessionRestangular) ->

  getParticipant: (userId, participants) ->
    return _.find participants, (participant) ->
      return participant.user_id == userId

  getAttending: (participants, rsvpPropertyName) ->
    return _.filter(participants, (p) -> p[rsvpPropertyName] == 'yes' || p[rsvpPropertyName] == 1)

  getPending: (participants, rsvpPropertyName) ->
    return _.filter(participants, (p) -> !p[rsvpPropertyName] || p[rsvpPropertyName] == '' || p[rsvpPropertyName] == 0)

  getDeclined: (participants, rsvpPropertyName) ->
    return _.filter(participants, (p) -> p[rsvpPropertyName] == 'no')

  getCurrentSchedulingAnswered: (participants) ->
    return _.where(participants, {has_answered_current_scheduling: 1})

  getAttendingCount: (participants, rsvpPropertyName) ->
    return @getAttending(participants, rsvpPropertyName).length

  getPendingCount: (participants, rsvpPropertyName) ->
    return @getPending(participants, rsvpPropertyName).length

  getDeclinedCount: (participants, rsvpPropertyName) ->
    return @getDeclined(participants, rsvpPropertyName).length

  getCurrentSchedulingAnsweredCount: (participants) ->
    return @getCurrentSchedulingAnswered(participants).length

  # Returns only the first manager partcipant
  getManager: (participants) ->
    return _.where(participants, { is_manager: '1' })[0]

  isManager: (participant) ->
    return parseInt(participant?.is_manager, 10) == 1

  hasLeftScheduling: (participant) ->
    return parseInt(participant?.scheduling_disabled, 10) == 1

  isRsvpRequired: (participant) ->
    return parseInt(participant?.rsvp_required, 10) == 1 && (!participant.rsvp_status || participant.rsvp_status == '')

  updateRsvpStatus: (participantId, rsvpStatus) ->
    meetingParticipants = SessionRestangular.one("meeting_participants", participantId)
    meetingParticipants.rsvp = rsvpStatus
    return meetingParticipants.put()

  restangularizeElement: (participant) ->
    return SessionRestangular.restangularizeElement(null, participant, "meeting_participants", {})

  fetchParticipant: (participantId, params) ->
    return SessionRestangular.one("meeting_participants", participantId).get(params)

  fetchParticipantList: (meetingId, params) ->
    return SessionRestangular.one("meetings", meetingId).getList("participants", params)

  addParticipant: (meetingId, opts) ->
    return SessionRestangular.one("meetings", meetingId).customPOST(opts, "participants")

  sendInvitationsToDraftParticipants: (meetingId, opts) ->
    return SessionRestangular.one("meetings", meetingId).customPOST(opts, "send_draft_participant_invites")

  removeParticipant: (participantId) ->
    return SessionRestangular.one("meeting_participants", participantId).remove()

  fetchUser: (params) ->
    return SessionRestangular.one("users").get(params)

  resendSchedulingInvitation: (participant) ->
    return participant.post("resend_invitation", {})

  disableScheduling: (participant) ->
    return SessionRestangular.one("meeting_participants", participant.id).customPOST(participant, "disable_scheduling")

  enableScheduling: (participant) ->
    return SessionRestangular.one("meeting_participants", participant.id).customPOST(participant, "enable_scheduling")

