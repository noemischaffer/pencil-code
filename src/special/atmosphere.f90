! $Id: atmosphere.f90 12795 2010-01-03 14:03:57Z ajohan@strw.leidenuniv.nl $
!
!  This module incorporates all the modules used for Natalia's
!  neutron star -- disk coupling simulations (referred to as nstar)
!
!  This sample modules solves a special set of problems related
!  to computing the accretion through a thin disk onto a rigid surface
!  and the spreading of accreted material along the neutron star's surface.
!  One-dimensional problems along the disc and perpendicular to it
!  can also be considered.
!

!** AUTOMATIC CPARAM.INC GENERATION ****************************
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! CPARAM logical, parameter :: lspecial = .true.
!
! MVAR CONTRIBUTION 0
! MAUX CONTRIBUTION 0
!
!***************************************************************

!-------------------------------------------------------------------
!
! HOW TO USE THIS FILE
! --------------------
!
! The rest of this file may be used as a template for your own
! special module.  Lines which are double commented are intended
! as examples of code.  Simply fill out the prototypes for the
! features you want to use.
!
! Save the file with a meaningful name, eg. geo_kws.f90 and place
! it in the $PENCIL_HOME/src/special directory.  This path has
! been created to allow users ot optionally check their contributions
! in to the Pencil-Code CVS repository.  This may be useful if you
! are working on/using the additional physics with somebodyelse or
! may require some assistance from one of the main Pencil-Code team.
!
! To use your additional physics code edit the Makefile.local in
! the src directory under the run directory in which you wish to
! use your additional physics.  Add a line with all the module
! selections to say something like:
!
!    SPECIAL=special/chem_stream
!
! Where nstar it replaced by the filename of your new module
! upto and not including the .f90
!
!--------------------------------------------------------------------

module Special

  use Cparam
  use Cdata
  use Messages
  use Sub, only: keep_compiler_quiet
!  use Density, only: rho_up
  use EquationOfState


  implicit none

  include '../special.h'

  ! input parameters
  logical :: lbuoyancy=.true.

  character (len=labellen) :: initstream='default'
  real :: Rgas, Rgas_unit_sys=1.
  integer :: ind_water=0, ind_cloud=0
! Keep some over used pencils
!
! start parameters
  namelist /chem_stream_init_pars/  &
      lbuoyancy
         
! run parameters
  namelist /chem_stream_run_pars/  &
      lbuoyancy
!!
!! Declare any index variables necessary for main or
!!
!!   integer :: iSPECIAL_VARIABLE_INDEX=0
!
!! other variables (needs to be consistent with reset list below)
!
  integer :: idiag_dtcrad=0
  integer :: idiag_dtchi=0
!
  contains

!***********************************************************************
    subroutine register_special()
!
!  Configure pre-initialised (i.e. before parameter read) variables
!  which should be know to be able to evaluate
!
!
!  6-oct-03/tony: coded
!
      use Cdata
   !   use Density
      use EquationOfState
      use Mpicomm
!
      logical, save :: first=.true.
!
! A quick sanity check
!
      if (.not. first) call stop_it('register_special called twice')
      first = .false.

!!
!! MUST SET lspecial = .true. to enable use of special hooks in the Pencil-Code
!!   THIS IS NOW DONE IN THE HEADER ABOVE
!
!
!
!!
!! Set any required f-array indexes to the next available slot
!!
!!
!      iSPECIAL_VARIABLE_INDEX = nvar+1             ! index to access entropy
!      nvar = nvar+1
!
!      iSPECIAL_AUXILIARY_VARIABLE_INDEX = naux+1             ! index to access entropy
!      naux = naux+1
!
!
!  identify CVS/SVN version information:
!
      if (lroot) call svn_id( &
           "$Id: chem_stream.f90 12795 2010-01-03 14:03:57Z ajohan@strw.leidenuniv.nl $")
!
!
!  Perform some sanity checks (may be meaningless if certain things haven't
!  been configured in a custom module but they do no harm)
!
      if (naux > maux) then
        if (lroot) write(0,*) 'naux = ', naux, ', maux = ', maux
        call stop_it('register_special: naux > maux')
      endif
!
      if (nvar > mvar) then
        if (lroot) write(0,*) 'nvar = ', nvar, ', mvar = ', mvar
        call stop_it('register_special: nvar > mvar')
      endif
!
    endsubroutine register_special
!***********************************************************************
    subroutine initialize_special(f)
!
!  called by run.f90 after reading parameters, but before the time loop
!
!  06-oct-03/tony: coded
!
      use Cdata
   !   use Density
      use EquationOfState

      real, dimension (mx,my,mz,mvar+maux) :: f
      integer :: k
!!
!!  Initialize any module variables which are parameter dependent
!!
       if (unit_system == 'cgs') then
         Rgas_unit_sys = k_B_cgs/m_u_cgs
         Rgas=Rgas_unit_sys*unit_temperature/unit_velocity**2
       endif

        do k=1,nchemspec
         if (trim(varname(ichemspec(k)))=='CLOUD') then
          ind_cloud=k
         endif
         if (trim(varname(ichemspec(k)))=='H2O') then
          ind_water=k
         endif

        enddo

        print*,'cloud index', ind_cloud
        print*,'water index', ind_water
