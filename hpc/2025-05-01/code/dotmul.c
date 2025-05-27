#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <math.h>

/* 计算两个长度为 n 的双精度向量 a 和 b 的点乘 */
#include <omp.h>

double dot_product_omp(const double *a, const double *b, size_t n) {
    double sum = 0.0;
    #pragma omp parallel for reduction(+:sum)
    for (size_t i = 0; i < n; ++i) {
        sum += a[i] * b[i];
    }
    return sum;
}

/* 验证 compute_result 与重新计算的 dot product 是否在误差范围内一致 */
int verify(const double *a, const double *b, size_t n, double compute_result) {
    double gold = 0.0;
    for (size_t i = 0; i < n; i++) {
        gold += a[i] * b[i];
    }
    double tolerance = 1e-4; // 调整容差为 1e-4
    if (fabs(compute_result - gold) < tolerance) {
        return 1;  /* 正确 */
    } else {
        printf("验证失败: 计算结果 = %.10f, 参考结果 = %.10f, 误差 = %.10e (容差 = %.10e)\n",
               compute_result, gold, fabs(compute_result - gold), tolerance);
        return 0;  /* 错误 */
    }
}

int main(int argc, char *argv[]) {
    /* 向量大小，可通过命令行传入 */
    size_t n = 100000000;
    if (argc > 1) {
        n = strtoull(argv[1], NULL, 10);
        if (n == 0) {
            fprintf(stderr, "无效的向量长度，“%s”\n", argv[1]);
            return EXIT_FAILURE;
        }
    }

    /* 动态分配两组向量 */
    double *a = malloc(n * sizeof(double));
    double *b = malloc(n * sizeof(double));
    if (!a || !b) {
        perror("malloc");
        return EXIT_FAILURE;
    }

    /* 随机初始化向量 */
    srand((unsigned)time(NULL));
    for (size_t i = 0; i < n; i++) {
        a[i] = (double)rand() / RAND_MAX;
        b[i] = (double)rand() / RAND_MAX;
    }

    /* 计时开始 */
    struct timespec ts_start, ts_end;
    if (clock_gettime(CLOCK_MONOTONIC, &ts_start) != 0) {
        perror("clock_gettime");
        return EXIT_FAILURE;
    }

    /* 点乘计算 */
    double result = dot_product_omp(a, b, n);

    /* 计时结束 */
    if (clock_gettime(CLOCK_MONOTONIC, &ts_end) != 0) {
        perror("clock_gettime");
        return EXIT_FAILURE;
    }

    /* 计算耗时（秒） */
    double elapsed = (ts_end.tv_sec - ts_start.tv_sec)
                   + (ts_end.tv_nsec - ts_start.tv_nsec) / 1e9;

    printf("向量长度: %zu\n", n);
    printf("点乘结果: %.6f\n", result);
    printf("计算耗时: %.6f 秒\n", elapsed);

    /* 正确性校验 */
    if (verify(a, b, n, result)) {
        printf("结果校验: 正确 ✅\n");
    } else {
        printf("结果校验: 错误 ❌\n");
    }

    /* 释放内存 */
    free(a);
    free(b);

    return 0;
}
