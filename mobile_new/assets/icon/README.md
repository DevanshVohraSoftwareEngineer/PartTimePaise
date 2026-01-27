# App Icon Setup

## Required Files

Place your icon images in this folder:

1. **app_icon.png** (1024x1024 px)
   - Your navy gear with clock and gold swoosh icon
   - Should be a square PNG with transparent or navy background
   - This will be used for both iOS and Android launcher icons

2. **splash_icon.png** (512x512 px or larger)
   - Logo/icon to display on the animated splash screen
   - Can be the same as app_icon.png or a simpler version
   - Will be displayed in the center of the navy blue splash screen

## After Adding Icons

Once you've added the images, run these commands:

```bash
cd c:\Users\vohra\OneDrive\Desktop\PartTimePaise\mobile_new

# Generate launcher icons
flutter pub run flutter_launcher_icons

# Generate splash screen assets
flutter pub run flutter_native_splash:create
```

## Current Configuration

- **Background Color**: Navy blue (#001129)
- **Adaptive Icon**: Enabled for Android with navy background
- **Platforms**: Android & iOS
- **Animated Splash**: Custom animation with waves and particles (see lib/widgets/animated_splash_screen.dart)

## Notes

- The animated splash screen is ALREADY coded and working
- You just need to provide the actual icon images
- For now, the app will show default Flutter icons until you add your images
