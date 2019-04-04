#if __has_include(<React/RCTBridgeModule.h>)
#import <React/RCTBridgeModule.h>
#else
#import "RCTBridgeModule.h"
#endif

#import <CoreBluetooth/CoreBluetooth.h>


@interface RNDiscovery : NSObject <RCTBridgeModule>{
    CBCentralManager *_bluetoothManager;
}
@end
