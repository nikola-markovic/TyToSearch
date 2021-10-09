// Created by Nikola Marković ® - MIT Licenced

import Foundation

/// Typo-Tolerant Search engine
///
/// To use this class, you just need to init it with some search terms (array of strings) of your choice and hit call the search function.

public class TyToSearchEngine {
    public static let defaultSensitivity = 1
    private var termsArray = [String]()
    private var sensitivity = defaultSensitivity
    
    /// Creates new instance of TyToSeachEngine with the passed search terms that TyTo instance will keep as its own 'dictionary' per se.
    ///
    ///
    /// - Parameter termsArray: The array of the terms or the words TyTo is going to search your searchTerm through.
    /// - Parameter sensitivity : ⚠️ in ß: this is how many times the searchTerm is going to be split to check for errors. This one is a Beta feature. Use it with caution.
    ///
    public init(with termsArray: [String], sensitivity: Int? = TyToSearchEngine.defaultSensitivity) {
        DispatchQueue.global().async {
            self.termsArray = termsArray
            if let sens = sensitivity {
                self.sensitivity = sens
            }
            debugPrint("🦉✅ TyTo Info: Init successful with: \(termsArray.count) terms/words")
        }
    }
    
    /// Creates new instance of TyToSeachEngine that will find search terms from a (json)data file under the specified keypath.
    ///
    /// - Parameter data: data from json
    /// - Parameter keyPath: key from json which’s value is an Array of strings
    /// - Parameter sensitivity : ⚠️ in ß: this is how many times the searchTerm is going to be split to check for errors. This one is a Beta feature. Use it with caution.
    ///
    /// Example of init from json data if you are getting this from your or some other HTTP call:
    /// ```
    /// //...
    /// ) { [weak self] response in
    /// if let data = response.data {
    ///     self?.tyto = TyToSearchEngine(from: data, keyPath: "countries")
    /// }
    /// // ...
    /// ```
    public convenience init(from data: Data, keyPath: String, sensitivity: Int? = TyToSearchEngine.defaultSensitivity) {
        var terms = [String]()
        if let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? NSDictionary {
            if let termsFromJson = json?.value(forKeyPath: keyPath) as? [String] {
                terms = termsFromJson
            } else {
                debugPrint("🦉❌ TyTo Error: Init error.\nJSON from provided data either doesn't contain a provided keypath \(keyPath), or the value of the keypath is not an array of strings.")
            }
        } else {
            debugPrint("🦉❌ TyTo Error: Init error.\nProvided data is not written in a proper JSON format. Please validate JSON first.")
        }
        self.init(with: terms, sensitivity: sensitivity)
    }
    
    /// Creates new instance of TyToSeachEngine that will find the array of terms/words from a json file located at jsonFilePath under its specified keyPath.
    ///
    /// - Parameter filePath: a path to the json file that has an array as a value for a specific key
    /// - Parameter keyPath: key from json which’s value is an Array of strings
    /// - Parameter sensitivity : ⚠️ in ß: this is how many times the searchTerm is going to be split to check for errors. This one is a Beta feature. Use it with caution.
    ///
    /// Example of init from json file at path
    /// ```
    /// let countriesJsonPath = Bundle.main.path(forResource: "Countries", ofType: "json") ?? ""
    /// let tyto = TyToSearchEngine(fromJsonFileAtPath: countriesJsonPath, keyPath: "countries")
    /// ```
    public convenience init(fromJsonFileAtPath filePath: String, keyPath: String, sensitivity: Int? = TyToSearchEngine.defaultSensitivity) {
        let terms = [String]()
        let url = URL(fileURLWithPath: filePath)
        do {
            let data = try Data(contentsOf: url)
            self.init(from: data, keyPath: keyPath, sensitivity: sensitivity)
        } catch let error {
            debugPrint("🦉❌ TyTo Error: Init error.\nFile is empty or there's no file at \(filePath)\nCaught error: \(error)")
            self.init(with: terms, sensitivity: sensitivity)
        }
    }
    
    /// Goes through the array of known terms/words (specified on initialization) to check it there is a term/word that’s similar to or contains the searchTerm
    ///
    /// - Parameter searchTerm: This is the term/word that the engine will try to find a hits or a misspelled suggestions from a known array of terms/words
    /// - Parameter completion: Returns 2 arrays of hits (terms/words that contains the searchTerm) and suggestions (terms/words that the search engine found as misspelled)
    /// - Parameter maximumSuggestionsCount: limit returning suggestion terms/words count to this number
    ///
    /// Example of init and search:
    /// ```
    /// let countriesJsonPath = Bundle.main.path(forResource: "Countries", ofType: "json")
    /// let tyto = TyToSearchEngine(fromJsonFileAtPath: countriesJsonPath, keyPath: "countries")
    /// tyto.search("gora") { result in
    ///   // Do your stuff by calling
    ///   // result.hits
    ///   // or
    ///   // result.suggestions
    /// }
    ///
    /// ```
    public func search(_ searchTerm: String, maximumSuggestionsCount: Int = .max, completion: @escaping ((hits: [String], suggestions: [String])) -> Void) {
        let shortest = 5
        if searchTerm.count < shortest {
            debugPrint("🦉⚠️ Warning: TyTo can't recognize typos with terms/words that are \(shortest - 1) or less characters long. *searchTerm* must be at least \(shortest) characters long.")
            completion((hits: [], suggestions: []))
            return
        }
        let arrayQueue = DispatchQueue.init(label: "arrayQueue")
        arrayQueue.async {
            var hits = [String]()
            var suggestions = [String]()
            
            let dispatchGroup = DispatchGroup()
            
            for charIndex in 0..<searchTerm.count {
                if suggestions.count >= maximumSuggestionsCount {
                    break
                }
                DispatchQueue.global().sync {
                    dispatchGroup.enter()
                    let first = searchTerm.prefix(charIndex)
                    let suffixLength = searchTerm.count - charIndex - 2
                    let last = suffixLength > -1 ? searchTerm.suffix(suffixLength) : ""
                    let regexFormat = ".*\(first).?.?\(last).*"
                    if let regex = try? NSRegularExpression(pattern: regexFormat, options: .caseInsensitive) {
                        for term in self.termsArray {
                            if (regex.firstMatch(in: term, options: .anchored, range: NSRange(location: 0, length: term.count)) != nil) {
                                arrayQueue.async {
                                    if !suggestions.contains(term.capitalized) {
                                        suggestions.append(term.capitalized)
                                    }
                                }
                            }
                        }
                    }
                    dispatchGroup.leave()
                }
            }
            dispatchGroup.wait()
            dispatchGroup.notify(queue: arrayQueue) {
                suggestions.sort(by: { $0.count < $1.count })
                hits = suggestions.filter({ $0.lowercased().contains(searchTerm.lowercased()) })
                suggestions.removeAll(where: { hits.contains($0) })
                DispatchQueue.main.async {
                    completion((hits: hits, suggestions: suggestions))
                }
            }
        }
    }
}
