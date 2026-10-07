# ROS 2 Lyrical di Docker pada Arch Linux

Panduan ini digunakan untuk menjalankan **ROS 2 Lyrical** di Docker pada **Arch Linux** tanpa perlu mengganti OS utama ke Ubuntu.

Repository ini sudah menyediakan:

- `Dockerfile`
- `compose.yaml`

ROS 2 berjalan di dalam container Ubuntu, sedangkan source code workspace tetap disimpan di Arch.

Panduan ini menyediakan contoh untuk **Bash** dan **Fish** pada host Arch.

---

## Gambaran Setup

```text
Arch Linux
├── Docker
│   └── Ubuntu + ROS 2 Lyrical
│       └── ~/ros2_ws
│           ├── src      ← diambil dari Arch
│           ├── build    ← hanya di Docker
│           ├── install  ← hanya di Docker
│           └── log      ← hanya di Docker
│
└── ~/ros2_ws/src
    └── source code ROS 2
```

Hanya folder `src` yang dibagikan ke Docker. Folder `build`, `install`, dan `log` tetap berada di dalam container supaya tidak bentrok dengan environment ROS 2 lain, misalnya Distrobox.

---

## 1. Install Docker

Di Arch Linux:

```bash
sudo pacman -S docker docker-compose
```

Aktifkan Docker:

```bash
sudo systemctl enable --now docker
```

Tambahkan user ke grup Docker supaya tidak perlu memakai `sudo` setiap kali menjalankan Docker:

### Bash

```bash
sudo usermod -aG docker "$USER"
```

### Fish

```fish
sudo usermod -aG docker $USER
```

Setelah itu **logout lalu login kembali**.

Cek:

```bash
docker --version
docker compose version
docker run --rm hello-world
```

Kalau `hello-world` berhasil, Docker sudah siap.

---

## 2. Clone Repository

```bash
git clone <URL-REPOSITORY>
cd <NAMA-REPOSITORY>
```

Ganti `<URL-REPOSITORY>` dan `<NAMA-REPOSITORY>` sesuai repository GitHub yang digunakan.

---

## 3. Buat File `.env`

`compose.yaml` membutuhkan informasi user Arch agar file yang dibuat dari Docker tetap memiliki izin yang benar.

### Bash

Jalankan:

```bash
cat > .env <<EOF
HOST_USER=$(id -un)
HOST_UID=$(id -u)
HOST_GID=$(id -g)
DISPLAY=$DISPLAY
HOME=$HOME
VIDEO_GID=$(getent group video | cut -d: -f3)
RENDER_GID=$(getent group render | cut -d: -f3)
EOF
```

### Fish

Jalankan:

```fish
printf "HOST_USER=%s\nHOST_UID=%s\nHOST_GID=%s\nDISPLAY=%s\nHOME=%s\n" \
    (id -un) \
    (id -u) \
    (id -g) \
    $DISPLAY \
    $HOME > .env

printf "VIDEO_GID=%s\n" (getent group video | cut -d: -f3) >> .env
printf "RENDER_GID=%s\n" (getent group render | cut -d: -f3) >> .env
```

Cek hasilnya:

```bash
cat .env
```

Contoh:

```text
HOST_USER=lain
HOST_UID=1000
HOST_GID=1000
DISPLAY=:0
HOME=/home/lain
VIDEO_GID=985
RENDER_GID=989
```

Nomor UID, GID, `VIDEO_GID`, dan `RENDER_GID` bisa berbeda di setiap komputer.

---

## 4. Siapkan Workspace ROS 2

Di Arch:

```bash
mkdir -p ~/ros2_ws/src
```

Source code ROS 2 diletakkan di:

```text
~/ros2_ws/src
```

Folder tersebut akan dibaca dari dalam container.

---

## 5. Build Image Docker

Dari folder repository:

```bash
docker compose build
```

Build pertama bisa cukup lama karena Docker perlu mengunduh image ROS 2 beserta paket desktop.

Build berikutnya biasanya lebih cepat karena file yang sudah pernah diunduh disimpan oleh Docker.

---

## 6. Jalankan Container

```bash
docker compose up -d
```

Cek apakah container hidup:

```bash
docker ps
```

Container ROS 2 seharusnya muncul di daftar.

---

## 7. Masuk ke Container

```bash
docker compose exec ros2 bash
```

Shell host boleh Bash atau Fish. Di dalam container kita tetap memakai **Bash** karena setup ROS 2 menggunakan script Bash.

Cek user:

```bash
whoami
```

Nama user seharusnya sama dengan user Arch.

Cek ROS 2:

```bash
ros2 --help
```

Kalau daftar perintah ROS 2 muncul, ROS 2 sudah aktif.

---

## 8. Build Workspace ROS 2

Di dalam container:

```bash
cd ~/ros2_ws
colcon build
```

Setelah selesai:

```bash
source install/setup.bash
```

Sekarang package di dalam `~/ros2_ws/src` bisa dijalankan menggunakan `ros2 run` atau `ros2 launch`.

Contoh:

```bash
ros2 pkg list
```

---

## 9. Menjalankan RViz di Arch + Wayland/Hyprland

Setup ini menggunakan:

