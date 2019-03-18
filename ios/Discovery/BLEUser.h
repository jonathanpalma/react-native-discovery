//
//  BLEUser.h
//  Discover
//
//  Created by Ömer Faruk Gül on 1/23/14.
//  Copyright (c) 2014 Louvre Digital. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <CoreLocation/CoreLocation.h>
#import "EasedValue.h"

@interface BLEUser : NSObject

- (id)initWithPerpipheral:(CBPeripheral *)peripheral;

@property (strong, nonatomic, readonly) CBPeripheral *peripheral;
@property (strong, nonatomic, readonly) NSString *peripheralId;

// the service user belong to.
@property (strong, nonatomic) NSString *service;
// the uuid for the user
@property (strong, nonatomic) NSString *uuid;
// indicates wheather the user's UUID is extracted from the peer device.
@property (nonatomic, getter=isIdentified) BOOL identified;

// rssi
@property (nonatomic) float rssi;
// proximity calculated by EasedValue class.
@property (nonatomic, readonly) NSInteger proximity;

// the last seen time of the user
@property (nonatomic) double updateTime;
@end
