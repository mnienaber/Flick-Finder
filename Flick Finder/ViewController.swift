//
//  ViewController.swift
//  Flick Finder
//
//  Created by Michael Nienaber on 6/02/2016.
//  Copyright © 2016 Michael Nienaber. All rights reserved.
//

import UIKit

let BASE_URL = "https://api.flickr.com/services/rest/"
let METHOD_NAME = "flickr.photos.search"
let API_KEY = "a2d1aaeead83f40edc51928ef2caf6a9"
let EXTRAS = "url_m"
let DATA_FORMAT = "json"
let NO_JSON_CALLBACK = "1"
let PER_PAGE = "500"

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var imageNameLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var searchBoxText: UITextField!
    @IBOutlet weak var latTextSearch: UITextField!
    @IBOutlet weak var longTextSearch: UITextField!
    
    var tap: UITapGestureRecognizer? = nil
    var latLongValue: String?
    var newLatString: String?
    var newLongString: String?
    var newLatBoxPlusString: String?
    var newLongBoxPlusString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.searchBoxText.delegate = self
        self.latTextSearch.delegate = self
        self.longTextSearch.delegate = self
        tap = UITapGestureRecognizer(target: self, action: "handleSingleTap:")
        tap?.numberOfTapsRequired = 1
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.addGestureRecognizer(tap!)
        subscribeToKeyboardNotifications()
        //print("Add the tapRecognizer and subscribe to keyboard notifications in viewWillAppear")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.view.removeGestureRecognizer(tap!)
        unsubscribeToKeyboardNotifications()
        //print("Remove the tapRecognizer and unsubscribe from keyboard notifications in viewWillDisappear")
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        
        self.view.endEditing(true)
        //print("End editing here")
    }
    
    func addKeyboardDismissRecognizer() {
        
        self.view.addGestureRecognizer(tap!)
        //print("Add the recognizer to dismiss the keyboard")
    }
    
    func removeKeyboardDismissRecognizer() {
        
        self.view.removeGestureRecognizer(tap!)
        //print("Remove the recognizer to dismiss the keyboard")
    }
    
    func subscribeToKeyboardNotifications() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
    }
    
    func unsubscribeToKeyboardNotifications() {
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        //print("Unsubscribe to the KeyboardWillShow and KeyboardWillHide notifications")
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        if view.frame.origin.y > 0 {
        } else {
            view.frame.origin.y -= getKeyboardHeight(notification) - 110
        }
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(notification: NSNotification) -> CGFloat {
        
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.CGRectValue().height
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    func buildBbox() -> String {
        
        let floatLatString:Float = (self.latTextSearch.text! as NSString).floatValue - 0.5
        let floatLongString:Float = (self.longTextSearch.text! as NSString).floatValue - 0.5
        let floatLatBoxPlusString:Float = (self.latTextSearch.text! as NSString).floatValue + 0.5
        let floatLongBoxPlusString:Float = (self.longTextSearch.text! as NSString).floatValue + 0.5

        if searchBoxText.text!.isEmpty == false {
            
            latLongValue = ""
            return latLongValue!
        } else if floatLatString > -91 && floatLatString < 91 && floatLongString > -181 && floatLongString < 181 {
            
            newLatString = floatLatString.description
            newLongString = floatLongString.description
            newLatBoxPlusString = floatLatBoxPlusString.description
            newLongBoxPlusString = floatLongBoxPlusString.description
            latLongValue = newLongString!  + "," + newLatString! + "," + newLongBoxPlusString! + "," + newLatBoxPlusString!
            return latLongValue!
        } else {
            latLongValue = ""
            return latLongValue!
        }
    }

    func getImageBySearchQuery(methodArguments: [String: AnyObject]) {
        
        print("search text is \(searchBoxText.text!)")
        print("latlong text is \(self.latTextSearch.text! + ",0," + self.longTextSearch.text! + ",0")")
    
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        print(urlString)
        
        /* 5 - Create NSURLSessionDataTask and completion handler */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* 1 - Get the photos dictionary */
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            
            /* Flickr API will only return up the 4000 images (100 per page * 40 page max) */
            /* Pick a random page! */
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            self.getImageBySearchQueryWithPage(methodArguments, pageNumber: randomPage)
        }
        task.resume()
    }
    
    func getImageBySearchQueryWithPage(methodArguments: [String: AnyObject], pageNumber: Int) {
        
        var withPageDictionary = methodArguments
        withPageDictionary["page"] = pageNumber
        
        let session = NSURLSession.sharedSession()
        let urlString = BASE_URL + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        print(urlString)
        
        /* 5 - Create NSURLSessionDataTask and completion handler */
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error)")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    print("Your request returned an invalid response! Status code: \(response.statusCode)!")
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                } else {
                    print("Your request returned an invalid response!")
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                return
            }
            
            /* Parse the data! */
            let parsedResult: AnyObject!
            do {
                parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
            } catch {
                parsedResult = nil
                print("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error? */
            guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                print("Flickr API returned an error. See error code and message in \(parsedResult)")
                return
            }
            
            /* 1 - Get the photos dictionary */
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                print("Cannot find keys 'photos' in \(parsedResult)")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPagesVal = photosDictionary["pages"] as? Int else {
                print("Cannot find key 'pages' in \(photosDictionary)")
                return
            }
            
            if totalPagesVal > 0 {
                
                /* GUARD: Is the "photo" key in photosDictionary? */
                guard let photosArray = photosDictionary["photo"] as? [[String: AnyObject]] else {
                    print("Cannot find key 'photo' in \(photosDictionary)")
                    return
                }
                
                /* 4 - Get a random index, and pick a random photo's dictionary */
                let randomPhotoIndex = Int(arc4random_uniform(UInt32(photosArray.count)))
                let photoDictionary = photosArray[randomPhotoIndex] as [String: AnyObject]
                let photoTitle = photoDictionary["title"] as? String /* non-fatal */
                
                /* GUARD: Does our photo have a key for 'url_m'? */
                guard let imageUrlString = photoDictionary["url_m"] as? String else {
                    print("Cannot find key 'url_m' in \(photoDictionary)")
                    return
                }
                
                /* 8 - If an image exists at the url, set the image and title */
                let imageURL = NSURL(string: imageUrlString)
                if let imageData = NSData(contentsOfURL: imageURL!) {
                    dispatch_async(dispatch_get_main_queue(), {
                        self.image.image = UIImage(data: imageData)
                        self.imageNameLabel.text = photoTitle
                        print(imageUrlString)
                        
                        if methodArguments["bbox"] != nil {
                            if let photoTitle = photoTitle {
                                self.imageNameLabel.text = "\(self.latLongValue) \(photoTitle)"
                            } else {
                                self.imageNameLabel.text = "nothing"
                            }
                        } else {
                            self.imageNameLabel.text = photoTitle ?? "(Untitled)"
                            
                        }
                    })
                } else {
                    print("Image does not exist at \(imageURL)")
                }
            } else {
                dispatch_async(dispatch_get_main_queue(), {
                    self.image.image = nil
                    self.imageNameLabel.text = "Got nothing for ya, try a different search!"
                })
            }
        }
        handleSingleTap(tap!)
        task.resume()
    }


    @IBAction func textSearch(sender: AnyObject) {
        
        self.dismissAnyVisibleKeyboards()
        
        let methodArguments: [String: String!] = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            "text": self.searchBoxText.text!,
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        getImageBySearchQuery(methodArguments)
    }
    
    @IBAction func latLongSearch(sender: AnyObject) {
        
        self.dismissAnyVisibleKeyboards()
        
        let methodArguments = [
            "method": METHOD_NAME,
            "api_key": API_KEY,
            //"text": self.searchBoxText.text!,
            "bbox": buildBbox(),
            "extras": EXTRAS,
            "format": DATA_FORMAT,
            "nojsoncallback": NO_JSON_CALLBACK
        ]
        getImageBySearchQuery(methodArguments)
    }
}

extension ViewController {
    func dismissAnyVisibleKeyboards() {
        if searchBoxText.isFirstResponder() || latTextSearch.isFirstResponder() || longTextSearch.isFirstResponder() {
            self.view.endEditing(true)
        }
    }
}


