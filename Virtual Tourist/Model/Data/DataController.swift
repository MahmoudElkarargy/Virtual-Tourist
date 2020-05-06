//
//  DataController.swift
//  Virtual Tourist
//
//  Created by Mahmoud Elkarargy on 5/5/20.
//  Copyright © 2020 Mahmoud Elkarargy. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    
    //singleton instance to Data Controller.
    static let shared = DataController()
    private init(){
        persistentContainer = NSPersistentContainer(name: "VirtualTourist")
    }
    
    // Singleton instance to init the persistent container
    let persistentContainer:NSPersistentContainer
    init(modelName:String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    // Loading the persisitent store.
    func load(completion: (() -> Void)? = nil) {
        persistentContainer.loadPersistentStores { storeDescription, error in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.autoSaveViewContext()
            //May need to pass a func to be called after load.
            completion?()
        }
    }
    
    // Acessing the context.
    var viewContext:NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    
}


// MARK: - Autosaving
extension DataController {
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving")
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }
        //If there change it will save.
        if viewContext.hasChanges {
            //Saving, won't throw error as it will try again the next interval.
            try? viewContext.save()
        }
        //Call again.
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
