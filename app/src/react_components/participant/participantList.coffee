ReactComponentFactory.createFactory("ParticipantList", "Participant",
  displayName: "ParticipantList"

  propTypes:
    participants     : React.PropTypes.array.isRequired
    rsvpPropertyName : React.PropTypes.string.isRequired
    showRsvp         : React.PropTypes.bool.isRequired

  render: ->
    {ul, li , Avatar} = React.DOM

    ul({className: "participant-list-container"},

      @props.participants.map((participant) =>

        li({
          className: "participant-list-item"
          key: participant.user_id
        },
          Avatar({
            className: "participant-list-item-avatar"
            user             : participant
            rsvpPropertyName : @props.rsvpPropertyName
            showRsvp         : @props.showRsvp || true
          })

        )
      )
    )
)
