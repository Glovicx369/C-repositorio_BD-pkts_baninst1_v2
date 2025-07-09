DROP PACKAGE BODY BANINST1.PKG_ALERTAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_alertas AS

Function f_bimestre_dos(p_pidm IN NUMBER)Return date

    As
        l_bim2 date := null;

    Begin

    Begin
        SELECT DISTINCT
                        to_date(b.SSBSECT_PTRM_START_DATE, 'dd/mm/yyyy') fecha_inicio
        Into l_bim2
                FROM SFRSTCR a, SSBSECT b
                WHERE 1=1
              AND a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                  AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                  AND b.SSBSECT_PTRM_START_DATE =
                                (SELECT min (b1.SSBSECT_PTRM_START_DATE)
                                   FROM SSBSECT b1
                                  WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                        AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                         and a.SFRSTCR_TERM_CODE = (select min(a1.SFRSTCR_TERM_CODE)
                                                            from SFRSTCR a1
                                                            where a.SFRSTCR_PIDM = a1.SFRSTCR_PIDM
                                                                and a.SFRSTCR_PTRM_CODE = a1.SFRSTCR_PTRM_CODE)
                                        and a.SFRSTCR_PTRM_CODE in ('L2A', 'L2B', 'M2A', 'M2B')
                   and  SFRSTCR_pidm = p_pidm
                GROUP BY SSBSECT_PTRM_START_DATE,SFRSTCR_pidm,SSBSECT_TERM_CODE
                order by 1 asc;

            EXCEPTION WHEN OTHERS THEN
                  l_bim2:=null;
            END;

        return(l_bim2);

End f_bimestre_dos;


Function f_bimestre_uno(p_pidm IN NUMBER)Return date

    As
        l_bim1 date := null;

    Begin

    Begin
        SELECT DISTINCT
                        to_date(b.SSBSECT_PTRM_START_DATE, 'dd/mm/yyyy') fecha_inicio
        Into l_bim1
                FROM SFRSTCR a, SSBSECT b
                WHERE 1=1
              AND a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                  AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                  AND b.SSBSECT_PTRM_START_DATE =
                                (SELECT min (b1.SSBSECT_PTRM_START_DATE)
                                   FROM SSBSECT b1
                                  WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                        AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                         and a.SFRSTCR_TERM_CODE = (select min(a1.SFRSTCR_TERM_CODE)
                                                            from SFRSTCR a1
                                                            where a.SFRSTCR_PIDM = a1.SFRSTCR_PIDM
                                                                and a.SFRSTCR_PTRM_CODE = a1.SFRSTCR_PTRM_CODE)
                                        and SFRSTCR_PTRM_CODE in ('L1A', 'L1B', 'L1C', 'L1D', 'L1E', 'M1A', 'M1B', 'M1C')
                   and  SFRSTCR_pidm = p_pidm
                GROUP BY SSBSECT_PTRM_START_DATE,SFRSTCR_pidm,SSBSECT_TERM_CODE
                order by 1 asc;

            EXCEPTION WHEN OTHERS THEN
                  l_bim1:=null;
            END;

        return(l_bim1);

End f_bimestre_uno;


END pkg_alertas;
/

DROP PUBLIC SYNONYM PKG_ALERTAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ALERTAS FOR BANINST1.PKG_ALERTAS;
