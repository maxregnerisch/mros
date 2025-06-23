#!/usr/bin/env python3
"""
mros-linux Upload Service
Service for uploading files to bashupload.com with progress tracking
"""

import sys
import os
import requests
import json
import subprocess
import threading
import time
from pathlib import Path
import hashlib
import mimetypes

class MrosUploadService:
    def __init__(self):
        self.upload_url = "https://bashupload.com"
        self.config_dir = Path.home() / '.config' / 'mros-upload'
        self.config_dir.mkdir(parents=True, exist_ok=True)
        self.history_file = self.config_dir / 'upload_history.json'
        self.load_history()
    
    def load_history(self):
        """Load upload history"""
        try:
            if self.history_file.exists():
                with open(self.history_file, 'r') as f:
                    self.history = json.load(f)
            else:
                self.history = []
        except:
            self.history = []
    
    def save_history(self):
        """Save upload history"""
        try:
            with open(self.history_file, 'w') as f:
                json.dump(self.history, f, indent=2)
        except Exception as e:
            print(f"Failed to save history: {e}")
    
    def upload_file(self, file_path, show_progress=True):
        """Upload a single file to bashupload.com"""
        try:
            file_path = Path(file_path)
            if not file_path.exists():
                raise FileNotFoundError(f"File not found: {file_path}")
            
            if not file_path.is_file():
                raise ValueError(f"Not a file: {file_path}")
            
            # Show notification
            if show_progress:
                self.show_notification(f"Uploading {file_path.name}...", "upload-start")
            
            # Prepare file for upload
            file_size = file_path.stat().st_size
            mime_type, _ = mimetypes.guess_type(str(file_path))
            
            # Create upload record
            upload_record = {
                'filename': file_path.name,
                'filepath': str(file_path),
                'size': file_size,
                'mime_type': mime_type,
                'timestamp': time.time(),
                'status': 'uploading'
            }
            
            # Upload file
            with open(file_path, 'rb') as f:
                files = {'file': (file_path.name, f, mime_type)}
                
                # Make request with progress tracking
                response = requests.post(
                    self.upload_url,
                    files=files,
                    timeout=300,  # 5 minutes timeout
                    stream=True
                )
            
            if response.status_code == 200:
                # Parse response to get download URL
                response_text = response.text.strip()
                
                # bashupload.com typically returns the URL directly
                if response_text.startswith('http'):
                    download_url = response_text
                else:
                    # Try to extract URL from response
                    lines = response_text.split('\\n')
                    download_url = None
                    for line in lines:
                        if line.startswith('http'):
                            download_url = line.strip()
                            break
                    
                    if not download_url:
                        download_url = f"{self.upload_url}/{file_path.name}"
                
                # Update record
                upload_record.update({
                    'status': 'completed',
                    'download_url': download_url,
                    'upload_id': hashlib.md5(download_url.encode()).hexdigest()[:8]
                })
                
                # Add to history
                self.history.insert(0, upload_record)
                if len(self.history) > 100:  # Keep only last 100 uploads
                    self.history = self.history[:100]
                self.save_history()
                
                # Copy URL to clipboard
                self.copy_to_clipboard(download_url)
                
                # Show success notification
                if show_progress:
                    self.show_notification(
                        f"Upload complete! URL copied to clipboard\\n{download_url}",
                        "upload-success"
                    )
                
                return {
                    'success': True,
                    'url': download_url,
                    'filename': file_path.name,
                    'size': file_size
                }
            
            else:
                error_msg = f"Upload failed: HTTP {response.status_code}"
                upload_record.update({
                    'status': 'failed',
                    'error': error_msg
                })
                self.history.insert(0, upload_record)
                self.save_history()
                
                if show_progress:
                    self.show_notification(f"Upload failed: {error_msg}", "upload-error")
                
                return {
                    'success': False,
                    'error': error_msg,
                    'filename': file_path.name
                }
        
        except Exception as e:
            error_msg = f"Upload error: {str(e)}"
            if show_progress:
                self.show_notification(error_msg, "upload-error")
            
            return {
                'success': False,
                'error': error_msg,
                'filename': file_path.name if 'file_path' in locals() else 'unknown'
            }
    
    def upload_multiple_files(self, file_paths, show_progress=True):
        """Upload multiple files"""
        results = []
        total_files = len(file_paths)
        
        if show_progress and total_files > 1:
            self.show_notification(f"Starting upload of {total_files} files...", "upload-start")
        
        for i, file_path in enumerate(file_paths, 1):
            if show_progress and total_files > 1:
                self.show_notification(f"Uploading file {i}/{total_files}: {Path(file_path).name}", "upload-progress")
            
            result = self.upload_file(file_path, show_progress=(total_files == 1))
            results.append(result)
            
            # Small delay between uploads to be respectful
            if i < total_files:
                time.sleep(1)
        
        if show_progress and total_files > 1:
            successful = sum(1 for r in results if r['success'])
            if successful == total_files:
                self.show_notification(f"All {total_files} files uploaded successfully!", "upload-success")
            else:
                failed = total_files - successful
                self.show_notification(f"{successful} files uploaded, {failed} failed", "upload-warning")
        
        return results
    
    def upload_folder(self, folder_path, show_progress=True):
        """Upload all files in a folder"""
        try:
            folder_path = Path(folder_path)
            if not folder_path.exists() or not folder_path.is_dir():
                raise ValueError(f"Invalid folder: {folder_path}")
            
            # Get all files in folder (recursively)
            files = []
            for file_path in folder_path.rglob('*'):
                if file_path.is_file():
                    files.append(file_path)
            
            if not files:
                if show_progress:
                    self.show_notification("No files found in folder", "upload-warning")
                return []
            
            return self.upload_multiple_files(files, show_progress)
        
        except Exception as e:
            error_msg = f"Folder upload error: {str(e)}"
            if show_progress:
                self.show_notification(error_msg, "upload-error")
            return [{'success': False, 'error': error_msg, 'filename': 'folder'}]
    
    def get_upload_history(self, limit=50):
        """Get upload history"""
        return self.history[:limit]
    
    def clear_history(self):
        """Clear upload history"""
        self.history = []
        self.save_history()
    
    def copy_to_clipboard(self, text):
        """Copy text to clipboard"""
        try:
            # Try different clipboard methods
            methods = [
                ['xclip', '-selection', 'clipboard'],
                ['xsel', '--clipboard', '--input'],
                ['wl-copy']  # For Wayland
            ]
            
            for method in methods:
                try:
                    process = subprocess.Popen(
                        method,
                        stdin=subprocess.PIPE,
                        stdout=subprocess.PIPE,
                        stderr=subprocess.PIPE
                    )
                    process.communicate(input=text.encode())
                    if process.returncode == 0:
                        return True
                except FileNotFoundError:
                    continue
            
            # Fallback: try to use Python's tkinter
            try:
                import tkinter as tk
                root = tk.Tk()
                root.withdraw()
                root.clipboard_clear()
                root.clipboard_append(text)
                root.update()
                root.destroy()
                return True
            except:
                pass
            
            return False
        
        except Exception as e:
            print(f"Failed to copy to clipboard: {e}")
            return False
    
    def show_notification(self, message, notification_type="info"):
        """Show desktop notification"""
        try:
            # Map notification types to icons
            icons = {
                'info': 'dialog-information',
                'upload-start': 'cloud-upload',
                'upload-progress': 'cloud-upload',
                'upload-success': 'dialog-ok-apply',
                'upload-error': 'dialog-error',
                'upload-warning': 'dialog-warning'
            }
            
            icon = icons.get(notification_type, 'dialog-information')
            
            # Try notify-send first
            try:
                subprocess.run([
                    'notify-send',
                    '-i', icon,
                    '-a', 'mros Upload Service',
                    'File Upload',
                    message
                ], check=True, timeout=5)
                return
            except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
                pass
            
            # Fallback: try zenity
            try:
                subprocess.run([
                    'zenity',
                    '--info',
                    '--text', f"File Upload\\n{message}",
                    '--title', 'mros Upload Service'
                ], check=True, timeout=10)
                return
            except (subprocess.CalledProcessError, FileNotFoundError, subprocess.TimeoutExpired):
                pass
            
            # Last resort: print to console
            print(f"NOTIFICATION: {message}")
        
        except Exception as e:
            print(f"Failed to show notification: {e}")

