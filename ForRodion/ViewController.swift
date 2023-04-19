//
//  ViewController.swift
//  ForRodion
//
//  Created by Султан Фастахиев on 17.04.2023.
//

import AVFoundation
import UIKit



class ViewController: UIViewController {
    @IBOutlet var popUpView: UIView!
    @IBOutlet var popUpLabel: UILabel!
    var session: AVCaptureSession?
    
    let output = AVCapturePhotoOutput()
    let previewLayer = AVCaptureVideoPreviewLayer()
    private let shutterButton: UIButton = {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        button.layer.cornerRadius = 50
        button.layer.borderWidth = 10
        button.layer.borderColor = UIColor.white.cgColor
        return button
    }()
    private let stockButton: UIButton = {
        let button = UIButton(frame: CGRect(x:0, y: 0, width: 100, height: 50))
        button.setTitle("Переснять", for: .normal)
        button.layer.backgroundColor = UIColor.gray.cgColor
        button.layer.cornerRadius = 20
        return button
    }()
    private let shareButton: UIButton = {
        let button = UIButton(frame: CGRect(x:30, y:770, width: 60, height: 60))
        button.setImage(UIImage(systemName: "square.and.arrow.up"), for: .normal)
        button.layer.backgroundColor = UIColor.white.cgColor
        button.layer.cornerRadius = 20
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.layer.addSublayer(previewLayer)
        view.addSubview(shutterButton)
        view.addSubview(shareButton)
        checkCameraPremission()
        
        shutterButton.addTarget(self, action: #selector(didTapTakePhoto), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(didTapShare), for: .touchUpInside)
        popUpView.layer.cornerRadius = 10
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
//        popUpView.center = CGPoint(x: 200, y: 500)
        popUpView.backgroundColor = .gray
        popUpView.center = view.center
        popUpLabel.center = popUpView.center
//        okButton.center = popUpLabel.center
//        okButton.center = CGPoint(x: 177, y: 195)
        shutterButton.center = CGPoint(x: view.frame.size.width/2,
                                       y: view.frame.size.height - 100)
        stockButton.center = CGPoint(x: view.frame.size.width/2,
                                       y: view.frame.size.height - 100)
        
    }
    
    func checkCameraPremission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                guard granted else {
                    return
                }
                DispatchQueue.main.async {
                    self?.setUpCamera()
                }
            }
        case .restricted:
            break
        case .denied:
            break
        case .authorized:
            setUpCamera()
        @unknown default:
            break
        }
    }
    
    func setUpCamera(){
        let session = AVCaptureSession()
        if let device = AVCaptureDevice.default(for: .video) {
            do{
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
                if session.canAddOutput(output){
                    session.addOutput(output)
                }
                
                previewLayer.videoGravity = .resizeAspectFill
                previewLayer.session = session
                
                session.startRunning()
                self.session = session
            }
            catch {
                print(error)
                
            }
        }
    }
    
    
    @objc private func didTapTakePhoto(){
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        
    }
    @objc private func didTapShare(){
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
        
    }
    
}


extension ViewController: AVCapturePhotoCaptureDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            return
        }
        var image = UIImage(data: data)
        session?.stopRunning()
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFill
        imageView.frame = view.bounds
        view.addSubview(imageView)
        stockButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
        self.uploadImage(fileName: "file", image: image!)
        
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let gg = (info[UIImagePickerController.InfoKey(rawValue: "UIImagePickerControllerEditedImage")] as? UIImage) {
            session?.stopRunning()
            stockButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
            picker.dismiss(animated: true, completion: nil)
            shareButton.removeFromSuperview()
            shutterButton.removeFromSuperview()
            self.uploadImage(fileName: "file", image: gg)
        }
        
    }
    func uploadImage(fileName: String, image: UIImage) {
        let url = URL(string: "http://10.82.130.42:8000/")
        let boundary = UUID().uuidString
        let session = URLSession.shared
        var urlRequest = URLRequest(url: url!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let alert = UIAlertController(title: "Loading", message: "Please wait...", preferredStyle: .alert)
        present(alert, animated: true, completion: nil)
        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        let paramName = "file"
        data.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        data.append(image.pngData()!)
        var normal: String?
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        session.uploadTask(with: urlRequest, from: data, completionHandler: { responseData, response, error in
                        if error == nil {
                            let jsonData = try? JSONSerialization.jsonObject(with: responseData!, options: .allowFragments)
                            if let json = jsonData as? [String: Any] {
                                print(json["smiles"])
                                normal = json["smiles"] as! String
                                
                               

                                
                            }
                        }
                    }).resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            alert.dismiss(animated: true, completion: nil)
            self.popUpLabel.text = normal
            self.popUpView.center = self.view.center
            self.animateIn()
 
//            self.view.addSubview(self.stockButton)
           
        }
        

       

        
        
        
    }
    
    func animateIn() {
        self.view.addSubview(popUpView)
        popUpLabel.preferredMaxLayoutWidth = 250
        popUpLabel.textColor = .white
        popUpView.center = self.view.center
        popUpView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
        popUpView.alpha = 0
        
        UIView.animate(withDuration: 0.4) {
            self.popUpView.alpha = 1
            self.popUpView.transform = CGAffineTransform.identity
        }
        view.addSubview(stockButton)
    }
    
    func animateOut() {
        UIView.animate(withDuration: 0.4, animations: {
            self.popUpView.transform = CGAffineTransform.init(scaleX: 1.3, y: 1.3)
            self.popUpView.alpha = 0
            
        }) { (success: Bool) in
            self.popUpView.removeFromSuperview()
        }
    }
    
    @objc private func didTapBack(){
        animateOut()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.view.subviews.forEach({ $0.removeFromSuperview() })
            self.view.subviews.map({ $0.removeFromSuperview() })
            self.view.addSubview(self.shutterButton)
            self.view.addSubview(self.shareButton)
            self.session?.startRunning()
        }
        
        
    }
    
}
