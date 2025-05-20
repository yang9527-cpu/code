MPI (Message Passing Interface) 并行  
共享内存并行   
与radiation较为类似  
重点展示micro_mg_cam_tend子程序中被修改以支持OpenMP并行的部分。其他子程序如micro_mg_cam_readnl, micro_mg_cam_register, micro_mg_cam_init等，主要是进行初始化、注册和读写操作，它们的循环次数较少或不是性能瓶颈，通常不作OpenMP并行化或并行化收益不大。

报错较多  
修改后，多次调试  
在radiation基础上，由5-19的754->760；
还原代码  
负优化 3s  
