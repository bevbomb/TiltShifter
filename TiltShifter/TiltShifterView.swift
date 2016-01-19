
//
//  TiltShifterView.swift
//  TiltShifter
//
//  Created by Throwr on 19/01/2016.
//  Copyright © 2016 Throwr Pty Ltd. All rights reserved.
//

import UIKit
import GPUImage
import SnapKit

class TiltShifterView: UIView, UIGestureRecognizerDelegate {

    enum BlurShape {
        case Linear, Radial
    }
  
    var lastScale: CGFloat = 1
    var lastPoint = CGPointZero
    var startLocation: CGFloat = 0.5
    var blurCircle: CGPoint = CGPointMake(0.5, 0.5)
    
    lazy var imageView: UIImageView = {
        let view = UIImageView(image: self.image)
        view.contentMode = UIViewContentMode.ScaleAspectFit
        view.clipsToBounds = true
        return view
    }()
    
    var shape: BlurShape = .Linear
    var blurDistance: CGFloat = 0.3
    var blurAmount: CGFloat = 1
    var blurStrength: CGFloat = 20 {
        didSet {
            self.updateBlurImage()
        }
    }
    
    var blurredImage: UIImage? {
        didSet {
            self.imageView.image = blurredImage
        }
    }
    var image: UIImage? {
        didSet {
            self.imageView.image = image
            self.updateBlurImage()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonSetup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonSetup()
    }
    
    func commonSetup() {
        self.addSubview(imageView)
        imageView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
        
        let pinch = UIPinchGestureRecognizer(target: self, action: "pinchedView:")
        pinch.delegate = self
        
        self.addGestureRecognizer(pinch)
        
        let pan = UIPanGestureRecognizer(target: self, action: "panView:")
        pan.minimumNumberOfTouches = 1
        pan.maximumNumberOfTouches = 1
        pan.delegate = self
        self.addGestureRecognizer(pan)
        
    }
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    func updateBlurImage() {
        if let image = image {
            let passes = max(image.size.width, image.size.height)/1000+1
            self.blurImage(image, passes: passes)
        }
    }
    
    func blurImage(image: UIImage, passes: CGFloat) {
        if shape == .Radial {
            let radialBlur = GPUImageGaussianSelectiveBlurFilter()
            radialBlur.blurRadiusInPixels = blurStrength
            radialBlur.excludeCircleRadius = 0 + blurDistance
            radialBlur.excludeCirclePoint = blurCircle
            radialBlur.aspectRatio = self.image!.size.width/self.image!.size.height
            
            self.blurredImage = radialBlur.imageByFilteringImage(image)
        } else {
            let increase = 0 + (self.startLocation.roundToPlaces(2) - blurDistance)
            
            let blurTilt =  GPUImageTiltShiftFilter()
            blurTilt.topFocusLevel = increase/2
            blurTilt.bottomFocusLevel = increase/2 + blurDistance
            blurTilt.blurRadiusInPixels = blurStrength
            
            self.blurredImage = blurTilt.imageByFilteringImage(image)
        }
    }
    
    func panView(gesture: UIPanGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.Ended {
            lastPoint = gesture.translationInView(gesture.view)
        }
        
        if gesture.state == .Began || gesture.state == .Changed {
            if let pan = panFromGesture(gesture) {

                if shape == .Radial {
                    blurCircle.x += pan.horizontal/8
                    blurCircle.y += pan.vertical/8
                    
                    blurCircle.x = blurCircle.x < 0.3 ? 0.3 : blurCircle.x
                    blurCircle.x = blurCircle.x > 0.7 ? 0.7 : blurCircle.x
                    
                    blurCircle.y = blurCircle.y < 0.3 ? 0.3 : blurCircle.y
                    blurCircle.y = blurCircle.y > 0.7 ? 0.7 : blurCircle.y
                } else {
                    self.startLocation += pan.vertical/3
                    self.startLocation = self.startLocation <= 0.1 ? 0.1 : self.startLocation
                    self.startLocation = self.startLocation >= 2 ? 2 : self.startLocation
                }
                
                self.updateBlurImage()
            }
        }
    }
    
    func panFromGesture(gesture: UIPanGestureRecognizer) -> Pan? {
        let viewTx = gesture.translationInView(self)
        
        // normalize both directions to [-1, 1]
        let panBounds = bounds
        if panBounds.width < 1 || panBounds.height < 1 {
            return nil
        }
        
        let normalized = CGPointMake(viewTx.x / panBounds.width, viewTx.y / panBounds.height)
        
        return Pan(horizontal: normalized.x, vertical: normalized.y)
    }
    
    func pinchedView(gesture: UIPinchGestureRecognizer) {
        if gesture.state == UIGestureRecognizerState.Ended {
            lastScale = 1
        }
        
        if gesture.state == .Began || gesture.state == .Changed {
            let pinchScale = gesture.scale
            var diff = pinchScale - lastScale
            
            if diff < 0 {
                diff *= 0.6
            } else {
                diff *= 0.4
            }
            
            self.blurDistance += diff
            self.blurDistance = self.blurDistance <= 0.15 ? 0.15 : self.blurDistance
            self.blurDistance = self.blurDistance > 1 ? 1 : self.blurDistance

            self.updateBlurImage()
            
            lastScale = pinchScale
        }
    }
}

internal struct Pan {
    // values in the range [-1, 1], describes the amount of distance the
    // user swiped relative to the size of the containing view.
    // A value of 1 means the user swiped all the way to the right or down,
    // a value of -1 means the user swiped all the way to the left or down,
    // 0.25 means the user swiped 1/4 the distance.
    let horizontal: CGFloat
    let vertical: CGFloat
    
    func scaled(factor: CGFloat) -> Pan {
        return Pan(horizontal: factor * horizontal, vertical: factor * vertical)
    }
}

extension CGFloat {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> CGFloat {
        let divisor = pow(10.0, CGFloat(places))
        return round(self * divisor) / divisor
    }
}
