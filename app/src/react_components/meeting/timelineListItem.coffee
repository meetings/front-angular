ReactComponentFactory.createFactory("TimelineListItem", "Meeting",
  displayName: "TimelineListItem"
  propTypes:
    meeting: React.PropTypes.object.isRequired

  isRsvpRequired: (meeting) ->
    userId = @props.ng.sessionService.getUserId()
    participant = @props.ng.participantService.getParticipant(userId, meeting.participants)
    return @props.ng.participantService.isRsvpRequired(participant)


  getRsvpPropertyName: (meeting) ->
    if meeting.current_scheduling_id != 0
      return "has_answered_current_scheduling"
    else
      return "rsvp_status"

  getInitialState: ->
    return {
      suggestMeeting: 0
      suggestionBtnWorking: null
    }

  handleSuggestMeeting: (e) ->
    if @state.suggestMeeting == e.detail.meetingId
      @setState({ suggestMeeting: 0 })

    else if e.detail.meetingId == @props.meeting.id
      @setState({ suggestMeeting: e.detail.meetingId})

  createSuggested: ->
    @setState(suggestionBtnWorking: "create")
    @props.ngCallbacks.createSuggested(@props.meeting)

  hideSuggested: ->
    @setState(suggestionBtnWorking: "hide")
    @props.ngCallbacks.confirmHideSuggested(
      @props.meeting,
      null,
      =>
        @setState(suggestionBtnWorking: null)
      )

  componentDidMount: ->
    window.addEventListener('suggestMeeting', @handleSuggestMeeting)

  componentWillUnmount: ->
    window.removeEventListener('suggestMeeting', @handleSuggestMeeting)

  render: ->
    {h2, div, span, i, button} = React.DOM
    {ParticipantList, ParticipantSummary} = React.DOM.Participant

    meeting = @props.meeting

    div({},
      div({
        className: "meeting-wrapper"
        onClick : => @props.ngCallbacks.openOrSuggest(meeting)
      },

        if meeting.is_draft  && meeting.matchmaking_accepted != 0
          div({className: "draft"},
            "Participants not invited"
          )

        if meeting.is_suggested_meeting
          div({className: "suggested"},
            "Suggestion from "
            meeting.source_name
          )

        if meeting.matchmaking_accepted == 0
          div({className: "matchmaking"},
            "Meeting request from "
            meeting.matchmaking_requester_name
          )

        if @isRsvpRequired(meeting)
          div({className: "invitation"},
            "Meeting invitation"
          )

        h2({className: "timeline-list-title"}
          if meeting.title_value
            meeting.title_value
          else
            "Untitled meeting"
        )

        div({className: "timeline-list-duration"}

          i({className: "icon icon-time"})

          if meeting.begin_epoch == 0 && meeting.current_scheduling_id == 0
            span({}
              "Date is not set"
            )
          else if meeting.begin_epoch == 0 && meeting.current_scheduling_id != 0
            span({}
              "Scheduling"
            )
          else if meeting.begin_epoch != 0
            span({}
              moment.unix(meeting.begin_epoch).format(@props.ng.dateHelper.formatTime)
              " \u2012 "
              moment.unix(meeting.end_epoch).format(@props.ng.dateHelper.formatTime)
              " \u2013 "

              span({},
                @props.ng.dateHelper.durationString(meeting.begin_epoch, meeting.end_epoch)
              )
            )
        )

        div({ className: "timeline-list-location" }

          if meeting.online_conferencing_option
            switch meeting.online_conferencing_option

              when "hangout"
                span({ className: "online-location"},
                  i({ className: "icon icon-hangout" })
                  span({}, "On Hangout")
                )


              when "skype"
                span({ className: "online-location"},
                  i({ className: "icon icon-skype" })
                  span({}, "On Skype")

                  if !meeting.location_value && meeting.online_conferencing_data?.skype_account
                    span({},
                      ": ",
                      meeting.online_conferencing_data.skype_account
                    )
                )

              when "lync"
                span({ className: "online-location"},
                  i({className: "icon icon-lync" })
                  span({}, "On Lync")
                )

              when "teleconf"
                span({ className: "online-location"},
                  i({className: "icon icon-onlineconf" })
                  span({}, "On the phone")
                )

              when "custom"
                span({ className: "online-location"},
                  i({ className: "icon icon-custom" })
                    span({}, "Online")
                )


          # Show if:
          # online tool + location
          # no online tool + location
          # no online tool + no location
          # Hide if:
          # online tool + no location
          if meeting.location_value || !meeting.online_conferencing_option
            span({ className: "physical-location" },

              i({className: "icon icon-location" })

              if meeting.location_value
                span({}, meeting.location_value)
              else
                span({}, "Location is undecided")

            )

        )

        if meeting.participants.length <= @props.ng.appConfig.meeting.participants.maxCountBeforeSummary
          ParticipantList({
            participants     : meeting.participants
            rsvpPropertyName : @getRsvpPropertyName(meeting)
            showRsvp         : meeting.current_scheduling_id == 0
          })

        if meeting.participants.length > @props.ng.appConfig.meeting.participants.maxCountBeforeSummary
          ParticipantSummary({
            participants     : meeting.participants
            rsvpPropertyName : @getRsvpPropertyName(meeting)
            shortSummary     : meeting.current_scheduling_id != 0
            ng               : @props.ng
          })

      )

      if @state.suggestMeeting == meeting.id
        div({ className: "suggestion-actions" },
             # scroll-into-view>

          button({
            disabled: @state.suggestionBtnWorking
            onClick: @createSuggested
          },
            "Set up this meeting"
            if @state.suggestionBtnWorking == "create"
              span({ className: "spinner" })
          )

          button({
            className: "secondary  #{if @props.tab == "upcoming" then "tab-selected"}"
            disabled: @state.suggestionBtnWorking
            onClick: @hideSuggested
          },
            "Hide this event"
            if @state.suggestionBtnWorking == "hide"
              span({ className: "spinner"})
          )

        )
    )
)
