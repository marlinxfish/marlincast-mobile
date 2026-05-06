# Product Requirements Document (PRD)

## Aplikasi Mobile: Marlin Cast (Pengendali / Caster)

## 1. Informasi Umum

- Nama Aplikasi: Marlin Cast
- Platform: Android (via Flutter)
- Minimum OS: Android 10 (API Level 29)
- Kategori: Video Players & Editors / Tools
- Peran Utama: Bertindak sebagai Smart Web Browser, Video Sniffer, Remote Control TV, dan Portal Pembayaran VIP.

## 2. Tujuan Aplikasi (Objectives)

- Bebas Iklan (Super Ad-Blocker): Memberikan pengalaman browsing situs streaming pihak ketiga (anime/film) yang 100% bersih dari pop-up, redirect paksa, dan overlay iklan.
- Seamless Casting: Menangkap URL video mentah secara otomatis dan mengirimkannya ke TV tanpa hambatan.
- Monetisasi Pintar: Mengonversi pengguna gratisan menjadi pelanggan VIP berbayar (Rp 15.000) melalui pendekatan fungsionalitas (saat TV butuh Cloud Cast/Transcoding Bunny.net).

## 3. Teknologi yang Digunakan (Tech Stack)

Aplikasi dibangun sepenuhnya menggunakan kerangka kerja lintas platform dengan integrasi Native tingkat tinggi untuk pemblokiran iklan.

- Framework UI & Logika: Flutter (Dart)
- Web Engine: flutter_inappwebview (Sebagai pengganti browser bawaan, memiliki fitur interceptor yang sangat kaya).
- Super AdBlock Engine: adblock-rust (Engine pemblokir iklan berbasis Rust, persis seperti yang digunakan Brave Browser).
- FFI Bridge: flutter_rust_bridge (Untuk menghubungkan engine Rust langsung ke kode Dart Flutter tanpa lag).
- Local Network (WebSocket): web_socket_channel (Untuk komunikasi interaktif dan Remote Control ke TV).
- HTTP Client & API: dio (Untuk komunikasi REST API ke Backend Golang, dilengkapi interceptor untuk JWT Token).
- QR Scanner: mobile_scanner (Berbasis ML Kit Google, sangat cepat mendeteksi QR TV).
- Local Storage: shared_preferences atau hive (Untuk menyimpan sesi token JWT dan pengaturan pengguna).

## 4. Fitur Utama & Fungsionalitas

### 4.1. Pemindai Perangkat (Device Pairing)

- Fungsi: Menghubungkan HP ke TV dalam satu jaringan WiFi.
- UI/UX: Kamera fullscreen dengan overlay kotak scanner. Terdapat teks petunjuk "Scan QR Code di layar Marlin Cast TV Anda".
- Logika: Membaca QR berformat `192.168.x.x:8080?token=ABC123`. Menyimpan IP dan Token ini di state aplikasi dan langsung membuka koneksi WebSocket.

### 4.2. Super Ad-Blocker & Web Browser

- Network Blocking (Lapis 1): Menggunakan flutter_inappwebview + adblock-rust. Setiap kali web memuat sumber daya (gambar, script, iframe), request akan diuji oleh Rust (berdasarkan EasyList). Jika cocok dengan ciri-ciri iklan, request dibatalkan (Abort) seketika.
- Cosmetic Filtering (Lapis 2): Menyuntikkan JavaScript (JS) kustom saat halaman selesai dimuat (onLoadStop). JS ini akan menghapus elemen HTML overlay transparan yang sering menjebak user untuk menekan iklan.

### 4.3. Video Sniffer (Penangkap URL)

- Fungsi: Mendeteksi file media asli di balik pemutar web.
- Logika: Memanfaatkan `shouldInterceptRequest`. Jika URL yang lewat berakhiran `.mp4`, `.m3u8`, `.ts`, atau memiliki `Content-Type video/*`:
- Tangkap URL tersebut.
- Cegah video diputar di HP (agar tidak boros kuota ganda).
- Munculkan UI (Floating Action Button / Bottom Sheet) berbunyi: "1 Video Ditemukan. Siap Cast ke TV."

