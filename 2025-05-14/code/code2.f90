subroutine c_sw(grid,   u,       v,      pt,       delp,               &
                 u2,     v2,                                            &
                 uc,     vc,      ptc,    delpf,    ptk,                &
                 tiny,   iord,    jord)

! Routine for shallow water dynamics on the C-grid

! !USES:

  use tp_core
  use pft_module, only : pft2d

  implicit none

! !INPUT PARAMETERS:
  type (T_FVDYCORE_GRID), intent(in) :: grid
  integer, intent(in):: iord
  integer, intent(in):: jord

  real(r8), intent(in):: u2(grid%im,grid%jfirst-grid%ng_d:grid%jlast+grid%ng_d)
  real(r8), intent(in):: v2(grid%im,grid%jfirst-grid%ng_s:grid%jlast+grid%ng_d)

! Prognostic variables:
  real(r8), intent(in):: u(grid%im,grid%jfirst-grid%ng_d:grid%jlast+grid%ng_s)
  real(r8), intent(in):: v(grid%im,grid%jfirst-grid%ng_s:grid%jlast+grid%ng_d)
  real(r8), intent(in):: pt(grid%im,grid%jfirst-grid%ng_d:grid%jlast+grid%ng_d)
  real(r8), intent(in):: delp(grid%im,grid%jfirst:grid%jlast)
  real(r8), intent(in):: delpf(grid%im,grid%jfirst-grid%ng_d:grid%jlast+grid%ng_d)

  real(r8), intent(in):: tiny

! !INPUT/OUTPUT PARAMETERS:
  real(r8), intent(inout):: uc(grid%im,grid%jfirst-grid%ng_d:grid%jlast+grid%ng_d)
  real(r8), intent(inout):: vc(grid%im,grid%jfirst-2:grid%jlast+2 )

! !OUTPUT PARAMETERS:
  real(r8), intent(out):: ptc(grid%im,grid%jfirst:grid%jlast)
  real(r8), intent(out):: ptk(grid%im,grid%jfirst:grid%jlast)

! !DESCRIPTION:
!
!   Routine for shallow water dynamics on the C-grid
!
! !REVISION HISTORY:
!   WS   2003.11.19     Merged in CAM changes by Mirin
!   WS   2004.10.07     Added ProTeX documentation
!   WS   2005.07.01     Simplified interface by passing grid
!
!EOP
!-----------------------------------------------------------------------
!BOC


