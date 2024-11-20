//
//  VideoCell.swift
//  VirtualMustache
//
//  Created by yuzai on 11/14/24.
//

import Foundation
import UIKit
import Kingfisher


class VideoCell: UITableViewCell {
    private let thumbnailImageView = UIImageView()
    private let titleLabel = UILabel()
    private let uploadDateLabel = UILabel()
    private let tagLabel = UILabel()
    private let durationLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        thumbnailImageView.contentMode = .scaleAspectFit
        thumbnailImageView.clipsToBounds = true
        thumbnailImageView.layer.cornerRadius = 8
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.numberOfLines = 1
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        uploadDateLabel.font = UIFont.systemFont(ofSize: 14)
        uploadDateLabel.textColor = .secondaryLabel
        uploadDateLabel.translatesAutoresizingMaskIntoConstraints = false

        tagLabel.font = UIFont.systemFont(ofSize: 14)
        tagLabel.textColor = .systemBlue
        tagLabel.backgroundColor = UIColor.systemGray6
        tagLabel.textAlignment = .center
        tagLabel.layer.cornerRadius = 8
        tagLabel.clipsToBounds = true
        tagLabel.translatesAutoresizingMaskIntoConstraints = false

        durationLabel.font = UIFont.systemFont(ofSize: 14)
        durationLabel.textColor = .secondaryLabel
        durationLabel.textAlignment = .right
        durationLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(thumbnailImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(uploadDateLabel)
        contentView.addSubview(tagLabel)
        contentView.addSubview(durationLabel)


        NSLayoutConstraint.activate([

            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            thumbnailImageView.widthAnchor.constraint(equalToConstant: 180),
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),


            titleLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),


            uploadDateLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16),
            uploadDateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            uploadDateLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),


            tagLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16), // 左对齐
            tagLabel.topAnchor.constraint(equalTo: uploadDateLabel.bottomAnchor, constant: 8),
            tagLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16), // 添加右对齐以保持一致
            tagLabel.heightAnchor.constraint(equalToConstant: 30),


            durationLabel.leadingAnchor.constraint(equalTo: thumbnailImageView.trailingAnchor, constant: 16), // 左对齐，与 tagLabel 一致
            durationLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            durationLabel.topAnchor.constraint(equalTo: tagLabel.bottomAnchor, constant: 8)
        ])

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with video: Video) {
        let imageUrl = URL(string: "http://47.89.217.2:9527/video/image/\(video.id)")
        thumbnailImageView.kf.setImage(
            with: imageUrl,
            placeholder: UIImage(named: "placeholder")
        )
        
        titleLabel.text = video.title
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // 确保日期格式的一致性
        uploadDateLabel.text = dateFormatter.string(from: video.createdAt)
        
        tagLabel.text = video.tag
        
        durationLabel.text = "Duration: \(video.videoDuration) seconds"
    }
}
