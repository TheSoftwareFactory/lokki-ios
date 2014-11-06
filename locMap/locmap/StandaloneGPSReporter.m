
#import "StandaloneGPSReporter.h"
#import "ServerApi+messages.h"
#import "LocalStorage.h"
#import <CoreLocation/CoreLocation.h>

static StandaloneGPSReporter* gStandaloneGPSReporter = nil;// we should have only 1 global instance created by AppDelegate

typedef void (^BackgroundQueryCompletionBlock)(void);

@interface StandaloneGPSReporter() <CLLocationManagerDelegate, ServerApiDelegate>

    @property (strong, nonatomic) CLLocationManager* locationManager;// real high accuracy location manager to query good location

    @property (strong, nonatomic) NSTimer* stopLocationManagerTimer;// we run it to stop location manager updates if acceptable quality cannot be reached
    @property NSUInteger backgroundTaskIdentifier;// we use background task to keep us running a bit longer

    @property (strong, atomic) ServerApi* serverApi;// nil when not sending anything to server and not nil during sending

    @property (strong) BackgroundQueryCompletionBlock backgroundQueryCompletionHandler;// handler for background query. if not nil then first report to server must call it
@end

@implementation StandaloneGPSReporter

+(StandaloneGPSReporter*)getInstance
{
    return gStandaloneGPSReporter;
}


-(id)init {
    self = [super init];
    gStandaloneGPSReporter = self;
    return self;
}


// real high quality location manager
-(CLLocationManager*)locationManager
{
    if (!_locationManager)
    {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        _locationManager.distanceFilter = 10;// report every 10 meters
    }
    return _locationManager;
    
}


//////////////////////////////////////////
/// Public API
//////////////////////////////////////////

-(void)quicklyQueryLocationAndSendToServerInBackgroundWithCompletionHandler:(void (^)())completionHandler {
    // if had handler already - call it immediately to not to lose it
    [self callCompletionHandler];

    self.backgroundQueryCompletionHandler = completionHandler;
    [self quicklyQueryLocationAndSendToServer];
}


// When app is started by one of triggers (significant location change, time change, request from server etc) - do a quick location lookup and send result to server.
// we get only some seconds to do it so it must be quick
-(void)quicklyQueryLocationAndSendToServer {
    if (![StandaloneGPSReporter isLocationMonitoringEnabled]) {
        [self callCompletionHandler];
        return;
    }
    
    NSLog(@"quicklyQueryLocationAndSendToServer");
    [self findOutCurrentPositionAndReportItToServer];
    
    
}


-(void)stopLocationUpdates
{
    [self callCompletionHandler];
    
    [self stopBackgroundTask];
    [self.locationManager stopUpdatingLocation];
    if (self.stopLocationManagerTimer) {
        [self.stopLocationManagerTimer invalidate];
        self.stopLocationManagerTimer = nil;
    }
}


//////////////////////////////////////////
/// Implementation
//////////////////////////////////////////
-(void)callCompletionHandler {
    if (self.backgroundQueryCompletionHandler) {
        NSLog(@"Calling completion handler");
        self.backgroundQueryCompletionHandler();
        self.backgroundQueryCompletionHandler = nil;
    }
}

+(BOOL)isLocationMonitoringEnabled {
    return ([LocalStorage isReportingEnabled] && [LocalStorage getAuthToken] != nil);
}


-(void)showDebugNotificationWithText:(NSString*)text {
#ifdef DEBUG
    /*
    UIApplication* app = [UIApplication sharedApplication];
    UIApplicationState state = [app applicationState];
    if (state == UIApplicationStateActive) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Lokki"
                                                            message:text
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
    } else {
        // Create a new notification.
        UILocalNotification* alarm = [[UILocalNotification alloc] init];
        if (alarm)
        {
            alarm.fireDate = [NSDate dateWithTimeIntervalSinceNow:0];
            alarm.timeZone = [NSTimeZone defaultTimeZone];
            alarm.repeatInterval = 0;
            alarm.soundName = @"default";
            alarm.alertBody = text;
            [app scheduleLocalNotification:alarm];
        }
    }
     */

#endif
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    [self callCompletionHandler];
    NSLog(@"locationManager didFailWithError: %@", error);
}


// returns YES when location query is in progress (so we dont start second one)
-(BOOL)isLocationQueryInProgress {
    return (self.serverApi || self.stopLocationManagerTimer);
}


