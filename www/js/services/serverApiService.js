/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 23.04.2013 10:52
 */

'use strict';

/// Service to handle communication with ringo server.
angular.module("ringo.services")
        .service("serverApiService", ["$http", "localStorageService", "commonService", function($http, localStorageService, commonService){
            var serverApiService = this;

            commonService.hideProgressIndicator();// hide it initially

            this.ringoServerApiUrl = "https://ringo-server.f-secure.com/api/";

            //this.ringoServerApiUrl = "http://ringo-test-environment.herokuapp.com/api/";

            //this.ringoServerApiUrl = "http://ringo-server-eu.herokuapp.com/api/";


            //this.ringoServerApiUrl = "http://127.0.0.1:9000/api/";

            this.errorCodes = {
                USER_HAS_BEEN_ALREADY_CREATED : 401,
                ACCESS_DENIED: 403,
                USER_ALREADY_ADDED_TO_FAMILY : 405,
                PLACE_ALREADY_ADDED_TO_FAMILY : 405,
                FAMILY_PLACE_LIMIT: 410, // user cannot create places anymore
                FAMILY_MEMBERS_LIMIT: 411, // family cannot fit more members
                FRIENDS_LIMIT: 411, // cannot fit more friends
                CANNOT_INVITE_FRIENDS_TO_FAMILY: 423,
                CANNOT_INVITE_FAMILY_TO_FRIENDS: 422
            };


            var _platform = ((window.device) ? window.device.platform : "browser");

            // returns config object with authorization token set in headers.
            var configWithAuthHeader = function() {
                return {
                    headers : {
                        authorizationtoken: localStorageService.getAuthToken(),
                        version: commonService.version,
                        platform: _platform
                    }
                }
            };

            // returns config object without authorization token set in headers.
            var configWithoutAuthHeader = function() {
                return {
                    headers : {
                        version: commonService.version,
                        platform: _platform
                    }
                }
            };


            // Read user userId data from server
            this.readUserData = function(userId, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                }

                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/otherUser/" + userId;
                commonService.showProgressIndicator();
                $http.get(url, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        callback(true, data);
                        commonService.hideProgressIndicator();
                    }).
                    error(function(data, status, headers, config) {
                        console.log("read user data call failed. Data:" + data + ". status: " + status);
                        callback("read user data call failed: " + data, undefined);
                        commonService.hideProgressIndicator();
                    });
            };


            /// Login user with name 'userName'.
            /// Executes 'callback' with one parameter:
            ///   - true if login successful or
            ///   - string containing error message if not
            this.login = function(userName, userPassword, callback) {

                var url = serverApiService.ringoServerApiUrl + "login/" + userName;
                // POST will create user if not yet created or return 401 if user has already been created
                commonService.showProgressIndicator();
                $http.post(url, {password: userPassword}, configWithoutAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Login successful.");
                        commonService.hideProgressIndicator();
                        // store auth token permanently
                        localStorageService.setAuthToken(data.authorizationToken);
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        localStorageService.setAuthToken(undefined);
                        console.log("Login failed. Data:" + data + ". status: " + status);
                        callback("Login error: " + status.toString());
                    });
            };

            // Create user
            this.createUser = function(userName, userObject, callback) {

                var createUserUrl = serverApiService.ringoServerApiUrl + "user/" + userName;
                // POST will create user if not yet created or return 401 if user has already been created
                commonService.showProgressIndicator();

                $http.post(createUserUrl, userObject, configWithoutAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Create user succeeded: " + data);
                        commonService.hideProgressIndicator();
                        serverApiService.login(userName, userObject.password, function(result) {
                            callback(result);
                        });
                    }).
                    error(function(data, status, headers, config) {
                        console.log("create user failed. Data:" + data + ". status: " + status);
                        commonService.hideProgressIndicator();
                        callback("Create user error: " + status.toString());
                    });
            };

            // request SMS confirmation for phone phoneNumber (userId).
            // returns callback with true if succeeded or number with error if failed.
            this.requestSMSConfirmationCode = function(phoneNumber, callback) {
                var url = serverApiService.ringoServerApiUrl + "user/confirmPhone/" + phoneNumber;
                commonService.showProgressIndicator();
                $http.post(url, configWithoutAuthHeader()).
                    success(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("SMS requesting failed. Data:" + data + ". status: " + status);
                        callback(status);
                    });
            };

            // checks if user enetered correct SMS confirmation code 'code' for phone 'phoneNumber' (userId).
            // returns callback with true if succeeded or string with error definition if failed.
            this.checkSMSConfirmationCode = function(phoneNumber, code, callback) {
                var url = serverApiService.ringoServerApiUrl + "user/" + phoneNumber + "/confirmationCode/" + code;
                commonService.showProgressIndicator();
                $http.post(url, configWithoutAuthHeader()).
                    success(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        callback(200);
                    }).
                    error(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("checkSMSConfirmationCode returned error. Data:" + data + ". status: " + status);
                        callback(status);
                    });
            };


            // read dashboard from server and return it as the second callback parameter.
            // callback's first paremeter is true if read succeeded or string with error if it failed.
            this.readDashboard = function(callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                };
                //commonService.showProgressIndicator();
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/dashboard";
                $http.get(url, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        //commonService.hideProgressIndicator();
                        callback(true, data);
                    }).
                    error(function(data, status, headers, config) {
                        //commonService.hideProgressIndicator();
                        console.log("Dashboard call failed. Data:" + data + ". status: " + status);
                        callback("Dashboard call failed: " + data, undefined);
                    });
            };


            /// Invites a family member to currently logged in user's family. newMember is an ßobject with:
            ///    name : name (id) of user to add
            /// After inviting user is done - callback will be executed with 2 parameters: status and text.
            /// Status is true if everything is fine and family member has been invited or number indicating error returned by server.
            /// callback gets 'text' string with error message if error happened.
            this.inviteFamilyMember = function(userId, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback(400, "You must log in first!");
                    return;
                }
                commonService.showProgressIndicator();
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/family/invite/" + userId;
                $http.post(url, undefined, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("User invited to family");
                        commonService.hideProgressIndicator();
                        callback(true, "OK");
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Inviting to family call failed: " + status + data);
                        commonService.hideProgressIndicator();
                        callback(status, "Failed. Error code: " + status + ". " + data);
                    });

            };

            /// Join family of inviting user.
            ///    userIdInvitingToJoinFamily : userId of user who invited current user to join his family. Current user will join his family.
            /// After joining family is done - callback will be executed with 1 parameter: status.
            /// Status is true if everything is fine and family member has been joined.
            /// callback gets string with error message if error happened.            ß
            this.acceptInvitationToJoinFamilyFromUser = function(userIdInvitingToJoinFamily, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/family/" + userIdInvitingToJoinFamily;
                commonService.showProgressIndicator();
                $http.post(url, undefined, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("User joined family");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Joining family call failed: " + status + data);
                        commonService.hideProgressIndicator();
                        callback("Failed. Error code: " + status + ". " + data);
                    });

            };


            /// Decline invitation to join family
            ///    invitingUserId : userId of a user who invited us.
            /// After REST call is done - callback will be executed with 1 parameter: status.
            /// Status is true if everything is fine and invitation has been removed.
            /// callback gets string with error message if error happened
            this.declineInvitationToJoinFamilyFromUser = function(invitingUserId, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/family/invite/decline/" + invitingUserId;
                commonService.showProgressIndicator();
                $http.post(url, undefined, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Invitation declined");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Declining invitation call failed: " + status + data);
                        commonService.hideProgressIndicator();
                        callback("Failed. Error code: " + status + ". " + data);
                    });
            };


            /// Remove family member or invited family member.
            ///    userIdToRemove : userId of a user whom to remove from family (or whose invitation to family to remove)
            /// After REST call is done - callback will be executed with 1 parameter: status.
            /// Status is true if everything is fine and family member has been removed.
            /// callback gets string with error message if error happened
            this.removeFamilyMember = function(userIdToRemove, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/family/" + userIdToRemove;
                commonService.showProgressIndicator();
                $http.delete(url, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("User removed from family");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Removing from family call failed: " + status + data);
                        commonService.hideProgressIndicator();
                        callback("Failed. Error code: " + status + ". " + data);
                    });

            };

            /// Invites a friend.
            /// After inviting user is done - callback will be executed with 2 parameters: status and text.
            /// Status is true if everything is fine and friend has been invited or number indicating error returned by server.
            /// callback gets 'text' string with error message if error happened.
            this.inviteFriend = function(userId, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback(400, "You must log in first!");
                    return;
                }
                commonService.showProgressIndicator();
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/friend/" + userId;
                $http.post(url, undefined, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("User invited as a friend");
                        commonService.hideProgressIndicator();
                        callback(true, "OK");
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Inviting to friends call failed: " + status + data);
                        commonService.hideProgressIndicator();
                        callback(status, "Failed. Error code: " + status + ". " + data);
                    });

            };


            /// Deletes friend or declines/cancels friend invitation
            /// After work is done - callback will be executed with 2 parameters: status and text.
            /// Status is true if everything is fine and friend has been removed or number indicating error returned by server.
            /// callback gets 'text' string with error message if error happened.
            this.deleteFriend = function(userId, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback(400, "You must log in first!");
                    return;
                }
                commonService.showProgressIndicator();
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/friend/" + userId;
                $http.delete(url, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("User deleted a friend");
                        commonService.hideProgressIndicator();
                        callback(true, "OK");
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Deleting friend call failed: " + status + data);
                        commonService.hideProgressIndicator();
                        callback(status, "Failed. Error code: " + status + ". " + data);
                    });

            };

            /// Adds a place to currently logged in user. Place is an object with:
            ///    name : name of place
            ///    lat : latitude of place
            ///    lon : longitude of place
            ///    radius : radius of place
            /// After adding place is done - callback will be executed with 2 parameters: status and string.
            /// Status is true if everything is fine and place has been added or it is number with error returned by server.
            // string with error message is a second parameter
            this.addPlace = function(place, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback(400, "You must log in first!");
                    return;
                }

                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/family/place/" + place.name;
                commonService.showProgressIndicator();
                $http.post(url, place, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Place added successfully");
                        commonService.hideProgressIndicator();
                        callback(true, "OK");
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Add place call failed: " + status + ". " + data);
                        commonService.hideProgressIndicator();
                        callback(status, "Failed. Error code: " + status + ". " + data);
                    });

                return true;
            };


            /// Edits a place placeId for currently logged in user. Place is an object with:
            ///    name : name of place
            ///    lat : latitude of place
            ///    lon : longitude of place
            ///    radius : radius of place
            /// After editing place is done - callback will be executed with 2 parameters: status and string.
            /// Status is true if everything is fine and place has been added or it is number with error returned by server.
            /// string with error message is a second parameter
            this.editPlace = function(placeId, place, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback(400, "You must log in first!");
                    return;
                }

                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/family/place/" + placeId;
                commonService.showProgressIndicator();
                $http.put(url, place, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Place edited successfully");
                        commonService.hideProgressIndicator();
                        callback(true, "OK");
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Edit place call failed: " + status + ". " + data);
                        commonService.hideProgressIndicator();
                        callback(status, "Failed. Error code: " + status + ". " + data);
                    });

                return true;
            };

            /// Removes place from family of currently logged in user. Place is a string - name of a place to remove.
            /// After removing place is done - callback will be executed with 1 parameter: status.
            /// Status is true if everything is fine and place has been deleted or it is string with error message
            /// otherwise.
            this.removePlace = function(place, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                }

                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/family/place/" + place;
                commonService.showProgressIndicator();
                $http.delete(url, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Place removed successfully");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Remove place call returned: " + status + ". " + data);
                        commonService.hideProgressIndicator();
                        callback("Did not remove place. Error code: " + status + ". " + data);
                    });

                return true;
            };

            /// Report current location of logged in user to the server.
            ///    position is an object like:
            /// position = {lat: 123.01, lon: 54.12, acc: 23};
            /// callback gets true if position has been reported successfully and
            /// string with error message if error happened.
            this.reportLocation = function(position, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                }

                var param = this._convertLocationToServerLocation(position);
                if (param === undefined) {
                    callback("Location format is unknown: " + position);
                    return;
                }

                commonService.showProgressIndicator();
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/location";
                $http.post(url, param, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Sending position failed with " + status + ". " + data);
                        commonService.hideProgressIndicator();
                        callback("Failed to send position update: " + status + ". " + data);
                    });
            };

            /// Update user's data
            ///    user is an object like:
            /// user = {name: "Oleg F.", icon: "images/defaultAvatar.png"};
            /// callback gets true if info has been reported successfully and
            /// string with error message if error happened.
            this.updateCurrentUserInfo = function(user, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("updateCurrentUserInfo: you must log in first!");
                    return;
                }

                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName();
                commonService.showProgressIndicator();
                $http.put(url, user, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("Updating user info failed with " + status + ". " + data);
                        callback("Failed to update user info: " + status + ". " + data);
                    });
            };

            this._convertLocationToServerLocation = function(location) {
                if (location === undefined || location.latitude === undefined || location.longitude === undefined || location.accuracy === undefined) {
                        return undefined;
                }
                var serverFormat = {};
                serverFormat.lat = location.latitude;
                serverFormat.lon = location.longitude;
                serverFormat.acc = location.accuracy;

                return serverFormat;
            };

            /// callback gets string with error message if error happened.
            this.getRingoUsers = function(userList, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/usersregistered";
                commonService.showProgressIndicator();
                var param = {userList: userList};
                $http.post(url, param, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("User contacts sent to server.");
                        callback(data);
                    }).
                    error(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("Sending user contacts failed: " + status + data);
                        callback("Failed. Error code: " + status + ". " + data);
                    });

            };

            /// executes callback(true) if succeeded or callback with error message as string if failed
            this.uploadNewAvatar = function(avatarJpgDataInBase64, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/avatar";
                var param = {avatarImageData: avatarJpgDataInBase64};
                commonService.showProgressIndicator();
                $http.post(url, param, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("Updated avatar successfuly");
                        callback(data);
                    }).
                    error(function(data, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("Updating avatar failed: " + status + ", " + data);
                        callback("Updating avatar failed. Error code: " + status + ". " + data);
                    });

            };


            // send device token for this user to be used by remote notification service
            // executes callback with true if succeeded or error message if failed
            this.registerForRemoteNotifications = function(deviceToken, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("registerForRemoteNotifications: You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/apnToken/" + localStorageService.getUserName();
                var param = {apnToken: deviceToken};
                commonService.showProgressIndicator();
                $http.post(url, param, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Successfully set token");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to set apn token: " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback("Failed to set apn token. Error code: " + status + ". " + data);
                    });
            };


            this.registerForGCMRemoteNotifications = function(token, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("registerForGCMRemoteNotifications: You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/gcmToken/" + localStorageService.getUserName();
                var param = {gcmToken: token};
                commonService.showProgressIndicator();
                $http.post(url, param, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Successfully set token");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to set gcm token: " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback("Failed to set gcm token. Error code: " + status + ". " + data);
                    });
            };

            this.registerForWP8RemoteNotifications = function(URL, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("registerForWP8RemoteNotifications: You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/wp8NotificationURL";
                var param = {wp8Url: URL};
                commonService.showProgressIndicator();
                $http.post(url, param, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Successfully set URL");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to set wp8 URL: " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback("Failed to set wp8 URL. Error code: " + status + ". " + data);
                    });
            };


            this.forgotPassword = function(phoneNumber, callback) {
                if (phoneNumber === undefined || phoneNumber === "") {
                    callback("forgotPassword: empty phone number!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/forgotPassword/" + phoneNumber;
                commonService.showProgressIndicator();
                $http.post(url, undefined, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Successfully posted reminding password");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to call forgot password service: " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback(status);
                    });

            };


            /// Method for feedback sending to Backend.

            this.nps = function(data, callback) {
                var username = localStorageService.getUserName();
                if (username === undefined) {
                    callback("You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "nps/" + username;
                var url_2 = "https://statistics.f-secure.com/upstream/v1/";
                var param = {'type': 'NPS', 'product': 'Lokki', 'version': 0.1, 'data': data};

                commonService.showProgressIndicator();
                $http.post(url, param, configWithAuthHeader()).

                    success(function(dataResponse, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("Feedback sent successfuly to main NPS server");
                        // Make 2nd post request to NPS server 2
                        $http.post(url_2, JSON.stringify(param)).
                            success(function(dataResponse, status, headers, config) {
                                commonService.hideProgressIndicator();
                                console.log("Feedback sent successfuly to 2nd NPS server");
                                callback(null, dataResponse);
                            }).
                            error(function(dataResponse, status, headers, config) {
                                commonService.hideProgressIndicator();
                                console.log("Feedback sending to 2nd NPS server failed: " + status + ", " + dataResponse);
                                callback("Sending NPS to 2nd server failed. Error code: " + status + ". " + dataResponse, null);
                            });
                    }).
                    error(function(dataResponse, status, headers, config) {
                        commonService.hideProgressIndicator();
                        console.log("Feedback sending to main NPS server failed: " + status + ", " + dataResponse);
                        callback("Sending NPS to main server failed. Error code: " + status + ". " + dataResponse, null);
                    });

            };


            this.sendMessageToUser = function(userId, message, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("sendMessageToUser: You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/message/" + userId;
                var param = message;
                commonService.showProgressIndicator();
                $http.post(url, param, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Successfully sent message");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to send message: " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback(status);
                    });
            };


            this.readMessagesFromUser = function(userId, sinceTimestamp, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("readMessagesFromUser: You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/message/" + userId;
                if (sinceTimestamp) {
                    url = url + "/" + sinceTimestamp;
                }
                commonService.showProgressIndicator();
                $http.get(url, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        //console.log("Successfully got messages");
                        commonService.hideProgressIndicator();
                        callback(true, data);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to get messages: " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback(status);
                    });
            };

            //timestamp - lastReadMessageTimestamp
            this.markMessagesReadFromUser = function(userId, timestamp, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("markMessagesReadFromUser: You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/message/" + userId;
                commonService.showProgressIndicator();
                $http.put(url, {lastReadMessageTimestamp: timestamp}, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        //console.log("Successfully marked read messages");
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to mark read messages: " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback(status);
                    });
            };

            this.manuallyCheckInToPlace = function(placeId, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("manuallyCheckInToPlace: You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/checkIn/" + placeId;
                commonService.showProgressIndicator();
                $http.post(url, {}, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Successfully checked into " + placeId);
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to check into " + placeId + ": " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback(status);
                    });
            };

            this.manuallyCheckOutOfPlace = function(placeId, callback) {
                if (localStorageService.getUserName() === undefined) {
                    callback("manuallyCheckOutOfPlace: You must log in first!");
                    return;
                }
                var url = serverApiService.ringoServerApiUrl + "user/" + localStorageService.getUserName() + "/checkOut/" + placeId;
                commonService.showProgressIndicator();
                $http.post(url, {}, configWithAuthHeader()).
                    success(function(data, status, headers, config) {
                        console.log("Successfully checked out of " + placeId);
                        commonService.hideProgressIndicator();
                        callback(true);
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Failed to check out of " + placeId + ": " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback(status);
                    });
            };

        // executes callback with first parameter - success (true, false) and second - location object if success===true
            // location object will include: {lat: 111, lon: 222, displayName: "Soukka, Suomi"}
            this.searchForAddressLocation = function(address, callback) {

                var url = "http://open.mapquestapi.com/nominatim/v1/search.php?format=json&q=" + address;
                commonService.showProgressIndicator();
                $http.post(url).
                    success(function(data, status, headers, config) {
                        //console.log("Successfully got address data: " + JSON.stringify(data));
                        commonService.hideProgressIndicator();
                        if (data && data.length) {
                            var location = {};
                            location.lat = +data[0].lat;
                            location.lon = +data[0].lon;
                            location.displayName = data[0].display_name;
                            callback(true, location);
                        } else {
                            callback(false, undefined);
                        }
                    }).
                    error(function(data, status, headers, config) {
                        console.log("Cannot get address data " + status + ", " + data);
                        commonService.hideProgressIndicator();
                        callback(false, undefined);
                    });


            };

            this.getCountry = function(callback) {
                // userid: 711012ca29304cbe460078eb111b8ae16ff59d2ec0742d59aea0511043623360
                // account registered for Oleg Fedorov (oleg.fedorov@f-secure.com)

                var url = "http://api.ipinfodb.com/v3/ip-country/?key=711012ca29304cbe460078eb111b8ae16ff59d2ec0742d59aea0511043623360&format=json";
                //var url = "http://freegeoip.net/xml/";
                //commonService.showProgressIndicator();
                $http.get(url).
                    success(function(data, status, headers, config) {
                        //console.log("Successfully got address data: " + data + JSON.stringify(data));
                        //console.log("Data: " + JSON.stringify(status) + JSON.stringify(headers) + JSON.stringify(config));
                        //commonService.hideProgressIndicator();
                        if (data && data['statusCode'] == 'OK') {
                            //console.log("OK");
                            callback(true, data.countryCode);
                        } else {
                            //console.log("NOT OK");
                            callback(false, undefined);
                        }
                    }).
                    error(function(data, status, headers, config) {
                        //console.log("Cannot get country data " + status + ", " + data);
                        //commonService.hideProgressIndicator();
                        callback(false, undefined);
                    });

            }

    }])
;
