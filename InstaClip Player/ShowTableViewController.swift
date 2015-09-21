//
//  ShowTableViewController.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/16/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import UIKit
import MediaPlayer


class ShowTableViewController: UITableViewController, UIDataSourceModelAssociation {

    @IBOutlet weak var actionBarButton: UIBarButtonItem!

    var podcast: MPMediaItemCollection? {
        didSet {
//            if podcast == nil {
//                podcast = MPMediaItemCollection(items: [])
//            }
            navigationItem.title = podcast?.podcastTitleValue
        }
    }
    
    private var timeObserver: AnyObject?
    weak var playerView: PlayerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.clearsSelectionOnViewWillAppear = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 103.0
    }

    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        playerView = tableView.dequeueReusableCellWithIdentifier("PlayerViewReuseIdentifier") as? PlayerView
        playerView?.artWorkImageView.image = podcast?.artworkImageValue
        
        // is player active with a show for this podcast?
        if let index = podcast?.indexOfShow(PlayerViewModel.sharedInstance.showMediaItem) {
            tableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: false, scrollPosition: .None)
            playerView?.showMediaItem = PlayerViewModel.sharedInstance.showMediaItem
        }        
        return playerView
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        PlayerViewModel.sharedInstance.saveShowCurrentTime()
        return indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        guard podcast != nil else {
            return
        }
        PlayerViewModel.sharedInstance.showMediaItem = podcast![indexPath.row]
        PlayerViewModel.sharedInstance.restoreShowCurrentTime()
        PlayerViewModel.sharedInstance.playPauseButtonPress() // start playback
        playerView?.showMediaItem = podcast![indexPath.row]
    }
    
    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        guard podcast != nil else {
            return
        }
        cell.textLabel?.text = podcast![indexPath.row]?.showTitleValue
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard podcast != nil else {
            return 0
        }
        return podcast!.countValue
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ShowReuseIdentifier", forIndexPath: indexPath)
        return cell
    }
    
    @IBAction func actionButtonPress(sender: UIBarButtonItem) {
        //if let showURL = PodcastMedia.showURLForShowMediaItem(PlayerViewModel.sharedInstance.showMediaItem), currentTime = PlayerViewModel.sharedInstance.playerCurrentTime() {
        if let showURL = PlayerViewModel.sharedInstance.showMediaItem?.showURLValue,
               currentTime = PlayerViewModel.sharedInstance.playerCurrentTime() {
            let activityVC = UIActivityViewController(activityItems: [showURL, currentTime], applicationActivities: nil)
            presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - state restoration
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        guard podcast != nil else {
            return
        }
        let podcastTitle = podcast!.podcastTitleValue
        coder.encodeObject(podcastTitle, forKey: "PodcastTitle")
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        if let podcastTitle = coder.decodeObjectForKey("PodcastTitle") as? String {
            podcast = PodcastMedia.sharedInstance.podcastQuery[podcastTitle]
        }
        super.decodeRestorableStateWithCoder(coder)
    }
    
    // MARK: - UIDataSourceModelAssociation for state restoration
    
    func modelIdentifierForElementAtIndexPath(idx: NSIndexPath, inView view: UIView) -> String? {
        // called during restore with idx==nil
        guard !isNil(idx) && !isNil(view) && podcast != nil else {
            return nil
        }
        if let showURL = podcast![idx.row]?.showURLValue {
            return showURL.absoluteString
        }
        return nil
    }
 
    func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
        // being cautious here because of idx==nil in modelIdentifierForElementAtIndexPath
        guard !isNil(identifier) && !isNil(view) && podcast != nil else {
            return nil
        }
        if let showURL = NSURL.init(string: identifier), index = podcast!.indexOfShowWithURL(showURL) {
            return NSIndexPath(forRow: index, inSection: 0)
        }
        return nil
    }
   
}
