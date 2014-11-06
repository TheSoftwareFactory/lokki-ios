//
//  Tutorial.h
//  Lokki
//
//  Created by Oleg Fedorov on 12/10/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TutorialDelegate <NSObject>
@optional

// Called when tutorial wants to add friends
- (void)tutorialRequestToAddFriends;

@end



@interface Tutorial : NSObject

    // show welcome to Lokki dialog if needed (has not been not shown before)
    +(void)triggerWelcomeToLokki;

    // show no friends in Lokki yet tutorial if needed
    +(void)triggerNoFriendsYet:(id<TutorialDelegate>)delegate;

    // we explain to user that he will see whom he invited when they invite him back
    +(void)triggerExplanationAfterAddingFriends:(NSArray*)emails;

    // Show error message to user if background refresh is not enabled
    +(void)checkIfBackgroundRefreshEnabled;

    // show error message to user if location service is disabled for app
    +(void)checkIfLocationServiceEnabled;

@end
