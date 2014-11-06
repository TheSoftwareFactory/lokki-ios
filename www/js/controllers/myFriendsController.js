/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 13.08.2013 13:42
 */

'use strict';

angular.module("ringo.controllers")
        .controller("myFriendsController",
                ["$scope", "$location", "ringoAppService", "localStorageService",
                    function($scope, $location, ringoAppService, localStorageService) {

                        $scope.friends = ringoAppService.getFriendsInDashboardFormat(true, true, true);
                        $scope.returnPath = "/settings";
                        $scope.back = function(){
                            $location.path($scope.returnPath);
                        };


                        $scope.onMemberClick = function(member){
                            if (member.invitingFriend) {
                                localStorageService.setValue("acceptFriendInvitationControllerReturnPath", "/myFriends");
                                $location.path('/acceptFriendInvitation/' + member.userId);
                            } else {
                                localStorageService.setValue("userDetailsControllerReturnPath", "/myFriends");
                                $location.path("/friendDetails/" + member.userId);
                            }
                        };

                        $scope.addFriend = function(){
                            localStorageService.setValue("inviteFamilyMemberControllerReturnPath", "/myFriends");
                            $location.path("/inviteFriend");
                        };
                    }
                ]);