!
      call keep_compiler_quiet(f)
!
    endsubroutine initialize_special
!***********************************************************************
    subroutine init_special(f)
!
!  initialise special condition; called from start.f90
!  06-oct-2003/tony: coded
!
      use Cdata
   !   use Density
      use EquationOfState
      use Mpicomm
      use Sub
!
      real, dimension (mx,my,mz,mvar+maux) :: f
!
      intent(inout) :: f

!!
!      select case (initstream)
!        case ('flame_spd')
!         call flame_spd(f)
!        case ('default')
!          if (lroot) print*,'init_special: Default  setup'
!        case default
!
!  Catch unknown values
!
!          if (lroot) print*,'init_special: No such value for initstream: ', trim(initstream)
!          call stop_it("")
!      endselect
!
    endsubroutine init_special
!***********************************************************************
    subroutine pencil_criteria_special()
!
!  All pencils that this special module depends on are specified here.
!
!  18-07-06/tony: coded
!
      use Cdata
!
!
!
    endsubroutine pencil_criteria_special
!***********************************************************************
    subroutine dspecial_dt(f,df,p)
!
!  calculate right hand side of ONE OR MORE extra coupled PDEs
!  along the 'current' Pencil, i.e. f(l1:l2,m,n) where
!  m,n are global variables looped over in equ.f90
!
!  Due to the multi-step Runge Kutta timestepping used one MUST always
!  add to the present contents of the df array.  NEVER reset it to zero.
!
!  several precalculated Pencils of information are passed if for
!  efficiency.
!
!   06-oct-03/tony: coded
!
      use Cdata
      use Diagnostics
      use Mpicomm
      use Sub
   !   use Global
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz,mvar) :: df
      type (pencil_case) :: p

!
      intent(in) :: f,p
      intent(inout) :: df
!
!  identify module and boundary conditions
!
      if (headtt.or.ldebug) print*,'dspecial_dt: SOLVE dSPECIAL_dt'
!!      if (headtt) call identify_bcs('ss',iss)
!
!!
!! SAMPLE DIAGNOSTIC IMPLEMENTATION
!!
      if (ldiagnos) then
        if (idiag_dtcrad/=0) &
          call max_mn_name(sqrt(advec_crad2)/cdt,idiag_dtcrad,l_dt=.true.)
        if (idiag_dtchi/=0) &
          call max_mn_name(diffus_chi/cdtv,idiag_dtchi,l_dt=.true.)
      endif

! Keep compiler quiet by ensuring every parameter is used
      call keep_compiler_quiet(f)
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(p)

    endsubroutine dspecial_dt
!***********************************************************************
    subroutine read_special_init_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat

      if (present(iostat)) then
        read(unit,NML=chem_stream_init_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=chem_stream_init_pars,ERR=99)
      endif

99    return
    endsubroutine read_special_init_pars
!***********************************************************************
    subroutine write_special_init_pars(unit)
      integer, intent(in) :: unit

      write(unit,NML=chem_stream_init_pars)

    endsubroutine write_special_init_pars
!***********************************************************************
    subroutine read_special_run_pars(unit,iostat)
      integer, intent(in) :: unit
      integer, intent(inout), optional :: iostat

      if (present(iostat)) then
        read(unit,NML=chem_stream_run_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=chem_stream_run_pars,ERR=99)
      endif

99    return
    endsubroutine read_special_run_pars
!***********************************************************************
    subroutine write_special_run_pars(unit)
      integer, intent(in) :: unit

      write(unit,NML=chem_stream_run_pars)

    endsubroutine write_special_run_pars
!***********************************************************************
    subroutine rprint_special(lreset,lwrite)
!
!  reads and registers print parameters relevant to special
!
!   06-oct-03/tony: coded
!
      use Diagnostics
!
!  define diagnostics variable
!
      integer :: iname
      logical :: lreset,lwr
      logical, optional :: lwrite
!
      lwr = .false.
      if (present(lwrite)) lwr=lwrite

!
!  reset everything in case of reset
!  (this needs to be consistent with what is defined above!)
!
      if (lreset) then
        idiag_dtcrad=0
        idiag_dtchi=0
      endif
!
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'dtcrad',idiag_dtcrad)
        call parse_name(iname,cname(iname),cform(iname),'dtchi',idiag_dtchi)
      enddo
!
!  write column where which magnetic variable is stored
      if (lwr) then
        write(3,*) 'i_dtcrad=',idiag_dtcrad
        write(3,*) 'i_dtchi=',idiag_dtchi
      endif
!
    endsubroutine rprint_special
!***********************************************************************
    subroutine calc_lspecial_pars(f)
!
!  dummy routine
!
!  15-jan-08/axel: coded
!
      real, dimension (mx,my,mz,mfarray) :: f
      intent(inout) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine calc_lspecial_pars
