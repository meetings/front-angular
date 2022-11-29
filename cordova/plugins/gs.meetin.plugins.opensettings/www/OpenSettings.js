// Init the plugin
var OpenSettings = function () {

};

OpenSettings.prototype.execute = function(name, successCallback, errorCallback, args) {
  if (typeof(args) === "undefined") {
    args = [];
  }

  ret = cordova.exec(
    successCallback,
    errorCallback,
    'OpenSettings',
    name,
    args
  );
  return ret;
};

OpenSettings.prototype.open = function(successCallback, errorCallback) {
  this.execute("settings", successCallback, errorCallback);
};

module.exports = new OpenSettings();
