#!/usr/bin/env python3
from flask import Flask, render_template_string, request, redirect, flash, jsonify
import os
import re
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'clilog_web_secret_key_2024'

NOTES_FILE = os.path.expanduser("~/.config/clilog/notes.log")

def get_notes():
    """Carrega todas as notas do arquivo"""
    if not os.path.exists(NOTES_FILE):
        return []
    
    notes = []
    with open(NOTES_FILE, 'r', encoding='utf-8') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
                
            status = "completed" if line.startswith("[X]") else "pending"
            
            # Extrai timestamp
            timestamp_match = re.search(r'\((\d{4}-\d{2}-\d{2} \d{2}:\d{2})\)', line)
            timestamp = timestamp_match.group(1) if timestamp_match else ""
            
            content = re.sub(r'^\[X\] |^\[ \] ', '', line)
            if timestamp_match:
                content = content.replace(timestamp_match.group(0), '').strip()
            
            TAG_PATTERN = re.compile(r'#(\w+)')
            tags = TAG_PATTERN.findall(content)
            content_without_tags = TAG_PATTERN.sub('', content).strip() 
            notes.append({
                'id': line_num,
                'status': status,
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
            current_status = "[X]" if status == "completed" else ("[ ]" if status else note['status'])
            current_timestamp = note['timestamp']
            
            status_prefix = "[X]" if status == "completed" else ("[ ]" if status else ("[X]" if note['status'] == "completed" else "[ ]"))
            timestamp_str = f"({current_timestamp})" if current_timestamp else f"({datetime.now().strftime('%Y-%m-%d %H:%M')})"
            tags_str = " " + " ".join(f"#{tag}" for tag in note['tags']) if note['tags'] else ""
            
            new_raw = f"{status_prefix} {timestamp_str} {new_content}{tags_str}"
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
    new_line = f"[ ] ({timestamp}) {content}{tags_str}"
    
    with open(NOTES_FILE, 'a', encoding='utf-8') as f:
        f.write(new_line + '\n')

def delete_note_from_file(note_id):
    """Dele a note from the file"""
    notes = get_notes()
    notes = [note for note in notes if note['id'] != note_id]
    
    with open(NOTES_FILE, 'w', encoding='utf-8') as f:
        for note in notes:
            f.write(note['raw'] + '\n')

# Template HTML com Tailwind CSS
HTML_TEMPLATE = '''
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Clilog Web Interface</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <script>
        function confirmDelete(id, content) {
            if (confirm(`Are you sure you want to delete the note?: "${content.substring(0, 50)}..."?`)) {
                window.location.href = `/delete/${id}`;
            }
        }
        
        function toggleEdit(id) {
            const displaySpan = document.getElementById(`content-${id}`);
            const editDiv = document.getElementById(`edit-${id}`);
            
            if (displaySpan.style.display !== 'none') {
                displaySpan.style.display = 'none';
                editDiv.style.display = 'block';
                document.getElementById(`edit-input-${id}`).focus();
            } else {
                displaySpan.style.display = 'inline';
                editDiv.style.display = 'none';
            }
        }
        
        function saveEdit(id) {
            const input = document.getElementById(`edit-input-${id}`);
            const newContent = input.value.trim();
            
            if (newContent) {
                fetch(`/edit/${id}`, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: `content=${encodeURIComponent(newContent)}`
                }).then(response => {
                    if (response.ok) {
                        location.reload();
                    }
                });
            }
        }
        
        function handleKeyPress(id, event) {
            if (event.key === 'Enter') {
                saveEdit(id);
            } else if (event.key === 'Escape') {
                toggleEdit(id);
            }
        }
        
        function filterNotes() {
            const filter = document.getElementById('statusFilter').value;
            const search = document.getElementById('searchInput').value.toLowerCase();
            
            const notes = document.querySelectorAll('.note-item');
            notes.forEach(note => {
                const status = note.getAttribute('data-status');
                const content = note.textContent.toLowerCase();
                
                const statusMatch = filter === 'all' || 
                                  (filter === 'completed' && status === 'completed') ||
                                  (filter === 'pending' && status === 'pending');
                
                const searchMatch = content.includes(search);
                
                note.style.display = statusMatch && searchMatch ? 'flex' : 'none';
            });
        }
    </script>
</head>
<body class="bg-gray-50 min-h-screen">
    <div class="container mx-auto px-4 py-8 max-w-4xl">
        <!-- Header -->
        <header class="text-center mb-8">
            <h1 class="text-4xl font-bold text-gray-800 mb-2">
                <i class="fas fa-tasks text-blue-500 mr-2"></i>Clilog Web
            </h1>
            <p class="text-gray-600">manage your tasks directly from the browser</p>
        </header>

        <!-- Stats -->
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div class="bg-white rounded-lg shadow p-4 text-center">
                <div class="text-2xl font-bold text-blue-600">{{ stats.total }}</div>
                <div class="text-gray-600">Total</div>
            </div>
            <div class="bg-white rounded-lg shadow p-4 text-center">
                <div class="text-2xl font-bold text-green-600">{{ stats.completed }}</div>
                <div class="text-gray-600">Completed</div>
            </div>
            <div class="bg-white rounded-lg shadow p-4 text-center">
                <div class="text-2xl font-bold text-orange-600">{{ stats.pending }}</div>
                <div class="text-gray-600">Pending</div>
            </div>
        </div>

        <!-- Filters and Search -->
        <div class="bg-white rounded-lg shadow p-4 mb-6">
            <div class="flex flex-col md:flex-row gap-4">
                <div class="flex-1">
                    <input type="text" id="searchInput" placeholder="Search notes..." 
                           class="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
                           onkeyup="filterNotes()">
                </div>
                <div>
                    <select id="statusFilter" onchange="filterNotes()" 
                            class="w-full p-2 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500">
                        <option value="All">All</option>
                        <option value="Pending">Pending</option>
                        <option value="Completed">Completed</option>
                    </select>
                </div>
            </div>
        </div>

        <!-- Add Note Form -->
        <div class="bg-white rounded-lg shadow p-4 mb-6">
            <form method="post" action="/add" class="flex flex-col md:flex-row gap-2">
                <input name="text" required 
                       class="flex-1 p-3 border border-gray-300 rounded focus:outline-none focus:ring-2 focus:ring-blue-500" 
                       placeholder="Add a new note/task...">
                <button type="submit" class="bg-blue-500 hover:bg-blue-600 text-white font-semibold py-3 px-6 rounded transition duration-200">
                    <i class="fas fa-plus mr-2"></i>Add
                </button>
            </form>
        </div>

        <!-- Notes List -->
        <div class="bg-white rounded-lg shadow overflow-hidden">
            {% if notes %}
                <ul>
                    {% for note in notes %}
                    <li class="note-item border-b border-gray-200 last:border-b-0 p-4 hover:bg-gray-50 flex justify-between items-start"
                        data-status="{{ note.status }}">
                        <div class="flex-1">
                            <div class="flex items-center mb-1">
                                <!-- Status Indicator -->
                                {% if note.status == 'completed' %}
                                    <span class="text-green-500 mr-2"><i class="fas fa-check-circle"></i></span>
                                {% else %}
                                    <span class="text-orange-500 mr-2"><i class="far fa-circle"></i></span>
                                {% endif %}
                                
                                <!-- Note Content -->
                                <span id="content-{{ note.id }}" class="{{ 'line-through text-gray-500' if note.status == 'completed' else 'text-gray-800' }}">
                                    {{ note.content }}
                                </span>
                                
                                <!-- Edit Form (hidden by default) -->
                                <div id="edit-{{ note.id }}" style="display: none;" class="flex-1">
                                    <div class="flex gap-2">
                                        <input type="text" id="edit-input-{{ note.id }}" value="{{ note.content }}" 
                                               class="flex-1 p-1 border border-gray-300 rounded"
                                               onkeypress="handleKeyPress({{ note.id }}, event)">
                                        <button onclick="saveEdit({{ note.id }})" class="bg-green-500 text-white px-3 py-1 rounded text-sm">
                                            <i class="fas fa-check"></i>
                                        </button>
                                        <button onclick="toggleEdit({{ note.id }})" class="bg-gray-500 text-white px-3 py-1 rounded text-sm">
                                            <i class="fas fa-times"></i>
                                        </button>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Metadata -->
                            <div class="text-sm text-gray-500 ml-6">
                                {% if note.timestamp %}
                                    <span><i class="far fa-clock mr-1"></i>{{ note.timestamp }}</span>
                                {% endif %}
                                
                                {% if note.tags %}
                                    <span class="ml-3">
                                        <i class="fas fa-tags mr-1"></i>
                                        {% for tag in note.tags %}
                                            <span class="bg-blue-100 text-blue-800 px-2 py-0.5 rounded text-xs mr-1">#{{ tag }}</span>
                                        {% endfor %}
                                    </span>
                                {% endif %}
                            </div>
                        </div>
                        
                        <!-- Actions -->
                        <div class="flex gap-2 ml-4">
                            <!-- Toggle Status -->
                            {% if note.status == 'completed' %}
                                <a href="/undo/{{ note.id }}" class="text-orange-500 hover:text-orange-700" title="Unmark a note">
                                    <i class="fas fa-undo"></i>
                                </a>
                            {% else %}
                                <a href="/done/{{ note.id }}" class="text-green-500 hover:text-green-700" title="Mark a note as completed">
                                    <i class="fas fa-check"></i>
                                </a>
                            {% endif %}
                            
                            <!-- Edit -->
                            <button onclick="toggleEdit({{ note.id }})" class="text-blue-500 hover:text-blue-700" title="Edit">
                                <i class="fas fa-edit"></i>
                            </button>
                            
                            <!-- Delete -->
                            <button onclick="confirmDelete({{ note.id }}, '{{ note.content }}')" class="text-red-500 hover:text-red-700" title="Delete">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    </li>
                    {% endfor %}
                </ul>
            {% else %}
                <div class="text-center py-12 text-gray-500">
                    <i class="fas fa-inbox text-4xl mb-4"></i>
                    <p>No notes found.</p>
                    <p class="text-sm">Add your first note above!</p>
                </div>
            {% endif %}
        </div>

        <!-- Footer -->
        <footer class="text-center mt-8 text-gray-600 text-sm">
            <p>Clilog Web &copy; 2025 | 
               <a href="/export" class="text-blue-500 hover:text-blue-700">Export notes</a> | 
               <a href="/api/notes" class="text-blue-500 hover:text-blue-700">API JSON</a>
            </p>
        </footer>
    </div>

    <!-- Flash Messages -->
    {% with messages = get_flashed_messages(with_categories=true) %}
        {% if messages %}
            <div class="fixed bottom-4 right-4 space-y-2">
                {% for category, message in messages %}
                    <div class="bg-{{ 'green' if category == 'success' else 'red' }}-500 text-white px-6 py-3 rounded-lg shadow-lg">
                        {{ message }}
                    </div>
                {% endfor %}
            </div>
            
            <script>
                setTimeout(() => {
                    const messages = document.querySelectorAll('.fixed > div');
                    messages.forEach(msg => {
                        msg.style.opacity = '0';
                        msg.style.transition = 'opacity 0.5s';
                        setTimeout(() => msg.remove(), 500);
                    });
                }, 5000);
            </script>
        {% endif %}
    {% endwith %}
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
    """ Add a new note """
    text = request.form.get("text", "").strip()
    if text:
        add_note_to_file(text)
        flash("Added note successfully!", "success")
    else:
        flash("Erro: Note content cannot be empty.", "error")
    
    return redirect("/")

@app.route("/done/<int:note_id>")
def mark_done(note_id):
    update_note_in_file(note_id, get_note_content(note_id), "completed")
    flash("Note marked as completed!", "success")
    return redirect("/")

@app.route("/undo/<int:note_id>")
def mark_undo(note_id):
    """Marca uma nota como pendente"""
    update_note_in_file(note_id, get_note_content(note_id), "pending")
    flash("Note returned to pending!", "success")
    return redirect("/")

@app.route("/delete/<int:note_id>")
def delete_note(note_id):
    delete_note_from_file(note_id)
    flash("Note deleted successfully!", "success")
    return redirect("/")

@app.route("/edit/<int:note_id>", methods=["POST"])
def edit_note(note_id):
    new_content = request.form.get("content", "").strip()
    if new_content:
        update_note_in_file(note_id, new_content)
        return jsonify({"success": True})
    return jsonify({"success": False, "error": "Content empty."})

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
    
    print("Clilog web interface starting...")
    print(f"Notes archive:: {NOTES_FILE}")
    print("Access: http://localhost:5000")
    
    app.run(debug=True, host='127.0.0.1', port=5000)
