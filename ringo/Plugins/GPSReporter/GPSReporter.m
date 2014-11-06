
#import "GPSSettings.h"
#import "GPSReporter.h"
#import "StandaloneGPSReporter.h"
#import <Cordova/CDVJSON.h>
#import <Cordova/CDVDebug.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreLocation/CLCircularRegion.h>
#import "GPSReporterHelper.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@interface GPSReporter() <CLLocationManagerDelegate>

@property BOOL lowBatteryModeActivated;// YES if we activated low battery mode which forbids running in background but allows forced location reporting
@property BOOL gpsMonitoringEnabled;// YES if we can monitor position or NO if user disabled monitoring on his device
@property BOOL observersAdded;// YES if notification observers added
@property (strong, nonatomic) GPSReporterHelper* helper;

@property (strong, nonatomic) CLLocationManager* locationManager;// high accuracy location manager to find out current position
@property (strong, nonatomic) NSTimer* stopLocationManagerTimer;// we run it to stop location manager updates if acceptable quality cannot be reached in MAX_TIME_FOR_POSITION_UPDATES seconds

@property (strong, atomic) CLLocation* previousReportedLocation;// if not nil then contains latest reported to JS position
@property (atomic) NSTimeInterval previousReportedLocationTime;// time when we reported location last time in seconds since 1970
@property (atomic) NSTimeInterval lastGPSReportTime;// time when we last time reported GPS location to server


@property NSUInteger backgroundTaskIdentifier;
@property dispatch_source_t backgroundThreadTimer;// timer which is running in background
@property (strong, nonatomic) CLLocationManager* wakeUpThreadLocationManager;// fake location manager just to continue running in background. very innacurate so works fast

@property (strong, atomic) NSString* currentlyConnectedWiFi;// name of currently connected wifi network

@property BOOL forceReportLocationOnce;// if YES then report latest best detected position to JS once and then set it to NO. Used when user opens dashboard to detect best position and to send it to server

@property (atomic) NSTimeInterval lastCreatedCrashNotificationTimeStamp;// time when we last time created crash notification

@end

@implementation GPSReporter

@synthesize currentlyConnectedWiFi = _currentlyConnectedWiFi;
@synthesize locationManager = _locationManager;


//////////////////////////////////////////
/// Public API
//////////////////////////////////////////


- (void)startMonitoringGPS:(CDVInvokedUrlCommand *)command {
	DLog(@"startMonitoringGPS:%@", command);
    
	NSString *URL = [command.arguments objectAtIndex:0];
	NSString *authCode = [command.arguments objectAtIndex:1];
    [StandaloneGPSReporter setLocationMonitoringEnabled:YES];
    [StandaloneGPSReporter setServerURL:URL andAuthCode:authCode];
  
    if ([self useConstantlyRunningGPSInBackground]) {
        [self.wakeUpThreadLocationManager startUpdatingLocation];
    }
    
    self.gpsMonitoringEnabled = YES;
    
    [self checkLowBatteryMode];
    
    [self findOutCurrentPositionAndReportItToJS];

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
	[self writeJavascript:[pluginResult toSuccessCallbackString:command.callbackId]];
}

- (void)stopMonitoringGPS:(CDVInvokedUrlCommand *)command
{
    [StandaloneGPSReporter setLocationMonitoringEnabled:NO];
    
    if ([self useConstantlyRunningGPSInBackground]) {
        [self.wakeUpThreadLocationManager stopUpdatingLocation];
    }
    
    self.gpsMonitoringEnabled = NO;
    [self stopBackgroundTask];
    [self resetCrashLocalNotification];

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
	[self writeJavascript:[pluginResult toSuccessCallbackString:command.callbackId]];
}

-(void)forceReportCurrentLocation:(CDVInvokedUrlCommand *)command
{
    [self checkLowBatteryMode];
    NSLog(@"forceReportCurrentLocation received");
    self.forceReportLocationOnce = YES;
    [self findOutCurrentPositionAndReportItToJS];
    

	CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsBool:YES];
	[self writeJavascript:[pluginResult toSuccessCallbackString:command.callbackId]];
}



//////////////////////////////////////////
/// Implementation
//////////////////////////////////////////

