//
//  BytesWriter.swift
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

public class BytesWriter {

	/// Errors throws by the writer
	public enum WriterError: Error {
		case cannotConvertStringEncoding
		case cannotOpenOutputFile
		case unableToWriteBytesToFile
		case notSupported
		case noDataAvailable
	}

	internal let writer: OutputStream

	/// Create a byte writer that writes to a Data() object
	public init() throws {
		self.writer = OutputStream(toMemory: ())
		self.writer.open()
	}

	/// Create a byte writer that writes to a file URL
	public init(fileURL: URL) throws {
		assert(fileURL.isFileURL)
		guard let stream = OutputStream(toFileAtPath: fileURL.path, append: false) else {
			throw BytesWriter.WriterError.cannotOpenOutputFile
		}
		self.writer = stream
		stream.open()
	}

	/// Must be called when you've finished writing.
	public func complete() { self.writer.close() }

	/// If the writer supports generating data, the data that was generated
	public func data() throws -> Data {
		guard let data = self.writer.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
			throw BytesWriter.WriterError.noDataAvailable
		}
		return data
	}
}

// MARK: - Data and bytes

public extension BytesWriter {
	/// Write the contents of a Data object to the output
	func writeData(_ data: Data) throws {
		let writtenCount = withUnsafeBytes(of: data) {
			writer.write($0.baseAddress!, maxLength: data.count)
		}
		guard writtenCount == data.count else {
			throw BytesWriter.WriterError.unableToWriteBytesToFile
		}
	}

	/// Write an array of bytes to the output
	func writeBytes(_ bytes: [UInt8]) throws {
		let writtenCount = writer.write(bytes, maxLength: bytes.count)
		guard writtenCount == bytes.count else {
			throw BytesWriter.WriterError.unableToWriteBytesToFile
		}
	}

	/// Write a single byte to the output
	@inlinable func writeByte(_ byte: UInt8) throws {
		try self.writeBytes([byte])
	}
}

// MARK: - Bool

public extension BytesWriter {
	/// Write a bool value byte (0x00 == false, 0x01 == true)
	func writeBool(_ value: Bool) throws {
		return try writeByte(value ? 0x01 : 0x00)
	}
}

// MARK: - Integers and floats

public extension BytesWriter {
	/// Write a big-endian representation of an integer value to the stream
	func writeBigEndian<T: FixedWidthInteger>(_ value: T) throws {
		return try writeInteger(value.bigEndian)
	}

	/// Write a little-endian representation of an integer value to the stream
	func writeLittleEndian<T: FixedWidthInteger>(_ value: T) throws {
		return try writeInteger(value.littleEndian)
	}

	/// Write an integer to the stream using the specified endianness
	func write<T: FixedWidthInteger>(_ value: T, isBigEndian: Bool = true) throws {
		isBigEndian ? try writeBigEndian(value) : try writeLittleEndian(value)
	}

	/// Write the integer's bytes into a data object
	private func writeInteger<T: FixedWidthInteger>(_ value: T) throws {
		return try withUnsafeBytes(of: value) {
			try self.writeData(Data($0))
		}
	}
}

public extension BytesWriter {

	@inlinable func writeInt8Value(_ value: Int8) throws {
		try self.writeBigEndian(value)
	}
	@inlinable func writeInt16Value(_ value: Int16, isBigEndian: Bool = true) throws {
		try self.write(value, isBigEndian: isBigEndian)
	}
	@inlinable func writeInt32Value(_ value: Int32, isBigEndian: Bool = true) throws {
		try self.write(value, isBigEndian: isBigEndian)
	}
	@inlinable func writeInt64Value(_ value: Int64, isBigEndian: Bool = true) throws {
		try self.write(value, isBigEndian: isBigEndian)
	}

	@inlinable func writeUInt8Value(_ value: UInt8) throws {
		try self.writeByte(value)
	}
	@inlinable func writeUInt16Value(_ value: UInt16, isBigEndian: Bool = true) throws {
		try self.write(value, isBigEndian: isBigEndian)
	}
	@inlinable func writeUInt32Value(_ value: UInt32, isBigEndian: Bool = true) throws {
		try self.write(value, isBigEndian: isBigEndian)
	}
	@inlinable func writeUInt64Value(_ value: UInt64, isBigEndian: Bool = true) throws {
		try self.write(value, isBigEndian: isBigEndian)
	}
}

public extension BytesWriter {
	/// Write a float32 value to the stream using the IEEE 754 specification
	@inlinable func writeFloat32(_ value: Float32, isBigEndian: Bool = true) throws {
		try self.write(value.bitPattern, isBigEndian: true)
	}

	/// Write a float64 (Double) value to the stream using the IEEE 754 specification
	@inlinable func writeFloat64(_ value: Float64, isBigEndian: Bool = true) throws {
		try self.write(value.bitPattern, isBigEndian: isBigEndian)
	}
}

// MARK: - Strings

public extension BytesWriter {
	func writeAsciiNullTerminated(_ string: String) throws {
		try self.writeAsciiNoTerminator(string)
		try self.writeByte(0x00)
	}

	func writeAsciiNoTerminator(_ string: String) throws {
		guard let data = string.data(using: .ascii) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
	}
}

public extension BytesWriter {
	/// Write a null terminated UTF8 string
	func writeUTF8NullTerminated(_ string: String) throws {
		try self.writeUTF8NoTerminator(string)
		try self.writeByte(0x00)
	}

	/// Write a UTF8 string without a terminator
	func writeUTF8NoTerminator(_ string: String) throws {
		guard let data = string.data(using: .utf8) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
	}
}

// MARK: - Convenience writers

public extension BytesWriter {
	/// Generate a Data object
	/// - Parameter block: The block to write formatted data using a `BytesWriter` to the Data object
	/// - Returns: A data object
	static func generate(_ block: (BytesWriter) throws -> Void) throws -> Data {
		let writer = try BytesWriter()
		do {
			try block(writer)
			writer.complete()
			return try writer.data()
		}
		catch {
			throw error
		}
	}

	/// Generate a file
	/// - Parameter block: The block to write formatted data using a `BytesWriter` to the file object
	static func generate(fileURL: URL, _ block: (BytesWriter) throws -> Void) throws {
		let writer = try BytesWriter(fileURL: fileURL)
		do {
			try block(writer)
			writer.complete()
		}
		catch {
			throw error
		}
	}
}
