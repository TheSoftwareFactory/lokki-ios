//
//  Tutorial.m
//  Lokki
//
//  Created by Oleg Fedorov on 12/10/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "Tutorial.h"
#import "LocalStorage.h"
#import <MapKit/MapKit.h>

@interface NoFriendsYetDelegate : NSObject <UIAlertViewDelegate>
    @property (strong) id<TutorialDelegate> delegate;

    -(id)initWithDelegate:(id<TutorialDelegate>)delegate;
@end

static NoFriendsYetDelegate* gDelegate;

@implementation NoFriendsYetDelegate

-(id)initWithDelegate:(id<TutorialDelegate>)delegate
{
    self = [super init];
    self.delegate = delegate;
    return self;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        // open add people
        [self.delegate tutorialRequestToAddFriends];
        
    }
}

@end


@implementation Tutorial


+(void)triggerWelcomeToLokki
{
    id shown = [LocalStorage getValueForKey:@"TutorialWelcomeToLokki"];
    if (shown) {
        return;
    }
    [LocalStorage setValue:[NSNumber numberWithBool:YES] forKey:@"TutorialWelcomeToLokki"];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_LOCALIZE(@"Tutorial")
                                                        message:_LOCALIZE(@"TutorialMessageWelcomeToLokki")
                                                       delegate:nil
                                              cancelButtonTitle:_LOCALIZE(@"OK")
                                              otherButtonTitles:nil, nil];
    [alertView show];
    
    
}

+(void)triggerNoFriendsYet:(id<TutorialDelegate>)delegate
{
    gDelegate = [[NoFriendsYetDelegate alloc] initWithDelegate:delegate];
    
    UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:_LOCALIZE(@"Tutorial")
                                                    message:_LOCALIZE(@"TutorialMessageAddFriends")
                                                    delegate:gDelegate
                                                    cancelButtonTitle:_LOCALIZE(@"Later")
                                                    otherButtonTitles:_LOCALIZE(@"Yes"), nil];
    [alertView show];
    
}


+(void)triggerExplanationAfterAddingFriends:(NSArray*)emails
{
//    [NSTimer scheduledTimerWithTimeInterval:1 target:gDelegate selector:@selector(triggerExplanationAfterAddingFriends:) userInfo:emails repeats:NO];
    
    NSString* text = [NSString stringWithFormat:_LOCALIZE(@"TutorialMessageSomeoneCanSeeYou"), [Tutorial getNamesByEmails:emails]];
    UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:_LOCALIZE(@"Tutorial")
                                                    message:text
                                                    delegate:nil
                                                    cancelButtonTitle:_LOCALIZE(@"OK")
                                                    otherButtonTitles:nil, nil];
    [alertView show];
}


+(NSString*)getNamesByEmails:(NSArray*)emails
{
    NSString* names = @"";
    for(NSString* email in emails) {
        NSString* name = [LocalStorage getUserNameByEmail:email];
        if (name) {
            if ([names isEqualToString:@""]) {
                names = name;
            } else {
                names = [names stringByAppendingString:@", "];
                names = [names stringByAppendingString:name];
            }
        }
    }
    
    return names;
}


+(void)checkIfBackgroundRefreshEnabled
{
    static BOOL alreadyChecked = NO;// do it only once
    if (alreadyChecked) {
        return;
    }
    alreadyChecked = YES;
    
    
    if ([[UIApplication sharedApplication] backgroundRefreshStatus] != UIBackgroundRefreshStatusAvailable) {
        NSLog(@"Error: Background updates are not available for the app.");
        
        // we should not block main thread now because it hangs
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* text = _LOCALIZE(@"Background refresh is not enabled");
            UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:nil
                                                            message:text
                                                            delegate:nil
                                                            cancelButtonTitle:_LOCALIZE(@"OK")
                                                            otherButtonTitles:nil, nil];
            [alertView show];
        });
        
    }
}


+(void)checkIfLocationServiceEnabled
{
    static BOOL alreadyChecked = NO;// do it only once
    if (alreadyChecked) {
        return;
    }
    
    CLAuthorizationStatus status = [CLLocationManager authorizationStatus];
    if (status == kCLAuthorizationStatusNotDetermined) {
        return;
    }
    alreadyChecked = YES;
    if (status != kCLAuthorizationStatusAuthorized) {
        NSLog(@"Error: Location services are not available for the app.");
        
        // we should not block main thread now because it hangs
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString* text = _LOCALIZE(@"Location services are not enabled");
            UIAlertView *alertView = [[UIAlertView alloc]   initWithTitle:nil
                                                              message:text
                                                             delegate:nil
                                                    cancelButtonTitle:_LOCALIZE(@"OK")
                                                    otherButtonTitles:nil, nil];
            [alertView show];
        });
        
    }
    
}


@end
