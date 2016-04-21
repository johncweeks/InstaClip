//
//  RingBufferTests.swift
//  InstaClip Player
//
//  Created by John Weeks on 1/22/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import XCTest
//@testable import InstaClip_Share

class RingBufferTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

    
    func testThatItMirrors() {
        
        let rb = RingBuffer<UInt8>(count: 123456)
        
        let mem = unsafeBitCast(rb.storagePtr, vm_address_t.self)
        let mirrorMem: vm_address_t = mem + vm_address_t(rb.capacity)
        
        let memPtr = unsafeBitCast(mem, UnsafeMutablePointer<UInt8>.self)
        let mirrorPtr = unsafeBitCast(mirrorMem, UnsafeMutablePointer<UInt8>.self)
        
        for i in 0..<Int(rb.capacity)/strideof(UInt8) {
            let rando = UInt8(arc4random_uniform(UInt32(UInt8.max)))
            memPtr.advancedBy(i).memory = rando
            if mirrorPtr.advancedBy(i).memory != rando {
                XCTFail()
            } else {
                //print(String(format: "%c", memPtr.advancedBy(i).memory), terminator:"")
            }
        }
        
        
        do {
        let rb = RingBuffer<Float32>(count: 123456)
        
        let mem = unsafeBitCast(rb.storagePtr, vm_address_t.self)
        let mirrorMem: vm_address_t = mem + vm_address_t(rb.capacity)
        
        let memPtr = unsafeBitCast(mem, UnsafeMutablePointer<Float32>.self)
        let mirrorPtr = unsafeBitCast(mirrorMem, UnsafeMutablePointer<Float32>.self)
        
        for i in 0..<Int(rb.capacity)/strideof(Float32) {
            let rando = Float32(arc4random_uniform(UInt32.max))
            memPtr.advancedBy(i).memory = rando
            if mirrorPtr.advancedBy(i).memory != rando {
                XCTFail()
            } else {
                //print(String(format: "%c", memPtr.advancedBy(i).memory), terminator:"")
            }
        }
        }
    }
    
    
}
