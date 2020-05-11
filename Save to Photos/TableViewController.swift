//
//  TableViewController.swift
//  Save to Photos
//
//  Created by oleG on 04/05/2020.
//  Copyright © 2020 oleG. All rights reserved.
//

import UIKit


class TableViewController: UITableViewController {
    @IBOutlet var progressView: UIProgressView!
    
    @IBOutlet var emptyView: UIView!
    @IBOutlet var mainView: UITableView!
    
    
    @IBAction func supportPressed(_ sender: Any) {
        guard let url = URL(string: "https://support.apple.com/en-us/HT201301") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBOutlet var barButton: UIBarButtonItem!
    @IBAction func saveButtonPressed(_ sender: Any) {
        if barButton.title == "Save" {
            svr.canceled = false
            progressView.progress = 0
            progressView.isHidden = false
            barButton.title = "Cancel"
            moveToPhotos()
        } else {
            svr.canceled = true
            progressView.isHidden = true
            barButton.title = "Save"
        }
    }
    
    func selectAll() {
        
    }
    
    func deselectAll() {
        
    }
    
    func moveToPhotos() {
        let progress = Progress(totalUnitCount: svr.filesCount)
        var totalProcessed = 0
        var totalSkipped = 0

        let serialQueue = DispatchQueue(label: "moving.queue")
        serialQueue.async {
            let svr = self.svr
            for album in svr.data {
                guard !svr.canceled else { break }
                svr.currentAlbum = nil
                var photosProcessed = 0
                for file in album {
                    guard !svr.canceled else { break }
                    guard file.selected else {
                        totalSkipped += 1
                        progress.completedUnitCount += 1
    //                    print("skipped \(file.album) \(file.name)")
                        continue
                    }
                    if svr.currentAlbum == nil {
    //                    print("acessing album")
                        svr.currentAlbum = svr.findAssetCollection(album: file.album)
                    }
                    
                    svr.addAsset(file: file, album: svr.currentAlbum!)
                    photosProcessed += 1
                    totalProcessed += 1
                    
                    
                    DispatchQueue.main.async {
                        // delete file
                        svr.deleteFile(at: file.URL)
                        
                        // delete folder if it's empty and not root
                        if photosProcessed == album.count,
                            file.album != File.rootAlbumName {
                            svr.deleteFile(at: file.URL.deletingLastPathComponent())
                        }
                        
                        print("[ \(totalProcessed) of \(Int(svr.filesCount) - totalSkipped) ] \(file.name) moved to photos")
                        
                        if !self.svr.canceled {
                            progress.completedUnitCount += 1
                            self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                        } else {
                            self.progressView.isHidden = true
                            self.barButton.title = "Save"
                            print("cancel")
                        }
                        if totalProcessed + totalSkipped == svr.filesCount {
                            svr.getFiles()
                            self.tableView.reloadData()
                            self.barButton.title = "Save"
                            let alert = UIAlertController(title: "Done", message: "\(totalProcessed) file(s) was moved to Photos!", preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                            self.present(alert, animated: true)
                            
                        }
                    }
                    
                }
            }
        }
    }
    
    var svr = Saver()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        svr.getFiles()


    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if svr.data.count < 1 {
            tableView.backgroundView = emptyView
            tableView.separatorStyle = .none
            navigationItem.rightBarButtonItem?.isEnabled = false
            navigationItem.leftBarButtonItem?.isEnabled = false
        }
        return svr.data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return svr.data[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        // Configure the cell...
        switch svr.isSelected(indexPath.section, indexPath.row) {
        case true:
            cell.accessoryType = .checkmark
        case false:
            cell.accessoryType = .none
        }
        cell.textLabel?.text = svr.getFileName(indexPath.section,indexPath.row)
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        svr.data[indexPath.section][indexPath.row].toggleSelection()
        tableView.reloadData()

    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < svr.data.count {
            return svr.getAlbumName(section)
        }
        
        return nil
    }
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}






//        let alert = UIAlertController(title: "SaveToPhotos", message: "\(i) files was saved to Camera Roll!", preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
//        self.present(alert, animated: true)
//


//DispatchQueue.global(qos: .background).async {
//    self.svr.addAsset(file: file, album: self.svr.currentAlbum!)
//
//    DispatchQueue.main.async {
//        processed += 1
//        // обновляем прогресс
//        print("[ \(processed) of \(Int(self.svr.filesCount) - skipped) ] \(file.name) moved to photos")
//        if !self.svr.canceled {
//            progress.completedUnitCount += 1
//            self.progressView.setProgress(Float(progress.fractionCompleted), animated: true )
//        } else {
//            self.stopMoving()
//            print("canceling")
//        }
//        if processed + skipped == self.svr.filesCount {
//            self.progressView.progress = 100
//            self.barButton.title = "Save"
//            print("finished")
//        }
//    }
//}
