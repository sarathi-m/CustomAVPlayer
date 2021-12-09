//
//  CustomAVPlayerView.swift
//  AVPlayerTest
//
//  Created by Parth Sarathi on 12/8/21.
//

import Foundation
import AVFoundation
import UIKit

@objc protocol PlayerDelegate: AnyObject {
    func playStarted()
    func playFinished()
    func halfSecondPeriodicObserver(time: CMTime)
}

private let TIME_SCALE = CMTimeScale(NSEC_PER_SEC)

class CustomAVPlayerView: UIView {
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }
        
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    private var playerItemContext = 0
    private var playerItem: AVPlayerItem?
    private var timeObserverToken: Any?
    private var seekTo: Int64?

    weak var delegate: PlayerDelegate?

    //MARK: AVPlayer Methods
    func play(with url: URL, seekToSeconds: Int64? = nil) {
        setUpPlayerItem(with: url)
        
        //seek to seconds if available
        self.seekTo = seekToSeconds
    }
    
    private func setUpPlayerItem(with url: URL) {
        let asset = AVAsset(url: url)
        playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["playable", "hasProtectedContent"])

        setupObserver(for: playerItem)
        
        DispatchQueue.main.async { [weak self] in
            self?.setupPlayer(playerItem: self?.playerItem)
        }
    }

    private func setupPlayer(playerItem: AVPlayerItem?) {
        player = AVPlayer(playerItem: playerItem!)
        let time = CMTime(seconds: 0.5, preferredTimescale: TIME_SCALE)
        
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: time, queue: .main) { [weak self] time in
            self?.delegate?.halfSecondPeriodicObserver(time: time)
        }
    }
    
    //MARK: Observer Methods
    private func setupObserver(for playerItem: AVPlayerItem?) {
        
        playerItem?.addObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), options: [.old, .new], context: &playerItemContext)
        playerItem?.addObserver(self, forKeyPath:  #keyPath(AVPlayerItem.timebase), options: [.old, .new], context: &playerItemContext)
        
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinish(_:)), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            switch status {
                case .readyToPlay:
                    player?.play()
                    
                    //Seek to last to check finished play
                    if let time = seekTo {
                        player?.seek(to: CMTimeMake(value: time, timescale: 1))
                    }
                case .failed, .unknown:
                    print(status)
                default:
                    print("default")
            }
        } else if keyPath == #keyPath(AVPlayerItem.timebase) {
            if let rate = player?.rate, rate > 0 {
                delegate?.playStarted()
            }
        }
    }
    
    @objc private func playerDidFinish(_ notification: Notification) {
        delegate?.playFinished()
     }
    
    //MARK: Deinit
    deinit {
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status))
        playerItem?.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.timebase))
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
}
