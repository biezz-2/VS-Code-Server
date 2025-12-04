# 🚀 VSCode Server Deploy (Microsoft Marketplace & Original Build)

**By biezz-2**

Repositori ini berisi dua opsi instalasi VS Code Server dengan dukungan penuh Microsoft Marketplace untuk extensions resmi. 

#### 📥 Download Repository
```sh
git clone https://github.com/biezz-2/vscode-server-deploy.git
cd vscode-server-deploy
```

---

## 🎯 **Pool Analysis: Perbandingan Kedua Instalasi**

| Aspek | Script 1 (Marketplace) | Script 2 (Original Build) |
|:------|:----------------------|:--------------------------|
| **Waktu Instalasi** | ⚡ 5-10 menit | 🐢 30-60 menit |
| **Microsoft Marketplace** | ✅ Penuh | ✅ Penuh |
| **Build dari Source** | ❌ Tidak | ✅ Ya (100% Original) |
| **Penggunaan Resource** | 💚 Ringan | 🟠 Lebih Berat (4GB+ RAM) |
| **Stabilitas** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Extension Official** | ✅ Pylance, Azure, C#, dll | ✅ Pylance, Azure, C#, dll |
| **Rekomendasi Untuk** | 🎯 Production/Fast Deploy | 🎯 Development/Custom Build |

**📊 Analisa Pool:**
- Untuk **deployment cepat & production**, gunakan **Script 1** (Recommended)
- Untuk **development custom** atau ingin **build 100% dari source Microsoft**, gunakan **Script 2**

---

## 📥 **Unduh dan Instalasi**

### **Script 1: Code Server dengan Microsoft Marketplace (RECOMMENDED)**

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/biezz-2/VS-Code-Server/refs/heads/main/official-vscode-server.sh)"

```
http://YOUR_IP:8680
```

---

### **Script 2: VSCode Server Build Original dari Microsoft**

```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/biezz-2/VS-Code-Server/refs/heads/main/unofficial-vscode-server.sh)"

```

**Akses setelah instalasi:**
```
http://YOUR_IP:8680
```

---

## ⭐ **Fitur Utama**

✅ **Microsoft Visual Studio Marketplace Penuh**
- Install Pylance, C#, Azure Tools, GitHub Copilot, dan lebih banyak lagi
- Extension resmi dari Microsoft, bukan alternatif

✅ **No Authentication by Default**
- Aksesibel langsung dari browser
- Bisa diubah ke mode password jika diperlukan

✅ **Accessible from Network**
- Bisa diakses dari device manapun di jaringan yang sama

✅ **Service Management**
- Systemd integration untuk auto-start & restart otomatis

---

## 🔧 **Manajemen Service**

Setelah instalasi berhasil, gunakan command berikut:

```sh
# Script 1 (Code-Server)
systemctl start code-server@$USER
systemctl stop code-server@$USER
systemctl restart code-server@$USER
systemctl status code-server@$USER
journalctl -u code-server@$USER -f

# Script 2 (VSCode Server)
systemctl start vscode-server
systemctl stop vscode-server
systemctl restart vscode-server
systemctl status vscode-server
```

---

## 🔐 **Keamanan & Konfigurasi**

### Mengaktifkan Password Authentication

Edit file konfigurasi:

**Untuk Script 1:**
```sh
nano ~/. config/code-server/config. yaml
```

Ubah bagian:
```yaml
auth: password
password: your_secure_password_here
```

Restart service:
```sh
systemctl restart code-server@$USER
```

---

## 📂 **File dan Struktur Repository**

```
vscode-server-deploy/
├── install-code-server-microsoft-marketplace. sh
├── install-vscode-server-original.sh
├── VSCODE-SERVER-README.md (dokumentasi lengkap)
├── README.md (file ini)
└── LICENSE (MIT)
```

---

## 📊 **Apa Saja yang Diinstal?**

### Script 1 menginstal:
- Code-Server versi terbaru
- Microsoft Marketplace integration
- Systemd service untuk management
- Configuration files untuk VS Code

### Script 2 menginstal:
- Node.js & Yarn
- VS Code dari repository Microsoft (original)
- Build dari source untuk web version
- Systemd service untuk management
- Microsoft Marketplace integration

---

## 🛠️ **Troubleshooting**

### Service tidak start? 
```sh
# Cek status
systemctl status code-server@$USER

# Lihat logs
journalctl -u code-server@$USER -n 50

# Cek port apakah sudah terpakai
netstat -tulpn | grep 8680
```

### Extension tidak bisa diinstall?
- Pastikan server terhubung internet
- Cek Microsoft Marketplace bisa diakses
- Restart service dan coba lagi

### Lupa password?
Edit config file dan ubah `auth: none` untuk disable password sementara

---

## 🚀 **Quick Start dengan Satu Baris (Script 1)**

```sh
git clone https://github.com/biezz-2/vscode-server-deploy.git && cd vscode-server-deploy && chmod +x install-code-server-microsoft-marketplace.sh && ./install-code-server-microsoft-marketplace.sh
```

---

## 📚 **Dokumentasi Lengkap**

Untuk dokumentasi detail tentang instalasi, konfigurasi, security recommendations, dan advanced settings, baca:
- **[VSCODE-SERVER-README. md](./VSCODE-SERVER-README.md)**

---

## 🔗 **Referensi & Sumber**

- [Visual Studio Code Marketplace](https://marketplace.visualstudio.com/)
- [Microsoft VS Code Repository](https://github.com/microsoft/vscode)
- [Code-Server by Coder](https://github.com/coder/code-server)

---

## 📝 **License**

MIT License - Gratis untuk digunakan dan dimodifikasi

---

## 💬 **Kontribusi & Dukungan**

Jika ada pertanyaan, saran, atau ingin berkontribusi:
1.  Buka **[Issues](https://github.com/biezz-2/vscode-server-deploy/issues)**
2. Atau kirim Pull Request dengan improvement Anda

---

**Created by:** [@biezz-2](https://github.com/biezz-2)  
**Last Updated:** 2025-12-04
