# THÔNG TIN DỰ ÁN
Tên dự án: Nutrifit.
Nền tảng: Flutter (Dart).
Mục đích: Ứng dụng quản lý tập luyện và dinh dưỡng.

# QUY TẮC NGÔN NGỮ (QUAN TRỌNG)
1. User (Tôi) sẽ giao tiếp và mô tả yêu cầu bằng Tiếng Việt.
2. MỌI MÃ NGUỒN (Class, Variable, Function, Enum, File name) BẮT BUỘC viết bằng Tiếng Anh chuẩn.
3. MỌI COMMENT trong code BẮT BUỘC viết bằng Tiếng Anh.
4. TEXT HIỂN THỊ trên UI (Text widget, SnackBar, Dialog) BẮT BUỘC dùng Tiếng Việt theo đúng mô tả của user.

# KIẾN TRÚC & THƯ VIỆN
1. Architecture: Dùng "Feature-First Clean Architecture" (lib/features/tên_tính_năng/...).
2. State Management: CHỈ SỬ DỤNG `flutter_bloc` (Bloc/Cubit). Không dùng Provider, GetX.
3. Database: Dùng CHÍNH THỨC Firebase Firestore (NoSQL). TUYỆT ĐỐI KHÔNG dùng Local DB (như SQLite, Drift, Floor). Luôn cấu hình `persistenceEnabled = true` cho Firestore để hỗ trợ Offline tự động.
4. UI/Design: Dùng Material 3. Tách nhỏ các Widget dài. Hỗ trợ sẵn Dark/Light theme.

# QUY TẮC VIẾT CODE DART
1. Luôn dùng `final` và `const` ở mọi nơi có thể.
2. Các Model bắt buộc phải có method `fromJson`, `toJson`, và `copyWith`.
3. Xử lý lỗi (Error Handling): Phải bọc các lời gọi Firebase bằng `try-catch` và trả về custom Exceptions hoặc dùng gói `fpdart`/`dartz` (Either) nếu có yêu cầu.
4. Không bao giờ xóa các đoạn code cũ đang chạy tốt nếu không được yêu cầu. Nếu cần sửa đổi, hãy giải thích ngắn gọn trước.