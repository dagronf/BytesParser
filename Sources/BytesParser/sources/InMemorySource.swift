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

// MARK: - An in-memory data source

/// An in-memory data source.  Supports random access calls like `seek`.
public class InMemorySource: BytesReaderSource {

	/// The data
	let storage: Data

	/// The number of bytes in the source
	public var count: Int { storage.count }

	/// The current read position in the data
	public private(set) var readPosition: Int = 0

	/// Create
	/// - Parameter data: The data to read
	public init(data: Data) {
		self.storage = data
	}

	/// Create
	/// - Parameter bytes: The bytes to read
	public init(bytes: [UInt8]) {
		self.storage = Data(bytes)
	}

	/// Is there more data to read?
	public var hasMoreData: Bool {
		self.readPosition < self.count
	}

	// MARK: - Reading

	/// The current read position within the source
	public func readOffset() -> Int { self.readPosition }

	/// Read data from the source
	/// - Parameter count: The number of bytes to read from the source
	/// - Returns: Data
	public func readData(count: Int) throws -> Data {
		guard self.readPosition + count <= self.count else {
			throw BytesReader.ReaderError.endOfData
		}
		defer { self.readPosition += count }
		return self.storage[self.readPosition ..< self.readPosition + count]
	}

	/// Read a single byte from the source
	/// - Returns: A byte
	public func readByte() throws -> UInt8 {
		guard self.readPosition < self.count else {
			throw BytesReader.ReaderError.endOfData
		}
		defer { self.readPosition += 1 }
		return self.storage[self.readPosition]
	}

	/// Reads bytes from the source
	/// - Parameter count: The number of bytes to read
	/// - Returns: An array of bytes
	@inlinable public func readBytes(count: Int) throws -> [UInt8] {
		Array(try self.readData(count: count))
	}

	/// Read the remaining data
	/// - Returns: Data
	///
	/// Any subsequent reads will fail
	public func readAllRemainingData() throws -> Data {
		let count = self.count - self.readPosition - 1
		defer { self.readPosition = self.count }
		return self.storage[self.readPosition ... self.readPosition + count]
	}

	// MARK: - Moving the read pointer

	/// Rewind the read position back to the start of the data
	public func rewind() throws { self.readPosition = 0 }

	/// Seek from the current read location
	/// - Parameter offset: The offset to move the read position
	public func seek(_ offset: Int) throws {
		guard (0 ..< self.count).contains(self.readPosition + offset) else {
			throw BytesReader.ReaderError.invalidOffset
		}
		self.readPosition += offset
	}

	/// Move the read offset from the start of the data
	/// - Parameter offset: The new read offset
	public func seekSet(_ offset: Int) throws {
		guard offset >= 0, offset < storage.count else {
			throw BytesReader.ReaderError.invalidOffset
		}
		self.readPosition = offset
	}

	/// Move the read offset from the end of the data
	/// - Parameter offset: The distance from the end of the data
	public func seekEnd(_ offset: Int) throws {
		guard offset >= 0, offset < self.count else {
			throw BytesReader.ReaderError.invalidOffset
		}
		self.readPosition = self.count - offset
	}
}
