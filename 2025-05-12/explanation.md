# cice_evp_subcycling：  
优化代码，考虑使用改进的EVP方法，如mevp或aevp。改的代码389-535，gemini改的代码不能运行。  
# 尝试优化bc-physics #
找到phys_run1_adiabatic_or_ideal,热点：tphysidl
当前 tphysidl 代码结构分析：
选择机制： 通过硬编码的 idlflag = 1 来选择 Held-Suarez 原始方案。后续的 elseif 对应其他方案。  
主要计算：  
温度趋势（ptend%s）： 基于辐射平衡温度和当前温度的差值，乘以一个松弛系数。  
风场趋势（ptend%u, ptend%v）： 主要是在边界层附近（pref_mid_norm(k) > sigmab）对风场进行阻尼（Rayleigh Damping）。  
循环结构： 主要的计算循环是外层 k (垂直层次, 1 到 pver) 和内层 i (水平列, 1 到 ncol)。这种结构对于 Fortran 列主序的数组 A(i,k)（即 A(pcols, pver)）是高效的，因为内层循环访问连续的内存。  
纬度相关项： coslat(i), sinsq(i), cossq(i), cossqsq(i) 在进入主循环前已计算好。  
state%pmid 的复制：  
pmid(i,k)=state%pmid(i,k) 将状态量中的气压复制到了局部数组。如果 pmid 之后没有被修改（当前代码中看起来是这样），这层复制可能是不必要的开销，可以直接使用 state%pmid(i,k)。  
```f90
! 删除这部分循环:
! do k = 1, pver
!    do i = 1, ncol
!       pmid(i,k) = state%pmid(i,k)  ! <--- 直接使用 state%pmid(i,k)
!    end do
! end do
```
```f90
! ... (trefc_val_for_i, log_term_factor_for_i 已在外部计算) ...
do k=1,pver
   if (pref_mid_norm(k) > sigmab) then
      do i=1,ncol
         real(r8) :: kt_val, tmp_factor_s  ! 明确 tmp_factor_s
         real(r8) :: pmid_over_psref, log_pmid_ratio, trefa_intermediate, trefa_final

         kt_val = ka + (ks - ka)*cossqsq(i)*(pref_mid_norm(k) - sigmab)/onemsig

         tmp_factor_s = kt_val
         #ifdef MODHS
            tmp_factor_s = kt_val / (1._r8 + ztodt * kt_val)
         #endif

         pmid_over_psref = state%pmid(i,k) / psurf_ref
         log_pmid_ratio  = log(pmid_over_psref)

         trefa_intermediate = trefc_val_for_i(i) + log_term_factor_for_i(i) * log_pmid_ratio
         trefa_final = trefa_intermediate * (pmid_over_psref)**cappa
         trefa_final = max(t00, trefa_final)

         ptend%s(i,k) = (trefa_final - state%t(i,k)) * tmp_factor_s * cpair
      end do
   else
      real(r8) :: tmp_factor_s_else ! 这个可以移到 k 循环的 i 循环外
      tmp_factor_s_else = ka
      #ifdef MODHS
         tmp_factor_s_else = ka / (1._r8 + ztodt * ka)
      #endif
      do i=1,ncol
         real(r8) :: pmid_over_psref, log_pmid_ratio, trefa_intermediate, trefa_final

         pmid_over_psref = state%pmid(i,k) / psurf_ref
         log_pmid_ratio  = log(pmid_over_psref)

         trefa_intermediate = trefc_val_for_i(i) + log_term_factor_for_i(i) * log_pmid_ratio
         trefa_final = trefa_intermediate * (pmid_over_psref)**cappa
         trefa_final = max(t00, trefa_final)

         ptend%s(i,k) = (trefa_final - state%t(i,k)) * tmp_factor_s_else * cpair
      end do
   endif
end do
```
。。。等优化  
### 报错非常多 ###  
# bandij #  
采用openmp优化，快了一两秒，可能是波动……  
```f90
subroutine bandij(dlam    ,phib    ,lamp    ,phip    ,iband   , &
                  jband   ,nlon    )

!-----------------------------------------------------------------------
!
! Purpose:
! Calculate longitude and latitude indices that identify the
! intervals on the extended grid that contain the departure points.
! Upon entry, all dep. points should be within jintmx intervals of the
! Northern- and Southern-most model latitudes. Note: the algorithm
! relies on certain relationships of the intervals in the Gaussian grid.
!
! Method:
!  dlam    Length of increment in equally spaced longitude grid (rad.)
!  phib    Latitude values for the extended grid.
!  lamp    Longitude coordinates of the points.  It is assumed that
!                     0.0 .le. lamp(i) .lt. 2*pi .
!  phip    Latitude coordinates of the points.
!  iband   Longitude index of the points.  This index points into
!          the extended arrays, e.g.,
!                   lam(iband(i)) .le. lamp(i) .lt. lam(iband(i)+1) .
!  jband   Latitude index of the points.  This index points into
!          the extended arrays, e.g.,
!                   phib(jband(i)) .le. phip(i) .lt. phib(jband(i)+1) .
!
! Author: J. Olson
!
!-----------------------------------------------------------------------
!
! $Id$
! $Author$
!
!-----------------------------------------------------------------------

  use shr_kind_mod, only: r8 => shr_kind_r8
  use pmgrid,       only: plon, plev
  use scanslt,      only: platd, i1
  use rgrid,        only: fullgrid
  implicit none

!------------------------------Arguments--------------------------------
  real(r8), intent(in)  :: dlam(platd)        ! longitude increment
  real(r8), intent(in)  :: phib(platd)        ! latitude  coordinates of model grid
  real(r8), intent(in)  :: lamp(plon,plev)    ! longitude coordinates of dep. points
  real(r8), intent(in)  :: phip(plon,plev)    ! latitude  coordinates of dep. points
  integer , intent(in)  :: nlon               ! number of longitudes
  integer , intent(out) :: iband(plon,plev,4) ! longitude index of dep. points
  integer , intent(out) :: jband(plon,plev)   ! latitude  index of dep. points
!-----------------------------------------------------------------------
!
!---------------------------Local workspace-----------------------------
!
  integer i,j,k             ! indices
  real(r8) dphibr           ! reciprocal of an approximate del phi
  real(r8) phibs            ! latitude of southern-most latitude
  real(r8) rdlam(platd)     ! reciprocal of longitude increment
!
!-----------------------------------------------------------------------
!
  dphibr = 1._r8/( phib(platd/2+1) - phib(platd/2) )
  phibs  = phib(1)
  do j = 1,platd
     rdlam(j) = 1._r8/dlam(j)
  end do
!
! Loop over level and longitude - parallelized with OpenMP

!$OMP PARALLEL DO PRIVATE (k, i, j)
  do k=1,plev
     do i = 1,nlon
!
! Latitude indices.
!
        jband(i,k) = int ( (phip(i,k) - phibs)*dphibr + 1._r8 )
        if( phip(i,k) >= phib(jband(i,k)+1) ) then
           jband(i,k) = jband(i,k) + 1
        end if
!
! Longitude indices.
!
        iband(i,k,1) = i1 + int( lamp(i,k)*rdlam(jband(i,k)-1))
        if (fullgrid) then
           iband(i,k,2) = iband(i,k,1)
           iband(i,k,3) = iband(i,k,1)
           iband(i,k,4) = iband(i,k,1)
        else
           iband(i,k,2) = i1 + int( lamp(i,k)*rdlam(jband(i,k)  ))
           iband(i,k,3) = i1 + int( lamp(i,k)*rdlam(jband(i,k)+1))
           iband(i,k,4) = i1 + int( lamp(i,k)*rdlam(jband(i,k)+2))
        end if
     end do
  end do
!$OMP END PARALLEL DO

  return
end subroutine bandij
```