#!/bin/bash

generate_uuid() {
    if command -v uuidgen &> /dev/null; then
        uuidgen | tr '[:upper:]' '[:lower:]'
    elif command -v python3 &> /dev/null; then
        python3 -c "import uuid; print(str(uuid.uuid4()))"
    else
        hexdump -n 16 -e '4/4 "%08X" 1 "\n"' /dev/urandom | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-\9\10-\11\12\13\14\15\16/' | tr '[:upper:]' '[:lower:]'
    fi
}

clear

echo "请选择配置模式:"
echo "1) 极速模式 - 只修改UUID并启动"
echo "2) 完整模式 - 详细配置所有选项"
echo
read -p "请输入选择 (1/2): " MODE_CHOICE

echo "检查并安装依赖..."
if ! command -v python3 &> /dev/null; then
    echo "正在安装 Python3..."
    sudo apt-get update && sudo apt-get install -y python3 python3-pip
fi

if ! python3 -c "import requests" &> /dev/null; then
    echo "正在安装 Python 依赖..."
    pip3 install requests
fi

PROJECT_DIR="python-xray-argo"
if [ ! -d "$PROJECT_DIR" ]; then
    echo "下载完整仓库..."
    if command -v git &> /dev/null; then
        git clone https://github.com/eooce/python-xray-argo.git
    else
        echo "Git未安装，使用wget下载..."
        wget -q https://github.com/eooce/python-xray-argo/archive/refs/heads/main.zip -O python-xray-argo.zip
        if command -v unzip &> /dev/null; then
            unzip -q python-xray-argo.zip
            mv python-xray-argo-main python-xray-argo
            rm python-xray-argo.zip
        else
            echo "正在安装 unzip..."
            sudo apt-get install -y unzip
            unzip -q python-xray-argo.zip
            mv python-xray-argo-main python-xray-argo
            rm python-xray-argo.zip
        fi
    fi
    
    if [ $? -ne 0 ] || [ ! -d "$PROJECT_DIR" ]; then
        echo "下载失败，请检查网络连接"
        exit 1
    fi
fi

cd "$PROJECT_DIR"

echo "依赖安装完成！"
echo

if [ ! -f "app.py" ]; then
    echo "未找到app.py文件！"
    exit 1
fi

cp app.py app.py.backup
echo "已备份原始文件为 app.py.backup"

if [ "$MODE_CHOICE" = "1" ]; then
    echo "=== 极速模式 ==="
    echo
    
    echo "当前UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)"
    read -p "请输入新的 UUID (留空自动生成): " UUID_INPUT
    if [ -z "$UUID_INPUT" ]; then
        UUID_INPUT=$(generate_uuid)
        echo "自动生成UUID: $UUID_INPUT"
    fi
    
    sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '$UUID_INPUT')/" app.py
    echo "UUID 已设置为: $UUID_INPUT"
    
    sed -i "s/CFIP = os.environ.get('CFIP', '[^']*')/CFIP = os.environ.get('CFIP', 'joeyblog.net')/" app.py
    echo "优选IP已自动设置为: joeyblog.net"
    
    echo
    echo "极速配置完成！正在启动服务..."
    echo
    
