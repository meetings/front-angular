notificationComponents = angular.module "notificationComponents", [ "react", "dateHelper" ]

notificationComponents.factory "NotificationList", (dateHelper) ->
  React.createClass(
    displayName: "NotificationList"
    propTypes:
      notifications: React.PropTypes.array.isRequired
      open: React.PropTypes.func.isRequired

    render: ->
      {div, Timestamp} = React.DOM
      {NotificationListItem} = React.DOM.Notifications

      div({},
        @props.notifications?.map((notification) =>
          meetingTitle = notification.data.meeting?.title_value || "Untitled meeting"

          className = "notification"
          if !notification.is_read
            className += " notification-new"

          notificationListItem = NotificationListItem({
            notification : notification
            meetingTitle : meetingTitle
          })

          return div({
            className: className
            onClick: => @props.open(notification)
          },
            notificationListItem
            Timestamp({
              dateHelper: dateHelper
              createdAt: notification.created_epoch
            })
          )
        )
      )
  )
