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
    
    @IBOutlet var barButton: UIBarButtonItem!
    @IBAction func saveButtonPressed(_ sender: Any) {
        // сделать кнопку Save неактивной, если не выбран ни один файл
        progressView.progress = 0
        
        if barButton.title == "Save" {
            svr.canceled = false
            progressView.isHidden = false
            barButton.title = "Cancel"
            svr.moveToCameraRoll(progressView: progressView, cancelButton: barButton)
        } else {
            svr.canceled = true
            progressView.isHidden = true
            barButton.title = "Save"            
        }


        
        
    }
    
    var svr = Saver()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        svr.getFiles()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
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
        
        svr.data[indexPath.section][indexPath.row].changeState()
        tableView.reloadData() // возможно лучше 

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
