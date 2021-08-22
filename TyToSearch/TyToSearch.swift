// Created by Nikola Marković ® - MIT Licenced

import Foundation

public class TyToSearchEngine {
    public static let defaultSensitivity = 1
    var termsArray = [String]()
    var sensitivity = defaultSensitivity
    
    public init(with termsArray: [String], sensitivity: Int? = TyToSearchEngine.defaultSensitivity) {
        self.termsArray = termsArray
        if let sens = sensitivity {
            self.sensitivity = sens
        }
        print("TTS: Init successful with: \(termsArray.count) words")
    }
    
    public convenience init(from data: Data, keyPath: String, sensitivity: Int? = TyToSearchEngine.defaultSensitivity) {
        var terms = [String]()
        if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary {
            if let termsFromJson = json?.value(forKeyPath: keyPath) as? [String] {
                terms = termsFromJson
            } else {
                print("TTS: Init error.\nJSON from provided data either doesn't contain a provided keypath \(keyPath), or the value of the keypath is not an array of strings.")
            }
        } else {
            print("TTS: Init error.\nProvided data is not written in a proper JSON format. Please validate JSON first.")
        }
        self.init(with: terms, sensitivity: sensitivity)
    }

    public convenience init(fromFileAtPath filePath: String, keyPath: String, sensitivity: Int? = TyToSearchEngine.defaultSensitivity) {
        let terms = [String]()
        let url = URL(fileURLWithPath: filePath)
        do {
            let data = try Data(contentsOf: url)
            self.init(from: data, keyPath: keyPath, sensitivity: sensitivity)
        } catch let error {
            print("TTS: Init error.\nFile is empty or there's no file at \(filePath)\nCaught error: \(error)")
            self.init(with: terms, sensitivity: sensitivity)
        }
    }
    
    public func search(_ searchTerm: String, completion: @escaping ((hits: [String], suggestions: [String])) -> Void) {
        let arrayQueue = DispatchQueue.init(label: "arrayQueue")
        arrayQueue.async {
            var hits = [String]()
            var suggestions = [String]()

            let dispatchGroup = DispatchGroup()
            
            for termCharacter in searchTerm {
                DispatchQueue.global().async {
                    dispatchGroup.enter()
                    let separated = searchTerm.split(separator: termCharacter, maxSplits: self.sensitivity, omittingEmptySubsequences: false)
                    if let first = separated.first,
                       let last = separated.last?.dropFirst() {
                        let regexFormat = "\(first)[A-Z0-9a-z]*\(last)"
                        if let regex = try? NSRegularExpression(pattern: regexFormat, options: .caseInsensitive) {
                            for term in self.termsArray {
                                if (regex.firstMatch(in: term, options: .anchored, range: NSRange(location: 0, length: term.count)) != nil) {
                                    arrayQueue.async {
                                        if !suggestions.contains(term) {
                                            suggestions.append(term)
                                            hits = suggestions.filter({ $0.lowercased().contains(searchTerm.lowercased()) })
                                            DispatchQueue.main.async {
                                                completion((hits: hits, suggestions: suggestions))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    dispatchGroup.leave()
                }
            }
            _ = dispatchGroup.wait(wallTimeout: DispatchWallTime.now() + 1.0)
            dispatchGroup.notify(queue: arrayQueue) {
                hits = suggestions.filter({ $0.lowercased().contains(searchTerm.lowercased()) })
                suggestions.removeAll(where: { hits.contains($0) })
                DispatchQueue.main.async {
                    completion((hits: hits, suggestions: suggestions))
                }
            }
        }
    }
}
