/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 */

'use strict';

(function (cordova) {

    var platform = ((window.device) ? window.device.platform : "browser");
    if (platform !== "Win32NT") {
        return;
    }

    /** JS API for Share plugin */
    function Share() { }

    /**
    usage:
        plugins.Share.shareLink( { 
            url : "http://mylink.com", 
            message : 'check this out',
            title : 'hi'
        });
    */
    Share.prototype.shareLink = function (params) {
        cordova.exec(function () { }, function () { }, "Share", "shareLink", [params]);
    };

    cordova.addConstructor(function () {
        if (!window.plugins) window.plugins = {};
        window.plugins.Share = new Share();
    });

})(window.cordova || window.Cordova);