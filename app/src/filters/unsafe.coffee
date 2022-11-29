mtnUnsafeFilter = angular.module "mtnUnsafeFilter", []

mtnUnsafeFilter.filter "unsafe", ($sce) ->
  return $sce.trustAsHtml
