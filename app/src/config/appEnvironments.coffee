#Set default values if environment.js is not set properly
window.mtnApp = mtnApp || {}
window.mtnApp.config = window.mtnApp.config || {}
window.mtnApp.appBrand = window.mtnApp.appBrand || 0
window.mtnApp.version = window.mtnApp.version || "dev"
window.mtnApp.config.environment = window.mtnApp.config.environment || "staging"
window.mtnApp.config.mode = window.mtnApp.config.mode || "development"


window.mtnApp.appSettings =
  0:
    appName: "Meetin.gs"
    urlScheme: "meetin.gs"
    supportLinks:
      support:
        linkText: "Send feedback"
        url: "mailto:feedback@meetin.gs?subject=Meetin.gs%20app%20feedback"
        alternativeUrl: "mailto:feedback@meetin.gs?subject=Meetin.gs%20app%20feedback"
      facebook:
        linkText: "Meetin.gs on Facebook"
        url: "fbnolongerworksinmeetings"
        # url: "fb://#{if device?.platform.toLowerCase() == 'ios' then 'profile' else 'page'}/" +
        #   182909251746386
        alternativeUrl: "https://www.facebook.com/www.meetin.gs"
      twitter:
        linkText: "Meetin.gs on Twitter"
        url: "twitter://user?user_id=" +
          252745045
        alternativeUrl: "https://twitter.com/meetin_gs"

  1:
    appName: "SwipeToMeet"
    urlScheme: "swipetomeet"
    supportLinks:
      support:
        linkText: "Send feedback"
        url: "mailto:feedback@swipetomeet.com?subject=SwipeToMeet%20feedback"
        alternativeUrl: "mailto:feedback@swipetomeet.com?subject=SwipeToMeet%20feedback"
      facebook:
        linkText: "SwipeToMeet on Facebook"
        url: "fbnolongerworksinswipetomeet"
        # url: "fb://#{if device?.platform.toLowerCase() == 'ios' then 'profile' else 'page'}/" +
        #   736185226466841
        alternativeUrl: "https://www.facebook.com/swipetomeet"
      twitter:
        linkText: "SwipeToMeet on Twitter"
        url: "twitter://user?user_id=" +
          2976255909
        alternativeUrl: "https://twitter.com/swipetomeet"

  2:
    appName: "cMeet"
    urlScheme: "cmeet"
    supportLinks:
      support:
        linkText: ""
        url: ""
        alternativeUrl: ""
      facebook:
        linkText: ""
        url: ""
        alternativeUrl: ""
      twitter:
        linkText: ""
        url: ""
        alternativeUrl: ""

window.mtnApp.appSetting = window.mtnApp.appSettings[window.mtnApp.appBrand]

window.mtnApp.appName = window.mtnApp.appSettings[window.mtnApp.appBrand].appName

