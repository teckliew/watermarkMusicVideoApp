//
//  ViewController.swift
//  WatermarkMusicVideo
//
//  Created by Teck Liew on 10/6/16.
//  Copyright © 2016 Teck Liew. All rights reserved.
//

import UIKit
import AVFoundation
import MobileCoreServices
import CoreMedia
import CoreImage
import MediaPlayer
import AVKit

class ViewController: UIViewController, AVPlayerViewControllerDelegate {
    
    @IBOutlet var videoLoaded: UILabel!
    @IBOutlet var audioLoaded: UILabel!
    @IBOutlet var activityMonitor: UIActivityIndicatorView!
    @IBOutlet var musicSlider: UISlider!
    @IBOutlet var musicTimeLabel: UILabel!
    @IBOutlet var previewView: UIView!
    @IBOutlet var videoDurationLabel: UILabel!
    @IBOutlet var videoMutedLabel: UILabel!
    
    var videoPlayer: AVPlayerViewController?
    var avPlayerLayer: AVPlayerLayer?
    var videoMute = true
    var video: AVAsset?
    var audioAsset: AVAsset?
    var loadedVideo = false
    var squareOrientation = true
    var musicTime = 0
    var audioPlayer = AVAudioPlayer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        activityMonitor.hidden = true
        musicSlider.setValue(0, animated: true)
        musicSlider.hidden = true
        musicTimeLabel.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //video preview
    func addVideoPlayer(url:NSURL){
        previewView.layer.sublayers?.removeAll()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
        catch {
            // report for an error
        }

        let playerItem = AVPlayerItem(URL: url)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.itemDidFinishPlaying(_:)), name:AVPlayerItemDidPlayToEndTimeNotification, object: playerItem)
        previewView.hidden = false
        videoPlayer = AVPlayerViewController() //
        videoPlayer?.delegate = self
        videoPlayer?.player = AVPlayer(playerItem: playerItem)
        avPlayerLayer = AVPlayerLayer(player: videoPlayer!.player)
        avPlayerLayer!.masksToBounds = true
        avPlayerLayer!.frame = previewView!.bounds
        avPlayerLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewView!.layer.addSublayer(avPlayerLayer!)
        videoPlayer!.player!.play()
        videoPlayer!.player?.muted = videoMute
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.muteVideo))
        previewView.addGestureRecognizer(gesture)
    }
    
    func muteVideo() {
        videoMute = !videoMute
        videoPlayer!.player?.muted = videoMute
        if videoMute {
            videoMutedLabel.text = "Muted"
        } else {
            videoMutedLabel.text = "Not muted"
        }
    }
    
    func itemDidFinishPlaying(notification:NSNotification){
        videoPlayer?.player?.seekToTime(kCMTimeZero)
        videoPlayer!.player!.play()
    }
    
    func removeVideoPlayer() {
        videoPlayer!.player!.pause()
        previewView.layer.sublayers?.removeAll()
        previewView.hidden = true
    }
    
    func savedPhotosAvailable() -> Bool {
        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) == false {
            let alert = UIAlertController(title: "Not Available", message: "No Saved Album found", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
    
    func startMediaBrowserFromViewController(viewController: UIViewController!, usingDelegate delegate : protocol<UINavigationControllerDelegate, UIImagePickerControllerDelegate>!) -> Bool {
        
        if UIImagePickerController.isSourceTypeAvailable(.SavedPhotosAlbum) == false {
            return false
        }
        
        let mediaUI = UIImagePickerController()
        mediaUI.sourceType = .SavedPhotosAlbum
        mediaUI.mediaTypes = [kUTTypeMovie as NSString as String]
        mediaUI.allowsEditing = true
        mediaUI.delegate = delegate
        presentViewController(mediaUI, animated: true, completion: nil)
        return true
    }
    
    func exportDidFinish(session: AVAssetExportSession) {
        if session.status == AVAssetExportSessionStatus.Completed {
            guard let outputURL = session.outputURL else {
                print("output url not loaded properly")
                return
            }
            PhotoAlbumUtility.saveImageInAlbum(outputURL, albumName: "Stance", completion: { (result) in
                switch result {
                case .SUCCESS:
                    dispatch_async(dispatch_get_main_queue(), {
                        print("saved to Stance album!")
                        self.video = nil
                        self.audioAsset = nil
                        self.videoLoaded.text = "Video is saved."
                        self.audioLoaded.text = "Ready for another one."
                        self.videoDurationLabel.text = "0:00"
                        self.videoLoaded.textColor = UIColor.darkGrayColor()
                        self.audioLoaded.textColor = UIColor.darkGrayColor()
                        self.musicSlider.setValue(0, animated: true)
                        self.musicSlider.hidden = true
                        self.musicTimeLabel.hidden = true
                        self.removeVideoPlayer()
                        self.audioPlayer = AVAudioPlayer()
                    })
                    break
                case .ERROR:
                    dispatch_async(dispatch_get_main_queue(), {
                        print("error saving to Stance album")
                        self.video = nil
                        self.audioAsset = nil
                        self.videoLoaded.text = "Error saving Video."
                        self.audioLoaded.text = "..."
                        self.videoDurationLabel.text = "0:00"
                        self.videoLoaded.textColor = UIColor.redColor()
                        self.audioLoaded.textColor = UIColor.redColor()
                        self.musicSlider.setValue(0, animated: true)
                        self.musicSlider.hidden = true
                        self.musicTimeLabel.hidden = true
                        self.removeVideoPlayer()
                        self.audioPlayer = AVAudioPlayer()
                    })
                    break
                case .DENIED:
                    break
                }
            })
        }
        
        activityMonitor.stopAnimating()
        activityMonitor.hidden = true
        let player = AVPlayer(URL: session.outputURL!)
        let playerController = AVPlayerViewController()
        playerController.player = player
        self.presentViewController(playerController, animated: true) {
            player.play()
        }
        
    }

    @IBAction func chooseVideo(sender: AnyObject) {
        if savedPhotosAvailable() {
            loadedVideo = true
            startMediaBrowserFromViewController(self, usingDelegate: self)
        }
    }

    @IBAction func addMusic(sender: AnyObject) {
        let mediaPickerController = MPMediaPickerController(mediaTypes: .Any)
        mediaPickerController.delegate = self
        mediaPickerController.prompt = "Select Audio"
        presentViewController(mediaPickerController, animated: true, completion: nil)
    }
    
    @IBAction func musicTimeSeek(sender: AnyObject) {
        let musicVal = musicSlider.value
        let minute = NSString(format: "%D", Int(musicVal) / 60)
        let secondInt = Int(musicVal) % 60
        var second = "00"
        if secondInt < 10 {
            second = "0\(secondInt)"
        } else {
            second = NSString(format: "%D", secondInt) as String
        }
        
        audioPlayer.currentTime = NSTimeInterval(Int(musicVal))
        audioPlayer.play()
        
        musicTime = Int(musicSlider.value)
        musicTimeLabel.text = "\(minute):\(second)"
        
        videoPlayer?.player?.seekToTime(kCMTimeZero)
    }
    
    
    @IBAction func squareToggle(sender: AnyObject) {
        squareOrientation = !squareOrientation
    }
    
    @IBAction func save(sender: AnyObject) {
        activityMonitor.startAnimating()
        activityMonitor.hidden = false
        
        guard let videoAsset = video else {
            activityMonitor.stopAnimating()
            activityMonitor.hidden = true
            videoLoaded.text = "Please pick a video."
            audioLoaded.text = "..."
            videoLoaded.textColor = UIColor.redColor()
            audioLoaded.textColor = UIColor.redColor()
            return
        }
        
        let mixComposition = AVMutableComposition()
        let compositionVideoTrack = mixComposition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: kCMPersistentTrackID_Invalid)
        let clipVideoTrack: AVAssetTrack = videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0]
        do {
            try compositionVideoTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, videoAsset.duration), ofTrack: clipVideoTrack, atTime: kCMTimeZero)
        } catch {
            print(error)
        }
        
        compositionVideoTrack.preferredTransform = videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0].preferredTransform
        
        //video frame
        let videoSize = videoAsset.tracksWithMediaType(AVMediaTypeVideo)[0].naturalSize
        let parentLayer = CALayer()
        let videoLayer = CALayer()
        parentLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
        videoLayer.frame = CGRectMake(0, 0, videoSize.width, videoSize.height)
        
        //Add watermark
        guard let stanceWatermark = UIImage(named: "stance_logo_wht") else {
            //completion(url: nil)
            print("no stance logo")
            return
        }
        guard let udefWatermark = UIImage(named: "UDEF-logo") else {
            print("no udef logo")
            return
        }
        
        //scale watermarks nicely
        let filter = CIFilter(name: "CILanczosScaleTransform")!
        filter.setValue(CIImage(image: stanceWatermark), forKey: "inputImage")
        filter.setValue(0.1, forKey: "inputScale")
        filter.setValue(1.0, forKey: "inputAspectRatio")
        let ciContext = CIContext(options:nil)
        let cgImage = ciContext.createCGImage(filter.outputImage!, fromRect:filter.outputImage!.extent)
        let scaledStanceWatermark = UIImage(CGImage: cgImage)
        
        let filter2 = CIFilter(name: "CILanczosScaleTransform")!
        filter2.setValue(CIImage(image: udefWatermark), forKey: "inputImage")
        filter2.setValue(0.05, forKey: "inputScale")
        filter2.setValue(1.0, forKey: "inputAspectRatio")
        let ciContext2 = CIContext(options:nil)
        let cgImage2 = ciContext2.createCGImage(filter2.outputImage!, fromRect: filter2.outputImage!.extent)
        let scaledUdefWatermark = UIImage(CGImage: cgImage2)
        
        //watermark sublayers positioning and size
        var watermarkXposition = CGFloat(50)
        
        if squareOrientation {
            watermarkXposition = (videoSize.width / 4)
        }
        
        let aLayer = CALayer()
        aLayer.contents = scaledStanceWatermark.CGImage
        aLayer.frame = CGRectMake(watermarkXposition - 25, videoSize.height - 65, scaledStanceWatermark.size.width, scaledStanceWatermark.size.height)
        aLayer.opacity = 0.55
        
        let bLayer = CALayer()
        bLayer.contents = scaledUdefWatermark.CGImage
        bLayer.frame = CGRectMake(watermarkXposition + 138, videoSize.height - 59.5, scaledUdefWatermark.size.width, scaledUdefWatermark.size.height)
        bLayer.opacity = 0.55
        
        
        //add all the sublayers: video, watermarks
        parentLayer.addSublayer(videoLayer)
        parentLayer.addSublayer(aLayer)
        parentLayer.addSublayer(bLayer)
        
        let videoComp = AVMutableVideoComposition()
        videoComp.renderSize = videoSize
        videoComp.frameDuration = CMTimeMake(1,30)
        videoComp.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, inLayer: parentLayer)
        
        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRangeMake(kCMTimeZero, mixComposition.duration)
        let videoTrack = mixComposition.tracksWithMediaType(AVMediaTypeVideo)[0]
        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        instruction.layerInstructions = [layerInstruction]
        videoComp.instructions = [instruction]
        
        // 3 - Audio track
        if let loadedAudioAsset = audioAsset {
            let startTime = CMTimeMake(Int64(musicTime), 1)
            
            let audioTrack1 = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)
            do {
                try audioTrack1.insertTimeRange(CMTimeRangeMake(startTime, mixComposition.duration),
                                                ofTrack: loadedAudioAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                                                atTime: kCMTimeZero)
            } catch _ {
                print("Failed to load Audio track")
            }
        }
        
        //video audio
        if !videoMute {
            let audioTrack2 = mixComposition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: 0)
            do {
                try audioTrack2.insertTimeRange(CMTimeRangeMake(kCMTimeZero, mixComposition.duration),
                                                ofTrack: videoAsset.tracksWithMediaType(AVMediaTypeAudio)[0] ,
                                                atTime: kCMTimeZero)
            } catch _ {
                print("Failed to load video Audio track")
            }
        }
        
        //file path
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let dataPath = documentsDirectory.stringByAppendingPathComponent("VideoCache")
        
        if (!NSFileManager.defaultManager().fileExistsAtPath(dataPath)) {
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(dataPath, withIntermediateDirectories: false, attributes: nil)
            } catch {
                print("Couldn't create path")
            }
        }
        let tempURL = NSURL(fileURLWithPath: dataPath)
        let completeMovieUrl = tempURL.URLByAppendingPathComponent("tether-\(NSDate()).mov")
        
        // 5 - Create Exporter
        guard let exporter = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetHighestQuality) else { return }
        exporter.outputURL = completeMovieUrl
        exporter.outputFileType = AVFileTypeQuickTimeMovie
        exporter.shouldOptimizeForNetworkUse = true
        exporter.videoComposition = videoComp
        
        // 6 - Perform the Export
        exporter.exportAsynchronouslyWithCompletionHandler() {
            dispatch_async(dispatch_get_main_queue()) { _ in
                self.exportDidFinish(exporter)
            }
        }
    }
    
}

