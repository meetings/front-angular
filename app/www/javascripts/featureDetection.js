(function() {
  redirectToError = function(reason) {
    var isIos = /iP(hone|od|ad)/.test(navigator.userAgent);
    window.location = "/errors/unsupportedDevice.html?ios="+ isIos.toString()+"&reason="+reason;
  };


  testLocalStorage = function() {
    if (window.localStorage) {
      try {
        window.localStorage.setItem("test", "test");
        window.localStorage.removeItem("test");
      } catch (err) {
        redirectToError("localStorageSetItem");
        return;
      }
    }
  };

  featureDetection = function() {
    requiredFeatures = {
      localStorage: window.localStorage,
      querySelector: document.querySelector
    };

    for (var i in requiredFeatures) {
      if (typeof requiredFeatures[i] === "undefined") {
        redirectToError(i);
        return;
      }
    }
  };

  featureDetection();
  testLocalStorage();
})();
