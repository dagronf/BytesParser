# BytesParser

A simple byte-oriented parser/writer. Read and write formatted values to/from binary blobs/files with ease! 

![tag](https://img.shields.io/github/v/tag/dagronf/BytesParser)
![Platform support](https://img.shields.io/badge/platform-ios%20%7C%20osx%20%7C%20tvos%20%7C%20watchos%20%7C%20macCatalyst%20%7C%20linux-lightgrey.svg?style=flat-square)
[![License MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square)](https://github.com/dagronf/BytesParser/blob/master/LICENSE) ![Build](https://img.shields.io/github/actions/workflow/status/dagronf/BytesParser/swift.yml)

Supports :-

* reading to/writing from a `Data` object, a file URL or an `OutputStream` object
* different endianness, even within the same file
* different string encodings, including multi-byte encodings like UInt32
* explicit string null-termination handling
* explicit endian handling for appropriate types (eg. `Int32`) so no unintential byte swaps.
* padding to byte boundaries

[Online Documentation](https://swiftpackageindex.com/dagronf/BytesParser/main/documentation/bytesparser)

## Reading

The `BytesParser` class type provides the basic mechanism for reading and extracting useful information
from binary data.

### Using a BytesParser Object 

```swift
let reader = BytesReader(data: <some data object>)

// The magic identifier for the file is an 8-byte ascii string (not null terminated)
let magic = try reader.readString(length: 8, encoding: .ascii)
assert("8BCBAFFE", magic)

// Read 12-character little-endian encoded WCS2 (UTF16) string 
let title = try reader.readUTF16String(.little, length: 12)
let length = try reader.readInt16(.little)
let offset = try reader.readInt32(.little)
```

### Closure based

The closure based API hides some of the complexity of opening/closing a bytes file/blob.

#### Example

```swift
// Parsing a (local) crossword file
try BytesReader.parse(fileURL: url) { parser in
   let checksum = try parser.readUInt16(.little)
   let magic = try parser.readStringASCII(length: 12, lengthIncludesTerminator: true)
   assert(magic, "ACROSS&DOWN")

   let width = try parser.readInt8()
   let height = try parser.readInt8()

   let clueCount = try parser.readUInt16(.little)
   ...
   let title = try parser.readStringNullTerminated(encoding: .ascii)
}
```

## Writing

The `BytesWriter` class allows you to write formatted binary data to a file/data

The basic process is as follows :-

1. Create a new `BytesWriter` writer object with the appropriate initializer 
2. Write to the writer object using the `.write(...)` methods
3. Call `complete()` on the writer to close any open file(s) and make the data ready. **Failure to call `.complete()` may render your data unreadable.**

* If using a `BytesWriter` to write to a data object, call the `.data()` method to retrieve the data. Calling `.data()` on a file-based writer will throw an error.

### Using a BytesWriter Object 

```swift
let data: [UInt8] = [0x20, 0x40, 0x60, 0x80]

let writer = try BytesWriter()
try writer.writeBytes(data)
writer.complete()

let myData = writer.data()
```

### Closure based

The closure based API hides some of the complexity of opening/closing a writing destination.
You won't need to call `complete()` at the end of an assemble block.

```swift
// Write to a Data object 
static func assemble(_ block: (BytesWriter) throws -> Void) throws -> Data
```

```swift
// Write to a file
static func assemble(fileURL: URL, _ block: (BytesWriter) throws -> Void) throws
```

#### Example

```swift
let message = "10. 好き 【す・き】 (na-adj) – likable; desirable"
try BytesWriter.assemble(fileURL: fileURL) { writer in
   // Write out a 'message' block
   // > Write out the block type identifier
   try writer.writeByte(0x78)
	// > Write message length (big-endian UInt32)
   try writer.writeUInt32(...message length in UTF32 chars..., .bigEndian)
   // > Write out the message in a big-endian, UTF32 format
   try writer.writeStringUTF32BE(message)

   // Write a 'data' block
	// > Write out the block type identifier
   try writer.writeByte(0x33)
   // > Write data length (big-endian UInt32)
   try writer.writeUInt32(...length of data..., .bigEndian)
   // > Write raw data as bytes
   try writer.writeData(...data...)
}
```

## Notes

* Forward reading only (no rewinding!)
* Intentionally not thread safe (no calling from multiple different threads!)

## License

```
MIT License

Copyright (c) 2024 Darren Ford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
