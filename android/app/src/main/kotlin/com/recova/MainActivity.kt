package com.recova

import android.content.ContentUris
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        private const val CHANNEL =
            "com.recova/recently_deleted"

        private const val RESTORE_REQUEST_CODE = 1001
    }

    private var pendingRestoreResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "getRecentlyDeletedMedia" -> {

                    try {
                        val media =
                            queryRecentlyDeletedMedia()

                        result.success(media)

                    } catch (e: Exception) {

                        result.error(
                            "TRASH_SCAN_ERROR",
                            e.message
                                ?: "Trash scan failed",
                            null
                        )
                    }
                }

                "requestRestore" -> {

                    val uris =
                        call.argument<List<String>>(
                            "uris"
                        ) ?: emptyList()

                    try {

                        requestRestore(
                            uris,
                            result
                        )

                    } catch (e: Exception) {

                        result.error(
                            "TRASH_RESTORE_ERROR",
                            e.message
                                ?: "Restore request failed",
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

    /*
     * ============================================================
     * ANDROID RESTORE RESULT
     * ============================================================
     *
     * We do NOT tell Flutter that restoration succeeded merely
     * because the Android confirmation dialog was launched.
     *
     * Flutter receives the final result only after Android
     * finishes the confirmation request.
     */

    @Deprecated("Deprecated in Android API, retained for compatibility")
    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(
            requestCode,
            resultCode,
            data
        )

        if (requestCode != RESTORE_REQUEST_CODE) {
            return
        }

        val pendingResult =
            pendingRestoreResult

        pendingRestoreResult = null

        if (pendingResult == null) {
            return
        }

        if (resultCode == RESULT_OK) {

            /*
             * Android accepted the restore operation.
             */
            pendingResult.success(true)

        } else {

            /*
             * User cancelled the confirmation dialog,
             * or Android did not complete the request.
             */
            pendingResult.success(false)
        }
    }

    /*
     * ============================================================
     * RECENTLY DELETED MEDIASTORE QUERY
     * ============================================================
     *
     * Android 11+ provides MediaStore trash support.
     *
     * This returns files that are STILL in Android's trash.
     *
     * It does NOT recover permanently deleted files.
     */

    private fun queryRecentlyDeletedMedia():
        List<Map<String, Any?>> {

        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.R
        ) {
            return emptyList()
        }

        val results =
            mutableListOf<Map<String, Any?>>()

        val collection =
            MediaStore.Files.getContentUri(
                MediaStore.VOLUME_EXTERNAL
            )

        val projection = arrayOf(

            MediaStore.Files.FileColumns._ID,

            MediaStore.Files.FileColumns.DISPLAY_NAME,

            MediaStore.Files.FileColumns.MIME_TYPE,

            MediaStore.Files.FileColumns.SIZE,

            MediaStore.Files.FileColumns.DATE_MODIFIED,

            MediaStore.Files.FileColumns.MEDIA_TYPE,

            MediaStore.Files.FileColumns.IS_TRASHED,

            MediaStore.Files.FileColumns.DATE_EXPIRES,

            MediaStore.Files.FileColumns.RELATIVE_PATH
        )

        /*
         * Only files currently in MediaStore trash.
         */

        val selection =
            "${MediaStore.Files.FileColumns.IS_TRASHED} = 1"

        val queryArgs =
            Bundle().apply {

                putString(
                    android.content.ContentResolver
                        .QUERY_ARG_SQL_SELECTION,
                    selection
                )

                putInt(
                    MediaStore.QUERY_ARG_MATCH_TRASHED,
                    MediaStore.MATCH_ONLY
                )

                putString(
                    android.content.ContentResolver
                        .QUERY_ARG_SQL_SORT_ORDER,
                    "${MediaStore.Files.FileColumns.DATE_MODIFIED} DESC"
                )
            }

        val cursor =
            contentResolver.query(
                collection,
                projection,
                queryArgs,
                null
            )

        cursor?.use {

            val idColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns._ID
                )

            val nameColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns.DISPLAY_NAME
                )

            val mimeColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns.MIME_TYPE
                )

            val sizeColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns.SIZE
                )

            val modifiedColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns.DATE_MODIFIED
                )

            val mediaTypeColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns.MEDIA_TYPE
                )

            val trashedColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns.IS_TRASHED
                )

            val expiresColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns.DATE_EXPIRES
                )

            val relativePathColumn =
                it.getColumnIndex(
                    MediaStore.Files.FileColumns.RELATIVE_PATH
                )

            while (it.moveToNext()) {

                if (idColumn < 0) {
                    continue
                }

                val id =
                    it.getLong(idColumn)

                val name =
                    if (nameColumn >= 0) {
                        it.getString(nameColumn)
                            ?: "Unknown"
                    } else {
                        "Unknown"
                    }

                val mimeType =
                    if (mimeColumn >= 0) {
                        it.getString(mimeColumn)
                            ?: ""
                    } else {
                        ""
                    }

                val size =
                    if (sizeColumn >= 0) {
                        it.getLong(sizeColumn)
                    } else {
                        0L
                    }

                val dateModified =
                    if (modifiedColumn >= 0) {
                        it.getLong(modifiedColumn)
                    } else {
                        0L
                    }

                val mediaStoreType =
                    if (mediaTypeColumn >= 0) {
                        it.getInt(mediaTypeColumn)
                    } else {
                        0
                    }

                val isTrashed =
                    if (trashedColumn >= 0) {
                        it.getInt(trashedColumn)
                    } else {
                        0
                    }

                val dateExpires =
                    if (expiresColumn >= 0) {
                        it.getLong(expiresColumn)
                    } else {
                        0L
                    }

                val relativePath =
                    if (relativePathColumn >= 0) {
                        it.getString(
                            relativePathColumn
                        ) ?: ""
                    } else {
                        ""
                    }

                /*
                 * Safety check.
                 */

                if (isTrashed != 1) {
                    continue
                }

                val type =
                    determineMediaType(
                        mimeType = mimeType,
                        fileName = name,
                        mediaStoreType = mediaStoreType
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

                        "relativePath" to relativePath,

                        "mediaType" to type,

                        "isTrashed" to true
                    )
                )
            }
        }

        return results
    }

    /*
     * ============================================================
     * MEDIA TYPE DETECTION
     * ============================================================
     */

    private fun determineMediaType(
        mimeType: String,
        fileName: String,
        mediaStoreType: Int
    ): String? {

        val mime =
            mimeType
                .trim()
                .lowercase()

        val extension =
            fileName
                .substringAfterLast(
                    ".",
                    ""
                )
                .lowercase()

        /*
         * ========================================================
         * IMAGES
         * ========================================================
         */

        if (
            mime.startsWith("image/") ||
            extension in setOf(

                "jpg",
                "jpeg",
                "png",
                "webp",
                "gif",
                "bmp",
                "heic",
                "heif",
                "tif",
                "tiff",
                "avif",

                "raw",
                "cr2",
                "nef",
                "arw",
                "dng"
            )
        ) {
            return "image"
        }
 /*
         * ========================================================
         * VIDEOS
         * ========================================================
         */

        if (
            mime.startsWith("video/") ||
            extension in setOf(

                "mp4",
                "mkv",
                "avi",
                "mov",
                "3gp",
                "3gpp",
                "webm",
                "flv",
                "wmv",
                "m4v",
                "ts",
                "mts",
                "m2ts"
            )
        ) {
            return "video"
        }

        /*
         * ========================================================
         * DOCUMENTS
         * ========================================================
         */

        if (
            mime.startsWith("text/") ||

            mime.startsWith(
                "application/pdf"
            ) ||

            mime.startsWith(
                "application/msword"
            ) ||

            mime.startsWith(
                "application/vnd.ms-excel"
            ) ||

            mime.startsWith(
                "application/vnd.ms-powerpoint"
            ) ||

            mime.startsWith(
                "application/vnd.openxmlformats"
            ) ||

            mime.startsWith(
                "application/vnd.oasis.opendocument"
            ) ||

            mime == "application/rtf" ||

            mime == "application/zip" ||

            mime == "application/x-rar-compressed" ||

            mime == "application/x-7z-compressed" ||

            mime == "application/x-tar" ||

            mime == "application/gzip" ||

            extension in setOf(

                "pdf",
                "doc",
                "docx",
                "xls",
                "xlsx",
                "ppt",
                "pptx",

                "txt",
                "csv",
                "rtf",

                "odt",
                "ods",
                "odp",

                "epub",

                "html",
                "htm",

                "xml",
                "json",

                "log",
                "md",

                "zip",
                "rar",
                "7z",

                "tar",
                "gz",

                "apk"
            )
        ) {
            return "document"
        }

        /*
         * ========================================================
         * MEDIASTORE FALLBACK
         * ========================================================
         */

        if (
            mediaStoreType ==
            MediaStore.Files.FileColumns
                .MEDIA_TYPE_IMAGE
        ) {
            return "image"
        }

        if (
            mediaStoreType ==
            MediaStore.Files.FileColumns
                .MEDIA_TYPE_VIDEO
        ) {
            return "video"
        }

        return null
    }

    /*
     * ============================================================
     * RESTORE TRASH ITEMS
     * ============================================================
     *
     * Android's official MediaStore restore mechanism.
     *
     * false = move selected items OUT of Trash.
     */

    private fun requestRestore(
        uriStrings: List<String>,
        result: MethodChannel.Result
    ) {

        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.R
        ) {

            result.error(
                "UNSUPPORTED",
                "MediaStore Trash restore requires Android 11 or newer.",
                null
            )

            return
        }

        if (uriStrings.isEmpty()) {
            result.success(false)
            return
        }

        /*
         * Do not allow two Android restore requests
         * to be active at the same time.
         */

        if (pendingRestoreResult != null) {

            result.error(
                "RESTORE_ALREADY_PENDING",
                "Another restore confirmation is already pending.",
                null
            )

            return
        }

        /*
         * Remove empty and duplicate URIs.
         */

        val uniqueStrings =
            uriStrings
                .map {
                    it.trim()
                }
                .filter {
                    it.isNotEmpty()
                }
                .distinct()

        if (uniqueStrings.isEmpty()) {
            result.success(false)
            return
        }

        val uris =
            uniqueStrings.map {
                Uri.parse(it)
            }

        /*
         * false means:
         *
         * Move files OUT of trash.
         */

        val pendingIntent =
            MediaStore.createTrashRequest(
                contentResolver,
                uris,
                false
            )

        try {

            /*
             * Keep the Flutter result pending.
             *
             * It will be completed from onActivityResult()
             * after Android finishes the confirmation.
             */

            pendingRestoreResult = result

            startIntentSenderForResult(
                pendingIntent.intentSender,
                RESTORE_REQUEST_CODE,
                null,
                0,
                0,
                0
            )

        } catch (e: Exception) {

            pendingRestoreResult = null

            result.error(
                "RESTORE_REQUEST_FAILED",
                e.message
                    ?: "Unable to launch Android restore request",
                null
            )
        }
    }
}
