//
//  AppRater.m
//
//  Created by Oleg Fedorov on 25/01/14.
//  Copyright (c) 2014 F-Secure. All rights reserved.
//

#import "AppRater.h"
#import <MessageUI/MessageUI.h>
#import "LocalStorage.h"

// after 4 days
#define DAYS_TO_SHOW_RATE_REMINDER 4

// after at least 8 times was opened
#define TIMES_TO_OPEN_MENU_TO_SHOW_RATE_REMINDER 8

#define DO_YOU_LIKE_DIALOG_TAG 111
#define RATE_SELECTION_DIALOG_TAG 222

@interface AppRater() <UIAlertViewDelegate, MFMailComposeViewControllerDelegate>

    @property (strong) UIViewController* controllerWhichPresentedAlert;
@end


@implementation AppRater

+(AppRater*)instance {
    static AppRater *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}



// show app rater only when user enters menu
-(void)onTrigger {
    [self incHowManyTimesOpenedMenu];
    
    // uncomment to test again
//    [LocalStorage setValue:[NSDate dateWithTimeIntervalSinceNow:-60*60*24*30] forKey:@"AppRaterFirstTimeTriggered"];//installed month ago
  //  [LocalStorage deleteStoredDataForKey:@"AppRaterDoYouLikeQuestionShown"];
    //[LocalStorage deleteStoredDataForKey:@"AppRaterDone"];
    
    if ([LocalStorage getValueForKey:@"AppRaterDone"]) {
        return;
    }
    
    
    if ([LocalStorage getValueForKey:@"AppRaterDoYouLikeQuestionShown"]) {
        if ([self timeToShowRatePleaseDialogAgain]) {
            [self showRatePleaseDialog];
        }
        return;
    }
    
    if ([self timeToShowDoYouLikeDialog]) {
        [self showDoYouLikeDialog];
        return;
    }
    
}

// show it DAYS_TO_SHOW_RATE_REMINDER after first launch when user entered menu at least TIMES_TO_OPEN_MENU_TO_SHOW_RATE_REMINDER
-(BOOL)timeToShowDoYouLikeDialog {
    if ([self howManyTimesOpenedMenu] < TIMES_TO_OPEN_MENU_TO_SHOW_RATE_REMINDER) {
        return NO;
    }
    NSTimeInterval dt = [[self firstTimeOpenedDate] timeIntervalSinceNow];
    dt = fabs(dt);
    double daysPassed = dt/60/60/24;
    if (daysPassed > DAYS_TO_SHOW_RATE_REMINDER) {
        return YES;
    }
    return NO;
}

// dialog asking if user likes app or not
// show this dialog only once and save "AppRaterDoYouLikeQuestionShown" so it will not be shown again
-(void)showDoYouLikeDialog {
    [self markDoYouLikeQuestionShown];
    UIAlertView *message = [[UIAlertView alloc] initWithTitle:_LOCALIZE(@"AppRaterDoYouLikeTitle")
                                                      message:_LOCALIZE(@"AppRaterDoYouLikeQuestion")
                                                     delegate:self
                                            cancelButtonTitle:_LOCALIZE(@"NO")
                                            otherButtonTitles:_LOCALIZE(@"YES"), nil];
    
    message.tag = DO_YOU_LIKE_DIALOG_TAG;
    [message show];
    
}

// if user wants to rate later - show dialog again next day
-(BOOL)timeToShowRatePleaseDialogAgain {
    NSDate* date = [LocalStorage getValueForKey:@"AppRaterLastDateWhenRateDialogWasShown"];
    NSTimeInterval dt = fabs([date timeIntervalSinceNow]);
    double days = dt/60/60/24;
    if (days > 1) {
        return YES;
    }
    return NO;
}

// show rate please dialog with 3 buttons: rate, later, never
-(void)showRatePleaseDialog {
    [LocalStorage setValue:[NSDate dateWithTimeIntervalSinceNow:0] forKey:@"AppRaterLastDateWhenRateDialogWasShown"];
    
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:_LOCALIZE(@"AppRaterReviewQuestionTitle")
                                                        message:_LOCALIZE(@"AppRaterReviewQuestion")
                                                       delegate:self
                                              cancelButtonTitle:_LOCALIZE(@"AppRaterNoThanks")
                                              otherButtonTitles:_LOCALIZE(@"AppRaterRate"), _LOCALIZE(@"AppRaterRemindLater"), nil];
	alertView.tag = RATE_SELECTION_DIALOG_TAG;
    [alertView show];
}

