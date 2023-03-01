//
//  DrawerContent.swift
//  Drawer
//
//  Created by Paulo Andrade on 11/05/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import UIKit
import QuartzCore

@objc public protocol DrawerChildViewController {
    @objc optional func drawerShouldBeginDragging(_ drawerViewController: DrawerViewController) -> Bool
    @objc optional func drawerDidBeginDragging(_ drawerViewController: DrawerViewController)
    @objc optional func drawerDidEndDragging(_ drawerViewController: DrawerViewController, at anchor: CGFloat)
    @objc optional func drawerDidEndDragging(_ drawerViewController: DrawerViewController, willAnimateTo anchor: CGFloat)
    @objc optional func drawerDidEndAnimating(_ drawerViewController: DrawerViewController)
    
    @objc optional func drawer(_ drawerViewController: DrawerViewController, didMoveTo offset: CGFloat)
}

@objc public protocol DrawerMainChildViewController: DrawerChildViewController {
    
    @objc optional func initialAccessibilityElementForDrawer(_ drawerViewController: DrawerViewController) -> Any?

}

@objc public protocol DrawerContentChildViewController: DrawerChildViewController {
    
    @objc optional func anchorsForDrawer(_ drawerViewController: DrawerViewController, consideringSafeAreaInsets: UIEdgeInsets) -> [CGFloat]
    @objc optional func updateDrawer(_ drawerViewController: DrawerViewController, for size: CGSize)
    @objc optional func clippingPathForDrawer(_ drawerViewController: DrawerViewController, in rect: CGRect) -> UIBezierPath
    

}

