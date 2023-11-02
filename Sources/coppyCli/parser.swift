import Foundation

internal struct CoppyField {
    let key: String
    var type: String
    var optional: Bool
    var cl: CoppyClass?
}

internal struct CoppyClass {
    var fields: [CoppyField]
    let name: String
}

internal struct CoppyParser {
    static func parseJson(obj: [String: Any], name: String) -> CoppyClass {
        var fields = [CoppyField]()

        for (key, value) in obj {
            if let field = getField(key: key, value: value, parentName: name) {
                fields.append(field)
            }
        }

        return CoppyClass(fields: fields, name: name)
    }

    private static func getField(key: String, value: Any, parentName: String) -> CoppyField? {
        if let str = value as? String {
            return CoppyField(key: key, type: "string", optional: str.isEmpty, cl: nil)
        }

        if let dict = value as? [String: Any] {
            return CoppyField(key: key, type: "object", optional: false, cl: parseJson(obj: dict, name: parentName + key.capitalized))
        }

        if let arr = value as? [Any], !arr.isEmpty {
            var valid = true
            var type: String?
            var nestedClass: CoppyClass?

            for item in arr {
                switch type {
                    case nil:
                        if item is String {
                            type = "string"
                        } else if let dict = item as? [String: Any] {
                            type = "object"
                            nestedClass = parseJson(obj: dict, name: parentName + key.capitalized)
                        }
                    case "string":
                        if !(item is String) {
                            valid = false
                            break
                        }
                    case "object":
                        guard let item = item as? [String: Any], nestedClass != nil else { valid = false; break }
                        let fields = Set(nestedClass!.fields.map { $0.key } + item.keys)
                        for fieldName in fields {
                            if let field = nestedClass!.fields.first(where: { $0.key == fieldName }) {
                                if let itemField = item[fieldName] {
                                    if itemField is String, field.type != "string" { valid = false; break }
                                    if itemField is [String: Any], field.type != "object" { valid = false; break }
                                    if itemField is [Any], field.type != "array" { valid = false; break }
                                } else {
                                    if let index = nestedClass!.fields.firstIndex(where: { $0.key == fieldName }) {
                                        nestedClass!.fields[index].optional = true
                                    }
                                }
                            } else if var field = getField(key: fieldName, value: item[fieldName]!, parentName: nestedClass!.name) {
                                field.optional = true
                                nestedClass!.fields.append(field)
                            }
                        }
                    default:
                        break
                }
            }

            if valid, type != nil {
                return CoppyField(key: key, type: "array", optional: false, cl: nestedClass)
            }
        }

        return nil
    }
}
