      SUBROUTINE CABLE_DAILY_EXCHANGE (JDAY)
C--
C--   Run an optional external daily CABLE hook and apply its return state.
C--   If EXOSPEEDY_CABLE_HOOK is unset, the baseline model is unchanged.
C--
C--   CABLE_SURFACE_DAT contains: RadT, Albedo, Fwsoil.
C--   The first safe prototype applies RadT and Fwsoil at CABLE_JGP.
C--
      include "atparam.h"
      include "com_var_land.h"

      INTEGER JDAY, JGP, IOS, LENV, CMDSTAT, EXITSTAT
      REAL RADT_CABLE, ALBEDO_CABLE, FWSOIL_CABLE
      CHARACTER*256 HOOK, STATEFILE, ENVVAL
      CHARACTER*600 COMMAND

      HOOK = ' '
      CALL GET_ENVIRONMENT_VARIABLE ('EXOSPEEDY_CABLE_HOOK',HOOK,
     &                               LENGTH=LENV)
      IF (LENV.LE.0) RETURN

      JGP = 1385
      ENVVAL = ' '
      CALL GET_ENVIRONMENT_VARIABLE ('CABLE_JGP',ENVVAL,LENGTH=LENV)
      IF (LENV.GT.0) THEN
        READ (ENVVAL(1:LENV),*,IOSTAT=IOS) JGP
        IF (IOS.NE.0) STOP 'Invalid CABLE_JGP'
      ENDIF
      IF (JGP.LT.1.OR.JGP.GT.NGP) STOP 'CABLE_JGP out of range'

      WRITE (COMMAND,'(A,1X,I0)') TRIM(HOOK),JDAY
      CALL EXECUTE_COMMAND_LINE (TRIM(COMMAND),WAIT=.TRUE.,
     &                           EXITSTAT=EXITSTAT,CMDSTAT=CMDSTAT)
      IF (CMDSTAT.NE.0.OR.EXITSTAT.NE.0) THEN
        PRINT *, 'CABLE hook failed: ',CMDSTAT,EXITSTAT
        STOP 'Daily CABLE hook failed'
      ENDIF

      STATEFILE = 'cable_surface.dat'
      ENVVAL = ' '
      CALL GET_ENVIRONMENT_VARIABLE ('CABLE_SURFACE_DAT',ENVVAL,
     &                               LENGTH=LENV)
      IF (LENV.GT.0) STATEFILE = ENVVAL(1:LENV)

      OPEN (98,FILE=STATEFILE,STATUS='OLD',ACTION='READ',IOSTAT=IOS)
      IF (IOS.NE.0) STOP 'Cannot open CABLE surface return file'
      READ (98,*,IOSTAT=IOS) RADT_CABLE,ALBEDO_CABLE,FWSOIL_CABLE
      CLOSE (98)
      IF (IOS.NE.0) STOP 'Cannot read CABLE surface return file'
      IF (RADT_CABLE.LT.180..OR.RADT_CABLE.GT.350.)
     &  STOP 'CABLE RadT outside safe range'

      ENVVAL = ' '
      CALL GET_ENVIRONMENT_VARIABLE ('CABLE_APPLY_FEEDBACK',ENVVAL,
     &                               LENGTH=LENV)
      IF (LENV.GT.0.AND.ENVVAL(1:1).EQ.'0') THEN
        PRINT *, 'CABLE feedback disabled at JGP',JGP
        RETURN
      ENDIF

      STL_LM(JGP) = RADT_CABLE
      STL_AM(JGP) = RADT_CABLE
      SOILW_AM(JGP) = FWSOIL_CABLE

      PRINT *, 'Applied CABLE state at JGP',JGP,RADT_CABLE,
     &         FWSOIL_CABLE
      RETURN
      END
