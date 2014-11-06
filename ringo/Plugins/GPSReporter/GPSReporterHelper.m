//
//  GPSReporterHelper.m
//  ringo
//
//  Created by Oleg Fedorov on 4/26/13.
//
//

#import "GPSReporterHelper.h"
#import <CoreMotion/CoreMotion.h>
#import <SystemConfiguration/CaptiveNetwork.h>


#define ACCELERATION_DIFF_TO_RECOGNIZE_MOVEMENT 0.1 // We assume device is moving when accelerometer shows changed bigger than that. default: 0.1


@interface GPSReporterHelper()
    @property double batteryLevel;
@end



@implementation GPSReporterHelper



-(NSString*)getCurrentlyConnectedWiFi
{
    NSArray *ifs = (id)CNCopySupportedInterfaces();
    //NSLog(@"Supported interfaces: %@", ifs);
    CFDictionaryRef info = NULL;
    for (NSString *ifnam in ifs)
    {
        info = CNCopyCurrentNetworkInfo((CFStringRef)ifnam);
        //NSLog(@"%@ => %@", ifnam, (id)info);
        if (info && CFDictionaryGetCount(info))
        {
            break;
        }
        [(id)info release];
        info = NULL;
    }
    [ifs release];
    
    if (info)
    {
        NSString* ssid = (NSString*)CFDictionaryGetValue(info, kCNNetworkInfoKeySSID);
        [ssid retain];
        [(id)info release];
        //NSLog(@"Currently connected wifi: %@", ssid);
        return [ssid autorelease];
    }
    
    //NSLog(@"Currently not connected to wifi");
    return @"";
}


// Use giro to find out if device is moving or not
-(BOOL)isDeviceMoving
{
    CMMotionManager* motionManager = [[CMMotionManager alloc] init];

    if (!motionManager.accelerometerAvailable) {
        [motionManager release];
        return YES;// assume that device is moving if accelerometer is not available
    }
    
    [motionManager startAccelerometerUpdates];
    
    CGFloat x_diff = 0, y_diff = 0, z_diff = 0;
    CMAcceleration lastKnownAccelerationData;
    BOOL lastKnownAccelerationDataInititalized = NO;
    
    NSInteger measuresLeft = 10;
    while(measuresLeft > 0)
    {
        usleep(0.1*1000*1000);
        --measuresLeft;
        if (motionManager.accelerometerData)
        {
            if (lastKnownAccelerationDataInititalized)
            {
                if (fabsf(motionManager.accelerometerData.acceleration.x - lastKnownAccelerationData.x) > x_diff)
                    x_diff = fabsf(motionManager.accelerometerData.acceleration.x - lastKnownAccelerationData.x);
                if (fabsf(motionManager.accelerometerData.acceleration.y - lastKnownAccelerationData.y) > y_diff)
                    y_diff = fabsf(motionManager.accelerometerData.acceleration.y - lastKnownAccelerationData.y);
                if (fabsf(motionManager.accelerometerData.acceleration.z - lastKnownAccelerationData.z) > z_diff)
                    z_diff = fabsf(motionManager.accelerometerData.acceleration.z - lastKnownAccelerationData.z);
                if (x_diff > ACCELERATION_DIFF_TO_RECOGNIZE_MOVEMENT || y_diff > ACCELERATION_DIFF_TO_RECOGNIZE_MOVEMENT || z_diff > ACCELERATION_DIFF_TO_RECOGNIZE_MOVEMENT)
                    break;
            }
            lastKnownAccelerationDataInititalized = YES;
            lastKnownAccelerationData = motionManager.accelerometerData.acceleration;
        }
    }
    
    [motionManager stopAccelerometerUpdates];
    BOOL moved = (x_diff > ACCELERATION_DIFF_TO_RECOGNIZE_MOVEMENT || y_diff > ACCELERATION_DIFF_TO_RECOGNIZE_MOVEMENT || z_diff > ACCELERATION_DIFF_TO_RECOGNIZE_MOVEMENT);
    //NSLog(@"moving: %@, accelerometer diff: %f, %f, %f", moved?@"yes":@"no", x_diff, y_diff, z_diff);
    [motionManager release];
    return moved;
}

-(float)getBatteryLevel
{
    [self performSelectorOnMainThread:@selector(getBatteryLevelImpl) withObject:nil waitUntilDone:YES];
    return self.batteryLevel;
}

-(float)getBatteryLevelImpl
{
    BOOL wasEnabled = [UIDevice currentDevice].batteryMonitoringEnabled;
    if (!wasEnabled) {
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    }
    
    float batteryLevel = [UIDevice currentDevice].batteryLevel;

    if (!wasEnabled) {
        [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    }
    
    self.batteryLevel = batteryLevel;
    return batteryLevel;
}

@end

