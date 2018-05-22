//
//  DrawerContent.swift
//  Secrets Touch
//
//  Created by Paulo@OC on 11/05/2018.
//  Copyright © 2018 Outer Corner. All rights reserved.
//

import Foundation

@objc public protocol DrawerContentProvider {
    
    @objc optional func anchorsForDrawer(_ drawerViewController: DrawerViewController, consideringSafeAreaInsets: UIEdgeInsets) -> [CGFloat]
    @objc optional func updateDrawer(_ drawerViewController: DrawerViewController, for size: CGSize)
    @objc optional func clippingPathForDrawer(_ drawerViewController: DrawerViewController, in rect: CGRect) -> UIBezierPath
    
    @objc optional func drawerDidBeginDragging(_ drawerViewController: DrawerViewController)
    @objc optional func drawerDidEndDragging(_ drawerViewController: DrawerViewController, at anchor: CGFloat)
    @objc optional func drawerDidEndDragging(_ drawerViewController: DrawerViewController, willAnimateTo anchor: CGFloat)
    @objc optional func drawerDidEndAnimating(_ drawerViewController: DrawerViewController)
}
