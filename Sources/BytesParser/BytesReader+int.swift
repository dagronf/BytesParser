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
	/// Read an integer value
	/// - Parameter byteOrder: Expected endianness for the integer
	/// - Returns: An integer value
	///
	/// See the discussion [here](https://web.archive.org/web/2/https://forums.swift.org/t/convert-uint8-to-int/30117/9)
	@inlinable func readInteger<T: FixedWidthInteger>(_ byteOrder: BytesParser.Endianness) throws -> T {
		byteOrder.convert(try self.readData(count: MemoryLayout<T>.size))
	}

	/// Read an array of integers
	/// - Parameters:
	///   - byteOrder: The byte order of the integers
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readInteger<T: FixedWidthInteger>(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [T] {
		let data = try self.readData(count: MemoryLayout<T>.size * count)
		return byteOrder.convert(data, count: count)
	}
}

public extension BytesReader {
	/// Read an Int8 value
	@inlinable func readInt8() throws -> Int8 {
		// Remap the UInt8 value to an Int8 value
		Int8(bitPattern: try self.readByte())
	}

	/// Read an Int16 value
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readInt16(_ byteOrder: BytesParser.Endianness) throws -> Int16 {
		return try self.readInteger(byteOrder)
	}

	/// Read an array of Int16 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readInt16(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Int16] {
		try readInteger(byteOrder, count: count)
	}

	/// Read an Int32 value
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readInt32(_ byteOrder: BytesParser.Endianness) throws -> Int32 {
		return try self.readInteger(byteOrder)
	}

	/// Read an array of Int32 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readInt32(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Int32] {
		try readInteger(byteOrder, count: count)
	}

	/// Read an Int64 value
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readInt64(_ byteOrder: BytesParser.Endianness) throws -> Int64 {
		return try self.readInteger(byteOrder)
	}

	/// Read an array of Int64 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of integers
	@inlinable func readInt64(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Int64] {
		try readInteger(byteOrder, count: count)
	}
}

// MARK: Unsigned integer values

public extension BytesReader {
	/// Read a UInt8 value
	@inlinable func readUInt8() throws -> UInt8 {
		return try self.readByte()
	}

	/// Read a UInt16 value
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readUInt16(_ byteOrder: BytesParser.Endianness) throws -> UInt16 {
		return try self.readInteger(byteOrder)
	}

	/// Read an array of UInt16 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of unsigned ints
	@inlinable func readUInt16(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [UInt16] {
		try readInteger(byteOrder, count: count)
	}

	/// Read a UInt32 value
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readUInt32(_ byteOrder: BytesParser.Endianness) throws -> UInt32 {
		return try self.readInteger(byteOrder)
	}

	/// Read an array of UInt32 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of unsigned ints
	@inlinable func readUInt32(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [UInt32] {
		try readInteger(byteOrder, count: count)
	}

	/// Read a UInt64 value
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readUInt64(_ byteOrder: BytesParser.Endianness) throws -> UInt64 {
		return try self.readInteger(byteOrder)
	}

	/// Read an array of UInt64 values
	/// - Parameters:
	///   - byteOrder: The expected endianness for the integer
	///   - count: The number of integers to read
	/// - Returns: An array of unsigned ints
	@inlinable func readUInt64(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [UInt64] {
		try readInteger(byteOrder, count: count)
	}
}
