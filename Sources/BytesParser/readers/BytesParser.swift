//
//  BytesParser.swift
//
//  Copyright © 2023 Darren Ford. All rights reserved.
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

/// An object that can iterate through raw byte data and extract parsable data (eg. integers, floats etc)
public class BytesParser {
	/// Errors thrown by the parser
	public enum ParseError: Error {
		case invalidFile
		case endOfData
		case invalidStringEncoding
	}

	/// Is there more data to read?
	public var hasMoreData: Bool { self.inputStream.hasBytesAvailable }

	/// Create a byte parser from a data object
	public init(data: Data) {
		self.inputStream = InputStream(data: data)
		self.inputStream.open()
	}

	/// Create a byte parser from an array of bytes
	public init(content: [UInt8]) {
		self.inputStream = InputStream(data: Data(content))
		self.inputStream.open()
	}

	/// Create a byte parser with an opened input stream
	public init(inputStream: InputStream) {
		self.inputStream = inputStream
		self.inputStream.open()
	}

	/// Create a byte parser from the contents of a local file
	public init(fileURL: URL) throws {
		guard
			fileURL.isFileURL,
			let inputStream = InputStream(url: fileURL)
		else {
			throw ParseError.invalidFile
		}
		self.inputStream = inputStream
		inputStream.open()
	}

	// private
	let readBuffer = ByteBuffer()

	// The stream containing the data to be parsed
	let inputStream: InputStream
}

// MARK: Bytes and Data

public extension BytesParser {
	/// Read a single byte
	func readByte() throws -> UInt8 {
		guard let data = try self.next(1).first else {
			throw ParseError.endOfData
		}
		return data
	}

	/// Read the next `count` bytes into a Data object
	func readData(count: Int) throws -> Data {
		try self.next(count)
	}

	/// Read the next `count` bytes
	func readBytes(count: Int) throws -> [UInt8] {
		try self.readData(count: count).map { $0 }
	}
}

// MARK: Up to next byte instance

public extension BytesParser {
	/// Reads the bytes up to **and including** the next instance of `byte` or EOD.
	func readUpToNextInstanceOfByte(byte: UInt8) throws -> Data {
		try self.nextUpToIncluding(byte)
	}

	/// Read up to **and including** the next instance of a **single** null byte (0x00)
	func readUpToNextNullByte() throws -> Data {
		try self.nextUpToIncluding(0x00)
	}
}

// MARK: Integers, Bool and floats

public extension BytesParser {
	/// Read a 'bool' value byte from the stream
	///
	/// A 0x0 byte == false, anything else is true (ie. not false)
	func readBool() throws -> Bool {
		(Int(try readByte()) == 0x0) ? false : true
	}

	/// Read an integer value
	/// - Parameter isBigEndian: Expected endianness for the integer
	/// - Returns: An integer value
	func readInteger<T: FixedWidthInteger>(isBigEndian: Bool) throws -> T {
		let typeSize = MemoryLayout<T>.size
		let intData = try self.next(typeSize)
		if isBigEndian {
			return intData.prefix(typeSize).reduce(0) { $0 << 8 | T($1) }
		}
		else {
			return intData.prefix(typeSize).reversed().reduce(0) { $0 << 8 | T($1) }
		}
	}

	/// Read a big endian int value
	@inlinable func readBigEndian<T: FixedWidthInteger>() throws -> T {
		try self.readInteger(isBigEndian: true)
	}

	/// Read a little endian int value
	@inlinable func readLittleEndian<T: FixedWidthInteger>() throws -> T {
		try self.readInteger(isBigEndian: false)
	}
}

public extension BytesParser {
	@inlinable func readInt8() throws -> Int8 {
		return try self.readInteger(isBigEndian: true)
	}
	@inlinable func readInt16(isBigEndian: Bool = true) throws -> Int16 {
		return try self.readInteger(isBigEndian: isBigEndian)
	}
	@inlinable func readInt32(isBigEndian: Bool = true) throws -> Int32 {
		return try self.readInteger(isBigEndian: isBigEndian)
	}
	@inlinable func readInt64(isBigEndian: Bool = true) throws -> Int64 {
		return try self.readInteger(isBigEndian: isBigEndian)
	}