extension ViewController: UIImagePickerControllerDelegate {
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        let mediaType = info[UIImagePickerControllerMediaType] as! NSString
        dismissViewControllerAnimated(true, completion: nil)
        
        if mediaType == kUTTypeMovie {
            let avAsset = AVAsset(URL:info[UIImagePickerControllerMediaURL] as! NSURL)
            if loadedVideo {
                video = avAsset
            }
            let seconds = Int(CMTimeGetSeconds((video?.duration)!))
            if seconds % 60 < 10 {
                videoDurationLabel.text = "\(seconds / 60):0\(seconds % 60)"
            } else {
                videoDurationLabel.text = "\(seconds / 60):\(seconds % 60)"
            }
            
            videoLoaded.text = "Video is loaded."
            videoLoaded.textColor = UIColor.greenColor()
            addVideoPlayer(info[UIImagePickerControllerMediaURL] as! NSURL)
        }
    }
    
}

extension ViewController: UINavigationControllerDelegate {
    
}

extension ViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        let selectedSongs = mediaItemCollection.items
        if selectedSongs.count > 0 {
            let song = selectedSongs[0]
            if let url = song.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL {
                audioAsset = (AVAsset(URL:url))
                dismissViewControllerAnimated(true, completion: nil)
                audioLoaded.text = "Audio is loaded."
                audioLoaded.textColor = UIColor.greenColor()
                
                
                do { try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback) } catch {}
                do { try AVAudioSession.sharedInstance().setActive(true) } catch {}
                
                do { audioPlayer = try AVAudioPlayer(contentsOfURL: url) } catch { print("can't play audio") }
                audioPlayer.prepareToPlay()
                audioPlayer.play()
                
                musicTimeLabel.text = "0:00"
                musicSlider.setValue(0, animated: true)
                musicSlider.maximumValue = Float(CMTimeGetSeconds((audioAsset?.duration)!))
                musicSlider.hidden = false
                musicTimeLabel.hidden = false
            } else {
                dismissViewControllerAnimated(true, completion: nil)
                audioLoaded.text = "Audio is not loaded."
            }
        } else {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func mediaPickerDidCancel(mediaPicker: MPMediaPickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}