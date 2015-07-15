 SUBROUTINE IPXETAS(IDIR, GDTNUMI, GDTLEN, GDTMPLI, NPTS_INPUT,  &
                    BITMAP_INPUT, DATA_INPUT, GDTNUMO, GDTMPLO, &
                    NPTS_OUTPUT, BITMAP_OUTPUT, DATA_OUTPUT, IRET)
!$$$  SUBPROGRAM DOCUMENTATION BLOCK
!
! SUBPROGRAM:  IPXETAS    EXPAND OR CONTRACT ETA GRIDS
!   PRGMMR: IREDELL       ORG: W/NMC23       DATE: 96-04-10
!
! ABSTRACT: THIS SUBPROGRAM TRANSFORMS BETWEEN THE STAGGERED ETA GRIDS
!           AS USED IN THE ETA MODEL AND FOR NATIVE GRID TRANSMISSION
!           AND THEIR FULL EXPANSION AS USED FOR GENERAL INTERPOLATION
!           AND GRAPHICS.  THE ETA GRIDS ARE ROTATED LATITUDE-LONGITUDE
!           GRIDS STAGGERED AS DEFINED BY THE ARAKAWA E-GRID, THAT IS
!           WITH MASS DATA POINTS ALTERNATING WITH WIND DATA POINTS.
!
! PROGRAM HISTORY LOG:
!   96-04-10  IREDELL
! 2015-07-14  GAYNO    MAKE GRIB 2 COMPLIANT.  REPLACE 4-PT
!                      INTERPOLATION WITH CALL TO IPOLATES.
!
! USAGE:    CALL IPXETAS(IDIR, GDTNUMI, GDTLEN, GDTMPLI, NPTS_INPUT,  &
!                   BITMAP_INPUT, DATA_INPUT, GDTNUMO, GDTMPLO, &
!                   NPTS_OUTPUT, BITMAP_OUTPUT, DATA_OUTPUT, IRET)
!
!   INPUT ARGUMENT LIST:
!     IDIR         - INTEGER TRANSFORM OPTION
!                   ( 0 TO EXPAND STAGGERED FIELDS TO FULL FIELDS)
!                   (-1 TO CONTRACT FULL MASS FIELDS TO STAGGERED FIELDS)
!                   (-2 TO CONTRACT FULL WIND FIELDS TO STAGGERED FIELDS)
!     GDTNUMI      - INTEGER GRID DEFINITION TEMPLATE NUMBER - INPUT GRID.
!                    CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                    NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.  MUST
!                    BE = 1 (FOR A ROTATED LAT/LON GRID.)
!     GDTLEN       - INTEGER NUMBER OF ELEMENTS OF THE GRID DEFINITION
!                    TEMPLATE ARRAY - SAME FOR INPUT AND OUTPUT GRIDS
!                    (=22) WHICH ARE BOTH ROTATED LAT/LON GRIDS. 
!                    CORRESPONDS TO THE GFLD%IGDTLEN COMPONENT
!                    OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     GDTMPLI      - INTEGER (GDTLEN) GRID DEFINITION TEMPLATE ARRAY -
!                    INPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
!                    OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     NPTS_INPUT   - INTEGER NUMBER POINTS INPUT GRID
!     BITMAP_INPUT - LOGICAL (NPTS_INPUT) INPUT GRID BITMAP
!     DATA_INPUT   - REAL (NPTS_INPUT) INPUT GRID DATA
!     NPTS_OUTPUT  - INTEGER NUMBER POINTS OUTPUT GRID. THE J-DIMENSION
!                    OF THE INPUT AND OUTPUT GRIDS ARE THE SAME. 
!                    WHEN GOING FROM A STAGGERED TO A FULL GRID THE
!                    I-DIMENSION INCREASES TO IDIM*2-1.  WHEN GOING
!                    FROM FULL TO STAGGERED THE I-DIMENSION DECREASES
!                    TO (IDIM+1)/2.
!
!   OUTPUT ARGUMENT LIST:
!     GDTNUMO       - INTEGER GRID DEFINITION TEMPLATE NUMBER - OUTPUT GRID.
!                     CORRESPONDS TO THE GFLD%IGDTNUM COMPONENT OF THE
!                     NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!                     SAME AS GDTNUMI (=1 FOR A ROTATED LAT/LON GRID).
!     GDTMPLO       - INTEGER (GDTLEN) GRID DEFINITION TEMPLATE ARRAY -
!                     OUTPUT GRID. CORRESPONDS TO THE GFLD%IGDTMPL COMPONENT
!                     OF THE NCEP G2 LIBRARY GRIDMOD DATA STRUCTURE.
!     BITMAP_OUTPUT - LOGICAL (NPTS_OUTUT) OUTPUT GRID BITMAP
!     DATA_OUTPUT   - REAL (NPTS_OUTPUT) OUTPUT GRID DATA
!     IRET          - INTEGER RETURN CODE
!                     0     SUCCESSFUL TRANSFORMATION
!                     NON-0 INVALID GRID SPECS OR PROBLEM IN IPOLATES
!
! ATTRIBUTES:
!   LANGUAGE: FORTRAN 90
!
!$$$
 IMPLICIT NONE
