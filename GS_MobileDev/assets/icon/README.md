# App Icon Setup

To set up the Gyaan Setu app icon:

1. **Create the icon.png file:**
   - Use the provided `icon.svg` as a reference
   - Convert it to PNG format (512x512 pixels recommended)
   - Save it as `assets/icon/icon.png`

2. **Generate app icons:**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons:main
   ```

3. **The icon should feature:**
   - Two graduation cap figures forming a bridge
   - Blue gradient colors (#1976D2 to #03DAC6)
   - White background
   - "Gyaan Setu" text at the bottom
   - Clean, modern design suitable for app stores

4. **Icon specifications:**
   - Android: Multiple sizes (48dp, 72dp, 96dp, 144dp, 192dp)
   - iOS: Multiple sizes (20pt, 29pt, 40pt, 58pt, 60pt, 76pt, 80pt, 87pt, 114pt, 120pt, 152pt, 167pt, 180pt, 1024pt)
   - Web: 192x192 and 512x512
   - Windows: 48x48
   - macOS: 1024x1024

The flutter_launcher_icons package will automatically generate all required sizes from the source PNG file.

