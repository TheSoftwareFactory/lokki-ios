/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
    .controller("chatsController",
        ["$scope", "$location", "localize", "ringoAppService", "localStorageService", "messagesCacheService",
        function($scope, $location, localize, ringoAppService, localStorageService, messagesCacheService) {
            /* example
            $scope.chats = {
                "0": {
                    name: "Oleg",
                    unreadMessages: 3,
                    userId: "358405297258",
                    icon: "http://ringo-server.f-secure.com/files/avatars/358405297258.jpg",
                    lastCommunicationTimestamp: 7364548,
                    lastCommunicationText: "3 days ago"
                },
                "1": {
                    name: "Miguel",
                    userId: "358406473147",
                    icon: "http://ringo-server.f-secure.com/files/avatars/358406473147.jpg",
                    lastCommunicationTimestamp: 1234567,
                    lastCommunicationText: "today"
                }
            };
            */
            $scope.chats = {};
            $scope.returnPath = "/dashboard";

            $scope.onChatClick = function(chat) {
                localStorageService.setValue("chatControllerReturnPath", "/chats");
                $location.path("/chat/" + chat.userId);
            };

            var getLastCommunicationText = function(lastCommunicationTimestamp) {
                if (lastCommunicationTimestamp === undefined || lastCommunicationTimestamp === 0) {
                    return localize.getLocalizedString("chats.noMessagesYet");//" (no messages yet)";
                }
                var curTime = new Date();
                var lastCommTime = new Date(lastCommunicationTimestamp);
                var diff = (curTime - lastCommTime);
                var millisecondsInADay = 1000*60*60*24;
                if (diff < millisecondsInADay) {
                    if (curTime.getDate() === lastCommTime.getDate()) {
                        return localize.getLocalizedString("chats.messagesToday");
                    } else {
                        return localize.getLocalizedString("chats.messagesYesterday");
                    }

                } else {
                    return localize.getLocalizedString("chats.messagesOld");
                }
            };

            var sortChats = function(chats) {
                // sort chats by lastCommunicationTimestamp
                var familyChat = null;
                var sortedChats = [];
                for(var c in chats) {
                    if (chats.hasOwnProperty(c)) {
                        // Catch family chat as separate, that needs to be first in the results.
                        if (c == "family") {
                            familyChat = chats[c];
                        } else {
                            sortedChats.push(chats[c]);
                        }
                    }
                }

                sortedChats.sort(function(left, right) {
                    return right.lastCommunicationTimestamp - left.lastCommunicationTimestamp;
                });

                var result = new Array();
                // Append family chat as the first one.
                if (familyChat != null) {
                    result.push(familyChat);
                }
                for(var c in sortedChats) {
                    if (sortedChats.hasOwnProperty(c)) {
                        result.push(sortedChats[c]);
                    }
                }
                return result;
            };

            //  readDashboard just prepares list of chats and this function should init texts and icons
            var makeChatsReadyForDisplay = function(chats) {
                //console.log("Preparing chats: " + JSON.stringify(chats));
                for(var userId in chats) {
                    var chat = chats[userId];
                    chat.name = ringoAppService.getUserName(userId);
                    chat.icon = ringoAppService.getUserAvatarIcon(userId);
                    if (chat.icon === "") {
                        chat.icon = "images/pendingAvatar.png";
                    }
                    chat.avatarHaloClass = "";
                    if (ringoAppService.isFriendOrPendingFriendUser(userId)) {
                        chat.avatarHaloClass = "friend";
                    } else if (ringoAppService.getLoggedInUserId() === userId) {
                        chat.avatarHaloClass = "yourself";
                    }
                    chat.lastCommunicationText = getLastCommunicationText(chat.lastCommunicationTimestamp);
                }
                $scope.chats = sortChats(chats);
            };


            // read list of chats from dashboard.
            var readDashboard = function () {
                // show all people who are in family in list of chats. Plus everyone who sent us messages ever.
                // sort by last message received
                var dashboard = ringoAppService.getDashboard();
                if (!dashboard) {
                    return;
                }
                var chats = {};
                // everyone who ever sent us a message
                if (dashboard.messages && dashboard.messages.last) {
                    for(var l in dashboard.messages.last) {
                        if (dashboard.messages.last.hasOwnProperty(l)) {
                            chats[l] = {
                                userId: l,
                                lastCommunicationTimestamp: +dashboard.messages.last[l],
                                unreadMessages: dashboard.messages.unread[l]
                            }
                        }
                    }
                }

                // everyone from local cache
                var cachedUsers = messagesCacheService.getAllUsersWhoSentMessages();
                for(var cachedUser in cachedUsers) {
                    if (cachedUsers.hasOwnProperty(cachedUser)) {
                        var userId = cachedUsers[cachedUser];
                        if (!chats[userId] || chats[userId].lastCommunicationTimestamp < messagesCacheService.getLastReadMessageTimestamp(userId)) {
                            chats[userId] = {
                                userId: userId,
                                lastCommunicationTimestamp: messagesCacheService.getLastReadMessageTimestamp(userId),
                                unreadMessages: 0
                            }
                        }
                    }
                }

                // everyone from family
                if (dashboard.family && dashboard.family.members) {
                    for(var fm in dashboard.family.members) {
                        if (dashboard.family.members.hasOwnProperty(fm)) {
                            var familyMember = dashboard.family.members[fm];
                            if (!chats[fm]) {
                                chats[fm] = {
                                    userId: fm,
                                    lastCommunicationTimestamp: 0,
                                    unreadMessages: 0
                                }
                            }
                        }

                    }
                }

                // everyone from friends
                if (dashboard.friendsInfo) {
                    for(var fr in dashboard.friendsInfo) {
                        if (dashboard.friendsInfo.hasOwnProperty(fr)) {
                            if (!chats[fr]) {
                                chats[fr] = {
                                    userId: fr,
                                    lastCommunicationTimestamp: 0,
                                    unreadMessages: 0
                                }
                            }
                        }

                    }
                }

                // add family chat if still not there
                if (!chats["family"]) {
                    chats["family"] = {
                        userId: "family",
                        lastCommunicationTimestamp: 0,
                        unreadMessages: 0
                    }
                }

                makeChatsReadyForDisplay(chats);
            };

            $scope.$on('dashboardUpdated', function() {
                console.log("got event dashboardUpdated");
                $scope.safeApply(function() {
                    readDashboard();
                });
            });

            readDashboard();
            ringoAppService.refreshDashboard();

        }]);