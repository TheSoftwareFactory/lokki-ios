/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 30.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
        .controller("placeDetailsController", ["$scope", "$location", "$routeParams", "ringoAppService", "commonService", "serverApiService", "localStorageService",
        function($scope, $location, $routeParams, ringoAppService, commonService, serverApiService, localStorageService){
            $scope.placeId = $routeParams.placeId;
            $scope.place = {}; // it will contain current place as in dashboard response (family.places.placeId)

            $scope.userIsInThisPlace = false;// is current user in this place or not

            $scope.distanceFromUserToPlace = 100;
            $scope.distanceType = "placeDetails.distanceFromYou.meters";//or placeDetails.distanceFromYou.kilometers

            $scope.returnPath = localStorageService.getValue("placeDetailsControllerReturnPath");
            localStorageService.setValue("placeDetailsControllerReturnPath", undefined);
            if (!$scope.returnPath) {
                $scope.returnPath = "/dashboard";
            }

            $scope.backButtonClicked = function() {
                $location.path($scope.returnPath);
            };

            $scope.deleteButtonClicked = function() {
                commonService.askUserConfirmation("confirm.deletePlace", "confirm.title.deletePlace", function(buttonPressed) {
                    if (buttonPressed === 1) {
                        serverApiService.removePlace($scope.placeId, function(status) {
                            if (status === true) {
                                $location.path("/dashboard");
                            } else {
                                commonService.showMessageToUser("error.failedToDeletePlace", "error.title.error");
                            }
                        });
                    }
                }, "confirm.buttons.confirmCancel");
            };

            $scope.editButtonClicked = function() {
                localStorageService.setValue("addEditPlaceControllerReturnPath", $location.path());
                $location.path("/place/edit/" + $scope.placeId);
            };


            $scope.showOnMapButtonClicked = function() {
                if (!$scope.place) {
                    console.log("Current place is unknown");
                    return;
                }
                commonService.showLocationOnMap($scope.place);
            };

            $scope.getCSSForShape = function() {
                return $scope.place.type;
            };

            var calculateDistanceToPlace = function() {
                $scope.distanceFromUserToPlace = commonService.getDistanceText($scope.place, ringoAppService.getCurrentUserPositionFromDashboard());
            };

            var init = function() {
                var dashboard = ringoAppService.getDashboard();
                if (dashboard) {
                    $scope.userIsInThisPlace = (dashboard.places && dashboard.places.indexOf($scope.placeId) !== -1);
                    for(var placeId in dashboard.family.places) {
                        if (placeId === $scope.placeId) {
                            $scope.place = dashboard.family.places[placeId];
                            break;
                        }
                    }
                }

                calculateDistanceToPlace();
            };

            init();

            $scope.checkInOrOutClass = function() {
                if ($scope.userIsInThisPlace) {
                    return "icon-manual-checkout";
                } else {
                    return "icon-manual-checkin";
                }
            };

            $scope.manuallyCheckInOrOut = function() {
                if ($scope.userIsInThisPlace) {
                    serverApiService.manuallyCheckOutOfPlace($scope.placeId, function(status) {
                        ringoAppService.refreshDashboard();
                    });
                } else {
                    serverApiService.manuallyCheckInToPlace($scope.placeId, function(status) {
                        ringoAppService.refreshDashboard();
                    });
                }
            };

            $scope.$on('dashboardUpdated', function () {
                $scope.safeApply(function () {
                    init();
                });
            });


        }])
;

