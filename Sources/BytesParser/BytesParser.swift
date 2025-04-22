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

public class BytesParser {
	/// UTF-8 BOM
	public static let BOMUTF8: [UInt8] = [0xef, 0xbb, 0xbf]
	/// UTF-16 Little Endian BOM
	public static let BOMUTF16LE: [UInt8] = [0xff, 0xfe]
	/// UTF-16 Big Endian BOM
	public static let BOMUTF16BE: [UInt8] = [0xfe, 0xff]

	/// String terminator - single byte
	public static let terminator8: UInt8 = 0x00
	/// String terminator - wide16
	public static let terminator16: [UInt8] = [0x00, 0x00]
	/// String terminator - wide32
	public static let terminator32: [UInt8] = [0x00, 0x00, 0x00, 0x00]
}

public extension BytesReader {
	/// Errors thrown by the parser
	enum ReaderError: Error {
		case invalidFile
		case endOfData
		case invalidStringEncoding
		case invalidOffset
		case randomAccessSeekingNotSupportedBySource
	}
}

public extension BytesWriter {
	/// Errors throws by the writer
	enum WriterError: Error {
		case cannotConvertStringEncoding
		case cannotOpenOutputFile
		case unableToWriteBytes
		case emptyBuffer
		case notSupported
		case noDataAvailable
		case invalidByteString
	}
}

public extension BytesParser {
	/// Endian types
	enum Endianness {
		/// Big endian
		case big
		/// Little endian
		case little
	}
}

extension FixedWidthInteger {
	/// Return the value with the specified endianness
	/// - Parameter byteOrder: The expected byte order
	/// - Returns: The value with the specified endianness
	@inlinable @inline(__always)
	func usingEndianness(_ byteOrder: BytesParser.Endianness) -> Self {
		(byteOrder == .big) ? self.bigEndian : self.littleEndian
	}
}

// #if _endian(big)
// print("Big-endian")
// #elseif _endian(little)
// print("Little-endian")
// #endif

//		switch self {
//		case .big:
//			return intData.reduce(0) { soFar, byte in
//				return soFar << 8 | T(byte)
//			}
//		case .little:
//			return intData.reversed().reduce(0) { soFar, byte in
//				return soFar << 8 | T(byte)
//			}
//		}
