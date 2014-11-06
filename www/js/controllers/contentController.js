/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Oleg Fedorov
 * Since: 21.05.2013 15:43
 */

'use strict';

// contentController controls  entire "content" area - can make it smaller or bigger
angular.module("ringo.controllers")
       .controller("contentController", ["$scope", function($scope) {
            $scope.isContentStartsOnTop = true;
    }])
;
