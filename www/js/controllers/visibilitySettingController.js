'use strict';

angular.module("ringo.controllers")
        .controller("visibilitySettingController",
                ["$scope", "$location",
                    function($scope, $location) {
                        /*
                        $scope.returnPath = "/dashboard";
                        $scope.back = function(){
                            $location.path($scope.returnPath);
                        };
                        */

                        $scope.setVisibility = function(mode){
                            alert("visibility set to mode: "+ mode);
                        }
                    }
                ]);