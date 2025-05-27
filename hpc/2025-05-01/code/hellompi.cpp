#include <iostream>
#include <mpi.h>

int main(int argc, char** argv) {
  // 初始化 MPI 环境
  MPI_Init(&argc, &argv);

  // 获取当前进程的 rank (ID)
  int world_rank;
  MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

  // 获取通信域中的进程总数
  int world_size;
  MPI_Comm_size(MPI_COMM_WORLD, &world_size);

  // 打印 Hello, World! 消息，包含进程的 rank 和总数
  std::cout << "Hello, World! 来自进程 " << world_rank << " (共 " << world_size << " 个进程)" << std::endl;

  // 清理 MPI 环境
  MPI_Finalize();

  return 0;
}