	@inlinable func readUInt8() throws -> UInt8 {
		return try self.readByte()
	}
	@inlinable func readUInt16(isBigEndian: Bool = true) throws -> UInt16 {
		return try self.readInteger(isBigEndian: isBigEndian)
	}
	@inlinable func readUInt32(isBigEndian: Bool = true) throws -> UInt32 {
		return try self.readInteger(isBigEndian: isBigEndian)
	}
	@inlinable func readUInt64(isBigEndian: Bool = true) throws -> UInt64 {
		return try self.readInteger(isBigEndian: isBigEndian)
	}
}

// MARK: Float values

public extension BytesParser {
	/// Read in an IEEE 754 float32 value ([IEEE 754 specification](http://ieeexplore.ieee.org/servlet/opac?punumber=4610933))
	func readFloat32(isBigEndian: Bool = true) throws -> Float32 {
		let rawValue: UInt32 = try readInteger(isBigEndian: isBigEndian)
		return Float32(bitPattern: rawValue)
	}

	/// Read in an IEEE 754 float64 value ([IEEE 754 specification](http://ieeexplore.ieee.org/servlet/opac?punumber=4610933))
	func readFloat64(isBigEndian: Bool = true) throws -> Float64 {
		let rawValue: UInt64 = try readInteger(isBigEndian: isBigEndian)
		return Float64(bitPattern: rawValue)
	}
}

// MARK: Ascii strings

public extension BytesParser {
	/// Read an ascii string of **specific** length of bytes
	/// - Parameters:
	///   - length: The expected number of characters in the string
	///   - lengthIncludesTerminator: If true, assumes that the _last_ character in the string is the null terminator.
	/// - Returns: An ascii-encoded string
	func readAsciiString(length: Int, lengthIncludesTerminator: Bool = false) throws -> String {
		let stringData = try self.readStringBytes(length: length, lengthIncludesTerminator: lengthIncludesTerminator)
		guard let str = String(data: stringData, encoding: .ascii) else {
			throw ParseError.invalidStringEncoding
		}
		return str
	}

	/// Read a utf8 string of **specific** length of bytes
	/// - Parameters:
	///   - length: The expected number of characters in the string
	///   - lengthIncludesTerminator: If true, assumes that the _last_ character in the string is the null terminator.
	/// - Returns: An ascii-encoded string
	func readUTF8String(length: Int, lengthIncludesTerminator: Bool = false) throws -> String {
		let stringData = try self.readStringBytes(length: length, lengthIncludesTerminator: lengthIncludesTerminator)
		guard let str = String(data: stringData, encoding: .utf8) else {
			throw ParseError.invalidStringEncoding
		}
		return str
	}

	private func readStringBytes(length: Int, lengthIncludesTerminator: Bool = false) throws -> Data {
		var stringData = try self.readData(count: length)
		if lengthIncludesTerminator, stringData.last == 0x00 {
			stringData = stringData.dropLast(1)
		}
		return stringData
	}
}

public extension BytesParser {
	/// Read in ascii null terminated string
	///
	/// Slower as we have to read byte-by-byte
	/// Also less safe than the length specific version!
	func readAsciiNullTerminatedString() throws -> String {
		let rawContent = try readUpToNextNullByteAndDiscardForString()
		guard let str = String(data: rawContent, encoding: .ascii) else {
			throw ParseError.invalidStringEncoding
		}
		return str
	}

	/// Read in a UTF8 null terminated string
	///
	/// Slower as we have to read byte-by-byte
	/// Also less safe than the length specific version!
	func readUTF8NullTerminatedString() throws -> String {
		let rawContent = try readUpToNextNullByteAndDiscardForString()
		guard let str = String(data: rawContent, encoding: .utf8) else {
			throw ParseError.invalidStringEncoding
		}
		return str
	}

