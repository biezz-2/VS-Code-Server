# 📘 VSCODE SERVER - Dokumentasi Lengkap

## Daftar Isi
1. [Pendahuluan](#pendahuluan)
2. [Persiapan Sistem](#persiapan-sistem)
3. [Instalasi Detail](#instalasi-detail)
4. [Konfigurasi](#konfigurasi)
5.  [Security](#security)
6. [Troubleshooting](#troubleshooting)

---

## Pendahuluan

Repositori ini menyediakan dua cara untuk instalasi VS Code Server dengan dukungan penuh Microsoft Extensions Marketplace. 

### Persyaratan Sistem

**Minimum:**
- OS: Ubuntu 18.04+, Debian 10+, atau Linux lainnya
- RAM: 1GB (Script 1), 4GB (Script 2)
- Disk: 2GB free space (Script 1), 5GB+ (Script 2)
- CPU: Dual-core processor

---

## Persiapan Sistem

### Update System
```bash
sudo apt-get update
sudo apt-get upgrade -y
```

### Cek Versi
```bash
lsb_release -a
uname -a
```

---

## Instalasi Detail

### Script 1: Code-Server dengan Microsoft Marketplace

**Keuntungan:**
- Instalasi paling cepat (5-10 menit)
- Resource usage minimal
- Sangat stabil untuk production
- Support penuh Microsoft Extensions

**Langkah Instalasi:**

1. **Download Script**
```bash
git clone https://github.com/biezz-2/vscode-server-deploy.git
cd vscode-server-deploy
```

2. **Jalankan Installer**
```bash
chmod +x install-code-server-microsoft-marketplace.sh
./install-code-server-microsoft-marketplace.sh
```

3. **Konfirmasi Instalasi**
Jawab `y` ketika diminta

4. **Tunggu proses selesai**
Akan menampilkan IP address untuk akses

---

### Script 2: VS Code Server Original Build

**Keuntungan:**
- Build 100% dari source Microsoft
- Lebih customizable
- Includes semua features terbaru VS Code

**Persyaratan Tambahan:**
- Build tools (gcc, make, dll)
- Node.js & Yarn
- Minimal 4GB RAM
- 30-60 menit untuk build

**Langkah Instalasi:**

1. **Download Script**
```bash
git clone https://github.com/biezz-2/vscode-server-deploy.git
cd vscode-server-deploy
```

2.  **Jalankan Installer**
```bash
chmod +x install-vscode-server-original. sh
./install-vscode-server-original.sh
```

3. **Tunggu Build Process**
Ini memakan waktu 30-60 menit tergantung spesifikasi server

4. **Selesai! **
Akan menampilkan URL akses

---

## Konfigurasi

### Mengubah Port

**Script 1:**
```bash
# Edit config
nano ~/.config/code-server/config.yaml

# Ubah bind-addr
bind-addr: 0. 0.0.0:9000  # Ganti 8680 dengan port yang diinginkan

# Restart
systemctl restart code-server@$USER
```

### Mengaktifkan Password

**Script 1:**
```bash
nano ~/.config/code-server/config.yaml

# Ubah menjadi:
auth: password
password: your_password_123

# Restart
systemctl restart code-server@$USER
```

### Settings VS Code

File: `~/.local/share/code-server/User/settings.json`

Contoh konfigurasi:
```json
{
  "telemetry. telemetryLevel": "off",
  "update.mode": "none",
  "extensions.autoUpdate": true,
  "workbench.colorTheme": "Default Dark+",
  "editor.fontSize": 14,
  "editor.tabSize": 2,
  "editor.formatOnSave": true
}
```

---

## Security

### 1. Aktivkan Password

Sangat direkomendasikan untuk production:
```bash
# Script 1
nano ~/.config/code-server/config.yaml
# Set: auth: password
# Set: password: your_secure_password

systemctl restart code-server@$USER
```

### 2.  Restrict Akses dengan Firewall

```bash
# Allow hanya dari IP tertentu
sudo ufw allow from 192.168.1.0/24 to any port 8680

# Atau allow dari IP spesifik
sudo ufw allow from 192.168.1.100 to any port 8680
```

### 3. Gunakan HTTPS/SSL

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /path/to/key.pem -out /path/to/cert.pem

# Edit config
nano ~/.config/code-server/config.yaml

# Tambahkan:
cert: /path/to/cert.pem
cert-key: /path/to/key.pem

# Restart
systemctl restart code-server@$USER
```

### 4. Reverse Proxy dengan Nginx (Optional)

```bash
# Install Nginx
sudo apt-get install nginx -y

# Create config
sudo nano /etc/nginx/sites-available/vscode
```

```nginx
server {
    listen 80;
    server_name your. domain.com;

    location / {
        proxy_pass http://localhost:8680;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
    }
}
```

```bash
# Enable config
sudo ln -s /etc/nginx/sites-available/vscode /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

---

## Troubleshooting

### Error: "Permission denied"
```bash
chmod +x install-code-server-microsoft-marketplace.sh
chmod +x install-vscode-server-original.sh
```

### Error: "Command not found"
```bash
# Pastikan di folder yang benar
pwd
ls -la

# Atau gunakan absolute path
/path/to/install-code-server-microsoft-marketplace.sh
```

### Service tidak start
```bash
# Cek status
systemctl status code-server@$USER

# Lihat logs
journalctl -u code-server@$USER -n 100 -e

# Manual start untuk debug
code-server --bind-addr 0.0.0. 0:8680
```

### Port 8680 sudah terpakai
```bash
# Cek siapa yang pakai port
sudo lsof -i :8680
sudo netstat -tulpn | grep 8680

# Kill process (jika perlu)
sudo kill -9 <PID>

# Atau ubah port di config
nano ~/.config/code-server/config.yaml
# Ubah bind-addr ke port lain
```

### Tidak bisa akses dari remote
```bash
# Cek apakah service running
systemctl status code-server@$USER

# Cek firewall
sudo ufw status
sudo ufw allow 8680

# Cek IP address server
hostname -I

# Test connection dari local
curl http://localhost:8680
```

### Extension tidak install
```bash
# Restart service
systemctl restart code-server@$USER

# Clear cache
rm -rf ~/.local/share/code-server/extensions/. cache

# Cek internet connection
curl https://marketplace.visualstudio.com

# Lihat logs
journalctl -u code-server@$USER -f
```

---

## Advanced Tips

### Auto-start pada Boot
Sudah auto-enabled oleh installer.  Cek dengan:
```bash
systemctl is-enabled code-server@$USER
```

### Backup Configuration
```bash
# Backup
tar -czf code-server-backup.tar.gz ~/.config/code-server ~/. local/share/code-server

# Restore
tar -xzf code-server-backup.tar.gz -C ~/
```

### Update Extensions
```bash
# Extensions otomatis update jika diset di settings. json
# Atau install extension tertentu via CLI
code-server --install-extension ms-python.python
code-server --install-extension ms-vscode.cpptools
```

---

## FAQ

**Q: Bisakah 2 user menggunakan service ini?**
A: Ya, setiap user punya servicenya sendiri:
```bash
systemctl start code-server@username1
systemctl start code-server@username2
```

**Q: Bagaimana update VS Code Server?**
A: Installer akan fetch versi terbaru otomatis saat dijalankan. 

**Q: Berapa banyak extension yang bisa diinstall?**
A: Tidak ada limit, tergantung disk space. 

---

## Support & Kontribusi

Issues dan suggestions: https://github.com/biezz-2/vscode-server-deploy/issues

---

