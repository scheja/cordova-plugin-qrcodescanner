import UIKit
import AVFoundation

@objc(QRCodeScanner) class QRCodeScanner : CDVPlugin,AVCaptureMetadataOutputObjectsDelegate {

    var supportedBarCodes = [AVMetadataObjectTypeQRCode]

    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
    var input:AVCaptureDeviceInput?
    var captureDevice:AVCaptureDevice?
    var scanActive = false
    var pluginResult:CDVPluginResult?
    var command:CDVInvokedUrlCommand?
    var myView:UIView?
    var x,y,height,width:Int?

    func startScan(cmd: CDVInvokedUrlCommand) {
        self.command = cmd
        self.x = self.command?.argumentAtIndex(0,withDefault: 0) as? Int
        self.y = self.command?.argumentAtIndex(1,withDefault: 0) as? Int
        self.width = self.command?.argumentAtIndex(2,withDefault: 100) as? Int
        self.height = self.command?.argumentAtIndex(3,withDefault: 100) as? Int

        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )

        if (scanActive) {
            return
        } else {
            scanActive = true
        }

        self.commandDelegate.runInBackground {
            self.captureDevice = AVCaptureDevice.devices().filter({ $0.position == .Front }).first as? AVCaptureDevice

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
                captureMetadataOutput.setMetadataObjectsDelegate(self, queue: dispatch_get_main_queue())

                // Detect all the supported bar code
                captureMetadataOutput.metadataObjectTypes = [AVMetadataObjectTypeQRCode]

                dispatch_async(dispatch_get_main_queue()) {
                    let viewRect = CGRectMake(CGFloat(self.x!), CGFloat(self.y!), CGFloat(self.width!), CGFloat(self.height!))
                    self.myView = UIView(frame: viewRect)
                    self.myView?.alpha = 0
                    self.webView.superview?.addSubview(self.myView!);
                    self.webView.superview?.bringSubviewToFront(self.myView!)
                    self.webView.superview?.setNeedsDisplay()

                    // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
                    self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                    self.videoPreviewLayer?.videoGravity = AVLayerVideoGravityResizeAspectFill
                    self.videoPreviewLayer?.frame = self.myView!.bounds
                    let orientation: UIDeviceOrientation = UIDevice.currentDevice().orientation
                    print(orientation)

                    switch (orientation) {
                    case .Portrait:
                        self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                        break
                    case .LandscapeRight:
                        self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeLeft
                        break
                    case .LandscapeLeft:
                        self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.LandscapeRight
                        break
                    default:
                        self.videoPreviewLayer?.connection.videoOrientation = AVCaptureVideoOrientation.Portrait
                        break
                    }

                    self.myView!.layer.addSublayer(self.videoPreviewLayer!)

                    // Start video capture
                    self.captureSession?.startRunning()

                    // Initialize QR Code Frame to highlight the QR code
                    self.qrCodeFrameView = UIView()

                    if let qrCodeFrameView = self.qrCodeFrameView {
                        qrCodeFrameView.layer.borderColor = UIColor.greenColor().CGColor
                        qrCodeFrameView.layer.borderWidth = 2
                        self.webView.superview!.addSubview(qrCodeFrameView)
                        self.webView.superview!.bringSubviewToFront(qrCodeFrameView)
                    }

                    UIView.animateWithDuration(0.3, delay: 0.4, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                        self.myView?.alpha = 1
                        }, completion: nil)

                }
            } catch {
                // If any error occurs, simply print it out and don't continue any more.
                print(error)
                return
            }
        }

    }

    func captureOutput(captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [AnyObject]!, fromConnection connection: AVCaptureConnection!) {

        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects == nil || metadataObjects.count == 0 {
            self.qrCodeFrameView?.frame = CGRectZero
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
            let barCodeObject = self.videoPreviewLayer?.transformedMetadataObjectForMetadataObject(metadataObj)
            self.qrCodeFrameView?.frame = barCodeObject!.bounds

            if metadataObj.stringValue != nil {
                self.didReceiveQRCode(metadataObj.stringValue)
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
            messageAsString: code
        )

        self.commandDelegate!.sendPluginResult(
            self.pluginResult,
            callbackId: self.command!.callbackId
        )
    }

    func stopScan(cmd: CDVInvokedUrlCommand) {
      self.didReceiveQRCode("abort")
    }

}