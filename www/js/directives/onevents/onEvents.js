'use strict';

angular.module("ringo.directives")

.directive('fsOnFocus', function () {
    return function(scope, element, attrs) {

        element.bind('focus', function(){
                scope.$eval(attrs.fsOnFocus);
            //scope.safeApply(function () {
            //});
        });
    }
});