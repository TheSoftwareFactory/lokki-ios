//
//  GPSReporterHelperTest.m
//  CordovaLib
//
//  Created by Oleg Fedorov on 4/26/13.
//
//

#import "GPSReporterHelperTest.h"
#import "../GPSReporterHelper.h"

@interface GPSReporterHelperTest()

@property (strong, nonatomic) GPSReporterHelper* helper;

@end

@implementation GPSReporterHelperTest


- (void)setUp
{
    [super setUp];
    
    self.helper = [[GPSReporterHelper alloc] init];
    NSLog(@"set up");
}

- (void)tearDown
{
    NSLog(@"tear down");
    [self.helper release];
    
    [super tearDown];
}

- (void)testBatteryLevel
{
    float level = [self.helper getBatteryLevel];
    [self verifyBatteryLevelIsGood:level];
}

- (void)testBatteryLevelCanBeExecutedSeveralTimes
{
    float level = [self.helper getBatteryLevel];
    level = [self.helper getBatteryLevel];
    level = [self.helper getBatteryLevel];// check that we can call it several times
    [self verifyBatteryLevelIsGood:level];
}

-(void)verifyBatteryLevelIsGood:(float)level
{
    NSLog(@"batteryLevel = %f", level);
    BOOL levelIsGood = NO;
    
#if TARGET_IPHONE_SIMULATOR
    levelIsGood = (-1.0f == level);// in simulator we get always -1
#endif
    
    levelIsGood = levelIsGood || (level >= 0 && level <= 1);
    STAssertTrue(levelIsGood, @"Got wrong battery level: %f", level);    
}

- (void)testBatteryLevelDoesNotEnableBatteryMonitoring
{
    STAssertFalse([UIDevice currentDevice].batteryMonitoringEnabled, @"Battery monitoring must be disabled");
    [self.helper getBatteryLevel];
    STAssertFalse([UIDevice currentDevice].batteryMonitoringEnabled, @"Battery monitoring must be disabled");
}


#if TARGET_IPHONE_SIMULATOR

    -(void)testDeviceIsMovingInSimulator
    {
        BOOL deviceIsMoving = [self.helper isDeviceMoving];
        STAssertTrue(deviceIsMoving, @"Emulator does not have accelerometer so isDeviceMoving should always return YES");
    }

#else //#if TARGET_IPHONE_SIMULATOR

    -(void)testDeviceIsMovingOnRealDevice
    {
        BOOL deviceIsMoving = [self.helper isDeviceMoving];
        NSLog(@"Device is moving: %d", deviceIsMoving);
    }

#endif

-(void)testGetCurrentlyConnectedWiFi
{
    NSString* wifi = [self.helper getCurrentlyConnectedWiFi];
    NSLog(@"Conneted wifi: %@", wifi);
    
    STAssertNotNil(wifi, @"getCurrentlyConnectedWiFi must never return nil");
    
#if TARGET_IPHONE_SIMULATOR
    STAssertEquals(wifi, @"", @"In simulator wifi is always empty but got: '%@'", wifi);
#endif
}

@end

