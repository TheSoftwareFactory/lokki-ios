/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 19.06.2013 12:40
 */

'use strict';

angular.module("ringo.controllers")
        .controller("locationSettingsController",
                ["$scope", "$routeParams", "$location", "ringoAppService", "serverApiService", "commonService", "localStorageService",
                    function($scope, $routeParams, $location, ringoAppService, serverApiService, commonService, localStorageService) {

                    $scope.userId = $routeParams.userId;
                    $scope.returnPath = localStorageService.getValue("locationSettingsControllerReturnPath");
                    localStorageService.setValue("locationSettingsControllerReturnPath", undefined);
                    if (!$scope.returnPath) {
                        $scope.returnPath = "/mySettings";
                    }

                    var allSettingsEnter = true;
                    var allSettingsExit = true;

                    /* Example
                    var settings = {
                        enabled: true,
                        perPlace: {
                            home: {
                                enter: true,
                                leave: false
                            }
                        }
                    };
                    It then goes into:
                    dashboard.settings.peopleNotifications[$scope.userId]
                    */

                    ($scope.readPlacesFromDashboard = function() {
                        if (ringoAppService.getDashboard() === undefined || ringoAppService.getDashboard().places === undefined) {
                            return;
                        }
                        var dashboard = ringoAppService.getDashboard();

                        $scope.places = dashboard.family.places;
                        if (dashboard.settings && dashboard.settings.peopleNotifications && dashboard.settings.peopleNotifications[$scope.userId]) {
                            $scope.settings = dashboard.settings.peopleNotifications[$scope.userId];
                        } else {
                            $scope.settings = {enabled: false};
                        }
                        if (!$scope.settings.perPlace) {
                            $scope.settings.perPlace = {};
                        }
                    })();

                    $scope.back = function() {
                        $location.path($scope.returnPath);
                    };

                    $scope.changeEnabledCheckbox = function(key){
                        $scope.settings.enabled = !$scope.settings.enabled;
                        $scope.onSettingChange();
                    };

                    // change all enter place settings at once
                    $scope.changeAllEnterPlaces = function() {
                        for(var placeId in $scope.places) {
                            if ($scope.places.hasOwnProperty(placeId)) {
                                if ($scope.settings.perPlace[placeId]) {
                                    $scope.settings.perPlace[placeId].enter = allSettingsEnter;
                                } else {
                                    $scope.settings.perPlace[placeId] = {enter:allSettingsEnter};
                                }
                            }
                        }
                        allSettingsEnter = !allSettingsEnter;
                        $scope.onSettingChange();
                    };

                    // change all exit place settings at once
                    $scope.changeAllExitPlaces = function() {
                        for(var placeId in $scope.places) {
                            if ($scope.places.hasOwnProperty(placeId)) {
                                if ($scope.settings.perPlace[placeId]) {
                                    $scope.settings.perPlace[placeId].leave = allSettingsExit;
                                } else {
                                    $scope.settings.perPlace[placeId] = {leave:allSettingsExit};
                                }
                            }
                        }
                        allSettingsExit = !allSettingsExit;
                        $scope.onSettingChange();
                    };

                    $scope.changeCheckboxArrival = function(placeName){
                        if(!$scope.settings.perPlace[placeName]){
                            $scope.settings.perPlace[placeName] = {
                                enter : true,
                                leave : false
                            }
                        } else {
                            $scope.settings.perPlace[placeName].enter = !$scope.settings.perPlace[placeName].enter;
                        }
                        $scope.onSettingChange();
                    };

                    $scope.changeCheckboxDeparture = function(placeName){
                        if(!$scope.settings.perPlace[placeName]){
                            $scope.settings.perPlace[placeName] = {
                                enter : false,
                                leave : true
                            }
                        } else {
                            $scope.settings.perPlace[placeName].leave = !$scope.settings.perPlace[placeName].leave;
                        }
                        $scope.onSettingChange();
                    };

                    $scope.onSettingChange = function() {
                        var newSettings = {peopleNotifications : {}};
                        newSettings.peopleNotifications[$scope.userId] = $scope.settings;
                        //console.log("New settings: " + JSON.stringify(newSettings));
                        serverApiService.updateCurrentUserInfo({settings: newSettings}, function(success) {
                            console.log("updateCurrentUserInfo: " + success);
                            if (success !== true) {
                                commonService.showMessageToUser("error.failedToUpdateUserSettings", "error.title.error");
                                return;
                            }
                        });

                    }


                }])
;