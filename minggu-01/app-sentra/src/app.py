"""Aplikasi studi kasus PT Sentra Digital Batam.

Tidak ada konfigurasi yang "hidup di kepala developer":
  - PORT dibaca dari environment (default 5000)
  - BUILD_ID dibaca dari environment (disuntikkan pipeline/setup.sh)
  - Dependensi dikunci di requirements.txt

Tujuan praktikum: membuktikan bahwa aplikasi yang sama bisa dijalankan
di mesin Dev dan mesin Ops *tanpa* instruksi manual, asalkan lingkungannya
didefinisikan sebagai kode.
"""

from flask import Flask, jsonify
import os, datetime

app = Flask(__name__)

BUILD = os.getenv("BUILD_ID", "dev-local")
PORT = int(os.getenv("PORT", "5000"))


@app.route("/")
def index():
    return jsonify(
        service="sentra-digital-batam",
        status="running",
        build=BUILD,
        time=datetime.datetime.now().isoformat(timespec="seconds"),
    )


@app.route("/health")
def health():
    return jsonify(status="ok"), 200


if __name__ == "__main__":
    # Di-bind ke 127.0.0.1: pada jaringan laboratorium bersama, bind ke
    # 0.0.0.0 akan mengekspos layanan ke seluruh kelas.
    app.run(host="127.0.0.1", port=PORT)
