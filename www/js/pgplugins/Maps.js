/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 */

'use strict';

(function (cordova) {

    /** JS API for Maps plugin */
    function Maps() { }

    /**
    usage:
        plugins.Maps.showLocation( { lat : 0, lon : 0, name:"My", acc: 19, editable: true }, successCallback, failedCallback );
        If you provide successCallback then it gets executed when map was shown and closed by user and it receives single parameter - new location in format:  {lat: 1, lon: 2, radius: 19}.
        Failed callback is executed if failure occures.
        Note: some platforms or situations may not call failure or success callback at all!
    */
    Maps.prototype.showLocation = function (params, successCallback, failedCallback) {
        cordova.exec(
            function (param) {console.log("Maps success callback fired with " + JSON.stringify(param));if (successCallback) successCallback(param);},
            function (param) {console.log("Maps failed callback fired with " + JSON.stringify(param));if (failedCallback) failedCallback(param);},
            "Maps",
            "showLocation",
            [params]
        );
    }; 

    cordova.addConstructor(function () {
        if (!window.plugins) window.plugins = {};
        window.plugins.Maps = new Maps();
    });

})(window.cordova || window.Cordova);