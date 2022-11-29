ReactComponentFactory.createFactory("TimelineList", "Meeting",
  displayName: "TimelineList"
  propTypes:
    meetings: React.PropTypes.array.isRequired

  render: ->
    {ul, li, div} = React.DOM
    {TimelineListItem} = React.DOM.Meeting

    ul({className: "timeline-list-container"},

      if !parseInt(@props.meetings[0].begin_epoch)
        div({ className: "timeline-list-date" },
          "Time not decided"
        )
      else
        div({ className: "timeline-list-date" },
          div({ className: "day" },
            moment.unix(@props.meetings[0].begin_epoch).format(@props.ng.dateHelper.formatDayOfWeek)
          )

          div({ className: "date" },
            if @props.ng.dateHelper.isEpochThisYear(@props.meetings[0].begin_epoch)
              moment.unix(@props.meetings[0].begin_epoch)
                .format(@props.ng.dateHelper.formatDate)
            else
              moment.unix(@props.meetings[0].begin_epoch)
                .format(@props.ng.dateHelper.formatDateYear)
          )
        )

      @props.meetings.map((meeting) =>

        li({
          className : "timeline-list-item"
          key       : meeting.id
        },
          TimelineListItem({
            meeting       : meeting
            ngCallbacks   : @props.ngCallbacks
            ng            : @props.ng
          })
        )
      )
    )
)
