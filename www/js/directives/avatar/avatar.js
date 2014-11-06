/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 13.08.2013 16:21
 */

'use strict';
angular.module("ringo.directives")
        .directive('fsAvatar', function () {

            var getMemberFadeCSSClass = function(member) {
                var curTime = Date.now();
                var minutes = (curTime - member.lastReport) / 1000 / 60;
                if (member.lastReport === 0 || member.lastReport === undefined) {
                    return "fade-100-percent";// not reported yet
                }
                if (minutes < 60) {
                    return "";
                }
                if (minutes < 60 * 4) {
                    return "fade-25-percent";
                }
                if (minutes < 60 * 8) {
                    return "fade-50-percent";
                }
                if (minutes < 60 * 16) {
                    return "fade-75-percent";
                }
                return "fade-100-percent";
            };

            var cssClassForAvatarHalo = function(member, fadeIcon){
                var cssClass = '';
                if(fadeIcon){
                    cssClass = getMemberFadeCSSClass(member);
                }
                if(member.isCurrentUser){
                    return cssClass + " yourself";
                }
                if (member.isFriend) {
                    return "friend";//friends don't fade
                }
                return cssClass;
            };

            return {
                restrict: 'E',
                replace: false,
                //transclude: true,
                templateUrl: 'js/directives/avatar/avatarTemplate.html',
                scope: {
                    person: '=',
                    onClick: '&',
                    fadeIcon: '='
                },
                controller: function($scope, $element, $attrs, $transclude){
                    $scope.onClickHandler = $scope.onClick;
                },
                link: function ($scope, $element, $attrs) {
                    $scope.showBadge = $scope.person.newMessages > 0;

                    $scope.badAccuracyIconClass = "";
                    if ($scope.person.lastAccuracy) {
                        var acc = +$scope.person.lastAccuracy;
                        if (acc > 200) {
                            $scope.badAccuracyIconClass = "icon-accuracy-very-bad";
                        } else if (acc > 80) {
                            $scope.badAccuracyIconClass = "icon-accuracy-bad";
                        }
                    }
                    var fadeIcon = true;
                    if($attrs.fadeIcon === 'false'){
                        fadeIcon = false;
                    }
                    $scope.haloClass = cssClassForAvatarHalo($scope.person, fadeIcon);


                }

            };


        });