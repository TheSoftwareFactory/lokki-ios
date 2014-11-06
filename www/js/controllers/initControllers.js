/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 02.05.2013 13:30
 */

'use strict';

// We just define ringo.controllers and dependencies here.
// All concrete controllers must be added to module in separated files under controllers directory
angular.module("ringo.controllers", ["ringo.services", "ringo.directives", "localization", "ringo.filters"]);