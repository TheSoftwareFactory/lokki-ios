/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
        .controller("selectLanguageController",
                ["$scope", "$location", "localize", "commonService", "localStorageService", "serverApiService",
                function($scope, $location, localize, commonService, localStorageService, serverApiService) {
                    $scope.languages = commonService.allPossibleLanguages;
                    $scope.currentLanguageID = localStorageService.getLanguage();


                    $scope.returnPath = localStorageService.getValue("selectLanguageControllerReturnPath");
                    localStorageService.setValue("selectLanguageControllerReturnPath", undefined);

                    $scope.getLanguageName = function(langID) {
                        var name = commonService.getLanguageName(langID);
                        if (langID === $scope.currentLanguageID) {
                            name = "✓ " + name;
                        }
                        return name;
                    };

                    $scope.back = function() {
                        $location.path($scope.returnPath);
                    };

                    $scope.onLanguageClick = function(id) {
                        console.log("User selected language: " + id);
                        $scope.currentLanguageID = id;
                        localStorageService.setLanguage(id);
                        localize.setLanguage(id);

                        if (localStorageService.isUserLoggedIn()) {
                            var newLang = {language : id};
                            serverApiService.updateCurrentUserInfo(newLang, function(success) {
                                console.log("updateCurrentUserInfo: " + success);
                                if (success !== true) {
                                    commonService.showMessageToUser("error.failedToUpdateUserSettings", "error.title.error");
                                    return;
                                }
                            });
                        }
                    };


                }])
;