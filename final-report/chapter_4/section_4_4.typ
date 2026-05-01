#import "../counters.typ": table_counter

== 4.4 Use Case

Sau khi xác định các yêu cầu chức năng và phi chức năng, phần này mô tả các use case cốt lõi của hệ thống SMAP theo góc nhìn mục tiêu sử dụng của người dùng nghiệp vụ. Use case trong phần này không được tách theo tên thành phần kỹ thuật, giao diện kỹ thuật, module hay luồng xử lý nội bộ, mà được tổ chức theo kết quả có giá trị quan sát được đối với tác nhân chính. Cách tiếp cận này giúp phần phân tích hệ thống tập trung vào nhu cầu sử dụng, còn chi tiết hiện thực sẽ được trình bày ở Chương 5.

Trong phạm vi này, các thao tác như tạo campaign, tạo project, khai báo nguồn dữ liệu, cấu hình mục tiêu thu thập và chạy kiểm tra thử được xem là các bước trong cùng một mục tiêu nghiệp vụ: thiết lập một chiến dịch theo dõi đủ điều kiện vận hành. Tương tự, các xử lý nền như thu thập dữ liệu, phân tích dữ liệu hoặc chuẩn bị dữ liệu phục vụ tra cứu không được tách thành use case độc lập cho người dùng, vì đây là hành vi hệ thống hỗ trợ cho các mục tiêu khai thác kết quả. Các cơ chế xác thực, phân quyền và kiểm tra nội bộ cũng được xem là điều kiện tiên quyết hoặc supporting concern cho các use case được bảo vệ, thay vì là một use case nghiệp vụ riêng.

Từ góc nhìn đó, các use case chính của SMAP được gom thành năm nhóm mục tiêu người dùng: thiết lập chiến dịch theo dõi, vận hành chiến dịch, khai thác dữ liệu phân tích, theo dõi trạng thái và nhận cảnh báo, cùng với thiết lập quy tắc cảnh báo khủng hoảng.

#context (align(center)[_Bảng #table_counter.display(): Danh sách Use Case_])
#table_counter.step()

#text()[
  #set par(justify: false)
  #table(
    columns: (0.2fr, 0.40fr, 0.34fr, 0.24fr, 0.68fr),
    stroke: 0.5pt,
    align: (center + horizon, center + horizon, center + horizon, center + horizon, left + horizon),

    table.header([*ID*], [*Tên Use Case*], [*Actor chính*], [*FR nghiệp vụ chính*], [*Mục tiêu nghiệp vụ*]),

    [UC-01],
    [Thiết lập chiến dịch theo dõi],
    [A-01: Nhóm người dùng chuyên môn nội bộ],
    [FR-02, FR-05, FR-06, FR-07],
    [Tạo ngữ cảnh theo dõi và hoàn tất cấu hình đầu vào cần thiết, bao gồm campaign, project, nguồn dữ liệu, mục tiêu thu thập và kiểm tra thử, để chiến dịch đủ điều kiện bước sang giai đoạn vận hành.],

    [UC-02],
    [Vận hành chiến dịch theo dõi],
    [A-01: Nhóm người dùng chuyên môn nội bộ],
    [FR-03, FR-08],
    [Kiểm tra mức độ sẵn sàng và điều khiển trạng thái vận hành của chiến dịch như kích hoạt, tạm dừng, tiếp tục hoặc lưu trữ theo nhu cầu nghiệp vụ.],

    [UC-03],
    [Tra cứu và hỏi đáp dữ liệu phân tích],
    [A-01: Nhóm người dùng chuyên môn nội bộ],
    [FR-10],
    [Khai thác dữ liệu đã được hệ thống xử lý thông qua tìm kiếm, hỏi đáp theo ngữ cảnh, câu trả lời có dẫn chứng và các gợi ý truy vấn tiếp theo.],

    [UC-04],
    [Theo dõi trạng thái và nhận cảnh báo],
    [A-01: Nhóm người dùng chuyên môn nội bộ],
    [FR-11],
    [Nhận các thông báo liên quan đến trạng thái xử lý, sự kiện chiến dịch hoặc cảnh báo quan trọng để kịp thời theo dõi và phản ứng.],

    [UC-05],
    [Thiết lập và quản lý quy tắc cảnh báo khủng hoảng],
    [A-01: Nhóm người dùng chuyên môn nội bộ],
    [FR-04],
    [Thiết lập và quản lý các quy tắc giám sát khủng hoảng như keyword, volume, sentiment hoặc influencer để hệ thống có cơ sở phát hiện và cảnh báo ở các luồng xử lý phía sau.],
  )
]

Các yêu cầu FR-01, FR-09 và FR-12 đóng vai trò hỗ trợ cho các use case được bảo vệ: FR-01 là điều kiện xác thực trước khi người dùng thực hiện thao tác nghiệp vụ, FR-09 cung cấp dữ liệu phân tích cho các mục tiêu khai thác và cảnh báo, còn FR-12 bảo vệ liên thông nội bộ giữa các thành phần hệ thống. Vì vậy, các yêu cầu này không được tách thành use case người dùng độc lập trong bảng trên.

