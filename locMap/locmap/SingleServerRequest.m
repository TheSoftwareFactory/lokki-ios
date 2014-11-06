//
//  SingleServerRequest.m
//  locmap
//
//  Created by Oleg Fedorov on 11/21/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "SingleServerRequest.h"


@implementation SingleServerRequest

-(id)initWithConnection:(NSURLConnection*)connection forOperationType:(ServerOperationType)type
{
    if ((self = [super init])) {
        self.serverConnection = connection;
        self.data = [[NSMutableData alloc] init];
        self.type = type;
    }
    return self;
}

@end

