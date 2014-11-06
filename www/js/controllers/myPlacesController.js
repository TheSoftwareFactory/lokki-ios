/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 23.07.2013 13:9
 */

'use strict';

angular.module("ringo.controllers")
        .controller("myPlacesController",
                ["$scope", "$location", "ringoAppService", "localStorageService",
                    function($scope, $location, ringoAppService, localStorageService) {
                        $scope.returnPath = "/settings";
                        $scope.back = function(){
                            $location.path($scope.returnPath);
                        };

                        var dashboard = ringoAppService.getDashboard();

                        if (dashboard !== undefined || dashboard.family !== undefined) {
                            $scope.places = dashboard.family.places;
                        }

                        $scope.onPlaceClick = function(place) {
                            localStorageService.setValue("placeDetailsControllerReturnPath", "/myPlaces");
                            $location.path("/placeDetails/" + place.name);
                        };

                        $scope.addNewPlace = function(){
                            localStorageService.setValue("addEditPlaceControllerReturnPath", "/myPlaces");
                            $location.path('/place/new');
                        }

                    }
                ]);