=== 4.4.1 UC-01: Thiết lập chiến dịch theo dõi

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-01_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-01: Thiết lập chiến dịch theo dõi],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: A-01 - Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: A-02 - Nền tảng mạng xã hội
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng thiết lập một chiến dịch theo dõi bằng cách tạo hoặc chọn campaign, tạo project trong campaign đó, khai báo nguồn dữ liệu, cấu hình mục tiêu thu thập và thực hiện kiểm tra thử khi cần để đánh giá khả năng thu thập dữ liệu trước khi vận hành chính thức. Use case này tập trung vào mục tiêu hoàn tất cấu hình đầu vào cho chiến dịch, không bao gồm bước kích hoạt vận hành hay xử lý phân tích phía sau.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (
      y: 0.6em,
    ))[User muốn tạo một chiến dịch theo dõi mới hoặc bổ sung một project theo dõi vào campaign đã tồn tại.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập và có quyền tạo hoặc quản lý campaign/project trong phạm vi làm việc tương ứng.
      2. User đã xác định được mục tiêu theo dõi cơ bản như thương hiệu, chủ đề, đối thủ, nền tảng hoặc phạm vi dữ liệu cần quan sát.
      3. Hệ thống có thể lưu cấu hình và kiểm tra nguồn dữ liệu khi kiểm tra thử được yêu cầu.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Campaign và project được tạo mới hoặc project được liên kết với campaign đã tồn tại.
      2. Nguồn dữ liệu và một hoặc nhiều mục tiêu thu thập được lưu theo project tương ứng.
      3. Nếu tổ hợp nguồn dữ liệu và mục tiêu thu thập yêu cầu kiểm tra, kết quả kiểm tra thử mới nhất và lịch sử kiểm tra được ghi nhận.
      4. Trạng thái cấu hình của project hoặc nguồn dữ liệu phản ánh mức độ sẵn sàng để chuyển sang bước vận hành.
      5. Nếu cấu hình hoặc kiểm tra thử không đạt yêu cầu, chiến dịch vẫn chưa đủ điều kiện vận hành chính thức cho đến khi user điều chỉnh lại.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User bắt đầu luồng thiết lập chiến dịch theo dõi.
      2. User tạo campaign mới hoặc chọn một campaign đã tồn tại làm ngữ cảnh nghiệp vụ.
      3. User nhập thông tin project như tên, mô tả, đối tượng theo dõi, domain hoặc phạm vi dữ liệu cần quan sát.
      4. Hệ thống kiểm tra dữ liệu đầu vào và lưu campaign/project tương ứng.
      5. User khai báo nguồn dữ liệu cho project, bao gồm loại nguồn dữ liệu, nền tảng và các thông tin cấu hình cần thiết.
      6. User thêm một hoặc nhiều mục tiêu thu thập phù hợp với nguồn dữ liệu, chẳng hạn keyword, profile hoặc post URL.
      7. Hệ thống kiểm tra loại mục tiêu, dữ liệu đầu vào và lưu mục tiêu ở trạng thái phù hợp trước khi vận hành.
      8. Nếu tổ hợp nguồn dữ liệu và mục tiêu thu thập cần kiểm tra, user yêu cầu chạy kiểm tra thử.
      9. Hệ thống thực hiện kiểm tra thử, thu thập dữ liệu mẫu hoặc xác nhận khả năng truy cập nguồn dữ liệu.
      10. Hệ thống lưu kết quả kiểm tra thử, cập nhật chỉ báo sẵn sàng và hiển thị kết quả để user đánh giá.
      11. User xác nhận cấu hình đã đủ dùng hoặc quay lại chỉnh sửa các thông tin chưa đạt yêu cầu.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Tạo project trong campaign đã có* \
      Tại Bước 2 của luồng cơ bản:
      - 2A.1. User chọn một campaign đã tồn tại thay vì tạo campaign mới.
      - 2A.2. Hệ thống sử dụng campaign đó làm ngữ cảnh nghiệp vụ cho project mới.
      - 2A.3. Luồng tiếp tục tại bước nhập thông tin project.

      *Cấu hình nhiều nguồn dữ liệu hoặc nhiều mục tiêu thu thập* \
      Tại Bước 5 hoặc Bước 6 của luồng cơ bản:
      - 6A.1. User khai báo thêm nguồn dữ liệu hoặc mục tiêu thu thập khác trong cùng project.
      - 6A.2. Hệ thống kiểm tra và lưu từng cấu hình hợp lệ.
      - 6A.3. User có thể chạy kiểm tra thử cho từng tổ hợp cần kiểm tra.

      *Tổ hợp nguồn dữ liệu không yêu cầu kiểm tra thử* \
      Tại Bước 8 của luồng cơ bản:
      - 8A.1. Hệ thống xác định tổ hợp nguồn dữ liệu và mục tiêu thu thập hiện tại không yêu cầu kiểm tra thử bắt buộc.
      - 8A.2. User có thể bỏ qua bước kiểm tra thử và tiếp tục hoàn tất cấu hình.
      - 8A.3. Mức độ sẵn sàng được xác định dựa trên các điều kiện cấu hình còn lại.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *User chưa được xác thực hoặc không đủ quyền* \
      Trước hoặc trong Bước 1 của luồng cơ bản, nếu user chưa có phiên hợp lệ hoặc không có quyền thao tác:
      - 1.E.1. Hệ thống từ chối truy cập chức năng thiết lập chiến dịch.
      - 1.E.2. User cần đăng nhập lại hoặc sử dụng tài khoản có quyền phù hợp.
      - Kết thúc use case.

      *Dữ liệu campaign, project, nguồn dữ liệu hoặc mục tiêu thu thập không hợp lệ* \
      Tại Bước 4, Bước 5 hoặc Bước 7 của luồng cơ bản, nếu dữ liệu đầu vào thiếu hoặc sai định dạng:
      - 7.E.1. Hệ thống từ chối lưu phần cấu hình không hợp lệ.
      - 7.E.2. Hệ thống hiển thị lỗi tại các trường liên quan.
      - 7.E.3. User chỉnh sửa dữ liệu và gửi lại.
      - Tiếp tục tại bước tương ứng.

      *Kiểm tra thử thất bại hoặc không đạt yêu cầu* \
      Tại Bước 9 hoặc Bước 10 của luồng cơ bản, nếu không thu thập được dữ liệu mẫu hoặc kết quả không usable:
      - 10.E.1. Hệ thống ghi nhận kết quả kiểm tra thử thất bại hoặc cảnh báo tương ứng.
      - 10.E.2. Cấu hình chưa được xem là đủ điều kiện vận hành đối với tổ hợp yêu cầu kiểm tra thử.
      - 10.E.3. User cần điều chỉnh nguồn dữ liệu hoặc mục tiêu thu thập trước khi chạy lại kiểm tra thử.
      - Kết thúc use case.

      *Lỗi lưu cấu hình hoặc xử lý kiểm tra thử* \
      Tại Bước 4, Bước 7 hoặc Bước 10 của luồng cơ bản, nếu hệ thống không thể lưu dữ liệu hoặc hoàn tất kiểm tra thử:
      - 10.E.4. Hệ thống thông báo thao tác thiết lập chưa hoàn tất.
      - 10.E.5. User có thể thử lại sau hoặc lưu cấu hình nháp nếu hệ thống cho phép.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Phạm vi*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này cố ý gom campaign, project, nguồn dữ liệu, mục tiêu thu thập và kiểm tra thử thành một mục tiêu nghiệp vụ thống nhất theo góc nhìn người dùng. Xác thực và phân quyền là điều kiện tiên quyết; kích hoạt vận hành, thu thập dữ liệu chính thức và xử lý phân tích thuộc các use case hoặc luồng hệ thống khác.
    ],
  )
]

