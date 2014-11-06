/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
    .controller("chatController",
        ["$scope", "$location", "$window", "$routeParams", "serverApiService", "ringoAppService", "messagesCacheService", "localStorageService", "commonService",
            function($scope, $location, $window, $routeParams, serverApiService, ringoAppService, messagesCacheService, localStorageService, commonService) {

            var maxNumberOfShownMessages = 100;// do not show more than that

            $scope.returnPath = localStorageService.getValue("chatControllerReturnPath");
            localStorageService.setValue("chatControllerReturnPath", undefined);
            if (!$scope.returnPath) {
                $scope.returnPath = "/dashboard";
            }

            $scope.userId = $routeParams.userId;
            $scope.userName = ringoAppService.getUserName($routeParams.userId);
            $scope.myUserId = ringoAppService.getLoggedInUserId();

            $scope.forceMessageReadingFromServer = false;

            $scope.messages = undefined;
            $scope.oldMessages = undefined;
            $scope.showOldMessages = false;
            $scope.canSendMessagesToThisChat = true;

            var prevTodayMessages;
            var prevOldMessages;

            // example
            /*
            $scope.messages = [
                {
                    userId: "358405297258",
                    texts: ["Hi", "Hi there"],
                    incoming: true,
                    date: "18.7.2013 13:55",
                    showIcon: true,
                    avatarHaloClass: "yourself-in-chat"
                },
                {
                    userId: "3584058",
                    texts: ["Hi back"],
                    incoming: false,
                    avatarHaloClass: "friend"
                },
                {
                    userId: "358405297258",
                    texts: ["How are you?"],
                    incoming: true,
                    date: "18.7.2013 14:00",
                    showIcon: true
                },
                {
                    userId: "3584058",
                    text: ["Fine, thanks! How are you doing today? Lets go to lunch to Yeti?"],
                    incoming: false
                },
                {
                    userId: "358405297258",
                    text: ["Nop, sorry. Have plans"],
                    incoming: true
                }

            ];
            */

            $scope.back = function() {
                $location.path($scope.returnPath);
            };

            var getMessagesInScopeFormat = function(serverMessages) {
                var prevDate = undefined;
                var messages = [];
                //console.log(JSON.stringify(serverMessages));
                for(var messageID in serverMessages) {
                    var ids = messageID.split("_");
                    if (ids.length === 2) {
                        var timestamp = +ids[0];
                        var userID = ids[1];
                        var date = new Date(timestamp);
                        var dateIfNeeded =  undefined;

                        // show date if previous message is 5 minutes older than this one
                        if (!prevDate || (date - prevDate)/1000 > 60*5) {
                            prevDate = date;
                            dateIfNeeded = date.getUTCDate() + "." + (date.getUTCMonth() + 1) + "." + date.getUTCFullYear() + " " + date.getHours() + ":";
                            if (date.getMinutes() < 10) {
                                dateIfNeeded += "0" + date.getMinutes();
                            } else {
                                dateIfNeeded += date.getMinutes();
                            }
                        }
                        var prevMessage = undefined;
                        if (messages.length > 0) {
                            prevMessage = messages[messages.length - 1];
                        }

                        // show icons when incoming messages stream changes to outgoing or vice versa
                        var prevIncoming = (prevMessage ? prevMessage.incoming : undefined);
                        var prevIsFromTheSameUser = (prevMessage ? (prevMessage.userId === userID): false);
                        var incomingMessage = (userID !== $scope.myUserId);
                        var _avatarHaloClass = "";
                        if (ringoAppService.isFriendOrPendingFriendUser(userID)) {
                            _avatarHaloClass = "friend";
                        } else if (ringoAppService.getLoggedInUserId() === userID) {
                            _avatarHaloClass = "yourself-in-chat";
                        }

                        var message = {
                            userId: userID,
                            texts: [serverMessages[messageID]],
                            incoming: incomingMessage,
                            date: dateIfNeeded,
                            showIcon: (!prevIsFromTheSameUser || prevIncoming !== incomingMessage || dateIfNeeded !==undefined),// show icon if user changes or date changes significantly or change incoming to non incoming
                            avatarHaloClass: _avatarHaloClass
                        };
                        if (message.showIcon) {
                            message.icon = ringoAppService.getUserAvatarIcon(userID);
                            if (message.icon === "") {
                                message.icon = "images/pendingAvatar.png";
                            }

                        }

                        var justAddToCurrentMessage = (prevMessage && !message.showIcon);
                        if (justAddToCurrentMessage) {
                            prevMessage.texts.push(serverMessages[messageID]);
                        } else {
                            messages.push(message);
                        }
                    } else {
                        console.log("Wrong message id format: " + messageID);
                    }
                }
                return messages;
            };

            var showMessagesFromLocalCache = function() {
                var todayMessages = messagesCacheService.getCachedMessagesFromServerForToday($scope.userId);
                var oldMessages = messagesCacheService.getOldCachedMessagesFromServer($scope.userId);
                if (prevTodayMessages !== JSON.stringify(todayMessages) || prevOldMessages !== JSON.stringify(oldMessages)) {
                    prevTodayMessages = JSON.stringify(todayMessages);
                    prevOldMessages = JSON.stringify(oldMessages);
                    $scope.safeApply(function() {
                        $scope.messages = getMessagesInScopeFormat(todayMessages);
                        $scope.oldMessages = getMessagesInScopeFormat(oldMessages);

                        // if user wants to see old messages or if todays messages are empty - show old
                        if ($scope.messages.length === 0 || $scope.showOldMessages) {
                            $scope.showOldMessages = false;
                            $scope.onOldClick();
                        } else {
                            // hide "show old messages" if there are no old messages
                            if ($scope.oldMessages.length === 0) {
                                $scope.showOldMessages = true;
                            }
                        }

                        // 100 max
                        if ($scope.messages.length > maxNumberOfShownMessages) {
                            $scope.messages.splice(0, $scope.messages.length - maxNumberOfShownMessages);
                        }
                    });

                    setTimeout(function() {$scope.scrollIntoLastElement()}, 0);
                }

                var lastReadMessageTimestamp = messagesCacheService.getLastReadMessageTimestamp($scope.userId);
                if (lastReadMessageTimestamp !== undefined) {
                    serverApiService.markMessagesReadFromUser($scope.userId, lastReadMessageTimestamp, function(status) {
                        if (status !== true) {
                            console.log("Failed to mark messages read");
                        }
                    });
                }


            };

            var setMessagesFromServerToScope = function(serverMessages) {
                messagesCacheService.cacheMessagesFromServer($scope.userId, serverMessages);

                showMessagesFromLocalCache();
            };

            var readDashboard = function() {
                var dashboard = ringoAppService.getDashboard();
                $scope.canSendMessagesToThisChat = (
                    $scope.userId === "family" ||
                    ringoAppService.isFriendUser($scope.userId) ||
                    ringoAppService.isFamilyMember($scope.userId)
                );

                if (!$scope.forceMessageReadingFromServer) {
                    if ($scope.messages !== undefined && ringoAppService.getNumOfNewMessagesFromUser(dashboard, $scope.userId) === 0) {
                        return;//no new messages
                    }
                }
                $scope.forceMessageReadingFromServer = false;

                // read messages from server
                var lastReadMessageTimestamp = messagesCacheService.getLastReadMessageTimestamp($scope.userId);
                serverApiService.readMessagesFromUser($scope.userId, lastReadMessageTimestamp, function(status, messages) {
                    if (status === true) {
                        setMessagesFromServerToScope(messages);
                    }
                });

                setTimeout(function() {$scope.scrollIntoLastElement()}, 0);
            };

            $scope.$on('dashboardUpdated', function() {
                console.log("got event dashboardUpdated");
                $scope.safeApply(function() {
                    readDashboard();
                });
            });


            $scope.sendMessage = function() {
                if ($scope.typedMessage === undefined || $scope.typedMessage === "") {
                    return;
                }

                var mes = $scope.typedMessage;

                serverApiService.sendMessageToUser($scope.userId, {message: $scope.typedMessage}, function(status) {
                    if (status === true) {
                        $scope.forceMessageReadingFromServer = true;
                        ringoAppService.refreshDashboard();
                    } else {
                        if (status === serverApiService.errorCodes.ACCESS_DENIED) {
                            commonService.showMessageToUser("error.sendMessageAccessDenied", "error.title.error");
                        } else {
                            commonService.showMessageToUser("error.sendMessageFailed", "error.title.error");
                        }
                    }
                });

                $scope.typedMessage = "";
            };

            $scope.onOldClick = function() {
                if (!$scope.showOldMessages) {
                    $scope.showOldMessages = true;

                    // add todays messages to old messages
                    $scope.oldMessages.push.apply($scope.oldMessages, $scope.messages);

                    $scope.messages = $scope.oldMessages;

                    // 100 max
                    if ($scope.messages.length > maxNumberOfShownMessages) {
                        $scope.messages.splice(0, $scope.messages.length - maxNumberOfShownMessages);
                    }
                }
            };

            $scope.onOtherUserClick = function(message) {
                // ignore clicks on users who are not friends and family anymore
                if (!ringoAppService.isFamilyMemberOrPendingFamilyMember(message.userId) && !ringoAppService.isFriendOrPendingFriendUser(message.userId)) {
                    return;
                }

                localStorageService.setValue("userDetailsControllerReturnPath", $location.path());
                if (ringoAppService.isFriendOrPendingFriendUser(message.userId)) {
                    $location.path("/friendDetails/" + message.userId);
                } else {
                    $location.path("/familyMemberDetails/" + message.userId);
                }
            };

            $scope.onOwnUserClick = function(message) {
                localStorageService.setValue("userDetailsControllerReturnPath", $location.path());
                $location.path("/familyMemberDetails/" + $scope.myUserId);
            };

            // show last message
            $scope.scrollIntoLastElement = function() {
                var messageLines = $window.document.getElementsByClassName("message-line");
                if (messageLines && messageLines.length > 0) {
                    var el = messageLines.item(messageLines.length -1);
                    if(el) {
                        el.scrollIntoView();
                    }
                }
            };

            $scope.onInputBoxFocus = function(){
                setTimeout(function() {
                    $scope.scrollIntoLastElement();
                }, 10);
            }

            showMessagesFromLocalCache();
            $scope.forceMessageReadingFromServer = true;
            readDashboard();



        }]);