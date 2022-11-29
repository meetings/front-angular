# Remember to edit also scheduling service formatAvatarInitialsHtml
ReactComponentFactory.createFactory("Avatar", null,
  displayName: "Avatar"
  # propTypes:
  #   size         : React.PropTypes.string.isRequired
  #   user         : React.PropTypes.object.isRequired
  #   isOrganzizer : React.PropTypes.boolean.isRequired

  render: ->
    {span, picture, img} = React.DOM

    user = @props.user
    rsvpPropertyName = "rsvp_status"
    rsvpClass = "rsvp-maybe"

    avatarClassNames = [@props.className, "avatar", @props.size]

    if @props.isOrganzizer
      avatarClassNames.push("avatar--organizer")

    if user.scheduling_disabled
      avatarClassNames.push("scheduling-disabled")

    if user?.user_id_md5?
      bgColorCount = 10
      md5 = parseInt(user.user_id_md5.substring(0, 6), 16)
      avatarClassNames.push("avatar-bg-" + md5 % bgColorCount)

    switch user[rsvpPropertyName]
      when "yes" then rsvpClass = "rsvp-yes"
      when "no" then rsvpClass = "rsvp-no"
      else rsvpClass = "rsvp-maybe"

    picture(
      {
        className: avatarClassNames.join(" ")
        title: user.name
      },

      span({ className: "avatar-initials" }
        if !user.image
          span({},
            user.initials
          )
      )

      if user.image
        img({
          className: "avatar-img"
          src: user.image
          alt: user.name
        })

      if @props.showRsvp
        span({ className: "avatar-rsvp-overlay #{rsvpClass}" })
    )
)
