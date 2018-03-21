//
//  ViewController.swift
//  FirebaseChat
//
//  Created by SS042 on 14/03/18.
//  Copyright © 2018 SS042. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {

    @IBOutlet var userName: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func loginAnonymousClicked(_ sender: UIButton) {
        if userName.text != "" { // 1
            Auth.auth().signInAnonymously(completion: { (user, error) in // 2
                if let err = error { // 3
                    print(err.localizedDescription)
                    return
                }
                
                let vc = WaitingChatRoomViewController()
                self.navigationController?.pushViewController(vc, animated: true)
            })
        }
    }
    
}

