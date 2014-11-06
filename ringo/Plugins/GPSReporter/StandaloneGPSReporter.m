

#import "GPSSettings.h"
#import "StandaloneGPSReporter.h"
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLCircularRegion.h> //ios7 only

#define SAVE_DATA_KEY_NAME @"SaveData"
#define SAVE_DATA_URL @"URL"
#define SAVE_DATA_AUTHCODE @"AUTH"
#define SAVE_DATA_MONITORING_ENABLED @"MONITORING_ENABLED"

static BOOL gStandaloneGPSReporterEnabled = NO;
static StandaloneGPSReporter* gStandaloneGPSReporter = nil;// we should have only 1 global instance created by AppDelegate
static BOOL gRegionMonitoringEnabled = NO;

@interface StandaloneGPSReporter() <CLLocationManagerDelegate, NSURLConnectionDataDelegate>

    @property BOOL observersStarted;// YES if notification observers added

    @property (strong, nonatomic) CLLocationManager* monitoringLocationManager;// fake location manager just to continue running in background. very innacurate so works fast
    @property (strong, nonatomic) CLLocationManager* locationManager;// real high accuracy location manager to query good location
    @property (atomic, strong) CLRegion* currentlyMonitoredRegion;

    @property (strong, nonatomic) NSTimer* stopLocationManagerTimer;// we run it to stop location manager updates if acceptable quality cannot be reached in MAX_TIME_FOR_POSITION_UPDATES seconds
    @property NSUInteger backgroundTaskIdentifier;// we use background task to keep us running a bit longer

    @property (strong, nonatomic) NSURLConnection *serverConnection;// POST query to send position to server. if not nul then query is currently sending

    +(void)startOrStopObservers;
    -(void)startObservers;
    -(void)stopObservers;
@end

@implementation StandaloneGPSReporter

-(id)init {
    self = [super init];
    gStandaloneGPSReporter = self;
    [StandaloneGPSReporter startOrStopObservers];
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
        _locationManager.distanceFilter = DISTANCE_FILTER;
    }
    return _locationManager;
    
}

// location manager for continuing running in background. use worst possible accuracy to avoid draining battery
-(CLLocationManager*)monitoringLocationManager
{
    if (!_monitoringLocationManager)
    {
        _monitoringLocationManager = [[CLLocationManager alloc] init];
        // setup very unprecise manager
        _monitoringLocationManager.delegate = self;
        _monitoringLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _monitoringLocationManager.distanceFilter = 100;
        if ([_monitoringLocationManager respondsToSelector:@selector(pausesLocationUpdatesAutomatically)]) {
            _monitoringLocationManager.pausesLocationUpdatesAutomatically = NO;
        }
    }
    return _monitoringLocationManager;
}

//////////////////////////////////////////
/// Public API
//////////////////////////////////////////
// Allow or disallow to query location data

+(void)setLocationMonitoringEnabled:(BOOL)enabled
{
    NSMutableDictionary* savedData = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:SAVE_DATA_KEY_NAME] mutableCopy];
    if (!savedData) {
        savedData = [[NSMutableDictionary alloc] init];
    }
    savedData[SAVE_DATA_MONITORING_ENABLED] = [NSNumber numberWithBool:enabled];
    
    NSDictionary* data = [savedData copy];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:SAVE_DATA_KEY_NAME];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [StandaloneGPSReporter startOrStopObservers];
}


+(void)setServerURL:(NSString*)URL andAuthCode:(NSString*)code {
    if (!URL || !code || [code compare:@"undefined"] == NSOrderedSame) {
        NSLog(@"setServerURL: Server url or auth code is invalid");
        return;
    }
    NSMutableDictionary* savedData = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:SAVE_DATA_KEY_NAME] mutableCopy];
    if (!savedData) {
        savedData = [[NSMutableDictionary alloc] init];
    }
    savedData[SAVE_DATA_URL] = URL;
    savedData[SAVE_DATA_AUTHCODE] = code;
    
    NSDictionary* data = [savedData copy];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:SAVE_DATA_KEY_NAME];
    [[NSUserDefaults standardUserDefaults] synchronize];

    [StandaloneGPSReporter startOrStopObservers];
}


// if another place determines location - use this method to start monitoring for exiting region around this location
+(void)startMonitoringForRegionAroundCurrentLocation:(CLLocationCoordinate2D)currentLocation {
    if (gStandaloneGPSReporter) {
        [gStandaloneGPSReporter startMonitoringForRegionAroundCurrentLocation:currentLocation];
    }
}

+(BOOL)canStartLocationMonitoringNow {
    if ([StandaloneGPSReporter isLocationMonitoringEnabled] && [StandaloneGPSReporter getServerURL] && [StandaloneGPSReporter getAuthCode]) {
        return YES;
    }
    return NO;
}

