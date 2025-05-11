# Linux 命令行基础 #

## 文件和目录列表 ##
- `ls`：列出文件和目录。
- `ls -l`：长格式列出详细信息（权限、所有者、大小、日期）。
- `ls -a`：显示隐藏文件（以点开头的文件）。
- `ls -lh`：以人类可读的格式显示大小（长格式）。

## 改变目录 ##
- `cd /path/to/directory`：切换到指定目录。
- `cd ..`：返回上级目录。
- `cd ~`：切换到主目录。
- `cd -`：切换到你之前所在的目录。
![使用code](截屏2025-05-05%2010.10.52.png)  

## 创建目录 ##
- `mkdir myFolder`：创建一个新目录。
- `mkdir -p dir1/dir2`：创建嵌套目录。

## 复制文件和目录  ##
- `cp source.txt destination.txt`：复制文件。
- `cp -r source/directory /dest/directory`：递归复制目录。

## 移动/重命名文件  ##
- `mv old_name.txt new_name.txt`：重命名文件。
- `mv file.txt /path/to/destination`：将文件移动到另一个位置。

## 删除文件和目录  ##
- `rm file.txt`：删除文件。
- `rm -r directory/`：删除目录及其内容。
- `rm -rf directory/`：强制删除目录，即使不为空。

## 查看文件内容  ##
- `cat file.txt`：输出整个文件。
- `less file.txt`：滚动查看文件内容（支持上下键）。
- `head file.txt`：查看文件的前10行。
- `tail -f logfile.log`：持续输出文件末尾内容（对日志文件有用）。

## 使用 grep 搜索文件  ##
- `grep "search_term" file.txt`：在文件中搜索一个词。
- `grep -r "search_term" /path`：在目录中的文件中递归搜索。
- `grep -i "search_term" file.txt`：不区分大小写搜索。

## 查看系统信息  ##
- `uname -a`：显示内核版本和系统信息。
- `df -h`：显示文件系统的磁盘使用情况。
- `free -h`：显示内存使用情况。
- `top`：实时显示系统资源监控。

## 管理进程  ##
- `ps aux`：列出所有运行的进程。
- `kill [pid]`：通过进程ID终止进程。
- `kill -9 [pid]`：强制终止进程。
- `killall process.name`：通过进程名称终止所有进程。

## 更改文件权限  ##
- `chmod 755 file.txt`：为文件分配读写执行权限（所有者：读写执行，组：只读执行，其他：只读执行）。
- `chmod u+x script.sh`：为脚本文件添加所有者执行权限。
- `chmod -R 777 /directory`：递归地为目录授予所有用户完全权限。

## 更改文件所有权  ##
- `chown user:group file.txt`：更改文件的所有者和组。
- `chown -R user:group /dir`：递归地更改目录中所有文件的所有者和组。

## 查找文件  ##
- `find /path -name "file.txt"`：按文件名搜索。
- `find /path -type f -size +100M`：搜索大于100MB的文件。
- `find /path -mtime -1`：查找过去24小时内修改的文件。

## 归档和压缩文件  ##
- `tar -cvf archive.tar /path`：创建目录的 tar 归档。
- `tar -xvf archive.tar`：提取 tar 归档。
- `tar -czvf archive.tar.gz /path`：创建压缩的 gzip tar 归档。
- `tar -xzvf archive.tar.gz`：提取压缩的 gzip tar 归档。

## 使用 sudo 进行管理权限操作  ##
- `sudo command`：以超级用户身份运行命令。
- `sudo su`：切换到 root 用户。
cd -ls 
