//
//  BytesParser+private.swift
//
//  Copyright © 2023 Darren Ford. All rights reserved.
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

internal extension BytesParser {
	/// Read a single byte from the input stream
	func next() throws -> UInt8 {
		guard self.inputStream.hasBytesAvailable else { throw BytesParser.ParseError.endOfData }
		self.readBuffer.requireSize(1)
		let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: 1)
		guard readCount == 1 else { throw BytesParser.ParseError.endOfData }
		self.offset += 1
		return self.readBuffer.buffer.pointee
	}

	/// Read the next `count` bytes from the input stream
	func next(_ count: Int) throws -> Data {
		guard count > 0 else { return Data() }
		guard self.inputStream.hasBytesAvailable else { throw BytesParser.ParseError.endOfData }

		// Make sure our internal buffer is big enough to hold all the data required
		self.readBuffer.requireSize(count)

		var result = Data()

		// Loop until we've read all the required data
		var read = 0
		while read != count {
			let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: count - read)
			if readCount < 0 {
				// The operation failed
				throw BytesParser.ParseError.endOfData
			}
			if readCount == 0, !self.inputStream.hasBytesAvailable {
				// If we haven't read anything and there's no more data to read,
				// then we're at the end of file
				throw BytesParser.ParseError.endOfData
			}

			if readCount > 0 {
				// Add the read data to the result
				result += Data(bytes: self.readBuffer.buffer, count: readCount)

				// Move the read header forward
				read += readCount
			}
		}
		self.offset += count
		return result
	}

	func nextUpToIncluding(_ byte: UInt8) throws -> Data {
		guard self.inputStream.hasBytesAvailable else { throw BytesParser.ParseError.endOfData }

		// We are reading 1 byte at a time (not overly optimal!)
		self.readBuffer.requireSize(1)

		var result = Data()

		while true {
			let readCount = self.inputStream.read(self.readBuffer.buffer, maxLength: 1)
			if readCount == 0 {
				return result
			}
			result += Data(bytes: self.readBuffer.buffer, count: 1)
			self.offset += 1
			if self.readBuffer.buffer[0] == byte {
				return result
			}
		}
	}
}
