#!/usr/bin/env python3
"""
mros-linux Wallpaper Generator
Creates Windows 12-inspired wallpapers for mros-linux
"""

try:
    from PIL import Image, ImageDraw, ImageFilter
    import math
    import os
except ImportError:
    print("PIL (Pillow) not available. Install with: pip install Pillow")
    exit(1)

def create_gradient_wallpaper(width=1920, height=1080, filename="default.jpg"):
    """Create a Windows 12-inspired gradient wallpaper"""
    
    # Create base image
    image = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(image)
    
    # Define colors (Windows 12 inspired)
    colors = [
        (0, 120, 212),    # Windows blue
        (16, 110, 190),   # Darker blue
        (32, 100, 168),   # Even darker
        (48, 90, 146),    # Deep blue
    ]
    
    # Create vertical gradient
    for y in range(height):
        # Calculate position in gradient (0.0 to 1.0)
        position = y / height
        
        # Determine which color segment we're in
        segment = position * (len(colors) - 1)
        segment_index = int(segment)
        segment_position = segment - segment_index
        
        # Handle edge case
        if segment_index >= len(colors) - 1:
            segment_index = len(colors) - 2
            segment_position = 1.0
        
        # Interpolate between colors
        color1 = colors[segment_index]
        color2 = colors[segment_index + 1]
        
        r = int(color1[0] + (color2[0] - color1[0]) * segment_position)
        g = int(color1[1] + (color2[1] - color1[1]) * segment_position)
        b = int(color1[2] + (color2[2] - color1[2]) * segment_position)
        
        # Draw horizontal line
        draw.line([(0, y), (width, y)], fill=(r, g, b))
    
    # Add subtle geometric patterns
    add_geometric_patterns(draw, width, height)
    
    # Apply subtle blur for smoothness
    image = image.filter(ImageFilter.GaussianBlur(radius=0.5))
    
    # Save image
    image.save(filename, 'JPEG', quality=95, optimize=True)
    print(f"Wallpaper created: {filename}")

def add_geometric_patterns(draw, width, height):
    """Add subtle geometric patterns to the wallpaper"""
    
    # Add subtle circles
    for i in range(5):
        x = width * (0.2 + i * 0.15)
        y = height * (0.3 + (i % 2) * 0.4)
        radius = min(width, height) * (0.1 + i * 0.02)
        
        # Very subtle white circles
        color = (255, 255, 255, 10)  # Very transparent
        
        # Draw circle outline
        for thickness in range(3):
            draw.ellipse([
                x - radius - thickness, 
                y - radius - thickness,
                x + radius + thickness, 
                y + radius + thickness
            ], outline=(255, 255, 255, 5))

def create_abstract_wallpaper(width=1920, height=1080, filename="abstract.jpg"):
    """Create an abstract Windows 12-inspired wallpaper"""
    
    # Create base image with dark background
    image = Image.new('RGB', (width, height), color=(16, 24, 32))
    draw = ImageDraw.Draw(image)
    
    # Create flowing curves
    for i in range(20):
        # Random curve parameters
        start_x = width * (i / 20)
        start_y = height * 0.3
        
        control_x = width * ((i + 5) / 20)
        control_y = height * (0.5 + math.sin(i * 0.5) * 0.2)
        
        end_x = width * ((i + 10) / 20)
        end_y = height * 0.7
        
        # Draw bezier-like curve with multiple points
        points = []
        for t in range(101):
            t = t / 100.0
            
            # Quadratic bezier curve
            x = (1-t)**2 * start_x + 2*(1-t)*t * control_x + t**2 * end_x
            y = (1-t)**2 * start_y + 2*(1-t)*t * control_y + t**2 * end_y
            
            points.append((int(x), int(y)))
        
        # Draw curve with gradient color
        alpha = int(50 + i * 5)
        color = (0, 120 + i * 3, 212, alpha)
        
        # Draw thick line
        for j in range(len(points) - 1):
            draw.line([points[j], points[j + 1]], fill=(0, 120 + i * 3, 212), width=2)
    
    # Apply blur for smooth effect
    image = image.filter(ImageFilter.GaussianBlur(radius=1.0))
    
    # Save image
    image.save(filename, 'JPEG', quality=95, optimize=True)
    print(f"Abstract wallpaper created: {filename}")

def create_minimal_wallpaper(width=1920, height=1080, filename="minimal.jpg"):
    """Create a minimal Windows 12-inspired wallpaper"""
    
    # Create base image
    image = Image.new('RGB', (width, height), color=(245, 245, 245))
    draw = ImageDraw.Draw(image)
    
    # Add Windows logo inspired shape in center
    center_x = width // 2
    center_y = height // 2
    size = min(width, height) // 8
    
    # Draw four squares (Windows logo style)
    square_size = size // 3
    gap = size // 10
    
    squares = [
        (center_x - square_size - gap//2, center_y - square_size - gap//2),  # Top left
        (center_x + gap//2, center_y - square_size - gap//2),                # Top right
        (center_x - square_size - gap//2, center_y + gap//2),                # Bottom left
        (center_x + gap//2, center_y + gap//2),                              # Bottom right
    ]
    
    colors = [
        (0, 120, 212),    # Blue
        (16, 137, 62),    # Green
        (255, 185, 0),    # Yellow
        (232, 17, 35),    # Red
    ]
    
    for i, (x, y) in enumerate(squares):
        draw.rectangle([
            x, y, 
            x + square_size, y + square_size
        ], fill=colors[i])
    
    # Add subtle shadow
    shadow_image = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow_image)
    
    for i, (x, y) in enumerate(squares):
        shadow_draw.rectangle([
            x + 5, y + 5, 
            x + square_size + 5, y + square_size + 5
        ], fill=(0, 0, 0, 30))
    
    # Blur shadow
    shadow_image = shadow_image.filter(ImageFilter.GaussianBlur(radius=3))
    
    # Composite shadow with main image
    image = Image.alpha_composite(image.convert('RGBA'), shadow_image).convert('RGB')
    
    # Save image
    image.save(filename, 'JPEG', quality=95, optimize=True)
    print(f"Minimal wallpaper created: {filename}")

def main():
    """Create all wallpapers"""
    
    # Get current directory
    current_dir = os.path.dirname(os.path.abspath(__file__))
    
    print("Creating mros-linux wallpapers...")
    
    # Create different wallpaper styles
    create_gradient_wallpaper(1920, 1080, os.path.join(current_dir, "default.jpg"))
    create_abstract_wallpaper(1920, 1080, os.path.join(current_dir, "abstract.jpg"))
    create_minimal_wallpaper(1920, 1080, os.path.join(current_dir, "minimal.jpg"))
    
    # Create additional resolutions
    resolutions = [
        (1366, 768),   # Common laptop resolution
        (2560, 1440),  # 1440p
        (3840, 2160),  # 4K
    ]
    
    for width, height in resolutions:
        create_gradient_wallpaper(width, height, 
            os.path.join(current_dir, f"default_{width}x{height}.jpg"))
    
    print("All wallpapers created successfully!")
    print("Available wallpapers:")
    print("- default.jpg (1920x1080)")
    print("- abstract.jpg (1920x1080)")
    print("- minimal.jpg (1920x1080)")
    print("- Additional resolutions for default wallpaper")

if __name__ == "__main__":
    main()

