/*
 * Copyright (c) 2013 F-Secure Corporation
 * See license terms for the related product.
 *
 * Author: Jussi Nieminen
 * Since: 22.04.2013 13:18
 */

'use strict';

angular.module("ringo.controllers")
    .controller("changeAvatarController",
        ["$scope", "$location", "localStorageService", "commonService",
            function ($scope, $location, localStorageService, commonService) {
                console.log("Creating changeAvatarController");
                var that = this;
                $scope.imageIsProcessing = false;// true while image is processing

                // Expects changeAvatarControllerReturnPage to be defined to correct return page
                // Stores selected image data in changeAvatarControllerImageData if image selected.
                // "changeAvatarControllerReturnPath" defines where app will be redirected if user presses "back" and
                // "changeAvatarControllerReturnPathForImageData" defines where app will be redirected if user selects or takes a picture.
                // If "changeAvatarControllerReturnPathForImageData" does not exist then forwards also to "changeAvatarControllerReturnPath" in case of picture was taken
                $scope.init = function () {
                    $scope.returnPath = localStorageService.getValue("changeAvatarControllerReturnPath");
                    $scope.returnPathForImageData = localStorageService.getValue("changeAvatarControllerReturnPathForImageData");
                    if (!$scope.returnPathForImageData) {
                        $scope.returnPathForImageData = $scope.returnPath;
                    }
                    localStorageService.setValue("changeAvatarControllerReturnPath", undefined);
                    localStorageService.setValue("changeAvatarControllerReturnPathForImageData", undefined);
                    localStorageService.setValue("changeAvatarControllerImageData", undefined);
                };

                $scope.backButtonPressed = function () {
                    $location.path($scope.returnPath);
                };

                $scope.returnImageDataBack = function () {
                    $location.path($scope.returnPathForImageData);
                };

                $scope.fromLibrary = function () {
                    $scope.imageIsProcessing = true;
                    $scope.selectNewAvatar("library");
                };

                $scope.fromCamera = function () {
                    $scope.imageIsProcessing = true;
                    $scope.selectNewAvatar("camera");
                };

                var resizePicture = function (imageData, size, callback) {

                    var img = new Image();
                    img.onload = function() {
                        var canvas = document.createElement("canvas");
                        canvas.width = size;
                        canvas.height = size;

                        var sx = 0, sy = 0, swidth = img.width, sheight = img.height;
                        if (img.width < img.height) {
                            // portait
                            sy = (img.height - img.width) / 2;
                            sheight = img.width;
                        }
                        else {
                            // landscape
                            sx = (img.width - img.height) / 2;
                            swidth = img.height;
                        }

                        //console.log("sx:" + sx + " sy:" + sy + " swidth:" + swidth + " sheight:" + sheight
                        //    + "img size:" + img.width + "," + img.height);

                        var ctx = canvas.getContext("2d");
                        ctx.drawImage(img, sx, sy, swidth, sheight, 0, 0, size, size);

                        callback(canvas.toDataURL());
                    };
                    //img.src = imageData; // Trigger onLoad
                    img.src = "data:image/png;base64," + imageData; // Trigger onLoad
                };

                var onCameraPhotoSuccess = function (imageData) {
                    resizePicture(imageData, 256, function(imageDataResized) {
                        imageDataResized = imageDataResized.substring("data:image/png;base64,".length); // Remove: "data:image/png;base64,"

                        localStorageService.setValue("changeAvatarControllerImageData", imageDataResized);
                        $scope.safeApply(function () {
                            //$scope.newAvatarImageData = imageData;
                            $scope.imageIsProcessing = false;
                            $scope.returnImageDataBack();
                        });

                    });
                };

                var onCameraPhotoFailed = function (message) {
                    console.log('Error: ' + message);
                    if (message && message !== "no image selected" && message.indexOf("cancelled") === -1) { //"no image selected" is returned when user cancels taking picture in iOS and "cancelled" is returned as path of error in Android
                        commonService.showMessageToUser("error.takePhotoFailed", "error.title.error");
                    }

                    $scope.safeApply(function () {
                        $scope.imageIsProcessing = false;
                    });
                };


                $scope.selectNewAvatar = function (imgSourceType) {
                    var platform = ((window.device) ? window.device.platform : "browser");
                    if (platform === "browser") {
                        console.log("Emulate picture taking in browser");
                        var fakeImg = "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";
                        onCameraPhotoSuccess(fakeImg);
                        return;
                    }
                    var sourceType = (imgSourceType === "library") ? navigator.camera.PictureSourceType.PHOTOLIBRARY : navigator.camera.PictureSourceType.CAMERA;

                    var options = {
                        quality: 50,
                        destinationType: navigator.camera.DestinationType.DATA_URL,//Return image as base64 encoded string
                        //destinationType : navigator.camera.DestinationType.FILE_URI,
                        sourceType: sourceType,
                        allowEdit: true,
                        encodingType: navigator.camera.EncodingType.JPEG,
                        targetWidth: 256,
                        targetHeight: 256,
                        mediaType: navigator.camera.MediaType.PICTURE,
                        correctOrientation: true,
                        saveToPhotoAlbum: false
                    };


                    navigator.camera.getPicture(onCameraPhotoSuccess, onCameraPhotoFailed, options);
                };

                $scope.init();


            }])
;