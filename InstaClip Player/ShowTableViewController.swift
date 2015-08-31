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
            navigationItem.title = PodcastMedia.podcastTitleForPodcast(podcast)
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
        //playerView?.delegate = PlayerViewModel.sharedInstance
        playerView?.artWorkImageView.image = PodcastMedia.imageForPodcast(podcast)
        
        // is player active with a show for this podcast?
        if let index = PodcastMedia.indexForShowInPodcast(podcast, withShowMediaItem: PlayerViewModel.sharedInstance.showMediaItem) { // where PlayerViewModel.sharedInstance.showMediaItem != nil  where handels simulator edge case
            tableView.selectRowAtIndexPath(NSIndexPath(forRow: index, inSection: 0), animated: false, scrollPosition: .None)
            playerView?.showMediaItem = PlayerViewModel.sharedInstance.showMediaItem
        }        
        return playerView
    }
    
    // MARK: - UITableViewDelegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        PlayerViewModel.sharedInstance.showMediaItem = PodcastMedia.showMediaItemForPodcast(podcast, withIndex: indexPath.row)
        PlayerViewModel.sharedInstance.playPauseButtonPress() // start playback
        playerView?.showMediaItem = PodcastMedia.showMediaItemForPodcast(podcast, withIndex: indexPath.row)
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return PodcastMedia.showCountForPodcast(podcast)
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ShowReuseIdentifier", forIndexPath: indexPath)

        // Configure the cell...
        cell.textLabel?.text = PodcastMedia.showTitleForPodcast(podcast, withIndex: indexPath.row)

        return cell
    }
    
    @IBAction func actionButtonPress(sender: UIBarButtonItem) {
        if let showURL = PodcastMedia.showURLForShowMediaItem(PlayerViewModel.sharedInstance.showMediaItem), currentTime = PlayerViewModel.sharedInstance.playerCurrentTime() {
            let activityVC = UIActivityViewController(activityItems: [showURL, currentTime], applicationActivities: nil)
            presentViewController(activityVC, animated: true, completion: nil)
        }
    }
    
    // MARK: - state restoration
    
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        let podcastTitle = PodcastMedia.podcastTitleForPodcast(podcast)
        coder.encodeObject(podcastTitle, forKey: "PodcastTitle")
        super.encodeRestorableStateWithCoder(coder)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        if let podcastTitle = coder.decodeObjectForKey("PodcastTitle") as? String {
            podcast = PodcastMedia.sharedInstance.podcastForPodcastTitle(podcastTitle)
        }
        super.decodeRestorableStateWithCoder(coder)
    }
    
    // MARK: - UIDataSourceModelAssociation for state restoration
    
    func modelIdentifierForElementAtIndexPath(idx: NSIndexPath, inView view: UIView) -> String? {
        // called during restore with idx==nil
        guard !isNil(idx) && !isNil(view) else {
            return nil
        }
        
        if let showURL = PodcastMedia.showURLForPodcast(podcast, withIndex: idx.row) {
            return showURL.absoluteString
        }
        return nil
    }
 
    func indexPathForElementWithModelIdentifier(identifier: String, inView view: UIView) -> NSIndexPath? {
        // being cautious here because of idx==nil in modelIdentifierForElementAtIndexPath
        guard !isNil(identifier) && !isNil(view) else {
            return nil
        }
        if let showURL = NSURL.init(string: identifier), index = PodcastMedia.indexForShowInPodcast(podcast, withShowURL: showURL) {
            return NSIndexPath(forRow: index, inSection: 0)
        }
        return nil
    }
   
}