	private func readUpToNextNullByteAndDiscardForString() throws -> Data {
		var rawContent = try readUpToNextInstanceOfByte(byte: 0x00)
		if rawContent.last == 0x00 {
			// Remove the last terminator character
			// Note that the last character is _not_ guaranteed to be nil IF we hit the EOD
			rawContent = rawContent.dropLast(1)
		}
		return rawContent
	}
}

// MARK: wide strings

private let terminator16: [UInt8] = [0x00, 0x00]

extension BytesParser {
	/// Read `length` count of 2-byte characters as a UTF16 string
	func readUTF16String(length: Int, isBigEndian: Bool = true) throws -> String {
		guard length > 0 else { return "" }
		let rawContent = try self.next(length * 2)
		let encoding: String.Encoding = isBigEndian ? .utf16BigEndian : .utf16LittleEndian
		if let str = String(data: rawContent, encoding: encoding) {
			return str
		}
		throw ParseError.invalidStringEncoding
	}

	/// Read in a series of 2-byte characters terminated with `0x00 0x00`
	func readUTF16NullTerminatedString(isBigEndian: Bool = true) throws -> String {
		var rawContent = Data(capacity: 1024)
		while self.hasMoreData {
			let char = try self.readData(count: 2)
			if char.map({ $0 }) == terminator16 { break }
			rawContent += char
		}

		let encoding: String.Encoding = isBigEndian ? .utf16BigEndian : .utf16LittleEndian
		if let str = String(data: rawContent, encoding: encoding) {
			return str
		}
		throw ParseError.invalidStringEncoding
	}
}

// MARK: UTF32 strings

private let terminator32: [UInt8] = [0x00, 0x00, 0x00, 0x00]

extension BytesParser {
	/// Read `length` count of 4-byte characters as a UTF16 string
	func readUTF32String(length: Int, isBigEndian: Bool = true) throws -> String {
		guard length > 0 else { return "" }
		let rawContent = try self.next(length * 4)
		let encoding: String.Encoding = isBigEndian ? .utf32BigEndian : .utf32LittleEndian
		if let str = String(data: rawContent, encoding: encoding) {
			return str
		}
		throw ParseError.invalidStringEncoding
	}

	/// Read in a series of 4-byte characters terminated with `0x00 0x00 0x00 0x00`
	func readUTF32NullTerminatedString(isBigEndian: Bool = true) throws -> String {
		var rawContent = Data(capacity: 1024)
		while self.hasMoreData {
			let char = try self.readData(count: 4)
			if char.map({ $0 }) == terminator32 { break }
			rawContent += char
		}

		let encoding: String.Encoding = isBigEndian ? .utf16BigEndian : .utf16LittleEndian
		if let str = String(data: rawContent, encoding: encoding) {
			return str
		}
		throw ParseError.invalidStringEncoding
	}
}

// MARK: - Convenience readers

public extension BytesParser {
	/// Parse the contents of a Data
	@inlinable static func parse(data: Data, _ block: (BytesParser) throws -> Void) throws {
		let parser = BytesParser(data: data)
		try block(parser)
	}

	/// Parse the contents of a byte array
	@inlinable static func parse(bytes: [UInt8], _ block: (BytesParser) throws -> Void) throws {
		let parser = BytesParser(content: bytes)
		try block(parser)
	}

	/// Parse the contents of a local file
	@inlinable static func parse(fileURL: URL, _ block: (BytesParser) throws -> Void) throws {
		let parser = try BytesParser(fileURL: fileURL)
		try block(parser)
	}

	/// Parse the contents of an input stream
	@inlinable static func parse(inputStream: InputStream, _ block: (BytesParser) throws -> Void) throws {
		let parser = BytesParser(inputStream: inputStream)
		try block(parser)
	}
}