else
    echo "=== 完整配置模式 ==="
    echo
    
    echo "当前UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)"
    read -p "请输入新的 UUID (留空自动生成): " UUID_INPUT
    if [ -z "$UUID_INPUT" ]; then
        UUID_INPUT=$(generate_uuid)
        echo "自动生成UUID: $UUID_INPUT"
    fi
    sed -i "s/UUID = os.environ.get('UUID', '[^']*')/UUID = os.environ.get('UUID', '$UUID_INPUT')/" app.py
    echo "UUID 已设置为: $UUID_INPUT"

    echo "当前节点名称: $(grep "NAME = " app.py | head -1 | cut -d"'" -f4)"
    read -p "请输入节点名称 (留空保持不变): " NAME_INPUT
    if [ -n "$NAME_INPUT" ]; then
        sed -i "s/NAME = os.environ.get('NAME', '[^']*')/NAME = os.environ.get('NAME', '$NAME_INPUT')/" app.py
        echo "节点名称已设置为: $NAME_INPUT"
    fi

    echo "当前服务端口: $(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)"
    read -p "请输入服务端口 (留空保持不变): " PORT_INPUT
    if [ -n "$PORT_INPUT" ]; then
        sed -i "s/PORT = int(os.environ.get('SERVER_PORT') or os.environ.get('PORT') or [0-9]*)/PORT = int(os.environ.get('SERVER_PORT') or os.environ.get('PORT') or $PORT_INPUT)/" app.py
        echo "端口已设置为: $PORT_INPUT"
    fi

    echo "当前优选IP: $(grep "CFIP = " app.py | cut -d"'" -f4)"
    read -p "请输入优选IP/域名 (留空使用默认 joeyblog.net): " CFIP_INPUT
    if [ -z "$CFIP_INPUT" ]; then
        CFIP_INPUT="joeyblog.net"
    fi
    sed -i "s/CFIP = os.environ.get('CFIP', '[^']*')/CFIP = os.environ.get('CFIP', '$CFIP_INPUT')/" app.py
    echo "优选IP已设置为: $CFIP_INPUT"

    echo "当前优选端口: $(grep "CFPORT = " app.py | cut -d"'" -f4)"
    read -p "请输入优选端口 (留空保持不变): " CFPORT_INPUT
    if [ -n "$CFPORT_INPUT" ]; then
        sed -i "s/CFPORT = int(os.environ.get('CFPORT', '[^']*'))/CFPORT = int(os.environ.get('CFPORT', '$CFPORT_INPUT'))/" app.py
        echo "优选端口已设置为: $CFPORT_INPUT"
    fi

    echo "当前Argo端口: $(grep "ARGO_PORT = " app.py | cut -d"'" -f4)"
    read -p "请输入 Argo 端口 (留空保持不变): " ARGO_PORT_INPUT
    if [ -n "$ARGO_PORT_INPUT" ]; then
        sed -i "s/ARGO_PORT = int(os.environ.get('ARGO_PORT', '[^']*'))/ARGO_PORT = int(os.environ.get('ARGO_PORT', '$ARGO_PORT_INPUT'))/" app.py
        echo "Argo端口已设置为: $ARGO_PORT_INPUT"
    fi

    echo "当前订阅路径: $(grep "SUB_PATH = " app.py | cut -d"'" -f4)"
    read -p "请输入订阅路径 (留空保持不变): " SUB_PATH_INPUT
    if [ -n "$SUB_PATH_INPUT" ]; then
        sed -i "s/SUB_PATH = os.environ.get('SUB_PATH', '[^']*')/SUB_PATH = os.environ.get('SUB_PATH', '$SUB_PATH_INPUT')/" app.py
        echo "订阅路径已设置为: $SUB_PATH_INPUT"
    fi

    echo "是否配置高级选项? (y/n)"
    read -p "> " ADVANCED_CONFIG

    if [ "$ADVANCED_CONFIG" = "y" ] || [ "$ADVANCED_CONFIG" = "Y" ]; then
        echo "当前上传URL: $(grep "UPLOAD_URL = " app.py | cut -d"'" -f4)"
        read -p "请输入上传URL (留空保持不变): " UPLOAD_URL_INPUT
        if [ -n "$UPLOAD_URL_INPUT" ]; then
            sed -i "s|UPLOAD_URL = os.environ.get('UPLOAD_URL', '[^']*')|UPLOAD_URL = os.environ.get('UPLOAD_URL', '$UPLOAD_URL_INPUT')|" app.py
            echo "上传URL已设置"
        fi

        echo "当前项目URL: $(grep "PROJECT_URL = " app.py | cut -d"'" -f4)"
        read -p "请输入项目URL (留空保持不变): " PROJECT_URL_INPUT
        if [ -n "$PROJECT_URL_INPUT" ]; then
            sed -i "s|PROJECT_URL = os.environ.get('PROJECT_URL', '[^']*')|PROJECT_URL = os.environ.get('PROJECT_URL', '$PROJECT_URL_INPUT')|" app.py
            echo "项目URL已设置"
        fi

        echo "当前自动保活状态: $(grep "AUTO_ACCESS = " app.py | grep -o "'[^']*'" | tail -1 | tr -d "'")"
        echo "是否启用自动保活? (y/n)"
        read -p "> " AUTO_ACCESS_INPUT
        if [ "$AUTO_ACCESS_INPUT" = "y" ] || [ "$AUTO_ACCESS_INPUT" = "Y" ]; then
            sed -i "s/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', '[^']*')/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', 'true')/" app.py
            echo "自动保活已启用"
        elif [ "$AUTO_ACCESS_INPUT" = "n" ] || [ "$AUTO_ACCESS_INPUT" = "N" ]; then
            sed -i "s/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', '[^']*')/AUTO_ACCESS = os.environ.get('AUTO_ACCESS', 'false')/" app.py
            echo "自动保活已禁用"
        fi

        echo "当前哪吒服务器: $(grep "NEZHA_SERVER = " app.py | cut -d"'" -f4)"
        read -p "请输入哪吒服务器地址 (留空保持不变): " NEZHA_SERVER_INPUT
        if [ -n "$NEZHA_SERVER_INPUT" ]; then
            sed -i "s|NEZHA_SERVER = os.environ.get('NEZHA_SERVER', '[^']*')|NEZHA_SERVER = os.environ.get('NEZHA_SERVER', '$NEZHA_SERVER_INPUT')|" app.py
            
            echo "当前哪吒端口: $(grep "NEZHA_PORT = " app.py | cut -d"'" -f4)"
            read -p "请输入哪吒端口 (v1版本留空): " NEZHA_PORT_INPUT
            if [ -n "$NEZHA_PORT_INPUT" ]; then
                sed -i "s|NEZHA_PORT = os.environ.get('NEZHA_PORT', '[^']*')|NEZHA_PORT = os.environ.get('NEZHA_PORT', '$NEZHA_PORT_INPUT')|" app.py
            fi
            
            echo "当前哪吒密钥: $(grep "NEZHA_KEY = " app.py | cut -d"'" -f4)"
            read -p "请输入哪吒密钥: " NEZHA_KEY_INPUT
            if [ -n "$NEZHA_KEY_INPUT" ]; then
                sed -i "s|NEZHA_KEY = os.environ.get('NEZHA_KEY', '[^']*')|NEZHA_KEY = os.environ.get('NEZHA_KEY', '$NEZHA_KEY_INPUT')|" app.py
            fi
            echo "哪吒配置已设置"
        fi

        echo "当前Argo域名: $(grep "ARGO_DOMAIN = " app.py | cut -d"'" -f4)"
        read -p "请输入 Argo 固定隧道域名 (留空保持不变): " ARGO_DOMAIN_INPUT
        if [ -n "$ARGO_DOMAIN_INPUT" ]; then
            sed -i "s|ARGO_DOMAIN = os.environ.get('ARGO_DOMAIN', '[^']*')|ARGO_DOMAIN = os.environ.get('ARGO_DOMAIN', '$ARGO_DOMAIN_INPUT')|" app.py
            
            echo "当前Argo密钥: $(grep "ARGO_AUTH = " app.py | cut -d"'" -f4)"
            read -p "请输入 Argo 固定隧道密钥: " ARGO_AUTH_INPUT
            if [ -n "$ARGO_AUTH_INPUT" ]; then
                sed -i "s|ARGO_AUTH = os.environ.get('ARGO_AUTH', '[^']*')|ARGO_AUTH = os.environ.get('ARGO_AUTH', '$ARGO_AUTH_INPUT')|" app.py
            fi
            echo "Argo固定隧道配置已设置"
        fi

        echo "当前Bot Token: $(grep "BOT_TOKEN = " app.py | cut -d"'" -f4)"
        read -p "请输入 Telegram Bot Token (留空保持不变): " BOT_TOKEN_INPUT
        if [ -n "$BOT_TOKEN_INPUT" ]; then
            sed -i "s|BOT_TOKEN = os.environ.get('BOT_TOKEN', '[^']*')|BOT_TOKEN = os.environ.get('BOT_TOKEN', '$BOT_TOKEN_INPUT')|" app.py
            
            echo "当前Chat ID: $(grep "CHAT_ID = " app.py | cut -d"'" -f4)"
            read -p "请输入 Telegram Chat ID: " CHAT_ID_INPUT
            if [ -n "$CHAT_ID_INPUT" ]; then
                sed -i "s|CHAT_ID = os.environ.get('CHAT_ID', '[^']*')|CHAT_ID = os.environ.get('CHAT_ID', '$CHAT_ID_INPUT')|" app.py
            fi
            echo "Telegram配置已设置"
        fi
    fi

    echo
    echo "完整配置完成！"
