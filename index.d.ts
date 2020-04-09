declare module "react-native-discovery" {
  export declare type BLEUser = {
    identified: boolean;
    peripheralId: string;
    proximity: number;
    rssi: number;
    service: string;
    updateTime: string;
    uuid: string;
  };
  export declare type EventType = "bleStateChanged" | "discoveredUsers";
  export declare type BluetoothData = {
    isOn: boolean;
  };
  export declare type DiscoverData = {
    users: BLEUser[];
    usersChanged: boolean;
    uuid: string;
  };
  export declare type Data = BluetoothData | DiscoverData;
  export declare function useEventListener(
    eventType: EventType,
    listener: (data: Data) => void
  ): void;

  export declare interface IDiscoveryModule {
    handleStateChange(state: number): void;
    initialize(uuid: string, service: string): Promise<string>;
    isLocationEnabled(): Promise<boolean>;
    setPaused(paused: boolean): Promise<true | string>;
    setScanForSeconds(scanForSeconds: number): Promise<true | string>;
    setShouldAdvertise(shouldAdvertise: boolean): Promise<true | string>;
    setShouldDiscover(shouldDiscover: boolean): Promise<true | string>;
    setUserTimeoutInterval(userTimeoutInterval: number): Promise<true | string>;
    setWaitForSeconds(waitForSeconds: number): Promise<true | string>;
  }
}
