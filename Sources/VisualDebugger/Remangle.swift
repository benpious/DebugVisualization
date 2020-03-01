
func mangledName(from type: Any.Type) -> String {
    let typePointer = UnsafeRawPointer(bitPattern: unsafeBitCast(type, to: Int.self))!
    // (void *)type
    let nominalTypeDescriptor = typePointer
        .advanced(by: MemoryLayout<Int>.size)
    let mangledNameOffset = nominalTypeDescriptor
        .advanced(by: MemoryLayout<Int>.size)
        .load(as: UInt32.self)
    // n[1]
    let mangledNameStartUntyped = nominalTypeDescriptor.advanced(by: Int(mangledNameOffset))
    let mangledNameStart = UnsafePointer<CChar>(OpaquePointer(mangledNameStartUntyped))
    let result = String(cString: mangledNameStart)
    return result
}
