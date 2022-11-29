ReactComponentFactory.createFactory("TimelineTabs", "Meeting",
  displayName: "TimelineTabs"

  switchTab: (tab) ->
    @props.switchTab(tab)

  render: ->
    {div, button} = React.DOM

    div( { className: "timeline-tabs" },
      button(
        {
          className: "timeline-tab #{if @props.tab == "upcoming" then "tab-selected"}"
          onClick: => @switchTab("upcoming")
        }
        "Upcoming"
      )
      button(
        {
          className: "timeline-tab #{if @props.tab == "past" then "tab-selected"}"
          onClick: => @switchTab("past")
        }
        "Past"
      )
    )
)
