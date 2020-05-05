//
//  MediaCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Mahmoud Elkarargy on 5/5/20.
//  Copyright © 2020 Mahmoud Elkarargy. All rights reserved.
//

//Things to do:
//  2. Add Animation controller dh
//  3. remove image.
//  4.Errors.
//  5. nfs tap mrten.
import UIKit
import CoreData

class MediaCollectionViewController: UIViewController {

    //MARK: Outlets and variables.
    @IBOutlet weak var okayButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flow: UICollectionViewFlowLayout!
    var response: ImagesSearchResponse?
    var dataController: DataController = DataController.shared
    /// The pin whose notes are being displayed
    var selectedPin: Pin!
    var fetchedResultsController:NSFetchedResultsController<Image>!
    var numberOfPages: Int = 1
    var numberOfImagesToBeLoaded: Int = 0
    //MARK: Override functions.
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    //MARK: IBActions functions.
    @IBAction func okayButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    //MARK: helper funcs.
    //load images and save them in the storage.
    func loadImages(){
        print("nv: \(selectedPin.images?.count)")
        guard (fetchedResultsController.fetchedObjects?.count != 0) else{
            print("First time!")
            //check if the total number of images > 18(const. number of pics in the single collection)
            if let numbers = Int((response?.photos!.total)!){
                print(numbers)
                if numbers > 18{
                    numberOfImagesToBeLoaded = 18
                }
                else { numberOfImagesToBeLoaded = numbers }
                //loop
                print("numbers are now: \(numberOfImagesToBeLoaded) and on page: \(numberOfPages)")
                for img in 0...numberOfImagesToBeLoaded-1{
                    let image = Image(context: dataController.viewContext)
                    image.photo = UIImage(named: "placeholderImage")!.pngData()
                    collectionView.reloadData()
                    FlickrClient.loadImage(photoData: (response?.photos?.photo[img])!, image: image , completionHandler: handleFlickerLoadResponse)
                }
            }
            return
        }
        print("there's saved images so don't load")
        print("Saved Images numbers: \(fetchedResultsController.fetchedObjects?.count)")
    }
    //MARK: handling functions.
    func handleFlickerLoadResponse(image:Image, imgdata: Data?, error: Error?){
        guard error == nil , imgdata != nil else {
            print("Error")
            return
        }
        //create new image.
        print("now saving data")
        print("selected pin: \(selectedPin.latitude)")
        image.creationDate = Date()
        image.photo = imgdata
        image.pin = selectedPin
        //saving data
        try? dataController.viewContext.save()
        collectionView.reloadData()
    }
}

extension MediaCollectionViewController: NSFetchedResultsControllerDelegate, UICollectionViewDelegate, UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("enta leeh fady? \(fetchedResultsController.sections![section].numberOfObjects)")
        return fetchedResultsController.sections![section].numberOfObjects
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        print("anta?")
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! MediaCollectionViewCell
        cell.imageView.image = UIImage(named: "placeholder")
        let aImage = fetchedResultsController.object(at: indexPath)
        // Configure the cell
        if let data = aImage.photo{
            cell.imageView?.image = UIImage(data: data)
        }
        
        return cell
    }
    
    
//    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
//        switch type {
//        case .insert:
//            print("I AM ADDDDOOONNNGGGG")
//            collectionView.insertItems(at: [indexPath!])
//            break
//        case .delete:
////            tableView.deleteRows(at: [indexPath!], with: .fade)
//            break
//        default:
//            break
//        }
//    }
    
    //update the data.
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        try? fetchedResultsController.performFetch()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        try? fetchedResultsController.performFetch()
    }
    
    func setFlowLayout() {
        let space: CGFloat = 2.0
        let dimensionW = (view.frame.size.width - (2 * space)) / 3.0
        let dimensionH = (view.frame.size.height - (2 * space)) / 6.0
        
        flow.minimumInteritemSpacing = space
        flow.minimumLineSpacing = space
        flow.itemSize = CGSize(width: dimensionW, height: dimensionH)
    }
     
}
