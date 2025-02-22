#!/bin/bash

# Kiểm tra số lượng tham số đầu vào
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <source_path> <destination_path> <backup_count>"
    exit 1
fi

SOURCE_PATH="$1"
DESTINATION_PATH="$2"
BACKUP_COUNT="$3"

# Kiểm tra xem thư mục nguồn có tồn tại không
if [ ! -d "$SOURCE_PATH" ]; then
    echo "Source path does not exist: $SOURCE_PATH"
    exit 1
fi

# Kiểm tra xem thư mục đích có tồn tại không, nếu không thì tạo mới
if [ ! -d "$DESTINATION_PATH" ]; then
    mkdir -p "$DESTINATION_PATH"
fi

# Định dạng tên file backup theo ngày giờ
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$DESTINATION_PATH/backup_$TIMESTAMP.tar.gz"

# Nén thư mục nguồn
tar -czf "$BACKUP_FILE" -C "$SOURCE_PATH" .

# Kiểm tra nếu nén thành công
if [ $? -eq 0 ]; then
    echo "Backup created: $BACKUP_FILE"
else
    echo "Backup failed"
    exit 1
fi

# Xóa các file backup cũ, chỉ giữ lại số lượng file backup theo yêu cầu
BACKUP_FILES=($(ls -t "$DESTINATION_PATH"/backup_*.tar.gz))

if [ "${#BACKUP_FILES[@]}" -gt "$BACKUP_COUNT" ]; then
    for ((i=$BACKUP_COUNT; i<${#BACKUP_FILES[@]}; i++)); do
        rm -f "${BACKUP_FILES[$i]}"
        echo "Deleted old backup: ${BACKUP_FILES[$i]}"
    done
fi

exit 0