!
 INTEGER,         INTENT(IN   )    :: IDIR
 INTEGER,         INTENT(IN   )    :: GDTNUMI, GDTLEN
 INTEGER(KIND=4), INTENT(IN   )    :: GDTMPLI(GDTLEN)
 INTEGER,         INTENT(IN   )    :: NPTS_INPUT, NPTS_OUTPUT
 INTEGER,         INTENT(  OUT)    :: GDTNUMO
 INTEGER(KIND=4), INTENT(  OUT)    :: GDTMPLO(GDTLEN)
 INTEGER,         INTENT(  OUT)    :: IRET

 LOGICAL(KIND=1), INTENT(IN   )    :: BITMAP_INPUT(NPTS_INPUT)
 LOGICAL(KIND=1), INTENT(  OUT)    :: BITMAP_OUTPUT(NPTS_OUTPUT)

 REAL,            INTENT(IN   )    :: DATA_INPUT(NPTS_INPUT)
 REAL,            INTENT(  OUT)    :: DATA_OUTPUT(NPTS_OUTPUT)

 INTEGER                           :: SCAN_MODE, ISCALE, IP, IPOPT(20)
 INTEGER                           :: IBI(1), IBO(1), J, KM, NO

 REAL                              :: DLONS
 REAL, ALLOCATABLE                 :: OUTPUT_RLAT(:), OUTPUT_RLON(:)
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 IRET = 0
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
! ROUTINE ONLY WORKS FOR ROTATED LAT/LON GRIDS.
 IF (GDTNUMI/=1) THEN
   IRET=1
   RETURN
 ENDIF
!
 SCAN_MODE=GDTMPLI(19)
 IF((SCAN_MODE==68.OR.SCAN_MODE==72).AND.(IDIR<-2.OR.IDIR>-1))THEN
   GDTNUMO=GDTNUMI
   GDTMPLO=GDTMPLI
   GDTMPLO(19)=64
   GDTMPLO(8)=GDTMPLO(8)*2-1
   IF((GDTMPLO(8)*GDTMPLO(9))/=NPTS_OUTPUT)THEN
     IRET=3
     RETURN
   ENDIF
   ISCALE=GDTMPLO(10)*GDTMPLO(11)
   IF(ISCALE==0) ISCALE=1E6
   DLONS=FLOAT(GDTMPLO(17))/FLOAT(ISCALE)
   DLONS=DLONS*0.5
   GDTMPLO(17)=NINT(DLONS*FLOAT(ISCALE))
 ELSEIF(SCAN_MODE==64.AND.IDIR==-1)THEN  ! FULL TO H-GRID
   GDTNUMO=GDTNUMI
   GDTMPLO=GDTMPLI
   GDTMPLO(19)=68
   GDTMPLO(8)=(GDTMPLO(8)+1)/2
   IF((GDTMPLO(8)*GDTMPLO(9))/=NPTS_OUTPUT)THEN
     IRET=3
     RETURN
   ENDIF
   ISCALE=GDTMPLO(10)*GDTMPLO(11)
   IF(ISCALE==0) ISCALE=1E6
   DLONS=FLOAT(GDTMPLO(17))/FLOAT(ISCALE)
   DLONS=DLONS*2.0
   GDTMPLO(17)=NINT(DLONS*FLOAT(ISCALE))
 ELSEIF(SCAN_MODE==64.AND.IDIR==-2)THEN  ! FULL TO V-GRID
   GDTNUMO=GDTNUMI
   GDTMPLO=GDTMPLI
   GDTMPLO(19)=72
   GDTMPLO(8)=(GDTMPLO(8)+1)/2
   IF((GDTMPLO(8)*GDTMPLO(9))/=NPTS_OUTPUT)THEN
     IRET=3
     RETURN
   ENDIF
   ISCALE=GDTMPLO(10)*GDTMPLO(11)
   IF(ISCALE==0) ISCALE=1E6
   DLONS=FLOAT(GDTMPLO(17))/FLOAT(ISCALE)
   DLONS=DLONS*2.0
   GDTMPLO(17)=NINT(DLONS*FLOAT(ISCALE))
 ELSE
   IRET=2
   RETURN
 ENDIF

 KM=1
 IP=0
 IPOPT=0
 IBI=1
 IBO=0

 ALLOCATE(OUTPUT_RLAT(NPTS_OUTPUT))
 ALLOCATE(OUTPUT_RLON(NPTS_OUTPUT))

 CALL IPOLATES(IP, IPOPT, GDTNUMI, GDTMPLI, GDTLEN, &
               GDTNUMO, GDTMPLO, GDTLEN, &
               NPTS_INPUT, NPTS_OUTPUT, KM, IBI, BITMAP_INPUT, DATA_INPUT, &
               NO, OUTPUT_RLAT, OUTPUT_RLON, IBO, BITMAP_OUTPUT, DATA_OUTPUT, IRET)

 DEALLOCATE(OUTPUT_RLAT, OUTPUT_RLON)

 IF(IRET /= 0)THEN
   PRINT*,'- PROBLEM IN IPOLATES: ', IRET
   RETURN
 ENDIF

! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
! REPLACE ANY UNDEFINED POINTS ALONG THE LEFT AND RIGHT EDGES.
 DO J=1, GDTMPLO(9)
   BITMAP_OUTPUT(J*GDTMPLO(8))=BITMAP_OUTPUT(J*GDTMPLO(8)-1)
   DATA_OUTPUT(J*GDTMPLO(8))=DATA_OUTPUT(J*GDTMPLO(8)-1)
   BITMAP_OUTPUT((J-1)*GDTMPLO(8)+1)=BITMAP_OUTPUT((J-1)*GDTMPLO(8)+2)
   DATA_OUTPUT((J-1)*GDTMPLO(8)+1)=DATA_OUTPUT((J-1)*GDTMPLO(8)+2)
 ENDDO

 RETURN
! - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 END SUBROUTINE IPXETAS