fi

echo "=== 当前配置摘要 ==="
echo "UUID: $(grep "UUID = " app.py | head -1 | cut -d"'" -f2)"
echo "节点名称: $(grep "NAME = " app.py | head -1 | cut -d"'" -f4)"
echo "服务端口: $(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)"
echo "优选IP: $(grep "CFIP = " app.py | cut -d"'" -f4)"
echo "优选端口: $(grep "CFPORT = " app.py | cut -d"'" -f4)"
echo "订阅路径: $(grep "SUB_PATH = " app.py | cut -d"'" -f4)"
echo "========================"
echo

echo "正在启动服务..."
echo "当前工作目录：$(pwd)"
echo

nohup python3 app.py > app.log 2>&1 &
APP_PID=$!

echo "服务已在后台启动，PID: $APP_PID"
echo "日志文件: $(pwd)/app.log"

echo "等待服务启动..."
sleep 10

if ps -p $APP_PID > /dev/null; then
    echo "服务运行正常"
else
    echo "服务启动失败，请检查日志"
    echo "查看日志: tail -f app.log"
    exit 1
fi

SERVICE_PORT=$(grep "PORT = int" app.py | grep -o "or [0-9]*" | cut -d" " -f2)
CURRENT_UUID=$(grep "UUID = " app.py | head -1 | cut -d"'" -f2)
SUB_PATH_VALUE=$(grep "SUB_PATH = " app.py | cut -d"'" -f4)

