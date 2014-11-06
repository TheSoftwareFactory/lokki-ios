//
//  LocMapAppDelegate.m
//  locmap
//
//  Created by Oleg Fedorov on 11/14/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "LocMapAppDelegate.h"

#import "LocMapViewController.h"
#import "StandaloneGPSReporter.h"
#import "ServerApi+messages.h"
#import "LocalStorage.h"
#import "FSConstants.h"

#ifdef DEBUG
    #import "mach/mach.h"
#endif


@interface LocMapAppDelegate() <ServerApiDelegate>
    @property (strong, nonatomic) StandaloneGPSReporter* standaloneGPSReporter;
    @property (strong, nonatomic) ServerApi* serverApi;

    @property (strong, nonatomic) NSString* apnToken;
@end



@implementation LocMapAppDelegate

-(StandaloneGPSReporter*)standaloneGPSReporter
{
    if (!_standaloneGPSReporter)
    {
        _standaloneGPSReporter = [[StandaloneGPSReporter alloc] init];
    }
    return _standaloneGPSReporter;
}

- (id)init
{
    //[self report_memory:@"init1"];
    self = [super init];
    self.serverApi = [[ServerApi alloc] initWithDelegate:self];

    //[self.standaloneGPSReporter quicklyQueryLocationAndSendToServer];// do query immediately if can
    
    //[self report_memory:@"init2"];
    
    return self;
}

void uncaughtExceptionHandler(NSException *exception) {
    
    NSLog(@"Call Stack: %@", exception.callStackSymbols);
}


- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [LocalStorage clearCache];
    [[FSConstants instance] clearCache];
}


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    NSLog(@"application didFinishLaunchingWithOptions");
#endif
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    

    if ([launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSLog(@"Remote Notification Recieved in didFinishLaunchingWithOptions");
        NSDictionary *remoteNotif = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
        [self didReceiveRemoteNotification:remoteNotif];
        return YES;
    }
    
    if ([LocalStorage getAuthToken]) {
        [self.standaloneGPSReporter stopLocationUpdates];// stop updates so next call to quicklyQueryLocationAndSendToServer will send location
        [self.standaloneGPSReporter quicklyQueryLocationAndSendToServer];// do query immediately if can
    }
    
	UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeNewsstandContentAvailability | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert;
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:notificationTypes];
    
    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
    [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
    if ([LocalStorage getAuthToken]) {
        [self.serverApi requestLocationUpdates];//update where everyone is
        
        [self.standaloneGPSReporter quicklyQueryLocationAndSendToServer];// do query immediately if can
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ReloadCachedContacts" object:self];
    
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

-(void)onSuccessfulLogin
{
    if ([LocalStorage getAuthToken]) {
        if (self.apnToken && [self.apnToken length]) {
            [self.serverApi registerAPNToken:self.apnToken];
        }
        
        [self.standaloneGPSReporter stopLocationUpdates];// stop updates so next call to quicklyQueryLocationAndSendToServer will send location
        [self.standaloneGPSReporter quicklyQueryLocationAndSendToServer];// do query immediately if can
        
        [self.serverApi requestLocationUpdates];//update where everyone is
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
#ifdef DEBUG
	NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken:%@", deviceToken);
#endif
	self.apnToken = [[[[deviceToken description] stringByReplacingOccurrencesOfString:@"<"withString:@""]
						stringByReplacingOccurrencesOfString:@">" withString:@""]
					   stringByReplacingOccurrencesOfString: @" " withString: @""];
    
#ifdef DEBUG
	NSLog(@"Token:%@", self.apnToken);
#endif
    if ([LocalStorage getAuthToken]) {
        [self.serverApi registerAPNToken:self.apnToken];
    }
    
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	NSLog(@"didFailToRegisterForRemoteNotificationsWithError:%@", error);
    self.apnToken = @"";
    if ([LocalStorage getAuthToken]) {
        [self.serverApi registerAPNToken:self.apnToken];// clear token
    }
    
}

// used in case if app is not yet started at all
- (void)didReceiveRemoteNotification:(NSDictionary*)userInfo {
	NSLog(@"didReceiveRemoteNotification:%@", userInfo);
    [self.standaloneGPSReporter quicklyQueryLocationAndSendToServer];
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSLog(@"Remote Notification Recieved in didReceiveRemoteNotification fetchCompletionHandler");
    [self.standaloneGPSReporter stopLocationUpdates];// stop current manager to get new location immediately
    [self.standaloneGPSReporter quicklyQueryLocationAndSendToServerInBackgroundWithCompletionHandler:^void() {
        completionHandler(UIBackgroundFetchResultNewData);
    }];
    //[self showDebugNotificationWithText:[NSString stringWithFormat:@"didReceiveRemoteNotification: %@", userInfo]];
}

    

 - (void)serverApi:(ServerApi *)api finishedOperation:(ServerOperationType)type withResult:(BOOL)success withResponse:(NSDictionary *)response
{
    if (type != ServerOperationRegisterAPN && type != ServerOperationRequestLocationUpdates) {
        NSLog(@"Unknown operation reported in delegate finishedOperation: %d", (int)type);
        return;
    }
    NSLog(@"APN registered with status: %d and response %@", (int)success, response);
}


-(void) report_memory:(NSString*)where {
#ifdef DEBUG
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use in %@: %d MB", where, (int)(info.resident_size/1024/1024));
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
#endif
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
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
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
}
    
@end
