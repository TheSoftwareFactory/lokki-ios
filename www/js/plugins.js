/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 02.05.2013 13:21
 */

'use strict';

/**
 * Require.js method to control which JS files are loaded. Don't add functionality here and use
 * AngularJS modules to manage dependencies
 */
define([
    './pgplugins/gpsReporter',
    './pgplugins/Maps',
    './pgplugins/PushNotification',
    './pgplugins/PushNotificationWP8',
    './pgplugins/GCMPlugin',
    './pgplugins/cdv-plugin-fb-connect',
    './pgplugins/SMSComposer',
    './pgplugins/Share'
], function () {
});