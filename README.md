# React Native Discovery
Discover nearby devices using BLE [Bluetooth Low Energy](https://en.wikipedia.org/wiki/Bluetooth_Low_Energy).

This is a porting of https://github.com/yonahforst/react-native-discovery project with alot of changes and bug fixes.

![IMG_1547](https://user-images.githubusercontent.com/6250203/54543335-c7113e80-499d-11e9-9a21-6d6f49ae58c0.jpg)


## What
RNDiscovery is a useful library for discovering nearby devices with BLE(Bluetooth Low Energy) and for exchanging a value (UUID) that can be an unique ID for device or user.

## Supported Platforms
- iOS 8+
- Android (API 19+)

## Getting started

````
npm install --save https://github.com/N3TC4T/react-native-discovery	
````

#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-discovery` and add `ReactNativeDiscovery.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libReactNativeDiscovery.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

### Android
##### Step 1 - Update Gradle Settings

```
// file: android/settings.gradle
...

include ':react-native-discovery'
project(':react-native-discovery').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-discovery/android')
```
##### Step 2 - Update Gradle Build

```
// file: android/app/build.gradle
...

dependencies {
    ...
    compile project(':react-native-discovery')
}
```

##### Step 3 - Update Android Manifest

```xml
// file: android/app/src/main/AndroidManifest.xml
...
    <uses-permission android:name="android.permission.BLUETOOTH"/>
    <uses-permission android:name="android.permission.BLUETOOTH_ADMIN"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
...
```

##### Step 4 - Register React Package
```
...
import com.joshblour.RNDiscovery.RNDiscoveryPackage; // <--- import

public class MainActivity extends ReactActivity {

    ...

    @Override
    protected List<ReactPackage> getPackages() {
        return Arrays.<ReactPackage>asList(
            new MainReactPackage(),
            new RNDiscoveryPackage() // <------ add the package
        );
    }

    ...
}
```



#### Example
```js
import Discovery from "react-native-discovery";

const myUUID = "3E1180E5-222E-43E9-98B4-E6C0DD18E728";
const myService = "MYAPP"

Discovery.initialize(myUUID, myService).then(uuid => {
  Discovery.setShouldAdvertise(true);
  Discovery.setShouldDiscover(true);
});

// Listen for discovery changes
Discovery.on("discoveredUsers", (data) => { console.log(data.users) } );

// Listen for bluetooth state changes
Discovery.on('bleStateChanged', (event) => { console.log('BLE is On: ' + event.isOn) } );


```

Or, you can still look into the whole [example](https://github.com/N3TC4T/react-native-discovery/tree/master/example) folder for a standalone project.



#### API

Method | Params | Info
------ | ------- | ----
initialize(uuid, service) | string, string | Initialize the Discovery object with a UUID specific to your device, and a service specific to your app. Returns a promise which resolves to the specified UUID
setPaused(isPaused) | bool | pauses advertising and detection
setShouldDiscover(shouldDiscover) | bool | starts and stops discovery
setShouldAdvertise(shouldAdvertise) | bool | starts and stops advertising
setUserTimeoutInterval(userTimeoutInterval) | integer in seconds | After not seeing a user for x seconds, we remove him from the users list in our callback (for the specified uuid)
isBluetoothEnabled() | null | Returns a promise, which will return a boolean value, true if bluetooth is enabled, false if disabled.

  
*The following methods are specific to the Android version.*

Method | Params | Info
------ | ------- | ----
setScanForSeconds(scanForSeconds) | integer in seconds | This parameter specifies the duration of the ON part of the scan cycle for the specified uuid. Returns a promise which resolves to true.
setWaitForSeconds(waitForSeconds) |  integer in seconds | This parameter specifies the duration of the OFF part of the scan cycle for the specified uuid. Returns a promise which resolves to true.
setBluetoothOn() | null | Changes bluetooth state to On, Returns a promise, which returns whether the change was successful or not.
setBluetoothOff() | null | Changes bluetooth state to Off, Returns a promise, which returns whether the change was successful or not.
isLocationEnabled() | null | Returns a promise, which will return a boolean value, true if location is enabled, false if disabled.