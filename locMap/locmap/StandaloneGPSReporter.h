

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface StandaloneGPSReporter : NSObject  {
    

}


/// Public API:

// When app is started by one of triggers (significant location change, time change etc) - do a quick location lookup and send result to server
// we get only some seconds to do it so it must be quick
-(void)quicklyQueryLocationAndSendToServer;


// the same as quicklyQueryLocationAndSendToServer but should execure completionHandler as soon as possible because is running in background.
// this call is executed when silent remote notification is received
-(void)quicklyQueryLocationAndSendToServerInBackgroundWithCompletionHandler:(void (^)())completionHandler;


// Stop all location querying and reporting
-(void)stopLocationUpdates;

+(StandaloneGPSReporter*)getInstance;



@end
