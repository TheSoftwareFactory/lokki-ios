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
        .service("validationService", [function(){

            // validates if phoneNumber is correct phone number and returns it converted to Ringo format.
            // if error happens then returns empty string ("").
            // if succeeds then returns phoneNumber in Ringo server format (like "+358 (40) 67891234" --> "3584067891234")
            this.validateAndConvertPhoneNumber = function(phoneNumber) {
                if (phoneNumber === undefined) {
                    return "";
                }
                var ringoPhone = phoneNumber;

                // allow to start only from + or 00
                if (ringoPhone.substring(0, 1) !== "+" && ringoPhone.substring(0, 2) !== "00") {
                    return "";
                }

                // remove all additional characters ("(", ")", "-" and spaces)
                ringoPhone = ringoPhone.replace(/[\s\(\)\-]/g, "");

                if (ringoPhone.substring(0, 1) === "+") {
                    ringoPhone = ringoPhone.substring(1);
                } else {
                    ringoPhone = ringoPhone.substring(2);
                }

                if (ringoPhone.length < 5) {
                    return "";
                }

                //allow only numbers
                var reg = /^\d+$/;
                if (reg.test(ringoPhone)) {
                    return ringoPhone;
                }

                return "";
            };


        }])
;
