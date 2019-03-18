//
//  Discovery.m
//  DiscoveryExample
//
//  Created by Ömer Faruk Gül on 08/02/15.
//  Copyright (c) 2015 Ömer Faruk Gül. All rights reserved.
//

#import "Discovery.h"

@interface Discovery()
@property (nonatomic, copy) void (^usersBlock)(NSArray *users, BOOL usersChanged);
@property (strong, nonatomic) NSTimer *timer;
@end

@implementation Discovery

- (instancetype)initWithUUID:(CBUUID *)uuid
                    service:(NSString *)service
                startOption:(DIStartOptions)startOption
                  usersBlock:(void (^)(NSArray *users, BOOL usersChanged))usersBlock {
    self = [super init];
    if(self) {
        _uuid = uuid;
        _service = service;
        _usersBlock = usersBlock;
        
        _paused = NO;
        
        _userTimeoutInterval = 10;
        _updateInterval = 2;
        


        // listen for UIApplicationDidEnterBackgroundNotification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        
        // listen for UIApplicationDidEnterBackgroundNotification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appWillEnterForeground:)
                                                     name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        
        
        // we will hold the detected users here
        self.usersMap = [NSMutableDictionary dictionary];
        
        // start the central and peripheral managers
        self.queue = dispatch_queue_create("com.omerfarukgul.discovery", DISPATCH_QUEUE_SERIAL);
        
        _shouldAdvertise = NO;
        _shouldDiscover = NO;
        
        switch (startOption) {
            case DIStartAdvertisingAndDetecting:
                self.shouldAdvertise = YES;
                self.shouldDiscover = YES;
                break;
            case DIStartAdvertisingOnly:
                self.shouldAdvertise = YES;
                break;
            case DIStartDetectingOnly:
                self.shouldDiscover = YES;
                break;
            case DIStartNone:
            default:
                break;
        }
        
    }
    
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
}

-(void)setShouldAdvertise:(BOOL)shouldAdvertise {
    if(_shouldAdvertise == shouldAdvertise)
        return;
    
    _shouldAdvertise = shouldAdvertise;
    
    if(shouldAdvertise) {
        if (!self.peripheralManager)
            self.peripheralManager = [[CBPeripheralManager alloc] initWithDelegate:self queue:self.queue options:@{CBCentralManagerOptionShowPowerAlertKey : @(NO)}];
    } else {
        if (self.peripheralManager) {
            [self.peripheralManager stopAdvertising];
            self.peripheralManager.delegate = nil;
            self.peripheralManager = nil;
        }
    }
    
    
}

-(void)setShouldDiscover:(BOOL)shouldDiscover {
    if(_shouldDiscover == shouldDiscover)
        return;
    
    _shouldDiscover = shouldDiscover;
    
    if(shouldDiscover) {
        if (!self.centralManager)
            self.centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:self.queue options:@{CBCentralManagerOptionShowPowerAlertKey : @(NO)}];
        if (!self.timer)
            [self startTimer];
    } else {
        if (self.centralManager) {
            [self.centralManager stopScan];
            self.centralManager.delegate = nil;
            self.centralManager = nil;
        }
        if (self.timer)
            [self stopTimer];
    }
}

-(instancetype)initWithUUID:(CBUUID *)uuid service:(NSString *)service usersBlock:(void (^)(NSArray *, BOOL))usersBlock {
    self = [self initWithUUID:uuid service:service startOption:DIStartAdvertisingAndDetecting usersBlock:usersBlock];
    return self;
}


- (void)startTimer {
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.updateInterval target:self
                                                selector:@selector(checkList) userInfo:nil repeats:YES];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)setUpdateInterval:(NSTimeInterval)updateInterval {
    _updateInterval = updateInterval;
    
    // restart the timers
    [self stopTimer];
    [self startTimer];
}

- (void)setPaused:(BOOL)paused {
    
    if(_paused == paused)
        return;
    
    _paused = paused;
    
    if(paused) {
        [self stopTimer];
        [self.centralManager stopScan];
    }
    else {
        [self startTimer];
        [self startDetecting];
    }
}

