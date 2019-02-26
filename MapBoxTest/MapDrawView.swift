//
//  MapDrawView.swift
//  MapBoxTest
//
//  Created by Jason S Foster on 2/26/19.
//  Copyright © 2019 Jason S Foster. All rights reserved.
//

import UIKit
import Mapbox

protocol MapDrawViewDelegate {
    func polygonFinish(points : [CGPoint])
}

class MapDrawView: UIView {

    fileprivate let POLYGON_ANGLE:Float = 15    //min angle for polygon simplification
    
    // Delegate for the map draw view
    var delegate : MapDrawViewDelegate?
    
    // ImageView to draw the map view on
    fileprivate var canvas : UIImageView
    
    //
    fileprivate var firstPoint = CGPoint.zero
    fileprivate var lastPoint = CGPoint.zero
    fileprivate var points = [CGPoint]()
    
    override init(frame : CGRect) {
        self.canvas = UIImageView(frame: CGRect(x: 0.0, y: 0.0, width: frame.width, height: frame.height))
        super.init(frame: frame)
        self.addSubview(canvas)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            self.firstPoint = touch.location(in: self)
            self.lastPoint = self.firstPoint
            self.points.append(self.firstPoint)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let currentPoint = touch.location(in: self)
            self.drawLine(lastPoint, toPoint: currentPoint)
            self.lastPoint = currentPoint
            self.points.append(lastPoint)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Finish drawing the polygon line
        self.drawLine(lastPoint, toPoint: firstPoint)
        
        // All polygons have to end with the same point that they start with
        self.points.append(firstPoint)
        
        // Removes too many points
        self.simplifyPolygon()
        
        // Calls back to the Controller to apply the polygon to the MapView
        self.delegate?.polygonFinish(points: self.points)
        
        // Removes access points
        self.points.removeAll()
        
        // Clears the old canvas
        self.canvas.removeFromSuperview()
        self.canvas = UIImageView(frame: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        self.addSubview(canvas)
    }
    
    ///
    ///
    ///
    func drawLine(_ fromPoint: CGPoint, toPoint: CGPoint) {
        UIGraphicsBeginImageContext(frame.size)
        let context = UIGraphicsGetCurrentContext()
        self.canvas.image?.draw(in: CGRect(x: 0, y: 0, width: frame.size.width, height: frame.size.height))
        context!.move(to: CGPoint(x: fromPoint.x, y: fromPoint.y))
        context!.addLine(to: CGPoint(x: toPoint.x, y: toPoint.y))
        context!.setLineCap(CGLineCap.round)
        context!.setLineWidth(1)
        context!.setStrokeColor(red: 0, green: 0, blue: 255, alpha: 1.0)
        context!.setBlendMode(CGBlendMode.normal)
        context!.strokePath()
        self.canvas.image = UIGraphicsGetImageFromCurrentImageContext()
        self.canvas.alpha = 1
        UIGraphicsEndImageContext()
    }
    

    
    
    ///
    ///
    ///
    func simplifyPolygon(){
        if self.points.count < 3 {
            return
        }
        var newPoints = [CGPoint]()
        newPoints.append(points[0])
        let k = points.count - 2
        for index in stride(from: 2, to: k + 1, by: 1) {
            let last = newPoints[newPoints.count-1]
            let p = points[index]
            let next = points[index+1]
            let angle = self.getAngleBetweenPoints(last, p2: p, p3: next);
            if angle > POLYGON_ANGLE {
                newPoints.append(p)
            }
            
        }
        self.points = newPoints
    }
    
    func getAngleBetweenPoints(_ p1 : CGPoint, p2 : CGPoint, p3 : CGPoint) -> Float{
        let vector1:CGPoint = CGPoint(x: p2.x - p1.x, y: p2.y - p1.y)
        let vector2:CGPoint = CGPoint(x: p3.x - p2.x, y: p3.y - p2.y)
        let n:Float = Float(vector1.x) * Float(vector2.x) + Float(vector1.y) * Float(vector2.y);
        let d1:Float = sqrt(pow(Float(vector1.x),2) + pow(Float(vector1.y),2))
        let d2:Float = sqrt(pow(Float(vector2.x),2) + pow(Float(vector2.y),2))
        let c:Float = n / (d1 * d2)
        let angle:Float = acos(c)
        return (angle * (180 / 3.14159))
    }
    
}
