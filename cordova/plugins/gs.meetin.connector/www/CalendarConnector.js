// Init the plugin
var CalendarConnector = function () {

};

CalendarConnector.prototype.execute = function(name, successCallback, errorCallback, args) {
  if (typeof(args) === "undefined") {
    args = [];
  }

  ret = cordova.exec(
    successCallback,
    errorCallback,
    'CalendarConnectorPlugin',
    name,
    args
  );
  return ret;
};

CalendarConnector.prototype.init = function(userId, token, appConfig, successCallback, errorCallback) {
  appConfig = appConfig || {};

  this.execute("init", successCallback, errorCallback, [userId, token, appConfig.apiBaseUrl, appConfig.pollInterval]);
};

CalendarConnector.prototype.getUserId = function(successCallback, errorCallback) {
  this.execute("getUserId", successCallback, errorCallback);
};

CalendarConnector.prototype.getToken = function(successCallback, errorCallback) {
  this.execute("getToken", successCallback, errorCallback);
};

CalendarConnector.prototype.signIn = function(userId, token, email, successCallback, errorCallback) {
  this.execute("signIn", successCallback, errorCallback, [userId, token, email]);
};

CalendarConnector.prototype.signOut = function(successCallback, errorCallback) {
  this.execute("signOut", successCallback, errorCallback);
};

CalendarConnector.prototype.startService = function(successCallback, errorCallback) {
  this.execute("startService", successCallback, errorCallback);
};

CalendarConnector.prototype.stopService = function(successCallback, errorCallback) {
  this.execute("stopService", successCallback, errorCallback);
};

CalendarConnector.prototype.forceUpdate = function(successCallback, errorCallback) {
  this.execute("forceUpdate", successCallback, errorCallback);
};

CalendarConnector.prototype.removeSources = function(successCallback, errorCallback) {
  this.execute("removeSources", successCallback, errorCallback);
};

module.exports = new CalendarConnector();
