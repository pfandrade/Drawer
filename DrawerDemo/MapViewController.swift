//
//  MapViewController.swift
//  DrawerDemo
//
//  Created by Paulo Andrade on 05/05/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import UIKit
import MapKit
import Drawer

class MapViewController: UIViewController, PlacesViewControllerDelegate {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateDrawer(for: self.view.frame.size)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        drawerViewController?.moveDrawerToLowestAnchor(animated: true)
        
    }
    
    @IBOutlet weak var mapView: MKMapView!
    
    func placesViewController(_ placesViewController: PlacesViewController, didSelectPlace place: PlacesViewController.Place) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegionMake(place.location, span)
        
        mapView.setRegion(region, animated: true)
    }
    

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateDrawer(for: size)
    }
    
    func updateDrawer(for size: CGSize) {
        if size.width < 500 {
            drawerViewController?.maxDrawerWidth = CGFloat.greatestFiniteMagnitude
            drawerViewController?.dimBackgroundStartingAtOffset = 250
        } else {
            drawerViewController?.maxDrawerWidth = 270
            drawerViewController?.dimBackgroundStartingAtOffset = CGFloat.greatestFiniteMagnitude
        }
    }
}
