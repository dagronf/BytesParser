# BytesParser

A byte-oriented parser for data.

Useful for extracting formatted values from raw data

```swift
let data: Data = ...

let parser = BytesParser(data: data)

let magic10 = try parser.readBytes(4)
let magic14 = try parser.readBytes(4)
let magic18 = try parser.readBytes(4)

// Version is a little-endian Int32
let version: Int32 = try parser.readLittleEndian()

// Width and height are UInt8
let width = Int(try parser.readByte())
let height = Int(try parser.readByte())

// Title is a pascal style ascii string (byte containing title length, then `length` ascii bytes)
let titleLength = Int(try parser.readByte())
let title = try parser.readAsciiString(length: titleLength)
// Description is a pascal style ascii string (byte containing description length, then `length` ascii bytes)
let descLength = Int(try parser.readByte())
let description = try parser.readAsciiString(length: titleLength)
```

## Notes

* Forward reading only (no rewinding!)

## License

```
MIT License

Copyright (c) 2023 Darren Ford

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
