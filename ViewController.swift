//
//  ViewController.swift
//  SprayAround
//
//  Created by AK on 9/14/18.
//  Copyright © 2018 AK. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import MapKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import CoreMotion
import CoreLocation
import CoreGraphics
import CoreImage
import ARCL

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    //tempArr takes values directly from the x and y readings in the constantly updating location. it will pass these values in the altimeterStart() ways //
    //into the thing.
    var floatArr:[Float] = [1,2,3]
    var tempArr:[Float] = []
    
    var sceneLocationView = SceneLocationView()
    
    var imageView: UIImage!
    
    let altimeter = CMAltimeter()
    lazy var queue = OperationQueue()
    
    static var marker:Int = 0
    
    var database:DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sleep(1) //dramatic effect with launchscreen
        database = Database.database().reference()
        
        sceneLocationView.locationDelegate = self
        
        //creates two buttons then adds the scene then puts the buttons in the front
        let uploadButton = UIButton(frame: CGRect(x: view.bounds.maxX-150, y: view.bounds.maxY-75, width: 125, height: 50))
        uploadButton.backgroundColor = .white
        
        uploadButton.setTitle("Upload Image", for: .normal)
        uploadButton.setTitleColor(.black, for: .normal)
        //uploadButton.addTarget(self, action: #selector(self.altimeterStart), for: .touchUpInside)
            uploadButton.addTarget(self, action: #selector(self.uploadPictureButton), for: .touchUpInside)
    
        print(view.bounds.maxX)
        let cameraButton = UIButton(frame: CGRect(x: 25, y: view.bounds.maxY - 75, width: 125, height: 50))
        cameraButton.backgroundColor = .white
        
        cameraButton.setTitle("Take Picture", for: .normal)
        cameraButton.setTitleColor(.black, for: .normal)
        cameraButton.addTarget(self, action: #selector(takePictureButton(_:)), for: .touchUpInside)
        
        
        self.view.addSubview(sceneLocationView)
        
        self.view.addSubview(uploadButton)
        self.view.bringSubview(toFront: uploadButton)
        
        self.view.addSubview(cameraButton)
        self.view.bringSubview(toFront: cameraButton)
        
        self.altimeterStart()
        
    }
    //not sure, dont fuck with it
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = view.bounds
    }
    //the button to take pictures, just follow the methods below
    @IBAction func takePictureButton(_ sender: Any) {
        convertPictureToFirebase(passedImage: self.sceneLocationView.snapshot())
    }
    //part of arkit, dont touch
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("run")
        sceneLocationView.run()
    }
    
    
    
    //adjusts the array with indexs 0, 1, 2 -> baro, y, x
    @objc func altimeterStart() {
        
        if CMAltimeter.isRelativeAltitudeAvailable() {
            altimeter.startRelativeAltitudeUpdates(to: OperationQueue.main, withHandler: { data, error in
                if (error == nil) {
                    let temp = Float(data?.pressure as! Double)
                    if self.floatArr[0] < temp {
                        print("baro at 0 dropped")
                    } else {
                        print("baro at 0 raised")
                    }
                    self.floatArr[0] = Float(data?.pressure as! Double)
                    if self.floatArr.count > 0 {
                        let temp1 = self.tempArr[self.tempArr.count-1]
                        let temp2 = self.tempArr[self.tempArr.count-2]
                        
                        if self.floatArr[1] < temp1 {
                            print("baro at 1 dropped")
                        } else {
                            print("baro at 1 raised")
                        }
                        
                        if self.floatArr[2] < temp2 {
                            print("baro at 2 dropped")
                        } else {
                            print("baro at 2 raised")
                        }
                        
                        self.floatArr[1] = (self.tempArr[self.tempArr.count-1])
                        self.floatArr[2] = self.tempArr[self.tempArr.count-2]
                        print(self.floatArr)
                        self.altimeter.stopRelativeAltitudeUpdates()
                        return
                    }
                }
            })
        }
        let alert = UIAlertController(title: "Test",
            message: "Testing image",
            preferredStyle: .alert)
        let imageView = UIImageView(frame: CGRect(x: 220, y: 10, width: 40, height: 40))
        imageView.image = #imageLiteral(resourceName: "camera-icon.png")
        alert.view.addSubview(imageView)
        
        print("we returned altimeter start")
    }
    
    //opens the image picker that allows you to choose what picture you want
    @IBAction func uploadPictureButton(_ sender: Any) {
        let image = UIImagePickerController()
        image.delegate = self
        image.sourceType = UIImagePickerControllerSourceType.photoLibrary
        image.allowsEditing = false
        self.present(image, animated: true)
    }
    //after you tap one picture, it runs this code where it formats the dictionary that you use to put shit into firebase
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            imageView = image
            let imageData:NSData = UIImagePNGRepresentation(image)! as NSData
            let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
            //let dataRef = Database.database().reference()
            
            let dateText = Date()
            let dateForm = DateFormatter.localizedString(from: dateText, dateStyle: .medium, timeStyle: .short)
            
            let post = ["x" : floatArr[2] as AnyObject, "y" : floatArr[1] as AnyObject, "z": floatArr[0] as AnyObject, "picture": strBase64 as AnyObject, "date":dateForm as AnyObject]
            database.child("data").childByAutoId().setValue(post)
        }
        self.dismiss(animated: true, completion: nil)
    }
    //similar to the method above except this doesnt work with the picker, it just uses the direct camera
    func convertPictureToFirebase(passedImage: UIImage) {
        var image = UIImage(named: "image")
        image = passedImage
        let imageData:NSData = UIImagePNGRepresentation(image!)! as NSData
        let strBase64 = imageData.base64EncodedString(options: .lineLength64Characters)
        //let dataRef = Database.database().reference()
        
        let dateText = Date()
        let dateForm = DateFormatter.localizedString(from: dateText, dateStyle: .medium, timeStyle: .short)
        
        imageView = image
        
        save()
        altimeterStart()
        let post = ["x" : floatArr[2] as AnyObject, "y" : floatArr[1] as AnyObject, "z": floatArr[0] as AnyObject, "picture": strBase64 as AnyObject, "date":dateForm as AnyObject]
        database.child("data").childByAutoId().setValue(post)
    }
    //ignore, this is for errors that we dont need to deal with
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //just saves pictures into the photoalbum, back trace to find this cuz im not sure which ones use it
    func save() {
        UIImageWriteToSavedPhotosAlbum(imageView!, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    //this just pops up with a "yay you saved it" or "no you fucked up" message when you save it into the photolibrary
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: false)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: false)
        }
    }
    
    
    
    
}

//this is how you get position y and x (latitude and longitude)
extension ViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
       // print("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
        tempArr.append( Float(location.coordinate.latitude)) //y
        tempArr.append( Float(location.coordinate.longitude)) // x
        //print(floatArr)
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        //print("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    }
    
    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        
    }
    
    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        
    }
}

