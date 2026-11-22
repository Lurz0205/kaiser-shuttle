import json

with open('C:/Users/sieut/.gemini/antigravity/brain/1c65eb4a-1be9-4d1b-977b-b853216b922a/.system_generated/logs/transcript.jsonl', 'r', encoding='utf-8') as f:
    for line in f:
        obj = json.loads(line)
        if obj.get('source') == 'USER_EXPLICIT':
            txt = obj.get('content', '')
            if any(w in txt.lower() for w in ['tốc độ', 'chậm', 'nhanh', 'bay', 'tuning']):
                print(f"--- Step {obj.get('step_index')} ---")
                print(txt[:300])