=== 4.4.2 UC-02: Vận hành chiến dịch theo dõi

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-02_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-02: Vận hành chiến dịch theo dõi],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: A-01 - Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng vận hành một chiến dịch theo dõi đã được thiết lập bằng cách kiểm tra mức độ sẵn sàng và thực hiện các thao tác như kích hoạt, tạm dừng, tiếp tục hoặc lưu trữ. Use case này bắt đầu khi cấu hình đầu vào đã có đủ thông tin cần thiết và tập trung vào việc chuyển chiến dịch từ trạng thái cấu hình sang trạng thái vận hành có kiểm soát.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (
      y: 0.6em,
    ))[User muốn kiểm tra mức độ sẵn sàng hoặc thay đổi trạng thái vận hành của một chiến dịch theo dõi đã được thiết lập.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập và có quyền quản lý chiến dịch theo dõi tương ứng.
      2. Campaign và project liên quan đã tồn tại trong hệ thống.
      3. Chiến dịch đã có cấu hình đầu vào cần thiết như nguồn dữ liệu, mục tiêu thu thập và bằng chứng kiểm tra nếu luồng vận hành yêu cầu.
      4. User đã chọn thao tác vận hành cần thực hiện.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Nếu thao tác hợp lệ và thành công, trạng thái vận hành của chiến dịch được cập nhật theo yêu cầu của user.
      2. Nếu user chỉ kiểm tra mức độ sẵn sàng, hệ thống trả về kết quả đánh giá mà không thay đổi trạng thái vận hành.
      3. Hoạt động thu thập dữ liệu của chiến dịch được bắt đầu, tạm dừng, tiếp tục hoặc giữ nguyên phù hợp với trạng thái mới.
      4. Nếu thao tác không hợp lệ hoặc mức độ sẵn sàng không đạt, trạng thái chiến dịch không bị thay đổi ngoài các thông tin lỗi hoặc cảnh báo cần hiển thị cho user.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User mở chiến dịch hoặc project cần vận hành.
      2. User yêu cầu kiểm tra mức độ sẵn sàng hoặc chọn thao tác kích hoạt chiến dịch.
      3. Hệ thống kiểm tra quyền thao tác và trạng thái hiện tại của chiến dịch.
      4. Hệ thống đánh giá mức độ sẵn sàng dựa trên cấu hình nguồn dữ liệu, mục tiêu thu thập, trạng thái cấu hình và kết quả kiểm tra thử cần thiết.
      5. Nếu mức độ sẵn sàng đạt yêu cầu, user xác nhận thao tác kích hoạt.
      6. Hệ thống chuyển chiến dịch sang trạng thái hoạt động và bắt đầu hoạt động thu thập dữ liệu tương ứng.
      7. Hệ thống ghi nhận trạng thái vận hành mới và trả kết quả thành công cho user.
      8. User có thể theo dõi trạng thái xử lý hoặc tiếp tục khai thác các thông tin liên quan ở các use case sau.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Chỉ kiểm tra mức độ sẵn sàng* \
      Thay cho Bước 5 của luồng cơ bản:
      - R1. User chỉ yêu cầu xem chiến dịch đã đủ điều kiện vận hành hay chưa.
      - R2. Hệ thống trả về danh sách điều kiện đạt hoặc chưa đạt.
      - R3. Không có thay đổi trạng thái vận hành nào được thực hiện.
      - Kết thúc use case.

      *Tạm dừng chiến dịch đang hoạt động* \
      Thay cho Bước 2 của luồng cơ bản:
      - P1. User chọn thao tác tạm dừng cho chiến dịch đang hoạt động.
      - P2. Hệ thống kiểm tra trạng thái hiện tại và quyền thao tác.
      - P3. Hệ thống chuyển chiến dịch sang trạng thái tạm dừng và dừng hoạt động thu thập dữ liệu phù hợp.
      - P4. Hệ thống trả kết quả tạm dừng thành công cho user.
      - Kết thúc use case.

      *Tiếp tục chiến dịch đã tạm dừng* \
      Thay cho Bước 2 của luồng cơ bản:
      - RS1. User chọn thao tác tiếp tục cho chiến dịch đang tạm dừng.
      - RS2. Hệ thống kiểm tra lại mức độ sẵn sàng trước khi cho phép vận hành tiếp.
      - RS3. Nếu đạt yêu cầu, hệ thống chuyển chiến dịch về trạng thái hoạt động.
      - RS4. Hệ thống trả kết quả tiếp tục thành công cho user.
      - Kết thúc use case.

      *Lưu trữ chiến dịch* \
      Thay cho Bước 2 của luồng cơ bản:
      - A1. User chọn lưu trữ một chiến dịch không còn cần vận hành thường xuyên.
      - A2. Hệ thống chuyển chiến dịch sang trạng thái lưu trữ sau khi xử lý các hoạt động đang chạy nếu cần.
      - A3. Hệ thống trả kết quả lưu trữ thành công cho user.
      - Kết thúc use case.

      *Mở lại chiến dịch đã lưu trữ* \
      Thay cho Bước 2 của luồng cơ bản:
      - U1. User chọn mở lại một chiến dịch đã được lưu trữ.
      - U2. Hệ thống đưa chiến dịch về trạng thái cho phép kiểm tra trước khi vận hành lại.
      - U3. Hệ thống trả kết quả mở lại thành công cho user.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Mức độ sẵn sàng không đạt yêu cầu* \
      Tại Bước 4 của luồng cơ bản hoặc RS2 của luồng tiếp tục, nếu chiến dịch chưa đủ điều kiện vận hành:
      - 4.E.1. Hệ thống từ chối kích hoạt hoặc tiếp tục chiến dịch.
      - 4.E.2. Hệ thống trả về các điều kiện chưa đạt như thiếu nguồn dữ liệu, thiếu mục tiêu thu thập phù hợp, cấu hình chưa sẵn sàng hoặc kiểm tra thử không đạt.
      - 4.E.3. User cần quay lại use case thiết lập chiến dịch để điều chỉnh cấu hình.
      - Kết thúc use case.

      *Thao tác không hợp lệ với trạng thái hiện tại* \
      Tại Bước 3 của luồng cơ bản hoặc các luồng thay thế, nếu trạng thái chiến dịch không cho phép thao tác được chọn:
      - 3.E.1. Hệ thống từ chối thao tác vận hành.
      - 3.E.2. Hệ thống hiển thị trạng thái hiện tại và thao tác hợp lệ có thể thực hiện.
      - Kết thúc use case.

      *User không đủ quyền vận hành chiến dịch* \
      Tại Bước 3 của luồng cơ bản, nếu user không có quyền quản lý chiến dịch:
      - 3.E.3. Hệ thống từ chối yêu cầu thay đổi trạng thái.
      - 3.E.4. Không có thay đổi nào được áp dụng lên chiến dịch.
      - Kết thúc use case.

      *Lỗi áp dụng hoặc lưu trạng thái vận hành* \
      Tại Bước 6 hoặc Bước 7 của luồng cơ bản, nếu hệ thống không thể áp dụng trạng thái vận hành hoặc không thể lưu trạng thái mới:
      - 7.E.1. Hệ thống thông báo thao tác vận hành chưa hoàn tất.
      - 7.E.2. Trạng thái chiến dịch được giữ nguyên hoặc được đưa về trạng thái an toàn gần nhất.
      - 7.E.3. User có thể tải lại trạng thái và thử lại sau.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Phạm vi*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này mô tả mục tiêu vận hành chiến dịch theo góc nhìn user, không mô tả chi tiết cách hệ thống hiện thực các thao tác vận hành. Các chi tiết kỹ thuật đó thuộc phần thiết kế hệ thống và luồng xử lý ở Chương 5.
    ],
  )
]

