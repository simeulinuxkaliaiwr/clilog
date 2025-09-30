#!/usr/bin/env python3

import sqlite3
import re
import os
import sys

CLILOG_DIR = os.environ.get('CLILOG_DIR', os.path.expanduser('~/.clilog'))
DB_PATH = os.path.join(CLILOG_DIR, 'clilog.db')
LOG_PATH = os.path.join(CLILOG_DIR, 'notes.log')

LINE_PATTERN = re.compile(r'\[(.)\] (.*) @(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{4})')
TAG_PATTERN = re.compile(r'#(\w+)')
DUE_PATTERN = re.compile(r'\[DUE:(\d{4}-\d{2}-\d{2})\]')

def init_db():
    """Cria a tabela de notas se ela não existir. Chamado pelo install.sh."""
    try:
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS notes (
                id INTEGER PRIMARY KEY,   -- O número da linha do notes.log
                status TEXT,              -- [ ] ou [X]
                text TEXT,                -- Texto limpo da nota
                tags TEXT,                -- Tags separadas por vírgula
                due_date TEXT,            -- Prazo YYYY-MM-DD
                timestamp TEXT            -- Timestamp de criação
            )
        """)
        conn.commit()
        conn.close()
    except Exception as e:
        print(f"Erro ao inicializar DB: {e}", file=sys.stderr)

def sync_all_data():
    """Sincroniza o log completo para o banco de dados. Chamado pelo Bash."""
    try:
        init_db()
        conn = sqlite3.connect(DB_PATH)
        cursor = conn.cursor()
        
        cursor.execute("DELETE FROM notes")
        
        with open(LOG_PATH, 'r') as f:
            for i, line in enumerate(f):
                match = LINE_PATTERN.search(line)
                if not match: continue

                status = match.group(1).strip()
                content_part = match.group(2).strip()
                timestamp = match.group(3).strip()

                tags = ','.join(TAG_PATTERN.findall(content_part))
                content_part = TAG_PATTERN.sub('', content_part).strip()

                due_match = DUE_PATTERN.search(content_part)
                due_date = due_match.group(1) if due_match else ''
                content_part = DUE_PATTERN.sub('', content_part).strip()

                note_text = content_part

                cursor.execute("""
                    INSERT INTO notes VALUES (?, ?, ?, ?, ?, ?)
                """, (i + 1, status, note_text, tags, due_date, timestamp))
                
        conn.commit()
        conn.close()
    except Exception as e:
        pass 

if __name__ == "__main__":
    if len(sys.argv) > 1:
        if sys.argv[1] == 'init_db':
            init_db()
        elif sys.argv[1] == 'sync_all_data':
            sync_all_data()
