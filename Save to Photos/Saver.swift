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
    let fileURL: URL
    var selected: Bool = true
    
    var fileName: String {
       return fileURL.lastPathComponent
    }
    var fileType: String {
        return fileURL.pathExtension.lowercased()
    }
    
    var mediaType: MediaType {
        switch "hevc:mp4:mov".contains(fileURL.pathExtension.lowercased()){
        case true: return .video
        case false: return .photo
        }

    }
    var album: String {
        return fileURL.pathComponents[fileURL.pathComponents.count - 2]
    }
    
    init(fileURL: URL) {
        self.fileURL = fileURL
    }
    
    mutating func changeState() {
        selected.toggle()        
    }
}

class Saver {
    
    //var data = [[File](),[File]()]
    var data = [[File]]()
    var filesCount: Int64 {
        return Int64(data.flatMap { $0 }.count)
    }
    var canceled = false
    
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
//            print(fileURL)
            let newFile = File(fileURL: fileURL)
            data[albumId].append(newFile)
//            print("\(fileAlbum) : \(fileURL)") // удалить!!!!!!!!!!!
            
        }
    }
    
    func getFileName(_ albumId:Int, _ fileId:Int) -> String {
        let file = data[albumId][fileId]
        return file.fileName
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
            return " — \(fileCount)"
        } else {
            return "\(file.album) — \(fileCount)"
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
//        NSLog("➡️adding \(file.fileName)")
        do {
            try PHPhotoLibrary.shared().performChangesAndWait({
                // Request creating an asset from the image.
                var creationRequest: PHAssetChangeRequest
                switch file.mediaType {
                    case .photo: creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: file.fileURL)!
                    case .video: creationRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: file.fileURL)!
                    
                }

                // Request editing the album.
                guard  let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
                    else {
                        print("album \(file.album) is not exitst (File: \(file.fileName))")
                        return }
                // Get a placeholder for the new asset and add it to the album editing request.
//                NSLog("➡️new asset request \(file.fileName)")
                addAssetRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
                
            })
        } catch { print("there is an error in asset")}
        
    }
    
    
    func moveToCameraRoll(progressView: UIProgressView, cancelButton: UIBarButtonItem) {
        // добавить удаление файла из расшареной папки?
        
        let progress = Progress(totalUnitCount: filesCount)
        var processed = 0
        var skipped = 0
        for album in data {
            guard !canceled else { break }
            var currentAlbum: PHAssetCollection?
            for file in album {
                guard !canceled else { break }
                guard file.selected else {
                    skipped += 1
//                    print("skipped \(file.album) \(file.fileName)")
                    continue
                }
                if currentAlbum == nil {
//                    print("acessing album")
                    currentAlbum = findAssetCollection(album: album[0].album)
                }
                
                DispatchQueue.global(qos: .background).async {
                    
                    self.addAsset(file: file, album: currentAlbum!)
                    DispatchQueue.main.async {
                        processed += 1
                        // обновляем прогресс
                        print("[ \(processed) of \(Int(self.filesCount) - skipped) ] \(file.fileName) moved to photos")
                        if !self.canceled {
                            progress.completedUnitCount += 1
                            progressView.setProgress(Float(progress.fractionCompleted), animated: true )                            
                        } else {
                            progressView.progress = 100
                            print("canceling")
                        }
                        if processed + skipped == self.filesCount {
                            progressView.progress = 100
                            cancelButton.title = "Save"
                            print("finished")
                        }
                    }
                }
            }
        }
    }
    
    
}




//func aaddAsset(file: File, album: PHAssetCollection) {
//    NSLog("➡️adding \(file.fileName)")
//    PHPhotoLibrary.shared().performChanges({
//        // Request creating an asset from the image.
//        let creationRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: file.fileURL)!
//
//        // Request editing the album.
//        guard  let addAssetRequest = PHAssetCollectionChangeRequest(for: album)
//            else {
//                print("album \(file.album) is not exitst (File: \(file.fileName))")
//                return }
//        // Get a placeholder for the new asset and add it to the album editing request.
//        NSLog("➡️new asset request \(file.fileName)")
//        addAssetRequest.addAssets([creationRequest.placeholderForCreatedAsset!] as NSArray)
//
//    }, completionHandler: { success, error in
//        if !success { NSLog("➡️error creating asset \(file.fileName): \(error)") } else { NSLog("➡️added \(file.fileName)") }
//    })
//}

//    func aaddAssetCollection(album: String) {
//        PHPhotoLibrary.shared().performChanges({
//            // Request creating an asset from the image.
//            NSLog("album request - \(album)")
//            let creationRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album)
//
//        }, completionHandler: { success, error in
//            if !success {
//                NSLog("error creating asset collecton: \(error)")
//
//            } else {
//                NSLog("album added - \(album)")
//
//            }
//        })
//    }







//    @discardableResult mutating func getFiles() -> [File] {
//        do {
//            let filesURL = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
//
//            getAll(directoryURL: filesURL)
//
//            let files = try FileManager.default.contentsOfDirectory(at: filesURL, includingPropertiesForKeys: [], options:  [.skipsHiddenFiles, .skipsSubdirectoryDescendants])
//
//            let typesAllowed = "jpg:jpeg"
//
//
//            for file in files {
//                let fileType = file.pathExtension.lowercased()
//
//                guard typesAllowed.contains(fileType) else { continue }
//                let newFile = File(fileName: file.lastPathComponent, fileURL: file, fileType: fileType)
//                fileList.append(newFile)
//            }
//
//            return fileList
//
//        } catch {
//
//            print("❌ \(error)") // добавить нормальную обработку ошибок
//            return []
//        }
//    }






//                PHPhotoLibrary.shared().performChanges({
//                    let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: file.fileURL)
//                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: workingAlbum)
//                    if let assetPlaceholder = assetRequest?.placeholderForCreatedAsset {
//                        let assetPlaceholders: NSArray = [assetPlaceholder]
//                        albumChangeRequest!.addAssets(assetPlaceholders)
//                    }
//
//                }, completionHandler: nil)




// проверяем есть ли альбом, и создаем если нужно
//var workingAlbum: PHAssetCollection!
//print("работаем с \(album[0].album)")
//if album[0].album != "Documents" {
//    let options = PHFetchOptions()
//    options.predicate = NSPredicate(format: "title = %@", album[0].album)
//    let collection = PHAssetCollection.fetchAssetCollections(with: .album,
//                                                             subtype: .any,
//                                                             options: options)
//    if let albumAsset = collection.firstObject {
//        // Альбом уже есть, можем его использовать
//        workingAlbum = albumAsset
//        print("\(album[0].album) уже был создан")
//    } else {
//        // Альбома нет, создаем
//        print("\(album[0].album) альбома нет")
//        var placeholder: PHObjectPlaceholder?
//        PHPhotoLibrary.shared().performChanges({
//            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: album[0].album)
//            placeholder = request.placeholderForCreatedAssetCollection
//        }, completionHandler: nil) /*{ (success, error) -> Void in
//
//         if success { */
//        if let id = placeholder?.localIdentifier {
//            let fetchResult = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [id], options: nil)
//            if let albumAsset = fetchResult.firstObject {
//                workingAlbum = albumAsset
//                print("\(album[0].album)  создается")
//            }
//            print("\(album[0].album) не создался создается")
//        } else { print("не проходит if let id = placeholder?.localIdentifier  ")}
//        /* } else {
//         print("!!!! Error: \(error?.localizedDescription)")
//         }
//         }) */
//}
