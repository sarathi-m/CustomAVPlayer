//
//  ViewController.swift
//  AVPlayerTest
//
//  Created by Parth Sarathi on 12/8/21.
//

import UIKit
import CoreMedia

let videoUrl = "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8"

class ViewController: UIViewController, PlayerDelegate {

    @IBOutlet weak var playerView: CustomAVPlayerView!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        setupCustomAVPlayerView()
    }
    
    func setupCustomAVPlayerView() {
        guard let url = URL(string: videoUrl) else {
            print("Invalid URL")
            return
        }
        
        playerView.play(with: url)
        playerView.delegate = self
    }
    
    func playStarted() {
        print("Play Started")
        activityIndicator.stopAnimating()
    }
    
    func playFinished() {
        print("Play Finished")
    }
    
    func halfSecondPeriodicObserver(time: CMTime) {
        print("Current PlayHead", time.seconds)
    }
    
}

