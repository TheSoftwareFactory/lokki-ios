/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 17.06.2013 11:5
 */

'use strict';

angular.module("ringo.controllers")
    .controller("fsecureProductsController",
        ["$scope", "$location", "commonService", "localize", function($scope, $location, commonService, localize) {
            $scope.returnPath = "/settings";

            $scope.allProducts = [
                {
                    platform: "iOS",
                    name: "F-Secure Child Safe",
                    icon: "images/childSafe.svg",
                    text: localize.getLocalizedString("fsecure.products.ios.childSafe"), //"Protect your child with F-Secure Child Safe",
                    link: "https://itunes.apple.com/app/f-secure-child-safe/id529104258"
                },
                {
                    platform: "Android",
                    name: "F-Secure Mobile Security",
                    icon: "images/mobileSecurity.svg",
                    text: localize.getLocalizedString("fsecure.products.android.mobileSecurity"), //"Try F-Secure Mobile Security for free",
                    link: "market://details?id=com.fsecure.ms.dc"
                }
            ];

            var platform = ((window.device) ? window.device.platform : "browser");
            $scope.products = [];
            for(var p in $scope.allProducts) {
                if ($scope.allProducts.hasOwnProperty(p) && (platform === "browser" || $scope.allProducts[p].platform === platform)) {
                    $scope.products.push($scope.allProducts[p]);
                }
            }

            $scope.back = function() {
                $location.path($scope.returnPath);
            };


            $scope.onProductClick = function(product) {
                console.log("Clicked product with link: " + product.link);
                commonService.openURLInExternalBrowser(product.link, true);
            };


        }]);