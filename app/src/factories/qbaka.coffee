mtnQbaka = angular.module "mtnQbaka", ["appConfig"]

# Configure qbaka parameters in app startup
mtnQbaka.run (appConfig, sessionService) ->
  if appConfig.qbaka.enabled
    window.qbaka.key = appConfig.qbaka.key
    window.qbaka.user = if sessionService.isSignedIn() then sessionService.getUserId() else "signed out"
    window.qbaka('param', 'version', appConfig.version)


mtnQbaka.factory('$exceptionHandler', ($log) ->
  return (exception) ->
    qbaka.report(exception)

    $log.error(exception)
)

# Directive for custom qbaka reports for missing notification types
#
# Usage:
#
#    <ANY mtn-qbaka-report="notificationType"></ANY>
#
#
mtnQbaka.directive "mtnQbakaReport", (appConfig) ->
  restrict: 'A'
  scope:
    mtnQbakaReport: '='
  link: (scope, elem, attrs) ->
    elem.parent().parent()[0].style.display = "none"

    if appConfig.qbaka.enabled
      window.qbaka.report("Unknown notification type: " + scope.mtnQbakaReport)

