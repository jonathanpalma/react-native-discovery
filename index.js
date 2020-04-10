import { useEffect, useState } from "react";
import { NativeModules, DeviceEventEmitter } from "react-native";

export type BLEUser = {
  identified: boolean,
  peripheralId: string,
  proximity: number,
  rssi: number,
  service: string,
  updateTime: string,
  uuid: string,
};
export type EventType = "bleStateChanged" | "discoveredUsers";
export type BluetoothData = {
  isOn: boolean,
};
export type DiscoverData = {
  users: BLEUser[],
  usersChanged: boolean,
  uuid: string,
};
export type Data = BluetoothData | DiscoverData;

export function useEventListener(
  eventType: EventType,
  listener: (data: Data) => void
) {
  useEffect(() => {
    DeviceEventEmitter.addListener(eventType, listener);
    return () => {
      DeviceEventEmitter.removeListener(eventType, listener);
    };
  });
}

export interface IDiscoveryModule {
  handleStateChange(state: number): void;
  initialize(uuid: string, service: string): Promise<string>;
  isBluetoothEnabled(): Promise<boolean>;
  isLocationEnabled(): Promise<boolean>;
  setBluetoothOn(): Promise<boolean>;
  setBluetoothOff(): Promise<boolean>;
  setPaused(paused: boolean): Promise<true | string>;
  setScanForSeconds(scanForSeconds: number): Promise<true | string>;
  setShouldAdvertise(shouldAdvertise: boolean): Promise<true | string>;
  setShouldDiscover(shouldDiscover: boolean): Promise<true | string>;
  setUserTimeoutInterval(userTimeoutInterval: number): Promise<true | string>;
  setWaitForSeconds(waitForSeconds: number): Promise<true | string>;
  useEventListener(eventType: EventType, listener: (data: Data) => void): void;
}

const Discovery: IDiscoveryModule = NativeModules.RNDiscovery;
export default Discovery;
