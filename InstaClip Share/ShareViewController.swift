//
//  ShareViewController.swift
//  InstaClip Share
//
//  Created by John Weeks on 8/14/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit
import MobileCoreServices
import MessageUI
import AVFoundation
import Metal
import QuartzCore

enum TranscodeError: ErrorType {
    case Fatal(String)
}

// We will have a custom UI so no need to subclass SLComposeServiceViewController
class ShareViewController: UIViewController, MFMessageComposeViewControllerDelegate {
    
    @IBOutlet weak var waveformView: UIView!
    var podcastURL: NSURL?
    var currentTime: CMTime?
    var clipURL: NSURL?
    let clip = Clip()
    
    var mtlDevice: MTLDevice?
    var waveform: Waveform?
    
    var pipelineState: MTLRenderPipelineState?
    var commandQueue: MTLCommandQueue?
    var timer: CADisplayLink?
    
    //let panSensivity:Float = 600.0 //5.0
    var lastPanLocation: CGPoint!
    
    // should have an index type !
    var index: Int = 2250
    var leftTrimIndex: Int = 2250 + (100 * 2)
    var rightTrimIndex: Int = 2250 + (100 * 2) + (100 * 4)
    var playHeadIndex: Int = 0
    
    var player: AVPlayer?
    
    func renderLoop() {
        autoreleasepool {
            self.render()
        }
    }
    
    func render() {
        guard waveform != nil, // index != lastIndexRendered && && waveformArray != nil,
            let mtlLayer = waveformView.layer as? CAMetalLayer, drawable = mtlLayer.nextDrawable(),
            pipelineState = pipelineState, commandQueue = commandQueue else {
                return
        }
        
        let (vertexBuffer, vertexCount, avaliableMtlBufferSemaphore) = waveform!.vertexMtlBuffer(index)
        
        //let dataSize = waveformArray!.count * sizeofValue(waveformArray![0]) //750*4*sizeofValue(waveform![0]) //
        //vertexBuffer = mtlDevice.newBufferWithBytes(waveformArray!, length: dataSize, options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        //            var waveformPtr = unsafeBitCast(waveformArray!, UnsafeMutablePointer<Float>.self)
        //            for var i=0; i<20; i+=2 {
        //                let x = waveformPtr.memory
        //                let y:Float = Float((waveformPtr+1).memory)
        //                print(x, waveformArray![i], y, waveformArray![i+1])
        //                waveformPtr += 2
        //            }
        
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0) //MTLClearColorMake(11.0/255.0, 35.0/255.0, 66.0/255.0, 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .Store
        
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.addCompletedHandler { (commandBuffer) -> Void in
            dispatch_semaphore_signal(avaliableMtlBufferSemaphore)
        }
        
        let renderEncoderOpt = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        let renderEncoder = renderEncoderOpt
        renderEncoder.setRenderPipelineState(pipelineState)
        
        // typealias Index = Int
        // typealias Pixel = CGFloat
        // typealias Translater = Index -> Pixel
        
        //            struct Uniform {
        //                float widthPixel;
        //                float leftTrimXPixel;
        //                float rightTrimXPixel;
        // need to add playHead
        //            };
        //let uniform: ContiguousArray<MetalPositionComponent> = [375.0, 750.0, leftTrimIndex/2.0 - index/2.0, rightTrimIndex/2.0 - index/2.0]
        //renderEncoder.setFragmentBytes(unsafeBitCast(uniform, UnsafeMutablePointer<MetalPositionComponent>.self), length: uniform.count*sizeof(MetalPositionComponent), atIndex: 0)
        let widthPixel = MetalPositionComponent(UIScreen.mainScreen().bounds.width*UIScreen.mainScreen().scale)
        let uniform: ContiguousArray<MetalPositionComponent> = [widthPixel, MetalPositionComponent(leftTrimIndex/2 - index/2), MetalPositionComponent(rightTrimIndex/2 - index/2)]

