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

// MARK: - Strings

public extension BytesWriter {
	/// Write a string using a particular single-byte string encoding
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	/// - Returns: The number of bytes written
	@discardableResult
	func writeStringSingleByteEncoding(_ string: String, encoding: String.Encoding, includeNullTerminator: Bool = false) throws -> Int {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}

		try self.writeData(data)
		if includeNullTerminator {
			try self.writeByte(BytesParser.terminator8)
		}
		return data.count + (includeNullTerminator ? 1 : 0)
	}

	/// Write am ASCII String
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, includes a string termination character (00)
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeStringASCII(_ string: String, includeNullTerminator: Bool = false) throws -> Int {
		try self.writeStringSingleByteEncoding(string, encoding: .ascii, includeNullTerminator: includeNullTerminator)
	}

	/// Write a UTF8 String
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, includes a string termination character (00)
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeStringUTF8(_ string: String, includeNullTerminator: Bool = false) throws -> Int {
		try self.writeStringSingleByteEncoding(string, encoding: .utf8, includeNullTerminator: includeNullTerminator)
	}

	/// Write a isoLatin1 String
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, includes a string termination character (00)
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeStringISOLatin1(_ string: String, includeNullTerminator: Bool = false) throws -> Int {
		try self.writeStringSingleByteEncoding(string, encoding: .isoLatin1, includeNullTerminator: includeNullTerminator)
	}
}

public extension BytesWriter {
	/// Write a wide (2-byte) string
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	///   - includeNullTerminator: If true, includes a string termination character (00 00)
	/// - Returns: The number of bytes written
	@discardableResult
	func writeStringWide16(_ string: String, encoding: String.Encoding, includeNullTerminator: Bool = false) throws -> Int {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
		if includeNullTerminator {
			try self.writeBytes(BytesParser.terminator16)
		}

		return data.count + (includeNullTerminator ? 2 : 0)
	}

	/// Write a UTF16 big endian string
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, includes a string termination character (00 00)
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeStringUTF16BE(_ string: String, includeNullTerminator: Bool = false) throws -> Int {
		try self.writeStringWide16(string, encoding: .utf16BigEndian, includeNullTerminator: includeNullTerminator)
	}

	/// Write a UTF16 little endian string
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, includes a string termination character (00 00)
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeStringUTF16LE(_ string: String, includeNullTerminator: Bool = false) throws -> Int {
		try self.writeStringWide16(string, encoding: .utf16LittleEndian, includeNullTerminator: includeNullTerminator)
	}
}

public extension BytesWriter {
	/// Write a wide (4-byte) string
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	///   - includeNullTerminator: If true, adds a string termination character (00 00 00 00)
	/// - Returns: The number of bytes written
	@discardableResult
	func writeStringWide32(_ string: String, encoding: String.Encoding, includeNullTerminator: Bool = false) throws -> Int {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
		if includeNullTerminator {
			try self.writeBytes(BytesParser.terminator32)
		}
		return data.count + (includeNullTerminator ? 4 : 0)
	}

	/// Write a wide (4-byte) string
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The endianness
	///   - includeNullTerminator: If true, adds a string termination character (00 00 00 00)
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeStringUTF32(
		_ string: String,
		endianness: BytesParser.Endianness,
		includeNullTerminator: Bool = false
	) throws -> Int {
		try self.writeStringWide32(
			string,
			encoding: endianness == .big ? .utf32BigEndian : .utf32LittleEndian,
			includeNullTerminator: includeNullTerminator
		)
	}

	/// Write a UTF32 big endian string
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, adds a string termination character (00 00 00 00)
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeStringUTF32BE(_ string: String, includeNullTerminator: Bool = false) throws -> Int {
		try self.writeStringWide32(string, encoding: .utf32BigEndian, includeNullTerminator: includeNullTerminator)
	}

	/// Write a UTF32 little endian string
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, adds a string termination character (00 00 00 00)
	/// - Returns: The number of bytes written
	@discardableResult
	@inlinable func writeStringUTF32LE(_ string: String, includeNullTerminator: Bool = false) throws -> Int {
		try self.writeStringWide32(string, encoding: .utf32LittleEndian, includeNullTerminator: includeNullTerminator)
	}
}
