mtnUtils = angular.module "mtnUtils", ["dateHelper"]

mtnUtils.service "deviceready", ($q) ->
  deferred = $q.defer()

  document.addEventListener("deviceready", ->
    deferred.resolve()
  , false)

  # Fake deviceready in web
  if !cordova?
    deferred.resolve()

  return deferred.promise

mtnUtils.factory "stringUtils", ->

  generateRandomString: (strLength) ->
    text = "";
    possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";

    i = 0
    while i < strLength
      text += possible.charAt(Math.floor(Math.random() * possible.length))
      i++

    return text;

  stripHtml: (str) ->
    return "" unless str?
    return str.replace(/<\/?[^>]+>/gi, "")

  lineBreakToBr: (str) ->
    return "" unless str?
    return str.replace(/\n/gi, "<br />")

mtnUtils.factory "cssClassUtils", ->
  calculateAvatarBgClassName: (md5) ->
    if !md5?
      return ""

    bgColorCount = 10
    return "avatar-bg-" + parseInt(md5.substring(0,6),16) % bgColorCount

mtnUtils.factory "vsprintfUtils", (cssClassUtils, dateHelper) ->

  formatIconHtml: (paramData) ->
    return "<i class=\"icon icon-#{ paramData }\"></i>"

  formatNameHtml: (paramData) ->
    return "<span>#{ paramData.name }</span>"

  formatFirstNameHtml: (paramData) ->
    return "<span>#{ paramData.first_name }</span>"

  formatAvatarInitialsHtml: (paramData) ->
    return "<div class=\"avatar log-avatar #{ cssClassUtils.calculateAvatarBgClassName(paramData.user_id_md5) }\">
              <span class=\"avatar-initials\">#{ paramData.initials }</span>
            </div>"

  formatAvatarImageHtml: (paramData) ->
    return "<div class=\"avatar log-avatar #{ cssClassUtils.calculateAvatarBgClassName(paramData.user_id_md5) }\">
              <img src=\"#{ paramData.image }\"
                 class=\"avatar-img\"
                 title=\"#{paramData.name}\"
                 alt=\"#{paramData.name}\" />
            </div>"

  formatAvatarHtml: (paramData) ->
    if( paramData.image )
      return @formatAvatarImageHtml(paramData)
    else
      return @formatAvatarInitialsHtml(paramData)

  formatAvatarNameHtml: (paramData) ->
    return @formatAvatarHtml(paramData) + " " + @formatNameHtml(paramData)

  formatAvatarFirstNameHtml: (paramData) ->
    return @formatAvatarHtml(paramData) + " " + @formatFirstNameHtml(paramData)

  formatShortTimestampHtml: (paramData) ->
    return moment.unix(paramData.epoch).format(dateHelper.formatTimeDate)

  formatLongTimestampHtml: (paramData) ->
    return moment.unix(paramData.epoch).format(dateHelper.formatTimeDayDate)

  # Iterate through log item's params and push properly formatted params to vsprintf argument array
  formatParams: (item) ->
    params = []
    _.each(item.params, (param) =>

      formattedParam = ""

      switch param.type
        when "icon"
          formattedParam = @formatIconHtml(param.data)

        when "user"
          switch param.display_hint
              when "name"
                formattedParam = @formatNameHtml(param.data)

              when "first_name"
                formattedParam = @formatFirstNameHtml(param.data)

              when "avatar"
                formattedParam = @formatAvatarHtml(param.data)

              else # avatar_name
                formattedParam = @formatAvatarFirstNameHtml(param.data)

        when "timestamp"
          switch param.display_hint
            when "short"
              formattedParam = @formatShortTimestampHtml(param.data)

            else
              formattedParam = @formatLongTimestampHtml(param.data)

        when "string"
          formattedParam = param.data

      switch param.render_hint
        when "strong"
          formattedParam = "<strong>#{formattedParam}</strong>"

        when "em"
          formattedParam = "<em>#{formattedParam}</em>"

      params.push(formattedParam)
    )

    return params

# Bypass cache by generating a one-time URL
#
# Image whose URL does not change will be not reloaded with ng-src due to cache issues.
# Use the URL provided by this function in order to bypass cache and force reloading.
# Function adds current timestamp in milliseconds in the image URL as a query parameter.
# It assumes that there are not other query parameters.
mtnUtils.factory "uncacheableUrl", ->
  (url) ->
    return null unless url

    url + "?" + (new Date).getTime()

# Device detection and other device related helper functions
mtnUtils.factory "deviceUtils", ($log) ->
  isIPad: ->
    /iPad/.test(navigator.userAgent)

  isIos: ->
    /iP(hone|od|ad)/.test(navigator.userAgent)

  isAndroid: ->
    /android/.test(navigator.userAgent.toLowerCase())

  platform: ->
    if window.mtnApp.fake_platform
      if(!window.device)
        $log.debug("Faking platform ", window.mtnApp.fake_platform)
        window.device = {};
      return window.mtnApp.fake_platform
    else if !cordova?
      return "web"
    else
      return device.platform.toLowerCase()

  uuid: ->
    if window.mtnApp.fake_platform
      $log.debug("Faking uuid for ", window.mtnApp.fake_platform)
      return "fake uuid"
    else if !cordova?
      return "web"
    else
      return device.uuid

  version: ->
    if !cordova?
      return "web"
    else
      return parseFloat(device.version)

# Remove focus from tinymce. Requires dummy button in view
mtnUtils.factory "removeTinyMCE", ->
  (id) ->
    document.getElementById("dummybutton").focus()
    tinyMCE.get(id).destroy()

mtnUtils.factory "javascriptUtils", ->

  capitalizeFirstLetter: (string) ->
    return string.charAt(0).toUpperCase() + string.slice(1);

  vendorPrefix: (element, property, argument) ->
    element.style["ms" + @capitalizeFirstLetter(property)] = argument;
    element.style["webkit" + @capitalizeFirstLetter(property)] = argument;
    element.style["Moz" + @capitalizeFirstLetter(property)] = argument;
    element.style["O" + @capitalizeFirstLetter(property)] = argument;
    element.style[property] = argument;

  vendorPrefixAttr: (element, property, argument) ->
    element.style["ms" + @capitalizeFirstLetter(property)] = "-ms-"+argument;
    element.style["webkit" + @capitalizeFirstLetter(property)] = "-webkit-"+argument;
    element.style["Moz" + @capitalizeFirstLetter(property)] = "-moz-"+argument;
    element.style["O" + @capitalizeFirstLetter(property)] = "-o-"+argument;
    @vendorPrefix( element, property, argument)

  parseQueryString: (queryString) ->
    queryArray = queryString.split('&')
    queryParams = {}
    _.each(queryArray, (q) ->
      item = q.split('=')
      key = item[0]

      try
        value = JSON.parse(item[1])
      catch e
        value = item[1]

      queryParams[key] = value
    )

    return queryParams
