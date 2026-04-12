---
trigger: always_on
---

# 1. THÔNG TIN DỰ ÁN
- Tên dự án: NutriFit.
- Nền tảng: Flutter (Dart).
- Mục đích: Ứng dụng quản lý tập luyện và dinh dưỡng.

# 2. QUY TẮC NGÔN NGỮ (LANGUAGE RULES)
- User sẽ giao tiếp và mô tả yêu cầu bằng **Tiếng Việt**.
- Codebase (Class, Variable, Function, Enum, File name) BẮT BUỘC viết bằng **Tiếng Anh chuẩn**.
- Comments trong code BẮT BUỘC viết bằng **Tiếng Anh**.
- Text hiển thị trên UI (Text, SnackBar, Dialog...) BẮT BUỘC dùng **Tiếng Anh** (AI tự động dịch sát nghĩa dựa trên mô tả Tiếng Việt của User).

# 3. KIẾN TRÚC & LUỒNG DỮ LIỆU (ARCHITECTURE & DATA FLOW)
- Tổ chức thư mục: Dùng **Feature-First Layered Architecture** (Tách `presentation`, `logic`, `data` bên trong mỗi feature). KHÔNG tạo tầng `domain` hay `usecases` để tránh Over-engineering với Firebase.
- State Management: CHỈ DÙNG `flutter_bloc` (Bloc/Cubit). Không dùng Provider, GetX.
- Nguyên tắc giao tiếp: Tuân thủ luồng dữ liệu một chiều (Unidirectional). **UI chỉ được phép giao tiếp với Bloc/Cubit. TUYỆT ĐỐI KHÔNG để UI gọi trực tiếp Repository hay API.**
- Cấu trúc Data: Tách biệt `models`, `repositories` và `data_sources` (chứa code gọi Firebase thuần).

# 4. DATABASE & BACKEND
- Database: Dùng CHÍNH THỨC **Firebase Firestore (NoSQL)**. TUYỆT ĐỐI KHÔNG dùng Local DB (SQLite, Drift, Floor).
- Offline Support: Luôn cấu hình `persistenceEnabled = true` cho Firestore để hỗ trợ Offline tự động.
- Model Design: Tối ưu theo hướng NoSQL (cho phép Denormalization / lặp dữ liệu) để hạn chế read queries dư thừa.

# 5. UI & DESIGN SYSTEM
- Design System: Sử dụng Material 3.
- Typography: Bắt buộc sử dụng font **Google Fonts: Inter** cho toàn bộ ứng dụng.
- Theme: Hỗ trợ linh hoạt Dark/Light theme (ưu tiên cấu trúc colors lấy từ `Theme.of(context)`).
- Component: Tách các Widget dài hoặc lặp lại (như Card, Button) ra file riêng trong thư mục `presentation/widgets/`.

# 6. QUY TẮC CODE DART (CODING STANDARDS)
- Luôn ưu tiên dùng từ khóa `final` và `const` ở mọi nơi có thể.
- Models: Bắt buộc phải có `fromJson`, `toJson`, `copyWith`, và implement **`Equatable`** để tối ưu so sánh State trong BLoC.
- Error Handling: Các hàm gọi Firebase (bên trong Repository/DataSource) phải được bọc bằng `try-catch` và trả về custom Exceptions hoặc dùng gói `fpdart`/`dartz` (Either).
- AI Behavior: KHÔNG BAO GIỜ tự ý xóa/sửa đổi các đoạn code cũ đang chạy tốt nếu User không yêu cầu. Nếu cần sửa để fix bug, hãy giải thích ngắn gọn nguyên nhân trước khi output code.