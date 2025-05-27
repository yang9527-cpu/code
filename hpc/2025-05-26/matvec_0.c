#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>

void print_matrix(double** T, int rows, int cols);
void print_vector(double* T, int cols);

int main (int argc, char *argv[]) 
{
   double* a0; //auxiliary 1D array to make a contiguously allocated
   double** a; //the two-dimensional input matrix
   double* x; //input vector
   double* b; //the resulting vector

   int NRA, NCA; //matrix size

   int i, k; // Loop variables i, j, k from original code were simplified to i, k for mat-vec
   struct timeval start_time, end_time;
   long seconds, microseconds;
   double elapsed;

   if (argc == 3){
      NRA = atoi(argv[1]); 
      NCA = atoi(argv[2]);

      printf("NRA = %d, NCA = %d\n", NRA, NCA);
    }  
    else{
            printf("Usage: %s NRA NCA\n\n"
                   " NRA: matrix a row length\n"
                   " NCA: matrix a column (or x) length\n\n", argv[0]);
        return 1;
    }

   // Allocate contiguous memory for 2D matrices
   a0 = (double*)malloc(NRA*NCA*sizeof(double));
   a = (double**)malloc(NRA*sizeof(double*));
   for (int r=0; r<NRA; r++){ // Changed loop var to 'r' to avoid conflict if i,j,k are used later
      a[r] = a0 + r*NCA;
   }

   //Allocate memory for vectors      
   x = (double*)malloc(NCA*sizeof(double));
   b = (double*)malloc(NRA*sizeof(double));

  printf("Initializing matrix and vectors\n\n");
  srand(time(0)); // Seed the random number generator
  /*** Initialize matrix and vectors ***/
  for (int r=0; r<NRA; r++) // Changed loop var to 'r'
    for (int c=0; c<NCA; c++) // Changed loop var to 'c'
      a[r][c]= (double) rand() / RAND_MAX;

  for (int r=0; r<NCA; r++) // Changed loop var to 'r'
      x[r] = (double) rand() / RAND_MAX;

  for (int r=0; r<NRA; r++) // Changed loop var to 'r'
      b[r]= 0.0;

/* printf ("matrix a:\n");
  print_matrix(a, NRA, NCA);
  printf ("vector x:\n");
  print_vector(x, NCA);
  printf ("vector b:\n");
  print_vector(b, NRA);
*/

  printf("Starting matrix-vector multiplication (i-loop unrolled by 4)\n\n");
  gettimeofday(&start_time, 0);

  int unroll_factor = 4;
  // 计算可以进行完整4次展开的部分的上限
  int i_limit_unrolled = NRA - (NRA % unroll_factor); 

  for (i = 0; i < i_limit_unrolled; i += unroll_factor) {
      // 为展开的四行初始化临时累加器 (因为b[i]在之前已全部初始化为0.0)
      double temp_b0 = 0.0;
      double temp_b1 = 0.0;
      double temp_b2 = 0.0;
      double temp_b3 = 0.0;
      double x_k_val; // 用于在内层循环外加载 x[k]

      for (k = 0; k < NCA; k++) {
          x_k_val = x[k]; // 将 x[k] 加载一次，供内部多次使用
          temp_b0 += a[i]    [k] * x_k_val;
          temp_b1 += a[i + 1][k] * x_k_val;
          temp_b2 += a[i + 2][k] * x_k_val;
          temp_b3 += a[i + 3][k] * x_k_val;
      }
      // 将累加结果存回 b 向量
      b[i]     = temp_b0;
      b[i + 1] = temp_b1;
      b[i + 2] = temp_b2;
      b[i + 3] = temp_b3;
  }

  // 处理 NRA 不能被 unroll_factor (4) 整除时余下的行 (尾部循环)
  for (; i < NRA; i++) {
      double temp_b_remainder = 0.0; // 为当前行初始化累加器
      for (k = 0; k < NCA; k++) {
          temp_b_remainder += a[i][k] * x[k];
      }
      b[i] = temp_b_remainder;
  }
  // ====================================================================
  // +++ 优化部分结束 +++
  // ====================================================================

  gettimeofday(&end_time, 0);
  seconds = end_time.tv_sec - start_time.tv_sec;
  microseconds = end_time.tv_usec - start_time.tv_usec;
  elapsed = seconds + 1e-6 * microseconds;
  printf("The computation takes %f seconds to complete.\n\n", elapsed); 
  
  
/*** Print results ***/
// printf("******************************************************\n");
// printf("Resulting vector:\n");
// print_vector(b, NRA);
// printf("******************************************************\n");

    // Free allocated memory
    free(a0);
    free(a);
    free(b);
    free(x);

    return 0; // Added return 0 for main
}

void print_matrix(double** T, int rows, int cols){
    for (int i=0; i < rows; i++){
        for (int j=0; j < cols; j++)
            printf("%.2f  ", T[i][j]);
        printf("\n");
    }
    printf("\n\n");
    return;
}

void print_vector(double* T, int cols){
    for (int i=0; i < cols; i++)
       printf("%.2f  ", T[i]);
    printf("\n\n");
    return;
}