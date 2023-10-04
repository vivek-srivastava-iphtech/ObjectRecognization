//
//  ViewController.swift
//  seeFood
//
//  Created by iPHTech on 11/12/22.
//a

import UIKit
import CoreML
import Vision

struct DataModel {
    let identifier: String
    let confidence: Double
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var notFoundImageVIew: UIImageView!
    @IBOutlet weak var possibilitiesTableView: UITableView!
    @IBOutlet weak var scanBtn: UIButton!
    @IBOutlet weak var gallaryBtn: UIButton!
    @IBOutlet weak var possibilitiesLbl: UILabel!
    let imagePicker = UIImagePickerController()
    
    var dataArray = [DataModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        possibilitiesTableView.delegate = self
        possibilitiesTableView.dataSource = self
        setupUI()
    }
    
    func setupUI() {
        scanBtn.setTitle("", for: .normal)
        gallaryBtn.setTitle("", for: .normal)
        if dataArray.count <= 0 {
            possibilitiesLbl.isHidden = true
        }
    }
    
    @IBAction func scanBtnTapped(_ sender: UIButton) {
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true)
    }
    
    @IBAction func gallaryBtnTapped(_ sender: UIButton) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true)
    }
    
    
    func detect(imageData: CIImage) {
        dataArray = []
        do{
            let model = try VNCoreMLModel(for: Inceptionv3().model)
            let requestValue = VNCoreMLRequest(model: model) { request, error in
                
                guard let results = request.results as? [VNClassificationObservation]else {
                    print("result not found")
                    return
                }
                for i in 0..<10 {
                    if results[i].confidence  >= 0.4{
                        self.dataArray.append(DataModel(identifier: results[i].identifier, confidence: Double(results[i].confidence) * 100.0))
                    }
                }
                print(self.dataArray)
                if  self.dataArray.count <= 0 {
                    self.notFoundImageVIew.isHidden = false
                    self.possibilitiesTableView.isHidden = true
                    self.possibilitiesLbl.isHidden = true
                }
                else {
                    self.notFoundImageVIew.isHidden = true
                    self.possibilitiesTableView.isHidden = false
                    self.possibilitiesLbl.isHidden = false
                }
            }
            
            let handler = VNImageRequestHandler(ciImage: imageData)
            
            do {
                try handler.perform([requestValue])
            }catch (let error){
                print(error)
            }
            
        }catch let error{
            print(error)
        }
        
    }
    
}


extension ViewController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = userPickedImage
            guard let ciImage = CIImage(image: userPickedImage) else {
                print("failed to change in CIImage")
                return
            }
            detect(imageData: ciImage)
            DispatchQueue.main.async {
                self.possibilitiesTableView.reloadData()
                self.possibilitiesLbl.isHidden = false
            }
            imagePicker.dismiss(animated: true)
        }
       
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataArray.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "cellId", for: indexPath) as? possibilitiesTableViewCell else {
            return  UITableViewCell()
        }
        cell.backgroundColor = UIColor.white
        if self.dataArray.count > 0 {
            cell.identifierLbl.text = dataArray[indexPath.row].identifier
            cell.confidenceLbl.text = String(format: "%.2f", dataArray[indexPath.row].confidence)+"%"
        }
        return cell
    }
    
    
}


class possibilitiesTableViewCell: UITableViewCell{
    
    @IBOutlet weak var confidenceLbl: UILabel!
    @IBOutlet weak var identifierLbl: UILabel!
    
}
