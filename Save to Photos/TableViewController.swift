//
//  TableViewController.swift
//  Save to Photos
//
//  Created by oleG on 04/05/2020.
//  Copyright © 2020 oleG. All rights reserved.
//

import UIKit


class TableViewController: UITableViewController {
    var svr = Saver()
    
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var emptyView: UIView!
    @IBOutlet var errorView: UIView!
    
    
    @IBAction func supportPressed(_ sender: Any) {
        guard let url = URL(string: "https://support.apple.com/en-us/HT201301") else { return }
        UIApplication.shared.open(url)
    }
    
    @IBOutlet var refreshButton: UIBarButtonItem!
    @IBOutlet var saveButton: UIBarButtonItem!
    
    @IBAction func refreshButtonPressed(_ sender: UIBarButtonItem) {
        sender.isEnabled = false
        startApp()
        sender.isEnabled = true
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        if sender.title == "Save" {
            svr.canceled = false
            progressView.progress = 0
            progressView.isHidden = false
            sender.title = "Cancel"
            refreshButton.isEnabled = false
            moveToPhotos()
        } else {
            svr.canceled = true
            progressView.isHidden = true
            sender.title = "Save"
            startApp()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("view did load")
        saveButton.isEnabled = false
        tableView.separatorStyle = .none
        startApp()
    }
    
    func startApp() {
        NSLog("start app")
        svr.data = [[File]]()
        NSLog("asking permission")
        svr.executePermissionRequest { answer in
            DispatchQueue.main.async {
                switch answer {
                case .allowed:
                    self.showFiles()
                case .denied:
                    self.showError()
                }
            }
        }
    }
    
    func showFiles() {
        NSLog("showFiles")
        svr.getFiles()
        guard svr.data.count > 0 else {
            showEmpty()
            return
        }
        tableView.reloadData()
        progressView.isHidden = true
        saveButton.title = "Save"
        saveButton.isEnabled = true
        refreshButton.isEnabled = true
        tableView.backgroundView = nil
        tableView.separatorStyle = .singleLine

    }
    
    func showError() {
        NSLog("showError")
        progressView.isHidden = true
        saveButton.title = "Save"
        saveButton.isEnabled = false
        refreshButton.isEnabled = true
        tableView.backgroundView = errorView
        tableView.separatorStyle = .none

    }
    
    func showEmpty() {
        NSLog("showEmpty")
        tableView.reloadData()
        progressView.isHidden = true
        saveButton.title = "Save"
        saveButton.isEnabled = false
        refreshButton.isEnabled = true
        tableView.backgroundView = emptyView
        tableView.separatorStyle = .none
    }
    
    func showDone(filesCount: Int) {
        let files = (filesCount > 1) ? "files" : "file"
        let message = "\(filesCount) \(files) was moved to Photos!"
        let alert = UIAlertController(title: "Done", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {(alert: UIAlertAction!) in self.startApp()}))
        self.present(alert, animated: true)
    }
    
    func moveToPhotos() {
        let progress = Progress(totalUnitCount: svr.filesCount)
        var totalProcessed = 0
        
        DispatchQueue(label: "moving").async {
            let svr = self.svr
            for album in svr.data {
                guard !svr.canceled else { break }
                svr.currentAlbum = nil
                for file in album {
                    guard !svr.canceled else { break }
                    
                    if svr.currentAlbum == nil {
                        svr.currentAlbum = svr.findAssetCollection(album: file.album)
                    }
                    svr.addAsset(file: file, album: svr.currentAlbum!)
                    totalProcessed += 1
                    
                    DispatchQueue.main.async {
                        // delete file
                        svr.deleteFile(at: file.URL)
                        print("[ \(totalProcessed) of \(Int(svr.filesCount)) ] \(file.name) moved to photos")
                        progress.completedUnitCount += 1
                        self.progressView.setProgress(Float(progress.fractionCompleted), animated: true)
                        // 100% complete
                        if totalProcessed == svr.filesCount {
                            svr.deleteFolders()
                            self.showDone(filesCount: totalProcessed)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        NSLog("numberOfSections")
        return svr.data.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return svr.data[section].count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        // Configure the cell...
        cell.textLabel?.text = svr.getFileName(indexPath.section,indexPath.row)
        return cell
    }
 
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < svr.data.count {
            return svr.getAlbumTitle(section)
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
