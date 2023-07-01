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

	/// Endian types
	public enum Endianness {
		case bigEndian
		case littleEndian
	}

	/// Is there more data to read?
	public var hasMoreData: Bool { self.inputStream.hasBytesAvailable }

	/// The offset of the reader into the source
	public internal(set) var offset: Int = 0

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
		(Int(try self.readByte()) == 0x0) ? false : true
	}

	/// Read an integer value
	/// - Parameter byteOrder: Expected endianness for the integer
	/// - Returns: An integer value
	func readInteger<T: FixedWidthInteger>(_ byteOrder: BytesParser.Endianness) throws -> T {
		let typeSize = MemoryLayout<T>.size
		let intData = try self.next(typeSize)
		let rawInteger = intData.withUnsafeBytes { $0.load(as: T.self) }
		return byteOrder == .bigEndian ? rawInteger.bigEndian : rawInteger.littleEndian
	}

	/// Read an Int8 value
	func readInt8() throws -> Int8 {
		let byte = try self.readByte()

		// Remap the UInt8 value to an Int8 value
		return withUnsafePointer(to: byte) { ptr in
			ptr.withMemoryRebound(to: Int8.self, capacity: 1) { pointer in
				return pointer.pointee
			}
		}
	}

	/// Read an Int16
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readInt16(_ byteOrder: BytesParser.Endianness) throws -> Int16 {
		return try self.readInteger(byteOrder)
	}

	/// Read an Int32
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readInt32(_ byteOrder: BytesParser.Endianness) throws -> Int32 {
		return try self.readInteger(byteOrder)
	}

	/// Read an Int64
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readInt64(_ byteOrder: BytesParser.Endianness) throws -> Int64 {
		return try self.readInteger(byteOrder)
	}

	/// Read a UInt8
	@inlinable func readUInt8() throws -> UInt8 {
		return try self.readByte()
	}

	/// Read a UInt16
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readUInt16(_ byteOrder: BytesParser.Endianness) throws -> UInt16 {
		return try self.readInteger(byteOrder)
	}

	/// Read a UInt32
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readUInt32(_ byteOrder: BytesParser.Endianness) throws -> UInt32 {
		return try self.readInteger(byteOrder)
	}

	/// Read a UInt64
	/// - Parameter byteOrder: The expected endianness for the integer
	/// - Returns: An integer
	@inlinable func readUInt64(_ byteOrder: BytesParser.Endianness) throws -> UInt64 {
		return try self.readInteger(byteOrder)
	}
}

// MARK: Float values

public extension BytesParser {
	/// Read in an IEEE 754 float32 value ([IEEE 754 specification](http://ieeexplore.ieee.org/servlet/opac?punumber=4610933))
	func readFloat32(_ byteOrder: Endianness) throws -> Float32 {
		let rawValue: UInt32 = try readInteger(byteOrder)
		return Float32(bitPattern: rawValue)
	}

	/// Read in an IEEE 754 float64 value ([IEEE 754 specification](http://ieeexplore.ieee.org/servlet/opac?punumber=4610933))
	func readFloat64(_ byteOrder: Endianness) throws -> Float64 {
		let rawValue: UInt64 = try readInteger(byteOrder)
		return Float64(bitPattern: rawValue)
	}
}

// MARK: Single-byte strings

public extension BytesParser {
	/// Read a string (byte-based) using a length and string encoding
	/// - Parameters:
	///   - length: The expected number of characters in the string
	///   - encoding: The string encoding to use when reading
	///   - lengthIncludesTerminator: If true, assumes that the _last_ character in the string is the null terminator.
	/// - Returns: A string
	func readString(length: Int, encoding: String.Encoding, lengthIncludesTerminator: Bool = false) throws -> String {
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
	/// Slower as we have to read byte-by-byte. Also less safe than the length specific version!
	func readStringNullTerminated(encoding: String.Encoding) throws -> String {
		var rawContent = try readUpToNextInstanceOfByte(byte: 0x00)
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

// MARK: wide strings

internal let terminator16: [UInt8] = [0x00, 0x00]

public extension BytesParser {
	/// Read a wide string (2-byte) with a particular encoding
	func readWide16String(length: Int, encoding: String.Encoding) throws -> String {
		guard length > 0 else { return "" }
		let rawContent = try self.next(length * 2)
		if let str = String(data: rawContent, encoding: encoding) {
			return str
		}
		throw ParseError.invalidStringEncoding
	}

	/// Read a wide string up to the string's null terminator
	func readWide16StringNullTerminated(encoding: String.Encoding) throws -> String {
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

	/// Read `length` count of 2-byte characters as a UTF16 string
	@inlinable func readUTF16String(_ byteOrder: Endianness, length: Int) throws -> String {
		try self.readWide16String(
			length: length,
			encoding: (byteOrder == .bigEndian) ? .utf16BigEndian : .utf16LittleEndian
		)
	}

	/// Read a wide16 string up to the string's null terminator
	/// - Parameter encoding: The expected string encoding
	/// - Returns: A string
	@inlinable func readUTF16NullTerminatedString(_ byteOrder: Endianness) throws -> String {
		try self.readWide16StringNullTerminated(
			encoding: (byteOrder == .bigEndian) ? .utf16BigEndian : .utf16LittleEndian
		)
	}
}

// MARK: UTF32 strings

internal let terminator32: [UInt8] = [0x00, 0x00, 0x00, 0x00]

extension BytesParser {
	/// Read `length` count of 4-byte characters as a string
	/// - Parameters:
	///   - length: The number of 4-byte characters
	///   - encoding: The expected string encoding (expects a 4 byte string encoding)
	/// - Returns: A string
	func readWide32String(length: Int, encoding: String.Encoding) throws -> String {
		guard length > 0 else { return "" }
		let rawContent = try self.next(length * 4)
		guard let str = String(data: rawContent, encoding: encoding) else {
			throw ParseError.invalidStringEncoding
		}
		return str
	}

	/// Read a wide string (32-bit, 4 byte) up to the string's null terminator
	/// - Parameter encoding: The expected string encoding (expects a 4 byte string encoding)
	/// - Returns: A string
	func readWide32StringNullTerminated(encoding: String.Encoding) throws -> String {
		var rawContent = Data(capacity: 1024)
		while self.hasMoreData {
			let char = try self.readData(count: 4)
			if char.map({ $0 }) == terminator32 { break }
			rawContent += char
		}
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
