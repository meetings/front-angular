mtnListFilters = angular.module "mtnListFilters", []

mtnListFilters.filter "remove", ->
  (list, removedItem) ->
    return unless list

    _.remove(list, (item) -> item == removedItem)

    return list

mtnListFilters.filter "difference", ->
  (list, removedItems) ->
    return unless list

    list = _.difference(list, removedItems)

    return list
