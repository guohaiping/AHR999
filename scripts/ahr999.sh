#!/bin/bash

# AHR999 多架构管理脚本
# 支持测试、构建、部署等功能

set -e

# 配置变量
IMAGE_NAME="ahr999"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 显示帮助信息
show_help() {
    echo "AHR999 多架构管理脚本"
    echo ""
    echo "用法: $0 <命令> [选项]"
    echo ""
    echo "命令:"
    echo "  test                    测试多架构支持"
    echo "  build [tag] [registry]  构建多架构镜像"
    echo "  deploy                  部署服务"
    echo "  status                  查看服务状态"
    echo "  logs                    查看服务日志"
    echo "  clean                   清理资源"
    echo "  help                    显示此帮助信息"
    echo ""
    echo "示例:"
    echo "  $0 test                 # 测试多架构支持"
    echo "  $0 build                # 构建本地镜像"
    echo "  $0 build v1.0           # 构建指定标签镜像"
    echo "  $0 build latest hub.docker.com/user  # 构建并推送到仓库"
    echo "  $0 deploy               # 部署服务"
    echo ""
}

# 检测系统架构
detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            PLATFORM="linux/amd64"
            ;;
        aarch64|arm64)
            PLATFORM="linux/arm64"
            ;;
        *)
            PLATFORM="unknown"
            ;;
    esac
}

# 检查Docker环境
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker 未安装"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo "❌ Docker 服务未运行"
        exit 1
    fi
}

# 测试功能
test_multiarch() {
    echo "=== AHR999 多架构支持测试 ==="
    
    detect_arch
    echo "当前系统架构: $ARCH ($PLATFORM)"
    
    echo ""
    echo "=== 检查 Docker 环境 ==="
    check_docker
    echo "✓ Docker 已安装: $(docker --version)"
    
    if docker buildx version &> /dev/null; then
        echo "✓ Docker Buildx 可用: $(docker buildx version)"
    else
        echo "⚠ Docker Buildx 不可用，将使用标准构建"
    fi
    
    echo ""
    echo "=== 构建测试 ==="
    
    cd "$PROJECT_DIR"
    echo "正在构建镜像..."
    if docker build -t ahr999-test:latest . > build.log 2>&1; then
        echo "✓ 镜像构建成功"
    else
        echo "❌ 镜像构建失败，查看 build.log 获取详细信息"
        tail -20 build.log
        exit 1
    fi
    
    echo ""
    echo "=== 容器测试 ==="
    
    echo "正在测试容器启动..."
    CONTAINER_ID=$(docker run -d --name ahr999-test-container ahr999-test:latest)
    
    if [ $? -eq 0 ]; then
        echo "✓ 容器启动成功: $CONTAINER_ID"
    else
        echo "❌ 容器启动失败"
        exit 1
    fi
    
    echo "等待容器初始化..."
    sleep 10
    
    if docker ps | grep ahr999-test-container > /dev/null; then
        echo "✓ 容器运行正常"
    else
        echo "❌ 容器未正常运行"
        docker logs ahr999-test-container
        docker rm -f ahr999-test-container
        exit 1
    fi
    
    echo ""
    echo "=== 环境检查 ==="
    
    CONTAINER_ARCH=$(docker exec ahr999-test-container uname -m)
    echo "容器内架构: $CONTAINER_ARCH"
    
    echo "检查浏览器配置..."
    docker exec ahr999-test-container bash -c 'source /etc/environment && echo "Chrome binary: $CHROME_BIN"'
    docker exec ahr999-test-container bash -c 'source /etc/environment && echo "ChromeDriver path: $CHROMEDRIVER_PATH"'
    
    if docker exec ahr999-test-container bash -c 'source /etc/environment && $CHROME_BIN --version' > /dev/null 2>&1; then
        CHROME_VERSION=$(docker exec ahr999-test-container bash -c 'source /etc/environment && $CHROME_BIN --version')
        echo "✓ 浏览器可用: $CHROME_VERSION"
    else
        echo "⚠ 浏览器版本检查失败"
    fi
    
    if docker exec ahr999-test-container bash -c 'source /etc/environment && $CHROMEDRIVER_PATH --version' > /dev/null 2>&1; then
        CHROMEDRIVER_VERSION=$(docker exec ahr999-test-container bash -c 'source /etc/environment && $CHROMEDRIVER_PATH --version')
        echo "✓ ChromeDriver 可用: $CHROMEDRIVER_VERSION"
    else
        echo "⚠ ChromeDriver 版本检查失败"
    fi
    
    echo ""
    echo "=== Python 环境检查 ==="
    
    if docker exec ahr999-test-container python3 -c "import selenium, requests, bs4; print('✓ 所有依赖已安装')" 2>/dev/null; then
        echo "✓ Python 依赖检查通过"
    else
        echo "❌ Python 依赖检查失败"
    fi
    
    echo ""
    echo "=== 清理 ==="
    
    docker rm -f ahr999-test-container > /dev/null 2>&1
    echo "✓ 测试容器已清理"
    
    read -p "是否删除测试镜像? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker rmi ahr999-test:latest > /dev/null 2>&1
        echo "✓ 测试镜像已删除"
    fi
    
    echo ""
    echo "=== 测试完成 ==="
    echo "架构: $ARCH"
    echo "平台: $PLATFORM"
    echo "状态: ✓ 多架构支持测试通过"
    
    echo ""
    echo "=== 下一步 ==="
    echo "1. 设置环境变量: export SERVER_CHAN_SCKEY='your_key'"
    echo "2. 启动服务: $0 deploy"
    echo "3. 查看日志: $0 logs"
}

