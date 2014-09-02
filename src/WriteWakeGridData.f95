SUBROUTINE WriteWakeGridData()

    ! Write wake grid data
    
    use wakedata
    use blade
    use wake
    use wallsoln 
    use configr
    
    implicit none
    
    integer :: xcount, ycount, zcount
    real :: dxgrid, dygrid, dzgrid       
    real :: vx, vy, vz, ufs_temp, vfs_temp, wfs_temp
    real :: xnode, ynode, znode
    integer :: ygcErr
 
    ! Set up grid for induced velocity output (only on first iteration)
    if (NT==1) then

        ! Compute the appropriate grid spacing
        ! (if number of grids is 1 in any direction, catch a divide-by-zero error)
        if (nxgrid==1) then
            dxgrid=0.0
        else
            dxgrid=(xgridU-xgridL)/(nxgrid-1)
        end if

        if (nygrid==1) then
            dygrid=0.0
        else
            dygrid=(ygridU-ygridL)/(nygrid-1)
        end if

        if (nzgrid==1) then
            dzgrid=0.0
        else
            dzgrid=(zgridU-zgridL)/(nzgrid-1)
        end if

        ! Set up grid node locations and initialize induced velocities
        do zcount=1,nzgrid
            do ycount=1,nygrid
                do xcount=1,nxgrid
                    ! Setup grid node locations
                    XGrid(xcount,ycount,zcount)=xgridL+(xcount-1)*dxgrid
                    YGrid(xcount,ycount,zcount)=ygridL+(ycount-1)*dygrid
                    ZGrid(xcount,ycount,zcount)=zgridL+(zcount-1)*dzgrid

                    ! Initialize induced velocities to zero
                    VXInd(xcount,ycount,zcount)=0.0
                    VYInd(xcount,ycount,zcount)=0.0
                    VZInd(xcount,ycount,zcount)=0.0

                    ! Initialize freestream velocities to zero
                    UfsGrid(xcount,ycount,zcount)=0.0
                    VfsGrid(xcount,ycount,zcount)=0.0
                    WfsGrid(xcount,ycount,zcount)=0.0
                end do
            end do
        end do
    end if ! end if (NT==1)

    ! Compute wake data on specified cartesian grid
    if (WakeGridOutFlag == 1) then
        ! Compute blade, wake, and wall induced streamwise velocity deficit
        do zcount=1,nzgrid
            do ycount=1,nygrid
                do xcount=1,nxgrid
                    ! Get the grid node location
                    xnode = XGrid(xcount,ycount,zcount)
                    ynode = YGrid(xcount,ycount,zcount)
                    znode = ZGrid(xcount,ycount,zcount)

                    ! Calculate wall and wake induced velocities at grid locations
                    Call CalcIndVel(NT,ntTerm,NBE,NB,NE,xnode,ynode,znode,vx,vy,vz)
                    VXInd(xcount,ycount,zcount)=vx
                    VYInd(xcount,ycount,zcount)=vy
                    VZInd(xcount,ycount,zcount)=vz

                    ! Calculate free stream velocities at grid locations
                    Call CalcFreestream(xnode,ynode,znode,ufs_temp,vfs_temp,wfs_temp,ygcErr)
                    UfsGrid(xcount,ycount,zcount)=ufs_temp
                    VfsGrid(xcount,ycount,zcount)=vfs_temp
                    WfsGrid(xcount,ycount,zcount)=wfs_temp
                end do
            end do
        end do

        ! Output blade, wake, and wall induced streamwise velocity deficit
        do zcount=1,nzgrid
            do ycount=1,nygrid
                do xcount=1,nxgrid
                    ! Write to file
                    write(13,'(E13.7,",",$)') TimeN                            ! Normalized simulation time (t*Uinf/Rmax)
                    write(13,'(E13.7,",",$)') XGrid(xcount,ycount,zcount) 
                    write(13,'(E13.7,",",$)') YGrid(xcount,ycount,zcount)      ! grid node locations
                    write(13,'(E13.7,",",$)') ZGrid(xcount,ycount,zcount) 
                    write(13,'(E13.7,",",$)') VXInd(xcount,ycount,zcount)
                    write(13,'(E13.7,",",$)') VYInd(xcount,ycount,zcount)      ! induced velocities
                    write(13,'(E13.7,",",$)') VZInd(xcount,ycount,zcount)
                    write(13,'(E13.7,",",$)') UfsGrid(xcount,ycount,zcount)
                    write(13,'(E13.7,",",$)') VfsGrid(xcount,ycount,zcount)    ! freestream velocities
                    write(13,'(E13.7)'      ) WfsGrid(xcount,ycount,zcount)    ! Dont suppress carriage return on last column
                end do
            end do
        end do
    end if

    Return
End SUBROUTINE WriteWakeGridData
