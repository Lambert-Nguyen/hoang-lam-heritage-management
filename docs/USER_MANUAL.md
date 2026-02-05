# 📱 Hoang Lam Heritage Management - Hướng Dẫn Sử Dụng

**Phiên bản:** MVP1 (Tháng 2/2026)  
**Dành cho:** Chủ khách sạn, Quản lý, Nhân viên

---

## 📋 Mục Lục

1. [Bắt Đầu](#1-bắt-đầu)
2. [Màn Hình Chính (Dashboard)](#2-màn-hình-chính-dashboard)
3. [Quản Lý Phòng](#3-quản-lý-phòng)
4. [Đặt Phòng](#4-đặt-phòng)
5. [Quản Lý Khách](#5-quản-lý-khách)
6. [Nhận Phòng / Trả Phòng](#6-nhận-phòng--trả-phòng)
7. [Tài Chính](#7-tài-chính)
8. [Housekeeping & Bảo Trì](#8-housekeeping--bảo-trì)
9. [Minibar & POS](#9-minibar--pos)
10. [Báo Cáo](#10-báo-cáo)
11. [Kiểm Toán Đêm](#11-kiểm-toán-đêm)
12. [Khai Báo Tạm Trú](#12-khai-báo-tạm-trú)
13. [Cài Đặt](#13-cài-đặt)
14. [Câu Hỏi Thường Gặp](#14-câu-hỏi-thường-gặp)

---

## 1. Bắt Đầu

### 1.1 Đăng Nhập

1. Mở ứng dụng **Hoang Lam Heritage**
2. Nhập **Tên đăng nhập** và **Mật khẩu**
3. Nhấn nút **Đăng nhập**

> 💡 **Mẹo:** Bật "Ghi nhớ đăng nhập" để không phải nhập lại mỗi lần mở app.

### 1.2 Các Vai Trò Người Dùng

| Vai Trò | Quyền Hạn |
|---------|-----------|
| **Chủ (Owner)** | Toàn quyền: cài đặt, người dùng, báo cáo đầy đủ |
| **Quản Lý (Manager)** | Đặt phòng, check-in/out, tài chính, báo cáo cơ bản |
| **Nhân Viên (Staff)** | Xem đặt phòng, cập nhật trạng thái phòng |
| **Housekeeping** | Nhiệm vụ dọn phòng, trạng thái dọn dẹp |

### 1.3 Điều Hướng

Ứng dụng có 4 tab chính ở dưới màn hình:

| Tab | Biểu Tượng | Chức Năng |
|-----|------------|-----------|
| **Trang Chủ** | 🏠 | Dashboard tổng quan |
| **Đặt Phòng** | 📅 | Lịch và danh sách đặt phòng |
| **Tài Chính** | 💰 | Thu chi, thanh toán |
| **Cài Đặt** | ⚙️ | Cấu hình ứng dụng |

---

## 2. Màn Hình Chính (Dashboard)

Dashboard hiển thị tổng quan hoạt động trong ngày:

### 2.1 Thông Tin Hiển Thị

- **Ngày hôm nay** - Ngày hiện tại
- **Phòng trống** - Số phòng sẵn sàng cho thuê
- **Đang ở** - Số phòng có khách
- **Check-in hôm nay** - Số khách sẽ đến
- **Check-out hôm nay** - Số khách sẽ trả phòng

### 2.2 Sơ Đồ Phòng

Hiển thị tất cả phòng với màu sắc:

| Màu | Trạng Thái |
|-----|------------|
| 🟢 Xanh lá | Trống (Available) |
| 🔴 Đỏ | Có khách (Occupied) |
| 🟡 Vàng | Đang dọn (Cleaning) |
| 🟠 Cam | Bảo trì (Maintenance) |
| ⚫ Xám | Khóa (Blocked) |

### 2.3 Thao Tác Nhanh

- **+ Đặt phòng mới** - Tạo đặt phòng nhanh
- **Xem tất cả** - Đến danh sách đặt phòng
- **Check-in ngay** - Nhận phòng cho khách đến

---

## 3. Quản Lý Phòng

### 3.1 Xem Danh Sách Phòng

1. Vào **Trang Chủ** > Nhấn vào bất kỳ phòng nào
2. Hoặc vào **Cài Đặt** > **Quản Lý Phòng**

### 3.2 Thay Đổi Trạng Thái Phòng

1. Nhấn vào phòng cần đổi
2. Chọn trạng thái mới:
   - **Trống** - Sẵn sàng cho thuê
   - **Đang dọn** - Nhân viên đang dọn
   - **Bảo trì** - Cần sửa chữa
   - **Khóa** - Tạm không cho thuê

3. Nhấn **Xác nhận**

### 3.3 Xem Chi Tiết Phòng

- **Số phòng** và **Tên phòng**
- **Loại phòng** (Đơn, Đôi, Gia đình, VIP)
- **Tầng**
- **Giá/đêm** và **Giá/giờ**
- **Tiện nghi** (WiFi, Điều hòa, Tủ lạnh, v.v.)
- **Ghi chú**

---

## 4. Đặt Phòng

### 4.1 Tạo Đặt Phòng Mới

1. Nhấn nút **+ Đặt phòng** (FAB)
2. Điền thông tin:
   - **Chọn phòng** - Phòng trống
   - **Khách hàng** - Chọn hoặc tạo mới
   - **Ngày nhận** - Ngày check-in
   - **Ngày trả** - Ngày check-out
   - **Loại đặt** - Qua đêm / Theo giờ
   - **Số khách**
   - **Nguồn đặt** - Walk-in, Điện thoại, Booking.com, Agoda, v.v.
   - **Ghi chú** / **Yêu cầu đặc biệt**

3. Nhấn **Tạo đặt phòng**

### 4.2 Đặt Phòng Theo Giờ

1. Chọn **Loại đặt: Theo giờ**
2. Nhập **Số giờ** (tối thiểu 2 giờ)
3. Hệ thống tự tính **Giờ trả dự kiến**
4. Giá tính theo giờ đầu + giờ tiếp theo

### 4.3 Xem Lịch Đặt Phòng

1. Vào tab **Đặt Phòng**
2. Xem lịch theo tháng
3. Các ngày có đặt phòng được đánh dấu
4. Nhấn vào ngày để xem chi tiết

### 4.4 Lọc Đặt Phòng

Nhấn biểu tượng **🔍 Lọc** để lọc theo:
- **Trạng thái**: Chờ xác nhận, Đã xác nhận, Đang ở, Đã trả
- **Nguồn**: Walk-in, OTA, Điện thoại
- **Phòng**: Chọn phòng cụ thể
- **Khoảng ngày**: Từ ngày - Đến ngày

### 4.5 Sửa / Hủy Đặt Phòng

1. Nhấn vào đặt phòng cần sửa
2. Nhấn **✏️ Sửa** để chỉnh sửa
3. Nhấn **🗑️ Hủy** để hủy đặt phòng
4. Nhập lý do hủy (bắt buộc)

---

## 5. Quản Lý Khách

### 5.1 Tạo Khách Mới

1. Khi tạo đặt phòng, chọn **+ Thêm khách mới**
2. Điền thông tin:
   - **Họ và tên** (bắt buộc)
   - **Số điện thoại** (bắt buộc, duy nhất)
   - **Loại giấy tờ**: CCCD / Hộ chiếu / CMND / GPLX
   - **Số giấy tờ**
   - **Quốc tịch**
   - **Ngày sinh**
   - **Địa chỉ**
   - **Email**

3. Nhấn **Lưu**

### 5.2 Tìm Kiếm Khách

1. Vào **Khách hàng** từ menu
2. Nhập từ khóa: tên, số điện thoại, hoặc số CCCD
3. Kết quả hiển thị ngay lập tức

### 5.3 Xem Lịch Sử Khách

1. Nhấn vào khách hàng
2. Tab **Lịch sử** hiển thị:
   - Tổng số lần ở
   - Tổng chi tiêu
   - Danh sách các lần đặt phòng trước

### 5.4 Đánh Dấu Khách VIP

1. Mở chi tiết khách hàng
2. Bật công tắc **Khách VIP**
3. Khách VIP được ưu tiên và có biểu tượng ⭐

---

## 6. Nhận Phòng / Trả Phòng

### 6.1 Check-in (Nhận Phòng)

1. Từ Dashboard, nhấn đặt phòng trong **Check-in hôm nay**
2. Hoặc vào chi tiết đặt phòng > Nhấn **Check-in**
3. Xác nhận thông tin khách
4. (Tùy chọn) Nhập **Tiền cọc**
5. Nhấn **Xác nhận nhận phòng**

**Sau khi check-in:**
- Trạng thái đổi thành **Đang ở**
- Phòng chuyển sang **Có khách** (đỏ)
- Ghi nhận thời gian nhận thực tế

### 6.2 Check-out (Trả Phòng)

1. Từ Dashboard, nhấn đặt phòng trong **Check-out hôm nay**
2. Hoặc vào chi tiết đặt phòng > Nhấn **Check-out**
3. Hệ thống hiển thị:
   - **Tiền phòng**
   - **Phí phát sinh** (minibar, dịch vụ)
   - **Phí trả muộn** (nếu có)
   - **Tiền cọc đã thu**
   - **Còn phải thu**

4. Chọn **Phương thức thanh toán**
5. Nhấn **Xác nhận trả phòng**

**Sau khi check-out:**
- Trạng thái đổi thành **Đã trả phòng**
- Phòng chuyển sang **Đang dọn** (vàng)
- Tự động tạo nhiệm vụ dọn phòng

### 6.3 Check-in Sớm / Check-out Muộn

**Check-in sớm:**
- Nếu khách đến trước giờ quy định (14:00)
- Hệ thống tính phí theo số giờ sớm
- Xác nhận phí với khách trước khi check-in

**Check-out muộn:**
- Nếu khách trả sau giờ quy định (12:00)
- Hệ thống tự động tính phí trả muộn
- Hiển thị trong hóa đơn khi check-out

---

## 7. Tài Chính

### 7.1 Xem Tổng Quan Tài Chính

1. Vào tab **Tài Chính**
2. Xem:
   - **Thu nhập** tháng này
   - **Chi phí** tháng này
   - **Lợi nhuận** = Thu - Chi
   - **Biểu đồ** xu hướng

### 7.2 Ghi Nhận Thu Nhập

1. Nhấn **+ Thu**
2. Chọn **Danh mục**: Tiền phòng, Dịch vụ, Minibar, v.v.
3. Nhập **Số tiền**
4. Chọn **Phương thức**: Tiền mặt, Chuyển khoản, MoMo, VNPay
5. (Tùy chọn) Liên kết với **Đặt phòng**
6. Nhập **Ghi chú**
7. Nhấn **Lưu**

### 7.3 Ghi Nhận Chi Phí

1. Nhấn **+ Chi**
2. Chọn **Danh mục**: Điện, Nước, Vật tư, Lương, v.v.
3. Nhập **Số tiền**
4. Chọn **Phương thức**
5. Nhập **Mô tả**
6. Nhấn **Lưu**

### 7.4 Xem Lịch Sử Giao Dịch

1. Cuộn xuống trong tab **Tài Chính**
2. Lọc theo:
   - **Tất cả** / **Thu** / **Chi**
   - **Khoảng ngày**
   - **Danh mục**

### 7.5 Quản Lý Thanh Toán

**Xem thanh toán của đặt phòng:**
1. Vào chi tiết đặt phòng
2. Tab **Thanh toán** hiển thị:
   - Danh sách các lần thanh toán
   - Tổng đã thu
   - Còn nợ

**Ghi nhận thanh toán:**
1. Nhấn **+ Thanh toán**
2. Nhập số tiền
3. Chọn phương thức
4. Nhấn **Lưu**

### 7.6 Quản Lý Folio (Phí Phòng)

**Xem folio:**
1. Vào chi tiết đặt phòng
2. Tab **Folio** hiển thị tất cả phí:
   - Tiền phòng
   - Minibar
   - Dịch vụ
   - Phí phát sinh

**Thêm phí vào folio:**
1. Nhấn **+ Thêm phí**
2. Chọn loại: Phòng, Minibar, Dịch vụ, Khác
3. Nhập mô tả và số tiền
4. Nhấn **Lưu**

### 7.7 In Hóa Đơn

1. Vào chi tiết đặt phòng (đã check-out)
2. Nhấn **🧾 In hóa đơn**
3. Chọn **Tiền tệ**: VND hoặc USD
4. Xem trước và nhấn **In** hoặc **Chia sẻ**

---

## 8. Housekeeping & Bảo Trì

### 8.1 Xem Nhiệm Vụ Housekeeping

1. Vào **Menu** > **Housekeeping**
2. Xem theo tab:
   - **Hôm nay** - Nhiệm vụ trong ngày
   - **Tất cả** - Toàn bộ nhiệm vụ
   - **Của tôi** - Nhiệm vụ được giao cho bạn

### 8.2 Các Loại Nhiệm Vụ

| Loại | Mô Tả |
|------|-------|
| **Dọn trả phòng** | Dọn sau khi khách check-out |
| **Dọn phòng đang ở** | Dọn hàng ngày cho khách đang ở |
| **Dọn sâu** | Dọn kỹ định kỳ |
| **Kiểm tra** | Kiểm tra phòng |
| **Bảo trì** | Sửa chữa, thay thế |

### 8.3 Hoàn Thành Nhiệm Vụ

1. Nhấn vào nhiệm vụ
2. Đánh dấu các mục trong checklist
3. (Tùy chọn) Chụp ảnh xác nhận
4. Nhập **Ghi chú** nếu có vấn đề
5. Nhấn **Hoàn thành**

### 8.4 Tạo Yêu Cầu Bảo Trì

1. Vào **Menu** > **Bảo trì**
2. Nhấn **+ Yêu cầu mới**
3. Chọn **Phòng** (hoặc "Khu vực chung")
4. Chọn **Danh mục**: Điện, Nước, Điều hòa, Nội thất, v.v.
5. Nhập **Mô tả vấn đề**
6. Chọn **Mức độ ưu tiên**: Thấp, Trung bình, Cao, Khẩn cấp
7. Nhấn **Tạo yêu cầu**

### 8.5 Kiểm Tra Phòng (Room Inspection)

1. Vào **Menu** > **Kiểm tra phòng**
2. Nhấn **+ Kiểm tra mới**
3. Chọn **Phòng** và **Loại kiểm tra**
4. Đánh dấu từng mục trong checklist:
   - ✅ Đạt
   - ❌ Không đạt (nhập ghi chú)
5. Hệ thống tính **Điểm** tự động
6. Nhấn **Lưu**

---

## 9. Minibar & POS

### 9.1 Bán Hàng Minibar

1. Vào **Menu** > **Minibar**
2. Nhấn **+ Bán hàng**
3. Chọn **Phòng** (đang có khách)
4. Chọn các sản phẩm:
   - Nước uống
   - Snack
   - Bia, rượu
5. Nhập số lượng mỗi món
6. Nhấn **Thanh toán** hoặc **Ghi vào Folio**

### 9.2 Xem Doanh Số Minibar

1. Tab **Báo cáo** trong Minibar
2. Xem:
   - Doanh thu theo ngày/tháng
   - Sản phẩm bán chạy
   - Doanh thu theo phòng

---

## 10. Báo Cáo

### 10.1 Truy Cập Báo Cáo

1. Vào **Menu** > **Báo cáo**
2. Chọn loại báo cáo
3. Chọn **Khoảng thời gian**
4. Nhấn **Xem báo cáo**

### 10.2 Các Loại Báo Cáo

| Báo Cáo | Nội Dung |
|---------|----------|
| **Công suất phòng** | Tỷ lệ lấp đầy, xu hướng theo ngày/tuần/tháng |
| **Doanh thu** | Theo phòng, theo nguồn, theo khoảng thời gian |
| **KPI** | RevPAR, ADR, tỷ lệ công suất |
| **Chi phí** | Phân tích theo danh mục |
| **Kênh đặt phòng** | So sánh OTA vs trực tiếp |
| **Khách hàng** | Quốc tịch, khách quay lại |
| **So sánh** | So sánh với tháng/năm trước |

### 10.3 Xuất Báo Cáo

1. Xem báo cáo xong
2. Nhấn **📥 Xuất**
3. Chọn định dạng: **Excel** hoặc **CSV**
4. File được tải về thiết bị

---

## 11. Kiểm Toán Đêm (Night Audit)

### 11.1 Thực Hiện Kiểm Toán Đêm

Thực hiện cuối mỗi ngày (thường sau 23:00):

1. Vào **Menu** > **Kiểm toán đêm**
2. Xem tổng kết ngày:
   - **Phòng đã bán** / **Tổng phòng**
   - **Công suất** (%)
   - **Doanh thu phòng**
   - **Doanh thu khác**
   - **Tổng doanh thu**
   - **Số check-in / check-out**

3. Kiểm tra các mục:
   - ✅ Thanh toán chưa thu
   - ✅ Phòng chưa dọn
   - ✅ Đặt phòng chưa xác nhận

4. Nhấn **Đóng ngày**

### 11.2 Xem Lịch Sử Kiểm Toán

1. Vào **Kiểm toán đêm** > **Lịch sử**
2. Chọn ngày để xem chi tiết
3. Xem ai đã thực hiện kiểm toán

---

## 12. Khai Báo Tạm Trú

### 12.1 Xuất Dữ Liệu Khai Báo

Yêu cầu pháp luật Việt Nam - báo công an về khách lưu trú:

1. Vào **Menu** > **Khai báo tạm trú**
2. Chọn **Khoảng ngày** (thường 1 ngày)
3. Chọn **Định dạng**: CSV hoặc Excel
4. Nhấn **Xuất file**

### 12.2 Thông Tin Trong File

- Họ tên khách
- Số CCCD/Hộ chiếu
- Quốc tịch
- Ngày sinh
- Giới tính
- Ngày check-in / check-out
- Số phòng

---

## 13. Cài Đặt

### 13.1 Cài Đặt Tài Khoản

1. Vào tab **Cài đặt**
2. Nhấn **Tài khoản**
3. Có thể:
   - Đổi mật khẩu
   - Cập nhật thông tin cá nhân

### 13.2 Cài Đặt Hiển Thị

| Cài Đặt | Mô Tả |
|---------|-------|
| **Ngôn ngữ** | Tiếng Việt / English |
| **Giao diện** | Sáng / Tối / Theo hệ thống |
| **Cỡ chữ** | Nhỏ / Vừa / Lớn |

### 13.3 Cài Đặt Thông Báo

Bật/tắt thông báo cho:
- Check-in sắp tới
- Check-out hôm nay
- Thanh toán chưa thu
- Nhiệm vụ housekeeping

### 13.4 Thông Tin Ứng Dụng

- Phiên bản ứng dụng
- Thông tin liên hệ hỗ trợ
- Điều khoản sử dụng

---

## 14. Câu Hỏi Thường Gặp

### ❓ Làm sao để đặt phòng cho khách vãng lai?

1. Nhấn **+ Đặt phòng**
2. Chọn nguồn **Walk-in (Khách vãng lai)**
3. Tạo thông tin khách mới
4. Có thể check-in ngay lập tức

### ❓ Khách muốn đổi phòng?

1. Vào chi tiết đặt phòng đang ở
2. Nhấn **✏️ Sửa**
3. Chọn phòng mới
4. Cập nhật giá nếu khác loại phòng
5. Nhấn **Lưu**

### ❓ Khách trả phòng muộn tính phí thế nào?

- Hệ thống tự động tính khi check-out
- Phí = Số giờ muộn × Giá/giờ của loại phòng
- Hiển thị trong hóa đơn trước khi xác nhận

### ❓ Làm sao biết khách đã thanh toán đủ chưa?

1. Vào chi tiết đặt phòng
2. Xem **Tình trạng thanh toán**:
   - 🟢 **Đã thanh toán đủ**
   - 🟡 **Đã đặt cọc** (còn nợ)
   - 🔴 **Chưa thanh toán**

### ❓ Làm sao xuất hóa đơn cho công ty?

1. Vào đặt phòng đã check-out
2. Nhấn **🧾 In hóa đơn**
3. Chọn **Hóa đơn công ty**
4. Nhập thông tin công ty (tên, MST, địa chỉ)
5. Nhấn **In** hoặc **Gửi email**

### ❓ Phòng bị hỏng, làm sao khóa không cho đặt?

1. Vào chi tiết phòng
2. Đổi trạng thái sang **Bảo trì** hoặc **Khóa**
3. Tạo yêu cầu bảo trì mô tả vấn đề
4. Phòng sẽ không hiển thị khi đặt mới

### ❓ Quên mật khẩu?

1. Liên hệ quản trị viên (Owner)
2. Quản trị viên vào **Cài đặt** > **Quản lý người dùng**
3. Đặt lại mật khẩu cho tài khoản

---

## 📞 Hỗ Trợ

Nếu gặp vấn đề, liên hệ:
- **Email:** support@hoanglam.vn
- **Điện thoại:** 0xxx-xxx-xxx

---

<p align="center">
  <strong>Hoang Lam Heritage Management v1.0</strong><br/>
  © 2026 Hoang Lam Heritage Hotel
</p>
