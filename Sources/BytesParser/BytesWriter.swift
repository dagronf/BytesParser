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
		case unableToWriteBytes
		case notSupported
		case noDataAvailable
	}

	internal let outputStream: OutputStream

	/// The number of bytes currently written to the output
	public private(set) var count: Int = 0

	/// Create a byte writer that writes to a Data() object
	public init() throws {
		self.outputStream = OutputStream(toMemory: ())
		self.outputStream.open()
	}

	/// Create a byte writer that writes to a file URL
	public init(fileURL: URL) throws {
		assert(fileURL.isFileURL)
		guard let stream = OutputStream(toFileAtPath: fileURL.path, append: false) else {
			throw BytesWriter.WriterError.cannotOpenOutputFile
		}
		self.outputStream = stream
		stream.open()
	}

	/// Must be called when you've finished writing.
	public func complete() { self.outputStream.close() }

	/// If the writer supports generating data, the data that was generated
	public func data() throws -> Data {
		guard let data = self.outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
			throw BytesWriter.WriterError.noDataAvailable
		}
		return data
	}
}

// MARK: - Data and bytes

public extension BytesWriter {
	/// Write the contents of a Data object to the output
	func writeData(_ data: Data) throws {
		try data.withUnsafeBytes { try self.writeBuffer($0, byteCount: data.count) }
	}

	/// Write an array of bytes to the output
	func writeBytes(_ bytes: [UInt8]) throws {
		let writtenCount = self.outputStream.write(bytes, maxLength: bytes.count)
		guard writtenCount == bytes.count else {
			throw BytesWriter.WriterError.unableToWriteBytes
		}
		self.count += bytes.count
	}

	/// Write a single byte to the output
	@inlinable func writeByte(_ byte: UInt8) throws {
		try self.writeBytes([byte])
	}
}

private extension BytesWriter {
	/// Write the contents of a raw buffer pointer to the outputstream
	func writeBuffer(_ buffer: UnsafeRawBufferPointer, byteCount: Int) throws {
		guard let base = buffer.baseAddress else {
			throw BytesWriter.WriterError.unableToWriteBytes
		}

		// Map the buffer contents to a UInt8 memory buffer
		try base.withMemoryRebound(to: UInt8.self, capacity: byteCount) { pointer in
			let writtenCount = self.outputStream.write(pointer, maxLength: byteCount)
			guard writtenCount == byteCount else {
				throw BytesWriter.WriterError.unableToWriteBytes
			}
		}
		self.count += byteCount
	}
}

// MARK: - Bool

public extension BytesWriter {
	/// Write a bool value byte (0x00 == false, 0x01 == true)
	func writeBool(_ value: Bool) throws {
		return try self.writeByte(value ? 0x01 : 0x00)
	}
}

// MARK: - Integers and floats

public extension BytesWriter {
	/// Write an integer to the stream using the specified endianness
	func writeInteger<T: FixedWidthInteger>(_ value: T, _ byteOrder: BytesParser.Endianness) throws {
		// Map the value to the correct endianness...
		let mapped = (byteOrder == .bigEndian) ? value.bigEndian : value.littleEndian

		// ... then write out the raw bytes
		try withUnsafeBytes(of: mapped) { pointer in
			try self.writeBuffer(pointer, byteCount: MemoryLayout<T>.size)
		}
	}
}

public extension BytesWriter {
	/// Write an Int8 value
	/// - Parameter value: The value to write
	@inlinable func writeInt8(_ value: Int8) throws {
		try self.writeInteger(value, .bigEndian)
	}

	@inlinable func writeInt16(_ value: Int16, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value, byteOrder)
	}

	@inlinable func writeInt32(_ value: Int32, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value, byteOrder)
	}

	@inlinable func writeInt64(_ value: Int64, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value, byteOrder)
	}

	@inlinable func writeUInt8(_ value: UInt8) throws {
		try self.writeByte(value)
	}

	@inlinable func writeUInt16(_ value: UInt16, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value, byteOrder)
	}

	@inlinable func writeUInt32(_ value: UInt32, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value, byteOrder)
	}

	@inlinable func writeUInt64(_ value: UInt64, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value, byteOrder)
	}
}

public extension BytesWriter {
	/// Write a float32 value to the stream using the IEEE 754 specification
	@inlinable func writeFloat32(_ value: Float32, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value.bitPattern, byteOrder)
	}

	/// Write a float64 (Double) value to the stream using the IEEE 754 specification
	@inlinable func writeFloat64(_ value: Float64, _ byteOrder: BytesParser.Endianness) throws {
		try self.writeInteger(value.bitPattern, byteOrder)
	}
}

// MARK: - Strings

public extension BytesWriter {
	/// Write a string with encoding
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
	func writeWide16String(_ string: String, encoding: String.Encoding) throws {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
	}

	/// Write a wide (2-byte) string with a null terminator (0x00 0x00)
	func writeWide16StringNullTerminated(_ string: String, encoding: String.Encoding) throws {
		try self.writeWide16String(string, encoding: encoding)
		try self.writeBytes(terminator16)
	}
}

public extension BytesWriter {
	/// Write a super-wide (4-byte) string without a terminator
	func writeWide32String(_ string: String, encoding: String.Encoding) throws {
		guard let data = string.data(using: encoding) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writeData(data)
	}

	/// Write a super-wide (4-byte) string with a terminator
	func writeWide32StringNullTerminated(_ string: String, encoding: String.Encoding) throws {
		try self.writeWide32String(string, encoding: encoding)
		try self.writeBytes(terminator32)
	}
}

public extension BytesWriter {
	/// Pad the output to an N byte boundary
	/// - Parameter
	///   - byteBoundary: The boundary size to use when adding padding bytes
	///   - byte: The padding byte to use, or null if not specified
	func padToNByteBoundary(byteBoundary: Int, using byte: UInt8 = 0x00) throws {
		let amount = self.count % byteBoundary
		if amount == 0 { return }
		let data = Array<UInt8>(repeating: byte, count: byteBoundary - amount)
		try self.writeBytes(data)
	}

	/// Pad the output to an four byte boundary
	/// - Parameter byte: The padding byte to use, or null if not specified
	@inlinable func padToFourByteBoundary(using byte: UInt8 = 0x00) throws {
		try self.padToNByteBoundary(byteBoundary: 4, using: byte)
	}

	/// Pad the output to an eight byte boundary
	/// - Parameter byte: The padding byte to use, or null if not specified
	func padToEightByteBoundary(using byte: UInt8 = 0x00) throws {
		try self.padToNByteBoundary(byteBoundary: 8, using: byte)
	}
}

// MARK: - Convenience writers

public extension BytesWriter {
	/// Generate a Data object
	/// - Parameter block: The block to write formatted data using a `BytesWriter` to the Data object
	/// - Returns: A data object
	static func assemble(_ block: (BytesWriter) throws -> Void) throws -> Data {
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
	static func assemble(fileURL: URL, _ block: (BytesWriter) throws -> Void) throws {
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
