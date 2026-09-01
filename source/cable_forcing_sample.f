      SUBROUTINE CABLE_FORCING_SAMPLE (JSTEP)
C--
C--   Save instantaneous forcing at one ExoSPEEDY grid point as CSV.
C--   make_cable_forcing.py converts the native day to CABLE NetCDF.
C--
C--   Environment variables:
C--     CABLE_JGP          grid-point index (default 1385, nearest T30
C--                        point to Tumbarumba)
C--     CABLE_FORCING_CSV  output pathname
C--
      include "atparam.h"
      include "atparam1.h"
      include "com_tsteps.h"
      include "com_physcon.h"
      include "com_physvar.h"

      INTEGER JSTEP, JGP, IOS, LENV
      CHARACTER*256 OUTFILE, ENVVAL
      SAVE JGP, OUTFILE
      DATA JGP /1385/
      DATA OUTFILE /'cable_forcing_native.csv'/

      IF (JSTEP.EQ.1) THEN
        ENVVAL = ' '
        CALL GET_ENVIRONMENT_VARIABLE ('CABLE_JGP',ENVVAL,
     &                                 LENGTH=LENV)
        IF (LENV.GT.0) THEN
          READ (ENVVAL(1:LENV),*,IOSTAT=IOS) JGP
          IF (IOS.NE.0) STOP 'Invalid CABLE_JGP'
        ENDIF
        IF (JGP.LT.1.OR.JGP.GT.NGP) STOP 'CABLE_JGP out of range'

        ENVVAL = ' '
        CALL GET_ENVIRONMENT_VARIABLE ('CABLE_FORCING_CSV',ENVVAL,
     &                                 LENGTH=LENV)
        IF (LENV.GT.0) OUTFILE = ENVVAL(1:LENV)

        OPEN (97,FILE=OUTFILE,STATUS='REPLACE',ACTION='WRITE',
     &        IOSTAT=IOS)
        IF (IOS.NE.0) STOP 'Cannot open CABLE forcing CSV'
        WRITE (97,'(A)')
     &    'step,seconds,Tair,Qair,Wind,PSurf,SWdown,LWdown,Rainf'
      ENDIF

      WRITE (97,'(I0,A,F12.3,7(A,ES24.16))') JSTEP,',',
     &  REAL(JSTEP)*DELT,',',
     &  TG1(JGP,NLEV),',',QG1(JGP,NLEV)*0.001,',',
     &  SQRT(UG1(JGP,NLEV)**2+VG1(JGP,NLEV)**2),',',
     &  PSG(JGP)*P0,',',SSRD(JGP),',',SLRD(JGP),',',
     &  (PRECNV(JGP)+PRECLS(JGP))*0.001
      CALL FLUSH (97)

      IF (JSTEP.EQ.NSTEPS) CLOSE (97)
      RETURN
      END
