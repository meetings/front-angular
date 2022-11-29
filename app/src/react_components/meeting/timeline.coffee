meetingComponents = angular.module "meetingComponents", [
  "ngRoute"
  "react"
  "appConfig"
  "dateHelper"
  "participantModule"
  "sessionModule"
]

meetingComponents.factory "Timeline", (
  $location
  appConfig
  dateHelper
  participantService
  sessionService
) ->
  React.createClass(
    displayName: "Timeline"
    propTypes:
      allMeetings: React.PropTypes.object.isRequired
      openOrSuggest: React.PropTypes.func.isRequired
      createSuggested: React.PropTypes.func.isRequired
      confirmHideSuggested: React.PropTypes.func.isRequired
      switchTab: React.PropTypes.func.isRequired

    switchTab: (tab) ->
      @setState(tab: tab)

      @props.switchTab(tab)

    getInitialState: ->
      return {
        tab: $location.search().tab || "upcoming"
      }

    componentWillMount: ->
      @ng = {
        appConfig          : appConfig
        dateHelper         : dateHelper
        participantService : participantService
        sessionService     : sessionService
      }

      @ngCallbacks = {
        openOrSuggest: @props.openOrSuggest
        createSuggested: @props.createSuggested
        confirmHideSuggested: @props.confirmHideSuggested
      }


      @categories = {
        upcoming: [
          {
            group: "today"
            title: "Today"
            icon: "icon-star"
            iconClass: "today"
          }
          {
            group: "unscheduled"
            title: "Scheduling"
            icon: "icon-schedule"
            iconClass: "schedule"
          }
          {
            group: "thisWeekUpcoming"
            title: "This week"
            icon: "icon-up"
            iconClass: "this-week"
          }
          {
            group: "nextWeek"
            title: "Next week"
            icon: "icon-up"
            iconClass: "next-week"
          }
          {
            group: "furtherInFuture"
            title: "Future"
            icon: "icon-up"
            iconClass: "future"
          }
        ]
        past: [
          {
            group: "yesterday"
            title: "Yesterday"
            icon: "icon-down1"
            iconClass: "past"
          }
          {
            group: "thisWeekBefore"
            title: "This week"
            icon: "icon-down1"
            iconClass: "past"
          }
          {
            group: "lastWeek"
            title: "Last week"
            icon: "icon-down1"
            iconClass: "past"
          }
          {
            group: "furtherInPast"
            title: "Past"
            icon: "icon-down1"
            iconClass: "past"
          }
        ]
      }

    render: ->
      {h1, div, span, i} = React.DOM
      {TimelineTabs, TimelineList, TimelineListItem} = React.DOM.Meeting

      div({},
        TimelineTabs({
          tab: @state.tab,
          switchTab: @switchTab
        })

        @categories[@state.tab].map((category, ci) =>

          if @props.allMeetings? && @props.allMeetings[category.group].length
            div({
              className: "timeline-list"
              key: ci
            },
              h1({ className: "timeline-list-header" },

                span({ className: "timeline-header-icon #{category.iconClass}" },
                  i({ className: "icon #{category.icon}" })
                )

                span({ className: "meeting-category-title" }, category.title)
              )

              @props.allMeetings[category.group].map((meetings, mi) =>
                if meetings.length
                  TimelineList({
                    key           : "".concat(ci, mi)
                    meetings      : meetings
                    ngCallbacks   : @ngCallbacks
                    ng            : @ng
                  })
              )
            )
        )
      )

  )
