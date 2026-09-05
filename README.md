# 🛡️ Obscura – Secure Encrypted Gallery

Obscura is a cross-platform desktop application (macOS & Windows) built with **Flutter** that allows you to securely store, encrypt, and manage your image folders.  
It combines powerful encryption with a simple and intuitive gallery UI — giving you complete control and privacy over your media.

---

## ✨ Features

### 🔐 Security & Privacy
- **Keyed pixel-permutation transform** — the folder key is hashed with SHA-256, and the first 4 bytes seed a Fisher-Yates shuffle of the image's pixel array.
- A **reserved marker pixel at (0,0)** tags an image as transformed, so the app can classify a folder without a database lookup and won't double-encrypt.
- Images are converted to **PNG** before transformation, because the permutation is byte-exact and any lossy re-encode would destroy it.
- Folder passwords are **bcrypt hashed** with a per-password salt (never saved in plain text).
- Viewing decrypts **only in memory** (RAM) — plaintext is never written back to disk.

### 📂 Folder Management
- Import and manage **multiple folders** simultaneously.
- Each folder can have its own encryption type, key, and password.
- Full **macOS secure bookmark** support for persistent folder access.

### 🖼️ Secure Gallery Mode
- Browse and preview encrypted images securely within the app.
- Supported image formats: `.jpg`, `.jpeg`, `.png`, `.gif`, `.webp`, `.bmp`, `.heic`.
- Fast and efficient in-memory decryption.

### ⚙️ Settings & Customization
- Built-in settings page to manage global preferences.
- Easily edit folder properties or remove them without affecting original files.
- Configure default encryption methods and security options.

### 💻 Cross-Platform Support
- Works seamlessly on **macOS (`.dmg`)** and **Windows (`.exe`)**.
- Designed to be distributed as a standalone desktop app.


---

## 🔎 Security model and known limitations

I want to be upfront about what Obscura actually protects against, because the transform it uses is not what most people mean by "encryption".

- **This is a transposition transform, not encryption.** Pixels are reordered, not substituted. The output image's colour histogram is identical to the input's, so it leaks statistical information about the original.
- **The seed is truncated to 32 bits.** However strong the folder key is, the effective key space is capped at roughly 2^32.
- **The folder key is stored in plaintext** in the local SQLite database. The bcrypt password gates the UI, not the data — an attacker with filesystem access can read the key and reverse the transform.
- **The marker pixel overwrites the original pixel at (0,0)**, so that single pixel is not recoverable.
- **Threat model:** this protects against casual browsing of a shared machine. It does not protect against an attacker with disk access or cryptanalytic intent.

### 🧭 Planned rebuild

- Derive an **AES-256** key from the password using **Argon2id** with a per-folder random salt.
- Encrypt file bytes with **AES-GCM** for authenticated encryption.
- Persist only the salt and the nonce — never the key.
- Re-derive the key in memory each session.

---

## 🛠 Tech Stack

- [Flutter](https://flutter.dev/) – Cross-platform UI framework  
- [Sqflite](https://pub.dev/packages/sqflite) – Local SQLite database  
- [macos_secure_bookmarks](https://pub.dev/packages/macos_secure_bookmarks) – Secure persistent folder access (macOS)  
- [bcrypt](https://pub.dev/packages/bcrypt) – Password hashing  
- [Crypto](https://pub.dev/packages/crypto) – Encryption utilities

---

## 🚀 Getting Started

### 📦 Prerequisites

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.x)
- Dart (comes with Flutter)
- macOS or Windows development environment

---

### 🔧 Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/obscura.git
cd obscura
flutter pub get
```

Run in development:
-  macOS
```bash 
flutter run -d macos
```
- Windows
```bash 
flutter run -d windows
```