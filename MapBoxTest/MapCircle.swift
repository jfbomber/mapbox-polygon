//
//  MapCircle.swift
//  uremobile
//
//  Created by Jason S Foster on 3/31/16.
//  Copyright © 2016 UtahRealEstate.com. All rights reserved.
//

import UIKit
import Mapbox

class MapCircle : MGLAnnotationView {
    
    var color : UIColor
    
    init(frame : CGRect, reuseIdentifier : String, color : UIColor, borderWidth : CGFloat = 4.0) {

        self.color = color
        
        super.init(reuseIdentifier: reuseIdentifier)
        
        
        
        self.frame = frame
        
        self.backgroundColor = UIColor.clear
        
        self.layer.borderColor = UIColor.white.cgColor
        self.layer.borderWidth = borderWidth
        
        self.layer.cornerRadius = self.frame.size.width/2.0
        self.backgroundColor = color
    }
    
    override func setSelected(_ selected : Bool, animated : Bool) {
        super.setSelected(selected, animated: true)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CustomMGLPointAnnotation : MGLPointAnnotation {
    var useCircle : Bool = false
}


