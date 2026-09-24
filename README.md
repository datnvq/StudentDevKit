# StudentDevKit v0.5.0

Bộ công cụ thiết lập môi trường lập trình C/C++, VS Code & Developer chuẩn hóa dành cho Sinh viên trên Windows (MinGW-w64 UCRT64).

---

## 🚀 Cách Chạy Nhanh (Dành Cho Sinh Viên)

Bạn có thể mở bộ cài đặt dễ dàng bằng **1 cú click đúp chuột**:

1. **`StudentDevKit.exe`** (Khuyên dùng): File thực thi trực tiếp, tự động yêu cầu quyền Administrator và mở **Giao diện Dòng lệnh (Terminal TUI)** sắc nét, chuyên nghiệp.
2. **`Chay-StudentDevKit.bat`**: File batch chạy ngay giao diện dòng lệnh Terminal chuẩn hóa.
3. **`Chay-Console.bat`**: Khởi động Console TUI nhanh chóng.

Hoặc mở PowerShell với quyền Administrator:
```powershell
# Chạy giao diện dòng lệnh chuẩn hóa (Terminal TUI)
.\setup.ps1

# Chạy tự động kiểm tra tính toàn vẹn
.\setup.ps1 -SelfTest
```

---

## 🎨 2 Chế Độ Giao Diện Hiện Đại

### 1. Giao diện Đồ họa Desktop (WPF Dark Mode)
- **Thiết kế Dark Theme hiện đại**, trực quan, thân thiện.
- **Phân loại danh mục rõ ràng**: Trình soạn thảo, Công cụ cốt lõi, Lập trình C/C++, Hệ thống Build, Ngôn ngữ khác, Cấu hình VS Code, Dự án mẫu.
- **Thao tác 1 click**: Nút *Chọn Gói Đề Xuất*, *Chọn Tất Cả*, *Bỏ Chọn*.
- **Theo dõi tiến trình thời gian thực**: Thanh phần trăm (%) động và khung nhật ký (Live Log Terminal) hiển thị tiến trình chi tiết từng bước.
- **Tab kiểm tra hệ thống**: Quét trực tiếp vị trí các trình biên dịch (`gcc`, `g++`, `gdb`, `git`, `code`, `cmake`...) trên máy tính.
- **Tab hướng dẫn sinh viên**: Hướng dẫn mở dự án mẫu và phím tắt chạy mã C/C++.

### 2. Giao diện Dòng Lệnh Tương Tác (Terminal / TUI)
- Sử dụng bảng mã UTF-8 tiếng Việt hoàn toàn.
- Khung viền Unicode bo góc sang trọng (`╔═╗`, `╭─╮`, `┌─┐`).
- Màu sắc trực quan theo chuẩn trạng thái (`[✔ ĐÃ CÀI]` màu xanh lá, `[○ CHƯA CÓ]` màu xám/vàng).
- Thanh tiến trình khối (`████░░░░ 50%`) sinh động khi đang cài đặt.
- Phím tắt nhanh: `[1-6]`, `[G]` mở GUI ngay từ Console, `[A]`, `[N]`, `[R]`, `[S]`, `[B]`, `[Q]`.

---

## 📦 Danh Mục Các Gói Công Cụ Hỗ Trợ

| Nhóm | Công Cụ | Đề Xuất | Mô Tả |
| :--- | :--- | :---: | :--- |
| **Editor** | **Visual Studio Code** | ★ Có | Trình soạn thảo mã nguồn gọn nhẹ, mạnh mẽ nhất hiện nay |
| **Core** | **Git for Windows** | ★ Có | Quản lý phiên bản mã nguồn chuẩn quốc tế (GitHub, GitLab) |
| **C/C++** | **GCC & G++ (MinGW-w64 UCRT64)** | ★ Có | Bộ trình biên dịch chuẩn C/C++ mới nhất qua MSYS2 UCRT64 |
| **C/C++** | **GDB Debugger** | ★ Có | Trình gỡ lỗi GNU Debugger giúp debug từng dòng code C/C++ |
| **Build** | **CMake** | Không | Hệ thống sinh file build đa nền tảng cho C/C++ |
| **Build** | **Ninja** | Không | Bộ sinh thực thi siêu nhanh, kết hợp với CMake |
| **C/C++** | **LLVM / Clang** | Không | Trình biên dịch Clang và bộ định dạng clang-format |
| **C/C++** | **Cppcheck** | Không | Công cụ phân tích tĩnh mã nguồn C/C++, phát hiện bug |
| **Language** | **Python 3.13** | Không | Môi trường Python phục vụ giải thuật, AI & dữ liệu |
| **Language** | **Node.js LTS** | Không | Môi trường JavaScript runtime ổn định cho web |
| **VS Code** | **C/C++ Extensions & Code Runner** | ★ Có | Extension C/C++ Tools, CMake Tools, Code Runner 1-click |
| **VS Code** | **Cấu hình VS Code chuẩn** | ★ Có | Tự động format code, phím tắt và terminal tối ưu |
| **VS Code** | **Bộ Snippets C/C++ Sinh viên** | ★ Có | Mẫu gõ nhanh hàm main, cin/cout, thuật toán cơ bản |
| **Project** | **Template Dự Án Mẫu** | ★ Có | Khởi tạo thư mục dự án C++ mẫu hoàn chỉnh sẵn sàng chạy |

---

## 🛡️ Tính An Toàn & Độc Lập
- Sử dụng `winget.exe` chính chủ từ Microsoft với mã Package ID cụ thể (`--exact`).
- MSYS2 UCRT64 chỉ cài GCC/G++ và GDB tinh gọn, không tải toàn bộ hệ thống nặng nề.
- Có tính năng **Self-Test** (`setup.ps1 -SelfTest`) để kiểm tra toàn vẹn bộ cài đặt trước khi chạy.
