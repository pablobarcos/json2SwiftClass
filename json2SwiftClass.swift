/*#!/usr/bin/swift -frontend -interpret -enable-source-import -I./Sources

import AnyCodable
import AnyDecodable
import AnyEncodable*/
import Foundation

let arguments = Array(CommandLine.arguments.dropFirst())
print(arguments)
let (jsonPath, swiftPath) = (arguments[0], arguments[1])

let parentClass = URL(fileURLWithPath: jsonPath).lastPathComponent.dropLast(".json".count)
let rawJson = (try? String(contentsOf: URL(fileURLWithPath: jsonPath))) ?? ""

let jsonDict: [String: AnyCodable] = [
    String(parentClass): (try? JSONDecoder().decode(AnyCodable.self, from: rawJson.data(using: .utf8)!)) ?? [:]
]

var classString = ""

func getType(key:String, value: AnyCodable) -> String {
    switch value.value {
    case is String:
        return "String"
    case is Int:
        return "Int"
    case is Float:
        return "Float"
    case is Double:
        return "Double"
    case is Bool:
        return "Bool"
    case is [String: Any]:
        return "Objeto\(key)"
    case is Array<Int>:
        return "[Int]"
    case is Array<String>:
        return "[String]"
    case is Array<Double>:
        return "[Double]"
    case is Array<Float>:
        return "[Float]"
    case is Array<Any>:
        return "[Objeto\(key)]"
    default: return "_"
    }
}

func createClass(decodedClasses: [String: AnyCodable]?) {
    
    for aClass in decodedClasses ?? [:] {
        classString.append("class \(aClass.key): Decodable {\n")
        
        if aClass.value.value is [String: Any], let anyDict = aClass.value.value as? [String: Any] {
            let dict = anyDict.mapValues { AnyCodable($0) }
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
                if valueType == "[Objeto\(key)]" ||  valueType == "[String]" ||  valueType == "[Int]" || valueType == "[Double]" || valueType == "[Float]"{
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
        
        if aClass.value.value is [String: Any], let anyDict = aClass.value.value as? [String: Any] {
            let dict = anyDict.mapValues { AnyCodable($0) }
            for (key, value) in dict {
                let valueType = getType(key: key, value: value)
                if valueType == "Objeto\(key)", let otherAnyDict = value.value as? [String: Any] {
                    let otherDict = otherAnyDict.mapValues { AnyCodable($0) }
                    if let encodedDict = try? JSONEncoder().encode(otherDict), let stringDict = String(data: encodedDict, encoding: .utf8) {
                        let newClass = """
                        {
                        "\(valueType)": \(stringDict)
                        }
                        """
                        if let decodedClasses = try? JSONDecoder().decode([String: AnyCodable].self, from: newClass.data(using: .utf8)!) {
                            createClass(decodedClasses: decodedClasses)
                        }
                    }
                }
                else if valueType == "[Objeto\(key)]", let anyOtherDict = value.value as? [[String: Any]] {
                    let dict = anyOtherDict[0].mapValues { AnyCodable($0) }
                    if let encodedDict = try? JSONEncoder().encode(dict), let stringDict = String(data: encodedDict, encoding: .utf8) {
                        let newClass = """
                        {
                        "\(valueType.dropFirst().dropLast())": \(stringDict)
                        }
                        """
                        if let decodedClasses = try? JSONDecoder().decode([String: AnyCodable].self, from: newClass.data(using: .utf8)!) {
                            createClass(decodedClasses: decodedClasses)
                        }
                    }
                }
            }
        }
    }
}

createClass(decodedClasses: jsonDict)
print(classString)
try? classString.write(to: URL(fileURLWithPath: swiftPath), atomically: true, encoding: .utf8)
