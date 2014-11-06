/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Miguel Rodriguez
 */
'use strict';

angular.module("ringo.controllers")
        .controller("npsController", ["$scope", "$location", "serverApiService", "commonService",
        function($scope, $location, serverApiService, commonService){

            $scope.scores = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
            $scope.returnPath = "/settings";

            $scope.backButtonClicked = function() {
                $location.path($scope.returnPath);
            };

            $scope.setScore = function(score) {
                $scope.selectedScore = score;
            };

            $scope.getCSSForScore = function(score) {
                if ($scope.selectedScore === score) {
                    return 'selectedScore';
                }
                else return '';
            };

            $scope.send = function(score) {
                if ($scope.selectedScore === undefined) {
                    commonService.showMessageToUser("message.npsPleaseSelectScore", "message.title.message");
                    return;
                }

                var data = {'score': $scope.selectedScore, 'comments': $scope.comments};

                serverApiService.nps(data, function(error, result) {
                    if (error) {
                        commonService.showMessageToUser("error.npsSendFailed", "error.title.error");
                    }
                    else {
                        commonService.showMessageToUser("message.npsSendSucceeded", "message.title.message");
                        $location.path("/dashboard");
                    }
                });
            };

            $scope.askMeLater = function(score) {
                commonService.showMessageToUser("message.npsWillAskLater", "message.title.message");
                $location.path("/dashboard");
            };

            $scope.neverAskMeAgain = function(score) {
                commonService.showMessageToUser("message.npsWillNeverAskAgain", "message.title.message");
                $location.path("/dashboard");
            };

        }])
;

