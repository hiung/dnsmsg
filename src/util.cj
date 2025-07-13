package dnsmsg

import std.io.*

func readUInt8<T>(buffer: T): Option<UInt8> where T <: InputStream & Seekable {
    let byte = Array<UInt8>(1, repeat: 0)
    if (buffer.read(byte) == 0) {
        return None // No data read, return None
    }

    return byte[0]
}

func readUInt16<T>(buffer: T): Option<UInt16> where T <: InputStream & Seekable {
    let bytes = Array<UInt8>(2, repeat: 0)
    let bytesRead = buffer.read(bytes)
    if (bytesRead != 2) {
        buffer.seek(SeekPosition.Current(-bytesRead)) // Seek back to the current position
        return None // Not enough data read, return None
    }

    return (UInt16(bytes[0]) << 8) | UInt16(bytes[1])
}

func readUInt32<T>(buffer: T): Option<UInt32> where T <: InputStream & Seekable {
    let bytes = Array<UInt8>(4, repeat: 0)
    let bytesRead = buffer.read(bytes)
    if (bytesRead != 4) {
        buffer.seek(SeekPosition.Current(-bytesRead)) // Seek back to the current position
        return None // Not enough data read, return None
    }

    return (UInt32(bytes[0]) << 24) | (UInt32(bytes[1]) << 16) | (UInt32(bytes[2]) << 8) | UInt32(bytes[3])
}

func readBytes<T>(buffer: T, length: Int64): Option<Array<UInt8>> where T <: InputStream & Seekable {
    if (length <= 0) {
        return None
    }

    let bytes = Array<UInt8>(length, repeat: 0)
    let bytesRead = buffer.read(bytes)
    if (bytesRead != length) {
        buffer.seek(SeekPosition.Current(-bytesRead)) // Seek back to the current position
        return None // Not enough data read, return None
    }

    return bytes
}

// Extend Array<T> to support concatenation
extend<T> Array<T> {
    operator func +(right: Array<T>): Array<T> {
        this.concat(right)
    }
}

extend ByteBuffer {
    public func writeUInt16(value: UInt16) {
        this.write([
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ])
    }

    public func writeUInt32(value: UInt32) {
        this.write([
            UInt8((value >> 24) & 0xFF),
            UInt8((value >> 16) & 0xFF),
            UInt8((value >> 8) & 0xFF),
            UInt8(value & 0xFF)
        ])
    }
}