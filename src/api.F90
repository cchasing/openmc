module openmc_api

  use, intrinsic :: ISO_C_BINDING

  use constants
  use error
  use geometry,        only: find_cell
  use particle_header
  use string, only: to_str
#ifdef DAGMC
  use dagmc_header,      only: free_memory_dagmc
#endif

  implicit none
  private

contains

!===============================================================================
! OPENMC_FIND_CELL determines what cell contains a given point in space
!===============================================================================

  function openmc_find_cell(xyz, index, instance) result(err) bind(C)
    real(C_DOUBLE), intent(in)        :: xyz(3) ! Cartesian point
    integer(C_INT32_T), intent(out)   :: index
    integer(C_INT32_T), intent(out)   :: instance
    integer(C_INT) :: err

    logical :: found
    type(Particle) :: p

    call particle_initialize(p)
    p % coord(1) % xyz(:) = xyz
    p % coord(1) % uvw(:) = [ZERO, ZERO, ONE]
    call find_cell(p, found)

    index = -1
    instance = -1
    err = E_UNASSIGNED

    if (found) then
      index = p % coord(p % n_coord) % cell + 1
      instance = p % cell_instance
      err = 0
    else
      err = E_GEOMETRY
      call set_errmsg("Could not find cell at position (" // &
           trim(to_str(xyz(1))) // "," // trim(to_str(xyz(2))) // "," // &
           trim(to_str(xyz(3))) // ").")
    end if

  end function openmc_find_cell

!===============================================================================
! FREE_MEMORY deallocates and clears  all global allocatable arrays in the
! program
!===============================================================================

  subroutine free_memory() bind(C)

    use bank_header
    use cmfd_header
    use geometry_header
    use material_header
    use photon_header
    use plot_header
    use sab_header
    use settings
    use simulation_header
    use surface_header
    use tally_derivative_header
    use tally_filter_header
    use tally_header
    use trigger_header
    use volume_header

    interface
      subroutine free_memory_source() bind(C)
      end subroutine

      subroutine free_memory_mesh() bind(C)
      end subroutine free_memory_mesh
    end interface

    call free_memory_geometry()
    call free_memory_surfaces()
    call free_memory_material()
    call free_memory_plot()
    call free_memory_volume()
    call free_memory_simulation()
    call free_memory_nuclide()
    call free_memory_photon()
    call free_memory_settings()
    call free_memory_sab()
    call free_memory_source()
    call free_memory_mesh()
    call free_memory_tally()
    call free_memory_tally_filter()
    call free_memory_tally_derivative()
    call free_memory_bank()
#ifdef DAGMC
    call free_memory_dagmc()
#endif

    ! Deallocate CMFD
    call deallocate_cmfd(cmfd)

  end subroutine free_memory

end module openmc_api
