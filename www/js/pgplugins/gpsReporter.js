/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 23.04.2013 15:23
 */

'use strict';

(function(cordova) {

    function GPSReporter() {}

    if(!cordova.browser){
        // Call this to start getting locations
        // Location will be sent into GPSReporter.prototype.GPSCallback
        GPSReporter.prototype.startMonitoringGPS = function(callback) {
            console.log("start monitoring GPS");
            var username = localStorage.getItem("userName") || undefined;
            if (username) {
                //var apiURL = "http://ringo-server-eu.herokuapp.com/api/user/" + username +"/location";
                var apiURL = "https://ringo-server.f-secure.com/api/user/" + username +"/location";
                var authToken = localStorage.getItem("authToken");
                cordova.exec(callback, callback, "GPSReporter", "startMonitoringGPS", [apiURL, authToken]);
            }
        };

        GPSReporter.prototype.stopMonitoringGPS = function(callback) {
            console.log("stop monitoring GPS");
            cordova.exec(callback, callback, "GPSReporter", "stopMonitoringGPS", []);
        };

        // Ask for current position to be reported. Report it even if it is the same
        GPSReporter.prototype.forceReportCurrentLocation = function() {
            console.log("forceReportCurrentLocation");
            cordova.exec(function() {}, function() {}, "GPSReporter", "forceReportCurrentLocation", []);
        };

        GPSReporter.prototype.useAlwaysGPS = function(alwaysGPS) {
            console.log("useAlwaysGPS: " + alwaysGPS);
            cordova.exec(function() {}, function() {}, "GPSReporter", "useAlwaysGPS", [alwaysGPS]);
        };

        // Event spawned when a notification is received while the application is active
        GPSReporter.prototype.GPSCallback = function(pos) {
            var position = {
                coords : {}
            };
            position.coords.latitude = pos[0];
            position.coords.longitude = pos[1];
            position.coords.accuracy = pos[2];

            this.dispatchEvent(position);
        };
    }else{
        // Call this to start getting locations
        // Location will be sent into GPSReporter.prototype.GPSCallback
        // This function creates timer which updates position every 30 seconds
        GPSReporter.prototype.startMonitoringGPS = function(callback) {

            console.log("start monitoring");
            var that = this;
            var getAndDispatchPos = function() {
                navigator.geolocation.getCurrentPosition(function(position){
                        if (position && position.coords) {
                            delete position.coords["speed"];
                            delete position.coords["heading"];
                            delete position.coords["altitudeAccuracy"];
                            delete position.coords["altitude"];
                        };
                        that.dispatchEvent(position);
                    }, function(error) {
                        console.log('ERROR(' + error.code + '): ' + error.message);
                    }, {timeout:10000,enableHighAccuracy:true,maximumAge:0});
            };
            setTimeout(getAndDispatchPos, 1000);// first report in 1 sec
            setInterval(getAndDispatchPos, 30000);

        };

        GPSReporter.prototype.stopMonitoringGPS = function(callback) {
            console.log("stop monitoring GPS does not work in browser");
        };

        GPSReporter.prototype.forceReportCurrentLocation = function() {
            console.log("force reporting location does not work in browser");
        };

        GPSReporter.prototype.useAlwaysGPS = function() {
            console.log("useAlwaysGPS location does not work in browser");
        };

    }

    GPSReporter.prototype.dispatchEvent = function(position){
        var ev = document.createEvent('HTMLEvents');
        ev.position = position;
        ev.initEvent('gps-position', true, true);
        document.dispatchEvent(ev);
    };

    cordova.addConstructor(function() {
        if(!window.plugins) window.plugins = {};
        window.plugins.GPSReporter = new GPSReporter();
    });

})(window.cordova || window.Cordova);