//
//  SingleServerRequest.h
//  locmap
//
//  Created by Oleg Fedorov on 11/21/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, ServerOperationType) {
    ServerOperationPostLocation,
    ServerOperationSignup,
    ServerOperationDashboard,
    ServerOperationAllow,
    ServerOperationDisallow,
    ServerOperationRegisterAPN,
    ServerOperationRequestLocationUpdates,
    ServerOperationChangeVisibility,
    ServerOperationAddPlace,
    ServerOperationEditPlace,
    ServerOperationDeletePlace,
    ServerOperationGetPlaces,
    ServerOperationUnknown
};

// class to store connections and it's data
@interface SingleServerRequest : NSObject

    @property (strong, atomic) NSURLConnection* serverConnection;
    @property (strong, atomic) NSMutableData *data;
    @property (atomic) ServerOperationType type;

    -(id)initWithConnection:(NSURLConnection*)connection forOperationType:(ServerOperationType)type;

@end