-(BOOL)useConstantlyRunningGPSInBackground {
    return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0");//7.0
}

- (void) onPause
{
    /*
    if (self.gpsMonitoringEnabled) {
        if ([self useConstantlyRunningGPSInBackground]) {
            [self.wakeUpThreadLocationManager startUpdatingLocation];
        }
    }
     */
}

- (void) onResume
{
    /*
    if ([self useConstantlyRunningGPSInBackground]) {
        [self.wakeUpThreadLocationManager stopUpdatingLocation];
    }
     */
}

-(GPSReporterHelper*)helper
{
    if (!_helper)
    {
        _helper = [[GPSReporterHelper alloc] init];
    }
    return _helper;
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
-(CLLocationManager*)wakeUpThreadLocationManager
{
    if (!_wakeUpThreadLocationManager)
    {
        _wakeUpThreadLocationManager = [[CLLocationManager alloc] init];
        // setup very unprecise manager
        _wakeUpThreadLocationManager.delegate = self;
        _wakeUpThreadLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        _wakeUpThreadLocationManager.distanceFilter = 100;
        if ([_wakeUpThreadLocationManager respondsToSelector:@selector(pausesLocationUpdatesAutomatically)]) {
            _wakeUpThreadLocationManager.pausesLocationUpdatesAutomatically = NO;
        }
    }
    return _wakeUpThreadLocationManager;
}


// save current mode to user defaults
-(void)saveLowBatteryMode:(BOOL)enabled {
    NSMutableDictionary* savedData = [[[NSUserDefaults standardUserDefaults] dictionaryForKey:USER_SETTINGS_DICT_NAME] mutableCopy];
    if (!savedData) {
        savedData = [[NSMutableDictionary alloc] init];
    }
    savedData[USER_SETTINGS_DICT_LOW_BATTERY_MODE_ENABLED] = [NSNumber numberWithBool:enabled];
    
    NSDictionary* data = [savedData copy];
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:USER_SETTINGS_DICT_NAME];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}

// read current mode from user defaults
-(BOOL)getSavedLowBatteryMode {
    NSDictionary* savedData = [[NSUserDefaults standardUserDefaults] dictionaryForKey:USER_SETTINGS_DICT_NAME];
    NSNumber* savedMode = [savedData objectForKey:USER_SETTINGS_DICT_LOW_BATTERY_MODE_ENABLED];
    BOOL mode = NO;
    if (savedMode) {
        mode = [savedMode boolValue];
    }
    
    return mode;
}

-(void)showDebugNotificationWithText:(NSString*)text {
#ifdef DEBUG
    [self showNotificationWithText:text];
#endif
}

-(void)showNotificationWithText:(NSString*)text {
    UIApplication* app = [UIApplication sharedApplication];
    UIApplicationState state = [app applicationState];
    if (state == UIApplicationStateActive) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Low battery mode"
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
}

// Show notification to user that mode has been activated
-(void)showLowBatteryModeActivatedNotification {
    [self showNotificationWithText:@"Lokki detected low battery charge and stopped reporting in background. Start Lokki again manually after you charge the battery."];
}


// check if low battery mode needs to be activated or deactivated
-(void)checkLowBatteryMode {
    BOOL currentMode = [self getSavedLowBatteryMode];
    self.lowBatteryModeActivated = currentMode;
    float batteryLevel = [self.helper getBatteryLevel];
    
    if (batteryLevel >= 0 && batteryLevel < CRITICAL_BATTERY_LEVEL_TO_ENABLE_LOW_BATTERY_MODE) {
        self.lowBatteryModeActivated = YES;

        if (currentMode == NO) {
            NSLog(@"Activating low battery mode");
            [self showLowBatteryModeActivatedNotification];
            [self saveLowBatteryMode:YES];
            [self stopBackgroundTask];
            [self.wakeUpThreadLocationManager stopUpdatingLocation];
            [StandaloneGPSReporter setLocationMonitoringEnabled:NO];
            [self resetCrashLocalNotification];
            
        }
        
    } else {
        if (batteryLevel > (CRITICAL_BATTERY_LEVEL_TO_ENABLE_LOW_BATTERY_MODE + 0.03)) {
            // 0.03 to give phone some slack before switching mode off
            if (currentMode != NO) {
                [self saveLowBatteryMode:NO];
                self.lowBatteryModeActivated = NO;
                [self findOutCurrentPositionAndReportItToJS];// start background timer and report location if needed
                [StandaloneGPSReporter setLocationMonitoringEnabled:YES];
                
                if ([self useConstantlyRunningGPSInBackground]) {
                    [self.wakeUpThreadLocationManager startUpdatingLocation];
                }
                
            }
        }
    }
    
}



