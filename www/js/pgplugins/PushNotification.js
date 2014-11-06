//
//  PushNotification.js
//
// Created by Olivier Louvignes on  2012-05-06.
// Inspired by Urban Airship Inc orphaned PushNotification phonegap plugin.
//
// Copyright 2012 Olivier Louvignes. All rights reserved.
// MIT Licensed
'use strict';
(function(cordova) {

	function PushNotification() {}
    if(cordova.browser) {
        return;// do nothing in browser
    }
    var platform = ((window.device) ? window.device.platform : "browser");
    if (platform !== "iOS") {
        return;
    };

	// Call this to register for push notifications and retreive a deviceToken
	PushNotification.prototype.registerDevice = function(config, callback) {
		cordova.exec(callback, callback, "PushNotification", "registerDevice", config ? [config] : []);
	};

	// Call this to set the application icon badge
	PushNotification.prototype.setApplicationIconBadgeNumber = function(badge, callback) {
		cordova.exec(callback, callback, "PushNotification", "setApplicationIconBadgeNumber", [{badge: badge}]);
	};


	// Event spawned when a notification is received while the application is active
	PushNotification.prototype.notificationCallback = function(notification) {
        console.log("PushNotification callback");
		var ev = document.createEvent('HTMLEvents');
		ev.notification = notification;
		ev.initEvent('push-notification', true, true, arguments);
		document.dispatchEvent(ev);
	};

	cordova.addConstructor(function() {
		if(!window.plugins) window.plugins = {};
		window.plugins.pushNotification = new PushNotification();
	});

})(window.cordova || window.Cordova);
