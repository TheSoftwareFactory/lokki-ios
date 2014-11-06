//
//  ServerApi.m
//  locmap
//
//  Created by Oleg Fedorov on 11/20/13.
//  Copyright (c) 2013 F-Secure. All rights reserved.
//

#import "ServerApi.h"
#import "SingleServerRequest.h"
#import "Foundation/NSJSONSerialization.h"
#import "LocalStorage.h"

@interface ServerApi() <NSURLConnectionDataDelegate>
    @property (strong, atomic) NSMutableArray* serverConnections;//array of SingleServerRequest* for all current connections

    -(SingleServerRequest*)getServerRequestForConnection:(NSURLConnection*)connection;
@end



@implementation ServerApi

// designated initializer
-(id)initWithDelegate:(id<ServerApiDelegate>)delegate
{
    if ((self = [super init])) {
        self.delegate = delegate;
        self.serverConnections = [[NSMutableArray alloc] init];
    }
    return self;
   
}



-(NSString*)getServerURL
{
    return @"https://ringo-server.f-secure.com/api/locmap/v1";
    //return @"http://ringo-test-environment.herokuapp.com/api/locmap/v1";
}


-(NSString*)getAuthCode
{
    return [LocalStorage getAuthToken];
}


-(NSString*)getUserId
{
    return [LocalStorage getLoggedInUserId];
}

-(BOOL)loggedIn
{
    NSString* URL = [self getServerURL];
    NSString* authCode = [self getAuthCode];
    NSString* userId = [self getUserId];
    // only report location which is not too old
    if (!URL || !authCode || !userId) {
        return NO;
    }
    return YES;
}

-(void)sendData:(NSData*)requestData toURL:(NSString*)URL forOperationType:(ServerOperationType)operationType
{
    NSMutableURLRequest *theRequest=[NSMutableURLRequest    requestWithURL:[NSURL URLWithString:[URL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]
                                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval:30.0];
    //do post request for parameter passing
    switch(operationType) {
        case ServerOperationDashboard:
        case ServerOperationGetPlaces:
            [theRequest setHTTPMethod:@"GET"];
        break;
        case ServerOperationDisallow:
        case ServerOperationDeletePlace:
            [theRequest setHTTPMethod:@"DELETE"];        
        break;
        case ServerOperationChangeVisibility:
        case ServerOperationEditPlace:
            [theRequest setHTTPMethod:@"PUT"];
        break;
        case ServerOperationPostLocation:
        case ServerOperationSignup:
        case ServerOperationAllow:
        case ServerOperationRegisterAPN:
        case ServerOperationRequestLocationUpdates:
        case ServerOperationAddPlace:
            [theRequest setHTTPMethod:@"POST"];
            break;
        default:
            NSLog(@"Unknown operation type, cannot find out what to do with it!");
    }
    
    //set the content type to JSON
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [theRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    [theRequest addValue:[self getAuthCode] forHTTPHeaderField:@"authorizationtoken"];
    [theRequest addValue:@"iOS" forHTTPHeaderField:@"platform"];
    [theRequest addValue:@"3.1" forHTTPHeaderField:@"version"];
    //TODO: still missing: version: commonService.version,
    
    if (requestData) {
        [theRequest setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestData length]] forHTTPHeaderField:@"Content-Length"];
        [theRequest setHTTPBody: requestData];
    }
    
    NSURLConnection* serverConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    SingleServerRequest* request = [[SingleServerRequest alloc] initWithConnection:serverConnection forOperationType:operationType];
    [self.serverConnections addObject:request];
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    SingleServerRequest* request = [self getServerRequestForConnection:connection];
    ServerOperationType type = ServerOperationUnknown;
    if (request) {
        type = request.type;
    } else {
        NSLog(@"didFailWithError for unknown connection: %@", connection);
    }
    [self removeServerRequestForConnection:connection];

    NSDictionary *jsonResult = @{@"error": [error localizedDescription],
                                 @"serverErrorCode": [NSNumber numberWithInt:(int)[error code]]
                                 };

    [self.delegate serverApi:self finishedOperation:type withResult:NO withResponse:jsonResult];
    

}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    //NSLog(@"Posting to server succeeded");
    SingleServerRequest* request = [self getServerRequestForConnection:connection];
    NSData* data;
    ServerOperationType type = ServerOperationUnknown;
    if (request) {
        data = [request.data copy];
        type = request.type;
    } else {
        NSLog(@"connectionDidFinishLoading for unknown connection: %@", connection);
        data = [[NSData alloc] init];
    }

    [self removeServerRequestForConnection:connection];
    NSDictionary *jsonResult=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    

    [self.delegate serverApi:self finishedOperation:type withResult:YES withResponse:jsonResult];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    SingleServerRequest* request = [self getServerRequestForConnection:connection];
    
    if (request) {
        request.data = [[NSMutableData alloc] init];
    } else {
        NSLog(@"didReceiveResponse for unknown connection: %@", connection);
    }
    
    if ([response respondsToSelector:@selector(statusCode)])
    {
        int statusCode = (int)[((NSHTTPURLResponse *)response) statusCode];
        if (statusCode != 200)
        {
            [connection cancel];  // stop connecting; no more delegate messages
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat:@"Server returned status code %d", statusCode] forKey:NSURLErrorFailingURLStringErrorKey];
            NSError *statusError = [NSError errorWithDomain:@"Error" code:statusCode userInfo:errorInfo];
            [self connection:connection didFailWithError:statusError];
        } else {
            
        }
    }
    
}



- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    SingleServerRequest* request = [self getServerRequestForConnection:connection];

    if (request) {
        [request.data appendData:data];
    } else {
        NSLog(@"didReceiveData for unknown connection: %@", connection);
    }
}

-(int)getNumberOfActiveRequests
{
    return (int)[self.serverConnections count];
}

-(SingleServerRequest*)getServerRequestForConnection:(NSURLConnection*)connection
{
    for(SingleServerRequest* request in self.serverConnections) {
        if (request.serverConnection == connection) {
            return request;
        }
    }
    return nil;
}

-(BOOL)removeServerRequestForConnection:(NSURLConnection*)connection
{
    for(SingleServerRequest* request in self.serverConnections) {
        if (request.serverConnection == connection) {
            [self.serverConnections removeObjectIdenticalTo:request];
            return YES;
        }
    }
    return NO;
}

-(NSInteger)getErrorCodeFromResponse:(NSDictionary*)response
{
    if (!response || ![response objectForKey:@"serverErrorCode"]) {
        return 200;
    }
    
    NSNumber* n = response[@"serverErrorCode"];
    if (!n) {
        return 200;
    }
    return [n integerValue];
}



@end

