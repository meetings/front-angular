describe "Participant Helper Service", ->

  beforeEach(angular.mock.module('participantModule'))

  beforeEach inject (participantService) ->
    @participantHelper = participantService


  describe "participant rsvp status", ->
    meeting =
      participants: [
        { "rsvp_status": "" }
        { "rsvp_status": "no" }
        { "rsvp_status": "yes" }
        {
          # rsvp_status is undefined
        }
      ]

    it 'counts attending participants', ->
      expect(@participantHelper.getAttendingCount(meeting.participants,"rsvp_status")).toEqual(1)

    it 'count pending participants', ->
      expect(@participantHelper.getPendingCount(meeting.participants,"rsvp_status")).toEqual(2)

    it 'count declined participants', ->
      expect(@participantHelper.getDeclinedCount(meeting.participants,"rsvp_status")).toEqual(1)


  describe "access control", ->

    participants = [
      { user_id: 1, is_manager: 1}
      { user_id: 2, is_manager: "1"}

      { user_id: 10, is_manager: 0}
      { user_id: 11, is_manager: "0"}
      { user_id: 12, is_manager: ""}
      { user_id: 13}
    ]

    it "knows who is the meeting manager", ->
      participant = @participantHelper.getParticipant 1, participants
      expect( @participantHelper.isManager(participant) ).toBeTruthy("integer")

      participant = @participantHelper.getParticipant 2, participants
      expect( @participantHelper.isManager(participant) ).toBeTruthy("string")

    it "knows who is not the meeting manager", ->
      participant = @participantHelper.getParticipant 10, participants
      expect( @participantHelper.isManager(participant) ).toBeFalsy("integer")

      participant = @participantHelper.getParticipant 11, participants
      expect( @participantHelper.isManager(participant) ).toBeFalsy("string")

      participant = @participantHelper.getParticipant 12, participants
      expect( @participantHelper.isManager(participant) ).toBeFalsy("empty string")

      participant = @participantHelper.getParticipant 13, participants
      expect( @participantHelper.isManager(participant) ).toBeFalsy("undefined")

    it "returns false for participants who are not listed", ->
      participant = @participantHelper.getParticipant 9999, participants
      expect( @participantHelper.isManager(participant) ).toBeFalsy("undefined user")

  describe "rsvp required", ->
    participants = [
      { user_id: 10, rsvp_required: 1}
      { user_id: 11, rsvp_required: "1"}
      { user_id: 12, rsvp_required: 0}
      { user_id: 13, rsvp_required: "0"}
      { user_id: 14, rsvp_required: ''}
      { user_id: 15}
    ]

    it "knows who needs to rsvp", ->
      participant = @participantHelper.getParticipant 10, participants
      expect( @participantHelper.isRsvpRequired(participant) ).toBeTruthy("integer")

      participant = @participantHelper.getParticipant 11, participants
      expect( @participantHelper.isRsvpRequired(participant) ).toBeTruthy("string")

      participant = @participantHelper.getParticipant 12, participants
      expect( @participantHelper.isRsvpRequired(participant) ).toBeFalsy("integer")

      participant = @participantHelper.getParticipant 13, participants
      expect( @participantHelper.isRsvpRequired(participant) ).toBeFalsy("string")

      participant = @participantHelper.getParticipant 14, participants
      expect( @participantHelper.isRsvpRequired(participant) ).toBeFalsy("empty string")

      participant = @participantHelper.getParticipant 15, participants
      expect( @participantHelper.isRsvpRequired(participant) ).toBeFalsy("undefined")
