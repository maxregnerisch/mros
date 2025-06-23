#!/usr/bin/env python3
"""
mros-linux Start Menu
Windows 12-inspired start menu with modern design and search functionality
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')

from gi.repository import Gtk, Gdk, GLib, Gio
import subprocess
import json
import os
import glob
from pathlib import Path

class MrosStartMenu(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        
        # Window properties
        self.set_title("mros-startmenu")
        self.set_decorated(False)
        self.set_resizable(False)
        self.set_default_size(600, 700)
        
        # Make window modal and centered
        self.set_modal(True)
        
        # Create main container
        self.main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.main_box.set_css_classes(['start-menu'])
        self.set_child(self.main_box)
        
        # Create menu sections
        self.create_header()
        self.create_search_section()
        self.create_pinned_section()
        self.create_apps_section()
        self.create_footer()
        
        # Load applications
        self.applications = self.load_applications()
        self.populate_apps()
        
        # Load CSS styling
        self.load_css()
        
        # Connect escape key to close
        self.setup_key_handlers()
    
    def create_header(self):
        """Create header with user info"""
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        header_box.set_css_classes(['header'])
        
        # User avatar
        avatar = Gtk.Image.new_from_icon_name("avatar-default")
        avatar.set_pixel_size(48)
        avatar.set_css_classes(['user-avatar'])
        header_box.append(avatar)
        
        # User info
        user_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        user_box.set_hexpand(True)
        
        username = os.getenv('USER', 'User')
        user_label = Gtk.Label(label=f"Hello, {username}")
        user_label.set_css_classes(['user-name'])
        user_label.set_halign(Gtk.Align.START)
        user_box.append(user_label)
        
        status_label = Gtk.Label(label="Ready to work")
        status_label.set_css_classes(['user-status'])
        status_label.set_halign(Gtk.Align.START)
        user_box.append(status_label)
        
        header_box.append(user_box)
        
        # Power button
        power_button = Gtk.Button()
        power_button.set_child(Gtk.Image.new_from_icon_name("system-shutdown"))
        power_button.set_css_classes(['power-button'])
        power_button.connect('clicked', self.on_power_clicked)
        header_box.append(power_button)
        
        self.main_box.append(header_box)
    
    def create_search_section(self):
        """Create search bar"""
        search_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        search_box.set_css_classes(['search-section'])
        
        self.search_entry = Gtk.Entry()
        self.search_entry.set_placeholder_text("Search for apps, files, and more...")
        self.search_entry.set_css_classes(['search-entry'])
        self.search_entry.set_hexpand(True)
        self.search_entry.connect('changed', self.on_search_changed)
        search_box.append(self.search_entry)
        
        search_button = Gtk.Button()
        search_button.set_child(Gtk.Image.new_from_icon_name("system-search"))
        search_button.set_css_classes(['search-button'])
        search_box.append(search_button)
        
        self.main_box.append(search_box)
    
    def create_pinned_section(self):
        """Create pinned applications section"""
        pinned_label = Gtk.Label(label="Pinned")
        pinned_label.set_css_classes(['section-label'])
        pinned_label.set_halign(Gtk.Align.START)
        self.main_box.append(pinned_label)
        
        # Pinned apps grid
        self.pinned_grid = Gtk.FlowBox()
        self.pinned_grid.set_css_classes(['pinned-grid'])
        self.pinned_grid.set_max_children_per_line(4)
        self.pinned_grid.set_selection_mode(Gtk.SelectionMode.NONE)
        
        # Add some pinned apps
        pinned_apps = [
            {'name': 'Firefox', 'icon': 'firefox', 'exec': 'firefox'},
            {'name': 'Files', 'icon': 'folder', 'exec': 'thunar'},
            {'name': 'Terminal', 'icon': 'terminal', 'exec': 'gnome-terminal'},
            {'name': 'Settings', 'icon': 'preferences-system', 'exec': 'mros-settings'},
            {'name': 'Calculator', 'icon': 'accessories-calculator', 'exec': 'gnome-calculator'},
            {'name': 'Text Editor', 'icon': 'accessories-text-editor', 'exec': 'gedit'},
        ]
        
        for app in pinned_apps:
            self.add_pinned_app(app)
        
        self.main_box.append(self.pinned_grid)
    
    def create_apps_section(self):
        """Create all applications section"""
        apps_label = Gtk.Label(label="All Apps")
        apps_label.set_css_classes(['section-label'])
        apps_label.set_halign(Gtk.Align.START)
        self.main_box.append(apps_label)
        
        # Apps scrolled window
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        scrolled.set_vexpand(True)
        
        self.apps_list = Gtk.ListBox()
        self.apps_list.set_css_classes(['apps-list'])
        self.apps_list.set_selection_mode(Gtk.SelectionMode.NONE)
        scrolled.set_child(self.apps_list)
        
        self.main_box.append(scrolled)
    
    def create_footer(self):
        """Create footer with quick actions"""
        footer_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        footer_box.set_css_classes(['footer'])
        
        # Quick action buttons
        actions = [
            {'icon': 'preferences-system', 'tooltip': 'Settings', 'action': 'mros-settings'},
            {'icon': 'system-file-manager', 'tooltip': 'File Manager', 'action': 'thunar'},
            {'icon': 'applications-utilities', 'tooltip': 'Utilities', 'action': 'mros-utilities'},
            {'icon': 'system-users', 'tooltip': 'User Accounts', 'action': 'users-admin'},
        ]
        
        for action in actions:
            button = Gtk.Button()
            button.set_child(Gtk.Image.new_from_icon_name(action['icon']))
            button.set_css_classes(['footer-button'])
            button.set_tooltip_text(action['tooltip'])
            button.connect('clicked', lambda btn, cmd=action['action']: self.launch_app(cmd))
            footer_box.append(button)
        
        # Spacer
        spacer = Gtk.Box()
        spacer.set_hexpand(True)
        footer_box.append(spacer)
        
        # Upload button
        upload_button = Gtk.Button()
        upload_button.set_child(Gtk.Image.new_from_icon_name("cloud-upload"))
        upload_button.set_css_classes(['upload-button'])
        upload_button.set_tooltip_text("Upload to bashupload.com")
        upload_button.connect('clicked', self.on_upload_clicked)
        footer_box.append(upload_button)
        
        self.main_box.append(footer_box)
    
    def add_pinned_app(self, app):
        """Add a pinned application"""
        button = Gtk.Button()
        button.set_css_classes(['pinned-app'])
        
        app_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        
        # App icon
        icon = Gtk.Image.new_from_icon_name(app['icon'])
        icon.set_pixel_size(48)
        app_box.append(icon)
        
        # App name
        label = Gtk.Label(label=app['name'])
        label.set_css_classes(['app-name'])
        label.set_ellipsize(3)  # ELLIPSIZE_END
        label.set_max_width_chars(10)
        app_box.append(label)
        
        button.set_child(app_box)
        button.connect('clicked', lambda btn, cmd=app['exec']: self.launch_app(cmd))
        
        self.pinned_grid.append(button)
    
    def load_applications(self):
        """Load system applications"""
        applications = []
        
        # Look for .desktop files
        desktop_dirs = [
            '/usr/share/applications',
            '/usr/local/share/applications',
            os.path.expanduser('~/.local/share/applications')
        ]
        
        for desktop_dir in desktop_dirs:
            if os.path.exists(desktop_dir):
                for desktop_file in glob.glob(os.path.join(desktop_dir, '*.desktop')):
                    app_info = self.parse_desktop_file(desktop_file)
                    if app_info:
                        applications.append(app_info)
        
        return sorted(applications, key=lambda x: x['name'])
    
    def parse_desktop_file(self, filepath):
        """Parse a .desktop file"""
        try:
            with open(filepath, 'r') as f:
                content = f.read()
            
            app_info = {}
            for line in content.split('\\n'):
                if line.startswith('Name='):
                    app_info['name'] = line.split('=', 1)[1]
                elif line.startswith('Exec='):
                    app_info['exec'] = line.split('=', 1)[1]
                elif line.startswith('Icon='):
                    app_info['icon'] = line.split('=', 1)[1]
                elif line.startswith('Comment='):
                    app_info['comment'] = line.split('=', 1)[1]
                elif line.startswith('NoDisplay=true'):
                    return None  # Skip hidden apps
            
            if 'name' in app_info and 'exec' in app_info:
                return app_info
        except:
            pass
        
        return None
    
    def populate_apps(self):
        """Populate the applications list"""
        for app in self.applications:
            self.add_app_to_list(app)
    
    def add_app_to_list(self, app):
        """Add an application to the list"""
        row = Gtk.ListBoxRow()
        row.set_css_classes(['app-row'])
        
        box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        
        # App icon
        icon = Gtk.Image.new_from_icon_name(app.get('icon', 'application-x-executable'))
        icon.set_pixel_size(32)
        box.append(icon)
        
        # App info
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        info_box.set_hexpand(True)
        
        name_label = Gtk.Label(label=app['name'])
        name_label.set_css_classes(['app-list-name'])
        name_label.set_halign(Gtk.Align.START)
        info_box.append(name_label)
        
        if 'comment' in app:
            comment_label = Gtk.Label(label=app['comment'])
            comment_label.set_css_classes(['app-list-comment'])
            comment_label.set_halign(Gtk.Align.START)
            comment_label.set_ellipsize(3)  # ELLIPSIZE_END
            info_box.append(comment_label)
        
        box.append(info_box)
        
        row.set_child(box)
        row.connect('activate', lambda row, cmd=app['exec']: self.launch_app(cmd))
        
        self.apps_list.append(row)
    
    def on_search_changed(self, entry):
        """Handle search text changes"""
        query = entry.get_text().lower()
        
        # Filter applications list
        child = self.apps_list.get_first_child()
        while child:
            row = child
            child = child.get_next_sibling()
            
            # Get app name from the row
            box = row.get_child()
            info_box = box.get_last_child()
            name_label = info_box.get_first_child()
            app_name = name_label.get_text().lower()
            
            # Show/hide based on search
            if query in app_name:
                row.set_visible(True)
            else:
                row.set_visible(False)
    
    def on_power_clicked(self, button):
        """Handle power button click"""
        # Show power menu
        subprocess.Popen(['mros-power-menu'])
        self.close()
    
    def on_upload_clicked(self, button):
        """Handle upload button click"""
        subprocess.Popen(['mros-upload-manager'])
        self.close()
    
    def launch_app(self, command):
        """Launch an application"""
        try:
            subprocess.Popen(command.split())
            self.close()
        except Exception as e:
            print(f"Failed to launch {command}: {e}")
    
    def setup_key_handlers(self):
        """Setup keyboard handlers"""
        key_controller = Gtk.EventControllerKey()
        key_controller.connect('key-pressed', self.on_key_pressed)
        self.add_controller(key_controller)
    
    def on_key_pressed(self, controller, keyval, keycode, state):
        """Handle key press events"""
        if keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False
    
    def load_css(self):
        """Load CSS styling"""
        css_provider = Gtk.CssProvider()
        css_data = """
        .start-menu {
            background: rgba(32, 32, 32, 0.95);
            border-radius: 12px;
            padding: 16px;
            backdrop-filter: blur(20px);
            border: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .header {
            padding: 12px;
            margin-bottom: 16px;
        }
        
        .user-avatar {
            border-radius: 24px;
            margin-right: 12px;
        }
        
        .user-name {
            color: white;
            font-size: 18px;
            font-weight: bold;
        }
        
        .user-status {
            color: rgba(255, 255, 255, 0.7);
            font-size: 12px;
        }
        
        .power-button {
            background: rgba(255, 255, 255, 0.1);
            border: none;
            border-radius: 8px;
            padding: 8px;
            color: white;
        }
        
        .power-button:hover {
            background: rgba(255, 255, 255, 0.2);
        }
        
        .search-section {
            margin-bottom: 16px;
        }
        
        .search-entry {
            background: rgba(255, 255, 255, 0.1);
            border: 1px solid rgba(255, 255, 255, 0.2);
            border-radius: 8px;
            padding: 12px 16px;
            color: white;
            font-size: 14px;
        }
        
        .search-entry:focus {
            background: rgba(255, 255, 255, 0.15);
            border-color: #0078d4;
        }
        
        .search-button {
            background: #0078d4;
            border: none;
            border-radius: 8px;
            padding: 12px;
            color: white;
            margin-left: 8px;
        }
        
        .section-label {
            color: white;
            font-weight: bold;
            font-size: 16px;
            margin: 16px 0px 8px 0px;
        }
        
        .pinned-grid {
            margin-bottom: 16px;
        }
        
        .pinned-app {
            background: rgba(255, 255, 255, 0.05);
            border: none;
            border-radius: 12px;
            padding: 16px;
            margin: 4px;
            color: white;
            transition: all 0.2s ease;
        }
        
        .pinned-app:hover {
            background: rgba(255, 255, 255, 0.1);
            transform: translateY(-2px);
        }
        
        .app-name {
            color: white;
            font-size: 12px;
            text-align: center;
        }
        
        .apps-list {
            background: transparent;
        }
        
        .app-row {
            background: rgba(255, 255, 255, 0.05);
            border-radius: 8px;
            padding: 8px 12px;
            margin: 2px 0px;
            transition: all 0.2s ease;
        }
        
        .app-row:hover {
            background: rgba(255, 255, 255, 0.1);
        }
        
        .app-list-name {
            color: white;
            font-weight: bold;
        }
        
        .app-list-comment {
            color: rgba(255, 255, 255, 0.7);
            font-size: 12px;
        }
        
        .footer {
            margin-top: 16px;
            padding-top: 16px;
            border-top: 1px solid rgba(255, 255, 255, 0.1);
        }
        
        .footer-button {
            background: rgba(255, 255, 255, 0.1);
            border: none;
            border-radius: 8px;
            padding: 8px;
            color: white;
            margin-right: 8px;
        }
        
        .footer-button:hover {
            background: rgba(255, 255, 255, 0.2);
        }
        
        .upload-button {
            background: linear-gradient(135deg, #0078d4, #106ebe);
            border: none;
            border-radius: 8px;
            padding: 8px;
            color: white;
        }
        
        .upload-button:hover {
            background: linear-gradient(135deg, #106ebe, #005a9e);
        }
        """
        
        css_provider.load_from_data(css_data.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

class MrosStartMenuApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='com.mros.startmenu')
    
    def do_activate(self):
        window = MrosStartMenu(self)
        window.present()

if __name__ == '__main__':
    app = MrosStartMenuApp()
    app.run()

