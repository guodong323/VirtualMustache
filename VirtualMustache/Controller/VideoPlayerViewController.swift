//
//  VideoPlayerViewController.swift
//  VirtualMustache
//
//  Created by yuzai on 11/17/24.
//

import UIKit
import AVKit

class VideoPlayerViewController: UIViewController {
    
    private var videoURL: URL?

    init(videoURL: URL) {
        self.videoURL = videoURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.isTabBarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.tabBarController?.isTabBarHidden = false
    }


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white

        guard let videoURL = videoURL else {
            print("Invalid video URL")
            dismiss(animated: true, completion: nil)
            return
        }

        let player = AVPlayer(url: videoURL)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player

        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        playerViewController.view.frame = view.bounds
        playerViewController.didMove(toParent: self)

        player.play()
    }
}
