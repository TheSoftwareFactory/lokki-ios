/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
    .controller("aboutController",
        ["$scope", "$location", "commonService", function($scope, $location, commonService) {
            $scope.version = commonService.version;

            $scope.returnPath = "/settings";

            $scope.back = function() {
                $location.path($scope.returnPath);
            };

            $scope.openLink = function(url){
                window.open(url, "_system");
                return false;
            }


        }]);