## 7.0.3+edge.1 (vendored in openstrap edge)
* edge patch: getConnectedPeripheral drops an entry whose CBPeripheral.state is not connected.
  A restored "connected" peripheral could outlive its link (no didDisconnectPeripheral when
  another central of the app owned and dropped it), leaving connect() a no-op until a BT toggle.

## 4.0.1
* fix unrecognized selector sent to instance (regression from 4.0.0)

## 4.0.0
* Use bytes instead of hex for platform communication (#1130)

## 3.0.0
* Update platform interface version to 3.0.0

## 2.0.1
* Add log color

## 2.0.0
* Combine the packages previously published as flutter_blue_plus_ios and flutter_blue_plus_macos
* Add support for Swift Package Manager
* Replace void return types with bool return types
