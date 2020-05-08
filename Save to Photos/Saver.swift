//
//  SaveToCameraRoll.swift
//  Save to Photos
//
//  Created by oleG on 04/05/2020.
//  Copyright © 2020 oleG. All rights reserved.
//

import Foundation
import Photos

enum MediaType {
    case photo
    case video
}

struct File {
    let URL: URL
    
    var selected: Bool = true /*{
        switch Int.random(in: 0...1) {
        case 0:
            return true
        default:
            return false
        }
    } */
    
    var name: String {
       return URL.lastPathComponent
    }
    
    var mediaType: MediaType {
        switch "hevc:mp4:mov".contains(URL.pathExtension.lowercased()){
            case true: return .video
            case false: return .photo
        }
    }
    
    var album: String {
        guard URL.pathComponents[URL.pathComponents.count - 2] != "Documents" else {
            return "PhotoImport"
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

class Saver {

    var data = [[File]]()
    
    var filesCount: Int64 {
        return Int64(data.flatMap { $0 }.count)
    }
    var canceled = false
    
    var currentAlbum: PHAssetCollection? = nil
    
    func getFiles() {        
        let fileManager = FileManager()
        let directoryURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let resourceKeys = Set<URLResourceKey>([.isRegularFileKey])
        let directoryEnumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!
        let typesAllowed = "heif:jpeg:jpg:raw:png:gif:tiff:hevc:mp4:mov"
        var prevAlbum = ""
        var albumId = -1

        
        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                resourceValues.isRegularFile!,
                typesAllowed.contains(fileURL.pathExtension.lowercased())
            else { continue }
            
            let fileAlbum = fileURL.pathComponents[fileURL.pathComponents.count - 2]
            if prevAlbum != fileAlbum {
                prevAlbum = fileAlbum
                albumId += 1
                data.append([File]())
            }
//            print(URL)
            let newFile = File(fileURL: fileURL)
            data[albumId].append(newFile)
//            print("\(fileAlbum) : \(URL)") // удалить!!!!!!!!!!!
            
        }
    }
    
    func getFileName(_ albumId:Int, _ fileId:Int) -> String {
        let file = data[albumId][fileId]
        return file.name
    }
    
    func getAlbumName(_ albumId: Int) -> String{
        let file = data[albumId][0]
        
        var fileCount: String
        if data[albumId].count == 1 {
            fileCount = "\(data[albumId].count) file"
        } else {
            fileCount = "\(data[albumId].count) files"
        }
        
        if file.album == "Documents" {
            return "/ – \(fileCount)"
        } else {
            return "\(file.album) – \(fileCount)"
        }
    }
    
    func isSelected(_ albumId:Int, _ fileId:Int) -> Bool {
        let file = data[albumId][fileId]
        return file.selected
    }
    
    func addAssetCollection(album: String) {
        do {
            try PHPhotoLibrary.shared().performChangesAndWait({
                // Request creating an asset from the image.
//                NSLog("album request - \(album)")
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album)
                
            })
        }
        catch { print("there is an error in collection")}
    }
    
    func findAssetCollection(album: String) -> PHAssetCollection{
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "title = %@", album)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album,
                                                                 subtype: .any,
                                                                 options: options)
        if let albumAsset = collection.firstObject {
            return albumAsset
        } else {
            addAssetCollection(album: album)
            return findAssetCollection(album: album)
        }
        
    }
    
    func addAsset(file: File, album: PHAssetCollection) {
//        NSLog("➡️adding \(file.name)")
        do {
            try PHPhotoLibrary.shared().performChangesAndWait({
                // Request creating an asset from the image.
                var creationRequest: PHAssetChangeRequest
                switch file.mediaType {
                    case .photo: creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: file.URL)!
                    case .video: creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: file.URL)!
                    
                }

                // Request editing the album.
                guard  let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
                    else {
                        print("album \(file.album) is not exitst (File: \(file.name))")
                        return }
                // Get a placeholder for the new asset and add it to the album editing request.
//                NSLog("➡️new asset request \(file.name)")
                addAssetRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                
            })
        } catch { print("there is an error in asset")}
        
    }
    
}
