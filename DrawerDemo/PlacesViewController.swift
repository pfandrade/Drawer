//
//  PlacesViewController.swift
//  DrawerDemo
//
//  Created by Paulo Andrade on 05/05/2018.
//  Copyright © 2018 Paulo Andrade. All rights reserved.
//

import UIKit
import MapKit

class PlacesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    weak var delegate: PlacesViewControllerDelegate?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var handleView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        handleView.layer.cornerRadius = 4.0
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 20, 0)
    }

    
    // MARK:- TableView
    typealias Place = (title: String, location: CLLocationCoordinate2D)
    private var places: [Place] = [
        ("Rome", CLLocationCoordinate2D(latitude: 41.9004041, longitude: 12.4432921)),
        ("Milan", CLLocationCoordinate2D(latitude: 45.4625319, longitude: 9.1574741)),
        ("Turin", CLLocationCoordinate2D(latitude: 45.0705805, longitude: 7.6593106)),
        ("London", CLLocationCoordinate2D(latitude: 51.5287718, longitude: -0.2416817)),
        ("Paris", CLLocationCoordinate2D(latitude: 48.8589507, longitude: 2.2770201)),
        ("Amsterdam", CLLocationCoordinate2D(latitude: 52.354775, longitude: 4.7585401)),
        ("Dublin", CLLocationCoordinate2D(latitude: 53.3244431, longitude: -6.3857869)),
        ("Reykjavik", CLLocationCoordinate2D(latitude: 64.1335484, longitude: -21.9224815)),
        ("Rome", CLLocationCoordinate2D(latitude: 41.9004041, longitude: 12.4432921)),
        ("Milan", CLLocationCoordinate2D(latitude: 45.4625319, longitude: 9.1574741)),
        ("Turin", CLLocationCoordinate2D(latitude: 45.0705805, longitude: 7.6593106)),
        ("London", CLLocationCoordinate2D(latitude: 51.5287718, longitude: -0.2416817)),
        ("Paris", CLLocationCoordinate2D(latitude: 48.8589507, longitude: 2.2770201)),
        ("Amsterdam", CLLocationCoordinate2D(latitude: 52.354775, longitude: 4.7585401)),
        ("Dublin", CLLocationCoordinate2D(latitude: 53.3244431, longitude: -6.3857869)),
        ("Reykjavik", CLLocationCoordinate2D(latitude: 64.1335484, longitude: -21.9224815)),
        ("Rome", CLLocationCoordinate2D(latitude: 41.9004041, longitude: 12.4432921)),
        ("Milan", CLLocationCoordinate2D(latitude: 45.4625319, longitude: 9.1574741)),
        ("Turin", CLLocationCoordinate2D(latitude: 45.0705805, longitude: 7.6593106)),
        ("London", CLLocationCoordinate2D(latitude: 51.5287718, longitude: -0.2416817)),
        ("Paris", CLLocationCoordinate2D(latitude: 48.8589507, longitude: 2.2770201)),
        ("Amsterdam", CLLocationCoordinate2D(latitude: 52.354775, longitude: 4.7585401)),
        ("Dublin", CLLocationCoordinate2D(latitude: 53.3244431, longitude: -6.3857869)),
        ("Reykjavik", CLLocationCoordinate2D(latitude: 64.1335484, longitude: -21.9224815)),
        ("Rome", CLLocationCoordinate2D(latitude: 41.9004041, longitude: 12.4432921)),
        ("Milan", CLLocationCoordinate2D(latitude: 45.4625319, longitude: 9.1574741)),
        ("Turin", CLLocationCoordinate2D(latitude: 45.0705805, longitude: 7.6593106)),
        ("London", CLLocationCoordinate2D(latitude: 51.5287718, longitude: -0.2416817)),
        ("Paris", CLLocationCoordinate2D(latitude: 48.8589507, longitude: 2.2770201)),
        ("Amsterdam", CLLocationCoordinate2D(latitude: 52.354775, longitude: 4.7585401)),
        ("Dublin", CLLocationCoordinate2D(latitude: 53.3244431, longitude: -6.3857869)),
        ("Reykjavik", CLLocationCoordinate2D(latitude: 64.1335484, longitude: -21.9224815)),
        ("Rome", CLLocationCoordinate2D(latitude: 41.9004041, longitude: 12.4432921)),
        ("Milan", CLLocationCoordinate2D(latitude: 45.4625319, longitude: 9.1574741)),
        ("Turin", CLLocationCoordinate2D(latitude: 45.0705805, longitude: 7.6593106)),
        ("London", CLLocationCoordinate2D(latitude: 51.5287718, longitude: -0.2416817)),
        ("Paris", CLLocationCoordinate2D(latitude: 48.8589507, longitude: 2.2770201)),
        ("Amsterdam", CLLocationCoordinate2D(latitude: 52.354775, longitude: 4.7585401)),
        ("Dublin", CLLocationCoordinate2D(latitude: 53.3244431, longitude: -6.3857869)),
        ("Reykjavik", CLLocationCoordinate2D(latitude: 64.1335484, longitude: -21.9224815)),        
    ]
    
    // MARK: delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.placesViewController(self, didSelectPlace: places[indexPath.row])
        self.drawerViewController?.moveDrawerToLowestAnchor(animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: datasource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return places.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell! = tableView.dequeueReusableCell(withIdentifier: "Basic")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "Basic")
            cell.backgroundColor = UIColor.clear
        }
        
        let place = places[indexPath.row]
        cell.textLabel?.text = place.title
        return cell
    }

}

protocol PlacesViewControllerDelegate: class {
    func placesViewController(_ placesViewController: PlacesViewController, didSelectPlace place: PlacesViewController.Place)
}
