ReactComponentFactory.createFactory("ParticipantSummary", "Participant",
  displayName: "ParticipantSummary"

  propTypes:
    participants     : React.PropTypes.array.isRequired
    shortSummary     : React.PropTypes.bool.isRequired
    rsvpPropertyName : React.PropTypes.string.isRequired

  render: ->
    {div, span} = React.DOM

    attending = @props.ng.participantService.getAttendingCount(
      @props.participants,
      @props.rsvpPropertyName
    )

    pending = @props.ng.participantService.getPendingCount(
      @props.participants,
      @props.rsvpPropertyName
    )

    declined = @props.ng.participantService.getDeclinedCount(
      @props.participants,
      @props.rsvpPropertyName
    )

    if !@props.shortSummary
      return div({ className: "participant-summary" },

        span({ className: "participant-summary-yes" },
          span({ className: "rsvp-bullet rsvp-yes" })
          attending
          " attending, "
        )

        span({ className: "participant-summary-maybe" },
          span({ className: "rsvp-bullet rsvp-maybe" })
          pending
          " unknown, "
        )

        span({ className: "participant-summary-no"},
          span({ className: "rsvp-bullet rsvp-no" })
          declined
          " declined"
        )

      )

    if @props.shortSummary
      return div({ className: "participant-summary" },
        @props.participants.length
        " participants"
      )

)
