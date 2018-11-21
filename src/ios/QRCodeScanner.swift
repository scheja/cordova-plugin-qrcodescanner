import UIKit
import AVFoundation

@objc(QRCodeScanner) class QRCodeScanner : CDVPlugin,AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate {
    
    var supportedBarCodes = [AVMetadataObjectTypeQRCode]
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var input:AVCaptureDeviceInput?
    var captureDevice:AVCaptureDevice?
    var cameraOutput: AVCapturePhotoOutput?
    var scanActive = false
    var pluginResult:CDVPluginResult?
    var command:CDVInvokedUrlCommand?
    var myView:UIView?
    var x,y,height,width:Int?
    var rotatePreview = false
    
    func startScan(_ cmd: CDVInvokedUrlCommand) {
        self.command = cmd
        self.x = self.command?.argument(at: 0,withDefault: 0) as? Int
        self.y = self.command?.argument(at: 1,withDefault: 0) as? Int
        self.width = self.command?.argument(at: 2,withDefault: 100) as? Int
        self.height = self.command?.argument(at: 3,withDefault: 100) as? Int
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        if (scanActive) {
            return
        } else {
            scanActive = true
        }
        
        self.commandDelegate.run( inBackground: {
            self.captureDevice = AVCaptureDevice.devices().filter({ ($0 as AnyObject).position == .front }).first as? AVCaptureDevice
            
            do {
                // Get an instance of the AVCaptureDeviceInput class using the previous device object.
                self.input = try AVCaptureDeviceInput(device: self.captureDevice)
                
                // Initialize the captureSession object.
                self.captureSession = AVCaptureSession()
                
                // Set the input device on the capture session.
                self.captureSession?.addInput(self.input)
                
                // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
                let captureMetadataOutput = AVCaptureMetadataOutput()
                self.captureSession?.addOutput(captureMetadataOutput)
                
                // Set delegate and use the default dispatch queue to execute the call back
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                
                // Detect all the supported bar code
                captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]
                
                DispatchQueue.main.async(execute: {
                    let viewRect = CGRect(origin: CGPoint(x: self.x!, y: self.y!), size: CGSize(width: self.width!, height: self.height!))
                    self.myView = UIView(frame: viewRect)
                    self.myView?.alpha = 0
                    self.webView.superview?.addSubview(self.myView!);
                    self.webView.superview?.bringSubview(toFront: self.myView!)
                    self.webView.superview?.setNeedsDisplay()
                    
                    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
                    self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                    self.videoPreviewLayer?.frame = self.myView!.bounds
                    let orientation: UIDeviceOrientation = UIDevice.current.orientation
                    print(orientation)
                    
                    if(self.rotatePreview) {
                        switch (orientation) {
                        case .portrait:
                            self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                            break
                        case .landscapeRight:
                            self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                            break
                        case .landscapeLeft:
                            self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                            break
                        default:
                            self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                            break
                        }
                    } else {
                        self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                    }
                    
                    self.myView!.layer.addSublayer(self.videoPreviewLayer!)
                    
                    // Start video capture
                    self.captureSession?.startRunning()
                    
                    // Initialize QR Code Frame to highlight the QR code
                    self.qrCodeFrameView = UIView()
                    
                    if let qrCodeFrameView = self.qrCodeFrameView {
                        qrCodeFrameView.layer.borderColor = UIColor.green.cgColor
                        qrCodeFrameView.layer.borderWidth = 2
                        self.webView.superview!.addSubview(qrCodeFrameView)
                        self.webView.superview!.bringSubview(toFront: qrCodeFrameView)
                    }
                    
                    UIView.animate(withDuration: 0.3, delay: 0.4, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        self.myView?.alpha = 1
                    }, completion: nil)
                    
                })
            } catch {
                // If any error occurs, simply print it out and don't continue any more.
                print(error)
                return
            }
        })
    }
    
    
    @available(iOS 11.0, *)
    func getImage(_ cmd: CDVInvokedUrlCommand) {
        self.command = cmd
        self.x = self.command?.argument(at: 0,withDefault: 0) as? Int
        self.y = self.command?.argument(at: 1,withDefault: 0) as? Int
        self.width = self.command?.argument(at: 2,withDefault: 100) as? Int
        self.height = self.command?.argument(at: 3,withDefault: 100) as? Int
        
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        if (scanActive) {
            return
        } else {
            scanActive = true
        }
        
        self.commandDelegate.run( inBackground: {
            self.captureDevice = AVCaptureDevice.devices().filter({ ($0 as AnyObject).position == .front }).first as? AVCaptureDevice
            
            do {
                // Get an instance of the AVCaptureDeviceInput class using the previous device object.
                self.input = try AVCaptureDeviceInput(device: self.captureDevice)
                
                // Initialize the captureSession object.
                self.captureSession = AVCaptureSession()
                self.captureSession?.sessionPreset = AVCaptureSessionPresetPhoto

                self.cameraOutput = AVCapturePhotoOutput()
                
                // Set the input device on the capture session.
                self.captureSession?.addInput(self.input)
                self.captureSession?.addOutput(self.cameraOutput!)
                
                DispatchQueue.main.async(execute: {
                    let viewRect = CGRect(origin: CGPoint(x: self.x!, y: self.y!), size: CGSize(width: self.width!, height: self.height!))
                    self.myView = UIView(frame: viewRect)
                    self.myView?.alpha = 0
                    self.webView.superview?.addSubview(self.myView!);
                    self.webView.superview?.bringSubview(toFront: self.myView!)
                    self.webView.superview?.setNeedsDisplay()
                    
                    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
                    self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                    self.videoPreviewLayer?.frame = self.myView!.bounds
                    let orientation: UIDeviceOrientation = UIDevice.current.orientation
                    print(orientation)
                    
                    if(self.rotatePreview) {
                        switch (orientation) {
                        case .portrait:
                            self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                            break
                        case .landscapeRight:
                            self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                            break
                        case .landscapeLeft:
                            self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeRight
                            break
                        default:
                            self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.portrait
                            break
                        }
                    } else {
                        self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.landscapeLeft
                    }
                    
                    self.myView!.layer.addSublayer(self.videoPreviewLayer!)
                    
                    // Start video capture
                    self.captureSession?.startRunning()
                    
                    UIView.animate(withDuration: 0.3, delay: 0.4, options: UIViewAnimationOptions.curveEaseOut, animations: {
                        self.myView?.alpha = 1
                    }, completion: nil)

                    print("start timer")
                    
                    Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { (Timer) in
                        
                        let settings = AVCapturePhotoSettings.init(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
                        settings.isAutoStillImageStabilizationEnabled = true
                        settings.flashMode = .off
                        print("capture!")
                        
                        DispatchQueue.main.async(execute: {
                            self.cameraOutput?.capturePhoto(with: settings, delegate: self )
                        })
                        
                    })
                
                })
            } catch {
                // If any error occurs, simply print it out and don't continue any more.
                print(error)
                return
            }
        })
    }
    
    @available(iOS 11.0, *)
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {

        print("inside capture!")
        
        
        if let error = error {
            print(error.localizedDescription)
        }
        
        self.qrCodeFrameView?.removeFromSuperview()
        self.qrCodeFrameView = nil
        self.captureSession?.stopRunning()
        self.captureSession = nil
        self.videoPreviewLayer?.removeFromSuperlayer()
        self.videoPreviewLayer = nil
        self.input = nil
        self.captureDevice = nil
        self.myView?.removeFromSuperview()
        self.myView = nil
        self.scanActive = false
        
        let photoMetadata = photo.metadata
        // Returns corresponting NSCFNumber. It seems to specify the origin of the image
        //                print("Metadata orientation: ",photoMetadata["Orientation"])
        
        // Returns corresponting NSCFNumber. It seems to specify the origin of the image
        print("Metadata orientation with key: ",photoMetadata[String(kCGImagePropertyOrientation)] as Any)
        
        guard let imageData = photo.fileDataRepresentation() else {
            print("Error while generating image from photo capture data.");
            return
        }
        
        let image = UIImage(data: imageData)
        let scaledImage = resizeImage(image: image!)
        
        self.pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: UIImageJPEGRepresentation(scaledImage, 0.8)?.base64EncodedString()
        )
        
        self.commandDelegate!.send(
            self.pluginResult,
            callbackId: self.command?.callbackId
        )
    }
    
    private func resizeImage(image: UIImage) -> UIImage {
        // Figure out what our orientation is, and use that to form the rectangle
        let newSize = CGSize(width: image.size.height/2, height: image.size.width)
        
        // Actually do the resizing to the rect using the ImageContext stuff
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        
        let con = UIGraphicsGetCurrentContext();
        
        con?.setFillColor(UIColor.blue.cgColor)
        con?.fill(CGRect(origin: CGPoint(x: 0, y: 0), size: newSize))
        
        let origin = CGPoint(x: newSize.width / 2.0, y: newSize.height / 2.0)
        
        con?.translateBy(x: origin.x, y: origin.y)
        // con?.scaleBy(x: -1.0, y: 1.0)
        con?.rotate(by: CGFloat((-90 * Float.pi) / 180))
        con?.translateBy(x: -origin.x, y: -origin.y)
        
        let rect = CGRect(x: -160, y: -160, width: 960, height: 640*2)
        image.draw(in: rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        print("got something");
        
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            self.qrCodeFrameView?.frame = CGRect.zero
            return
        }
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        // Here we use filter method to check if the type of metadataObj is supported
        // Instead of hardcoding the AVMetadataObjectTypeQRCode, we check if the type
        // can be found in the array of supported bar codes.
        if [AVMetadataObjectTypeQRCode].contains(metadataObj.type) {
            //        if metadataObj.type == AVMetadataObjectTypeQRCode {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = self.videoPreviewLayer?.transformedMetadataObject(for: metadataObj)
            self.qrCodeFrameView?.frame = barCodeObject!.bounds
            
            if metadataObj.stringValue != nil {
                self.didReceiveQRCode(code: metadataObj.stringValue)
            }
        }
    }
    
    func didReceiveQRCode(code: String) {
        self.qrCodeFrameView?.removeFromSuperview()
        self.qrCodeFrameView = nil
        self.captureSession?.stopRunning()
        self.captureSession = nil
        self.videoPreviewLayer?.removeFromSuperlayer()
        self.videoPreviewLayer = nil
        self.input = nil
        self.captureDevice = nil
        self.myView?.removeFromSuperview()
        self.myView = nil
        self.scanActive = false
        
        self.pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: code
        )
        
        self.commandDelegate!.send(
            self.pluginResult,
            callbackId: self.command?.callbackId
        )
    }
    
    func stopScan(_ cmd: CDVInvokedUrlCommand) {
        self.didReceiveQRCode(code: "abort")
    }
    
}