window.appEnvironments =
  commons: # - shared with all environments
    timeline:
      initialMeetingsLimit: 20
      fetchMoreMeetingsLimit: 10

    meeting:
      participants:
        maxCountBeforeSummary: 7 # Participants

    thumbnail:
      small: 32 * 2
      medium: 60 * 2
      large: 100 * 2

    notifications:
      pollInterval: (1000*60) * 5 # minutes

    calendar:
      pollInterval: (1000*60) * 10 #minutes

    scheduling:
      pollInterval: 500 #milliseconds

    pushNotifications:
      testPushRetryCount: 10
      testPushRetryInterval: 5000 #milliseconds

    tabIndex:
      scheduling: 0
      timeline: 1
      notification: 2
      menu: 3

    tabs: [
      {
        location: "http://localhost/views/scheduling/index.html#/scheduling/"
      }
      {
        location: "http://localhost/views/meeting/index.html?msgChannel=timeline"
      }
      {
        location: "http://localhost/views/notification/index.html?msgChannel=notifications"
      }
      {
        location: "http://localhost/views/menu/index.html?msgChannel=menu"
      }
    ]

    appStoreUrls:
      ios: "https://itunes.apple.com/en/app/swipetomeet/id996409597"
      android: "https://play.google.com/store/apps/details?id=com.swipetomeet.mobile"

  staging:
    api:
      baseUrl: "https://api-dev.meetin.gs/v1"

    googleSignIn:
      clientId: x
      redirectUri: "https://dev.meetin.gs/meetings_global/redirect_mobile"

    google:
      analytics:
        enabled:       true
        accountId:     "x"
        updateInterval: 10 # seconds

    qbaka:
      enabled:  true
      key:      "x"

    pusher:
      key:          "x"
      authEndpoint: "https://api-dev.meetin.gs/v1/pusher_auth"
      channelName:  "private-meetings_user_"

    analytics:
      mixpanel:
        token: "x"
      segment:
        token: "x"

    sentry:
      enabled:   false
      projectId: "35872"
      token:     "x"
      whitelistUrls: [
        /http:\/\/(mob|dist)\.dev/
        /https?:\/\/mobiledev\.meetin\.gs/
        /https?:\/\/localhost/
      ]

    GCM:
      id: "x"

  alpha:
    api:
      baseUrl: "https://api-dev.meetin.gs/v1"

    googleSignIn:
      clientId: 584216729178
      redirectUri: "https://dev.meetin.gs/meetings_global/redirect_mobile"

    google:
      analytics:
        enabled:       true
        accountId:     "x"
        updateInterval: 10 # seconds

    qbaka:
      enabled:  true
      key:      "x"

    pusher:
      key:          "x"
      authEndpoint: "https://api-dev.meetin.gs/v1/pusher_auth"
      channelName:  "private-meetings_user_"

    analytics:
      mixpanel:
        token: "x"
      segment:
        token: "x"

    sentry:
      enabled:   false
      projectId: "35872"
      token:     "x"
      whitelistUrls: [
        /http:\/\/(mob|dist)\.dev/
        /https?:\/\/mobiledev\.meetin\.gs/
        /https?:\/\/localhost/
      ]

  beta:
    api:
      baseUrl: "https://api-beta.meetin.gs/v1"

    googleSignIn:
      clientId: x
      redirectUri: "https://beta.meetin.gs/meetings_global/redirect_mobile"

    google:
      analytics:
        enabled:       true
        accountId:     "x"
        updateInterval: 10 # seconds

    qbaka:
      enabled:  true
      key:      "x"

    pusher:
      key:          "x"
      authEndpoint: "https://api-beta.meetin.gs/v1/pusher_auth"
      channelName:  "private-meetings_user_"

    analytics:
      mixpanel:
        token: "x"
      segment:
        token: "x"

    sentry:
      enabled:   true
      projectId: "35886"
      token:     "x"
      whitelistUrls: [
        /https?:\/\/mobilebeta\.meetin\.gs/
        /https?:\/\/localhost/
      ]

  live:
    api:
      baseUrl: "https://api.meetin.gs/v1"

    googleSignIn:
      clientId: x
      redirectUri: "https://meetin.gs/meetings_global/redirect_mobile"

    google:
      analytics:
        enabled:       true
        accountId:     "x"
        updateInterval: 10 # seconds

    qbaka:
      enabled:  true
      key:      "x"

    pusher:
      key:          "x"
      authEndpoint: "https://api.meetin.gs/v1/pusher_auth"
      channelName:  "private-meetings_user_"

    analytics:
      mixpanel:
        token: "x"
      segment:
        token: "x"

    sentry:
      enabled:   true
      projectId: "35892"
      token:     "x"
      whitelistUrls: [
        /https?:\/\/mobile\.meetin\.gs/
        /https?:\/\/localhost/
      ]

    GCM:
      id: "x"

window.appEnvironment = window.appEnvironments[window.mtnApp.config.environment]
