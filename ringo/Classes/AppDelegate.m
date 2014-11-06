/*
 Licensed to the Apache Software Foundation (ASF) under one
 or more contributor license agreements.  See the NOTICE file
 distributed with this work for additional information
 regarding copyright ownership.  The ASF licenses this file
 to you under the Apache License, Version 2.0 (the
 "License"); you may not use this file except in compliance
 with the License.  You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing,
 software distributed under the License is distributed on an
 "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 KIND, either express or implied.  See the License for the
 specific language governing permissions and limitations
 under the License.
 */

//
//  AppDelegate.m
//  ringo
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//  Copyright ___ORGANIZATIONNAME___ ___YEAR___. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "PushNotification.h"
#ifdef DEBUG
    #import "mach/mach.h"
#endif
#import "./../Flurry/Flurry.h"
#import <FacebookSDK/FacebookSDK.h>

#import <Cordova/CDVPlugin.h>
#import "StandaloneGPSReporter.h"

@interface AppDelegate()
    @property (strong, nonatomic) StandaloneGPSReporter* standaloneGPSReporter;
@end


@implementation AppDelegate

@synthesize window, viewController, enteringForegroundMode;

-(StandaloneGPSReporter*)standaloneGPSReporter
{
    if (!_standaloneGPSReporter)
    {
        _standaloneGPSReporter = [[StandaloneGPSReporter alloc] init];
    }
    return _standaloneGPSReporter;
}

- (void) redirectConsoleLogToDocumentFolder
{
#ifdef DEBUG
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *logPath = [documentsDirectory stringByAppendingPathComponent:@"console.log"];
    freopen([logPath cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
    NSLog(@"************************************************");
    NSLog(@"************************************************");

    NSLog(@"App started at %@", [[NSDate date] description]);

    NSLog(@"************************************************");
    NSLog(@"************************************************");
#endif
}

- (id)init
{
    [self report_memory:@"init1"];
    self = [super init];
    
#ifdef DEBUG
    //[self redirectConsoleLogToDocumentFolder];
#endif
    /** If you need to do any extra app-specific initialization, you can do it here
     *  -jm
     **/
    NSHTTPCookieStorage* cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];

    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];

    int cacheSizeMemory = 1 * 1024 * 1024; // 8MB
    int cacheSizeDisk = 8 * 1024 * 1024; // 32MB
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString* documentsDirectory = [paths objectAtIndex:0];
    NSString* diskCachePath = [NSString stringWithFormat:@"%@/%@", documentsDirectory, @"Caches/myCache"];
    
    #if __has_feature(objc_arc)
        NSURLCache* cacheMngr = [[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:diskCachePath];
    #else
        NSURLCache* cacheMngr = [[[NSURLCache alloc] initWithMemoryCapacity:cacheSizeMemory diskCapacity:cacheSizeDisk diskPath:diskCachePath] autorelease];
    #endif
    

    [NSURLCache setSharedURLCache:cacheMngr];
    
    [self.standaloneGPSReporter quicklyQueryLocationAndSendToServer];// do query immediately if can
    
    // ask to run every 4 minutes
//    if ([[UIApplication sharedApplication] respondsToSelector:@selector(setMinimumBackgroundFetchInterval:)]) {
  //      [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:(4*60)];
    //}
    

    [self report_memory:@"init2"];

    return self;
}

#pragma mark UIApplicationDelegate implementation


-(void)createViewAndController
{
    NSLog(@"createViewAndController");
    CGRect screenBounds = [[UIScreen mainScreen] bounds];
    
    #if __has_feature(objc_arc)
        self.window = [[UIWindow alloc] initWithFrame:screenBounds];
    #else
        self.window = [[[UIWindow alloc] initWithFrame:screenBounds] autorelease];
    #endif
    
    self.window.autoresizesSubviews = YES;
    
    #if __has_feature(objc_arc)
        self.viewController = [[MainViewController alloc] init];
    #else
        self.viewController = [[[MainViewController alloc] init] autorelease];
    #endif
    
    // Set your app's start page by setting the <content src='foo.html' /> tag in config.xml.
    // If necessary, uncomment the line below to override it.
    // self.viewController.startPage = @"index.html";
    
    // NOTE: To customize the view's frame size (which defaults to full screen), override
    // [self.viewController viewWillAppear:] in your view controller.
    
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
}

-(void)deleteViewAndController
{
    [self.viewController release];
    self.viewController = nil;
    [self.window release];
    self.window = nil;
}

-(void)initializeFullApp {
    NSLog(@"initializeFullApp");
    
    [Flurry setAppVersion:@"2.0.0"];
    [Flurry setBackgroundSessionEnabled:NO];
    [Flurry startSession:@"BX96572V53TGCTVXCN49"];
    
    [self createViewAndController];
    
}

/**
 * This is main kick off after the app inits, the views and Settings are setup here. (preferred - iOS4 and up)
 */
- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    NSLog(@"application didFinishLaunchingWithOptions");
    if ([launchOptions objectForKey:UIApplicationLaunchOptionsLocationKey]) {
        [self.standaloneGPSReporter quicklyQueryLocationAndSendToServer];
        [self report_memory:@"didFinishLaunchingWithOptions for location"];
        return YES;// do not create view controller if started to handle location
    }

    NSLog(@"application didFinishLaunchingWithOptions initializing full app");
    [self initializeFullApp];

    /* Handler when launching application from push notification */
    // PushNotification - Handle launch from a push notification
    NSDictionary* userInfo = [launchOptions objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
    if(userInfo) {
        PushNotification *pushHandler = [self.viewController getCommandInstance:@"PushNotification"];
        NSMutableDictionary* mutableUserInfo = [userInfo mutableCopy];
        [mutableUserInfo setValue:@"1" forKey:@"applicationLaunchNotification"];
        [mutableUserInfo setValue:@"0" forKey:@"applicationStateActive"];
        [pushHandler.pendingNotifications addObject:mutableUserInfo];
        
        [mutableUserInfo release];
    }
    /* end code block */
    
    return YES;
}

//-(void)application:(UIApplication *)application performFetchWithCompletionHandler:(void(^) (UIBackgroundFetchResult))completionHandler
//{
 //   NSLog(@"performFetchWithCompletionHandler background task executed");
 //   usleep(1000*1000*2);
 //   completionHandler(UIBackgroundFetchResultNewData);
//}

/**
 * This is main kick off after the app inits, the views and Settings are setup here. (preferred - iOS4 and up)
 */
- (BOOL)application:(UIApplication*)application willFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
//    NSLog(@"application willFinishLaunchingWithOptions");
    
    return YES;
}

