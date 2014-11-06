/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 23.04.2013 10:52
 */

'use strict';

/// localStorageService is a service to keep persistent data.
/// Functions:
///    setUserName(userName); - save user name to persistent storage
///    var userName = getUserName(); - read user name from persistent storage or return null if not in storage yet
angular.module("ringo.services")
        .service("localStorageService", [function(){

            this.setValue = function(key, value) {
                if (value === undefined) {
                    localStorage.removeItem(key);
                } else {
                    localStorage.setItem(key, value);
                };
            };

            this.getValue = function(key) {
                var val = localStorage.getItem(key);
                return val || undefined;
            };

            // Set current user name
            this.setUserName = function(userName) {
                this.setValue("userName", userName);
            };


            // get current user name. Will return undefined if user name is not yet set
            this.getUserName = function() {
                return this.getValue("userName");
            };

            // returns true if user is logged in and false if not
            this.isUserLoggedIn = function() {
                return (this.getValue("authToken") !== undefined);
            };

            this.setConfirmationCode = function(pinCodeForConfirmation) {
                this.setValue("pinCodeForConfirmation", pinCodeForConfirmation);
            };

            this.getConfirmationCode = function() {
                return this.getValue("pinCodeForConfirmation");
            };

            this.setAuthToken = function(token) {
                this.setValue("authToken", token);
            };

            this.getAuthToken = function() {
                return (this.getValue("authToken") || "no token found");
            };

            this.setLocationReportingEnabled = function(enabled) {
                if (enabled === true) {
                    this.setValue("locationReportingEnabled", "true");
                } else {
                    this.setValue("locationReportingEnabled", "false");
                }
            };

            this.isLocationReportingEnabled = function() {
                var strVal = this.getValue("locationReportingEnabled");
                if (strVal === "false") {
                    return false;
                }
                return true;
            };


            this.setDashboardShouldShowEmptyPlaces = function(enabled) {
                if (enabled === true) {
                    this.setValue("dashboardShouldShowEmptyPlaces", "true");
                } else {
                    this.setValue("dashboardShouldShowEmptyPlaces", "false");
                }
            };

            this.shouldDashboardShowEmptyPlaces = function() {
                var strVal = this.getValue("dashboardShouldShowEmptyPlaces");
                if (strVal === "false") {
                    return false;
                }
                return true;
            };

            // save dashboard object to persistent storage
            this.setDashboard = function(dashboard) {
                this.setValue("dashboard", JSON.stringify(dashboard));
            };

            // returns dashboard object from persistent storage. will return undefined if dashboard is not yet set.
            this.getDashboard = function() {
                var dashboard = localStorage.getItem("dashboard");
                if (dashboard) {
                    try {
                        return JSON.parse(dashboard);
                    } catch(err) {
                        return undefined;
                    }
                }
                return undefined;
            };


            this.getLanguage = function() {
                var lang = this.getValue("language");
                if (lang) {
                    return lang;
                }

                return "en-US";
            };

            this.setLanguage = function(language) {
                this.setValue("language", language);
            };
        }])
;






