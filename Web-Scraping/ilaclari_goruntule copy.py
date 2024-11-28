from flask import Flask, render_template, request, jsonify
import json
import os

app = Flask(__name__)

# JSON dosyalarının saklandığı klasör
JSON_FOLDER = "ilaclar"  # JSON dosyalarının bulunduğu klasör

@app.route('/')
def index():
    """JSON dosyalarını listeleyen ana sayfa."""
    files = [f for f in os.listdir(JSON_FOLDER) if f.endswith('.json')]
    return render_template('index.html', files=files)

@app.route('/view/<filename>')
def view_json(filename):
    """Seçilen JSON dosyasındaki HTML içeriğini gösterir."""
    filepath = os.path.join(JSON_FOLDER, filename)
    if not os.path.exists(filepath):
        return "Dosya bulunamadı!", 404

    with open(filepath, 'r', encoding='utf-8') as file:
        data = json.load(file)

    return render_template('view.html', data=data, filename=filename)

if __name__ == '__main__':
    # Sunucuyu çalıştır
    app.run(debug=True)
