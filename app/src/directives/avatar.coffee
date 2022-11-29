mtnAvatar = angular.module "mtnAvatar", [
]

mtnAvatar.directive "mtnAvatar", ($log) ->
  restrict: 'E'
  replace: true
  require: 'ngModel'
  scope:
    showRsvp: '=?'
  templateUrl: '/views/partials/_avatar.html'

  link: ( scope, elem, attrs, ngModel ) ->
    attrs.rsvpPropertyName ?= "rsvp_status"
    scope.showRsvp ?= false

    # TODO: figure if there's any sense in setting the size in html
    # attrs.size ?= "medium"
    # scope.size = "avatar-"+attrs.size

    scope.organizer = attrs.organizer?

    ngModel.$formatters.push (user) ->
      return unless user?

      scope.user = user

      switch user[attrs.rsvpPropertyName]
        when "yes" then scope.rsvpClass = "rsvp-yes"
        when "no" then scope.rsvpClass = "rsvp-no"
        else scope.rsvpClass = "rsvp-maybe"

      if user?.user_id_md5?
        bgColorCount = 10
        scope.avatarBgClassName = "avatar-bg-" + parseInt(user.user_id_md5.substring(0,6),16) % bgColorCount
