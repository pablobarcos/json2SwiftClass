# json2SwiftClass
Convert a .json file to a swift decodable class

## Usage
  1. Download the project.

  2. Open the terminal.

  3. Navigate to project directory.

  4. Enter: 
  ```
  ./json2SwiftClass "{input .json path}" "{output path}/SwiftClass.swift"
  ```
  5. Open the new SwiftClass.swift created in the output path directory 
 
 ### Change the code
 
  1. Change the code of the json2SwiftClass.swift
  
  2. Delete json2SwiftClass exe

  2. Open the terminal.

  3. Navigate to project directory.
  
  4. Enter:
  ```
  cat AnyCodable.swift json2SwiftClass.swift | swiftc - 
  ```
  5. Rename "main" exe to "json2SwiftClass"
  
  6. Do steps: 4,5 of Usage
  
