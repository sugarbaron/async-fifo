//
//  AsyncFifo.swift
//  
//
//  Created by sugarbaron on 22.07.2023.
//

import Foundation

// MARK: constructor
public extension Async {
    
    final class Fifo {
        
        private var queue: [Scheduled]
        private let access: NSRecursiveLock
        private var executing: Bool
        
        public init() {
            self.queue = [ ]
            self.access = NSRecursiveLock()
            self.executing = false
        }
        
    }
    
}

// MARK: interface
public extension Async.Fifo {
    
    func enqueue(_ coroutine: @Sendable @escaping () async throws -> Void,
                 catch: @escaping (Error) -> Void = { print("[x][Async.Fifo] coroutine throws: \($0)") }) {
        schedule(coroutine, `catch`)
        inBackground { [weak self] in await self?.executeSequentally() }
    }
    
    var isBusy: Bool {
        access.lock()
        let isBusy: Bool = executing || !(queue.isEmpty)
        access.unlock()
        return isBusy
    }
    
    var queueSize: Int {
        access.lock()
        let size: Int = queue.count + (executing ? 1 : 0)
        access.unlock()
        return size
    }
    
    func cancelAll() {
        access.lock()
        queue = [ ]
        access.unlock()
    }
    
}

// MARK: tools
private extension Async.Fifo {
    
    func schedule(_ coroutine: @Sendable @escaping () async throws -> Void, _ catch: @escaping (Error) -> Void) {
        access.lock()
        queue.append((coroutine, `catch`))
        access.unlock()
    }
    
    func executeSequentally() async {
        if alreadyExecuting { return }
        while let next: Scheduled {
            do    { try await next.coroutine() }
            catch { next.catch(error) }
        }
    }
    
    var next: Scheduled? {
        access.lock()
        if queue.isEmpty { executing = false; access.unlock(); return nil }
        let next: Scheduled = queue.removeFirst()
        access.unlock()
        return next
    }
    
    var alreadyExecuting: Bool {
        access.lock()
        let executing = self.executing
        if executing == false { self.executing = true }
        access.unlock()
        return executing
    }
    
    typealias Scheduled = (coroutine: () async throws -> Void, catch: (Error) -> Void)
    
}