-(void)findOutCurrentPositionAndReportItToJS
{
    if (!self.gpsMonitoringEnabled) {
        NSLog(@"Monitoring has been disabled! Ignore findOutCurrentPositionAndReportItToJS");
        return;
    }
    [self.locationManager startUpdatingLocation];
    [self startBackgroundTaskIfNotYetStarted];
    [self startTimerToStopLocationUpdates];
}

-(void)startTimerToStopLocationUpdates
{
    if (!self.stopLocationManagerTimer)
    {
        NSTimeInterval timeout = ((self.forceReportLocationOnce) ? MAX_TIME_FOR_FORCED_POSITION_UPDATES : MAX_TIME_FOR_POSITION_UPDATES);
        self.stopLocationManagerTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                              target:self
                                            selector:@selector(stopLocationManagerTimerFired:)
                                            userInfo:nil
                                             repeats:NO];
    }
}

-(void)stopLocationManagerTimerFired:(NSTimer*)timer
{
    // if we did not report location yet - do it
    BOOL needToReport = self.forceReportLocationOnce || ([self secondsSinceLastGPSReport] > MAX_TIME_FOR_FORCED_POSITION_UPDATES);
    if (needToReport) {
        // if we did not report yet - do it
        if (self.locationManager.location) {
            //NSLog(@"Reporting location");
            [self reportLocationToJS:self.locationManager.location];
        }
        self.forceReportLocationOnce = NO;
    }
    
    [self.locationManager stopUpdatingLocation];
    self.stopLocationManagerTimer = nil;
}


-(void)sendCoordinatesToJS:(NSString*)position fromLocation:(CLLocation*)location
{
    if (!self.gpsMonitoringEnabled) {
        NSLog(@"Monitoring has been disabled! Ignore sendCoordinatesToJS");
        return;
    }
    [self showDebugNotificationWithText:[NSString stringWithFormat:@"Sending %d meters accurate location to JS", (int)location.horizontalAccuracy]];
    
    NSString *jsStatement = [NSString stringWithFormat:@"window.plugins.GPSReporter.GPSCallback(%@);", position];
    NSLog(@"Executing '%@'", jsStatement);
	[self writeJavascript:jsStatement];
}


