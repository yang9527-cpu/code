# qrs/qrl 与 pdel 的乘除操作 (能量守恒转换):   

代码中使用了 !DIR$ CONCURRENT。这可以替换为标准的 OpenMP：  

```F90
!984
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(pver, ncol, qrs, qrl, state) &
!$OMP PRIVATE(k,i) COLLAPSE(2) SCHEDULE(STATIC)
do k =1 , pver
   do i = 1, ncol
      qrs(i,k) = qrs(i,k)/state%pdel(i,k)
      qrl(i,k) = qrl(i,k)/state%pdel(i,k)
   end do
end do
```
# 计算 HR (加热率) 的循环
```f90
!1004
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(pver, ncol, ftem, qrs, qrl, cpair, state, cappa) &
!$OMP PRIVATE(k,i) COLLAPSE(2) SCHEDULE(STATIC)
do k=1,pver
   do i=1,ncol
      ftem(i,k) = (qrs(i,k) + qrl(i,k))/cpair * (1.e5_r8/state%pmid(i,k))**cappa
   end do
end do
!$OMP END PARALLEL DO
```
# 使用 IdxDay/IdxNite 的循环 如计算云光学厚度  
```f90

# 核心辐射计算调用 (radcswmx, radclwmx)

这些是辐射模块中最主要的计算部分。
它们通常是针对 ncol 个大气柱进行计算。这些子程序内部的 i=1,ncol 循环是 OpenMP 并行化的首要目标。
概念性示例 (在 radcswmx 或 radclwmx 内部):
```f90
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(Nday, IdxDay, pver, tot_icld_vistau, liq_icld_vistau, ice_icld_vistau, tot_cld_vistau, cld) &
!$OMP PRIVATE(i) SCHEDULE(STATIC)
do i=1,Nday
    integer :: col_idx
    col_idx = IdxDay(i) ! 获取实际的列索引
    tot_icld_vistau(col_idx,1:pver) = liq_icld_vistau(col_idx,1:pver) + ice_icld_vistau(col_idx,1:pver)
    tot_cld_vistau(col_idx,1:pver) = (liq_icld_vistau(col_idx,1:pver) + &
                                     ice_icld_vistau(col_idx,1:pver)) * cld(col_idx,1:pver)
end do
!$OMP END PARALLEL DO
```
# radiation_tend 中其他潜在的并行化循环  
```f90
!803
! 原代码中类似这样的循环:
! do i=1,ncol
!    solin(i) = solin(i)*cgs2mks
!    fsds(i)  = fsds(i)*cgs2mks
!    ! ... many other similar assignments ...
! end do
! 可以优化为:
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(ncol, solin, fsds, ..., cgs2mks) & ! ... 列出所有相关数组和参数 ...
!$OMP PRIVATE(i) SCHEDULE(STATIC)
do i=1,ncol
   solin(i) = solin(i)*cgs2mks
   fsds(i)  = fsds(i)*cgs2mks
   ! ...
end do
!$OMP END PARALLEL DO
```
# radinp 子程序中的循环未并行化
```f90
!1083
!$OMP PARALLEL DEFAULT(NONE) &
!$OMP SHARED(pver, ncol, pmidrd, pmid, pintrd, pint, pverp) &
!$OMP PRIVATE(k,i)

  !$OMP DO COLLAPSE(2) SCHEDULE(STATIC)
  do k=1,pver
     do i=1,ncol
        pmidrd(i,k) = pmid(i,k)*10.0_r8
        pintrd(i,k) = pint(i,k)*10.0_r8
     end do
  end do
  !$OMP END DO

  !$OMP DO SCHEDULE(STATIC)
  do i=1,ncol
     pintrd(i,pverp) = pint(i,pverp)*10.0_r8
  end do
  !$OMP END DO

!$OMP END PARALLEL
```
ect...