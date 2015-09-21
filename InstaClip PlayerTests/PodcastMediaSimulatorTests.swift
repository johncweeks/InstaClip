//
//  PodcastMediaSimulatorTests.swift
//  InstaClip Player
//
//  Created by John Weeks on 9/20/15.
//  Copyright © 2015 Moonrise Software. All rights reserved.
//

// tests for the simulator

import XCTest

class PodcastMediaSimulatorTests: XCTestCase {

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
        let count = PodcastMedia.sharedInstance.podcastQuery.countValue
        // Then
        XCTAssert(count==1)
    }
    
    func testThatItHasShowCountValue() {
        // Given
        // When
        // Then
        XCTAssert(PodcastMedia.sharedInstance.podcastQuery[0]?.countValue==1)
    }
    
    func testThatItDoesPodcastSubscript() {
        //"Developing Perspective"
        // Given
        // When
        let index = PodcastMedia.sharedInstance.podcastQuery.indexOfPodcastWithTitle("Developing Perspective")
        let podcast = PodcastMedia.sharedInstance.podcastQuery[0]
        if podcast==nil {
            XCTFail()
        }
        let podcastTitle = PodcastMedia.sharedInstance.podcastQuery["Developing Perspective"]?.podcastTitleValue
        if podcastTitle==nil {
            XCTFail()
        }
        // Then
        XCTAssert(index==0)
        XCTAssert(podcast!.podcastTitleValue=="Developing Perspective")
        XCTAssert(podcastTitle=="Developing Perspective")
    }

    func testThatItDoesShowSubscript() {
        // Given
        let podcast = PodcastMedia.sharedInstance.podcastQuery["Developing Perspective"]
        if podcast==nil {
            XCTFail()
        }
        let show1 = podcast!["#224: Unplanned Absence."]
        if show1==nil {
            XCTFail()
        }
        // When
        let show2 = podcast![0]
        if show2==nil {
            XCTFail()
        }
        // Then
        XCTAssert(podcast!.podcastTitleValue==show1!.podcastTitleValue)
        XCTAssert(show1!.showTitleValue==show2!.showTitleValue)
        XCTAssert(podcast!.indexOfShowWithURL(show1!.showURLValue)==0)
        XCTAssert(podcast!.indexOfShow(show1)==0)
        XCTAssertEqual(show1!, PodcastMedia.sharedInstance.podcastQuery[show1!.showURLValue])
    }


}
