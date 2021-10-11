package com.nm.tytosearchexample

import kotlinx.coroutines.*
import java.util.regex.Pattern

// Created by Nikola Marković ® - MIT Licenced

/**
 * Creates new instance of TyToSeachEngine with the passed search terms that TyTo instance will keep as its own 'dictionary' per se.
 * @param termsArray 📖 [termsArray]: The array of the terms or the words TyTo is going to search your searchTerm through.
 * @param sensitivity 🥎 [sensitivity]: ⚠️ in ß: this is how many times the searchTerm is going to be split to check for errors. This one
 * is a
 * Beta feature. Use it with caution.
 */
class TyToSearchEngine(val termsArray: List<String>, val sensitivity: Int = 2) {

    init {
        println("🦉✅ TyTo Info: Init successful with: ${termsArray.size} terms/words")
    }

    /** Goes through the array of known terms/words (specified on initialization) to check it there is a term/word that’s similar to or
    contains the searchTerm
    *
    * @param searchTerm 🔍 [searchTerm] This is the term/word that the engine will try to find a hits or a misspelled suggestions from a
     * known array of terms/words
     * @param maxSuggestionCount 🪓 [maxSuggestionCount]: limit returning suggestion terms/words count to this number
     * @param completion 🏁 [completion] Returns 2 arrays of hits (terms/words that contains the searchTerm) and suggestions (terms/words that
     * the search engine found as misspelled)
    */
    fun search(searchTerm: String, maxSuggestionCount: Int = Int.MAX_VALUE, completion: ((hits: List<String>, suggestions: List<String>)
    -> Unit)) {
        if (searchTerm.length < 5) {
            println("🦉⚠️ Warning: TyTo can't recognize typos with terms/words that are 4 or less characters long. *searchTerm* must be at" +
                    " least 5 characters long.")
            completion((listOf()), (listOf()))
            return
        }
        val suggestions = mutableListOf<String>()
        GlobalScope.launch(Dispatchers.Default) {
            val charJobs = (0..searchTerm.length - 1).map { charIndex ->
                GlobalScope.async {
                    val first = searchTerm.substring(0, charIndex)
                    val last = searchTerm.substring(charIndex + 2, searchTerm.length)
                    val pattern = Pattern.compile(".*$first.?.?$last.*", Pattern.CASE_INSENSITIVE)
                    for (term in termsArray) {
                        val match = pattern.matcher(term)
                        match.useAnchoringBounds(true)
                        if (suggestions.count() >= maxSuggestionCount) {
                            break
                        }
                        if (match.find() && !suggestions.contains(term.replaceFirstChar { it.uppercase() })) {
                            suggestions.add(term.replaceFirstChar { it.uppercase() })
                        }
                    }
                }
            }
            charJobs.joinAll()
            GlobalScope.launch(Dispatchers.Main) {
                val hits = suggestions.filter { it.uppercase().contains(searchTerm.uppercase()) }
                suggestions.removeAll { hits.contains(it) }
                suggestions.sortBy { it.length }
                completion((hits), (suggestions))
            }
        }
    }
}
