//
//  VideoViewController.swift
//  VirtualMustache
//
//  Created by yuzai on 11/14/24.
//

import UIKit
import Kingfisher
import ProgressHUD
import AVKit
import Alamofire

class VideoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    
    var videos: [Video] = []
    
    private let videoManager = VideoManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Videos"
        view.backgroundColor = .white

        tableView.register(VideoCell.self, forCellReuseIdentifier: "VideoCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 130
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .white

        refreshControl.attributedTitle = NSAttributedString(string: "Loading...")
        refreshControl.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        fetchVideos()
    }
    
    // MARK: - Data load and Refresh

    @objc private func refreshTableView() {
        fetchVideos()
    }
    
    private func fetchVideos() {
        videoManager.fetchVideos { [weak self] result in
            DispatchQueue.main.async {
                self?.refreshControl.endRefreshing()
                switch result {
                case .success(let videos):
                    self?.videos = videos
                    self?.tableView.reloadData()
                case .failure(let error):
                    print("Failed to fetch videos: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return videos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        print("Loading cell for row \(indexPath.row)")
        let cell = tableView.dequeueReusableCell(withIdentifier: "VideoCell", for: indexPath) as! VideoCell
        let video = videos[indexPath.row]
        cell.configure(with: video)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let video = videos[indexPath.row]
        let playerViewController = videoManager.videoPlayerController(for: video)
        navigationController?.pushViewController(playerViewController!, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let video = videos[indexPath.row]
        if editingStyle == .delete {
            videoManager.deleteVideo(for: video) { _ in
                self.tableView.reloadData()
            }
        }
    }
}
