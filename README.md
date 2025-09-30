# 🚀 clilog: Manage Your Tasks Directly From the Terminal (CLI Log)

**clilog** is a fast, minimal, and open-source Command Line Interface (CLI) utility, built **in Bash And Python**, that allows you to efficiently manage notes, reminders, and to-do lists without relying on complex external software or databases.

**Clilog was made by a 13 year old Linux user!**

It’s designed to be a native Unix task management tool with a focus on **speed**, **simplicity**, and **minimalism**.

`clilog` is also available on the **AUR** as [`clilog-git`](https://aur.archlinux.org/packages/clilog-git/) for Arch Linux users.

---

## ✨ Key Features

| Command | Description | Usage Example |
| :--- | :--- | :--- |
| **`clilog add [text]`** | Adds a new note or task with a creation timestamp. | `clilog add "Configure the new server"` |
| **`clilog list`** | Lists all notes, showing IDs and status with color coding. | `clilog list` |
| **`clilog done [ID]`** | Marks a specific task (by ID) as **completed** (`[X]`). | `clilog done 5` |
| **`clilog undo [ID]`** | Reverts a completed task back to **pending** (`[ ]`). | `clilog undo 5` |
| **`clilog del [ID]`** | Permanently deletes a specific note by its ID. | `clilog del 3` |
| **`clilog clear`** | Clears **ALL** notes after a confirmation prompt. | `clilog clear` |
| **`clilog help`** | Displays the help menu with all commands. | `clilog help` |
| **`clilog version`** | Shows the current version of clilog. | `clilog version` |
| **`clilog search [text]`** | Search for a specific note. | `clilog search "learn"` |
| **`clilog edit [ID]`** | Edit a specific note by its ID. | `clilog edit 4` |
| **`clilog tag add [ID] [tag]`** | Add a tag to a note. | `clilog tag add 2 anime` |
| **`clilog tag remove [ID] [tag]`** | Remove a tag from a note. | `clilog tag remove 2 anime` |
| **`clilog tag move [ID] [old_tag] [new_tag]`** | Rename or move a tag on a note. | `clilog tag move 3 anime movie` |
| **`clilog interactive`** | Enter interactive TUI mode with a menu-driven interface. | `clilog interactive` |
| **`clilog export [file] [format]`** | Export notes to a file .md, .json or .csv. | clilog export $HOME/Documents/tasks.md **`markdown`** |
| **`clilog web`** | Starts the new clilog web mode made with python | clilog **`web`** |
| **`clilog add [TASK] --due`** | Adds a new note or task with a expiration date. | `clilog add "Task content" **`--due`** 2025-10-05 |
| **`clilog stats`** | Show All Clilog Stats | `clilog stats` |

---

## 🛠️ Installation (Recommended)

Since `clilog` is intended as a system-wide utility, it uses global directories (`/usr/local/bin` and `/usr/local/lib`) and therefore **requires `sudo` privileges**.

1. **Clone the Repository:**
```bash
git clone https://github.com/simeulinuxkaliaiwr/clilog.git
cd clilog
```

2. **Run the Installer:**
The `install.sh` script copies the executable to `/usr/local/bin` and the logic module to `/usr/local/lib/clilog`.
```bash
chmod +x install.sh
sudo ./install.sh
```

After installation, `clilog` can be run from any directory.

Alternatively, Arch Linux users can install it via the **AUR**:
```bash
yay -S clilog-git
```

---

## 💾 Data Storage

`clilog` follows the **XDG Base Directory Specification**, keeping your `$HOME` directory clean.

Notes are saved in a simple plaintext log file:

```
$HOME/.config/clilog/notes.log
```

This allows for easy backups, manual inspection, and seamless integration with other command-line tools like `grep` and `cat`.

---

## ⚙️ Project Structure

`clilog` is organized for clarity and maintainability:

| Directory/File | Purpose |
| :--- | :--- |
| **`bin/clilog`** | Main executable; validates arguments and routes commands. |
| **`src/functions.sh`** | Core logic for adding, listing, and modifying notes, using **`awk`** for safe file operations. |
| **`src/interactive.sh`** | TUI interactive mode using **`dialog`** for a user-friendly terminal interface. |
| **`src/clilog_web.py`** | WEB mode made with python |
| **`install.sh`** | Installs the files to global directories (`/usr/local/`). |

---

## 🤝 Contributions

Contributions are welcome! 

---
