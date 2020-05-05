//
//  Image+Extensions.swift
//  Virtual Tourist
//
//  Created by Mahmoud Elkarargy on 5/5/20.
//  Copyright © 2020 Mahmoud Elkarargy. All rights reserved.
//

import Foundation
import CoreData

// to store objects at their right date.
extension Image {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        creationDate = Date()
    }
}
