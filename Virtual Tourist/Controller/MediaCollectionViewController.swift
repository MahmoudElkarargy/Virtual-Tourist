//
//  MediaCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Mahmoud Elkarargy on 5/5/20.
//  Copyright © 2020 Mahmoud Elkarargy. All rights reserved.
//

import UIKit
import CoreData

class MediaCollectionViewController: UIViewController {

    //MARK: Outlets and variables.
    @IBOutlet weak var okayButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flow: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    var response: ImagesSearchResponse?
    var dataController: DataController = DataController.shared
    // The pin whose notes are being displayed
    var selectedPin: Pin!
    var fetchedResultsController:NSFetchedResultsController<Image>!
    var numberOfPages: Int = 1
    var numberOfImagesToBeLoaded: Int = 0
    var deletePerformed: Bool = false
    //MARK: Override functions.
    override func viewDidLoad() {
        super.viewDidLoad()
        if (response?.photos!.pages)! > 1{
            newCollectionButton.isEnabled = true
        } else{ newCollectionButton.isEnabled = false }
        collectionView.delegate = self
        collectionView.dataSource = self
        setFlowLayout()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        setupFetchedResultsController()
        loadImages()
        // Make sure collection data is reloaded appropriately
        self.collectionView.reloadData()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        fetchedResultsController = nil
    }
    
    //MARK: Init funcs
    //fetch data from storge
    func setupFetchedResultsController() {
        //Fetch data from the store.
        let fetchRequest: NSFetchRequest<Image> = Image.fetchRequest()
        //Getting images of right pin
        let predicate = NSPredicate(format: "pin == %@", selectedPin)
        fetchRequest.predicate = predicate
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
    //load images and save them in the storage.
    func loadImages(){
        guard (fetchedResultsController.fetchedObjects?.count != 0) else{
            //check if the total number of images > 18(const. number of pics in the single collection)
            if let numbers = Int((response?.photos!.total)!){
                //if this location contains photos?
                if numbers != 0{
                    print(numbers)
                    if numbers > 18{
                        numberOfImagesToBeLoaded = 18
                    }
                    else { numberOfImagesToBeLoaded = numbers }
                    //loop for the number of images in this location.
                    for img in 0...numberOfImagesToBeLoaded-1{
                        //Create and save the Image object!
                        let image = Image(context: dataController.viewContext)
                        //Assign the placeHolder image untill loading is complete.
                        image.photo = UIImage(named: "placeholderImage")!.pngData()
                        image.creationDate = Date()
                        image.pin = selectedPin
                        try? dataController.viewContext.save()
                        collectionView.reloadData()
                        FlickrClient.loadImage(photoData: (response?.photos?.photo[img])!, image: image , completionHandler: handleFlickerLoadResponse)
                    }
                }
                else{print("WARNING! No images here!")
                    self.dismiss(animated: true, completion: nil)
                }
            }
            return
        }
        //If already there is saved image. So, view them only!
    }
    
    //MARK: IBActions functions.
    @IBAction func okayButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    @IBAction func newCollectionButtonPressed(_ sender: Any) {
        deletePerformed = true
        //Delete all excisting imgs, to free space.
        let numbers = fetchedResultsController.sections![0].numberOfObjects
        for img in 0...numbers-1{
            let photo = fetchedResultsController.object(at: [0,img])
            dataController.viewContext.delete(photo)
        }
        //save changes
        try? dataController.viewContext.save()
        
        self.numberOfPages = numberOfPages + 1
        //check is there more pages? to be loaded next time?
        //increment the number of pages by one to avoid deleting imgs if there's no more pages.
        if numberOfPages+1 > (response?.photos!.pages)!{
            newCollectionButton.isEnabled = false
        }
        else {
                deletePerformed = false
                FlickrClient.getPhotosSearchResult(lat: selectedPin.latitude, lon: selectedPin.longitude, page: numberOfPages, completionHandler: handleFlickerImagesSearchResponse)
        }
    }
    
    //MARK: handling functions.
    func handleFlickerLoadResponse(image:Image, imgdata: Data?, error: Error?){
        guard error == nil , imgdata != nil else {
            print("Error")
            return
        }
        //Update the image after loading it.
        image.creationDate = Date()
        image.photo = imgdata
        image.pin = selectedPin
        //saving data
        try? dataController.viewContext.save()
        collectionView.reloadData()
    }
    func handleFlickerImagesSearchResponse(response: ImagesSearchResponse?, error: Error?){
        guard error == nil , response != nil else {
            print("Error")
            return
        }
        //Save the response to move it to the media view.
        self.response = response!
        loadImages()
    }
}

extension MediaCollectionViewController: NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource{
    //MARK: CollectionView funcs.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections![section].numberOfObjects
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! MediaCollectionViewCell
        let aImage = fetchedResultsController.object(at: indexPath)
        // add the image to the cell.
        if let data = aImage.photo{
            cell.imageView?.image = UIImage(data: data)
        }
        return cell
    }
    // Delete Image on tap
         func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
           //delete photo from memory
            
    //        print("moshkla 3ndk?")
    //        print(indexPath)
    //        print("Index kda: \(indexPath.row)")
    //        let photo = fetchedResultsController.object(at: indexPath)
    //        print("ha")
    //        dataController.viewContext.delete(photo)
    //        print("deleting")
    ////        try? dataController.viewContext.save()
    //        print("mt3'ertsh? \(fetchedResultsController.sections![0].numberOfObjects)")
    ////        collectionView.deleteItems(at: [indexPath])
    //        print("bdan dh")
    //        do{
    //            try dataController.viewContext.save()
    //        }catch{
    //            fatalError(error.localizedDescription)
    //        }
    //        print("hina")
    //        setupFetchedResultsController()
    //        DispatchQueue.main.async {
    //            collectionView.reloadData()
    //        }
    }
    func setFlowLayout() {
        let space: CGFloat = 2.0
        let dimensionW = (view.frame.size.width - (2 * space)) / 3.0
        let dimensionH = (view.frame.size.height - (2 * space)) / 6.0
        
        flow.minimumInteritemSpacing = space
        flow.minimumLineSpacing = space
        flow.itemSize = CGSize(width: dimensionW, height: dimensionH)
    }
    
    //update the data.
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        if !deletePerformed{
            try? fetchedResultsController.performFetch()
        }
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
         if !deletePerformed{
            try? fetchedResultsController.performFetch()
        }
    }
}
