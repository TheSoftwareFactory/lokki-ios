/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 30.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
    .controller("familyMemberDetailsController", ["$scope", "$rootScope", "$location", "$routeParams", "localize", "serverApiService", "ringoAppService", "localStorageService", "commonService",
        function ($scope, $rootScope, $location, $routeParams, localize, serverApiService, ringoAppService, localStorageService, commonService) {

            $scope.user = {};
            $scope.userId = $routeParams.userId;
            $scope.numberOfNewMessages = ringoAppService.getNumOfNewMessagesFromUser(ringoAppService.getDashboard(), $scope.userId);
            $scope.text = {
                currentlyAt: "",
                lastReportTime: ""
            };
            $scope.leavingFamily = false;
            $scope.allNotificationsReportingEnabled = true;
            $scope.placeToShareToFacebook = undefined;

            $scope.returnPath = localStorageService.getValue("userDetailsControllerReturnPath");
            localStorageService.setValue("userDetailsControllerReturnPath", undefined);
            if (!$scope.returnPath) {
                $scope.returnPath = "/dashboard";
            }

            $scope.backButtonClicked = function () {
                $location.path($scope.returnPath);
            };

            $scope.onEditButtonClicked = function() {
                if ($scope.user.isFriend) {
                    console.log("You cannot edit settings of friends");
                    return;
                }

                if ($scope.user.currentUser || $scope.allNotificationsReportingEnabled) {
                    localStorageService.setValue("mySettingsControllerReturnPath", $location.path());
                    $location.path("/mySettings");
                } else {
                    localStorageService.setValue("locationSettingsControllerReturnPath", $location.path());
                    $location.path("/locationSettings/" + $scope.userId);
                }
            };

            $scope.cssClassForAvatarHalo = function() {
                if ($scope.user.currentUser) {
                    return "yourself";
                }
                return "";
            };


            var getLastReportTimeText = function (lastReportTime) {
                var curTime = Date.now();
                var minutes = (curTime - lastReportTime) / 1000 / 60;
                if (lastReportTime === 0) {
                    return localize.getLocalizedString("userDetailsPage.text.lastReportTime.never");
                }
                if (curTime <= lastReportTime || minutes < 1) {
                    return localize.getLocalizedString("userDetailsPage.text.lastReportTime.justNow");
                }
                if (minutes < 60) {
                    return minutes.toFixed(0) + localize.getLocalizedString("userDetailsPage.text.lastReportTime.minutes");
                }
                if (minutes < 60 * 48) {
                    return (minutes / 60).toFixed(0) + localize.getLocalizedString("userDetailsPage.text.lastReportTime.hours");
                }
                return (minutes / 60 / 24).toFixed(0) + localize.getLocalizedString("userDetailsPage.text.lastReportTime.days");
            };

            var prepareTextsAndFacebookLink = function (dashboard, user) {
                $scope.text = {
                    currentlyAt: "",
                    lastReportTime: ""
                };
                $scope.badAccuracy = {
                    text: "",
                    iconClass: ""
                };
                $scope.placeToShareToFacebook = undefined;
                if (!dashboard || !user) {
                    return;
                }

                var places = user.places;
                if (places && places.length > 0) {
                    if (user.family && user.family.places && user.family.places[places[0]]) {
                        $scope.placeToShareToFacebook = user.family.places[places[0]];
                    }

                    $scope.text.currentlyAt = localize.getLocalizedString("userDetailsPage.text.currentlyAt");
                    $scope.text.currentlyAt += places[0];
                } else {
                    $scope.text.currentlyAt = localize.getLocalizedString("userDetailsPage.text.currentlyAtUnknownPlace");
                }

                if (user && user.location) {
                    $scope.text.lastReportTime = localize.getLocalizedString("userDetailsPage.text.lastReportTime.starter");
                    $scope.text.lastReportTime += getLastReportTimeText(user.location.time);

                    if (!user.currentUser) {
                        $scope.text.distanceFromYou = localize.getLocalizedString("placeDetails.distanceFromYou.distance") + commonService.getDistanceText(user.location, dashboard.location);
                    }

                    if (user) {
                        var acc = +user.location.acc;
                        if (acc > 200) {
                            $scope.badAccuracy.iconClass = "icon-accuracy-very-bad";
                            $scope.badAccuracy.text = localize.getLocalizedString("userDetailsPage.text.accuracyIsVeryBad");
                        } else if (acc > 80) {
                            $scope.badAccuracy.iconClass = "icon-accuracy-bad";
                            $scope.badAccuracy.text = localize.getLocalizedString("userDetailsPage.text.accuracyIsBad");
                        }
                    }
                }
            };


            var readUserInfoFromDashboard = function () {
                var dashboard = JSON.parse(JSON.stringify(ringoAppService.getDashboard()));
                if (dashboard && dashboard.family && dashboard.family.members) {
                    $scope.userId = $routeParams.userId;
                    $scope.user.pendingMember = false;
                    if ($scope.userId === dashboard.userId) { // Current user
                        $scope.user = dashboard;
                        $scope.user.currentUser = true;
                        $scope.user.icon = commonService.fetchImage($scope.user.icon);

                    } else {
                        $scope.user = dashboard.family.members[$scope.userId];

                        if ($scope.user === undefined) { // Not a family member. Must be a pending member then.
                            _readPendingUserInfoFromDashboard(dashboard);
                        }
                        else { // Family member
                            $scope.user.icon = commonService.fetchImage($scope.user.icon);
                        }
                    }
                } else {
                    console.log("userDetailsController: Dashboard is invalid");
                }
                if ($scope.user.userId) {
                    $scope.user.phoneNumber = "+" + $scope.user.userId;
                }
                if (dashboard && dashboard.settings && dashboard.settings.peopleNotifications) {
                    $scope.allNotificationsReportingEnabled = dashboard.settings.peopleNotifications.sendAllLocationAlerts;
                }
                prepareTextsAndFacebookLink(dashboard, $scope.user);
            };


            // read info for non family member from dashboard. It can be pending pending family member
            var _readPendingUserInfoFromDashboard = function(dashboard) {
                var pendingUserStorageName = "PendingUser:" + $scope.userId;
                if (localStorageService.getValue(pendingUserStorageName)) {
                    $scope.user = JSON.parse(localStorageService.getValue(pendingUserStorageName));
                } else {
                    $scope.user = {};
                    $scope.user.userId = $scope.userId;
                    $scope.user.name = ("+" + $scope.userId);
                    $scope.user.currentUser = false;
                    $scope.user.icon = "images/pendingAvatar.png";
                }

                $scope.user.pendingMember = true;

                serverApiService.readUserData($scope.userId, function(status, userData) {
                    if (status === true) {
                        //console.log("Pending user: " + JSON.stringify(userData));
                        $scope.safeApply(function() {
                            $scope.user.name = userData.name;
                            $scope.user.icon = commonService.fetchImage(userData.icon);
                            // save user's data to cache so next time it is shown correctly
                            localStorageService.setValue(pendingUserStorageName, JSON.stringify($scope.user));
                        });
                    } else {
                        console.log("Cannot get pending user data: " + status);
                    }
                });
            };

            $scope.$on('dashboardUpdated', function () {
                console.log("got event dashboardUpdated");
                $scope.safeApply(function () {
                    readUserInfoFromDashboard();
                });
            });

            $scope.$on('imageCached', function () {
                console.log("got event imageCached");
                $scope.safeApply(function () {
                    readUserInfoFromDashboard();
                });
            });

            $scope.callButtonClicked = function () {
                if (!$scope.user.currentUser) {
                    document.location.href = 'tel:' + $scope.user.phoneNumber;
                }
            };

            $scope.messageButtonClicked = function () {
                if (!$scope.user.currentUser) {
                    document.location.href = 'sms:' + $scope.user.phoneNumber;
                }
            };

            $scope.pingButtonClicked = function () {
                if (!$scope.user.currentUser) {
                    localStorageService.setValue("chatControllerReturnPath", "/familyMemberDetails/" + $scope.userId);
                    $location.path("/chat/" + $scope.user.userId);
                }
            };

            $scope.locationOnMapButtonClicked = function () {
                var loc = JSON.parse(JSON.stringify($scope.user.location));
                loc.name = $scope.user.name;
                commonService.showLocationOnMap(loc);
            };

            $scope.changeAvatar = function () {
                if (!$scope.user.currentUser) {
                    console.log("You cannot change other user's avatar");
                    return;
                }
                localStorageService.setValue("changeAvatarControllerReturnPath", "/familyMemberDetails/" + $routeParams.userId);
                $location.path("/changeAvatar");
            };

            var uploadNewAvatarOnReturnFromChangeAvatarPage = function () {
                var imgData = localStorageService.getValue("changeAvatarControllerImageData"); // If it exists -returned from changeAvatar Controller
                if (imgData) {
                    console.log("Uploading... Image size:" + imgData.length);
                    console.log("Uploading new image data to server");
                    localStorageService.setValue("changeAvatarControllerImageData", undefined);
                    serverApiService.uploadNewAvatar(imgData, function (avatarUploadStatus) {
                        console.log("uploadNewAvatar returned: " + avatarUploadStatus);
                        ringoAppService.refreshDashboard();
                    })
                }
            };

            $scope.deleteUser = function (userId) {
                if ($scope.user.pendingMember) {
                    commonService.askUserConfirmation("confirm.cancelFamilyMemberRequest", "confirm.title.confirm", function (buttonPressed) {
                        if (buttonPressed === 1) {
                            console.log("Deleting family member: " + userId);
                            serverApiService.removeFamilyMember(userId, function (status) {
                                console.log("Family member deleted: " + userId + " with status: " + status);
                                if (status !== true) {
                                    commonService.showMessageToUser("error.deletingFamilyMemberFailed", "error.title.error");
                                } else {
                                    $location.path("/dashboard");
                                }
                            });
                        }
                    }, "confirm.buttons.confirmCancel");
                    return;
                }

                $scope.leavingFamily = !$scope.leavingFamily;
            };

            $scope.leaveFamilyButtonClicked = function(userId){
                console.log("Deleting family member: " + userId);
                serverApiService.removeFamilyMember(userId, function (status) {
                    console.log("Family member deleted: " + userId + " with status: " + status);
                    if (status !== true) {
                        commonService.showMessageToUser("error.deletingFamilyMemberFailed", "error.title.error");
                    } else {
                        $location.path("/dashboard");
                    }
                });
            };

            $scope.leaveFamilyCancelButtonClicked = function(){
                $scope.leavingFamily = false;
            };


            $scope.createPlaceButtonClicked = function() {
                localStorageService.setValue("addEditPlaceControllerReturnPath", $location.path());
                $location.path("/place/createInUserLocation/" + $scope.userId);
            };



            $scope._shareWhereUserInOnFacebook = function() {
                if (!$scope.placeToShareToFacebook) {
                    return;
                }
                //var googleMapsQuery = "https://maps.google.com/maps?q=";
                //var lat = "" + $scope.placeToShareToFacebook.lat;
                //var lon = "" + $scope.placeToShareToFacebook.lon;
                //lat = lat.replace(",", ".");
                //lon = lon.replace(",", ".");
                //googleMapsQuery += lat + "," + lon;

                var params = {
                    method: 'feed',
                    name: localize.getLocalizedString("share.facebook.header", "placeName", $scope.placeToShareToFacebook.name),
                    picture: 'http://lok.ki/wp-content/uploads/2013/08/icon96.png',
                    caption: " ",
                    link: "http://lok.ki",
                    description: localize.getLocalizedString("share.facebook.description")
                };
                FB.ui(params, function(obj) {
                    console.log("FB.ui returned: " + JSON.stringify(obj));
                });
            };

            $scope.shareOnFacebookButtonClicked = function () {

                if (window.plugins && window.plugins.Share) {
                    var title = localize.getLocalizedString("share.facebook.header",
                                                            "placeName",
                                                            $scope.placeToShareToFacebook.name);
                    var msg = localize.getLocalizedString("share.facebook.description");

                    plugins.Share.shareLink({
                        url: "http://lok.ki",
                        title: title,
                        message: msg
                    });
                    return;
                }

                if (typeof CDV == 'undefined') console.log('CDV variable does not exist');
                if (typeof FB == 'undefined') console.log('FB variable does not exist. Check that you have included the Facebook JS SDK file.');

                if (!FB) {
                    return;
                }

                FB.getLoginStatus(function(response) {
                    if (response.authResponse) {
                        if (response.status === 'connected') {
                            // logged in and connected user, someone you know
                            $scope._shareWhereUserInOnFacebook();
                        }
                    } else {
                        // the user isn't even logged in to Facebook.
                        FB.login(
                            function(response) {
                                console.log("FB login returned: " + JSON.stringify(response));
                                if (response.authResponse) {
                                    $scope._shareWhereUserInOnFacebook();

                                } else {
                                    console.log('not logged in');
                                }
                            },
                            { scope: "email" }
                        );
                    }
                });


            };

            uploadNewAvatarOnReturnFromChangeAvatarPage();
            readUserInfoFromDashboard();

        }])
;