echo "等待节点信息生成..."
sleep 15

NODE_INFO=""
if [ -f ".cache/sub.txt" ]; then
    NODE_INFO=$(cat .cache/sub.txt)
elif [ -f "sub.txt" ]; then
    NODE_INFO=$(cat sub.txt)
fi

echo
echo "========================================"
echo "           部署完成！                   "
echo "========================================"
echo

echo "=== 服务信息 ==="
echo "服务状态: 运行中"
echo "进程PID: $APP_PID"
echo "服务端口: $SERVICE_PORT"
echo "UUID: $CURRENT_UUID"
echo "订阅路径: /$SUB_PATH_VALUE"
echo

echo "=== 访问地址 ==="
if command -v curl &> /dev/null; then
    PUBLIC_IP=$(curl -s https://api.ipify.org 2>/dev/null || echo "获取失败")
    if [ "$PUBLIC_IP" != "获取失败" ]; then
        echo "订阅地址: http://$PUBLIC_IP:$SERVICE_PORT/$SUB_PATH_VALUE"
        echo "管理面板: http://$PUBLIC_IP:$SERVICE_PORT"
    fi
fi
echo "本地订阅: http://localhost:$SERVICE_PORT/$SUB_PATH_VALUE"
echo "本地面板: http://localhost:$SERVICE_PORT"
echo

if [ -n "$NODE_INFO" ]; then
    echo "=== 节点信息 ==="
    DECODED_NODES=$(echo "$NODE_INFO" | base64 -d 2>/dev/null || echo "$NODE_INFO")
    echo "原始节点配置:"
    echo "$DECODED_NODES"
    echo
    echo "订阅链接 (Base64编码):"
    echo "$NODE_INFO"
    echo
else
    echo "=== 节点信息 ==="
    echo "节点信息还未生成，请稍等几分钟后查看日志或手动访问订阅地址"
    echo
fi

echo "=== 管理命令 ==="
echo "查看日志: tail -f $(pwd)/app.log"
echo "停止服务: kill $APP_PID"
echo "重启服务: kill $APP_PID && nohup python3 app.py > app.log 2>&1 &"
echo "查看进程: ps aux | grep python3"
echo

echo "=== 重要提示 ==="
echo "服务正在后台运行，请等待Argo隧道建立完成"
echo "如果使用临时隧道，域名会在几分钟后出现在日志中"
echo "建议10-15分钟后再次查看订阅地址获取最新节点信息"
echo "可以通过日志查看详细的启动过程和隧道信息"
echo

echo "部署完成！感谢使用！"
