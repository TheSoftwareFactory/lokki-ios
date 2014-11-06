/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 23.07.2013 13:48
 */

'use strict';

angular.module("ringo.controllers")
        .controller("myFamilyController",
                ["$scope", "$location", "ringoAppService", "localStorageService",
                    function($scope, $location, ringoAppService, localStorageService) {

                        $scope.peopleInFamily = ringoAppService.getAllFamilyMembersInDashboardFormat();
                        $scope.returnPath = "/settings";
                        $scope.back = function(){
                            $location.path($scope.returnPath);
                        };

                        $scope.onMemberClick = function(member){
                            localStorageService.setValue("userDetailsControllerReturnPath", "/myFamily");
                            $location.path('/familyMemberDetails/' + member.userId);
                        };

                        $scope.addToFamily = function(){
                            localStorageService.setValue("inviteFamilyMemberControllerReturnPath", "/myFamily");
                            $location.path('/inviteFamilyMember');
                        };

                    }
                ]);