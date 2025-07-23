package dnsmsg

import std.io.*
import std.binary.*

func readUInt8<T>(buffer: T): ?UInt8 where T <: InputStream & Seekable {
    let byte = Array<UInt8>(1, repeat: 0)
    if (buffer.read(byte) == 0) {
        return None // No data read, return None
    }

    return byte[0]
}

func readUInt16<T>(buffer: T): ?UInt16 where T <: InputStream & Seekable {
    let bytes = Array<UInt8>(2, repeat: 0)
    let bytesRead = buffer.read(bytes)
    if (bytesRead != 2) {
        buffer.seek(SeekPosition.Current(-bytesRead)) // Seek back to the current position
        return None // Not enough data read, return None
    }

    return UInt16.readBigEndian(bytes)
}

func readUInt32<T>(buffer: T): ?UInt32 where T <: InputStream & Seekable {
    let bytes = Array<UInt8>(4, repeat: 0)
    let bytesRead = buffer.read(bytes)
    if (bytesRead != 4) {
        buffer.seek(SeekPosition.Current(-bytesRead)) // Seek back to the current position
        return None // Not enough data read, return None
    }

    return UInt32.readBigEndian(bytes)
}

func readBytes<T>(buffer: T, length: Int64): ?Array<UInt8> where T <: InputStream & Seekable {
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

extend ByteBuffer {
    func writeUInt16(value: UInt16) {
        let bytes = Array<UInt8>(2, repeat: 0)
        value.writeBigEndian(bytes)
        write(bytes)
    }

    func writeUInt32(value: UInt32) {
        let bytes = Array<UInt8>(4, repeat: 0)
        value.writeBigEndian(bytes)
        write(bytes)
    }
}
