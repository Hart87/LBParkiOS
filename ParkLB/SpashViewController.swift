//
//  SpashViewController.swift
//  ParkLB
//
//  Created by James Hart on 11/3/16.
//  Copyright © 2016 James Hart. All rights reserved.
//

import UIKit

class SpashViewController: UIViewController {

    
    @IBOutlet var splashView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    
        splashView.transform = CGAffineTransform.init(scaleX: 0, y: 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        UIView.animate(withDuration: 2.0, delay: 0.5, usingSpringWithDamping: 0.4,
                       initialSpringVelocity: 0.2, options: .curveEaseInOut, animations: {
                        self.splashView.transform = CGAffineTransform.identity
            }, completion: { finished in
                //fire off segue after completon to start the app.
                self.performSegue(withIdentifier: "start", sender: self)
                
        })
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    
}