!--------------------------------------------------------------
! Local 
  real(r8) :: zt_c
  real(r8) :: dydt
  real(r8) :: dtdy5
  real(r8) :: rcap

  real(r8), pointer:: sc(:)
  real(r8), pointer:: dc(:,:)

  real(r8), pointer:: cosp(:)
  real(r8), pointer:: acosp(:)
  real(r8), pointer:: cose(:)

  real(r8), pointer:: dxdt(:)
  real(r8), pointer:: dxe(:)
  real(r8), pointer:: rdxe(:)
  real(r8), pointer:: dtdx2(:)
  real(r8), pointer:: dtdx4(:)
  real(r8), pointer:: dtxe5(:)
  real(r8), pointer:: dycp(:)
  real(r8), pointer::  cye(:)

  real(r8), pointer:: fc(:)

  real(r8), pointer:: sinlon(:)
  real(r8), pointer:: coslon(:)
  real(r8), pointer:: sinl5(:)
  real(r8), pointer:: cosl5(:)

    real(r8) :: fx(grid%im,grid%jfirst:grid%jlast)
    real(r8) :: xfx(grid%im,grid%jfirst:grid%jlast)
    real(r8) :: tm2(grid%im,grid%jfirst:grid%jlast)

    real(r8) :: va(grid%im,grid%jfirst-1:grid%jlast)

    real(r8) :: wk4(grid%im+2,grid%jfirst-grid%ng_s:grid%jlast+grid%ng_d)
    
    real(r8) :: wk1(grid%im,grid%jfirst-1:grid%jlast+1)

    real(r8) :: cry(grid%im,grid%jfirst-1:grid%jlast+1)
    real(r8) :: fy(grid%im,grid%jfirst-1:grid%jlast+1)
    
    real(r8) :: ymass(grid%im,grid%jfirst: grid%jlast+1) 
    real(r8) :: yfx(grid%im,grid%jfirst: grid%jlast+1)

    real(r8) :: crx(grid%im,grid%jfirst-grid%ng_c:grid%jlast+grid%ng_c)
    real(r8) :: vort_u(grid%im,grid%jfirst-grid%ng_d:grid%jlast+grid%ng_d)
    real(r8) :: vort(grid%im,grid%jfirst-grid%ng_s:grid%jlast+grid%ng_d)

    real(r8) :: fxjv(grid%im,grid%jfirst-1:grid%jn2g0)
    real(r8) :: p1dv(grid%im,grid%jfirst-1:grid%jn2g0)
    real(r8) :: cx1v(grid%im,grid%jfirst-1:grid%jn2g0)

    real(r8) :: qtmp(-grid%im/3:grid%im+grid%im/3)
    real(r8) :: qtmpv(-grid%im/3:grid%im+grid%im/3, grid%jfirst-1:grid%jn2g0)
    real(r8) :: slope(-grid%im/3:grid%im+grid%im/3)
    real(r8) :: al(-grid%im/3:grid%im+grid%im/3)
    real(r8) :: ar(-grid%im/3:grid%im+grid%im/3)
    real(r8) :: a6(-grid%im/3:grid%im+grid%im/3)

    real(r8) :: us, vs, un, vn
    real(r8) :: p1ke, p2ke
    real(r8) :: uanp(grid%im), uasp(grid%im), vanp(grid%im), vasp(grid%im)

    logical :: ffsl(grid%jm)
    logical :: sldv(grid%jfirst-1:grid%jn2g0)

    integer :: i, j, im2
    integer :: js1g1, js2g1, js2gc1, jn2gc, jn1g1, js2g0, js2gc, jn1gc
    integer :: im, jm, jfirst, jlast, jn2g0, ng_s, ng_c, ng_d



!
!   For convenience
!

  im     = grid%im
  jm     = grid%jm
  jfirst = grid%jfirst
  jlast  = grid%jlast

  jn2g0  = grid%jn2g0

  ng_c   = grid%ng_c
  ng_d   = grid%ng_d
  ng_s   = grid%ng_s

  rcap   = grid%rcap

  zt_c   =  grid%zt_c
  dydt   =  grid%dydt
  dtdy5  =  grid%dtdy5

  sc     => grid%sc
  dc     => grid%dc

  cosp   => grid%cosp
  acosp  => grid%acosp
  cose   => grid%cose

  dxdt   => grid%dxdt
  dxe    => grid%dxe
  rdxe   => grid%rdxe
  dtdx2  => grid%dtdx2
  dtdx4  => grid%dtdx4
  dtxe5  => grid%dtxe5
  dycp   => grid%dycp
  cye    => grid%cye
  fc     => grid%fc

  sinlon => grid%sinlon
  coslon => grid%coslon
  sinl5  => grid%sinl5
  cosl5  => grid%cosl5


! Set loop limits

    im2 = im/2

    js2g0  = max(2,jfirst)
    js2gc  = max(2,jfirst-ng_c) ! NG lats on S (starting at 2)
    jn1gc  = min(jm,jlast+ng_c) ! ng_c lats on N (ending at jm)
    js1g1  = max(1,jfirst-1)
    js2g1  = max(2,jfirst-1)
    jn1g1  = min(jm,jlast+1)
    jn2gc  = min(jm-1,jlast+ng_c)   ! NG latitudes on N (ending at jm-1)
    js2gc1 = max(2,jfirst-ng_c+1)   ! NG-1 latitudes on S (starting at 2) 

! KE at poles (串行部分，保持不变)
if ( jfirst-ng_d <= 1 ) then
   p1ke = D0_125*(u2(1, 1)**2 + v2(1, 1)**2)
endif
if ( jlast+ng_d >= jm ) then
   p2ke = D0_125*(u2(1,jm)**2 + v2(1,jm)**2)
