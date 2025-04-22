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

/// An object that can iterate through raw byte data and extract parsable data (eg. integers, floats etc)
public class BytesReader {
	/// Create a reader with data
	/// - Parameter data: The data to read
	///
	/// Create a random-access reader (supporting seek)
	public init(data: Data) {
		self.source = InMemorySource(data: data)
	}

	/// Create a reader containing bytes
	/// - Parameter bytes: The bytes to read
	///
	/// Create a random-access reader (supporting seek)
	public init(bytes: [UInt8]) {
		self.source = InMemorySource(bytes: bytes)
	}

	/// Create a reader containing an input stream
	/// - Parameter inputStream: The data stream to read
	///
	/// This reader type does not support random access (ie. `seek` calls will fail)
	public init(inputStream: InputStream) {
		self.source = InputStreamSource(inputStream: inputStream)
	}

	/// Create a byte parser from the contents of a local file
	/// - Parameter fileURL: The file URL to read
	public init(fileURL: URL) throws {
		guard
			fileURL.isFileURL,
			let inputStream = InputStream(url: fileURL)
		else {
			throw BytesReader.ReaderError.invalidFile
		}
		self.source = InputStreamSource(inputStream: inputStream)
	}

	/// The current read offset within the source
	@inlinable public var readPosition: Int { self.source.readPosition }

	/// Is there more data available in the source for reading?
	@inlinable public var hasMoreData: Bool { self.source.hasMoreData }

	/// The byte source
	@usableFromInline let source: BytesReaderSource
}

// MARK: - Random access

public extension BytesReader {
	/// Seek direction
	enum Seek {
		/// Seek from start
		case start
		/// Seek backwards from end
		case end
		/// Seek from current read position
		case current
	}

	/// Rewind the read position back to the start of the source
	@inlinable func rewind() throws {
		try self.source.rewind()
	}

	/// Move the read offset from the start of the data
	/// - Parameter offset: The new read offset
	@inlinable func seekSet(_ offset: Int) throws {
		try self.source.seekSet(offset)
	}

	/// Move the read offset from the end of the data
	/// - Parameter offset: The distance from the end of the data
	@inlinable func seekEnd(_ offset: Int) throws {
		try self.source.seekEnd(offset)
	}

	/// Seek from the current read location
	/// - Parameter offset: The offset to move the read position
	@inlinable func seek(_ offset: Int) throws {
		try self.source.seek(offset)
	}

	/// Seek within the source
	func seek(_ offset: Int, _ direction: Seek) throws {
		switch direction {
		case .start:
			try self.seekSet(offset)
		case .end:
			try self.seekEnd(offset)
		case .current:
			try self.seek(offset)
		}
	}
}

// MARK: - Convenience readers

public extension Data {
	/// Parse the data using the supplied BytesReader object
	/// - Parameter block: The block to call, providing a BytesReader instance for parsing the data content
	func bytesReader(_ block: (BytesReader) throws -> Void) rethrows {
		try block(BytesReader(data: self))
	}
}

public extension BytesReader {
	/// Parse the contents of a `Data` object
	/// - Parameters:
	///   - data: The data object to parse
	///   - block: The block containing the parsing calls
	@inlinable static func read(data: Data, _ block: (BytesReader) throws -> Void) throws {
		let parser = BytesReader(data: data)
		try block(parser)
	}

	/// Parse the contents of a byte array
	/// - Parameters:
	///   - bytes: An array of bytes to parse
	///   - block: The block containing the parsing calls
	@inlinable static func read(bytes: [UInt8], _ block: (BytesReader) throws -> Void) throws {
		let parser = BytesReader(data: Data(bytes))
		try block(parser)
	}

	/// Parse the contents of a local file
	/// - Parameters:
	///   - fileURL: The local file URL to read from
	///   - block: The block containing the parsing calls
	static func read<ResultType>(
		fileURL: URL,
		_ block: (BytesReader) throws -> ResultType
	) throws -> ResultType {
		let parser = try BytesReader(fileURL: fileURL)
		return try block(parser)
	}

	/// Parse the contents of an input stream
	/// - Parameters:
	///   - inputStream: The stream to read from
	///   - block: The block containing the parsing calls
	@inlinable static func read(inputStream: InputStream, _ block: (BytesReader) throws -> Void) throws {
		let parser = BytesReader(inputStream: inputStream)
		try block(parser)
	}

	/// Read all remaining data in the input stream
	/// - Parameter inputStream: The inputstream to read from
	/// - Returns: A data object containing the read data
	@inlinable static func data(inputStream: InputStream) throws -> Data {
		try BytesReader(inputStream: inputStream).readAllRemainingData()
	}
}

// MARK: - Read up to pattern match

public extension BytesReader {
	/// Read until we find the next instance of a byte pattern
	/// - Parameter pattern: The pattern to find
	///
	/// - If found, sets the read pointer to the _next_ character after the match
	/// - Throws an error if the pattern isn't found. No more data can be read from the stream in this case
	func readThroughNextInstanceOfPattern(_ pattern: Data) throws {
		var matchCount = 0
		while matchCount < pattern.count {
			let byte = try self.readByte()
			if byte == pattern[matchCount] {
				matchCount += 1
			}
			else {
				// Match failed. Reset the window
				matchCount = 0
				// In the case where the currently read byte matches the
				// first byte in the pattern, make sure we mark the match
				if byte == pattern[0] {
					matchCount = 1
				}
			}
		}
	}

	/// Read until we find the next instance of an ASCII pattern
	/// - Parameter asciiPattern: The ascii string to find
	///
	/// - If found, sets the read pointer to the _next_ character after the match
	/// - Throws an error if the pattern isn't found. No more data can be read from the stream in this case
	func readThroughNextInstanceOfASCII(_ asciiPattern: String) throws {
		guard let d = asciiPattern.data(using: .ascii) else {
			throw BytesReader.ReaderError.invalidStringEncoding
		}
		return try self.readThroughNextInstanceOfPattern(d)
	}
}