```text
QT_QPA_PLATFORM=xcb
```

agar RViz berjalan lewat XWayland.

Di Arch, pastikan `xhost` tersedia:

```bash
sudo pacman -S xorg-xhost
```

Berikan izin tampilan kepada user.

### Bash

```bash
xhost +SI:localuser:"$USER"
```

### Fish

```fish
xhost +SI:localuser:$USER
```

Masuk lagi ke container:

```bash
docker compose exec ros2 bash
```

Lalu:

```bash
rviz2
```

Kalau jendela RViz muncul, bagian tampilan grafis sudah bekerja.

---

## 10. Akses GPU Intel/AMD untuk RViz

Kalau RViz menampilkan error seperti:

```text
MESA: error: Failed to query drm device.
glx: failed to create dri3 screen
failed to load driver: iris
```

berarti container belum mendapatkan akses yang benar ke GPU.

Cek dari Arch:

```bash
ls -l /dev/dri
```

Biasanya akan terlihat:

```text
card0
renderD128
```

Pastikan `compose.yaml` memiliki bagian seperti:

```yaml
devices:
  - /dev/dri:/dev/dri

group_add:
  - "${VIDEO_GID}"
  - "${RENDER_GID}"
```

Setelah mengubah konfigurasi:

```bash
docker compose down
docker compose up -d
```

Masuk kembali:

```bash
docker compose exec ros2 bash
```

Cek:

```bash
ls -l /dev/dri
```

Lalu coba lagi:

```bash
rviz2
```

---

## 11. Workflow Sehari-hari

### Bash

Menyalakan container:

```bash
cd <FOLDER-REPOSITORY>
docker compose up -d
```

Masuk ke ROS 2:

```bash
docker compose exec ros2 bash
```

### Fish

Menyalakan container:

```fish
cd <FOLDER-REPOSITORY>
docker compose up -d
```

Masuk ke ROS 2:

```fish
docker compose exec ros2 bash
```

Setelah masuk container, perintahnya sama untuk semua shell host:

```bash
cd ~/ros2_ws
colcon build
source install/setup.bash
ros2 ...
rviz2
```

Keluar dari container:

```bash
exit
```

Mematikan container:

```bash
docker compose stop
```

Menyalakannya lagi:

```bash
docker compose start
```

---

## 12. Catatan Jika Juga Menggunakan Distrobox

Docker dan Distrobox boleh sama-sama memiliki ROS 2.

Source code bisa memakai folder yang sama:

```text
~/ros2_ws/src
```

Tetapi jangan membagikan seluruh `~/ros2_ws` ke Docker.

Yang dibagikan cukup:

```text
~/ros2_ws/src
```

Dengan begitu hasil build Docker dan Distrobox tidak tercampur.

Kalau ROS 2 di Docker dan Distrobox dijalankan bersamaan, keduanya bisa saling menemukan lewat jaringan jika memakai nomor komunikasi ROS 2 yang sama.

Kalau ingin dipisahkan, gunakan `ROS_DOMAIN_ID` yang berbeda.

Contoh:

```text
Distrobox: ROS_DOMAIN_ID=10
Docker:    ROS_DOMAIN_ID=20
```

`ROS_DOMAIN_ID` sederhananya adalah nomor ruang komunikasi ROS 2. ROS 2 dengan nomor berbeda tidak akan saling melihat.

---

## Troubleshooting

### `groupadd: GID '1000' already exists`

Image Ubuntu/ROS 2 bisa saja sudah memiliki group dengan nomor `1000`.

Dockerfile pada repository ini harus menggunakan group yang sudah ada jika nomor tersebut sudah dipakai, bukan membuat group baru secara paksa.

Setelah Dockerfile diperbaiki:

```bash
docker compose build
```

Tidak perlu memakai `--no-cache`.

---

### RViz tidak muncul

Pastikan izin tampilan sudah diberikan.

#### Bash

```bash
xhost +SI:localuser:"$USER"
```

#### Fish

```fish
xhost +SI:localuser:$USER
```

Lalu pastikan `compose.yaml` memiliki:

```yaml
environment:
  DISPLAY: ${DISPLAY}
  QT_QPA_PLATFORM: xcb
```

---

### RViz Menampilkan Error GPU

Pastikan `/dev/dri` tersedia di Arch:

```bash
ls -l /dev/dri
```

dan `compose.yaml` memberikan akses `/dev/dri` ke container.

---

### ROS 2 Tidak Menemukan Package Setelah Build

Setelah:

```bash
colcon build
```

jalankan:

```bash
source install/setup.bash
```

Setiap terminal baru di dalam container perlu membaca hasil build workspace sebelum package buatan sendiri bisa digunakan.

---

## Ringkasan

Setup akhirnya:

```text
Arch Linux
├── Bash atau Fish
├── Docker
│   └── Ubuntu
│       └── ROS 2 Lyrical
│           ├── colcon
│           ├── RViz
│           └── workspace ROS 2
│
└── ~/ros2_ws/src
    └── source code project
```

Dengan setup ini Arch tetap menjadi OS utama, sementara ROS 2 berjalan di lingkungan Ubuntu yang terpisah dan lebih mudah dijaga versinya.
