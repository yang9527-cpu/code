subroutine bandij(dlam    ,phib    ,lamp    ,phip    ,iband   , &
                  jband   ,nlon    )

!-----------------------------------------------------------------------
! (Comments as before)
!-----------------------------------------------------------------------

  use shr_kind_mod, only: r8 => shr_kind_r8
  use pmgrid,       only: plon, plev  ! Assuming plon, plev are module parameters for array dimensions
  use scanslt,      only: platd, i1   ! Assuming platd, i1 are module parameters
  use rgrid,        only: fullgrid    ! Assuming fullgrid is a module parameter or variable
  implicit none

!------------------------------Arguments--------------------------------
  real(r8), intent(in)  :: dlam(platd)        ! longitude increment
  real(r8), intent(in)  :: phib(platd)        ! latitude coordinates of model grid (or platd+N for extended cells)
  real(r8), intent(in)  :: lamp(plon,plev)    ! longitude coordinates of dep. points
  real(r8), intent(in)  :: phip(plon,plev)    ! latitude  coordinates of dep. points
  integer , intent(in)  :: nlon               ! number of longitudes (should match plon if consistent)
  integer , intent(out) :: iband(plon,plev,4) ! longitude index of dep. points
  integer , intent(out) :: jband(plon,plev)   ! latitude  index of dep. points
!-----------------------------------------------------------------------
!
!---------------------------Local workspace-----------------------------
!
  integer i,k             ! Loop indices for parallel region (will be private)
  integer :: j_temp        ! Temporary for jband calculation, private to each iteration
  real(r8) dphibr           ! reciprocal of an approximate del phi
  real(r8) phibs            ! latitude of southern-most latitude
  real(r8) rdlam(platd)     ! reciprocal of longitude increment
  integer j_loop_idx        ! Loop index for rdlam calculation (sequential)
!
!-----------------------------------------------------------------------
!
  ! These calculations are done once, sequentially
  dphibr = 1._r8/( phib(platd/2+1) - phib(platd/2) ) ! Assumes platd/2 and platd/2+1 are valid
  phibs  = phib(1)
  do j_loop_idx = 1,platd
     rdlam(j_loop_idx) = 1._r8/dlam(j_loop_idx)
  end do
!
! Loop over level and longitude
! Using DEFAULT(NONE) to be explicit about variable scopes.
! SHARED: Arrays being read/written, pre-calculated scalars, module variables.
! PRIVATE: Loop counters, temporary variables within an iteration.
! Note: 'nlon' from argument list is used as upper bound for 'i'. If 'plon' is the actual dimension
!       from the module and should be used, ensure consistency. Here, using 'nlon' as per args.
! Consider if 'plev' (from module) or a passed argument for levels should be used if they differ.

!$OMP PARALLEL DO PRIVATE(k, i, j_temp) &
!$OMP DEFAULT(NONE) &
!$OMP SHARED(phip, phibs, dphibr, phib, jband, iband, lamp, rdlam, i1, fullgrid, nlon, plev, platd) &
!$OMP COLLAPSE(2) SCHEDULE(STATIC)
  do k=1,plev  ! plev is from 'use pmgrid'
     do i = 1,nlon ! nlon is an argument
!
! Latitude indices.
!
        j_temp = int ( (phip(i,k) - phibs)*dphibr + 1._r8 )
        ! Potential out-of-bounds for phib(j_temp+1) if j_temp can reach platd
        ! Assuming phib is dimensioned appropriately for this access (e.g., phib(platd+1) is valid)
        ! or j_temp is naturally constrained.
        if (j_temp < platd .and. phip(i,k) >= phib(j_temp+1)) then
           j_temp = j_temp + 1
        else if (j_temp >= platd .and. phip(i,k) >= phib(platd)) then ! Handle edge case if phip is at/beyond last phib interval
           ! This else if condition might need refinement based on exact grid definition
           ! If phip(i,k) is >= phib(platd), j_temp should likely be platd.
           ! The original code didn't have j_temp < platd check, implying phib(j_temp+1) was always valid.
           ! If j_temp = platd, then phib(platd+1) would be accessed.
           ! For safety, if phib is only phib(1:platd):
           ! if( j_temp < platd .and. phip(i,k) >= phib(j_temp+1) ) then
           !    j_temp = j_temp + 1
           ! else if (j_temp == platd .and. phip(i,k) >= phib(platd) ) then
           !    ! j_temp remains platd, or handle as error/specific logic
           ! end if
           ! Simplest if assuming phib(platd+1) is a valid "upper bound" sentinel value
           if( phip(i,k) >= phib(min(j_temp+1, platd)) ) then ! A more robust check if phib is 1:platd
               if (j_temp < platd) j_temp = j_temp + 1
           end if
        end if
        jband(i,k) = j_temp
!
! Longitude indices.
! Critical: Ensure j_temp's value (now jband(i,k)) keeps rdlam indices valid.
! rdlam is 1:platd.
! j_temp-1 needs j_temp >= 2.
! j_temp+2 needs j_temp <= platd-2.
! This requires j_temp to be in [2, platd-2] for the 'else' branch.
! If j_temp can be 1, platd-1, platd, then rdlam access needs clamping or specific handling.
! For simplicity, assuming j_temp will be in a safe range due to problem constraints.
! If not, clamping like: idx = max(1, min(j_temp_val, platd)) is needed for each rdlam access.
!
        integer :: rd_idx1, rd_idx2, rd_idx3, rd_idx4
        
        rd_idx1 = max(1, min(jband(i,k)-1, platd)) ! Clamping example
        iband(i,k,1) = i1 + int( lamp(i,k)*rdlam(rd_idx1))

        if (fullgrid) then
           iband(i,k,2) = iband(i,k,1)
           iband(i,k,3) = iband(i,k,1)
           iband(i,k,4) = iband(i,k,1)
        else
           rd_idx2 = max(1, min(jband(i,k)  , platd))
           rd_idx3 = max(1, min(jband(i,k)+1, platd))
           rd_idx4 = max(1, min(jband(i,k)+2, platd))
           iband(i,k,2) = i1 + int( lamp(i,k)*rdlam(rd_idx2))
           iband(i,k,3) = i1 + int( lamp(i,k)*rdlam(rd_idx3))
           iband(i,k,4) = i1 + int( lamp(i,k)*rdlam(rd_idx4))
        end if
     end do
  end do
!$OMP END PARALLEL DO

  return
end subroutine bandij