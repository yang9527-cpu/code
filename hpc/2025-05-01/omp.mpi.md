# openmp #  
**1.安装gcc@14**  
```
brew install gcc@14
```
**2.omp编译**  
```c++
#include <iostream>
#include <omp.h>

int main() {
  #pragma omp parallel
  {
    int thread_id = omp_get_thread_num();
    int num_threads = omp_get_num_threads();
    std::cout << "Hello, World! 来自线程 " << thread_id << " (共 " << num_threads << " 个线程)" << std::endl;
  }
  return 0;
}
```  

```
g++-14 -fopenmp helloopenmp.cpp -o helloopenmp
./helloopenmp
```  
# mpi #
**1.下载mpich**
```
brew install mpich
```
**2.编译**  
```c++
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
```
```
mpic++ hellompi.cpp -o hellompi
./hellompi
```
