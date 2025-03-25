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

// MARK: - Generic integer writing

public extension BytesWriter {
	/// Write an integer to the stream using the specified endianness
	/// - Parameters:
	///   - value: The integer value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	func writeInteger<T: FixedWidthInteger>(_ value: T, _ byteOrder: BytesParser.Endianness) throws -> Int {
		// Map the value to the correct endianness...
		let mapped = value.usingEndianness(byteOrder)
		// ... then write out the raw bytes
		return try withUnsafeBytes(of: mapped) { pointer in
			try self.writeBuffer(pointer, byteCount: MemoryLayout<T>.stride)
		}
	}

	/// Write an array of integer values to the stream using the specified endianness
	/// - Parameters:
	///   - value: The integer values to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	func writeIntegers<T: FixedWidthInteger>(_ values: [T], _ byteOrder: BytesParser.Endianness) throws -> Int {
		// If no values just return
		guard values.count > 0 else { return 0 }

		// Map the integer values accordingly
		let mapped = values.map { $0.usingEndianness(byteOrder) }

		// Map the raw integer array into a Data object
		let count = try mapped.withUnsafeBytes {
			try self.writeBuffer($0, byteCount: mapped.count * MemoryLayout<T>.stride)
		}
		return count
	}
}

// MARK: - int

public extension BytesWriter {
	/// Write an Int8 value
	/// - Parameter value: The value to write
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt8(_ value: Int8) throws -> Int {
		try self.writeInteger(value, .big)
	}

	/// Write an array of Int8 values
	/// - Parameter value: The values to write
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt8(_ value: [Int8]) throws -> Int {
		try self.writeIntegers(value, .big)
	}

	/// Write an Int16 value
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt16(_ value: Int16, _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeInteger(value, byteOrder)
	}

	/// Write an array of Int16 values
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt16(_ value: [Int16], _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeIntegers(value, byteOrder)
	}

	/// Write an Int32 value
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt32(_ value: Int32, _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeInteger(value, byteOrder)
	}

	/// Write an array of Int32 values
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt32(_ value: [Int32], _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeIntegers(value, byteOrder)
	}

	/// Write an Int64 value
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt64(_ value: Int64, _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeInteger(value, byteOrder)
	}

	/// Write an array of Int64 values
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt16(_ value: [Int64], _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeIntegers(value, byteOrder)
	}
}

// MARK: - Unsigned int

public extension BytesWriter {
	/// Write A UInt8 value
	/// - Parameters:
	///   - value: The value to write
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeUInt8(_ value: UInt8) throws -> Int {
		try self.writeByte(value)
	}

	/// Write an array of UInt8 values
	/// - Parameter value: The values to write
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeUInt8(_ value: [UInt8]) throws -> Int {
		try self.writeIntegers(value, .big)
	}

	/// Write a UInt16 value
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeUInt16(_ value: UInt16, _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeInteger(value, byteOrder)
	}

	/// Write an array of UInt16 values
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeInt16(_ value: [UInt16], _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeIntegers(value, byteOrder)
	}

	/// Write a UInt32 value
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeUInt32(_ value: UInt32, _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeInteger(value, byteOrder)
	}

	/// Write an array of UInt32 values
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeUInt32(_ value: [UInt32], _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeIntegers(value, byteOrder)
	}

	/// Write a UInt64 value
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeUInt64(_ value: UInt64, _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeInteger(value, byteOrder)
	}

	/// Write an array of UInt64 values
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeUInt64(_ value: [UInt64], _ byteOrder: BytesParser.Endianness) throws -> Int {
		try self.writeIntegers(value, byteOrder)
	}
}
