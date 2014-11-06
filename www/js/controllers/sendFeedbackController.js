/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
    .controller("sendFeedbackController",
        ["$scope", "$location", "commonService", "localStorageService", "serverApiService", function($scope, $location, commonService, localStorageService, serverApiService) {
            var country = undefined;
            var platform = ((window.device) ? window.device.platform : "browser");
            var version = ((window.device) ? window.device.version: "0.0");
            $scope.canSendBugReports = (platform == "Win32NT");

            $scope.returnPath = "/settings";
            $scope.backToSettings = function() {
                $location.path($scope.returnPath);
            };

            serverApiService.getCountry(function(status, _country) {
                if (status === true) {
                    console.log("Country: " + _country);
                    country = _country;
                }
            });


            var getDeviceDetails = function() {
                var details = "[" + platform + version + "/";
                details += commonService.version + "/";
                details += localStorageService.getLanguage();
                if (country) {
                    details += "/" + country;
                }

                details += "]";
                return details;
            };

            $scope.onContactDevelopersClick = function() {
                var address = "lokki-feedback@f-secure.com";
                var subject = commonService.getLocalizedString("dashboard.sendFeedback.subject");
                var body = commonService.getLocalizedString("dashboard.sendFeedback.body");

                subject += " " + getDeviceDetails();
                commonService.openEmailApp(address, subject, body);
            };

            $scope.onNPSClick = function() {
                $location.path("/nps");
            };

            $scope.onSendBugReportClick = function() {
                if (console.sendLogWithEmail) {
                    console.sendLogWithEmail({
                        'to': 'lokki-feedback@f-secure.com',
                        'subject' : 'Lokki bug report'
                    });
                } else {
                    console.log("console.sendLogWithEmail is not defined");
                }
            }

        }]);