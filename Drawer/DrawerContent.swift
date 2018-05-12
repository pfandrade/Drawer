//
//  DrawerContent.swift
//  Secrets Touch
//
//  Created by Paulo@OC on 11/05/2018.
//  Copyright © 2018 Outer Corner. All rights reserved.
//

import Foundation

@objc public protocol DrawerContentProvider {
    func drawerAnchorsConsidering(safeAreaInsets: UIEdgeInsets) -> [CGFloat]
}