-(void)markAppRaterDone {
    [LocalStorage setValue:@"Done" forKey:@"AppRaterDone"];
}

-(void)markDoYouLikeQuestionShown {
    [LocalStorage setValue:@"Done" forKey:@"AppRaterDoYouLikeQuestionShown"];
}


-(int)howManyTimesOpenedMenu {
    NSNumber* timesOpened = [LocalStorage getValueForKey:@"HowManyTimesMenuOpened"];
    if (!timesOpened) {
        return 0;
    }
    return (int)[timesOpened integerValue];
}

// date when app was first time opened (launched)
-(NSDate*)firstTimeOpenedDate {
    NSDate* firstOpenDate = [LocalStorage getValueForKey:@"AppRaterFirstTimeTriggered"];
    if (!firstOpenDate) {
        firstOpenDate = [NSDate dateWithTimeIntervalSinceNow:0];
    }
    return firstOpenDate;
    
}

-(void)incHowManyTimesOpenedMenu {
    NSDate* firstOpenDate = [LocalStorage getValueForKey:@"AppRaterFirstTimeTriggered"];
    if (!firstOpenDate) {
        firstOpenDate = [NSDate dateWithTimeIntervalSinceNow:0];
        [LocalStorage setValue:firstOpenDate forKey:@"AppRaterFirstTimeTriggered"];
    }
    
    int n = [self howManyTimesOpenedMenu] + 1;
    [LocalStorage setValue:[NSNumber numberWithInt:n] forKey:@"HowManyTimesMenuOpened"];
}



// Called when a button is clicked. The view will be automatically dismissed after this call returns
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == DO_YOU_LIKE_DIALOG_TAG) {
        if (buttonIndex == 0) {
            [self onDontLike];
        } else {
            [self onDoLike];
        }
    } else if (alertView.tag == RATE_SELECTION_DIALOG_TAG) {
        
        if (buttonIndex == 0) {
            // no, thanks
            [self markAppRaterDone];
        } else if (buttonIndex == 1) {
            //rate
            [self rateInAppStore];
            [self markAppRaterDone];
        } else if (buttonIndex == 2) {
            // remind later
            // it happens automaticaly in 1 day
        }
        
    }
}


+ (UIViewController *) topMostViewController: (UIViewController *) controller {
	BOOL isPresenting = NO;
	do {
		// this path is called only on iOS 6+, so -presentedViewController is fine here.
		UIViewController *presented = [controller presentedViewController];
		isPresenting = presented != nil;
		if(presented != nil) {
			controller = presented;
		}
		
	} while (isPresenting);
	
	return controller;
}

+ (id)getRootViewController {
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal) {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(window in windows) {
            if (window.windowLevel == UIWindowLevelNormal) {
                break;
            }
        }
    }
    
    for (UIView *subView in [window subviews])
    {
        UIResponder *responder = [subView nextResponder];
        if([responder isKindOfClass:[UIViewController class]]) {
            return [self topMostViewController: (UIViewController *) responder];
        }
    }
    
    return nil;
}


// user does not like app, show send feedback dialog
-(void)onDontLike {
    MFMailComposeViewController *mailController = [[MFMailComposeViewController alloc] init];
    
    mailController.mailComposeDelegate = self;
    
    if([MFMailComposeViewController canSendMail]){
        [mailController setSubject:_LOCALIZE(@"FeedbackEmailSubject")];
        [mailController setMessageBody:_LOCALIZE(@"SendFeedbackBodyWhenUserDoesNotLike") isHTML:NO];
        [mailController setToRecipients:[NSArray arrayWithObject:@"lokki-feedback@f-secure.com"]];
        [mailController setTitle:_LOCALIZE(@"Send feedback")];
        [[AppRater getRootViewController] presentViewController:mailController animated:YES completion:nil];
    }else{
        NSLog(@"Mail is not configured");
        UIAlertView *message = [[UIAlertView alloc] initWithTitle:nil
                                                          message:_LOCALIZE(@"MailClientNotConfigured")
                                                         delegate:nil
                                                cancelButtonTitle:_LOCALIZE(@"OK")
                                                otherButtonTitles:nil];
        [message show];
    }
}


- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    NSLog(@"Mail composer returned: %d (%@)", (int)result, error);
    [controller dismissViewControllerAnimated:YES completion:nil];
}


// user does like app
-(void)onDoLike {
    [self showRatePleaseDialog];
}


-(void)rateInAppStore {
    NSString *reviewURL = @"itms-apps://itunes.apple.com/app/id669949035";
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
    
}



@end
