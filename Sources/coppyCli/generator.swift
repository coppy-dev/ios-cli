import Foundation

enum CoppyGeneratorError: Error {
    case error(String)
}

public struct CoppyGenerator {
    
    static func generateContentFile(_ content: [String: Any], classPrefix: String? = "") throws -> String {
        let cl = CoppyParser.parseJson(obj: content, name: "\(classPrefix ?? "")CoppyContent")
        
        return """
            import Foundation
            import Coppy
            
            \(try generateContentClass(cl, content))
            """
    }
    
    static func getFieldType(_ field: CoppyField) throws -> String {
        switch field.type {
        case "string":
            return "String\(field.optional ? "?" : "")"
        
        case "object":
            guard let cl = field.cl else { throw CoppyGeneratorError.error("Missing class definition for object field \(field.key)") }
            return "\(cl.name)\(field.optional ? "?" : "")"
        
        case "array":
            return "[\(field.cl?.name ?? "String")]\(field.optional ? "?" : "")"
        
        default:
            throw CoppyGeneratorError.error("Unknown field type \(field.type)")
        }
    }
    
    static func getUpdater(_ field: CoppyField, observable: Bool = false, indent: String = "        ", valueLabel: String = "v") throws -> String {
        switch (field.type) {
        case "string":
            return "\(indent)if let \(field.key) = \(valueLabel)[\"\(field.key)\"] as? String\(field.optional ? ", !\(field.key).isEmpty" : "" ) { self.\(field.key) = \(field.key)\(observable ? "; willUpdate = true" : "") }\(field.optional ? " else { self.\(field.key) = nil\(observable ? "; willUpdate = true" : "") }" : "")"
            
        case "object":
            if field.optional {
                guard let cl = field.cl else { throw CoppyGeneratorError.error("Missing class definition for object field \(field.key)") }
                return """
                    \(indent)if let \(field.key) = \(valueLabel)[\"\(field.key)\"] as? [String: Any] {
                    \(indent)    if self.\(field.key) != nil { self.\(field.key)!.update(\(field.key))\(observable ? "; willUpdate = true" : "") }
                    \(indent)    else { self.\(field.key) = \(cl.name).createFrom(\(field.key))\(observable ? "; willUpdate = true" : "") }
                    \(indent)} else { self.\(field.key) = nil\(observable ? "; willUpdate = true" : "") }
                    """
            }
            return "\(indent)if let \(field.key) = \(valueLabel)[\"\(field.key)\"] as? [String: Any] { self.\(field.key).update(\(field.key))\(observable ? "; willUpdate = true" : "") }"
            
        case "array":
            var result = """
                \(indent)if let \(field.key) = v["\(field.key)"] as? [String] {
                \(indent)    self.\(field.key) = \(field.key)\(observable ? "\n\(indent)    willUpdate = true" : "")
                \(indent)}
                """
            
            if let cl = field.cl {
                result = """
                \(indent)if let \(field.key) = v["\(field.key)"] as? [[String: Any]] {
                \(indent)    var \(field.key)List: [\(cl.name)] = []
                \(indent)    for el in \(field.key) {
                \(indent)        let _item = \(cl.name).createFrom(el)
                \(indent)        if let item = _item { \(field.key)List.append(item) }
                \(indent)    }
                \(indent)    self.\(field.key) = \(field.key)List\(observable ? "\n\(indent)    willUpdate = true" : "")
                \(indent)}
                """
            }
            
            if field.optional {
                result += " else { self.\(field.key) = nil\(observable ? "; willUpdate = true" : "") }"
            }
            
            return result
            
        default:
            throw CoppyGeneratorError.error("Unknown field type \(field.type)")
        }
    }
    
    static func getCreatorCheck(_ field: CoppyField, _ parentClassName: String, _ valueLabel: String = "obj") throws -> String {
        switch (field.type) {
        case "string":
            return "let \(field.key) = \(valueLabel)[\"\(field.key)\"] as? String"
            
        case "object":
            guard let cl = field.cl else { throw CoppyGeneratorError.error("Missing class definition for object field \(field.key)") }
            return "let \(field.key) = \(cl.name).createFrom(\(valueLabel)[\"\(field.key)\"] as? [String: Any])"
            
        case "array":
            if field.cl != nil {
                return "let \(field.key) = \(parentClassName).create\(field.key.capitalized)List(\(valueLabel)[\"\(field.key)\"] as? [[String: Any]])"
            } else {
                return "let \(field.key) = \(valueLabel)[\"\(field.key)\"] as? [String]"
            }
            
        default:
            throw CoppyGeneratorError.error("Unknown field type \(field.type)")
        }
    }
    