// When app is started by one of triggers (significant location change, time change etc) - do a quick location lookup and send result to server
// we get only some seconds to do it so it must be quick
-(void)quicklyQueryLocationAndSendToServer {
    if (![StandaloneGPSReporter isLocationMonitoringEnabled] || ![StandaloneGPSReporter getServerURL] || ![StandaloneGPSReporter getAuthCode]) {
        return;
    }
    
    NSLog(@"quicklyQueryLocationAndSendToServer");
    [self findOutCurrentPositionAndReportItToServer];
    
    
}


//////////////////////////////////////////
/// Implementation
//////////////////////////////////////////
+(BOOL)isLocationMonitoringEnabled {
    if (!gStandaloneGPSReporterEnabled) {
        return NO;
    }
    
    NSDictionary* savedData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SAVE_DATA_KEY_NAME];
    NSNumber* num = [savedData objectForKey:SAVE_DATA_MONITORING_ENABLED];
    return [num boolValue];
}


+(NSString*)getServerURL {
    NSDictionary* savedData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SAVE_DATA_KEY_NAME];
    return [savedData objectForKey:SAVE_DATA_URL];
}

+(NSString*)getAuthCode {
    NSDictionary* savedData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:SAVE_DATA_KEY_NAME];
    return [savedData objectForKey:SAVE_DATA_AUTHCODE];
}


+(void)startOrStopObservers {
    if (!gStandaloneGPSReporter || !gStandaloneGPSReporterEnabled) {
        return;
    }
    if (![StandaloneGPSReporter isLocationMonitoringEnabled] || ![StandaloneGPSReporter getServerURL] || ![StandaloneGPSReporter getAuthCode]) {
        [gStandaloneGPSReporter stopObservers];
    } else {
        [gStandaloneGPSReporter startObservers];
    }
}


-(void)startObservers {
    if (self.observersStarted || !gStandaloneGPSReporterEnabled) {
        return;
    }
    
    NSLog(@"Starting observers");
    self.observersStarted = YES;
    [self.monitoringLocationManager startMonitoringSignificantLocationChanges];
}

-(void)stopObservers {
    if (!self.observersStarted) {
        return;
    }

    NSLog(@"Stopping observers");
    self.observersStarted = NO;
    [self stopMonitoringForRegionAroundCurrentLocation];
    [self.monitoringLocationManager stopMonitoringSignificantLocationChanges];
    
}




-(void)showDebugNotificationWithText:(NSString*)text {
#ifdef DEBUG
    UIApplication* app = [UIApplication sharedApplication];
    UIApplicationState state = [app applicationState];
    if (state == UIApplicationStateActive) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Lokki"
                                                            message:text
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil, nil];
        [alertView show];
        [alertView release];
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
            [alarm release];
        }
    }

#endif
}

-(CLRegion*)createRegionAroundLocation:(CLLocationCoordinate2D)currentLocation withRadius:(CLLocationDistance)_radius{
    CLRegion* region = nil;
    region = [[CLCircularRegion alloc] initWithCenter:currentLocation radius:_radius identifier:@"LokkiRegionAroundUser"];
    if (!region) {
        region = [[CLRegion alloc] initCircularRegionWithCenter:currentLocation radius:_radius identifier:@"LokkiRegionAroundUser"];
    }
    return region;
    
}


-(void)startMonitoringForRegionAroundCurrentLocation:(CLLocationCoordinate2D)currentLocation {
    [self stopMonitoringForRegionAroundCurrentLocation];//stop if monitoring
    if (!gRegionMonitoringEnabled || !gStandaloneGPSReporterEnabled) {
        return;
    }
    
    if ([StandaloneGPSReporter isLocationMonitoringEnabled]) {
        NSLog(@"startMonitoringForRegionAroundCurrentLocation");
        self.currentlyMonitoredRegion = [self createRegionAroundLocation:currentLocation withRadius:400];
        [self.monitoringLocationManager startMonitoringForRegion:self.currentlyMonitoredRegion];
    }
}

-(void)stopMonitoringForRegionAroundCurrentLocation {
    if (self.currentlyMonitoredRegion) {
        [self.monitoringLocationManager stopMonitoringForRegion:self.currentlyMonitoredRegion];
        self.currentlyMonitoredRegion = nil;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self showDebugNotificationWithText:@"didEnterRegion"];
    NSLog(@"did enter region: %@", region);
    [self findOutCurrentPositionAndReportItToServer];
    
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    NSLog(@"did exit region: %@", region);
    [self showDebugNotificationWithText:@"didExitRegion"];
    
    [self findOutCurrentPositionAndReportItToServer];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"locationManager didFailWithError: %@", error);
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"monitoringDidFailForRegion: %@", error);
    [self showDebugNotificationWithText:@"monitoringDidFailForRegion happened"];
}


