//
//  PodcastMedia.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/14/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import Foundation
import MediaPlayer

// iPod Library is not available on iOS simulators so hardcode one for testing

class PodcastMedia {
    
    static let sharedInstance = PodcastMedia()
    private init() {} // prevent others from using the default initializer
    
    let podcastQuery = MPMediaQuery.podcastsQuery()
}

extension MPMediaItem {
    
    var podcastTitleValue: String {
        guard podcastTitle != nil else {
            return "Developing Perspective"
        }
        return podcastTitle!
    }
    
    var showTitleValue: String {
        guard title != nil else {
            return "#224: Unplanned Absence."
        }
        return title!
    }

    var mediaItemArtworkValue: MPMediaItemArtwork {
        guard artwork != nil else {
            return MPMediaItemArtwork(image: UIImage(named:"radiowaves")!)
        }
        return artwork!
    }
    
    var showURLValue: NSURL {
        guard assetURL != nil else {
            return NSBundle.mainBundle().URLForResource("developing_perspective_224", withExtension: "mp3")!
        }
        return assetURL!
    }
}

extension MPMediaItemCollection {
    
    var countValue: Int {
        guard count > 0 else {
            return 1
        }
        return count
    }
    
    var podcastTitleValue: String {
        guard representativeItem != nil && representativeItem!.podcastTitle != nil else {
            return "Developing Perspective"
        }
        return representativeItem!.podcastTitle!
    }
    
    var artworkImageValue: UIImage! {
        guard representativeItem != nil else {
            return UIImage(named:"radiowaves")!
        }
        return representativeItem!.artwork?.imageWithSize(CGSize(width: 50, height: 50)) ?? UIImage(named:"radiowaves")!
    }

    func indexOfShowWithURL(showURL: NSURL) -> Int? {
        guard count > 0 else {
            return 0
        }
        for (index, show) in items.enumerate() {
            if show.showURLValue == showURL {
                return index
            }
        }
        return nil
    }
    
    func indexOfShow(show: MPMediaItem?) -> Int? {
        guard count > 0 else {
            return 0
        }
        for (index, s) in items.enumerate() {
            if s == show {
                return index
            }
        }
        return nil
    }
    
    @nonobjc subscript(index: Int) -> MPMediaItem? {
        get {
            guard count > 0 && 0..<count ~= index else {
                return MPMediaItem()
            }
            return items[index]
        }
    }

    @nonobjc subscript(showTitle: String) -> MPMediaItem? {
        guard count > 0 else {
            return MPMediaItem()
        }
        for show in items {
            if show.showTitleValue == showTitle {
                return show
            }
        }
        return nil
    }
    
    @nonobjc private subscript(showURL: NSURL) -> MPMediaItem? {
        get {
            guard count > 0 else {
                return nil
            }
            for show in items {
                if show.showURLValue == showURL {
                    return show
                }
            }
            return nil
        }
    }
}

extension MPMediaQuery {
    
    var countValue: Int {
        guard collections != nil && collections!.count > 0 else {
            return 1
        }
        return collections!.count
    }
    
    func indexOfPodcastWithTitle(podcastTitle: String) -> Int? {
        guard collections != nil && collections?.count > 0 else {
            return 0
        }
        for (index, podcast) in collections!.enumerate() {
            if podcast.podcastTitleValue == podcastTitle {
                return index
            }
        }
        return nil
    }
    
    @nonobjc subscript(index: Int) ->  MPMediaItemCollection? {
        get {
            guard collections != nil && collections!.count > 0 && 0..<collections!.count ~= index else {
                return MPMediaItemCollection(items: [])
            }
            if let mediaItemCollection = collections?[index] {
                return mediaItemCollection
            } else {
                return nil
            }
        }
    }
    
    @nonobjc subscript(podcastTitle: String) -> MPMediaItemCollection? {
        get {
            guard collections != nil && collections?.count > 0 else {
                return MPMediaItemCollection(items: [])
            }
            for mediaItemCollection in collections! {
                if mediaItemCollection.podcastTitleValue == podcastTitle {
                    return mediaItemCollection
                }
            }
            return nil
        }
    }
    
    @nonobjc subscript(showURL: NSURL) -> MPMediaItem? {
        get {
            guard collections != nil && collections?.count > 0 else {
                return  MPMediaItem()
            }
            for podcast in collections! {
                if let show = podcast[showURL] {
                    return show
                }
            }
            return nil
        }
    }
    
    @nonobjc subscript(show: MPMediaItem) -> MPMediaItemCollection? {
        guard collections != nil && collections?.count > 0 else {
            return MPMediaItemCollection(items: [])
        }
        for podcast in collections! {
            for s in podcast.items {
                if s == show {
                    return podcast
                }
            }
        }
        return nil
    }
}
