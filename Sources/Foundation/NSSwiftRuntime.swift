// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//


@_implementationOnly import CoreFoundation

// Re-export Darwin and Glibc by importing Foundation
// This mimics the behavior of the swift sdk overlay on Darwin
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
@_exported import Darwin
#elseif os(Linux) || os(Android) || CYGWIN || os(OpenBSD)
@_exported import Glibc
#elseif os(WASI)
@_exported import WASILibc
#elseif os(Windows)
@_exported import CRT
#endif

#if !os(WASI)
@_exported import Dispatch
#endif

#if os(Windows)
import WinSDK
#endif

#if !_runtime(_ObjC)
/// The Objective-C BOOL type.
///
/// On 64-bit iOS, the Objective-C BOOL type is a typedef of C/C++
/// bool. Elsewhere, it is "signed char". The Clang importer imports it as
/// ObjCBool.
@frozen
public struct ObjCBool : ExpressibleByBooleanLiteral {
    #if os(macOS) || (os(iOS) && (arch(i386) || arch(arm)))
    // On macOS and 32-bit iOS, Objective-C's BOOL type is a "signed char".
    var _value: Int8

    init(_ value: Int8) {
        self._value = value
    }

    public init(_ value: Bool) {
        self._value = value ? 1 : 0
    }

    #else
    // Everywhere else it is C/C++'s "Bool"
    var _value: Bool

    public init(_ value: Bool) {
        self._value = value
    }
    #endif

    /// The value of `self`, expressed as a `Bool`.
    public var boolValue: Bool {
        #if os(macOS) || (os(iOS) && (arch(i386) || arch(arm)))
        return _value != 0
        #else
        return _value
        #endif
    }

    /// Create an instance initialized to `value`.
    @_transparent
    public init(booleanLiteral value: Bool) {
        self.init(value)
    }
}

extension ObjCBool : CustomReflectable {
    /// Returns a mirror that reflects `self`.
    public var customMirror: Mirror {
        return Mirror(reflecting: boolValue)
    }
}

extension ObjCBool : CustomStringConvertible {
    /// A textual representation of `self`.
    public var description: String {
        return self.boolValue.description
    }
}
#endif

@usableFromInline
internal class __NSCFType : NSObject {
    private var _cfinfo : _CFInfo
    
    override init() {
        // This is not actually called; _CFRuntimeCreateInstance will initialize _cfinfo
        _cfinfo = _CFInfo(typeID: 0)
    }
    
    override var hash: Int {
        return Int(bitPattern: CFHash(self))
    }
    
    override func isEqual(_ value: Any?) -> Bool {
        guard let other = value as? NSObject else { return false }
        return CFEqual(self, other)
    }
    
    override var description: String {
        return CFCopyDescription(unsafeBitCast(self, to: CFTypeRef.self))._swiftObject
    }

    deinit {
        _CFDeinit(self)
    }
}


internal func _CFSwiftGetTypeID(_ cf: AnyObject) -> CFTypeID {
    return (cf as! NSObject)._cfTypeID
}



internal func _CFSwiftCopyWithZone(_ cf: CFTypeRef, _ zone: CFTypeRef?) -> Unmanaged<CFTypeRef> {
    return Unmanaged<CFTypeRef>.passRetained((cf as! NSObject).copy() as! NSObject)
}


internal func _CFSwiftGetHash(_ cf: AnyObject) -> CFHashCode {
    return CFHashCode(bitPattern: (cf as! NSObject).hash)
}


internal func _CFSwiftIsEqual(_ cf1: AnyObject, cf2: AnyObject) -> Bool {
    return (cf1 as! NSObject).isEqual(cf2)
}

// Ivars in _NSCF* types must be zeroed via an unsafe accessor to avoid deinit of potentially unsafe memory to access as an object/struct etc since it is stored via a foreign object graph
internal func _CFZeroUnsafeIvars<T>(_ arg: inout T) {
    withUnsafeMutablePointer(to: &arg) { (ptr: UnsafeMutablePointer<T>) -> Void in
        memset(UnsafeMutableRawPointer(ptr), 0, MemoryLayout<T>.size)
    }
}

