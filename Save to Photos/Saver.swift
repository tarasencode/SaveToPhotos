//
//  SaveToCameraRoll.swift
//  Save to Photos
//
//  Created by oleG on 04/05/2020.
//  Copyright © 2020 oleG. All rights reserved.
//

import Foundation
import Photos

enum answer {
    case allowed
    case denied
}

class Saver {
    var data = [[File]]()
    var filesCount: Int64 {
        return Int64(data.flatMap { $0 }.count)
    }
    var canceled = false
    var currentAlbum: PHAssetCollection? = nil
    
    var documentsURL: URL
    
    func executePermissionRequest(completionHandler: @escaping (answer) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            switch status {
            case .authorized:
                completionHandler(.allowed)
            default:
                completionHandler(.denied)
            }
        }
    }
    
    init() {
        let fileManager = FileManager()
        documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    func getFiles() {
        NSLog("get files")
        data = [[File]]()
        var tempData = [File]()
        let fileManager = FileManager()
        print(documentsURL) //MARK: delete
        let resourceKeys = Set<URLResourceKey>([.isRegularFileKey])
        let directoryEnumerator = fileManager.enumerator(at: documentsURL, includingPropertiesForKeys: Array(resourceKeys), options: .skipsHiddenFiles)!
        let typesAllowed = "heif:jpeg:jpg:raw:png:gif:tiff:hevc:mp4:mov"
        var prevAlbum = ""
        var albumId = -1
        var rootId:Int?

        
        for case let fileURL as URL in directoryEnumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
                resourceValues.isRegularFile!,
                typesAllowed.contains(fileURL.pathExtension.lowercased())
            else { continue }
            
            let shortPath = fileURL.relativePath.replacingOccurrences(of: documentsURL.relativePath, with: "")
            tempData.append(File(fileURL: fileURL, shortPath: shortPath))
        }
        
        for file in tempData.sorted(by: {$0.shortPath < $1.shortPath }) {
            let fileAlbum = file.URL.pathComponents[file.URL.pathComponents.count - 2]
            if prevAlbum != fileAlbum {
                prevAlbum = fileAlbum
                albumId += 1
                data.append([File]())
                if fileAlbum == "Documents" {
                    rootId = albumId
                }
            }            
            data[albumId].append(file)
        }
        if rootId != nil {
            data.insert(data.remove(at: rootId!), at: 0)
        }
    }
    
    func getFileName(_ albumId:Int, _ fileId:Int) -> String {
        let file = data[albumId][fileId]
        return file.name
    }
    
    func getAlbumTitle(_ albumId: Int) -> String{
        let albumName = (data[albumId][0].album == File.rootAlbumName) ? "Main Folder – " : "\(data[albumId][0].album) – "
        let countString = "\(data[albumId].count) "
        let filesString = (data[albumId].count > 1) ? "files" : "file"
        
        return albumName + countString + filesString
    }
    
    
    func addAssetCollection(album: String) {
        do {
            try PHPhotoLibrary.shared().performChangesAndWait({
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
//        NSLog("adding \(file.name)")
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
//                NSLog("new asset request \(file.name)")
                addAssetRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                
            })
        } catch { print("there is an error in asset")}
        
    }
    
    func deleteFile(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
        } catch  { print(error) }
    }
    
    func deleteFolders() {
        do {
            let contents = try FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: [.skipsSubdirectoryDescendants])
            for folder in contents {
                deleteFile(at: folder)
            }
        } catch { print(error) }
    }
}