-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (manager == self.wakeUpThreadLocationManager) {
        return;//just ignore
    }
    CLLocation* newLocation = [locations lastObject];
    [self onNewLocation:newLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    if (manager == self.wakeUpThreadLocationManager) {
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
    if (locationAge > 20.0) {
        return;
    }
    
    // in force reporting we report even slight changes
    CLLocationDistance filterDistance = DISTANCE_FILTER;
    
    CLLocationDistance distance = [self.previousReportedLocation distanceFromLocation:newLocation];
    if (self.previousReportedLocation && distance < filterDistance)
    {
        if (distance > 0.1) {
            // location is not the same as previous but close. if accuracy is good enough or similar to accuracy of previous report - stop trying to get better location
            if (newLocation.horizontalAccuracy < ACCURACY_TO_STOP_GETTING_BETTER_READING) {
                [self.locationManager stopUpdatingLocation];
            }
        }
        // ignore all changes in location with less than DISTANCE_FILTER meters change
        NSLog(@"New location reported but it is very close to old one (%f m), so ignore this: %@", distance, newLocation);
        return;// comment it for testing without movements
    }
    
    NSLog(@"User moved %f meters", distance);
    
    [self reportLocationToJS:newLocation];
}


-(void)reportLocationToJS:(CLLocation*)newLocation
{
    [StandaloneGPSReporter startMonitoringForRegionAroundCurrentLocation:newLocation.coordinate];
    
    self.lastGPSReportTime = [[NSDate date] timeIntervalSince1970];
    NSString* str = [NSString stringWithFormat:@"[lat=%f, lon=%f, acc=%f]", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy];
    [self sendCoordinatesToJS:str fromLocation:newLocation];

    BOOL forceStopReadingBecauseLocationIsGreat = (newLocation.horizontalAccuracy >= 0 && newLocation.horizontalAccuracy < 15.0);
    
    // stop searching for new location if accuracy is good enough and already reported once location (location manager usualy sends once old data)
    if (self.previousReportedLocation && (forceStopReadingBecauseLocationIsGreat || !self.forceReportLocationOnce) && newLocation.horizontalAccuracy < ACCURACY_TO_STOP_GETTING_BETTER_READING)
    {
        if (self.stopLocationManagerTimer)
        {
            [self.stopLocationManagerTimer invalidate];
            self.stopLocationManagerTimer = nil;
        };
        // don't stop monitoring if it is first position which we have got because it is most likely buggy one
        [self.locationManager stopUpdatingLocation];
    }
    
    self.previousReportedLocation = newLocation;
    self.previousReportedLocationTime = [[NSDate date] timeIntervalSince1970];    
}


-(void)startBackgroundTaskIfNotYetStarted
{
    if (self.lowBatteryModeActivated) {
        NSLog(@"Don't start background task because low battery mode is activated");
        return;
    }
    
    [self resetBackgroundTimeRemainingCounter];
    
    if (self.backgroundTaskIdentifier)
        return;

    [self createCrashLocalNotification];

    if (![self useConstantlyRunningGPSInBackground]) {
        self.backgroundTaskIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^
                                         {
                                             [self stopBackgroundTask];
                                         }
                                         ];
        NSLog(@"Started background task with backgroundTaskIdentifier=%d", self.backgroundTaskIdentifier);
    }
    
    if (!self.backgroundThreadTimer) {
        dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.backgroundThreadTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, backgroundQueue);
        dispatch_source_set_timer(self.backgroundThreadTimer, dispatch_time(DISPATCH_TIME_NOW, 0), SECONDS_TO_SLEEP_IN_BACKGROUND_TASK*NSEC_PER_SEC, 5*NSEC_PER_SEC);
        dispatch_source_set_event_handler(self.backgroundThreadTimer, ^{
            [self backgroundTask:self.backgroundTaskIdentifier];
        });
        dispatch_resume(self.backgroundThreadTimer);
    }
    
    // Start the long-running task and return immediately.
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self backgroundTask:self.backgroundTaskIdentifier];
//    });
    
}

-(void)stopBackgroundTask
{
    NSLog(@"Stopping background task");
    if (self.backgroundTaskIdentifier)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundTaskIdentifier];
        self.backgroundTaskIdentifier = 0;
    }
    if (self.backgroundThreadTimer) {
        dispatch_source_cancel(self.backgroundThreadTimer);
        dispatch_release(self.backgroundThreadTimer);
        self.backgroundThreadTimer = 0;
    }
    [self resetCrashLocalNotification];// don't show crash message to user
}

-(NSUInteger)getCrashNotificationTimeout {
#ifdef DEBUG
    return 4*SECONDS_TO_SLEEP_IN_BACKGROUND_TASK;
#else
    return 17*SECONDS_TO_SLEEP_IN_BACKGROUND_TASK;//every half an hour in release build (2*SECONDS_TO_SLEEP_IN_BACKGROUND_TASK) is to have time to reset and recreate notifications
#endif
}

-(void)resetCrashLocalNotification
{
    //buggy with ios7
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        return;
    }
    UIApplication* app = [UIApplication sharedApplication];
    NSArray*    oldNotifications = [app scheduledLocalNotifications];
    if ([oldNotifications count] > 0)
        [app cancelAllLocalNotifications];    
}

