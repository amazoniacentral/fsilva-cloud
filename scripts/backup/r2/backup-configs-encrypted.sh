docker run --rm \
  --name "rclone_configs_backup" \
  -v "${BASE_DIR}":/data:ro \
  -v "${RCLONE_CONFIG_HOST}":/config/rclone \
  rclone/rclone --config /config/rclone/rclone.conf copy /data "${RCLONE_REMOTE}" \
  --exclude "**/node_modules/**" \
  --include "*.env" \
  --include "*.env.*" \
  --include "*.yml" \
  --include "*.yaml" \
  --include "*.conf" \
  --exclude "**" \
  --fast-list \
  --buffer-size 16M \
  --transfers 2 \
  --checkers 4 \
  --progress
