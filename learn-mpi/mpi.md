# mpi #
## 简介 ##  
mpi（信息传递接口）：可以通过mpi，可以在不同进程间传递消息，从而可以并行处理任务，即并行计算  
## 第一个mpi程序 ##  
```mpi
#include"mpi.h"
#include<stdio.h>
#include<math.h>
//

void main(argc,argv)
int argc;
char *argv[];
{
    int myid,numprocs;
    int namelen;
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    //

    MPI_Init(&argc,&argv);
    MPI_Comm_rank(MPI_COMM_WORLD,&myid);
    MPI_Comm_size(MPI_COMM_WORLD,&numprocs)

}