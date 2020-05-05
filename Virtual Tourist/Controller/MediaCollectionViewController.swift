//
//  MediaCollectionViewController.swift
//  Virtual Tourist
//
//  Created by Mahmoud Elkarargy on 5/5/20.
//  Copyright © 2020 Mahmoud Elkarargy. All rights reserved.
//

import UIKit

class MediaCollectionViewController: UIViewController {

    var response: ImagesSearchResponse?

    @IBOutlet weak var okayButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        print("number: \(response?.photos?.total)")
    }
    @IBAction func okayButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
}
