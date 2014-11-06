/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 30.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
        .controller("privacyPolicyController", ["$scope", "$location", function($scope, $location){
            $scope.returnPath = "/signupEula";
            $scope.backButtonClicked = function() {
                $location.path($scope.returnPath);
            };

        }])
;

