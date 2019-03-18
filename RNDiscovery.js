const ReactNative = require('react-native')
const { NativeModules, DeviceEventEmitter } = ReactNative
const RNDiscovery = NativeModules.RNDiscovery

/**
 * Listen for available events
 * @param  {String} eventName Name of event one of discoveredUsers, bleStateChanged
 * @param  {Function} handler Event handler
 */
RNDiscovery.on = (eventName, handler) => {
  DeviceEventEmitter.addListener(eventName, handler)
}

/**
 * Stop listening for event
 * @param  {String} eventName Name of event one of discoveredUsers, bleStateChanged
 * @param  {Function} handler Event handler
 */
RNDiscovery.removeListener = (eventName, handler) => {
  DeviceEventEmitter.removeListener(eventName, handler)
}

module.exports = RNDiscovery