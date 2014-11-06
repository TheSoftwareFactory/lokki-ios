/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 30.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
    .controller("joinFamilyController", ["$scope", "$location", "serverApiService", "ringoAppService", "localStorageService", "commonService",
        function ($scope, $location, serverApiService, ringoAppService, localStorageService, commonService) {

        $scope.returnPath = "/dashboard";

        // expect "joinFamilyControllerInvitingUser" to be set in localStorage as JSON encoded object like:
        //{
        //    userId: "358406655...",
        //    name: "Nickname",
        //    icon: "images/....png"
        //};
        $scope.invitingUser = JSON.parse(localStorageService.getValue("joinFamilyControllerInvitingUser"));
//        {
//            userId: ringoAppService.getDashboard().userInvitingToJoinFamily,
//            name: ringoAppService.getDashboard().userInvitingToJoinFamily,
//            icon: "images/defaultAvatar.png"
//        };

        var hasFamilyMembers = function() {
            var dashboard = ringoAppService.getDashboard();
            if (dashboard && dashboard.family && dashboard.family.members) {
                return !commonService.isObjectEmpty(dashboard.family.members);
            }
            return false;
        };

        $scope.joinFamily = function() {

            /*
            if (hasFamilyMembers()) {
                commonService.showMessageToUser("error.cannotJoinFamilyWhileHasOwnFamilyMembers", "error.title.error");

                return;
            }
            */

            commonService.askUserConfirmation("confirm.joinNewFamily", "confirm.title.confirm", function(buttonPressed) {
                if (buttonPressed === 1) {
                    serverApiService.acceptInvitationToJoinFamilyFromUser($scope.invitingUser.userId, function(status) {
                        console.log("acceptInvitationToJoinFamilyFromUser returned " + status);
                        $scope.safeApply(function() {
                            $location.path("/dashboard");
                        });
                    });
                }
            }, "confirm.buttons.confirmCancel");
        };

        $scope.declineInvitation = function() {
            serverApiService.declineInvitationToJoinFamilyFromUser($scope.invitingUser.userId, function(status) {
                console.log("declineInvitationToJoinFamilyFromUser returned " + status);
                $scope.safeApply(function() {
                    $location.path("/dashboard");
                });
            });
        }
    }]);


