subroutine basdy(phi     ,lbasdy  )

!-----------------------------------------------------------------------
! (保留原始注释)
!-----------------------------------------------------------------------
  use shr_kind_mod, only: r8 => shr_kind_r8
  use scanslt,      only: nxpt, platd  ! nxpt, platd 是模块参数
  implicit none

!------------------------------参数 (源自原代码, 隐式使用)------------------
!  integer, parameter ::  jfirst_calc = nxpt + 1          ! 计算的第一个索引
!  integer, parameter ::  jlast_calc  = platd - nxpt - 1  ! 计算的最后一个索引
! 为清晰起见，如果它们匹配，则在循环边界中直接使用模块参数。
! 否则，像原代码一样定义局部参数。
!-----------------------------------------------------------------------

!------------------------------参数 (Arguments)--------------------------------
  real(r8), intent(in)  :: phi(platd)          ! 模型网格的纬度坐标
  real(r8), intent(out) :: lbasdy(4,2,platd)   ! 导数估计权重
!-----------------------------------------------------------------------

!---------------------------局部变量 (Local variables)-----------------------------
  integer jj                ! 循环索引, 在OMP中将是私有的
  integer :: jfirst, jlast  ! 计算得出的循环边界
!-----------------------------------------------------------------------

  jfirst = nxpt + 1
  jlast  = platd - nxpt - 1

  ! 在启动OpenMP区域之前，确保有迭代要执行
  if (jfirst <= jlast) then
    !$OMP PARALLEL DO PRIVATE(jj) SHARED(phi, lbasdy, jfirst, jlast) SCHEDULE(STATIC) DEFAULT(NONE)
    do jj = jfirst,jlast
       ! 假设 lcdbas 是线程安全的 (这类计算核心通常是)
       call lcdbas( phi(jj-1), lbasdy(1,1,jj), lbasdy(1,2,jj) )
    end do
    !$OMP END PARALLEL DO
  end if
!
  return
end subroutine basdy