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

// MARK: Integer values

public extension BytesReader {
	/// Read an integer value from the storage
	/// - Parameter byteOrder: The expected byte order for the integer
	/// - Returns: The integer value
	func readInteger<T: FixedWidthInteger>(_ byteOrder: BytesParser.Endianness) throws -> T {
		let data = try self.source.readData(count: MemoryLayout<T>.size)
		let value = data.withUnsafeBytes { $0.loadUnaligned(as: T.self) }
		return byteOrder == .big ? value.bigEndian : value.littleEndian
	}

	/// Read integers from the storage
	/// - Parameters:
	///   - byteOrder: The expected byte order for each integer
	///   - count: The expected number of integers to read
	/// - Returns: The read integers
	func readIntegers<T: FixedWidthInteger>(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [T] {
		try (0 ..< count).map { _ in
			try self.readInteger(byteOrder)
		}
	}
}

public extension BytesReader {
	/// Read a Int8 value
	@inlinable func readInt8() throws -> Int8 {
		Int8(bitPattern: try self.readByte())
	}

	/// Read an array of integer values
	/// - Parameter count: The number of values to read
	/// - Returns: An array of integers
	@inlinable func readInt8(count: Int) throws -> [Int8] {
		let bytes = try self.readBytes(count: count)
		return bytes.map { Int8(bitPattern: $0) }
	}

	/// Read an Int16 value from the storage
	/// - Parameter byteOrder: The expected byte order for the integer
	/// - Returns: The integer value
	@inlinable func readInt16(_ byteOrder: BytesParser.Endianness) throws -> Int16 {
		try readInteger(byteOrder)
	}

	/// Read an array of Int16 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readInt16(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Int16] {
		try self.readIntegers(byteOrder, count: count)
	}

	/// Read an Int32 value from the storage
	/// - Parameter byteOrder: The expected byte order for the integer
	/// - Returns: The integer value
	@inlinable func readInt32(_ byteOrder: BytesParser.Endianness) throws -> Int32 {
		try readInteger(byteOrder)
	}

	/// Read an array of Int32 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readInt32(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Int32] {
		try self.readIntegers(byteOrder, count: count)
	}

	/// Read an Int64 value from the storage
	/// - Parameter byteOrder: The expected byte order for the integer
	/// - Returns: The integer value
	@inlinable func readInt64(_ byteOrder: BytesParser.Endianness) throws -> Int64 {
		try readInteger(byteOrder)
	}

	/// Read an array of Int64 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readInt64(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Int64] {
		try self.readIntegers(byteOrder, count: count)
	}
}

public extension BytesReader {
	/// Read a Int8 value
	@inlinable func readUInt8() throws -> UInt8 {
		try self.readByte()
	}

	/// Read an array of integer values
	/// - Parameter count: The number of values to read
	/// - Returns: An array of integers
	@inlinable func readUInt8(count: Int) throws -> [UInt8] {
		try self.readBytes(count: count)
	}

	/// Read an UInt16 value from the storage
	/// - Parameter byteOrder: The expected byte order for the integer
	/// - Returns: The integer value
	@inlinable func readUInt16(_ byteOrder: BytesParser.Endianness) throws -> UInt16 {
		try readInteger(byteOrder)
	}

	/// Read an array of UInt16 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readUInt16(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [UInt16] {
		try self.readIntegers(byteOrder, count: count)
	}

	/// Read an UInt32 value from the storage
	/// - Parameter byteOrder: The expected byte order for the integer
	/// - Returns: The integer value
	@inlinable func readUInt32(_ byteOrder: BytesParser.Endianness) throws -> UInt32 {
		try readInteger(byteOrder)
	}

	/// Read an array of UInt32 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readUInt32(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [UInt32] {
		try self.readIntegers(byteOrder, count: count)
	}

	/// Read an UInt64 value from the storage
	/// - Parameter byteOrder: The expected byte order for the integer
	/// - Returns: The integer value
	@inlinable func readUInt64(_ byteOrder: BytesParser.Endianness) throws -> UInt64 {
		try readInteger(byteOrder)
	}

	/// Read an array of UInt64 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readUInt64(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [UInt64] {
		try self.readIntegers(byteOrder, count: count)
	}
}
