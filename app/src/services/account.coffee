account = angular.module "accountModule", ['appConfig']

account.service "accountService", (appConfig, sessionService, currentUserService) ->

  generateGoogleAuthUrl: (state) ->
    stateStr = encodeURIComponent(JSON.stringify(state))

    googleUrl = 'https://accounts.google.com/o/oauth2/auth?'
    googleUrl += 'response_type=code'
    googleUrl += '&client_id=' + appConfig.googleSignIn.clientId
    googleUrl += '&redirect_uri=' + encodeURIComponent(appConfig.googleSignIn.redirectUri)
    googleUrl += '&state=' + stateStr
    googleUrl += '&scope=' + encodeURIComponent('https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email https://www.google.com/calendar/feeds/ https://www.google.com/m8/feeds')
    googleUrl += '&access_type=offline'
    googleUrl += '&approval_prompt=force'

    return googleUrl
