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

// MARK: - Strings

public extension BytesWriter {
	/// Returns the expected byte length for the given string using an encoding (not including null termination)
	/// - Parameters:
	///   - string: The string to encode
	///   - encoding: The string encoding to use
	/// - Returns: The length of the encoded string in bytes
	@inlinable func expectedStringByteLength(for string: String, encoding: String.Encoding) throws -> Int {
		guard let len = string.data(using: encoding)?.count else {
			throw WriterError.cannotConvertStringEncoding
		}
		return len
	}
}

public extension BytesWriter {
	/// Write a string using a particular string encoding
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	func writeStringByte(_ string: String, encoding: String.Encoding, includeNullTerminator: Bool = false) throws {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
		if includeNullTerminator {
			try self.writeByte(BytesParser.terminator8)
		}
	}

	/// Write a UTF8 String
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, includes a string termination character (00 00)
	@inlinable func writeStringUTF8(_ string: String, includeNullTerminator: Bool = false) throws {
		try self.writeStringByte(string, encoding: .utf8, includeNullTerminator: includeNullTerminator)
	}
}

public extension BytesWriter {
	/// Write a wide (2-byte) string
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	///   - includeNullTerminator: If true, includes a string termination character (00 00)
	///
	/// Example usage :-
	///
	/// ```swift
	/// let data = try BytesWriter.assemble { writer in
	///    try writer.writeWide16String(message, encoding: .utf16LittleEndian)
	/// }
	/// ```
	func writeStringWide16(_ string: String, encoding: String.Encoding, includeNullTerminator: Bool = false) throws {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
		if includeNullTerminator {
			try self.writeBytes(BytesParser.terminator16)
		}
	}

	/// Write a UTF16 big endian string
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, includes a string termination character (00 00)
	@inlinable func writeStringUTF16BE(_ string: String, includeNullTerminator: Bool = false) throws {
		try self.writeStringWide16(string, encoding: .utf16BigEndian, includeNullTerminator: includeNullTerminator)
	}

	/// Write a UTF16 little endian string
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, includes a string termination character (00 00)
	@inlinable func writeStringUTF16LE(_ string: String, includeNullTerminator: Bool = false) throws {
		try self.writeStringWide16(string, encoding: .utf16LittleEndian, includeNullTerminator: includeNullTerminator)
	}
}

public extension BytesWriter {
	/// Write a wide (4-byte) string
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	///   - includeNullTerminator: If true, adds a string termination character (00 00 00 00)
	func writeStringWide32(_ string: String, encoding: String.Encoding, includeNullTerminator: Bool = false) throws {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
		if includeNullTerminator {
			try self.writeBytes(BytesParser.terminator32)
		}
	}

	/// Write a UTF32 big endian string
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, adds a string termination character (00 00 00 00)
	@inlinable func writeStringUTF32BE(_ string: String, includeNullTerminator: Bool = false) throws {
		try self.writeStringWide32(string, encoding: .utf32BigEndian, includeNullTerminator: includeNullTerminator)
	}

	/// Write a UTF32 little endian string
	/// - Parameters:
	///   - string: The string to write
	///   - includeNullTerminator: If true, adds a string termination character (00 00 00 00)
	@inlinable func writeStringUTF32LE(_ string: String, includeNullTerminator: Bool = false) throws {
		try self.writeStringWide32(string, encoding: .utf32LittleEndian, includeNullTerminator: includeNullTerminator)
	}
}
