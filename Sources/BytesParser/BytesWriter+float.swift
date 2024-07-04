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

public extension BytesWriter {
	/// Write a float32 value to the stream using the IEEE 754 specification
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	@inlinable func writeFloat32(_ value: Float32, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value.bitPattern, byteOrder)
	}

	/// Write an array of float32 values to the stream using the IEEE 754 specification
	/// - Parameters:
	///   - value: The values to write
	///   - byteOrder: The byte order to apply
	@inlinable func writeFloat32(_ value: [Float32], _ byteOrder: BytesParser.Endianness) throws {
//		try value.forEach { try self.writeInteger($0.bitPattern, byteOrder) }
		let bitpats: [UInt32] = value.map { $0.bitPattern }
		try self.writeInteger(bitpats, byteOrder)
	}

	/// Write a float64 (Double) value to the stream using the IEEE 754 specification
	/// - Parameters:
	///   - value: The value to write
	///   - byteOrder: The byte order to apply when writing
	@inlinable func writeFloat64(_ value: Float64, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value.bitPattern, byteOrder)
	}

	/// Write an array of float64 values to the stream using the IEEE 754 specification
	/// - Parameters:
	///   - value: The values to write
	///   - byteOrder: The byte order to apply
	@inlinable func writeFloat64(_ value: [Float64], _ byteOrder: BytesParser.Endianness) throws {
		let bitpats: [UInt64] = value.map { $0.bitPattern }
		try self.writeInteger(bitpats, byteOrder)
	}
}
