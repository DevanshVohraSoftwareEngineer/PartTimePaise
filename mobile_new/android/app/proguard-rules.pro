# General ML Kit keep rules
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_vision_text_common.** { *; }
-keep class com.google.android.gms.vision.text.** { *; }
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.**
-dontwarn com.google.mlkit.**

# Supabase & Realtime Keep Rules
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-dontwarn io.supabase.**

# Razorpay Keep Rules
-keepclassmembers class com.razorpay.Checkout {
  public void onSuccess(java.lang.String);
  public void onError(int, java.lang.String);
}
-keep class com.razorpay.** {*;}
-dontwarn com.razorpay.**

# Agora RTC keep rules
-keep class io.agora.** { *; }

# Flutter Wrapper keep rules
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }

# Obfuscation (Rename classes/methods for smaller size)
# Temporarily disabling aggressive repackaging due to R8 errors
# -repackageclasses ''
-allowaccessmodification
-printmapping mapping.txt
