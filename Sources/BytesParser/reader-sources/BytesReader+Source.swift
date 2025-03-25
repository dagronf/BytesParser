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

import Foundation

/// Interface for a data readable source
public protocol BytesReaderSource {
	/// Does the source have more data available for reading?
	var hasMoreData: Bool { get }
	/// The current read offset within the source
	func readOffset() -> Int
	/// Read data from the source
	/// - Parameter count: The number of bytes to read
	/// - Returns: Data
	func readData(count: Int) throws -> Data
	/// Read a single byte from the source
	/// - Returns: A byte
	func readByte() throws -> UInt8
	/// Read all of the remaining data in the source.
	///
	/// After this call, any further reads will throw (end of data)
	func readAllRemainingData() throws -> Data
	/// Rewind the read pointer to the start of the data
	func rewind() throws
	/// Move the read offset from the start of the data
	/// - Parameter offset: The new read offset
	func seekSet(_ offset: Int) throws
	/// Move the read offset from the end of the data
	/// - Parameter offset: The distance from the end of the data
	func seekEnd(_ offset: Int) throws
	/// Seek from the current read location
	/// - Parameter offset: The offset to move the read position
	func seek(_ offset: Int) throws
}

public extension BytesReaderSource {
	/// Read bytes from the source
	/// - Parameter count: The number of bytes to read
	/// - Returns: Array of bytes
	@inlinable func readBytes(count: Int) throws -> [UInt8] {
		Array(try self.readData(count: count))
	}
}