### 4.4. UI Remote Control TV

- Fungsi: Mengendalikan video yang sedang tayang di TV.
- Tampilan: Layout minimalis dengan tombol raksasa: Play, Pause, Rewind 10s, Forward 10s, Stop/Disconnect, dan Slider Volume.
- Komunikasi: Saat ditekan, tombol ini mengirim JSON ringan via WebSocket ke TV. Contoh: `{"cmd": "SEEK", "value": "+10"}`.

### 4.5. Sistem Monetisasi & VIP Paywall

- User Gratis: Akan dipaksa menonton Rewarded Ad / Interstitial Ad (Google AdMob / AppLovin) setiap kali menekan tombol "Mulai Cast" atau "Stop Cast".
- Skenario Cloud Cast: Jika TV mengirim pesan galat (Unsupported Codec) via WebSocket, Mobile App langsung memunculkan Paywall VIP.
- Paywall UI: Menawarkan fitur Cloud Cast (Bebas iklan, Transcoding Bunny.net, Kuota 150GB). Harga Rp 15.000.
- Pembayaran: Menggunakan Deep-link URL langsung ke aplikasi DANA/Gopay/ShopeePay (via Payment Gateway Midtrans/Xendit).

## 5. Alur Pengguna (User Flow) Lengkap

- Onboarding: Buka aplikasi -> Izin Kamera -> Tampilan Scan QR.
- Koneksi: Scan QR di TV -> Validasi Token Lokal -> Terhubung (Status berubah jadi "TV Connected").
- Eksplorasi: Layar berubah ke halaman Browser. User bisa mengetik URL situs web film, atau memilih Bookmark bawaan.
- Sniffing: User klik tombol "Play" di situs web anime -> Layar web berhenti (Intercepted) -> Muncul pop-up "Video Terdeteksi".
- Casting (Routing Decision):
- User klik "Cast ke TV".
- Aplikasi mengirim instruksi DIRECT_PLAY beserta URL ke TV.
- Jika TV Sukses: Layar HP berubah menjadi UI Remote Control.
- Jika TV Gagal (Error): HP menerima sinyal galat. Muncul pop-up "Format tidak didukung. Butuh Cloud Cast."
- Eksekusi Cloud Cast (Premium):
- Cek VIP di HP: Jika belum VIP, arahkan ke pembayaran. Jika sudah VIP:
- HP mengirim token JWT dan URL video asli ke API Backend VPS Golang.
- Backend mengembalikan URL CDN Bunny HLS (`.m3u8`).
- HP memerintahkan TV memutar URL CDN Bunny tersebut.
- Layar HP berubah menjadi UI Remote Control.

## 6. Keamanan Aplikasi (Security & Mitigations)

- Validasi Server-Side: Hak istimewa VIP, sisa kuota FUP, dan limitasi device HANYA diperiksa dan dikelola oleh Backend Golang. Aplikasi seluler tidak boleh menyimpan variabel seperti `bool isVip = true` di storage lokal tanpa validasi real-time dengan API.
- Anti-Obfuscation: Saat build ke `.aab` atau `.apk`, wajib mengaktifkan obfuscation Dart (`--obfuscate`) agar source code tidak mudah di-reverse engineering oleh pembuat aplikasi modifikasi (Modder APK).
- JWT Storage: Menyimpan token otentikasi menggunakan flutter_secure_storage yang dienkripsi oleh Keystore bawaan OS Android.

## 7. Pemantauan & Analitik (Observability)

- Firebase Crashlytics: Digunakan untuk melacak crash atau aplikasi force close, lengkap dengan parameter tipe HP pengguna (contoh: Xiaomi Redmi Note 10 - RAM 4GB).
- Firebase Analytics: Melacak events spesifik:
- `cast_button_clicked`
- `paywall_viewed`
- `ad_blocked_count` (Berapa banyak iklan yang berhasil dicegat oleh Rust Engine).
