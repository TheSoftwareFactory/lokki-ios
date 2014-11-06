/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 23.04.2013 10:52
 */

'use strict';

angular.module("ringo.services")
        .service("geoLocationService", ["$rootScope", function($rootScope){
            this.gpsReporter = window.plugins.GPSReporter;
            var rootScope = $rootScope;
            var locationService = this;
            var gpsMonitoringCallbacks = {};

            /// Start monitoring GPS if not yet started.
            /// callback will be executed with position as the only parameter when new GPS position arrives.
            /// For every new position will call something like:
            /// callback({"accuracy":10,"longitude":24.938378,"latitude":60.169863});
            this.enableGeoLocationTracking = function(){
                this.gpsReporter.startMonitoringGPS(function() {});
            };

            this.stopGeoLocationTracking = function(){
                console.log("Stop tracking GPS");
                this.gpsReporter.stopMonitoringGPS(function() {});
            };

            // Ask for current position to be reported. Report it even if it is the same
            this.forceReportCurrentLocation = function() {
                this.gpsReporter.forceReportCurrentLocation();
            };

            this.useAlwaysGPS = function(alwaysGPS) {
                this.gpsReporter.useAlwaysGPS(alwaysGPS);
            };

            angular.element(document).bind("gps-position", function(event){
                $rootScope.$broadcast('new-gps-location', event.position.coords);
            });
        }])
;







