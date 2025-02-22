#!/bin/bash

# Hàm hiển thị hướng dẫn sử dụng
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type <file|folder>         Kiểu nguồn cần backup (bắt buộc)"
    echo "  -p, --source <source_path>         Đường dẫn đến file hoặc folder cần backup (bắt buộc)"
    echo "  -d, --destination <dest_path>      Đường dẫn đến thư mục lưu backup (bắt buộc)"
    echo "  -a, --archive-all <yes|no>         Nếu nguồn là folder, xác định nén toàn bộ folder (bao gồm tên folder) hay chỉ nội dung bên trong (mặc định: yes)"
    echo "  -o, --overwrite <yes|no>           Ghi đè file backup nếu tồn tại (mặc định: no, sử dụng timestamp)"
    echo "  -k, --keep <number>                Số lượng file backup mới nhất cần giữ lại (mặc định: 0, không xóa)"
    echo "  -h, --help                         Hiển thị hướng dẫn sử dụng"
    exit 1
}

# Giá trị mặc định
ARCHIVE_ALL="yes"
OVERWRITE="no"
KEEP_COUNT=0

# Phân tích tham số dòng lệnh (hỗ trợ short và long options)
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -t|--type)
            TYPE="$2"
            shift 2
            ;;
        -p|--source)
            SOURCE_PATH="$2"
            shift 2
            ;;
        -d|--destination)
            DESTINATION_PATH="$2"
            shift 2
            ;;
        -a|--archive-all)
            ARCHIVE_ALL="$2"
            shift 2
            ;;
        -o|--overwrite)
            OVERWRITE="$2"
            shift 2
            ;;
        -k|--keep)
            KEEP_COUNT="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)    # Tùy chọn không hợp lệ
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Kiểm tra các tham số bắt buộc
if [[ -z "$TYPE" || -z "$SOURCE_PATH" || -z "$DESTINATION_PATH" ]]; then
    echo "Error: Thiếu tham số bắt buộc."
    usage
fi

# Xác nhận rằng nguồn tồn tại và đúng loại
if [[ "$TYPE" == "folder" ]]; then
    if [[ ! -d "$SOURCE_PATH" ]]; then
        echo "Error: Đường dẫn nguồn không phải là folder hoặc không tồn tại: $SOURCE_PATH"
        exit 1
    fi
elif [[ "$TYPE" == "file" ]]; then
    if [[ ! -f "$SOURCE_PATH" ]]; then
        echo "Error: Đường dẫn nguồn không phải là file hoặc không tồn tại: $SOURCE_PATH"
        exit 1
    fi
else
    echo "Error: Giá trị của --type phải là 'file' hoặc 'folder'."
    exit 1
fi

# Đảm bảo thư mục đích tồn tại
mkdir -p "$DESTINATION_PATH"

# Xác định tên file backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BASENAME=$(basename "$SOURCE_PATH")
if [[ "$OVERWRITE" == "yes" ]]; then
    BACKUP_FILE="$DESTINATION_PATH/${BASENAME}.tar.gz"
else
    BACKUP_FILE="$DESTINATION_PATH/${BASENAME}_$TIMESTAMP.tar.gz"
fi

# Thực hiện backup dựa theo loại nguồn và tham số archive-all
if [[ "$TYPE" == "folder" ]]; then
    if [[ "$ARCHIVE_ALL" == "yes" ]]; then
        # Nén toàn bộ folder (bao gồm tên folder)
        tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_PATH")" "$BASENAME"
    else
        # Chỉ nén nội dung bên trong folder
        tar -czf "$BACKUP_FILE" -C "$SOURCE_PATH" .
    fi
else
    # Backup file
    tar -czf "$BACKUP_FILE" -C "$(dirname "$SOURCE_PATH")" "$BASENAME"
fi

if [[ $? -eq 0 ]]; then
    echo "Backup created: $BACKUP_FILE"
else
    echo "Backup failed"
    exit 1
fi

# Cleanup: Xóa các file backup cũ nếu KEEP_COUNT được đặt (> 0)
if [[ "$KEEP_COUNT" -gt 0 ]]; then
    if [[ "$OVERWRITE" == "yes" ]]; then
        echo "Chế độ overwrite được kích hoạt; chỉ có 1 file backup tồn tại nên không cần cleanup."
    else
        # Tìm các file backup có định dạng: <BASENAME>_*.tar.gz
        BACKUP_FILES=($(ls -t "$DESTINATION_PATH"/${BASENAME}_*.tar.gz 2>/dev/null))
        if [[ "${#BACKUP_FILES[@]}" -gt "$KEEP_COUNT" ]]; then
            for ((i=KEEP_COUNT; i<${#BACKUP_FILES[@]}; i++)); do
                rm -f "${BACKUP_FILES[$i]}"
                echo "Deleted old backup: ${BACKUP_FILES[$i]}"
            done
        fi
    fi
fi

exit 0

