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

/// UTF-8 BOM
public let BOMUTF8: [UInt8] = [0xef, 0xbb, 0xbf]
/// UTF-16 Little Endian BOM
public let BOMUTF16LE: [UInt8] = [0xff, 0xfe]
/// UTF-16 Big Endian BOM
public let BOMUTF16BE: [UInt8] = [0xfe, 0xff]

internal let terminator16: [UInt8] = [0x00, 0x00]
internal let terminator32: [UInt8] = [0x00, 0x00, 0x00, 0x00]

// MARK: - String conveniences

public extension BytesParser {
	/// Read a string (byte-based) using a length and string encoding
	/// - Parameters:
	///   - encoding: The string encoding to use when reading
	///   - length: The expected number of characters in the string
	///   - lengthIncludesTerminator: If true, assumes that the _last_ character in the string is the null terminator.
	/// - Returns: A string
	func readString(_ encoding: String.Encoding, length: Int, lengthIncludesTerminator: Bool = false) throws -> String {
		var stringData = try self.readData(count: length)
		if lengthIncludesTerminator, stringData.last == 0x00 {
			stringData = stringData.dropLast(1)
		}
		guard let str = String(data: stringData, encoding: encoding) else {
			throw ParseError.invalidStringEncoding
		}
		return str
	}

	/// Read a string (single byte based) up to the string's null terminator
	/// - Parameter encoding: The expected string encoding (assumes a single-byte encoding)
	/// - Returns: A string
	///
	/// NOTE: Slower as we have to read byte-by-byte. Also less safe than the length specific version!
	func readStringNullTerminated(_ encoding: String.Encoding) throws -> String {
		var rawContent = try readUpToNextInstanceOfByte(0x00)
		if rawContent.last == 0x00 {
			// Remove the last terminator character
			// Note that the last character is _not_ guaranteed to be nil IF we hit the EOD
			rawContent = rawContent.dropLast()
		}
		guard let str = String(data: rawContent, encoding: encoding) else {
			throw ParseError.invalidStringEncoding
		}
		return str
	}
}

public extension BytesParser {
	/// Read a UTF8 string using a byte count
	/// - Parameters:
	///   - byteCount: The number of bytes containing the string
	///   - lengthIncludesTerminator: If true, assumes that the _last_ character in the string is the null terminator.
	/// - Returns: A string
	@inlinable func readStringUTF8(byteCount: Int, lengthIncludesTerminator: Bool = false) throws -> String {
		try self.readString(.utf8, length: byteCount, lengthIncludesTerminator: lengthIncludesTerminator)
	}

	/// Read an ASCII string
	/// - Parameters:
	///   - length: The number of characters to read
	///   - lengthIncludesTerminator: If true, assumes that the _last_ character in the string is the null terminator.
	/// - Returns: A string
	@inlinable func readStringASCII(length: Int, lengthIncludesTerminator: Bool = false) throws -> String {
		try self.readString(.ascii, length: length, lengthIncludesTerminator: lengthIncludesTerminator)
	}

	/// Read an ASCII string up to the string's null terminator
	@inlinable func readStringASCIINullTerminated() throws -> String {
		try self.readStringNullTerminated(.ascii)
	}

	/// Read a UTF8 string up to a null terminator
	@inlinable func readStringUTF8NullTerminated() throws -> String {
		try self.readStringNullTerminated(.utf8)
	}
}

// MARK: wide strings

public extension BytesParser {
	/// Read a wide (2-byte) string with a particular encoding
	/// - Parameters:
	///   - length: The number of 2-byte characters to read
	///   - encoding: The expected encoding
	/// - Returns: A string
	func readStringWide16(_ encoding: String.Encoding, length: Int) throws -> String {
		guard length > 0 else { return "" }
		let rawContent = try self.readData(count: length * 2)
		if let str = String(data: rawContent, encoding: encoding) {
			return str
		}
		throw ParseError.invalidStringEncoding
	}

	/// Read a wide (2-byte) string up to the string's null terminator
	/// - Parameters:
	///   - encoding: The expected encoding
	/// - Returns: A string
	func readStringWide16NullTerminated(encoding: String.Encoding) throws -> String {
		var rawContent = Data(capacity: 1024)
		while self.hasMoreData {
			let char = try self.readData(count: 2)
			if char.map({ $0 }) == terminator16 { break }
			rawContent += char
		}
		if let str = String(data: rawContent, encoding: encoding) {
			return str
		}
		throw ParseError.invalidStringEncoding
	}
}