!***********************************************************************
    subroutine special_calc_density(f,df,p)
!
!   06-oct-03/tony: coded
!
      use Cdata
      ! use Viscosity
      use EquationOfState

      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p
!
! Keep compiler quiet by ensuring every parameter is used
!
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(p)
!
    endsubroutine special_calc_density
!***********************************************************************
    subroutine special_calc_hydro(f,df,p)
!
!
!   16-jul-06/natalia: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p

      real :: gg=9.81e2, TT0=293, qwater0=9.9e-3
      real :: eps=0.5 !!????????????????????????
 
      if (lbuoyancy) then
        df(l1:l2,m,n,iuz)=df(l1:l2,m,n,iuz)&
             + gg*((p%TT(:)-TT0)/TT0 &
             + eps*(f(l1:l2,m,n,ichemspec(ind_water))-qwater0) &
             - f(l1:l2,m,n,ichemspec(ind_cloud)))
      endif
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(p)

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    endsubroutine special_calc_hydro
!***********************************************************************
    subroutine special_calc_magnetic(f,df,p)
!
!
!   06-oct-03/tony: coded
!
      use Cdata

      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p


! Keep compiler quiet by ensuring every parameter is used
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(p)

    endsubroutine special_calc_magnetic
!!***********************************************************************
    subroutine special_calc_entropy(f,df,p)
!
      use Cdata
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      real, dimension (mx,my,mz,mvar), intent(inout) :: df
      type (pencil_case), intent(in) :: p
      integer :: l_sz


! Keep compiler quiet by ensuring every parameter is used
      call keep_compiler_quiet(df)
      call keep_compiler_quiet(p)

    endsubroutine special_calc_entropy
!***********************************************************************
    subroutine special_boundconds(f,bc)
!
!   calculate a additional 'special' term on the right hand side of the
!   entropy equation.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   06-oct-03/tony: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
      type (boundary_condition) :: bc
!
      select case (bc%bcname)
         case ('stm')
         select case (bc%location)
         case (iBC_X_TOP)
           call bc_stream_x(f,-1, bc)
         case (iBC_X_BOT)
           call bc_stream_x(f,-1, bc)
         endselect
         bc%done=.true.
      endselect


      call keep_compiler_quiet(f)
      call keep_compiler_quiet(bc%bcname)
!
    endsubroutine special_boundconds
!***********************************************************************
!
!  PRIVATE UTITLITY ROUTINES
!
!***********************************************************************
   subroutine density_init(f)
!
      real, dimension (mx,my,mz,mvar+maux) :: f
!
    endsubroutine density_init
!***************************************************************
    subroutine entropy_init(f)
!
      real, dimension (mx,my,mz,mvar+maux) :: f
!
      endsubroutine entropy_init
!***********************************************************************
      subroutine velocity_init(f)
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
!
    endsubroutine  velocity_init
!***********************************************************************
!   INITIAL CONDITIONS
!
!**************************************************************************
!       BOUNDARY CONDITIONS
!*88888888888888888888888888888888888888888888888888888888888888888888888888
  subroutine bc_stream_x(f,sgn,bc)
!
! Natalia
!
    use Cdata
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (my, nchemspec-1) :: mask
      integer :: sgn
      type (boundary_condition) :: bc
      integer :: i,i1,j,vr,k
      real :: value1, value2

      vr=bc%ivar

      value1=bc%value1
      value2=bc%value2


    if (bc%location==iBC_X_BOT) then
      ! bottom boundary

        if (vr==4 ) then
          do i=0,nghost; f(l1-i,:,:,vr)=2*f(l1,:,:,vr)+sgn*f(l1+i,:,:,vr); enddo
       endif

      elseif (bc%location==iBC_X_TOP) then
      ! top boundary
        do i=1,nghost
        f(l2+i,:,:,vr)=f(l2,:,:,vr)!2*f(l2,:,:,vr)+sgn*f(l2-i,:,:,vr); 
        enddo
      else
        print*, "bc_BL_x: ", bc%location, " should be `top(", &
                        iBC_X_TOP,")' or `bot(",iBC_X_BOT,")'"
      endif
!
    endsubroutine bc_stream_x
!******************************************************************** 

    subroutine special_before_boundary(f)
!
!   Possibility to modify the f array before the boundaries are
!   communicated.
!
!   Some precalculated pencils of data are passed in for efficiency
!   others may be calculated directly from the f array
!
!   06-jul-06/tony: coded
!
      use Cdata
!
      real, dimension (mx,my,mz,mvar+maux), intent(in) :: f
!
      call keep_compiler_quiet(f)
!
    endsubroutine special_before_boundary
!
!********************************************************************

!************        DO NOT DELETE THE FOLLOWING       **************
!********************************************************************
!**  This is an automatically generated include file that creates  **
!**  copies dummy routines from nospecial.f90 for any Special      **
!**  routines not implemented in this file                         **
!**                                                                **
    include '../special_dummies.inc'
!********************************************************************

endmodule Special

