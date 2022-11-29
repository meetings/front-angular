viewParams = angular.module "viewParams", [ "ngRoute" ]

viewParams.service "viewParams", ($routeParams) ->

  get: (key) ->
    value = null

    if @viewParams?
      value = @viewParams[key]

    if !value?
      value = $routeParams[key]

    if value? && !_.isObject(value)
      value = decodeURIComponent(value)

    return value

  add: (key, value) ->
    if !@viewParams?
      @viewParams = {}

    @viewParams[key] = value

  remove: (key) ->
    return unless @viewParams?

    delete @viewParams[key]

  set: (object) ->
    @viewParams = object
