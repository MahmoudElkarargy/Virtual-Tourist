//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Mahmoud Elkarargy on 5/4/20.
//  Copyright © 2020 Mahmoud Elkarargy. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class MapViewController: UIViewController {
    //MARK: Outlets and variables.
    @IBOutlet weak var mapView: MKMapView!
    var dataController: DataController = DataController.shared
    var fetchedResultsController:NSFetchedResultsController<Pin>!
    var searchResponse: ImagesSearchResponse?
    var currentPin: MKAnnotation?
    override func viewDidLoad() {
        super.viewDidLoad()
        //Setting delegets
        mapView.delegate = self
        restoreTheCenterOfTheMap()
        setupGestureRecognition()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setupFetchedResultsController()
        viewPinsOnMap()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    //MARK: Init funcs
    //fetch data from storge
    private func setupFetchedResultsController() {
        //Fetch data from the store.
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        //Adding sort rule.
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        //Init the fetch result controller
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        //Check if fetch data is success.
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    //function to get the center of the map for the last time user left it.
    fileprivate func restoreTheCenterOfTheMap() {
        //If it's the user first time to launch, show a welcome msg!
        if !UserDefaults.standard.bool(forKey: "HasLaunchedBefore"){
            showError(title: "Welcome!", message: "Start by holding the map to drop pins and explore photos.")
            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }
        
        let latitudeSaved = UserDefaults.standard.double(forKey: "latitude")
        let longitudeSaved = UserDefaults.standard.double(forKey: "longitude")
        let centerMapCoordinate = CLLocationCoordinate2D(latitude: latitudeSaved, longitude: longitudeSaved)
        let region = MKCoordinateRegion(center: centerMapCoordinate, latitudinalMeters: 10000000, longitudinalMeters: 10000000)
        mapView.setRegion(region, animated: true)
        
    }
    //Func to listen to long press on the map
    func setupGestureRecognition(){
        let uilgr = UILongPressGestureRecognizer(target: self, action: #selector(self.handleLongPress(_:)))
        uilgr.minimumPressDuration = 2.0
        mapView.addGestureRecognizer(uilgr)
    }
    
    //MARK: Handling functions
    func handleFlickerImagesSearchResponse(response: ImagesSearchResponse?, error: Error?){
        guard error == nil , response != nil else {
            showError(title: "Error!", message: "Can't load data")
            return
        }
        //Save the response to move it to the media view.
        searchResponse = response!
        //Navigate to the Media view.
        performSegue(withIdentifier: "openMediaSegue", sender: nil)
    }
    //Handling map press and add the pin next.
    @objc func handleLongPress(_ gestureRecognizer : UIGestureRecognizer){
        if gestureRecognizer.state != .began { return }
        let touchPoint = gestureRecognizer.location(in: mapView)
        let touchMapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        //Save the pin in the coreData
        let newPin = Pin(context: dataController.viewContext)
        newPin.latitude = touchMapCoordinate.latitude
        newPin.longitude =  touchMapCoordinate.longitude
        newPin.creationDate = Date()
        //saving data
        try? dataController.viewContext.save()
        
        //Add the new Pin in the map.
        let newAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = CLLocationCoordinate2D(latitude: touchMapCoordinate.latitude, longitude: touchMapCoordinate.longitude)
        mapView.addAnnotation(newAnnotation)
    }
    
    //MARK: View functions:
    func viewPinsOnMap(){
        var annotations = [MKPointAnnotation]()
        //fetch data of pins from the storge and loop over them.
        for pin in fetchedResultsController!.fetchedObjects! {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
            annotations.append(annotation)
        }
        // add the annotations to the map
        self.mapView.addAnnotations(annotations)
        self.mapView.reloadInputViews()
    }
}

extension MapViewController: MKMapViewDelegate, NSFetchedResultsControllerDelegate{
    //Update and save the center of the map, when user travel locations around the world
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let center = mapView.centerCoordinate
        UserDefaults.standard.set(Double(center.latitude), forKey: "latitude")
        UserDefaults.standard.set(Double(center.longitude), forKey: "longitude")
    }
    
    //customize pins
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
       let reuseId = "pin"
       var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
       if pinView == nil {
            //Styling of pins
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.isEnabled = true
            pinView!.pinTintColor = .black
            pinView?.animatesDrop = true
       }
       else {
           pinView!.annotation = annotation
       }
       return pinView
    }
    // This delegate method is implemented to respond to taps. as to direct to media type
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let longitude = (view.annotation?.coordinate.longitude)!
        let latitude = (view.annotation?.coordinate.latitude)!
        currentPin = view.annotation!
        //Get the images ready.
        FlickrClient.getPhotosSearchResult(lat: latitude, lon: longitude, page: 1, completionHandler: handleFlickerImagesSearchResponse)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openMediaSegue"{
            let mediaCollectionView = segue.destination as! MediaCollectionViewController
            if let pins = fetchedResultsController.fetchedObjects {
            // there will be only one selected annotation at a time
            let annotation = mapView.selectedAnnotations[0]
            // getting the index of the selected annotation to set pin value in destination VC
            guard let indexPath = pins.firstIndex(where: {
                (pin) -> Bool in
                pin.latitude == annotation.coordinate.latitude && pin.longitude == annotation.coordinate.longitude
            })else{return}
            mediaCollectionView.selectedPin = pins[indexPath]
            mediaCollectionView.response = searchResponse
            }
        }
        //deselect the tapped pin here so that the next time the can select it.
        mapView.deselectAnnotation(currentPin , animated: true)
    }    
    //update the data.
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        try? fetchedResultsController.performFetch()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        try? fetchedResultsController.performFetch()
    }
}

