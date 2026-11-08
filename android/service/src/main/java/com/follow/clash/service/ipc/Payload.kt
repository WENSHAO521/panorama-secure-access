package com.follow.clash.service.ipc

import android.os.Parcel
import android.os.ParcelFileDescriptor
import android.os.Parcelable
import com.follow.clash.common.GlobalState
import kotlin.concurrent.thread

// Binder calls in flight share one 1 MB buffer, so a large payload streams through a pipe.
class Payload private constructor(
    private var bytes: ByteArray?,
    private var pipe: ParcelFileDescriptor?,
) : Parcelable {
    constructor(bytes: ByteArray) : this(bytes, null)

    constructor(text: String) : this(text.toByteArray(Charsets.UTF_8))

    fun read(): ByteArray {
        bytes?.let { return it }
        val source = pipe ?: return ByteArray(0)
        pipe = null
        return ParcelFileDescriptor.AutoCloseInputStream(source).use { it.readBytes() }
            .also { bytes = it }
    }

    fun readText(): String = String(read(), Charsets.UTF_8)

    override fun describeContents(): Int =
        if (pipe != null || (bytes?.size ?: 0) > INLINE_LIMIT) {
            Parcelable.CONTENTS_FILE_DESCRIPTOR
        } else {
            0
        }

    override fun writeToParcel(dest: Parcel, flags: Int) {
        val data = read()
        if (data.size <= INLINE_LIMIT) {
            dest.writeInt(INLINE)
            dest.writeByteArray(data)
            return
        }
        val (source, sink) = ParcelFileDescriptor.createPipe()
        dest.writeInt(PIPED)
        source.writeToParcel(dest, Parcelable.PARCELABLE_WRITE_RETURN_VALUE)
        thread(name = "PayloadWriter", isDaemon = true) {
            runCatching {
                ParcelFileDescriptor.AutoCloseOutputStream(sink).use { it.write(data) }
            }.onFailure { error -> GlobalState.log("Unable to stream payload: $error") }
        }
    }

    companion object {
        private const val INLINE = 0
        private const val PIPED = 1
        private const val INLINE_LIMIT = 128 * 1024

        @JvmField
        val CREATOR = object : Parcelable.Creator<Payload> {
            override fun createFromParcel(source: Parcel): Payload =
                when (source.readInt()) {
                    PIPED -> Payload(null, ParcelFileDescriptor.CREATOR.createFromParcel(source))
                    else -> Payload(source.createByteArray() ?: ByteArray(0), null)
                }

            override fun newArray(size: Int): Array<Payload?> = arrayOfNulls(size)
        }
    }
}
