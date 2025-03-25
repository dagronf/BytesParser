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

// MARK: - Data and bytes

public extension BytesWriter {
	/// Write the contents of a Data object to the destination
	/// - Parameter data: The data to write
	/// - Returns: The number of bytes written
	@discardableResult
	func writeData(_ data: Data) throws -> Int {
		try data.withUnsafeBytes { try self.writeBuffer($0, byteCount: data.count) }
	}

	/// Write an array of bytes to the destination
	/// - Parameter bytes: An array of bytes to write
	/// - Returns: The number of bytes written
	@discardableResult
	func writeBytes(_ bytes: [UInt8]) throws -> Int {
		let writtenCount = self.outputStream.write(bytes, maxLength: bytes.count)
		guard writtenCount == bytes.count else {
			throw BytesWriter.WriterError.unableToWriteBytes
		}
		self.count += bytes.count
		return bytes.count
	}

	/// Write a single byte to the destination
	/// - Parameter byte: The byte to write
	/// - Returns: The number of bytes written
	@discardableResult
	func writeByte(_ byte: UInt8) throws -> Int {
		let writtenCount = withUnsafePointer(to: byte) {
			self.outputStream.write($0, maxLength: 1)
		}
		guard writtenCount == 1 else {
			throw BytesWriter.WriterError.unableToWriteBytes
		}
		self.count += 1
		return 1
	}
}

internal extension BytesWriter {
	/// Write the contents of a raw buffer pointer to the destination
	func writeBuffer(_ buffer: UnsafeRawBufferPointer, byteCount: Int) throws -> Int {
		assert(byteCount >= 0)

		if byteCount == 0 { return 0 }
		guard let buffer = buffer.baseAddress else {
			throw BytesWriter.WriterError.emptyBuffer
		}

		let ptr = buffer.assumingMemoryBound(to: UInt8.self)
		let written = self.outputStream.write(ptr, maxLength: byteCount)
		guard written == byteCount else { throw BytesWriter.WriterError.unableToWriteBytes }
		self.count += byteCount

		return byteCount
	}
}
