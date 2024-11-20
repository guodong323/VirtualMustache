//
//  VideoManager.swift
//  VirtualMustache
//
//  Created by yuzai on 11/14/24.
//

import Foundation
import Alamofire
import UIKit


struct APIResponse<T: Decodable>: Decodable {
    let code: Int
    let msg: String
    let data: T
}

struct Video: Decodable {
    let id: Int
    let createdAt: Date
    let updatedAt: Date
    let title: String
    let coverPath: String
    let videoPath: String
    let tag: String
    let videoDuration: Double
    let videoSize: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case createdAt
        case updatedAt
        case title
        case coverPath
        case videoPath
        case tag
        case videoDuration
        case videoSize
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        coverPath = try container.decode(String.self, forKey: .coverPath)
        videoPath = try container.decode(String.self, forKey: .videoPath)
        tag = try container.decode(String.self, forKey: .tag)

        if let durationString = try? container.decode(String.self, forKey: .videoDuration),
           let duration = Double(durationString) {
            videoDuration = duration
        } else if let durationDouble = try? container.decode(Double.self, forKey: .videoDuration) {
            videoDuration = durationDouble
        } else {
            videoDuration = 0.0
        }
        videoSize = try container.decode(Int.self, forKey: .videoSize)
        
       
        let createdAtFormatter = DateFormatter()
        createdAtFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        createdAtFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let updatedAtFormatter = ISO8601DateFormatter()
        updatedAtFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let createdAtString = try container.decode(String.self, forKey: .createdAt)
        if let date = createdAtFormatter.date(from: createdAtString) {
            createdAt = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt, in: container, debugDescription: "Cannot decode date string: \(createdAtString)")
        }
        
        let updatedAtString = try container.decode(String.self, forKey: .updatedAt)
        if let date = updatedAtFormatter.date(from: updatedAtString) {
            updatedAt = date
        } else {
            throw DecodingError.dataCorruptedError(forKey: .updatedAt, in: container, debugDescription: "Cannot decode date string: \(updatedAtString)")
        }
    }
}

class VideoManager {
    
    func uploadVideoData(
        videoData: Data,
        coverData: Data,
        title: String,
        tag: String,
        createdAtData: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        let uploadURL = "http://47.89.217.2:9527/upload"

        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(
                    videoData,
                    withName: "file",
                    fileName: "video.mp4",
                    mimeType: "video/mp4"
                )
                
                multipartFormData.append(
                    coverData,
                    withName: "cover",
                    fileName: "cover.jpg",
                    mimeType: "image/jpeg"
                )
                
                if let titleData = title.data(using: .utf8) {
                    multipartFormData.append(titleData, withName: "title")
                }
                if let tagData = tag.data(using: .utf8) {
                    multipartFormData.append(tagData, withName: "tag")
                }
                if let createdAtData = createdAtData.data(using: .utf8) {
                    multipartFormData.append(createdAtData, withName: "createdAt")
                }
            },
            to: uploadURL,
            method: .post
        )
        .uploadProgress { progress in
            print("Upload Progress: \(progress.fractionCompleted)")
        }
        .response { response in
            switch response.result {
            case .success(let data):
                if let jsonData = data,
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("Upload Success: \(jsonString)")
                    completion(.success(jsonString))
                } else {
                    completion(.success("Upload succeeded with no response data"))
                }
            case .failure(let error):
                print("Upload Failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }

    
    func fetchVideos(completion: @escaping (Result<[Video], Error>) -> Void) {
        let url = "http://47.89.217.2:9527/video/videos"
        
        AF.request(url, method: .get)
        .validate()
        .responseDecodable(of: APIResponse<[Video]>.self) { response in
            switch response.result {
            case .success(let apiResponse):
                completion(.success(apiResponse.data))
            case .failure(let error):
                if let responseData = response.data,
                   let jsonString = String(data: responseData, encoding: .utf8) {
                    print("Failed to decode. Raw Response Data:\n\(jsonString)")
                    print("Error details: \(error)")
                    
                    // 尝试打印更详细的错误信息
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .dataCorrupted(let context):
                            print("Data corrupted: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("Key not found: \(key), context: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("Type mismatch: expected \(type), context: \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("Value not found: expected \(type), context: \(context.debugDescription)")
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                }
                completion(.failure(error))
            }
        }
    }
    
    func videoPlayerController(for video: Video) -> VideoPlayerViewController? {
        guard let url = URL(string: "http://47.89.217.2:9527/video/play/\(video.id)") else {
            print("Invalid video URL: \(video.id)")
            return nil
        }
        return VideoPlayerViewController(videoURL: url)
    }
    
    func deleteVideo(for video: Video, completion: @escaping (Result<Void, Error>) -> Void) {
        let url = "http://47.89.217.2:9527/video/\(video.id)"
        AF.request(url, method: .delete).validate().response { response in
            switch response.result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}
