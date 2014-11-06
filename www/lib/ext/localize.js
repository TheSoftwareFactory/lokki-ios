'use strict';

/*
 * An AngularJS Localization Service
 *
 * Written by Jim Lavin
 * http://codingsmackdown.tv
 *
 */

/**
 * Originally from https://github.com/lavinjj/angularjs-localizationservice
 * Modified by F-Secure
 *
 */

angular.module('localization', [])
    // localization service responsible for retrieving resource files from the server and
    // managing the translation dictionary
        .factory('localize', ['$http', '$rootScope', '$window', '$filter', function ($http, $rootScope, $window) {
            var localize = {
                // use the $window service to get the language of the user's browser
                language:$window.navigator.userLanguage || $window.navigator.language,
                // array to hold the localized resource string entries
                dictionary:undefined,

                // array to hold the localized resource string entries for en-US version - we fallback to this strings if cannot find in other languages
                defaultDictionary:undefined,

                // flag to indicate if the service hs loaded the resource file
                resourceFileLoaded:false,

                // success handler for all server communication
                successCallback:function (data) {
                    localize.dictionary = eval(data);
                    localize.resourceFileLoaded = true;
                    $rootScope.$broadcast('localizeResourcesUpdates');
                },

                successCallbackDefault:function (data) {
                    localize.defaultDictionary = eval(data);
                    localize.resourceFileLoaded = true;
                    $rootScope.$broadcast('localizeResourcesUpdates');
                },

                // allows setting of language on the fly
                setLanguage: function(value) {
                    localize.language = value;
                    localize.initLocalizedResources();
                },

                // loads the language resource file from the server
                initLocalizedResources:function () {

                    var url = 'i18n/resources-locale_' + localize.language + '.json';
                    $http({ method:"GET", url:url, cache:false }).success(localize.successCallback);

                    var urlDefault = 'i18n/resources-locale_en-US.json';
                    $http({ method:"GET", url:urlDefault, cache:false }).success(localize.successCallbackDefault);

                },

                getLocalizedString: function(key, fieldName1, fieldValue1, fieldName2, fieldValue2) {
                    var result = '';
                    var found = false;
                    if(!angular.isUndefined(localize.dictionary)){
                        var entry = localize.dictionary[key];
                        if(angular.isUndefined(entry)){
                            result = "Key '"+key+"' not localized in language '"+localize.language+"'";
                        }else{
                            result = entry;
                            found = true;
                        }
                    }
                    if(!found && !angular.isUndefined(localize.defaultDictionary)){
                        var entry = localize.defaultDictionary[key];
                        if(angular.isUndefined(entry)){
                            result = "Key '"+key+"' not localized in default language file for 'en-US'";
                        }else{
                            result = entry;
                            found = true;
                        }
                    }

                    if (found) {
                        var textBeforeReplace;
                        if (fieldName1 !== undefined && fieldValue1 !== undefined) {
                            textBeforeReplace = result;
                            result = result.replace("%" + fieldName1 + "%", fieldValue1);
                            if (textBeforeReplace === result) {
                                console.log("LOC: string [" + result + "] does not have field %" + fieldName1 + "% to replace to " + fieldValue1);
                            }
                        }

                        if (fieldName2 !== undefined && fieldValue2 !== undefined) {
                            textBeforeReplace = result;
                            result = result.replace("%" + fieldName2 + "%", fieldValue2);
                            if (textBeforeReplace === result) {
                                console.log("LOC: string [" + result + "] does not have field %" + fieldName2 + "% to replace to " + fieldValue2);
                            }
                        }
                    }

                    return result;
                }
            };

            // force the load of the resource file
            localize.initLocalizedResources();

            // return the local instance when called
            return localize;
        } ])
    // simple translation filter
    // usage {{ TOKEN | i18n }}
        .filter('i18n', ['localize', function (localize) {
            return function (input) {
                return localize.getLocalizedString(input);
            };
        }])
    // translation directive that can handle dynamic strings
    // updates the text value of the attached element
    // usage <span data-i18n="TOKEN" ></span>
    // or
    // <span data-i18n="TOKEN|VALUE1|VALUE2" ></span>
        .directive('i18n', ['localize', function(localize){
            var i18nDirective = {
                restrict:"EAC",
                updateText:function(elm, token){
                    var values = token.split('|');
                    if (values.length >= 1) {
                        // construct the tag to insert into the element
                        var tag = localize.getLocalizedString(values[0]);
                        // update the element only if data was returned
                        if ((tag !== null) && (tag !== undefined) && (tag !== '')) {
                            if (values.length > 1) {
                                for (var index = 1; index < values.length; index++) {
                                    var target = '{' + (index - 1) + '}';
                                    tag = tag.replace(target, values[index]);
                                }
                            }
                            // insert the text into the element
                            elm.text(tag);
                        };
                    }
                },

                link:function (scope, elm, attrs) {
                    scope.$on('localizeResourcesUpdates', function() {
                        i18nDirective.updateText(elm, attrs.i18n);
                    });

                    attrs.$observe('i18n', function (value) {
                        i18nDirective.updateText(elm, attrs.i18n);
                    });
                }
            };

            return i18nDirective;
        }])
    // translation directive that can handle dynamic strings
    // updates the attribute value of the attached element
    // usage <span data-i18n-attr="TOKEN|ATTRIBUTE" ></span>
    // or
    // <span data-i18n-attr="TOKEN|ATTRIBUTE|VALUE1|VALUE2" ></span>
        .directive('i18nAttr', ['localize', function (localize) {
            var i18NAttrDirective = {
                restrict: "EAC",
                updateText:function(elm, token){
                    var values = token.split('|');
                    // construct the tag to insert into the element
                    var tag = localize.getLocalizedString(values[0]);
                    // update the element only if data was returned
                    if ((tag !== null) && (tag !== undefined) && (tag !== '')) {
                        if (values.length > 2) {
                            for (var index = 2; index < values.length; index++) {
                                var target = '{' + (index - 2) + '}';
                                tag = tag.replace(target, values[index]);
                            }
                        }
                        // insert the text into the element
                        elm.attr(values[1], tag);
                    }
                },
                link: function (scope, elm, attrs) {
                    scope.$on('localizeResourcesUpdated', function() {
                        i18NAttrDirective.updateText(elm, attrs.i18nAttr);
                    });

                    attrs.$observe('i18nAttr', function (value) {
                        i18NAttrDirective.updateText(elm, value);
                    });
                }
            };

            return i18NAttrDirective;
        }]);