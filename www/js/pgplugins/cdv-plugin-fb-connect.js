CDV = ( typeof CDV == 'undefined' ? {} : CDV );
var cordova = window.cordova || window.Cordova;
CDV.FB = {
  init: function(apiKey, fail) {
    // create the fb-root element if it doesn't exist
    if (!document.getElementById('fb-root')) {
      var elem = document.createElement('div');
      elem.id = 'fb-root';
      document.body.appendChild(elem);
    }
    var xmlhttp = new XMLHttpRequest();
    xmlhttp.onload=function(){console.log("Endpoint saved "+ this.responseText);}
    xmlhttp.open("POST", "https://www.facebook.com/impression.php", true);
    xmlhttp.send('plugin=featured_resources&payload={"resource": "adobe_phonegap", "appid": "'+apiKey+'", "version": "3.0.0" }');
    
    cordova.exec(function() {
    var authResponse;
    if (localStorage.getItem('cdv_fb_session') !== "undefined") {
        try {
            authResponse = JSON.parse(localStorage.getItem('cdv_fb_session') || '{"expiresIn":0}');
        }
        catch(err) {
            console.log("Failed to parse cdv_fb_session");
        }
    }
    if (authResponse && authResponse.expirationTime) { 
      var nowTime = (new Date()).getTime();
      if (authResponse.expirationTime > nowTime) { 
        // Update expires in information
        updatedExpiresIn = Math.floor((authResponse.expirationTime - nowTime) / 1000);
        authResponse.expiresIn = updatedExpiresIn;
                 
        localStorage.setItem('cdv_fb_session', JSON.stringify(authResponse));
        FB.Auth.setAuthResponse(authResponse, 'connected');
       }
      }
      console.log('Cordova Facebook Connect plugin initialized successfully.');
    }, (fail?fail:null), 'org.apache.cordova.facebook.Connect', 'init', [apiKey]);
  },
  login: function(params, cb, fail) {
    params = params || { scope: '' };
    cordova.exec(function(e) { // login
        if (e.authResponse && e.authResponse.expiresIn) {
          var expirationTime = e.authResponse.expiresIn === 0
          ? 0 
          : (new Date()).getTime() + e.authResponse.expiresIn * 1000;
          e.authResponse.expirationTime = expirationTime; 
        }
        if (e.authResponse) {
            localStorage.setItem('cdv_fb_session', JSON.stringify(e.authResponse));
        }
        FB.Auth.setAuthResponse(e.authResponse, 'connected');
        if (cb) cb(e);
    }, (fail?fail:null), 'org.apache.cordova.facebook.Connect', 'login', params.scope.split(',') );
  },
  logout: function(cb, fail) {
    cordova.exec(function(e) {
      localStorage.removeItem('cdv_fb_session');
      FB.Auth.setAuthResponse(null, 'notConnected');
      if (cb) cb(e);
    }, (fail?fail:null), 'org.apache.cordova.facebook.Connect', 'logout', []);
  },
  getLoginStatus: function(cb, fail) {
    cordova.exec(function(e) {
      if (cb) cb(e);
    }, (fail?fail:null), 'org.apache.cordova.facebook.Connect', 'getLoginStatus', []);
  },
  dialog: function(params, cb, fail) {
    cordova.exec(function(e) { // login
      if (cb) cb(e);
                  }, (fail?fail:null), 'org.apache.cordova.facebook.Connect', 'showDialog', [params] );
  }
};
