'use strict';

angular.module("ringo.controllers")
    .controller("notificationsPanelController",
        ["$scope", "$location", "$window", "$routeParams", "serverApiService", "ringoAppService", "messagesCacheService", "localStorageService", "commonService",
            function($scope, $location, $window, $routeParams, serverApiService, ringoAppService, messagesCacheService, localStorageService, commonService) {

            if (!$scope.returnPath) {
                $scope.returnPath = "/dashboard";
            }
            $scope.back = function() {

                $location.path($scope.returnPath);
            };

            var getNotifications = function() {

                $scope.notifications = [{message: "Julia (Family) entered Home", date: "2013-11-01 15:03", type: "alert", icon: "images/icons/icon_chat.png"},
                                        {message: "Harri (Family) entered Work", date: "2013-11-01 15:21", type: "alert", icon: "images/icons/icon_chat.png"},
                                        {message: "You have been invited to join Lokki group", date: "2013-11-01 16:56", type: "invitation", icon: "images/icons/icon_chat.png"},
                                       ];
            };

            getNotifications();
        }]);