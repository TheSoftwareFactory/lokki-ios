

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface StandaloneGPSReporter : NSObject  {
    

}


/// Public API:
// Allow or disallow to query location data
+(void)setLocationMonitoringEnabled:(BOOL)enabled;

// Set server API data
+(void)setServerURL:(NSString*)URL andAuthCode:(NSString*)code;

// When app is started by one of triggers (significant location change, time change etc) - do a quick location lookup and send result to server
// we get only some seconds to do it so it must be quick
-(void)quicklyQueryLocationAndSendToServer;


// if another place determines location - use this method to start monitoring for exiting region around this location
+(void)startMonitoringForRegionAroundCurrentLocation:(CLLocationCoordinate2D)currentLocation;



@end
