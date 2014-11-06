/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 30.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
    .controller("friendDetailsController", ["$scope", "$rootScope", "$location", "$routeParams", "localize", "serverApiService", "ringoAppService", "localStorageService", "commonService",
        function ($scope, $rootScope, $location, $routeParams, localize, serverApiService, ringoAppService, localStorageService, commonService) {

            $scope.user = {};
            $scope.userId = $routeParams.userId;
            $scope.numberOfNewMessages = ringoAppService.getNumOfNewMessagesFromUser(ringoAppService.getDashboard(), $scope.userId);

            $scope.timeoutToHideInaccurateInfoPassed = false;
            setTimeout(function() {
                $scope.safeApply(function() {
                    $scope.timeoutToHideInaccurateInfoPassed = true;
                });
            }, 3500);

            var shareStatuses = ["shareNearby", "shareAlways", "shareNever"]; // note: do not change, it is exact match with backend
            var myViewStatuses = ["showNearby", "showNowhere"]; // note: do not change, it is exact match with backend. "showInMyPlaces"
            var selectedShareStatus = "shareNearby";
            var selectedMyViewStatus = "showNearby";

            $scope.returnPath = localStorageService.getValue("userDetailsControllerReturnPath");
            localStorageService.setValue("userDetailsControllerReturnPath", undefined);
            if (!$scope.returnPath) {
                $scope.returnPath = "/dashboard";
            }

            $scope.backButtonClicked = function () {
                $location.path($scope.returnPath);
            };

            var readUserInfoFromDashboard = function () {
                var dashboard = JSON.parse(JSON.stringify(ringoAppService.getDashboard()));
                if (dashboard) {
                    $scope.userId = $routeParams.userId;

                    if (dashboard.settings && dashboard.settings.friend && dashboard.settings.friend[$scope.userId]) {
                        var shareMode = dashboard.settings.friend[$scope.userId].shareMode;
                        var viewMode = dashboard.settings.friend[$scope.userId].viewMode;
                        if (shareStatuses.indexOf(shareMode) !== -1) {
                            selectedShareStatus = shareMode;
                        }
                        if (myViewStatuses.indexOf(viewMode) !== -1) {
                            selectedMyViewStatus = viewMode;
                        }
                    }

                    if (_isFriend(dashboard, $scope.userId)) {
                        _readFriendInfoFromDashboard(dashboard);
                    } else {
                        _readPendingUserInfoFromDashboard(dashboard);
                    }
                } else {
                    console.log("friendDetailsController: Dashboard is invalid");
                }
                if ($scope.user.userId) {
                    $scope.user.phoneNumber = "+" + $scope.user.userId;
                }
            };

            // user is friend so prepare data for friend details view
            var _readFriendInfoFromDashboard = function(dashboard) {
                $scope.user = JSON.parse(JSON.stringify(dashboard.friendsInfo[$scope.userId]));
                $scope.user.icon = commonService.fetchImage($scope.user.icon);

                $scope.badAccuracy = {
                    text: "",
                    iconClass: ""
                };
                if ($scope.user && $scope.user.location) {
                    var acc = +$scope.user.location.acc;
                    if (acc > 200) {
                        $scope.badAccuracy.iconClass = "icon-accuracy-very-bad";
                        $scope.badAccuracy.text = localize.getLocalizedString("userDetailsPage.text.accuracyIsVeryBad");
                    } else if (acc > 80) {
                        $scope.badAccuracy.iconClass = "icon-accuracy-bad";
                        $scope.badAccuracy.text = localize.getLocalizedString("userDetailsPage.text.accuracyIsBad");
                    }
                }


            };

            // read info for non friend yet from dashboard. It can be pending friend or invited friend
            var _readPendingUserInfoFromDashboard = function(dashboard) {
                var pendingUserStorageName = "PendingFriend:" + $scope.userId;
                if (localStorageService.getValue(pendingUserStorageName)) {
                    $scope.user = JSON.parse(localStorageService.getValue(pendingUserStorageName));
                } else {
                    $scope.user = {};
                    $scope.user.userId = $scope.userId;
                    $scope.user.name = ("+" + $scope.userId);
                    $scope.user.currentUser = false;
                    $scope.user.icon = "images/pendingAvatar.png";
                    if (_isPendingFriend(dashboard, $scope.userId)) {
                        $scope.user.icon = "images/pendingFriendAvatar.png";
                    }
                    if (_isInvitingFriend(dashboard, $scope.userId)) {
                        $scope.user.icon = "images/invitingFriendAvatar.png";
                    }
                }

                $scope.user.pendingFriend = _isPendingFriend(dashboard, $scope.userId);
                $scope.user.invitingFriend = _isInvitingFriend(dashboard, $scope.userId);

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

            var _isPendingFriend = function(dashboard, userId) {
                if (dashboard && dashboard.pendingFriends && dashboard.pendingFriends.indexOf(userId) !== -1) {
                    return true;
                }
                return false;
            };

            var _isInvitingFriend = function(dashboard, userId) {
                if (dashboard && dashboard.invitingFriends && dashboard.invitingFriends.indexOf(userId) !== -1) {
                    return true;
                }
                return false;
            };

            var _isFriend = function(dashboard, userId) {
                if (dashboard && dashboard.friends && dashboard.friends.indexOf(userId) !== -1 && dashboard.friendsInfo && dashboard.friendsInfo[userId]) {
                    return true;
                }
                return false;
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
                document.location.href = 'tel:' + $scope.user.phoneNumber;
            };

            $scope.messageButtonClicked = function () {
                document.location.href = 'sms:' + $scope.user.phoneNumber;
            };

            $scope.pingButtonClicked = function () {
                localStorageService.setValue("chatControllerReturnPath", "/friendDetails/" + $scope.userId);
                $location.path("/chat/" + $scope.user.userId);
            };

            $scope.locationOnMapButtonClicked = function () {
                var loc = JSON.parse(JSON.stringify($scope.user.location));
                loc.name = $scope.user.name;
                commonService.showLocationOnMap(loc);
            };

             $scope.deleteUser = function (userId) {
                $scope.removingFriend = true;
            };

            $scope.deletePendingFriend = function (userId) {
                commonService.askUserConfirmation("confirm.cancelFriendRequest", "confirm.title.confirm", function (buttonPressed) {
                    if (buttonPressed === 1) {
                        console.log("Deleting friend: " + userId);
                        serverApiService.deleteFriend(userId, function (status) {
                            console.log("Friend deleted: " + userId + " with status: " + status);
                            if (status !== true) {
                                commonService.showMessageToUser("error.deletingFriendFailed", "error.title.error");
                            } else {
                                $location.path("/dashboard");
                            }
                        });
                    }
                }, "confirm.buttons.confirmCancel");
            };

            $scope.removeFriendButtonClicked = function(userId) {
                serverApiService.deleteFriend(userId, function (status) {
                    console.log("Friend deleted: " + userId + " with status: " + status);
                    if (status !== true) {
                        commonService.showMessageToUser("error.deletingFriendFailed", "error.title.error");
                    } else {
                        $location.path("/dashboard");
                    }
                });
            };

            $scope.removeFriendCancelButtonClicked = function() {
                $scope.removingFriend = false;
            };

            var _sendStatusToServer = function() {
                var newSettings = {
                    friend : {}
                };
                newSettings.friend[$scope.userId] = {
                    shareMode: selectedShareStatus,
                    viewMode: selectedMyViewStatus
                };
                serverApiService.updateCurrentUserInfo({settings: newSettings}, function(success) {
                    console.log("updateCurrentUserInfo returned: " + success);
                    if (success !== true) {
                        commonService.showMessageToUser("error.failedToUpdateUserSettings", "error.title.error");
                    }
                });

            };

            $scope.onHowFriendCanSeeMe = function(newState) {
                selectedShareStatus = newState;
                _sendStatusToServer();
            };

            $scope.onHowISeeFriend = function(newState) {
                selectedMyViewStatus = newState;
                _sendStatusToServer();
            };

            $scope.selectClassIfHowFriendCanSeeMeIs = function(checkState, returnClass) {
                if (selectedShareStatus === checkState) {
                    return returnClass;
                }
                return "";
            };

            $scope.selectClassIfHowISeeFriendIs = function(checkState, returnClass) {
                if (selectedMyViewStatus === checkState) {
                    return returnClass;
                }
                return "";
            };


            readUserInfoFromDashboard();

        }])
;