// returns YES when location query is in progress (so we dont start second one)
-(BOOL)isLocationQueryInProgress {
    return (self.serverConnection || self.stopLocationManagerTimer || self.stopLocationManagerTimer);
}


-(void)findOutCurrentPositionAndReportItToServer {
    if ([self isLocationQueryInProgress] || ![StandaloneGPSReporter canStartLocationMonitoringNow]) {
        return;
    }

    NSLog(@"findOutCurrentPositionAndReportItToServer");
    [self startBackgroundTask];
    [self startTimerToStopLocationUpdates];
    [self.locationManager startUpdatingLocation];
}

-(void)startTimerToStopLocationUpdates
{
    if (!self.stopLocationManagerTimer)
    {
        NSTimeInterval timeout = MAX_TIME_FOR_FORCED_POSITION_UPDATES;
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
       [self startMonitoringForRegionAroundCurrentLocation:self.locationManager.location.coordinate];
       
       [self reportLocationToServer:self.locationManager.location];
   } else {
       [self stopBackgroundTask];
   }
    
    [self.locationManager stopUpdatingLocation];
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
    NSLog(@"Started background task with backgroundTaskIdentifier=%d", self.backgroundTaskIdentifier);
}

-(void)stopBackgroundTask
{
    NSLog(@"Stopping background task");
    if (self.backgroundTaskIdentifier)
    {
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
    if (newLocation.horizontalAccuracy > MAXIMAL_ACCEPTABLE_ACCURACY_TO_REPORT_RIGHT_AWAY || newLocation.horizontalAccuracy < 0)
    {
        NSLog(@"Ignore reports with bad accuracy: %f", newLocation.horizontalAccuracy);
        return;
    }
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge >= 30.0) {//ignore reports older than 30 seconds
        return;
    }
    
    // location is not the same as previous but close. if accuracy is good enough or similar to accuracy of previous report - stop trying to get better location
    if (newLocation.horizontalAccuracy < ACCURACY_TO_STOP_GETTING_BETTER_READING) {
        [self stopLocationManagerTimerFired:nil];// stop manager and report location
    }
    

}



-(void)reportLocationToServer:(CLLocation*)newLocation
{
    NSString* URL = [StandaloneGPSReporter getServerURL];
    NSString* authCode = [StandaloneGPSReporter getAuthCode];
    // only report location which is not too old
    NSTimeInterval locationAge = -[newLocation.timestamp timeIntervalSinceNow];
    if (locationAge > 30.0 || !URL || !authCode) {
        NSLog(@"reportLocationToServer ignores location %@", newLocation);
        [self stopBackgroundTask];
        return;
    }
    
    
    NSMutableURLRequest *theRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                         timeoutInterval:30.0];
    //do post request for parameter passing
    [theRequest setHTTPMethod:@"POST"];

    //set the content type to JSON
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [theRequest addValue:authCode forHTTPHeaderField:@"authorizationtoken"];
    [theRequest addValue:@"iOS" forHTTPHeaderField:@"platform"];
    [theRequest addValue:@"3.0" forHTTPHeaderField:@"version"];
    //TODO: still missing: version: commonService.version,
    
    NSString *data = [NSString stringWithFormat:@"{\"lat\":%f, \"lon\":%f, \"acc\":%f}", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy];
    NSLog(@"data is %@", data);
    NSData* requestData = [data dataUsingEncoding:NSUTF8StringEncoding];
    
    [theRequest setValue:[NSString stringWithFormat:@"%d", [requestData length]] forHTTPHeaderField:@"Content-Length"];
    [theRequest setHTTPBody: requestData];
    
    self.serverConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    //[theConnection release];
    
    
}



- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self.serverConnection release];
    self.serverConnection = nil;
    
    // inform the user
    NSLog(@"Posting location to server failed failed! Error - %@ (%@)", [error localizedDescription], [[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
    [self stopBackgroundTask];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//    NSLog(@"Posting to server succeeded");
    [self showDebugNotificationWithText:@"Location sent from native"];
    
    [self.serverConnection release];
    self.serverConnection = nil;
    [self stopBackgroundTask];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {

    if ([response respondsToSelector:@selector(statusCode)])
    {
        int statusCode = [((NSHTTPURLResponse *)response) statusCode];
        if (statusCode != 200)
        {
            [connection cancel];  // stop connecting; no more delegate messages
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Server returned status code %d", statusCode] forKey:NSURLErrorFailingURLStringErrorKey];
            NSError *statusError = [NSError errorWithDomain:@"Error" code:statusCode userInfo:errorInfo];
            [self connection:connection didFailWithError:statusError];
        }
    }
    
}


@end
