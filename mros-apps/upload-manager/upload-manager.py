#!/usr/bin/env python3
"""
mros-linux Upload Manager
GUI application for managing file uploads to bashupload.com
"""

import gi
gi.require_version('Gtk', '4.0')
gi.require_version('Gdk', '4.0')

from gi.repository import Gtk, Gdk, GLib, Gio
import subprocess
import json
import os
import threading
import time
from pathlib import Path
from datetime import datetime
import sys
sys.path.append('/usr/share/mros/services/upload-service')
from upload_service import MrosUploadService

class MrosUploadManager(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app)
        
        # Window properties
        self.set_title("mros Upload Manager")
        self.set_default_size(800, 600)
        
        # Upload service
        self.upload_service = MrosUploadService()
        
        # Create main layout
        self.create_layout()
        
        # Load upload history
        self.load_history()
        
        # Load CSS
        self.load_css()
    
    def create_layout(self):
        """Create the main layout"""
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.set_child(main_box)
        
        # Create header
        self.create_header(main_box)
        
        # Create main content
        self.create_main_content(main_box)
        
        # Create footer
        self.create_footer(main_box)
    
    def create_header(self, parent):
        """Create header with upload controls"""
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        header_box.set_css_classes(['header'])
        
        # Title
        title_label = Gtk.Label(label="Upload Manager")
        title_label.set_css_classes(['header-title'])
        title_label.set_hexpand(True)
        title_label.set_halign(Gtk.Align.START)
        header_box.append(title_label)
        
        # Upload buttons
        upload_file_btn = Gtk.Button(label="Upload Files")
        upload_file_btn.set_css_classes(['upload-button'])
        upload_file_btn.connect('clicked', self.on_upload_files_clicked)
        header_box.append(upload_file_btn)
        
        upload_folder_btn = Gtk.Button(label="Upload Folder")
        upload_folder_btn.set_css_classes(['upload-button'])
        upload_folder_btn.connect('clicked', self.on_upload_folder_clicked)
        header_box.append(upload_folder_btn)
        
        # Settings button
        settings_btn = Gtk.Button()
        settings_btn.set_child(Gtk.Image.new_from_icon_name("preferences-system"))
        settings_btn.set_css_classes(['icon-button'])
        settings_btn.connect('clicked', self.on_settings_clicked)
        header_box.append(settings_btn)
        
        parent.append(header_box)
    
    def create_main_content(self, parent):
        """Create main content area"""
        # Create notebook for tabs
        self.notebook = Gtk.Notebook()
        self.notebook.set_css_classes(['main-notebook'])
        
        # Upload history tab
        self.create_history_tab()
        
        # Active uploads tab
        self.create_active_tab()
        
        # Settings tab
        self.create_settings_tab()
        
        parent.append(self.notebook)
    
    def create_history_tab(self):
        """Create upload history tab"""
        # Scrolled window for history
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        
        # History list
        self.history_list = Gtk.ListBox()
        self.history_list.set_css_classes(['history-list'])
        self.history_list.set_selection_mode(Gtk.SelectionMode.NONE)
        
        scrolled.set_child(self.history_list)
        
        # Add tab
        tab_label = Gtk.Label(label="History")
        self.notebook.append_page(scrolled, tab_label)
    
    def create_active_tab(self):
        """Create active uploads tab"""
        active_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        active_box.set_css_classes(['active-uploads'])
        
        # Active uploads label
        active_label = Gtk.Label(label="Active Uploads")
        active_label.set_css_classes(['section-title'])
        active_label.set_halign(Gtk.Align.START)
        active_box.append(active_label)
        
        # Active uploads list
        self.active_list = Gtk.ListBox()
        self.active_list.set_css_classes(['active-list'])
        active_box.append(self.active_list)
        
        # Add tab
        tab_label = Gtk.Label(label="Active")
        self.notebook.append_page(active_box, tab_label)
    
    def create_settings_tab(self):
        """Create settings tab"""
        settings_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=16)
        settings_box.set_css_classes(['settings-tab'])
        settings_box.set_margin_top(20)
        settings_box.set_margin_bottom(20)
        settings_box.set_margin_start(20)
        settings_box.set_margin_end(20)
        
        # Upload settings
        upload_group = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        
        upload_title = Gtk.Label(label="Upload Settings")
        upload_title.set_css_classes(['settings-group-title'])
        upload_title.set_halign(Gtk.Align.START)
        upload_group.append(upload_title)
        
        # Auto-copy URL setting
        auto_copy_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        auto_copy_label = Gtk.Label(label="Automatically copy URLs to clipboard")
        auto_copy_label.set_hexpand(True)
        auto_copy_label.set_halign(Gtk.Align.START)
        auto_copy_box.append(auto_copy_label)
        
        self.auto_copy_switch = Gtk.Switch()
        self.auto_copy_switch.set_active(True)
        auto_copy_box.append(self.auto_copy_switch)
        
        upload_group.append(auto_copy_box)
        
        # Show notifications setting
        notifications_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        notifications_label = Gtk.Label(label="Show upload notifications")
        notifications_label.set_hexpand(True)
        notifications_label.set_halign(Gtk.Align.START)
        notifications_box.append(notifications_label)
        
        self.notifications_switch = Gtk.Switch()
        self.notifications_switch.set_active(True)
        notifications_box.append(self.notifications_switch)
        
        upload_group.append(notifications_box)
        
        settings_box.append(upload_group)
        
        # History settings
        history_group = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        
        history_title = Gtk.Label(label="History Settings")
        history_title.set_css_classes(['settings-group-title'])
        history_title.set_halign(Gtk.Align.START)
        history_group.append(history_title)
        
        # Clear history button
        clear_history_btn = Gtk.Button(label="Clear Upload History")
        clear_history_btn.set_css_classes(['destructive-button'])
        clear_history_btn.connect('clicked', self.on_clear_history_clicked)
        history_group.append(clear_history_btn)
        
        settings_box.append(history_group)
        
        # Add tab
        tab_label = Gtk.Label(label="Settings")
        self.notebook.append_page(settings_box, tab_label)
    
    def create_footer(self, parent):
        """Create footer with status"""
        self.status_bar = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL)
        self.status_bar.set_css_classes(['status-bar'])
        
        self.status_label = Gtk.Label(label="Ready")
        self.status_label.set_hexpand(True)
        self.status_label.set_halign(Gtk.Align.START)
        self.status_bar.append(self.status_label)
        
        # Upload count
        self.upload_count_label = Gtk.Label()
        self.status_bar.append(self.upload_count_label)
        
        parent.append(self.status_bar)
    
    def load_history(self):
        """Load upload history"""
        history = self.upload_service.get_upload_history()
        
        # Clear existing items
        child = self.history_list.get_first_child()
        while child:
            next_child = child.get_next_sibling()
            self.history_list.remove(child)
            child = next_child
        
        # Add history items
        for item in history:
            self.add_history_item(item)
        
        # Update count
        self.upload_count_label.set_text(f"{len(history)} uploads")
    
    def add_history_item(self, item):
        """Add item to history list"""
        row = Gtk.ListBoxRow()
        row.set_css_classes(['history-item'])
        
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=12)
        main_box.set_margin_top(8)
        main_box.set_margin_bottom(8)
        main_box.set_margin_start(12)
        main_box.set_margin_end(12)
        
        # Status icon
        status_icon = Gtk.Image()
        if item['status'] == 'completed':
            status_icon.set_from_icon_name("dialog-ok-apply")
            status_icon.set_css_classes(['status-success'])
        elif item['status'] == 'failed':
            status_icon.set_from_icon_name("dialog-error")
            status_icon.set_css_classes(['status-error'])
        else:
            status_icon.set_from_icon_name("dialog-information")
            status_icon.set_css_classes(['status-info'])
        
        status_icon.set_pixel_size(24)
        main_box.append(status_icon)
        
        # File info
        info_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        info_box.set_hexpand(True)
        
        # Filename
        filename_label = Gtk.Label(label=item['filename'])
        filename_label.set_css_classes(['filename'])
        filename_label.set_halign(Gtk.Align.START)
        filename_label.set_ellipsize(3)  # ELLIPSIZE_END
        info_box.append(filename_label)
        
        # Details
        details = []
        if 'size' in item:
            details.append(self.format_file_size(item['size']))
        
        timestamp = datetime.fromtimestamp(item['timestamp'])
        details.append(timestamp.strftime("%Y-%m-%d %H:%M"))
        
        if item['status'] == 'failed' and 'error' in item:
            details.append(f"Error: {item['error']}")
        
        details_label = Gtk.Label(label=" • ".join(details))
        details_label.set_css_classes(['details'])
        details_label.set_halign(Gtk.Align.START)
        details_label.set_ellipsize(3)  # ELLIPSIZE_END
        info_box.append(details_label)
        
        main_box.append(info_box)
        
        # Actions
        if item['status'] == 'completed' and 'download_url' in item:
            actions_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=4)
            
            # Copy URL button
            copy_btn = Gtk.Button()
            copy_btn.set_child(Gtk.Image.new_from_icon_name("edit-copy"))
            copy_btn.set_css_classes(['action-button'])
            copy_btn.set_tooltip_text("Copy URL")
            copy_btn.connect('clicked', lambda btn, url=item['download_url']: self.copy_url(url))
            actions_box.append(copy_btn)
            
            # Open URL button
            open_btn = Gtk.Button()
            open_btn.set_child(Gtk.Image.new_from_icon_name("web-browser"))
            open_btn.set_css_classes(['action-button'])
            open_btn.set_tooltip_text("Open in browser")
            open_btn.connect('clicked', lambda btn, url=item['download_url']: self.open_url(url))
            actions_box.append(open_btn)
            
            main_box.append(actions_box)
        
        row.set_child(main_box)
        self.history_list.append(row)
    
    def format_file_size(self, size_bytes):
        """Format file size in human readable format"""
        if size_bytes == 0:
            return "0 B"
        
        size_names = ["B", "KB", "MB", "GB", "TB"]
        i = 0
        while size_bytes >= 1024 and i < len(size_names) - 1:
            size_bytes /= 1024.0
            i += 1
        
        return f"{size_bytes:.1f} {size_names[i]}"
    
    def copy_url(self, url):
        """Copy URL to clipboard"""
        if self.upload_service.copy_to_clipboard(url):
            self.status_label.set_text("URL copied to clipboard")
            GLib.timeout_add_seconds(3, lambda: self.status_label.set_text("Ready"))
        else:
            self.status_label.set_text("Failed to copy URL")
    
    def open_url(self, url):
        """Open URL in browser"""
        try:
            subprocess.Popen(['xdg-open', url])
        except Exception as e:
            self.status_label.set_text(f"Failed to open URL: {e}")
    
    def on_upload_files_clicked(self, button):
        """Handle upload files button click"""
        dialog = Gtk.FileChooserDialog(
            title="Select files to upload",
            transient_for=self,
            action=Gtk.FileChooserAction.OPEN
        )
        dialog.add_buttons(
            "_Cancel", Gtk.ResponseType.CANCEL,
            "_Upload", Gtk.ResponseType.ACCEPT
        )
        dialog.set_select_multiple(True)
        
        dialog.connect('response', self.on_file_dialog_response)
        dialog.present()
    
    def on_upload_folder_clicked(self, button):
        """Handle upload folder button click"""
        dialog = Gtk.FileChooserDialog(
            title="Select folder to upload",
            transient_for=self,
            action=Gtk.FileChooserAction.SELECT_FOLDER
        )
        dialog.add_buttons(
            "_Cancel", Gtk.ResponseType.CANCEL,
            "_Upload", Gtk.ResponseType.ACCEPT
        )
        
        dialog.connect('response', self.on_folder_dialog_response)
        dialog.present()
    
    def on_file_dialog_response(self, dialog, response):
        """Handle file dialog response"""
        if response == Gtk.ResponseType.ACCEPT:
            files = dialog.get_files()
            file_paths = [f.get_path() for f in files]
            
            # Start upload in background thread
            threading.Thread(
                target=self.upload_files_background,
                args=(file_paths,),
                daemon=True
            ).start()
        
        dialog.destroy()
    
    def on_folder_dialog_response(self, dialog, response):
        """Handle folder dialog response"""
        if response == Gtk.ResponseType.ACCEPT:
            folder = dialog.get_file()
            folder_path = folder.get_path()
            
            # Start upload in background thread
            threading.Thread(
                target=self.upload_folder_background,
                args=(folder_path,),
                daemon=True
            ).start()
        
        dialog.destroy()
    
    def upload_files_background(self, file_paths):
        """Upload files in background thread"""
        GLib.idle_add(lambda: self.status_label.set_text(f"Uploading {len(file_paths)} files..."))
        
        results = self.upload_service.upload_multiple_files(file_paths, show_progress=False)
        
        # Update UI in main thread
        GLib.idle_add(self.on_upload_complete, results)
    
    def upload_folder_background(self, folder_path):
        """Upload folder in background thread"""
        GLib.idle_add(lambda: self.status_label.set_text(f"Uploading folder: {Path(folder_path).name}"))
        
        results = self.upload_service.upload_folder(folder_path, show_progress=False)
        
        # Update UI in main thread
        GLib.idle_add(self.on_upload_complete, results)
    
    def on_upload_complete(self, results):
        """Handle upload completion"""
        successful = sum(1 for r in results if r['success'])
        total = len(results)
        
        if successful == total:
            self.status_label.set_text(f"Upload complete: {total} files uploaded successfully")
        else:
            failed = total - successful
            self.status_label.set_text(f"Upload complete: {successful} successful, {failed} failed")
        
        # Reload history
        self.load_history()
        
        # Switch to history tab
        self.notebook.set_current_page(0)
    
    def on_settings_clicked(self, button):
        """Handle settings button click"""
        self.notebook.set_current_page(2)  # Switch to settings tab
    
    def on_clear_history_clicked(self, button):
        """Handle clear history button click"""
        dialog = Gtk.MessageDialog(
            transient_for=self,
            modal=True,
            message_type=Gtk.MessageType.QUESTION,
            buttons=Gtk.ButtonsType.YES_NO,
            text="Clear Upload History",
            secondary_text="Are you sure you want to clear all upload history? This action cannot be undone."
        )
        
        dialog.connect('response', self.on_clear_history_response)
        dialog.present()
    
    def on_clear_history_response(self, dialog, response):
        """Handle clear history dialog response"""
        if response == Gtk.ResponseType.YES:
            self.upload_service.clear_history()
            self.load_history()
            self.status_label.set_text("Upload history cleared")
        
        dialog.destroy()
    
    def load_css(self):
        """Load CSS styling"""
        css_provider = Gtk.CssProvider()
        css_data = """
        .header {
            background: linear-gradient(135deg, #0078d4, #106ebe);
            padding: 16px;
            color: white;
        }
        
        .header-title {
            font-size: 20px;
            font-weight: bold;
            color: white;
        }
        
        .upload-button {
            background: rgba(255, 255, 255, 0.2);
            border: 1px solid rgba(255, 255, 255, 0.3);
            border-radius: 8px;
            padding: 8px 16px;
            color: white;
            margin-left: 8px;
            transition: all 0.2s ease;
        }
        
        .upload-button:hover {
            background: rgba(255, 255, 255, 0.3);
        }
        
        .icon-button {
            background: rgba(255, 255, 255, 0.2);
            border: 1px solid rgba(255, 255, 255, 0.3);
            border-radius: 8px;
            padding: 8px;
            color: white;
            margin-left: 8px;
        }
        
        .icon-button:hover {
            background: rgba(255, 255, 255, 0.3);
        }
        
        .main-notebook {
            background: white;
        }
        
        .history-list {
            background: transparent;
        }
        
        .history-item {
            border-bottom: 1px solid rgba(0, 0, 0, 0.1);
            transition: all 0.2s ease;
        }
        
        .history-item:hover {
            background: rgba(0, 120, 212, 0.05);
        }
        
        .filename {
            font-weight: bold;
            color: #333;
        }
        
        .details {
            font-size: 12px;
            color: #666;
        }
        
        .status-success {
            color: #28a745;
        }
        
        .status-error {
            color: #dc3545;
        }
        
        .status-info {
            color: #17a2b8;
        }
        
        .action-button {
            background: transparent;
            border: 1px solid rgba(0, 0, 0, 0.2);
            border-radius: 6px;
            padding: 6px;
            transition: all 0.2s ease;
        }
        
        .action-button:hover {
            background: rgba(0, 120, 212, 0.1);
            border-color: #0078d4;
        }
        
        .settings-tab {
            background: white;
        }
        
        .settings-group-title {
            font-size: 16px;
            font-weight: bold;
            color: #333;
            margin-bottom: 8px;
        }
        
        .destructive-button {
            background: #dc3545;
            border: none;
            border-radius: 8px;
            padding: 8px 16px;
            color: white;
        }
        
        .destructive-button:hover {
            background: #c82333;
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

class MrosUploadManagerApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id='com.mros.uploadmanager')
    
    def do_activate(self):
        window = MrosUploadManager(self)
        window.present()

if __name__ == '__main__':
    app = MrosUploadManagerApp()
    app.run()

