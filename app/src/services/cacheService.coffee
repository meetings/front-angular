cacheModule = angular.module "cacheModule", [ "angular-cache" ]

cacheModule.service "cacheService", (CacheFactory) ->

  @cache = null

  init: (name) ->
    if !CacheFactory.get(name)
      CacheFactory.createCache(name, {
        storageMode: "localStorage"
      })

    @cache = CacheFactory.get(name)

  get: (name) ->
    @cache.get(name)

  put: (name, data) ->
    @cache.put(name, data)

  remove: (name) ->
    @cache.remove(name)

  removeAll: () ->
    @cache.removeAll()

  destroy: ->
    @cache.destroy()
