mtnURL = angular.module "mtnURL", [ "mtnUtils" ]

mtnURL.service "mtnURL", ($q, $window, deviceUtils) ->

  open: (href, altHref, target = "_top") ->

    deferred = $q.defer()

    if !href?
      deferred.reject()

    if deviceUtils.platform() == "web"
      # use altHref in web if possible
      altHref ?= href

      $window.open(altHref, target)
      deferred.resolve()

    # Open links in system browser on Corodva
    else
      target = "_system"

      CanOpen(href,
        (isInstalled) ->
          if isInstalled
            $window.open(href, target)
            deferred.resolve()
          else
            if altHref?
              $window.open(altHref, target)
              deferred.resolve()

            else
              deferred.reject()
      )

    return deferred.promise
