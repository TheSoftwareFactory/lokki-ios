 /*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 22.04.2013 13:18
 */

'use strict';

angular.module("ringo", ["ringo.controllers", "ringo.services"]).
        config(["$routeProvider", function($routeProvider){
            console.log("angular.config");

            $routeProvider.when('/dashboard', {
                templateUrl: 'partials/dashboard.html',
                controller: 'dashboardController'
            });

            $routeProvider.when('/notifications', {
                templateUrl: 'partials/notificationsPanel.html',
                controller: 'notificationsPanelController'
            });

            $routeProvider.when('/groupDetails', {
                templateUrl: 'partials/groupDetails.html',
                controller: 'groupDetailsController'
            });

            $routeProvider.when('/familyMemberDetails/:userId', {
                templateUrl: 'partials/familyMemberDetails.html',
                controller: 'familyMemberDetailsController'
            });

            $routeProvider.when('/friendDetails/:userId', {
                templateUrl: 'partials/friendDetails.html',
                controller: 'friendDetailsController'
            });

            $routeProvider.when('/placeDetails/:placeId', {
                templateUrl: 'partials/placeDetails.html',
                controller: 'placeDetailsController'
            });

            $routeProvider.when('/inviteFamilyMember', {
                templateUrl: 'partials/inviteFamilyMember.html',
                controller: 'inviteFamilyMemberController'
            });

            $routeProvider.when('/inviteFriend', {
                templateUrl: 'partials/inviteFamilyMember.html',
                controller: 'inviteFamilyMemberController'
            });


            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // NPS
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            $routeProvider.when('/nps', {
                templateUrl: 'partials/nps.html',
                controller: 'npsController'
            });

            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            // Login flow
            ////////////////////////////////////////////////////////////////////////////////////////////////////////////
            $routeProvider.when('/welcome', {
                templateUrl: 'partials/welcome.html',
                controller: 'loginFlowController'
            });

            $routeProvider.when('/signupEula', {
                templateUrl: 'partials/signupEula.html',
                controller: 'loginFlowController'
            });

            $routeProvider.when('/login', {
                templateUrl: 'partials/login.html',
                controller: 'loginFlowController'
            });


            $routeProvider.when('/', {
                templateUrl: 'partials/welcome.html',
                controller: 'loginFlowController'
            });

            $routeProvider.when('/signupFlowSendCode', {
                templateUrl: 'partials/signupFlowSendCode.html',
                controller: 'loginFlowController'
            });

            $routeProvider.when('/signupFlowEnterSMSConfirmation', {
                templateUrl: 'partials/signupFlowEnterSMSConfirmation.html',
                controller: 'loginFlowController'
            });

            $routeProvider.when('/signupFlowUserDetails', {
                templateUrl: 'partials/signupFlowUserDetails.html',
                controller: 'loginFlowController'
            });

            $routeProvider.when('/signupFlowCreateUserAvatar', {
                templateUrl: 'partials/signupFlowCreateUserAvatar.html',
                controller: 'loginFlowController'
            });


            $routeProvider.when('/changeAvatar', {
                templateUrl: 'partials/changeAvatar.html',
                controller: 'changeAvatarController'
            });


            $routeProvider.when('/joinFamily', {
                templateUrl: 'partials/joinFamily.html',
                controller: 'joinFamilyController'
            });

            $routeProvider.when('/place/new', {
                templateUrl: 'partials/addEditPlace.html',
                controller: 'addEditPlaceController'
            });

            $routeProvider.when('/place/createInUserLocation/:userId', {
                templateUrl: 'partials/addEditPlace.html',
                controller: 'addEditPlaceController'
            });

            $routeProvider.when('/place/edit/:placeId', {
                templateUrl: 'partials/addEditPlace.html',
                controller: 'addEditPlaceController'
            });


            $routeProvider.when('/mySettings', {
                templateUrl: 'partials/mySettings.html',
                controller: 'mySettingsController'
            });

            $routeProvider.when('/myPlaces', {
                templateUrl: 'partials/myPlaces.html',
                controller: 'myPlacesController'
            });

            $routeProvider.when('/myFamily', {
                templateUrl: 'partials/myFamily.html',
                controller: 'myFamilyController'
            });

            $routeProvider.when('/myFriends', {
                templateUrl: 'partials/myFriends.html',
                controller: 'myFriendsController'
            });

            $routeProvider.when('/locationSettings/:userId', {
                templateUrl: 'partials/locationSettings.html',
                controller: 'locationSettingsController'
            });

            $routeProvider.when('/privacyPolicy', {
                templateUrl: 'partials/privacyPolicy.html',
                controller: 'privacyPolicyController'
            });

            $routeProvider.when('/selectLanguage', {
                templateUrl: 'partials/selectLanguage.html',
                controller: 'selectLanguageController'
            });

            $routeProvider.when('/settings', {
                templateUrl: 'partials/settings.html',
                controller: 'settingsController'
            });

            $routeProvider.when('/about', {
                templateUrl: 'partials/about.html',
                controller: 'aboutController'
            });

            $routeProvider.when('/chat/:userId', {
                templateUrl: 'partials/chat.html',
                controller: 'chatController'
            });

            $routeProvider.when('/chats', {
                templateUrl: 'partials/chats.html',
                controller: 'chatsController'
            });

            $routeProvider.when('/sendFeedback', {
                templateUrl: 'partials/sendFeedback.html',
                controller: 'sendFeedbackController'
            });

            $routeProvider.when('/fsecureProducts', {
                templateUrl: 'partials/fsecureProducts.html',
                controller: 'fsecureProductsController'
            });

            $routeProvider.when('/acceptFriendInvitation/:userId', {
                templateUrl: 'partials/acceptFriendInvitation.html',
                controller: 'acceptFriendInvitationController'
            });

            $routeProvider.when('/tellFriendVia', {
                templateUrl: 'partials/tellFriendVia.html',
                controller: 'tellFriendViaController'
            });

            $routeProvider.when('/visibilitySetting', {
                templateUrl: 'partials/visibilitySetting.html',
                controller: 'visibilitySettingController'
            });


            $routeProvider.otherwise({ redirectTo: '/dashboard' });
        }]).
        run(["ringoAppService", "$rootScope", "$location", function(ringoAppService, $rootScope, $location){
            ringoAppService.onAppStarted();
            var platform = ((window.device) ? window.device.platform : "browser");
            if (window.FB && platform !== "browser") {
                if (!cordova || cordova.browser || !window.CDV || !window.CDV.FB) {
                    FB.init({ appId: "413632302078455", useCachedDialogs: false });
                } else {
                    FB.init({ appId: "413632302078455", nativeInterface: CDV.FB, useCachedDialogs: false });
                }
            }

            $rootScope.backToDashboard = function(){
                $location.path("/dashboard");
            }
        }]);