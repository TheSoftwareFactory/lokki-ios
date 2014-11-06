//
//  GPSReporterHelper.h
//  ringo
//
//  Created by Oleg Fedorov on 4/26/13.
//
//

#import <Foundation/Foundation.h>

/// Helper class for GPSReporter - provides convenience functions for it
@interface GPSReporterHelper : NSObject


/// Returns name of currently connected WiFi network.
/// If no WiFi connected then returns @""
-(NSString*)getCurrentlyConnectedWiFi;


/// Returns YES if device is moving right now. Uses accelerometer to recognize movement.
/// Note: blocks. may take up to 1 second to execute
-(BOOL)isDeviceMoving;


/// Returns current battery level (0..1 or -1 if level is unknown)
-(float)getBatteryLevel;


@end


