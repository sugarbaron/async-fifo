//
//  File.swift
//  
//
//  Created by sugarbaron on 22.07.2023.
//

import Foundation

/// namespace class
public final class Async { }

public extension Async {  typealias Task = _Concurrency.Task }

@inlinable public func concurrent<T>(function: String = #function, _ callback: (CheckedContinuation<T, Error>) -> Void)
async throws -> T {
    try await withCheckedThrowingContinuation(function: function, callback)
}

@discardableResult
public func inBackground<T:Sendable>(_ coroutine: @Sendable @escaping () async throws -> T) -> Async.Task<T, Error> {
    Async.Task.detached(priority: .low, operation: coroutine)
}

@discardableResult
public func onMain<T:Sendable>(_ coroutine: @MainActor @Sendable @escaping () throws -> T) -> Async.Task<T, Error> {
    Async.Task.detached { try await MainActor.run { try coroutine() } }
}

@discardableResult
public func onMain<T:Sendable>(after delay: TimeInterval, _ coroutine: @MainActor @Sendable @escaping () throws -> T)
-> Async.Task<T, Error> {
    Async.Task.detached { await idle(delay); return try await MainActor.run { try coroutine() } }
}

public func idle(_ duration: TimeInterval) async {
    do    { try await Task.sleep(nanoseconds: UInt64(duration * 1e9)) }
    catch { print("[x][Async] sleep interrupted: \(error)") }
}