endif
if ( jfirst /= 1 ) then
  do i=1,im
    cry(i,jfirst-1) = dtdy5*vc(i,jfirst-1)
  enddo
endif

! 计算 cry 和 ymass (第一个并行块)
#if defined(INNER_OMP)
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(dtdy5, vc, cose, cry, ymass, js2g0, jn1g1, im) &
!$OMP PRIVATE(j,i) COLLAPSE(2) SCHEDULE(STATIC)
do j=js2g0,jn1g1                     ! ymass needed on NS
  do i=1,im
       cry(i,j) = dtdy5*vc(i,j)
     ymass(i,j) = cry(i,j)*cose(j) ! cose 是 grid%cose 的指针，而 grid 是 SHARED
  enddo
enddo
!$OMP END PARALLEL DO
#else
! 串行版本 (如果 INNER_OMP 未定义)
do j=js2g0,jn1g1
  do i=1,im
       cry(i,j) = dtdy5*vc(i,j)
     ymass(i,j) = cry(i,j)*cose(j)
  enddo
enddo
#endif
! New va definition
#if defined(INNER_OMP)
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(D0_5, cry, va, js2g1, jn2g0, im) &
!$OMP PRIVATE(j,i) COLLAPSE(2) SCHEDULE(STATIC)
do j=js2g1,jn2g0                     ! va needed on S (for YCC, iv==1)
  do i=1,im
    va(i,j) = D0_5*(cry(i,j)+cry(i,j+1)) ! cry 数组在此为只读
  enddo
enddo
!$OMP END PARALLEL DO
#else
! 串行版本
do j=js2g1,jn2g0
  do i=1,im
    va(i,j) = D0_5*(cry(i,j)+cry(i,j+1))
  enddo
enddo
#endif
! SJL: Check if FFSL integer fluxes need to be computed
! SJL: Check if FFSL integer fluxes need to be computed
#if defined(INNER_OMP)
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(uc, dtdx2, cosp, zt_c, D1_0, crx, ffsl, js2gc, jn2gc, im) &
!$OMP PRIVATE(j,i) SCHEDULE(STATIC)
do j=js2gc,jn2gc                ! ffsl needed on N*sg S*sg
  ! 第一个内循环计算 crx (对于当前的j，由一个线程串行执行)
  do i=1,im
    crx(i,j) = uc(i,j)*dtdx2(j) ! dtdx2 是 grid%dtdx2 的指针
  enddo

  ffsl(j) = .false.
  if( cosp(j) < zt_c ) then ! cosp 和 zt_c 是 grid 的成员指针
    ! 第二个内循环判断 ffsl(j) (对于当前的j，由一个线程串行执行)
    do i=1,im
      if( abs(crx(i,j)) > D1_0 ) then
        ffsl(j) = .true. 
#if ( !defined UNICOSMP ) || ( !defined NEC_SX )
        exit ! 退出当前 j 对应的这个内部 i 循环
#endif
      endif
    enddo
  endif
enddo
!$OMP END PARALLEL DO
#else
! 串行版本
do j=js2gc,jn2gc
  do i=1,im
    crx(i,j) = uc(i,j)*dtdx2(j)
  enddo
  ffsl(j) = .false.
  if( cosp(j) < zt_c ) then
    do i=1,im
      if( abs(crx(i,j)) > D1_0 ) then
        ffsl(j) = .true.
#if ( !defined UNICOSMP ) || ( !defined NEC_SX )
        exit
#endif
      endif
    enddo
  endif
enddo
#endif
! 2D transport of polar filtered delp (for computing fluxes!)
! Update is done on the unfiltered delp

   call tp2c( ptk,  va(1,jfirst),  delpf(1,jfirst-ng_c),    &
              crx(1,jfirst-ng_c), cry(1,jfirst),             &
              im, jm, iord, jord, ng_c, xfx,                 &
              yfx, ffsl, rcap, acosp,                        &
              crx(1,jfirst), ymass, cosp,                    &
              0, jfirst, jlast)

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)

