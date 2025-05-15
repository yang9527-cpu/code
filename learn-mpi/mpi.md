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
(1). 对等模式（以Jacobi迭代为例） 
对于MPI的SPMD(Single Program Multiple Data)程序，实现对等模式的问题是比较容易理解和接受的，因为各个部分地位相同功能和代码基本一致，只不过是处理的数据或对象不同，也容易用同样的程序来实现。

Jacobi迭代就是用上下左右周围的四个点取平均值来得到新的点。
```c++
while (not converged) {
  for (i,j)
    xnew[i][j] = (x[i+1][j] + x[i-1][j] + x[i][j+1] + x[i][j-1])/4;
  for (i,j)
    x[i][j] = xnew[i][j];
  }
```
收敛性测试如下:
```c++
diffnorm = 0;
for (i,j)
    diffnorm += (xnew[i][j] - x[i][j]) * (xnew[i][j] - x[i][j]);
diffnorm = sqrt(diffnorm);
```
Jacobi迭代的局部性很好可以取得很高的并行性，是并行计算中常见的一个例子。将参加迭代的数据按块分割后，各块之间除了相邻的元素需要通信外，在各块的内部可以完全独立地并行计算，随着计算规模的扩大，通信的开销相对于计算来说比例会降低，这将更有利于提高并行效果。
![tu](截屏2025-05-15%2017.11.26.png)  
由于在迭代过程中边界点新值的计算需要相邻边界其它块的数据，因此在每一个数据块的两侧又各增加1列的数据空间（注意FORTRAN数组在内存中是按列优先排列的），用于存放从相邻数据块通信得到的数据。

在迭代之前，每个进程都需要从相邻的进程得到数据块，同时每一个进程也都需要向相邻的进程提供数据块，由于每一个新迭代点的值是由相邻点的旧值得到，所以这里引入一个中间数组用来记录临时得到的新值，一次迭代完成后再统一进行更新操作。
![tu](截屏2025-05-15%2017.18.45.png)  
![tu](截屏2025-05-15%2018.20.53.png)  
在边界上的点不用更新，初始值定义如下（上下两边都是-1，中间的数值取为进程编号）：  
```c++
#include <stdio.h>
#include <math.h>
#include "mpi.h"
 
/* This example handles a 12 x 12 mesh, on 4 processors only. */
#define maxn 12
 
int main( argc, argv )
int argc;
char **argv;
{
    int        rank, value, size, errcnt, toterr, i, j, itcnt;
    int        i_first, i_last;
    MPI_Status status;
    double     diffnorm, gdiffnorm;
    double     xlocal[(12/4)+2][12];
    double     xnew[(12/3)+2][12];
 
    MPI_Init( &argc, &argv );
 
    MPI_Comm_rank( MPI_COMM_WORLD, &rank );
    MPI_Comm_size( MPI_COMM_WORLD, &size );
 
    if (size != 4) MPI_Abort( MPI_COMM_WORLD, 1 );
 
    /* xlocal[][0] is lower ghostpoints, xlocal[][maxn+2] is upper */
 
    /* Note that top and bottom processes have one less row of interior
       points */
    i_first = 1;
    i_last  = maxn/size;
    if (rank == 0)        i_first++;
    if (rank == size - 1) i_last--;
 
    /* Fill the data as specified */
    for (i=1; i<=maxn/size; i++) 
	for (j=0; j<maxn; j++) 
	    xlocal[i][j] = rank;
    for (j=0; j<maxn; j++) {
	xlocal[i_first-1][j] = -1;
	xlocal[i_last+1][j] = -1;
    }
 
    itcnt = 0;
    do {
	/* Send up unless I'm at the top, then receive from below */
	/* Note the use of xlocal[i] for &xlocal[i][0] */
	if (rank < size - 1) 
	    MPI_Send( xlocal[maxn/size], maxn, MPI_DOUBLE, rank + 1, 0, 
		      MPI_COMM_WORLD );
	if (rank > 0)
	    MPI_Recv( xlocal[0], maxn, MPI_DOUBLE, rank - 1, 0, 
		      MPI_COMM_WORLD, &status );
	/* Send down unless I'm at the bottom */
	if (rank > 0) 
	    MPI_Send( xlocal[1], maxn, MPI_DOUBLE, rank - 1, 1, 
		      MPI_COMM_WORLD );
	if (rank < size - 1) 
	    MPI_Recv( xlocal[maxn/size+1], maxn, MPI_DOUBLE, rank + 1, 1, 
		      MPI_COMM_WORLD, &status );
	
	/* Compute new values (but not on boundary) */
	itcnt ++;
	diffnorm = 0.0;
	for (i=i_first; i<=i_last; i++) 
	    for (j=1; j<maxn-1; j++) {
		xnew[i][j] = (xlocal[i][j+1] + xlocal[i][j-1] +
			      xlocal[i+1][j] + xlocal[i-1][j]) / 4.0;
		diffnorm += (xnew[i][j] - xlocal[i][j]) * 
		            (xnew[i][j] - xlocal[i][j]);
	    }
	/* Only transfer the interior points */
	for (i=i_first; i<=i_last; i++) 
	    for (j=1; j<maxn-1; j++) 
		xlocal[i][j] = xnew[i][j];
 
	MPI_Allreduce( &diffnorm, &gdiffnorm, 1, MPI_DOUBLE, MPI_SUM,
		       MPI_COMM_WORLD );
	gdiffnorm = sqrt( gdiffnorm );
	if (rank == 0) printf( "At iteration %d, diff is %e\n", itcnt, 
			       gdiffnorm );
    } while (gdiffnorm > 1.0e-2 && itcnt < 100);
 
    MPI_Finalize( );
    return 0;
}
```
编译命令：
```bash
mpicc -o jacobi jacobi.c -lm
```
运行命令：
```bash
mpirun -np 4 ./jacobi
```

(2) 主从模式  

现介绍另一种并行程序的设计模式——主从模式：我们可以在逻辑上规定一个主进程，用于将数据发送给各个进程，再收集各个进程所计算的结果。  
例子1：A simple output server  
实现三个功能：

1. 有序输出 Ordered output 
2. 无序输出 Unordered output 
3. 退出通知 Exit notification
关于程序逻辑：
1. 主进程（Master）会持续接收消息，直到它从每一个从属进程（Slave）那里都收到了退出通知（或退出消息）为止。
2. 为简化编程，让每个从属进程（Slave）负责发送这些消息。
```bash
"Hello from slave %d, ordered print\n", rank
"Goodbye from slave %d, ordered print\n", rank
```
```bash
"I'm existing (%d), unordered print\n", rank
```

