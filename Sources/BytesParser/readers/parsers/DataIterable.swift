//
//  DataIterable.swift
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

internal class DataIterable: BytesParserIterable {
	let data: Data
	var index: Data.Index

	init(data: Data) {
		self.data = data
		self.index = data.startIndex
	}

	var hasMoreData: Bool { self.index < self.data.endIndex }

	func next() throws -> UInt8 {
		guard self.index < self.data.endIndex else {
			throw BytesParser.ParseError.endOfData
		}
		defer { index += 1 }
		return self.data[self.index]
	}

	func next(_ count: Int) throws -> Data {
		guard self.data.count - self.index >= count else {
			throw BytesParser.ParseError.endOfData
		}
		defer { index += count }
		return self.data[self.index ..< self.index + count]
	}

	func nextUpToIncluding(_ byte: UInt8) throws -> Data {
		guard self.hasMoreData else {
			throw BytesParser.ParseError.endOfData
		}
		let startIndex = self.index
		while self.index < self.data.endIndex {
			let char = self.data[self.index]
			if char == byte {
				// Make sure we move the read pointer to the next byte
				defer { index += 1 }
				return self.data[startIndex ... self.index]
			}
			self.index += 1
		}

		// Just return all the rest of the data
		return self.data[startIndex...]
	}
}