=== 4.4.3 UC-03: Tra cứu và hỏi đáp dữ liệu phân tích

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-03_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-03: Tra cứu và hỏi đáp dữ liệu phân tích],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: A-01 - Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng tra cứu dữ liệu phân tích đã được hệ thống xử lý hoặc đặt câu hỏi theo ngữ cảnh chiến dịch để nhận câu trả lời có dẫn chứng. Use case này giúp người dùng khai thác dữ liệu đã thu thập và phân tích, thay vì mô tả cách hệ thống chuẩn bị hoặc lưu trữ dữ liệu ở phía sau.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (
      y: 0.6em,
    ))[User nhập truy vấn tìm kiếm, đặt câu hỏi trong trợ lý dữ liệu hoặc mở lại một hội thoại phân tích đã có.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập và có quyền truy cập chiến dịch hoặc project tương ứng.
      2. Phạm vi tra cứu đã được xác định theo campaign, project hoặc bộ lọc tương đương.
      3. Hệ thống có dữ liệu phân tích phù hợp để truy vấn hoặc có khả năng phản hồi rõ rằng chưa có dữ liệu liên quan.
      4. Nội dung truy vấn của user không rỗng và nằm trong giới hạn hợp lệ.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. User nhận được danh sách kết quả tra cứu hoặc câu trả lời phân tích phù hợp với phạm vi được chọn.
      2. Nếu là hỏi đáp, hệ thống lưu hội thoại và các nội dung trao đổi mới khi thao tác hoàn tất thành công.
      3. Nếu không có dữ liệu phù hợp, hệ thống trả thông báo hoặc kết quả rỗng có kiểm soát thay vì suy diễn không có căn cứ.
      4. Dữ liệu campaign, project và kết quả phân tích gốc không bị thay đổi bởi thao tác tra cứu hoặc hỏi đáp.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User mở chức năng tra cứu hoặc trợ lý dữ liệu trong phạm vi một campaign hay project.
      2. Hệ thống hiển thị ô nhập truy vấn, bộ lọc và ngữ cảnh hiện tại.
      3. User nhập câu hỏi hoặc từ khóa cần tra cứu, có thể bổ sung bộ lọc như thời gian, nền tảng hoặc chủ đề.
      4. Hệ thống kiểm tra quyền truy cập, nội dung truy vấn và phạm vi dữ liệu được phép sử dụng.
      5. Hệ thống tìm các kết quả phân tích liên quan trong phạm vi đã chọn.
      6. Hệ thống sắp xếp, tổng hợp và chuẩn bị phần dẫn chứng hoặc metadata cần thiết để user kiểm chứng kết quả.
      7. Nếu user đang hỏi đáp, hệ thống tạo câu trả lời dựa trên các kết quả liên quan đã truy xuất.
      8. Hệ thống trả kết quả tra cứu hoặc câu trả lời cho user kèm dẫn chứng, gợi ý hoặc thông tin bổ trợ nếu có.
      9. Nếu là hội thoại, hệ thống lưu câu hỏi của user, câu trả lời và ngữ cảnh liên quan để user có thể tiếp tục hỏi sau đó.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Tra cứu không qua hội thoại* \
      Thay cho Bước 7 của luồng cơ bản:
      - S1. User chỉ yêu cầu tìm kiếm danh sách kết quả, không yêu cầu hệ thống sinh câu trả lời tổng hợp.
      - S2. Hệ thống trả về danh sách kết quả, điểm liên quan, nguồn và các thống kê tổng hợp nếu có.
      - Kết thúc use case.

      *Tiếp tục hội thoại đã tồn tại* \
      Tại Bước 1 của luồng cơ bản:
      - C1. User mở một hội thoại phân tích đã có.
      - C2. Hệ thống nạp lịch sử hội thoại trong giới hạn cho phép.
      - C3. Câu hỏi mới của user được xử lý cùng ngữ cảnh hội thoại trước đó.
      - Tiếp tục tại bước 3.

      *Tinh chỉnh truy vấn sau khi xem kết quả* \
      Sau Bước 8 của luồng cơ bản:
      - F1. User thay đổi từ khóa, bộ lọc hoặc phạm vi campaign/project để thu hẹp kết quả.
      - F2. Hệ thống thực hiện lại truy vấn với điều kiện mới.
      - Tiếp tục tại bước 4.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Truy vấn không hợp lệ* \
      Tại Bước 4 của luồng cơ bản, nếu câu hỏi rỗng, quá ngắn, quá dài hoặc chứa bộ lọc không hợp lệ:
      - 4.E.1. Hệ thống từ chối yêu cầu tra cứu.
      - 4.E.2. Hệ thống hiển thị lý do để user chỉnh sửa truy vấn.
      - Tiếp tục tại bước 3.

      *User không có quyền truy cập phạm vi dữ liệu* \
      Tại Bước 4 của luồng cơ bản, nếu user không có quyền với campaign hoặc project được chọn:
      - 4.E.3. Hệ thống từ chối yêu cầu.
      - 4.E.4. Không có dữ liệu phân tích nào được trả về cho user.
      - Kết thúc use case.

      *Không có dữ liệu phù hợp* \
      Tại Bước 5 hoặc Bước 6 của luồng cơ bản, nếu hệ thống không tìm được dữ liệu liên quan:
      - 6.E.1. Hệ thống trả kết quả rỗng hoặc thông báo chưa có đủ ngữ cảnh.
      - 6.E.2. Hệ thống không sinh câu trả lời khẳng định khi thiếu căn cứ dữ liệu.
      - Kết thúc use case.

      *Không thể hoàn tất hỏi đáp hoặc lưu hội thoại* \
      Tại Bước 7 hoặc Bước 9 của luồng cơ bản, nếu hệ thống không tạo được câu trả lời hoặc không lưu được hội thoại:
      - 9.E.1. Hệ thống thông báo thao tác chưa hoàn tất.
      - 9.E.2. Nếu kết quả tra cứu đã có, hệ thống có thể vẫn hiển thị phần kết quả không phụ thuộc vào hội thoại.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Phạm vi*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này chỉ mô tả việc user khai thác dữ liệu phân tích. Các bước chuẩn bị dữ liệu phục vụ tra cứu, truy xuất ngữ cảnh hoặc sinh câu trả lời là chi tiết thiết kế kỹ thuật và không được tách thành use case người dùng riêng trong mục này.
    ],
  )
]

