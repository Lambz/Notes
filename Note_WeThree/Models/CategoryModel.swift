//
//  CategoryModel.swift
//  Note_WeThree
//
//  Created by Chetan on 2020-06-21.
//  Copyright © 2020 Chaitanya Sanoriya. All rights reserved.
//

import UIKit
//This class stores the data for category cell
//contains the vars and initializer for the cell
class CategoryModel {
   
    var cellImage: UIImage
    var categoryLabel: String
    var categoryCount: Int
    
    init(cellImage: UIImage, categoryName: String) {
        self.cellImage = cellImage
        self.categoryLabel = categoryName
        self.categoryCount = 1
    }

}