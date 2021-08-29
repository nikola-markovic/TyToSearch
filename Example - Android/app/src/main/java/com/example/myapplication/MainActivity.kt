package com.nm.tytosearchexample

import android.content.Context
import android.os.Bundle
import android.text.method.ScrollingMovementMethod
import android.view.KeyEvent
import android.view.View
import android.widget.EditText
import android.widget.ProgressBar
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.addTextChangedListener
import java.io.IOException
import com.google.gson.*

data class JSON(val countries: List<String>)

class MainActivity : AppCompatActivity() {

    lateinit var textView: TextView
    lateinit var textField: EditText
    lateinit var loading: ProgressBar

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContentView(R.layout.activity_main)
        textView = findViewById(R.id.textView)
        textView.setMovementMethod(ScrollingMovementMethod())
        textField = findViewById(R.id.textField)
        loading = findViewById(R.id.loading)
        loading.visibility = View.INVISIBLE
        val jsonString = getJsonDataFromAsset(context = this.applicationContext, "Countries.json")
        val gson = Gson()
        val json = gson.fromJson(jsonString, JSON::class.java)
        val search = TyToSearchEngine(
            json.countries
        )

        textField.setOnKeyListener { view, key, keyEvent ->
            if (key == KeyEvent.KEYCODE_ENTER || key == KeyEvent.KEYCODE_NUMPAD_ENTER) {
                loading.visibility = View.VISIBLE
                search.search(textField.text.toString()) { hits: List<String>, suggestions: List<String> ->
                    loading.visibility = View.INVISIBLE
                    val finalHits = if (!hits.isEmpty()) hits.joinToString(",\n") else ""
                    val finalSuggestions = if (!suggestions.isEmpty()) suggestions.joinToString(",\n", limit = 100) else ""
                    "HITS:\n${finalHits}\n\nSUGGESTIONS:\n${finalSuggestions}".also { textView.text = it }
                }
                return@setOnKeyListener true
            }
            false
        }

        textField.addTextChangedListener {
        }
    }

    fun getJsonDataFromAsset(context: Context, fileName: String): String {
        var jsonString = ""
        try {
            jsonString = context.assets.open(fileName).bufferedReader().use { it.readText() }
        } catch (ioException: IOException) {
            ioException.printStackTrace()
        }
        return jsonString
    }
}