@usableFromInline
@_cdecl("__CFSwiftGetBaseClass")
internal func __CFSwiftGetBaseClass() -> UnsafeRawPointer {
    return unsafeBitCast(__NSCFType.self, to:UnsafeRawPointer.self)
}

@inline(never)
private func blackhole(_: _NSCFConstantString?) {
}

@usableFromInline
@_cdecl("__CFInitializeSwift")
internal func __CFInitializeSwift() {
#if os(Windows)
    __CFSocketInitializeWinSock()
#endif

    // Ensure that the foreign type value witness for `_NSCFConstantString` is
    // initialized prior to access.  This may be lazily initialized on some
    // targets when the type cache is updated due to a type-cast.
    //
    // TODO: invoke `swift_getForeignTypeMetadata` to do this directly
    blackhole("" as? _NSCFConstantString)

    _CFRuntimeBridgeTypeToClass(CFStringGetTypeID(), unsafeBitCast(_NSCFString.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFArrayGetTypeID(), unsafeBitCast(_NSCFArray.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFDictionaryGetTypeID(), unsafeBitCast(_NSCFDictionary.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFSetGetTypeID(), unsafeBitCast(_NSCFSet.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFBooleanGetTypeID(), unsafeBitCast(__NSCFBoolean.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFNumberGetTypeID(), unsafeBitCast(NSNumber.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFDataGetTypeID(), unsafeBitCast(NSData.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFDateGetTypeID(), unsafeBitCast(NSDate.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFURLGetTypeID(), unsafeBitCast(NSURL.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFCalendarGetTypeID(), unsafeBitCast(NSCalendar.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFLocaleGetTypeID(), unsafeBitCast(NSLocale.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFTimeZoneGetTypeID(), unsafeBitCast(NSTimeZone.self, to: UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFCharacterSetGetTypeID(), unsafeBitCast(_NSCFCharacterSet.self, to: UnsafeRawPointer.self))

#if !os(WASI)
    _CFRuntimeBridgeTypeToClass(_CFKeyedArchiverUIDGetTypeID(), unsafeBitCast(_NSKeyedArchiverUID.self, to: UnsafeRawPointer.self))
#endif
    
//    _CFRuntimeBridgeTypeToClass(CFErrorGetTypeID(), unsafeBitCast(NSError.self, UnsafeRawPointer.self))
    _CFRuntimeBridgeTypeToClass(CFAttributedStringGetTypeID(), unsafeBitCast(NSMutableAttributedString.self, to: UnsafeRawPointer.self))
//    _CFRuntimeBridgeTypeToClass(CFReadStreamGetTypeID(), unsafeBitCast(InputStream.self, UnsafeRawPointer.self))
//    _CFRuntimeBridgeTypeToClass(CFWriteStreamGetTypeID(), unsafeBitCast(OutputStream.self, UnsafeRawPointer.self))
   //_CFRuntimeBridgeTypeToClass(CFRunLoopTimerGetTypeID(), unsafeBitCast(Timer.self, to: UnsafeRawPointer.self))

    __CFSwiftBridge.NSObject.isEqual = _CFSwiftIsEqual
    __CFSwiftBridge.NSObject.hash = _CFSwiftGetHash
    __CFSwiftBridge.NSObject._cfTypeID = _CFSwiftGetTypeID
    __CFSwiftBridge.NSObject.copyWithZone = _CFSwiftCopyWithZone
    
    __CFSwiftBridge.NSSet.count = _CFSwiftSetGetCount
    __CFSwiftBridge.NSSet.countForKey = _CFSwiftSetGetCountOfValue
    __CFSwiftBridge.NSSet.containsObject = _CFSwiftSetContainsValue
    __CFSwiftBridge.NSSet.__getValue = _CFSwiftSetGetValue
    __CFSwiftBridge.NSSet.getValueIfPresent = _CFSwiftSetGetValueIfPresent
    __CFSwiftBridge.NSSet.getObjects = _CFSwiftSetGetValues
    __CFSwiftBridge.NSSet.copy = _CFSwiftSetCreateCopy
    __CFSwiftBridge.NSSet.__apply = _CFSwiftSetApplyFunction
    __CFSwiftBridge.NSSet.member = _CFSwiftSetMember
    
    __CFSwiftBridge.NSMutableSet.addObject = _CFSwiftSetAddValue
    __CFSwiftBridge.NSMutableSet.replaceObject = _CFSwiftSetReplaceValue
    __CFSwiftBridge.NSMutableSet.setObject = _CFSwiftSetSetValue
    __CFSwiftBridge.NSMutableSet.removeObject = _CFSwiftSetRemoveValue
    __CFSwiftBridge.NSMutableSet.removeAllObjects = _CFSwiftSetRemoveAllValues
    
    __CFSwiftBridge.NSArray.count = _CFSwiftArrayGetCount
    __CFSwiftBridge.NSArray.objectAtIndex = _CFSwiftArrayGetValueAtIndex
    __CFSwiftBridge.NSArray.getObjects = _CFSwiftArrayGetValues
    __CFSwiftBridge.NSArray.isSubclassOfNSMutableArray = _CFSwiftArrayIsSubclassOfNSMutableArray
    
    __CFSwiftBridge.NSMutableArray.addObject = _CFSwiftArrayAppendValue
    __CFSwiftBridge.NSMutableArray.setObject = _CFSwiftArraySetValueAtIndex
    __CFSwiftBridge.NSMutableArray.replaceObjectAtIndex = _CFSwiftArrayReplaceValueAtIndex
    __CFSwiftBridge.NSMutableArray.insertObject = _CFSwiftArrayInsertValueAtIndex
    __CFSwiftBridge.NSMutableArray.exchangeObjectAtIndex = _CFSwiftArrayExchangeValuesAtIndices
    __CFSwiftBridge.NSMutableArray.removeObjectAtIndex = _CFSwiftArrayRemoveValueAtIndex
    __CFSwiftBridge.NSMutableArray.removeAllObjects = _CFSwiftArrayRemoveAllValues
    __CFSwiftBridge.NSMutableArray.replaceObjectsInRange = _CFSwiftArrayReplaceValues
    
    __CFSwiftBridge.NSDictionary.count = _CFSwiftDictionaryGetCount
    __CFSwiftBridge.NSDictionary.countForKey = _CFSwiftDictionaryGetCountOfKey
    __CFSwiftBridge.NSDictionary.containsKey = _CFSwiftDictionaryContainsKey
    __CFSwiftBridge.NSDictionary.objectForKey = _CFSwiftDictionaryGetValue
    __CFSwiftBridge.NSDictionary._getValueIfPresent = _CFSwiftDictionaryGetValueIfPresent
    __CFSwiftBridge.NSDictionary.containsObject = _CFSwiftDictionaryContainsValue
    __CFSwiftBridge.NSDictionary.countForObject = _CFSwiftDictionaryGetCountOfValue
    __CFSwiftBridge.NSDictionary.getObjects = _CFSwiftDictionaryGetValuesAndKeys
    __CFSwiftBridge.NSDictionary.__apply = _CFSwiftDictionaryApplyFunction
    __CFSwiftBridge.NSDictionary.copy = _CFSwiftDictionaryCreateCopy
    
    __CFSwiftBridge.NSMutableDictionary.__addObject = _CFSwiftDictionaryAddValue
    __CFSwiftBridge.NSMutableDictionary.replaceObject = _CFSwiftDictionaryReplaceValue
    __CFSwiftBridge.NSMutableDictionary.__setObject = _CFSwiftDictionarySetValue
    __CFSwiftBridge.NSMutableDictionary.removeObjectForKey = _CFSwiftDictionaryRemoveValue
    __CFSwiftBridge.NSMutableDictionary.removeAllObjects = _CFSwiftDictionaryRemoveAllValues
    
    __CFSwiftBridge.NSString._createSubstringWithRange = _CFSwiftStringCreateWithSubstring
    __CFSwiftBridge.NSString.copy = _CFSwiftStringCreateCopy
    __CFSwiftBridge.NSString.mutableCopy = _CFSwiftStringCreateMutableCopy
    __CFSwiftBridge.NSString.length = _CFSwiftStringGetLength
    __CFSwiftBridge.NSString.characterAtIndex = _CFSwiftStringGetCharacterAtIndex
    __CFSwiftBridge.NSString.getCharacters = _CFSwiftStringGetCharacters
    __CFSwiftBridge.NSString.__getBytes = _CFSwiftStringGetBytes
    __CFSwiftBridge.NSString._fastCStringContents = _CFSwiftStringFastCStringContents
    __CFSwiftBridge.NSString._fastCharacterContents = _CFSwiftStringFastContents
    __CFSwiftBridge.NSString._getCString = _CFSwiftStringGetCString
    __CFSwiftBridge.NSString._encodingCantBeStoredInEightBitCFString = _CFSwiftStringIsUnicode
    
    __CFSwiftBridge.NSMutableString.insertString = _CFSwiftStringInsert
    __CFSwiftBridge.NSMutableString.deleteCharactersInRange = _CFSwiftStringDelete
    __CFSwiftBridge.NSMutableString.replaceCharactersInRange = _CFSwiftStringReplace
    __CFSwiftBridge.NSMutableString.setString = _CFSwiftStringReplaceAll
    __CFSwiftBridge.NSMutableString.appendString = _CFSwiftStringAppend
    __CFSwiftBridge.NSMutableString.appendCharacters = _CFSwiftStringAppendCharacters
    __CFSwiftBridge.NSMutableString._cfAppendCString = _CFSwiftStringAppendCString

#if !os(WASI)    
    __CFSwiftBridge.NSRunLoop._new = _NSRunLoopNew
#endif
    
    __CFSwiftBridge.NSCharacterSet._expandedCFCharacterSet = _CFSwiftCharacterSetExpandedCFCharacterSet
    __CFSwiftBridge.NSCharacterSet._retainedBitmapRepresentation = _CFSwiftCharacterSetRetainedBitmapRepresentation
    __CFSwiftBridge.NSCharacterSet.characterIsMember = _CFSwiftCharacterSetCharacterIsMember
    __CFSwiftBridge.NSCharacterSet.mutableCopy = _CFSwiftCharacterSetMutableCopy
    __CFSwiftBridge.NSCharacterSet.longCharacterIsMember = _CFSwiftCharacterSetLongCharacterIsMember
    __CFSwiftBridge.NSCharacterSet.hasMemberInPlane = _CFSwiftCharacterSetHasMemberInPlane
    __CFSwiftBridge.NSCharacterSet.invertedSet = _CFSwiftCharacterSetInverted
    
    __CFSwiftBridge.NSMutableCharacterSet.addCharactersInRange = _CFSwiftMutableSetAddCharactersInRange
    __CFSwiftBridge.NSMutableCharacterSet.removeCharactersInRange = _CFSwiftMutableSetRemoveCharactersInRange
    __CFSwiftBridge.NSMutableCharacterSet.addCharactersInString = _CFSwiftMutableSetAddCharactersInString
    __CFSwiftBridge.NSMutableCharacterSet.removeCharactersInString = _CFSwiftMutableSetRemoveCharactersInString
    __CFSwiftBridge.NSMutableCharacterSet.formUnionWithCharacterSet = _CFSwiftMutableSetFormUnionWithCharacterSet
    __CFSwiftBridge.NSMutableCharacterSet.formIntersectionWithCharacterSet = _CFSwiftMutableSetFormIntersectionWithCharacterSet
    __CFSwiftBridge.NSMutableCharacterSet.invert = _CFSwiftMutableSetInvert
    
    __CFSwiftBridge.NSNumber._cfNumberGetType = _CFSwiftNumberGetType
    __CFSwiftBridge.NSNumber._getValue = _CFSwiftNumberGetValue
    __CFSwiftBridge.NSNumber.boolValue = _CFSwiftNumberGetBoolValue
    
    __CFSwiftBridge.NSData.copy = _CFSwiftDataCreateCopy
    __CFSwiftBridge.NSData.length = _CFSwiftDataGetLength
    __CFSwiftBridge.NSData.bytes = _CFSwiftDataGetBytesPtr
    __CFSwiftBridge.NSData.mutableBytes = _CFSwiftDataGetMutableBytesPtr
    __CFSwiftBridge.NSData.getBytes = _CFSwiftDataGetBytes
    __CFSwiftBridge.NSData.setLength = _CFSwiftDataSetLength
    __CFSwiftBridge.NSData.increaseLengthBy = _CFSwiftDataIncreaseLength
    __CFSwiftBridge.NSData.appendBytes = _CFSwiftDataAppendBytes
    __CFSwiftBridge.NSData.replaceBytes = _CFSwiftDataReplaceBytes
    
    __CFSwiftBridge.NSCalendar.calendarIdentifier = _CFSwiftCalendarGetCalendarIdentifier
    __CFSwiftBridge.NSCalendar.copyLocale = _CFSwiftCalendarCopyLocale
    __CFSwiftBridge.NSCalendar.setLocale = _CFSwiftCalendarSetLocale
    __CFSwiftBridge.NSCalendar.copyTimeZone = _CFSwiftCalendarCopyTimeZone
    __CFSwiftBridge.NSCalendar.setTimeZone = _CFSwiftCalendarSetTimeZone
    __CFSwiftBridge.NSCalendar.firstWeekday = _CFSwiftCalendarGetFirstWeekday
    __CFSwiftBridge.NSCalendar.setFirstWeekday = _CFSwiftCalendarSetFirstWeekday
    __CFSwiftBridge.NSCalendar.minimumDaysInFirstWeek = _CFSwiftCalendarGetMinimumDaysInFirstWeek
    __CFSwiftBridge.NSCalendar.setMinimumDaysInFirstWeek = _CFSwiftCalendarSetMinimumDaysInFirstWeek
    __CFSwiftBridge.NSCalendar.copyGregorianStartDate = _CFSwiftCalendarCopyGregorianStartDate
    __CFSwiftBridge.NSCalendar.setGregorianStartDate = _CFSwiftCalendarSetGregorianStartDate
    
//    __CFDefaultEightBitStringEncoding = UInt32(kCFStringEncodingUTF8)
    
#if !os(WASI)
    __CFSwiftBridge.NSURL.copyResourcePropertyForKey = _CFSwiftURLCopyResourcePropertyForKey
    __CFSwiftBridge.NSURL.copyResourcePropertiesForKeys = _CFSwiftURLCopyResourcePropertiesForKeys
    __CFSwiftBridge.NSURL.setResourcePropertyForKey = _CFSwiftURLSetResourcePropertyForKey
    __CFSwiftBridge.NSURL.setResourcePropertiesForKeys = _CFSwiftURLSetResourcePropertiesForKeys
    __CFSwiftBridge.NSURL.clearResourcePropertyCacheForKey = _CFSwiftURLClearResourcePropertyCacheForKey
    __CFSwiftBridge.NSURL.clearResourcePropertyCache = _CFSwiftURLClearResourcePropertyCache
    __CFSwiftBridge.NSURL.setTemporaryResourceValueForKey = _CFSwiftSetTemporaryResourceValueForKey
    __CFSwiftBridge.NSURL.resourceIsReachable = _CFSwiftURLResourceIsReachable
#endif
}

public func === (lhs: AnyClass, rhs: AnyClass) -> Bool {
    return unsafeBitCast(lhs, to: UnsafeRawPointer.self) == unsafeBitCast(rhs, to: UnsafeRawPointer.self)
}

/// Swift extensions for common operations in Foundation that use unsafe things...


extension NSObject {
    static func unretainedReference<R: NSObject>(_ value: UnsafeRawPointer) -> R {
        return unsafeBitCast(value, to: R.self)
    }
    
    static func unretainedReference<R: NSObject>(_ value: UnsafeMutableRawPointer) -> R {
        return unretainedReference(UnsafeRawPointer(value))
    }
    
    static func releaseReference(_ value: UnsafeRawPointer) {
        _CFSwiftRelease(UnsafeMutableRawPointer(mutating: value))
    }
    
    static func releaseReference(_ value: UnsafeMutableRawPointer) {
        _CFSwiftRelease(value)
    }

    func withRetainedReference<T, R>(_ work: (UnsafePointer<T>) -> R) -> R {
        let selfPtr = Unmanaged.passRetained(self).toOpaque().assumingMemoryBound(to: T.self)
        return work(selfPtr)
    }
    
    func withRetainedReference<T, R>(_ work: (UnsafeMutablePointer<T>) -> R) -> R {
        let selfPtr = Unmanaged.passRetained(self).toOpaque().assumingMemoryBound(to: T.self)
        return work(selfPtr)
    }
    
    func withUnretainedReference<T, R>(_ work: (UnsafePointer<T>) -> R) -> R {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque().assumingMemoryBound(to: T.self)
        return work(selfPtr)
    }
    
    func withUnretainedReference<T, R>(_ work: (UnsafeMutablePointer<T>) -> R) -> R {
        let selfPtr = Unmanaged.passUnretained(self).toOpaque().assumingMemoryBound(to: T.self)
        return work(selfPtr)
    }
}

extension Array {
    internal mutating func withUnsafeMutablePointerOrAllocation<R>(_ count: Int, fastpath: UnsafeMutablePointer<Element>? = nil, body: (UnsafeMutablePointer<Element>) -> R) -> R {
        if let fastpath = fastpath {
            return body(fastpath)
        } else if self.count > count {
            let buffer = UnsafeMutablePointer<Element>.allocate(capacity: count)
            let res = body(buffer)
            buffer.deinitialize(count: count)
            buffer.deallocate()
            return res
        } else {
            return withUnsafeMutableBufferPointer() { (bufferPtr: inout UnsafeMutableBufferPointer<Element>) -> R in
                return body(bufferPtr.baseAddress!)
            }
        }
    }
}


#if os(macOS) || os(iOS)
    internal typealias _DarwinCompatibleBoolean = DarwinBoolean
#else
    internal typealias _DarwinCompatibleBoolean = Bool
#endif

public protocol _NSNonfileURLContentLoading: AnyObject {
    init()
    func contentsOf(url: URL) throws -> (result: NSData, textEncodingNameIfAvailable: String?)
}


internal enum _NSNonfileURLContentLoader {
    static private(set) var external: _NSNonfileURLContentLoading?
    
    static var current: _NSNonfileURLContentLoading {
        if let external = _NSNonfileURLContentLoader.external {
            return external
        } else {
            guard let type = _typeByName(_SwiftFoundationNetworkingModuleName + "._NSNonfileURLContentLoader") as? _NSNonfileURLContentLoading.Type else {
                fatalError("You must link or load module \(_SwiftFoundationNetworkingModuleName) to load non-file: URL content using String(contentsOf:…), Data(contentsOf:…), etc.")
            }
            
            let result = type.init()
            _NSNonfileURLContentLoader.external = result
            return result
        }
    }
}

public struct _NSCFXMLBridgeForFoundationXMLUseOnly {
    public var originalBridge: UnsafeMutableRawPointer
    public var CFArrayGetCount: UnsafeMutableRawPointer
    public var CFArrayGetValueAtIndex: UnsafeMutableRawPointer
    public var CFErrorCreate: UnsafeMutableRawPointer
    public var CFStringCreateWithCString: UnsafeMutableRawPointer
    public var CFStringCreateMutable: UnsafeMutableRawPointer
    public var CFStringAppend: UnsafeMutableRawPointer
    public var CFStringAppendCString: UnsafeMutableRawPointer
    public var CFStringGetLength: UnsafeMutableRawPointer
    public var CFStringGetMaximumSizeForEncoding: UnsafeMutableRawPointer
    public var CFStringGetCString: UnsafeMutableRawPointer
    public var CFDataCreateWithBytesNoCopy: UnsafeMutableRawPointer
    public var CFRelease: UnsafeMutableRawPointer
    public var CFStringCreateWithBytes: UnsafeMutableRawPointer
    public var CFArrayCreateMutable: UnsafeMutableRawPointer
    public var CFArrayAppendValue: UnsafeMutableRawPointer
    public var CFDataGetLength: UnsafeMutableRawPointer
    public var CFDataGetBytePtr: UnsafeMutableRawPointer
    public var CFDictionaryCreateMutable: UnsafeMutableRawPointer
    public var CFDictionarySetValue: UnsafeMutableRawPointer
    public var kCFAllocatorSystemDefault: UnsafeMutableRawPointer
    public var kCFAllocatorNull: UnsafeMutableRawPointer
    public var kCFCopyStringDictionaryKeyCallBacks: UnsafeMutableRawPointer
    public var kCFTypeDictionaryValueCallBacks: UnsafeMutableRawPointer
    public var kCFErrorLocalizedDescriptionKey: UnsafeMutableRawPointer
    
    public init() {
        self.originalBridge = UnsafeMutableRawPointer(&__NSCFXMLBridgeUntyped)
        self.CFArrayGetCount = __NSCFXMLBridgeUntyped.CFArrayGetCount
        self.CFArrayGetValueAtIndex = __NSCFXMLBridgeUntyped.CFArrayGetValueAtIndex
        self.CFErrorCreate = __NSCFXMLBridgeUntyped.CFErrorCreate
        self.CFStringCreateWithCString = __NSCFXMLBridgeUntyped.CFStringCreateWithCString
        self.CFStringCreateMutable = __NSCFXMLBridgeUntyped.CFStringCreateMutable
        self.CFStringAppend = __NSCFXMLBridgeUntyped.CFStringAppend
        self.CFStringAppendCString = __NSCFXMLBridgeUntyped.CFStringAppendCString
        self.CFStringGetLength = __NSCFXMLBridgeUntyped.CFStringGetLength
        self.CFStringGetMaximumSizeForEncoding = __NSCFXMLBridgeUntyped.CFStringGetMaximumSizeForEncoding
        self.CFStringGetCString = __NSCFXMLBridgeUntyped.CFStringGetCString
        self.CFDataCreateWithBytesNoCopy = __NSCFXMLBridgeUntyped.CFDataCreateWithBytesNoCopy
        self.CFRelease = __NSCFXMLBridgeUntyped.CFRelease
        self.CFStringCreateWithBytes = __NSCFXMLBridgeUntyped.CFStringCreateWithBytes
        self.CFArrayCreateMutable = __NSCFXMLBridgeUntyped.CFArrayCreateMutable
        self.CFArrayAppendValue = __NSCFXMLBridgeUntyped.CFArrayAppendValue
        self.CFDataGetLength = __NSCFXMLBridgeUntyped.CFDataGetLength
        self.CFDataGetBytePtr = __NSCFXMLBridgeUntyped.CFDataGetBytePtr
        self.CFDictionaryCreateMutable = __NSCFXMLBridgeUntyped.CFDictionaryCreateMutable
        self.CFDictionarySetValue = __NSCFXMLBridgeUntyped.CFDictionarySetValue
        self.kCFAllocatorSystemDefault = __NSCFXMLBridgeUntyped.kCFAllocatorSystemDefault
        self.kCFAllocatorNull = __NSCFXMLBridgeUntyped.kCFAllocatorNull
        self.kCFCopyStringDictionaryKeyCallBacks = __NSCFXMLBridgeUntyped.kCFCopyStringDictionaryKeyCallBacks
        self.kCFTypeDictionaryValueCallBacks = __NSCFXMLBridgeUntyped.kCFTypeDictionaryValueCallBacks
        self.kCFErrorLocalizedDescriptionKey = __NSCFXMLBridgeUntyped.kCFErrorLocalizedDescriptionKey
    }
}
