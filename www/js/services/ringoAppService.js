/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 16.05.2013 10:52
 */

'use strict';

/// Main Ringo service which connects other services
angular.module("ringo.services")
    .service("ringoAppService", ["$rootScope", "$location", "localize", "localStorageService", "geoLocationService", "serverApiService", "commonService", "$route", "$routeParams",
        function($rootScope, $location, localize, localStorageService, geoLocationService, serverApiService, commonService, $route, $routeParams) {

            var dashboard = undefined;  // cached dashboard for app
            var ringoAppService = this;
            ringoAppService.serverApiService = serverApiService;
            ringoAppService.geoLocationService = geoLocationService;
            ringoAppService.localStorageService = localStorageService;
            this.appIsActive = true;// true if app is running and false if it is background


            // Detect back button (in Android) and redirect to Dashboard
            // Logic to handle back button
            function backbuttonHandler(){
                $rootScope.safeApply(function(){

                    var returnPath;
                    console.log("Back button pressed! Current page: " + $location.path());
                    if ($route.current && $route.current.locals && $route.current.locals.$scope) {
                        if ($route.current.locals.$scope.returnPath !== undefined) {
                            returnPath = $route.current.locals.$scope.returnPath;
                            console.log("Found return path in current scope: " + returnPath);
                        }
                    }

                    if ($location.path() === "/dashboard" || returnPath === "") {
                        navigator.app.exitApp();
                        /* // Prompt to exit app
                         console.log("Prompting to exit");
                         commonService.askUserConfirmation("confirm.exit", "confirm.title.confirm", function(buttonPressed) {
                         if (buttonPressed === 1) { // Yes
                         navigator.app.exitApp();
                         }
                         }, "confirm.buttons.confirmCancel");
                         */
                    } else if (returnPath) {
                        $location.path(returnPath);
                    } else {
                        navigator.app.backHistory();
                    }
                })
            }

            var platform = ((window.device) ? window.device.platform : "browser");

            if (platform == "Win32NT") {
                navigator.app = {};
                navigator.app.backHistory = window.history.back;

                // To avoid displaying login page if user doesn't want to close app
                window.history.back = function () {};

                $rootScope.$on("$locationChangeStart", function (event, next, current) {
                    console.log("locationChangeStart: " + current + " -> " + next);
                    // we should exit app if we are in welcome screen (#/ or #/welcome) or dashboard
                    // to exit app we just remove event listener and native code handles exiting
                    if (next.indexOf("dashboard") >= 0 || next === "x-wmapp0://www/index.html#/" || next === "x-wmapp0://www/index.html#/welcome") {
                        console.log("removing backbutton handler");
                        document.removeEventListener('backbutton', backbuttonHandler);
                    } else if (current.indexOf("dashboard") >= 0 || current === "x-wmapp0://www/index.html#/" || current === "x-wmapp0://www/index.html#/welcome") {
                        console.log("adding backbutton handler");
                        document.addEventListener('backbutton', backbuttonHandler, false);
                    }
                });
            } else {
                document.addEventListener('backbutton', backbuttonHandler, false);
            }


            // Detect options button (in Android) and redirect to Settings
            // Logic to handle back button
            document.addEventListener('menubutton', function(){

                $rootScope.safeApply(function(){
                    console.log("Back button pressed! Current page: " + $location.path());
                    $location.path('/settings');
                })

            }, false);


            angular.element(document).bind('push-notification', function(event){
                console.log("Got notification: " + JSON.stringify(event.notification));
                if (event.notification && event.notification.messageFrom && event.notification.applicationStateActive === "0") {
                    // open chats window when we get woken up from remote notification
                    $rootScope.safeApply(function(){
                        console.log("Opening chats window when opened from remote notification");
                        $location.path('/chats');
                    })

                }
                // always update dashboard on any event received
                if (ringoAppService.appIsActive) {
                    setTimeout(function() {ringoAppService.refreshDashboard()}, 10);
                }
            });


            // entering in background
            document.addEventListener("pause", function() {
                ringoAppService.appIsActive = false;
            }, false);

            // detect activating app back from background
            document.addEventListener("resume", function() {
                ringoAppService.appIsActive = true;
                setTimeout(function() {ringoAppService.forceReportLocationIfLocationReportingEnabled()}, 5);// trigger updating location
                setTimeout(function() {ringoAppService.refreshDashboard()}, 10);// refresh dashboard once
            }, false);


            $rootScope.$on('new-gps-location', function(event, position) {
                //console.log("got event new-gps-location: " + JSON.stringify(position));
                ringoAppService.serverApiService.reportLocation(position, function(status) {
                    if (status  === true) {
                        $rootScope.ringo.latestPosition = position;
                        if (ringoAppService.appIsActive) {
                            ringoAppService.refreshDashboard();// always update dashboard after new position report
                        }
                    }
                });
            });

            this.startGeoLocationTrackingIfEnabled = function (){
                if (ringoAppService.localStorageService.isLocationReportingEnabled() && ringoAppService.localStorageService.getUserName() !== undefined) {
                    ringoAppService.geoLocationService.enableGeoLocationTracking();
                }
            };

            this.forceReportLocationIfLocationReportingEnabled = function (){
                if (ringoAppService.localStorageService.isLocationReportingEnabled() && ringoAppService.localStorageService.getUserName() !== undefined) {
                    ringoAppService.geoLocationService.forceReportCurrentLocation();
                }
            };

            var registerForRemoteNotificationsCallback = function(result) {
                console.log("registerForRemoteNotificationsCallback got: " + JSON.stringify(result));
                var enabled = result.enabled;
                var deviceToken = result.deviceToken;
                if (enabled) {
                    ringoAppService.localStorageService.setValue("remoteNotificationsDeviceTokenAPN", deviceToken);
                    ringoAppService.serverApiService.registerForRemoteNotifications(deviceToken, function(status) {
                        console.log("registerForRemoteNotifications returned " + status);
                    });
                } else {
                    ringoAppService.localStorageService.setValue("remoteNotificationsDeviceTokenAPN", undefined);
                }
            };

            var androidRemoteNotificationsCallback = function(e) {
                console.log("androidRemoteNotificationsCallback got: " + JSON.stringify(e));
                switch( e.event )
                {
                    case 'registered':
                        var token = e.regid;
                        ringoAppService.localStorageService.setValue("remoteNotificationsDeviceTokenGCM", token);
                        ringoAppService.serverApiService.registerForGCMRemoteNotifications(token, function(status) {
                            console.log("registerForGCMRemoteNotifications returned " + status);
                        });
                    break;
                    case 'message':
                        if (ringoAppService.appIsActive) {
                            setTimeout(function() {ringoAppService.refreshDashboard()}, 10);
                        }
                    break;
                };

            };

            var registerForWP8RemoteNotificationsCallback = function(result) {
                console.log("registerForWP8RemoteNotificationsCallback got: " + JSON.stringify(result));
                var enabled = result.enabled;
                var deviceToken = result.deviceToken;
                if (enabled) {
                    ringoAppService.localStorageService.setValue("remoteNotificationsDeviceTokenWP8", deviceToken);
                    ringoAppService.serverApiService.registerForWP8RemoteNotifications(deviceToken, function(status) {
                        console.log("registerForWP8RemoteNotifications returned " + status);
                    });
                } else {
                    ringoAppService.localStorageService.setValue("remoteNotificationsDeviceTokenWP8", undefined);
                }
            };

            window.androidRemoteNotificationsCallback = androidRemoteNotificationsCallback;

            var registerForRemoteNotifications = function() {

                // check if settings are enabled
                if (window.plugins.pushNotificationWP8) { 

                    // register notification only if enabled
                    if (dashboard && dashboard.settings.enableNotifications === false) {
                        console.log("Push notifications for WP8 are disabled");
                    }
                    else {
                        console.log("Register for remote push notifications for WP8");
                        window.plugins.pushNotificationWP8.registerDevice(true, registerForWP8RemoteNotificationsCallback);
                    }
                }

                if (window.plugins.pushNotification) {
                    console.log("Register for APN");
                    window.plugins.pushNotification.registerDevice({badge: 1, sound: 1, alert: 1}, registerForRemoteNotificationsCallback);
                }
                if (window.plugins.GCM) {
                    console.log("Registering GCM plugin");
                    window.plugins.GCM.register("103901975110", "androidRemoteNotificationsCallback", function(param) {
                        console.log("Registered to GCM. param: " + JSON.stringify(param));
                    }, function(err) {
                        console.log("Registration to GCM failed. param: " + JSON.stringify(err));
                    });
                }
            };


            var onDashboardReadFinished = function(status, dashboardFromServer) {
                if (status === true) {
                    ringoAppService.localStorageService.setDashboard(dashboardFromServer);
                    dashboard = dashboardFromServer;
                } else {
                    //dashboard = {error:status};//error message
                }
                $rootScope.$broadcast('dashboardUpdated', {});
            };

            this.refreshDashboard = function() {
                ringoAppService.serverApiService.readDashboard(onDashboardReadFinished);
            };

            this.getDashboard = function() {
                return dashboard;
            };
            
            this.startRemoteNotificationsIfEnabled = function () {

                console.log("registerForRemoteNotifications...");
                registerForRemoteNotifications();
            };
            

            // returns avatar icon path or base64 encodede image for user with userId
            this.getUserAvatarIcon = function(userId) {
                if (userId === "family") {
                    return "images/familyAvatar.png";
                }
                var dashboard = this.getDashboard();
                if (!dashboard) {
                    console.log("getUserAvatarIcon with no dashboard");
                    return "";
                }
                if (dashboard.userId === userId) {
                    return commonService.fetchImage(dashboard.icon);
                }

                if (dashboard.family && dashboard.family.members && dashboard.family.members[userId]) {
                    return commonService.fetchImage(dashboard.family.members[userId].icon);
                }

                if (dashboard.friendsInfo && dashboard.friendsInfo[userId]) {
                    return commonService.fetchImage(dashboard.friendsInfo[userId].icon);
                }

                return "";
            };

            // returns true if userId is a friend or invited friend or pending friend
            this.isFriendOrPendingFriendUser = function(userId) {
                var dashboard = this.getDashboard();
                if (!dashboard) {
                    return false;
                }
                if (dashboard.friends && dashboard.friends.indexOf(userId) !== -1) {
                    return true;
                }
                if (dashboard.pendingFriends && dashboard.pendingFriends.indexOf(userId) !== -1) {
                    return true;
                }
                if (dashboard.invitingFriends && dashboard.invitingFriends.indexOf(userId) !== -1) {
                    return true;
                }
                return false;
            };

            // returns true if userId is a friend
            this.isFriendUser = function(userId) {
                var dashboard = this.getDashboard();
                if (!dashboard) {
                    return false;
                }
                if (dashboard.friends && dashboard.friends.indexOf(userId) !== -1) {
                    return true;
                }
                return false;
            };

            // returns true if userId is a family member or pending family member
            this.isFamilyMemberOrPendingFamilyMember = function(userId) {
                var dashboard = this.getDashboard();
                if (!dashboard) {
                    return false;
                }
                if (dashboard.userId === userId) {
                    return true;
                }
                if (dashboard.family && dashboard.family.members && dashboard.family.members[userId]) {
                    return true;
                }
                if (dashboard.family && dashboard.family.invitedMembers && dashboard.family.invitedMembers.indexOf(userId) !== -1) {
                    return true;
                }
                return false;
            };

            // returns true if userId is a family member
            this.isFamilyMember = function(userId) {
                var dashboard = this.getDashboard();
                if (!dashboard) {
                    return false;
                }
                if (dashboard.userId === userId) {
                    return true;
                }
                if (dashboard.family && dashboard.family.members && dashboard.family.members[userId]) {
                    return true;
                }
                return false;
            };

            // returns name of a user userId
            this.getUserName = function(userId) {
                if (userId === "family") {
                    return localize.getLocalizedString("family.yourFamilyName");
                }

                var userName = undefined;
                if (dashboard) {
                    if (userId === dashboard.userId) {
                        userName = dashboard.name;
                    } else {
                        if (dashboard.family && dashboard.family.members && dashboard.family.members[userId]) {
                            userName = dashboard.family.members[userId].name;
                        } else {
                            if (dashboard.friendsInfo && dashboard.friendsInfo[userId]) {
                                userName = dashboard.friendsInfo[userId].name;
                            }

                        }
                    }
                };

                // cache names
                if (userName) {
                    ringoAppService.localStorageService.setValue("UserName:" + userId, userName);
                } else {
                    // maybe cached?
                    userName = ringoAppService.localStorageService.getValue("UserName:" + userId);
                    if (!userName) {
                        userName = "+" + userId;
                    }
                }

                return userName;
            };

            // reads and returns copy of current user position from dashboard
            // returns undefined if dashboard is not available or location is not known there
            this.getCurrentUserPositionFromDashboard = function() {
                var dashboard = this.getDashboard();
                if (!dashboard || !dashboard.location) {
                    return undefined;
                }
                return JSON.parse(JSON.stringify(dashboard.location));
            };

            this.getUserPositionFromDashboard = function(userId) {
                var dashboard = this.getDashboard();
                if (!dashboard) {
                    return undefined;
                }

                if (dashboard.userId === userId) {
                    return JSON.parse(JSON.stringify(dashboard.location));
                }

                //one of family members
                for(var memberId in dashboard.family.members) {
                    if (dashboard.family.members[memberId].userId === userId) {
                        return JSON.parse(JSON.stringify(dashboard.family.members[memberId].location));
                    }
                }

                return undefined;

            };

            /* TODO: documentation needed!!! */
            var sortPlacesByNumberOfUsersInside = function(pl1, pl2) {
                if (pl1.type == "friends_nearby") {
                    if (pl2.atPlace.length == 0) return -1;
                    else return 1;
                }
                if (pl2.type == "friends_nearby") {
                    if (pl1.atPlace.length == 0) return 1;
                    else return -1;
                }
                else
                    return (pl2.atPlace.length - pl1.atPlace.length);
            };


            this.getNumOfNewMessagesFromUser = function(dashboard, userId) {
                if (dashboard === undefined || dashboard.messages === undefined || dashboard.messages.unread === undefined || userId === undefined) {
                    return 0;
                }
                if (dashboard.messages.unread[userId]) {
                    return dashboard.messages.unread[userId];
                } else {
                    return 0;
                }
            };

            // reads places from dashboard into array of objects which is in dashboard friendly format, like:
            //[{
            //    name: "F-Secure",
            //    type: "home",
            //    atPlace:[{
            //          name: "Miguel",
            //          userId: "Miguel",
            //          image: "images/avatar1.png",
            //          newMessages: 3
            //      }]
            //  },{
            //      name: "Oulu",
            //      type: "home",
            //      atPlace:[{
            //          name: "Harri",
            //          userId: "Harri",
            //          image: "images/avatar1.png",
            //          newMessages: 0
            //          },{
            //          name: "Oleg",
            //          isCurrentUser: true,
            //          image: "images/avatar2.png",
            //          newMessages: 1
            //      }]
            //  }
            //  ];
            this.getPlacesInDashboardFormat = function(splitCrowdedPlaces) {
                var dashboard = this.getDashboard();
                var places = [];
                if (!dashboard || !dashboard.family || !dashboard.family.places) {
                    return places;
                }

                var familyMembers = JSON.parse(JSON.stringify(dashboard.family.members));//deep copy
                // add ourselves to family members

                familyMembers[ringoAppService.localStorageService.getUserName()] = {
                    name: dashboard.name,
                    icon: dashboard.icon, // Do NOT use fetchImage here, as it will be used in the next loop.
                    places: dashboard.places,
                    userId: dashboard.userId,
                    location: dashboard.location
                };

                for(var placeId in dashboard.family.places) {
                    var place = dashboard.family.places[placeId];
                    var dashboardPlace = {
                        name: place.name,
                        type: (place.type || "home"),
                        isEditable: true,
                        atPlace: []
                    };
                    for(var memberId in familyMembers) {
                        var member = familyMembers[memberId];
                        if (member.places.indexOf(place.name) !== -1) {

                            dashboardPlace.atPlace.push({
                                userId: member.userId,
                                name: (member.name === "") ? member.userId : member.name,
                                image: (member.icon === "") ? "images/defaultAvatar.png" : commonService.fetchImage(member.icon),
                                isCurrentUser: (member.userId === ringoAppService.localStorageService.getUserName()),
                                lastReport: member.location.time,
                                lastAccuracy: member.location.acc,
                                newMessages: this.getNumOfNewMessagesFromUser(dashboard, member.userId)
                            });
                        }
                    };

                    //var addEmptyPlaces = localStorageService.shouldDashboardShowEmptyPlaces();// add places where no one is currently or not
                    //if (addEmptyPlaces || dashboardPlace.atPlace.length > 0) {
                    places.push(dashboardPlace);
                    //}

                }

                // sort by number of people inside
                //places.sort(sortPlacesByNumberOfUsersInside);

                // Friends nearby
                /*
                if (dashboard.friendsNearby && dashboard.friendsNearby.length > 0) {
                    var dashboardPlace = {
                        name: localize.getLocalizedString("dashboard.friendsNearby"),
                        type: "friends_nearby",
                        atPlace: [],
                        isEditable: false // cannot edit, so cannot go to place details
                    };

                    for(var friendId in dashboard.friendsNearby) {
                        var friend = dashboard.friendsInfo[dashboard.friendsNearby[friendId]];
                        if (friend) {
                            var wantToSeeThisFriendNearby = (!dashboard.settings || !dashboard.settings.friend || !dashboard.settings.friend[friend.userId] || dashboard.settings.friend[friend.userId].viewMode !== "showNowhere");
                            if (wantToSeeThisFriendNearby) {
                                dashboardPlace.atPlace.push({
                                    userId: friend.userId,
                                    name: (friend.name === "") ? friend.userId : friend.name,
                                    image: (friend.icon === "") ? "images/defaultAvatar.png" : commonService.fetchImage(friend.icon),
                                    isCurrentUser: false,
                                    isFriend: true,
                                    lastReport: Date.now(),
                                    lastAccuracy: ((friend.location)? friend.location.acc : 10),
                                    newMessages: this.getNumOfNewMessagesFromUser(dashboard, friend.userId)
                                });
                            }
                        }
                    }
                    if (dashboardPlace.atPlace.length > 0) {
                        places.push(dashboardPlace);
                    }
                }
                */
                // sort by number of people inside
                // AND make near_by show before empty places
                places.sort(sortPlacesByNumberOfUsersInside);

                // a trick here: if place is too crowded then split it to several places
                // we are doing it after sorting because if we do it before sorting - sort will move the same places all around dashboard
                if (splitCrowdedPlaces === true) {
                    var maxPeopleInPlace = 5;
                    var length = places.length;
                    for(var placeIdx = 0; placeIdx < length; ++placeIdx) {
                        if (places.hasOwnProperty(placeIdx) && places[placeIdx].atPlace.length > maxPeopleInPlace) {
                            var newPlace = JSON.parse(JSON.stringify(places[placeIdx]));//copy
                            places[placeIdx].atPlace.splice(maxPeopleInPlace);//remove all after N from initial place
                            newPlace.atPlace.splice(0, maxPeopleInPlace);// remove first N from new place
                            places.splice(placeIdx + 1, 0, newPlace);//add new place right after old one
                            ++length;// we added one more element which we will step over next iteration
                        }
                    }
                }

                return places;
            };

            this.getFamilyInDashboardFormat = function() {
                return this._getFamilyInDashboardFormat(/*includePeopleInPlaces=*/false, /*includeInvitedMembers=*/true);
            };

            this.getAllFamilyMembersInDashboardFormat = function() {
                return this._getFamilyInDashboardFormat(/*includePeopleInPlaces=*/true, /*includeInvitedMembers=*/false);
            };

            // returns family members in format used in dashboardController:
            //  family = [{
            //          name: "Oleg",
            //          userId: "Oleg"
            //          image: "images/avatar1.png",
            //          lastReport: 12233445
            //          newMessages: 1
            //      },
            //      {
            //          name: "Harri",
            //          userId: "Harri"
            //          isCurrentUser: true,
            //          image: "images/avatar2.png"
            //          lastReport: 12233445
            //          newMessages: 0
            //  }];
            this._getFamilyInDashboardFormat = function(includePeopleInPlaces, includeInvitedMembers) {
                var dashboard = this.getDashboard();
                if (!dashboard || !dashboard.family || !dashboard.family.members) {
                    return [];
                }
                var family = [];
                // The current USER
                if (includePeopleInPlaces || dashboard.places.length === 0) {

                    family.push({
                        userId: dashboard.userId,
                        name: (dashboard.name === "") ? dashboard.userId : dashboard.name,
                        image: (dashboard.icon === "") ? "images/defaultAvatar.png" : commonService.fetchImage(dashboard.icon),
                        lastReport: dashboard.location.time,
                        lastAccuracy: dashboard.location.acc,
                        isCurrentUser: true,
                        newMessages: this.getNumOfNewMessagesFromUser(dashboard, dashboard.userId)
                    });
                }

                for(var memberId in dashboard.family.members) {
                    var member = dashboard.family.members[memberId];
                    if (includePeopleInPlaces || member.places.length === 0) {
                        family.push({
                                userId: member.userId,
                                name: (member.name === "") ? member.userId : member.name,
                                image: (member.icon === "") ? "images/defaultAvatar.png" : commonService.fetchImage(member.icon),
                                lastReport: member.location.time,
                                lastAccuracy: member.location.acc,
                                isCurrentUser: false,
                                newMessages: this.getNumOfNewMessagesFromUser(dashboard, member.userId)
                            }
                        );
                    }
                }

                if (includeInvitedMembers) {
                    for(var invitedMember in dashboard.family.invitedMembers) {
                        var pendingMember = dashboard.family.invitedMembers[invitedMember];
                        family.push({
                            userId: pendingMember,
                            name: '+' + pendingMember,
                            image: "images/pendingAvatar.png",
                            lastReport: Date.now(),// we don't know yet his location so just show without fading
                            lastAccuracy: 10,// assume accuracy is good for invited members
                            isCurrentUser: false,
                            newMessages: 0
                        });

                    }
                }

                return family;
            };


            // returns friends in format used in dashboardController:
            //  friends = [{
            //          name: "Oleg",
            //          userId: "Oleg"
            //          image: "images/pendingFriend.png",
            //          pendingFriend: true,
            //          newMessages: 0
            //      },
            //      {
            //          name: "Harri",
            //          userId: "Harri"
            //          image: "images/invitingFriend.png"
            //          invitingFriend: true,
            //          newMessages: 0
            //      },
            //      {
            //          name: "Miguel",
            //          userId: "Miguel"
            //          image: "f-secure.com/images/Miguel.jpg?whatever"
            //          newMessages: 2
            //  }];
            this.getFriendsInDashboardFormat = function(includeFriendsNearby, includePending, includeInviting) {
                var dashboard = this.getDashboard();
                if (!dashboard || !dashboard.friendsInfo) {
                    return [];
                }
                var friends = [];

                // friends
                for(var friendId in dashboard.friendsInfo) {
                    var friend = dashboard.friendsInfo[friendId];
                    var wantToSeeThisFriendNearby = (!dashboard.settings || !dashboard.settings.friend || !dashboard.settings.friend[friend.userId] || dashboard.settings.friend[friend.userId].viewMode !== "showNowhere");
                    // do not add to bar if friend is nearby but still add if we don't show this friend nearby
                    if (includeFriendsNearby || !dashboard.friendsNearby || dashboard.friendsNearby.indexOf(friend.userId) === -1 || !wantToSeeThisFriendNearby) {
                        friends.push({
                                userId: friend.userId,
                                name: (friend.name === "") ? friend.userId : friend.name,
                                image: (friend.icon === "") ? "images/defaultAvatar.png" : commonService.fetchImage(friend.icon),
                                newMessages: this.getNumOfNewMessagesFromUser(dashboard, friend.userId),
                                isFriend: true
                            });
                    }
                }

                // inviting and pending
                if (includeInviting) {
                    for(var inviting in dashboard.invitingFriends) {
                        var invitingUserId = dashboard.invitingFriends[inviting];
                        friends.push({
                            userId: invitingUserId,
                            name: '+' + invitingUserId,
                            image: "images/invitingFriendAvatar.png",
                            invitingFriend: true,
                            newMessages: 0,
                            isFriend: true
                        });
                    }
                }

                if (includePending) {
                    for(var pending in dashboard.pendingFriends) {
                        var pendingUserId = dashboard.pendingFriends[pending];
                        friends.push({
                            userId: pendingUserId,
                            name: '+' + pendingUserId,
                            image: "images/pendingFriendAvatar.png",
                            pendingFriend: true,
                            newMessages: 0,
                            isFriend: true
                        });
                    }
                }

                return friends;
            };

            // log out user
            this.logOut = function() {
                dashboard = undefined;
                $rootScope.ringo = {};

                localStorage.removeItem('ringoUsers');
                localStorageService.setUserName(undefined);
                localStorageService.setDashboard(undefined);
                localStorageService.setAuthToken(undefined);
                ringoAppService.geoLocationService.stopGeoLocationTracking();
                $rootScope.safeApply(function() {
                    $location.path('/');
                });
            };

            // returns user Id for currently logged in user
            this.getLoggedInUserId = function() {
                return ringoAppService.localStorageService.getUserName();
            };

            var restoreState = function () {
                localize.setLanguage(ringoAppService.localStorageService.getLanguage());
                if ($rootScope.ringo) {
                    console.log("WTF? ringo object must not exist yet");
                }
                $rootScope.ringo = {};
                $rootScope.ringo.userName = ringoAppService.localStorageService.getUserName();
                $rootScope.ringo.loggedIn = ringoAppService.localStorageService.isUserLoggedIn();
                console.log("app.run restored state: " + JSON.stringify($rootScope.ringo));
                dashboard = ringoAppService.localStorageService.getDashboard();
                if ($rootScope.ringo.loggedIn) {
                    ringoAppService.startGeoLocationTrackingIfEnabled();
                    if ($location.path() === "") { // forward to dashboard only if we are initializing
                        $location.path("/dashboard");
                    }
                }
            };


            // It will be executed when app starts before any controller is initialized
            this.onAppStarted = function() {
                // add safeApply function available for everyone
                $rootScope.safeApply = function(fn) {
                    var phase = this.$root.$$phase;
                    if(phase == '$apply' || phase == '$digest') {
                        fn();
                    } else {
                        this.$apply(fn);
                    }
                };

                restoreState();
                if (localStorageService.isUserLoggedIn()) {
                    registerForRemoteNotifications();
                }
                setTimeout(function() {ringoAppService.refreshDashboard()}, 10);// refresh dashboard once

            };

    }])
;
