/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Harri Kukkonen
 * Since: 11.09.2013 14:24
 */

'use strict';



angular.module("ringo.filters")
    // Sort an object of objects by the specified parameter. Return as array of objects or object of objects.
    .filter('objectSort', function() {
        return function (input, sortParams) {
            if (input !== undefined && input != null) {
                var sortParamKeyMap = new Object(); // Key: sortParam Value: object key.
                var sortedObjects = new Array();
                var firstParamKey = null;
                var firstParamValue = null;

                // Special case handling if we want specific values as first of list.
                if (sortParams.firstParamKey !== undefined && sortParams.firstParamValue !== undefined) {
                    firstParamKey = sortParams.firstParamKey;
                    firstParamValue = sortParams.firstParamValue;
                }

                // Make a sortParam -> object key mapping.
                var objKeys = Object.keys(input);
                for (var i = 0; i < objKeys.length; i++) {
                    var objKey = objKeys[i];
                    // If we have the special first into list setting and the values match, put it as first of list.
                    if (firstParamKey != null && input[objKey][firstParamKey] == firstParamValue) {
                        sortedObjects.push(input[objKey]);
                    }  else {
                        sortParamKeyMap[input[objKey][sortParams.by]] = objKey;
                    }
                }
                var sortParamList = Object.keys(sortParamKeyMap);

                // Sort the parameter list in somewhat Unicode compatible way.
                //TODO Probably does not work optimally in all cases, some external library might be needed to improve.
                //TODO toLocaleLowerCase is slow compared to toLowerCase, libraries could be more optimized.
                sortParamList.sort(function(a, b) {
                    return a.toLocaleLowerCase().localeCompare(b.toLocaleLowerCase());
                });

                // Create array of the original objects in sorted order.
                for (var i = 0; i < sortParamList.length; i++) {
                    var sortKey = sortParamList[i];
                    var objKey = sortParamKeyMap[sortKey];
                    sortedObjects.push(input[objKey]);
                }
                return sortedObjects;
            } else {
                return input;
            }
        }
    }
);