- (void)appDidEnterBackground:(NSNotification *)notification {
    [self stopTimer];
}

- (void)appWillEnterForeground:(NSNotification *)notification {
    [self startTimer];
}

- (void)startAdvertising {
    
    NSDictionary *advertisingData = @{CBAdvertisementDataLocalNameKey:self.service,
                                      CBAdvertisementDataServiceUUIDsKey:@[self.uuid]
                                      };
    
    // create our characteristics
    CBMutableCharacteristic *characteristic =
    [[CBMutableCharacteristic alloc] initWithType:self.uuid
                                       properties:CBCharacteristicPropertyRead
                                            value:[self.service dataUsingEncoding:NSUTF8StringEncoding]
                                      permissions:CBAttributePermissionsReadable];
    
    // create the service with the characteristics
    CBMutableService *service = [[CBMutableService alloc] initWithType:self.uuid primary:YES];
    service.characteristics = @[characteristic];
    [self.peripheralManager addService:service];
    
    [self.peripheralManager startAdvertising:advertisingData];
}

- (void)startDetecting {
    
    NSDictionary *scanOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@(YES)};
    NSArray *services = nil;
    
    // we listen to the all services
    // maybe bad for performance and battery consumption
    [self.centralManager scanForPeripheralsWithServices:services options:scanOptions];
}

- (void)peripheralManagerDidStartAdvertising:(CBPeripheralManager *)peripheral error:(NSError *)error {
    
}

- (void)peripheralManagerDidUpdateState:(CBPeripheralManager *)peripheral {
    if(peripheral.state == CBPeripheralManagerStatePoweredOn) {
        [self startAdvertising];
    }
    
    //record the state because it's not accessible thru the peripheral manager
    self.peripheralManagerState = peripheral.state;
    
    [self notifyOfChangedState];
}



- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    if (central.state == CBCentralManagerStatePoweredOn) {
        [self startDetecting];
    }
    
    [self notifyOfChangedState];
}

- (void)notifyOfChangedState {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kBluetoothStateNotificationKey
                                                            object:nil
                                                          userInfo:@{kBluetoothCentralStateKey : @(self.centralManager.state),
                                                                     kBluetoothPeripheralStateKey : @(self.peripheralManagerState)}];
    });
    
}

- (void)updateList {
    [self updateList:YES];
}

- (void)updateList:(BOOL)usersChanged {
    
    NSMutableArray *users;
    
    @synchronized(self.usersMap) {
        users = [[[self usersMap] allValues] mutableCopy];
    }
    
    // remove unidentified users
    NSMutableArray *discardedItems = [NSMutableArray array];
    for (BLEUser *user in users) {
        if (!user.isIdentified)
            [discardedItems addObject:user];
    }
    [users removeObjectsInArray:discardedItems];
    
    // we sort the list according to "proximity".
    // so the client will receive ordered users according to the proximity.
    [users sortUsingDescriptors: [NSArray arrayWithObjects: [NSSortDescriptor sortDescriptorWithKey:@"proximity"
                                                                                          ascending:NO], nil]];
    
    if(self.usersBlock) {
        self.usersBlock([users mutableCopy], usersChanged);
    }
}

- (void)checkList {
    
    double currentTime = [[NSDate date] timeIntervalSince1970];
    
    NSMutableArray *discardedKeys = [NSMutableArray array];
    
    for (NSString* key in self.usersMap) {
        BLEUser *bleUser = [self.usersMap objectForKey:key];
        
        NSTimeInterval diff = currentTime - bleUser.updateTime;
        
        // We remove the user if we haven't seen him for the userTimeInterval amount of seconds.
        // You can simply set the userTimeInterval variable anything you want.
        if(diff > self.userTimeoutInterval) {
            [discardedKeys addObject:key];
        }
    }
    
    // update the list if we removed a user.
    if(discardedKeys.count > 0) {
        [self.usersMap removeObjectsForKeys:discardedKeys];
        [self updateList];
    }
    else {
        // simply update the list, because the order of the users may have changed.
        [self updateList:NO];
    }
}