!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(ffsl, crx, tiny, xfx, js2g0, jn2g0, im) &
!$OMP PRIVATE(j,i) SCHEDULE(STATIC)
do j=js2g0,jn2g0
   if( ffsl(j) ) then
      do i=1,im
        xfx(i,j) = xfx(i,j)/sign(max(abs(crx(i,j)),tiny),crx(i,j))
      enddo
   endif
enddo
!$OMP END PARALLEL DO
#else
! 串行版本
do j=js2g0,jn2g0
   if( ffsl(j) ) then
      do i=1,im
        xfx(i,j) = xfx(i,j)/sign(max(abs(crx(i,j)),tiny),crx(i,j))
      enddo
   endif
enddo
#endif

! pt-advection using pre-computed mass fluxes
! use tm2 below as the storage for pt increment
! WS 99.09.20 : pt, crx need on N*ng S*ng, yfx on N

    call tp2c(tm2 ,va(1,jfirst), pt(1,jfirst-ng_c),       &
              crx(1,jfirst-ng_c), cry(1,jfirst),          &
              im, jm,  iord, jord, ng_c, fx,              &
              fy(1,jfirst), ffsl, rcap, acosp,            &
              xfx, yfx, cosp, 1, jfirst, jlast)

! use wk4, crx as work arrays
     call pft2d(ptk(1,js2g0), sc,   &
                dc, im, jn2g0-js2g0+1,  &
                wk4, crx )
     call pft2d(tm2(1,js2g0), sc,   &
                dc, im, jn2g0-js2g0+1,  &
                wk4, crx )
! 更新 ptk 和 ptc
#if defined(INNER_OMP)
!$OMP PARALLEL DO DEFAULT(NONE) &
!$OMP SHARED(delp, ptk, pt, tm2, ptc, jfirst, jlast, im) &
!$OMP PRIVATE(j,i) COLLAPSE(2) SCHEDULE(STATIC)
do j=jfirst,jlast
   do i=1,im
      ! ptk(i,j) 在右侧被读取（其循环前的旧值），然后被写入新值。
      ! 由于 COLLAPSE(2) 保证了每个 (i,j) 组合由一个线程独立处理，
      ! 即使 ptk 是共享的，对 ptk(i,j) 的读写也是安全的。
      ptk(i,j) = delp(i,j) + ptk(i,j)
      ptc(i,j) = (pt(i,j)*delp(i,j) + tm2(i,j))/ptk(i,j) ! ptc(i,j) 被写入
   enddo
enddo
!$OMP END PARALLEL DO
#else
! 串行版本 (如果 INNER_OMP 未定义)
do j=jfirst,jlast
   do i=1,im
      ptk(i,j) = delp(i,j) + ptk(i,j)
      ptc(i,j) = (pt(i,j)*delp(i,j) + tm2(i,j))/ptk(i,j)
   enddo
enddo
#endif
!------------------
! Momentum equation
!------------------

     call ycc(im, jm, fy, vc(1,jfirst-2), va(1,jfirst-1),   &
              va(1,jfirst-1), jord, 1, jfirst, jlast)

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
     do j=js2g1,jn2g0

          do i=1,im
            cx1v(i,j) = dtdx4(j)*u2(i,j)
          enddo

          sldv(j) = .false.
          if( cosp(j) < zt_c ) then
            do i=1,im
              if( abs(cx1v(i,j)) > D1_0 ) then
                sldv(j) = .true. 
#if ( !defined UNICOSMP ) || ( !defined NEC_SX )
                exit
#endif
              endif
            enddo
          endif

          p1dv(im,j) = uc(1,j)
          do i=1,im-1
            p1dv(i,j) = uc(i+1,j)
          enddo

     enddo

     call xtpv(im, sldv, fxjv, p1dv, cx1v, iord, cx1v,        &
              cosp, 0, slope, qtmpv, al, ar, a6,              &
              jfirst, jlast, js2g1, jn2g0, jm,                &
              jfirst-1, jn2g0, jfirst-1, jn2g0,               &
              jfirst-1, jn2g0, jfirst-1, jn2g0,               &
              jfirst-1, jn2g0, jfirst-1, jn2g0)

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
     do j=js2g1,jn2g0
        do i=1,im
          wk1(i,j) = dxdt(j)*fxjv(i,j) + dydt*fy(i,j)
       enddo
     enddo

     if ( jfirst == 1 ) then
          do i=1,im
            wk1(i,1) = p1ke
          enddo
     endif

     if ( jlast == jm ) then
          do i=1,im
            wk1(i,jm) = p2ke
          enddo
     endif

