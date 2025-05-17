#include <stdio.h>
#include <string.h>
#include "mpi.h"
 
#define MSG_EXIT 1
#define MSG_PRINT_ORDERED 2
#define MSG_PRINT_UNORDERED 3
 
void master_io()
{
    int size;   // 总进程数
    int nslave; // 从进程数
    int firstmsg;
    char buf[256], buf2[256];
    MPI_Status status;
    MPI_Comm_size(MPI_COMM_WORLD, &size); // 得到总的进程数
    nslave = size - 1;
    while (nslave > 0)
    {                                                                                       // 只要还有从进程则执行下面的接收与打印
        MPI_Recv(buf, 256, MPI_CHAR, MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_COMM_WORLD, &status); // 从任意从进程接收任意标识的消息
        switch (status.MPI_TAG)
        {
        // 若该从进程要求退出,则将总的从进程个数减1
        case MSG_EXIT:
            nslave--;
            break;
        // 若该从进程要求乱序打印,则直接将该消息打印
        case MSG_PRINT_UNORDERED:
            fputs(buf, stdout);
            break;
        // 按顺序打印
        // 首先需要对收到的消息进行排序，若有些消息还没有收到则，需要调用接收语句接收相应的有序消息
        case MSG_PRINT_ORDERED:
            firstmsg = status.MPI_SOURCE; // the rank of the process that sent the message.
            for (int i = 1; i < size; ++i)
            {
                // 若接收到的消息恰巧是需要打印的消息则直接打印
                if (i == firstmsg)
                {
                    fputs(buf, stdout);
                }
                else
                { // 否则,先接收需要打印的消息然后再打印
                    MPI_Recv(buf2, 256, MPI_CHAR, i, MSG_PRINT_ORDERED, MPI_COMM_WORLD, &status);
                    fputs(buf2, stdout);
                }
            }
            break;
                }
    }
}
 
void slave_io()
{
    char buf[256];
    int rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    // 向主进程发送一个有序打印消息
    sprintf(buf, "Hello from slave %d, ordered print\n", rank);
    MPI_Send(buf, strlen(buf) + 1, MPI_CHAR, 0, MSG_PRINT_ORDERED, MPI_COMM_WORLD);
    // 再向主进程发送一个有序打印消息
    sprintf(buf, "Goodbye from slave %d, ordered print\n", rank);
    MPI_Send(buf, strlen(buf) + 1, MPI_CHAR, 0, MSG_PRINT_ORDERED, MPI_COMM_WORLD);
    // 向主进程发送一个乱序打印的消息
    sprintf(buf, "I'm existing (%d), unordered print\n", rank);
    MPI_Send(buf, strlen(buf) + 1, MPI_CHAR, 0, MSG_PRINT_UNORDERED, MPI_COMM_WORLD);
    // 最后，向主进程发送退出执行的消息
    MPI_Send(buf, 0, MPI_CHAR, 0, MSG_EXIT, MPI_COMM_WORLD);
}
 
int main(int argc, char **argv)
{
    int rank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    if (rank == 0)
    {
        master_io(); // process 0 is the master process
    }
    else
    {
        slave_io(); // other prcess is the slave processes
    }
    MPI_Finalize();
}
//mpicxx -o output_executable source_file.cpp [其他编译选项] [链接库选项]
//mpirun -np <进程数> ./output_executable

