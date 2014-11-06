/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
    .controller("settingsController",
        ["$scope", "$location", "commonService", "serverApiService", "ringoAppService", "localStorageService", "geoLocationService", function($scope, $location, commonService, serverApiService, ringoAppService, localStorageService, geoLocationService) {

            $scope.returnPath = "/dashboard";

            var dashboard = ringoAppService.getDashboard();
            if (dashboard) {
                $scope.userData = {
                    id: dashboard.userId,
                    name: (dashboard.name === "") ? dashboard.userId : dashboard.name,
                    image: (dashboard.icon === "") ? "images/defaultAvatar.png" : commonService.fetchImage(dashboard.icon),
                    lastReport: dashboard.location.time,
                    lastAccuracy: dashboard.location.acc,
                    isCurrentUser: true,
                    newMessages: 0
                };

            }
            $scope.currentLanguageName = commonService.getLanguageName(localStorageService.getLanguage());
            $scope.onAndroid = true;
            var platform = ((window.device) ? window.device.platform : "browser");
            if (platform == "Android") $scope.onAndroid = true;

            var version = ((window.device) ? window.device.version: "0.0");
            var country = undefined;

            var allowedToShowCrosssellInThisCountry = function(country) {
                var allowedCountries = ["AT", "BE", "BR", "BG", "CA", "CY", "CZ", "DK",
                    "EE", "FI", "FR", "DE", "GR", "HK", "HU", "IS", "IE", "IT", "JP",
                    "LV", "LT", "LU", "MY", "MT", "NL", "AN", "NO", "PL", "PT", "RO", "SK", "SI",
                    "KR", "ES", "SE", "CH", "GB", "US"];

                if (platform === "Android" && country === "CA") {
                    return false;
                }
                if (platform === "iOS" && country === "AN") {
                    return false;

                }

                return (allowedCountries.indexOf(country) !== -1);
            };

            $scope.fsecureProductsIsVisible = false;
            if (platform === "Win32NT" ) {
                // no cross sell in win phone
                localStorageService.setValue("fsecureProductsIsVisible", false)
            }

            if (localStorageService.getValue("fsecureProductsIsVisible") !== undefined) {
                $scope.fsecureProductsIsVisible = localStorageService.getValue("fsecureProductsIsVisible");
            } else {
                serverApiService.getCountry(function(status, country) {
                    if (status === true) {
                        console.log("Country: " + country);

                        $scope.safeApply(function() {
                            $scope.fsecureProductsIsVisible = allowedToShowCrosssellInThisCountry(country);
                            localStorageService.setValue("fsecureProductsIsVisible", $scope.fsecureProductsIsVisible);
                        });
                    } else {
                        console.log("Failed to query country. Status: " + status);
                    }
                })
            }

            $scope.onChangeLanguage = function() {
                localStorageService.setValue("mySettingsControllerReturnPath", $scope.returnPath);
                localStorageService.setValue("selectLanguageControllerReturnPath", "/settings");
                $location.path("/selectLanguage");
            };

            $scope.onFinishChangingName = function() {
                $scope.nameEditorEnabled = false;
                    if (dashboard && $scope.userName !== dashboard.name) {
                        serverApiService.updateCurrentUserInfo({name: $scope.userName}, function(success) {
                            console.log("updateCurrentUserInfo returned: " + success);
                            if (success !== true) {
                                commonService.showMessageToUser("error.failedToUpdateUserSettings", "error.title.error");
                                return;
                            }
                        });
                    }
            };

            $scope.onChangeName = function() {
                $scope.nameEditorEnabled = true;
            };

            $scope.onMySettingsClick = function() {
                $location.path("/mySettings");
            };

            $scope.onMyPlacesClick = function() {
                $location.path('/myPlaces');
            };

            $scope.onMyFamilyClick = function() {
                $location.path('/myFamily');
            };

            $scope.onMyFriendsClick = function() {
                $location.path('/myFriends');
            };

            $scope.onOtherProductsClick = function() {
                $location.path('/fsecureProducts');
            };

            $scope.onFeedbackClick = function() {
                //$location.path('/sendFeedback');
                $scope.onContactDevelopersClick();
            };

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
                subject += " " + getDeviceDetails();
                var body = commonService.getLocalizedString("dashboard.sendFeedback.body");

                commonService.openEmailApp(address, subject, body);
            };

            $scope.onAboutClick = function() {
                $location.path("/about");
            };

            $scope.onHelpClick = function() {
                //commonService.openURLInExternalBrowser("http://lok.ki/fi/faq/#post-32", true);
                commonService.openURLInExternalBrowser(commonService.getLocalizedString("help.link"), true);
            };

            $scope.onChangeAvatar = function() {
                localStorageService.setValue("changeAvatarControllerReturnPath", $location.path());
                localStorageService.setValue("changeAvatarControllerReturnPathForImageData", "/familyMemberDetails/" + ringoAppService.getLoggedInUserId());
                $location.path('/changeAvatar');
            };

            $scope.onUseGPS = function() {
                localStorage.setItem('alwaysGPS', $scope.useGPS);
                console.log("useGPS: " + $scope.useGPS);
                geoLocationService.useAlwaysGPS($scope.useGPS);
            };

            $scope.useGPS = localStorage.getItem('alwaysGPS') == "true"? true : false;
            $scope.useNoGPS = !$scope.useGPS;
            console.log("READ useGPS: " + $scope.useGPS);

        }]);