//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Mahmoud Elkarargy on 5/4/20.
//  Copyright © 2020 Mahmoud Elkarargy. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    //MARK: Outlets and variables.
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setting delegets
        mapView.delegate = self
        restoreTheCenterOfTheMap()
        FlickrClient.getPhotosSearchResult(lat: 26.8206, lon: 30.8025, page: 1, completionHandler: handleFlickerImagesSearchResponse)
    }
    
    //MARK: Init funcs
    //function to get the center of the map for the last time user left it.
    fileprivate func restoreTheCenterOfTheMap() {
        let latitudeSaved = UserDefaults.standard.double(forKey: "latitude")
        let longitudeSaved = UserDefaults.standard.double(forKey: "longitude")
        let centerMapCoordinate = CLLocationCoordinate2D(latitude: latitudeSaved, longitude: longitudeSaved)
        let region = MKCoordinateRegion(center: centerMapCoordinate, latitudinalMeters: 10000000, longitudinalMeters: 10000000)
        mapView.setRegion(region, animated: true)
    }
    
    //MARK: Handling functions
    func handleFlickerImagesSearchResponse(response: ImagesSearchResponse?, error: Error?){
        guard error == nil , response != nil else {
            print("Error")
            return
        }
    }
    
}

extension MapViewController: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        //Update and save the center of the map, when user travel locations around the world
        let center = mapView.centerCoordinate
        UserDefaults.standard.set(Double(center.latitude), forKey: "latitude")
        UserDefaults.standard.set(Double(center.longitude), forKey: "longitude")
    }
    
}

