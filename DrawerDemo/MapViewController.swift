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
    

    
}
