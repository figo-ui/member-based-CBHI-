# Flutter wrapper
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Dart entry points
-keep class et.gov.ehia.cbhi.member.** { *; }

# Flutter Play Store split install (prevents R8 missing class errors)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.SplitInstallException
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManager
-dontwarn com.google.android.play.core.splitinstall.SplitInstallManagerFactory
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest$Builder
-dontwarn com.google.android.play.core.splitinstall.SplitInstallRequest
-dontwarn com.google.android.play.core.splitinstall.SplitInstallSessionState
-dontwarn com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener
-dontwarn com.google.android.play.core.tasks.OnFailureListener
-dontwarn com.google.android.play.core.tasks.OnSuccessListener
-dontwarn com.google.android.play.core.tasks.Task

# Sentry
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# flutter_secure_storage — required to prevent R8 from stripping the Android
# Keystore integration classes, which causes a ClassNotFoundException at runtime.
-keep class com.it_nomads.fluttersecurestorage.** { *; }
-keep class androidx.security.crypto.** { *; }
-dontwarn com.it_nomads.fluttersecurestorage.**

# SQLite / sqflite
-keep class com.tekartik.sqflite.** { *; }
-keep class io.flutter.plugins.sqflite.** { *; }
-dontwarn io.flutter.plugins.sqflite.**

# connectivity_plus
-keep class dev.fluttercommunity.plus.connectivity.** { *; }
-dontwarn dev.fluttercommunity.plus.connectivity.**

# image_picker / file_picker
-keep class io.flutter.plugins.imagepicker.** { *; }

# local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# Firebase / FCM
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
