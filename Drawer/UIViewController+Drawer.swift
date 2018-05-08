//
//  UIViewController+Drawer.swift
//  Drawer
//
//  Created by Paulo Andrade on 07/05/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import UIKit

public extension UIViewController {
    @objc public var drawerViewController: DrawerViewController? {
        return (parent as? DrawerViewController) ?? parent?.drawerViewController
    }
}