=== 4.4.4 UC-04: Theo dõi trạng thái và nhận cảnh báo

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-04_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-04: Theo dõi trạng thái và nhận cảnh báo],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: A-01 - Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng theo dõi trạng thái vận hành của chiến dịch, project hoặc nguồn dữ liệu và nhận các thông báo quan trọng khi có thay đổi trạng thái, lỗi xử lý hoặc cảnh báo nghiệp vụ. Use case này tập trung vào việc giúp user nắm tình hình và phản ứng kịp thời, không mô tả chi tiết cơ chế truyền sự kiện nội bộ.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (
      y: 0.6em,
    ))[User mở màn hình theo dõi trạng thái hoặc hệ thống phát sinh thông báo, cảnh báo liên quan đến phạm vi user được phép theo dõi.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập và có quyền xem campaign, project hoặc phạm vi cảnh báo tương ứng.
      2. Hệ thống có thông tin trạng thái hoặc sự kiện cảnh báo cần hiển thị cho user.
      3. Nếu user muốn nhận thông báo trong phiên đang hoạt động, phiên làm việc của user đang hợp lệ.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. User nhìn thấy trạng thái hiện tại, lịch sử gần nhất hoặc thông báo liên quan đến phạm vi được chọn.
      2. Cảnh báo hoặc thông báo phù hợp được hiển thị cho user nếu có sự kiện tương ứng.
      3. Nếu không có sự kiện mới, hệ thống vẫn hiển thị trạng thái hiện tại hoặc thông báo không có cảnh báo mới.
      4. User có đủ thông tin để quyết định thao tác tiếp theo nếu cần.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User mở dashboard hoặc khu vực theo dõi của một campaign hay project.
      2. Hệ thống kiểm tra quyền truy cập và xác định phạm vi trạng thái cần hiển thị.
      3. Hệ thống hiển thị trạng thái hiện tại của các đối tượng liên quan như campaign, project, nguồn dữ liệu hoặc quá trình xử lý.
      4. Khi có trạng thái mới, lỗi xử lý hoặc cảnh báo nghiệp vụ trong phạm vi user được phép theo dõi, hệ thống cập nhật nội dung cần thông báo.
      5. Hệ thống phân loại thông báo theo loại sự kiện, mức độ nghiêm trọng và đối tượng liên quan.
      6. Nếu user đang có phiên theo dõi hoặc nhận thông báo phù hợp, hệ thống hiển thị thông báo hoặc cảnh báo trên giao diện.
      7. User xem nội dung tóm tắt gồm mức độ, thời điểm và campaign/project liên quan.
      8. User mở chi tiết cảnh báo hoặc điều hướng tới campaign/project liên quan để xem thêm thông tin.
      9. Hệ thống hiển thị chi tiết trạng thái hoặc cảnh báo để user quyết định thao tác tiếp theo ở use case phù hợp.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *User chỉ xem trạng thái hiện tại* \
      Thay cho Bước 4 của luồng cơ bản:
      - S1. Không có sự kiện mới phát sinh trong thời điểm user truy cập.
      - S2. Hệ thống hiển thị trạng thái hiện tại và thời điểm cập nhật gần nhất.
      - Kết thúc use case.

      *Không có phiên nhận thông báo hợp lệ* \
      Tại Bước 6 của luồng cơ bản:
      - R1. User không có phiên theo dõi hoặc nhận thông báo hợp lệ ở thời điểm thông báo được phát sinh.
      - R2. Hệ thống không hiển thị thông báo cho phiên đó.
      - R3. User vẫn có thể xem trạng thái hiện tại khi tải lại hoặc mở lại màn hình theo dõi.
      - Kết thúc use case.

      *Lọc hoặc ưu tiên cảnh báo* \
      Tại Bước 7 của luồng cơ bản:
      - F1. User chọn bộ lọc theo campaign, project, mức độ nghiêm trọng hoặc loại cảnh báo.
      - F2. Hệ thống chỉ hiển thị các cảnh báo phù hợp với điều kiện lọc.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *User không có quyền xem trạng thái hoặc cảnh báo* \
      Tại Bước 2 của luồng cơ bản, nếu user không có quyền với phạm vi được chọn:
      - 2.E.1. Hệ thống từ chối hiển thị thông tin trạng thái hoặc cảnh báo.
      - 2.E.2. Không có dữ liệu nào ngoài phạm vi quyền được trả về.
      - Kết thúc use case.

      *Thông báo hoặc cảnh báo không thể hiển thị đầy đủ* \
      Tại Bước 5 của luồng cơ bản, nếu nội dung thông báo thiếu thông tin cần thiết để hiển thị đáng tin cậy:
      - 5.E.1. Hệ thống bỏ qua thông báo lỗi hoặc hiển thị theo dạng an toàn nếu phù hợp.
      - 5.E.2. User không nhận thông tin cảnh báo không đáng tin cậy.
      - Kết thúc use case.

      *Không thể lấy trạng thái hiện tại* \
      Tại Bước 3 hoặc Bước 9 của luồng cơ bản, nếu hệ thống không truy xuất được trạng thái hiện tại:
      - 9.E.1. Hệ thống hiển thị thông báo không thể tải trạng thái.
      - 9.E.2. User có thể thử tải lại sau.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Phạm vi*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này bao phủ nhu cầu theo dõi và nhận biết sự kiện từ phía user. Các thao tác thay đổi trạng thái vận hành thuộc UC-02. Chi tiết kỹ thuật về kênh truyền thông báo thuộc phần thiết kế hệ thống ở Chương 5.
    ],
  )
]

