/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
    .controller("tellFriendViaController",
        ["$scope", "$location", "localStorageService", "commonService", function($scope, $location, localStorageService, commonService) {

            $scope.returnPath = localStorageService.getValue("tellFriendViaControllerReturnPath");
            localStorageService.setValue("tellFriendViaControllerReturnPath", undefined);

            $scope.canSendSMS = (window.plugins && window.plugins.smsComposer !== undefined);
            $scope.isUsingFacebookAPI = (!!window.FB && !!window.CDV);
            
            $scope.back = function() {
                $location.path($scope.returnPath);
            };


            $scope.sendEMail = function() {
                commonService.openEmailApp("", commonService.getLocalizedString("tellFriendVia.emailSubject"), commonService.getLocalizedString("tellFriendVia.message"));
            };

            $scope._shareLokkiOnFacebook = function() {
                var params = {
                    method: 'apprequests',
                    to: "",
                    title: commonService.getLocalizedString("invite.facebook.header"),
                    message: commonService.getLocalizedString("tellFriendVia.message")
                };
                FB.ui(params, function(obj) {
                    console.log("FB.ui returned: " + JSON.stringify(obj));
                });
            };

            $scope.shareOnFacebook = function () {

                if (typeof CDV == 'undefined') console.log('CDV variable does not exist');
                if (typeof FB == 'undefined') console.log('FB variable does not exist. Check that you have included the Facebook JS SDK file.');

                if (!FB) {
                    return;
                }

                FB.getLoginStatus(function(response) {
                    if (response.authResponse) {
                        console.log('FB response: ' + JSON.stringify(response));
                        if (response.status === 'connected') {
                            $scope._shareLokkiOnFacebook();
                        }
                    } else {
                        // the user isn't even logged in to Facebook.
                        FB.login(
                            function(response) {
                                console.log("FB login returned: " + JSON.stringify(response));
                                if (response.authResponse) {
                                    $scope._shareLokkiOnFacebook();
                                } else {
                                    console.log('not logged in');
                                }
                            },
                            { scope: "email" }
                        );
                    }
                });
            };


            $scope.sendSMS = function() {

                if (window.plugins.smsComposer) {
                    window.plugins.smsComposer.showSMSComposerWithCB(function(err) {
                            console.log("showSMSComposer returned with: " + JSON.stringify(err));
                        },
                        "",
                        commonService.getLocalizedString("tellFriendVia.message")
                    );
                }

            };


        }]);