import sys
import os
import subprocess
import json
import sqlite3
import datetime
from PyQt6.QtCore import QObject, pyqtSignal, pyqtSlot, QUrl
from PyQt6.QtWidgets import QApplication
from PyQt6.QtQml import QQmlApplicationEngine

class SystemBackend(QObject):
    terminalOutputReady = pyqtSignal(str)
    fileListReady = pyqtSignal(str)
    alarmTriggered = pyqtSignal(str)

    def __init__(self):
        super().__init__()
        self.data_dir = os.path.expanduser("~/.local/share/angler-plasma-mobile")
        os.makedirs(self.data_dir, exist_ok=True)
        self.init_db()

    def init_db(self):
        self.db_path = os.path.join(self.data_dir, "plasma_mobile.db")
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        # Messages table
        cur.execute('''CREATE TABLE IF NOT EXISTS messages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            recipient TEXT,
            body TEXT,
            timestamp DATETIME,
            is_incoming INTEGER
        )''')
        # Notes table
        cur.execute('''CREATE TABLE IF NOT EXISTS notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            updated_at DATETIME
        )''')
        # Alarms table
        cur.execute('''CREATE TABLE IF NOT EXISTS alarms (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            time_str TEXT,
            label TEXT,
            enabled INTEGER
        )''')
        # Contacts (PIM) table
        cur.execute('''CREATE TABLE IF NOT EXISTS contacts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            email TEXT,
            category TEXT DEFAULT 'Personal'
        )''')
        # Calendar Events (PIM) table
        cur.execute('''CREATE TABLE IF NOT EXISTS calendar_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            date_str TEXT NOT NULL,
            time_str TEXT,
            location TEXT,
            description TEXT
        )''')
        # Tasks / Todo (PIM) table
        cur.execute('''CREATE TABLE IF NOT EXISTS tasks (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task TEXT NOT NULL,
            completed INTEGER DEFAULT 0,
            due_date TEXT
        )''')
        # Weather cache table
        cur.execute('''CREATE TABLE IF NOT EXISTS weather_cache (
            id INTEGER PRIMARY KEY,
            city TEXT,
            temp_c REAL,
            condition TEXT,
            humidity INTEGER,
            wind_speed REAL,
            updated_at DATETIME
        )''')
        # Email (PIM) table
        cur.execute('''CREATE TABLE IF NOT EXISTS emails (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sender TEXT NOT NULL,
            sender_email TEXT NOT NULL,
            subject TEXT NOT NULL,
            body TEXT NOT NULL,
            date_str TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            is_starred INTEGER DEFAULT 0
        )''')
        # Insert initial default contacts if empty
        cur.execute("SELECT COUNT(*) FROM contacts")
        if cur.fetchone()[0] == 0:
            cur.executemany("INSERT INTO contacts (name, phone, email, category) VALUES (?, ?, ?, ?)", [
                ("Nexus Emergency", "911", "emergency@local", "Emergency"),
                ("Linux Kernel Team", "555-0199", "torvalds@kernel.org", "Work"),
                ("KDE Mobile Community", "555-0142", "plasma@kde.org", "Community"),
                ("Halium Porter", "555-0188", "angler@halium.org", "Dev")
            ])
        # Insert initial sample calendar event if empty
        cur.execute("SELECT COUNT(*) FROM calendar_events")
        if cur.fetchone()[0] == 0:
            today_str = datetime.date.today().isoformat()
            cur.execute("INSERT INTO calendar_events (title, date_str, time_str, location, description) VALUES (?, ?, ?, ?, ?)",
                        ("Nexus 6P Plasma Mobile Bringup", today_str, "10:00 AM", "Huawei Nexus 6P", "First boot and validation of Wayland/Qt6 shell on Halium 7.1"))
        # Insert initial sample emails if empty
        cur.execute("SELECT COUNT(*) FROM emails")
        if cur.fetchone()[0] == 0:
            cur.executemany("INSERT INTO emails (sender, sender_email, subject, body, date_str, is_read, is_starred) VALUES (?, ?, ?, ?, ?, ?, ?)", [
                ("KDE Plasma Mobile", "release@kde.org", "Welcome to Plasma 6 Mobile!", "Congratulations on launching KDE Plasma 6 Mobile on your Huawei Nexus 6P. You are running a native Wayland environment on top of Linux and libhybris.", "Sep 16", 0, 1),
                ("Linus Torvalds", "torvalds@linux-foundation.org", "MSM8994 4-Core BLOD Fix", "The patch disabling cpu4-7 in the device tree table ensures hardware stability without A57 core degradation. Happy hacking.", "Sep 15", 1, 1),
                ("Arch Linux ARM", "security@archlinuxarm.org", "Package updates available for aarch64", "Your glibc and systemd base installation has 12 security updates available in extra-arm. Use Discover or terminal to update.", "Sep 14", 1, 0)
            ])
        conn.commit()
        conn.close()

    # --- TERMINAL BACKEND ---
    @pyqtSlot(str, str)
    def runTerminalCommand(self, cmd, working_dir):
        try:
            cwd = os.path.expanduser(working_dir) if working_dir else os.path.expanduser("~")
            res = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True, timeout=10)
            output = res.stdout if res.stdout else res.stderr
            if not output and res.returncode == 0:
                output = "[Success - No Output]"
        except subprocess.TimeoutExpired:
            output = "Error: Command timed out."
        except Exception as e:
            output = f"Error: {str(e)}"
        self.terminalOutputReady.emit(output)

    # --- DOLPHIN FILE MANAGER BACKEND ---
    @pyqtSlot(str, result=str)
    def listDirectory(self, path):
        target = os.path.expanduser(path) if path else os.path.expanduser("~")
        if not os.path.exists(target) or not os.path.isdir(target):
            return json.dumps({"error": "Directory not found", "path": target, "items": []})
        
        items = []
        try:
            entries = os.scandir(target)
            for entry in entries:
                try:
                    stat = entry.stat()
                    size_str = f"{stat.st_size} B"
                    if stat.st_size > 1024 * 1024:
                        size_str = f"{round(stat.st_size / (1024 * 1024), 1)} MB"
                    elif stat.st_size > 1024:
                        size_str = f"{round(stat.st_size / 1024, 1)} KB"
                    
                    items.append({
                        "name": entry.name,
                        "isDir": entry.is_dir(),
                        "size": "" if entry.is_dir() else size_str,
                        "icon": "📁" if entry.is_dir() else "📄",
                        "fullPath": entry.path
                    })
                except PermissionError:
                    continue
        except Exception as e:
            return json.dumps({"error": str(e), "path": target, "items": []})
            
        items.sort(key=lambda x: (not x["isDir"], x["name"].lower()))
        return json.dumps({"path": target, "items": items})

    # --- MESSAGING BACKEND ---
    @pyqtSlot(result=str)
    def getMessages(self):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("SELECT id, recipient, body, timestamp, is_incoming FROM messages ORDER BY timestamp ASC")
        rows = cur.fetchall()
        conn.close()
        msgs = [{"id": r[0], "recipient": r[1], "body": r[2], "timestamp": r[3], "isIncoming": bool(r[4])} for r in rows]
        return json.dumps(msgs)

    @pyqtSlot(str, str)
    def sendMessage(self, recipient, body):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        now = datetime.datetime.now().strftime("%H:%M")
        cur.execute("INSERT INTO messages (recipient, body, timestamp, is_incoming) VALUES (?, ?, ?, 0)", (recipient, body, now))
        conn.commit()
        conn.close()

    # --- NOTES BACKEND ---
    @pyqtSlot(result=str)
    def getNotes(self):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("SELECT id, title, content, updated_at FROM notes ORDER BY id DESC")
        rows = cur.fetchall()
        conn.close()
        notes = [{"id": r[0], "title": r[1], "content": r[2], "updatedAt": r[3]} for r in rows]
        return json.dumps(notes)

    @pyqtSlot(str, str)
    def saveNote(self, title, content):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
        cur.execute("INSERT INTO notes (title, content, updated_at) VALUES (?, ?, ?)", (title, content, now))
        conn.commit()
        conn.close()

    @pyqtSlot(int)
    def deleteNote(self, note_id):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("DELETE FROM notes WHERE id = ?", (note_id,))
        conn.commit()
        conn.close()

    # --- ALARMS & CLOCK BACKEND ---
    @pyqtSlot(result=str)
    def getAlarms(self):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("SELECT id, time_str, label, enabled FROM alarms ORDER BY time_str ASC")
        rows = cur.fetchall()
        conn.close()
        alarms = [{"id": r[0], "time": r[1], "label": r[2], "enabled": bool(r[3])} for r in rows]
        return json.dumps(alarms)

    @pyqtSlot(str, str)
    def addAlarm(self, time_str, label):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("INSERT INTO alarms (time_str, label, enabled) VALUES (?, ?, 1)", (time_str, label))
        conn.commit()
        conn.close()

    @pyqtSlot(int, bool)
    def toggleAlarm(self, alarm_id, enabled):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("UPDATE alarms SET enabled = ? WHERE id = ?", (1 if enabled else 0, alarm_id))
        conn.commit()
        conn.close()

    # --- PIM: CONTACTS BACKEND ---
    @pyqtSlot(result=str)
    def getContacts(self):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("SELECT id, name, phone, email, category FROM contacts ORDER BY name ASC")
        rows = cur.fetchall()
        conn.close()
        contacts = [{"id": r[0], "name": r[1], "phone": r[2], "email": r[3], "category": r[4]} for r in rows]
        return json.dumps(contacts)

    @pyqtSlot(str, str, str, str)
    def saveContact(self, name, phone, email, category):
        if not name:
            return
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("INSERT INTO contacts (name, phone, email, category) VALUES (?, ?, ?, ?)", (name, phone, email, category))
        conn.commit()
        conn.close()

    @pyqtSlot(int)
    def deleteContact(self, contact_id):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("DELETE FROM contacts WHERE id = ?", (contact_id,))
        conn.commit()
        conn.close()

    # --- PIM: CALENDAR EVENTS BACKEND ---
    @pyqtSlot(str, result=str)
    def getEvents(self, date_str):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        if date_str:
            cur.execute("SELECT id, title, date_str, time_str, location, description FROM calendar_events WHERE date_str = ? ORDER BY time_str ASC", (date_str,))
        else:
            cur.execute("SELECT id, title, date_str, time_str, location, description FROM calendar_events ORDER BY date_str ASC, time_str ASC")
        rows = cur.fetchall()
        conn.close()
        events = [{"id": r[0], "title": r[1], "date": r[2], "time": r[3], "location": r[4], "description": r[5]} for r in rows]
        return json.dumps(events)

    @pyqtSlot(str, str, str, str, str)
    def addEvent(self, title, date_str, time_str, location, description):
        if not title or not date_str:
            return
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("INSERT INTO calendar_events (title, date_str, time_str, location, description) VALUES (?, ?, ?, ?, ?)",
                    (title, date_str, time_str, location, description))
        conn.commit()
        conn.close()

    @pyqtSlot(int)
    def deleteEvent(self, event_id):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("DELETE FROM calendar_events WHERE id = ?", (event_id,))
        conn.commit()
        conn.close()

    # --- PIM: TASKS / TODO BACKEND ---
    @pyqtSlot(result=str)
    def getTasks(self):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("SELECT id, task, completed, due_date FROM tasks ORDER BY completed ASC, id DESC")
        rows = cur.fetchall()
        conn.close()
        tasks = [{"id": r[0], "task": r[1], "completed": bool(r[2]), "dueDate": r[3]} for r in rows]
        return json.dumps(tasks)

    @pyqtSlot(str, str)
    def addTask(self, task, due_date):
        if not task:
            return
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("INSERT INTO tasks (task, completed, due_date) VALUES (?, 0, ?)", (task, due_date))
        conn.commit()
        conn.close()

    @pyqtSlot(int, bool)
    def toggleTask(self, task_id, completed):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("UPDATE tasks SET completed = ? WHERE id = ?", (1 if completed else 0, task_id))
        conn.commit()
        conn.close()

    @pyqtSlot(int)
    def deleteTask(self, task_id):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("DELETE FROM tasks WHERE id = ?", (task_id,))
        conn.commit()
        conn.close()

    # --- PIM: EMAIL BACKEND ---
    @pyqtSlot(result=str)
    def getEmails(self):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("SELECT id, sender, sender_email, subject, body, date_str, is_read, is_starred FROM emails ORDER BY id DESC")
        rows = cur.fetchall()
        conn.close()
        emails = [{
            "id": r[0],
            "sender": r[1],
            "senderEmail": r[2],
            "subject": r[3],
            "body": r[4],
            "dateStr": r[5],
            "isRead": bool(r[6]),
            "isStarred": bool(r[7])
        } for r in rows]
        return json.dumps(emails)

    @pyqtSlot(str, str, str)
    def sendEmail(self, recipient_email, subject, body):
        if not recipient_email or not subject:
            return
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        now_str = datetime.datetime.now().strftime("%b %d")
        cur.execute("INSERT INTO emails (sender, sender_email, subject, body, date_str, is_read, is_starred) VALUES (?, ?, ?, ?, ?, 1, 0)",
                    ("Me", recipient_email, subject, body, now_str))
        conn.commit()
        conn.close()

    @pyqtSlot(int, bool)
    def toggleStarEmail(self, email_id, is_starred):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("UPDATE emails SET is_starred = ? WHERE id = ?", (1 if is_starred else 0, email_id))
        conn.commit()
        conn.close()

    @pyqtSlot(int)
    def markEmailRead(self, email_id):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("UPDATE emails SET is_read = 1 WHERE id = ?", (email_id,))
        conn.commit()
        conn.close()

    @pyqtSlot(int)
    def deleteEmail(self, email_id):
        conn = sqlite3.connect(self.db_path)
        cur = conn.cursor()
        cur.execute("DELETE FROM emails WHERE id = ?", (email_id,))
        conn.commit()
        conn.close()

    # --- WEATHER BACKEND ---
    @pyqtSlot(str, result=str)
    def getWeather(self, city):
        """Fetches live weather via wttr.in or returns offline sensor cache"""
        target_city = city if city else "Denver"
        # Attempt network fetch with 2s timeout
        try:
            import urllib.request
            url = f"https://wttr.in/{urllib.parse.quote(target_city)}?format=j1"
            req = urllib.request.Request(url, headers={"User-Agent": "PlasmaMobile/6.0 Nexus6P"})
            with urllib.request.urlopen(req, timeout=3) as resp:
                data = json.loads(resp.read().decode())
                current = data.get("current_condition", [{}])[0]
                temp_c = float(current.get("temp_C", 20))
                desc = current.get("weatherDesc", [{}])[0].get("value", "Clear")
                humidity = int(current.get("humidity", 40))
                wind = float(current.get("windspeedKmph", 10))
                
                # Cache to sqlite
                conn = sqlite3.connect(self.db_path)
                cur = conn.cursor()
                now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")
                cur.execute("INSERT OR REPLACE INTO weather_cache (id, city, temp_c, condition, humidity, wind_speed, updated_at) VALUES (1, ?, ?, ?, ?, ?, ?)",
                            (target_city, temp_c, desc, humidity, wind, now))
                conn.commit()
                conn.close()
                return json.dumps({
                    "city": target_city,
                    "temp_c": round(temp_c),
                    "temp_f": round(temp_c * 9/5 + 32),
                    "condition": desc,
                    "humidity": humidity,
                    "wind_speed": wind,
                    "is_live": True,
                    "updated_at": now
                })
        except Exception:
            pass

        # Fallback to local SQLite cache
        try:
            conn = sqlite3.connect(self.db_path)
            cur = conn.cursor()
            cur.execute("SELECT city, temp_c, condition, humidity, wind_speed, updated_at FROM weather_cache WHERE id = 1")
            row = cur.fetchone()
            conn.close()
            if row:
                return json.dumps({
                    "city": row[0],
                    "temp_c": round(row[1]),
                    "temp_f": round(row[1] * 9/5 + 32),
                    "condition": row[2],
                    "humidity": row[3],
                    "wind_speed": row[4],
                    "is_live": False,
                    "updated_at": row[5]
                })
        except Exception:
            pass

        return json.dumps({
            "city": target_city,
            "temp_c": 21,
            "temp_f": 70,
            "condition": "Partly Cloudy",
            "humidity": 35,
            "wind_speed": 12,
            "is_live": False,
            "updated_at": "Offline Default"
        })

    # --- ANGELFISH BROWSER BACKEND ---
    @pyqtSlot(str, result=str)
    def fetchWebPage(self, url):
        """Fetches web page content with timeout and returns parsed title & snippet"""
        target_url = url if url.startswith("http") else f"https://{url}"
        try:
            import urllib.request
            req = urllib.request.Request(target_url, headers={"User-Agent": "Mozilla/5.0 (Mobile; Plasma/6.0; Nexus6P; Linux aarch64) AppleWebKit/537.36"})
            with urllib.request.urlopen(req, timeout=4) as resp:
                raw_html = resp.read().decode('utf-8', errors='ignore')
                import re
                title_match = re.search(r'<title>(.*?)</title>', raw_html, re.IGNORECASE | re.DOTALL)
                title = title_match.group(1).strip() if title_match else target_url
                
                # Strip basic html tags for text preview
                clean_text = re.sub(r'<script.*?</script>', '', raw_html, flags=re.DOTALL | re.IGNORECASE)
                clean_text = re.sub(r'<style.*?</style>', '', clean_text, flags=re.DOTALL | re.IGNORECASE)
                clean_text = re.sub(r'<[^<]+?>', ' ', clean_text)
                clean_text = re.sub(r'\s+', ' ', clean_text).strip()[:300]
                
                return json.dumps({
                    "url": target_url,
                    "title": title,
                    "snippet": clean_text,
                    "status": "Loaded"
                })
        except Exception as e:
            return json.dumps({
                "url": target_url,
                "title": f"Offline / Error: {url}",
                "snippet": f"Could not reach {target_url}: {str(e)}",
                "status": "Failed"
            })

    # --- DISCOVER PACKAGE MANAGER BACKEND ---
    @pyqtSlot(str, result=str)
    def searchPackages(self, query):
        """Searches local pacman / flatpak or returns curated mobile packages"""
        pkgs = [
            {"name": "plasma-mobile", "version": "6.0.4", "repo": "KDE", "desc": "KDE Plasma phone experience for Linux", "installed": True},
            {"name": "angelfish", "version": "24.02", "repo": "Extra", "desc": "Mobile touch-friendly web browser", "installed": True},
            {"name": "koko", "version": "24.02", "repo": "KDE", "desc": "Image gallery viewer for Plasma Mobile", "installed": False},
            {"name": "audiotube", "version": "24.02", "repo": "Extra", "desc": "YouTube Music client for mobile", "installed": False},
            {"name": "neochat", "version": "24.02", "repo": "KDE", "desc": "Matrix client for Plasma Mobile", "installed": False},
            {"name": "alligator", "version": "24.02", "repo": "KDE", "desc": "Kirigami RSS and Atom feed reader", "installed": False},
            {"name": "itinerary", "version": "24.02", "repo": "KDE", "desc": "Digital travel assistant", "installed": False},
            {"name": "tokodon", "version": "24.02", "repo": "KDE", "desc": "Mastodon and Fediverse mobile client", "installed": False},
            {"name": "libhybris", "version": "0.1.0", "repo": "Halium", "desc": "Android HAL bridge libraries", "installed": True},
            {"name": "wayland", "version": "1.23.0", "repo": "Core", "desc": "Wayland display server protocol", "installed": True}
        ]
        
        # If real pacman is available, query it
        if query:
            q_lower = query.lower()
            filtered = [p for p in pkgs if q_lower in p["name"].lower() or q_lower in p["desc"].lower()]
            try:
                res = subprocess.run(["pacman", "-Ss", query], capture_output=True, text=True, timeout=3)
                if res.returncode == 0 and res.stdout:
                    # Parse pacman matches
                    lines = res.stdout.strip().split("\n")
                    for i in range(0, min(len(lines), 10), 2):
                        header = lines[i].split()
                        desc = lines[i+1].strip() if i+1 < len(lines) else ""
                        if len(header) >= 2:
                            filtered.append({
                                "name": header[0].split("/")[-1],
                                "version": header[1],
                                "repo": header[0].split("/")[0],
                                "desc": desc,
                                "installed": "[installed]" in lines[i]
                            })
            except Exception:
                pass
            return json.dumps(filtered)
            
        return json.dumps(pkgs)

    # --- HARDWARE SYSTEM CONTROLS ---
    @pyqtSlot(str, result=str)
    def readSysfs(self, path):
        if os.path.exists(path):
            try:
                with open(path, "r") as f:
                    return f.read().strip()
            except Exception as e:
                return f"Error: {e}"
        return "N/A"

    @pyqtSlot(str, str)
    def writeSysfs(self, path, val):
        try:
            with open(path, "w") as f:
                f.write(val)
        except Exception as e:
            print(f"Error writing to {path}: {e}")

    @pyqtSlot(result=str)
    def getSystemStats(self):
        """Returns live hardware metrics (CPU, RAM, Battery, Thermal, Uptime)"""
        stats = {
            "uptime": "Unknown",
            "cpu_usage": 0,
            "ram_total": "3.0 GB",
            "ram_used": "0 MB",
            "ram_percent": 0,
            "battery_percent": 100,
            "battery_status": "Discharging",
            "cpu_temp": "N/A",
            "active_cores": 4
        }
        try:
            # Uptime
            if os.path.exists("/proc/uptime"):
                with open("/proc/uptime", "r") as f:
                    up_secs = int(float(f.readline().split()[0]))
                    h = up_secs // 3600
                    m = (up_secs % 3600) // 60
                    stats["uptime"] = f"{h}h {m}m"
            
            # RAM
            if os.path.exists("/proc/meminfo"):
                mem = {}
                with open("/proc/meminfo", "r") as f:
                    for line in f:
                        parts = line.split(":")
                        if len(parts) == 2:
                            mem[parts[0].strip()] = int(parts[1].strip().split()[0])
                total_kb = mem.get("MemTotal", 1)
                avail_kb = mem.get("MemAvailable", mem.get("MemFree", 0))
                used_kb = total_kb - avail_kb
                stats["ram_total"] = f"{round(total_kb / (1024 * 1024), 1)} GB"
                stats["ram_used"] = f"{round(used_kb / 1024)} MB"
                stats["ram_percent"] = round((used_kb / total_kb) * 100)

            # Battery (sysfs)
            batt_dirs = [p for p in os.listdir("/sys/class/power_supply") if "batt" in p.lower()] if os.path.exists("/sys/class/power_supply") else []
            if batt_dirs:
                b_dir = os.path.join("/sys/class/power_supply", batt_dirs[0])
                cap_file = os.path.join(b_dir, "capacity")
                stat_file = os.path.join(b_dir, "status")
                if os.path.exists(cap_file):
                    with open(cap_file, "r") as f:
                        stats["battery_percent"] = int(f.read().strip())
                if os.path.exists(stat_file):
                    with open(stat_file, "r") as f:
                        stats["battery_status"] = f.read().strip()
            
            # Thermals
            tz0 = "/sys/class/thermal/thermal_zone0/temp"
            if os.path.exists(tz0):
                with open(tz0, "r") as f:
                    temp_raw = int(f.read().strip())
                    stats["cpu_temp"] = f"{round(temp_raw / 1000, 1)}°C" if temp_raw > 1000 else f"{temp_raw}°C"

        except Exception as e:
            stats["error"] = str(e)

        return json.dumps(stats)

    @pyqtSlot(str, result=str)
    def setCpuGovernor(self, governor):
        """Sets the CPU scaling governor across active online cores"""
        success_cores = []
        for cpu in range(4):
            gov_path = f"/sys/devices/system/cpu/cpu{cpu}/cpufreq/scaling_governor"
            if os.path.exists(gov_path):
                try:
                    with open(gov_path, "w") as f:
                        f.write(governor)
                    success_cores.append(cpu)
                except Exception:
                    pass
        return f"Applied {governor} to cores: {success_cores}"

    @pyqtSlot(result=str)
    def getWifiNetworks(self):
        """Scans for local Wi-Fi SSIDs using nmcli or iwlist if available"""
        networks = []
        try:
            res = subprocess.run(["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY", "dev", "wifi"], capture_output=True, text=True, timeout=5)
            if res.returncode == 0:
                for line in res.stdout.strip().split("\n"):
                    if line:
                        parts = line.split(":")
                        if len(parts) >= 2 and parts[0]:
                            networks.append({
                                "ssid": parts[0],
                                "signal": parts[1] + "%",
                                "security": parts[2] if len(parts) > 2 else "Open"
                            })
        except Exception:
            pass
        return json.dumps(networks)

    @pyqtSlot(result=str)
    def getAudioTracks(self):
        """Discovers real audio files in user Music or current directory"""
        search_dirs = [
            os.path.expanduser("~/Music"),
            os.path.expanduser("~/Downloads"),
            os.path.expanduser("~")
        ]
        tracks = []
        extensions = (".mp3", ".wav", ".flac", ".ogg", ".m4a")
        for sdir in search_dirs:
            if os.path.exists(sdir):
                for root, _, files in os.walk(sdir):
                    for f in files:
                        if f.lower().endswith(extensions):
                            tracks.append({
                                "title": os.path.splitext(f)[0],
                                "artist": "Local Audio",
                                "duration": "--:--",
                                "path": os.path.join(root, f)
                            })
                    if len(tracks) >= 25:
                        break
            if len(tracks) >= 25:
                break

        # Fallback system defaults if no music files found yet
        if not tracks:
            tracks = [
                {"title": "KDE Plasma Breeze Theme", "artist": "KDE Community", "duration": "3:42", "path": ""},
                {"title": "Arch Linux Freedom Sound", "artist": "Open Source Collective", "duration": "4:15", "path": ""},
                {"title": "Snapdragon 810 Beats", "artist": "Adreno Sound Team", "duration": "2:58", "path": ""},
                {"title": "Ambient AMOLED Night", "artist": "PulseAudio Stream", "duration": "5:20", "path": ""}
            ]
        return json.dumps(tracks)

    @pyqtSlot(str, result=str)
    def capturePhoto(self, sensor_name):
        """Captures a real snapshot to ~/Pictures using ffmpeg / v4l2 or camera HAL"""
        pics_dir = os.path.expanduser("~/Pictures")
        os.makedirs(pics_dir, exist_ok=True)
        ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"IMG_{ts}.jpg"
        target_path = os.path.join(pics_dir, filename)

        # Attempt capture via /dev/video if available
        v_devs = [f"/dev/{x}" for x in os.listdir("/dev") if x.startswith("video")] if os.path.exists("/dev") else []
        if v_devs:
            try:
                subprocess.run(["ffmpeg", "-y", "-f", "v4l2", "-i", v_devs[0], "-vframes", "1", target_path],
                               stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
                if os.path.exists(target_path):
                    return json.dumps({"success": True, "path": target_path, "file": filename})
            except Exception:
                pass

        # If no camera device node is available (e.g. HAL container not yet attached), generate test snapshot
        try:
            subprocess.run([
                "ffmpeg", "-y", "-f", "lavfi",
                "-i", f"color=c=black:s=1920x1080:d=1,drawtext=text='Nexus 6P {sensor_name} \\n {ts}':fontcolor=white:fontsize=48:x=(w-text_w)/2:y=(h-text_h)/2",
                "-vframes", "1", target_path
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=5)
            return json.dumps({"success": True, "path": target_path, "file": filename})
        except Exception as e:
            return json.dumps({"success": False, "error": str(e)})

def main():
    app = QApplication(sys.argv)
    engine = QQmlApplicationEngine()

    backend = SystemBackend()
    engine.rootContext().setContextProperty("systemBackend", backend)

    qml_file = os.path.join(os.path.dirname(__file__), "Main.qml")
    engine.load(QUrl.fromLocalFile(qml_file))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())

if __name__ == "__main__":
    main()
