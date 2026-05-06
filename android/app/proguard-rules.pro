# ── Flutter ──────────────────────────────────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-dontwarn io.flutter.**

# ── Kotlin ────────────────────────────────────────────────────────────────────
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

# ── Dio / OkHttp / Retrofit (HTTP client) ────────────────────────────────────
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# ── Gson / JSON serialization (used by Dio) ──────────────────────────────────
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ── Firebase / FCM ────────────────────────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Ably realtime ─────────────────────────────────────────────────────────────
-keep class io.ably.** { *; }
-dontwarn io.ably.**

# ── Flutter Secure Storage ────────────────────────────────────────────────────
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ── permission_handler ────────────────────────────────────────────────────────
-keep class com.baseflow.permissionhandler.** { *; }

# ── url_launcher ──────────────────────────────────────────────────────────────
-keep class io.flutter.plugins.urllauncher.** { *; }

# ── Google Sign-In ────────────────────────────────────────────────────────────
-keep class com.google.android.gms.auth.** { *; }
-keep class com.google.android.gms.common.** { *; }

# ── Cached Network Image / Glide ──────────────────────────────────────────────
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule { *; }
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}

# ── Shared Preferences ────────────────────────────────────────────────────────
-keep class androidx.datastore.** { *; }

# ── Suppress common warnings ──────────────────────────────────────────────────
-dontwarn javax.annotation.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn sun.misc.**
