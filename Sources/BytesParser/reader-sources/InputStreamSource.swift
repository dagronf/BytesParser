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

// MARK: - Input stream reader

/// An input stream source. Does not support changing the read position
public class InputStreamSource: BytesReaderSource {
	// The stream containing the data to be parsed
	let inputStream: InputStream

	/// Read buffer
	let readBuffer = ByteBuffer()

	/// The current read offset within the source
	public private(set) var readPosition: Int = 0

	public init(inputStream: InputStream) {
		self.inputStream = inputStream
		self.inputStream.open()
	}

	public var hasMoreData: Bool {
		self.inputStream.hasBytesAvailable
	}

	public func readData(count: Int) throws -> Data {
		assert(count > 0)
		guard self.inputStream.hasBytesAvailable else { throw BytesReader.ReaderError.endOfData }

		// Make sure our internal buffer is big enough to hold all the data required
		self.readBuffer.requireSize(count)

		var result = Data(capacity: count)

		// Loop until we've read all the required data
		var read = 0
		while read != count {
			let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: count - read)
			if readCount < 0 {
				// The operation failed
				throw BytesReader.ReaderError.endOfData
			}
			if readCount == 0, !self.inputStream.hasBytesAvailable {
				// If we haven't read anything and there's no more data to read,
				// then we're at the end of file
				throw BytesReader.ReaderError.endOfData
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

	/// Read a single byte
	/// - Returns: A byte
	public func readByte() throws -> UInt8 {
		guard self.inputStream.hasBytesAvailable else {
			throw BytesReader.ReaderError.endOfData
		}
		self.readBuffer.requireSize(1)
		let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: 1)
		guard readCount == 1 else { throw BytesReader.ReaderError.endOfData }
		self.readPosition += 1
		return self.readBuffer.buffer.pointee
	}

	/// Read all of the remaining data in the source.
	///
	/// After this call, any further reads will throw (end of data)
	public func readAllRemainingData() throws -> Data {
		// If the stream has no data available throw endOfData
		guard self.inputStream.hasBytesAvailable else { throw BytesReader.ReaderError.endOfData }

		// The chunk size for reading to the end of the file
		let CHUNK_SZ = 16384

		// Make sure our internal buffer is big enough to hold our buffered reads
		self.readBuffer.requireSize(CHUNK_SZ)

		var result = Data(capacity: CHUNK_SZ)
		while self.inputStream.hasBytesAvailable {
			let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: CHUNK_SZ)
			if readCount < 0 {
				// -1 means that the operation failed
				throw BytesReader.ReaderError.endOfData
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
		throw BytesReader.ReaderError.randomAccessSeekingNotSupportedBySource
	}
	
	public func seekSet(_ offset: Int) throws {
		throw BytesReader.ReaderError.randomAccessSeekingNotSupportedBySource
	}
	
	public func seekEnd(_ offset: Int) throws {
		throw BytesReader.ReaderError.randomAccessSeekingNotSupportedBySource
	}
	
	public func seek(_ offset: Int) throws {
		throw BytesReader.ReaderError.randomAccessSeekingNotSupportedBySource
	}
}
