 /*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 30.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
    .controller("inviteFamilyMemberController", ["$scope", "$location", "localize", "ringoAppService", "serverApiService", "commonService", "validationService", "localStorageService",
        function ($scope, $location, localize, ringoAppService, serverApiService, commonService, validationService, localStorageService) {
            $scope.inBrowser = ((window.device) ? false : true);
            $scope.invitingFriend = ($location.path().indexOf("inviteFriend") !== -1);
            $scope.invitingFamilyMember = !$scope.invitingFriend;

            $scope.returnPath = localStorageService.getValue("inviteFamilyMemberControllerReturnPath");
            localStorageService.setValue("inviteFamilyMemberControllerReturnPath", undefined);
            if (!$scope.returnPath) {
                $scope.returnPath = "/dashboard";
            }

            var haveFamily = function() {
                var dashboard = ringoAppService.getDashboard();
                if (dashboard === undefined || dashboard.family === undefined || commonService.isObjectEmpty(dashboard.family.members)) {
                    return false;
                }
                return true;
            };
            $scope.haveUsersToShow = false;// true if ringoUsers is not empty
            $scope.queryInProgress = false;

            if ($scope.invitingFriend) {
                $scope.startFamily = false;
                $scope.addToFamily = false;
                $scope.addToFriends = true;
            } else {
                $scope.startFamily = !haveFamily();  // true when user does not have family yet (no family members). becomes false after "Choose contacts" is clicked)
                $scope.addToFamily = haveFamily(); // true when user does have family already. becomes false after "Choose contacts" is clicked)
                $scope.addToFriends = false;
            }

            $scope.tellFriends = function() {
                localStorageService.setValue("inviteFamilyMemberControllerReturnPath", $scope.returnPath);
                localStorageService.setValue("tellFriendViaControllerReturnPath", $location.path());
                $location.path("/tellFriendVia");
            };

            $scope.inviteFromBrowser = function() {
                var phone = validationService.validateAndConvertPhoneNumber($scope.browserPhoneNumber);
                if (phone === "") {
                    commonService.showMessageToUser("error.wrongPhoneFormat", "error.title.error");
                } else {
                    $scope.contactClicked(phone);
                }
            };

            $scope.inviteFamilyMember = function (userId) {
                console.log("Inviting family member: " + userId);
                serverApiService.inviteFamilyMember(userId, $scope.onInvitingFamilyMemberFinished);
            };

            $scope.inviteFriend = function (userId) {
                console.log("Inviting friend: " + userId);
                serverApiService.inviteFriend(userId, $scope.onInvitingFriendFinished);
            };

            $scope.backButtonClicked = function() {
                commonService.hideProgressIndicator();
                $location.path($scope.returnPath);
            };

            $scope.onInvitingFamilyMemberFinished = function (status, text) {
                console.log("Inviting member finished with: " + status + ", " + text);
                if (status !== true) {
                    if (status === serverApiService.errorCodes.FAMILY_MEMBERS_LIMIT) {
                        commonService.showMessageToUser("error.familyMembersLimit", "error.title.limit");
                    } else {
                        if (status === serverApiService.errorCodes.CANNOT_INVITE_FRIENDS_TO_FAMILY) {
                            commonService.showMessageToUser("error.cannotInviteFriendsToFamily", "error.title.limit");
                        } else {
                            commonService.showMessageToUser("error.familyInvitationFailed", "error.title.error");
                        }
                    }
                } else {
                    $location.path("/dashboard");
                }
            };

            $scope.onInvitingFriendFinished = function (status, text) {
                console.log("Inviting friend finished with: " + status + ", " + text);
                if (status !== true) {
                    if (status === serverApiService.errorCodes.FRIENDS_LIMIT) {
                        commonService.showMessageToUser("error.friendsLimit", "error.title.limit");
                    } else {
                        if (status === serverApiService.errorCodes.CANNOT_INVITE_FAMILY_TO_FRIENDS) {
                            commonService.showMessageToUser("error.cannotInviteFamilyMemberToFriends", "error.title.limit");
                        } else {
                            commonService.showMessageToUser("error.friendInvitationFailed", "error.title.error");
                        }
                    }
                } else {
                    $location.path("/dashboard");
                }
            };

            var removeUsersWhoAlreadyInFamilyOrInFriends = function(ringoUsers) {
                var dashboard = ringoAppService.getDashboard();
                if (dashboard === undefined || dashboard.family === undefined) {
                    return ringoUsers;
                }
                var newUsers = new Array();
                for (var i = 0; i < ringoUsers.length; i++) {
                    var user = ringoUsers[i];
                    var userPhone = "";
                    if (user.hasOwnProperty("phoneNumber") && user["phoneNumber"] !== dashboard.userId) {
                        userPhone = user["phoneNumber"];
                        var isFriend = (dashboard.friends && dashboard.friends.indexOf(userPhone) !== -1);
                        var isFamilyMember = (dashboard.family.members && dashboard.family.members.hasOwnProperty(userPhone));
                        var isInvitedFamilyMember = (dashboard.family.invitedMembers && dashboard.family.invitedMembers.indexOf(userPhone) !== -1);
                        var isPendingFriend = (dashboard.family.pendingFriends && dashboard.family.pendingFriends.indexOf(userPhone) !== -1);
                        if (!isFriend &&
                            !isPendingFriend &&
                            !isFamilyMember &&
                            !isInvitedFamilyMember) {
                                newUsers.push(user);
                        }
                    }
                }
                return newUsers;
            };

            $scope.checkPhoneContacts = function () {
                var ringoUsers = localStorage.getItem("ringoUsers") || undefined;

                if (ringoUsers) {
                    console.log('ringoUsers:', ringoUsers);
                    $scope.ringoUsers = JSON.parse(ringoUsers); // Show cached contacts that use Ringo
                    $scope.ringoUsers = removeUsersWhoAlreadyInFamilyOrInFriends($scope.ringoUsers);
                    $scope.haveUsersToShow = $scope.ringoUsers !== undefined;
                }
                console.log("checkPhoneContacts");
                if (window.device) {
                    if (!$scope.ringoUsers) {
                        $scope.queryInProgress = true;
                    }
                    var options = new ContactFindOptions();
                    options.filter = ""; // All contacts
                    options.multiple = true;
                    var fields = ["name", "phoneNumbers"];
                    commonService.showProgressIndicator();
                    navigator.contacts.find(fields, $scope.checkPhoneContactsSuccess, $scope.checkPhoneContactsError, options);
                }
            };

            // Create array with ALL phone numbers and push it to ringo-server
            $scope.checkPhoneContactsSuccess = function (contacts) {
                commonService.hideProgressIndicator();
                console.log("checkPhoneContactsSuccess: " + contacts.length + " contacts found.");
                var contactsObject = {};
                var contactsNumber = 0;
                for (var i = 0; i < contacts.length; i++) {
                    try {
                        var phoneNumber = null;
                        for (var j = 0; j < contacts[i].phoneNumbers.length; j++) {
                            phoneNumber = validationService.validateAndConvertPhoneNumber(contacts[i].phoneNumbers[j]["value"]);

                            if (phoneNumber !== "") {
                                contactsObject[phoneNumber] = contacts[i].name.formatted;
                                contactsNumber++;
                            }
                        }
                    } catch (error) {}
                }
                $scope.checkRegisteredUsers(contactsObject);

            };

            $scope.checkPhoneContactsError = function (contactError) {
                $scope.queryInProgress = false;
                commonService.hideProgressIndicator();
                console.log("checkPhoneContactsError: " + contactError);
                commonService.showMessageToUser("error.failedToQueryPhoneContacts", "error.title.error");
            };

            $scope.contactClicked = function (phoneNr) {
                console.log('Contact clicked: ' + phoneNr);
                if ($scope.invitingFriend) {
                    $scope.inviteFriend(phoneNr);
                } else {
                    $scope.inviteFamilyMember(phoneNr);
                }
            };

            // Create a list of phone numbers to check, and send it to the ringo-server
            $scope.checkRegisteredUsers = function (contactsObject) {
                var userList = [];
                for (var key in contactsObject)
                    if (contactsObject.hasOwnProperty(key))
                        userList.push(key.replace('+', ''));
                //console.log('Data being sent:' + JSON.stringify(userList));

                serverApiService.getRingoUsers(userList, function (data) {

                    $scope.queryInProgress = false;
                    if (typeof data === "string") {
                        commonService.showMessageToUser("error.serverQueryFailed", "error.title.error");
                    } else {
                        var ringoUsers = new Array();
                        for (var i = 0; i < data.length; i++) {
                            var url = 'http://ringo-server.f-secure.com/files/avatars/' + data[i] + '.jpg';
                            var cachedUrl = commonService.getFetchedImageURI(url);
                            if (cachedUrl) {
                                url = cachedUrl;
                            } else {
                                url = url + "?t=" + data[i];
                            }
                            ringoUsers.push({ 'name': contactsObject[data[i]], 'img': commonService.fetchImage(url), 'phoneNumber': data[i] });
                        }
                        console.log('ringoUsers: ' + JSON.stringify(ringoUsers));
                        $scope.ringoUsers = removeUsersWhoAlreadyInFamilyOrInFriends(ringoUsers);
                        $scope.haveUsersToShow = $scope.ringoUsers !== [];
                        localStorage.setItem("ringoUsers", JSON.stringify(ringoUsers));
                    }
                });
            };

            $scope.chooseContacts = function(){
                $scope.startFamily = false;
                $scope.addToFamily = false;
                $scope.addToFriends = false;
                console.log('Show contact list button pressed.');
            };

            $scope._shareLokkiOnFacebook = function() {
                var params = {
                    method: 'feed',
                    name: localize.getLocalizedString("invite.facebook.header"),
                    link: 'http://lok.ki',
                    picture: 'http://lok.ki/wp-content/uploads/2013/08/icon96.png',
                    description: localize.getLocalizedString("invite.facebook.description")
                };
                FB.ui(params, function(obj) {
                    console.log("FB.ui returned: " + JSON.stringify(obj));
                });
            };

            $scope.shareOnFacebookButtonClicked = function () {

                if (window.plugins && window.plugins.Share) {
                    var title = localize.getLocalizedString("invite.facebook.header");
                    var msg = localize.getLocalizedString("invite.facebook.description")

                    plugins.Share.shareLink({
                        url: "http://lok.ki",
                        title: title,
                        message: msg
                    });
                    return;
                }

                if (typeof CDV == 'undefined') console.log('CDV variable does not exist');
                if (typeof FB == 'undefined') console.log('FB variable does not exist. Check that you have included the Facebook JS SDK file.');

                if (!FB) {
                    return;
                }

                FB.getLoginStatus(function(response) {
                    if (response.authResponse) {
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

            setTimeout(function() {$scope.checkPhoneContacts();}, 10);// give time for initial update of UI

    }]);


