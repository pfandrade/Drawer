# Drawer

An iOS Maps like drawer view controller implementation. 

Features:

* Simple API. Just initialize ```DrawerViewController``` like so:
```swift
DrawerViewController(mainViewController: mapViewController, drawerContentViewController: drawerContentController)
```
* Support for multiple anchor positions;
* Flicking speed is taken into account for a natural behavior. You can flick the drawer to the top or bottom, skipping any intermediate anchor positions;
* Objective-C and iOS 9+ compatible;