! crx redefined
#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
     do j=js2gc1,jn1gc
            crx(1,j) = dtxe5(j)*u(im,j)
          do i=2,im
            crx(i,j) = dtxe5(j)*u(i-1,j)
          enddo
     enddo

     if ( jfirst /=1 ) then 
          do i=1,im
             cry(i,jfirst-1) = dtdy5*v(i,jfirst-1)
          enddo
     endif

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
     do j=jfirst,jlast
        do i=1,im
             cry(i,j) = dtdy5*v(i,j)
           ymass(i,j) = cry(i,j)*cosp(j)       ! ymass actually unghosted
        enddo
     enddo

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
     do j=js2g0,jlast
          do i=1,im
            tm2(i,j) = D0_5*(cry(i,j)+cry(i,j-1)) ! cry ghosted on S 
          enddo
     enddo

!    Compute absolute vorticity on the C-grid.

     if ( jfirst-ng_d <= 1 ) then
          do i=1,im
            vort_u(i,1) = D0_0
          enddo
     endif

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
     do j=js2gc,jn2gc
         do i=1,im
            vort_u(i,j) = uc(i,j)*cosp(j)
         enddo
     enddo

     if ( jlast+ng_d >= jm ) then
          do i=1,im
            vort_u(i,jm) = D0_0
          enddo
     endif

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
     do j=js2gc1,jn1gc
! The computed absolute vorticity on C-Grid is assigned to vort
          vort(1,j) = fc(j) + (vort_u(1,j-1)-vort_u(1,j))*cye(j) +     &
                    (vc(1,j) - vc(im,j))*rdxe(j)

          do i=2,im
             vort(i,j) = fc(j) + (vort_u(i,j-1)-vort_u(i,j))*cye(j) +  &
                       (vc(i,j) - vc(i-1,j))*rdxe(j)
          enddo
     enddo

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
     do j=js2gc1,jn1gc          ! ffsl needed on N*ng S*(ng-1)
          ffsl(j) = .false.
          if( cose(j) < zt_c ) then
            do i=1,im
              if( abs(crx(i,j)) > D1_0 ) then
                ffsl(j) = .true. 
#if ( !defined UNICOSMP ) || ( !defined NEC_SX )
                exit
#endif
              endif
            enddo
          endif
     enddo

   call tpcc( tm2, ymass, vort(1,jfirst-ng_d), crx(1,jfirst-ng_c),  &
              cry(1,jfirst), im, jm, ng_c, ng_d,                  &
              iord, jord, fx, fy(1,jfirst), ffsl, cose,           &
              jfirst, jlast, slope, qtmp, al, ar, a6 )

#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
   do j=js2g0,jn2g0
         uc(1,j) = uc(1,j) + dtdx2(j)*(wk1(im,j)-wk1(1,j)) + dycp(j)*fy(1,j)
      do i=2,im
         uc(i,j) = uc(i,j) + dtdx2(j)*(wk1(i-1,j)-wk1(i,j)) + dycp(j)*fy(i,j)
      enddo
   enddo
#if defined(INNER_OMP)
!$omp parallel do default(shared) private(j,i)
#endif
   do j=js2g0,jlast
        do i=1,im-1
           vc(i,j) = vc(i,j) + dtdy5*(wk1(i,j-1)-wk1(i,j))-dxe(j)*fx(i+1,j)
        enddo
           vc(im,j) = vc(im,j) + dtdy5*(wk1(im,j-1)-wk1(im,j))-dxe(j)*fx(1,j)
   enddo
!EOC
 end subroutine c_sw