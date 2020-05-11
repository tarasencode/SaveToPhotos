//
//  File.swift
//  Save to Photos
//
//  Created by oleG on 09/05/2020.
//  Copyright © 2020 oleG. All rights reserved.
//
import Foundation

struct File {
    let URL: URL
    
    var selected: Bool = true
    
    var name: String {
        return URL.lastPathComponent
    }
    
    var mediaType: MediaType {
        switch "hevc:mp4:mov".contains(URL.pathExtension.lowercased()){
        case true: return .video
        case false: return .photo
        }
    }
    
    static let rootAlbumName = "PhotoImport"
    
    var album: String {
        guard URL.pathComponents[URL.pathComponents.count - 2] != "Documents" else {
            return File.rootAlbumName
        }
        return URL.pathComponents[URL.pathComponents.count - 2]
    }
    
    init(fileURL: URL) {
        self.URL = fileURL
    }
    
    mutating func toggleSelection() {
        selected.toggle()
    }
    
    
}
