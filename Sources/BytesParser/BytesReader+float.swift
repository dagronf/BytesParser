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

// MARK: Float values

public extension BytesReader {
	/// Read in an IEEE 754 float32 value
	/// - Parameter byteOrder: The endianness of the input value
	/// - Returns: A Float32 value
	///
	/// [IEEE 754 specification](http://ieeexplore.ieee.org/servlet/opac?punumber=4610933)
	func readFloat32(_ byteOrder: BytesParser.Endianness) throws -> Float32 {
		return Float32(bitPattern: try readUInt32(byteOrder))
	}

	/// Read an array of Float32 values
	/// - Parameters:
	///   - byteOrder: The byte order of the float values
	///   - count: The number of Float32 values to read
	/// - Returns: An array of float values
	@inlinable func readFloat32(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Float32] {
		assert(count > 0)
		let values = try readUInt32(byteOrder, count: count)
		return values.map { Float32(bitPattern: $0) }
	}

	/// Read in an IEEE 754 float64 value
	/// - Parameter byteOrder: The endianness of the input value
	/// - Returns: A Float64 value
	///
	/// [IEEE 754 specification](http://ieeexplore.ieee.org/servlet/opac?punumber=4610933)
	@inlinable func readFloat64(_ byteOrder: BytesParser.Endianness) throws -> Float64 {
		Float64(bitPattern: try readUInt64(byteOrder))
	}

	/// Read an array of Float64 values
	/// - Parameters:
	///   - byteOrder: The byte order of the float values
	///   - count: The number of Float64 values to read
	/// - Returns: An array of float values
	@inlinable func readFloat64(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Float64] {
		assert(count > 0)
		let values = try readUInt64(byteOrder, count: count)
		return values.map { Float64(bitPattern: $0) }
	}
}

public extension BytesReader {
	/// Read a double (64-bit) value
	/// - Parameter byteOrder: The byte order
	/// - Returns: A double value
	func readDouble(_ byteOrder: BytesParser.Endianness) throws -> Double {
		Float64(bitPattern: try readUInt64(byteOrder))
	}

	/// Read an array of Double values
	/// - Parameters:
	///   - byteOrder: The byte order
	///   - count: The number of Double values to read
	/// - Returns: An array of double values
	@inlinable func readDouble(_ byteOrder: BytesParser.Endianness, count: Int) throws -> [Double] {
		assert(count > 0)
		let values = try readUInt64(byteOrder, count: count)
		return values.map { Double(bitPattern: $0) }
	}
}
