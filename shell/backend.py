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
