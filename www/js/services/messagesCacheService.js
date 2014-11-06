/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 03.06.2013 10:52
 */

'use strict';

// Common functions for different services and controllers
angular.module("ringo.services")
        .service("messagesCacheService", ["localStorageService", "commonService", function(localStorageService, commonService){
            var oneDayInMilliseconds = 1000*60*60*24;

            var cachedMessages = localStorageService.getValue("cachedMessages");
            if (cachedMessages) {
                cachedMessages = JSON.parse(cachedMessages);
            }
            if (!cachedMessages) {
                cachedMessages = {};
            }


            // sorts messages and also removes old messages keeping only 100 last messages max
            var sortMessages = function(messages) {
                // sort by date as server returns not sorted. date timestamp is part of key so just sort by key
                var keys = [];
                for(var m in messages) {
                    if (messages.hasOwnProperty(m)) {
                        keys.push(m);
                    }
                }
                keys.sort();

                // remove messages if more than 100 there
                if (keys.length > 100) {
                    keys.splice(0, keys.length - 100);
                }
                var keysCount = keys.length;
                var sorted = {};
                for(var i = 0; i < keysCount; ++i) {
                    sorted[keys[i]] = messages[keys[i]];
                }
                return sorted;
            };

            this.cacheMessagesFromServer = function(userId, serverMessages) {
                if (!cachedMessages[userId]) {
                    cachedMessages[userId] = {};
                }

                commonService.mergeObjectsRecursive(cachedMessages[userId], serverMessages);

                cachedMessages[userId] = sortMessages(cachedMessages[userId]);

                localStorageService.setValue("cachedMessages", JSON.stringify(cachedMessages));
            };

            // returns array of userid's of all users who exchanged messages with current user (cached messages)
            this.getAllUsersWhoSentMessages = function() {
                var all = [];
                for(var userId in cachedMessages) {
                    if (cachedMessages.hasOwnProperty(userId)) {
                        all.push(userId);
                    }
                }
                return all;
            };


            // returns today's messages from cache
            this.getCachedMessagesFromServerForToday = function(userId) {

                var allMessages = cachedMessages[userId];
                var messages = {};
                var currentDate = new Date();

                for(var m in allMessages) {
                    if (allMessages.hasOwnProperty(m)) {
                        var ids = m.split("_");
                        if (ids.length === 2) {
                            var timestamp = +ids[0];
                            var date = new Date(timestamp);
                            var diff = (currentDate - date);
                            if (diff < oneDayInMilliseconds) {
                                messages[m] = allMessages[m];
                            }
                        }

                    }
                }

                return sortMessages(messages);
            };

            // returns messages from server which are oder than 1 day
            this.getOldCachedMessagesFromServer = function(userId) {

                var allMessages = cachedMessages[userId];
                var messages = {};
                var currentDate = new Date();

                for(var m in allMessages) {
                    if (allMessages.hasOwnProperty(m)) {
                        var ids = m.split("_");
                        if (ids.length === 2) {
                            var timestamp = +ids[0];
                            var date = new Date(timestamp);
                            var diff = (currentDate - date);
                            if (diff >= oneDayInMilliseconds) {
                                messages[m] = allMessages[m];
                            }
                        }

                    }
                }
                return sortMessages(messages);
            };

            // returns timestamp of a last message which userId received and cached
            this.getLastReadMessageTimestamp = function(userId) {
                var allMessages = cachedMessages[userId];
                var lastTimestamp = 0;

                for(var m in allMessages) {
                    if (allMessages.hasOwnProperty(m)) {
                        var ids = m.split("_");
                        if (ids.length === 2) {
                            var timestamp = +ids[0];
                            if (timestamp > lastTimestamp) {
                                lastTimestamp = timestamp;
                            }
                        }
                    }
                }
                return lastTimestamp;
            };

        }])
;
