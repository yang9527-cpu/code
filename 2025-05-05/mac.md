### 一.v2rayN.app  
1. 下载v2rayN  
2. v2rayN 拖入 Applications 安装  
3. 在iterm中输入：
```
sudo xattr -cr /Applications/v2rayN.app. 
```  
#### 配置 ####  
1. 订阅分组  
2. 订阅分组设置  
3. 在“可选地址（Url）：输入https://api.xmancdn.net/osubscribe.php?sid=127930&token=9feClAzADbwl”并输入别名   
4.订阅分组->更新全部代理（不通过代理）  
### 二.brew  
1. 设置环境（类似头文件？？）  
```
export all_proxy=127.0.0.1:10808 http_proxy=127.0.0.1:10808 https_proxy=127.0.0.1:10808
```  
2. 在brew官网中安装  
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"  
```
