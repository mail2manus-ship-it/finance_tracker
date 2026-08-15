# ProGuard / R8 rules for release Android builds.
#
# After running `flutter create .` to generate the android/ folder, copy
# this file to android/app/proguard-rules.pro, and make sure
# android/app/build.gradle has:
#
#   buildTypes {
#     release {
#       signingConfig signingConfigs.release
#       minifyEnabled true
#       shrinkResources true
#       proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
#     }
#   }

# Isar: keep generated schema/collection classes and native bindings.
-keep class dev.isar.isar.** { *; }
-keep class **$$IsarCollectionSchema { *; }
-keepclassmembers class * {
  @isar.annotations.* <fields>;
}

# flutter_local_notifications: keep receivers used for scheduled/repeating
# notifications (the daily reminder) so they survive R8 across app restarts.
-keep class com.dexterous.** { *; }

# local_auth / biometric prompt classes.
-keep class androidx.biometric.** { *; }

# flutter_secure_storage (Android Keystore-backed implementation).
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# pdf / printing plugin native bridge.
-keep class net.nfet.flutter.printing.** { *; }

# Keep annotations and Kotlin metadata generally, since several plugins
# rely on reflection at startup.
-keepattributes *Annotation*
-keep class kotlin.Metadata { *; }
