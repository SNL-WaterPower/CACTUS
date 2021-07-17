subroutine WriteWallData()

    ! Write wall data outputs

    use fnames
    use wallgeom
    use wallsoln
    use wallsystem
    use configr

    implicit none

    integer :: i, OutIter, iw
    integer :: ip_global
    integer :: ip, i_local, j_local
    integer :: ip1, ip2, ip3, ip4
    character(80) :: filename
    character(10) :: iw_str, nt_str
    character(80) :: var_string, varlocation_string             ! string to contain variable information for TecPlot output file
    real :: vel_center(3)
    real :: TVel, dH
    real, allocatable :: TVelIFS(:,:)
    real :: dummy

    ! Setup
    if (NT==1) then

        ! Iteration on which to write (FS only, GP always last iter)
        OutIterFS=nti

        ! Initialize output counter
        OutCount=0

    end if

    if (irev == nr) then
        OutCount=OutCount+1
    end if

    ! Output ground plane source density
    if (GPFlag == 1 .or. WPFlag == 1) then

        ! write file to Tecplot Finite Element structured, cell-centered data format
        write(nt_str,'(I5.5)') nt
        filename=adjustl(trim(WallOutputPath))//path_separator//trim(FNBase)//'_WPData_'//trim(nt_str)//'.tp'
        open(17, file=filename)

        ! set header string
        if (WallOutFlag == 2) then
            var_string = 'VARIABLES=X, Y, Z, "sigma", "u", "v", "w"'
        else
            var_string = 'VARIABLES=X, Y, Z, "sigma"'
        end if

        ! write header
        write(17,*) 'TITLE="wall panel source strengths"'
        write(17,*) var_string

        ip_global=1
        do iw=1,Nwalls

            ! set the cell-centered VARLOCATION variable appropriately
            if (WallOutFlag == 2) then
                var_string = 'VARLOCATION=([4,5,6,7]=CELLCENTERED)'
            else
                var_string = 'VARLOCATION=([4]=CELLCENTERED)'
            end if

            ! write each wall as a zone, specifying cellcentered data for sigma
            write(17,'(A,I0,A,I0,A,I0,A,E13.7,A,A)') 'ZONE I=', Walls(iw)%NumWP1+1, &
                                                      ', J=', Walls(iw)%NumWP2+1, &
                                                      ', K=1, T="WP', iw, '", SOLUTIONTIME=', TimeN, ', DATAPACKING=BLOCK, ', var_string

            ! if WallOutFlag == 2 (verbose wall data), then compute and write out the velocities -- can be expensive
            if (WallOutFlag == 2) then
                !! compute the velocities at the center of each source panel on the iw'th wall
                do i=1,Walls(iw)%NumWP
                    call CalcIndVel(NT,ntTerm,NBE,NB,NE, &
                        Walls(iw)%WCPoints(i,1),Walls(iw)%WCPoints(i,2),Walls(iw)%WCPoints(i,3), &
                        Walls(iw)%vel_centers(i,1),Walls(iw)%vel_centers(i,2),Walls(iw)%vel_centers(i,3))
                end do
            end if

            ! write x of nodes
            do i=1,Walls(iw)%NumWPNodes
                write(17,'(E13.7, " ",$)') Walls(iw)%pnodes(i,1)
            end do
            write(17,*) ""

            ! write y of nodes
            do i=1,Walls(iw)%NumWPNodes
                write(17,'(E13.7, " ",$)') Walls(iw)%pnodes(i,2)
            end do
            write(17,*) ""

            ! write z of nodes
            do i=1,Walls(iw)%NumWPNodes
                write(17,'(E13.7, " ",$)') Walls(iw)%pnodes(i,3)
            end do
            write(17,*) ""

            ! write wall source strengths
            do ip=ip_global,ip_global + Walls(iw)%NumWP - 1
                write(17,'(E13.7, " ",$)') WSource(ip, 1)
            end do
            write(17,*) ""

            !! if WallOutFlag == 2 (verbose wall data), write velocities at panel centers
            if (WallOutFlag == 2) then
                ! u
                do i=1,Walls(iw)%NumWP
                    write(17,'(E13.7, " ",$)') Walls(iw)%vel_centers(i,1)
                end do
                write(17,*) ""


                ! v
                do i=1,Walls(iw)%NumWP
                    write(17,'(E13.7, " ",$)') Walls(iw)%vel_centers(i,2)
                end do
                write(17,*) ""

                ! w
                do i=1,Walls(iw)%NumWP
                    write(17,'(E13.7, " ",$)') Walls(iw)%vel_centers(i,3)
                end do
                write(17,*) ""
            end if

            ! advance the global panel index
            ip_global = ip_global+Walls(iw)%NumWP
        end do
        close(17)

        ! !! write file to Tecplot Finite Element unstructured, cell-centered data format
        ! write(nt_str,'(I0)') nt
        ! filename=trim(FNBase)//'_WPData_'//trim(nt_str)//'.tp'
        ! open(17, file=filename)

        ! !! write header
        ! write(17,*) 'TITLE="wall panel source strengths"'
        ! write(17,*) 'VARIABLES=X, Y, Z, "sigma"'

        ! ip_global=1
        ! do iw=1,Nwalls

        !     !! write each wall as a zone, specifying cellcentered data for sigma
        !     write(17,'(A,I0,A,E13.7,A,I0,A,I0,A)') 'ZONE T="WP', iw, '", SOLUTIONTIME=', TimeN, ', N=', Walls(iw)%NumWPNodes, ', E=', Walls(iw)%NumWP, ', ET=QUADRILATERAL, F=FEBLOCK, VARLOCATION=([4]=CELLCENTERED) '

        !     ! write x of nodes
        !     do i=1,Walls(iw)%NumWPNodes
        !         write(17,'(E13.7, " ",$)') Walls(iw)%pnodes(i,1)
        !     end do
        !     write(17,*) ""

        !     ! write y of nodes
        !     do i=1,Walls(iw)%NumWPNodes
        !         write(17,'(E13.7, " ",$)') Walls(iw)%pnodes(i,2)
        !     end do
        !     write(17,*) ""

        !     ! write z of nodes
        !     do i=1,Walls(iw)%NumWPNodes
        !         write(17,'(E13.7, " ",$)') Walls(iw)%pnodes(i,3)
        !     end do
        !     write(17,*) ""

        !     ! write wall source strengths
        !     do ip=ip_global,ip_global + Walls(iw)%NumWP - 1
        !         write(17,'(E13.7, " ",$)') WSource(ip, 1)
        !     end do
        !     write(17,*) ""

        !     !! write node connectivity
        !     do ip=1,Walls(iw)%NumWP
        !         ! get the local i and j
        !         call ip_local_to_ij_panel(Walls(iw),ip,i_local,j_local)

        !         ! write out the node numbers which define each quadrilateral panel
        !         ip1 = i_local   + (j_local-1)*(Walls(iw)%NumWP1+1)
        !         ip2 = i_local+1 + (j_local-1)*(Walls(iw)%NumWP1+1)
        !         ip3 = i_local+1 + (j_local  )*(Walls(iw)%NumWP1+1)
        !         ip4 = i_local   + (j_local  )*(Walls(iw)%NumWP1+1)

        !         write(17,'(I0," ",I0," ",I0," ",I0)') ip1,ip2,ip3,ip4
        !     end do

        !     ! advance the global panel index
        !     ip_global = ip_global+Walls(iw)%NumWP
        ! end do
        ! close(17)


        if (FSFlag == 1) then
            ! Output wall tangent velocity and free surface height, dH/R=1/2*FnR^2*(1-(Ux@FS/UInf)^2)

            ! Write on appropriate iter
            if (OutCount == OutIterFS) then

                ! Calc tangential velocity induced by free surface
                allocate(TVelIFS(NumFSCP,1))
                TVelIFS=matmul(FSInCoeffT,FSSource)

                ! Calc tangential velocity at each control point (already an average over last revolution)
                do i=1,NumFSCP

                    ! Get average tangential velocity on free surface
                    TVel=FSVTAve(i,1)+TVelIFS(i,1)

                    ! Calc dH (over radius)
                    dH=0.5*FnR**2*(1-TVel**2)

                    ! Write
                    write(15,'(E13.7,",",$)') FSCPPoints(i,1)
                    write(15,'(E13.7,",",$)') FSCPPoints(i,2)
                    write(15,'(E13.7,",",$)') FSCPPoints(i,3)
                    write(15,'(E13.7,",",$)') TVel
                    ! Dont suppress carriage return on last column
                    write(15,'(E13.7)') dH

                end do

            end if

        end if

    end if

    return
end subroutine WriteWallData
