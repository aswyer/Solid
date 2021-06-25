////////////////////////////////////////////////////////////////////////////
//
// Copyright 2021 Realm Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
////////////////////////////////////////////////////////////////////////////

import Foundation
import Realm.Private

public protocol _RealmSchemaDiscoverable {
    static var _rlmType: PropertyType { get }
    static var _rlmOptional: Bool { get }
    func _rlmPopulateProperty(_ prop: RLMProperty)
    static func _rlmPopulateProperty(_ prop: RLMProperty)
    static var _rlmRequireObjc: Bool { get }
}

extension _RealmSchemaDiscoverable {
    public static var _rlmOptional: Bool { false }
    public static var _rlmRequireObjc: Bool { true }
    public func _rlmPopulateProperty(_ prop: RLMProperty) { }
    public static func _rlmPopulateProperty(_ prop: RLMProperty) { }
}

// If the property is a storage property for a lazy Swift property, return
// the base property name (e.g. `foo.storage` becomes `foo`). Otherwise, nil.
private func baseName(forLazySwiftProperty name: String) -> String? {
    // A Swift lazy var shows up as two separate children on the reflection tree:
    // one named 'x', and another that is optional and is named "$__lazy_storage_$_propName"
    if let storageRange = name.range(of: "$__lazy_storage_$_", options: [.anchored]) {
        return String(name[storageRange.upperBound...])
    }
    return nil
}

internal extension RLMProperty {
    convenience init(name: String, value: _RealmSchemaDiscoverable) {
        let valueType = Swift.type(of: value)
        self.init(name: name, createSelectors: valueType._rlmRequireObjc)
        self.type = valueType._rlmType
        self.optional = valueType._rlmOptional
        valueType._rlmPopulateProperty(self)
        value._rlmPopulateProperty(self)
    }
}

private func getProperties(_ cls: RLMObjectBase.Type) -> [RLMProperty] {
    let object = cls.init()
    let indexedProperties: Set<String>
    let ignoredPropNames: Set<String>
    let columnNames = cls._realmColumnNames()
    if let realmObject = object as? Object {
        indexedProperties = Set(type(of: realmObject).indexedProperties())
        ignoredPropNames = Set(type(of: realmObject).ignoredProperties())
    } else {
        indexedProperties = Set()
        ignoredPropNames = Set()
    }
    return Mirror(reflecting: object).children.filter { (prop: Mirror.Child) -> Bool in
        guard let label = prop.label else { return false }
        if ignoredPropNames.contains(label) {
            return false
        }
        if let lazyBaseName = baseName(forLazySwiftProperty: label) {
            if ignoredPropNames.contains(lazyBaseName) {
                return false
            }
            throwRealmException("Lazy managed property '\(lazyBaseName)' is not allowed on a Realm Swift object"
                + " class. Either add the property to the ignored properties list or make it non-lazy.")
        }
        return true
    }.compactMap { prop in
        guard let label = prop.label else { return nil }
        var rawValue = prop.value
        if let value = rawValue as? RealmEnum {
            rawValue = type(of: value)._rlmToRawValue(value)
        }

        guard let value = rawValue as? _RealmSchemaDiscoverable else {
            if class_getProperty(cls, label) != nil {
                throwRealmException("Property \(cls).\(label) is declared as \(type(of: prop.value)), which is not a supported managed Object property type. If it is not supposed to be a managed property, either add it to `ignoredProperties()` or do not declare it as `@objc dynamic`. See https://realm.io/docs/swift/latest/api/Classes/Object.html for more information.")
            }
            if prop.value as? RealmOptionalProtocol != nil {
                throwRealmException("Property \(cls).\(label) has unsupported RealmOptional type \(type(of: prop.value)). Extending RealmOptionalType with custom types is not currently supported. ")
            }
            return nil
        }

        RLMValidateSwiftPropertyName(label)
        let valueType = type(of: value)

        let property = RLMProperty(name: label, value: value)
        property.indexed = indexedProperties.contains(property.name)
        property.columnName = columnNames?[property.name]

        if let objcProp = class_getProperty(cls, label) {
            var count: UInt32 = 0
            let attrs = property_copyAttributeList(objcProp, &count)!
            defer {
                free(attrs)
            }
            var computed = true
            for i in 0..<Int(count) {
                let attr = attrs[i]
                switch attr.name[0] {
                case Int8(UInt8(ascii: "R")): // Read only
                    return nil
                case Int8(UInt8(ascii: "V")): // Ivar name
                    computed = false
                case Int8(UInt8(ascii: "G")): // Getter name
                    property.getterName = String(cString: attr.value)
                case Int8(UInt8(ascii: "S")): // Setter name
                    property.setterName = String(cString: attr.value)
                default:
                    break
                }
            }

            // If there's no ivar name and no ivar with the same name as
            // the property then this is a computed property and we should
            // implicitly ignore it
            if computed && class_getInstanceVariable(cls, label) == nil {
                return nil
            }
        } else if valueType._rlmRequireObjc {
            // Implicitly ignore non-@objc dynamic properties
            return nil
        } else {
            property.swiftIvar = class_getInstanceVariable(cls, label)
        }

        property.updateAccessors()
        return property
    }
}

internal class ObjectUtil {
    private static let runOnce: Void = {
        RLMSwiftAsFastEnumeration = { (obj: Any) -> Any? in
            // Intermediate cast to AnyObject due to https://bugs.swift.org/browse/SR-8651
            if let collection = obj as AnyObject as? UntypedCollection {
                return collection.asNSFastEnumerator()
            }
            return nil
        }
    }()

    internal class func getSwiftProperties(_ cls: RLMObjectBase.Type) -> [RLMProperty] {
        _ = ObjectUtil.runOnce
        return getProperties(cls)
    }
}
