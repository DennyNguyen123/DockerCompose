#!/bin/bash

# Hàm hiển thị hướng dẫn sử dụng
usage() {
    echo "Usage: $0 [OPTIONS] source1 [source2 ...]"
    echo ""
    echo "Options:"
    echo "  -d, --destination <dest_path>      Thư mục lưu backup (bắt buộc)"
    echo "  -o, --overwrite <yes|no>           Ghi đè file backup nếu tồn tại (mặc định: no)"
    echo "  -k, --keep <number>                Số lượng file backup mới nhất cần giữ lại (mặc định: 0, không xóa)"
    echo "  -h, --help                         Hiển thị hướng dẫn sử dụng"
    exit 1
}

# Giá trị mặc định
DESTINATION=""
OVERWRITE="no"
KEEP_COUNT=0

# Phân tích tham số dòng lệnh
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -d|--destination)
            DESTINATION="$2"
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
        --) 
            shift
            break
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            break
            ;;
    esac
done

# Kiểm tra tham số bắt buộc và ít nhất 1 nguồn đầu vào
if [[ -z "$DESTINATION" ]]; then
    echo "Error: Thiếu tham số --destination"
    usage
fi

if [[ $# -lt 1 ]]; then
    echo "Error: Ít nhất phải cung cấp 1 nguồn (file hoặc folder)"
    usage
fi

# Mảng các nguồn được truyền vào
SOURCES=("$@")

# Kiểm tra tồn tại của các nguồn
for src in "${SOURCES[@]}"; do
    if [[ ! -e "$src" ]]; then
        echo "Error: Nguồn không tồn tại: $src"
        exit 1
    fi
done

# Tạo thư mục đích nếu chưa có
mkdir -p "$DESTINATION"

# Tạo tên file backup dựa trên tên của các nguồn
COMBINED_NAME=""
for src in "${SOURCES[@]}"; do
    BASENAME=$(basename "$src")
    if [[ -z "$COMBINED_NAME" ]]; then
        COMBINED_NAME="$BASENAME"
    else
        COMBINED_NAME="${COMBINED_NAME}_${BASENAME}"
    fi
done

if [[ "$OVERWRITE" == "yes" ]]; then
    BACKUP_FILE="$DESTINATION/${COMBINED_NAME}.tar.gz"
else
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_FILE="$DESTINATION/${COMBINED_NAME}_$TIMESTAMP.tar.gz"
fi

# Tạo thư mục tạm thời để sao chép các nguồn vào (để đảm bảo tên file trong archive không chứa đường dẫn tuyệt đối)
TMP_DIR=$(mktemp -d)

for src in "${SOURCES[@]}"; do
    # Sao chép file hoặc folder (sử dụng -r để copy đệ quy nếu là folder)
    cp -r "$src" "$TMP_DIR/"
done

# Nén nội dung của thư mục tạm
tar -czf "$BACKUP_FILE" -C "$TMP_DIR" .

if [[ $? -eq 0 ]]; then
    echo "Backup created: $BACKUP_FILE"
else
    echo "Backup failed"
    rm -rf "$TMP_DIR"
    exit 1
fi

# Xóa thư mục tạm sau khi nén xong
rm -rf "$TMP_DIR"

# Cleanup: Nếu KEEP_COUNT > 0 và overwrite không được kích hoạt (do khi overwrite=yes chỉ có 1 file backup)
if [[ "$KEEP_COUNT" -gt 0 && "$OVERWRITE" != "yes" ]]; then
    # Tìm các file backup có định dạng: <COMBINED_NAME>_*.tar.gz
    BACKUP_FILES=($(ls -t "$DESTINATION"/${COMBINED_NAME}_*.tar.gz 2>/dev/null))
    if [[ "${#BACKUP_FILES[@]}" -gt "$KEEP_COUNT" ]]; then
        for ((i=KEEP_COUNT; i<${#BACKUP_FILES[@]}; i++)); do
            rm -f "${BACKUP_FILES[$i]}"
            echo "Deleted old backup: ${BACKUP_FILES[$i]}"
        done
    fi
fi

exit 0
