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
	/// Write a string using a particular string encoding
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	func writeByteString(_ string: String, encoding: String.Encoding) throws {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
	}

	/// Write a null-terminated string with encoding
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	func writeByteStringNullTerminated(_ string: String, encoding: String.Encoding) throws {
		try self.writeByteString(string, encoding: encoding)
		try self.writeByte(0x00)
	}
}

public extension BytesWriter {
	/// Write a wide (2-byte) string without a terminator
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	///
	/// Example usage :-
	///
	/// ```swift
	/// let data = try BytesWriter.assemble { writer in
	///    try writer.writeWide16String(message, encoding: .utf16LittleEndian)
	/// }
	/// ```
	func writeWide16String(_ string: String, encoding: String.Encoding) throws {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
	}

	/// Write a wide (2-byte) string with a null terminator (0x00 0x00)
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	///
	/// Example usage :-
	///
	/// ```swift
	/// let data = try BytesWriter.assemble { writer in
	///    try writer.writeWide16StringNullTerminated(message, encoding: .utf16LittleEndian)
	/// }
	func writeWide16StringNullTerminated(_ string: String, encoding: String.Encoding) throws {
		try self.writeWide16String(string, encoding: encoding)
		try self.writeBytes(terminator16)
	}
}

public extension BytesWriter {
	/// Write a UTF32 (4-byte) string without a terminator
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	///
	/// Example usage :-
	///
	/// ```swift
	/// let data = try BytesWriter.assemble { writer in
	///    try writer.writeWide32String(message, encoding: .utf32LittleEndian)
	/// }
	func writeWide32String(_ string: String, encoding: String.Encoding) throws {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
	}

	/// Write a UTF32 (4-byte) string with a terminator
	/// - Parameters:
	///   - string: The string to write
	///   - encoding: The encoding to use
	///
	/// Example usage :-
	///
	/// ```swift
	/// let data = try BytesWriter.assemble { writer in
	///    try writer.writeWide32StringNullTerminated(message, encoding: .utf32LittleEndian)
	/// }
	func writeWide32StringNullTerminated(_ string: String, encoding: String.Encoding) throws {
		try self.writeWide32String(string, encoding: encoding)
		try self.writeBytes(terminator32)
	}
}
