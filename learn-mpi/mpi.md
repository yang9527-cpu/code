# mpi #
## 简介 ##  
mpi（信息传递接口）：可以通过mpi，可以在不同进程间传递消息，从而可以并行处理任务，即并行计算  
## 第一个mpi程序 ##  
*MPI 程序通常使用 C, C++ 或 Fortran 编写。*
```c++
#include"mpi.h"
#include<stdio.h>
#include<math.h>

void main(argc,argv)
int argc;
char *argv[];
{
    int myid,numprocs;
    int namelen;
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    //相关变量声明

    MPI_Init(&argc,&argv);
    //程序开始

    MPI_Comm_rank(MPI_COMM_WORLD,&myid);
    MPI_Comm_size(MPI_COMM_WORLD,&numprocs)；
    MPI_GET_processer_name(processer_name,&namelen);
    fprintf(stderr,"Hello world!Process%d of %d on %s\n",myid,numprocs,processor_name);
    //程序体 计算与通信

    MPI_Finalize();
    //程序结束
}
```
## 六个MPI基本函数 ##
MPI (Message Passing Interface) 包含许多函数，但对于初学者或者构建基本并行程序来说，以下六个函数可以被认为是最核心和最基本的：

1. MPI_Init

功能: 初始化MPI执行环境。这是几乎所有MPI程序中第一个需要调用的MPI函数（除了少数几个查询状态的函数）。它负责建立MPI运行所需的所有内部数据结构和通信通道。
```c++
int MPI_Init(int *argc, char ***argv);
```
```f90
CALL MPI_INIT(ierror)
```
2. MPI_Finalize

功能: 终止MPI执行环境。这是几乎所有MPI程序中最后一个需要调用的MPI函数。它负责释放MPI在 MPI_Init 时分配的所有资源。
```c++
int MPI_Finalize(void);
```
```f90
CALL MPI_FINALIZE(ierror)
```
3. MPI_Comm_size

功能: 获取指定通信域（communicator）中的进程总数。最常用的通信域是 MPI_COMM_WORLD，它包含了程序启动时的所有MPI进程。
```c++
int MPI_Comm_size(MPI_Comm comm, int *size);
```
```f90
CALL MPI_COMM_SIZE(comm, size, ierror)
```
4. MPI_Comm_rank

功能: 获取当前调用进程在指定通信域中的秩（rank）或称编号。秩是一个从 0 到 size-1 的整数，唯一标识了通信域中的一个进程。
```c++
int MPI_Comm_rank(MPI_Comm comm, int *rank);
```
```f90
CALL MPI_COMM_RANK(comm, rank, ierror)
```

5. MPI_Send

功能: 一个进程向指定通信域中的另一个进程发送消息（数据）。这是一个基本的点对点（point-to-point）通信操作，通常是阻塞式的（程序会等待消息被安全地发出或复制到缓冲区后才继续执行）。
```c++
int MPI_Send(const void *buf, int count, MPI_Datatype datatype, int dest, int tag, MPI_Comm comm);
```
buf: 发送缓冲区的起始地址。  
count: 发送元素的数量。  
datatype: 发送元素的数据类型 (如 MPI_INT, MPI_DOUBLE)。  
dest: 目标进程的秩。  
tag: 消息标签，用于区分不同的消息。  
comm: 通信域。  
```f90
CALL MPI_SEND(buf, count, datatype, dest, tag, comm, ierror)
```

6. MPI_Recv

功能: 一个进程从指定通信域中的另一个进程接收消息。这也是一个基本的点对点通信操作，通常是阻塞式的（程序会等待直到接收到符合条件的消息才继续执行）。
```c++
int MPI_Recv(void *buf, int count, MPI_Datatype datatype, int source, int tag, MPI_Comm comm, MPI_Status *status);
```
buf: 接收缓冲区的起始地址。
count: 接收缓冲区的最大元素容量。
datatype: 接收元素的数据类型。
source: 源进程的秩（也可以是 MPI_ANY_SOURCE）。
tag: 期望接收的消息标签（也可以是 MPI_ANY_TAG）。
comm: 通信域。
status: 一个 MPI_Status 结构体，返回接收操作的详细信息（如实际接收到的数据量、源进程、标签）。
```f90
CALL MPI_RECV(buf, count, datatype, source, tag, comm, status, ierror) 
!在Fortran中, status 通常是一个整型数组
```
这六个函数构成了编写简单MPI程序的基础框架：初始化环境，了解并行规模和自身身份，进行数据交换，最后清理环境。掌握了它们，就可以开始构建并行应用了。当然，MPI标准库中还有许多其他重要的函数，用于更复杂的通信模式（如非阻塞通信、集合通信等）。  

## MPI并行程序的两种基本模式 ##  
