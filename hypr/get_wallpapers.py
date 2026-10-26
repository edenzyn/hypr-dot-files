#!/usr/bin/env python3
import os
import json
import hashlib
import subprocess
from concurrent.futures import ThreadPoolExecutor

SOURCES_FILE = os.path.expanduser("~/.config/hypr/wallpaper_sources.json")
cur_file = os.path.expanduser("~/.config/hypr/current_wallpaper")
THUMB_DIR = os.path.expanduser("~/.cache/wallpaper-thumbs")
image_exts = ('.jpg', '.jpeg', '.png', '.webp')
video_exts = ('.mp4', '.webm', '.mkv', '.mov', '.gif')  # played with mpvpaper
valid_exts = image_exts + video_exts

# Video thumbnails are cached by path + mtime, so they are only made once
pending_thumbs = []

def video_thumb(path):
    key = hashlib.sha1(f"{path}:{os.path.getmtime(path)}".encode()).hexdigest()
    out = os.path.join(THUMB_DIR, key + ".jpg")
    if not os.path.exists(out):
        pending_thumbs.append((path, out))
    return out

def make_thumb(job):
    path, out = job
    base = ["ffmpeg", "-v", "error", "-y"]
    tail = ["-i", path, "-frames:v", "1", "-vf", "scale=480:-2", "-q:v", "5", out]
    try:
        # Grab a frame 1s in (skips black intros), fall back to the first frame
        if path.lower().endswith('.gif') or subprocess.run(base + ["-ss", "1"] + tail, timeout=30).returncode != 0 or not os.path.exists(out):
            subprocess.run(base + tail, timeout=30)
    except Exception:
        pass

current_wall = ""
if os.path.exists(cur_file):
    try:
        with open(cur_file, 'r') as f:
            current_wall = f.read().strip()
    except Exception:
        pass

if not current_wall or not os.path.exists(current_wall):
    current_wall = os.path.expanduser('~/Pictures/wall.jpg')

# Load only user configured sources (no hardcoded defaults)
sources = []
if os.path.exists(SOURCES_FILE):
    try:
        with open(SOURCES_FILE, 'r') as f:
            loaded = json.load(f)
            if isinstance(loaded, list):
                sources = loaded
    except Exception:
        pass

wallpapers = []
categories_set = set()
seen_paths = set()
folders_info = []

for src in sources:
    expanded_src = os.path.normpath(os.path.expanduser(src.strip()))
    if not os.path.isdir(expanded_src):
        continue

    folder_wall_count = 0
    src_folder_name = os.path.basename(expanded_src) or expanded_src

    for root, dirs, files in os.walk(expanded_src):
        if '.git' in root:
            continue
        rel = os.path.relpath(root, expanded_src)
        
        if rel == '.':
            # Direct files inside the source folder
            cat = src_folder_name.replace('_', ' ').replace('-', ' ').title()
        else:
            # Inside a subfolder
            parts = rel.split(os.sep)
            cat = parts[0].replace('_', ' ').replace('-', ' ').title()

        for f in sorted(files):
            if f.lower().endswith(valid_exts):
                p = os.path.join(root, f)
                if p in seen_paths:
                    continue
                seen_paths.add(p)
                folder_wall_count += 1
                categories_set.add(cat)
                
                clean_name = os.path.splitext(f)[0].replace('-', ' ').replace('_', ' ').title()
                if len(clean_name) > 28:
                    clean_name = clean_name[:25] + "..."
                is_video = f.lower().endswith(video_exts)
                wallpapers.append({
                    "path": p,
                    "name": clean_name,
                    "category": cat,
                    "folder": expanded_src,
                    "type": "video" if is_video else "image",
                    "thumb": video_thumb(p) if is_video else p
                })

    folders_info.append({
        "path": expanded_src,
        "name": src_folder_name.replace('_', ' ').replace('-', ' ').title(),
        "count": folder_wall_count
    })

if pending_thumbs:
    os.makedirs(THUMB_DIR, exist_ok=True)
    with ThreadPoolExecutor(max_workers=4) as pool:
        list(pool.map(make_thumb, pending_thumbs))

sorted_cats = ["All"] + sorted(list(categories_set))

print(json.dumps({
    "current": current_wall,
    "categories": sorted_cats,
    "folders": folders_info,
    "wallpapers": wallpapers
}))
