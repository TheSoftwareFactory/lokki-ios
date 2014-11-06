/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 22.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
    .controller("dashboardController", ["$scope", "$route", "$location", "ringoAppService", "localStorageService", "serverApiService", "commonService", "geoLocationService",
        function ($scope, $route, $location, ringoAppService, localStorageService, serverApiService, commonService, geoLocationService) {

            $scope.haveFamilyPlaces = true;
            $scope.numberOfNewMessages = 0;
            $scope.visibilityOptions = false;
            $scope.viewOverlay = false;

            var calculateNumberOfMessages = function (dashboard) {
                $scope.numberOfNewMessages = 0;
                if (dashboard.messages && dashboard.messages.unread) {
                    for (var id in dashboard.messages.unread) {
                        if (dashboard.messages.unread.hasOwnProperty(id)) {
                            $scope.numberOfNewMessages += +dashboard.messages.unread[id];
                        }
                    }
                }
            };

            var readDashboard = function () {
                var places = ringoAppService.getPlacesInDashboardFormat(true);
                var family = ringoAppService.getFamilyInDashboardFormat();
                var friends = ringoAppService.getFriendsInDashboardFormat(false, true, true);

                // to avoid binking in angular when we update dashboard, we check here if there are really changes
                var placesStringified = JSON.stringify(places);
                if (placesStringified !== $scope.placesStringified) {
                    $scope.places = places;
                    $scope.placesStringified = placesStringified;

                }
                var familyStringified = JSON.stringify(family);
                if (familyStringified !== $scope.familyStringified) {
                    $scope.family = family;
                    $scope.familyStringified = familyStringified;

                }
                var friendsStringified = JSON.stringify(friends);
                if (friendsStringified !== $scope.friendsStringified) {
                    $scope.friends = friends;
                    $scope.friendsStringified = friendsStringified;

                }

                $scope.hasFamilyMembers = false;
                var dashboard = ringoAppService.getDashboard();
                if (dashboard) {
                    calculateNumberOfMessages(dashboard);
                    if (dashboard.family) {
                        $scope.haveFamilyPlaces = (!commonService.isObjectEmpty(dashboard.family.places) || ($scope.places.length > 0));
                        if (dashboard.family.members) {
                            $scope.hasFamilyMembers = !commonService.isObjectEmpty(dashboard.family.members);
                        }
                    }

                    if (dashboard.userInvitingToJoinFamily &&
                        dashboard.userInvitingToJoinFamily !== "") {
                        serverApiService.readUserData(dashboard.userInvitingToJoinFamily, function (status, userData) {
                            // dashboard maybe was updated already and we may not have inviting user anymore
                            var stillHaveInvitingUser = (ringoAppService.getDashboard() && ringoAppService.getDashboard().userInvitingToJoinFamily && ringoAppService.getDashboard().userInvitingToJoinFamily !== "");
                            if (status === true && stillHaveInvitingUser) {
                                //console.log("Inviting user: " + JSON.stringify(userData));
                                $scope.safeApply(function () {
                                    $scope.invitingUser = userData;
                                });
                            } else {
                                console.log("No inviting user: " + status);
                                $scope.safeApply(function () {
                                    $scope.invitingUser = undefined;
                                });
                            }
                        });
                    } else {
                        $scope.safeApply(function () {
                            $scope.invitingUser = undefined;
                        });
                    }

                    //---------------------------------------------------
                    //  SETTINGS per family
                    //---------------------------------------------------
                    var settings = {};
                    //$scope.userName = dashboard.name;
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
                    $scope.settings = settings;
                    if ($scope.settings.visibilityMode) $scope.setVisibility($scope.settings.visibilityMode);
                }

            };

            var sendNewSettingsToServer = function () {
                serverApiService.updateCurrentUserInfo({settings: $scope.settings}, function (success) {
                    console.log("updateCurrentUserInfo returned: " + success);
                    if (success !== true) {
                        commonService.showMessageToUser("error.failedToUpdateUserSettings", "error.title.error");
                        return;
                    }
                });
            };

            $scope.$on('dashboardUpdated', function () {
                //console.log("got event dashboardUpdated");
                $scope.safeApply(function () {
                    readDashboard();
                });
            });

            $scope.onAvatarClick = function ($event, member) {
                $event.stopPropagation();
                if (member.invitingFriend) {
                    $location.path('/acceptFriendInvitation/' + member.userId);
                } else {
                    if (member.isFriend) {
                        $location.path("/friendDetails/" + member.userId);
                    } else {
                        $location.path("/familyMemberDetails/" + member.userId);
                    }
                }
            };

            $scope.onPlaceClick = function (place) {
                if (place.isEditable) {
                    $location.path("/placeDetails/" + place.name);
                }
            };

            $scope.notificationsPanelButtonClicked = function() {
                //$scope.returnPath = "dashboard";
                $location.path("/notifications");
            }

            $scope.onGroupClick = function() {
                $location.path("/groupDetails");
            }

            $scope.addToFamily = function () {
                $location.path("/inviteFamilyMember");
            };

            $scope.addToFriends = function () {
                $location.path("/inviteFriend");
            };


            $scope.menuButtonClicked = function () {
                $location.path('/settings');
            };

            $scope.chatsButtonClicked = function () {
                $location.path('/chat/family');
            };

            $scope.tellMeHowButtonClicked = function () {
                commonService.showMessageToUser("error.tellMeHowNotImplementedYet", "error.title.notImplemented");
            };

            $scope.emotionsButtonClicked = function () {
                commonService.showMessageToUser("error.emotionsNotImplementedYet", "error.title.notImplemented");
            };

            $scope.viewFamilyInvitation = function () {
                if ($scope.invitingUser) {
                    localStorageService.setValue("joinFamilyControllerInvitingUser", JSON.stringify($scope.invitingUser));
                    $location.path('/joinFamily');
                }
            };

            $scope.createNewPlace = function () {
                $location.path('/place/new');
            };

            $scope.changeVisibilityForGroup = function () {
                $scope.visibilityOptions = !$scope.visibilityOptions;
                $scope.viewOverlay = false;
            };

            $scope.showOverlay = function () {
                $scope.viewOverlay = !$scope.viewOverlay;
                $scope.visibilityOptions = false;
                //console.log("showOverlay clicked: viewOverlay is " + $scope.viewOverlay);
            };

            $scope.setVisibility = function (mode) {
                // TODO: set visibilityMode for the selected family, and push to the server.

                if (mode == 2) { // ON
                    $scope.settings.enableNotifications = true;
                    $scope.settings.messagesNotifications = true;
                    $scope.settings.familyNotifications = true;
                    $scope.settings.peopleNotifications.sendAllLocationAlerts = true;
                    geoLocationService.enableGeoLocationTracking();

                    $scope.visibilityClass = "icon-visibility-on";

                } else if (mode == 1) { // Invisible
                    $scope.settings.enableNotifications = true;
                    $scope.settings.messagesNotifications = true;
                    $scope.settings.familyNotifications = true;
                    $scope.settings.peopleNotifications.sendAllLocationAlerts = true;
                    geoLocationService.stopGeoLocationTracking();

                    $scope.visibilityClass = "icon-visibility-invisible";
                }
                if (mode == 0) { // OFF
                    $scope.settings.enableNotifications = false;
                    geoLocationService.stopGeoLocationTracking();

                    $scope.visibilityClass = "icon-visibility-off";
                }
                $scope.settings.friendsNotifications = false;
                $scope.settings.friendsNearbyNotifications = false;

                $scope.settings.visibilityMode = mode;
                sendNewSettingsToServer();
                $scope.visibilityOptions = false;
                //$scope.visibilityClass = "icon-visibility-off";
                console.log("VisibilityMode: " + $scope.settings.visibilityMode);
                console.log("VisibilityClass: " + $scope.visibilityClass);
            };

            $scope.cssClassForPlace = function (place) {

                var length = !angular.isUndefined(place.atPlace) && place.atPlace.length;
                var style = "house_pyramid";
                if (place.type) {
                    style = place.type;
                }
                if (length === 2) {
                    return "twoAvatars " + style;
                } else if (length === 3) {
                    return "threeAvatars " + style;
                } else if (length > 3) {
                    return "fullAvatars " + style;
                } else {
                    return style;
                }
            };


            var getMemberFadeCSSClass = function (member) {
                var curTime = Date.now();
                var minutes = (curTime - member.lastReport) / 1000 / 60;
                if (member.lastReport === 0 || member.lastReport === undefined) {
                    return "fade-100-percent";// not reported yet
                }
                if (minutes < 60) {
                    return "";
                }
                if (minutes < 60 * 4) {
                    return "fade-25-percent";
                }
                if (minutes < 60 * 8) {
                    return "fade-50-percent";
                }
                if (minutes < 60 * 16) {
                    return "fade-75-percent";
                }
                return "fade-100-percent";
            };

            $scope.cssClassForAvatarHalo = function (member) {
                var cssClass = getMemberFadeCSSClass(member);
                if (member.isCurrentUser) {
                    return cssClass + " yourself";
                }
                if (member.isFriend) {
                    return "friend";//friends don't fade
                }
                return cssClass;
            };

            $scope.leftArrowClick = function($event){
                $event.stopPropagation();
                console.log("Dashboard left arrow clicked");
            };
            $scope.rightArrowClick = function($event){
                $event.stopPropagation();
                console.log("Dashboard right arrow clicked");
            };

            ringoAppService.refreshDashboard();
            readDashboard();

        }])
;

