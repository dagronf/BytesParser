//
//  File.swift
//  
//
//  Created by Darren Ford on 28/6/2023.
//

import Foundation


public protocol BytesWriterGenerator {
	func writeData(_ data: Data) throws
	func writeBytes(_ bytes: [UInt8]) throws
	func complete()

	/// If the writer generates data, the generated data
	///
	/// Must be preceeded by a call to `complete()`
	func data() throws -> Data
}

extension BytesWriterGenerator {
	/// Write a single byte
	@inlinable func writeByte(_ byte: UInt8) throws { try self.writeBytes([byte]) }
}

// Write the contents of 'data' to the output stream
internal func __writeData(outputStream: OutputStream, _ data: Data) throws {
	let writtenCount = withUnsafeBytes(of: data) {
		outputStream.write($0.baseAddress!, maxLength: data.count)
	}
	guard writtenCount == data.count else {
		throw BytesWriter.WriterError.unableToWriteBytesToFile
	}
}

/// Write the contents of 'bytes' to the output stream
internal func __writeBytes(outputStream: OutputStream, _ bytes: [UInt8]) throws {
	let writtenCount = outputStream.write(bytes, maxLength: bytes.count)
	guard writtenCount == bytes.count else {
		throw BytesWriter.WriterError.unableToWriteBytesToFile
	}
}

/// Writes to a file URL
public class OutputFileWriter: BytesWriterGenerator {
	private let outputStream: OutputStream

	public let fileURL: URL

	public init(fileURL: URL) throws {
		assert(fileURL.isFileURL)
		guard let stream = OutputStream(toFileAtPath: fileURL.path, append: false) else {
			throw BytesWriter.WriterError.cannotOpenOutputFile
		}
		self.fileURL = fileURL
		self.outputStream = stream
		stream.open()
	}

	public func writeData(_ data: Data) throws {
		try __writeData(outputStream: self.outputStream, data)
	}

	public func writeBytes(_ bytes: [UInt8]) throws {
		try __writeBytes(outputStream: self.outputStream, bytes)
	}

	public func complete() {
		self.outputStream.close()
	}

	public func data() throws -> Data {
		throw BytesWriter.WriterError.notSupported
	}
}

/// Write bytes to a `Data` representation
public class OutputDataWriter: BytesWriterGenerator {
	private let outputStream: OutputStream
	public init() throws {
		self.outputStream = OutputStream(toMemory: ())
		self.outputStream.open()
	}

	public func writeData(_ data: Data) throws {
		try __writeData(outputStream: self.outputStream, data)
	}

	public func writeBytes(_ bytes: [UInt8]) throws {
		try __writeBytes(outputStream: self.outputStream, bytes)
	}

	public func complete() {
		self.outputStream.close()
	}

	/// Return the data written to the stream
	///
	/// `finish()` should be called on the writer BEFORE this function is called.
	public func data() throws -> Data {
		guard let data = self.outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
			throw BytesWriter.WriterError.noDataAvailable
		}
		return data
	}
}
