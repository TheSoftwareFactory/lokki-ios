/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 22.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
        .controller("loginFlowController",
            ["$scope", "$rootScope", "$location", "localStorageService", "serverApiService", "ringoAppService", "commonService", "validationService",
                function($scope, $rootScope, $location, localStorageService, serverApiService, ringoAppService, commonService, validationService) {

                    var that = this;
                    var platform = ((window.device) ? window.device.platform : "browser");
                    var version = ((window.device) ? window.device.version: "0.0");
                    var country = undefined;

                    $scope.returnPath = "/";// always get back to beginning of flow with back button
                    if ($location.path() === "/") {
                        $scope.returnPath = "";// nowhere to return
                    }

                    $scope.inUSA = false;
                    if (localStorageService.getValue("inUSA") !== undefined) {
                        $scope.inUSA = localStorageService.getValue("inUSA");
                    } else {
                        serverApiService.getCountry(function(status, country) {
                            if (status === true) {
                                console.log("Country: " + country);
                                $scope.safeApply(function() {
                                    $scope.inUSA = (country == "US");
                                    localStorageService.setValue("inUSA", $scope.inUSA);
                                });
                            } else {
                                console.log("Failed to query country");
                            }
                        });
                    }


                    $scope.startLoginFlow = function() {
                        $location.path("/login");
                    };

                    $scope.startSignupFlow = function() {
                        localStorageService.setValue("signupFlowMode", undefined);
                        $location.path("/signupEula");
                    };

                    $scope.userDeclinedEula = function() {
                        $location.path("/welcome");
                    };

                    $scope.userAcceptedEula = function() {
                        $location.path("/signupFlowSendCode");
                    };

                    $scope.goToStartOfFlow = function() {
                        $location.path("/");
                    };

                    $scope.goToUserDetails = function() {
                        $location.path("/signupFlowUserDetails");
                    };

                    $scope.onEulaClicked = function() {
                        $location.path("/privacyPolicy");
                    };

                    $scope.onForgotPassword = function() {
                        /*
                        var phoneNumber = validationService.validateAndConvertPhoneNumber($scope.userName);
                        if (phoneNumber === "") {
                            commonService.showMessageToUser("error.forgotPassword.definePhone", "error.title.error");
                            return;
                        }
                        */
                        var phoneNumber = getAndValidatePhoneNumber();
                        if (phoneNumber == "" || phoneNumber == undefined) return;

                        localStorageService.setUserName(phoneNumber);
                        localStorageService.setValue("newUserId", phoneNumber);

                        commonService.askUserConfirmation("confirm.forgotPassword", "confirm.title.confirm", function(buttonPressed) {
                            if (buttonPressed === 1) {
                                serverApiService.forgotPassword(phoneNumber, function(status) {
                                    if (status === true) {
                                        localStorageService.setValue("signupFlowMode", "forgotPassword");
                                        $location.path("/signupFlowEnterSMSConfirmation");
                                    } else if (status === 404) {
                                        commonService.showMessageToUser("error.forgotPasswordFailed.noUser", "error.title.error");
                                    } else {
                                        commonService.showMessageToUser("error.forgotPasswordFailed.generic", "error.title.error");
                                    }
                                });
                            }
                        }, "confirm.buttons.default");
                    };

                    $scope.init = function() {
                        // restore some data because controller gets deleted when we move between screens
                        $scope.newUserName = localStorageService.getValue("newUserName");
                        $scope.newUserAvatar = localStorageService.getValue("newUserIcon");
                        //$scope.phoneNumberForConfirmation = localStorageService.getValue("lastEnteredLoginUserId");

                        $rootScope.ringo.loggedIn = false;
                        $scope.loginStatus = "";
                        /*
                        if (localStorageService.getUserName()) {
                            $scope.userName = ("+" + localStorageService.getUserName());
                        }

                        $scope.disclaimer = "Note: this is not real login page but just a placeholder to set up test user name. Please set your user name once here.";
                        if ($scope.userName === undefined) {
                            $scope.userName = "";
                        } else {
                            //$scope.login();// try to login immediately
                        }
                        */
                    };

                    this.onSuccessfulLogin = function(userId) {
                        console.log("Logged in " + userId);
                        $rootScope.ringo.loggedIn = true;
                        $rootScope.ringo.userName = userId;
                        $location.path("/dashboard");
                        $scope.loginStatus = "";

                        // token may be obtained already on startup so register them after login/signup
                        var apnToken = localStorageService.getValue("remoteNotificationsDeviceTokenAPN");
                        var gcmToken = localStorageService.getValue("remoteNotificationsDeviceTokenGCM");
                        var wp8Token = localStorageService.getValue("remoteNotificationsDeviceTokenWP8");
                        if (apnToken !== undefined) {
                            serverApiService.registerForRemoteNotifications(apnToken, function(status) {
                                console.log("registerForRemoteNotifications returned " + status);
                            });
                        }
                        if (gcmToken !== undefined) {
                            serverApiService.registerForGCMRemoteNotifications(gcmToken, function(status) {
                                console.log("registerForGCMRemoteNotifications returned " + status);
                            });
                        }
                        if (wp8Token !== undefined) {
                            serverApiService.registerForWP8RemoteNotifications(wp8Token, function(status) {
                                console.log("registerForWP8RemoteNotifications returned " + status);
                            });
                        }

                        ringoAppService.startRemoteNotificationsIfEnabled();
                        ringoAppService.startGeoLocationTrackingIfEnabled();
                    };

                    // Login when user clicks 'login' or automatically when
                    // we have cached user credentials
                    $scope.onLogin = function() {

                        var phoneNumber = getAndValidatePhoneNumber();
                        if (phoneNumber == "" || phoneNumber == undefined) return;

                        if ($scope.userPassword == "" || $scope.userPassword == undefined || $scope.userPassword.length < 4) {
                            commonService.showMessageToUser("error.typePassword", "error.title.error");
                            return;
                        }
                        $scope.loginStatus = "Logging in " + phoneNumber;

                        localStorageService.setUserName(phoneNumber);
                        serverApiService.login(phoneNumber, $scope.userPassword, function(loginRetValue) {
                            if (loginRetValue === true) {
                                that.onSuccessfulLogin(phoneNumber);
                            } else {
                                commonService.showMessageToUser("error.loginFailed", "error.title.error");
                                $scope.loginStatus = loginRetValue;
                            }
                        });
                    };

                    // Get countryCode and phoneNumber from inputs, and validates them
                    var getAndValidatePhoneNumber = function() {
                        if ($scope.countryCode === "" || $scope.countryCode == undefined) {
                            commonService.showMessageToUser("error.selectCountry", "error.title.error");
                            return;
                        }
                        if ($scope.phoneNumberForConfirmation === "" || $scope.phoneNumberForConfirmation == undefined) {
                            commonService.showMessageToUser("error.typePhoneNumber", "error.title.error");
                            return;
                        }
                        var phoneNumber = $scope.phoneNumberForConfirmation;
                        if ($scope.phoneNumberForConfirmation.indexOf("0") == "0") {
                            phoneNumber = phoneNumber.slice(1,phoneNumber.length);
                        }
                        phoneNumber = $scope.countryCode + phoneNumber;
                        return phoneNumber;
                    };

                    // when user enters phone number and clicks "continue" we should send confirmation code to this phone
                    $scope.sendConfirmationCode = function() {

                        var phoneNumber = getAndValidatePhoneNumber();
                        if (phoneNumber == "" || phoneNumber == undefined) return;
                        alert("phoneNumber validated: " + phoneNumber);

                        serverApiService.requestSMSConfirmationCode(phoneNumber, function(smsRequestingStatus) {
                            if (smsRequestingStatus === 405) {
                                commonService.askUserConfirmation("confirm.userAlreadyRegistered.login", "confirm.title.login", function(buttonPressed) {
                                    if (buttonPressed === 1) {
                                        localStorageService.setUserName(phoneNumber);// to automaticaly fill user name
                                        $rootScope.safeApply(function(){
                                            $location.path("/login");
                                        });
                                    }
                                }, "confirm.buttons.loginCancel");
                            } else {
                                localStorageService.setValue("newUserId", phoneNumber);
                                $location.path("/signupFlowEnterSMSConfirmation");
                                if (smsRequestingStatus !== true) {
                                    console.log("SMS confirmation returned error: " + smsRequestingStatus);
                                }
                            }
                        });
                    };

                    $scope.sendAgainConfirmationCode = function() {
                        commonService.showMessageToUser("error.notImplementedYet", "error.title.error");
                    };

                    $scope.verifyConfirmationCode = function() {
                        if ($scope.pinCodeForConfirmation === undefined || $scope.pinCodeForConfirmation.length < 4) {
                            commonService.showMessageToUser("error.wrongConfirmationCode", "error.title.error");
                            return;
                        }
                        var userId = localStorageService.getValue("newUserId");
                        serverApiService.checkSMSConfirmationCode(userId, $scope.pinCodeForConfirmation, function(status) {
                            if (status === 200) {
                                localStorageService.setConfirmationCode($scope.pinCodeForConfirmation);
                                $location.path("/signupFlowUserDetails");
                            } else if (status === 404) { // Confirmation code not found (expired or never created)
                                commonService.showMessageToUser("error.confirmationCodeNotFound", "error.title.error");
                            } else {
                                commonService.showMessageToUser("error.confirmationCodeIsIncorrect", "error.title.error");
                            }
                        });
                    };

                    $scope.setUserDetails = function() {
                        var verifyResult = that._verifyUserDetails();
                        if (verifyResult !== true) {
                            commonService.showMessageToUser(verifyResult, "error.title.error");
                            return;
                        }
                        localStorageService.setValue("newUserPassword", $scope.newUserPassword1);
                        localStorageService.setValue("newUserName", $scope.newUserName);
                        $scope.newUserAvatar = "images/defaultAvatar.png";
                        localStorageService.setValue("newUserIcon", $scope.newUserAvatar);// set default icon

                        if (localStorageService.getValue("signupFlowMode") === "forgotPassword") {
                            $scope.finishSignUp();// we should not change icon in forgot password flow
                        } else {
                            $location.path("/signupFlowCreateUserAvatar");
                        }
                    };

                    $scope.setAvatar = function() {
                        localStorageService.setValue("changeAvatarControllerReturnPath", "/signupFlowCreateUserAvatar");
                        $location.path("/changeAvatar");
                    };


                    // entire signup flow ends up here
                    $scope.finishSignUp = function() {
                        var userObj = {
                            name: localStorageService.getValue("newUserName"),
                            icon: localStorageService.getValue("newUserIcon"),
                            password:  localStorageService.getValue("newUserPassword"),
                            smsConfirmationCode: localStorageService.getConfirmationCode(),
                            language: localStorageService.getLanguage()
                        };

                        var newAvatar = localStorageService.getValue("newUserAvatarData");
                        //console.log("Avatar data: " + newAvatar);

                        if (localStorageService.getValue("signupFlowMode") === "forgotPassword") {
                            newAvatar = undefined;
                            delete userObj.icon;
                        }

                        serverApiService.createUser(localStorageService.getValue("newUserId"), userObj, function(status) {
                            if (status === true) {
                                localStorageService.setUserName(localStorageService.getValue("newUserId"));// remember who is logged in
                                localStorageService.setValue("newUserPassword", undefined);// remove copy of password
                                if (newAvatar) {
                                    serverApiService.uploadNewAvatar(newAvatar, function(avatarUploadStatus) {
                                        console.log("uploadNewAvatar returned: " + avatarUploadStatus);
                                        localStorageService.setValue("newUserAvatarData", undefined);// clear cached avatar

                                        that.onSuccessfulLogin(localStorageService.getValue("newUserId"));
                                    })
                                } else {
                                    that.onSuccessfulLogin(localStorageService.getValue("newUserId"));
                                }
                            } else {
                                commonService.showMessageToUser("error.signupError", "error.title.error");
                            }
                        });
                    };

                    // returns true if user details are correct for user signup details page
                    this._verifyUserDetails = function() {
                        if ($scope.newUserPassword1 === undefined || $scope.newUserPassword1.length < 6) {
                            return "error.tooShortPassword";
                        }
                        if ($scope.newUserPassword1 !== $scope.newUserPassword2) {
                            return "error.passwordsDontMatch";
                        }

                        if ($scope.newUserName === undefined || $scope.newUserName.length < 1) {
                            return "error.nameIsMissing";
                        }
                        return true;
                    };

                    $scope.changeLanguage = function() {
                        localStorageService.setValue("selectLanguageControllerReturnPath", "/welcome");
                        $location.path("/selectLanguage");
                    };

                    $scope.enterVerificationCode = function() {
                        $location.path("/signupFlowEnterSMSConfirmation");
                    };

                    $scope.problemsSigningUp = function() {
                        // Send email
                        $scope.onContactDevelopersClick();
                    };

                    var getDeviceDetails = function() {
                        var details = "[" + platform + version + "/";
                        details += commonService.version + "/";
                        details += localStorageService.getLanguage();
                        if (country) {
                            details += "/" + country;
                        }

                        details += "]";
                        return details;
                    };

                    $scope.onContactDevelopersClick = function() {
                        var address = "lokki-feedback@f-secure.com";
                        var subject = commonService.getLocalizedString("dashboard.sendFeedback.subject");
                        subject += " " + getDeviceDetails();
                        var body = commonService.getLocalizedString("dashboard.sendFeedback.body");

                        commonService.openEmailApp(address, subject, body);
                    };

                    var readNewAvatarOnReturnFromChangeAvatarPage = function() {
                        var imgData = localStorageService.getValue("changeAvatarControllerImageData");
                        if (imgData) {
                            localStorageService.setValue("changeAvatarControllerImageData", undefined);
                            localStorageService.setValue("newUserAvatarData", imgData);
                            $scope.safeApply(function() {
                                $scope.newAvatarImageData = imgData;
                            });
                        } else {
                            var savedImgData = localStorageService.getValue("newUserAvatarData");
                            if (savedImgData) {
                                $scope.safeApply(function() {
                                    $scope.newAvatarImageData = savedImgData;
                                });
                            }
                        }
                    };

                    readNewAvatarOnReturnFromChangeAvatarPage();

                    $scope.init();


        }])
;