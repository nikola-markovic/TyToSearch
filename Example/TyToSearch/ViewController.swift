//
//  ViewController.swift
//  TTSEngine
//
//  Created by Nikola Marković on 08/22/2021.
//  Copyright (c) 2021 Nikola Marković. All rights reserved.
//

import UIKit
import TyToSearch

class ViewController: UIViewController {

    @IBOutlet var tableView: UITableView!
    @IBOutlet var loadingView: UIActivityIndicatorView!
    
    var searchEngine: TyToSearchEngine!
    var results = [[String](), [String]()] {
        didSet {
            tableView.reloadData()
        }
    }
    var sectionTitles = ["Hits", "Suggestions"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let filePath = Bundle.main.path(forResource: "Countries", ofType: "json") ?? ""
        searchEngine = TyToSearchEngine(fromJsonFileAtPath: filePath, keyPath: "countries")
    }
    
    @IBAction func didChangeSearchText(_ sender: UITextField) {
//        Uncomment this code if you're using a small array of terms/words and you want live results
//        guard let text = sender.text
//        else { return }
//        searchEngine.search(text) { result in
//            self.results = [result.hits, result.suggestions]
//        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        guard let text = textField.text
        else { return true }
        loadingView.startAnimating()
        searchEngine.search(text) { [weak self] result in
            self?.loadingView.stopAnimating()
            self?.results = [result.hits, result.suggestions]
        }
        return true
    }
}

extension ViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let term = results[indexPath.section][indexPath.row]
        let cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        cell.textLabel?.text = term
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sectionTitles[section]
    }
}
