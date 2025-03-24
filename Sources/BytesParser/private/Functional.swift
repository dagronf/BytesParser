//
//  Copyright © 2025 Darren Ford. All rights reserved.
//
//  MIT license
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
//  documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
//  rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
//  permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or substantial
//  portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
//  WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
//  OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

// Some functional programming additions

import Foundation

// MARK: Repeating a call multiple times

/// Runs a block multiple times
/// - Parameters:
///   - count: The number of times to run the block
///   - callBlock: The block to call for each iteration
@inlinable func repeating(_ count: Int, _ callBlock: (Int) -> Void) {
	(0 ..< max(0, count)).forEach { callBlock($0) }
}

/// Runs a block multiple times
/// - Parameters:
///   - count: The number of times to run the block
///   - callBlock: The block to call for each iteration
@inlinable func repeating(_ count: Int, _ callBlock: (Int) throws -> Void) rethrows {
	try (0 ..< max(0, count)).forEach { try callBlock($0) }
}

// MARK: Generating an array of data

/// Runs a block multiple times, aggregating the result for each call in an array
/// - Parameters:
///   - count: The number of times to run the block
///   - generatorBlock: The block to call for each iteration, passing the index
@inlinable func generating<T>(_ count: Int, _ generatorBlock: @autoclosure () -> T) -> [T] {
	(0 ..< max(0, count)).map { _ in generatorBlock() }
}

/// Runs a block multiple times, aggregating the result for each call in an array
/// - Parameters:
///   - count: The number of times to run the block
///   - generatorBlock: The block to call for each iteration, passing the index
@inlinable func generating<T>(_ count: Int, _ generatorBlock: @autoclosure () throws -> T) rethrows -> [T] {
	try (0 ..< max(0, count)).map { _ in try generatorBlock() }
}

/// Runs a block multiple times, aggregating the result for each call in an array
/// - Parameters:
///   - count: The number of times to run the block
///   - generatorBlock: The block to call for each iteration, passing the index
@inlinable func generating<T>(_ count: Int, _ generatorBlock: (Int) -> T) -> [T] {
	(0 ..< max(0, count)).map { generatorBlock($0) }
}

/// Runs a block multiple times, aggregating the result for each call in an array
/// - Parameters:
///   - count: The number of times to run the block
///   - generatorBlock: The block to call for each iteration, passing the index
@inlinable func generating<T>(_ count: Int, _ generatorBlock: (Int) throws -> T) rethrows -> [T] {
	try (0 ..< max(0, count)).map { try generatorBlock($0) }
}