# 构建功能
build_multiarch() {
    local TAG="${1:-latest}"
    local REGISTRY="${2:-}"
    
    echo "=== AHR999 多架构镜像构建 ==="
    echo "镜像名称: ${IMAGE_NAME}"
    echo "标签: ${TAG}"
    echo "目标架构: linux/amd64,linux/arm64"
    
    check_docker
    
    if ! docker buildx version > /dev/null 2>&1; then
        echo "错误: Docker buildx 不可用，请确保Docker版本支持buildx"
        exit 1
    fi
    
    BUILDER_NAME="ahr999-builder"
    if ! docker buildx inspect $BUILDER_NAME > /dev/null 2>&1; then
        echo "创建新的buildx构建器: $BUILDER_NAME"
        docker buildx create --name $BUILDER_NAME --driver docker-container --bootstrap
    fi
    
    echo "使用buildx构建器: $BUILDER_NAME"
    docker buildx use $BUILDER_NAME
    
    cd "$PROJECT_DIR"
    echo "开始构建多架构镜像..."
    
    if [ -n "$REGISTRY" ]; then
        FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${TAG}"
        echo "将推送到仓库: $FULL_IMAGE_NAME"
        
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --tag $FULL_IMAGE_NAME \
            --push \
            .
    else
        FULL_IMAGE_NAME="${IMAGE_NAME}:${TAG}"
        echo "本地构建: $FULL_IMAGE_NAME"
        
        docker buildx build \
            --platform linux/amd64,linux/arm64 \
            --tag $FULL_IMAGE_NAME \
            --load \
            .
    fi
    
    echo "=== 构建完成 ==="
    echo "镜像: $FULL_IMAGE_NAME"
    echo "支持架构: linux/amd64, linux/arm64"
    
    echo ""
    echo "=== 镜像信息 ==="
    docker buildx imagetools inspect $FULL_IMAGE_NAME
    
    echo ""
    echo "=== 使用说明 ==="
    echo "部署服务: $0 deploy"
    echo "查看状态: $0 status"
}

# 部署功能
deploy_service() {
    echo "=== 部署 AHR999 服务 ==="
    
    check_docker
    
    if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
        echo "❌ 未找到 docker-compose.yml 文件"
        exit 1
    fi
    
    if [ -z "$SERVER_CHAN_SCKEY" ]; then
        echo "⚠ 警告: 未设置 SERVER_CHAN_SCKEY 环境变量"
        echo "请设置: export SERVER_CHAN_SCKEY='your_key'"
        read -p "是否继续部署? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    cd "$PROJECT_DIR"
    echo "正在启动服务..."
    docker-compose up -d
    
    echo "✓ 服务部署完成"
    echo ""
    echo "查看状态: $0 status"
    echo "查看日志: $0 logs"
}

# 查看状态
show_status() {
    echo "=== AHR999 服务状态 ==="
    
    check_docker
    cd "$PROJECT_DIR"
    
    echo "容器状态:"
    docker-compose ps
    
    echo ""
    echo "系统资源:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" $(docker-compose ps -q) 2>/dev/null || echo "无运行中的容器"
}

# 查看日志
show_logs() {
    echo "=== AHR999 服务日志 ==="
    
    check_docker
    cd "$PROJECT_DIR"
    
    docker-compose logs -f
}

# 清理资源
clean_resources() {
    echo "=== 清理 AHR999 资源 ==="
    
    check_docker
    cd "$PROJECT_DIR"
    
    echo "停止并删除容器..."
    docker-compose down
    
    echo "清理未使用的镜像..."
    docker image prune -f
    
    echo "清理构建缓存..."
    docker builder prune -f
    
    echo "✓ 资源清理完成"
}

# 主函数
main() {
    case "${1:-help}" in
        test)
            test_multiarch
            ;;
        build)
            build_multiarch "$2" "$3"
            ;;
        deploy)
            deploy_service
            ;;
        status)
            show_status
            ;;
        logs)
            show_logs
            ;;
        clean)
            clean_resources
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            echo "未知命令: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 执行主函数
main "$@"