    static func getCreatorParams(_ field: CoppyField, _ parentClassName: String, _ valueLabel: String = "obj") throws -> String {
        if !field.optional { return field.key }
        switch (field.type) {
        case "string":
            return "\(valueLabel)[\"\(field.key)\"] as? String ?? nil"
            
        case "object":
            guard let cl = field.cl else { throw CoppyGeneratorError.error("Missing class definition for object field \(field.key)") }
            return "\(cl.name).createFrom(\(valueLabel)[\"\(field.key)\"] as? [String: Any])"
            
        case "array":
            if field.cl != nil {
                return "\(parentClassName).create\(field.key.capitalized)List(\(valueLabel)[\"\(field.key)\"] as? [[String: Any]])"
            } else {
                return "\(valueLabel)[\"\(field.key)\"] as? [String]"
            }
            
        default:
            throw CoppyGeneratorError.error("Unknown field type \(field.type)")
        }
    }
    
    static func getListCreator(_ field: CoppyField, _ indent: String = "    " , _ valueLabel: String = "obj") -> String {
        if let cl = field.cl {
            return """
                \(indent)internal static func create\(field.key.capitalized)List(_ _arr: [[String: Any]]?) -> [\(cl.name)]? {
                \(indent)    guard let arr = _arr else { return nil }
                \(indent)    var result: [\(cl.name)] = []
                \(indent)    for el in arr {
                \(indent)        let _item = \(cl.name).createFrom(el)
                \(indent)        if let item = _item { result.append(item) }
                \(indent)    }
                \(indent)    return result
                \(indent)}\n
                """
        } else { return "" }
    }
    
    static func getFieldValue(_ field: CoppyField, _ _value: Any?, _ indent: String = "        ") throws -> String {
        guard let value = _value else {
            if field.optional { return "nil" }
            throw CoppyGeneratorError.error("Missing value for not optional field \(field.key)")
        }
        switch (field.type) {
        case "string":
            guard let str = value as? String else { throw CoppyGeneratorError.error("Incorrect value passed for the string field \(field.key): \(value)") }
            if field.optional, str.isEmpty { return "nil" }
            return "#######\"\"\"\n\(indent)    \(str.components(separatedBy: .newlines).joined(separator: "\n\(indent)    "))\n\(indent)    \"\"\"#######"
            
        case "object":
            guard let obj = value as? [String: Any] else { throw CoppyGeneratorError.error("Incorrect value passed for the object field \(field.key): \(value)") }
            guard let cl = field.cl else { throw CoppyGeneratorError.error("Missing class description for the object field \(field.key)")}
            
            var values = ""
            for (index, f) in cl.fields.enumerated() {
                let isLast = index == cl.fields.count - 1
                values += "\(indent)    \(try getFieldValue(f, obj[f.key], indent + "    "))\(isLast ? "" : ",\n")"
            }
            
            return """
                \(cl.name)(
                \(values)
                \(indent))
                """
            
        case "array":
            if let cl = field.cl {
                guard let objArray = value as? [[String: Any]] else { throw CoppyGeneratorError.error("Incorrect value passed for the objects list field \(field.key): \(value)") }
                
                var values = ""
                
                for (index, obj) in objArray.enumerated() {
                    let isLast = index == objArray.count - 1
                    let nestedField = CoppyField(key: field.key, type: "object", optional: false, cl: cl)
                    values += "\(indent)    \(try getFieldValue(nestedField, obj, indent + "    "))\(isLast ? "" : ",\n")"
                }
                
                return """
                    [
                    \(values)
                    \(indent)]
                    """
            }
            
            guard let strArray = value as? [String] else { throw CoppyGeneratorError.error("Incorrect value passed for the strings list field \(field.key): \(value)") }
            var values = ""
            
            for (index, str) in strArray.enumerated() {
                let isLast = index == strArray.count - 1
                if !str.isEmpty {
                    let stringIndent = "\(indent)        "
                    values += "\(indent)    #######\"\"\"\n\(stringIndent)\(str.components(separatedBy: .newlines).joined(separator: "\n\(stringIndent)"))\n\(stringIndent)\"\"\"#######\(isLast ? "" : ",\n")"
                }
            }
            return """
                [
                \(values)
                \(indent)]
                """
            
        default:
            throw CoppyGeneratorError.error("Unknown field type \(field.type)")
        }
    }
    
