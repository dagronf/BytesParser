//
//  Copyright © 2024 Darren Ford. All rights reserved.
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

// MARK: - An in-memory data source

/// An in-memory data source.  Supports random access called like `seek`.
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
			throw BytesReader.ParseError.endOfData
		}
		defer { self.readPosition += count }
		return self.storage[self.readPosition ..< self.readPosition + count]
	}

	/// Read a single byte from the source
	/// - Returns: A byte
	public func readByte() throws -> UInt8 {
		guard self.readPosition < self.count else {
			throw BytesReader.ParseError.endOfData
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
			throw BytesReader.ParseError.invalidOffset
		}
		self.readPosition += offset
	}

	/// Move the read offset from the start of the data
	/// - Parameter offset: The new read offset
	public func seekSet(_ offset: Int) throws {
		guard offset >= 0, offset < storage.count else {
			throw BytesReader.ParseError.invalidOffset
		}
		self.readPosition = offset
	}

	/// Move the read offset from the end of the data
	/// - Parameter offset: The distance from the end of the data
	public func seekEnd(_ offset: Int) throws {
		guard offset >= 0, offset < self.count else {
			throw BytesReader.ParseError.invalidOffset
		}
		self.readPosition = self.count - offset
	}
}

// MARK: - Input stream reader

/// An input stream source. Does not support changing the read position
public class InputStreamSource: BytesReaderSource {

	// The stream containing the data to be parsed
	let inputStream: InputStream

	/// Read buffer
	let readBuffer = ByteBuffer()

	/// The current read offset within the source
	var readPosition: Int = 0

	public init(inputStream: InputStream) {
		self.inputStream = inputStream
		self.inputStream.open()
	}

	public var hasMoreData: Bool {
		self.inputStream.hasBytesAvailable
	}

	public func readOffset() -> Int { self.readPosition }

	public func readData(count: Int) throws -> Data {
		assert(count > 0)
		guard self.inputStream.hasBytesAvailable else { throw BytesReader.ParseError.endOfData }

		// Make sure our internal buffer is big enough to hold all the data required
		self.readBuffer.requireSize(count)

		var result = Data(capacity: count)

		// Loop until we've read all the required data
		var read = 0
		while read != count {
			let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: count - read)
			if readCount < 0 {
				// The operation failed
				throw BytesReader.ParseError.endOfData
			}
			if readCount == 0, !self.inputStream.hasBytesAvailable {
				// If we haven't read anything and there's no more data to read,
				// then we're at the end of file
				throw BytesReader.ParseError.endOfData
			}

			if readCount > 0 {
				// Add the read data to the result
				result += Data(bytes: self.readBuffer.buffer, count: readCount)

				// Move the read header forward
				read += readCount
			}
		}
		self.readPosition += count
		return result
	}

	public func readByte() throws -> UInt8 {
		guard self.inputStream.hasBytesAvailable else {
			throw BytesReader.ParseError.endOfData
		}
		self.readBuffer.requireSize(1)
		let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: 1)
		guard readCount == 1 else { throw BytesReader.ParseError.endOfData }
		self.readPosition += 1
		return self.readBuffer.buffer.pointee
	}

	/// Read all of the remaining data in the source.
	///
	/// After this call, any further reads will throw (end of data)
	public func readAllRemainingData() throws -> Data {
		// If the stream has no data available throw endOfData
		guard self.inputStream.hasBytesAvailable else { throw BytesReader.ParseError.endOfData }

		// The chunk size for reading to the end of the file
		let CHUNK_SZ = 16384

		// Make sure our internal buffer is big enough to hold our buffered reads
		self.readBuffer.requireSize(CHUNK_SZ)

		var result = Data(capacity: CHUNK_SZ)
		while self.inputStream.hasBytesAvailable {
			let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: CHUNK_SZ)
			if readCount < 0 {
				// -1 means that the operation failed
				throw BytesReader.ParseError.endOfData
			}

			self.readPosition += readCount

			if readCount > 0 {
				// A positive number indicates the number of bytes read.
				// Add the read data to the result
				result += Data(bytes: self.readBuffer.buffer, count: readCount)
			}
			else {
				// 0 indicates that the end of the buffer was reached.
				break
			}
		}
		return result
	}

	public func rewind() throws {
		throw BytesReader.ParseError.randomAccessSeekingNotSupportedBySource
	}
	
	public func seekSet(_ offset: Int) throws {
		throw BytesReader.ParseError.randomAccessSeekingNotSupportedBySource
	}
	
	public func seekEnd(_ offset: Int) throws {
		throw BytesReader.ParseError.randomAccessSeekingNotSupportedBySource
	}
	
	public func seek(_ offset: Int) throws {
		throw BytesReader.ParseError.randomAccessSeekingNotSupportedBySource
	}
}
