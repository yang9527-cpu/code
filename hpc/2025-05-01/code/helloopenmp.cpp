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