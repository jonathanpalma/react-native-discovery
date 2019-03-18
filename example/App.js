/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 *
 * @format
 * @flow
 * @lint-ignore-every XPLATJSCOPYRIGHT1
 */

import React, { Component } from "react";
import {
  Platform,
  StyleSheet,
  Text,
  View,
  FlatList,
  DeviceEventEmitter,
  PermissionsAndroid,
  AppState
} from "react-native";

import Discovery from "react-native-discovery";

function uuidv4() {
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
    var r = (Math.random() * 16) | 0,
      v = c == "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

const MY_UUID = uuidv4();
const SERVICE_NAME = "XRPL";

type Props = {};
export default class App extends Component<Props> {
  constructor() {
    super();

    this.state = {
      discovered: [],
      bluetoothStatus: "false",
      paused: false,
      appState: ''
    };
  }

  componentDidMount() {
    this.checkPermission();
    this.checkBluetooth();

    AppState.addEventListener('change', this.handleAppStateChange);

    Discovery.initialize(MY_UUID, SERVICE_NAME).then(uuid => {
      Discovery.setShouldAdvertise(true);
      Discovery.setShouldDiscover(true);
    });

    // Listen for discovery changes
    Discovery.on("discoveredUsers", this.handleDiscover);
    // Listen for bluetooth state changes
    Discovery.on("bleStateChanged", this.handleBluethootState);
  }

  handleBluethootState = event => {
    const { paused } = this.state;
    this.setState({
      bluetoothStatus: event.isOn ? "true" : "false"
    });
    if (!event.isOn) {
      this.pause(true)
    }

    if (event.isOn) {
      this.pause(false)
    }
  };

  handleDiscover = data => {
    const { discovered } = this.state;
    console.log(data);
    if (discovered !== data.users) {
      this.setState({
        discovered: data.users
      });
    }
    //slight callback discrepancy between the iOS and Android libraries
  };



  pause = (value) => {
    const { paused } = this.state ;
    if(value){
      if (!paused) {
        console.log("Set paused the discovery to On")
        Discovery.setPaused(true);
        this.setState({
          paused: true
        });
      }
    }else{
      if (paused) {
        console.log("Set paused the discovery to Off")
        Discovery.setPaused(false);
        this.setState({
          paused: false
        });
      }
    }

  }

  handleAppStateChange = (nextAppState) => {
    const { appState, paused } = this.state ;
    if (appState.match(/inactive|background/) && nextAppState === 'active') {
      this.pause(false)
    }else{
      this.pause(true)
    }
    this.setState({appState: nextAppState});
  }

  checkBluetooth = () => {
    if (Platform.OS === "android") {
      Discovery.getBluetoothState((status) => {
          console.log(status)
          if(status !== true){
            Discovery.setBluetoothOn(() => {});
          }
      })
    }
  };

  checkPermission = () => {
    if (Platform.OS === "android" && Platform.Version >= 23) {
      PermissionsAndroid.check(
        PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION
      ).then(result => {
        if (result) {
          console.log("Permission is OK: true");
          return true;
        } else {
          PermissionsAndroid.requestPermission(
            PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION
          ).then(result => {
            if (result) {
              console.log("User accept permission!");
              return true;
            } else {
              console.log("User refuse permission!");
              return false;
            }
          });
        }
      });
    }
  };

  render() {
    const { discovered, bluetoothStatus } = this.state;

    return (
      <View style={styles.container}>
        <View style={{ flex: 1, backgroundColor: "#c2c3c4", ...styles.center }}>
          <Text style={{ textAlign: "center", fontSize: 18 }}>
            React Native Discovery
          </Text>
        </View>
        <View style={{ flex: 1, backgroundColor: "#E9EBEE", ...styles.center }}>
          <Text style={{ textAlign: "center" }}>
            Bluetooth is On: {bluetoothStatus}
          </Text>
          <Text style={{ textAlign: "center" }}>My UUID : {MY_UUID}</Text>
        </View>
        <View style={{ flex: 6 }}>
          <FlatList
            data={discovered}
            renderItem={({ item }) => (
              <Text style={{ color: "green", ...styles.item }}>
                {item.uuid}
              </Text>
            )}
            keyExtractor={(item, index) => item.uuid}
            ListEmptyComponent={
              <Text style={{ color: "red", ...styles.item }}>
                No user discovered!
              </Text>
            }
          />
        </View>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    flexDirection: "column",
    backgroundColor: "#F5FCFF"
  },
  center: {
    justifyContent: "center",
    alignItems: "center"
  },
  item: {
    marginTop: 20,
    textAlign: "center",
    fontSize: 15,
    fontWeight: "900"
  }
});
