'use strict';
(function(cordova) {

    function PushNotificationWP8() {}
    if(cordova.browser) {
        return;// do nothing in browser
    }

    var platform = ((window.device) ? window.device.platform : "browser");
    // use Win32NT for WP8
    if (platform !== "Win32NT") {
        return;
    };

    // Call this to register for push notifications and retreive a deviceToken
    PushNotificationWP8.prototype.registerDevice = function (config, callback) {
        console.log("PushNotification, registerDevice");
        cordova.exec(callback, callback, "PushNotification", "registerDevice", config ? [config] : []);
    };

    PushNotificationWP8.prototype.unregisterDevice = function (config, callback) {
        console.log("PushNotification, unregisterDevice");
        cordova.exec(callback, callback, "PushNotification", "unregisterDevice");
    };

    PushNotificationWP8.prototype.NotificationCallback = function (notification) {
        console.log("PushNotificationWP8 - NotificationCallback");
        var ev = document.createEvent('HTMLEvents');
        ev.notification = notification;
        ev.initEvent('push-notification', true, true);
        document.dispatchEvent(ev);
    };

    cordova.addConstructor(function () {
        if (!window.plugins) window.plugins = {};
        window.plugins.pushNotificationWP8 = new PushNotificationWP8();
    });

})(window.cordova || window.Cordova);