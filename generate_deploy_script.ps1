$files = @(
    "backend/config/swagger.js",
    "backend/src/controllers/authController.js",
    "backend/src/models/User.js",
    "backend/src/middleware/authMiddleware.js"
)

$sb = new-object System.Text.StringBuilder
$sb.AppendLine("cd /opt/devops-app")

foreach ($f in $files) {
    $bytes = [IO.File]::ReadAllBytes($f)
    $b64 = [Convert]::ToBase64String($bytes)
    # Ensure directory exists just in case
    $dir = [IO.Path]::GetDirectoryName($f).Replace("\", "/")
    $sb.AppendLine("mkdir -p $dir")
    $linuxPath = $f.Replace("\", "/")
    $sb.AppendLine("echo '$b64' | base64 -d > $linuxPath")
}

# Add rebuild commands
$sb.AppendLine("sed -i 's/\/\/ const setupSwagger/const setupSwagger/' backend/server.js")
$sb.AppendLine("sed -i 's/\/\/ setupSwagger/setupSwagger/' backend/server.js")
$sb.AppendLine("sudo docker-compose stop backend")
$sb.AppendLine("sudo docker rm backend")
$sb.AppendLine("sudo docker-compose build --no-cache backend")
$sb.AppendLine("sudo docker-compose up -d backend")

[IO.File]::WriteAllText("deploy_fix_b64.sh", $sb.ToString())
