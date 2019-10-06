//
//  ViewController.swift
//  MemeMe1.0
//
//  Created by 🍑 on 04/10/2019.
//  Copyright © 2019 udacity. All rights reserved.
//

import UIKit

class MemeEditorViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate , UITextFieldDelegate {

    
    //MARK:- Outlets
    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var memeImageView: UIImageView!
    @IBOutlet weak var topTextField: UITextField!
    @IBOutlet weak var bottomTextField: UITextField!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var navBar: UIToolbar!
    @IBOutlet weak var shareButton: UIBarButtonItem!
    
    //MARK:- Other Variables
    var meme = MemeMe() //an instance of the meme structure
    
    //MARK:- View & Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        topTextField.delegate = self
        bottomTextField.delegate = self
        specifyTextField(topTextField, meme.topTextField)
        specifyTextField(bottomTextField, meme.bottomTextField)
        shareButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cameraButton.isEnabled = UIImagePickerController.isSourceTypeAvailable(.camera) //makes sure the device has a camera available
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    //MARK:- Picking Images
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            memeImageView.image = image
            topTextField.topAnchor.constraint(equalTo:memeImageView.topAnchor, constant: +35).isActive = true
            bottomTextField.bottomAnchor.constraint(equalTo: memeImageView.bottomAnchor, constant: -35).isActive = true
        }
        dismiss(animated: true, completion: nil)
        shareButton.isEnabled = true
    }
    //when the image controller is canceled
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    // function to specify UIImagePickerController attributes for both image pickings for abstraction
    func pickImage(_ imageSource: UIImagePickerController.SourceType ) {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = imageSource
        imagePicker.allowsEditing = false
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction func pickAnImageFromLibrary(_ sender: Any) {
        self.pickImage(.photoLibrary)
    }
    
    @IBAction func pickAnImageFromCamera(_ sender: Any){
        self.pickImage(.camera)
    }
    
    //MARK:- Text Field Delegates & Specifications
    //specifcying text field attributes for top and bottom text fields
    func specifyTextField(_ sender: UITextField , _ text: String) {
        //setting default attributes
        let memeTextAttributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.strokeColor: UIColor.black ,
            NSAttributedString.Key.foregroundColor: UIColor.white ,
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-CondensedBlack", size: 40)!,
            NSAttributedString.Key.strokeWidth: -4.5
        ]
        sender.text = text
        sender.defaultTextAttributes = memeTextAttributes
        sender.textAlignment = .center
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //Makes sure to not edit user input texts
        if textField.text == "TOP" || textField.text == "BOTTOM" {
            textField.text = ""
        }
        //Makes sure to not apply keyboard adjustments to top text field
        if textField == topTextField {
            unsubscribeFromKeyboardNotifications()
        } else {
            subscribeToKeyboardNotifications()
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            return true;
    }
    
    //MARK:- Generating Meme
    //saving meme
    func saveMeme() {
        let memeImage = generateMemedImage()
        meme = MemeMe(topTextField: topTextField.text!, bottomTextField: bottomTextField.text!, ogImage: memeImageView.image!, memeImage: memeImage)
    }
    //generates a memed picture with texts
    func generateMemedImage() -> UIImage {
        navBar.isHidden = true
        toolBar.isHidden = true
        // Render view to an image
        UIGraphicsBeginImageContext(self.view.frame.size)
        view.drawHierarchy(in: self.view.frame, afterScreenUpdates: true)
        let memedImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        navBar.isHidden = false
        toolBar.isHidden = false
        return memedImage
    }
    
    //MARK:- Sharing Meme
    //sets the activity view controller
    @IBAction func shareMemeImage(_ sender: UIBarButtonItem){
        let memeImage = generateMemedImage()
        //creates an instance of the activity view controller and passes the memed image as an activity item to be shared
        let controller = UIActivityViewController(activityItems: [memeImage], applicationActivities: nil)
        self.present(controller, animated: true, completion: nil)
        //presentation of activity view
        controller.completionWithItemsHandler = { (activityType, completed, returnedItems, activityError) -> () in
            if (completed) {
                self.saveMeme()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    //cancel button
    @IBAction func cancelMeme(_ sender: UIBarButtonItem){
        topTextField.text = meme.topTextField
        bottomTextField.text = meme.bottomTextField
        memeImageView.image = nil
        shareButton.isEnabled = false
    }
    //MARK:- Keyboard Adjustments & Notifications
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    //sets the keyboard adjustments to move the view when the bottom text field is selected
    @objc func keyboardWillShow(_ notification:Notification) {
        view.frame.origin.y -= getKeyboardHeight(notification)
    }

    @objc func keyboardWillHide(_ notification:Notification){
        view.frame.origin.y = 0
    }
    
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
}

