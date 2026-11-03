package app.ledgerly.ledgerly

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

/**
 * Ledgerly's only native code: a backup folder the person chooses through Android's folder
 * picker. Access is kept across restarts with a persisted URI permission. File work runs on
 * one background thread and answers on the main thread.
 */
class MainActivity : FlutterActivity() {
    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var picking: MethodChannel.Result? = null
    private var previousUri: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "ledgerly/folder")
            .setMethodCallHandler { call, result ->
                if (call.method == "pick") pick(call, result) else inBackground(call, result)
            }
    }

    @Suppress("DEPRECATION")
    private fun pick(call: MethodCall, result: MethodChannel.Result) {
        if (picking != null) {
            result.error("busy", "The folder picker is already open.", null)
            return
        }
        picking = result
        previousUri = call.argument<String>("previous")
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
        )
        startActivityForResult(intent, PICK_FOLDER)
    }

    @Deprecated("Deprecated in Java")
    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != PICK_FOLDER) return
        val result = picking ?: return
        picking = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return
        }
        try {
            val flags = Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            contentResolver.takePersistableUriPermission(uri, flags)
            val previous = previousUri
            if (previous != null && previous != uri.toString()) {
                runCatching { contentResolver.releasePersistableUriPermission(Uri.parse(previous), flags) }
            }
            val name = Folder(contentResolver, uri).displayName() ?: uri.lastPathSegment ?: "Chosen folder"
            result.success(mapOf("uri" to uri.toString(), "name" to name))
        } catch (e: Exception) {
            result.error("io", e.message, null)
        }
    }

    private fun inBackground(call: MethodCall, result: MethodChannel.Result) {
        io.execute {
            try {
                val folder = Folder(contentResolver, Uri.parse(call.argument<String>("uri")))
                val name = call.argument<String>("name")
                val path = call.argument<String>("path")
                val answer: Any? = when (call.method) {
                    "canAccess" -> folder.canAccess()
                    "list" -> folder.list()
                    "put" -> folder.put(name!!, File(path!!)).let { null }
                    "remove" -> folder.remove(name!!).let { null }
                    "fetch" -> folder.fetch(name!!, File(path!!)).let { null }
                    else -> throw IllegalArgumentException("Unknown call ${call.method}")
                }
                main.post { result.success(answer) }
            } catch (e: Exception) {
                main.post { result.error("io", e.message ?: e.toString(), null) }
            }
        }
    }

    private companion object {
        const val PICK_FOLDER = 4711
    }
}

/** A folder chosen with the system picker, reached through its tree URI. */
private class Folder(private val resolver: ContentResolver, private val tree: Uri) {
    private val treeId = DocumentsContract.getTreeDocumentId(tree)
    private val self = DocumentsContract.buildDocumentUriUsingTree(tree, treeId)
    private val children = DocumentsContract.buildChildDocumentsUriUsingTree(tree, treeId)

    fun displayName(): String? =
        resolver.query(self, arrayOf(Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) it.getString(0) else null
        }

    /** The permission is still held and the folder still exists. */
    fun canAccess(): Boolean {
        val held = resolver.persistedUriPermissions.any {
            it.uri == tree && it.isReadPermission && it.isWritePermission
        }
        return held && runCatching { displayName() != null }.getOrDefault(false)
    }

    fun list(): List<Map<String, Any?>> {
        val columns = arrayOf(
            Document.COLUMN_DOCUMENT_ID,
            Document.COLUMN_DISPLAY_NAME,
            Document.COLUMN_SIZE,
            Document.COLUMN_LAST_MODIFIED,
            Document.COLUMN_MIME_TYPE,
        )
        val out = mutableListOf<Map<String, Any?>>()
        resolver.query(children, columns, null, null, null)?.use {
            while (it.moveToNext()) {
                if (it.getString(4) == Document.MIME_TYPE_DIR) continue
                out.add(
                    mapOf(
                        "id" to it.getString(0),
                        "name" to it.getString(1),
                        "size" to it.getLong(2),
                        "modified" to it.getLong(3),
                    ),
                )
            }
        }
        return out
    }

    private fun find(name: String): Uri? =
        list().firstOrNull { it["name"] == name }?.let {
            DocumentsContract.buildDocumentUriUsingTree(tree, it["id"] as String)
        }

    /** Writes "name.part" first and renames it, so a backup is complete or absent. */
    fun put(name: String, source: File) {
        find("$name.part")?.let { DocumentsContract.deleteDocument(resolver, it) }
        val part = DocumentsContract.createDocument(resolver, self, "application/octet-stream", "$name.part")
            ?: throw IllegalStateException("The folder refused a new file.")
        resolver.openOutputStream(part, "wt").use { out ->
            source.inputStream().use { it.copyTo(out!!) }
        }
        find(name)?.let { DocumentsContract.deleteDocument(resolver, it) }
        val renamed = runCatching { DocumentsContract.renameDocument(resolver, part, name) }.getOrNull()
        if (renamed == null) {
            // Some folders cannot rename: write the final name directly, then drop the part.
            val target = DocumentsContract.createDocument(resolver, self, "application/octet-stream", name)
                ?: throw IllegalStateException("The folder refused a new file.")
            resolver.openOutputStream(target, "wt").use { out ->
                source.inputStream().use { it.copyTo(out!!) }
            }
            DocumentsContract.deleteDocument(resolver, part)
        }
    }

    fun remove(name: String) {
        find(name)?.let { DocumentsContract.deleteDocument(resolver, it) }
    }

    fun fetch(name: String, target: File) {
        val uri = find(name) ?: throw IllegalStateException("$name is no longer in the folder.")
        target.parentFile?.mkdirs()
        resolver.openInputStream(uri).use { input ->
            target.outputStream().use { input!!.copyTo(it) }
        }
    }
}
