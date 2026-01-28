${{ content_synopsis }} This image will run rclone [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md), for maximum security and performance. It will always add ```--rc``` to your command and expose the metrics as well as reading the config from ```/rclone/etc/default.conf```, the rest is up to you.

${{ content_uvp }} Good question! Because ...

${{ github:> [!IMPORTANT] }}
${{ github:> }}* ... this image runs [rootless](https://github.com/11notes/RTFM/blob/main/linux/container/image/rootless.md) as 1000:1000
${{ github:> }}* ... this image is auto updated to the latest version via CI/CD
${{ github:> }}* ... this image has a health check
${{ github:> }}* ... this image is automatically scanned for CVEs before and after publishing
${{ github:> }}* ... this image is created via a secure and pinned CI/CD process
${{ github:> }}* ... this image is very small

If you value security, simplicity and optimizations to the extreme, then this image might be for you.

${{ content_comparison }}

${{ title_volumes }}
* **${{ json_root }}/etc** - Directory of the configuration file

${{ content_compose }}

${{ content_defaults }}

${{ content_environment }}

${{ content_source }}

${{ content_parent }}

${{ content_built }}

${{ content_tips }}

${{ title_caution }}
${{ github:> [!CAUTION] }}
${{ github:> }}* The compose example spins up minio (for S3) and connects rclone via an unverified SSL connection. In production, only connect to a verified destination with a valid SSL certificate!