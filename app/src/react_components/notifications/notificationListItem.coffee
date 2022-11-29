ReactComponentFactory.createFactory("NotificationListItem", "Notifications",
  displayName: "NotificationListItem"
  propTypes:
    notification : React.PropTypes.object.isRequired
    meetingTitle : React.PropTypes.string.isRequired
  render: ->
    {div, span, i, strong} = React.DOM

    div({},
      i { "className": "icon " +
                       "icon-#{ @props.notification.data.icon } " +
                       "icon-color-#{ @props.notification.data.icon_color }"
        }
      span {
        "className":"notification-text"
        "dangerouslySetInnerHTML": { __html: @props.notification.data.template }
      }
    )
)
