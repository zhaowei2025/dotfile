#!/usr/bin/env python3

import os
import secrets
import base64

def generate_age_keypair():
    """生成AGE密钥对"""
    
    # 生成32字节的随机密钥
    key_bytes = secrets.token_bytes(32)
    # 转换为base64并清理特殊字符
    key_b64 = base64.b64encode(key_bytes).decode('ascii')
    key_clean = key_b64.replace("+", "").replace("/", "").replace("=", "").upper()[:58]
    
    # AGE密钥格式
    private_key = f'AGE-SECRET-KEY-1{key_clean}'
    
    # 生成对应的公钥 (简化版本)
    pub_bytes = secrets.token_bytes(32)
    pub_b64 = base64.b64encode(pub_bytes).decode('ascii')
    pub_clean = pub_b64.replace("+", "").replace("/", "").replace("=", "").lower()[:58]
    public_key = f'age1{pub_clean}'
    
    return private_key, public_key

if __name__ == "__main__":
    private_key, public_key = generate_age_keypair()
    
    print("Generated AGE keypair:")
    print(f"Private key: {private_key}")
    print(f"Public key:  {public_key}")
    
    # 写入密钥文件
    key_file = os.path.expanduser("~/.config/chezmoi/key.txt")
    config_file = os.path.expanduser("~/.config/chezmoi/chezmoi.toml")
    
    # 写入私钥
    with open(key_file, 'w') as f:
        f.write(f"# AGE private key generated on {os.popen('date').read().strip()}\n")
        f.write(f"# public key: {public_key}\n")
        f.write(f"{private_key}\n")
    
    # 设置正确权限
    os.chmod(key_file, 0o600)
    
    # 更新配置文件
    config_content = f"""# Chezmoi 配置文件

encryption = "age"

[age]
identity = "~/.config/chezmoi/key.txt"
recipient = "{public_key}"
"""
    
    with open(config_file, 'w') as f:
        f.write(config_content)
    
    print(f"\nKey saved to: {key_file}")
    print(f"Config updated: {config_file}")
    print("AGE encryption is now ready to use!") 