//
//  SettingsController.swift
//  SwipeMatchTinder
//
//  Created by Le Doan Anh Khoa on 27/1/19.
//  Copyright © 2019 Le Doan Anh Khoa. All rights reserved.
//

import UIKit
import Firebase
import JGProgressHUD
import SDWebImage

protocol SettingsControllerDelegate: class {
    func didSaveSettings()
}

final class SettingsTableViewController: UITableViewController {
    
    deinit {
        print("Object is destroing itself properly, no retain cycles of any other memory related issue. Memory being reclaimed properly")
    }
    
    var user: User?
    var delegate: SettingsControllerDelegate?
    
    lazy var image1Button = createButton(selector: #selector(handleSelectPhoto))
    lazy var image2Button = createButton(selector: #selector(handleSelectPhoto))
    lazy var image3Button = createButton(selector: #selector(handleSelectPhoto))
    
    @objc func handleSelectPhoto(button: UIButton) {
        let imagePicker = CustomImagePickerController()
        imagePicker.imageButton = button
        imagePicker.delegate = self
        present(imagePicker, animated: true, completion: nil)
    }
    
    func createButton(selector: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle("Select Photo", for: .normal)
        button.backgroundColor = .white
        button.addTarget(self, action: selector, for: .touchUpInside)
        button.layer.cornerRadius = 8
        button.imageView?.contentMode = .scaleAspectFill
        button.clipsToBounds = true
        return button
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupNavigationItems()
        setupTableView()
        fetchCurrentUser()
        
    }
    
    fileprivate func setupTableView() {
        tableView.backgroundColor = UIColor(white: 0.95, alpha: 1) // lightGray
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .interactive
    }
    
    fileprivate func setupNavigationItems() {
        navigationItem.title = "Settings"
        navigationController?.navigationBar.tintColor = #colorLiteral(red: 0.9652562737, green: 0.3096027374, blue: 0.6150571108, alpha: 1)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Cancel",
            style: .plain,
            target: self,
            action: #selector(handleCancel)
        )
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                title: "Save",
                style: .plain,
                target: self,
                action: #selector(handleSave)
            ),
        ]
    }
    
