/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 24.04.2013 15:8
 */

'use strict';

// This is dummy file for browsers. Do not remove!

(function()
{
    var cordova = {};
    cordova.addConstructor = function(func){
        func();
    };
    window.cordova = cordova;
    cordova.browser =true;

    var ev = document.createEvent('HTMLEvents');
    ev.initEvent('deviceready', true, true, arguments);

    setTimeout(function(){
        document.dispatchEvent(ev);
    }, 200);


})();