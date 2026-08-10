package com.example.smart_media_recovery

import android.content.ContentUris
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL = "com.recova/recently_deleted"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getRecentlyDeletedMedia" -> {
                    try {
                        val media = queryRecentlyDeletedMedia()
                        result.success(media)
                    } catch (e: Exception) {
                        result.error(
                            "TRASH_SCAN_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                "requestRestore" -> {

                    val uris = call.argument<List<String>>("uris")
                        ?: emptyList()

                    try {
                        requestRestore(uris, result)
                    } catch (e: Exception) {
                        result.error(
                            "TRASH_RESTORE_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun queryRecentlyDeletedMedia(): List<Map<String, Any?>> {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            return emptyList()
        }

        val results = mutableListOf<Map<String, Any?>>()

        val collection =
            MediaStore.Files.getContentUri("external")

        val projection = arrayOf(
            MediaStore.Files.FileColumns._ID,
            MediaStore.Files.FileColumns.DISPLAY_NAME,
            MediaStore.Files.FileColumns.MIME_TYPE,
            MediaStore.Files.FileColumns.SIZE,
            MediaStore.Files.FileColumns.DATE_MODIFIED,
            MediaStore.Files.FileColumns.MEDIA_TYPE,
            MediaStore.Files.FileColumns.IS_TRASHED,
            MediaStore.Files.FileColumns.DATE_EXPIRES
        )

        val selection =
            "${MediaStore.Files.FileColumns.IS_TRASHED} = 1"

        /*
         * QUERY_ARG_MATCH_TRASHED is required on Android 11+
         * when querying trashed MediaStore items.
         */
        val queryArgs = android.os.Bundle().apply {

            putString(
                android.content.ContentResolver.QUERY_ARG_SQL_SELECTION,
                selection
            )

            putInt(
                MediaStore.QUERY_ARG_MATCH_TRASHED,
                MediaStore.MATCH_ONLY
            )
        }

        val cursor = contentResolver.query(
            collection,
            projection,
            queryArgs,
            null
        )

        cursor?.use {

            val idColumn =
                it.getColumnIndex(MediaStore.Files.FileColumns._ID)

            val nameColumn =
                it.getColumnIndex(MediaStore.Files.FileColumns.DISPLAY_NAME)

            val mimeColumn =
                it.getColumnIndex(MediaStore.Files.FileColumns.MIME_TYPE)

            val sizeColumn =
                it.getColumnIndex(MediaStore.Files.FileColumns.SIZE)

            val modifiedColumn =
                it.getColumnIndex(MediaStore.Files.FileColumns.DATE_MODIFIED)

            val mediaTypeColumn =
                it.getColumnIndex(MediaStore.Files.FileColumns.MEDIA_TYPE)

            val trashedColumn =
                it.getColumnIndex(MediaStore.Files.FileColumns.IS_TRASHED)

            val expiresColumn =
                it.getColumnIndex(MediaStore.Files.FileColumns.DATE_EXPIRES)

            while (it.moveToNext()) {

                val id = it.getLong(idColumn)

                val name =
                    if (nameColumn >= 0)
                        it.getString(nameColumn) ?: "Unknown"
                    else
                        "Unknown"

                val mimeType =
                    if (mimeColumn >= 0)
                        it.getString(mimeColumn) ?: ""
                    else
                        ""

                val size =
                    if (sizeColumn >= 0)
                        it.getLong(sizeColumn)
                    else
                        0L

                val dateModified =
                    if (modifiedColumn >= 0)
                        it.getLong(modifiedColumn)
                    else
                        0L

                val mediaType =
                    if (mediaTypeColumn >= 0)
                        it.getInt(mediaTypeColumn)
                    else
                        0

                val isTrashed =
                    if (trashedColumn >= 0)
                        it.getInt(trashedColumn)
                    else
                        0

                val dateExpires =
                    if (expiresColumn >= 0)
                        it.getLong(expiresColumn)
                    else
                        0L

                if (isTrashed != 1) {
                    continue
                }

                /*
                 * We only expose media/document types that Recova
                 * understands.
                 */
                val type = determineMediaType(
                    mimeType,
                    name,
                    mediaType
                )

                if (type == null) {
                    continue
                }

                val uri =
                    ContentUris.withAppendedId(
                        collection,
                        id
                    )

                results.add(
                    mapOf(
                        "id" to id,
                        "uri" to uri.toString(),
                        "name" to name,
                        "mimeType" to mimeType,
                        "size" to size,
                        "dateModified" to dateModified,
                        "dateExpires" to dateExpires,
                        "mediaType" to type,
                        "isTrashed" to true
                    )
                )
            }
        }

        return results
    }

    private fun determineMediaType(
        mimeType: String,
        fileName: String,
        mediaStoreType: Int
    ): String? {

        val mime = mimeType.lowercase()
        val extension =
            fileName.substringAfterLast(
                ".",
                ""
            ).lowercase()

        if (
            mime.startsWith("image/") ||
            extension in setOf(
                "jpg",
                "jpeg",
                "png",
                "webp",
                "gif"
            )
        ) {
            return "image"
        }

        if (
            mime.startsWith("video/") ||
            extension in setOf(
                "mp4",
                "mkv",
                "avi",
                "mov",
                "3gp"
            )
        ) {
            return "video"
        }

        if (
            mime == "application/pdf" ||
            extension in setOf(
                "pdf",
                "doc",
                "docx",
                "xls",
                "xlsx",
                "ppt",
                "pptx",
                "txt",
                "zip"
            )
        ) {
            return "document"
        }

        return null
    }

    private fun requestRestore(
        uriStrings: List<String>,
        result: MethodChannel.Result
    ) {

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            result.error(
                "UNSUPPORTED",
                "Trash restore requires Android 11 or newer.",
                null
            )
            return
        }

        if (uriStrings.isEmpty()) {
            result.success(false)
            return
        }

        val uris = uriStrings.map {
            Uri.parse(it)
        }

        /*
         * Android's supported Trash restore request.
         *
         * The system confirmation dialog is shown to the user.
         */
        val pendingIntent =
            MediaStore.createTrashRequest(
                contentResolver,
                uris,
                false
            )

        try {
            startIntentSenderForResult(
                pendingIntent.intentSender,
                1001,
                null,
                0,
                0,
                0
            )

            result.success(true)

        } catch (e: Exception) {

            result.error(
                "RESTORE_REQUEST_FAILED",
                e.message,
                null
            )
        }
    }
}
