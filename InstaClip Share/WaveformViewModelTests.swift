//
//  WaveformViewModelTests.swift
//  InstaClip Player
//
//  Created by John Weeks on 4/19/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import XCTest
import AVFoundation

@testable import InstaClip_Player
@testable import InstaClip_Share

class WaveformViewModelTests: XCTestCase {

    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testThatDurationIsCorrect() {
        
        let durationExpectation = expectationWithDescription("testThatDurationIsCorrect")
        var waveformViewModel: WaveformViewModelProtocol! {
            didSet {
                waveformViewModel.durationDidChange = { [unowned self] waveformViewModel in
                    //print(CMTimeGetSeconds(waveformViewModel.duration))
                    XCTAssertEqual(Float32(CMTimeGetSeconds(waveformViewModel.duration)), Float32(898.037551020408), "wrong duration")
                    durationExpectation.fulfill()
                }
            }
        }
        let testBundle = NSBundle.init(forClass: self.classForCoder)
        waveformViewModel = WaveformViewModel(testBundle.URLForResource("developing_perspective_224", withExtension: "mp3")!)
        waitForExpectationsWithTimeout(10.0, handler: nil)
        
    }
    
    
    
}