-(void)createCrashLocalNotification
{
    //buggy with ios7
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        return;
    }
    self.lastCreatedCrashNotificationTimeStamp = [[NSDate date] timeIntervalSince1970];

    UIApplication* app = [UIApplication sharedApplication];
    // Create a new notification.
    UILocalNotification* alarm = [[UILocalNotification alloc] init];
    if (alarm)
    {
        alarm.fireDate = [NSDate dateWithTimeIntervalSinceNow:[self getCrashNotificationTimeout]];
        alarm.timeZone = [NSTimeZone defaultTimeZone];
        alarm.repeatInterval = 0;
        alarm.soundName = @"default";
        NSString* body = [NSString stringWithFormat:@"It looks like Lokki is not running anymore. Start it again if you want your family to see where you are."];
        alarm.alertBody = body;
        [app scheduleLocalNotification:alarm];
        [alarm release];
    }
}

// if crash notification is already created then kill it and create new one after some time
-(void)updateCrashLocalNotification
{
    //buggy with ios7
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
        return;
    }
    if (self.lowBatteryModeActivated) {
        [self resetCrashLocalNotification];
        return;        
    }
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval diff = 0;
    if (currentTime > self.lastCreatedCrashNotificationTimeStamp)
        diff = currentTime - self.lastCreatedCrashNotificationTimeStamp;
    else
        diff = self.lastCreatedCrashNotificationTimeStamp - currentTime;
    // don't recreate notifications all the time but give it some time to run and recreate after it runs for 25% of it's time
    if (diff > ([self getCrashNotificationTimeout]/4)) {
        [self resetCrashLocalNotification];
        [self createCrashLocalNotification];
    }
}

-(void)backgroundTask:(NSUInteger)myID
{
    [self checkLowBatteryMode];
    [self updateCrashLocalNotification];
    
    if (self.gpsMonitoringEnabled && myID == self.backgroundTaskIdentifier)
    {
        //NSLog(@"Background thread for task %d executed", myID);
        [self oneBackgroundTaskTick];
        if ([UIApplication sharedApplication].backgroundTimeRemaining < 600)
        {
            //NSLog(@"Background task left %f tick at %@", [UIApplication sharedApplication].backgroundTimeRemaining, [NSDate date]);
            if ([UIApplication sharedApplication].backgroundTimeRemaining < SECONDS_BEFORE_TERMINATION_TO_ACTIVATE_GPS)
            {
                [self resetBackgroundTimeRemainingCounter];
            }
        }
        else
        {
            //NSLog(@"Background task left is not limited by time");
        }
    } else {
        NSLog(@"!!! Background thread for task %d executed when not expected!", myID);
    }
}


-(void)resetBackgroundTimeRemainingCounter
{
    if ([self useConstantlyRunningGPSInBackground]) {
        return;
    }
    
    [self.wakeUpThreadLocationManager startUpdatingLocation];
    [self.wakeUpThreadLocationManager stopUpdatingLocation];
}

// One single background task tick. should verify if device is moving - then query new position
-(void)oneBackgroundTaskTick
{    
    BOOL needToQueryNewPosition = ([self secondsSinceLastGPSReport] >= SECONDS_TO_SEND_POS_PERIODICALY);
    if (needToQueryNewPosition) {
        self.forceReportLocationOnce = YES;// do force reporting or else location may be ignored
    }
    
    NSString* currentWiFi = [self.helper getCurrentlyConnectedWiFi];
    BOOL wifiChangedOrNotConnected = ([currentWiFi compare:@""] == NSOrderedSame);
    //wifiChangedOrNotConnected = YES;
    if (self.currentlyConnectedWiFi == nil || [self.currentlyConnectedWiFi compare:currentWiFi] != NSOrderedSame)
    {
        NSLog(@"Wifi changed from %@ to %@", self.currentlyConnectedWiFi, currentWiFi);
        self.currentlyConnectedWiFi = currentWiFi;
        wifiChangedOrNotConnected = YES;
    }
    
    if (wifiChangedOrNotConnected && !needToQueryNewPosition)
    {
        needToQueryNewPosition = [self.helper isDeviceMoving];
        if (needToQueryNewPosition) {
            NSLog(@"Device is moving - query new position");
        }
    }

    if (needToQueryNewPosition)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self findOutCurrentPositionAndReportItToJS];
        });
        
    }
    
}

-(NSTimeInterval)secondsSinceLastGPSReport
{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    if (currentTime > self.lastGPSReportTime)
        return currentTime - self.lastGPSReportTime;
    else
        return self.lastGPSReportTime - currentTime;
}

@end