-(void)findOutCurrentPositionAndReportItToServer {
    BOOL alreadyQuerying = [self isLocationQueryInProgress];
    // if we are already monitoring GPS then stop and start it again to report location at least once
    if (alreadyQuerying) {
        [self.locationManager stopUpdatingLocation];
        [self.locationManager startUpdatingLocation];
        return;
    }
    
    [self startBackgroundTask];
    [self startTimerToStopLocationUpdates];
    [self.locationManager startUpdatingLocation];
}

-(void)startTimerToStopLocationUpdates
{
    if (!self.stopLocationManagerTimer)
    {
        NSTimeInterval timeout = 30;//give 30 seconds max to find out location
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
            timeout = 15;// in background give 15 seconds max. system gives us 30 seconds but we need to send location also plus spend less battery
        }
        
        self.stopLocationManagerTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                                         target:self
                                                                       selector:@selector(stopLocationManagerTimerFired:)
                                                                       userInfo:nil
                                                                        repeats:NO];
    }
}


-(void)stopLocationManagerTimerFired:(NSTimer*)timer
{
    // if we did not report yet - do it
    if (self.locationManager.location) {
       [self reportLocationToServer:self.locationManager.location];
    } else {
       [self callCompletionHandler];
       [self stopBackgroundTask];
    }

    // we stop updating locations only when we are in background
    UIApplication* app = [UIApplication sharedApplication];
    if (app.applicationState == UIApplicationStateBackground) {
        [self.locationManager stopUpdatingLocation];
    }
    
    if (self.stopLocationManagerTimer) {
        [self.stopLocationManagerTimer invalidate];
    }
    self.stopLocationManagerTimer = nil;
}



-(void)startBackgroundTask
{
    if (self.backgroundTaskIdentifier)
        return;
    
    self.backgroundTaskIdentifier =  [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                                         {
                                             [self stopBackgroundTask];
                                         }
                                     ];
    //NSLog(@"Started background task with backgroundTaskIdentifier=%lu", (unsigned long)self.backgroundTaskIdentifier);
}

-(void)stopBackgroundTask
{
    if (self.backgroundTaskIdentifier)
    {
        //NSLog(@"Stopping background task");
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = 0;
    }
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (manager != self.locationManager) {
        return;//just ignore
    }
    CLLocation* newLocation = [locations lastObject];
    [self onNewLocation:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (manager == self.locationManager) {
        return;//just ignore
    }
    //before ios6
    [self onNewLocation:newLocation];
}

-(void)onNewLocation:(CLLocation*)newLocation
{
    if (newLocation.horizontalAccuracy > 15000 || newLocation.horizontalAccuracy < 0)
    {
        //NSLog(@"Ignore reports with bad accuracy: %f", newLocation.horizontalAccuracy);
        return;
    }
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge >= 30.0) {//ignore reports older than 30 seconds
        NSLog(@"Ignore very old reports. Age: %f", locationAge);
        return;
    }
    
    // location is not the same as previous but close. if accuracy is good enough or similar to accuracy of previous report - stop trying to get better location
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
        // in non active state report immediately no matter accuracy
        [self reportLocationToServer:newLocation];
    }
    
    if (newLocation.horizontalAccuracy < 80) {
        [self stopLocationManagerTimerFired:nil];// stop manager and report location
    }
    

}



-(void)reportLocationToServer:(CLLocation*)newLocation
{
    if (!self.serverApi) {
        self.serverApi = [[ServerApi alloc] initWithDelegate:self];
    }
    
#ifdef DEBUG
    NSLog(@"reportLocationToServer: %@", newLocation);
#endif
    [self.serverApi reportLocationToServer:newLocation];
}

- (void)serverApi:(ServerApi *)api finishedOperation:(ServerOperationType)type withResult:(BOOL)success withResponse:(NSDictionary *)response;
{
    if (type != ServerOperationPostLocation) {
        NSLog(@"Unknown operation reported in finishedOperation: %d", (int)type);
        return;        
    }
    
    NSLog(@"Location reported with status: %d and response %@", (int)success, response);
    
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"DashboardNeedsUpdating" object:self];
    }
    
    [self callCompletionHandler];
    
    if (self.serverApi && [self.serverApi getNumberOfActiveRequests] == 0) {
        self.serverApi = nil;
        [self stopBackgroundTask];
    }    
}

@end
