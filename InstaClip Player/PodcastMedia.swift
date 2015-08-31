//
//  PodcastMedia.swift
//  InstaClip Player
//
//  Created by John Weeks on 8/14/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

import Foundation
import MediaPlayer

// iPod Library is not available on simulators so hardcode one for testing

class PodcastMedia {
    
    static let sharedInstance = PodcastMedia()
    private init() {} // prevent others from using the default initializer
    
    private let podcastQuery = MPMediaQuery.podcastsQuery()
    
    static func showCountForPodcast(podcast: MPMediaItemCollection?) -> Int {
        guard podcast != nil else {
            return 1
        }
        return podcast!.count
        
    }
    
    static func artworkForPodcast(podcast: MPMediaItemCollection?) -> MPMediaItemArtwork {
        guard podcast != nil else {
            return MPMediaItemArtwork(image: UIImage(named:"radiowaves")!)
        }
        if let representativeItem = podcast!.representativeItem {
            if let artwork = representativeItem.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
                return artwork
            }
        }
        return  MPMediaItemArtwork(image: UIImage(named:"radiowaves")!)
    }

    
    static func imageForPodcast(podcast: MPMediaItemCollection?) -> UIImage? {
        guard podcast != nil else {
            return UIImage(named:"radiowaves")
        }
        if let representativeItem = podcast!.representativeItem {
            if let artwork = representativeItem.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
                if let artworkImage = artwork.imageWithSize(CGSize(width: 50, height: 50)) {
                    return artworkImage
                }
            }
        }
        return UIImage(named:"radiowaves")
    }
    
    static func podcastTitleForPodcast(podcast: MPMediaItemCollection?) -> String {
        guard podcast != nil else {
            return "Developing Perspective"
        }
        if let representativeItem = podcast!.representativeItem {
            if let title = representativeItem.valueForProperty(MPMediaItemPropertyPodcastTitle) as? String {
                return title
            }
        }
        return ""
    }
    
    static func indexForShowInPodcast(podcast: MPMediaItemCollection?, withShowURL showURL: NSURL) -> Int? {
        guard podcast != nil else {
            return 0
        }
        for (index, _) in podcast!.items.enumerate() {
            if showURL == showURLForPodcast(podcast, withIndex: index) {
                return index
            }
        }
        return nil
    }
    
    static func showTitleForPodcast(podcast: MPMediaItemCollection?, withIndex index: Int) -> String {
        guard podcast != nil else {
            return "#224: Unplanned Absence."
        }
        if let title = podcast?.items[index].valueForProperty(MPMediaItemPropertyTitle) as? String {
            return title
        }
        return ""
    }
    
    static func showURLForPodcast(podcast: MPMediaItemCollection?, withIndex index: Int) -> NSURL? {
        guard podcast != nil else {
            return NSBundle.mainBundle().URLForResource("developing_perspective_224", withExtension: "mp3")
        }
        return podcast?.items[index].valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL
    }
    
    static func showMediaItemForPodcast(podcast: MPMediaItemCollection?, withIndex index: Int) -> MPMediaItem? {
        guard podcast != nil else {
            return nil
        }
        return podcast?.items[index]
    }
    
    static func indexForShowInPodcast(podcast: MPMediaItemCollection?, withShowMediaItem showMediaItem: MPMediaItem?) -> Int? {
        guard podcast != nil && showMediaItem != nil else {
            return 0
        }
        for (index, value) in podcast!.items.enumerate() {
            if value == showMediaItem {
                return index
            }
        }
        
        return nil
    }
    
    static func showURLForShowMediaItem(showMediaItem: MPMediaItem?) -> NSURL? {
        guard showMediaItem != nil else {
            return NSBundle.mainBundle().URLForResource("developing_perspective_224", withExtension: "mp3")
        }
        return showMediaItem?.valueForProperty(MPMediaItemPropertyAssetURL) as? NSURL
    }
    
    static func podcastTitleForShowMediaItem(showMediaItem: MPMediaItem?) -> String {
        guard showMediaItem != nil else {
            return "Developing Perspective"
        }
        if let title = showMediaItem?.valueForProperty(MPMediaItemPropertyPodcastTitle) as? String {
            return title
        }
        return ""
    }
    
    static func showTitleForShowMediaItem(showMediaItem: MPMediaItem?) -> String {
        guard showMediaItem != nil else {
            return "#224: Unplanned Absence."
        }
        if let title = showMediaItem?.valueForProperty(MPMediaItemPropertyTitle) as? String {
            return title
        }
        return ""
    }

    static func artworkForShowMediaItem(showMediaItem: MPMediaItem?) -> MPMediaItemArtwork {
        guard showMediaItem != nil else {
            return MPMediaItemArtwork(image: UIImage(named:"radiowaves")!)
        }
        if let artwork = showMediaItem?.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
            return artwork
        }
        return  MPMediaItemArtwork(image: UIImage(named:"radiowaves")!)
    }

    private func hasPodcastItemCollections() -> Bool {
        if let count = podcastQuery.collections?.count where count > 0 {
            return true
        } else {
            return false
        }
    }
    
    private func podcastRepresentativeItemForIndex(index: Int) -> MPMediaItem? {
        if let podcastItemCollection = podcastQuery.collections {
            let podcastItem = podcastItemCollection[index]
            if let representativeItem = podcastItem.representativeItem {
                return representativeItem
            }
        }
        return nil
    }

    func podcastCount() -> Int {
        guard hasPodcastItemCollections() else {
            return 1
        }
        return podcastQuery.collections!.count
    }
    
    func podcastForIndex(index: Int) -> MPMediaItemCollection? {
        guard hasPodcastItemCollections() else {
            return nil
        }
        return podcastQuery.collections![index]
    }
    
    func podcastForPodcastTitle(podcastTitle: String) -> MPMediaItemCollection? {
        guard hasPodcastItemCollections() else {
            return nil
        }
        for (index, _) in podcastQuery.collections!.enumerate() {
            if podcastTitleForIndex(index) == podcastTitle {
                return podcastForIndex(index)
            }
        }
        return nil
    }
    
    func podcastTitleForIndex(index: Int) -> String {
        guard hasPodcastItemCollections() else {
            return "Developing Perspective"
        }
        if let representativeItem = podcastRepresentativeItemForIndex(index) {
            if let title = representativeItem.valueForProperty(MPMediaItemPropertyPodcastTitle) as? String {
                return title
            }
        }
        return ""
    }
    
    func podcastIndexForTitle(podcastTitle: String) -> Int {
        guard hasPodcastItemCollections() else {
            return 0
        }
        for index in 0..<podcastQuery.collections!.count {
            if podcastTitleForIndex(index) == podcastTitle {
                return index
            }
        }
        return 0
    }
    
    func podcastIndexForShowMediaItem(showMediaItem: MPMediaItem?) -> Int {
        guard showMediaItem != nil else {
            return 0
        }
        for (index, podcast) in podcastQuery.collections!.enumerate() {
            for show in podcast.items {
                if show == showMediaItem {
                    return  index
                }
            }
        }
        return 0
    }
    
    func podcastImageForIndex(index: Int) -> UIImage? {
        guard hasPodcastItemCollections() else {
            return UIImage(named:"radiowaves")
        }
        if let representativeItem = podcastRepresentativeItemForIndex(index) {
            if let artwork = representativeItem.valueForProperty(MPMediaItemPropertyArtwork) as? MPMediaItemArtwork {
                if let artworkImage = artwork.imageWithSize(CGSize(width: 50, height: 50)) {
                    return artworkImage
                }
            }
        }
        return UIImage(named:"radiowaves")
    }
    
//    func showForShowURL(showURL: NSURL) -> (podcast: MPMediaItemCollection?, index: Int)? {
//        guard hasPodcastItemCollections() else {
//            return nil
//        }
//        for podcast in podcastQuery.collections! {
//            for index in 0..<podcast.items.count {
//                if showURL == PodcastMedia.showURLForPodcast(podcast, withIndex: index) {
//                    return (podcast, index)
//                }
//            }
//        }
//        return nil
//    }
    
    func showMediaItemForShowURL(showURL: NSURL) -> MPMediaItem? {
        guard hasPodcastItemCollections() else {
            return nil
        }
        for podcast in podcastQuery.collections! {
            for (index, value) in podcast.items.enumerate() {
                if showURL == PodcastMedia.showURLForPodcast(podcast, withIndex: index) {
                    return value
                }
            }
        }
        return nil
    }
}

