//
//  ServerApi.h
//  locmap
//
//  Created by Oleg Fedorov on 11/20/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MapKit/MapKit.h"
#import "SingleServerRequest.h"

@class ServerApi;

// no error
#define SERVER_ERROR_SUCCESS 200

// auth code is invalid - signup again
#define SERVER_ERROR_SIGNUP_WRONG_AUTH_CODE 401

// maximum places
#define SERVER_ERROR_PLACES_LIMIT 403


@protocol ServerApiDelegate
    - (void)serverApi:(ServerApi *)api finishedOperation:(ServerOperationType)type withResult:(BOOL)success withResponse:(NSDictionary *)response;

@end


// main functions for server api.
// Use ServerApi+messages category to send concrete messages
@interface ServerApi : NSObject

    @property (weak, nonatomic) id<ServerApiDelegate> delegate;// delegate to get notifications about requests finished

    // designated initializer
    -(id)initWithDelegate:(id<ServerApiDelegate>)delegate;

    // returns number of currently active requests (0 if all requests are finished)
    -(int)getNumberOfActiveRequests;


    -(NSString*)getServerURL;
    -(NSString*)getAuthCode;
    -(NSString*)getUserId;
    -(BOOL)loggedIn;
    -(void)sendData:(NSData*)requestData toURL:(NSString*)URL  forOperationType:(ServerOperationType)operationType;

    // returns error code from response provided into finishedOperation if success=NO
    // 200 means no error
    -(NSInteger)getErrorCodeFromResponse:(NSDictionary*)response;
@end

