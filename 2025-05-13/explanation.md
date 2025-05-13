# 优化 #
1. OpenMP 优化  

do jj 循环是 OpenMP 并行化的理想目标。  
!$OMP PARALLEL DO 指令:
可以直接在循环前添加 OpenMP 并行指令。
```f90
!$OMP PARALLEL DO PRIVATE(jj) SHARED(phi, lbasdy, jfirst, jlast) SCHEDULE(STATIC) DEFAULT(NONE)
do jj = jfirst,jlast
   call lcdbas( phi(jj-1), lbasdy(1,1,jj), lbasdy(1,2,jj) )
end do
!$OMP END PARALLEL DO
```
2. 数据作用域 (Data Scoping):  

jj: 循环迭代变量，对于每个线程必须是 PRIVATE (私有的)。
phi: 输入数组，在循环内部是只读的（或者其片段被传递给 lcdbas 读取）。应声明为 SHARED (共享的)。
lbasdy: 输出数组。每个线程写入 lbasdy 的不同部分 lbasdy(:,:,jj)。应声明为 SHARED。
jfirst, jlast: 循环的起始和结束边界。它们是由模块 scanslt 中的参数 nxpt 和 platd 定义的参数，对于并行区域来说是常量，可以视为 SHARED。(在原代码中，它们是 parameter，所以天然是共享的)。  


SCHEDULE 子句 (调度策略):
SCHEDULE(STATIC): 如果每次调用 lcdbas 的工作量大致相同，静态调度（在开始时将迭代尽可能均匀地分配给线程）效率较高，开销也小。这是一个很好的默认选项。
SCHEDULE(DYNAMIC, chunk_size): 如果 lcdbas 调用的执行时间差异较大，动态调度可能提供更好的负载均衡，但调度开销也更大。
SCHEDULE(GUIDED, chunk_size): 一种折中方案，初始块较大，然后逐渐减小。 对于这个例程，除非 lcdbas 每次调用的性能差异极大，否则 SCHEDULE(STATIC) 可能就足够了。
lcdbas 的线程安全性:
并行化的一个关键前提是子程序 lcdbas 必须是线程安全的。这意味着：

它不应在没有适当同步的情况下修改任何共享的全局变量（对于这类计算核心来说不太可能）。
它不应依赖任何在调用之间保持状态的静态局部变量，以免与并行执行冲突。 考虑到其功能（计算拉格朗日基函数权重），lcdbas 几乎可以肯定是纯计算函数，因此是线程安全的。
针对少量循环迭代的 IF 子句:
如果循环迭代次数 (jlast - jfirst + 1) 非常少，创建和管理线程的开销可能会超过并行带来的好处。可以使用 IF 子句：

```f90
integer :: num_iterations
num_iterations = jlast - jfirst + 1
! 阈值示例，例如线程数的两倍
!$OMP PARALLEL DO PRIVATE(jj) SHARED(phi, lbasdy, jfirst, jlast) SCHEDULE(STATIC) DEFAULT(NONE) IF(num_iterations > omp_get_max_threads() * 2)
do jj = jfirst,jlast
   call lcdbas( phi(jj-1), lbasdy(1,1,jj), lbasdy(1,2,jj) )
end do
!$OMP END PARALLEL DO
!IF 子句中的阈值需要通过实验来调整。
```
2. MPI 优化

MPI 用于分布式内存并行计算，通常跨越集群中的不同计算节点。
数据分解策略:

此处使用 MPI 的主要方式是在不同的 MPI 进程（rank）之间分配 jj 循环的迭代任务。
phi 数组:
如果 phi 数组非常大，它也可能需要在 MPI 进程间进行分解。每个进程将拥有 phi 的一个片段。
当一个进程处理其分配的 jj 值时，它需要访问 phi(jj-1) 到 phi(jj+2) 的数据。如果 phi 是分布式的，这将需要“晕轮”或“影子单元”(halo/ghost cells) 的数据交换，以确保每个进程在其本地片段的边界附近拥有必要的 phi 值。
或者，如果 phi 不是特别大，它可以在所有 MPI 进程中复制。
lbasdy 数组: 每个 MPI 进程将计算其分配到的 jj 值对应的 lbasdy 数组部分。在本地计算完成后，可能需要使用 MPI_Allgatherv 或类似的 MPI 集合操作将完整的 lbasdy 数组汇集到所有进程或某个根进程上（如果后续计算需要）。
修改后的子程序或调用结构:
basdy 子程序本身可能不直接包含 MPI 调用。相反，调用它的代码将管理 MPI 的数据分解和任务分配：

```f90
! 在一个更高级别的、MPI并行化的例程中
! MPI_COMM_RANK(comm, my_rank) ! 获取当前进程号
! MPI_COMM_SIZE(comm, num_procs) ! 获取总进程数

! 根据全局的 jfirst, jlast 为当前 my_rank 计算 local_jfirst 和 local_jlast
! (这里省略了具体的迭代分配逻辑，例如简单的块划分)
integer :: global_jfirst, global_jlast
integer :: my_jfirst, my_jlast ! 当前进程负责的 jj 起始和结束 (全局索引)

global_jfirst = nxpt + 1
global_jlast  = platd - nxpt - 1
! (此处添加计算 my_jfirst, my_jlast 的逻辑)

! 确保 phi_local 包含 [my_jfirst-1 : my_jlast+2] 所需的数据
! (这取决于 phi 如何分布以及是否管理了晕轮区)
! phi_local 可能是全局 phi 数组的一个片段。
! lbasdy_local 将存储 jj 在 [my_jfirst : my_jlast] 范围内的结果。

! 方案1: 调用一个修改过的、接受本地范围的 basdy
! call basdy_mpi_local(phi_local_with_halos, lbasdy_local, my_jfirst_local_idx, my_jlast_local_idx, ...)

! 方案2: 直接在 MPI 上下文中循环 (更常见的是外部控制循环范围)
if (my_jfirst <= my_jlast) then ! 确保当前进程有工作要做
    do jj = my_jfirst, my_jlast  ! jj 此处是全局索引
       ! 必须能够访问 phi(jj-1)。如果 phi 是分布式的，
       ! 这里的访问需要映射到带有晕轮区的本地 phi 数组。
       call lcdbas( phi(jj-1), lbasdy(1,1,jj), lbasdy(1,2,jj) )
       ! lbasdy 如果是本地数组片段，也需要正确索引。
    end do
end if

! 如果需要，从所有进程收集 lbasdy
! call MPI_Allgatherv(...)
上述 MPI 分配逻辑是示意性的。
```
混合 MPI + OpenMP 编程:
这是一种非常常见且强大的方法。每个 MPI 进程处理 jj 迭代的一个子集。在每个 MPI 进程内部，再使用 OpenMP 来利用线程进一步并行化其分配到的 jj 循环。前面讨论的 OpenMP 指令将应用于每个 MPI 进程在其本地 jj 范围上运行的循环。

3. 编译器优化

无论是否进行显式并行化：

确保使用 Fortran 编译器提供的适当优化标志（例如 -O2, -O3, -march=native，以及特定于向量化的标志）。
如果 lcdbas 被内联（尽管在 OpenMP 目标循环中内联子程序调用需要编译器仔细处理），编译器或许能够对 lcdbas 内部的操作甚至 basdy 进行一定程度的自动向量化。

*五份代码都是类似方法优化*  
提升了 3秒左右  
atm/cam/src/advection 将剩余的代码按照相同的方法优化可能会提高更多  
