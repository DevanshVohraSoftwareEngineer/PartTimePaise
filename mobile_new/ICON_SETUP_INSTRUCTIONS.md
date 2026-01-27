# Icon Setup Instructions

## The provided icon image needs to be saved manually:

1. **Save the icon image:**
   - Take the image you provided (navy blue gear with clock and gold swoosh)
   - Save it as: `c:\Users\vohra\OneDrive\Desktop\PartTimePaise\mobile_new\assets\icon\app_icon.png`
   - Recommended size: 1024x1024 pixels or 512x512 pixels
   - Format: PNG with transparent background

2. **Create splash icon (optional simplified version):**
   - Save the same image or a simplified version as: `assets\icon\splash_icon.png`
   - Recommended size: 512x512 pixels

3. **Generate launcher icons:**
   ```bash
   cd c:\Users\vohra\OneDrive\Desktop\PartTimePaise\mobile_new
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

4. **Generate splash screen:**
   ```bash
   flutter pub run flutter_native_splash:create
   ```

5. **Test the app:**
   ```bash
   flutter run -d emulator-5554
   ```

## Alternative: Use temporary placeholder

If you don't have the image file ready, I'll create a navy blue placeholder icon for now:

The app will use:
- Navy blue (#001129) background
- White animated waves
- Circular glow effect
- Your logo in the center
- Floating particles animation
- "PartTimePaise" text with gradient
- Loading indicator

Once you save your icon image, run the commands above to apply it!
