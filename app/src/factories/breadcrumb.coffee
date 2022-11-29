breadcrumb = angular.module 'breadcrumb', []

breadcrumb.factory 'breadcrumb', ->
  set: (title, clickable) ->
    if title?
      localStorage.setItem("breadcrumb", title)
      localStorage.setItem("breadcrumbClickable", clickable)
    else
      title = localStorage.getItem("breadcrumb")
      clickable = if localStorage.getItem("breadcrumbClickable") != "undefined" then localStorage.getItem("breadcrumbClickable") else undefined

    @title = decodeURIComponent(title)
    @clickable = clickable
