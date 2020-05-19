//
//  File.swift
//  Save to Photos
//
//  Created by oleG on 09/05/2020.
//  Copyright © 2020 oleG. All rights reserved.
//
import Foundation

enum MediaType {
    case photo
    case video
}

class File {
    let URL: URL    
    var name: String
    var mediaType: MediaType
    var album: String
    var shortPath: String
    
    static let rootAlbumName = "Save Photos"
    
    init(fileURL: URL, shortPath: String) {
        self.URL = fileURL
        self.shortPath = shortPath
        self.name = URL.lastPathComponent
        
        self.mediaType = ("hevc:mp4:mov".contains(URL.pathExtension.lowercased())) ? .video : .photo
        self.album = (URL.pathComponents[URL.pathComponents.count - 2] == "Documents") ? File.rootAlbumName : URL.pathComponents[URL.pathComponents.count - 2]        
    }
}
