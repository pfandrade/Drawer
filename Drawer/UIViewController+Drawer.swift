//
//  UIViewController+Drawer.swift
//  Drawer
//
//  Created by Paulo@OC on 07/05/2018.
//  Copyright © 2018 Paulo@OC. All rights reserved.
//

import UIKit

public extension UIViewController {
    public var drawerViewController: DrawerViewController? {
        return (parent as? DrawerViewController) ?? parent?.drawerViewController
    }
}