    @objc fileprivate func handleCancel() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc fileprivate func handleSave() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docData: [String: Any] = [
            "uid": uid,
            "fullName": user?.name ?? "",
            "imageUrl1": user?.imageUrl1 ?? "",
            "imageUrl2": user?.imageUrl2 ?? "",
            "imageUrl3": user?.imageUrl3 ?? "",
            "age": user?.age ?? -1,
            "profession": user?.profession ?? "",
            "minSeekingAge": user?.minSeekingAge ?? -1,
            "maxSeekingAge": user?.maxSeekingAge ?? -1
        ]
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Saving settings"
        hud.show(in: view)
        Firestore.firestore().collection("users").document(uid).setData(docData) { (err) in
            hud.dismiss()
            if let err = err {
                print("Failed to save user setting \(err)")
                return
            }
            self.dismiss(animated: true, completion: {
                self.delegate?.didSaveSettings()
            })
        }
    }
    
    fileprivate func fetchCurrentUser() {
        Firestore.firestore().fetchCurrentUser { (user, err) in
            if let err = err {
                print("Failed to fetch user in setting\(err)")
                return
            }
            
            self.user = user
            self.loadUserPhotos()
            self.tableView.reloadData()
        }
    }
    
    fileprivate func loadUserPhotos() {
        if let imageUrl = user?.imageUrl1, let url = URL(string: imageUrl) {
            SDWebImageManager.shared().loadImage(with: url, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                self.image1Button.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
        
        if let imageUrl = user?.imageUrl2, let url = URL(string: imageUrl) {
            SDWebImageManager.shared().loadImage(with: url, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                self.image2Button.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
        
        if let imageUrl = user?.imageUrl3, let url = URL(string: imageUrl) {
            SDWebImageManager.shared().loadImage(with: url, options: .continueInBackground, progress: nil) { (image, _, _, _, _, _) in
                self.image3Button.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
            }
        }
    }
    
    // MARK: - HeaderView
    
    lazy var header: UIView = {
        let header = UIView()
        let padding: CGFloat = 16
        
        let stackView = UIStackView(arrangedSubviews: [image2Button, image3Button])
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = padding
        
        header.addSubview(image1Button)
        image1Button.anchor(
            top: header.topAnchor,
            leading: header.leadingAnchor,
            bottom: header.bottomAnchor,
            trailing: nil,
            padding: .init(top: padding, left: padding, bottom: padding, right: 0)
        )
        
        image1Button.widthAnchor.constraint(equalTo: header.widthAnchor, multiplier: 0.45).isActive = true
        
        header.addSubview(stackView)
        stackView.anchor(
            top: header.topAnchor,
            leading: image1Button.trailingAnchor,
            bottom: header.bottomAnchor,
            trailing: header.trailingAnchor,
            padding: .init(top: padding, left: padding, bottom: padding, right: padding)
        )
        return header
    }()
    
}

// MARK: - UITableViewController Datasource

extension SettingsTableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 7
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 0 : 1
    }
    
    static let defaultMinSeekingAge = 18
    static let defaultMaxSeekingAge = 50
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = SettingsCell(style: .default, reuseIdentifier: nil)
        switch indexPath.section {
        case 1:
            cell.textField.placeholder = "Enter Name"
            cell.textField.text = user?.name
            cell.textField.addTarget(self, action: #selector(handleNameChange), for: .editingChanged)
        case 2:
            cell.textField.placeholder = "Enter Profession"
            cell.textField.text = user?.profession
            cell.textField.addTarget(self, action: #selector(handleProfessionChange), for: .editingChanged)
        case 3:
            cell.textField.placeholder = "Enter Age"
            cell.textField.keyboardType = .numberPad
            cell.textField.addTarget(self, action: #selector(handleAgeChange), for: .editingChanged)
            if let age = user?.age {
                cell.textField.text = String(age)
            }
        default:
            Void()
        }
        if indexPath.section == 4 {
            cell.textField.placeholder = "Enter Bio"
            //            let bioCell = BioCell(style: .default, reuseIdentifier: nil)
            //            let bioTextView = bioCell.textView
            //            bioTextView.text = user?.bio
            //            return bioCell
        }
        // age range cell
        if indexPath.section == 5 {
            let ageRangeCell = AgeRangeCell(style: .default, reuseIdentifier: nil)
            ageRangeCell.minSlider.addTarget(self, action: #selector(handleMinAgeChange), for: .valueChanged)
            ageRangeCell.maxSlider.addTarget(self, action: #selector(handleAgeSeekingChange), for: .valueChanged)
            // we need tp set up the labels on our cell here
            let minAge = user?.minSeekingAge ?? SettingsTableViewController.defaultMinSeekingAge
            let maxAge = user?.maxSeekingAge ?? SettingsTableViewController.defaultMaxSeekingAge
            ageRangeCell.minLabel.text = "Min \(minAge)"
            ageRangeCell.maxLabel.text = "Max \(maxAge)"
            ageRangeCell.minSlider.value = Float(minAge)
            ageRangeCell.maxSlider.value = Float(maxAge)
            return ageRangeCell
        }
        if indexPath.section == 6 {
            let logoutCell = LogoutCell(style: .default, reuseIdentifier: nil)
            logoutCell.logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
            return logoutCell
        }
        return cell
    }
    
    // MARK: - Handle Change
    
    @objc fileprivate func handleNameChange(textField: UITextField) {
        self.user?.name = textField.text
    }
    
    @objc fileprivate func handleProfessionChange(textField: UITextField) {
        self.user?.profession = textField.text
    }
    
    @objc fileprivate func handleAgeChange(textField: UITextField) {
        self.user?.age = Int(textField.text ?? "")
    }
    
    //    @objc fileprivate func handleBioChange(textField: UITextField) {
    //        self.user?.bio = textField.text
    //    }
    
    @objc fileprivate func handleAgeSeekingChange() {
        evaluateMinMax()
    }
    
    @objc fileprivate func handleMinAgeChange() {
        evaluateMinMax()
    }
    
    fileprivate func evaluateMinMax() {
        guard let ageRangeCell = tableView.cellForRow(at: [5, 0]) as? AgeRangeCell else { return }
        let minValue = Int(ageRangeCell.minSlider.value)
        var maxValue = Int(ageRangeCell.maxSlider.value)
        maxValue = max(minValue, maxValue)
        ageRangeCell.maxSlider.value = Float(maxValue)
        ageRangeCell.minLabel.text = "Min \(minValue)"
        ageRangeCell.maxLabel.text = "Max \(maxValue)"
        user?.minSeekingAge = minValue
        user?.maxSeekingAge = maxValue
    }
    
    @objc fileprivate func handleLogout() {
        let alertController = UIAlertController(title: "Log out of \(user?.name ?? "")?", message: "", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Log Out", style: .default, handler: { (_) in
            try? Auth.auth().signOut()
            self.dismiss(animated: true, completion: nil)
        }))
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alertController.view.tintColor = #colorLiteral(red: 0.9652562737, green: 0.3096027374, blue: 0.6150571108, alpha: 1)
        self.present(alertController, animated: true)
        
    }
    
}

// MARK: - UITableViewControllerDelegate

extension SettingsTableViewController {
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if section == 0 {
            return header
        }
        
        let headerLabel = HeaderLabel()
        headerLabel.font = UIFont.boldSystemFont(ofSize: 16)
        headerLabel.textColor = #colorLiteral(red: 0.9652562737, green: 0.3096027374, blue: 0.6150571108, alpha: 1)
        
        switch section {
        case 1:
            headerLabel.text = "Name"
        case 2:
            headerLabel.text = "Profession"
        case 3:
            headerLabel.text = "Age"
        case 4:
            headerLabel.text = "Bio"
        case 5:
            headerLabel.text = "Seeking Age Range"
        default:
            Void()
        }
        
        return headerLabel
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 300
        }
        return 40
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
}


// MARK: - UIImagePickerControllerDelegate

extension SettingsTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let selectedImage = info[.originalImage] as? UIImage
        let imageButton = (picker as? CustomImagePickerController)?.imageButton
        imageButton?.setImage(selectedImage?.withRenderingMode(.alwaysOriginal), for: .normal)
        dismiss(animated: true, completion: nil)
        
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: "/images/\(filename)")
        guard let uploadData = selectedImage?.jpegData(compressionQuality: 0.75) else { return }
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Uploading image..."
        hud.show(in: view)
        ref.putData(uploadData, metadata: nil) { (_, err) in
            hud.dismiss()
            if let err = err {
                print("Failed to upload image to storage in setting \(err)")
                return
            }
            
            ref.downloadURL(completion: { (url, err) in
                hud.dismiss()
                if let err = err {
                    print("Failed to retrieve download URL \(err)")
                    return
                }
                if imageButton == self.image1Button {
                    self.user?.imageUrl1 = url?.absoluteString
                } else if imageButton == self.image2Button {
                    self.user?.imageUrl2 = url?.absoluteString
                } else {
                    self.user?.imageUrl3 = url?.absoluteString
                }
                
            })
        }
    }
    
}