    static func generateContentClass(_ cl: CoppyClass, _ content: [String: Any]) throws -> String {
        var nestedClasses = ""
        var initializers = ""
        var properties = ""
        var updaters = ""
        var encodingKeys = ""
        var encodingCalls = ""
        
        for (index, field) in cl.fields.enumerated() {
            let isLast = index == cl.fields.count - 1
            let le = isLast ? "" : "\n"
            properties += "    @Published public private(set) var \(field.key): \(try getFieldType(field))\(le)"
            initializers += "        self.\(field.key) = \(try getFieldValue(field, content[field.key]))\(le)"
            updaters += "\(try getUpdater(field, observable: true))\(le)"
            encodingKeys += "        case \(field.key)\(le)"
            encodingCalls += "        try container.encode(\(field.key), forKey: .\(field.key))\(le)"
            
            if let fcl = field.cl {
                let ncl = try generateClasses(fcl)
                nestedClasses += "\(ncl)\n\n"
            }
        }
        
        return """
            \(nestedClasses)final public class \(cl.name): CoppyUpdatable {
            \(properties)
            
                public init() {
            \(initializers)
                }
            
                public func update(_ v: [String: Any]) {
                    var willUpdate: Bool = false
            \(updaters)
                    if willUpdate { self.objectWillChange.send() }
                }
            
                enum CodingKeys: CodingKey {
            \(encodingKeys)
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
            \(encodingCalls)
                }
            }
            """
    }
    
    static func generateClasses(_ cl: CoppyClass) throws -> String {
        var nestedClasses = ""
        var variables = ""
        var initializers = ""
        var properties = ""
        var updaters = ""
        var creatorsCheck = ""
        var creatorParams = ""
        var listCreators = ""
        var encodingKeys = ""
        var encodingCalls = ""
        
        for (index, field) in cl.fields.enumerated() {
            let isLast = index == cl.fields.count - 1
            let lec = isLast ? "" : ",\n"
            let le = isLast ? "" : "\n"
            variables += "        _ \(field.key): \(try getFieldType(field))\(lec)"
            initializers += "        self.\(field.key) = \(field.key)\(le)"
            properties += "    \(field.type == "object" && !field.optional ? "public let" : "public private(set) var") \(field.key): \(try getFieldType(field))\(le)"
            updaters += "\(try getUpdater(field))\(le)"
            encodingKeys += "        case \(field.key)\(le)"
            encodingCalls += "        try container.encode(\(field.key), forKey: .\(field.key))\(le)"
            
            creatorParams += "            \(try getCreatorParams(field, cl.name))\(lec)"
            if !field.optional {
                creatorsCheck += "\(creatorsCheck == "" ? "        guard " : ",\n              ")\(try getCreatorCheck(field, cl.name))"
            }
            
            if let fcl = field.cl {
                let ncl = try generateClasses(fcl)
                nestedClasses += "\(ncl)\n\n"
            }
            
            if field.type == "array", field.cl != nil {
                listCreators += "\n\(getListCreator(field))"
            }
        }
        
        return """
            \(nestedClasses)public class \(cl.name): Encodable {
            \(properties)
            
                init(
            \(variables)
                ) {
            \(initializers)
                }
            
                internal func update(_ v: [String: Any]) {
            \(updaters)
                }
            \(listCreators)
                internal static func createFrom(_ _obj: [String: Any]?) -> \(cl.name)? {
                    guard let obj = _obj else { return nil }
            \(creatorsCheck.isEmpty ? "" : creatorsCheck + " else { return nil }\n")
                    return \(cl.name)(
            \(creatorParams)
                    )
                }
            
                enum CodingKeys: CodingKey {
            \(encodingKeys)
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
            \(encodingCalls)
                }
            }
            """
    }
}