        uniform.withUnsafeBufferPointer { (uniformPtr: UnsafeBufferPointer<MetalPositionComponent>) -> Void in
            renderEncoder.setVertexBytes(uniformPtr.baseAddress, length: uniform.count*sizeof(MetalPositionComponent), atIndex: 0)
            renderEncoder.setFragmentBytes(uniformPtr.baseAddress, length: uniform.count*sizeof(MetalPositionComponent), atIndex: 0)
        }
        
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 1)
        //renderEncoder.drawPrimitives(.Line, vertexStart: 0, vertexCount: ((vertexBuffer.length/sizeof(Float))/2), instanceCount: 1)
        renderEncoder.drawPrimitives(.Line, vertexStart: 0, vertexCount: vertexCount, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
    }
    
    
    func pan(panGesture: UIPanGestureRecognizer){
        if panGesture.state == UIGestureRecognizerState.Changed {
            let pointInView = panGesture.locationInView(self.view)
            let xDelta = Int((lastPanLocation.x - pointInView.x) * UIScreen.mainScreen().scale)
            
            // if touching L trimBar then change it's position
            // if touching R trimBar then change it's position
            // otherwise change index (horizontial scroll)
            let leftTrimLocation = CGFloat(leftTrimIndex/2 - index/2)
            let rightTrimLocation = CGFloat(rightTrimIndex/2 - index/2)
            if (pointInView.x - 20.0 < leftTrimLocation) && (pointInView.x + 20.0 > leftTrimLocation) {
                leftTrimIndex -= xDelta
                if leftTrimIndex%2 != 0 {
                    leftTrimIndex -= 1
                }
            } else if (pointInView.x - 20.0 < rightTrimLocation) && (pointInView.x + 20.0 > rightTrimLocation) {
                rightTrimIndex -= xDelta
                if rightTrimIndex%2 != 0 {
                    rightTrimIndex -= 1
                }
            } else {
                index += xDelta
                if index%2 != 0 {
                    index -= 1
                }
                if index < 0 {
                    index = 0
                }
            }
            lastPanLocation = pointInView
        } else if panGesture.state == UIGestureRecognizerState.Began {
            lastPanLocation = panGesture.locationInView(self.view)
        }        
    }
    
    
    override func viewDidLoad() {
        
//        print((0/2) * (1.0 / (750.0/2.0)) - 1.0)
//        print((1/2) * (1.0 / (750.0/2.0)) - 1.0)
//        print((748/2) * (1.0 / (750.0/2.0)) - 1.0)
//        print((749/2) * (1.0 / (750.0/2.0)) - 1.0)
//
//        print("")
//        
//        print((0/2) * (1.0 / (1334.0/2.0)) - 1.0)
//        print((1/2) * (1.0 / (1334.0/2.0)) - 1.0)
//        print((2666/2) * (1.0 / (1334.0/2.0)) - 1.0)
//        print((2667/2) * (1.0 / (1334.0/2.0)) - 1.0)
        
        mtlDevice = MTLCreateSystemDefaultDevice()
        guard let mtlDevice = mtlDevice else {
            self.showAlertWithTitle("Can't reference the preferred system default Metal device", message:nil)
            return
        }
        timer = CADisplayLink(target: self, selector: Selector("renderLoop"))
        guard let timer = timer else {
            self.showAlertWithTitle("Can't display link to render audio waveform", message:nil)
            return
        }
        //timer.frameInterval = 90
        
        if let gradientLayer = self.view.layer as? CAGradientLayer {
            gradientLayer.colors = [UIColor(red: 11.0/255.0, green: 35.0/255.0, blue: 66.0/255.0, alpha: 1.0).CGColor,
                                    UIColor(red: 9.0/255.0, green: 11.0/255.0, blue: 20.0/255.0, alpha: 1.0).CGColor]
        }
        
        // WaveformView.swift override class func layerClass returns CAMetalLayer
        if let mtlLayer = waveformView.layer as? CAMetalLayer {
            //waveformView.opaque = false
            //waveformView.backgroundColor = nil
            mtlLayer.backgroundColor = nil
            mtlLayer.opaque = false
            mtlLayer.device = mtlDevice
            mtlLayer.pixelFormat = .BGRA8Unorm
            mtlLayer.framebufferOnly = true
        }
        
        let defaultLibrary = mtlDevice.newDefaultLibrary()
        let fragmentProgram = defaultLibrary!.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary!.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
//        pipelineStateDescriptor.colorAttachments[0].blendingEnabled = true
//        pipelineStateDescriptor.colorAttachments[0].rgbBlendOperation = .Add
//        pipelineStateDescriptor.colorAttachments[0].alphaBlendOperation = .Add
//        pipelineStateDescriptor.colorAttachments[0].sourceRGBBlendFactor = .One//.SourceAlpha
//        pipelineStateDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .One//.SourceAlpha
//        pipelineStateDescriptor.colorAttachments[0].destinationRGBBlendFactor = .OneMinusSourceAlpha
//        pipelineStateDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .OneMinusSourceAlpha

        do {
            try pipelineState = mtlDevice.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch {
            print("error with device.newRenderPipelineStateWithDescriptor \(error)")
        }
        commandQueue = mtlDevice.newCommandQueue()

        let pan = UIPanGestureRecognizer(target: self, action: Selector("pan:"))
        waveformView.addGestureRecognizer(pan)
        
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        guard MFMessageComposeViewController.canSendAttachments() else {
            self.showAlertWithTitle("Can't create a clip", message: "This device can not send attachments in MMS, iMessage messages.")
            return
        }

        if let inputItems = self.extensionContext?.inputItems as? [NSExtensionItem] {
            for extensionItem in inputItems     {
                if let attachments = extensionItem.attachments as? [NSItemProvider] {
                    for itemProvider in attachments {
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypeURL)) { //kUTTypeFileURL
                            itemProvider.loadItemForTypeIdentifier(String(kUTTypeURL), options: nil, completionHandler: { (data :NSSecureCoding?, error :NSError!) -> Void in
                                guard let podcastURL = data as? NSURL else {
                                    // if cast fails docs guarantee error object exists so implicit unwrapped optional succeeds
                                    self.showAlertWithTitle("Could not load \(String(kUTTypeURL))", message: error.localizedDescription)
                                    return
                                }
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.podcastURL = podcastURL
                                    self.itemLoadComplete()
                                })
                            })
                        }
                        if itemProvider.hasItemConformingToTypeIdentifier(String(kUTTypePlainText)) {
                            itemProvider.loadItemForTypeIdentifier(String(kUTTypePlainText), options: nil, completionHandler: { (data :NSSecureCoding?, error :NSError!) -> Void in
                                guard let currentTimeString = data as? String else {
                                    // if cast fails docs guarantee error object exists so implicit unwrapped optional succeeds
                                    self.showAlertWithTitle("Could not load \(String(kUTTypePlainText))", message: error.localizedDescription)
                                    return
                                }
                                guard let currentTimeDouble = Double(currentTimeString) else {
                                    self.showAlertWithTitle("Could not convert start time \"\(currentTimeString)\" to double", message: nil)
                                    return
                                }
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.currentTime = CMTimeMakeWithSeconds(currentTimeDouble, Int32(NSEC_PER_SEC))
                                    self.itemLoadComplete()
                                })
                            })
                        }
                    }
                }
            }
        }
    }
    
    private func itemLoadComplete() {
        guard let podcastURL = self.podcastURL, currentTime = self.currentTime, mtlDevice = self.mtlDevice else {
            // need both to make the clip
            return
        }
        
        self.waveform = Waveform(podcastURL: podcastURL, mtlDevice: mtlDevice, currentTime: currentTime)
        
//        self.waveform?.readAndConflate(startTimeCMT, completionHandler: { (waveform) -> Void in
//                self.waveformArray = waveform
//            })
        
        return
        return

        clip.newFromURL(podcastURL, startTime: currentTime, completionHandler: { (result) -> Void in
            switch result {
            case let .Success(clipURL):
                self.clipURL = clipURL
                let txtMessageVC = MFMessageComposeViewController()
                txtMessageVC.messageComposeDelegate = self
                if !txtMessageVC.addAttachmentURL(clipURL, withAlternateFilename: nil) {
                    self.showAlertWithTitle("Unable to attach clip to message", message: nil)
                    return
                }
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.presentViewController(txtMessageVC, animated: true, completion: nil)
                })
            case let .Failure(msg):
                self.showAlertWithTitle("Can't create the clip", message: msg)
            }
        })
    }
    
    private func showAlertWithTitle(title: String, message: String?) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "Okay", style: .Default) { (action) -> Void in
            self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
        }
        alertVC.addAction(defaultAction)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(alertVC, animated: true, completion: nil)
        })
    }
    
    // MARK: - MFMessageComposeViewControllerDelegate
    func messageComposeViewController(controller: MFMessageComposeViewController, didFinishWithResult result: MessageComposeResult) {
        controller.dismissViewControllerAnimated(true) { () -> Void in
            do {
                // MFMessageComposeViewController is only created if clipURL exisits so forced unwrap succeeds
                try NSFileManager.defaultManager().removeItemAtURL(self.clipURL!)
                self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
            } catch let error as NSError {
                self.showAlertWithTitle("Error deleting temporary clip file", message: error.localizedDescription)
            } catch {
                self.showAlertWithTitle("Encountered an unknown error", message: String(error))
            }
        }
    }
    
    @IBAction func playButtonPress(sender: UIButton) {
        guard let waveform = waveform else {
            return
        }
        let playerItem = AVPlayerItem(asset: waveform.urlAsset)
        player = AVPlayer(playerItem: playerItem)
        
        let startTime = waveform.indexToTime(Float(leftTrimIndex))
        let stopTime = waveform.indexToTime(Float(rightTrimIndex))
        print(CMTimeCopyDescription(kCFAllocatorDefault, currentTime!), CMTimeCopyDescription(kCFAllocatorDefault, startTime), CMTimeCopyDescription(kCFAllocatorDefault, stopTime))
        
        playerItem.seekToTime(startTime)
        playerItem.forwardPlaybackEndTime = stopTime
        //print(playerItem.status.rawValue, player?.status.rawValue, player?.muted, player?.volume)
        
        while (playerItem.status != .ReadyToPlay && player?.status != .ReadyToPlay) {
            NSThread.sleepForTimeInterval(1.0)
            print("z", terminator:"")
        }
        
        if AVAudioSession().category != AVAudioSessionCategoryPlayback {
            do {
                try AVAudioSession().setCategory(AVAudioSessionCategoryPlayback)
                try AVAudioSession().setActive(true)
            } catch let error as NSError {
                // try... lands here
                showAlertWithTitle("Problem setting up AVAudioSession", message: error.localizedDescription)
            } catch {
                showAlertWithTitle("Problem setting up AVAudioSession", message: "Encountered an unknown error \(error)")
            }
        }

        player?.play()
    }
    
    @IBAction func doneButtonPress(sender: UIButton) {
        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
    }
}