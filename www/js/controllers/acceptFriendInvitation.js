/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 30.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
    .controller("acceptFriendInvitationController", ["$scope", "$location", "$routeParams", "serverApiService", "commonService", "localStorageService",
        function ($scope, $location, $routeParams, serverApiService, commonService, localStorageService) {
            $scope.userId = $routeParams.userId;
            $scope.user = {
                icon: "images/invitingFriendAvatar.png",
                name: ""
            };

            $scope.returnPath = localStorageService.getValue("acceptFriendInvitationControllerReturnPath");
            localStorageService.setValue("acceptFriendInvitationControllerReturnPath", undefined);
            if (!$scope.returnPath) {
                $scope.returnPath = "/dashboard";
            }

            $scope.backButtonClicked = function () {
                $location.path($scope.returnPath);
            };

            var prepareInvitingUserInfo = function() {
                var storageName = "invitingFriend:" + $scope.userId;
                if (localStorageService.getValue(storageName)) {
                    $scope.user = JSON.parse(localStorageService.getValue(storageName));
                }

                serverApiService.readUserData($scope.userId, function(status, userData) {
                    if (status === true) {
                        $scope.safeApply(function() {
                            $scope.user.name = userData.name;
                            $scope.user.icon = commonService.fetchImage(userData.icon);
                            // save user's data to cache so next time it is shown correctly
                            localStorageService.setValue(storageName, JSON.stringify($scope.user));
                        });
                    } else {
                        console.log("Cannot get pending user data: " + status);
                    }
                });
            };

            prepareInvitingUserInfo();


            $scope.addFriend = function() {
                serverApiService.inviteFriend($scope.userId, function (status, text) {
                    console.log("Inviting friend finished with: " + status + ", " + text);
                    if (status !== true) {
                        if (status === serverApiService.errorCodes.FRIENDS_LIMIT) {
                            commonService.showMessageToUser("error.friendsLimit", "error.title.limit");
                        } else {
                            commonService.showMessageToUser("error.friendAcceptInvitationFailed", "error.title.error");
                        }
                    } else {
                        $location.path("/dashboard");
                    }
                });

            };

            $scope.declineInvitation = function() {
                console.log("Declining friend invitation: " + $scope.userId);
                serverApiService.deleteFriend($scope.userId, function (status) {
                    console.log("Friend deleted: " + $scope.userId + " with status: " + status);
                    if (status !== true) {
                        commonService.showMessageToUser("error.deletingFriendFailed", "error.title.error");
                    } else {
                        $location.path("/dashboard");
                    }
                });

            };

    }]);


