//
//  RingBuffer.swift
//  InstaClip Player
//
//  Created by John Weeks on 1/22/16.
//  Copyright © 2016 Moonrise Software. All rights reserved.
//

import Foundation


final class RingBuffer<Element> {
    
    var storagePtr: UnsafePointer<Element> = nil //vm_address_t
    var count: Int = 0
    var capacity: Int = 0
    
    /// Allocates memory for RingBuffer
    ///
    /// - parameter count: the number of elements
    /// - returns: an initialized RingBUffer
    /// - throws: Error if memory cannot be allocated
    
    deinit {
        // TODO: free memory
    }
    
    func reserveCapacity(minimumCapacity: Int) throws {
        
        //self.count = count
        let byteCount = minimumCapacity * strideof(Element)
        capacity =  byteCount + Int(vm_page_size) - (byteCount % Int(vm_page_size))
        print(byteCount, capacity, capacity%Int(vm_page_size))
        
        var mem: vm_address_t = 0
        var error: kern_return_t
        let allocationSize = vm_size_t(capacity * 2)
        
        error = withUnsafeMutablePointer(&mem, { (ptr: UnsafeMutablePointer<vm_address_t>) -> kern_return_t in
            return vm_allocate(mach_task_self_,    // target_task
                               ptr,                // address
                               allocationSize,     // size
                               VM_FLAGS_ANYWHERE)  // flags
        })
        
        //assert(error == KERN_SUCCESS, "error vm_allocate: \(error)")
        // TODO: if alloc fails return

        
        var mirrorMem = mem + vm_address_t(capacity)
        var curProtection: vm_prot_t = 0
        var maxProtection: vm_prot_t = 0
        let remapSize = vm_size_t(capacity)
        
        error = withUnsafeMutablePointers(&mirrorMem, &curProtection, &maxProtection,
            { (mirrorMemPtr: UnsafeMutablePointer<vm_address_t>,
                curProtectionPtr: UnsafeMutablePointer<vm_prot_t>,
                maxProtectionPtr: UnsafeMutablePointer<vm_prot_t>) -> kern_return_t in
                
                return vm_remap(mach_task_self_,    // target_task
                    mirrorMemPtr,       // target_address
                    remapSize,          // size
                    0,                  // mask
                    VM_FLAGS_OVERWRITE, // flags
                    mach_task_self_,    // src_task
                    mem,                // src_address
                    0,                  // copy
                    curProtectionPtr,
                    maxProtectionPtr,
                    1)                  // VM_INHERIT_COPY		((vm_inherit_t) 1)	/* copy into child */
        })
        assert(error == KERN_SUCCESS, "error vm_remap: \(error)")
        // TODO: if remap fails free memory & return
        
        
        
        //        let memPtr = unsafeBitCast(mem, UnsafeMutablePointer<UInt8>.self)
        //        let mirrorPtr = unsafeBitCast(mirrorMem, UnsafeMutablePointer<UInt8>.self)
        //
        //        for i in 0..<Int(howMuch) {
        //            let rando = UInt8(arc4random_uniform(256))
        //            memPtr.advancedBy(i).memory = rando
        //            if mirrorPtr.advancedBy(i).memory != rando {
        //                print("\nError")
        //            } else {
        //                //print(String(format: "%c", memPtr.advancedBy(i).memory), terminator:"")
        //            }
        //        }
        
        storagePtr = UnsafePointer<Element>(bitPattern: Int(mem))
    }
    
    subscript(index: Int) -> UnsafePointer<Void> {
        get {
            return unsafeBitCast(storagePtr.advancedBy(index), UnsafePointer<Void>.self)
        }
    }
    
    subscript(index: Int) -> Element {

        //let storagePtr = UnsafePointer<Element>(bitPattern: Int(storage))
        return storagePtr.advancedBy(index).memory
    }
    
//    subscript(index: Int) -> Void {
//        
//        let storagePtr = UnsafePointer<Element>(bitPattern: Int(storage))
//        return unsafeBitCast(storagePtr.advancedBy(index).memory, Void.self)
//    }
}

