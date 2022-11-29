# Angular app for scheduling tab
# Define all required controller apps here and controller specific dependencies in controllers.
schedulingTabApp = angular.module 'schedulingTabApp',
  [
    'ngRoute'
    'ngAnimate'
    'SPARouteConfig'
    'schedulingApp'
    'meetingApp'
    'materialApp'
  ]
