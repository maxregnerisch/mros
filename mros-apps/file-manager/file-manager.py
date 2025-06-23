#!/usr/bin/env python3
"""
mros-linux File Manager
Windows 12-inspired file manager with modern ribbon interface
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')

from gi.repository import Gtk, Gdk, GLib, Gio, GdkPixbuf
import os
import subprocess
import shutil
import mimetypes
from pathlib import Path
import json

class MrosFileManager(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        
        # Window properties
        self.set_title("mros File Manager")
        self.set_default_size(1200, 800)
        
        # Current directory
        self.current_path = Path.home()
        self.history = [self.current_path]
        self.history_index = 0
        
        # Selection
        self.selected_files = []
        
        # Create main layout
        self.create_layout()
        
        # Load initial directory
        self.load_directory(self.current_path)
        
        # Load CSS
        self.load_css()
    
    def create_layout(self):
        """Create the main layout"""
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_child(main_box)
        
        # Create ribbon toolbar
        self.create_ribbon(main_box)
        
        # Create navigation bar
        self.create_navigation_bar(main_box)
        
        # Create main content area
        content_paned = Gtk.Paned(orientation=Gtk.Orientation.HORIZONTAL)
        content_paned.set_vexpand(True)
        main_box.append(content_paned)
        
        # Create sidebar
        self.create_sidebar(content_paned)
        
        # Create file view
        self.create_file_view(content_paned)
        
        # Create status bar
        self.create_status_bar(main_box)
    
    def create_ribbon(self, parent):
        """Create ribbon toolbar"""
        ribbon_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        ribbon_box.set_css_classes(['ribbon'])
        
        # Home tab
        home_section = self.create_ribbon_section("Home", [
            {'icon': 'edit-copy', 'label': 'Copy', 'action': self.copy_files},
            {'icon': 'edit-cut', 'label': 'Cut', 'action': self.cut_files},
            {'icon': 'edit-paste', 'label': 'Paste', 'action': self.paste_files},
            {'icon': 'edit-delete', 'label': 'Delete', 'action': self.delete_files},
        ])
        ribbon_box.append(home_section)
        
        # View tab
        view_section = self.create_ribbon_section("View", [
            {'icon': 'view-list', 'label': 'List', 'action': lambda: self.set_view_mode('list')},
            {'icon': 'view-grid', 'label': 'Grid', 'action': lambda: self.set_view_mode('grid')},
            {'icon': 'zoom-in', 'label': 'Zoom In', 'action': self.zoom_in},
            {'icon': 'zoom-out', 'label': 'Zoom Out', 'action': self.zoom_out},
        ])
        ribbon_box.append(view_section)
        
        # Upload tab
        upload_section = self.create_ribbon_section("Upload", [
            {'icon': 'cloud-upload', 'label': 'Upload File', 'action': self.upload_selected_files},
            {'icon': 'folder-upload', 'label': 'Upload Folder', 'action': self.upload_folder},
            {'icon': 'link', 'label': 'Get Link', 'action': self.get_upload_link},
        ])
        ribbon_box.append(upload_section)
        
        parent.append(ribbon_box)
    
    def create_ribbon_section(self, title, buttons):
        """Create a ribbon section"""
        section_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        section_box.set_css_classes(['ribbon-section'])
        
        # Section title
        title_label = Gtk.Label(label=title)
        title_label.set_css_classes(['ribbon-title'])
        section_box.append(title_label)
        
        # Buttons
        buttons_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        for button_info in buttons:
            button = Gtk.Button()
            button.set_css_classes(['ribbon-button'])
            
            button_content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
            
            icon = Gtk.Image.new_from_icon_name(button_info['icon'])
            icon.set_pixel_size(24)
            button_content.append(icon)
            
            label = Gtk.Label(label=button_info['label'])
            label.set_css_classes(['ribbon-button-label'])
            button_content.append(label)
            
            button.set_child(button_content)
            button.connect('clicked', lambda btn, action=button_info['action']: action())
            
            buttons_box.append(button)
        
        section_box.append(buttons_box)
        return section_box
    
    def create_navigation_bar(self, parent):
        """Create navigation bar"""
        nav_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        nav_box.set_css_classes(['navigation-bar'])
        
        # Back/Forward buttons
        self.back_button = Gtk.Button()
        self.back_button.set_child(Gtk.Image.new_from_icon_name("go-previous"))
        self.back_button.set_css_classes(['nav-button'])
        self.back_button.connect('clicked', self.go_back)
        nav_box.append(self.back_button)
        
        self.forward_button = Gtk.Button()
        self.forward_button.set_child(Gtk.Image.new_from_icon_name("go-next"))
        self.forward_button.set_css_classes(['nav-button'])
        self.forward_button.connect('clicked', self.go_forward)
        nav_box.append(self.forward_button)
        
        # Up button
        up_button = Gtk.Button()
        up_button.set_child(Gtk.Image.new_from_icon_name("go-up"))
        up_button.set_css_classes(['nav-button'])
        up_button.connect('clicked', self.go_up)
        nav_box.append(up_button)
        
        # Address bar
        self.address_entry = Gtk.Entry()
        self.address_entry.set_css_classes(['address-bar'])
        self.address_entry.set_hexpand(True)
        self.address_entry.connect('activate', self.navigate_to_address)
        nav_box.append(self.address_entry)
        
        # Search box
        self.search_entry = Gtk.Entry()
        self.search_entry.set_placeholder_text("Search files...")
        self.search_entry.set_css_classes(['search-box'])
        self.search_entry.connect('changed', self.on_search_changed)
        nav_box.append(self.search_entry)
        
        parent.append(nav_box)
    
    def create_sidebar(self, parent):
        """Create sidebar with quick access"""
        sidebar_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        sidebar_box.set_css_classes(['sidebar'])
        sidebar_box.set_size_request(200, -1)
        
        # Quick access
        quick_label = Gtk.Label(label="Quick Access")
        quick_label.set_css_classes(['sidebar-title'])
        quick_label.set_halign(Gtk.Align.START)
        sidebar_box.append(quick_label)
        
        quick_places = [
            {'name': 'Desktop', 'path': Path.home() / 'Desktop', 'icon': 'user-desktop'},
            {'name': 'Documents', 'path': Path.home() / 'Documents', 'icon': 'folder-documents'},
            {'name': 'Downloads', 'path': Path.home() / 'Downloads', 'icon': 'folder-download'},
            {'name': 'Pictures', 'path': Path.home() / 'Pictures', 'icon': 'folder-pictures'},
            {'name': 'Music', 'path': Path.home() / 'Music', 'icon': 'folder-music'},
            {'name': 'Videos', 'path': Path.home() / 'Videos', 'icon': 'folder-videos'},
        ]
        
        for place in quick_places:
            button = Gtk.Button()
            button.set_css_classes(['sidebar-button'])
            
            button_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
            
            icon = Gtk.Image.new_from_icon_name(place['icon'])
            icon.set_pixel_size(16)
            button_box.append(icon)
            
            label = Gtk.Label(label=place['name'])
            label.set_halign(Gtk.Align.START)
            button_box.append(label)
            
            button.set_child(button_box)
            button.connect('clicked', lambda btn, path=place['path']: self.navigate_to(path))
            
            sidebar_box.append(button)
        
        parent.set_start_child(sidebar_box)
    
    def create_file_view(self, parent):
        """Create file view area"""
        self.view_stack = Gtk.Stack()
        self.view_stack.set_css_classes(['file-view'])
        
        # List view
        self.create_list_view()
        
        # Grid view
        self.create_grid_view()
        
        # Set default view
        self.view_stack.set_visible_child_name('list')
        self.current_view_mode = 'list'
        
        parent.set_end_child(self.view_stack)
    
    def create_list_view(self):
        """Create list view"""
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        
        self.list_view = Gtk.ColumnView()
        self.list_view.set_css_classes(['file-list'])
        
        # Create columns
        self.create_list_columns()
        
        scrolled.set_child(self.list_view)
        self.view_stack.add_named(scrolled, 'list')
    
    def create_grid_view(self):
        """Create grid view"""
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        
        self.grid_view = Gtk.FlowBox()
        self.grid_view.set_css_classes(['file-grid'])
        self.grid_view.set_max_children_per_line(6)
        self.grid_view.set_selection_mode(Gtk.SelectionMode.MULTIPLE)
        
        scrolled.set_child(self.grid_view)
        self.view_stack.add_named(scrolled, 'grid')
    
    def create_list_columns(self):
        """Create columns for list view"""
        # Name column
        name_factory = Gtk.SignalListItemFactory()
        name_factory.connect('setup', self.setup_name_column)
        name_factory.connect('bind', self.bind_name_column)
        
        name_column = Gtk.ColumnViewColumn(title="Name", factory=name_factory)
        name_column.set_expand(True)
        self.list_view.append_column(name_column)
        
        # Size column
        size_factory = Gtk.SignalListItemFactory()
        size_factory.connect('setup', self.setup_size_column)
        size_factory.connect('bind', self.bind_size_column)
        
        size_column = Gtk.ColumnViewColumn(title="Size", factory=size_factory)
        self.list_view.append_column(size_column)
        
        # Modified column
        modified_factory = Gtk.SignalListItemFactory()
        modified_factory.connect('setup', self.setup_modified_column)
        modified_factory.connect('bind', self.bind_modified_column)
        
        modified_column = Gtk.ColumnViewColumn(title="Modified", factory=modified_factory)
        self.list_view.append_column(modified_column)
    
    def create_status_bar(self, parent):
        """Create status bar"""
        self.status_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.status_bar.set_css_classes(['status-bar'])
        
        self.status_label = Gtk.Label(label="Ready")
        self.status_label.set_hexpand(True)
        self.status_label.set_halign(Gtk.Align.START)
        self.status_bar.append(self.status_label)
        
        self.items_label = Gtk.Label()
        self.status_bar.append(self.items_label)
        
        parent.append(self.status_bar)
    
    def load_directory(self, path):
        """Load directory contents"""
        try:
            self.current_path = Path(path)
            self.address_entry.set_text(str(self.current_path))
            
            # Clear current views
            self.clear_views()
            
            # Get directory contents
            items = []
            if self.current_path.exists() and self.current_path.is_dir():
                for item in self.current_path.iterdir():
                    try:
                        stat = item.stat()
                        items.append({
                            'name': item.name,
                            'path': item,
                            'is_dir': item.is_dir(),
                            'size': stat.st_size if not item.is_dir() else 0,
                            'modified': stat.st_mtime,
                            'icon': self.get_file_icon(item)
                        })
                    except:
                        continue
            
            # Sort items (directories first)
            items.sort(key=lambda x: (not x['is_dir'], x['name'].lower()))
            
            # Populate views
            self.populate_views(items)
            
            # Update status
            self.update_status(len(items))
            
            # Update navigation buttons
            self.update_navigation_buttons()
            
        except Exception as e:
            self.show_error(f"Failed to load directory: {e}")
    
    def get_file_icon(self, path):
        """Get appropriate icon for file"""
        if path.is_dir():
            return "folder"
        
        mime_type, _ = mimetypes.guess_type(str(path))
        if mime_type:
            if mime_type.startswith('image/'):
                return "image-x-generic"
            elif mime_type.startswith('video/'):
                return "video-x-generic"
            elif mime_type.startswith('audio/'):
                return "audio-x-generic"
            elif mime_type.startswith('text/'):
                return "text-x-generic"
            elif 'pdf' in mime_type:
                return "application-pdf"
        
        return "text-x-generic"
    
    def clear_views(self):
        """Clear all views"""
        # Clear grid view
        child = self.grid_view.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self.grid_view.remove(child)
            child = next_child
    
    def populate_views(self, items):
        """Populate views with items"""
        # Populate grid view
        for item in items:
            self.add_grid_item(item)
    
    def add_grid_item(self, item):
        """Add item to grid view"""
        button = Gtk.Button()
        button.set_css_classes(['file-item'])
        
        item_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        
        # Icon
        icon = Gtk.Image.new_from_icon_name(item['icon'])
        icon.set_pixel_size(48)
        item_box.append(icon)
        
        # Name
        label = Gtk.Label(label=item['name'])
        label.set_css_classes(['file-name'])
        label.set_ellipsize(3)  # ELLIPSIZE_END
        label.set_max_width_chars(12)
        item_box.append(label)
        
        button.set_child(item_box)
        button.connect('clicked', lambda btn, path=item['path']: self.on_item_clicked(path))
        
        self.grid_view.append(button)
    
    def on_item_clicked(self, path):
        """Handle item click"""
        if path.is_dir():
            self.navigate_to(path)
        else:
            self.open_file(path)
    
    def navigate_to(self, path):
        """Navigate to path"""
        # Add to history
        if self.history_index < len(self.history) - 1:
            self.history = self.history[:self.history_index + 1]
        
        self.history.append(Path(path))
        self.history_index = len(self.history) - 1
        
        self.load_directory(path)
    
    def open_file(self, path):
        """Open file with default application"""
        try:
            subprocess.Popen(['xdg-open', str(path)])
        except Exception as e:
            self.show_error(f"Failed to open file: {e}")
    
    def upload_selected_files(self):
        """Upload selected files to bashupload.com"""
        if not self.selected_files:
            self.show_info("Please select files to upload")
            return
        
        # Launch upload service
        subprocess.Popen(['mros-upload-service'] + [str(f) for f in self.selected_files])
    
    def show_error(self, message):
        """Show error dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.ERROR,
            buttons=Gtk.ButtonsType.OK,
            text=message
        )
        dialog.connect('response', lambda d, r: d.destroy())
        dialog.present()
    
    def show_info(self, message):
        """Show info dialog"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.OK,
            text=message
        )
        dialog.connect('response', lambda d, r: d.destroy())
        dialog.present()
    
    # Placeholder methods for ribbon actions
    def copy_files(self): pass
    def cut_files(self): pass
    def paste_files(self): pass
    def delete_files(self): pass
    def set_view_mode(self, mode): 
        self.view_stack.set_visible_child_name(mode)
        self.current_view_mode = mode
    def zoom_in(self): pass
    def zoom_out(self): pass
    def upload_folder(self): pass
    def get_upload_link(self): pass
    def go_back(self): pass
    def go_forward(self): pass
    def go_up(self): 
        if self.current_path.parent != self.current_path:
            self.navigate_to(self.current_path.parent)
    def navigate_to_address(self): pass
    def on_search_changed(self, entry): pass
    def setup_name_column(self, factory, item): pass
    def bind_name_column(self, factory, item): pass
    def setup_size_column(self, factory, item): pass
    def bind_size_column(self, factory, item): pass
    def setup_modified_column(self, factory, item): pass
    def bind_modified_column(self, factory, item): pass
    def update_status(self, count):
        self.items_label.set_text(f"{count} items")
    def update_navigation_buttons(self): pass
    
    def load_css(self):
        """Load CSS styling"""
        css_provider = Gtk.CssProvider()
        css_data = """
        .ribbon {
            background: rgba(248, 249, 250, 0.95);
            border-bottom: 1px solid rgba(0, 0, 0, 0.1);
            padding: 8px;
        }
        
        .ribbon-section {
            margin: 0px 16px;
            padding: 8px;
            border-right: 1px solid rgba(0, 0, 0, 0.1);
        }
        
        .ribbon-title {
            font-size: 12px;
            font-weight: bold;
            color: #666;
            margin-bottom: 8px;
        }
        
        .ribbon-button {
            background: transparent;
            border: 1px solid transparent;
            border-radius: 6px;
            padding: 8px;
            margin: 2px;
            transition: all 0.2s ease;
        }
        
        .ribbon-button:hover {
            background: rgba(0, 120, 212, 0.1);
            border-color: rgba(0, 120, 212, 0.3);
        }
        
        .ribbon-button-label {
            font-size: 11px;
            color: #333;
        }
        
        .navigation-bar {
            background: rgba(255, 255, 255, 0.9);
            border-bottom: 1px solid rgba(0, 0, 0, 0.1);
            padding: 8px;
        }
        
        .nav-button {
            background: transparent;
            border: 1px solid transparent;
            border-radius: 6px;
            padding: 8px;
            margin-right: 4px;
        }
        
        .nav-button:hover {
            background: rgba(0, 0, 0, 0.05);
            border-color: rgba(0, 0, 0, 0.1);
        }
        
        .address-bar {
            background: white;
            border: 1px solid rgba(0, 0, 0, 0.2);
            border-radius: 6px;
            padding: 8px 12px;
            margin: 0px 8px;
        }
        
        .search-box {
            background: white;
            border: 1px solid rgba(0, 0, 0, 0.2);
            border-radius: 6px;
            padding: 8px 12px;
            min-width: 200px;
        }
        
        .sidebar {
            background: rgba(248, 249, 250, 0.95);
            border-right: 1px solid rgba(0, 0, 0, 0.1);
            padding: 16px 8px;
        }
        
        .sidebar-title {
            font-weight: bold;
            color: #333;
            margin: 16px 8px 8px 8px;
        }
        
        .sidebar-button {
            background: transparent;
            border: none;
            border-radius: 6px;
            padding: 8px;
            margin: 2px 0px;
            width: 100%;
            transition: all 0.2s ease;
        }
        
        .sidebar-button:hover {
            background: rgba(0, 120, 212, 0.1);
        }
        
        .file-view {
            background: white;
        }
        
        .file-grid {
            padding: 16px;
        }
        
        .file-item {
            background: transparent;
            border: 1px solid transparent;
            border-radius: 8px;
            padding: 12px;
            margin: 4px;
            transition: all 0.2s ease;
        }
        
        .file-item:hover {
            background: rgba(0, 120, 212, 0.05);
            border-color: rgba(0, 120, 212, 0.2);
        }
        
        .file-name {
            font-size: 12px;
            color: #333;
            text-align: center;
        }
        
        .status-bar {
            background: rgba(248, 249, 250, 0.95);
            border-top: 1px solid rgba(0, 0, 0, 0.1);
            padding: 8px 16px;
        }
        """
        
        css_provider.load_from_data(css_data.encode())
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION
        )

class MrosFileManagerApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='com.mros.filemanager')
    
    def do_activate(self):
        window = MrosFileManager(self)
        window.present()

if __name__ == '__main__':
    app = MrosFileManagerApp()
    app.run()

