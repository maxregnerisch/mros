#!/usr/bin/env python3
"""
mros-linux Taskbar
Windows 12-inspired taskbar with modern design elements
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')
gi.require_version('GdkPixbuf', '2.0')

from gi.repository import Gtk, Gdk, GLib, GdkPixbuf, Gio
import subprocess
import json
import os
import time
from datetime import datetime

class MrosTaskbar(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        
        # Window properties
        self.set_title("mros-taskbar")
        self.set_decorated(False)
        self.set_resizable(False)
        
        # Set window properties for taskbar behavior
        self.set_default_size(1920, 48)  # Full width, 48px height
        
        # Position at bottom of screen
        self.setup_window_positioning()
        
        # Create main container
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.main_box.set_css_classes(['taskbar'])
        self.set_child(self.main_box)
        
        # Create taskbar sections
        self.create_start_section()
        self.create_app_section()
        self.create_system_section()
        
        # Load CSS styling
        self.load_css()
        
        # Start update timers
        self.start_timers()
    
    def setup_window_positioning(self):
        """Position taskbar at bottom of screen"""
        display = Gdk.Display.get_default()
        monitor = display.get_monitors().get_item(0)
        geometry = monitor.get_geometry()
        
        # Position at bottom
        self.set_default_size(geometry.width, 48)
        # Note: Actual positioning would require window manager cooperation
    
    def create_start_section(self):
        """Create start button and search"""
        start_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        start_box.set_css_classes(['start-section'])
        
        # Start button
        self.start_button = Gtk.Button()
        self.start_button.set_css_classes(['start-button'])
        
        # Create start icon
        start_icon = Gtk.Image.new_from_icon_name("applications-system")
        start_icon.set_pixel_size(24)
        self.start_button.set_child(start_icon)
        
        self.start_button.connect('clicked', self.on_start_clicked)
        start_box.append(self.start_button)
        
        # Search box
        self.search_entry = Gtk.Entry()
        self.search_entry.set_placeholder_text("Search apps, files, web...")
        self.search_entry.set_css_classes(['search-entry'])
        self.search_entry.set_size_request(300, -1)
        self.search_entry.connect('activate', self.on_search_activate)
        start_box.append(self.search_entry)
        
        self.main_box.append(start_box)
    
    def create_app_section(self):
        """Create running applications area"""
        self.app_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        self.app_box.set_css_classes(['app-section'])
        self.app_box.set_hexpand(True)
        
        # Add some example app buttons
        self.update_running_apps()
        
        self.main_box.append(self.app_box)
    
    def create_system_section(self):
        """Create system tray and clock"""
        system_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        system_box.set_css_classes(['system-section'])
        
        # System tray icons
        tray_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
        
        # Network icon
        network_icon = Gtk.Button()
        network_icon.set_child(Gtk.Image.new_from_icon_name("network-wireless"))
        network_icon.set_css_classes(['tray-icon'])
        tray_box.append(network_icon)
        
        # Volume icon
        volume_icon = Gtk.Button()
        volume_icon.set_child(Gtk.Image.new_from_icon_name("audio-volume-high"))
        volume_icon.set_css_classes(['tray-icon'])
        tray_box.append(volume_icon)
        
        # Battery icon (if laptop)
        battery_icon = Gtk.Button()
        battery_icon.set_child(Gtk.Image.new_from_icon_name("battery-good"))
        battery_icon.set_css_classes(['tray-icon'])
        tray_box.append(battery_icon)
        
        system_box.append(tray_box)
        
        # Clock
        self.clock_label = Gtk.Label()
        self.clock_label.set_css_classes(['clock'])
        self.update_clock()
        system_box.append(self.clock_label)
        
        # Notification center button
        notif_button = Gtk.Button()
        notif_button.set_child(Gtk.Image.new_from_icon_name("preferences-system-notifications"))
        notif_button.set_css_classes(['notification-button'])
        notif_button.connect('clicked', self.on_notifications_clicked)
        system_box.append(notif_button)
        
        self.main_box.append(system_box)
    
    def update_running_apps(self):
        """Update running applications display"""
        # Clear existing apps
        child = self.app_box.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self.app_box.remove(child)
            child = next_child
        
        # Get running applications (simplified)
        apps = self.get_running_applications()
        
        for app in apps:
            app_button = Gtk.Button()
            app_button.set_css_classes(['app-button'])
            
            # Create app icon and label
            app_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
            
            icon = Gtk.Image.new_from_icon_name(app.get('icon', 'application-x-executable'))
            icon.set_pixel_size(24)
            app_box.append(icon)
            
            label = Gtk.Label(label=app.get('name', 'Unknown'))
            label.set_ellipsize(3)  # ELLIPSIZE_END
            label.set_max_width_chars(15)
            app_box.append(label)
            
            app_button.set_child(app_box)
            app_button.connect('clicked', lambda btn, app_id=app.get('id'): self.on_app_clicked(app_id))
            
            self.app_box.append(app_button)
    
    def get_running_applications(self):
        """Get list of running applications"""
        # This is a simplified implementation
        # In a real system, this would query the window manager
        return [
            {'id': 'firefox', 'name': 'Firefox', 'icon': 'firefox'},
            {'id': 'files', 'name': 'Files', 'icon': 'folder'},
            {'id': 'terminal', 'name': 'Terminal', 'icon': 'terminal'},
        ]
    
    def update_clock(self):
        """Update clock display"""
        now = datetime.now()
        time_str = now.strftime("%I:%M %p")
        date_str = now.strftime("%m/%d/%Y")
        self.clock_label.set_markup(f"<b>{time_str}</b>\n<small>{date_str}</small>")
        return True
    
    def start_timers(self):
        """Start periodic update timers"""
        # Update clock every second
        GLib.timeout_add_seconds(1, self.update_clock)
        
        # Update running apps every 5 seconds
        GLib.timeout_add_seconds(5, lambda: (self.update_running_apps(), True)[1])
    
    def on_start_clicked(self, button):
        """Handle start button click"""
        # Launch start menu
        subprocess.Popen(['python3', '/usr/share/mros/desktop/startmenu/startmenu.py'])
    
    def on_search_activate(self, entry):
        """Handle search activation"""
        query = entry.get_text()
        if query:
            # Launch search with query
            subprocess.Popen(['mros-search', query])
            entry.set_text("")
    
    def on_app_clicked(self, app_id):
        """Handle application button click"""
        # Focus or launch application
        subprocess.Popen(['mros-app-focus', app_id])
    
    def on_notifications_clicked(self, button):
        """Handle notification center click"""
        subprocess.Popen(['mros-notifications'])
    
    def load_css(self):
        """Load CSS styling"""
        css_provider = Gtk.CssProvider()
        css_data = """
        .taskbar {
            background: rgba(32, 32, 32, 0.95);
            border-radius: 12px 12px 0px 0px;
            padding: 4px 12px;
            backdrop-filter: blur(20px);
        }
        
        .start-section {
            padding: 0px 8px;
        }
        
        .start-button {
            background: linear-gradient(135deg, #0078d4, #106ebe);
            border: none;
            border-radius: 8px;
            padding: 8px 12px;
            color: white;
            transition: all 0.2s ease;
        }
        
        .start-button:hover {
            background: linear-gradient(135deg, #106ebe, #005a9e);
            transform: scale(1.05);
        }
        
        .search-entry {
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 20px;
            padding: 8px 16px;
            color: white;
        }
        
        .search-entry:focus {
            background: rgba(255, 255, 255, 0.15);
            border-color: #0078d4;
        }
        
        .app-section {
            padding: 0px 8px;
        }
        
        .app-button {
            background: rgba(255, 255, 255, 0.1);
            border: none;
            border-radius: 8px;
            padding: 6px 12px;
            color: white;
            transition: all 0.2s ease;
        }
        
        .app-button:hover {
            background: rgba(255, 255, 255, 0.2);
            transform: translateY(-2px);
        }
        
        .system-section {
            padding: 0px 8px;
        }
        
        .tray-icon {
            background: transparent;
            border: none;
            border-radius: 6px;
            padding: 6px;
            color: white;
            transition: all 0.2s ease;
        }
        
        .tray-icon:hover {
            background: rgba(255, 255, 255, 0.1);
        }
        
        .clock {
            color: white;
            font-weight: bold;
            text-align: center;
            padding: 4px 8px;
        }
        
        .notification-button {
            background: rgba(255, 255, 255, 0.1);
            border: none;
            border-radius: 8px;
            padding: 8px;
            color: white;
            transition: all 0.2s ease;
        }
        
        .notification-button:hover {
            background: rgba(255, 255, 255, 0.2);
        }
        """
        
        css_provider.load_from_data(css_data.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

class MrosTaskbarApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='com.mros.taskbar')
    
    def do_activate(self):
        window = MrosTaskbar(self)
        window.present()

if __name__ == '__main__':
    app = MrosTaskbarApp()
    app.run()

