# ProGuard and R8 rules for Daybreak

# Keep WorkManager and Room database classes
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keep class androidx.room.** { *; }
-keep class androidx.startup.** { *; }
-keep class es.antonborri.home_widget.** { *; }
-keep class com.daybreak.daybreak.** { *; }

-dontwarn androidx.work.**
-dontwarn androidx.room.**
-dontwarn androidx.startup.**
