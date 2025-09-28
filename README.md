# 🚀 clilog: Manage Your Tasks Right From the Terminal (CLI Log)

**clilog** is a simple, fast, and open-source Command Line Interface (CLI) utility, built 100% in **Bash**, designed to efficiently manage notes, reminders, and to-do lists without relying on complex external software or databases.

The primary goal of `clilog` is to provide a task management tool that is native to the Unix environment, offering **speed** and **minimalism**.

## ✨ Key Features

| Command | Description | Usage Example |
| :--- | :--- | :--- |
| **`clilog add [text]`** | Adds a new note or task with a creation timestamp. | `clilog add "Configure the new server"` |
| **`clilog list`** | Lists all notes, displaying their IDs and status with color coding. | `clilog list` |
| **`clilog done [ID]`** | Marks a specific task (by ID) as **completed** (`[X]`). | `clilog done 5` |
| **`clilog undo [ID]`** | Reverts a completed task back to **pending** (`[ ]`). | `clilog undo 5` |
| **`clilog del [ID]`** | Permanently deletes a specific note by its ID. | `clilog del 3` |
| **`clilog clear`** | Clears **ALL** notes after a safety confirmation prompt. | `clilog clear` |
| **`clilog help`** | Displays the help menu and the full list of commands. | `clilog help` |
| **`clilog version`** | Shows the current version of Clilog. | `clilog version` |
| **`clilog search`** | Search for a especific note | clilog search "learn"
| **`clilog edit [ID]`** | Edit a especific note (by ID) | clilog edit 4 |

---

## 🛠️ Installation (Recommended Method)

Since `clilog` is designed to be a system-wide utility, installation uses global directories (`/usr/local/bin` and `/usr/local/lib`) and therefore **requires `sudo` privileges**.

1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/simeulinuxkaliaiwr/clilog.git
    cd clilog
    ```

2.  **Execute the Installer:**
    The `install.sh` script will copy the binary to `/usr/local/bin` and the logic module to `/usr/local/lib/clilog`.
    ```bash
    chmod +x install.sh
    sudo ./install.sh
    ```

After installation, you can use the `clilog` command from any directory.

---

## 💾 Where Your Data Lives

Instead of cluttering your `$HOME` directory, `clilog` adheres to the **XDG Base Directory Specification** for data persistence.

Your notes are saved in a simple plaintext log file:

$$\mathbf{\$HOME/.config/clilog/notes.log}$$

This makes it easy to back up, manually inspect, and integrate with other command-line tools like `grep` and `cat`.

## ⚙️ Project Structure

`clilog` is split into two directories to ensure clarity and maintainability:

| Directory/File | Purpose |
| :--- | :--- |
| **`bin/clilog`** | The main router and executable. Handles argument validation and directs execution to the correct function. |
| **`src/functions.sh`** | Contains all the data manipulation logic (add, list, mark) using **`awk`** for secure file editing. |
| **`install.sh`** | Script responsible for copying files to the global directories (`/usr/local/`). |

---

## 🤝 Contributions

Contributions are highly welcome! If you have suggestions for new commands, improvements to the `awk` logic, or Bash optimizations, feel free to open an issue or submit a pull request.

---
