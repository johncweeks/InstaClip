//
//  PodcastMediaTests.swift
//  InstaClip Player
//
//  Created by John Weeks on 9/20/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

// Device tests

import XCTest

class PodcastMediaTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
//
//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measureBlock {
//            // Put the code you want to measure the time of here.
//        }
//    }

    func testThatItHasPodcastCountValue() {
        // Given
        
        // When
        let countValue = PodcastMedia.sharedInstance.podcastQuery.countValue
        if PodcastMedia.sharedInstance.podcastQuery.collections == nil {
            XCTFail()
        }
        // Then
        XCTAssert(countValue==PodcastMedia.sharedInstance.podcastQuery.collections!.count)
    }

    func testThatItHasShowCountValue() {
        // Given
        let index = Int(arc4random_uniform(UInt32(PodcastMedia.sharedInstance.podcastQuery.countValue)))
        let podcast = PodcastMedia.sharedInstance.podcastQuery[index]
        if podcast==nil {
            XCTFail()
        }
        // When
        
        // Then
        XCTAssert(podcast!.countValue==podcast!.items.count)
    }
    
    func testThatItDoesPodcastSubscript() {
        // Given a random podcast index
        let index = Int(arc4random_uniform(UInt32(PodcastMedia.sharedInstance.podcastQuery.countValue)))
        // When
        let podcast1 = PodcastMedia.sharedInstance.podcastQuery[index]
        if podcast1 == nil {
            XCTFail()
        }
        let podcast2 = PodcastMedia.sharedInstance.podcastQuery[podcast1!.podcastTitleValue]
        if podcast2 == nil {
            XCTFail()
        }
        // Then
        XCTAssert(index==PodcastMedia.sharedInstance.podcastQuery.indexOfPodcastWithTitle(podcast1!.podcastTitleValue))
        XCTAssertEqual(podcast1, podcast2)
    }
    
    func testThatItDoesShowSubscript() {
        // Given
        let podcastIndex = Int(arc4random_uniform(UInt32(PodcastMedia.sharedInstance.podcastQuery.countValue)))
        let podcast = PodcastMedia.sharedInstance.podcastQuery[podcastIndex]!
        let showIndex = Int(arc4random_uniform(UInt32(podcast.countValue)))
        
        // When
        let show1 = podcast[showIndex]
        if show1==nil {
            XCTFail()
        }
        let show2 = podcast[show1!.showTitleValue]
        if show2==nil {
            XCTFail()
        }
        // Then
        XCTAssert(podcast.podcastTitleValue==show1!.podcastTitleValue)
        XCTAssert(show1!.showTitleValue==show2!.showTitleValue)
        XCTAssert(showIndex==podcast.indexOfShowWithURL(show1!.showURLValue))
        XCTAssert(showIndex==podcast.indexOfShow(show1))
        XCTAssertEqual(show1!, PodcastMedia.sharedInstance.podcastQuery[show1!.showURLValue])
        XCTAssertEqual(podcast, PodcastMedia.sharedInstance.podcastQuery[show1!])
    }
}