- (BLEUser *)userWithPeripheralId:(NSString *)peripheralId {
    return [self.usersMap valueForKey:peripheralId];
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSString *service = advertisementData[CBAdvertisementDataLocalNameKey];
    
    if ([service isEqual:self.service]) {
        BLEUser *bleUser = [self userWithPeripheralId:peripheral.identifier.UUIDString];
        if(bleUser == nil) {
            NSLog(@"Adding ble user: %@ %@ at %@", peripheral.name, peripheral.identifier, RSSI);
            bleUser = [[BLEUser alloc] initWithPerpipheral:peripheral];
            bleUser.service = service;
            bleUser.identified = NO;
            bleUser.peripheral.delegate = self;
            
            NSArray *serviceUUIDs = [advertisementData objectForKey:CBAdvertisementDataServiceUUIDsKey];
            if (serviceUUIDs) {
                for (CBUUID* serviceUUID in serviceUUIDs){
                    if([serviceUUID.UUIDString length] >= 36 ){
                        // if we found service uuid then dosen't need to connect
                        bleUser.uuid = serviceUUID.UUIDString;
                        bleUser.identified = YES;
                    }
                }

            }
            
            [self.usersMap setObject:bleUser forKey:bleUser.peripheralId];
        }
        
        if(!bleUser.isIdentified) {
            // nope we could not get the UUID from CBAdvertisementDataLocalNameKey,
            // we have to connect to the peripheral and try to get the characteristic data
            // add we will extract the UUID from characteristics.
                
            if(peripheral.state == CBPeripheralStateDisconnected) {
                [self.centralManager connectPeripheral:peripheral options:nil];
            }
        }
        
        // update the rss and update time
        bleUser.rssi = [RSSI floatValue];
        bleUser.updateTime = [[NSDate date] timeIntervalSince1970];
    }
}

- (void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Peripheral connection failure: %@. (%@)", peripheral, [error localizedDescription]);
}

- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    BLEUser *user = [self userWithPeripheralId:peripheral.identifier.UUIDString];
    NSLog(@"Peripheral Connected: %@", user);
    
    // Search only for services that match our UUID
    // the connection does not guarantee that we will discover the services.
    // if the device is too far away, it may not be possible to discover the service we want.
    [peripheral discoverServices:nil];
}


#pragma mark - CBPeripheralDelegate

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    // loop the services
    // since we are looking forn only one service, services array probably contains only one or zero item
    for (CBService *service in peripheral.services) {
        [peripheral discoverCharacteristics:nil forService:service];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    //BLEUser *user = [self userWithPeripheralId:peripheral.identifier.UUIDString];
    if (!error) {
        // loop through to find our characteristic
        for (CBCharacteristic *characteristic in service.characteristics) {
            if (characteristic.UUID) {
                BLEUser *user = [self userWithPeripheralId:peripheral.identifier.UUIDString];
                NSLog(@"Peripheral Identified: %@", user);
                user.identified = YES;
                user.uuid = characteristic.UUID.UUIDString;

                [self updateList];
                
                // cancel the subscription to our characteristic
                [peripheral setNotifyValue:NO forCharacteristic:characteristic];
                
                // and disconnect from the peripehral
                [self.centralManager cancelPeripheralConnection:peripheral];
            }
        }
    }
    
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{

    NSString *valueStr = [[NSString alloc] initWithData:characteristic.value encoding:NSUTF8StringEncoding];
    NSLog(@"CBCharacteristic updated value: %@", valueStr);
    
    // if the value is not nil, we found our service!
    if(valueStr != nil) {
        BLEUser *user = [self userWithPeripheralId:peripheral.identifier.UUIDString];
        user.service = valueStr;
        user.identified = YES;
        
        [self updateList];
        
        // cancel the subscription to our characteristic
        [peripheral setNotifyValue:NO forCharacteristic:characteristic];
        
        // and disconnect from the peripehral
        [self.centralManager cancelPeripheralConnection:peripheral];
    }
}

- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    NSLog(@"Characteristic Update Notification: %@", error);
}

@end
