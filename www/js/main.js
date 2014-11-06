/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 02.05.2013 12:21
 */

'use strict';

requirejs.config({
    baseUrl: './',
    paths: {
        localize: 'lib/ext/localize'
    }
});

/// Avoid cache similar to jQuery by adding a timestamp query parameter
/// which is different for each request to same url.
/// IE has more aggressive cache, this is to have behavior similar to Android and iOS
function disableXHRCaching() {
    var xhrorig = window.XMLHttpRequest;

    xhrorig.prototype._original_open = xhrorig.prototype.open;
    xhrorig.prototype.open = function (reqType, uri, isAsync, user, password) {
        /// Only external requests need to be modified.
        /// Local XHR is handled differently. See XHRShim in XHRHelper.cs
        if (uri && uri.indexOf('http') === 0) {
            var queryIndex = uri.indexOf('?');
            if (queryIndex == -1) {
                uri += '?';
            }
            // not endswith
            else if ((queryIndex + 1) != uri.length) {
                uri += '&';
            }

            var arg = '_';
            while (uri.indexOf(arg + '=') >= 0) {
                arg += '_';
            }
            uri += arg + '=' + (new Date).getTime();

            console.log("req:" + uri);
        }

        this._original_open(reqType, uri, isAsync, user, password);
    }
}

require(["localize"], function(){

    console.log("addEventListener('deviceready')");

    function init() {

        console.log("init()");

        var platform = ((window.device) ? window.device.platform : "browser");
        if (platform == "Win32NT") {
            disableXHRCaching();
        }

        require(['js/app', 'js/plugins', 'js/controllers/initControllers', 'js/services/initServices', 'js/directives/initDirectives', 'js/filters/initFilters'], function(){
            require(['js/controllers', 'js/services', 'js/directives', 'js/filters'], function(){
                angular.bootstrap(document, ['ringo']);                
                // No fastclick on wp8
                if(window.FastClick) {
                    new FastClick(document.body);
                }
            });
        });
    }

    if(IS_DEVICE_READY) {
        init();
    }
    else {
        document.addEventListener('deviceready', init, false);
    }
});