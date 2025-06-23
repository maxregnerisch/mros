# mros-linux Themes

This directory contains the visual themes and assets for mros-linux, providing a Windows 12-inspired look and feel.

## Theme Structure

### windows12-theme/
The main Windows 12-inspired theme for mros-linux.

#### Components:
- **theme.conf** - Main theme configuration with colors, effects, and styling options
- **gtk.css** - GTK4 CSS styling for applications
- **wallpapers/** - Desktop wallpapers and background images
- **icons/** - Icon theme configuration and assets
- **cursors/** - Mouse cursor theme
- **sounds/** - System sound theme

## Theme Features

### Visual Design
- **Rounded Corners** - Modern rounded corner design throughout the interface
- **Transparency Effects** - Blur and transparency effects for modern look
- **Smooth Animations** - Fluid transitions and animations
- **Consistent Color Scheme** - Windows 12-inspired color palette

### Color Palette
- **Accent Color**: #0078d4 (Windows Blue)
- **Background**: Light grays and whites
- **Text**: Dark grays for readability
- **Surfaces**: Layered whites and light grays

### Typography
- **Font Family**: Segoe UI, Ubuntu, sans-serif
- **Font Sizes**: 14px base with proper hierarchy
- **Font Weights**: 400 (normal), 600 (headings)

## Installation

The themes are automatically installed during the mros-linux build process. Manual installation:

```bash
# Copy theme to system directory
sudo cp -r mros-themes/windows12-theme /usr/share/mros/themes/

# Set as default theme
gsettings set org.gnome.desktop.interface gtk-theme "windows12-theme"
gsettings set org.gnome.desktop.interface icon-theme "mros-icons"
gsettings set org.gnome.desktop.interface cursor-theme "mros-cursors"
```

## Customization

### Modifying Colors
Edit `windows12-theme/theme.conf` to change the color scheme:

```ini
[Colors]
AccentColor=#0078d4        # Change accent color
BackgroundPrimary=#f3f3f3  # Change background color
TextPrimary=#323130        # Change text color
```

### Adding Wallpapers
1. Add wallpaper files to `windows12-theme/wallpapers/`
2. Update wallpaper references in theme configuration
3. Use the wallpaper generator script:

```bash
cd mros-themes/windows12-theme/wallpapers/
python3 create_wallpaper.py
```

### Customizing Effects
Modify visual effects in `theme.conf`:

```ini
[Effects]
RoundedCorners=true     # Enable/disable rounded corners
Transparency=true       # Enable/disable transparency
BlurEffects=true       # Enable/disable blur effects
Animations=true        # Enable/disable animations
```

## Theme Components

### Taskbar Styling
- Semi-transparent dark background
- Rounded top corners
- Blur effect backdrop
- Modern button styling

### Start Menu
- Dark semi-transparent background
- Rounded corners with border
- Smooth animations
- Grid layout for pinned apps

### File Manager
- Light ribbon interface
- Rounded buttons and controls
- Hover effects and transitions
- Upload integration styling

### Windows
- Rounded window corners
- Modern title bars
- Smooth window controls
- Consistent border styling

## Development

### Adding New Themes
1. Create new theme directory: `mros-themes/new-theme-name/`
2. Copy structure from `windows12-theme/`
3. Modify configuration files
4. Update build scripts to include new theme

### Testing Themes
```bash
# Test theme components
cd mros-themes/windows12-theme/wallpapers/
python3 create_wallpaper.py

# Apply theme for testing
gsettings set org.gnome.desktop.interface gtk-theme "windows12-theme"
```

### Theme Guidelines
- Maintain consistency across all components
- Follow accessibility guidelines for contrast
- Test with different screen resolutions
- Ensure compatibility with GTK4 applications

## File Structure

```
mros-themes/
├── README.md
└── windows12-theme/
    ├── theme.conf              # Main theme configuration
    ├── gtk.css                 # GTK4 styling
    ├── wallpapers/
    │   ├── create_wallpaper.py # Wallpaper generator
    │   ├── default.jpg         # Default wallpaper
    │   ├── abstract.jpg        # Abstract wallpaper
    │   └── minimal.jpg         # Minimal wallpaper
    ├── icons/
    │   └── icon-theme.conf     # Icon theme configuration
    ├── cursors/
    │   └── cursor-theme.conf   # Cursor theme configuration
    └── sounds/
        └── sound-theme.conf    # Sound theme configuration
```

## Contributing

When contributing to themes:

1. **Maintain Consistency** - Follow the established design language
2. **Test Thoroughly** - Test on different screen sizes and resolutions
3. **Document Changes** - Update configuration files and documentation
4. **Follow Standards** - Use standard theme formats and conventions

## License

The mros-linux themes are released under the same license as the main project (GPL-3.0).

## Credits

- Inspired by Microsoft Windows 12 design language
- Built on GTK4 theming standards
- Uses Freedesktop.org icon and sound specifications

