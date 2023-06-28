//
//  File.swift
//  
//
//  Created by Darren Ford on 28/6/2023.
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

	let writer: BytesWriterGenerator

	/// Create a byte writer that writes to a Data() object
	public init() throws {
		self.writer = try OutputDataWriter()
	}

	/// Create a byte writer that writes to a file URL
	public init(fileURL: URL) throws {
		self.writer = try OutputFileWriter(fileURL: fileURL)
	}

	/// Create a byte writer using a ByteWriterGenerator
	public init(_ writer: BytesWriterGenerator) throws {
		self.writer = writer
	}

	/// Must be called when you've finished writing.
	public func complete() { self.writer.complete() }

	/// If the writer supports generating data, the data
	public func data() throws -> Data { try self.writer.data() }
}

// MARK: - Data and bytes

public extension BytesWriter {
	/// Write an array of bytes to the output
	func writeBytes(_ bytes: [UInt8]) throws {
		try self.writer.writeBytes(bytes)
	}

	/// Write a single byte to the output
	func writeByte(_ byte: UInt8) throws {
		try self.writer.writeByte(byte)
	}

	/// Write the contents of a Data object to the output
	func write(_ data: Data) throws {
		try self.writer.writeData(data)
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
			try self.writer.writeData(Data($0))
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
		try self.writer.writeByte(0x00)
	}

	func writeAsciiNoTerminator(_ string: String) throws {
		guard let data = string.data(using: .ascii) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writer.writeData(data)
	}
}

public extension BytesWriter {
	func writeUTF8NullTerminated(_ string: String) throws {
		try self.writeUTF8NoTerminator(string)
		try self.writer.writeByte(0x00)
	}

	func writeUTF8NoTerminator(_ string: String) throws {
		guard let data = string.data(using: .utf8) else {
			throw WriterError.cannotConvertStringEncoding
		}
		try self.writer.writeData(data)
	}
}

// MARK: - Convenience writers

public extension BytesWriter {
	/// Generate a Data object
	/// - Parameter block: The block to write formatted data to the Data object
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
	/// - Parameter block: The block to write formatted data to the Data object
	/// - Returns: A data object
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
