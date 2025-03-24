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

public extension BytesReader {
	/// Read a single byte from the input stream
	/// - Returns: A byte
	func readByte() throws -> UInt8 {
		try self.source.readByte()
	}

	/// Read the next `count` bytes into a byte array
	/// - Parameter count: The number of bytes to read
	/// - Returns: An array of bytes
	func readBytes(count: Int) throws -> [UInt8] {
		try self.source.readBytes(count: count)
	}

	/// Read the next `count` bytes into a Data object
	/// - Parameter count: The number of bytes to read
	/// - Returns: A data object containing the read bytes
	func readData(count: Int) throws -> Data {
		try self.source.readData(count: count)
	}

	/// Reads the bytes up to **and including** the next instance of `byte` or EOD.
	/// - Parameter byte: The byte to use as the terminator
	/// - Returns: A data object containing the read bytes
	func readUpToNextInstanceOfByte(_ byte: UInt8) throws -> Data {
		var result = Data()
		while true {
			do {
				let read = try self.source.readByte()
				result.append(read)
				if read == byte {
					return result
				}
			}
			catch {
				// End of file
				return result
			}
		}
	}

	/// Read up to **and including** the next instance of a **single** null byte (0x00)
	/// - Returns: A data object containing the read bytes
	@inlinable func readUpToNextNullByte() throws -> Data {
		try self.readUpToNextInstanceOfByte(0x00)
	}

	/// Read all of the remaining data in the source.
	///
	/// After this call, any further reads will throw (end of data)
	@inlinable func readAllRemainingData() throws -> Data {
		try self.source.readAllRemainingData()
	}
}
