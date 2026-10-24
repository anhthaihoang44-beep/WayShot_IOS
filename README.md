# WayShot iOS: Aesthetic DigiCam & Film Photo Editor

Ứng dụng iOS của **WayShot** được xây dựng chuẩn mực theo mô hình **SwiftUI + Clean Architecture**, tuân thủ 100% toàn bộ 9 Kiến trúc Quyết định (ADRs):

| ADR | Tiêu đề | Hiện thực trên iOS (`wayshot_ios`) |
| :--- | :--- | :--- |
| **[ADR-001](../../docs/adr/ADR-001-on-device-image-processing.md)** | Xử lý ảnh 100% on-device | Toàn bộ thuật toán render và xuất ảnh chạy trên GPU Metal / CoreImage cục bộ. Không có bất kỳ pixel hay ảnh người dùng nào rời khỏi máy. |
| **[ADR-002](../../docs/adr/ADR-002-mvvm-clean-architecture.md)** | MVVM + Clean Architecture | Phân tách 3 tầng: `Domain` (Models, Services, Repository interface), `Data` (Repositories, Image IO, Metal/CoreImage render, Analytics), `UI` (SwiftUI Views, ViewModels, Theme Tokens). |
| **[ADR-003](../../docs/adr/ADR-003-non-destructive-pipeline.md)** | Pipeline Non-Destructive & Undo/Redo | `EditSession.swift` quản lý danh sách thao tác có thứ tự và 2 ngăn xếp Undo/Redo lịch sử 30 bước hoàn tác mượt mà. |
| **[ADR-004](../../docs/adr/ADR-004-platform-rendering-engine.md)** | Core Image & Metal Render Engine | `WayShotShaders.metal` (GPU Fragment Shader) + `WayShotCoreImagePipeline.swift` cho preview 60fps, Color Curves, 8-band HSL, Film Grain, VHS và Chroma Prism. |
| **[ADR-005](../../docs/adr/ADR-005-shared-preset-format.md)** | Định dạng Preset Dùng Chung | Sử dụng chung file `presets_manifest.json` chuẩn hóa giữa iOS và Android với các thông số tone, tint, contrast, grain. |
| **[ADR-006](../../docs/adr/ADR-006-remote-assets-cdn-cache-offline.md)** | CDN Cache, SHA-256 & Fallback Offline | `PresetRepositoryImpl.swift` hỗ trợ nạp Starter Kit nhúng sẵn trong bundle, đồng bộ CDN qua manifest, kiểm tra tính toàn vẹn SHA-256 và lưu Disk Cache. |
| **[ADR-007](../../docs/adr/ADR-007-in-app-purchase-pro-tier.md)** | In-App Purchase & Gói Pro Tier | `ProSubscriptionManager.swift` tích hợp **StoreKit 2** (Yearly $19.99/năm với 7 ngày dùng thử & Lifetime $39.99), kiểm tra entitlement mã hoá JWS kèm giao diện `ProPaywallView.swift`. |
| **[ADR-008](../../docs/adr/ADR-008-analytics-crash-reporting.md)** | Analytics & Crash Reporting | `PrivacyCompliantAnalyticsService.swift` ghi nhận telemetry ẩn danh (preset được chọn, thời gian export, paywall impression). Khẳng định tuyệt đối không gửi EXIF toạ độ hay pixel ảnh. |
| **[ADR-009](../../docs/adr/ADR-009-preview-export-memory-strategy.md)** | Preview, Export & Quản lý Bộ nhớ | Dual-Pipeline: Preview downsample (1080p–1440p) giữ vững 60fps; Export `HeadlessImageExporter.swift` render toàn dải ảnh gốc. Dùng `PHPickerViewController` không yêu cầu quyền đọc toàn bộ thư viện ảnh. |

---

## 📁 Cấu trúc Thư mục Chi tiết

