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
        .service("commonService", ["localize", "$rootScope", "localStorageService", function(localize, $rootScope, localStorageService){

            var platform = ((window.device) ? window.device.platform : "browser");
            if (platform === "Android") {
                this.version = "2.6.6";

            } else if (platform === "iOS") {
                this.version = "2.2.0";

            } else if (platform === "Win32NT") {
                this.version = "2.0.0";

            } else {
                this.version = "X.X.X";
            }

            this.allPossiblePlaceShapes = [
                "house_pyramid",
                "house_flat",
                "house_skillion",
                "house_school",
                "place_office",
                "place_amusement",
                "house1",
                "house_arched",
                "house_cross_gabled",
                "park",
                "place_stadium",
                "seaside",
                "factory",
                "place_shopping_mall",
                "place_playground",
                "place_shop",
                "place_restaurant",
                "downtown",
                "house_hip",
                "place_lyceum",
                "house_saltbox",
                "place_mosque",
                "place_church",
                "place_church_o",
                "place_orient_temple",
                "place_terminal",
                "place_desert",
                "place_house_middleeast"
            ];

            this.allPossibleLanguages = [
                {
                    id: "en-US",
                    name: "English"
                },
                {
                    id: "es-ES",
                    name: "español"
                },
                {
                    id: "ru-RU",
                    name: "Русский"
                },
                {
                    id: "fi-FI",
                    name: "suomi"
                },
                {
                    id: "sv-SE",
                    name: "Svenska"
                },
                 {
                    id: "bg-BG",
                    name: "Български"
                },
                {
                    id: "cs-CZ",
                    name: "Čeština"
                },
                {
                    id: "da-DK",
                    name: "Dansk"
                },
                {
                    id: "de-DE",
                    name: "Deutsch"
                },
                {
                    id: "el-GR",
                    name: "Ελληνικά"
                },
                {
                    id: "es-MX",
                    name: "Español - América Latina"
                },
                {
                    id: "et-EE",
                    name: "Eesti"
                },
                {
                    id: "fr-CA",
                    name: "Français - Canada"
                },
                {
                    id: "fr-FR",
                    name: "Français"
                },
                {
                    id: "hu-HU",
                    name: "Magyar"
                },
                {
                    id: "it-IT",
                    name: "Italiano"
                },
                {
                    id: "ja-JP",
                    name: "日本語"
                },
                {
                    id: "ko-KR",
                    name: "한국어(대한민국)"
                },
                {
                    id: "nl-NL",
                    name: "Nederlands"
                },
                {
                    id: "no-NO",
                    name: "Norsk"
                },
                {
                    id: "pl-PL",
                    name: "Polski"
                },
                {
                    id: "pt-BR",
                    name: "Português brasileiro"
                },
                {
                    id: "pt-PT",
                    name: "Português"
                },
                {
                    id: "ro-RO",
                    name: "Română"
                },
                {
                    id: "sl-SI",
                    name: "Slovenščina"
                },
                {
                    id: "tr-TR",
                    name: "Türkçe"
                },
                {
                    id: "vi-VN",
                    name: "Tiếng Việt"
                },
                {
                    id: "zh-CN",
                    name: "简体中文"
                },
                {
                    id: "zh-HK",
                    name: "繁體中文(香港)"
                },
                {
                    id: "zh-TW",
                    name: "繁體中文(臺灣)"
                }
            ];

            if (window.ImgCache) {
                ImgCache.init(
                    function() {
                        //ImgCache.clearCache();//FOR TESTING
                    },
                    function() {
                        console.log("ImgCache initialization failed");

                    }
                );
            }


        // Sets default language on first startup
            if (localStorageService.getValue("language") === undefined && localize.language) {
                var lang = localize.language;
                var selected = false;
                for (var i = 0; i < this.allPossibleLanguages.length; i++)
                {
                    if(this.allPossibleLanguages[i].id.toUpperCase() == lang.toUpperCase())
                    {
                        lang = this.allPossibleLanguages[i].id;
                        selected = true;
                        break;
                    }
                }

                if (selected) {
                    console.log("defaulting to user language:" + lang);
                    localStorageService.setLanguage(lang);
                } else {
                    console.log("unsupported default language:" + lang + " falling back to en-US");
                    localStorageService.setLanguage("en-US");
                }
            }



            this.showProgressIndicator = function() {
                document.getElementById("progress").style.visibility='visible';
            };
            this.hideProgressIndicator = function() {
                document.getElementById("progress").style.visibility='hidden';
            };

            // return name for language ID (getLanguageName("en-US") returns "English")
            this.getLanguageName = function(languageID) {
                for(var l in this.allPossibleLanguages) {
                    if (this.allPossibleLanguages.hasOwnProperty(l)) {
                        if (this.allPossibleLanguages[l].id === languageID) {
                            return this.allPossibleLanguages[l].name;
                        }
                    }
                }
                return this.allPossibleLanguages[0].name;
            };

            // opens URL in external browser
            this.openURLInExternalBrowser = function(url, preferSystemRoutine) {
                console.log("openURLInExternalBrowser: " + url);
                var platform = ((window.device) ? window.device.platform : "browser");
                if (platform === "Android") {
                    //window.open(url, (preferSystemRoutine) ? '_system' : '_blank');
                    // DON'T CHANGE THIS OR IT WILL OPEN BROWSER IN ANDROID DEVICES!!!
                    document.location.href = url;
                } else if (platform === "iOS" || platform === "Win32NT" ) {
                    window.open(url, (preferSystemRoutine) ? '_system' : '_blank');
                } else if (platform === "browser") {
                    var win = window.open(url, '_blank');
                    win.focus();
                } else {
                    alert("Unsupported platform: " + platform);
                }
            };
             
            // shows location on map. location must be an object in dashboard format: {lat: 111, lon:222, radius: 100}
            //// Coma and period fixed by encoding the coma into %2C
            //If you provide successCallback then it gets executed when map was shown and closed by user and it receives single parameter - new location in format:  {lat: 1, lon: 2, radius: 19}.
            //Failed callback is executed if failure occures.
            //    Note: some platforms or situations may not call failure or success callback at all!
            this.showLocationOnMap = function(location, successCallback, failureCallback) {
                var platform = ((window.device) ? window.device.platform : "browser");
                var latStr = "" + location.lat;
                var lonStr = "" + location.lon;
                //var radStr = "" + location.radius;
                if (platform === "Android") {
                    plugins.Maps.showLocation(location, successCallback, failureCallback); // Or create string already lat,lon
                } else if (platform === "iOS") {
                    plugins.Maps.showLocation(location, successCallback, failureCallback);
                } else if (platform === "Win32NT") { // wp8
                    plugins.Maps.showLocation(location, successCallback, failureCallback);
                } else if (platform === "browser") {
                    this.openURLInExternalBrowser('http://maps.google.com/?q=' + latStr + '%2C' + lonStr);
                } else {
                    alert("Unsupported platform: " + platform);
                }
            };

            // Opens standard email app with prefilled address, text and subject
            this.openEmailApp = function(address, subject, body) {
                var platform = ((window.device) ? window.device.platform : "browser");
                var emailURL = "mailto:" + address;
                var bodyText = "Body=";
                var subjectText = "Subject=";
                if (platform === "Android") {
                    bodyText = "body=";
                    subjectText = "subject=";
                }

                if (body) {
                    emailURL += "?" + bodyText + encodeURIComponent(body);
                }
                if (subject) {
                    emailURL += ((body) ? "&" : "?");
                    emailURL += subjectText + encodeURIComponent(subject);
                }
                this.openURLInExternalBrowser(emailURL, true);
            };


            // returns true if object obj is empty ({}) or false if it has any members
            this.isObjectEmpty = function(obj) {
                for(var m in obj) {
                    if (obj.hasOwnProperty(m)) {
                        return false;
                    }
                }
                return true;
            };

            // returns distance in meters between 2 positions. positions must have this format: {lat: 123, lon: 234}
            this.distanceBetween2Positions = function(pos1, pos2) {
                if (pos1 === undefined || pos2 === undefined || pos1.lat === undefined || pos1.lon === undefined || pos2.lat === undefined || pos2.lon === undefined) {
                    return 0;
                }
                var rad = function(x) {return x*Math.PI/180;}

                var R = 6371; // earth's mean radius in km
                var dLat  = rad(pos2.lat - pos1.lat);
                var dLong = rad(pos2.lon - pos1.lon);

                var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                    Math.cos(rad(pos1.lat)) * Math.cos(rad(pos2.lat)) * Math.sin(dLong/2) * Math.sin(dLong/2);
                var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                var d = R * c;

                return d.toFixed(3)*1000;//in meters
            };

            this.getLocalizedString = function(stringId) {
                return localize.getLocalizedString(stringId);
            };


            // shows message (error) to user with native looking dialog with one button.
            // Shows message with title 'title' and button title buttonTile and calls callback when user presses button.
            // Default button title is "OK".
            // message and title must be defined. Everything else is optional.
            // note: callback does not work in browser
            this.showMessageToUser = function(message, title, buttonTitle) {
                var localizedMessage = localize.getLocalizedString(message);
                var localizedTitle = localize.getLocalizedString(title);
                var localizedButtonTitle = ((buttonTitle) ? localize.getLocalizedString(buttonTitle) : localize.getLocalizedString("message.button.ok"));
                console.log(message);
                if (navigator.notification) {
                    navigator.notification.alert(localizedMessage, function () {}, localizedTitle, localizedButtonTitle);
                } else {
                    alert(localizedMessage);
                }
            };

            // asks user's confirmation with defined message and title (should be id's from resources-locale_xxxx.json).
            // Uses native looks and feel for dialogs if possible.
            // You can define comma separated buttonLabels to set your own buttons, by default it is "OK,Cancel".
            // executes callback with 1 parameter in the end: ID of clicked button (starting from index 1) or 0 if no button was clicked.
            // So, it returns 1 for first button and 2 for seconds.
            // In browser it ignores buttonLabels and title and always uses "OK,Cancel" so can call callback only with 1 and 2. Also this call is blocking in browser
            // Example: commonService.askUserConfirmation("confirm.deletePlace", "confirm.title", function(sel) {if (sel===1) {onDeletePlace()}}, "confirm.buttons.confirmOrCancel");
            this.askUserConfirmation = function(message, title, callback, buttonLabels) {
                var localizedMessage = localize.getLocalizedString(message);
                var localizedTitle = localize.getLocalizedString(title);
                var localizedButtonLabels = ((buttonLabels) ? localize.getLocalizedString(buttonLabels) : localize.getLocalizedString("confirm.buttons.default"));
                console.log(message);
                if (navigator.notification) {
                    navigator.notification.confirm(localizedMessage, callback, localizedTitle, localizedButtonLabels);
                } else {
                    var r = confirm(localizedMessage);
                    if (r == true) {
                        callback(1);
                    } else {
                        callback(2);
                    }
                }
            };

            // parse 03AA9746-EA19-42D7-9DD1-1B0218EA8342 from path like "/var/mobile/Applications/03AA9746-EA19-42D7-9DD1-1B0218EA8342/Documents/imgcache"
            var getUUIDFromPath = function(path) {
                var docsInPath = path.indexOf("/Documents/imgcache");
                var UUIDinPath;
                if (docsInPath !== -1) {
                    UUIDinPath = path.substring(0, docsInPath);
                    var lastSlash = UUIDinPath.lastIndexOf("/");
                    UUIDinPath = UUIDinPath.substring(lastSlash);
                }
                return UUIDinPath;
            };


            var isReDownloadRequiredForFile = function(fileName) {
                var reDownloadRequired = false;
                var platform = ((window.device) ? window.device.platform : "browser");
                if (platform === "iOS" && ImgCache.dirEntry && ImgCache.dirEntry.fullPath) {
                    // ImgCache.dirEntry.fullPath is like "/var/mobile/Applications/03AA9746-EA19-42D7-9DD1-1B0218EA8342/Documents/imgcache"
                    // fileName is like "file://localhost/var/mobile/Applications/F00E80E4-CB36-4262-B67D-9DD4BF9EDCEB/Documents/imgcache/382669ca7fdbd044b76380e7cd3225483ca3b9c6.jpg"
                    // we need to detect that app id did not change
                    reDownloadRequired = (getUUIDFromPath(ImgCache.dirEntry.fullPath) !== getUUIDFromPath(fileName));
                    if (reDownloadRequired) {
                        console.log("! Redownloading because " +  getUUIDFromPath(ImgCache.dirEntry.fullPath) + " !== " + getUUIDFromPath(fileName));
                    }
                }
                return reDownloadRequired;
            };

            // returns stored timestamp if url has been stored already to local cache.
            // so, if this returns not undefined then you can use returned URI in fetchImage to get cached url
            this.getFetchedImageURI =  function(url) {
                if (!window.ImgCache) {
                    return undefined;
                }
                var cachedTimestamp = localStorage.getItem("CacheURL:" + url);
                var oldFile = localStorage.getItem("CacheTS:" + cachedTimestamp);
                if (cachedTimestamp && oldFile) {

                    if (isReDownloadRequiredForFile(oldFile)) {
                        oldFile = undefined;
                    }

                    return oldFile;
                }
                return undefined;
            };


            var fetchInProgressForURI = {};

            // fetch and cache uri. returns link to local file if already cached or to the same URI if not yet cached and runs caching in background
            this.fetchImage = function(uri) {
                if (!window.ImgCache) {
                    return uri;
                }

                if (fetchInProgressForURI[uri]) {
                    return uri;// don't try to fetch again if already fetching
                }

                if (uri.indexOf('http://') !== 0) return uri; // If image is already in Base64 format

                var urlData = uri.split("?t=");
                var timestamp = "0";
                if (urlData.length == 2) timestamp = urlData[1];
                var url = urlData[0];

                var cachedTimestamp = localStorage.getItem("CacheURL:" + url);
                var oldFile = localStorage.getItem("CacheTS:" + cachedTimestamp);

                if (cachedTimestamp && cachedTimestamp === timestamp && oldFile) {

                    // we have changing root folder bug in iOS so detect it and cause redownload!
                    if (!isReDownloadRequiredForFile(oldFile)) {
                        ImgCache.isCached(uri,
                            function(src, cached) {
                                if (!cached) {
                                    console.log("fetchImage something happened with cache, rebuild it for " + uri);
                                    localStorage.removeItem("CacheTS:" + cachedTimestamp);// next time it will be redownloaded
                                }
                            }
                        );
                        return oldFile;
                    }
                }

                fetchInProgressForURI[uri] = 1;
                ImgCache.cacheFile(uri,
                    function(cachedUrl) {
                        fetchInProgressForURI[uri] = undefined;

                        var oldURI = (url + "?t=" + cachedTimestamp);
                        if (oldFile && cachedTimestamp && oldURI !== uri) {
                            ImgCache.deleteCachedFile(oldURI, function() {
                                },
                                function() {
                                    console.error("Failed to delete old file " + oldURI);
                                });
                        }
                        //succeeded
                        localStorage.removeItem("CacheTS:" + cachedTimestamp);//remove old ts
                        localStorage.setItem("CacheURL:" + url, timestamp);
                        localStorage.setItem("CacheTS:" + timestamp, cachedUrl);
                        // Broadcast
                        $rootScope.$broadcast('imageCached', {'uri': uri});
                    },
                    function() {
                        fetchInProgressForURI[uri] = undefined;
                        //fail
                        if (ImgCache.filesystem && ImgCache.dirEntry) {
                            console.log("Failed to cache " + uri);
                        }
                    }
                );

                if (oldFile) {
                    return oldFile;
                } else {
                    return uri; // Return the raw url since not yet cached.
                }
            };


            this.getDistanceText = function(pos1, pos2) {
                var dist = this.distanceBetween2Positions(pos1, pos2);
                dist = Math.ceil(dist);
                var distanceType = "placeDetails.distanceFromYou.meters";
                if (dist > 3000) {
                    dist = (dist/1000).toFixed(0);
                    distanceType = "placeDetails.distanceFromYou.kilometers";
                }

                return (dist + localize.getLocalizedString(distanceType));
            };


            /*
             * Recursively merge properties of two objects
             * Merges result into obj1 and returns it also
             */
            this.mergeObjectsRecursive = function(obj1, obj2) {
                for (var p in obj2) {
                    if (obj2.hasOwnProperty(p)) {
                        try {
                            if (obj2[p].constructor==Object ) {
                                obj1[p] = mergeRecursive(obj1[p], obj2[p]);
                            } else {
                                obj1[p] = obj2[p];
                            }

                        } catch(e) {
                            obj1[p] = obj2[p];
                        }
                    }
                }

                return obj1;
            };


        }])
;
