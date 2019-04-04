#import "RNDiscovery.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>

#import "Discovery/Discovery.h"


@interface RNDiscovery()

@property (strong, nonatomic) id bleStateObserver;
@property (strong, nonatomic) Discovery * discovery;

@end

@implementation RNDiscovery

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

#pragma mark Initialization


- (instancetype)init
{
    if (self = [super init]) {
        NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey: @NO};
        _bluetoothManager = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue() options:options];
    }
    
    return self;
}

+(BOOL)requiresMainQueueSetup
{
    return YES;
}

/**
 * Initialize the Discovery object with a UUID specific to your device, and a service specific to your app.
 */
RCT_REMAP_METHOD(initialize, initialize:(NSString *)uuidString service:(NSString *)service resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (self.bleStateObserver == nil) {
        self.bleStateObserver = [[NSNotificationCenter defaultCenter] addObserverForName:kBluetoothStateNotificationKey object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {

            NSInteger centralState = [(NSNumber *)note.userInfo[kBluetoothCentralStateKey] integerValue];
            BOOL isOn = centralState == CBCentralManagerStatePoweredOn;
            NSDictionary *event = @{ @"isOn" : @(isOn)};
            [self.bridge.eventDispatcher sendDeviceEventWithName:@"bleStateChanged" body:event];
        }];
    }

 
    if (self.discovery != nil) {
        [self.discovery setShouldDiscover: NO];
        [self.discovery setShouldAdvertise: NO];
        self.discovery = nil;
    }


    self.discovery = [[Discovery alloc] initWithUUID: [CBUUID UUIDWithString:uuidString]
                                       service: service
                                    startOption:DIStartNone
                                     usersBlock:^(NSArray *users, BOOL usersChanged) {
                                         [self discovery:uuidString discoveredUsers:users didChange:usersChanged];
                                     }];

    resolve(uuidString);
}

/**
 * run on the main queue otherwise discovery timers dont work.
 */
- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}


-(void)discovery:(NSString *)uuidString discoveredUsers:(NSArray *)users didChange:(BOOL) usersChanged {
    NSMutableArray *array = [NSMutableArray array];
    for (BLEUser *user in users) {
        [array addObject:[self convertBLEUserToDict:user]];
    }

    NSDictionary *event = @{
                            @"uuid": uuidString,
                            @"users": array,
                            @"usersChanged": @(usersChanged)
                            };

    [self.bridge.eventDispatcher sendDeviceEventWithName:@"discoveredUsers" body:event];
}

-(NSDictionary *)convertBLEUserToDict:(BLEUser *)bleUser{

    NSDictionary *dict = @{
                           @"peripheralId":bleUser.peripheralId,
                           @"service":bleUser.service,
                           @"uuid":bleUser.uuid,
                           @"identified":@(bleUser.identified),
                           @"rssi":@(bleUser.rssi),
                           @"proximity":@(bleUser.proximity),
                           @"updateTime":@(bleUser.updateTime)
                           };

    return dict;
}


/**
 * Returns the user user from our user dictionary according to its peripheralId.
 */
RCT_REMAP_METHOD(userWithPeripheralId, peripheralId:(NSString *)peripheralId resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (self.discovery) {
        BLEUser *user = [self.discovery userWithPeripheralId:peripheralId];
        resolve(user ? [self convertBLEUserToDict:user] : @{});
    } else {
        reject(@"not_initialized", [NSString stringWithFormat:@"discovery not initialized"], [NSError errorWithDomain:@"RNDiscovery" code:0 userInfo:nil]);
    }
}


/**
 * Changing these properties will start/stop advertising/discovery
 */
RCT_REMAP_METHOD(setShouldAdvertise, shouldAdvertise:(BOOL)shouldAdvertise resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (self.discovery) {
        [self.discovery setShouldAdvertise:shouldAdvertise];
        resolve(@YES);
    } else {
        reject(@"not_initialized", [NSString stringWithFormat:@"discovery not initialized"], [NSError errorWithDomain:@"RNDiscovery" code:0 userInfo:nil]);
    }

}

RCT_REMAP_METHOD(setShouldDiscover, shouldDiscover:(BOOL)shouldDiscover resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (self.discovery) {
        [self.discovery setShouldDiscover:shouldDiscover];
        resolve(@YES);
    } else {
        reject(@"not_initialized", [NSString stringWithFormat:@"discovery not initialized"], [NSError errorWithDomain:@"RNDiscovery" code:0 userInfo:nil]);
    }
}


/*
 * Discovery removes the users if can not re-see them after some amount of time, assuming the device-user is gone.
 * The default value is 3 seconds. You can set your own values.
 */
RCT_REMAP_METHOD(setUserTimeoutInterval, userTimeoutInterval:(int)userTimeoutInterval resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (self.discovery) {
        [self.discovery setUserTimeoutInterval:userTimeoutInterval];
        resolve(@YES);
    } else {
        reject(@"not_initialized", [NSString stringWithFormat:@"discovery initialized"], [NSError errorWithDomain:@"RNDiscovery" code:0 userInfo:nil]);
    }
}

/*
 * Update interval is the interval that your usersBlock gets triggered.
 */
RCT_REMAP_METHOD(setUpdateInterval, updateInterval:(int)updateInterval resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (self.discovery) {
        [self.discovery setUpdateInterval:updateInterval];
        resolve(@YES);
    } else {
        reject(@"not_initialized", [NSString stringWithFormat:@"discovery not initialized"], [NSError errorWithDomain:@"RNDiscovery" code:0 userInfo:nil]);
    }
}

/**
 * Set this to YES, if your app will disappear, or set to NO when it will appear.
 * You don't have to set YES when your app goes to background state, Discovery handles that.
 */
RCT_REMAP_METHOD(setPaused, paused:(BOOL)paused resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if (self.discovery) {
        [self.discovery setPaused:paused];
        resolve(@YES);
    } else {
        reject(@"not_initialized", [NSString stringWithFormat:@"discovery not initialized"], [NSError errorWithDomain:@"RNDiscovery" code:0 userInfo:nil]);
    }
}

RCT_REMAP_METHOD(isBluetoothEnabled, resolve:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject)
{
    if(_bluetoothManager) {
        if([_bluetoothManager state] == CBCentralManagerStatePoweredOn) {
            resolve(@YES);
        }
        else {
            resolve(@NO);
        }
    }
}

-(void)centralManagerDidUpdateState:(CBCentralManager *)central{}



@end