=== 4.4.5 UC-05: Thiết lập và quản lý quy tắc cảnh báo khủng hoảng

#context (align(center)[_Bảng #table_counter.display(): Use Case UC-05_])
#table_counter.step()

#text()[
  #set par(justify: true)
  #table(
    columns: (auto, 1fr, auto, 1fr),
    stroke: 0.5pt,
    align: (left + top, left + top, left + top, left + top),

    table.cell(align: center + horizon, inset: (y: 0.8em))[*Use Case name*],
    table.cell(colspan: 3, align: center + horizon)[UC-05: Thiết lập và quản lý quy tắc cảnh báo khủng hoảng],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Actors*],
    table.cell(colspan: 3)[
      - Primary Actor: A-01 - Nhóm người dùng chuyên môn nội bộ
      - Secondary Actor: Không có
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Description*],
    table.cell(
      colspan: 3,
    )[Người dùng thiết lập, xem, cập nhật hoặc xóa các quy tắc cảnh báo khủng hoảng cho một project. Các quy tắc này xác định điều kiện cần theo dõi như keyword, volume, sentiment hoặc influencer để hệ thống có cơ sở phát hiện và cảnh báo ở các luồng vận hành sau đó.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Trigger*],
    table.cell(colspan: 3, align: horizon, inset: (
      y: 0.6em,
    ))[User mở chức năng cấu hình cảnh báo khủng hoảng của một project và yêu cầu xem, lưu, cập nhật hoặc xóa bộ quy tắc.],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Preconditions*],
    table.cell(colspan: 3, inset: (y: 0.6em), align: horizon)[
      1. User đã đăng nhập và có quyền quản lý project tương ứng.
      2. User đã chọn project cần thiết lập hoặc quản lý quy tắc cảnh báo khủng hoảng.
      3. User có thông tin điều kiện cảnh báo muốn thiết lập hoặc có nhu cầu xem cấu hình hiện tại.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Postconditions*],
    table.cell(colspan: 3)[
      1. Bộ quy tắc cảnh báo khủng hoảng được tạo mới hoặc cập nhật nếu dữ liệu hợp lệ.
      2. User có thể xem lại cấu hình đã lưu cho project.
      3. Nếu user xóa cấu hình, project không còn bộ quy tắc cảnh báo khủng hoảng tương ứng.
      4. Quy tắc hợp lệ trở thành đầu vào cho các luồng giám sát và phát cảnh báo sau này.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Normal Flows*],
    table.cell(colspan: 3, inset: (y: 0.6em))[
      1. User mở trang thiết lập cảnh báo khủng hoảng của một project.
      2. Hệ thống kiểm tra quyền quản lý project và nạp cấu hình hiện có nếu đã được thiết lập.
      3. Hệ thống hiển thị các nhóm quy tắc có thể cấu hình như keyword, volume, sentiment hoặc influencer.
      4. User bật một hoặc nhiều nhóm quy tắc và nhập điều kiện cảnh báo tương ứng.
      5. User gửi yêu cầu lưu cấu hình.
      6. Hệ thống kiểm tra project, quyền thao tác và tính hợp lệ của từng nhóm quy tắc được bật.
      7. Nếu dữ liệu hợp lệ, hệ thống lưu bộ quy tắc cảnh báo khủng hoảng cho project.
      8. Hệ thống trả cấu hình đã lưu thành công để user xác nhận.
      9. User có thể quay lại màn hình theo dõi trạng thái và cảnh báo để quan sát kết quả trong quá trình vận hành.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Alternative Flows*],
    table.cell(colspan: 3)[
      *Xem cấu hình hiện có* \
      Thay cho Bước 4 của luồng cơ bản:
      - D1. User chỉ muốn xem cấu hình cảnh báo khủng hoảng đang áp dụng.
      - D2. Hệ thống hiển thị cấu hình hiện có hoặc thông báo chưa có cấu hình.
      - D3. Không phát sinh thao tác lưu mới.
      - Kết thúc use case.

      *Chỉ bật một phần nhóm quy tắc* \
      Tại Bước 4 của luồng cơ bản:
      - P1. User chỉ bật một số nhóm quy tắc cần thiết thay vì cấu hình toàn bộ nhóm điều kiện.
      - P2. Hệ thống chỉ validate và lưu các nhóm quy tắc được bật.
      - Tiếp tục tại bước 5.

      *Xóa cấu hình cảnh báo khủng hoảng* \
      Thay cho Bước 5 của luồng cơ bản:
      - X1. User chọn xóa cấu hình cảnh báo khủng hoảng của project.
      - X2. Hệ thống yêu cầu xác nhận thao tác xóa nếu giao diện có bước xác nhận.
      - X3. Hệ thống xóa cấu hình tương ứng khỏi project.
      - X4. Hệ thống trả kết quả xóa thành công.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Exceptions*],
    table.cell(colspan: 3)[
      *Project không hợp lệ hoặc user không có quyền* \
      Tại Bước 2 hoặc Bước 6 của luồng cơ bản, nếu project không tồn tại hoặc user không có quyền quản lý:
      - 6.E.1. Hệ thống từ chối thao tác cấu hình.
      - 6.E.2. Không có quy tắc nào được tạo, cập nhật hoặc xóa.
      - Kết thúc use case.

      *Dữ liệu quy tắc không hợp lệ* \
      Tại Bước 6 của luồng cơ bản, nếu không có nhóm quy tắc nào được bật hoặc một nhóm được bật nhưng thiếu điều kiện bắt buộc:
      - 6.E.3. Hệ thống trả lỗi validation cho nhóm quy tắc liên quan.
      - 6.E.4. User chỉnh sửa cấu hình và gửi lại.
      - Tiếp tục tại bước 4.

      *Cấu hình cần xem hoặc xóa không tồn tại* \
      Trong luồng xem hoặc xóa cấu hình, nếu project chưa có bộ quy tắc cảnh báo khủng hoảng:
      - D.E.1. Hệ thống thông báo chưa có cấu hình tương ứng.
      - D.E.2. Với thao tác xóa, không có thay đổi nào được thực hiện.
      - Kết thúc use case.

      *Không thể lưu hoặc xóa cấu hình* \
      Tại Bước 7 của luồng cơ bản hoặc X3 của luồng xóa, nếu hệ thống không thể hoàn tất thao tác:
      - 7.E.1. Hệ thống thông báo thao tác cấu hình chưa thành công.
      - 7.E.2. User có thể thử lại sau.
      - Kết thúc use case.
    ],

    table.cell(align: center + horizon, inset: (y: 0.6em))[*Phạm vi*],
    table.cell(colspan: 3, align: horizon, inset: (y: 0.8em))[
      Use case này chỉ bao phủ việc người dùng thiết lập và quản lý quy tắc cảnh báo khủng hoảng. Việc phát hiện khủng hoảng trong quá trình vận hành và việc phân phối cảnh báo cho user thuộc các luồng xử lý hệ thống và được user quan sát thông qua UC-04.
    ],
  )
]
