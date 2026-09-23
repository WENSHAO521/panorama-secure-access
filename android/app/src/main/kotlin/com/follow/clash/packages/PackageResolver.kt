package com.follow.clash.packages

// Adapted from FlClash (chen08209/FlClash, GPL-3.0),
// android/app/src/main/kotlin/com/follow/clash/packages/PackageResolver.kt
// at v0.8.98: returns this app's Package model, keeps MATCH_UNINSTALLED_PACKAGES
// from the old AppPlugin code, and leaves out the GET_INSTALLED_APPS
// permission check, which this app doesn't request.

import android.Manifest
import android.content.pm.ApplicationInfo
import android.content.pm.ComponentInfo
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.os.Build
import com.android.tools.smali.dexlib2.dexbacked.DexBackedDexFile
import com.follow.clash.models.Package
import java.io.File
import java.util.zip.ZipFile

/**
 * Installed apps for per-app routing, cached until [invalidate] (called when
 * an app is installed, updated or removed). The cache is filled at most once
 * at a time, so concurrent callers never see a half-built or doubled list.
 */
internal class PackageResolver(
    private val packageManager: PackageManager,
    private val appPackageName: String,
) {
    private val cacheLock = Any()

    @Volatile
    private var cachedPackages: List<Package>? = null

    val installedPackages: List<Package>
        get() = cachedPackages ?: synchronized(cacheLock) {
            cachedPackages ?: loadPackages().also { cachedPackages = it }
        }

    fun invalidate() {
        synchronized(cacheLock) { cachedPackages = null }
    }

    fun getChinaPackageNames(): List<String> = installedPackages
        .map { it.packageName }
        .filter(::isChinaPackage)

    private fun loadPackages(): List<Package> {
        val flags = PackageManager.GET_META_DATA or PackageManager.GET_PERMISSIONS
        val packages = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            packageManager.getInstalledPackages(
                PackageManager.PackageInfoFlags.of(flags.toLong()),
            )
        } else {
            @Suppress("DEPRECATION")
            packageManager.getInstalledPackages(flags)
        }
        return packages.asSequence()
            .filter { info ->
                info.packageName != appPackageName && info.packageName != ANDROID_PACKAGE_NAME
            }
            .map { info ->
                Package(
                    packageName = info.packageName,
                    label = info.applicationInfo?.loadLabel(packageManager)?.toString()
                        ?: info.packageName,
                    system = info.applicationInfo?.let { applicationInfo ->
                        applicationInfo.flags and ApplicationInfo.FLAG_SYSTEM != 0
                    } == true,
                    internet = info.requestedPermissions
                        ?.contains(Manifest.permission.INTERNET) == true,
                    lastUpdateTime = info.lastUpdateTime,
                )
            }.toList()
    }

    private fun isChinaPackage(packageName: String): Boolean {
        if (ChinaPackageMatcher.isSkipped(packageName)) {
            return false
        }
        if (ChinaPackageMatcher.matchesKnownPrefix(packageName)) {
            return true
        }
        return runCatching {
            val packageInfo = getPackageInfo(packageName)
            packageInfo.componentNames().any(ChinaPackageMatcher::matchesKnownPrefix) ||
                packageInfo.applicationInfo?.publicSourceDir?.let(::scanArchive) == true
        }.getOrDefault(false)
    }

    private fun getPackageInfo(packageName: String): PackageInfo = if (
        Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
    ) {
        packageManager.getPackageInfo(
            packageName,
            PackageManager.PackageInfoFlags.of(PACKAGE_INFO_FLAGS.toLong()),
        )
    } else {
        @Suppress("DEPRECATION")
        packageManager.getPackageInfo(packageName, PACKAGE_INFO_FLAGS)
    }

    private fun PackageInfo.componentNames(): Sequence<String> = sequence {
        yieldAll(services.orEmpty().asSequence().map(ComponentInfo::name))
        yieldAll(activities.orEmpty().asSequence().map(ComponentInfo::name))
        yieldAll(receivers.orEmpty().asSequence().map(ComponentInfo::name))
        yieldAll(providers.orEmpty().asSequence().map(ComponentInfo::name))
    }

    private fun scanArchive(sourcePath: String): Boolean = ZipFile(File(sourcePath)).use { archive ->
        if (archive.entries().asSequence().any { it.name.startsWith("firebase-") }) {
            return false
        }
        archive.entries().asSequence()
            .filter { entry ->
                entry.name.startsWith("classes") && entry.name.endsWith(".dex")
            }.any { entry ->
                if (entry.size > MAX_DEX_SIZE_BYTES) {
                    return@any true
                }
                val dexFile = archive.getInputStream(entry).buffered().use { input ->
                    DexBackedDexFile.fromInputStream(null, input)
                }
                dexFile.classes.any { clazz ->
                    ChinaPackageMatcher.matchesKnownPrefix(
                        ChinaPackageMatcher.classNameOf(clazz.type),
                    )
                }
            }
    }

    companion object {
        private const val ANDROID_PACKAGE_NAME = "android"
        private const val MAX_DEX_SIZE_BYTES = 15_000_000L

        private val PACKAGE_INFO_FLAGS = PackageManager.MATCH_UNINSTALLED_PACKAGES or
            PackageManager.GET_ACTIVITIES or
            PackageManager.GET_SERVICES or
            PackageManager.GET_RECEIVERS or
            PackageManager.GET_PROVIDERS
    }
}
