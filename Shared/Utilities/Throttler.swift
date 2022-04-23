//
//  Throttler.swift
//  ManaGuide
//
//  Created by Jovito Royeca on 12/07/2018.
//  Copyright © 2018 Jovito Royeca. All rights reserved.
//

import UIKit

/*
 * Based on code from Daniele Margutti
 * http://danielemargutti.com/2017/10/19/throttle-in-swift/
 */
class Throttler: NSObject {
    private let queue: DispatchQueue = DispatchQueue.global(qos: .background)
    
    private var job: DispatchWorkItem = DispatchWorkItem(block: {})
    private var previousRun: Date = Date.distantPast
    private var maxInterval: TimeInterval
    
    init(seconds: TimeInterval) {
        self.maxInterval = seconds
    }
    
    func throttle(block: @escaping () -> ()) {
        job.cancel()
        job = DispatchWorkItem(){ [weak self] in
            self?.previousRun = Date()
            block()
        }
        let delay = Date.second(from: previousRun) > maxInterval ? 0 : maxInterval
        queue.asyncAfter(deadline: .now() + Double(delay), execute: job)
    }
}

private extension Date {
    static func second(from referenceDate: Date) -> TimeInterval {
        return Date().timeIntervalSince(referenceDate).rounded()
    }
}

