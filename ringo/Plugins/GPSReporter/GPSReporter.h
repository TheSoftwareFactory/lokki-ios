

#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface GPSReporter : CDVPlugin {

}

/// Public API:
/// Start background thread which will keep application running in background forever
/// and will report new position to "window.plugins.GPSReporter.GPSCallback" function when needed.
/// Currently reports position every 20 minutes if device is static and every 1-2 minutes if device is moving.
/// Also does not report new position if device is connected to the same WiFi point as it was when reported position last time.
- (void)startMonitoringGPS:(CDVInvokedUrlCommand *)command;


/// Public API:
/// Stop background thread and stop monitoring positions.
/// After this call "window.plugins.GPSReporter.GPSCallback" will not be executed anymore
/// and application can be frozen by iOS
- (void)stopMonitoringGPS:(CDVInvokedUrlCommand *)command;


/// Public API:
/// Find out current location and report it to JS once.
/// Report location even if it is not very precise or exactly like we detected before
-(void)forceReportCurrentLocation:(CDVInvokedUrlCommand *)command;


/// Public API:
/// just report from JS that it received coordinates.
/// This function will show local notification to user with text from command.arguments
//- (void)jsReceivedCoordinates:(CDVInvokedUrlCommand *)command;

@end