// this happens while we are running ( in the background, or from within our own app )
// only valid if ringo-Info.plist specifies a protocol to handle
- (BOOL)application:(UIApplication*)application handleOpenURL:(NSURL*)url
{
    if (!self.window) {
        return NO;
    }
    NSLog(@"application handleOpenURL");
    if (!url) {
        return NO;
    }

    // calls into javascript global function 'handleOpenURL'
    NSString* jsString = [NSString stringWithFormat:@"handleOpenURL(\"%@\");", url];
    [self.viewController.webView stringByEvaluatingJavaScriptFromString:jsString];

    // all plugins will get the notification, and their handlers will be called
    [[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:CDVPluginHandleOpenURLNotification object:url]];

    return YES;
}

// repost the localnotification using the default NSNotificationCenter so multiple plugins may respond
- (void)           application:(UIApplication*)application
   didReceiveLocalNotification:(UILocalNotification*)notification
{
    // re-post ( broadcast )
    [[NSNotificationCenter defaultCenter] postNotificationName:CDVLocalNotification object:notification];
}

- (NSUInteger)application:(UIApplication*)application supportedInterfaceOrientationsForWindow:(UIWindow*)window
{
    // iPhone doesn't support upside down by default, while the iPad does.  Override to allow all orientations always, and let the root view controller decide what's allowed (the supported orientations mask gets intersected).
    NSUInteger supportedInterfaceOrientations = (1 << UIInterfaceOrientationPortrait) | (1 << UIInterfaceOrientationLandscapeLeft) | (1 << UIInterfaceOrientationLandscapeRight) | (1 << UIInterfaceOrientationPortraitUpsideDown);

    return supportedInterfaceOrientations;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    NSLog(@"applicationDidEnterBackground");
    //[self deleteViewAndController];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    NSLog(@"applicationWillEnterForeground");
    self.enteringForegroundMode = YES;
    [self report_memory:@"applicationWillEnterForeground"];
    
    if (!self.window) {
        [self initializeFullApp];
    }
   
    
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
        NSLog(@"Memory in use in %@: %u MB", where, info.resident_size/1024/1024);
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
#endif
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    NSLog(@"applicationDidBecomeActive");
    self.enteringForegroundMode = NO;

    if (self.window) {
        [FBSettings setDefaultAppID:@"413632302078455"];
        [FBAppEvents activateApp];
    
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 1];
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber: 0];
        [[UIApplication sharedApplication] cancelAllLocalNotifications];
    }

    [self report_memory:@"report_memory"];
    
}


/* START BLOCK */
#pragma PushNotification delegation

- (void)application:(UIApplication*)app
didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
    PushNotification* pushHandler = [self.viewController getCommandInstance:@"PushNotification"];
    [pushHandler didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
}

- (void)application:(UIApplication*)app didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    PushNotification* pushHandler = [self.viewController getCommandInstance:@"PushNotification"];
    [pushHandler didFailToRegisterForRemoteNotificationsWithError:error];
}

- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    NSLog(@"application didReceiveRemoteNotification");
    if (!self.window) {
        return;
    }
    PushNotification* pushHandler = [self.viewController getCommandInstance:@"PushNotification"];
    NSMutableDictionary* mutableUserInfo = [userInfo mutableCopy];
    
    // Get application state for iOS4.x+ devices, otherwise assume active
    UIApplicationState appState = UIApplicationStateActive;
    if ([application respondsToSelector:@selector(applicationState)]) {
        appState = application.applicationState;
    }
    
    [mutableUserInfo setValue:@"0" forKey:@"applicationLaunchNotification"];
    if (appState == UIApplicationStateActive) {
        [mutableUserInfo setValue:@"1" forKey:@"applicationStateActive"];
    } else {
        [mutableUserInfo setValue:@"0" forKey:@"applicationStateActive"];
    }
    
    if (appState == UIApplicationStateActive || self.enteringForegroundMode) {
        [pushHandler didReceiveRemoteNotification:mutableUserInfo];
    } else {
        [mutableUserInfo setValue:[NSNumber numberWithDouble: [[NSDate date] timeIntervalSince1970]] forKey:@"timestamp"];
        [pushHandler.pendingNotifications addObject:mutableUserInfo];
    }
    
    [mutableUserInfo release];
}
/* STOP BLOCK */
@end
