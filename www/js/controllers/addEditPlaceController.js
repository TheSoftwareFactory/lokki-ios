/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 30.04.2013 13:18
 */

'use strict';

//$routeProvider.when('/place/new'
//$routeProvider.when('/place/createInUserLocation/:userId'
//$routeProvider.when('/place/edit/:placeId'

angular.module("ringo.controllers")
        .controller("addEditPlaceController", ["$scope", "$location", "$routeParams", "serverApiService", "ringoAppService", "commonService", "localStorageService",
            function($scope, $location, $routeParams, serverApiService, ringoAppService, commonService, localStorageService){

                $scope.canCreatePlaceOnMap = false;
                var platform = ((window.device) ? window.device.platform : "browser");
//                if (platform === "iOS" || platform === "browser") {
                    $scope.canCreatePlaceOnMap = true;
  //              }


                $scope.isAdd = ($routeParams.placeId === undefined);// add place or edit place
                $scope.selectingMode = $scope.isAdd;// first show select mode buttons if create place

                $scope.userFromWhomToTakeLocation = ($routeParams.userId || ringoAppService.getLoggedInUserId());// userId whose location to use when create new place
                $scope.nameOfUserFromWhomToTakeLocation = ringoAppService.getUserName($scope.userFromWhomToTakeLocation);

                $scope.createPlaceInLoggedInUserLocation = ($scope.userFromWhomToTakeLocation === ringoAppService.getLoggedInUserId());
                $scope.createPlaceInOtherUserLocation = !$scope.createPlaceInLoggedInUserLocation;
                $scope.createPlaceInAddress = false;

                $scope.shapes = commonService.allPossiblePlaceShapes;

                $scope.returnPath = localStorageService.getValue("addEditPlaceControllerReturnPath");
                localStorageService.setValue("addEditPlaceControllerReturnPath", undefined);
                if (!$scope.returnPath) {
                    $scope.returnPath = "/dashboard";
                }

                // location where user currently is (user around whom we create location)
                $scope.userLocation = ringoAppService.getUserPositionFromDashboard($scope.userFromWhomToTakeLocation);

                var sizeText = [
                    "createPlace.size.30",
                    "createPlace.size.60",
                    "createPlace.size.100",
                    "createPlace.size.150",
                    "createPlace.size.200",
                    "createPlace.size.500",
                    "createPlace.size.1000",
                    "createPlace.size.3000",
                    "createPlace.size.10000"];
                var sizeInMeters = [30, 60, 100, 150, 200, 500, 1000, 3000, 10000];
                $scope.currentSizeText = sizeText[4];//200 m by default
                $scope.place = {
                    radius : sizeInMeters[4],
                    type   : $scope.shapes[0]
                };

                $scope.onCreatePlaceInUserLocationSelected = function() {
                    $scope.createPlaceInAddress = false;
                    $scope.selectingMode = false;
                };

                $scope.onCreatePlaceInAddressSelected = function() {
                    $scope.createPlaceInLoggedInUserLocation = false;
                    $scope.createPlaceInOtherUserLocation = false;
                    $scope.createPlaceInAddress = true;
                    $scope.selectingMode = false;
                };

                $scope.onCreatePlaceOnMapSelected = function() {
                    $scope.createPlaceInAddress = false;
                    $scope.selectingMode = false;
                    $scope.userFromWhomToTakeLocation = ringoAppService.getLoggedInUserId();// always start on map from our location
                    $scope.userLocation = ringoAppService.getUserPositionFromDashboard($scope.userFromWhomToTakeLocation);
                    $scope.showOnMap();
                };


                var init = function(isAdd) {

                    var place = {};
                    /*
                     var place = {
                     name: $scope.place.name,
                     type: $scope.place.type,
                     lat:  loc.lat,
                     lon:  loc.lon,
                     radius: $scope.place.radius
                     };
                     */

                    if(!isAdd) {
                        $scope.placeId = $routeParams.placeId;
                        var dashboard = ringoAppService.getDashboard();
                        if (dashboard) {
                            for(var placeId in dashboard.family.places) {
                                if (placeId === $scope.placeId) {
                                    $scope.place = JSON.parse(JSON.stringify(dashboard.family.places[placeId])); // do copy
                                    $scope.userLocation = {
                                        lat: $scope.place.lat,
                                        lon: $scope.place.lon
                                    };
                                    //find out size
                                    var idx = sizeInMeters.indexOf($scope.place.radius);
                                    if (idx !== -1) {
                                        $scope.currentSizeText = sizeText[idx];
                                        $scope.place.radius = sizeInMeters[idx];
                                    } else {
                                        $scope.place.radius = sizeInMeters[4];// return to default if unknown
                                    }
                                    break;
                                }
                            }
                        }
                    }
                };

                init($scope.isAdd);

                $scope._addPlace = function(loc) {
                    var place = {
                        name: $scope.place.name,
                        type: $scope.place.type,
                        lat:  loc.lat,
                        lon:  loc.lon,
                        radius: $scope.place.radius
                    };

                    if ($scope.isAdd) {
                        var placeToRemove = place.name;
                        serverApiService.removePlace(placeToRemove, function(status) {
                            serverApiService.addPlace(place, $scope.onAddPlaceFinished);
                        });
                    } else {
                        serverApiService.editPlace($routeParams.placeId, place, $scope.onAddPlaceFinished);
                    }
                };


                $scope.addPlace = function() {
                    var loc = $scope.getLocation();
                    if (!loc) {
                        console.log("Location is unknown!");
                        return;
                    }

                    if ($scope.isAdd) {
                        if ((loc.lat === "0" && loc.lon === "0") || (loc.lat === 0 && loc.lon === 0)) {
                            if ($scope.createPlaceInLoggedInUserLocation) {
                                commonService.showMessageToUser("error.yourLocationUnknown", "error.title.error");
                            } else {
                                commonService.showMessageToUser("error.otherUserLocationUnknown", "error.title.error");
                            }
                            return;
                        }
                    }

                    // warn about location reports which are old
                    var curTime = Date.now();
                    var secondsSinceReport = (curTime - loc.time)/1000;
                    var accuracyIsBad = (loc.acc > 100);
                    if ($scope.isAdd && (secondsSinceReport > 60*10 || accuracyIsBad)) {

                        commonService.askUserConfirmation((accuracyIsBad)?"confirm.createPlaceWhenAccuracyIsBad":"confirm.createPlaceWhenlocationReportIsOld", "confirm.title.confirm", function(buttonPressed) {
                            if (buttonPressed === 1) {
                                $scope._addPlace(loc);
                            }
                        }, "confirm.buttons.confirmCancel");

                    } else {
                        $scope._addPlace(loc);
                    }

                };

                $scope.onAddPlaceFinished = function(status, text) {
                    console.log("Adding/editing place finished with: " + status + ", " + text);
                    if (status !== true) {
                        $scope.errorMessage = text;
                        if (status === serverApiService.errorCodes.FAMILY_PLACE_LIMIT) {
                            commonService.showMessageToUser("error.placeLimit", "error.title.limit");
                        } else if (status === serverApiService.errorCodes.PLACE_ALREADY_ADDED_TO_FAMILY) {
                            commonService.showMessageToUser("error.placeWithThisNameAlreadyExists", "error.title.limit");
                        } else {
                            commonService.showMessageToUser("error.creatingPlaceFailed", "error.title.limit");
                        }
                    } else {
                        $location.path("/dashboard");
                    }
                };

                $scope.getLocation = function() {
                    if ($scope.locationFromAddressData) {
                        return {
                            lat: $scope.locationFromAddressData.lat,
                            lon: $scope.locationFromAddressData.lon,
                            acc: 10,
                            time: Date.now()
                        }
                    }
                    if($scope.isAdd) {
                        return $scope.userLocation;
                    } else {
                        return {
                            lat: $scope.place.lat,
                            lon: $scope.place.lon,
                            acc: 10,
                            time: Date.now()
                        };
                    }
                };

                var editPlaceOnMapFinished = function(newLocation) {
                    if (!newLocation) {
                        console.log("newLocation is undefined");
                        return;
                    }

                    if (newLocation.radius) {
                        $scope.place.radius = newLocation.radius;
                    }
                    if (newLocation.lat && newLocation.lon) {
                        $scope.place.lat = newLocation.lat;
                        $scope.place.lon = newLocation.lon;

                        if ($scope.locationFromAddressData) {
                            $scope.locationFromAddressData.lon = newLocation.lon;
                            $scope.locationFromAddressData.lat = newLocation.lat;
                        }
                        if ($scope.userLocation) {
                            $scope.userLocation.lat = newLocation.lat;
                            $scope.userLocation.lon = newLocation.lon;
                        }
                    }
                };

                $scope.showOnMap = function() {
                    if (!$scope.getLocation()) {
                        console.log("Current position is unknown");
                        return;
                    }
                    var location = JSON.parse(JSON.stringify($scope.getLocation()));
                    location.radius = $scope.place.radius;
                    if ($scope.place.name) {
                        location.name = $scope.place.name;
                    } else {
                        location.name = " ";
                    }
                    location.editable = true;

                    commonService.showLocationOnMap(location, editPlaceOnMapFinished);
                };


                $scope.backButtonClicked = function() {
                    $location.path($scope.returnPath);
                };

                $scope.shapeSelected = function(shape) {
                    $scope.place.type = shape;
                };

                $scope.getCSSForShape = function(shape) {
                    if ($scope.place.type === shape) {
                        return shape + " selected";
                    }
                    return shape;
                };

                // iterate through sizes
                $scope.onSizeClicked = function() {
                    var idx = sizeText.indexOf($scope.currentSizeText);
                    ++idx;
                    if (idx >= sizeText.length) {
                        idx = 0;
                    }
                    $scope.currentSizeText = sizeText[idx];
                    $scope.place.radius = sizeInMeters[idx];
                };

                $scope.locationFromAddressChanged = function() {
                    $scope.locationFromAddressNotFound = false;
                    $scope.locationFromAddressSucceeded = false;
                    $scope.locationFromAddressData = undefined;
                    if ($scope.locationFromAddressChangedTimer !== undefined) {
                        clearTimeout($scope.locationFromAddressChangedTimer);
                    }

                    $scope.locationFromAddressChangedTimer = setTimeout(function() {
                        $scope.locationFromAddressChangedTimer = undefined;
                        $scope._onLocationFromAddressChanged()
                    }, 2000);
                };


                $scope._onLocationFromAddressChanged = function() {
                    if ($scope.locationFromAddress && $scope.locationFromAddress !== "") {
                        console.log("Searching for location: " + $scope.locationFromAddress);
                        serverApiService.searchForAddressLocation($scope.locationFromAddress, function(success, location) {
                            $scope.safeApply(function() {
                                if (success) {
                                    $scope.locationFromAddressSucceeded = true;
                                    $scope.locationFromAddressData = location;
                                } else {
                                    $scope.locationFromAddressData = undefined;
                                    $scope.locationFromAddressNotFound = true;
                                }
                            });
                        });
                    }
                };

                // return "with-one-button" if save/add button is visible and "" if not
                $scope.contentClass = function() {
                    if ($scope.selectingMode) {
                        return "";
                    }
                    if ($scope.userLocation && $scope.place.name && !$scope.isAdd) {
                        return "with-one-button";
                    }

                    if ($scope.isAdd && $scope.place.name) {
                        if (!$scope.createPlaceInAddress && $scope.userLocation) {
                            return "with-one-button";
                        }
                        if ($scope.createPlaceInAddress && $scope.locationFromAddressSucceeded) {
                            return "with-one-button";
                        }
                    }
                    return "";
                };

                // refresh dashboard when we create place to get latest position
                // for instance, in Android we don't report position to App so it may be not in sync
                if ($scope.isAdd) {
                    ringoAppService.refreshDashboard();
                }

            }])
;

