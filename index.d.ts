declare module "react-native-discovery" {
  export type BLEUser = {
    identified: boolean;
    peripheralId: string;
    proximity: number;
    rssi: number;
    service: string;
    updateTime: string;
    uuid: string;
  };
  export type EventType = "bleStateChanged" | "discoveredUsers";
  export type BluetoothData = {
    isOn: boolean;
  };
  export type DiscoverData = {
    users: BLEUser[];
    usersChanged: boolean;
    uuid: string;
  };
  export type EventListener = ((data: BluetoothData) => void) | ((data: DiscoverData) => void);
  export function useEventListener(
    eventType: EventType,
    listener: EventListener
  ): void;

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
  }

  const Discovery: IDiscoveryModule;
  export default Discovery;
}
