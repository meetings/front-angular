describe "Cache service", ->

  beforeEach module("cacheModule", "angular-cache")

  beforeEach inject (cacheService, CacheFactory) ->
    @CacheFactory = CacheFactory
    @cacheService = cacheService

    @cacheService.init("SwipeToMeet")

  it "is not null after init", ->
    expect(@CacheFactory.get("SwipeToMeet")).not.toBeUndefined()

  it "is null after destroy", ->
    @cacheService.destroy()
    expect(@CacheFactory.get("SwipeToMeet")).toBeUndefined()

  describe "write and read", ->

    it "can put object to cache", ->
      @cacheService.put("test", {test: "test"})
      expect(@cacheService.cache.info().size).toEqual(1)

    it "can get object from cache", ->
      cached = @cacheService.get("test")
      expect(cached).toEqual(test: "test")

    it "can remove object from cache", ->
      @cacheService.remove("test")
      expect(@cacheService.get("test")).toBeUndefined()

    it "can remove all objects from cache", ->
      @cacheService.put("test1", {test: "test1"})
      @cacheService.put("test2", {test: "test2"})

      @cacheService.removeAll()

      expect(@cacheService.get("test1")).toBeUndefined()
      expect(@cacheService.get("test2")).toBeUndefined()
