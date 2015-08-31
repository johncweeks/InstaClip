//
//  PodcastTableViewController.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/15/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit

class PodcastTableViewController: UITableViewController, UISplitViewControllerDelegate, UIDataSourceModelAssociation {
    
    private var collapseDetailViewController = true     // From http://nshipster.com/uisplitviewcontroller/
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
        
        splitViewController!.delegate = self
        
        self.navigationItem.rightBarButtonItem?.title = "Now\nPlaying"
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PodcastMedia.sharedInstance.podcastCount()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("PodcastReuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...
        cell.textLabel?.text = PodcastMedia.sharedInstance.podcastTitleForIndex(indexPath.row)
        cell.imageView?.image = PodcastMedia.sharedInstance.podcastImageForIndex(indexPath.row)
        
        return cell
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "ShowPodcastDetailSegueID" {
            if let showNavigationController = segue.destinationViewController as? UINavigationController {
                if let showTableViewController = showNavigationController.topViewController as? ShowTableViewController {
                    showTableViewController.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                    showTableViewController.navigationItem.leftItemsSupplementBackButton = true
                    if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
                        showTableViewController.podcast =  PodcastMedia.sharedInstance.podcastForIndex(selectedRowIndexPath.row)
                    }
                }
            }
        } else if segue.identifier == "NowPlayingDetailSegueID" {
            if let showNavigationController = segue.destinationViewController as? UINavigationController {
                if let showTableViewController = showNavigationController.topViewController as? ShowTableViewController {
                    showTableViewController.navigationItem.leftBarButtonItem = self.splitViewController?.displayModeButtonItem()
                    showTableViewController.navigationItem.leftItemsSupplementBackButton = true
 //                   if let selectedRowIndexPath = tableView.indexPathForSelectedRow {
                        showTableViewController.podcast =  PodcastMedia.sharedInstance.podcastForIndex(PodcastMedia.sharedInstance.podcastIndexForShowMediaItem(PlayerViewModel.sharedInstance.showMediaItem))
 //                   }
                }
            }
            
        }
    }

    // MARK: UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        collapseDetailViewController = false
    }
    
    // MARK: - UISplitViewControllerDelegate
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return collapseDetailViewController
    }
    
    @IBAction func nowPlayingButtonPress(sender: UIBarButtonItem) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let vc = storyboard.instantiateViewControllerWithIdentifier("ShowTableViewControllerID") as? ShowTableViewController {
            let showMediaItem = PlayerViewModel.sharedInstance.showMediaItem
            //self.navigationController?.pushViewController(vc, animated: true)
            if let splitViewController = self.splitViewController as? SplitViewController {
                if let navigationController = splitViewController.viewControllers.last as? UINavigationController {
                    if let _ = navigationController.topViewController {
                        navigationController.popViewControllerAnimated(false)
                    }
                    print(navigationController.viewControllers.count)
                    vc.podcast = PodcastMedia.sharedInstance.podcastForIndex(PodcastMedia.sharedInstance.podcastIndexForShowMediaItem(showMediaItem))
                    navigationController.pushViewController(vc, animated: true)
                }
            }
        }
    }
    
    
    // MARK: - UIDataSourceModelAssociation for state restoration
    
    func modelIdentifierForElementAtIndexPath(idx: NSIndexPath, inView view: UIView) -> String? {
        // called during state restoration with idx==nil
        guard !isNil(idx) && !isNil(view) else {
            return nil
        }
        return PodcastMedia.sharedInstance.podcastTitleForIndex(idx.row)
    }
    
    func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
        // being cautious here because of idx==nil in modelIdentifierForElementAtIndexPath
        guard !isNil(identifier) && !isNil(view) else {
            return nil
        }
        return NSIndexPath(forRow: PodcastMedia.sharedInstance.podcastIndexForTitle(identifier), inSection: 0)
    }
}
