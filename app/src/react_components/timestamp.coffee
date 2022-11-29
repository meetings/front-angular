ReactComponentFactory.createFactory("Timestamp", null,
  displayName: "Timestamp"
  propTypes:
    createdAt: React.PropTypes.number.isRequired
  render: ->

    {span} = React.DOM

    span(
      {
        className: "notification-time"
      }
      moment.unix(@props.createdAt).format(@props.dateHelper.formatTimeDayDate)
    )
)
