## SCI 1 ##  
1. 编译器（Compiler）是一种将高级编程语言（如C、C++、Java等）编写的源代码转换成机器语言（即计算机可以直接执行的指令）的软件工具。编译器的主要任务是将源代码进行词法分析、语法分析、语义分析、中间代码生成、优化以及目标代码生成等步骤，最终生成可执行文件。  
对于C/C++语言，市面上有多种编译器可供选择，以下是一些常见的C/C++编译器：

GCC (GNU Compiler Collection）、 Clang、Clang、Microsoft Visual C++ (MSVC)、Intel C++ Compiler (ICC)、
Borland C++ Compiler、MinGW (Minimalist GNU for Windows)、TCC (Tiny C Compiler)、DMD (D Language Foundation's D Compiler)。  
2. 根据June 2023发布的Top500榜单，能效比最高的超算系统是JEDI–JUPITER Exascale Development Instrument，这台超级计算机由德国的EuroHPC/FZJ开发，其能效评级高达72.73GFlop/W。而峰值性能最高的超算系统是Frontier，它以1.206 EFlop/s的峰值性能排名第一。

3. (1) 请你使用 hwloc 库的 lstopo 命令查看你做题时使用的机器的拓扑结构等##
```
~/Documents/code  lstopo
Machine (8192MB total)
  Package L#0
    NUMANode L#0 (P#0 8192MB)
    L3 L#0 (6144KB)
      L2 L#0 (256KB) + Core L#0
        L1d L#0 (32KB) + L1i L#0 (32KB) + PU L#0 (P#0)
        L1d L#1 (32KB) + L1i L#1 (32KB) + PU L#1 (P#1)
      L2 L#1 (256KB) + Core L#1
        L1d L#2 (32KB) + L1i L#2 (32KB) + PU L#2 (P#2)
        L1d L#3 (32KB) + L1i L#3 (32KB) + PU L#3 (P#3)
      L2 L#2 (256KB) + Core L#2
        L1d L#4 (32KB) + L1i L#4 (32KB) + PU L#4 (P#4)
        L1d L#5 (32KB) + L1i L#5 (32KB) + PU L#5 (P#5)
      L2 L#3 (256KB) + Core L#3
        L1d L#6 (32KB) + L1i L#6 (32KB) + PU L#6 (P#6)
        L1d L#7 (32KB) + L1i L#7 (32KB) + PU L#7 (P#7)
CoProc(OpenCL) "opencl0d1"
```  
(2) 请你使用 hwloc 库 lscpu 命令查看你做题时使用的机器的 CPU 型号等##
![lscpu](./1.png)  
![lscpu](./2.png)
(3) 请你使用 hwloc 库的 cpuid 等命令查看你做题时使用的机器 缓存大小 等
![lscpu](截屏2025-05-04%2011.10.45.png)

## SCI 2 ##
1.  
![SCI2](./截屏2025-05-04%2012.20.16.png)
2.  
./compile.sh help  
./compile.sh m0  
./compile.sh m1  
./compile.sh m2  
./compile.sh m3  
./compile.sh m4  
./compile.sh m5  
3.  
静态库（Static Library）和动态库（Dynamic Library）是两种不同类型的库文件，它们在编译、链接和运行时的行为有所不同。以下是它们的主要区别：
编译的简要流程：预处理，编译，汇编，链接
### 编译和链接时的行为

1. **静态库**：
   - 在编译和链接阶段，静态库的内容会被复制到最终的可执行文件中。
   - 这意味着每个使用静态库的可执行文件都会包含库的一个副本。
   - 这样做的好处是，最终的可执行文件不依赖于外部的库文件，可以在没有安装相应库的系统上运行。
   - 缺点是，如果多个程序使用了同一个静态库，那么每个程序都会包含库的副本，这会浪费磁盘空间。

2. **动态库**：
   - 在编译阶段，程序只会记录需要哪些函数和数据，并不会将库的内容复制到可执行文件中。
   - 在运行时，程序会从动态库中加载所需的代码和数据。
   - 这样做的好处是可以节省磁盘空间，因为多个程序可以共享同一个库文件。
   - 缺点是，如果库文件被删除或移动，或者库的版本不兼容，程序可能无法运行。

### 运行时的行为

1. **静态库**：
   - 静态库中的代码在程序启动时就已经加载到内存中，因此不需要在运行时动态加载。
   - 这可能会导致程序启动时间稍长，因为需要加载更多的代码。

2. **动态库**：
   - 动态库中的代码在程序运行时按需加载，这可以减少程序的启动时间。
   - 动态库可以被操作系统管理，例如，操作系统可以决定何时加载库，以及在多个程序之间共享库的内存。

### 更新和维护

1. **静态库**：
   - 更新静态库可能比较困难，因为每个使用该库的程序都需要重新编译和链接。
   - 这可能导致维护成本较高。

2. **动态库**：
   - 更新动态库相对容易，因为只需要替换库文件，不需要重新编译使用该库的所有程序。
   - 这使得动态库更容易维护和更新。

### 系统资源利用

1. **静态库**：
   - 由于每个程序都包含库的副本，可能会占用更多的内存和磁盘空间。

2. **动态库**：
   - 多个程序可以共享同一个库，这有助于节省系统资源。

### 安全性和稳定性

1. **静态库**：
   - 由于程序不依赖于外部文件，因此可能更稳定。

2. **动态库**：
   - 程序依赖于外部文件，如果文件损坏或丢失，程序可能无法运行。

总的来说，选择静态库还是动态库取决于具体的应用场景、性能要求、维护成本以及对系统资源的考虑。在某些情况下，开发者可能会同时提供静态库和动态库，以供用户根据需要选择。  
4. 
在使用编译器（如 `gcc` 或 `g+++`）编译程序时，编译参数（也称为编译选项或标志）用于控制编译过程的不同方面。以下是一些常用的编译参数及其意义：

1. **`-c`**：
   - 编译源代码但不进行链接。生成目标文件（.o 文件）。

2. **`-o <file>`**：
   - 指定输出文件的名称。用于指定编译后生成的可执行文件或目标文件的名称。

3. **`-g`**：
   - 包含调试信息。生成的可执行文件将包含足够的信息，以便在调试器中使用。

4. **`-O, -O1, -O2, -O3`**：
   - 优化代码。`-O` 是 `-O1` 的简写，`-O2` 和 `-O3` 提供更高级别的优化。优化可以提高程序的运行效率，但可能会使编译时间变长。

5. **`-Wall`**：
   - 打开所有编译警告。这有助于发现代码中的问题。

6. **`-Werror`**：
   - 将所有警告视为错误。这可以强制编译器在遇到警告时停止编译。

7. **`-std=c++11`** 或 `-std=c+++11`**：
   - 指定使用的 C+++ 语言标准。例如，`-std=c++11` 用于启用 C+++11 特性。

8. **`-I<dir>`**：
   - 添加头文件搜索路径。编译器将在指定的目录中搜索头文件。

9. **`-L<dir>`**：
   - 添加库文件搜索路径。链接器将在指定的目录中搜索库文件。

10. **`-l<libname>`**：
    - 链接指定的库。例如，`-lpthread` 用于链接 POSIX 线程库。

11. **`-static`**：
    - 静态链接库。在最终的可执行文件中包含所有需要的库代码。

12. **`-shared`**：
    - 生成共享库（动态库）。

13. **`-fPIC`**：
    - 生成位置无关代码。这对于创建动态库是必需的。

14. **`-fopenmp`**：
    - 启用 OpenMP 支持，用于并行编程。

15. **`-D<macro>`**：
    - 定义宏。例如，`-DDEBUG` 定义了一个名为 `DEBUG` 的宏。

16. **`-U<macro>`**：
    - 取消定义宏。

17. **`-E`**：
    - 只运行预处理器。

18. **`-S`**：
    - 生成汇编代码文件。

19. **`-x <language>`**：
    - 指定源文件的语言。例如，`-x c+++` 指定源文件是 C+++。

这些编译参数可以根据需要组合使用，以控制编译过程的不同方面。正确使用这些参数可以帮助你生成更高效、更可靠的程序。  

## SCI 3 ##  

[wyy@inspur1 src]$ export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH  

[wyy@inspur1 src]$ mpirun -np 1 ./matrix_cal_mpi_cuda
![解决](截屏2025-05-04%2017.52.34.png) 

[wyy@inspur1 src]$ mpirun -np 1 ./matrix_cal_mpi_cuda  
**np改为一，单机运算**  

![solve](截屏2025-05-04%2018.02.08.png)  

## 编译 ##  
编译cuda代码  
nvcc -I../inc -o matrix_cal_cuda matrix_cal_cuda.cu -lmpi  

## Intel VTune ##
**source /opt/intel/oneapi/setvars.sh**:配置环境  
**ls**:查看目录  
**vtune -collect hotspots ./matrix_cal_cuda**:分析热点  
**vtune-server --help**:查看vtune-server帮助信息  
**vtune-server --data-directory .**:会生成一个网站，com+单击 即可打开网站 

```
使用前先使用source /opt/intel/oneapi/setvars.sh来为vtune的使用配置环境。
然后vtune-server --data-direectory来打开
vtune -collect hotspots ./a.out：进行热点分析
vtune -collect memory-hotspots ./a.out:内存热点分析
vtune -collect threading ./a.out：线程分析
```
![solve](截屏2025-05-05%2011.17.03.png)
![solve](截屏2025-05-05%2011.19.39.png)