```
wayshot_ios/
├── Package.swift                                      # SPM Package cho iOS 16+ & macOS 13+
├── WayShot.xcodeproj/project.pbxproj                  # Xcode project chuẩn
├── WayShot/
│   ├── App/
│   │   └── WayShotApp.swift                          # Điểm khởi chạy ứng dụng SwiftUI
│   ├── Domain/
│   │   ├── Models/
│   │   │   ├── Adjustments.swift                     # Brightness, Contrast, Saturation, Warmth, Sharpen, Shadows
│   │   │   ├── CropTransform.swift                   # Aspect Ratios (1:1, 4:5, 3:4, 9:16, 16:9) & Frames
│   │   │   ├── Curves.swift                          # Pro Tone Curves (RGB, R, G, B channels)
│   │   │   ├── HslAdjustment.swift                   # 8-band HSL fine color grading
│   │   │   ├── Effects.swift                         # Film Grain, VHS, Chroma Prism
│   │   │   ├── EditSession.swift                     # Non-destructive Undo/Redo stack (30 bước)
│   │   │   └── Preset.swift                          # Model filter DigiCam / Film
│   │   ├── Repositories/
│   │   │   └── PresetRepository.swift                # Protocol tải danh mục presets
│   │   └── Services/
│   │       └── ProSubscriptionManager.swift          # StoreKit 2 Pro In-App Purchase Service (ADR-007)
│   ├── Data/
│   │   ├── Analytics/
│   │   │   └── AnalyticsService.swift                # Telemetry bảo mật quyền riêng tư (ADR-008)
│   │   ├── Repositories/
│   │   │   └── PresetRepositoryImpl.swift            # 3-tier fallback: Disk Cache -> Starter Kit -> Defaults (ADR-006)
│   │   ├── Image/
│   │   │   ├── SampleImageGenerator.swift            # Sinh ảnh mẫu aesthetic chất lượng cao
│   │   │   ├── ImageIOHelper.swift                   # Downsampling preview chống tràn RAM (ADR-009)
│   │   │   └── PhotoLibrarySaver.swift               # Lưu ảnh vào Album "WayShot"
│   │   └── Render/
│   │       ├── Shaders/WayShotShaders.metal          # Metal GPU Fragment Shader
│   │       ├── WayShotCoreImagePipeline.swift        # Core Image CPU/GPU Pipeline
│   │       ├── WayShotMetalRenderer.swift            # MTKViewDelegate Metal 60fps renderer
│   │       └── HeadlessImageExporter.swift           # Render ảnh gốc độ phân giải cao
│   ├── UI/
│   │   ├── Theme/
│   │   │   ├── ColorTokens.swift                     # Bảng màu Dark Mode & Cherry Crimson
│   │   │   └── TypographyTokens.swift                # Monospaced date & typography aesthetic
│   │   ├── Paywall/
│   │   │   └── ProPaywallView.swift                  # Giao diện nâng cấp Pro Studio sang trọng (ADR-007)
│   │   ├── Components/
│   │   │   ├── TopActionBar.swift                    # Header thanh công cụ, Undo/Redo, Split, RAW, Pro Badge
│   │   │   ├── PresetStrip.swift                     # Thanh cuộn filter mô phỏng ống kính máy ảnh
│   │   │   ├── AdjustmentsPanel.swift                # Bảng thanh trượt điều chỉnh ánh sáng, màu sắc
│   │   │   ├── CurvesPanel.swift                     # Đồ thị hiệu chỉnh tone curves RGB (ADR-004/007)
│   │   │   ├── HslPanel.swift                        # 8 dải màu HSL chuyên nghiệp
│   │   │   ├── EffectsPanel.swift                    # Bảng hiệu ứng hoài cổ Grain, VHS, Chroma
│   │   │   ├── BorderCropPanel.swift                 # Khung Polaroid, 35mm Film Strip, Minimal
│   │   │   ├── ToolNavigationBar.swift               # Thanh điều hướng 6 tab công cụ
│   │   │   ├── InteractiveSplitSlider.swift          # Thanh trượt so sánh Before/After trực tiếp
│   │   │   └── ExportDialog.swift                    # Hộp thoại chọn format và chất lượng xuất ảnh
│   │   └── Editor/
│   │       ├── EditorView.swift                      # Màn hình Canvas chính với Split, LED Date Stamp
│   │       ├── EditorViewModel.swift                 # MVVM ViewModel kết nối UI & Domain (ADR-002)
│   │       └── StudioHomeView.swift                  # Màn hình chọn ảnh / thử ảnh mẫu khi mở app
│   └── Resources/
│       ├── Info.plist                                # Quyền riêng tư NSPhotoLibraryAddUsageDescription
│       └── Presets/presets_manifest.json             # Manifest preset dùng chung chuẩn (ADR-005)
└── WayShotTests/
    ├── EditSessionTests.swift                        # Unit test stack Undo/Redo 30 bước
    ├── ColorMathTests.swift                          # Unit test tính toán sRGB Luma và công thức màu
    └── ADRArchitectureTests.swift                    # Unit test kiểm tra tuân thủ cả 9 ADRs
```

---

## 🚀 Hướng Dẫn Mở & Đóng Gói Ứng Dụng

### 1. Mở trong Xcode (macOS)
```bash
open wayshot_ios/WayShot.xcodeproj
```

### 2. Chạy Unit Tests độc lập qua Swift Package Manager
```bash
cd wayshot_ios
swift test
```

### 3. Đóng gói file `.ipa` tự động qua GitHub Actions (Dành cho người dùng Windows / Linux)
Kho lưu trữ đã được tích hợp sẵn quy trình CI/CD tại [`.github/workflows/ios-build.yml`](../.github/workflows/ios-build.yml):
1. Đẩy code lên GitHub (`git push`).
2. GitHub Actions chạy trên máy ảo `macos-14`, tự động kiểm thử toàn bộ `WayShotTests` và đóng gói thành tệp **`WayShot-Unsigned.ipa`**.
3. Bạn tải tệp IPA về máy tính Windows và dùng công cụ **Sideloadly** để cài trực tiếp vào iPhone mà không cần tài khoản Apple Developer trả phí!
