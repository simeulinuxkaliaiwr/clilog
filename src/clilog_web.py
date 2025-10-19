#!/usr/bin/env python3
from flask import Flask, render_template_string, request, redirect, flash, jsonify
import os
import re
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'clilog_web_secret_key_2024'

NOTES_FILE = os.path.expanduser("~/.config/clilog/notes.log")

def get_notes():
    if not os.path.exists(NOTES_FILE):
        return []
    
    notes = []
    with open(NOTES_FILE, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            
            id_match = re.match(r'^(\d+)\.\s+', line)
            note_id = int(id_match.group(1)) if id_match else line_num
            
            status = "completed" if "[X]" in line else "pending"
            due_match = re.search(r'\|\s*Due:\s*([^\|]+?)\s*\|', line)
            due_date = due_match.group(1).strip() if due_match else "-"
            
            timestamp_match = re.search(r'\((\d{4}-\d{2}-\d{2} \d{2}:\d{2})\)', line)
            timestamp = timestamp_match.group(1) if timestamp_match else ""
            
            content = line
            if timestamp_match:
                content = line[timestamp_match.end():].strip()
            else:
                content = re.sub(r'^\d+\.\s+\[.\]\s+\|\s*Due:.*?\|\s*', '', line).strip()
            
            tags = re.findall(r'#(\w+)', content)
            content_without_tags = re.sub(r'#\w+', '', content).strip()
            
            notes.append({
                'id': note_id,
                'status': status,
                'due_date': due_date,
                'timestamp': timestamp,
                'content': content_without_tags,
                'tags': tags,
                'raw': line
            })
    
    return notes

def save_notes(notes_data):
    with open(NOTES_FILE, 'w', encoding='utf-8') as f:
        for note in notes_data:
            f.write(note['raw'] + '\n')

def update_note_in_file(note_id, new_content, status=None):
    notes = get_notes()
    
    for note in notes:
        if note['id'] == note_id:
            status_prefix = "[X]" if status == "completed" else ("[ ]" if status else ("[X]" if note['status'] == "completed" else "[ ]"))
            due_str = f"| Due: {note['due_date']} |"
            timestamp_str = f"({note['timestamp']})" if note['timestamp'] else f"({datetime.now().strftime('%Y-%m-%d %H:%M')})"
            tags_str = " " + " ".join(f"#{tag}" for tag in note['tags']) if note['tags'] else ""
            
            new_raw = f"{note_id}. {status_prefix} {due_str} {timestamp_str} {new_content}{tags_str}"
            note['raw'] = new_raw
            note['content'] = new_content
            if status:
                note['status'] = status
            break
    
    with open(NOTES_FILE, 'w', encoding='utf-8') as f:
        for note in notes:
            f.write(note['raw'] + '\n')

def add_note_to_file(content, tags=None):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M")
    tags_str = " " + " ".join(f"#{tag}" for tag in (tags or [])) if tags else ""
    
    # Calcula o próximo ID
    notes = get_notes()
    next_id = max([n['id'] for n in notes], default=0) + 1
    
    new_line = f"{next_id}. [ ] | Due: - | ({timestamp}) {content}{tags_str}"
    
    with open(NOTES_FILE, 'a', encoding='utf-8') as f:
        f.write(new_line + '\n')

def delete_note_from_file(note_id):
    notes = get_notes()
    notes = [note for note in notes if note['id'] != note_id]
    
    with open(NOTES_FILE, 'w', encoding='utf-8') as f:
        for note in notes:
            f.write(note['raw'] + '\n')

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clilog - Modern Task Manager</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <style>
        @keyframes slideIn {
            from { opacity: 0; transform: translateY(-10px); }
            to { opacity: 1; transform: translateY(0); }
        }
        @keyframes fadeIn {
            from { opacity: 0; }
            to { opacity: 1; }
        }
        @keyframes slideOut {
            from { opacity: 1; transform: translateX(0); }
            to { opacity: 0; transform: translateX(100px); }
        }
        .task-item {
            animation: slideIn 0.3s ease-out;
        }
        .task-removing {
            animation: slideOut 0.3s ease-out;
        }
        .toast {
            animation: slideIn 0.3s ease-out;
        }
        .dark body {
            background: #0f172a;
            color: #e2e8f0;
        }
        .dark .card {
            background: #1e293b;
            border-color: #334155;
        }
        .gradient-bg {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        .glass {
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255, 255, 255, 0.2);
        }
        .task-checkbox {
            transition: all 0.3s ease;
        }
        .task-checkbox:hover {
            transform: scale(1.1);
        }
        input:focus, textarea:focus {
            outline: none;
            ring: 2px;
            ring-color: #667eea;
        }
    </style>
</head>
<body class="bg-gradient-to-br from-purple-50 to-blue-50 min-h-screen transition-colors duration-300">
    <div class="container mx-auto px-4 py-8 max-w-5xl">
        <!-- Header com Dark Mode Toggle -->
        <header class="text-center mb-8 relative">
            <div class="gradient-bg text-white rounded-2xl p-8 shadow-2xl">
                <button onclick="toggleDarkMode()" class="absolute top-4 right-4 text-white hover:text-yellow-300 transition-colors">
                    <i class="fas fa-moon text-2xl"></i>
                </button>
                <h1 class="text-5xl font-bold mb-2">
                    <i class="fas fa-rocket mr-3"></i>Clilog
                </h1>
                <p class="text-purple-100 text-lg">Seu gerenciador de tarefas turbinado</p>
            </div>
        </header>

        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
            <div class="card bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 transform hover:scale-105 transition-transform cursor-pointer">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-3xl font-bold text-purple-600">{{ stats.total }}</div>
                        <div class="text-gray-600 dark:text-gray-300 mt-1">Total de Tarefas</div>
                    </div>
                    <div class="text-5xl text-purple-200"><i class="fas fa-tasks"></i></div>
                </div>
            </div>
            <div class="card bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 transform hover:scale-105 transition-transform cursor-pointer">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-3xl font-bold text-green-600">{{ stats.completed }}</div>
                        <div class="text-gray-600 dark:text-gray-300 mt-1">Concluídas</div>
                    </div>
                    <div class="text-5xl text-green-200"><i class="fas fa-check-circle"></i></div>
                </div>
            </div>
            <div class="card bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 transform hover:scale-105 transition-transform cursor-pointer">
                <div class="flex items-center justify-between">
                    <div>
                        <div class="text-3xl font-bold text-orange-600">{{ stats.pending }}</div>
                        <div class="text-gray-600 dark:text-gray-300 mt-1">Pendentes</div>
                    </div>
                    <div class="text-5xl text-orange-200"><i class="fas fa-clock"></i></div>
                </div>
            </div>
        </div>

        <!-- Add Task Form -->
        <div class="card bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 mb-8">
            <form id="addTaskForm" class="flex flex-col md:flex-row gap-3">
                <div class="flex-1 relative">
                    <input 
                        type="text" 
                        id="taskInput"
                        class="w-full p-4 pr-12 border-2 border-gray-200 dark:border-gray-600 dark:bg-slate-700 dark:text-white rounded-xl focus:border-purple-500 transition-colors" 
                        placeholder="Enter your new task... (Ctrl+N for focus)"
                        autocomplete="off"
                    >
                    <button type="submit" class="absolute right-2 top-1/2 transform -translate-y-1/2 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-700 hover:to-blue-700 text-white font-bold py-2 px-6 rounded-lg transition-all duration-200 shadow-lg hover:shadow-xl">
                        <i class="fas fa-plus mr-2"></i>Adicionar
                    </button>
                </div>
            </form>
        </div>

        <!-- Filters -->
        <div class="card bg-white dark:bg-slate-800 rounded-xl shadow-lg p-6 mb-8">
            <div class="flex flex-col md:flex-row gap-4">
                <div class="flex-1 relative">
                    <i class="fas fa-search absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400"></i>
                    <input 
                        type="text" 
                        id="searchInput" 
                        placeholder="Buscar tarefas..." 
                        class="w-full pl-12 p-3 border-2 border-gray-200 dark:border-gray-600 dark:bg-slate-700 dark:text-white rounded-lg focus:border-purple-500 transition-colors"
                        onkeyup="filterNotes()"
                    >
                </div>
                <select id="statusFilter" onchange="filterNotes()" class="p-3 border-2 border-gray-200 dark:border-gray-600 dark:bg-slate-700 dark:text-white rounded-lg focus:border-purple-500 transition-colors">
                    <option value="all">All</option>
                    <option value="pending">Pending</option>
                    <option value="completed">Completed</option>
                </select>
            </div>
        </div>

        <!-- Tasks List -->
        <div id="tasksList" class="space-y-3">
            {% if notes %}
                {% for note in notes %}
                <div class="task-item note-item card bg-white dark:bg-slate-800 rounded-xl shadow-md hover:shadow-xl transition-all duration-200 p-5" 
                     data-status="{{ note.status }}"
                     data-id="{{ note.id }}">
                    <div class="flex items-start gap-4">
                        <!-- Checkbox -->
                        <button 
                            onclick="toggleStatus({{ note.id }}, '{{ note.status }}')" 
                            class="task-checkbox mt-1 flex-shrink-0"
                        >
                            {% if note.status == 'completed' %}
                                <i class="fas fa-check-circle text-3xl text-green-500 hover:text-green-600"></i>
                            {% else %}
                                <i class="far fa-circle text-3xl text-gray-300 hover:text-purple-500"></i>
                            {% endif %}
                        </button>

                        <!-- Content -->
                        <div class="flex-1 min-w-0">
                            <div class="flex items-center justify-between mb-2">
                                <span 
                                    id="content-{{ note.id }}" 
                                    class="text-lg font-medium {{ 'line-through text-gray-400' if note.status == 'completed' else 'text-gray-800 dark:text-white' }}"
                                >
                                    {{ note.content }}
                                </span>
                            </div>
                            
                            <!-- Edit Form (hidden) -->
                            <div id="edit-{{ note.id }}" style="display: none;" class="mb-2">
                                <input 
                                    type="text" 
                                    id="edit-input-{{ note.id }}" 
                                    value="{{ note.content }}" 
                                    class="w-full p-2 border-2 border-purple-300 dark:border-purple-600 dark:bg-slate-700 dark:text-white rounded-lg"
                                    onkeypress="handleKeyPress({{ note.id }}, event)"
                                >
                            </div>

                            <!-- Metadata -->
                            <div class="flex flex-wrap items-center gap-3 text-sm text-gray-500 dark:text-gray-400">
                                {% if note.timestamp %}
                                    <span class="flex items-center gap-1">
                                        <i class="far fa-clock"></i>
                                        {{ note.timestamp }}
                                    </span>
                                {% endif %}
                                
                                {% if note.due_date and note.due_date != '-' %}
                                    <span class="flex items-center gap-1 bg-orange-100 dark:bg-orange-900 text-orange-800 dark:text-orange-200 px-2 py-1 rounded-md">
                                        <i class="fas fa-calendar-alt"></i>
                                        Vence: {{ note.due_date }}
                                    </span>
                                {% endif %}
                                
                                {% if note.tags %}
                                    <div class="flex flex-wrap gap-2">
                                        {% for tag in note.tags %}
                                            <span class="bg-purple-100 dark:bg-purple-900 text-purple-800 dark:text-purple-200 px-3 py-1 rounded-full text-xs font-medium">
                                                #{{ tag }}
                                            </span>
                                        {% endfor %}
                                    </div>
                                {% endif %}
                            </div>
                        </div>

                        <!-- Actions -->
                        <div class="flex gap-2 flex-shrink-0">
                            <button 
                                onclick="toggleEdit({{ note.id }})" 
                                class="text-blue-500 hover:text-blue-700 hover:bg-blue-50 dark:hover:bg-blue-900 p-2 rounded-lg transition-colors" 
                                title="Editar"
                            >
                                <i class="fas fa-edit text-lg"></i>
                            </button>
                            <button 
                                onclick="deleteTask({{ note.id }}, '{{ note.content[:30] }}')" 
                                class="text-red-500 hover:text-red-700 hover:bg-red-50 dark:hover:bg-red-900 p-2 rounded-lg transition-colors" 
                                title="Deletar"
                            >
                                <i class="fas fa-trash text-lg"></i>
                            </button>
                        </div>
                    </div>
                </div>
                {% endfor %}
            {% else %}
                <div class="text-center py-16 text-gray-400">
                    <i class="fas fa-inbox text-6xl mb-4"></i>
                    <p class="text-xl">Nenhuma tarefa ainda</p>
                    <p class="text-sm mt-2">Adicione sua primeira tarefa acima!</p>
                </div>
            {% endif %}
        </div>

        <!-- Footer -->
        <footer class="text-center mt-12 text-gray-600 dark:text-gray-400 text-sm">
            <p>Clilog Web v2.0 | 
               <a href="/export" class="text-purple-600 hover:text-purple-800 dark:text-purple-400">Exportar</a> | 
               <a href="/api/notes" class="text-purple-600 hover:text-purple-800 dark:text-purple-400">API</a>
            </p>
        </footer>
    </div>

    <!-- Toast Container -->
    <div id="toastContainer" class="fixed bottom-4 right-4 space-y-2 z-50"></div>

    <script>
        // Atalhos de teclado
        document.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'n') {
                e.preventDefault();
                document.getElementById('taskInput').focus();
            }
        });

        // Dark Mode
        function toggleDarkMode() {
            document.documentElement.classList.toggle('dark');
            const icon = document.querySelector('.fa-moon');
            icon.classList.toggle('fa-moon');
            icon.classList.toggle('fa-sun');
        }

        // Add Task (AJAX)
        document.getElementById('addTaskForm').addEventListener('submit', async (e) => {
            e.preventDefault();
            const input = document.getElementById('taskInput');
            const text = input.value.trim();
            
            if (!text) return;

            const response = await fetch('/add', {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `text=${encodeURIComponent(text)}`
            });

            if (response.ok) {
                input.value = '';
                location.reload();
                showToast('Tarefa adicionada!', 'success');
            }
        });

        // Toggle Status (AJAX)
        async function toggleStatus(id, currentStatus) {
            const endpoint = currentStatus === 'completed' ? '/undo' : '/done';
            const response = await fetch(`${endpoint}/${id}`);
            
            if (response.ok) {
                location.reload();
                showToast(currentStatus === 'completed' ? 'Tarefa reaberta!' : 'Tarefa concluída!', 'success');
            }
        }

        // Delete Task
        async function deleteTask(id, content) {
            if (!confirm(`Deletar: "${content}..."?`)) return;
            
            const taskElement = document.querySelector(`[data-id="${id}"]`);
            taskElement.classList.add('task-removing');
            
            setTimeout(async () => {
                const response = await fetch(`/delete/${id}`);
                if (response.ok) {
                    taskElement.remove();
                    showToast('Tarefa deletada!', 'error');
                }
            }, 300);
        }

        // Edit Functions
        function toggleEdit(id) {
            const display = document.getElementById(`content-${id}`);
            const edit = document.getElementById(`edit-${id}`);
            
            if (display.style.display !== 'none') {
                display.style.display = 'none';
                edit.style.display = 'block';
                document.getElementById(`edit-input-${id}`).focus();
            } else {
                display.style.display = 'inline';
                edit.style.display = 'none';
            }
        }

        async function saveEdit(id) {
            const input = document.getElementById(`edit-input-${id}`);
            const newContent = input.value.trim();
            
            if (!newContent) return;

            const response = await fetch(`/edit/${id}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
                body: `content=${encodeURIComponent(newContent)}`
            });

            if (response.ok) {
                location.reload();
                showToast('Tarefa editada!', 'success');
            }
        }

        function handleKeyPress(id, event) {
            if (event.key === 'Enter') {
                saveEdit(id);
            } else if (event.key === 'Escape') {
                toggleEdit(id);
            }
        }

        // Filter
        function filterNotes() {
            const filter = document.getElementById('statusFilter').value;
            const search = document.getElementById('searchInput').value.toLowerCase();
            
            document.querySelectorAll('.note-item').forEach(note => {
                const status = note.getAttribute('data-status');
                const content = note.textContent.toLowerCase();
                
                const statusMatch = filter === 'all' || status === filter;
                const searchMatch = content.includes(search);
                
                note.style.display = statusMatch && searchMatch ? 'block' : 'none';
            });
        }

        // Toast Notifications
        function showToast(message, type = 'success') {
            const toast = document.createElement('div');
            const colors = {
                success: 'bg-green-500',
                error: 'bg-red-500',
                info: 'bg-blue-500'
            };
            
            toast.className = `toast ${colors[type]} text-white px-6 py-3 rounded-lg shadow-lg flex items-center gap-2`;
            toast.innerHTML = `
                <i class="fas fa-${type === 'success' ? 'check' : type === 'error' ? 'times' : 'info'}-circle"></i>
                <span>${message}</span>
            `;
            
            document.getElementById('toastContainer').appendChild(toast);
            
            setTimeout(() => {
                toast.style.opacity = '0';
                toast.style.transform = 'translateX(100px)';
                setTimeout(() => toast.remove(), 300);
            }, 3000);
        }
    </script>
</body>
</html>
'''

@app.route("/")
def index():
    notes = get_notes()
    stats = {
        'total': len(notes),
        'completed': len([n for n in notes if n['status'] == 'completed']),
        'pending': len([n for n in notes if n['status'] == 'pending'])
    }
    return render_template_string(HTML_TEMPLATE, notes=notes, stats=stats)

@app.route("/add", methods=["POST"])
def add_note():
    text = request.form.get("text", "").strip()
    if text:
        add_note_to_file(text)
        flash("Tarefa adicionada!", "success")
    return redirect("/")

@app.route("/done/<int:note_id>")
def mark_done(note_id):
    update_note_in_file(note_id, get_note_content(note_id), "completed")
    return redirect("/")

@app.route("/undo/<int:note_id>")
def mark_undo(note_id):
    update_note_in_file(note_id, get_note_content(note_id), "pending")
    return redirect("/")

@app.route("/delete/<int:note_id>")
def delete_note(note_id):
    delete_note_from_file(note_id)
    return redirect("/")

@app.route("/edit/<int:note_id>", methods=["POST"])
def edit_note(note_id):
    new_content = request.form.get("content", "").strip()
    if new_content:
        update_note_in_file(note_id, new_content)
        return jsonify({"success": True})
    return jsonify({"success": False})

@app.route("/export")
def export_notes():
    notes = get_notes()
    return jsonify({
        "export_date": datetime.now().isoformat(),
        "total_notes": len(notes),
        "notes": notes
    })

@app.route("/api/notes")
def api_notes():
    return jsonify(get_notes())

def get_note_content(note_id):
    notes = get_notes()
    for note in notes:
        if note['id'] == note_id:
            return note['content']
    return ""

if __name__ == "__main__":
    os.makedirs(os.path.dirname(NOTES_FILE), exist_ok=True)
    print("🚀 Clilog Web v2.0 - Modern Interface")
    print(f"📁 Notes: {NOTES_FILE}")
    print("🌐 Access: http://localhost:5000")
    app.run(debug=True, host='0.0.0.0', port=5000)