def main():
    """Main function for command line usage"""
    if len(sys.argv) < 2:
        print("Usage: mros-upload-service <file1> [file2] [file3] ...")
        print("       mros-upload-service --folder <folder_path>")
        print("       mros-upload-service --history")
        print("       mros-upload-service --clear-history")
        sys.exit(1)
    
    service = MrosUploadService()
    
    if sys.argv[1] == '--history':
        history = service.get_upload_history()
        if history:
            print("Upload History:")
            print("-" * 80)
            for item in history:
                status = "✓" if item['status'] == 'completed' else "✗"
                print(f"{status} {item['filename']} - {item.get('download_url', 'N/A')}")
        else:
            print("No upload history found.")
        return
    
    elif sys.argv[1] == '--clear-history':
        service.clear_history()
        print("Upload history cleared.")
        return
    
    elif sys.argv[1] == '--folder':
        if len(sys.argv) < 3:
            print("Error: Please specify folder path")
            sys.exit(1)
        
        folder_path = sys.argv[2]
        print(f"Uploading folder: {folder_path}")
        results = service.upload_folder(folder_path)
        
        successful = sum(1 for r in results if r['success'])
        total = len(results)
        print(f"Upload complete: {successful}/{total} files uploaded successfully")
        
        for result in results:
            if result['success']:
                print(f"✓ {result['filename']}: {result['url']}")
            else:
                print(f"✗ {result['filename']}: {result['error']}")
    
    else:
        # Upload individual files
        file_paths = sys.argv[1:]
        print(f"Uploading {len(file_paths)} file(s)...")
        
        results = service.upload_multiple_files(file_paths)
        
        successful = sum(1 for r in results if r['success'])
        total = len(results)
        print(f"Upload complete: {successful}/{total} files uploaded successfully")
        
        for result in results:
            if result['success']:
                print(f"✓ {result['filename']}: {result['url']}")
            else:
                print(f"✗ {result['filename']}: {result['error']}")

if __name__ == '__main__':
    main()

