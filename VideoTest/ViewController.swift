//
//  ViewController.swift
//  VideoTest
//
//  Created by altaf on 02/11/2024.
//

import UIKit
import RangeUISlider
import AVFoundation
import Photos
import CoreImage
class ViewController: UIViewController ,RangeUISliderDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    func rangeChangeFinished(event: RangeUISliderChangeFinishedEvent) {
        startValue = event.minValueSelected
        endValue = event.maxValueSelected
    }

    public var startValue: CGFloat = 0.0
    public var endValue: CGFloat = 0.0

    @IBOutlet weak var videoPreview: UIView!
    @IBOutlet weak var cropSlider: RangeUISlider!
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    var videoURL: URL?
    
    
    @IBAction func loadVideo(_ sender: Any) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.mediaTypes = ["public.movie"]
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }
    @IBAction func applyFilter(_ sender: Any) {
        guard let url = videoURL else { return }
        
        let asset = AVURLAsset(url: url)
        let composition = AVMutableVideoComposition(asset: asset) { request in
            let source = request.sourceImage.clampedToExtent()
            let filter = CIFilter(name: "CISepiaTone")!
            filter.setValue(source, forKey: kCIInputImageKey)
            filter.setValue(1.0, forKey: kCIInputIntensityKey)
            
            if let output = filter.outputImage?.cropped(to: request.sourceImage.extent) {
                request.finish(with: output, context: nil)
            } else {
                request.finish(with: NSError(domain: "FilterError", code: 0, userInfo: nil))
            }
        }
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.videoComposition = composition
        player?.replaceCurrentItem(with: playerItem)
        player?.play()
    }
    
    @IBAction func trimVideo(_ sender: Any) {
        guard let url = videoURL else { return }

        let asset = AVURLAsset(url: url)
        let composition = AVMutableComposition()
        
        guard let videoTrack = asset.tracks(withMediaType: .video).first else { return }
        
        let start = CMTime(seconds: startValue, preferredTimescale: 20)
        let end = CMTime(seconds: endValue, preferredTimescale: 20)
        
        let timeRange = CMTimeRange(start: start, end: end)
        
        do {
            let compositionTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
            try compositionTrack?.insertTimeRange(timeRange, of: videoTrack, at: .zero)
            
            // Preview the trimmed video
            let playerItem = AVPlayerItem(asset: composition)
            player?.replaceCurrentItem(with: playerItem)
            player?.play()
            
        } catch {
            print("Error trimming video: \(error)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cropSlider.delegate = self
    }
    
    func setupVideoPlayer(with url: URL) {
        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = videoPreview.bounds
        videoPreview.layer.addSublayer(playerLayer!)
        player?.play()

        var duration = (player?.currentItem?.asset.duration)!;
        let seconds = CMTimeGetSeconds(duration);
        
        cropSlider.scaleMinValue = 0.0
        cropSlider.scaleMaxValue = seconds
        
        cropSlider.scaleMinValue = 0.0
        cropSlider.defaultValueRightKnob = seconds
        
        cropSlider.isHidden = false
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let videoURL = info[.mediaURL] as? URL {
            self.videoURL = videoURL
            setupVideoPlayer(with: videoURL)
        }
        picker.dismiss(animated: true, completion: nil)
    }
}
