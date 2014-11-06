/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
        .controller("mySettingsController",
                ["$scope", "$location", "ringoAppService", "serverApiService", "commonService", "localStorageService", "geoLocationService",
                function($scope, $location, ringoAppService, serverApiService, commonService, localStorageService, geoLocationService) {

                    $scope.peopleInFamily = ringoAppService.getAllFamilyMembersInDashboardFormat();
                    $scope.locationReportingEnabled = localStorageService.isLocationReportingEnabled();
                    $scope.showEmptyPlaces = localStorageService.shouldDashboardShowEmptyPlaces();
                    $scope.currentLanguageName = commonService.getLanguageName(localStorageService.getLanguage());
                    $scope.userName = "";
                    $scope.nameEditorEnabled = false;

                    $scope.returnPath = localStorageService.getValue("mySettingsControllerReturnPath");
                    localStorageService.setValue("mySettingsControllerReturnPath", undefined);
                    if (!$scope.returnPath) {
                        $scope.returnPath = "/settings";
                    }

                    var dashboard = ringoAppService.getDashboard();
                    var settings = {};
                    if (dashboard) {
                        $scope.userName = dashboard.name;
                        if (dashboard.settings) {
                            settings = dashboard.settings;
                            if (settings.enableNotifications === undefined) {
                                settings.enableNotifications = true;// notifications are enabled by default
                            }

                            if (settings.messagesNotifications === undefined) {
                                settings.messagesNotifications = true;// messages notifications are true by default
                            }
                            if (settings.familyNotifications === undefined) {
                                settings.familyNotifications = true;// family notifications are true by default
                            }
                            if (settings.friendsNotifications === undefined) {
                                settings.friendsNotifications = true;// friends notifications are true by default
                            }
                            if (settings.friendsNearbyNotifications === undefined) {
                                settings.friendsNearbyNotifications = true;// friends nearby notifications are true by default
                            }
                            if (settings.peopleNotifications === undefined) {
                                settings.peopleNotifications = {};
                            }
                            if (settings.peopleNotifications.sendAllLocationAlerts === undefined) {
                                settings.peopleNotifications.sendAllLocationAlerts = true;// send all by default
                            }
                        }
                    }

                    $scope.settings = settings;

                    $scope.onMemberClick = function(member){
                        $scope.safeApply(function() {
                            $location.path('/locationSettings/' + member.userId);
                        });
                    };


                    var sendNewSettingsToServer = function() {
                        serverApiService.updateCurrentUserInfo({settings: $scope.settings}, function(success) {
                            console.log("updateCurrentUserInfo returned: " + success);
                            if (success !== true) {
                                commonService.showMessageToUser("error.failedToUpdateUserSettings", "error.title.error");
                                return;
                            }
                        });
                    };

                    $scope.changePlaceNotificationsCheckbox = function(key){
                        if (!$scope.settings.placeNotifications) {
                            $scope.settings.placeNotifications = {};
                        }
                        $scope.settings.placeNotifications[key] = !$scope.settings.placeNotifications[key];
                        sendNewSettingsToServer();
                    };

                    $scope.changeMessagesNotificationsCheckbox = function() {
                        $scope.settings.messagesNotifications = !$scope.settings.messagesNotifications;
                        sendNewSettingsToServer();
                    };

                    $scope.changeFamilyNotificationsCheckbox = function(){
                        $scope.settings.familyNotifications = !$scope.settings.familyNotifications;

                        sendNewSettingsToServer();

                    };

                    $scope.changeFriendsNotificationsCheckbox = function() {
                        $scope.settings.friendsNotifications = !$scope.settings.friendsNotifications;
                        sendNewSettingsToServer();
                    };

                    $scope.changeFriendsNearbyNotificationsCheckbox = function() {
                        $scope.settings.friendsNearbyNotifications = !$scope.settings.friendsNearbyNotifications;
                        sendNewSettingsToServer();
                    };

                    $scope.changeLocationEnabledCheckbox = function() {
                        $scope.locationReportingEnabled = !$scope.locationReportingEnabled;
                        localStorageService.setLocationReportingEnabled($scope.locationReportingEnabled);
                        if ($scope.locationReportingEnabled) {
                            geoLocationService.enableGeoLocationTracking();
                        } else {
                            geoLocationService.stopGeoLocationTracking();
                        }

                    };

                    $scope.changeShowEmptyPlacesCheckbox = function() {
                        $scope.showEmptyPlaces = !$scope.showEmptyPlaces;
                        localStorageService.setDashboardShouldShowEmptyPlaces($scope.showEmptyPlaces);
                    };


                    $scope.onLogOutClicked = function() {
                        commonService.askUserConfirmation("confirm.logOut", "confirm.title.confirm", function(buttonPressed) {
                            if (buttonPressed === 1) {
                                console.log("Logging out");
                                ringoAppService.logOut();
                            }
                        }, "confirm.buttons.logOut");

                    };

                    $scope.back = function() {
                        if ($scope.nameEditorEnabled) {
                            $scope.nameEditorEnabled = false;
                            if (dashboard) {
                                $scope.userName = dashboard.name
                            }
                            return;
                        }
                        $location.path($scope.returnPath);
                    };


                    $scope.onChangeLanguage = function() {
                        localStorageService.setValue("mySettingsControllerReturnPath", $scope.returnPath);
                        localStorageService.setValue("selectLanguageControllerReturnPath", "/mySettings");
                        $location.path("/selectLanguage");
                    };

                    $scope.changeEnableNotificationsCheckbox = function() {
                        $scope.settings.enableNotifications = !$scope.settings.enableNotifications;
                        sendNewSettingsToServer();
                    };

                    $scope.changeSendAllLocationAlertsCheckbox = function() {
                        $scope.settings.peopleNotifications.sendAllLocationAlerts = !$scope.settings.peopleNotifications.sendAllLocationAlerts;
                        sendNewSettingsToServer();
                    };


                    $scope.onChangeName = function() {
                        $scope.nameEditorEnabled = true;
                        //var input = document.getElementById('userNameInputElement');
                        //setTimeout(function(){
                        //    input.focus();
                        //},0);
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

                    $scope.sendFeedback = function() {
                        $location.path('/nps');
                    };

                    $scope.changeAvatar = function() {
                        localStorageService.setValue("changeAvatarControllerReturnPath", $location.path());
                        localStorageService.setValue("changeAvatarControllerReturnPathForImageData", "/familyMemberDetails/" + ringoAppService.getLoggedInUserId());
                        $location.path('/changeAvatar');
                    };

                }])
;