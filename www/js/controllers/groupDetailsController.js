'use strict';

angular.module("ringo.controllers")
    .controller("groupDetailsController",
        ["$scope", "$location", "$window", "$routeParams", "serverApiService", "ringoAppService", "messagesCacheService", "localStorageService", "commonService",
            function($scope, $location, $window, $routeParams, serverApiService, ringoAppService, messagesCacheService, localStorageService, commonService) {

            $scope.leaveGroupOptions = false;
            $scope.nameEditorEnabled = false;

            if (!$scope.returnPath) {
                $scope.returnPath = "/dashboard";
            }

            $scope.back = function() {
                $location.path($scope.returnPath);
            };

            var getGroupInfo = function() {
                $scope.group = {name: "Familia", numberOfMembers: 2, numberOfPlaces: 5};
            };

            $scope.pingButtonClicked = function() {
                $location.path('/chat/family');
            };

            $scope.createPlaceClicked = function() {
                $location.path('/place/new');
            };

            $scope.leaveGroupClicked = function() {
                $scope.nameEditorEnabled = false;
                $scope.leaveGroupOptions = !$scope.leaveGroupOptions;
            };

            $scope.leaveGroupOKClicked = function() {
                // TODO: Leave group
                $location.path('/dashboard');
            };

            $scope.leaveGroupCancelClicked = function() {
                $scope.leaveGroupClicked();
            };

            $scope.editButtonClicked = function() {
                $scope.leaveGroupOptions = false;
                $scope.nameEditorEnabled = !$scope.nameEditorEnabled;
            };

            $scope.onFinishChangingName = function() {
                $scope.nameEditorEnabled = false;
            };


            getGroupInfo();
        }]);