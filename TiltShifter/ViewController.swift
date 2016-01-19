//
//  ViewController.swift
//  TiltShifter
//
//  Created by Throwr on 19/01/2016.
//  Copyright © 2016 Throwr Pty Ltd. All rights reserved.
//

import UIKit
import GPUImage

class ViewController: UIViewController {
    @IBOutlet var tiltShiftView: TiltShifterView!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tiltShiftView.image = UIImage(named: "Selfie.jpg")
        // Do any additional setup after loading the view, typically from a nib.
        
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

    }

    @IBAction func blurStrengthChanged(sender: UISlider) {
        tiltShiftView.blurStrength = CGFloat(sender.value)
    }

}


extension GPUImageFilter {

}