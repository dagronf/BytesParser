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

public class BytesWriter {
	internal let outputStream: OutputStream

	/// The number of bytes currently written to the output
	public internal(set) var count: Int = 0

	/// Create a byte writer that writes to a Data() object destination
	public init() throws {
		self.outputStream = OutputStream(toMemory: ())
		self.outputStream.open()
	}

	/// Create a byte writer that writes to a file URL destination
	public init(fileURL: URL) throws {
		assert(fileURL.isFileURL)
		guard let stream = OutputStream(toFileAtPath: fileURL.path, append: false) else {
			throw BytesWriter.WriterError.cannotOpenOutputFile
		}
		self.outputStream = stream
		stream.open()
	}

	/// Finish writing to the destination
	///
	/// Must be called when you've finished writing to flush the contents to the destination
	public func complete() { self.outputStream.close() }

	/// Returns the data written to the destination **IF** the writer supports generating a `Data` object
	///
	/// This method only applies when writing to a `Data` destination
	public func data() throws -> Data {
		guard let data = self.outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data else {
			throw BytesWriter.WriterError.noDataAvailable
		}
		return data
	}
}

// MARK: - Padding

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
	@inlinable func padToEightByteBoundary(using byte: UInt8 = 0x00) throws {
		try self.padToNByteBoundary(byteBoundary: 8, using: byte)
	}
}

// MARK: - Convenience writers

public extension BytesWriter {
	/// Write formatted bytes to a Data object
	/// - Parameter block: The block to write formatted data using a `BytesWriter` to the Data object
	/// - Returns: A data object
	///
	/// Usage :-
	///
	/// ```swift
	/// let data = try BytesWriter.assemble() { writer in
	///    try writer.writeUInt16(5, .bigEndian)
	///    try writer.writeString("Hello", encoding: .ascii)
	/// }
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

	/// Write formatted bytes to a file URL
	/// - Parameter block: The block to write formatted data using a `BytesWriter` to the file object
	///
	/// Usage :-
	///
	/// ```swift
	/// try BytesWriter.assemble(fileURL: fileURL) { writer in
	///    try writer.writeUInt16(5, .bigEndian)
	///    try writer.writeString("Hello", encoding: .ascii)
	/// }
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