public extension BytesParser {
	/// Read a UTF16 string
	/// - Parameters:
	///   - byteOrder: The expected byte ordering for the string
	///   - length: The number of 2-byte character to read
	/// - Returns: A string
	@inlinable func readStringUTF16(_ byteOrder: Endianness, length: Int) throws -> String {
		try self.readStringWide16(
			(byteOrder == .big) ? .utf16BigEndian : .utf16LittleEndian,
			length: length
		)
	}

	/// Read a big-endian utf16 string
	/// - Parameter length: The number of 4 byte characters to read
	/// - Returns: A string
	@inlinable @inline(__always) func readStringUTF16BE(length: Int) throws -> String {
		try self.readStringWide16(.utf16BigEndian, length: length)
	}

	/// Read a little-endian utf16 string
	/// - Parameter length: The number of 4 byte characters to read
	/// - Returns: A string
	@inlinable @inline(__always) func readStringUTF16LE(length: Int) throws -> String {
		try self.readStringWide16(.utf16LittleEndian, length: length)
	}

	/// Read a UTF16 string up to the string's null terminator
	///   - byteOrder: The expected byte ordering for the string
	/// - Returns: A string
	@inlinable func readStringUTF16NullTerminated(_ byteOrder: Endianness) throws -> String {
		try self.readStringWide16NullTerminated(
			encoding: (byteOrder == .big) ? .utf16BigEndian : .utf16LittleEndian
		)
	}
}

// MARK: UTF32 strings

public extension BytesParser {
	/// Read a wide (4-byte) string
	/// - Parameters:
	///   - length: The number of 4-byte characters
	///   - encoding: The expected string encoding (expects a 4 byte string encoding)
	/// - Returns: A string
	func readStringWide32(_ encoding: String.Encoding, length: Int) throws -> String {
		guard length > 0 else { return "" }
		let rawContent = try self.readData(count: length * 4)
		guard let str = String(data: rawContent, encoding: encoding) else {
			throw ParseError.invalidStringEncoding
		}
		return str
	}

	/// Read a big-endian utf32 string
	/// - Parameter length: The number of 4 byte characters to read
	/// - Returns: A string
	@inlinable @inline(__always) func readStringUTF32BE(length: Int) throws -> String {
		try self.readStringWide32(.utf32BigEndian, length: length)
	}

	/// Read a little-endian utf32 string
	/// - Parameter length: The number of 4 byte characters to read
	/// - Returns: A string
	@inlinable @inline(__always) func readStringUTF32LE(length: Int) throws -> String {
		try self.readStringWide32(.utf32LittleEndian, length: length)
	}

	/// Read a wide (4-byte) string up to the string's null terminator
	/// - Parameter encoding: The expected string encoding (expects a 4 byte string encoding)
	/// - Returns: A string
	func readStringWide32NullTerminated(_ encoding: String.Encoding) throws -> String {
		var rawContent = Data(capacity: 1024)
		while self.hasMoreData {
			let char = try self.readData(count: 4)
			if char.map({ $0 }) == terminator32 { break }
			rawContent += char
		}

		guard let str = String(data: rawContent, encoding: encoding) else {
			throw ParseError.invalidStringEncoding
		}

		return str
	}
}

public extension BytesParser {
	/// Read a UTF32 string
	/// - Parameters:
	///   - byteOrder: The expected byte ordering for the string (expects a 2 byte string encoding)
	///   - length: The number of 4-byte character to read
	/// - Returns: A string
	@inlinable func readStringUTF32(_ byteOrder: Endianness, length: Int) throws -> String {
		try self.readStringWide32(
			(byteOrder == .big) ? .utf32BigEndian : .utf32LittleEndian,
			length: length
		)
	}

	/// Read a UTF32 string up to the string's null terminator
	///   - byteOrder: The expected byte ordering for the string
	/// - Returns: A string
	@inlinable func readStringUTF32NullTerminated(_ byteOrder: Endianness) throws -> String {
		try self.readStringWide32NullTerminated((byteOrder == .big) ? .utf32BigEndian : .utf32LittleEndian)
	}
}
