import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
print(arguments)
let (jsonPath, swiftPath) = (arguments[0], arguments[1])

let parentClass = URL(fileURLWithPath: jsonPath).lastPathComponent.dropLast(".json".count)
let rawJson = (try? String(contentsOf: URL(fileURLWithPath: jsonPath))) ?? ""

let jsonDict: [String: Any] = [
    String(parentClass): (try? JSONSerialization.jsonObject(with: rawJson.data(using: .utf8)!)) ?? [:]
]

var classString = ""

func getType(key:String, value: Any) -> String {
    
    switch value {
    case is String:
        return "String"
    case is Int:
        return "Int"
    case is [String: Any]:
        return "Objeto\(key)"
    case is Array<Any>:
        return "[Objeto\(key)]"
    default: return "_"
    }
}

func createClass(decodedClasses: [String : Any]?) {
    
    for aClass in decodedClasses ?? [:] {
        
        classString.append("class \(aClass.key): Decodable {\n")
        if let dict = aClass.value as? [String: Any] {
            for (key, value) in dict {
                let valueType = getType(key:key, value: value)
                classString.append("\tvar \(key) : \(valueType)?\n")
            }
            classString.append("\n\tenum UserCodingKeys: String, CodingKey {\n")
            for (key, _) in dict {
                classString.append("\t\tcase \(key) = \"\(key)\"\n")
            }
            classString.append("\t}")
            classString.append("\n\tpublic required init(from decoder: Decoder) throws {\n")
            classString.append("\t\ttry super.init(from: decoder)\n")
            classString.append("\t\tlet container = try decoder.container(keyedBy: UserCodingKeys.self)\n")
            for (key, value) in dict {
                var valueType = getType(key:key, value: value)
                if valueType == "[Objeto\(key)]" {
                    valueType = "Array"
                }
                classString.append("\t\tself.\(key) = try container.decodeIfPresent(\(valueType).self, forKey: .\(key))\n")
            }
            classString.append("\t}\n")
        }
        classString.append("""
        }
        \n
        """)
        
        if let dict = aClass.value as? [String: Any] {
            for (key, value) in dict {
                let valueType = getType(key: key, value: value)
                if valueType == "Objeto\(key)", let otherDict = value as? [String: Any] {
                    if let encodedDict = try? JSONSerialization.data(withJSONObject: otherDict), let stringDict = String(data: encodedDict, encoding: .utf8) {
                        let newClass = """
                        {
                        "\(valueType)": \(stringDict)
                        }
                        """
                        if let decodedClasses = try? JSONSerialization.jsonObject(with: newClass.data(using: .utf8)!) as? [String: Any] {
                            createClass(decodedClasses: decodedClasses)
                        }
                    }
                }
                else if valueType == "[Objeto\(key)]", let otherDict = value as? [[String: Any]] {
                    
                    if let encodedDict = try? JSONSerialization.data(withJSONObject: otherDict[0]), let stringDict = String(data: encodedDict, encoding: .utf8) {
                        let newClass = """
                        {
                        "\(valueType.dropFirst().dropLast())": \(stringDict)
                        }
                        """
                        if let decodedClasses = try? JSONSerialization.jsonObject(with: newClass.data(using: .utf8)!) as? [String: Any] {
                            createClass(decodedClasses: decodedClasses)
                        }
                    }
                }
            }
        }
    }
}

/*
if let data = json.data(using: .utf8),
    let decodedClasses = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
    createClass(decodedClasses: decodedClasses)
    print(classString)
}

*/

createClass(decodedClasses: jsonDict)
print(classString)
try? classString.write(to: URL(fileURLWithPath: swiftPath), atomically: true, encoding: .utf8)
