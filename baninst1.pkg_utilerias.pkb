DROP PACKAGE BODY BANINST1.PKG_UTILERIAS;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_UTILERIAS" AS
/******************************************************************************
 NAME: BANINST1.pkg_utilerias
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/04/2020      vramirlo       1. Created this package body.
******************************************************************************/
Function  f_giro_empresarial(p_pidm in number) return varchar2
as

    vl_giro_empresarial varchar2(250) := null;

    Begin
                Begin

                SELECT DISTINCT
                GORADID_ADDITIONAL_ID GIRO_EMPRESARIAL
                Into vl_giro_empresarial
                from GORADID
                where 1 = 1
                and GORADID_ADID_CODE = 'GIRE'
                and GORADID_PIDM = p_pidm;


                    Exception
                        When Others then
                            vl_giro_empresarial := ' ';
                End;

               Return (vl_giro_empresarial);

    Exception
        when Others then
         vl_giro_empresarial := ' ';
          Return (vl_giro_empresarial);
    End f_giro_empresarial;
Function  f_anti(p_pidm in number) return varchar2
as

    vl_anti varchar2(250) := null;

    Begin
                Begin

                SELECT DISTINCT
                GORADID_ADDITIONAL_ID ANTIGÜEDAD
                Into vl_anti
                from GORADID
                where 1 = 1
                and GORADID_ADID_CODE = 'ANTI'
                and GORADID_PIDM = p_pidm;

                    Exception
                        When Others then
                            vl_anti := ' ';
                End;

               Return (vl_anti);

    Exception
        when Others then
         vl_anti := ' ';
          Return (vl_anti);
    End f_anti;
Function  f_ultimo_grado_estudios(p_pidm in number) return varchar2
as

    vl_ultimo_grado_estudios varchar2(250) := null;

    Begin
                Begin

                SELECT DISTINCT
                SORDEGR_DEGC_CODE ULTIMO_GRADO_ESTUDIOS
                Into vl_ultimo_grado_estudios
                from SORDEGR
                where 1 = 1
                and SORDEGR_PIDM = p_pidm;


                    Exception
                        When Others then
                            vl_ultimo_grado_estudios := ' ';
                End;

               Return (vl_ultimo_grado_estudios);

    Exception
        when Others then
         vl_ultimo_grado_estudios := ' ';
          Return (vl_ultimo_grado_estudios);
    End f_ultimo_grado_estudios;
Function  f_nombre_institucion (p_pidm in number) return varchar2
as

    vl_nombre_institucion varchar2(250) := null;

    Begin
                Begin

                SELECT DISTINCT
                SOVSBGV_DESC NOMBRE_INSTITUCION
                Into vl_nombre_institucion
                from SORPCOL ,SOVSBGV
                where 1 = 1
                and SORPCOL_SBGI_CODE = SOVSBGV_CODE
                and SORPCOL_PIDM = p_pidm;


                    Exception
                        When Others then
                            vl_nombre_institucion := ' ';
                End;

               Return (vl_nombre_institucion);

    Exception
        when Others then
         vl_nombre_institucion := ' ';
          Return (vl_nombre_institucion);
    End f_nombre_institucion;
Function  f_dni (p_pidm in number) return varchar2
as

    vl_dni varchar2(250) := null;

    Begin
                Begin

                    SELECT DISTINCT
                    SPBPERS_SSN DNI
                    Into vl_dni
                    from SPBPERS
                    where 1 = 1
                    and SPBPERS_PIDM = p_pidm;  --246231

                    If vl_dni is null  then

                        begin
                                    SELECT DISTINCT
                                    GORADID_ADDITIONAL_ID DNI
                                    Into vl_dni
                                    from GORADID
                                    where 1 = 1
                                    and GORADID_ADID_CODE = 'IDID'
                                    and GORADID_PIDM = p_pidm; --246231

                        end;
                    end if;

                    Exception
                        When Others then
                            vl_dni := ' ';
                End;

               Return (vl_dni);

    Exception
        when Others then
         vl_dni := ' ';
          Return (vl_dni);
    End f_dni;
Function  f_correo (p_pidm in number, tipo in varchar2 ) return varchar2
as

    vl_correo varchar2(250) := null;

    Begin

                Begin
                            select distinct GOREMAL_EMAIL_ADDRESS
                                 Into vl_correo
                            from   GOREMAL gore
                            where      gore.goremal_pidm = p_pidm
                            AND gore.goremal_emal_code = tipo
                            AND gore.goremal_status_ind = 'A'
                            AND gore.GOREMAL_SURROGATE_ID = (SELECT MAX (gore1.GOREMAL_SURROGATE_ID)
                                                                                    FROM GOREMAL gore1
                                                                                    WHERE gore.goremal_pidm = gore1.goremal_pidm
                                                                                    AND gore.goremal_emal_code = gore1.goremal_emal_code
                                                                                    AND gore.goremal_status_ind =gore1.goremal_status_ind);
                Exception
                    When Others then
                        vl_correo := ' ';
                End;


               Return (vl_correo);

    Exception
        when Others then
         vl_correo := ' ';
          Return (vl_correo);
    End f_correo;



Function  f_bienvenida_obs (p_pidm in number, campus in varchar2, nivel in varchar2 ) return varchar2
as

    vl_resultado varchar2(250) := null;

    begin

                Begin
                        Select distinct SZTBNDA_OBS
                            Into vl_resultado
                        from  SZTBNDA a
                            where a.SZTBNDA_PIDM = p_pidm
                               AND  a.SZTBNDA_CAMP_CODE = campus
                               AND a.SZTBNDA_LEVL_CODE = nivel
                               AND a.SZTBNDA_STAT_IND = '1'
                               AND a.SZTBNDA_SEQ_NO =
                                      (SELECT MAX (b.SZTBNDA_SEQ_NO)
                                                         FROM SZTBNDA b
                                                        WHERE 1 = 1
                                                            AND a.sztbnda_pidm = b.sztbnda_pidm
                                                              AND a.sztbnda_levl_code = b.sztbnda_levl_code
                                                              AND a.sztbnda_camp_code = b.sztbnda_camp_code);

                Exception
                    When Others then
                      vl_resultado := ' ';
                End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := '  ';
          Return (vl_resultado);
    End f_bienvenida_obs;


Function  f_bienvenida_curso (p_pidm in number, campus in varchar2, nivel in varchar2 ) return varchar2
as

    vl_resultado varchar2(250) := null;

    begin

                Begin
                        Select distinct SZTBNDA_CRSE_SUBJ
                        Into vl_resultado
                        from  SZTBNDA a
                            where a.SZTBNDA_PIDM = p_pidm
                               AND  a.SZTBNDA_CAMP_CODE = campus
                               AND a.SZTBNDA_LEVL_CODE = nivel
                               AND a.SZTBNDA_STAT_IND = '1'
                               AND a.SZTBNDA_SEQ_NO =
                                      (SELECT MAX (b.SZTBNDA_SEQ_NO)
                                                         FROM SZTBNDA b
                                                        WHERE 1 = 1
                                                            AND a.sztbnda_pidm = b.sztbnda_pidm
                                                              AND a.sztbnda_levl_code = b.sztbnda_levl_code
                                                              AND a.sztbnda_camp_code = b.sztbnda_camp_code);
                Exception
                    When Others then
                      vl_resultado := ' ';
                End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := ' ';
          Return (vl_resultado);
    End f_bienvenida_curso;

Function  f_bienvenida_fecha (p_pidm in number, campus in varchar2, nivel in varchar2 ) return varchar2
as

    vl_resultado varchar2(250) := null;

    begin
                Begin

                        Select distinct SZTBNDA_ACTIVITY_DATE
                        Into vl_resultado
                        from  SZTBNDA a
                            where a.SZTBNDA_PIDM = p_pidm
                               AND  a.SZTBNDA_CAMP_CODE = campus
                               AND a.SZTBNDA_LEVL_CODE = nivel
                               AND a.SZTBNDA_STAT_IND = '1'
                               AND a.SZTBNDA_SEQ_NO =
                                      (SELECT MAX (b.SZTBNDA_SEQ_NO)
                                                         FROM SZTBNDA b
                                                        WHERE 1 = 1
                                                            AND a.sztbnda_pidm = b.sztbnda_pidm
                                                              AND a.sztbnda_levl_code = b.sztbnda_levl_code
                                                              AND a.sztbnda_camp_code = b.sztbnda_camp_code);
                Exception
                    When Others then
                      vl_resultado := ' ';
                End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := ' ';
          Return (vl_resultado);
    End f_bienvenida_fecha;

Function  f_canal_venta  (p_pidm in number, tipo in varchar2 ) return varchar2
As
            vl_resultado varchar2(250) := null;

    Begin

              Begin

                    Select distinct NVL (vend.saracmt_comment_text, '05')
                        Into vl_resultado
                     from SARACMT vend
                       Where vend.saracmt_pidm = p_pidm
                        AND vend.saracmt_orig_code = tipo
                        AND VEND.SARACMT_APPL_NO =(SELECT MAX (cmt.SARACMT_APPL_NO)
                                                                         FROM SARACMT cmt
                                                                        WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                              AND cmt.saracmt_orig_code =tipo)
                           AND vend.SARACMT_SEQNO IN (SELECT MAX (cmt.SARACMT_SEQNO)
                                                                            FROM SARACMT cmt
                                                                            WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                            AND cmt.saracmt_orig_code = tipo);

              Exception
                    When Others then
                      vl_resultado := '05';
              End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := '05';
          Return (vl_resultado);
    End f_canal_venta;


Function  f_canal_venta_reingreso  (p_pidm in number, tipo in varchar2 ) return varchar2
As
            vl_resultado varchar2(250) := null;

    Begin

              Begin

                    Select distinct NVL (vend.saracmt_comment_text, '05')
                        Into vl_resultado
                     from SARACMT vend
                       Where vend.saracmt_pidm = p_pidm
                        AND vend.saracmt_orig_code = tipo
                        AND vend.SARACMT_COMMENT_TEXT = '19'
                        AND VEND.SARACMT_APPL_NO =(SELECT MAX (cmt.SARACMT_APPL_NO)
                                                                         FROM SARACMT cmt
                                                                        WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                              AND cmt.saracmt_orig_code =tipo)
                           AND vend.SARACMT_SEQNO IN (SELECT MAX (cmt.SARACMT_SEQNO)
                                                                            FROM SARACMT cmt
                                                                            WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                            AND cmt.saracmt_orig_code = tipo);

              Exception
                    When Others then
                      vl_resultado := '05';
              End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := '05';
          Return (vl_resultado);
    End f_canal_venta_reingreso;


Function  f_sarappd_decision (p_pidm in number, periodo in varchar2, secuencia in number ) return varchar2
As

            vl_resultado varchar2(250) := null;

    Begin

              Begin
                        Select distinct SARAPPD_APDC_CODE
                            Into vl_resultado
                        from SARAPPD ss
                       Where sarappd_pidm = p_pidm
                       AND sarappd_term_code_entry = periodo
                       AND sarappd_appl_no = secuencia
                     --  AND ss.sarappd_user != 'MIGRA_D'
                       AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                                                 FROM SARAPPD s
                                                                WHERE ss.sarappd_pidm = s.sarappd_pidm
                                                                      AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                                                      AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                                              );
              Exception
                    When Others then
                      vl_resultado := ' ';
              End;

                Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := ' ';
          Return (vl_resultado);
    End f_sarappd_decision;


Function  f_sarappd_user_decision (p_pidm in number, periodo in varchar2, secuencia in number ) return varchar2
As

            vl_resultado varchar2(250) := null;

    Begin

              Begin
                        Select distinct sarappd_user
                            Into vl_resultado
                        from SARAPPD ss
                       Where sarappd_pidm = p_pidm
                       AND sarappd_term_code_entry = periodo
                       AND sarappd_appl_no = secuencia
                       AND ss.sarappd_user != 'MIGRA_D'
                       AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                                                 FROM SARAPPD s
                                                                WHERE ss.sarappd_pidm = s.sarappd_pidm
                                                                      AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                                                      AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                                              );
              Exception
                    When Others then
                      vl_resultado := ' ';
              End;

                Return (vl_resultado);
    Exception
        when Others then
         vl_resultado := ' ';
          Return (vl_resultado);
    End f_sarappd_user_decision;


Function  f_sarappd_fecha_decision (p_pidm in number, periodo in varchar2, secuencia in number ) return date
As

            vl_resultado date := null;

    Begin

              Begin
                        Select distinct sarappd_apdc_date
                            Into vl_resultado
                        from SARAPPD ss
                       Where sarappd_pidm = p_pidm
                       AND sarappd_term_code_entry = periodo
                       AND sarappd_appl_no = secuencia
                       AND ss.sarappd_user != 'MIGRA_D'
                       AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                                                 FROM SARAPPD s
                                                                WHERE ss.sarappd_pidm = s.sarappd_pidm
                                                                      AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                                                      AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                                              );
              Exception
                    When Others then
                      vl_resultado := '01/01/1900';
              End;

                Return (vl_resultado);
    Exception
        when Others then
         vl_resultado := '01/01/1900';
          Return (vl_resultado);
    End f_sarappd_fecha_decision;

Function  f_sarappd_periodo_matric (p_pidm in number, periodo in varchar2, secuencia in number ) return varchar2
As

            vl_resultado varchar2(250) := null;

    Begin

              Begin
                        Select distinct sarappd_term_code_entry
                            Into vl_resultado
                        from SARAPPD ss
                       Where sarappd_pidm = p_pidm
                       AND sarappd_term_code_entry = periodo
                       AND sarappd_appl_no = secuencia
                       AND ss.sarappd_user != 'MIGRA_D'
                       AND SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                                                 FROM SARAPPD s
                                                                WHERE ss.sarappd_pidm = s.sarappd_pidm
                                                                      AND ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                                                      AND ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO
                                                              );
              Exception
                    When Others then
                      vl_resultado := ' ';
              End;

                Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := ' ';
          Return (vl_resultado);
    End f_sarappd_periodo_matric;

Function   f_fecha_ini (p_pidm in number,  p_sp in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin

        select  to_CHAR (min (x.fecha_inicio),'dd/mm/rrrr')||' ' || ' Periodo  ' || x.Periodo  fecha, min (x.fecha_inicio) --, rownum
            into   vl_salida, vl_fecha
        from (
        SELECT DISTINCT
                   MIN (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                FROM SFRSTCR a, SSBSECT b
               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                     And  a.SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                     AND a.SFRSTCR_RSTS_CODE = 'RE'
                     And  b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB  not in ( 'IND00001','UTEL001','L1HP401', 'L1HB401','M1HB401','L1HB403','L1HB402','L1HB404','L1HB405')
                     AND b.SSBSECT_PTRM_START_DATE =
                            (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                               FROM SSBSECT b1
                              WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                    AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                    And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB = b1.SSBSECT_SUBJ_CODE||b1.SSBSECT_CRSE_NUMB
                                    )
               and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1,3 asc
            )  x
            where rownum = 1
            group by x.Periodo
            order by 2 asc;

    Exception
    When Others then
      vl_salida := '01/01/1900';
    End;

        return vl_salida;

Exception
When Others then
  vl_salida := '01/01/1900';
 return vl_salida;
END f_fecha_ini;


Function  f_celular (p_pidm in number, tipo in varchar2 ) return varchar2
as

    vl_numero  varchar2(250) := null;

    Begin

                Begin


                     Select   case
                                when sprtele_primary_ind = 'Y' then
                                         (sprtele_phone_area||sprtele_phone_number)
                                when sprtele_primary_ind = 'N' then
                                         (sprtele_phone_area||sprtele_phone_number)
                                when sprtele_primary_ind is null then
                                         (sprtele_phone_area||sprtele_phone_number)
                                 end as celular
                       Into vl_numero
                     from sprtele tele
                     Where  tele.sprtele_pidm = p_pidm
                     and tele.sprtele_tele_code = tipo
                     and tele.sprtele_surrogate_id = (select max (tele1.sprtele_surrogate_id)
                                                                              from sprtele tele1
                                                                              where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                              and  tele.sprtele_tele_code =  tele1.sprtele_tele_code);
                Exception
                    When Others then
                        vl_numero := ' ';
                End;


               Return (vl_numero);

    Exception
        when Others then
         vl_numero := ' ';
          Return (vl_numero);
    End f_celular;


Function   f_fecha_primera (p_pidm in number,  p_sp in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



        select   distinct to_char (min (x.fecha_inicio),'dd/mm/rrrr') --, rownum
            into   vl_salida
        from (
        SELECT DISTINCT
                   MIN (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                FROM SFRSTCR a, SSBSECT b
               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                     And  a.SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                     AND a.SFRSTCR_RSTS_CODE = 'RE'
                     And  b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB  not in ( 'IND00001','UTEL001','L1HP401', 'L1HB401','M1HB401' )
                     AND b.SSBSECT_PTRM_START_DATE =
                            (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                               FROM SSBSECT b1
                              WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                    AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                    And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB = b1.SSBSECT_SUBJ_CODE||b1.SSBSECT_CRSE_NUMB)
               and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1,3 asc
            )  x
            where rownum = 1
            group by x.Periodo
            order by 1 asc;






    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida := '01/01/1900';
 return vl_salida;
END f_fecha_primera;

--
--
    Function f_calcula_jornada(p_pidm number,
                               p_sp number,
                               p_nivel varchar2,
                               p_periodo varchar2
                               )Return varchar2
    as
        l_jornada varchar2(10);
    begin

        BEGIN


            SELECT CASE
                          WHEN p_nivel IN ('MA') AND sgrsatt_atts_code IS NULL
                          THEN
                             '1MN2'
                          WHEN p_nivel IN ('MS') AND sgrsatt_atts_code IS NULL
                          THEN
                             '1AN2'
                          WHEN p_nivel = 'LI' AND sgrsatt_atts_code IS NULL
                          THEN
                             '1LC4'
                          ELSE
                             sgrsatt_atts_code
                       END
                          tipo_jornada
            INTO l_jornada
            FROM SGRSATT b
            WHERE     1 = 1
            and REGEXP_LIKE (SGRSATT_ATTS_CODE, '^[0-9]')
            AND b.sgrsatt_pidm =p_pidm
            AND b.sgrsatt_stsp_key_sequence = p_sp
            And b.SGRSATT_TERM_CODE_EFF  = p_periodo
            AND b.sgrsatt_surrogate_id IN
                                         (SELECT MAX (b1.sgrsatt_surrogate_id)
                                          FROM sgrsatt b1
                                          WHERE 1 = 1
                                          AND b.sgrsatt_pidm = b1.sgrsatt_pidm
                                          AND b.sgrsatt_stsp_key_sequence = b1.sgrsatt_stsp_key_sequence
                                          and REGEXP_LIKE (SGRSATT_ATTS_CODE, '^[0-9]')
                                          And b.SGRSATT_TERM_CODE_EFF = b1.SGRSATT_TERM_CODE_EFF
                                          --and b.sgrsatt_atts_code = b1.sgrsatt_atts_code
                                          );
        EXCEPTION WHEN OTHERS THEN
            Begin
                SELECT CASE
                              WHEN p_nivel IN ('MA') AND sgrsatt_atts_code IS NULL
                              THEN
                                 '1MN2'
                              WHEN p_nivel IN ('MS') AND sgrsatt_atts_code IS NULL
                              THEN
                                 '1AN2'
                              WHEN p_nivel = 'LI' AND sgrsatt_atts_code IS NULL
                              THEN
                                 '1LC4'
                              ELSE
                                 sgrsatt_atts_code
                           END
                              tipo_jornada
                INTO l_jornada
                FROM SGRSATT b
                WHERE     1 = 1
                and REGEXP_LIKE (SGRSATT_ATTS_CODE, '^[0-9]')
                AND b.sgrsatt_pidm =p_pidm
                And b.SGRSATT_TERM_CODE_EFF  = p_periodo
                AND b.sgrsatt_surrogate_id IN
                                             (SELECT MAX (b1.sgrsatt_surrogate_id)
                                              FROM sgrsatt b1
                                              WHERE 1 = 1
                                              AND b.sgrsatt_pidm = b1.sgrsatt_pidm
                                              and REGEXP_LIKE (SGRSATT_ATTS_CODE, '^[0-9]')
                                              And b.SGRSATT_TERM_CODE_EFF = b1.SGRSATT_TERM_CODE_EFF
                                              --and b.sgrsatt_atts_code = b1.sgrsatt_atts_code
                                              );
               Exception When Others then
                    SELECT CASE
                                  WHEN p_nivel IN ('MA') AND sgrsatt_atts_code IS NULL
                                  THEN
                                     '1MN2'
                                  WHEN p_nivel IN ('MS') AND sgrsatt_atts_code IS NULL
                                  THEN
                                     '1AN2'
                                  WHEN p_nivel = 'LI' AND sgrsatt_atts_code IS NULL
                                  THEN
                                     '1LC4'
                                  ELSE
                                     sgrsatt_atts_code
                               END
                                  tipo_jornada
                    INTO l_jornada
                    FROM SGRSATT b
                    WHERE     1 = 1
                    and REGEXP_LIKE (SGRSATT_ATTS_CODE, '^[0-9]')
                    AND b.sgrsatt_pidm =p_pidm
                    --And b.SGRSATT_TERM_CODE_EFF  = p_periodo
                    AND b.sgrsatt_surrogate_id IN
                                                 (SELECT MAX (b1.sgrsatt_surrogate_id)
                                                  FROM sgrsatt b1
                                                  WHERE 1 = 1
                                                  AND b.sgrsatt_pidm = b1.sgrsatt_pidm
                                                  and REGEXP_LIKE (SGRSATT_ATTS_CODE, '^[0-9]')
                                                  --And b.SGRSATT_TERM_CODE_EFF = b1.SGRSATT_TERM_CODE_EFF
                                                  --and b.sgrsatt_atts_code = b1.sgrsatt_atts_code
                                                  );
               End;
        END;

        return(l_jornada);

    end;


    Function f_calcula_rate(p_pidm number,
                               p_programa varchar2
                               )Return varchar2
    as
        l_rate varchar2(10);

Begin
            Begin
                    select distinct a.sgbstdn_rate_code
                    Into l_rate
                    from sgbstdn a
                    where a.SGBSTDN_PIDM = p_pidm
                    And a.SGBSTDN_PROGRAM_1 = p_programa
                    And a.SGBSTDN_TERM_CODE_EFF = (select max ( a1.SGBSTDN_TERM_CODE_EFF)
                                                                            from SGBSTDN a1
                                                                            Where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                            And a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1);

            EXCEPTION WHEN OTHERS THEN
                  l_rate:='ERROR';
            END;

        return(l_rate);

End f_calcula_rate;


Procedure p_rolado_academico (p_term in varchar2, p_matricula in varchar2 default null) is

vl_error varchar2(250):= 'EXITO';
conta_shrttrm number;
pidm number;
periodo varchar2(6);
sb varchar2(4);
cr varchar2(5);
coll varchar2(2);
dept varchar2(4);
schd varchar2(4);
cuenta varchar2(9);
seq number;
orig_seq number;
cred decimal(7,3);
gmod varchar2(10);
prog varchar2(10);
nivel varchar2(2);
camp varchar2(3);
gchg_code varchar2(3);
conta_origen number;
conta_origen_shrttrm number;
conta_destino number;
sp integer;
tckn_crn varchar2(5);
mensaje varchar2(200);
long_course varchar2(100);
short_course varchar2(100);

conta_materia number :=0;
conta_seq number :=0;
vl_exito varchar2(250):=0;

vl_pidm number:=null; 
vl_existe number :=0;


Begin


    If p_matricula is not null then 

        Begin
            Select distinct spriden_pidm
            Into vl_pidm
            from spriden
            where spriden_id = p_matricula
            and spriden_change_ind is null;
        Exception
            When Others then 
                null;
        End;

        Begin
                update sfrstcr
                set SFRSTCR_GRDE_DATE = null
                where SFRSTCR_TERM_CODE = p_term
                And  sfrstcr_pidm = vl_pidm
                And SFRSTCR_RSTS_CODE = 'RE';
                --And  SFRSTCR_PTRM_CODE= 'L1E';
                commit;
        Exception
            When Others then
               vl_error := sqlerrm;
        End;


        Begin

                delete from shrtckl where SHRTCKL_TERM_CODE = p_term and shrtckl_pidm = vl_pidm; Commit;
                delete from shrtckg where SHRTCKG_TERM_CODE = p_term and shrtckg_pidm = vl_pidm; Commit;
                delete from shrtckn where SHRTCKN_TERM_CODE = p_term and shrtckn_pidm = vl_pidm; Commit;
                delete from SHRCHRT where SHRCHRT_TERM_CODE = p_term and SHRCHRT_pidm = vl_pidm; Commit;
                delete from SHRTTRM where SHRTTRM_TERM_CODE = p_term and SHRTTRM_pidm = vl_pidm; Commit;
                delete from shrtgpa where SHRTGPA_TERM_CODE = p_term and shrtgpa_pidm = vl_pidm; Commit;

        Exception
            When Others then
               vl_error := sqlerrm;
        End;

    ElsIf p_matricula is null then 

        Begin
                update sfrstcr
                set SFRSTCR_GRDE_DATE = null
                where SFRSTCR_TERM_CODE = p_term
                And SFRSTCR_RSTS_CODE = 'RE';
                --And  SFRSTCR_PTRM_CODE= 'L1E';
                commit;
        Exception
            When Others then
               vl_error := sqlerrm;
        End;


        Begin
                delete from shrtckl where SHRTCKL_TERM_CODE = p_term; Commit;
                delete from shrtckg where SHRTCKG_TERM_CODE = p_term; Commit;
                delete from shrtckn where SHRTCKN_TERM_CODE = p_term; Commit;
                delete from SHRCHRT where SHRCHRT_TERM_CODE = p_term; Commit;
                delete from SHRTTRM where SHRTTRM_TERM_CODE = p_term; Commit;
                delete from shrtgpa where SHRTGPA_TERM_CODE = p_term; Commit;

        Exception
            When Others then
               vl_error := sqlerrm;
        End;


    End if;



                If vl_error = 'EXITO' then


                                Begin

                                        For alumno in (


                                                    Select x.pidm,
                                                            x.campus,
                                                            x.nivel,
                                                            x.matricula,
                                                            x.SFRSTCR_CRN,
                                                            x.SFRSTCR_TERM_CODE,
                                                            x.SSBSECT_CRSE_TITLE,
                                                            x.numero,
                                                            x.sp
                                                    from (
                                                     select distinct sfrstcr_pidm pidm, 
                                                                    a.SFRSTCR_CAMP_CODE Campus, 
                                                                    a.SFRSTCR_LEVL_CODE Nivel, 
                                                                    spriden_id matricula, 
                                                                    a.SFRSTCR_CRN, 
                                                                    a.SFRSTCR_TERM_CODE, 
                                                                    SSBSECT_CRSE_TITLE,
                                                                    row_number() over(partition by a.sfrstcr_pidm, SSBSECT_CRSE_TITLE, a.SFRSTCR_STSP_KEY_SEQUENCE order by a.SFRSTCR_GRDE_CODE desc) numero, 
                                                                    a.SFRSTCR_GRDE_CODE,
                                                                    a.SFRSTCR_STSP_KEY_SEQUENCE sp
                                                     from sfrstcr a
                                                     join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('SESO1001')
                                                     join spriden on spriden_pidm = sfrstcr_pidm and spriden_change_ind is null
                                                     join shrgrde on  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE  and  SHRGRDE_CODE =SFRSTCR_GRDE_CODE and shrgrde_passed_ind = 'Y'
                                                     where   1=1
                                                     and a.SFRSTCR_GRDE_CODE is not null
                                                     And a.SFRSTCR_GRDE_DATE is null
                                                     And a.SFRSTCR_RSTS_CODE = 'RE'
                                                     And a.SFRSTCR_TERM_CODE = p_term
                                                     And a.SFRSTCR_pidm = nvl (vl_pidm, a.SFRSTCR_pidm)
                                                     --ANd a.SFRSTCR_STSP_KEY_SEQUENCE = 2
                                                     ) x
                                                     where x.numero = 1
                                                     order by 2, 3, 4,9


                                       ) loop




                                         dbms_output.put_line('Alumnos:'||alumno.pidm||'*'||alumno.Campus||'*'||alumno.nivel ||'*'||alumno.SFRSTCR_CRN||'*'||alumno.sp);


                                                   For c1 in (


                                                                 Select x.pidm pidm, 
                                                                        x.matricula matricula,  
                                                                        x.SSBSECT_SUBJ_CODE ,  
                                                                        x.SSBSECT_CRSE_NUMB, 
                                                                        x.Calificacion, 
                                                                        x.Campus, 
                                                                        x.Nivel, 
                                                                        x.SP, 
                                                                        x.parte, max (x.fecha) fecha,
                                                                        x.SFRSTCR_CRN
                                                                 from (
                                                                         select distinct
                                                                         a.sfrstcr_pidm pidm,
                                                                         c.spriden_id matricula,
                                                                         b.SSBSECT_SUBJ_CODE,
                                                                         b.SSBSECT_CRSE_NUMB,
                                                                         a.SFRSTCR_GRDE_CODE Calificacion,
                                                                         a.SFRSTCR_CAMP_CODE Campus,
                                                                         a.SFRSTCR_LEVL_CODE Nivel,
                                                                         nvl (a.SFRSTCR_STSP_KEY_SEQUENCE,1) SP,
                                                                         a.SFRSTCR_PTRM_CODE parte,
                                                                         b.SSBSECT_PTRM_START_DATE fecha,
                                                                         a.SFRSTCR_GRDE_DATE,
                                                                         a.SFRSTCR_CRN
                                                                 from sfrstcr a, ssbsect b, spriden c
                                                                 where b.ssbsect_term_code = a.sfrstcr_term_code
                                                                     and a.sfrstcr_crn = b.ssbsect_crn
                                                                     and a.sfrstcr_pidm = spriden_pidm
                                                                     and c.spriden_change_ind is null
                                                                     and a.SFRSTCR_GRDE_CODE is not null
                                                                     and a.SFRSTCR_GRDE_DATE is null
                                                                     And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                     and c.spriden_pidm = alumno.pidm
                                                                     and a.SFRSTCR_CAMP_CODE = alumno.campus
                                                                     and a.SFRSTCR_LEVL_CODE = alumno.nivel
                                                                     And a.SFRSTCR_CRN = alumno.SFRSTCR_CRN
                                                                     And a.SFRSTCR_STSP_KEY_SEQUENCE = alumno.sp 
                                                                    and TO_NUMBER (decode (a.SFRSTCR_GRDE_CODE,  'AC',1,'NA',1,'NP',1
                                                                          ,'10',10,'10.0',10,'100',10
                                                                          ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                                          ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                                          ,'6.0',6,'6',6,'60',6,'6.1',6,'61',6,'6.2',6,'62',6,'6.3',6,'63',6,'6.4',6,'64',6,'6.5',6,'65',6,'6.6',6,'66',6,'6.7',6,'67',6,'6.8',6,'68',6,'6.9',6,'69',6
                                                                          ,'7.0',7,'7',7,'70',7,'7.1',7,'71',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'76',7,'7.7',7,'77',7,'7.8',7,'78',7,'7.9',7,'79',7
                                                                          ,'8.0',8,'8',8,'80',8,'8.1',8,'81',8,'8.2',8,'82',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                                          ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9 
                                                                          )) =
                                                                            (select max (TO_NUMBER (decode (xx1.SFRSTCR_GRDE_CODE,  'AC',1,'NA',1,'NP',1
                                                                          ,'10',10,'10.0',10,'100',10
                                                                          ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                                          ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                                          ,'6.0',6,'6',6,'60',6,'6.1',6,'61',6,'6.2',6,'62',6,'6.3',6,'63',6,'6.4',6,'64',6,'6.5',6,'65',6,'6.6',6,'66',6,'6.7',6,'67',6,'6.8',6,'68',6,'6.9',6,'69',6
                                                                          ,'7.0',7,'7',7,'70',7,'7.1',7,'71',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'76',7,'7.7',7,'77',7,'7.8',7,'78',7,'7.9',7,'79',7
                                                                          ,'8.0',8,'8',8,'80',8,'8.1',8,'81',8,'8.2',8,'82',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                                          ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9 
                                                                         )))
                                                                                                        from SFRSTCR xx1, ssbsect xx2
                                                                                                         where 1=1
                                                                                                         And  xx1.SFRSTCR_TERM_CODE = xx2.SSBSECT_TERM_CODE
                                                                                                        And xx1.SFRSTCR_CRN = xx2.SSBSECT_CRN
                                                                                                         And xx1.SFRSTCR_PIDM = a.sfrstcr_pidm
                                                                                                        And xx2.SSBSECT_SUBJ_CODE||xx2.SSBSECT_CRSE_NUMB  = b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB
                                                                                                          )
                                                                     order by 1, 2,3, 4
                                                                     ) x
                                                                     group by x.pidm , x.matricula ,  
                                                                              x.SSBSECT_SUBJ_CODE ,  
                                                                              x.SSBSECT_CRSE_NUMB, 
                                                                              x.Calificacion, 
                                                                              x.Campus, 
                                                                              x.Nivel, 
                                                                              x.SP, 
                                                                              x.parte,
                                                                              x.SFRSTCR_CRN
                                                                     order by 1, 2, 3, 4,10




                                                 ) loop
                                                                   dbms_output.put_line('MAteria:'||c1.matricula||'*'||c1.SSBSECT_SUBJ_CODE||'*'||c1.SSBSECT_CRSE_NUMB||'*'||c1.Calificacion||'*'|| c1.SFRSTCR_CRN||'*'|| c1.sp);

                                                                   
                                                                   conta_materia :=0;
                                                                   conta_seq :=0;
                                                                   vl_exito := null;
                                                                   coll:= null;
                                                                   dept:= null;
                                                                   cred:= null;
                                                                   schd:= null;
                                                                   long_course:= null;
                                                                   short_course:= null;

                                                                 For c in (

                                                                            Select x.pidm, 
                                                                                   x.matricula, 
                                                                                   x.periodo,
                                                                                   x.id_materia,
                                                                                   x.SSBSECT_SUBJ_CODE,
                                                                                   x.SSBSECT_CRSE_NUMB,
                                                                                   x.crn,
                                                                                   x.grupo,
                                                                                   x.calificacion,
                                                                                   x.fecha_rolado,
                                                                                   x.campus,
                                                                                   x.nivel,
                                                                                   x.fecha,
                                                                                   x.sp,
                                                                                   x.numero,
                                                                                   x.parte
                                                                            from (
                                                                             select distinct a.sfrstcr_pidm pidm,
                                                                             c.spriden_id matricula,
                                                                             a.sfrstcr_term_code periodo,
                                                                             b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB id_materia,
                                                                             b.SSBSECT_SUBJ_CODE,
                                                                             b.SSBSECT_CRSE_NUMB,
                                                                             a.sfrstcr_crn crn,
                                                                             b.SSBSECT_SEQ_NUMB grupo,
                                                                             a.SFRSTCR_GRDE_CODE Calificacion,
                                                                             a.SFRSTCR_GRDE_DATE fecha_rolado,
                                                                             a.SFRSTCR_CAMP_CODE Campus,
                                                                             a.SFRSTCR_LEVL_CODE Nivel,
                                                                             b.SSBSECT_PTRM_START_DATE fecha,
                                                                             a.SFRSTCR_STSP_KEY_SEQUENCE SP,
                                                                             row_number() over(partition by a.sfrstcr_pidm, a.sfrstcr_term_code, a.SFRSTCR_STSP_KEY_SEQUENCE order by a.sfrstcr_pidm) numero,
                                                                             a.SFRSTCR_PTRM_CODE parte
                                                                             from sfrstcr a, ssbsect b, spriden c
                                                                             where b.ssbsect_term_code = a.sfrstcr_term_code
                                                                             and a.sfrstcr_crn = b.ssbsect_crn
                                                                             and a.SFRSTCR_CAMP_CODE = c1.campus
                                                                             and a.SFRSTCR_LEVL_CODE = c1.nivel
                                                                             and a.sfrstcr_pidm = spriden_pidm
                                                                             and c.spriden_change_ind is null
                                                                             and a.SFRSTCR_GRDE_CODE is not null
                                                                             and a.SFRSTCR_GRDE_DATE is null
                                                                             And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                              and c.spriden_pidm = c1.pidm
                                                                              And a.SFRSTCR_CRN = c1.SFRSTCR_CRN
                                                                              and b.SSBSECT_SUBJ_CODE = c1.SSBSECT_SUBJ_CODE
                                                                              and b.SSBSECT_CRSE_NUMB = c1.SSBSECT_CRSE_NUMB
                                                                              and  a.SFRSTCR_GRDE_CODE = c1.calificacion
                                                                              and trunc (b.SSBSECT_PTRM_START_DATE)  =  trunc (c1.fecha)
                                                                              ) x
                                                                             order by 1, 2,3, 15


                                                                ) loop

                                                                            conta_shrttrm :=0;
                                                                            conta_materia :=0;
                                                                            conta_seq :=0;
                                                                            vl_exito := null;
                                                                            coll:= null;
                                                                            dept:= null;
                                                                            cred:= null;
                                                                            schd:= null;
                                                                            long_course:= null;
                                                                            short_course:= null;
                                                                        
                                                            dbms_output.put_line('Secuencia:'||c.matricula||'*'||c.periodo||'*'||c.id_materia||'*'||c.Calificacion||'*'||c.numero||'*'||c.crn||'*'||c.sp);

                                                                             Begin
                                                                                     select count(*)
                                                                                     into conta_shrttrm
                                                                                     from shrttrm
                                                                                     where shrttrm_pidm=c.pidm
                                                                                     and shrttrm_term_code=c.periodo;
                                                                             Exception
                                                                             when Others then
                                                                                     conta_shrttrm :=0;
                                                                             End;

                                                                             if conta_shrttrm = 0 then
                                                                                 conta_origen_shrttrm:=conta_origen_shrttrm+1;
                                                                             --dbms_output.put_line('periodo:'||periodo);
                                                                                 begin
                                                                                             insert into shrttrm ( shrttrm_pidm, shrttrm_term_code, shrttrm_update_source_ind, shrttrm_pre_catalog_ind, shrttrm_record_status_ind, shrttrm_record_status_date,
                                                                                                                          shrttrm_activity_date, shrttrm_user_id, shrttrm_data_origin)
                                                                                             values(c.pidm, c.periodo,'S', 'N', 'G', c.fecha, c.fecha, user, 'CARG_HHH');

                                                                                            --  dbms_output.put_line('Inserta en shrttrm ');
                                                                                              vl_exito := 'Exito';
                                                                                    exception
                                                                                     when DUP_VAL_ON_INDEX then
                                                                                     dbms_output.put_line('Error duplicidad shrttrm '||sqlerrm);
                                                                                     vl_exito := sqlerrm;
                                                                                     when others then
                                                                                      dbms_output.put_line('Error Othrs shrttrm '||sqlerrm);
                                                                                      vl_exito := sqlerrm;
                                                                                 end;


                                                                                 Begin
                                                                                            Insert into SHRCHRT values (c.pidm, c.periodo, c.periodo, null, null, sysdate, null, null, user, 'MASIVO', null);
                                                                                                                          --    dbms_output.put_line('Inserta en SHRCHRT ');
                                                                                              vl_exito := 'Exito';
                                                                                    exception
                                                                                     when DUP_VAL_ON_INDEX then
                                                                                     dbms_output.put_line('Error duplicidad SHRCHRT '||sqlerrm);
                                                                                     vl_exito := 'Exito';
                                                                                     when others then
                                                                                      dbms_output.put_line('Error Othrs SHRCHRT '||sqlerrm);
                                                                                      vl_exito := sqlerrm||'*'||c.periodo;
                                                                                 end;

                                                                             end if;

                                                                             begin
                                                                                     select distinct scbcrse_coll_code, scbcrse_dept_code, scbcrse_credit_hr_low , scrschd_schd_code , scrsyln_long_course_title, SCBCRSE_TITLE
                                                                                            into coll,dept, cred , schd , long_course, short_course
                                                                                     from scbcrse , scrschd, scrsyln
                                                                                     where scbcrse_subj_code= c.SSBSECT_SUBJ_CODE
                                                                                     and scbcrse_crse_numb= c.SSBSECT_CRSE_NUMB
                                                                                     and scbcrse_eff_term='000000'
                                                                                     and scrschd_subj_code=scbcrse_subj_code
                                                                                     and scrschd_crse_numb=scbcrse_crse_numb
                                                                                     and scrsyln_subj_code=scbcrse_subj_code
                                                                                     and scrsyln_crse_numb=scbcrse_crse_numb;
                                                                             Exception when others then
                                                                                      dbms_output.put_line(' Materia NO cargada en SCBCRSE');
                                                                                     cuenta:=c.matricula;
                                                                             end;


                                                                             Begin
                                                                                     select nvl (max (shrtckn_seq_no), 0) +1
                                                                                     into conta_materia
                                                                                     from shrtckn
                                                                                     where shrtckn_pidm = c.pidm
                                                                                     And shrtckn_term_code = c.periodo;
                                                                             Exception
                                                                                when Others then
                                                                                 conta_materia :=1;
                                                                             End;


                                                                             begin
                                                                                     insert into shrtckn ( shrtckn_pidm, shrtckn_term_code, shrtckn_seq_no, shrtckn_crn, shrtckn_subj_code, shrtckn_crse_numb,
                                                                                                                 shrtckn_coll_code, shrtckn_camp_code, shrtckn_dept_code, shrtckn_crse_title,
                                                                                                                 shrtckn_course_comment, shrtckn_activity_date, shrtckn_seq_numb, shrtckn_schd_code,
                                                                                                                 shrtckn_user_id, shrtckn_data_origin,shrtckn_stsp_key_sequence,shrtckn_long_course_title, shrtckn_ptrm_code)
                                                                                                                 values (c.pidm, c.periodo, conta_materia, c.crn, c.SSBSECT_SUBJ_CODE, c.SSBSECT_CRSE_NUMB,
                                                                                                                 coll, c.campus, dept, short_course,
                                                                                                                 null, sysdate, conta_materia, schd,
                                                                                                                 user, 'CARG_HHH',c.sp, long_course,c.parte);

                                                                                     vl_exito :='Exito';
                                                                                   --  dbms_output.put_line('Inserta en shrtckn ' ||vl_exito);

                                                                             exception
                                                                                 when DUP_VAL_ON_INDEX then
                                                                                 vl_exito := 'Exito';
                                                                                 dbms_output.put_line('Error duplicidad shrtckn '||sqlerrm);
                                                                                 when others then
                                                                                 dbms_output.put_line('Error gemeral shrtckn '||sqlerrm);
                                                                                 vl_exito := sqlerrm;
                                                                             end;

                                                                            If vl_exito = 'Exito' then

                                                                                     begin
                                                                                     select scrgmod_gmod_code
                                                                                             into gmod
                                                                                     from scrgmod
                                                                                     where scrgmod_subj_code=c.ssbsect_subj_code
                                                                                     and scrgmod_crse_numb=c.ssbsect_crse_numb
                                                                                     And SCRGMOD_DEFAULT_IND ='D';
                                                                                     exception
                                                                                        when others then
                                                                                        gmod:=null;
                                                                                     end;

                                                                                    gchg_code:='OE';

                                                                                     Begin
                                                                                     select nvl (max (shrtckg_seq_no), 0) +1
                                                                                           Into conta_seq
                                                                                     from shrtckg
                                                                                     Where shrtckg_pidm = c.pidm
                                                                                     And shrtckg_term_code = c.periodo
                                                                                     And shrtckg_tckn_seq_no = conta_materia;
                                                                                      Exception
                                                                                     when Others then
                                                                                      conta_seq:=1;
                                                                                     End;



                                                                                     begin

                                                                                         insert into shrtckg(shrtckg_pidm,
                                                                                                                 shrtckg_term_code,
                                                                                                                 shrtckg_tckn_seq_no,
                                                                                                                 shrtckg_seq_no,
                                                                                                                 shrtckg_grde_code_final,
                                                                                                                 shrtckg_gmod_code,
                                                                                                                 shrtckg_credit_hours,
                                                                                                                 shrtckg_activity_date,
                                                                                                                 shrtckg_data_origin,
                                                                                                                 shrtckg_user_id,
                                                                                                                 shrtckg_gchg_code,
                                                                                                                 shrtckg_final_grde_chg_date,
                                                                                                                 shrtckg_final_grde_chg_user,
                                                                                                                 shrtckg_gcmt_code,
                                                                                                                 shrtckg_term_code_grade,
                                                                                                                 SHRTCKG_HOURS_ATTEMPTED)
                                                                                                     values(c.pidm, c.periodo, conta_materia, conta_seq, c.calificacion, gmod, cred, sysdate, 'CARG_HHH', sysdate,gchg_code, c.fecha, user,'INTMOO', c.periodo,cred );
                                                                                                     vl_exito := 'Exito';

                                                                                                 --    dbms_output.put_line('LLEGA A CKG ');
                                                                                     Exception
                                                                                        when DUP_VAL_ON_INDEX then
                                                                                            vl_exito := 'Exito';
                                                                                            dbms_output.put_line('Error DUP  SHRTCKG '||vl_exito);
                                                                                        When Others then
                                                                                            vl_exito := sqlerrm;
                                                                                            dbms_output.put_line('Error  SHRTCKG '||vl_exito);
                                                                                     End;



                                                                                If vl_exito = 'Exito' then

                                                                                         begin
                                                                                                 insert into shrtckl(shrtckl_pidm, shrtckl_term_code, shrtckl_tckn_seq_no, shrtckl_levl_code, shrtckl_activity_date, shrtckl_user_id, shrtckl_data_origin, shrtckl_primary_levl_ind)
                                                                                                 values( c.pidm, c.periodo, conta_materia, c.nivel, c.fecha, user, 'CARG_HHH','Y');
                                                                                                  vl_exito := 'Exito';
                                                                                                 --  dbms_output.put_line('LLEGA A CKL ');
                                                                                         exception
                                                                                         when DUP_VAL_ON_INDEX then
                                                                                             vl_exito := 'Exito';
                                                                                             dbms_output.put_line('Error DUP  shrtckl '||vl_exito);
                                                                                         when others then
                                                                                            vl_exito := sqlerrm;
                                                                                            dbms_output.put_line('Error  shrtckl '||vl_exito);
                                                                                         end;

                                                                                    If vl_exito = 'Exito' then
                                                                                         Begin
                                                                                             Update SFRSTCR
                                                                                             set SFRSTCR_GRDE_DATE = sysdate
                                                                                             where SFRSTCR_TERM_CODE = c.periodo
                                                                                             And SFRSTCR_PIDM = c.pidm
                                                                                             And SFRSTCR_CRN = c.crn
                                                                                             And SFRSTCR_STSP_KEY_SEQUENCE = c.sp ;
                                                                                            --  dbms_output.put_line('UPDATE A SFRSTCR ');
                                                                                         Exception
                                                                                         when Others then
                                                                                          vl_exito := sqlerrm;
                                                                                            dbms_output.put_line('Error  Update SFRSTCR '||vl_exito);
                                                                                         End;

                                                                                    End if;

                                                                                End if;

                                                                            End if;

                                                                            Commit;

                                                                End loop c;




                                                 End loop c1;

                                       
                                     End loop alumno;

                                Exception
                                    When Others then 
                                        null;
                                End;

                                Begin 
                                    
--                                    Begin 
--                                        EXECUTE IMMEDIATE 'ALTER TRIGGER SATURN.ST_SFRSTCR_POST_UPDATE_ROW DISABLE';
--                                    Exception
--                                        When Others then 
--                                            null;
--                                    End;
                                
                                        For cx in (    
                                                        Select x.pidm,
                                                            x.campus,
                                                            x.nivel,
                                                            x.matricula,
                                                            x.SFRSTCR_CRN,
                                                            x.SFRSTCR_TERM_CODE,
                                                            x.SSBSECT_CRSE_TITLE,
                                                            x.numero,
                                                            x.sp,
                                                            x.Materia,
                                                            x.Calificacion
                                                    from (
                                                     select distinct a.sfrstcr_pidm pidm, 
                                                                    a.SFRSTCR_CAMP_CODE Campus, 
                                                                    a.SFRSTCR_LEVL_CODE Nivel, 
                                                                    spriden_id matricula, 
                                                                    a.SFRSTCR_CRN, 
                                                                    a.SFRSTCR_TERM_CODE, 
                                                                    SSBSECT_CRSE_TITLE,
                                                                    row_number() over(partition by a.sfrstcr_pidm, SSBSECT_CRSE_TITLE, a.SFRSTCR_STSP_KEY_SEQUENCE order by a.SFRSTCR_GRDE_CODE desc) numero, 
                                                                    a.SFRSTCR_GRDE_CODE Calificacion,
                                                                    a.SFRSTCR_STSP_KEY_SEQUENCE sp,
                                                                    SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB Materia
                                                     from sfrstcr a
                                                     join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('SESO1001')
                                                     join spriden on spriden_pidm = sfrstcr_pidm and spriden_change_ind is null
                                                     join shrgrde on  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE  and  SHRGRDE_CODE =SFRSTCR_GRDE_CODE and shrgrde_passed_ind = 'Y'
                                                     where   1=1
                                                     and a.SFRSTCR_GRDE_CODE is not null
                                                     And a.SFRSTCR_GRDE_DATE is null
                                                     And a.SFRSTCR_RSTS_CODE = 'RE'
                                                     And a.SFRSTCR_TERM_CODE = p_term
                                                     And a.SFRSTCR_pidm = nvl (vl_pidm, a.SFRSTCR_pidm)
                                                    -- ANd a.SFRSTCR_STSP_KEY_SEQUENCE = 2
                                                     ) x
                                                     where x.numero = 1
                                                     order by 2, 3, 4,9
                                                     
                                        ) loop
                                        
                                        
                                            vl_existe:=0;
                                            Begin 
                                                select count(*)
                                                    Into vl_existe
                                                from shrtckn
                                                join shrtckg on shrtckg_pidm = SHRTCKN_PIDM and SHRTCKG_TCKN_SEQ_NO = SHRTCKN_SEQ_NO and SHRTCKG_TERM_CODE = SHRTCKN_TERM_CODE
                                                where SHRTCKN_PIDM =  cx.pidm 
                                                And SHRTCKN_STSP_KEY_SEQUENCE = cx.sp
                                                and SHRTCKN_SUBJ_CODE ||SHRTCKN_CRSE_NUMB = cx.materia   
                                                ANd SHRTCKG_GRDE_CODE_FINAL = cx.calificacion;
                                            Exception
                                                When Others then 
                                                vl_existe:=0;
                                            End;
                                            
                                            If vl_existe >= 1 then 
                                            
                                                Begin 
                                                    Update sfrstcr
                                                    set SFRSTCR_GRDE_CODE = null,
                                                        SFRSTCR_RSTS_CODE ='DD',
                                                        SFRSTCR_USER_ID = 'ROLADO_AUTO'
                                                    Where 1=1
                                                    and sfrstcr_pidm = cx.pidm
                                                    And SFRSTCR_TERM_CODE = cx.SFRSTCR_TERM_CODE
                                                    And SFRSTCR_CRN = cx.SFRSTCR_CRN
                                                    And SFRSTCR_STSP_KEY_SEQUENCE = cx.sp;
                                                Exception
                                                    When Others then 
                                                        null;
                                                End;
                                                
                                            
                                            End if;
                                        
                                        
                                        
                                        End Loop;
                                    Commit;  
                                    
--                                    Begin 
--                                        EXECUTE IMMEDIATE 'ALTER TRIGGER SATURN.ST_SFRSTCR_POST_UPDATE_ROW ENABLED';
--                                    Exception
--                                        When Others then 
--                                            null;
--                                    End;  
                                        
                                End;                                   


                                 Begin

                                        insert into shrtgpa
                                        select shrttrm_pidm, shrttrm_term_code, sgbstdn_levl_code, 'I', null,null, 0,0,0,0,0,sysdate,0,null,null,user,null,null
                                        from shrttrm, sgbstdn a
                                        where shrttrm_pidm=sgbstdn_pidm
                                        And sgbstdn_pidm = nvl (vl_pidm,sgbstdn_pidm) 
                                        and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                                                                          where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                                                          and    b.sgbstdn_term_code_eff <= shrttrm_term_code)
                                        and     shrttrm_term_code= p_term;
                                        commit;

                                 Exception
                                    When Others then
                                        null;
                                 End;






                    Commit;   
                End if;
           

End p_rolado_academico;

Function  f_paquete_venta  (p_pidm in number, tipo in varchar2 ) return varchar2
As
            vl_resultado varchar2(250) := null;

    Begin

              Begin

                    Select distinct vend.saracmt_comment_text
                        Into vl_resultado
                     from SARACMT vend
                       Where vend.saracmt_pidm = p_pidm
                        AND vend.saracmt_orig_code = tipo
                        AND VEND.SARACMT_APPL_NO =(SELECT MAX (cmt.SARACMT_APPL_NO)
                                                                         FROM SARACMT cmt
                                                                        WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                              AND cmt.saracmt_orig_code =tipo)
                           AND vend.SARACMT_SEQNO IN (SELECT MAX (cmt.SARACMT_SEQNO)
                                                                            FROM SARACMT cmt
                                                                            WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                            And  vend.SARACMT_APPL_NO= cmt.SARACMT_APPL_NO
                                                                            AND cmt.saracmt_orig_code = tipo);

              Exception
                    When Others then
                      vl_resultado := null;
              End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := '05';
          Return (vl_resultado);
    End f_paquete_venta;


Function  f_edad (p_pidm in number) return varchar2
as

    vl_edad varchar2(250) := null;

    Begin

                Begin

                            select distinct
                                nvl(trunc(months_between(SYSDATE, SPBPERS_BIRTH_DATE) / 12), 0) as Edad
                                Into vl_edad
                            from SPBPERS
                            where 1 = 1
                                and SPBPERS_PIDM = p_pidm;

                Exception
                    When Others then
                        vl_edad := ' ';
                End;


               Return (vl_edad);

    Exception
        when Others then
         vl_edad := ' ';
          Return (vl_edad);
    End f_edad;


Function  f_lugar_nacimiento (p_pidm in number) return varchar2
as

    vl_lugar_nacimiento varchar2(250) := null;

    Begin

                Begin

                    select
                        STVSTAT_DESC||', '|| STVNATN_NATION Lugar_nacimiento
                        Into vl_lugar_nacimiento
                    from SPRADDR, STVNATN, STVSTAT
                    where 1 = 1
                        and SPRADDR_NATN_CODE = STVNATN_CODE
                        and SPRADDR_STAT_CODE = STVSTAT_CODE
                        and SPRADDR_ATYP_CODE = 'NA'
                        and SPRADDR_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_lugar_nacimiento := ' ';
                End;


               Return (vl_lugar_nacimiento);

    Exception
        when Others then
         vl_lugar_nacimiento := ' ';
          Return (vl_lugar_nacimiento);
    End f_lugar_nacimiento;


Function  f_ocupacion (p_pidm in number) return varchar2
as

    vl_ocupacion varchar2(250) := null;

    Begin

                Begin


                    select distinct
                        GORADID_ADDITIONAL_ID ocupacion
                        Into vl_ocupacion
                    from GORADID
                    where 1 = 1
                        and GORADID_ADID_CODE = 'TPUE'
                        and GORADID_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_ocupacion := ' ';
                End;


               Return (vl_ocupacion);

    Exception
        when Others then
         vl_ocupacion := ' ';
          Return (vl_ocupacion);
    End f_ocupacion;


Function  f_esc_procedencia (p_pidm in number) return varchar2
as

    vl_esc_procedencia varchar2(250) := null;

    Begin

                Begin


                    select distinct
                        STVSBGI_DESC procedencia
                        Into vl_esc_procedencia
                    from SORHSCH, STVSBGI
                    where 1 = 1
                        and SORHSCH_SBGI_CODE = STVSBGI_CODE
                        and SORHSCH_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_esc_procedencia := ' ';
                End;


               Return (vl_esc_procedencia);

    Exception
        when Others then
         vl_esc_procedencia := ' ';
          Return (vl_esc_procedencia);
    End f_esc_procedencia;

Function  f_CP (p_pidm in number) return varchar2

as

   vl_CP varchar2(250) := null;

    Begin

                Begin

                    select
                             a.SPRADDR_ZIP
                        Into vl_CP
                    from SPRADDR a
                    where 1 = 1
                    And a.SPRADDR_SURROGATE_ID = (select max (a1.SPRADDR_SURROGATE_ID)
                                                                            from SPRADDR a1
                                                                            Where a.SPRADDR_pidm = a1.SPRADDR_pidm
                                                                        )
                        and SPRADDR_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_CP := ' ';
                End;


               Return (vl_CP);

    Exception
        when Others then
         vl_CP := ' ';
          Return (vl_CP);


     End f_CP;


Function  f_Salario_Mensual (p_pidm in number) return varchar2
as

    vl_ocupacion varchar2(250) := null;

    Begin

                Begin


                  select distinct   a.GORADID_ADDITIONAL_ID ocupacion
                        Into vl_ocupacion
                    from GORADID a
                    where 1 = 1
                        and a.GORADID_ADID_CODE = 'SALM'
                        And a.GORADID_SURROGATE_ID = (select max (a1.GORADID_SURROGATE_ID)
                                                                                from GORADID a1
                                                                                Where a.GORADID_PIDM = a1.GORADID_PIDM
                                                                                And a.GORADID_ADID_CODE = a1.GORADID_ADID_CODE
                                                                                )
                        and a.GORADID_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_ocupacion := ' ';
                End;


               Return (vl_ocupacion);

    Exception
        when Others then
         vl_ocupacion := ' ';
          Return (vl_ocupacion);
    End f_Salario_Mensual;

Function  f_tipo_puesto (p_pidm in number) return varchar2
as

    vl_ocupacion varchar2(250) := null;

    Begin

                Begin


                    select distinct
                        GORADID_ADDITIONAL_ID ocupacion
                        Into vl_ocupacion
                    from GORADID
                    where 1 = 1
                        and GORADID_ADID_CODE = 'TPUE'
                        and GORADID_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_ocupacion := ' ';
                End;


               Return (vl_ocupacion);

    Exception
        when Others then
         vl_ocupacion := ' ';
          Return (vl_ocupacion);
    End f_tipo_puesto;


Function  f_nombre_empresa (p_pidm in number) return varchar2
as

    vl_ocupacion varchar2(250) := null;

    Begin

                Begin


                    select distinct
                        GORADID_ADDITIONAL_ID ocupacion
                        Into vl_ocupacion
                    from GORADID
                    where 1 = 1
                        and GORADID_ADID_CODE = 'NEMP'
                        and GORADID_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_ocupacion := ' ';
                End;


               Return (vl_ocupacion);

    Exception
        when Others then
         vl_ocupacion := ' ';
          Return (vl_ocupacion);
    End f_nombre_empresa;

    Function  f_tipo_etiqueta (p_pidm in number, p_tipo in varchar2) return varchar2
as

    vl_ocupacion varchar2(250) := null;

    Begin

                Begin


                    select distinct
                        GORADID_ADID_CODE ocupacion
                        Into vl_ocupacion
                    from GORADID
                    where 1 = 1
                        and GORADID_ADID_CODE = p_tipo
                        and GORADID_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_ocupacion := ' ';
                End;


               Return (vl_ocupacion);

    Exception
        when Others then
         vl_ocupacion := ' ';
          Return (vl_ocupacion);
    End f_tipo_etiqueta;


Function  f_nacionalidad (p_pidm in number) return varchar2
as

    vl_nacionalidad varchar2(250) := null;

    Begin

                Begin

                            select distinct
                                case
                                    when SPBPERS_CITZ_CODE = 'EX' then 'EXTRANJERO'
                                    when SPBPERS_CITZ_CODE = 'ME' then 'MEXICANA'
                                    when SPBPERS_CITZ_CODE = 'ER' then 'EXTRANJERO RESIDENTE'
                                    when SPBPERS_CITZ_CODE = 'EN' then 'EXTRANJERO NO RESIDENTE'
                                    else null
                                end as Nacionalidad
                                Into vl_nacionalidad
                            from SPBPERS
                            where 1 = 1
                                and SPBPERS_PIDM = p_pidm;

                Exception
                    When Others then
                        vl_nacionalidad := ' ';
                End;

               Return (vl_nacionalidad);

    Exception
        when Others then
         vl_nacionalidad := ' ';
          Return (vl_nacionalidad);
    End f_nacionalidad;


Function   f_fecha_primera_sin_estatus (p_pidm in number,  p_sp in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



        select   distinct to_char (min (x.fecha_inicio),'dd/mm/rrrr') --, rownum
            into   vl_salida
        from (
        SELECT DISTINCT
                   MIN (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                FROM SFRSTCR a, SSBSECT b
               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                     And  a.SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                      and substr (a.SFRSTCR_TERM_CODE, 5,1) not in ( '8','9')
                   --  AND a.SFRSTCR_RSTS_CODE = 'DD'
                     And  b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB  not in ( 'IND00001','UTEL001','L1HP401', 'L1HB401','M1HB401' )
                     AND b.SSBSECT_PTRM_START_DATE =
                            (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                               FROM SSBSECT b1
                              WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                    AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                    And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB = b1.SSBSECT_SUBJ_CODE||b1.SSBSECT_CRSE_NUMB)
               and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1,3 asc
            )  x
            where rownum = 1
            group by x.Periodo
            order by 1 asc;


    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida := null;
 return vl_salida;
END f_fecha_primera_sin_estatus;

--

Function   f_fecha_primera_baja (p_pidm in number,  p_sp in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



        select   distinct to_char (min (x.fecha_inicio),'dd/mm/rrrr') --, rownum
            into   vl_salida
        from (
        SELECT DISTINCT
                   MIN (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                FROM SFRSTCR a, SSBSECT b
               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                     And  a.SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                      and substr (a.SFRSTCR_TERM_CODE, 5,1) not in ( '8','9')
                     AND a.SFRSTCR_RSTS_CODE = 'DD'
                     And  b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB  not in ( 'IND00001','UTEL001','L1HP401', 'L1HB401','M1HB401' )
                     AND b.SSBSECT_PTRM_START_DATE =
                            (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                               FROM SSBSECT b1
                              WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                    AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                    And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB = b1.SSBSECT_SUBJ_CODE||b1.SSBSECT_CRSE_NUMB)
               and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1,3 asc
            )  x
            where rownum = 1
            group by x.Periodo
            order by 1 asc;


    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida := null;
 return vl_salida;
END f_fecha_primera_baja;
--

Procedure p_actualiza_correo
is


Begin

            For c in (

                        select count(*), GOREMAL_PIDM
                        from goremal
                        where 1=1
                    --    And goremal_pidm = 293715
                        And GOREMAL_EMAL_CODE = 'PRIN'
                        And GOREMAL_STATUS_IND ='A'
                        group by GOREMAL_PIDM
                        having count(*) > 1

            ) loop

                        Begin
                                    Update  goremal a
                                    set GOREMAL_STATUS_IND ='I',
                                         GOREMAL_PREFERRED_IND = 'N'
                                    where 1= 1
                                    And a.GOREMAL_EMAL_CODE = 'PRIN'
                                    --And a.GOREMAL_PREFERRED_IND = 'Y'
                                    And a.GOREMAL_STATUS_IND ='A'
                                    And a.GOREMAL_PIDM = c.GOREMAL_PIDM
                                    And trunc (a.GOREMAL_ACTIVITY_DATE)  = (select min (trunc (a1.GOREMAL_ACTIVITY_DATE))
                                                                                                    from goremal a1
                                                                                                    Where a.GOREMAL_PIDM = a1.GOREMAL_PIDM
                                                                                                    And a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE
                                                                                                 --   And a.GOREMAL_PREFERRED_IND = a1.GOREMAL_PREFERRED_IND
                                                                                                    And a.GOREMAL_STATUS_IND = a1.GOREMAL_STATUS_IND);
                       Exception
                        When Others then
                            null;
                       End;

            End Loop;
            Commit;

    End p_actualiza_correo;


    Function f_direccion (p_pidm in number) return varchar2 is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



            select distinct ' Direccion = ' || SPRADDR_STREET_LINE1 ||SPRADDR_STREET_LINE2||SPRADDR_STREET_LINE3  ||
                    ' Ciudad ='  ||   SPRADDR_CITY||' Pais = ' || STVNATN_NATION ||' Estado = ' || STVSTAT_DESC||' CP = 'SPRADDR_ZIP
            Into vl_salida
            from SPRADDR a
            left join stvnatn on   STVNATN_CODE= SPRADDR_NATN_CODE
            left join stvstat on   STVSTAT_CODE= SPRADDR_STAT_CODE
            Where a.SPRADDR_PIDM =  p_pidm
            And a.SPRADDR_ATYP_CODE ='RE'
            And a.SPRADDR_SEQNO = (select max (a1.SPRADDR_SEQNO)
                                                    from SPRADDR a1
                                                    Where a.SPRADDR_PIDM = a1.SPRADDR_PIDM
                                                    And a.SPRADDR_ATYP_CODE = a1.SPRADDR_ATYP_CODE);






    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida :=null;
 return vl_salida;
END f_direccion;

--
--
Function f_documento (p_pidm in number, p_programa in varchar2) return varchar2  is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


BEGIN

            Begin

                        select SARCHKL_RECEIVE_DATE ||'*'|| SARCHKL_CKST_CODE Documento
                        into vl_salida
                        from SARCHKL
                        join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_programa
                                                                                               and SARADAP_APPL_NO = SARCHKL_APPL_NO
                        join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
                        where SARCHKL_PIDM = p_pidm
                        And SARCHKL_ADMR_CODE ='TECD';

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_documento;

--
Function f_programa (p_programa in varchar2) return varchar2  is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


BEGIN

            Begin

                    select distinct decode (SZTDTEC_MOD_TYPE,'OL', 'OnLine', 'S', 'Semipresencial') tipo
                      Into vl_salida
                    from SZTDTEC
                    where SZTDTEC_PROGRAM =  p_programa;

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_programa;

Function f_genero (p_pidm in number) return varchar2  is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


BEGIN

            Begin

                    select distinct  decode (SPBPERS_SEX, 'F', 'Femenino', 'M', 'Masculino', null, 'No Definido') Sexo
                           Into vl_salida
                    from SPBPERS
                    where  SPBPERS_pidm = p_pidm;


            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_genero;


Function f_NSS (p_pidm in number) return varchar2  is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


BEGIN

            Begin

                    select distinct   (SPBPERS_SSN) Sexo
                           Into vl_salida
                    from SPBPERS
                    where  SPBPERS_pidm = p_pidm;


            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_NSS;


Function  f_etiqueta (p_pidm in number, p_etiqueta in varchar2) return varchar2
as

    vl_etiqueta varchar2(250) := null;

    Begin

                Begin


                    select distinct
                        GORADID_ADDITIONAL_ID etiqueta
                        Into vl_etiqueta
                    from GORADID
                    where 1 = 1
                        and GORADID_ADID_CODE = upper(p_etiqueta)
                        and GORADID_PIDM = p_pidm;


                Exception
                    When Others then
                        vl_etiqueta := null;
                End;


               Return (vl_etiqueta);

    Exception
        when Others then
         vl_etiqueta := null;
          Return (vl_etiqueta);
    End f_etiqueta;

Function  f_fecha_nac (p_pidm in number) return varchar2
as

    vl_edad varchar2(250) := null;

    Begin

                Begin

                            select distinct
                                SPBPERS_BIRTH_DATE
                                Into vl_edad
                            from SPBPERS
                            where 1 = 1
                                and SPBPERS_PIDM = p_pidm;

                Exception
                    When Others then
                        vl_edad := '01/01/1900';
                End;


               Return (vl_edad);

    Exception
        when Others then
         vl_edad := '01/01/1900';
          Return (vl_edad);
    End f_fecha_nac;


    Function f_calle (p_pidm in number) return varchar2 is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



            select distinct SPRADDR_STREET_LINE1 ||SPRADDR_STREET_LINE2||SPRADDR_STREET_LINE3 calle
            Into vl_salida
            from SPRADDR a
            left join stvnatn on   STVNATN_CODE= SPRADDR_NATN_CODE
            left join stvstat on   STVSTAT_CODE= SPRADDR_STAT_CODE
            Where a.SPRADDR_PIDM =  p_pidm
            And a.SPRADDR_ATYP_CODE ='RE'
            And a.SPRADDR_SEQNO = (select max (a1.SPRADDR_SEQNO)
                                                    from SPRADDR a1
                                                    Where a.SPRADDR_PIDM = a1.SPRADDR_PIDM
                                                    And a.SPRADDR_ATYP_CODE = a1.SPRADDR_ATYP_CODE);






    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida :=null;
 return vl_salida;
END f_calle;


Function f_colonia (p_pidm in number) return varchar2 is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



            select distinct  SPRADDR_CITY
            Into vl_salida
            from SPRADDR a
            left join stvnatn on   STVNATN_CODE= SPRADDR_NATN_CODE
            left join stvstat on   STVSTAT_CODE= SPRADDR_STAT_CODE
            Where a.SPRADDR_PIDM =  p_pidm
            And a.SPRADDR_ATYP_CODE ='RE'
            And a.SPRADDR_SEQNO = (select max (a1.SPRADDR_SEQNO)
                                                    from SPRADDR a1
                                                    Where a.SPRADDR_PIDM = a1.SPRADDR_PIDM
                                                    And a.SPRADDR_ATYP_CODE = a1.SPRADDR_ATYP_CODE);






    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida :=null;
 return vl_salida;
END f_colonia;


Function f_municipio (p_pidm in number) return varchar2 is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



            select distinct  STVCNTY_DESC
            Into vl_salida
            from SPRADDR a
            left join stvnatn on   STVNATN_CODE= SPRADDR_NATN_CODE
            left join stvstat on   STVSTAT_CODE= SPRADDR_STAT_CODE
            join STVCNTY on STVCNTY_CODE =  a.SPRADDR_CNTY_CODE
            Where a.SPRADDR_PIDM =  p_pidm
            And a.SPRADDR_ATYP_CODE ='RE'
            And a.SPRADDR_SEQNO = (select max (a1.SPRADDR_SEQNO)
                                                    from SPRADDR a1
                                                    Where a.SPRADDR_PIDM = a1.SPRADDR_PIDM
                                                    And a.SPRADDR_ATYP_CODE = a1.SPRADDR_ATYP_CODE);






    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida :=null;
 return vl_salida;
END f_municipio;

Function f_estado (p_pidm in number) return varchar2 is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



            select distinct  STVSTAT_DESC
            Into vl_salida
            from SPRADDR a
            left join stvstat on   STVSTAT_CODE= SPRADDR_STAT_CODE
            Where a.SPRADDR_PIDM =  p_pidm
            And a.SPRADDR_ATYP_CODE ='RE'
            And a.SPRADDR_SEQNO = (select max (a1.SPRADDR_SEQNO)
                                                    from SPRADDR a1
                                                    Where a.SPRADDR_PIDM = a1.SPRADDR_PIDM
                                                    And a.SPRADDR_ATYP_CODE = a1.SPRADDR_ATYP_CODE);






    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida :=null;
 return vl_salida;
END f_estado;

Function f_pais (p_pidm in number) return varchar2 is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



            select distinct  STVNATN_NATION
            Into vl_salida
            from SPRADDR a
            join stvnatn on   STVNATN_CODE= SPRADDR_NATN_CODE
            Where a.SPRADDR_PIDM =  p_pidm
            And a.SPRADDR_ATYP_CODE ='RE'
            And a.SPRADDR_SEQNO = (select max (a1.SPRADDR_SEQNO)
                                                    from SPRADDR a1
                                                    Where a.SPRADDR_PIDM = a1.SPRADDR_PIDM
                                                    And a.SPRADDR_ATYP_CODE = a1.SPRADDR_ATYP_CODE);






    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida :=null;
 return vl_salida;
END f_pais;

Function   f_periodo_inscripcion (p_pidm in number,  p_sp in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin

       select   distinct to_char (min (x.Periodo)) --, rownum
            into   vl_salida
        from (
        SELECT DISTINCT
                   MIN (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                FROM SFRSTCR a, SSBSECT b
               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                     And  a.SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                     AND a.SFRSTCR_RSTS_CODE = 'RE'
                     And  b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB  not in ( 'IND00001','UTEL001','L1HP401', 'L1HB401','M1HB401' )
                     AND b.SSBSECT_PTRM_START_DATE =
                            (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                               FROM SSBSECT b1
                              WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                    AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                    And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB = b1.SSBSECT_SUBJ_CODE||b1.SSBSECT_CRSE_NUMB)
               and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1,3 asc
            )  x
            where rownum = 1
            group by x.fecha_inicio
            order by 1 asc;

    Exception
    When Others then
            select   distinct to_char (min (x.Periodo)) --, rownum
            into   vl_salida
            from (
            SELECT DISTINCT
               MIN (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
            FROM SFRSTCR a, SSBSECT b
            WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                 AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                 And  a.SFRSTCR_STSP_KEY_SEQUENCE= p_sp
             --    AND a.SFRSTCR_RSTS_CODE = 'RE'
                 And  b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB  not in ( 'IND00001','UTEL001','L1HP401', 'L1HB401','M1HB401' )
                 AND b.SSBSECT_PTRM_START_DATE =
                        (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                           FROM SSBSECT b1
                          WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB = b1.SSBSECT_SUBJ_CODE||b1.SSBSECT_CRSE_NUMB)
            and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1,3 asc
            )  x
            where rownum = 1
            group by x.fecha_inicio
            order by 1 asc;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida := null;
 return vl_salida;
END f_periodo_inscripcion;

/*
  FUNCTION f_alumnos_CRM_out(p_pidm in number DEFAULT NULL)  RETURN pkg_utilerias.cursor_out
           AS
                c_out pkg_utilerias.cursor_out;

            BEGIN
                          open c_out
                            FOR

                               Select distinct
                                    PIDM,
                                    MATRICULA,
                                    PATERNO,
                                    MATERNO,
                                    NOMBRE,
                                    CAMPUS,
                                    NIVEL,
                                    ESTATUS,
                                    CORREO,
                                    CARRERA,
                                    GENERO,
                                    NACIONALIDAD,
                                    NSS,
                                    CURP,
                                    FECHA_NAC,
                                    OCUPACION,
                                    NOMBRE_EMPRESA ,
                                    TEL_CELULAR,
                                    TEL_CASA,
                                    TEL_OFICINA,
                                    TEL_ALTERNO,
                                    CALLE,
                                    COLONIA,
                                    CP,
                                    MUNICIPIO,
                                    ESTADO,
                                    PAIS,
                                    FECHA_INSCRIPCION,
                                    PERIODO_INSCRIPCION,
                                    EDAD,
                                    LUGAR_NACIMIENTO,
                                    TIPO_PUESTO,
                                    SALARIO_MENSUAL,
                                    ESCUELA_PROCEDENCIA,
                                    JORNADA
                                  From SZTECRM
                                  Where ESTATUS_ENVIO is null
                                  And PIDM = nvl (p_pidm, pidm)
                                  order by matricula, periodo_inscripcion asc;

                        RETURN (c_out);

 END f_alumnos_CRM_out;
*/
Function f_alumnos_actualiza (p_pidm in number, p_respuesta in number, p_observaciones in varchar2 ) return varchar2
Is


--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


    BEGIN

               If p_respuesta = 1 then

                    Begin
                                Update SZTECRM
                                set ESTATUS_ENVIO = p_respuesta,
                                     observaciones = null,
                                     FECHA_ACTUALIZA = sysdate
                                Where PIDM = p_pidm;
                    Exception
                    When Others then
                      vl_salida := null;
                    End;
              Else

                    Begin
                                Update SZTECRM
                                set ESTATUS_ENVIO = p_respuesta,
                                     observaciones = p_observaciones,
                                     FECHA_ACTUALIZA = sysdate
                                Where PIDM = p_pidm;
                    Exception
                    When Others then
                      vl_salida := null;
                    End;

              End if;

            return vl_salida;

    Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
    END f_alumnos_actualiza;


Function  f_paquete_programa  (p_pidm in number, p_programa in varchar2 ) return varchar2

As
            vl_resultado varchar2(250) := null;
            vl_secuencia number:=0;

    Begin

            Begin
                    select SARADAP_APPL_NO
                        Into vl_secuencia
                    from saradap a
                    where a.saradap_pidm = p_pidm
                    And  a.SARADAP_PROGRAM_1  = p_programa
                    And a.SARADAP_APST_CODE ='A'
                    And a.SARADAP_APPL_NO = (select max (a1.SARADAP_APPL_NO)
                                                                 from saradap a1
                                                                 Where a.saradap_pidm = a1.saradap_pidm
                                                                 And a.SARADAP_PROGRAM_1 = a1.SARADAP_PROGRAM_1
                                                                 And a.SARADAP_APST_CODE = a1.SARADAP_APST_CODE);



            Exception
                When Others then
                    vl_secuencia :=1;
            End;



              Begin

                    Select distinct vend.saracmt_comment_text
                        Into vl_resultado
                     from SARACMT vend
                       Where vend.saracmt_pidm = p_pidm
                        AND vend.saracmt_orig_code = 'PAQT'
                        AND VEND.SARACMT_APPL_NO = vl_secuencia
                           AND vend.SARACMT_SEQNO IN (SELECT MAX (cmt.SARACMT_SEQNO)
                                                                            FROM SARACMT cmt
                                                                            WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                            And  vend.SARACMT_APPL_NO= cmt.SARACMT_APPL_NO
                                                                            AND cmt.saracmt_orig_code = 'PAQT');

              Exception
                    When Others then
                      vl_resultado := null;
              End;



               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := '05';
          Return (vl_resultado);
    End f_paquete_programa;


Function  f_documento_programa  (p_pidm in number, p_programa in varchar2, p_documento in varchar2 ) return varchar2

As
            vl_resultado varchar2(250) := null;
            vl_secuencia number:=0;

    Begin

            Begin
                    select SARADAP_APPL_NO
                        Into vl_secuencia
                    from saradap
                    where saradap_pidm = p_pidm
                    And  SARADAP_PROGRAM_1  = p_programa
                    And SARADAP_APST_CODE ='A';

            Exception
                When Others then
                    vl_secuencia :=1;
            End;



              Begin

                        select distinct SARCHKL_CKST_CODE
                        Into vl_resultado
                        from SARCHKL
                        where SARCHKL_PIDM = p_pidm
                        And SARCHKL_APPL_NO = vl_secuencia
                        And SARCHKL_ADMR_CODE = p_documento;

              Exception
                    When Others then
                      vl_resultado := null;
              End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := '05';
          Return (vl_resultado);
    End f_documento_programa;


    Function f_jornada (p_pidm in number, p_sp in number) Return varchar2
    As


           vl_jornada varchar2(250) := null;

    Begin

            Begin

                    select distinct SGRSATT_ATTS_CODE || ' ' ||STVATTS_DESC Jornada
                        into vl_jornada
                    from SGRSATT a
                    join stvatts b on  b.STVATTS_CODE  = a.SGRSATT_ATTS_CODE and  STVATTS_DESC like 'JOR%'
                    where a.SGRSATT_PIDM = p_pidm
                    And a.SGRSATT_STSP_KEY_SEQUENCE = p_sp
                    And a.SGRSATT_TERM_CODE_EFF = (select max (a1.SGRSATT_TERM_CODE_EFF)
                                                                             from SGRSATT a1
                                                                             Where a.SGRSATT_PIDM = a1.SGRSATT_PIDM
                                                                             And a.SGRSATT_STSP_KEY_SEQUENCE =  a1.SGRSATT_STSP_KEY_SEQUENCE);
            Exception
                When Others then
                    vl_jornada :=null;
            End;


               Return (vl_jornada);

    Exception
        when Others then
         vl_jornada := null;
          Return (vl_jornada);
    End f_jornada;


 Function f_fecha_jornada (p_pidm in number, p_sp in number) Return varchar2
    As


           vl_fecha_jornada varchar2(250) := null;

    Begin

            Begin

                select distinct TRUNC(SGRSATT_ACTIVITY_DATE) CAMBIO_FECHA_JORNADA
                        into vl_fecha_jornada
                    from SGRSATT a
                    join stvatts b on  b.STVATTS_CODE  = a.SGRSATT_ATTS_CODE and  STVATTS_DESC like 'JOR%'
                    where a.SGRSATT_PIDM = p_pidm
                    And a.SGRSATT_STSP_KEY_SEQUENCE = p_sp
                    And a.SGRSATT_TERM_CODE_EFF = (select max (a1.SGRSATT_TERM_CODE_EFF)
                                                                             from SGRSATT a1
                                                                             Where a.SGRSATT_PIDM = a1.SGRSATT_PIDM
                                                                             And a.SGRSATT_STSP_KEY_SEQUENCE =  a1.SGRSATT_STSP_KEY_SEQUENCE);

            Exception
                When Others then
                    vl_fecha_jornada :=null;
            End;


               Return (vl_fecha_jornada);

    Exception
        when Others then
         vl_fecha_jornada := null;
          Return (vl_fecha_jornada);
    End f_fecha_jornada;

    Function f_moneda (p_pidm in number) Return varchar2
 As


           vl_moneda varchar2(250) := null;

    Begin

            Begin
                             Select x.TVRDCTX_CURR_CODE
                                     Into vl_moneda
                             from (
                                select distinct TVRDCTX_CURR_CODE, count(*)
                                from TVRDCTX
                                join spriden on spriden_pidm = p_pidm and SPRIDEN_CHANGE_IND  is null
                                Where  substr (TVRDCTX_DETC_CODE, 1, 2) = substr (spriden_id, 1, 2)
                                group by TVRDCTX_CURR_CODE
                                having count(*)  > 10
                            ) x;
            Exception
                When Others then
                    vl_moneda :=sqlerrm;
            End;


               Return (vl_moneda);

    Exception
        when Others then
         vl_moneda := sqlerrm;
          Return (vl_moneda);
    End f_moneda;



Function f_servicio_social (p_pidm in number) Return varchar2
 As


           vl_servicio varchar2(250) := null;

    Begin

            Begin

                           select distinct
                                                    CASE WHEN  a.matricula=(SELECT distinct max (d.spriden_id)
                                                                                          FROM  spriden d, shrncrs s, SGRCOOP
                                                                                          WHERE d.spriden_pidm=s.shrncrs_pidm
                                                                                          AND s.shrncrs_ncrq_code='SS'
                                                                                          AND S.SHRNCRS_NCST_CODE='AP'
                                                                                          and d.spriden_pidm = SGRCOOP_PIDM
                                                                                          and d.spriden_pidm = a.pidm
                                                                             )
                                                                            THEN 'LIBERADO'
                                                         WHEN  a.matricula=(SELECT distinct MAX(d.spriden_id)
                                                                              FROM  spriden d, shrncrs s
                                                                              WHERE d.spriden_pidm=a.pidm
                                                                              AND d.spriden_pidm=s.shrncrs_pidm
                                                                              AND s.shrncrs_ncrq_code='SS'
                                                                              And s.SHRNCRS_NCST_DATE is null
                                                                              AND S.SHRNCRS_ACTIVITY_DATE IS NOT NULL
                                                                            )
                                                                           THEN 'CONCLUIDO'
                                                          WHEN  a.matricula=(SELECT distinct MAX(spriden_id)
                                                                                  FROM  spriden , SGRCOOP  s
                                                                                  WHERE a.pidm=spriden_pidm
                                                                                  AND spriden_pidm=s.SGRCOOP_PIDM
                                                                                  And spriden_pidm not in (select shrncrs_pidm
                                                                                                                        from shrncrs
                                                                                                                        )
                                                                                )
                                                                              THEN 'EN PROCESO'
                                                          WHEN  a.matricula=(SELECT distinct MAX(spriden_id)
                                                                                  FROM  spriden , SGRCOOP  s
                                                                                  WHERE a.pidm=spriden_pidm
                                                                                  AND spriden_pidm=s.SGRCOOP_PIDM
                                                                                  And spriden_pidm  in (select shrncrs_pidm
                                                                                                                        from shrncrs
                                                                                                                        where  SHRNCRS_NCST_DATE is null
                                                                                                                        And shrncrs_ncrq_code is null)
                                                                                )
                                                                              THEN 'EN PROCESO'
                                                    ELSE
                                                             'NO INICIADO'
                                                    END estatus_del_servicio_social
                                           Into vl_servicio
                            from tztprog a
                            where 1=1
                            and a.pidm = p_pidm;


            Exception
                When Others then
                    vl_servicio :='NO INICIADO';
            End;


               Return (vl_servicio);

    Exception
        when Others then
         vl_servicio := null;
          Return (vl_servicio);
    End f_servicio_social;


Function f_razon_social (p_pidm in number) Return varchar2
 As


           vl_razon  varchar2(250) := null;

    Begin

            Begin

                    select distinct SPREMRG_LAST_NAME
                        Into vl_razon
                    from SPREMRG a
                    where a.SPREMRG_PIDM = p_pidm
                    And to_number (a.SPREMRG_PRIORITY) = (select max (to_number(a1.SPREMRG_PRIORITY))
                                                                                    from SPREMRG a1
                                                                                    Where a.SPREMRG_PIDM = a1.SPREMRG_PIDM);


            Exception
                When Others then
                    vl_razon :=null;
            End;


               Return (vl_razon);

    Exception
        when Others then
         vl_razon := null;
          Return (vl_razon);
    End f_razon_social;

Function f_direccion_fiscal (p_pidm in number) Return varchar2
 As


           vl_direccion  varchar2(250) := null;

    Begin

            Begin

                select distinct SPREMRG_STREET_LINE1 ||' '||SPREMRG_STREET_LINE2 ||' '||SPREMRG_STREET_LINE3 ||' '||SPREMRG_STREET_LINE3 direccion
                                        Into vl_direccion
                                    from SPREMRG a
                                    where a.SPREMRG_PIDM = p_pidm
                                    And to_number (a.SPREMRG_PRIORITY) = (select max (to_number(a1.SPREMRG_PRIORITY))
                                                                                                    from SPREMRG a1
                                                                                                    Where a.SPREMRG_PIDM = a1.SPREMRG_PIDM);


            Exception
                When Others then
                    vl_direccion :=null;
            End;


               Return (vl_direccion);

    Exception
        when Others then
         vl_direccion := null;
          Return (vl_direccion);
    End f_direccion_fiscal;


Function f_cp_fiscal (p_pidm in number) Return varchar2
 As


           vl_direccion  varchar2(250) := null;

    Begin

            Begin

                select distinct SPREMRG_ZIP
                                        Into vl_direccion
                                    from SPREMRG a
                                    where a.SPREMRG_PIDM = p_pidm
                                    And to_number (a.SPREMRG_PRIORITY) = (select max (to_number(a1.SPREMRG_PRIORITY))
                                                                                                    from SPREMRG a1
                                                                                                    Where a.SPREMRG_PIDM = a1.SPREMRG_PIDM);


            Exception
                When Others then
                    vl_direccion :=null;
            End;


               Return (vl_direccion);

    Exception
        when Others then
         vl_direccion := null;
          Return (vl_direccion);
    End f_cp_fiscal;

Function f_tipo_referencia (p_pidm in number) Return varchar2
 As


           vl_referencia  varchar2(250) := null;

    Begin

            Begin

                        select distinct GORADID_ADID_CODE
                            Into vl_referencia
                        from goradid
                        where goradid_pidm = p_pidm
                        and GORADID_ADID_CODE like 'REF%';


            Exception
                When Others then
                    vl_referencia :=null;
            End;


               Return (vl_referencia);

    Exception
        when Others then
         vl_referencia := null;
          Return (vl_referencia);
    End f_tipo_referencia;


Function f_referencia (p_pidm in number) Return varchar2
 As


           vl_referencia  varchar2(250) := null;

    Begin

            Begin

                        select distinct GORADID_ADDITIONAL_ID
                            Into vl_referencia
                        from goradid
                        where goradid_pidm = p_pidm
                        and GORADID_ADID_CODE like 'REF%';


            Exception
                When Others then
                    vl_referencia :=null;
            End;


               Return (vl_referencia);

    Exception
        when Others then
         vl_referencia := null;
          Return (vl_referencia);
    End f_referencia;


Function f_formaPago (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<comprobante');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'formaPago="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'formaPago="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'formaPago="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'formaPago="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_metodo_pago
                    FROM DUAL;
           Exception
            When Others then
            vl_metodo_pago := null;
           End;

               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_formaPago;

Function f_metodoPago (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<comprobante');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'metodoPago="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'metodoPago="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'metodoPago="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'metodoPago="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_metodo_pago
                    FROM DUAL;
           Exception
            When Others then
            vl_metodo_pago := null;
           End;

               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_metodoPago;


Function f_colegiatura (p_pidm in number, p_secuencia in number) Return varchar2

 As




vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO_CODE ||',' codigo
                                from tztconc
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE in ('COL')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_colegiatura;

Function f_monto_col (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, 'MontoColegiatura');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_salida
                    FROM DUAL;
           Exception
            When Others then
            vl_salida := null;
           End;

               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_monto_col;

Function f_descripcion_col (p_pidm in number, p_secuencia in number) Return varchar2


 As


vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO ||',' codigo
                                from tztconc
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE in ('COL')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_descripcion_col;


Function f_intereses (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO_CODE ||',' codigo
                                from tztconc
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE in ('INT')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_intereses;

Function f_monto_interes (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, 'MontoInteresPagoTardio');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_salida
                    FROM DUAL;
           Exception
            When Others then
            vl_salida := null;
           End;

               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_monto_interes;

Function f_descrip_interes (p_pidm in number, p_secuencia in number) Return varchar2


 As




i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, 'nombre="InteresPagoTardio"');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_salida
                    FROM DUAL;
           Exception
            When Others then
            vl_salida := null;
           End;

               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_descrip_interes;

Function f_monto_accesorio (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, 'MontoAccesorio');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_salida
                    FROM DUAL;
           Exception
            When Others then
            vl_salida := null;
           End;

               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_monto_accesorio;

Function f_monto_iva (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<trasladados  impuesto');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'importe="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'importe="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'importe="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'importe="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_salida
                    FROM DUAL;
           Exception
            When Others then
            vl_salida := null;
           End;

               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_monto_iva;

Function f_subtotal (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<comprobante');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'subTotal="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'subTotal="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'subTotal="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'subTotal="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_metodo_pago
                    FROM DUAL;
           Exception
            When Others then
            vl_metodo_pago := null;
           End;

               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_subtotal;

Function f_total (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<comprobante');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'total="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'total="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'total="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'total="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_metodo_pago
                    FROM DUAL;
           Exception
            When Others then
            vl_metodo_pago := null;
           End;

               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_total;


Function f_total_grabado (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_iva number:=0;
vl_total_iva number:=0;
vl_total_grabado number:=0;



  Begin

            Begin

                            select  sum (TZTCONC_SUBTOTAL)
                                Into vl_total_grabado
                            from tztconc
                            join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                     And TBBDETC_TYPE_IND ='C'
                                                     And TBBDETC_DCAT_CODE not in ('COL', 'INT', 'APF')
                            where TZTCONC_PIDM = p_pidm
                            and TZTCONC_TRAN_NUMBER = p_secuencia
                            And nvl (TZTCONC_IVA,0) > 0;
            Exception
                When Others then
                   vl_total_grabado :=0;
            End;

        Return (vl_total_grabado);
   Exception
        when Others then
         vl_total_grabado := 0;
          Return (vl_total_grabado);

  End f_total_grabado;

Function f_total_Excento (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_iva number:=0;
vl_total_iva number:=0;
vl_total_exento number:=0;



  Begin

            Begin

                            select  sum (TZTCONC_SUBTOTAL)
                                Into vl_total_exento
                            from tztconc
                            join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                     And TBBDETC_TYPE_IND ='C'
                                                     And TBBDETC_DCAT_CODE not in ('COL', 'INT','APF')
                            where TZTCONC_PIDM = p_pidm
                            and TZTCONC_TRAN_NUMBER = p_secuencia
                            And nvl (TZTCONC_IVA,0) =  0;
            Exception
                When Others then
                   vl_total_exento :=0;
            End;

        Return (vl_total_exento);
   Exception
        when Others then
         vl_total_exento := 0;
          Return (vl_total_exento);

  End f_total_Excento;


  Function f_total_grabado_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_iva number:=0;
vl_total_iva number:=0;
vl_total_grabado number:=0;



  Begin

            Begin

                select  sum (TZTCONC_SUBTOTAL)
                Into vl_total_grabado
                from tztcont
                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                And TBBDETC_TYPE_IND ='C'
                And TBBDETC_DCAT_CODE not in ('COL', 'INT', 'APF')
                where TZTCONC_PIDM = p_pidm
                and TZTCONC_TRAN_NUMBER = p_secuencia
                And nvl (TZTCONC_IVA,0) > 0;
            Exception
            When Others then
            vl_total_grabado :=0;
            End;

        Return (vl_total_grabado);
  Exception
  when Others then
  vl_total_grabado := 0;
  Return (vl_total_grabado);

  End f_total_grabado_nt;


  Function f_total_Excento_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_iva number:=0;
vl_total_iva number:=0;
vl_total_exento number:=0;



  Begin

            Begin

            select  sum (TZTCONC_SUBTOTAL)
            Into vl_total_exento
            from tztcont
            join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
            And TBBDETC_TYPE_IND ='C'
            And TBBDETC_DCAT_CODE not in ('COL', 'INT','APF')
            where TZTCONC_PIDM = p_pidm
            and TZTCONC_TRAN_NUMBER = p_secuencia
            And nvl (TZTCONC_IVA,0) =  0;
            Exception
            When Others then
            vl_total_exento :=0;
            End;

        Return (vl_total_exento);
  Exception
  when Others then
  vl_total_exento := 0;
  Return (vl_total_exento);

  End f_total_Excento_nt;



  Function f_total_monto_accesorio (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_iva number:=0;
vl_total_iva number:=0;
vl_total_exento number:=0;
vl_final number :=0;



  Begin
            Begin
                    select sum (TZTCONC_SUBTOTAL)
                        Into vl_final
                    from tztconc
                    join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                             And TBBDETC_TYPE_IND ='C'
                                             And TBBDETC_DCAT_CODE not in ('COL', 'INT','APF')
                    where TZTCONC_PIDM = p_pidm
                    and TZTCONC_TRAN_NUMBER = p_secuencia;
             Exception
                When Others then
                    vl_final:=0;
             End;

        Return (vl_final);
   Exception
        when Others then
         vl_final := 0;
          Return (vl_final);

  End f_total_monto_accesorio;


Function f_fecha_pago_fact (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, 'fechaPago');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_salida
                    FROM DUAL;
           Exception
            When Others then
            vl_salida := null;
           End;

               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_fecha_pago_fact;


Function f_descrip_accesorios (p_pidm in number, p_secuencia in number) Return varchar2


 As

vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO ||',' codigo
                                from tztconc
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE not in ('INT','COL','APF')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_descrip_accesorios;


Function f_estado_facturacion (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, 'comprobante');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'estado="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'estado="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'estado="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'estado="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_salida
                    FROM DUAL;
           Exception
            When Others then
            vl_salida := null;
           End;

               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_estado_facturacion;

Function f_folio_interno (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, 'folioInterno');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'valor="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_salida
                    FROM DUAL;
           Exception
            When Others then
            vl_salida := null;
           End;

               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_folio_interno;

Function f_accesorio (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO_CODE ||',' codigo
                                from tztconc
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE not in ('INT','COL','APF')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_accesorio;


function f_avcu_out(pidm number, prog varchar2,usu_siu varchar2) RETURN pkg_utilerias.avcu_out
           AS
                avance_n_out pkg_utilerias.avcu_out;

                       BEGIN
                       delete from avance_n
                       where protocolo=9999
                       and USUARIO_SIU=usu_siu;
                       commit;


              insert into avance_n
                    select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                    case
                           when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+3
                           when smralib_area_desc like 'Taller%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                           else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                    end  per,  ----
                    smrpaap_area area,   ----
                                                  case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                      case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('11') then substr(smrpaap_area,9,2)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('12') then substr(smrpaap_area,9,2)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             else smralib_area_desc
                                                       end
                                                    else smralib_area_desc
                                                    end
                                                     nombre_area,  ---
                                    smrarul_subj_code||smrarul_crse_numb_low materia, ----
                                    scrsyln_long_course_title nombre_mat, ----
                                     case when k.calif in ('NA','NP','AC') then '1'
                                            when k.st_mat='EC' then '101'
                                     else  k.calif
                                     end calif, ---
                                     nvl(k.st_mat,'PC'),  ---
                                     smracaa_rule regla,   ---
                                     case when k.st_mat='EC' then null
                                       else k.calif
                                     end  origen,
                                     k.fecha, ---
                                     pidm ,
                                     usu_siu
                                    from smrpaap s, smrarul, sgbstdn y, sorlcur so, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
                                    (
                                               select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                 w.shrtckn_subj_code subj, w.shrtckn_crse_numb code,
                                                 shrtckg_grde_code_final CALIF, decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, shrtckg_final_grde_chg_date fecha
                                                from shrtckn w,shrtckg, shrgrde, smrprle
                                                where shrtckn_pidm=pidm
                                                and     shrtckg_pidm=w.shrtckn_pidm
                                                and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                and     shrtckg_tckn_seq_no=w.shrtckn_seq_no
                                                and     shrtckg_term_code=w.shrtckn_term_code
                                                and     smrprle_program=prog
                                                and     shrgrde_levl_code=smrprle_levl_code
                                                and     shrgrde_code=shrtckg_grde_code_final
   /* cambio escalas para prod */               and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                                and     decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))   -- anadido para sacar la calificacion mayor  OLC
                                                                  in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))) from shrtckn ww, shrtckg zz
                                                                          where w.shrtckn_pidm=ww.shrtckn_pidm
                                                                             and  w.shrtckn_subj_code=ww.shrtckn_subj_code  and w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                                                             and  ww.shrtckn_pidm=zz.shrtckg_pidm and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no and ww.shrtckn_term_code=zz.shrtckg_term_code)
                                                and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                                               and shrtckn_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                union
                                                select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                shrtrce_grde_code  CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                from  shrtrce
                                                where  shrtrce_pidm=pidm
                                                and     SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                union
                                                select SHRTRTK_SUBJ_CODE_INST subj, SHRTRTK_CRSE_NUMB_INST code,
                                                /*nvl(SHRTRTK_GRDE_CODE_INST,0)*/  '0' CALIF, 'EQ'  ST_MAT, trunc(SHRTRTK_ACTIVITY_DATE) fecha
                                                from  SHRTRTK
                                                where  SHRTRTK_PIDM=pidm
                                                union
                                                select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                from sfrstcr, smrprle, ssbsect, spriden
                                                where  smrprle_program=prog
                                                and     sfrstcr_pidm=pidm  and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                and     SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
    --                                            and    sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                and    ssbsect_term_code=sfrstcr_term_code
                                                and    ssbsect_crn=sfrstcr_crn
                                                union
                                                select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                 ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)/*+120*/  fecha
                                                from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                                where  smrprle_program=prog
                                                and     sfrstcr_pidm=pidm  and sfrstcr_grde_code is not null
                                                and     sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and shrtckn_crn=sfrstcr_crn)
                                                and    SFRSTCR_RSTS_CODE!='DD'  --- agregado
                                                and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
    --                                            and    sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                and     SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                and     SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                                               and sfrstcr_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                and    ssbsect_term_code=sfrstcr_term_code
                                                and    ssbsect_crn=sfrstcr_crn
                                                and    shrgrde_levl_code=smrprle_levl_code
                                                and    shrgrde_code=sfrstcr_grde_code
      /* cambio escalas para prod */            and    shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                   ) k
                                  where    spriden_pidm=pidm  and spriden_change_ind is null
                                    and   sorlcur_pidm= spriden_pidm
                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                    and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                   and     smrpaap_program=prog
                                   AND  smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                   and     smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                   and     SMBAGEN_ACTIVE_IND='Y'           --solo areas activas  OLC
                                   and     SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF   --solo areas activas  OLC
                                   and     smrpaap_area=smrarul_area
                                   and     sgbstdn_pidm=spriden_pidm
                                   and     sgbstdn_program_1=smrpaap_program
                                   and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                   and     sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO'  and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                   and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                   and     SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
                                   and     stvstst_code=sgbstdn_stst_code
                                   and     smralib_area=smrpaap_area
                                   AND    smracaa_area = smrarul_area
                                   AND    smracaa_rule = smrarul_key_rule
                                   and    SMRACAA_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                   and     SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
--                                   and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
--                                                    (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
--                                                    (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                                   and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                           )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                              and ss.sorlcur_program =prog )
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                                 ) )) )
                                   and    k.subj=smrarul_subj_code and k.code=smrarul_crse_numb_low
                                   and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                   and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=sgbstdn_program_1 and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                 union
                                 select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                                    case
                                            when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+3
                                            when smralib_area_desc like 'Taller%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                           else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                                    end  per,  ---
                                    smrpaap_area area, ---
                                                              case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                                  case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('11') then substr(smrpaap_area,9,2)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('12') then substr(smrpaap_area,9,2)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         else smralib_area_desc
                                                                   end
                                                                else smralib_area_desc
                                                                end   nombre_area, ---
                                                smrarul_subj_code||smrarul_crse_numb_low materia, ---
                                                 scrsyln_long_course_title nombre_mat, ---
                                                 null calif,  ---
                                                 'PC' ,  ---
                                                 smracaa_rule regla, ---
                                                 null origen, ---
                                                  null fecha, --
                                                  pidm ,
                                                 usu_siu
                                    from spriden, smrpaap, sgbstdn y, sorlcur so,SZTDTEC, smrarul, smracaa, smralib, stvstst, scrsyln, zstpara,smbagen
                                     where    spriden_pidm=pidm  and spriden_change_ind is null
                                               and   sorlcur_pidm= spriden_pidm
                                               and   SORLCUR_LMOD_CODE = 'LEARNER'
                                               and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                  and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                  and ss.sorlcur_program =prog)
                                               and       smrpaap_program=prog
                                               AND  smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                                    and     smrpaap_area=SMBAGEN_AREA
                                                    and     SMBAGEN_ACTIVE_IND='Y'
                                                    and     SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                                and     smrpaap_area=smrarul_area
                                                and     sgbstdn_pidm=spriden_pidm
                                                and     sgbstdn_program_1=smrpaap_program
                                                and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                  where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                  and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                and     sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO' and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                                and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                                and     stvstst_code=sgbstdn_stst_code
                                                and     smralib_area=smrpaap_area
                                                AND smracaa_area = smrarul_area
                                                AND smracaa_rule = smrarul_key_rule
                                                AND   SMRARUL_TERM_CODE_EFF = SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                                and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                                           and spriden_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                               and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                           )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                              and ss.sorlcur_program =prog )
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                                 ) )) )
                                                    and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                                    and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTCKN_SUBJ_CODE,SHRTCKN_CRSE_NUMB  from shrtckn where shrtckn_pidm=pidm )
                                                    and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRCE_SUBJ_CODE,SHRTRCE_CRSE_NUMB  from SHRTRCE where SHRTRCE_pidm=pidm )     --agregado
                                                    and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRTK_SUBJ_CODE_INST,SHRTRTK_CRSE_NUMB_INST  from SHRTRTK where SHRTRTK_pidm=pidm )  --agregado
                                                    and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select ssbsect_subj_code subj, ssbsect_crse_numb code  from  sfrstcr, smrprle, ssbsect, spriden  --agregado para materias EC y aprobadas sin rolar
                                                                                                                           where  smrprle_program=prog
                                                                                                                               and     sfrstcr_pidm=pidm  and (sfrstcr_grde_code is null or sfrstcr_grde_code is not null)  and sfrstcr_rsts_code='RE'
                                                                                                                               and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                                                               and    ssbsect_term_code=sfrstcr_term_code
                                                                                                                               and    ssbsect_crn=sfrstcr_crn)
                                                     and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=sgbstdn_program_1 and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG;

                                 commit;


                          open avance_n_out
                            FOR
                             select
                                   CASE  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                       where SMBPGEN_program=prog
                                                                           and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                                                 where  s.sorlcur_pidm=pidm
                                                                                                                                      and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                      and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                                 where ss.sorlcur_pidm=pidm
                                                                                                                                                                                  and ss.sorlcur_program=prog
                                                                                                                                                                                  and ss.sorlcur_lmod_code='LEARNER'))) ='40' then
                                                                                                                                                                                             (select count(unique materia)  from avance_n x
                                                                                                                                                                                             where  apr in ('AP','EQ')
                                                                                                                                                                                             and    protocolo=9999
                                                                                                                                                                                             and    pidm_alu=pidm
                                                                                                                                                                                             and    usuario_siu=usu_siu
                                                                                                                                                                                             and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                                                                                                                                                             and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                                                    where x.materia=xx.materia
                                                                                                                                                                                                                    and   x.protocolo=xx.protocolo
                                                                                                                                                                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                                                    and   x.usuario_siu=xx.usuario_siu)
                                                                                                                                                                                                                    and CALIF!=0
                                                    and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )

                                                  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                       where SMBPGEN_program=prog
                                                                           and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                                                 where  s.sorlcur_pidm=pidm
                                                                                                                                      and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                      and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                                 where ss.sorlcur_pidm=pidm
                                                                                                                                                                                  and ss.sorlcur_program=prog
                                                                                                                                                                                  and ss.sorlcur_lmod_code='LEARNER'))) ='42' then
                                                                                                                                                                                          (select count(unique materia)  from avance_n x
                                                                                                                                                                                             where  apr in ('AP','EQ')
                                                                                                                                                                                             and    protocolo=9999
                                                                                                                                                                                             and    pidm_alu=pidm
                                                                                                                                                                                             and    usuario_siu=usu_siu
                                                                                                                                                                                             and    area not in  ((select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' ) )
                                                                                                                                                                                             and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                                                    where x.materia=xx.materia
                                                                                                                                                                                                                    and   x.protocolo=xx.protocolo
                                                                                                                                                                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                                                    and   x.usuario_siu=xx.usuario_siu)
                                                                                                                                                                                                                    and CALIF!=0
                                                    and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )
                                            ELSE
                                                  (select count(unique materia)  from avance_n x
                                                     where  apr in ('AP','EQ')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    usuario_siu=usu_siu
                                                     and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                     and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            and   x.usuario_siu=xx.usuario_siu)
                                                                            and CALIF!=0
                                                     and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )
                                      end  aprobadas_curr,
                                   ---------------------------
                                     (select count(unique materia)  from avance_n x
                                     where  apr in ('NA')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                     and    materia not in (select materia from avance_n xx
                                                           where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu
                                                            and   xx.apr='EC')
                                     and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu)) no_aprobadas_curr,
                                     (select count(unique materia) from avance_n x
                                     where  apr in ('EC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                                  ) curso_curr,
                                         (select count(unique materia)  from avance_n x
                                                     where apr in ('PC')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    usuario_siu=usu_siu
                                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                     and materia not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB' and ZSTPARA_PARAM_VALOR=materia and
                                                           pidm_alu in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                           ) por_cursar_curr,
                                       case when
                                              round ((select count(unique materia) from avance_n x
                                             where  apr in ('AP','EQ')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    usuario_siu=usu_siu
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and     calif not in ('NP','AC')
                                             and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) or calif is null)
                                                      and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                           and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
                                                                    ) *100 /
                                            (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                    where  sorlcur_pidm=pidm
                                                                                                                       and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                       and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where ss.sorlcur_pidm=pidm
                                                                                                                                                                   and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))>100  then 100
                                         else
                                            round ((select count(unique materia) from avance_n x
                                             where  apr in ('AP','EQ')
                                            and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    usuario_siu=usu_siu
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and     calif not in ('NP','AC')
                                             and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) or calif is null)
                                                     and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
                                                                    ) *100 /
                                            (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                    where  sorlcur_pidm=pidm
                                                                                                                       and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                       and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                             where ss.sorlcur_pidm=pidm
                                                                                                                                                             and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))
                                       end Avance_n_curr,
                                    (select count(unique materia) from avance_n x
                                     where apr in ('AP','EQ')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                     and    to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu))  aprobadas_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('NA')
                                     and    protocolo=9999
                                      and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                     and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu)) no_aprobadas_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('EC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                  ) curso_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('PC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                  )  por_cursar_tall
--                                    (select count(unique materia) from avance_n x
--                                     where area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
--                                     and    protocolo=9999
--                                     and    pidm_alu=pidm
--                                     and    usuario_siu=usu_siu
--                                     and    (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
--                                                            where x.materia=xx.materia
--                                                            and   x.protocolo=xx.protocolo
--                                                            and   x.pidm_alu=xx.pidm_alu
--                                                            and   x.usuario_siu=xx.usuario_siu) or calif is null)) total_tall
                                    from spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
                                    (SELECT 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
                                       FROM  (
                                                        select 9999, per, area, nombre_area, materia, nombre_mat,
                                                                        case when calif='1' then cal_origen
                                                                                when apr='EC' then null
                                                                        else calif
                                                                        end calif, apr, regla, null n_area,
                                                                        case when substr(materia,1,2)='L3' then 5
                                                                        else 1
                                                                        end ord,fecha
                                                                 from  sgbstdn y, avance_n x
                                                                   where  x.protocolo=9999
                                                                    and    sgbstdn_pidm=pidm
                                                                    and    sgbstdn_program_1=prog
                                                                    and    x.pidm_alu=pidm
                                                                    and    x.usuario_siu=usu_siu
                                                                    and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                    and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and  x.protocolo=xx.protocolo   ----cambio
                                                                          and  x.pidm_alu=sgbstdn_pidm  ----cambio
                                                                          and  x.pidm_alu=xx.pidm_alu   ---- cambio
                                                                          and  x.usuario_siu=xx.usuario_siu) or calif is null)
                                                        union
                                                        select distinct 9999, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                                                        case when calif='1' then cal_origen
                                                                when apr='EC' then null
                                                        else calif
                                                        end calif, apr, regla, null n_area,
                                                        case when substr(materia,1,2)='L3' then 5
                                                        else 1
                                                        end ord, fecha
                                                                    from  sgbstdn y, avance_n x
                                                                   where   x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                     and    x.pidm_alu=sgbstdn_pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     apr='EC'
                                                                    and     sgbstdn_program_1=prog
                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                        union
                                                        select protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                    case when calif='1' then cal_origen
                                                                           when apr='EC' then null
                                                                    else calif
                                                                    end calif, apr, regla, stvmajr_desc n_area, 2 ord, fecha
                                                                    from  sgbstdn y, avance_n x, smriemj, stvmajr
                                                                   where   x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                    and     x.pidm_alu=sgbstdn_pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     sgbstdn_program_1=prog
                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and    area=smriemj_area
--                                                                   and smriemj_majr_code=sgbstdn_majr_code_1   --vic
                                                                   and smriemj_majr_code= (select distinct SORLFOS_MAJR_CODE
                                                                                            from  sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                                            and   sorlcur_program   =prog
                                                                                                      )
                                                                   and    area not in (select smriecc_area from smriecc)
                                                                   and    smriemj_majr_code=stvmajr_code
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or calif is null)
                                                        union
                                                          select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                case when calif='1' then cal_origen
                                                                         when apr='EC' then null
                                                                 else calif
                                                                end  calif, apr, regla, smralib_area_desc n_area, 3 ord, fecha
                                                                    from sgbstdn y, avance_n x ,smralib, smriecc a -- , stvmajr
                                                                   where  x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                    and     x.pidm_alu=sgbstdn_pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     sgbstdn_program_1=prog
                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and    area=smralib_area
                                                                   and    area=smriecc_area
--                                                                   and    smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)---modifico vic   18.04.2018
                                                                   and     smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
--                                                                                                        and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
--                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
--                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
--                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                        and   cu.sorlcur_pidm=pidm
                                                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                                                                        and   sorlcur_program   =prog
                                                                                                         )
--                                                                   and    smriecc_majr_code_conc=stvmajr_code
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or calif is null)
--                                                                          or calif='1')   -----------------
                                                                   and    (fecha in (select distinct fecha from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or fecha is null)
                                                        order by   n_area desc, per, nombre_area,regla
                                          )
                                        GROUP BY 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
                                    )  avance1
                                    where  spriden_pidm=pidm
                                    and   sorlcur_pidm= spriden_pidm
                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                    and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                   and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                   and ss.sorlcur_program =prog)
                                    and     spriden_change_ind is null
                                    and     sgbstdn_pidm=spriden_pidm
                                    and     sgbstdn_program_1=prog
                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                                                                      where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                                                      and    a.sgbstdn_program_1=b.sgbstdn_program_1)
                                    and     sztdtec_program=sgbstdn_program_1
                                    and     sztdtec_status='ACTIVO'
                                    and     SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE
                                    and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                    and     sgbstdn_stst_code=stvstst_code
                                    order by  avance1.per,avance1.n_area, avance1.materia,avance1.regla,avance1.ord ;
--                                    order by  avance1.per,avance1.n_area, avance1.regla,avance1.ord,hoja ;

                        RETURN (avance_n_out);

            END f_avcu_out;

Function  f_canal_venta_programa  (p_pidm in number, p_programa in varchar2 ) return varchar2

As
            vl_resultado varchar2(250) := null;
            vl_secuencia number:=0;

    Begin

            Begin
                    select SARADAP_APPL_NO
                        Into vl_secuencia
                    from saradap a
                    where a.saradap_pidm = p_pidm
                    And  a.SARADAP_PROGRAM_1  = p_programa
                    And a.SARADAP_APST_CODE ='A'
                    And a.SARADAP_APPL_NO = (select max (a1.SARADAP_APPL_NO)
                                                                 from saradap a1
                                                                 Where a.saradap_pidm = a1.saradap_pidm
                                                                 And a.SARADAP_PROGRAM_1 = a1.SARADAP_PROGRAM_1
                                                                 And a.SARADAP_APST_CODE = a1.SARADAP_APST_CODE);



            Exception
                When Others then
                    vl_secuencia :=1;
            End;



              Begin

                    Select distinct SARACMT_COMMENT_TEXT
                        Into vl_resultado
                     from SARACMT vend
                       Where vend.saracmt_pidm = p_pidm
                        AND vend.saracmt_orig_code = 'CANF'
                        AND VEND.SARACMT_APPL_NO = vl_secuencia
                           AND vend.SARACMT_SEQNO IN (SELECT MAX (cmt.SARACMT_SEQNO)
                                                                            FROM SARACMT cmt
                                                                            WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                            And  vend.SARACMT_APPL_NO= cmt.SARACMT_APPL_NO
                                                                            AND cmt.saracmt_orig_code = 'CANF');

              Exception
                    When Others then
                      vl_resultado := null;
              End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := '05';
          Return (vl_resultado);
    End f_canal_venta_programa;

Function  f_paquete_programa_fecha  (p_pidm in number, p_programa in varchar2 ) return varchar2

As
            vl_resultado varchar2(250) := null;
            vl_secuencia number:=0;

    Begin

            Begin
                    select SARADAP_APPL_NO
                        Into vl_secuencia
                    from saradap a
                    where a.saradap_pidm = p_pidm
                    And  a.SARADAP_PROGRAM_1  = p_programa
                    And a.SARADAP_APST_CODE ='A'
                    And a.SARADAP_APPL_NO = (select max (a1.SARADAP_APPL_NO)
                                                                 from saradap a1
                                                                 Where a.saradap_pidm = a1.saradap_pidm
                                                                 And a.SARADAP_PROGRAM_1 = a1.SARADAP_PROGRAM_1
                                                                 And a.SARADAP_APST_CODE = a1.SARADAP_APST_CODE);



            Exception
                When Others then
                    vl_secuencia :=1;
            End;



              Begin

                    Select distinct trunc (vend.SARACMT_ACTIVITY_DATE)
                        Into vl_resultado
                     from SARACMT vend
                       Where vend.saracmt_pidm = p_pidm
                        AND vend.saracmt_orig_code = 'PAQT'
                        AND VEND.SARACMT_APPL_NO = vl_secuencia
                           AND vend.SARACMT_SEQNO IN (SELECT MAX (cmt.SARACMT_SEQNO)
                                                                            FROM SARACMT cmt
                                                                            WHERE cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                            And  vend.SARACMT_APPL_NO= cmt.SARACMT_APPL_NO
                                                                            AND cmt.saracmt_orig_code = 'PAQT');

              Exception
                    When Others then
                      vl_resultado := null;
              End;

               Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := '05';
          Return (vl_resultado);
    End f_paquete_programa_fecha;


function f_carta_out(vl_pidm number) RETURN pkg_utilerias.cartas_out

           AS
                car_out pkg_utilerias.cartas_out;

            BEGIN
                          open car_out
                            FOR
                                Select distinct a.matricula,  REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU'),'/', ' ')  ||' ' || REPLACE (TRANSLATE (SPRIDEN_FIRST_NAME, 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU'),'/', ' ') Nombre,
                                                    a.fecha_inicio inicio_clase, c.STVLEVL_DESC nivel, d.SZTDTEC_PROGRAMA_COMP nombre_programa, SPBPERS_SSN dni
                                from tztprog a
                                join spriden b on b.spriden_pidm = a.pidm and spriden_change_ind is null
                                join stvlevl c on c.STVLEVL_CODE = a.nivel
                                join SZTDTEC d on d.SZTDTEC_PROGRAM = a.programa and d.SZTDTEC_TERM_CODE = a.CTLG
                                left join SPBPERS e on e.SPBPERS_pidm = a.pidm
                                where 1= 1
                                And a.sp = (Select max (a1.sp)
                                                        from tztprog a1
                                                        Where a.pidm = a1.pidm
                                                  )
                                And a.pidm = vl_pidm;

 RETURN (car_out);

End f_carta_out;

Function f_rfc_emisor (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from tztfact
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<comprobante');
                  entrada_sbt := SUBSTR(entrada, POSICION-1);

            Exception
                When Others then
                    Entrada:= null;
            End;




--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||entrada_sbt);

           Begin


                    SELECT SUBSTR(SUBSTR( REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'rfc="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        )
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'rfc="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1) + 1
                        ,INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'rfc="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))
                        ),'"',1,2) -
                        INSTR(SUBSTR(REPLACE(entrada_sbt,' ')
                        ,INSTR(REPLACE(entrada_sbt,' '),'rfc="')
                        ,LENGTH(REPLACE(entrada_sbt,' '))),'"',1) - 1
                        )
                    INTO vl_metodo_pago
                    FROM DUAL;
           Exception
            When Others then
            vl_metodo_pago := null;
           End;

               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_rfc_emisor;

Function f_documento_tipo (p_pidm in number, p_programa in varchar2, p_tipo in varchar2) return varchar2  is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


BEGIN

            Begin

                        select  SARCHKL_CKST_CODE Documento
                        into vl_salida
                        from SARCHKL
                        join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_programa
                                                                                               and SARADAP_APPL_NO = SARCHKL_APPL_NO
                        join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
                        where SARCHKL_PIDM = p_pidm
                        And SARCHKL_ADMR_CODE = p_tipo;

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_documento_tipo;


Function f_mora (p_pidm in number) return varchar2 is

vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select
                               case
                                when NVL(TZTMORA_dias,0)  < 0 then
                                         'Mora0'
                                when NVL(TZTMORA_dias,0)  between 1 and 30 then
                                         'Mora1'
                                when NVL(TZTMORA_dias,0)  between 31 and 60 then
                                         'Mora2'
                                when NVL(TZTMORA_dias,0)  between 61 and 90 then
                                        'Mora3'
                                when NVL(TZTMORA_dias,0)  between 91 and 120 then
                                        'Mora4'
                                when NVL(TZTMORA_dias,0)  between 121 and 150 then
                                        'Mora5'
                                when NVL(TZTMORA_dias,0)  between 151 and 180 then
                                        'Mora6'
                                when NVL(TZTMORA_dias,0) > 181 then
                                         'Mora7'
                                         else '0'
                                end as Tipo_Mora
                                Into vl_salida
                    from TZTMORA
                    join SZVCAMP on szvcamp_camp_alt_code=substr(TZTMORA_MATRICULA,1,2)
                    left outer join GORADID on TZTMORA_PIDM = GORADID_PIDM AND GORADID_ADID_CODE = 'NOMR'
                    where 1=1
                    And TZTMORA_PIDM = p_pidm
                    group by SZVCAMP_CAMP_CODE,TZTMORA_MATRICULA,TZTMORA_NOMBRE,TZTMORA_ESTATUS,TZTMORA_dias,GORADID_ADID_CODE;

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_mora;

Function f_Colegiatura_Vencida (p_pidm in number ) return varchar2 is

vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select count(*)
                        Into vl_salida
                    from tbraccd
                    where tbraccd_pidm = p_pidm
                    and tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          )
                    and TBRACCD_BALANCE > 0
                    And trunc (TBRACCD_EFFECTIVE_DATE) < trunc (sysdate);

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_Colegiatura_Vencida;

Function f_Primer_Fecha_Col (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct trunc (TBRACCD_EFFECTIVE_DATE)
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          )
             And trunc (a.TBRACCD_EFFECTIVE_DATE) < trunc (sysdate)
             And trunc (a.TBRACCD_EFFECTIVE_DATE) = (Select min (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                                        from tbraccd a1
                                                                                        Where  a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                        And  a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                                                        And trunc (a1.TBRACCD_EFFECTIVE_DATE) < trunc (sysdate)
                                                                                        )
                   ;


            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_Primer_Fecha_Col;

Function f_ultima_Fecha_Col (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct trunc (TBRACCD_EFFECTIVE_DATE)
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          )
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) < trunc (sysdate)
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) = (Select max (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                                        from tbraccd a1
                                                                                        Where  a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                        And  a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                                                        And trunc (a1.TBRACCD_EFFECTIVE_DATE) < trunc (sysdate)
                                                                                        )
                                                                                        ;


            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_ultima_Fecha_Col;

Function f_dias_Mora (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select TZTMORA_DIAS
                        Into vl_salida
                    from TZTMORA
                    join SZVCAMP on szvcamp_camp_alt_code=substr(TZTMORA_MATRICULA,1,2)
                    left outer join GORADID on TZTMORA_PIDM = GORADID_PIDM AND GORADID_ADID_CODE = 'NOMR'
                    where 1=1
                    and TZTMORA_pidm = p_pidm
                    --AND  trunc(TZTMORA_EFFECTIVE_DATE) BETWEEN NVL(to_date(:fechainicio, 'dd/mm/YYYY'),'01/01/1900') and NVL(to_date(:fechafin, 'dd/mm/YYYY'), SYSDATE)
                    group by SZVCAMP_CAMP_CODE,TZTMORA_MATRICULA,TZTMORA_NOMBRE,TZTMORA_ESTATUS,TZTMORA_dias,GORADID_ADID_CODE;


            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_dias_Mora;

Function f_monto_prox_Col (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct sum (nvl (tbraccd_balance,0))
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) > trunc (sysdate)
                     and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          )
                   ;


            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_monto_prox_Col;

Function f_monto_min_prox_Col (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct tbraccd_balance
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          )
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) > trunc (sysdate)
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) = (Select max (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                                        from tbraccd a1
                                                                                        Where  a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                        And  a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                                                        And trunc (a1.TBRACCD_EFFECTIVE_DATE) > trunc (sysdate)
                                                                                        )
                                                                                        ;



            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_monto_min_prox_Col;

Function f_Colegiatura_No_Vencidas (p_pidm in number ) return varchar2 is

vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select count(*)
                        Into vl_salida
                    from tbraccd
                    where tbraccd_pidm = p_pidm
                    and tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          )
                    and TBRACCD_BALANCE > 0
                    And trunc (TBRACCD_EFFECTIVE_DATE) > trunc (sysdate);

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_Colegiatura_No_Vencidas;


Function f_Fecha_Col_No_Vencidas (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct sum (tbraccd_balance)
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          )
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) > trunc (sysdate)
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) = (Select min (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                                        from tbraccd a1
                                                                                        Where  a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                        And  a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                                                        And trunc (a1.TBRACCD_EFFECTIVE_DATE) > trunc (sysdate)
                                                                                        )
                    ;


            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_Fecha_Col_No_Vencidas;


Function f_dias_Col_No_Vencidas (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct  trunc (TBRACCD_EFFECTIVE_DATE) - trunc (sysdate)
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          )
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) > trunc (sysdate)
                    And trunc (a.TBRACCD_EFFECTIVE_DATE) = (Select min (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                                        from tbraccd a1
                                                                                        Where  a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                        And  a.tbraccd_detail_code = a1.tbraccd_detail_code
                                                                                         And trunc (a1.TBRACCD_EFFECTIVE_DATE) > trunc (sysdate)
                                                                                        );

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_dias_Col_No_Vencidas;



Function f_Total_Depositos (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct sum (TBRACCD_AMOUNT)
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO  IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                          );

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_Total_Depositos;

Function f_Total_numero_Depositos (p_pidm in number ) return varchar2 is

vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct count(*)
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO  IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                          );

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_Total_numero_Depositos;

Function f_Total_incobrable (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select distinct sum (TBRACCD_AMOUNT)
                        Into vl_salida
                    from tbraccd a
                    where a.tbraccd_pidm = p_pidm
                    and a.tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO  IN ('Incobrable')
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                          );

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_Total_incobrable;


Function f_descuento (p_pidm in number ) return varchar2 is
vl_salida varchar2(5000):= 'EXITO';

Begin
            Begin

                    select substr (a.TBBESTU_EXEMPTION_CODE, 4,3)
                        Into vl_salida
                    from TBBESTU a
                    where a.TBBESTU_PIDM = p_pidm
                    and a.TBBESTU_DEL_IND ='Y'
                    And a.TBBESTU_TERM_CODE = (select max (a1.TBBESTU_TERM_CODE)
                                                                    from TBBESTU a1
                                                                    Where a.TBBESTU_PIDM = a1.TBBESTU_PIDM
                                                                    And a.TBBESTU_DEL_IND = a1.TBBESTU_DEL_IND
                                                                    );

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_descuento;

Function  f_rolado_periodo  (vl_campus_origen in varchar2, vl_campus_dest in varchar2 ) return varchar2 is

vl_existe number :=0;
vl_numero number :=0;
vl_resultado varchar2(500) := 'Exito';
Begin

       Begin
                Select count (*)
                    Into vl_existe
                from stvterm
                where STVTERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6);
       Exception
            When Others then
                vl_existe :=0;
       End;

        If vl_existe >= 1 then
            -- dbms_output.put_line('mensaje:'||'Ya existe el Periodo stvterm');
           vl_numero := vl_numero +1;
     --        dbms_output.put_line('Numero1*:'||vl_numero);
        Else
                vl_existe :=0;
                Begin
              --   dbms_output.put_line('Periodo:'|| vl_campus_dest ||substr (vl_campus_origen,3,6));

                        Insert into stvterm
                        Select  vl_campus_dest ||substr (vl_campus_origen,3,6), a.STVTERM_DESC, a.STVTERM_START_DATE, a.STVTERM_END_DATE, a.STVTERM_FA_PROC_YR, a.STVTERM_ACTIVITY_DATE,
                                   a.STVTERM_FA_TERM,  a.STVTERM_FA_PERIOD, a.STVTERM_FA_END_PERIOD, a.STVTERM_ACYR_CODE, a.STVTERM_HOUSING_START_DATE, a.STVTERM_HOUSING_END_DATE,
                                   a.STVTERM_SYSTEM_REQ_IND, a.STVTERM_TRMT_CODE, a.STVTERM_FA_SUMMER_IND, null, null, user, 'SZFROLA', null
                        from stvterm a
                        where a.STVTERM_CODE = vl_campus_origen;
                        Commit;
                Exception
                    When others then
                       vl_resultado := 'Error stvterm '||sqlerrm;
                     --   dbms_output.put_line('mensaje stvterm:'||sqlerrm);
                End;

        End if;

       Begin
                Select count(*)
                    Into vl_existe
                from STVCHRT
                where STVCHRT_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6);
       Exception
            When Others then
                vl_existe:=0;
       End;

   --    dbms_output.put_line('Numeroxx*:'||vl_existe||'*'||vl_resultado);

        If vl_existe >= 1 then
        --     dbms_output.put_line('mensaje:'||'Ya existe el Periodo STVCHRT');
                vl_numero := vl_numero +1;
           --     dbms_output.put_line('Numero2*:'||vl_numero);
        Elsif vl_existe =  0 and vl_resultado = 'Exito' then
                vl_existe :=0 ;

                Begin
                        Insert into STVCHRT
                        select vl_campus_dest ||substr (vl_campus_origen,3,6), a.STVCHRT_DESC, a.STVCHRT_TERM_CODE_START, a.STVCHRT_TERM_CODE_END, a.STVCHRT_DLEV_CODE,
                                  a.STVCHRT_ACTIVITY_DATE, a.STVCHRT_RIGHT_IND, null, a.STVCHRT_VERSION, user, 'SZFROLA', a.STVCHRT_VPDI_CODE
                        from STVCHRT a
                        where a.STVCHRT_CODE = vl_campus_origen;
                    --    commit;
                Exception
                    When others then
                       -- dbms_output.put_line('mensaje STVCHRT:'||sqlerrm);
                        vl_resultado := 'Error STVCHRT '||sqlerrm;
                End;

        End if;

        Begin
                Select count(*)
                    Into vl_existe
                from SOBTERM
                where SOBTERM_TERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6);
        Exception
            When Others then
                vl_existe:=0;
        End;

        If vl_existe >= 1 then
             --dbms_output.put_line('mensaje:'||'Ya existe el Periodo SOBTERM');
                vl_numero := vl_numero +1;
            --    dbms_output.put_line('Numero3*:'||vl_numero);
        Elsif vl_existe =  0 and vl_resultado = 'Exito' then
                vl_existe :=0;

            --     dbms_output.put_line ('PPeriodo '||vl_campus_dest ||substr (vl_campus_origen,3,6));

                Begin
                        Insert into SOBTERM
                        select vl_campus_dest ||substr (vl_campus_origen,3,6),
                        a.SOBTERM_CRN_ONEUP,
                        a.SOBTERM_REG_ALLOWED,
                        a.SOBTERM_READM_REQ,
                        a.SOBTERM_FEE_ASSESSMENT,
                        a.SOBTERM_FEE_ASSESSMNT_EFF_DATE,
                        a.SOBTERM_DUPL_SEVERITY,
                        a.SOBTERM_LINK_SEVERITY,
                        a.SOBTERM_PREQ_SEVERITY,
                        a.SOBTERM_CORQ_SEVERITY,
                        a.SOBTERM_TIME_SEVERITY,
                        a.SOBTERM_CAPC_SEVERITY,
                        a.SOBTERM_LEVL_SEVERITY,
                        a.SOBTERM_COLL_SEVERITY,
                        a.SOBTERM_MAJR_SEVERITY,
                        a.SOBTERM_CLAS_SEVERITY,
                        a.SOBTERM_APPR_SEVERITY,
                        a.SOBTERM_MAXH_SEVERITY,
                        a.SOBTERM_HOLD_SEVERITY,
                        a.SOBTERM_ACTIVITY_DATE,
                        a.SOBTERM_HOLD,
                        a.SOBTERM_REFUND_IND,
                        a.SOBTERM_BYCRN_IND,
                        a.SOBTERM_REPT_SEVERITY,
                        a.SOBTERM_RPTH_SEVERITY,
                        a.SOBTERM_TEST_SEVERITY,
                        a.SOBTERM_CAMP_SEVERITY,
                        a.SOBTERM_FEE_ASSESS_VR,
                        a.SOBTERM_PRINT_BILL_VR,
                        a.SOBTERM_TMST_CALC_IND,
                        a.SOBTERM_INCL_ATTMPT_HRS_IND,
                        a.SOBTERM_CRED_WEB_UPD_IND,
                        a.SOBTERM_GMOD_WEB_UPD_IND,
                        a.SOBTERM_LEVL_WEB_UPD_IND,
                        a.SOBTERM_CLOSECT_WEB_DISP_IND,
                        a.SOBTERM_MAILER_WEB_IND,
                        a.SOBTERM_SCHD_WEB_SEARCH_IND,
                        a.SOBTERM_CAMP_WEB_SEARCH_IND,
                        a.SOBTERM_SESS_WEB_SEARCH_IND,
                        a.SOBTERM_INSTR_WEB_SEARCH_IND,
                        a.SOBTERM_FACSCHD_WEB_DISP_IND,
                        a.SOBTERM_CLASLST_WEB_DISP_IND,
                        a.SOBTERM_OVERAPP_WEB_UPD_IND,
                        a.SOBTERM_ADD_DRP_WEB_UPD_IND,
                        a.SOBTERM_DEGREE_SEVERITY,
                        a.SOBTERM_PROGRAM_SEVERITY,
                        a.SOBTERM_INPROGRESS_USAGE_IND,
                        a.SOBTERM_GRADE_DETAIL_WEB_IND,
                        a.SOBTERM_MIDTERM_WEB_IND,
                        a.SOBTERM_PROFILE_SEND_IND,
                        a.SOBTERM_CUTOFF_DATE,
                        a.SOBTERM_TIV_DATE_SOURCE,
                        a.SOBTERM_WEB_CAPP_TERM_IND,
                        a.SOBTERM_WEB_CAPP_CATLG_IND,
                        a.SOBTERM_ATTR_WEB_SEARCH_IND,
                        a.SOBTERM_LEVL_WEB_SEARCH_IND,
                        a.SOBTERM_INSM_WEB_SEARCH_IND,
                        a.SOBTERM_LS_TITLE_WEBS_DISP_IND,
                        a.SOBTERM_LS_DESC_WEBS_DISP_IND,
                        a.SOBTERM_DURATION_WEB_SRCH_IND,
                        a.SOBTERM_LEVL_WEB_CATL_SRCH_IND,
                        a.SOBTERM_STYP_WEB_CATL_SRCH_IND,
                        a.SOBTERM_COLL_WEB_CATL_SRCH_IND,
                        a.SOBTERM_DIV_WEB_CATL_SRCH_IND,
                        a.SOBTERM_DEPT_WEB_CATL_SRCH_IND,
                        a.SOBTERM_PROG_ATT_WEBC_SRCH_IND,
                        a.SOBTERM_LC_TITLE_WEBC_DISP_IND,
                        a.SOBTERM_LC_DESC_WEBC_DISP_IND,
                        a.SOBTERM_DYNAMIC_SCHED_TERM_IND,
                        a.SOBTERM_DATA_ORIGIN,
                        a.SOBTERM_USER_ID,
                        a.SOBTERM_ASSESS_SWAP_IND,
                        a.SOBTERM_ASSESS_REV_NRF_IND,
                        a.SOBTERM_ASSESS_REG_GRACE_IND,
                        a.SOBTERM_MINH_SEVERITY,
                        a.SOBTERM_DEPT_SEVERITY,
                        a.SOBTERM_ATTS_SEVERITY,
                        a.SOBTERM_CHRT_SEVERITY,
                        a.SOBTERM_MEXC_SEVERITY,
                        a.SOBTERM_STUDY_PATH_IND,
                        a.SOBTERM_FUTURE_REPEAT_IND,
                        a.SOBTERM_SP_WEB_UPD_IND,
                        a.SOBTERM_SECTIONFEE_IND,
                        a.SOBTERM_MEETING_TIME_SRC_CDE,
                        a.SOBTERM_PLAN_TERM_OPEN_CDE,
                        a.SOBTERM_SEC_ALLOWED_PLAN_CDE,
                        a.SOBTERM_MAX_PLANS,
                        a.SOBTERM_DEG_AUDIT_PLAN_CDE,
                        a.SOBTERM_PLAN_DA_REG_CDE,
                        a.SOBTERM_PLAN_REG_CDE,
                        a.SOBTERM_COND_ADD_DROP_CDE,
                        a.SOBTERM_AUTO_DROP_CDE,
                        a.SOBTERM_ADMIN_DROP_CDE,
                        a.SOBTERM_DROP_LAST_CLASS_CDE,
                        a.SOBTERM_FINAL_GRDE_PUB_DATE,
                        a.SOBTERM_DET_GRDE_PUB_DATE,
                        a.SOBTERM_REAS_GRDE_PUB_DATE,
                        a.SOBTERM_REAS_DET_GRD_PB_DATE,
                        a.SOBTERM_REGISTRATION_MODEL_CDE,
                        null,
                        a.SOBTERM_VERSION,
                        a.SOBTERM_VPDI_CODE
                        from SOBTERM a
                        where a.SOBTERM_TERM_CODE = vl_campus_origen;
                        commit;
                Exception
                    When others then
                        --dbms_output.put_line('mensaje SOBTERM:'||sqlerrm);
                         vl_resultado := 'Error SOBTERM '||sqlerrm;
                End;

        End if;


        Begin
                Select count(*)
                    Into vl_existe
                from SOBPTRM
                where SOBPTRM_TERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6);
        Exception
            When Others then
                vl_existe:=0;
        End;

        If vl_existe >= 1 then
             --dbms_output.put_line('mensaje:'||'Ya existe el Periodo SOBPTRM');
            vl_numero := vl_numero +1;
          --  dbms_output.put_line('Numero4*:'||vl_numero);
        Elsif vl_existe =  0 and vl_resultado = 'Exito' then
                vl_existe :=0;

           --      dbms_output.put_line ('PPeriodo '||vl_campus_dest ||substr (vl_campus_origen,3,6));

                Begin
                        Insert into SOBPTRM
                        select vl_campus_dest ||substr (vl_campus_origen,3,6),
                                    a.SOBPTRM_PTRM_CODE,
                                    a.SOBPTRM_DESC,
                                    a.SOBPTRM_START_DATE,
                                    a.SOBPTRM_END_DATE,
                                    a.SOBPTRM_REG_ALLOWED,
                                    a.SOBPTRM_WEEKS,
                                    a.SOBPTRM_CENSUS_DATE,
                                    a.SOBPTRM_ACTIVITY_DATE,
                                    a.SOBPTRM_SECT_OVER_IND,
                                    a.SOBPTRM_CENSUS_2_DATE,
                                    a.SOBPTRM_MGRD_WEB_UPD_IND,
                                    a.SOBPTRM_FGRD_WEB_UPD_IND,
                                    a.SOBPTRM_WAITLST_WEB_DISP_IND,
                                    a.SOBPTRM_INCOMPLETE_EXT_DATE,
                                    a.SOBPTRM_FINAL_GRDE_PUB_DATE,
                                    a.SOBPTRM_DET_GRDE_PUB_DATE,
                                    a.SOBPTRM_REAS_GRDE_PUB_DATE,
                                    a.SOBPTRM_REAS_DET_GRDE_PUB_DATE,
                                    a.SOBPTRM_SCORE_OPEN_DATE,
                                    a.SOBPTRM_SCORE_CUTOFF_DATE,
                                    a.SOBPTRM_REAS_SCORE_OPEN_DATE,
                                    a.SOBPTRM_REAS_SCORE_CUTOFF_DATE,
                                    null,
                                    a.SOBPTRM_VERSION,
                                    user,
                                    'SZFROLA',
                                    a.SOBPTRM_VPDI_CODE
                        from SOBPTRM a
                        where a.SOBPTRM_TERM_CODE = vl_campus_origen;
                     --   commit;
                Exception
                    When others then
                   --     dbms_output.put_line('mensaje SOBPTRM:'||sqlerrm);
                        vl_resultado := 'Error SOBPTRM '||sqlerrm;
                End;

        End if;

        Commit;

        If vl_numero = 4 then
                vl_resultado :='Este periodo ya fue Rolado, previamente ';
        End if;
        Return (vl_resultado);

End f_rolado_periodo;

Function   f_fecha_ultima (p_pidm in number,  p_sp in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



        select   distinct  max (x.fecha_inicio) --, rownum
            into   vl_salida
        from (
        SELECT DISTINCT
                   max (SSBSECT_PTRM_START_DATE) fecha_inicio--, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                FROM SFRSTCR a, SSBSECT b
               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                     And  a.SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                     AND a.SFRSTCR_RSTS_CODE = 'RE'
                     And  substr (a.SFRSTCR_TERM_CODE,5,1) not in ('9')
                     And  b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB  not in ( 'IND00001','UTEL001','L1HP401', 'L1HB401','M1HB401' )
                    AND b.SSBSECT_PTRM_START_DATE =
                                                                                (SELECT max (b1.SSBSECT_PTRM_START_DATE)
                                                                                   FROM SSBSECT b1
                                                                                  WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                                                        AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                                                                        And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB = b1.SSBSECT_SUBJ_CODE||b1.SSBSECT_CRSE_NUMB)
              and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1 desc
            )  x
            where rownum = 1
          order by 1 asc;

    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida := '01/01/1900';
 return vl_salida;
END f_fecha_ultima;

Function f_documento_nivel (p_pidm in number, p_nivel in varchar2, p_tipo in varchar2) return varchar2  is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


BEGIN

            Begin

                        select  distinct SARCHKL_CKST_CODE Documento
                        into vl_salida
                        from SARCHKL
                        join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_LEVL_CODE = p_nivel
                                                                                               and SARADAP_APPL_NO = SARCHKL_APPL_NO
                        join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
                        where SARCHKL_PIDM = p_pidm
                        And SARCHKL_ADMR_CODE = p_tipo;

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_documento_nivel;


Function  f_rolado_periodo  (vl_campus_origen in varchar2, vl_campus_dest in varchar2, vl_campus_letra in varchar2, vl_campus_ori_letra in varchar2, vl_nivel in varchar2 ) return varchar2 is

vl_existe number :=0;
vl_numero number :=0;
vl_resultado varchar2(500) := 'Exito';
Begin

       Begin
                Select count (*)
                    Into vl_existe
                from stvterm
                where STVTERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6);
       Exception
            When Others then
                vl_existe :=0;
       End;

        If vl_existe >= 1 then
            -- dbms_output.put_line('mensaje:'||'Ya existe el Periodo stvterm');
           vl_numero := vl_numero +1;
     --        dbms_output.put_line('Numero1*:'||vl_numero);
        Else
                vl_existe :=0;
                Begin
              --   dbms_output.put_line('Periodo:'|| vl_campus_dest ||substr (vl_campus_origen,3,6));

                        Insert into stvterm
                        Select  vl_campus_dest ||substr (vl_campus_origen,3,6), a.STVTERM_DESC, a.STVTERM_START_DATE, a.STVTERM_END_DATE, a.STVTERM_FA_PROC_YR, a.STVTERM_ACTIVITY_DATE,
                                   a.STVTERM_FA_TERM,  a.STVTERM_FA_PERIOD, a.STVTERM_FA_END_PERIOD, a.STVTERM_ACYR_CODE, a.STVTERM_HOUSING_START_DATE, a.STVTERM_HOUSING_END_DATE,
                                   a.STVTERM_SYSTEM_REQ_IND, a.STVTERM_TRMT_CODE, a.STVTERM_FA_SUMMER_IND, null, null, user, 'SZFROLA', null
                        from stvterm a
                        where a.STVTERM_CODE = vl_campus_origen;
                        Commit;
                Exception
                    When others then
                       vl_resultado := 'Error stvterm '||sqlerrm;
                     --   dbms_output.put_line('mensaje stvterm:'||sqlerrm);
                End;

        End if;

       Begin
                Select count(*)
                    Into vl_existe
                from STVCHRT
                where STVCHRT_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6);
       Exception
            When Others then
                vl_existe:=0;
       End;

   --    dbms_output.put_line('Numeroxx*:'||vl_existe||'*'||vl_resultado);

        If vl_existe >= 1 then
        --     dbms_output.put_line('mensaje:'||'Ya existe el Periodo STVCHRT');
                vl_numero := vl_numero +1;
           --     dbms_output.put_line('Numero2*:'||vl_numero);
        Elsif vl_existe =  0 and vl_resultado = 'Exito' then
                vl_existe :=0 ;

                Begin
                        Insert into STVCHRT
                        select vl_campus_dest ||substr (vl_campus_origen,3,6), a.STVCHRT_DESC, vl_campus_dest ||substr (vl_campus_origen,3,6), a.STVCHRT_TERM_CODE_END, a.STVCHRT_DLEV_CODE,
                                  a.STVCHRT_ACTIVITY_DATE, a.STVCHRT_RIGHT_IND, null, a.STVCHRT_VERSION, user, 'SZFROLA', a.STVCHRT_VPDI_CODE
                        from STVCHRT a
                        where a.STVCHRT_CODE = vl_campus_origen;
                    --    commit;
                Exception
                    When others then
                       -- dbms_output.put_line('mensaje STVCHRT:'||sqlerrm);
                        vl_resultado := 'Error STVCHRT '||sqlerrm;
                End;

        End if;

        Begin
                Select count(*)
                    Into vl_existe
                from SOBTERM
                where SOBTERM_TERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6);
        Exception
            When Others then
                vl_existe:=0;
        End;

        If vl_existe >= 1 then
             --dbms_output.put_line('mensaje:'||'Ya existe el Periodo SOBTERM');
                vl_numero := vl_numero +1;
            --    dbms_output.put_line('Numero3*:'||vl_numero);
        Elsif vl_existe =  0 and vl_resultado = 'Exito' then
                vl_existe :=0;

            --     dbms_output.put_line ('PPeriodo '||vl_campus_dest ||substr (vl_campus_origen,3,6));

                Begin
                        Insert into SOBTERM
                        select vl_campus_dest ||substr (vl_campus_origen,3,6),
                        a.SOBTERM_CRN_ONEUP,
                        a.SOBTERM_REG_ALLOWED,
                        a.SOBTERM_READM_REQ,
                        a.SOBTERM_FEE_ASSESSMENT,
                        a.SOBTERM_FEE_ASSESSMNT_EFF_DATE,
                        a.SOBTERM_DUPL_SEVERITY,
                        a.SOBTERM_LINK_SEVERITY,
                        a.SOBTERM_PREQ_SEVERITY,
                        a.SOBTERM_CORQ_SEVERITY,
                        a.SOBTERM_TIME_SEVERITY,
                        a.SOBTERM_CAPC_SEVERITY,
                        a.SOBTERM_LEVL_SEVERITY,
                        a.SOBTERM_COLL_SEVERITY,
                        a.SOBTERM_MAJR_SEVERITY,
                        a.SOBTERM_CLAS_SEVERITY,
                        a.SOBTERM_APPR_SEVERITY,
                        a.SOBTERM_MAXH_SEVERITY,
                        a.SOBTERM_HOLD_SEVERITY,
                        a.SOBTERM_ACTIVITY_DATE,
                        a.SOBTERM_HOLD,
                        a.SOBTERM_REFUND_IND,
                        a.SOBTERM_BYCRN_IND,
                        a.SOBTERM_REPT_SEVERITY,
                        a.SOBTERM_RPTH_SEVERITY,
                        a.SOBTERM_TEST_SEVERITY,
                        a.SOBTERM_CAMP_SEVERITY,
                        a.SOBTERM_FEE_ASSESS_VR,
                        a.SOBTERM_PRINT_BILL_VR,
                        a.SOBTERM_TMST_CALC_IND,
                        a.SOBTERM_INCL_ATTMPT_HRS_IND,
                        a.SOBTERM_CRED_WEB_UPD_IND,
                        a.SOBTERM_GMOD_WEB_UPD_IND,
                        a.SOBTERM_LEVL_WEB_UPD_IND,
                        a.SOBTERM_CLOSECT_WEB_DISP_IND,
                        a.SOBTERM_MAILER_WEB_IND,
                        a.SOBTERM_SCHD_WEB_SEARCH_IND,
                        a.SOBTERM_CAMP_WEB_SEARCH_IND,
                        a.SOBTERM_SESS_WEB_SEARCH_IND,
                        a.SOBTERM_INSTR_WEB_SEARCH_IND,
                        a.SOBTERM_FACSCHD_WEB_DISP_IND,
                        a.SOBTERM_CLASLST_WEB_DISP_IND,
                        a.SOBTERM_OVERAPP_WEB_UPD_IND,
                        a.SOBTERM_ADD_DRP_WEB_UPD_IND,
                        a.SOBTERM_DEGREE_SEVERITY,
                        a.SOBTERM_PROGRAM_SEVERITY,
                        a.SOBTERM_INPROGRESS_USAGE_IND,
                        a.SOBTERM_GRADE_DETAIL_WEB_IND,
                        a.SOBTERM_MIDTERM_WEB_IND,
                        a.SOBTERM_PROFILE_SEND_IND,
                        a.SOBTERM_CUTOFF_DATE,
                        a.SOBTERM_TIV_DATE_SOURCE,
                        a.SOBTERM_WEB_CAPP_TERM_IND,
                        a.SOBTERM_WEB_CAPP_CATLG_IND,
                        a.SOBTERM_ATTR_WEB_SEARCH_IND,
                        a.SOBTERM_LEVL_WEB_SEARCH_IND,
                        a.SOBTERM_INSM_WEB_SEARCH_IND,
                        a.SOBTERM_LS_TITLE_WEBS_DISP_IND,
                        a.SOBTERM_LS_DESC_WEBS_DISP_IND,
                        a.SOBTERM_DURATION_WEB_SRCH_IND,
                        a.SOBTERM_LEVL_WEB_CATL_SRCH_IND,
                        a.SOBTERM_STYP_WEB_CATL_SRCH_IND,
                        a.SOBTERM_COLL_WEB_CATL_SRCH_IND,
                        a.SOBTERM_DIV_WEB_CATL_SRCH_IND,
                        a.SOBTERM_DEPT_WEB_CATL_SRCH_IND,
                        a.SOBTERM_PROG_ATT_WEBC_SRCH_IND,
                        a.SOBTERM_LC_TITLE_WEBC_DISP_IND,
                        a.SOBTERM_LC_DESC_WEBC_DISP_IND,
                        a.SOBTERM_DYNAMIC_SCHED_TERM_IND,
                        a.SOBTERM_DATA_ORIGIN,
                        a.SOBTERM_USER_ID,
                        a.SOBTERM_ASSESS_SWAP_IND,
                        a.SOBTERM_ASSESS_REV_NRF_IND,
                        a.SOBTERM_ASSESS_REG_GRACE_IND,
                        a.SOBTERM_MINH_SEVERITY,
                        a.SOBTERM_DEPT_SEVERITY,
                        a.SOBTERM_ATTS_SEVERITY,
                        a.SOBTERM_CHRT_SEVERITY,
                        a.SOBTERM_MEXC_SEVERITY,
                        a.SOBTERM_STUDY_PATH_IND,
                        a.SOBTERM_FUTURE_REPEAT_IND,
                        a.SOBTERM_SP_WEB_UPD_IND,
                        a.SOBTERM_SECTIONFEE_IND,
                        a.SOBTERM_MEETING_TIME_SRC_CDE,
                        a.SOBTERM_PLAN_TERM_OPEN_CDE,
                        a.SOBTERM_SEC_ALLOWED_PLAN_CDE,
                        a.SOBTERM_MAX_PLANS,
                        a.SOBTERM_DEG_AUDIT_PLAN_CDE,
                        a.SOBTERM_PLAN_DA_REG_CDE,
                        a.SOBTERM_PLAN_REG_CDE,
                        a.SOBTERM_COND_ADD_DROP_CDE,
                        a.SOBTERM_AUTO_DROP_CDE,
                        a.SOBTERM_ADMIN_DROP_CDE,
                        a.SOBTERM_DROP_LAST_CLASS_CDE,
                        a.SOBTERM_FINAL_GRDE_PUB_DATE,
                        a.SOBTERM_DET_GRDE_PUB_DATE,
                        a.SOBTERM_REAS_GRDE_PUB_DATE,
                        a.SOBTERM_REAS_DET_GRD_PB_DATE,
                        a.SOBTERM_REGISTRATION_MODEL_CDE,
                        null,
                        a.SOBTERM_VERSION,
                        a.SOBTERM_VPDI_CODE
                        from SOBTERM a
                        where a.SOBTERM_TERM_CODE = vl_campus_origen;
                        commit;
                Exception
                    When others then
                        --dbms_output.put_line('mensaje SOBTERM:'||sqlerrm);
                         vl_resultado := 'Error SOBTERM '||sqlerrm;
                End;

        End if;


        Begin
                Select count(*)
                    Into vl_existe
                from SOBPTRM
                where SOBPTRM_TERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6);
        Exception
            When Others then
                vl_existe:=0;
        End;

        If vl_existe >= 1 then
             --dbms_output.put_line('mensaje:'||'Ya existe el Periodo SOBPTRM');
            vl_numero := vl_numero +1;
          --  dbms_output.put_line('Numero4*:'||vl_numero);
        Elsif vl_existe =  0 and vl_resultado = 'Exito' then
                vl_existe :=0;

           --      dbms_output.put_line ('PPeriodo '||vl_campus_dest ||substr (vl_campus_origen,3,6));

                Begin
                        Insert into SOBPTRM
                        select vl_campus_dest ||substr (vl_campus_origen,3,6),
                                    a.SOBPTRM_PTRM_CODE,
                                    a.SOBPTRM_DESC,
                                    a.SOBPTRM_START_DATE,
                                    a.SOBPTRM_END_DATE,
                                    a.SOBPTRM_REG_ALLOWED,
                                    a.SOBPTRM_WEEKS,
                                    a.SOBPTRM_CENSUS_DATE,
                                    a.SOBPTRM_ACTIVITY_DATE,
                                    a.SOBPTRM_SECT_OVER_IND,
                                    a.SOBPTRM_CENSUS_2_DATE,
                                    a.SOBPTRM_MGRD_WEB_UPD_IND,
                                    a.SOBPTRM_FGRD_WEB_UPD_IND,
                                    a.SOBPTRM_WAITLST_WEB_DISP_IND,
                                    a.SOBPTRM_INCOMPLETE_EXT_DATE,
                                    a.SOBPTRM_FINAL_GRDE_PUB_DATE,
                                    a.SOBPTRM_DET_GRDE_PUB_DATE,
                                    a.SOBPTRM_REAS_GRDE_PUB_DATE,
                                    a.SOBPTRM_REAS_DET_GRDE_PUB_DATE,
                                    a.SOBPTRM_SCORE_OPEN_DATE,
                                    a.SOBPTRM_SCORE_CUTOFF_DATE,
                                    a.SOBPTRM_REAS_SCORE_OPEN_DATE,
                                    a.SOBPTRM_REAS_SCORE_CUTOFF_DATE,
                                    null,
                                    a.SOBPTRM_VERSION,
                                    user,
                                    'SZFROLA',
                                    a.SOBPTRM_VPDI_CODE
                        from SOBPTRM a
                        where a.SOBPTRM_TERM_CODE = vl_campus_origen;
                     --   commit;
                Exception
                    When others then
                   --     dbms_output.put_line('mensaje SOBPTRM:'||sqlerrm);
                        vl_resultado := 'Error SOBPTRM '||sqlerrm;
                End;

        End if;

        Commit;


        Begin

                Insert into SZTPTRM
                   select distinct SZTPRCO_CAMP_CODE_HIJO,
                            SZTPTRM_LEVL_CODE,
                            vl_campus_dest ||substr (vl_campus_origen,3,6),
                            SZTPTRM_PTRM_CODE,
                            SZTPRCO_PRGHIJO,
                            SZTPTRM_ACTIVITY_DATE,
                            SZTPTRM_USER_ID,
                            SZTPTRM_ADICIONAL,
                            SZTPTRM_PROPEDEUTICO,
                            SZTPTRM_VISIBLE,
                            SZTPTRM_MATERIA,
                            SZTPTRM_NO_PAGO
                    from SZTPTRM
                    join SZTPRCO on SZTPRCO_CAMP_CODE = SZTPTRM_CAMP_CODE and SZTPRCO_PROGRAM = SZTPTRM_PROGRAM AND SZTPRCO_CAMP_CODE_HIJO  = vl_campus_letra
                    join SOBPTRM on SOBPTRM_TERM_CODE = vl_campus_dest ||substr (vl_campus_origen,3,6)
                    where 1= 1
                    and SZTPTRM_CAMP_CODE = vl_campus_ori_letra
                    and SZTPTRM_TERM_CODE = vl_campus_origen
                    And SZTPTRM_LEVL_CODE  = vl_nivel ;
                    commit;

        Exception
            When Others then
            null;
        End;


 /*
        Begin

                For c in (

                            select distinct a.SOBCURR_CAMP_CODE Campus, a.SOBCURR_LEVL_CODE Nivel , a.SOBCURR_PROGRAM Programa, b.SZTDTEC_MOD_TYPE Tipo
                            from SOBCURR a
                            join SZTDTEC b on b.SZTDTEC_CAMP_CODE = a.SOBCURR_CAMP_CODE and b.SZTDTEC_PROGRAM = a.SOBCURR_PROGRAM
                                    And b.SZTDTEC_TERM_CODE = (select max (b1.SZTDTEC_TERM_CODE)
                                                                                        from SZTDTEC b1
                                                                                        Where b.SZTDTEC_CAMP_CODE = b1.SZTDTEC_CAMP_CODE
                                                                                        And b.SZTDTEC_PROGRAM = b1.SZTDTEC_PROGRAM)
                            where a.SOBCURR_CAMP_CODE = vl_campus_letra

                 ) loop

                          If c.nivel = 'LI' then

                                For c1 in (

                                            select SOBPTRM_TERM_CODE Periodo, SOBPTRM_PTRM_CODE Pperido
                                            from SOBPTRM
                                            where SOBPTRM_TERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6)
                                            And SOBPTRM_PTRM_CODE not in ('1')
                                            And substr (SOBPTRM_PTRM_CODE,1,1) ='L'

                                        ) loop

                                                    Begin
                                                                Insert into SZTPTRM values ( c.campus,
                                                                                                           c.nivel,
                                                                                                           c1.Periodo,
                                                                                                           c1.pperido,
                                                                                                           c.Programa,
                                                                                                           sysdate,
                                                                                                           user,
                                                                                                           3,
                                                                                                           null,
                                                                                                            case when c1.pperido = 'L2A' then null else 1 end ,
                                                                                                           NULL);
                                                    Exception
                                                    When Others then
                                                        null;
                                                    End;

                                       End  Loop;

                          ElsIf c.nivel = 'MA' then

                                For c1 in (

                                            select SOBPTRM_TERM_CODE Periodo, SOBPTRM_PTRM_CODE Pperido
                                            from SOBPTRM
                                            where SOBPTRM_TERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6)
                                            And SOBPTRM_PTRM_CODE not in ('1')
                                            And substr (SOBPTRM_PTRM_CODE,1,1) ='M'

                                        ) loop

                                                    Begin
                                                                Insert into SZTPTRM values ( c.campus,
                                                                                                           c.nivel,
                                                                                                           c1.Periodo,
                                                                                                           c1.pperido,
                                                                                                           c.Programa,
                                                                                                           sysdate,
                                                                                                           user,
                                                                                                           3,
                                                                                                           case when c1.pperido IN ( 'M0C', 'M0A' ) And c.tipo = 'S' then 1 else NULL end ,
                                                                                                          1,
                                                                                                           case when c1.pperido IN ( 'M0C', 'M0A' ) And c.tipo = 'S' then 'M1HB401' else NULL end );
                                                    Exception
                                                    When Others then
                                                        null;
                                                    End;

                                       End  Loop;

                          ElsIf c.nivel = 'DO' then

                                For c1 in (

                                            select SOBPTRM_TERM_CODE Periodo, SOBPTRM_PTRM_CODE Pperido
                                            from SOBPTRM
                                            where SOBPTRM_TERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6)
                                            And SOBPTRM_PTRM_CODE not in ('1')
                                            And substr (SOBPTRM_PTRM_CODE,1,1) ='D'

                                        ) loop

                                                    Begin
                                                                Insert into SZTPTRM values ( c.campus,
                                                                                                           c.nivel,
                                                                                                           c1.Periodo,
                                                                                                           c1.pperido,
                                                                                                           c.Programa,
                                                                                                           sysdate,
                                                                                                           user,
                                                                                                           3,
                                                                                                           NULL,
                                                                                                          1,
                                                                                                           NULL);
                                                    Exception
                                                    When Others then
                                                        null;
                                                    End;

                                       End  Loop;

                          ElsIf c.nivel = 'MS' then

                                For c1 in (

                                            select SOBPTRM_TERM_CODE Periodo, SOBPTRM_PTRM_CODE Pperido
                                            from SOBPTRM
                                            where SOBPTRM_TERM_CODE =  vl_campus_dest ||substr (vl_campus_origen,3,6)
                                            And SOBPTRM_PTRM_CODE not in ('1')
                                            And substr (SOBPTRM_PTRM_CODE,1,1) ='A'

                                        ) loop

                                                    Begin
                                                                Insert into SZTPTRM values ( c.campus,
                                                                                                           c.nivel,
                                                                                                           c1.Periodo,
                                                                                                           c1.pperido,
                                                                                                           c.Programa,
                                                                                                           sysdate,
                                                                                                           user,
                                                                                                           3,
                                                                                                            case when c1.pperido IN ( 'M0C', 'M0A' ) And c.tipo = 'S' then 1 else NULL end ,
                                                                                                          1,
                                                                                                           case when c1.pperido IN ( 'M0C', 'M0A' ) And c.tipo = 'S' then 'M1HB401' else NULL end );
                                                    Exception
                                                    When Others then
                                                        null;
                                                    End;

                                       End  Loop;


                          End if;
                          commit;

                 end Loop;


        End;
        */

        If vl_numero = 4 then
                vl_resultado :='Este periodo ya fue Rolado, previamente, se complementa las fechas de SZFPART ';
        End if;
        Return (vl_resultado);

End f_rolado_periodo;

function f_avcu_out_titulo(pidm number,usu_siu varchar2) RETURN pkg_utilerias.avcu_out_tit



           AS
                avance_n_out_tit pkg_utilerias.avcu_out_tit;
                prog varchar2(50):= null;
                 vl_campus varchar2(50):= null;
                 vl_nivel  varchar2(50):= null;
                 vl_pidm number:= null;

                       BEGIN
                       delete from avance_n
                       where protocolo=9999
                       and USUARIO_SIU=usu_siu;
                       commit;

                       vl_pidm:= pidm;

                        Begin

                              --  dbms_output.put_line('salida uno : '|| pidm);
                           For c1 in (
                                            select distinct PROGRAMA, CAMPUS, NIVEL
                                            from tztprog a
                                            where a.pidm = vl_pidm
                                            And a.estatus not in ('CP')
                                            And a.sp in  (select max (a1.sp)
                                                                from tztprog a1
                                                                Where a.pidm = a1.pidm
                                                               --  And a.estatus = a1.estatus
                                                                )

                            ) loop

                                    prog := c1.programa;
                                    vl_campus := c1.campus;
                                    vl_nivel := c1.nivel;

                            End Loop;

                               dbms_output.put_line('salida Into : '|| prog||'*'|| vl_campus||'*'|| vl_nivel);

                        Exception
                            When Others then
                                prog:= null;
                                vl_campus:= null;
                                vl_nivel:= null;
                              --    dbms_output.put_line('salida error  : '||sqlerrm);
                        End;


              insert into avance_n
                    select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                    case
                           when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+3
                           when smralib_area_desc like 'Taller%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                           else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                    end  per,  ----
                    smrpaap_area area,   ----
                                                  case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                      case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('11') then substr(smrpaap_area,9,2)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('12') then substr(smrpaap_area,9,2)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             else smralib_area_desc
                                                       end
                                                    else smralib_area_desc
                                                    end
                                                     nombre_area,  ---
                                    smrarul_subj_code||smrarul_crse_numb_low materia, ----
                                    scrsyln_long_course_title nombre_mat, ----
                                     case when k.calif in ('NA','NP','AC') then '1'
                                            when k.st_mat='EC' then '101'
                                     else  k.calif
                                     end calif, ---
                                     nvl(k.st_mat,'PC'),  ---
                                     smracaa_rule regla,   ---
                                     case when k.st_mat='EC' then null
                                       else k.calif
                                     end  origen,
                                     k.fecha, ---
                                     pidm ,
                                     usu_siu
                                    from smrpaap s, smrarul, sgbstdn y, sorlcur so, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
                                    (
                                               select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                 w.shrtckn_subj_code subj, w.shrtckn_crse_numb code,
                                                 shrtckg_grde_code_final CALIF, decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, shrtckg_final_grde_chg_date fecha
                                                from shrtckn w,shrtckg, shrgrde, smrprle
                                                where shrtckn_pidm=pidm
                                                and     shrtckg_pidm=w.shrtckn_pidm
                                                and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                and     shrtckg_tckn_seq_no=w.shrtckn_seq_no
                                                and     shrtckg_term_code=w.shrtckn_term_code
                                                and     smrprle_program=prog
                                                and     shrgrde_levl_code=smrprle_levl_code
                                                and     shrgrde_code=shrtckg_grde_code_final
   /* cambio escalas para prod */               and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                                and     decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))   -- anadido para sacar la calificacion mayor  OLC
                                                                  in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))) from shrtckn ww, shrtckg zz
                                                                          where w.shrtckn_pidm=ww.shrtckn_pidm
                                                                             and  w.shrtckn_subj_code=ww.shrtckn_subj_code  and w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                                                             and  ww.shrtckn_pidm=zz.shrtckg_pidm and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no and ww.shrtckn_term_code=zz.shrtckg_term_code)
                                                and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                                               and shrtckn_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                union
                                                select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                shrtrce_grde_code  CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                from  shrtrce
                                                where  shrtrce_pidm=pidm
                                                and     SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                union
                                                select SHRTRTK_SUBJ_CODE_INST subj, SHRTRTK_CRSE_NUMB_INST code,
                                                /*nvl(SHRTRTK_GRDE_CODE_INST,0)*/  '0' CALIF, 'EQ'  ST_MAT, trunc(SHRTRTK_ACTIVITY_DATE) fecha
                                                from  SHRTRTK
                                                where  SHRTRTK_PIDM=pidm
                                                union
                                                select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                from sfrstcr, smrprle, ssbsect, spriden
                                                where  smrprle_program=prog
                                                and     sfrstcr_pidm=pidm  and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                and     SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
    --                                            and    sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                and    ssbsect_term_code=sfrstcr_term_code
                                                and    ssbsect_crn=sfrstcr_crn
                                                union
                                                select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                 ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)/*+120*/  fecha
                                                from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                                where  smrprle_program=prog
                                                and     sfrstcr_pidm=pidm  and sfrstcr_grde_code is not null
                                                and     sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and shrtckn_crn=sfrstcr_crn)
                                                and    SFRSTCR_RSTS_CODE!='DD'  --- agregado
                                                and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
    --                                            and    sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                and     SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                and     SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                                               and sfrstcr_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                and    ssbsect_term_code=sfrstcr_term_code
                                                and    ssbsect_crn=sfrstcr_crn
                                                and     shrgrde_levl_code=smrprle_levl_code
                                                and     shrgrde_code=sfrstcr_grde_code
   /* cambio escalas para prod */               and    shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)

                                   ) k
                                  where    spriden_pidm=pidm  and spriden_change_ind is null
                                    and   sorlcur_pidm= spriden_pidm
                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                    and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                   and     smrpaap_program=prog
                                   AND  smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                   and     smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                   and     SMBAGEN_ACTIVE_IND='Y'           --solo areas activas  OLC
                                   and     SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF   --solo areas activas  OLC
                                   and     smrpaap_area=smrarul_area
                                   and     sgbstdn_pidm=spriden_pidm
                                   and     sgbstdn_program_1=smrpaap_program
                                   and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                   and     sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO'  and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                   and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                   and     SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
                                   and     stvstst_code=sgbstdn_stst_code
                                   and     smralib_area=smrpaap_area
                                   AND    smracaa_area = smrarul_area
                                   AND    smracaa_rule = smrarul_key_rule
                                   and    SMRACAA_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                   and     SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
--                                   and  (     (smrarul_area not in (select smriecc_area from smriecc)) or
--                                                    (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1,sgbstdn_majr_code_conc_1_2))) or
--                                                    (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=sgbstdn_majr_code_1)) )
                                   and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                           )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                              and ss.sorlcur_program =prog )
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                                 ) )) )
                                   and    k.subj=smrarul_subj_code and k.code=smrarul_crse_numb_low
                                   and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                   and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=sgbstdn_program_1 and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                 union
                                 select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                                    case
                                            when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+3
                                            when smralib_area_desc like 'Taller%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                           else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                                    end  per,  ---
                                    smrpaap_area area, ---
                                                              case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                                  case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('11') then substr(smrpaap_area,9,2)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('12') then substr(smrpaap_area,9,2)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         else smralib_area_desc
                                                                   end
                                                                else smralib_area_desc
                                                                end   nombre_area, ---
                                                smrarul_subj_code||smrarul_crse_numb_low materia, ---
                                                 scrsyln_long_course_title nombre_mat, ---
                                                 null calif,  ---
                                                 'PC' ,  ---
                                                 smracaa_rule regla, ---
                                                 null origen, ---
                                                  null fecha, --
                                                  pidm ,
                                                 usu_siu
                                    from spriden, smrpaap, sgbstdn y, sorlcur so,SZTDTEC, smrarul, smracaa, smralib, stvstst, scrsyln, zstpara,smbagen
                                     where    spriden_pidm=pidm  and spriden_change_ind is null
                                               and   sorlcur_pidm= spriden_pidm
                                               and   SORLCUR_LMOD_CODE = 'LEARNER'
                                               and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                  and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                  and ss.sorlcur_program =prog)
                                               and       smrpaap_program=prog
                                               AND  smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                                    and     smrpaap_area=SMBAGEN_AREA
                                                    and     SMBAGEN_ACTIVE_IND='Y'
                                                    and     SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                                and     smrpaap_area=smrarul_area
                                                and     sgbstdn_pidm=spriden_pidm
                                                and     sgbstdn_program_1=smrpaap_program
                                                and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                  where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                  and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                and     sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO' and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                                and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                                and     stvstst_code=sgbstdn_stst_code
                                                and     smralib_area=smrpaap_area
                                                AND smracaa_area = smrarul_area
                                                AND smracaa_rule = smrarul_key_rule
                                                AND   SMRARUL_TERM_CODE_EFF = SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                                and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                                and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                                           and spriden_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                               and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                                       where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                           )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                              and ss.sorlcur_program =prog )
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                                 ) )) )
                                                    and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                                    and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTCKN_SUBJ_CODE,SHRTCKN_CRSE_NUMB  from shrtckn where shrtckn_pidm=pidm )
                                                    and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRCE_SUBJ_CODE,SHRTRCE_CRSE_NUMB  from SHRTRCE where SHRTRCE_pidm=pidm )     --agregado
                                                    and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRTK_SUBJ_CODE_INST,SHRTRTK_CRSE_NUMB_INST  from SHRTRTK where SHRTRTK_pidm=pidm )  --agregado
                                                    and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select ssbsect_subj_code subj, ssbsect_crse_numb code  from  sfrstcr, smrprle, ssbsect, spriden  --agregado para materias EC y aprobadas sin rolar
                                                                                                                           where  smrprle_program=prog
                                                                                                                               and     sfrstcr_pidm=pidm  and (sfrstcr_grde_code is null or sfrstcr_grde_code is not null)  and sfrstcr_rsts_code='RE'
                                                                                                                               and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                                                               and    ssbsect_term_code=sfrstcr_term_code
                                                                                                                               and    ssbsect_crn=sfrstcr_crn)
                                                     and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=sgbstdn_program_1 and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG;

                                 commit;


                          open avance_n_out_tit
                            FOR
                             select
                                   vl_campus Campus, vl_nivel Nivel,
                                   CASE  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                       where SMBPGEN_program=prog
                                                                           and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                                                 where  s.sorlcur_pidm=pidm
                                                                                                                                      and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                      and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                                 where ss.sorlcur_pidm=pidm
                                                                                                                                                                                  and ss.sorlcur_program=prog
                                                                                                                                                                                  and ss.sorlcur_lmod_code='LEARNER'))) ='40' then
                                                                                                                                                                                             (select count(unique materia)  from avance_n x
                                                                                                                                                                                             where  apr in ('AP','EQ')
                                                                                                                                                                                             and    protocolo=9999
                                                                                                                                                                                             and    pidm_alu=pidm
                                                                                                                                                                                             and    usuario_siu=usu_siu
                                                                                                                                                                                             and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                                                                                                                                                             and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                                                    where x.materia=xx.materia
                                                                                                                                                                                                                    and   x.protocolo=xx.protocolo
                                                                                                                                                                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                                                    and   x.usuario_siu=xx.usuario_siu)
                                                                                                                                                                                                                    and CALIF!=0
                                                    and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )

                                                  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                       where SMBPGEN_program=prog
                                                                           and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                                                 where  s.sorlcur_pidm=pidm
                                                                                                                                      and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                      and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                                 where ss.sorlcur_pidm=pidm
                                                                                                                                                                                  and ss.sorlcur_program=prog
                                                                                                                                                                                  and ss.sorlcur_lmod_code='LEARNER'))) ='42' then
                                                                                                                                                                                          (select count(unique materia)  from avance_n x
                                                                                                                                                                                             where  apr in ('AP','EQ')
                                                                                                                                                                                             and    protocolo=9999
                                                                                                                                                                                             and    pidm_alu=pidm
                                                                                                                                                                                             and    usuario_siu=usu_siu
                                                                                                                                                                                             and    area not in  ((select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' ) )
                                                                                                                                                                                             and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                                                    where x.materia=xx.materia
                                                                                                                                                                                                                    and   x.protocolo=xx.protocolo
                                                                                                                                                                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                                                    and   x.usuario_siu=xx.usuario_siu)
                                                                                                                                                                                                                    and CALIF!=0
                                                    and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )
                                            ELSE
                                                  (select count(unique materia)  from avance_n x
                                                     where  apr in ('AP','EQ')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    usuario_siu=usu_siu
                                                     and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                     and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            and   x.usuario_siu=xx.usuario_siu)
                                                                            and CALIF!=0
                                                     and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )
                                      end  aprobadas_curr,
                                   ---------------------------
                                     (select count(unique materia)  from avance_n x
                                     where  apr in ('NA')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                     and    materia not in (select materia from avance_n xx
                                                           where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu
                                                            and   xx.apr='EC')
                                     and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu)) no_aprobadas_curr,
                                     (select count(unique materia) from avance_n x
                                     where  apr in ('EC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                                  ) curso_curr,
                                         (select count(unique materia)  from avance_n x
                                                     where apr in ('PC')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    usuario_siu=usu_siu
                                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                     and materia not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB' and ZSTPARA_PARAM_VALOR=materia and
                                                           pidm_alu in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                           ) por_cursar_curr,
                                       case when
                                              round ((select count(unique materia) from avance_n x
                                             where  apr in ('AP','EQ')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    usuario_siu=usu_siu
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and     calif not in ('NP','AC')
                                             and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) or calif is null)
                                                      and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                           and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
                                                                    ) *100 /
                                            (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                    where  sorlcur_pidm=pidm
                                                                                                                       and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                       and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where ss.sorlcur_pidm=pidm
                                                                                                                                                                   and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))>100  then 100
                                         else
                                            round ((select count(unique materia) from avance_n x
                                             where  apr in ('AP','EQ')
                                            and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    usuario_siu=usu_siu
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and     calif not in ('NP','AC')
                                             and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) or calif is null)
                                                     and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
                                                                    ) *100 /
                                            (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                    where  sorlcur_pidm=pidm
                                                                                                                       and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                       and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                             where ss.sorlcur_pidm=pidm
                                                                                                                                                             and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))
                                       end Avance_n_curr,
                                    (select count(unique materia) from avance_n x
                                     where apr in ('AP','EQ')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                     and    to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu))  aprobadas_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('NA')
                                     and    protocolo=9999
                                      and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                     and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu)) no_aprobadas_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('EC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                  ) curso_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('PC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                  )  por_cursar_tall
--                                    (select count(unique materia) from avance_n x
--                                     where area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
--                                     and    protocolo=9999
--                                     and    pidm_alu=pidm
--                                     and    usuario_siu=usu_siu
--                                     and    (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
--                                                            where x.materia=xx.materia
--                                                            and   x.protocolo=xx.protocolo
--                                                            and   x.pidm_alu=xx.pidm_alu
--                                                            and   x.usuario_siu=xx.usuario_siu) or calif is null)) total_tall
                                    from spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
                                    (SELECT 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
                                       FROM  (
                                                        select 9999, per, area, nombre_area, materia, nombre_mat,
                                                                        case when calif='1' then cal_origen
                                                                                when apr='EC' then null
                                                                        else calif
                                                                        end calif, apr, regla, null n_area,
                                                                        case when substr(materia,1,2)='L3' then 5
                                                                        else 1
                                                                        end ord,fecha
                                                                 from  sgbstdn y, avance_n x
                                                                   where  x.protocolo=9999
                                                                    and    sgbstdn_pidm=pidm
                                                                    and    sgbstdn_program_1=prog
                                                                    and    x.pidm_alu=pidm
                                                                    and    x.usuario_siu=usu_siu
                                                                    and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                    and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and  x.protocolo=xx.protocolo   ----cambio
                                                                          and  x.pidm_alu=sgbstdn_pidm  ----cambio
                                                                          and  x.pidm_alu=xx.pidm_alu   ---- cambio
                                                                          and  x.usuario_siu=xx.usuario_siu) or calif is null)
                                                        union
                                                        select distinct 9999, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                                                        case when calif='1' then cal_origen
                                                                when apr='EC' then null
                                                        else calif
                                                        end calif, apr, regla, null n_area,
                                                        case when substr(materia,1,2)='L3' then 5
                                                        else 1
                                                        end ord, fecha
                                                                    from  sgbstdn y, avance_n x
                                                                   where   x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                     and    x.pidm_alu=sgbstdn_pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     apr='EC'
                                                                    and     sgbstdn_program_1=prog
                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                        union
                                                        select protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                    case when calif='1' then cal_origen
                                                                           when apr='EC' then null
                                                                    else calif
                                                                    end calif, apr, regla, stvmajr_desc n_area, 2 ord, fecha
                                                                    from  sgbstdn y, avance_n x, smriemj, stvmajr
                                                                   where   x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                    and     x.pidm_alu=sgbstdn_pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     sgbstdn_program_1=prog
                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and    area=smriemj_area
--                                                                   and smriemj_majr_code=sgbstdn_majr_code_1   --vic
                                                                   and smriemj_majr_code= (select distinct SORLFOS_MAJR_CODE
                                                                                            from  sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                                            and   sorlcur_program   =prog
                                                                                                      )
                                                                   and    area not in (select smriecc_area from smriecc)
                                                                   and    smriemj_majr_code=stvmajr_code
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or calif is null)
                                                        union
                                                          select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                case when calif='1' then cal_origen
                                                                         when apr='EC' then null
                                                                 else calif
                                                                end  calif, apr, regla, smralib_area_desc n_area, 3 ord, fecha
                                                                    from sgbstdn y, avance_n x ,smralib, smriecc a -- , stvmajr
                                                                   where  x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                    and     x.pidm_alu=sgbstdn_pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     sgbstdn_program_1=prog
                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                      and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and    area=smralib_area
                                                                   and    area=smriecc_area
--                                                                   and    smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)---modifico vic   18.04.2018
                                                                   and     smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
--                                                                                                        and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
--                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
--                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
--                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                        and   cu.sorlcur_pidm=pidm
                                                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                                                                        and   sorlcur_program   =prog
                                                                                                         )
--                                                                   and    smriecc_majr_code_conc=stvmajr_code
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or calif is null)
--                                                                          or calif='1')   -----------------
                                                                   and    (fecha in (select distinct fecha from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or fecha is null)
                                                        order by   n_area desc, per, nombre_area,regla
                                          )
                                        GROUP BY 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
                                    )  avance1
--                                    vl_campus ,
--                                    vl_nivel
                                    where  spriden_pidm=pidm
                                    and   sorlcur_pidm= spriden_pidm
                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                    and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                   and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                   and ss.sorlcur_program =prog)
                                    and     spriden_change_ind is null
                                    and     sgbstdn_pidm=spriden_pidm
                                    and     sgbstdn_program_1=prog
                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                                                                      where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                                                      and    a.sgbstdn_program_1=b.sgbstdn_program_1)
                                    and     sztdtec_program=sgbstdn_program_1
                                    and     sztdtec_status='ACTIVO'
                                    and     SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE
                                    and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                    and     sgbstdn_stst_code=stvstst_code
                                    order by  avance1.per,avance1.n_area, avance1.materia,avance1.regla,avance1.ord ;
--                                    order by  avance1.per,avance1.n_area, avance1.regla,avance1.ord,hoja ;

                        RETURN (avance_n_out_tit);

            END f_avcu_out_titulo;


function F_Genera_Etiqueta(PPIDM NUMBER, p_etiqueta in  varchar2, p_descripcion in varchar2, p_usuario in varchar2) RETURN VARCHAR2 IS

vl_exito varchar2(500):= 'EXITO';
vl_existe number:= 0;

begin

            Begin
                    Select count(1)
                        Into vl_existe
                    from goradid
                    where goradid_pidm = PPIDM
                    And GORADID_ADID_CODE = p_etiqueta;
            Exception
                When Others then
                vl_existe:=0;
            End;

           If vl_existe >= 1 then
                    Begin
                            Update goradid
                              set GORADID_ADDITIONAL_ID = p_descripcion,
                              GORADID_USER_ID = p_usuario
                               where goradid_pidm = PPIDM
                             And GORADID_ADID_CODE = p_etiqueta;
                             commit;
                    Exception
                        When Others then
                            vl_exito := 'Se presento un error al actualizar '||sqlerrm;
                    End;

           Elsif vl_existe = 0  then

                    Begin
                            Insert into goradid values (PPIDM,
                                                                  p_descripcion,
                                                                  p_etiqueta,
                                                                  p_usuario,
                                                                  sysdate,
                                                                  'ETIQUETA',
                                                                  null,
                                                                  null,
                                                                  null);
                         Commit;
                    Exception
                        When others then
                            vl_exito := 'Se Presento el error al insertar '||sqlerrm;
                    End;

            End if;

       RETURN (vl_exito);

exception when others THEN
vl_exito :='Error General' ||sqlerrm;
 RETURN (vl_exito);

END  F_Genera_Etiqueta;

Function F_genera_NSS(PPIDM NUMBER, pss varchar2 , puser varchar2 ) RETURN VARCHAR2 is

vl_exito varchar2(500):= 'EXITO';
vl_existe number:= 0;

Begin

        Begin
               update spbpers
                 set SPBPERS_SSN = pss,
                     SPBPERS_USER_ID = puser,
                     SPBPERS_ACTIVITY_DATE  = sysdate
                 where 1=1
                   and SPBPERS_PIDM  = PPIDM;
        Exception
            When Others then
               vl_exito := ' Se presento el error al actualizar el SSN '  ||sqlerrm;
        End;

                  RETURN (vl_exito);

exception when others THEN
vl_exito :='Error General' ||sqlerrm;
 RETURN (vl_exito);
END  F_genera_NSS;

Function  f_modalidad  (p_programa in varchar2, p_perid_ctlg in varchar2 ) return varchar2
-- se agregro esta funcion para recuperar la modalidad del programa glovicx 02/08/021
As
            vl_resultado varchar2(250) := null;
            vl_secuencia number:=0;
            vmodalidad    varchar2(25);


    Begin

            Begin

                select distinct decode ( SZTDTEC_MOD_TYPE, 'S', 'Ejecutivo','OL','Online')
                   INTO vmodalidad
                from SZTDTEC
                where 1=1
                and SZTDTEC_PROGRAM = p_programa --'UTLMATSFED'
                and SZTDTEC_TERM_CODE = p_perid_ctlg ; -- '000000';

            Exception
                When Others then
                    vmodalidad :='NA';
            End;




               Return (vmodalidad);

    Exception
        when Others then
         vmodalidad :=  substr(sqlerrm,1,25);
          Return (vmodalidad);
    End f_modalidad;

Function f_fecha_fin (p_pidm in number, p_Regla in number, p_sp in number ) return varchar2 as

vl_exito varchar2(50):= null;

Begin

            Begin

                    select distinct to_char (SOBPTRM_END_DATE,'dd/mm/yyyy') FECHA_TERMINO
                        Into vl_exito
                    from sztprono
                    JOIN SOBPTRM ON  SOBPTRM_TERM_CODE = SZTPRONO_TERM_CODE AND SOBPTRM_PTRM_CODE = SZTPRONO_PTRM_CODE
                    where 1=1
                    AND SZTPRONO_PIDM= p_pidm
                    AND SZTPRONO_NO_REGLA = p_Regla
                    AND SZTPRONO_STUDY_PATH = p_sp;
            Exception
                When Others then
                        vl_exito:= null;
            End;


            Return vl_exito;

End f_fecha_fin;

procedure p_titulacion_incluida (p_pidm in number default null) as

vl_existe_1 number:=0;
vl_existe_2 number:=0;
vl_etiqueta_final varchar2(10):= null;
vl_etiqueta_1 varchar2(10):= null;
vl_quita    number:= 0;
vl_quita_no  number:=0;
vl_inserta   number:=0;

vl_quita_f    date:= null;
vl_quita_no_f  date:=null;
vl_saldo_total number :=0;
vl_saldo_parametro number:=0;
vl_valida_saldo number:=0;

Begin
    -------------------- Se borran las etiquetas  ----------------------

        Begin 
            delete goradid
            where 1=1
            And GORADID_ADID_CODE in ( select TZTTIIN_CODE_GT
                                         from TZTTIIN
                                         )
            And goradid_pidm = nvl (p_pidm, goradid_pidm);
        Exception
            When Others then 
                null;
        End;



        For cx in (

                        Select x.pidm, x.matricula, x.campus, x.nivel, x.etiqueta, x.Descripcion_etiqueta, x.sp, x.programa, x.tbraccd_detail_code, x.estatus, x.seq, x.monto_ajusto, x.monto_no_ajusto, x.monto_origen, x.porcentaje,x.fecha_mov
                       from  (
                            with ajuste as (
                            select nvl (sum (TBRAPPL_AMOUNT),0) monto , TBRAPPL_PIDM, TBRAPPL_CHG_TRAN_NUMBER
                            from tbrappl
                            where 1= 1
                            And TBRAPPL_REAPPL_IND is null
                            And TBRAPPL_PAY_TRAN_NUMBER in (select TBRACCD_TRAN_NUMBER
                                                                                    from tbraccd
                                                                                    Where TBRACCD_PIDM = TBRAPPL_PIDM
                                                                                    And substr (TBRACCD_DETAIL_CODE,3,2) in (Select substr (TZTINCO_CODE_DET,3,2)
                                                                                                                             from TZTINCO
                                                                                                                             )
                                                                                    )
                            group by TBRAPPL_PIDM, TBRAPPL_CHG_TRAN_NUMBER
                            ),
                            no_ajuste as (
                            select nvl (sum (TBRAPPL_AMOUNT),0) monto , TBRAPPL_PIDM, TBRAPPL_CHG_TRAN_NUMBER
                            from tbrappl
                            where 1= 1
                            And TBRAPPL_REAPPL_IND is null
                            And TBRAPPL_PAY_TRAN_NUMBER in (select TBRACCD_TRAN_NUMBER
                                                                                    from tbraccd
                                                                                    Where TBRACCD_PIDM = TBRAPPL_PIDM
                                                                                    And substr (TBRACCD_DETAIL_CODE,3,2) not in (Select substr (TZTINCO_CODE_DET,3,2)
                                                                                                                             from TZTINCO
                                                                                                                             )
                                                                                    )
                            group by TBRAPPL_PIDM, TBRAPPL_CHG_TRAN_NUMBER
                            )
                            select distinct a.pidm, a.matricula, a.campus, a.nivel, TZTTIIN_CODE_GT Etiqueta, TZTTIIN_DESC_GT||' SP.'||a.sp Descripcion_etiqueta, a.sp, a.programa, b.tbraccd_detail_code,a.estatus,b.TBRACCD_TRAN_NUMBER Seq
                            , nvl (c.MONTO,0) Monto_Ajusto, d.monto Monto_No_Ajusto, b.tbraccd_amount Monto_origen
                                          , nvl ((c.MONTO * 100) / (b.tbraccd_amount),0) Porcentaje, a.fecha_mov 
                            from tztprog a
                            join tbraccd b on b.tbraccd_pidm  = a.pidm and TBRACCD_STSP_KEY_SEQUENCE = a.sp
                            join TZTTIIN on TZTTIIN_CODE_DET = tbraccd_detail_code and TZTTIIN_CAMPUS = a.campus and TZTTIIN_NIVEL = a.nivel and TZTTIIN_CVE_ESTATUS = a.estatus
                            left join ajuste c on c.TBRAPPL_PIDM  = b.tbraccd_pidm and c.TBRAPPL_CHG_TRAN_NUMBER = b.TBRAccd_TRAN_NUMBER
                            left join no_ajuste d on d.TBRAPPL_PIDM  = b.tbraccd_pidm and d.TBRAPPL_CHG_TRAN_NUMBER = b.TBRACCD_TRAN_NUMBER
                            join tztordr e on  e.TZTORDR_PIDM = b.tbraccd_pidm and e.TZTORDR_CONTADOR = b.TBRACCD_RECEIPT_NUMBER and e.TZTORDR_CAMPUS = a.campus and e.TZTORDR_NIVEL = a.nivel
                            where 1=1
                            And a.estatus in ('MA', 'EG','SG')
                            And b.tbraccd_amount > 0
                          --  And pkg_utilerias.f_canal_venta_programa(a.pidm, a.programa) not in ('21')
                            and a.sp = (select max (a1.sp)
                                             from tztprog a1
                                             Where a.pidm = a1.pidm
                                             And a.campus = a1.campus
                                             And a.nivel = a1.nivel
                                             And a.programa = a1.programa)
                           And b.tbraccd_pidm = nvl (p_pidm, b.tbraccd_pidm)
                           And nvl ((c.MONTO * 100) / (b.tbraccd_amount),0) <= 5.0
                         --   And a.matricula in ('010567618')
                            order by 1, 15 desc
                            ) x                            
                            union
                        Select x.pidm, x.matricula, x.campus, x.nivel, x.etiqueta, x.Descripcion_etiqueta, x.sp, x.programa, x.tbraccd_detail_code, x.estatus, x.seq, x.monto_ajusto, x.monto_no_ajusto, x.monto_origen, x.porcentaje, x.fecha_mov
                       from  (
                            with ajuste as (
                                           select distinct TBRACCD_TRAN_NUMBER, tbraccd_pidm, TBRACCD_TRAN_NUMBER_PAID, TBRACCD_STSP_KEY_SEQUENCE
                                            from tbraccd
                                            Where 1=1
                                            And substr (TBRACCD_DETAIL_CODE,3,2) in (Select substr (TZTINCO_CODE_DET,3,2)
                                                                                     from TZTINCO
                                                                                     )
                             )
                            select distinct a.pidm, a.matricula, a.campus, a.nivel, TZTTIIN_CODE_GT Etiqueta, TZTTIIN_DESC_GT||' SP.'||a.sp Descripcion_etiqueta, a.sp, a.programa, b.tbraccd_detail_code,a.estatus,b.TBRACCD_TRAN_NUMBER Seq
                            , 0 Monto_Ajusto, 0 Monto_No_Ajusto, b.tbraccd_amount Monto_origen
                             , c.TBRACCD_TRAN_NUMBER_PAID  Porcentaje, a.FECHA_MOV 
                            from tztprog a
                            join tbraccd b on b.tbraccd_pidm  = a.pidm and TBRACCD_STSP_KEY_SEQUENCE = a.sp
                            join TZTTIIN on TZTTIIN_CODE_DET = tbraccd_detail_code and TZTTIIN_CAMPUS = a.campus and TZTTIIN_NIVEL = a.nivel and TZTTIIN_CVE_ESTATUS = a.estatus
                            left join ajuste c on c.tbraccd_pidm  = b.tbraccd_pidm and c.TBRACCD_TRAN_NUMBER_PAID = b.TBRAccd_TRAN_NUMBER
                            join tztordr e on  e.TZTORDR_PIDM = b.tbraccd_pidm and e.TZTORDR_CONTADOR = b.TBRACCD_RECEIPT_NUMBER and e.TZTORDR_CAMPUS = a.campus and e.TZTORDR_NIVEL = a.nivel
                            where 1=1
                            And a.estatus in ('MA', 'EG','SG')
                            And c.TBRACCD_TRAN_NUMBER_PAID is null
                            And b.tbraccd_amount = 0
                          --  And pkg_utilerias.f_canal_venta_programa(a.pidm, a.programa) not in ('21')
                            and a.sp = (select max (a1.sp)
                                             from tztprog a1
                                             Where a.pidm = a1.pidm
                                             And a.campus = a1.campus
                                             And a.nivel = a1.nivel
                                             And a.programa = a1.programa)
                           And b.tbraccd_pidm = nvl (p_pidm, b.tbraccd_pidm)
                          --  And a.matricula in ('010191109')
                            order by 1, 15 desc
                            ) x                            
                            
  
        ) loop



            If cx.estatus in ('EG') then 
   
               dbms_output.put_line('Entra a Egresado '||cx.estatus);
                vl_inserta:= 0;
                
                vl_quita_no:= 0;
                vl_quita:= 0;
                
                vl_quita_no_f:= null;
                vl_quita_f:= null;
                
                vl_valida_saldo:=0;
                vl_saldo_total:=0;
                vl_saldo_parametro:=0;
                
                Begin 
                    vl_saldo_total:= pkg_utilerias.f_dashboard_saldototal_SP(cx.pidm, cx.sp);
                Exception
                    When Others then 
                    vl_saldo_total:=0;
                End;

                Begin
                    select to_number(ZSTPARA_PARAM_VALOR) valor
                        Into vl_saldo_parametro
                    from zstpara 
                    where 1=1
                    and ZSTPARA_MAPA_ID = 'ADEUDO_COLF'
                    And ZSTPARA_PARAM_ID = cx.campus;
                Exception
                   When Others then 
                   vl_saldo_parametro:=0;
                End;

                If vl_saldo_total > vl_saldo_parametro then 
                   vl_valida_saldo:= 1;
                Else 
                    vl_valida_saldo:= 0;
                End if;

                    dbms_output.put_line('Saldo Total '||vl_saldo_total);
                    dbms_output.put_line('Saldo parametro '||vl_saldo_parametro);
                    dbms_output.put_line('Valida Saldo '||vl_valida_saldo);

            
                Begin
                    Select max (TBRACCD_ENTRY_DATE)
                        Into vl_quita_f
                    from tbraccd
                    join TZTNCD on TZTNCD_CODE = tbraccd_detail_code  and OPERA ='RESTA'
                    Where 1=1
                    And tbraccd_pidm = cx.pidm 
                     And tbraccd_desc like '%QUITA%'
                     And trunc (TBRACCD_ENTRY_DATE) >= cx.fecha_mov;
                 Exception
                    When OThers then 
                     vl_quita_f:=null;
                End;

                dbms_output.put_line('Encuentra con quitas '||vl_quita_f);


                Begin
                    Select max (TBRACCD_ENTRY_DATE)
                        Into vl_quita_no_f
                    from tbraccd
                    join TZTNCD on TZTNCD_CODE = tbraccd_detail_code  and OPERA ='SUMA'
                    Where 1=1
                    And tbraccd_pidm = cx.pidm 
                     And substr (tbraccd_detail_code,3,2) in ('NU', 'YM')
                     And trunc (TBRACCD_ENTRY_DATE) >= cx.fecha_mov;
                 Exception
                    When OThers then 
                     vl_quita_no_f:=null;
                End;            

                    dbms_output.put_line('Encuentra con NO_quitas '||vl_quita_no_f);
                    
                 If vl_quita_f is not null then 
                    vl_quita:= 1;
                 End if;

                 If vl_quita_no_f is not null then 
                    vl_quita_no:= 1;
                 End if;




                If vl_quita_f is not null  and vl_quita_no_f is not null then 
                
                dbms_output.put_line('Amboas fecha existen y entro ');
                    
                   IF  vl_quita_f >= vl_quita_no_f then 
                       vl_quita_no:=0;
                       dbms_output.put_line('Amboas fecha existen y entro #1');
                       
                   ElsIF vl_quita_f < vl_quita_no_f then 
                      vl_quita:=0;
                      dbms_output.put_line('Amboas fecha existen y entro #2');
                   End if;

                End if;


                
                If substr (cx.TBRACCD_DETAIL_CODE,3,2) in ( 'OR', 'TQ', 'TR', '06', '49') then  ----RD para diferidas 
                
                 dbms_output.put_line('Limpio Variables porque encuentro el codigo OR de Autoserivcio'); 
                 
                  
                    vl_quita_f:= null;
                    vl_quita_no_f := null;
                    vl_quita:=0;
                    vl_quita_no :=0;
                    vl_valida_saldo:=0;
                End if;
----------------------------------------------------------------------------------------------


                If vl_quita_no >= 1 and vl_quita >= 1 then 
                   vl_inserta:= 0 ;
                    dbms_output.put_line('Bloque 1 '||vl_inserta);
                ElsIf vl_quita_no = 0 and vl_quita = 0 then 
                   vl_inserta:= 0 ;
                    dbms_output.put_line('Bloque 2 '||vl_inserta);
                ElsIf vl_quita_no = 0 and vl_quita >= 1 then 
                   vl_inserta:= 1 ;
                    dbms_output.put_line('Bloque 3 '||vl_inserta);
                Else
                    vl_inserta:= 0 ;
                    dbms_output.put_line('Bloque 4 '||vl_inserta);
                End if;

                 IF vl_inserta = 0 and vl_valida_saldo = 0 then 

                        Begin

                                Insert into goradid values ( cx.pidm,
                                                           cx.DESCRIPCION_ETIQUETA,
                                                           cx.ETIQUETA,
                                                           user,
                                                           sysdate,
                                                           'MASIVO',
                                                           NULL,
                                                           0,
                                                           NULL);
                       Exception
                        When Others then
                             DBMS_OUTPUT.PUT_LINE('pidm:'||cx.pidm||' ' ||sqlerrm);
                       End;

                        Commit;
                 End if;                    
                
                
            Else
                vl_inserta:= 0 ;
                vl_valida_saldo:=0;
                    dbms_output.put_line('Entra como no Egresado '||cx.estatus);
                    
                    

                 IF vl_inserta = 0 and vl_valida_saldo = 0 then 

                        Begin

                                Insert into goradid values ( cx.pidm,
                                                           cx.DESCRIPCION_ETIQUETA,
                                                           cx.ETIQUETA,
                                                           user,
                                                           sysdate,
                                                           'MASIVO',
                                                           NULL,
                                                           0,
                                                           NULL);
                       Exception
                        When Others then
                             DBMS_OUTPUT.PUT_LINE('pidm:'||cx.pidm||' ' ||sqlerrm);
                       End;

                        Commit;
                 End if;                    
                    
            End if;



        End loop;



        Begin 

                EXECUTE IMMEDIATE 'TRUNCATE TABLE taismgr.tztetiq';  

                 Begin 
                    Insert into tztetiq
                    select distinct a.GORADID_PIDM pidm, substr (GORADID_ADDITIONAL_ID,length (GORADID_ADDITIONAL_ID), 1) sp, GORADID_ADID_CODE etiqueta, GORADID_ADDITIONAL_ID Descripcion
                    from goradid a
                    join TZTTIIN on TZTTIIN_CODE_GT = GORADID_ADID_CODE
                    where  1=1
                    And a.GORADID_PIDM= nvl (p_pidm, a.GORADID_PIDM)
                    order by 1,2;
                    commit;
                  Exception
                    When Others then    
                        null;
                  End;

                  For cx in (

                            select count(*),  pidm, sp
                            from tztetiq
                            group by pidm, sp
                            having count(*) > 1
                            
                            ) loop
                
                                    For cx1 in (
                                    
                                                select *
                                                from tztetiq
                                                where pidm = cx.pidm
                                                And sp = cx.sp
                                                
                                               ) loop
                          
                                         dbms_output.put_line('Entra a los duplicados '|| cx1.pidm ||'*'|| cx1.sp ||'*'||cx1.etiqueta );     
                                                  --------- Busca Etiqueta 1------------
                                                  vl_existe_1:=0;
                                                  vl_etiqueta_final := null;
                                                  
                                                  Begin
                                                      select count(1), SZTETIQ_ETIQ_FINAL
                                                      Into vl_existe_1, vl_etiqueta_final
                                                     from SZTETIQ   
                                                     where SZTETIQ_ETIQUETA1 = cx1.etiqueta
                                                     group by SZTETIQ_ETIQ_FINAL;
                                                  Exception
                                                    When Others then 
                                                       vl_existe_1:=0; 
                                                       vl_etiqueta_final:= null;
                                                  End;

                                                  dbms_output.put_line('Etiqueta_1 '|| cx1.pidm ||'*'|| vl_existe_1 ||'*'||vl_etiqueta_final );       
                                                  
                                                  --------- Busca Etiqueta 2------------
                                                  vl_existe_2:=0;
                                                  vl_etiqueta_final:= null;
                                                  
                                                  Begin
                                                      select count(1), SZTETIQ_ETIQ_FINAL
                                                      Into vl_existe_2, vl_etiqueta_final
                                                     from SZTETIQ   
                                                     where SZTETIQ_ETIQUETA2 = cx1.etiqueta
                                                     group by SZTETIQ_ETIQ_FINAL;
                                                  Exception
                                                    When Others then 
                                                       vl_existe_2:=0; 
                                                       vl_etiqueta_final:= null;
                                                  End;
                                                
                                                dbms_output.put_line('Etiqueta_2 '|| cx1.pidm ||'*'|| vl_existe_2 ||'*'||vl_etiqueta_final );

                                                 If vl_existe_1 >= 1 and vl_existe_2 >= 1 then 
                                                 
                                                 dbms_output.put_line('Cumple los criterios '|| cx1.pidm ||'*'|| vl_existe_1 ||'*'||vl_existe_2 );
                                                 
                                                      Begin
                                                          select SZTETIQ_ETIQUETA1
                                                          Into vl_etiqueta_1
                                                         from SZTETIQ   
                                                         where SZTETIQ_ETIQ_FINAL = vl_etiqueta_final;
                                                      Exception
                                                        When Others then 
                                                           vl_etiqueta_1:= null;
                                                      End;                                     

                                                     --   dbms_output.put_line('Recupera Etiqueta para borrar '|| cx1.pidm ||'*'||vl_etiqueta_1);                                                 

                                                     If vl_etiqueta_1 is null then 
                                                        Begin
                                                            select distinct etiqueta 
                                                                Into vl_etiqueta_1
                                                            from tztetiq
                                                            where pidm = cx1.pidm
                                                            And sp = cx1.sp
                                                            and  etiqueta != vl_etiqueta_final;
                                                        Exception
                                                            When OThers then 
                                                                
                                                        vl_etiqueta_1:= null;
                                                        End;
                                                     End if;

                                                    dbms_output.put_line('Recupera Etiqueta para borrar xxx '|| cx1.pidm ||'*'||vl_etiqueta_1);           


                                                      Begin
                                                            delete goradid 
                                                            where 1=1
                                                            And goradid_pidm = cx1.pidm
                                                            And GORADID_ADID_CODE = vl_etiqueta_1;
                                                      Exception
                                                        When others then 
                                                            null;
                                                      End;

                                                End if;
                            
                                    End loop;
                    Commit;

                  End Loop;
                
        End;    




End p_titulacion_incluida;

Function f_rfc_emisor_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(20) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2   NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<rfc>');
                  POSICION_2   := INSTR(Entrada, '</rfc>');
                  vl_metodo_pago := SUBSTR(entrada, POSICION+5,  (POSICION_2 -POSICION-5 ) );

            Exception
                When Others then
                    Entrada:= null;
            End;


               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_rfc_emisor_nt;

Function f_estado_facturacion_nt (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2   NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<estado>');
                  POSICION_2   := INSTR(Entrada, '</estado>');
                  vl_salida := SUBSTR(entrada, POSICION+8,  (POSICION_2 -POSICION-8 ) );

            Exception
                When Others then
                    Entrada:= null;
            End;




               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_estado_facturacion_nt;


Function f_fecha_pago_fact_nt (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2   NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<fecha>');
                  POSICION_2   := INSTR(Entrada, '</fecha>');
                  vl_salida := SUBSTR(entrada, POSICION+7,  (POSICION_2 -POSICION-7 ) );

            Exception
                When Others then
                    Entrada:= null;
            End;



               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_fecha_pago_fact_nt;


Function f_folio_interno_nt (p_pidm in number, p_secuencia in number) Return varchar2


 As



i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<folio>');
                  POSICION_2   := INSTR(Entrada, '</folio>');
                  vl_salida := SUBSTR(entrada, POSICION+7,  (POSICION_2 -POSICION-7 ) );

            Exception
                When Others then
                    Entrada:= null;
            End;




               Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_folio_interno_nt;


Function f_formaPago_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<formaPago>');
                  POSICION_2   := INSTR(Entrada, '</formaPago>');
                  vl_metodo_pago := SUBSTR(entrada, POSICION+22,  (POSICION_2 -POSICION-22 ) );

            Exception
                When Others then
                    Entrada:= null;
            End;





               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_formaPago_nt;


Function f_metodoPago_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<metodoPago>');
                  POSICION_2   := INSTR(Entrada, '</metodoPago>');
                  vl_metodo_pago := SUBSTR(entrada, POSICION+12,  (POSICION_2 -POSICION-12 ) );

            Exception
                When Others then
                    Entrada:= null;
            End;





               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_metodoPago_nt;

Function f_monto_iva_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As


vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<totalImpuestosTrasladados>');
                  POSICION_2   := INSTR(Entrada, '</totalImpuestosTrasladados>');
                  vl_metodo_pago := SUBSTR(entrada, POSICION+27,  (POSICION_2 -POSICION-27 ) );


--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION_2);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||vl_metodo_pago);

            Exception
                When Others then
                    Entrada:= null;
            End;





               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_monto_iva_nt;


Function f_subtotal_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As



vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<subTotal>');
                  POSICION_2   := INSTR(Entrada, '</subTotal>');
                  vl_metodo_pago := SUBSTR(entrada, POSICION+10,  (POSICION_2 -POSICION-10 ) );


--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION_2);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||vl_metodo_pago);

            Exception
                When Others then
                    Entrada:= null;
            End;





               Return (vl_metodo_pago);

    Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
    End f_subtotal_nt;


Function f_total_nt (p_pidm in number, p_secuencia in number) Return varchar2
 As



vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2    NUMBER:= null;
vl_salida varchar2(500);



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<granTotal>');
                  POSICION_2   := INSTR(Entrada, '</granTotal>');
                  vl_metodo_pago := SUBSTR(entrada, POSICION+11,  (POSICION_2 -POSICION-11 ) );


--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION_2);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||vl_metodo_pago);

            Exception
                When Others then
                    Entrada:= null;
            End;





               Return (vl_metodo_pago);

  Exception
        when Others then
         vl_metodo_pago := null;
          Return (vl_metodo_pago);
  End f_total_nt;


Function f_colegiatura_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As




vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO_CODE ||',' codigo
                                from tztcont
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE in ('COL')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_colegiatura_nt;

Function f_descripcion_col_nt (p_pidm in number, p_secuencia in number) Return varchar2


 As


vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO ||',' codigo
                                from tztcont
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE in ('COL')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_descripcion_col_nt;


Function f_monto_col_nt (p_pidm in number, p_secuencia in number) Return varchar2

as

vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2    NUMBER:= null;
vl_salida varchar2(500);
vl_metodo_pago_1  varchar2(250) := null;



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<key>MontoColegiatura</key><value>');
                  POSICION_2   :=  INSTR(Entrada, '<key>MontoColegiatura</key><value>')+50;
                  vl_metodo_pago := SUBSTR(entrada, POSICION+11,  (POSICION_2 -POSICION-11 ) );

--                    DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION_2);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||vl_metodo_pago);
-- -- DBMS_OUTPUT.PUT_LINE('pos ....'||length (vl_metodo_pago)-10);


                  vl_metodo_pago_1 := substr  (vl_metodo_pago, 24, (length (vl_metodo_pago)-24)-9);





            Exception
                When Others then
                    Entrada:= null;
            End;





               Return (vl_metodo_pago_1);

  Exception
        when Others then
         vl_metodo_pago_1 := null;
          Return (vl_metodo_pago_1);
    End f_monto_col_nt;


Function f_intereses_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO_CODE ||',' codigo
                                from tztcont
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE in ('INT')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_intereses_nt;

Function f_descrip_interes_nt (p_pidm in number, p_secuencia in number) Return varchar2


 As


vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO ||',' codigo
                                from tztcont
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE in ('INT')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_descrip_interes_nt;

Function f_monto_interes_nt (p_pidm in number, p_secuencia in number) Return varchar2

as

vl_metodo_pago  varchar2(250) := null;
i integer;
Entrada_sbt clob;
Entrada     clob;
POSICION    NUMBER:= null;
POSICION_2    NUMBER:= null;
vl_salida varchar2(500);
vl_metodo_pago_1  varchar2(250) := null;



  Begin

            Begin
                    select TZTFACT_XML
                                Into Entrada
                    from TZTFCTU
                    where TZTFACT_PIDM= p_pidm
                    And TZTFACT_TRAN_NUMBER = p_secuencia;

                  POSICION    := INSTR(Entrada, '<key>InteresPagoTardio</key><value>');
                  POSICION_2   :=  INSTR(Entrada, '<key>InteresPagoTardio</key><value>')+50;
                  vl_metodo_pago := SUBSTR(entrada, POSICION,  (POSICION_2 -POSICION ) );

--                    DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||POSICION_2);
--  DBMS_OUTPUT.PUT_LINE('pos ....'||vl_metodo_pago);
-- -- DBMS_OUTPUT.PUT_LINE('pos ....'||length (vl_metodo_pago)-10);


                  vl_metodo_pago_1 := substr  (vl_metodo_pago, 36, (length (vl_metodo_pago)-36)-13);





            Exception
                When Others then
                    Entrada:= null;
            End;





               Return (vl_metodo_pago_1);

  Exception
        when Others then
         vl_metodo_pago_1 := null;
          Return (vl_metodo_pago_1);
    End f_monto_interes_nt;


  Function f_total_monto_accesorio_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_iva number:=0;
vl_total_iva number:=0;
vl_total_exento number:=0;
vl_final number :=0;



  Begin
            Begin
                    select sum (TZTCONC_SUBTOTAL)
                        Into vl_final
                    from tztcont
                    join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                             And TBBDETC_TYPE_IND ='C'
                                             And TBBDETC_DCAT_CODE not in ('COL', 'INT','APF')
                    where TZTCONC_PIDM = p_pidm
                    and TZTCONC_TRAN_NUMBER = p_secuencia;
             Exception
                When Others then
                    vl_final:=0;
             End;

        Return (vl_final);
   Exception
        when Others then
         vl_final := 0;
          Return (vl_final);

  End f_total_monto_accesorio_nt;


Function f_accesorio_nt (p_pidm in number, p_secuencia in number) Return varchar2

 As

vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO_CODE ||',' codigo
                                from tztcont
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE not in ('INT','COL','APF')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_accesorio_nt;

Function f_descrip_accesorios_nt (p_pidm in number, p_secuencia in number) Return varchar2


 As

vl_salida varchar2(5000);



    Begin

            For c in (


                                select distinct TZTCONC_CONCEPTO ||',' codigo
                                from tztcont
                                join TBBDETC on TBBDETC_DETAIL_CODE = TZTCONC_CONCEPTO_CODE
                                                         And TBBDETC_TYPE_IND ='C'
                                                         And TBBDETC_DCAT_CODE not in ('INT','COL','APF')
                                where TZTCONC_PIDM = p_pidm
                                and TZTCONC_TRAN_NUMBER = p_secuencia

            ) loop

                    vl_salida := vl_salida||c.codigo;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_descrip_accesorios_nt;


Function f_escuela (p_programa in varchar2) Return varchar2


 As

vl_salida varchar2(5000):= null;



    Begin

            For c in (


                            select distinct SOBCURR_COLL_CODE ||' '||STVCOLL_DESC Escuela
                            from SOBCURR
                            join stvcoll on   STVCOLL_CODE = SOBCURR_COLL_CODE
                            where 1= 1
                            and SOBCURR_PROGRAM = p_programa


            ) loop

                    vl_salida := vl_salida||c.escuela;

            End Loop;

           Return (vl_salida);

    Exception
        when Others then
         vl_salida := null;
          Return (vl_salida);
    End f_escuela;

Function f_periodo_materias (p_pidm in number,  p_fecha_ini date, p_sp in number) Return varchar2 as
vl_exito varchar2(50):= null;

Begin

            Begin

                    select distinct SFRSTCR_TERM_CODE
                        Into vl_exito
                    from sfrstcr
                    join ssbsect on SFRSTCR_TERM_CODE = ssbsect_TERM_CODE and SFRSTCR_CRN = SSBSECT_CRN
                    where 1= 1
                    and SFRSTCR_PIDM = p_pidm
                    and SSBSECT_PTRM_START_DATE = p_fecha_ini
                    And SFRSTCR_STSP_KEY_SEQUENCE = p_sp
                   And substr (SFRSTCR_TERM_CODE, 5,1)  not in ('9','8')
                    and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('M1HB401', 'M1HB402')
                    and SFRSTCR_DATA_ORIGIN != 'CONVALIDACION';

            Exception
                When Others then
                        vl_exito:= null;
            End;


            Return vl_exito;

End f_periodo_materias;

Function f_Jornada_desc (p_clave in varchar2) Return varchar2
as

    vl_valor varchar2(250) := null;

    Begin

                Begin
                        select distinct STVATTS_DESC
                            Into vl_valor
                        from STVATTS
                        where STVATTS_CODE = p_clave;
                Exception
                    When Others then
                        vl_valor := ' ';
                End;


               Return (vl_valor);

    Exception
        when Others then
         vl_valor := ' ';
          Return (vl_valor);
    End f_Jornada_desc;


Function f_programa_desc (p_clave in varchar2) Return varchar2
as

    vl_valor varchar2(250) := null;

    Begin

                Begin
                        select distinct SZTDTEC_PROGRAMA_COMP
                            into vl_valor
                        from SZTDTEC a
                        where 1= 1
                        and a.SZTDTEC_TERM_CODE = (select max (a1.SZTDTEC_TERM_CODE)
                                                                           from SZTDTEC a1
                                                                           Where a.SZTDTEC_PROGRAM = a1.SZTDTEC_PROGRAM)
                        and SZTDTEC_PROGRAM = p_clave;
                Exception
                    When Others then
                        vl_valor := ' ';
                End;


               Return (vl_valor);

    Exception
        when Others then
         vl_valor := ' ';
          Return (vl_valor);
    End f_programa_desc;

Function f_periodo_desc (p_clave in varchar2) Return varchar2
as

    vl_valor varchar2(250) := null;

    Begin

                Begin
                        select distinct STVTERM_DESC
                            Into vl_valor
                        from STVTERM
                        where STVTERM_CODE =  p_clave;
                Exception
                    When Others then
                        vl_valor := ' ';
                End;


               Return (vl_valor);

    Exception
        when Others then
         vl_valor := ' ';
          Return (vl_valor);
    End f_periodo_desc;

Function f_cadena (p_pidm in number,p_nivel varchar2) Return varchar2
as

    vl_valor varchar2(250) := null;

    Begin

                Begin
                        with accesorio as (
                                Select distinct x.GORADID_pidm, x.SZTALIA_LVEL, LISTAGG(x.SZTALIA_TEXT, ' ') WITHIN GROUP (ORDER BY x.SZTALIA_SEQ) AS description
                                from (
                                 select distinct GORADID_pidm,  SZTALIA_TEXT , SZTALIA_SEQ, SZTALIA_LVEL
                                  from GORADID
                                join SZTALIA on SZTALIA_CODE = GORADID_ADID_CODE
                                 join STVPAQT on STVPAQT_ADID_CODE = GORADID_ADID_CODE and  STVPAQT_LEVL_CODE = SZTALIA_LVEL
                                where 1= 1
                                )x
                        group by x.GORADID_pidm, x.SZTALIA_LVEL
                        )
                        select distinct  a.PROGRAMA||' , '||b.SZTDTEC_PROGRAMA_COMP||' , '||decode (b.SZTDTEC_MOD_TYPE,'OL', 'EN LINEA', 'S', 'SEMIPRESENCIAL')||' , '|| c.description Cadena
                            Into vl_valor
                        from tztprog a
                        join SZTDTEC b on b.SZTDTEC_PROGRAM = a.programa and a.CTLG = b.SZTDTEC_TERM_CODE and b.SZTDTEC_CAMP_CODE  = a.campus
                        join accesorio c on c.GORADID_pidm = a.pidm  and  c.SZTALIA_LVEL = a.nivel
                        where 1 = 1
                        And a.sp = (select max (a1.sp)
                        from tztprog a1
                        where a.pidm = a1.pidm
                        And a.campus = a1.campus
                        and a.nivel = a1.nivel
                        )
                        and a.pidm = p_pidm;
                        --And a.NIVEL = p_nivel;
                Exception
                    When Others then
                        vl_valor := null;
                End;

               Return (vl_valor);

    Exception
        when Others then
         vl_valor := ' ';
          Return (vl_valor);
    End f_cadena;

Function f_forma_adquisicion (p_pidm in number, p_nivel in varchar2, p_programa in varchar2) Return varchar2
as

vl_existe number :=0;
vl_cadena varchar2(500):= null;
vl_cadena_F varchar2(500):= null;
vl_UNICEF number:=0;
vl_UBA number:=0;
vl_POL number:=0;
vl_ONU number:=0;
vl_IEBS number:=0;
vl_Goog number:=0;
vl_etiqueta varchar2(50):= null;
vl_ejec number:=0;


    begin

            For cx in (

                        select distinct GORADID_pidm Pidm,
                                            GORADID_ADID_CODE etiqueta,
                                            decode (STVPAQT_ORIGEN,'A', 'AUTOSERVICIO', 'P', 'PAQUETE') Origen,
                                            STVPAQT_DETAIL_CODE Codigo,
                                            SZTALIA_SEQ
                        from GORADID
                        join SZTALIA on SZTALIA_CODE = GORADID_ADID_CODE
                        join STVPAQT on STVPAQT_ADID_CODE = GORADID_ADID_CODE and SZTALIA_LVEL = STVPAQT_LEVL_CODE
                        where 1= 1
                        and  GORADID_pidm = p_pidm
                        And SZTALIA_LVEL = p_nivel
                        order by 5,3,4

                   ) loop

                            vl_existe :=0;
                            Begin

                                    Select count(*)
                                        Into vl_existe
                                    from tbraccd
                                    where 1= 1
                                    And tbraccd_pidm = cx.pidm
                                    And substr (tbraccd_detail_code, 3,2) = cx.codigo
                                    ;
                            Exception
                                 When Others then
                                  vl_existe:=0;
                            End;

                            If vl_existe >= 1 then
                             vl_cadena :=cx.etiqueta ||' '||cx.origen;
                             vl_cadena_F :=vl_cadena_F|| ' , '||vl_cadena;

                           End if;


            End loop;

            If vl_cadena_F is null then

                     Begin
                         Select distinct  GORADID_ADID_CODE etiqueta
                            Into vl_etiqueta
                        from GORADID
                        join SZTALIA on SZTALIA_CODE = GORADID_ADID_CODE
                        join STVPAQT on STVPAQT_ADID_CODE = GORADID_ADID_CODE and SZTALIA_LVEL = STVPAQT_LEVL_CODE
                        where 1= 1
                        and  GORADID_pidm = p_pidm
                        And SZTALIA_LVEL = p_nivel;
                     Exception
                        When others then
                            vl_etiqueta:= null;
                     End;

             --  dbms_output.put_line('cadena_vacia:'||vl_cadena_F);
                   If vl_etiqueta is null then
                        vl_cadena_F:= null;

                  ElsIf vl_etiqueta = 'UNIC'  then


                        Begin
                            Select count(*)
                            Into vl_UNICEF
                            from SZTDTEC
                            where 1= 1
                            and SZTDTEC_PROGRAM = p_programa
                            And SZTDTEC_PROGRAMA_COMP like '%UNICEF%';
                              vl_cadena_F :=vl_etiqueta||'  '|| 'PAQUETE';
                        Exception
                            When Others then
                                vl_UNICEF:=0;
                        End;

                  Elsif  vl_etiqueta = 'MUBA'  then

                            Begin
                                Select count(*)
                                Into vl_UBA
                                from SZTDTEC
                                where 1= 1
                                and SZTDTEC_PROGRAM = p_programa
                                And SZTDTEC_PROGRAMA_COMP like '%UBA%';
                                 vl_cadena_F :=vl_etiqueta||'  '|| 'PAQUETE';
                            Exception
                                When Others then
                                    vl_UBA:=0;
                            End;

                  Elsif   vl_etiqueta = 'MPOL'  then
                                Begin
                                    Select count(*)
                                    Into vl_POL
                                    from SZTDTEC
                                    where 1= 1
                                    and SZTDTEC_PROGRAM = p_programa
                                    And SZTDTEC_PROGRAMA_COMP like '%Polonia%';
                                    vl_cadena_F :=vl_etiqueta||'  '|| 'PAQUETE';
                                Exception
                                    When Others then
                                        vl_POL:=0;
                                End;

                  Elsif   vl_etiqueta = 'MONU'  then

                                    Begin
                                        Select count(*)
                                        Into vl_ONU
                                        from SZTDTEC
                                        where 1= 1
                                        and SZTDTEC_PROGRAM = p_programa
                                        And SZTDTEC_PROGRAMA_COMP like '%ONU%';
                                        vl_cadena_F :=vl_etiqueta||'  '|| 'PAQUETE';
                                    Exception
                                        When Others then
                                            vl_ONU:=0;
                                    End;

                  Elsif   vl_etiqueta = 'IEBS'  then

                                        Begin
                                            Select count(*)
                                            Into vl_IEBS
                                            from SZTDTEC
                                            where 1= 1
                                            and SZTDTEC_PROGRAM = p_programa
                                            And SZTDTEC_PROGRAMA_COMP like '%IEBS%';
                                             vl_cadena_F :=vl_etiqueta||'  '|| 'PAQUETE';
                                        Exception
                                            When Others then
                                                vl_IEBS:=0;
                                        End;

                  Elsif   vl_etiqueta = 'GADS'  then

                                            Begin
                                                Select count(*)
                                                Into vl_Goog
                                                from SZTDTEC
                                                where 1= 1
                                                and SZTDTEC_PROGRAM = p_programa
                                                And SZTDTEC_PROGRAMA_COMP like '%Google%';
                                                vl_cadena_F :=vl_etiqueta||'  '|| 'PAQUETE';
                                            Exception
                                                When Others then
                                                    vl_Goog:=0;
                                            End;

                  Elsif   vl_etiqueta = 'EJEC'  then

                                            Begin
                                                Select count(*)
                                                Into vl_Goog
                                                from SZTDTEC
                                                where 1= 1
                                                and SZTDTEC_PROGRAM = p_programa
                                                And SZTDTEC_MOD_TYPE = 'S';
                                                vl_cadena_F :=vl_etiqueta||'  '|| 'PAQUETE';
                                            Exception
                                                When Others then
                                                    vl_Goog:=0;
                                            End;

                  End if;



            End if;

                Return (vl_cadena_F);

    Exception
        when Others then
         vl_cadena_F := ' ';
          Return (vl_cadena_F);
    End f_forma_adquisicion;


Function f_fecha_adquisicion (p_pidm in number, p_nivel varchar2, p_programa varchar2) Return varchar2
as

 vl_existe varchar2(250) :=null;
vl_cadena varchar2(500):= null;
vl_cadena_F varchar2(500):= null;
vl_fecha  varchar2(50);
vl_etiqueta varchar2(50):= null;

    begin

            For cx in (

                        select distinct GORADID_pidm Pidm,
                                            GORADID_ADID_CODE etiqueta,
                                            decode (STVPAQT_ORIGEN,'A', 'AUTOSERVICIO', 'P', 'PAQUETE') Origen,
                                            STVPAQT_DETAIL_CODE Codigo,
                                            SZTALIA_SEQ
                        from GORADID
                        join SZTALIA on SZTALIA_CODE = GORADID_ADID_CODE
                        join STVPAQT on STVPAQT_ADID_CODE = GORADID_ADID_CODE and SZTALIA_LVEL = STVPAQT_LEVL_CODE
                        where 1= 1
                        and  GORADID_pidm = p_pidm
                        And SZTALIA_LVEL = p_nivel
                        order by 5,3,4

             ) loop

                            vl_existe :=null;
                            Begin

                                 Select distinct max (trunc (a.TBRACCD_EFFECTIVE_DATE))
                                        Into vl_existe
                                    from tbraccd a
                                    where 1= 1
                                    And a.tbraccd_pidm = cx.pidm
                                    And substr (a.tbraccd_detail_code, 3,2) = cx.codigo -- 'SY'-- cx.codigo  XW
                                    And trunc (a.TBRACCD_EFFECTIVE_DATE) = (select min (trunc (a1.TBRACCD_EFFECTIVE_DATE))
                                                                                                       from TBRACCD a1
                                                                                                       Where a.tbraccd_pidm = a1.tbraccd_pidm
                                                                                                        And substr (a.tbraccd_detail_code, 3,2)  = substr (a1.tbraccd_detail_code, 3,2)
                                                                                                   );
                            Exception
                                 When Others then
                                  vl_existe:=null;
                            End;

                            If vl_existe is not null  then
                             vl_cadena :=cx.etiqueta ||' '||vl_existe;
                             vl_cadena_F :=vl_cadena_F|| ' , '||vl_cadena;

                           End if;


            End loop;

            If  vl_existe is null then

                     Begin
                         Select distinct  GORADID_ADID_CODE etiqueta
                            Into vl_etiqueta
                        from GORADID
                        join SZTALIA on SZTALIA_CODE = GORADID_ADID_CODE
                        join STVPAQT on STVPAQT_ADID_CODE = GORADID_ADID_CODE and SZTALIA_LVEL = STVPAQT_LEVL_CODE
                        where 1= 1
                        and  GORADID_pidm = p_pidm
                        And SZTALIA_LVEL = p_nivel;
                     Exception
                        When others then
                            vl_etiqueta:= null;
                     End;


                     If vl_etiqueta is not null then

                             Begin

                                        Select distinct max (trunc (SARAPPD_APDC_DATE)) Fecha_Adquision
                                            Into vl_fecha
                                        from saradap a
                                        join sarappd b on b.sarappd_pidm = a.saradap_pidm   and b.SARAPPD_TERM_CODE_ENTRY =  a.SARADAP_TERM_CODE_ENTRY and b.SARAPPD_APPL_NO = a.SARADAP_APPL_NO
                                        where 1 = 1
                                        And a.saradap_pidm = p_pidm
                                        and a.SARADAP_APST_CODE ='A'
                                        And a.SARADAP_PROGRAM_1 = p_programa
                                        And a.SARADAP_APPL_NO = (select max (a1.SARADAP_APPL_NO)
                                                                                    from SARADAP a1
                                                                                    Where a.saradap_pidm = a1.saradap_pidm
                                                                                    And a.SARADAP_APST_CODE = a1.SARADAP_APST_CODE
                                                                                    And a.SARADAP_PROGRAM_1 = a1.SARADAP_PROGRAM_1) ;
                             Exception
                                When Others then
                                   vl_fecha:= null;
                             End;

                              vl_cadena_F := vl_etiqueta ||' '||vl_fecha;

                              If vl_fecha is null then
                                  vl_cadena_F:= null;
                              End if;

                     End if;

             End if;


             Return (vl_cadena_F);

    Exception
        when Others then
         vl_cadena_F := ' ';
          Return (vl_cadena_F);
    End f_fecha_adquisicion;


    Function f_inserta_gtvadid(p_clave in varchar2, p_descripcion varchar2, p_usuario varchar2) Return varchar2
    As
     vl_salida varchar2(250) := 'EXITO';
     vl_existe number:=0;

    Begin

              Begin
                    Select count(*)
                        Into vl_existe
                    from gtvadid
                    where GTVADID_CODE = p_clave;
               Exception
                When Others then
                     vl_existe:=0;
              End;

              If vl_existe = 0 then


                          Begin
                                Insert into gtvadid values (p_clave,
                                                                      p_descripcion,
                                                                      p_usuario,
                                                                      trunc (sysdate),
                                                                      'Banner',
                                                                      'N',
                                                                      null,
                                                                      null,
                                                                      null);
                               Commit;
                          Exception
                            When Others then
                                 vl_salida:= 'Se presento un error al insertar '||sqlerrm;
                          End;

              Else
                        vl_salida :='El registro '||p_clave ||'  Ya esta dado de alta';

              End if;

              Return (vl_salida);

    Exception
           when Others then
            vl_salida:= 'Error General '||sqlerrm;
               Return (vl_salida);
    End f_inserta_gtvadid;
Function f_categoria_docente(p_matricula varchar2)Return varchar2
    as
        l_categoria varchar2(10);

    Begin
            Begin

                    select distinct SIBINST_FCTG_CODE
                    Into l_categoria
                    from SPRIDEN, SIBINST
                    where SPRIDEN_PIDM = SIBINST_PIDM
                        and SPRIDEN_ID = p_matricula
                        and SIBINST_FCTG_CODE = 'DPEX'
                        and SPRIDEN_CHANGE_IND is null;


            EXCEPTION WHEN OTHERS THEN
                  l_categoria:='ERROR';
            END;

        return(l_categoria);

End f_categoria_docente;

function f_calcula_bimestres(p_pidm number,p_sp number)return varchar2
is
l_BIMESTRE number;

begin
      for c in
        (select *
        from tztprog
        where 1=1
        AND PIDM=P_pidm
        and sp=p_sp
        )
   loop

        begin

         SELECT SUM (BIMESTRE)
           INTO l_BIMESTRE
            FROM (
              select COUNT (distinct SFRSTCR_PTRM_CODE)BIMESTRE,SFRSTCR_term_CODE PERIODIO
                                from sfrstcr a
                                where 1 = 1
                                and a.SFRSTCR_RSTS_CODE ='RE'
                                and a.SFRSTCR_STSP_KEY_SEQUENCE =c.sp
                                And SUBSTR (a.SFRSTCR_TERM_CODE,5,1) NOT IN ('8','9')
                                and a.sfrstcr_pidm = c.pidm
                               GROUP BY SFRSTCR_term_CODE
                               ORDER BY 2 DESC
                                );

        EXCEPTION WHEN OTHERS THEN
        l_BIMESTRE:=0;
       END;


   end loop;
    --    dbms_output.put_line('Bimestre '||l_BIMESTRE);
     return (l_bimestre);



end f_calcula_bimestres;

Function f_documento_valido (p_pidm in number, p_programa in varchar2, p_documento in varchar2) return varchar2  is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


BEGIN

            Begin

                         select to_char (SARCHKL_ACTIVITY_DATE,'dd/mm/rrrr') ||'*'|| SARCHKL_CKST_CODE Documento
                        into vl_salida
                        from SARCHKL
                        join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_programa
                                                                                               and SARADAP_APPL_NO = SARCHKL_APPL_NO
                        join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
                        where SARCHKL_PIDM = p_pidm
                        And SARCHKL_ADMR_CODE =p_documento;

            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_documento_valido;


Procedure mata_sesion as


BEGIN

            FOR R IN (

                        select distinct sid, serial#, to_char (LOGON_TIME, 'DD') dia, to_char (LOGON_TIME,'HH') hora, LOGON_TIME,
                            to_char (sysdate, 'DD') dia_s, to_char (sysdate,'HH') hora_s,
                            username,status
                        FROM SYS.V_$SESSION
                        WHERE STATUS = 'INACTIVE'
                        and username not in ('GENLPRD','SYS','BANINST1', 'MIGRA', 'SAISUSR', 'UMD')
                    --  And  username = 'DPAZSAN'

            ) LOOP

                            If r.dia||r.hora != r.dia_s||r.hora_s then

                                    dbms_output.put_line(' Salida'|| r.dia||r.hora ||'*'|| r.dia_s||r.hora_s  );

                                execute IMMEDIATE 'ALTER SYSTEM KILL SESSION ''' || R.SID || ',' || R.SERIAL# || ''''||' IMMEDIATE';

                            End if;

            END LOOP;

END mata_sesion;



Procedure p_alinea_descuento as

Begin

            For cx in (

                            Select x.pidm, x.matricula, x.campus, x.fecha_inicio, x.Descuento, tipo_nivel_Correcto, tipo_descuento, tipo_nivel_Correcto||substr (x.Descuento,2,5) Nuevo, x.periodo
                            from (
                            select  a.pidm, a.matricula, a.campus, a.nivel,a.fecha_inicio, TBBESTU_EXEMPTION_CODE Descuento,
                            case
                                When a.nivel = 'EC' then '5'
                                When a.nivel = 'LI' then '1'
                                When a.nivel = 'MA' then '2'
                                When a.nivel = 'MS' then '3'
                                When a.nivel = 'ID' then '7'
                                When a.nivel = 'DO' then '9'
                            end tipo_nivel_Correcto,
                            substr (TBBESTU_EXEMPTION_CODE,1,1) tipo_descuento, b.TBBESTU_TERM_CODE Periodo
                            from tztprog a
                            join TBBESTU b on b.TBBESTU_pidm = a.pidm
                            And b.TBBESTU_STUDENT_EXPT_ROLL_IND ='Y' and TBBESTU_DEL_IND is null
                            and b.TBBESTU_TERM_CODE in (select max (b1.TBBESTU_TERM_CODE)
                                                                                                                                      from TBBESTU b1
                                                                                                                                      Where b.TBBESTU_pidm = b1.TBBESTU_pidm)
                            where 1=1
                            and a.estatus ='MA'
                            And a.nivel in ('LI', 'MA', 'DO')
                            And a.sp = (select max (a1.sp)
                                                from tztprog a1
                                                where 1=1
                                                And a.pidm = a1.pidm)
                                                ) x
                            where x.tipo_nivel_Correcto !=  x.tipo_descuento
                            order by 5

            ) loop

                    Begin
                                Update TBBESTU
                                set TBBESTU_EXEMPTION_CODE = cx.nuevo,
                                TBBESTU_USER_ID ='MASIVO',
                                TBBESTU_DATA_ORIGIN ='MASIVO'
                                Where TBBESTU_TERM_CODE = cx.periodo
                                And TBBESTU_PIDM =  cx.pidm
                                And TBBESTU_STUDENT_EXPT_ROLL_IND ='Y'
                                And TBBESTU_DEL_IND is null;
                    Exception
                        When Others then
                            null;
                    End;


            End loop;

            Commit;



End p_alinea_descuento;

function f_programa_autoenr(p_campus varchar2, p_rvoe varchar2) RETURN pkg_utilerias.prog_out as
--function f_avcu_out_titulo(pidm number, usu_siu varchar2) RETURN pkg_utilerias.avcu_out_tit;

                prog_out_aut pkg_utilerias.prog_out;

Begin
                          open prog_out_aut
                            FOR
                                   select a.SZTDTEC_PROGRAM Programa, a.SZTDTEC_PROGRAMA_COMP Descripcion , a.SZTDTEC_TERM_CODE Periodo, a.SZTDTEC_MOD_TYPE Modalidad
                                    from SZTDTEC a
                                    where 1=1
                                    And a.SZTDTEC_CAMP_CODE = p_campus
                                    ANd a.SZTDTEC_NUM_RVOE = p_rvoe
                                    And a.SZTDTEC_MOD_TYPE = 'OL'
                                    And A.SZTDTEC_AUTOENR = '1'
                                    And a.SZTDTEC_TERM_CODE in (select max (a1.SZTDTEC_TERM_CODE)
                                                                                        from SZTDTEC a1
                                                                                        Where a.SZTDTEC_PROGRAM = a1.SZTDTEC_PROGRAM
                                                                                        And A1.SZTDTEC_AUTOENR = '1');

                        RETURN (prog_out_aut);

END f_programa_autoenr;


Function f_moneda (p_codigo varchar2) return varchar2 as
vl_salida varchar2(10):= null;

Begin

        Begin
                select TVRDCTX_CURR_CODE
                    Into vl_salida
                from TVRDCTX
                where TVRDCTX_DETC_CODE = p_codigo;
        Exception
                When Others then
                vl_salida:= 'MXN';
        End;

        Return vl_salida;
End f_moneda;

procedure bitacora (vl_pidm in number, vl_periodo in varchar2, vl_sp in number, vl_programa in varchar2, vl_comentario in varchar2, vl_origen in varchar2)

as

  vn_sec_SGRSCMT number:=0;
  l_descripcion varchar2(2000):= null;

    Begin

        Begin
              SELECT NVL(MAX(SGRSCMT_SEQ_NO),0)+1
            INTO vn_sec_SGRSCMT
          FROM SGRSCMT
          WHERE SGRSCMT_PIDM  = vl_pidm
          AND SGRSCMT_TERM_CODE = vl_periodo;
        Exception
                When Others then
                  vn_sec_SGRSCMT :=1;
        End;

         l_descripcion:=   vl_comentario||' ' ||vl_periodo ||' '||vl_programa;



        BEgin

             INSERT INTO SGRSCMT (
                SGRSCMT_PIDM
            , SGRSCMT_SEQ_NO
            , SGRSCMT_TERM_CODE
            , SGRSCMT_COMMENT_TEXT
            , SGRSCMT_ACTIVITY_DATE
            , SGRSCMT_DATA_ORIGIN
            , SGRSCMT_USER_ID
            , SGRSCMT_VPDI_CODE
             )
             VALUES (
                vl_pidm
              , vn_sec_SGRSCMT
              , vl_periodo
              , l_descripcion
              , SYSDATE
              , vl_origen
              , user
              , vl_sp
             );
        Exception
                When Others then
                null;
        End;


Exception
    when others then
        null;
End bitacora;

Function f_curp (p_pidm in varchar2) return varchar2 is

vl_salida varchar2(20):= '';
 begin
      BEGIN

        SELECT GORADID_ADDITIONAL_ID
          into vl_salida
        FROM GORADID A
        WHERE 1=1
        AND A.GORADID_PIDM = FGET_PIDM (p_pidm)
        AND A.GORADID_ADID_CODE = 'CURP'
        AND  (A.GORADID_SURROGATE_ID) = (SELECT MAX (A1.GORADID_SURROGATE_ID)
                                                                        FROM  GORADID A1
                                                                        WHERE 1=1
                                                                        AND A.GORADID_ADID_CODE = A1.GORADID_ADID_CODE
                                                                        AND A.GORADID_PIDM =A1.GORADID_PIDM);

      Exception
        When Others then
            vl_salida := null;
      end;

        return vl_salida;
   Exception
    When Others then
      vl_salida :=null;
     return vl_salida;

 END f_curp;

Function f_folio_pago  (p_pidm in number, p_secuencia in number ) return varchar2 is

vl_salida varchar2(500):= '';

Begin



       Begin

             SELECT DISTINCT
                (SELECT DISTINCT SUBSTR((SELECT DISTINCT ((SELECT DISTINCT TBRACDT_TEXT FROM TBRACDT WHERE TBRACDT_PIDM = A1.TBRACCD_PIDM AND TBRACDT_TRAN_NUMBER = A1.TBRACCD_TRAN_NUMBER AND TBRACDT_SEQ_NUMBER = 1)||(SELECT DISTINCT TBRACDT_TEXT FROM TBRACDT WHERE TBRACDT_PIDM = A1.TBRACCD_PIDM AND TBRACDT_TRAN_NUMBER = A1.TBRACCD_TRAN_NUMBER AND TBRACDT_SEQ_NUMBER = 2))
                 FROM TBRACCD A1
                 WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                 AND A1.TBRACCD_TRAN_NUMBER = A.TBRACCD_TRAN_NUMBER),-------CADENA COMPLETA
                (SELECT INSTR((SELECT DISTINCT (SELECT DISTINCT TBRACDT_TEXT
                 FROM TBRACDT
                 WHERE TBRACDT_PIDM = A1.TBRACCD_PIDM
                 AND TBRACDT_TRAN_NUMBER = A1.TBRACCD_TRAN_NUMBER
                 AND TBRACDT_SEQ_NUMBER = 1) ||(SELECT DISTINCT TBRACDT_TEXT
                                                FROM TBRACDT
                                                WHERE TBRACDT_PIDM = A1.TBRACCD_PIDM
                                                AND TBRACDT_TRAN_NUMBER = A1.TBRACCD_TRAN_NUMBER
                                                AND TBRACDT_SEQ_NUMBER = 2)FOLIO_PAGO
                 FROM TBRACCD A1
                 WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                 AND A1.TBRACCD_TRAN_NUMBER = A.TBRACCD_TRAN_NUMBER),'_',-1,1)CARA
                 FROM DUAL)+1,------NUMERO DE CARACTERESA BUSCAR
                (SELECT DISTINCT (SELECT LENGTH((SELECT DISTINCT
                (SELECT DISTINCT TBRACDT_TEXT
                 FROM TBRACDT
                 WHERE TBRACDT_PIDM = A1.TBRACCD_PIDM
                 AND TBRACDT_TRAN_NUMBER = A1.TBRACCD_TRAN_NUMBER
                 AND TBRACDT_SEQ_NUMBER = 1) ||(SELECT DISTINCT TBRACDT_TEXT
                                                FROM TBRACDT
                                                WHERE TBRACDT_PIDM = A1.TBRACCD_PIDM
                                                AND TBRACDT_TRAN_NUMBER = A1.TBRACCD_TRAN_NUMBER
                                                AND TBRACDT_SEQ_NUMBER = 2)FOLIO_PAGO
                 FROM TBRACCD A1
                 WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                 AND A1.TBRACCD_TRAN_NUMBER = A.TBRACCD_TRAN_NUMBER))------LARGO DE CADENA
                 -
                (SELECT DISTINCT INSTR((SELECT DISTINCT
                (SELECT DISTINCT TBRACDT_TEXT
                 FROM TBRACDT
                 WHERE TBRACDT_PIDM = A1.TBRACCD_PIDM
                 AND TBRACDT_TRAN_NUMBER = A1.TBRACCD_TRAN_NUMBER
                 AND TBRACDT_SEQ_NUMBER = 1) ||(SELECT DISTINCT TBRACDT_TEXT
                                                FROM TBRACDT
                                                WHERE TBRACDT_PIDM = A1.TBRACCD_PIDM
                                                AND TBRACDT_TRAN_NUMBER = A1.TBRACCD_TRAN_NUMBER
                                                AND TBRACDT_SEQ_NUMBER = 2)FOLIO_PAGO
                FROM TBRACCD A1
                WHERE A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                AND A1.TBRACCD_TRAN_NUMBER = A.TBRACCD_TRAN_NUMBER),'_',-1,1)CARA
                FROM DUAL)TAMAÑO--------NUMERO DE LA POSICION DEL CARACTER
                FROM DUAL)TOTAL--------TOTAL DE CARACTERES A SUBSTRAER
                FROM DUAL))
                FROM DUAL)FOLIO_DE_PAGO
                   Into vl_salida
            FROM TBRACCD A,TBBDETC
            WHERE A.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
            AND A.TBRACCD_PIDM = p_pidm
            AND A.TBRACCD_TRAN_NUMBER = p_secuencia;
       Exception
        When OThers then
            vl_salida:=null;
       End;

       return vl_salida;
Exception
    When Others then
      vl_salida :=null;
     return vl_salida;

End f_folio_pago;

Function f_cadena_etiqueta (p_pidm in number) return varchar2  is

vl_salida varchar2(500):= null;
vl_cadena varchar2(500):= null;

Begin

    For cx in (

       Select distinct GTVADID_DESC ||'|' Etiqueta
                from goradid
                join gtvADID on GTVADID_CODE = GORADID_ADID_CODE
                where 1=1
                And GORADID_ADID_CODE  in (select ZSTPARA_PARAM_ID
                         from ZSTPARA
                         Where ZSTPARA_MAPA_ID = 'ETIQUETA_SIU_IN'
                         )
                and goradid_pidm = p_pidm

    ) loop

            vl_cadena:= null;

            vl_cadena:= cx.Etiqueta;

            vl_salida:= vl_salida||vl_cadena;

    End loop;

       return vl_salida;
Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
End f_cadena_etiqueta;

PROCEDURE P_UPSELLING_CHANGE AS

/******************************************************************************
   NAME:      P_UPSELLING_CHANGE
   PURPOSE:   Cambio de etiqueta de Colegiatura Diferida(CFDI) a Titulación
              Incluida(TIIN) en GORADID, cuando se detecta que se haya
              saldado por Autoservicio(TZTCOTA).

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        30/01/2023  FND@Create       1. Creación del procedimiento.


   NOTES:     Aplicará los cambios de etiqueta bajo las siguientes condiciones:

              => Cuando es por Pago único: se considera cuando existe un solo
                 cargo y que aplicados sea igual a NULO o 0 en Autoservicio
                 (TZTCOTA).
              => Cuando es por saldo liquidado: se considera cuando la cantidad
                 de cargos sea igual a la cantidad de aplicados en Autoservicio
                 (TZTCOTA).

              Este procedimiento será ejecutado por un proceso automatizado(JOB)
              de nombre: (Pend. por confirmar)

******************************************************************************
   MARCAS DE CAMBIO:
   No. 1
   Clave de cambio: 001-DDMMYYYY-(Autor@Iniciales)
   Autor: (Nombre del autor)
   Descripción: Descripción de ajuste del cambio.
******************************************************************************
   No. 2
   Clave de cambio: 002-DDMMYYYY-(Autor@Iniciales)
   Autor: (Nombre del autor)
   Descripción: Descripción de ajuste del cambio.
******************************************************************************

******************************************************************************/

-- Variables del proceso
VL_ERROR            VARCHAR(1000)   := NULL;
VL_MAX_SEQ          NUMBER;
VL_MAX_PERIODO      VARCHAR2(6);
VL_MAX_SURROGATE    NUMBER;

BEGIN

-- Recuperación de Pidm's que cumplan las condiciones de saldo liquidado en Autoservicio(TZTCOTA).

    FOR CUR_COTA_SALDO IN (
                        -- Pago único(TZTCOTA): Cuando cargo = 1 y aplicados es Nulo o 0.
                            SELECT COTA.TZTCOTA_PIDM PIDM
                            FROM   TZTCOTA COTA
                            WHERE  1 = 1
                            AND    COTA.TZTCOTA_ORIGEN = 'CFDI'
                            AND    COTA.TZTCOTA_STATUS = 'A'
                            AND    COTA.TZTCOTA_PIDM IN
                                   (
                                          SELECT COTA1.TZTCOTA_PIDM
                                          FROM   TZTCOTA COTA1
                                          WHERE  1 = 1
                                          AND    COTA1.TZTCOTA_ORIGEN = 'CFDI'
                                          AND    COTA1.TZTCOTA_STATUS = 'A'
                                          AND    COTA1.TZTCOTA_CARGOS = 1
                                          AND    (
                                                        COTA1.TZTCOTA_APLICADOS IS NULL
                                                 OR     COTA1.TZTCOTA_APLICADOS = 0)
                                          AND    COTA1.TZTCOTA_SEQNO =
                                                 (
                                                        SELECT MAX(COTA2.TZTCOTA_SEQNO)
                                                        FROM   TZTCOTA COTA2
                                                        WHERE  1 = 1
                                                        AND    COTA2.TZTCOTA_ORIGEN = 'CFDI'
                                                        AND    COTA2.TZTCOTA_STATUS = 'A'
                                                        AND    COTA2.TZTCOTA_PIDM = COTA1.TZTCOTA_PIDM
                                                        AND    COTA2.TZTCOTA_CARGOS = 1
                                                        AND    (
                                                                      COTA2.TZTCOTA_APLICADOS IS NULL
                                                               OR     COTA2.TZTCOTA_APLICADOS = 0)))
                            AND    COTA.TZTCOTA_CARGOS = 1
                            AND    (
                                          COTA.TZTCOTA_APLICADOS IS NULL
                                   OR     COTA.TZTCOTA_APLICADOS = 0)
                            AND    COTA.TZTCOTA_SEQNO =
                                   (
                                          SELECT MAX (COTA1.TZTCOTA_SEQNO)
                                          FROM   TZTCOTA COTA1
                                          WHERE  1 = 1
                                          AND    COTA1.TZTCOTA_ORIGEN = 'CFDI'
                                          AND    COTA1.TZTCOTA_STATUS = 'A'
                                          AND    COTA1.TZTCOTA_PIDM = COTA.TZTCOTA_PIDM
                                          AND    (
                                                        COTA1.TZTCOTA_CARGOS = 1
                                                 OR     COTA1.TZTCOTA_APLICADOS = 0))
                            UNION
                        -- Saldo liquidado(TZTCOTA): Cuando el No. de cargos sea igual al No. de aplicados.
                            SELECT COTA.TZTCOTA_PIDM PIDM
                            FROM   TZTCOTA COTA
                            WHERE  1 = 1
                            AND    COTA.TZTCOTA_ORIGEN = 'CFDI'
                            AND    COTA.TZTCOTA_STATUS = 'A'
                            AND    COTA.TZTCOTA_PIDM IN
                                   (
                                          SELECT COTA1.TZTCOTA_PIDM
                                          FROM   TZTCOTA COTA1
                                          WHERE  1 = 1
                                          AND    COTA1.TZTCOTA_ORIGEN = 'CFDI'
                                          AND    COTA1.TZTCOTA_STATUS = 'A'
                                          AND    COTA1.TZTCOTA_CARGOS =
                                                 (
                                                        SELECT COTA2.TZTCOTA_APLICADOS
                                                        FROM   TZTCOTA COTA2
                                                        WHERE  1 = 1
                                                        AND    COTA2.TZTCOTA_ORIGEN = 'CFDI'
                                                        AND    COTA2.TZTCOTA_STATUS = 'A'
                                                        AND    COTA2.TZTCOTA_PIDM = COTA1.TZTCOTA_PIDM
                                                        AND    COTA2.TZTCOTA_SEQNO =
                                                               (
                                                                      SELECT MAX(COTA3.TZTCOTA_SEQNO)
                                                                      FROM   TZTCOTA COTA3
                                                                      WHERE  1 = 1
                                                                      AND    COTA3.TZTCOTA_PIDM = COTA2.TZTCOTA_PIDM
                                                                      AND    COTA3.TZTCOTA_ORIGEN = 'CFDI'
                                                                      AND    COTA3.TZTCOTA_STATUS = 'A')))
                            AND    COTA.TZTCOTA_CARGOS =
                                   (
                                          SELECT COTA1.TZTCOTA_APLICADOS
                                          FROM   TZTCOTA COTA1
                                          WHERE  1 = 1
                                          AND    COTA1.TZTCOTA_ORIGEN = 'CFDI'
                                          AND    COTA1.TZTCOTA_STATUS = 'A'
                                          AND    COTA1.TZTCOTA_PIDM = COTA.TZTCOTA_PIDM
                                          AND    COTA1.TZTCOTA_SEQNO =
                                                 (
                                                        SELECT MAX(COTA2.TZTCOTA_SEQNO)
                                                        FROM   TZTCOTA COTA2
                                                        WHERE  1 = 1
                                                        AND    COTA2.TZTCOTA_PIDM = COTA.TZTCOTA_PIDM
                                                        AND    COTA2.TZTCOTA_ORIGEN = 'CFDI'
                                                        AND    COTA2.TZTCOTA_STATUS = 'A'))
                          )LOOP

                            -- Actualización de registros: Cambio de etiqueta(GORADID) de COLEGIATURA DIFERIDA(CFDI) a TITULACIÓN INCLUIDA(TIIN),
                            --                             de acuerdo al resultado del cursor CUR_COTA_SALDO.
                                BEGIN
                                    UPDATE GORADID GORA
                                       SET GORA.GORADID_ADID_CODE = 'TIIN'
                                          ,GORA.GORADID_ADDITIONAL_ID = 'TITULACION INCLUIDA'
                                          ,GORA.GORADID_DATA_ORIGIN  = 'ACTUALIZA ETIQUETA'
                                          ,GORA.GORADID_USER_ID = 'ACTUALIZA_TZTCOTA'
                                          ,GORA.GORADID_ACTIVITY_DATE = SYSDATE
                                     WHERE 1 = 1
                                       AND GORA.GORADID_ADID_CODE = 'CFDI'
                                       AND GORA.GORADID_PIDM = CUR_COTA_SALDO.PIDM;

                                EXCEPTION
                                    WHEN OTHERS THEN
                                        VL_ERROR := '(Exc.) Error al actualizar registros: cambio de etiqueta de Col. Dif.(CFDI) a Tit. Inc.(TIIN)... Favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM||CHR(10)||CHR(10);
                                END;

                          -- Registro en bitácora.

                                -- Recuperación de registros en GORADID que fueron actualizados por el cambio de etiqueta, de Col. Dif.(CFDI) a Tit. Inc.(TIIN)
                                    FOR CUR_RECU_GORA IN (
                                                                    SELECT GORA.GORADID_PIDM PIDM
                                                                      FROM GORADID GORA
                                                                     WHERE 1 = 1
                                                                       AND GORA.GORADID_ADID_CODE = 'TIIN'
                                                                       AND GORA.GORADID_ADDITIONAL_ID = 'TITULACION INCLUIDA'
                                                                       AND GORA.GORADID_DATA_ORIGIN = 'ACTUALIZA ETIQUETA'
                                                                       AND GORA.GORADID_USER_ID = 'ACTUALIZA_TZTCOTA'
                                                                       AND TRUNC(GORA.GORADID_ACTIVITY_DATE) = TRUNC(SYSDATE)
                                                               )LOOP

                                                               -- Busca el No. máximo de registro de la secuencia en la tabla SGRSCMT para el alumno.
                                                                    BEGIN
                                                                        SELECT NVL(MAX(SGRSCMT_SEQ_NO),0) + 1
                                                                          INTO VL_MAX_SEQ
                                                                          FROM SGRSCMT
                                                                         WHERE 1 = 1
                                                                           AND SGRSCMT_PIDM = CUR_RECU_GORA.PIDM;

                                                                    EXCEPTION
                                                                        WHEN NO_DATA_FOUND THEN
                                                                            VL_MAX_SEQ := 0;
                                                                    END;

                                                               -- Busca el No. máximo de registro del Periodo en la tabla SGBSTDN para el alumno.
                                                                    BEGIN
                                                                        SELECT NVL(MAX(SGBSTDN_TERM_CODE_EFF),'SIN PERIODO')
                                                                          INTO VL_MAX_PERIODO
                                                                          FROM SGBSTDN
                                                                         WHERE 1 = 1
                                                                           AND SGBSTDN_PIDM = CUR_RECU_GORA.PIDM;

                                                                    EXCEPTION
                                                                        WHEN NO_DATA_FOUND THEN
                                                                            VL_MAX_PERIODO := NULL;
                                                                    END;

                                                               -- Busca el No. máximo de surrogate del ID en la tabla SGRSCMT más 1 para el alumno
                                                                    BEGIN
                                                                        SELECT NVL(MAX(SGRSCMT_SURROGATE_ID),0) + 1
                                                                          INTO VL_MAX_SURROGATE
                                                                          FROM SGRSCMT
                                                                         WHERE 1 = 1
                                                                           AND SGRSCMT_PIDM = CUR_RECU_GORA.PIDM;

                                                                    EXCEPTION
                                                                        WHEN NO_DATA_FOUND THEN
                                                                            VL_MAX_SURROGATE := 0;
                                                                    END;

                                                               -- Inserta registro en la tabla SGRSCMT
                                                                    BEGIN
                                                                         INSERT INTO SGRSCMT(SGRSCMT_PIDM
                                                                                            ,SGRSCMT_SEQ_NO
                                                                                            ,SGRSCMT_TERM_CODE
                                                                                            ,SGRSCMT_COMMENT_TEXT
                                                                                            ,SGRSCMT_ACTIVITY_DATE
                                                                                            ,SGRSCMT_SURROGATE_ID
                                                                                            ,SGRSCMT_VERSION
                                                                                            ,SGRSCMT_USER_ID
                                                                                            ,SGRSCMT_DATA_ORIGIN
                                                                                            ,SGRSCMT_VPDI_CODE)
                                                                                      VALUES(CUR_RECU_GORA.PIDM                                                                                                    --SGRSCMT_PIDM
                                                                                            ,VL_MAX_SEQ                                                                                                                 --SGRSCMT_SEQ_NO
                                                                                            ,VL_MAX_PERIODO                                                                                                             --SGRSCMT_TERM_CODE
                                                                                            ,'Actualiza de CFDI a TIIN al PIDM '||CUR_RECU_GORA.PIDM||'. Usuario: '||USER ||' Fecha: ' ||SYSDATE       --SGRSCMT_COMMENT_TEXT
                                                                                            ,SYSDATE                                                                                                                    --SGRSCMT_ACTIVITY_DATE
                                                                                            ,VL_MAX_SURROGATE                                                                                                           --SGRSCMT_SURROGATE_ID
                                                                                            ,1                                                                                                                          --SGRSCMT_VERSION
                                                                                            ,USER                                                                                                                       --SGRSCMT_USER_ID
                                                                                            ,'UPSELLING'                                                                                                                --SGRSCMT_DATA_ORIGIN
                                                                                            ,1);                                                                                                                        --SGRSCMT_VPDI_CODE

                                                                        DBMS_OUTPUT.PUT_LINE('(Qry,) Registro a la bitácora(SGRSCMT) con éxito... '||CHR(10)||CHR(10));

                                                                    EXCEPTION
                                                                        WHEN OTHERS THEN
                                                                              VL_ERROR := 'Error al insertar en la tabla SGRSCMT  para cambio de COLEGIATURA DIFERIDA(CFDI) A TITULACIÓN INCLUIDA(PAGO ÚNICO)(TIIN), favor de revisar... '||CHR(10)||'SQLCODE: '||SQLCODE||CHR(10)||SQLERRM;

                                                                    END;

                                                               END LOOP;

                          END LOOP;


        -- Confirmar el registro en bitácora
        IF VL_ERROR IS NULL THEN

            COMMIT;

        END IF;

END P_UPSELLING_CHANGE;
        
Function f_valida_metamap (p_pidm in number) return number is 

vl_salida number := 0;

Begin


            Begin 
            
                     Select distinct max (x.existe)
                        Into vl_salida
                     from (
                        Select count(*) existe
                        from tztprog a
                        where 1=1
                        and a.campus in ('ARG','UTL', 'UTS', 'COL', 'BOL', 'CHI', 'DOM', 'ECU','SAL', 'ESP', 'USA', 'GUA', 'PAN', 'PAR', 'PER', 'URU')
                        And trunc (a.FECHA_INICIO) between '17/07/2023' and '01/04/2024'
                        And a.fecha_primera is null
                        And a.estatus ='MA'
                        And a.SGBSTDN_STYP_CODE in ('F','C', 'N')
                        And a.sp = (select max (a1.sp)
                                    from tztprog a1
                                    Where a.pidm = a1.pidm)
                        And a.pidm = p_pidm 
                        union
                        Select count(*) existe
                        from tztprog a
                        where 1=1
                        and a.campus in ('ARG','UTL', 'UTS', 'COL', 'BOL', 'CHI', 'DOM', 'ECU','SAL', 'ESP', 'USA', 'GUA', 'PAN', 'PAR', 'PER', 'URU')
                        And trunc (a.fecha_primera) between '17/07/2023' and '01/04/2024'
                        And a.estatus ='MA'
                        And a.SGBSTDN_STYP_CODE in ('F','C', 'N')
                        And a.sp = (select max (a1.sp)
                                    from tztprog a1
                                    Where a.pidm = a1.pidm)
                       And a.pidm = p_pidm 
                       order by 1 asc   
                      ) x;
          Exception
            When Others then 
              vl_salida:=0;     
          End;  

       return vl_salida;
       
Exception
    When Others then
      vl_salida :=0;
     return vl_salida;
End f_valida_metamap;

function f_moneda_ucamp(p_campus varchar2, p_moneda varchar2) RETURN pkg_utilerias.moneda_out as


                moneda_out_aut pkg_utilerias.moneda_out;

Begin
                          open moneda_out_aut
                            FOR
                                select distinct SZVCAMP_CAMP_CODE Campus,
                                                TBBDETC_DETAIL_CODE codigo, 
                                                TBBDETC_DESC descripcion, 
                                                TZTNCD_CONCEPTO Tipo, 
                                                TVRDCTX_CURR_CODE Moneda 
                                from tbbdetc 
                                join tvrdctx on TVRDCTX_DETC_CODE = tbbdetc_detail_code
                                join  TZTNCD on TZTNCD_CODE = tbbdetc_detail_code
                                join SZVCAMP on SZVCAMP_CAMP_ALT_CODE = substr (tbbdetc_detail_code,1,2)
                                where 1=1 
                                And TBBDETC_TYPE_IND ='P'
                                And TBBDETC_DESC not like '%DOM'
                                And TZTNCD_CONCEPTO = 'Deposito'
                                And SZVCAMP_CAMP_CODE = p_campus
                                And TVRDCTX_CURR_CODE = p_moneda
                                order by 1 asc;                   

                        RETURN (moneda_out_aut);

END f_moneda_ucamp;

function f_documento_falta (p_pidm in number, p_seq in number) return number as
 
vl_salida number := 0;

Begin

        Begin
               Select distinct count (*)
                   into vl_salida
                from sarchkl
                where 1= 1 
                And SARCHKL_PIDM = p_pidm
                and SARCHKL_APPL_NO = p_seq
                And SARCHKL_CKST_CODE in ('NOACEPTADO', 'FALTALEGALIZACI', 'NOLEGIBLE', 'NORECIBIDO', 'DOCAPOCRIFO', 'SINVALIDEZ');
        Exception
            When others then  
            vl_salida:=0;
        End;

       return vl_salida;
       
Exception
    When Others then
      vl_salida :=0;
     return vl_salida;
End f_documento_falta;

function f_aspirantes(p_campus varchar2, p_nivel varchar2, p_fecha_ini date) RETURN pkg_utilerias.aspira_out as


                aspira_out_aut pkg_utilerias.aspira_out;

Begin
                          open aspira_out_aut
                            FOR
                                Select distinct spriden_id matricula,  
                                          substr (c.SPRIDEN_LAST_NAME, 1, INSTR(c.SPRIDEN_LAST_NAME,'/')-1) || ' '||
                                          substr (c.SPRIDEN_LAST_NAME, INSTR(c.SPRIDEN_LAST_NAME,'/')+1,150) || ' '||
                                          c.SPRIDEN_FIRST_NAME Nombre,
                                          a.saradap_camp_code Campus,
                                          a.saradap_levl_code nivel,
                                          trunc (a.SARADAP_ACTIVITY_DATE)  Fecha_Actividad,
                                          b.sorlcur_start_Date Fecha_Inicio,
                                          f.STVADMT_DESC Tipo,
                                          e.STVSTYP_DESC Tipo_Ingreso, 
                                          d.SARAPPD_APDC_CODE Decision,
                                          pkg_utilerias.f_canal_venta_programa( a.saradap_pidm,a.SARADAP_PROGRAM_1) Canal_Venta
                                         -- pkg_utilerias.f_documento_falta(a.saradap_pidm,a.SARADAP_APPL_NO) Faltantes,
                                         -- a.SARADAP_APPL_NO
                                from saradap a
                                join sorlcur b on sorlcur_pidm = a.saradap_pidm and a.SARADAP_PROGRAM_1 = b.SORLCUR_PROGRAM and b.SORLCUR_CACT_CODE = 'ACTIVE'
                                join spriden c on spriden_pidm = a.saradap_pidm and c.spriden_change_ind is null
                                left join sarappd d on d.sarappd_pidm = a.saradap_pidm  and d.SARAPPD_APPL_NO = a.SARADAP_APPL_NO
                                join stvSTYP e on e.STVSTYP_CODE = SARADAP_STYP_CODE 
                                join STVADMT f on f.STVADMT_CODE = a.SARADAP_ADMT_CODE
                                where 1=1
                                and a.saradap_pidm not in (select x.sgbstdn_pidm
                                                            from sgbstdn x
                                                            )
                                And a.SARADAP_APST_CODE  in ('A')    
                                And pkg_utilerias.f_documento_falta(a.saradap_pidm,a.SARADAP_APPL_NO) > 0   
                                And a.SARADAP_APPL_NO = (select max (a1.SARADAP_APPL_NO)
                                                            from SARADAP a1
                                                          Where a.saradap_pidm = a1.saradap_pidm
                                                         )
                                And a.saradap_camp_code = p_campus
                                And a.saradap_levl_code = p_nivel   
                                --And c.spriden_id ='010513367'   
                                And trunc (b.sorlcur_start_Date) is not null
                                And trunc (b.sorlcur_start_Date)= p_fecha_ini
                                order by 1;

                        RETURN (aspira_out_aut);

END f_aspirantes;


Procedure p_ejecuta_rolado_fecha(p_fecha_inicio date) is 

Begin 

    For cx in (
    
                    Select distinct SFRSTCR_TERM_CODE periodo
                from sfrstcr
                join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                join shrgrde on  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE  and  SHRGRDE_CODE =SFRSTCR_GRDE_CODE and shrgrde_passed_ind = 'Y'
                where SFRSTCR_RSTS_CODE ='RE'
                and SFRSTCR_GRDE_CODE is not null
                and SFRSTCR_GRDE_DATE is null
                And trunc (SSBSECT_PTRM_START_DATE) = p_fecha_inicio
                order by 1
                
              ) Loop
              
              Begin
                  pkg_utilerias.p_rolado_academico (cx.periodo); commit;
              End;   
    
    End Loop;
    Commit;
    
End p_ejecuta_rolado_fecha;



--
--
   FUNCTION f_mat_unica (p_matricula in varchar2) RETURN PKG_UTILERIAS.cursor_out_muni  -- GOG v1 22/09/2022
           AS
                c_out_muni PKG_UTILERIAS.cursor_out_muni;
                ln_pidm   NUMBER;

  BEGIN 
     --Obtiene PIDM para consultar 
     BEGIN
     SELECT FGET_PIDM (p_matricula) 
     INTO ln_pidm
     FROM DUAL;
     EXCEPTION WHEN OTHERS THEN 
     ln_pidm := NULL;
     END;
     
     OPEN c_out_muni         
      FOR 
            SELECT DISTINCT A.GORADID_ADDITIONAL_ID AS DESCRIPCION
              FROM GORADID A
             WHERE     A.GORADID_PIDM = ln_pidm
                   AND A.GORADID_ADID_CODE = 'MUNI';
                               
       RETURN (c_out_muni);
       
  END f_mat_unica;


Procedure p_ejecuta_rolado_fecha_mat(p_matricula in varchar2, p_fecha_inicio date default null) is 

vl_pidm number;

Begin 

     Begin
        Select spriden_pidm
            Into vl_pidm
        from spriden
        where spriden_id = p_matricula
        And spriden_change_ind is null;
     Exception
            When Others then 
          vl_pidm:= null;  
     End;
        

    For cx in (
    
                    Select distinct SFRSTCR_TERM_CODE periodo
                from sfrstcr
                join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                join shrgrde on  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE  and  SHRGRDE_CODE =SFRSTCR_GRDE_CODE and shrgrde_passed_ind = 'Y'
                where 1=1
                And sfrstcr_pidm = vl_pidm
                And SFRSTCR_RSTS_CODE ='RE'
                and SFRSTCR_GRDE_CODE is not null
                And trunc (SSBSECT_PTRM_START_DATE) = nvl (p_fecha_inicio, trunc (SSBSECT_PTRM_START_DATE))
                order by 1
              ) Loop
              
              Begin
                 --   DBMS_OUTPUT.PUT_LINE('Vueltas '||cx.periodo ||'*'||vl_pidm);
              
                  pkg_utilerias.p_rolado_academico_mat (cx.periodo, vl_pidm); commit;
              End;   
    
    End Loop;
    Commit;
    
End p_ejecuta_rolado_fecha_mat;


Procedure p_rolado_academico_mat (p_term in varchar2, p_pidm in number) is

vl_error varchar2(250):= 'EXITO';
conta_shrttrm number;
pidm number;
periodo varchar2(6);
sb varchar2(4);
cr varchar2(5);
coll varchar2(2);
dept varchar2(4);
schd varchar2(4);
cuenta varchar2(9);
seq number;
orig_seq number;
cred decimal(7,3);
gmod varchar2(10);
prog varchar2(10);
nivel varchar2(2);
camp varchar2(3);
gchg_code varchar2(3);
conta_origen number;
conta_origen_shrttrm number;
conta_destino number;
sp integer;
tckn_crn varchar2(5);
mensaje varchar2(200);
long_course varchar2(100);
short_course varchar2(100);

conta_materia number :=0;
conta_seq number :=0;
vl_exito varchar2(250):=0;


Begin

        Begin
                update sfrstcr
                set SFRSTCR_GRDE_DATE = null
                where SFRSTCR_TERM_CODE = p_term
                And  sfrstcr_pidm = p_pidm
                And SFRSTCR_RSTS_CODE = 'RE';
                --And  SFRSTCR_PTRM_CODE= 'L1E';
                commit;
        Exception
            When Others then
               vl_error := sqlerrm;
        End;

        If vl_error = 'EXITO' then
          --   DBMS_OUTPUT.PUT_LINE('******Actualiza FEcha GRADE '||vl_error);
        

                Begin

                        delete from shrtckl where SHRTCKL_TERM_CODE = p_term and SHRTCKL_PIDM = p_pidm; Commit;
                        delete from shrtckg where SHRTCKG_TERM_CODE = p_term and SHRTCKG_PIDM = p_pidm ; commit;
                        delete from shrtckn where SHRTCKN_TERM_CODE = p_term and SHRTCKN_PIDM = p_pidm; commit;
                        delete from SHRCHRT where SHRCHRT_TERM_CODE = p_term and SHRCHRT_PIDM = p_pidm; commit;
                        delete from SHRTTRM where SHRTTRM_TERM_CODE = p_term and SHRTTRM_PIDM = p_pidm; commit;
                        delete from shrtgpa where SHRTGPA_TERM_CODE = p_term and SHRTGPA_PIDM = p_pidm; commit;

                Exception
                    When Others then
                       vl_error := sqlerrm;
                End;




                 If vl_error = 'EXITO' then
                           -- DBMS_OUTPUT.PUT_LINE('******BORRA las Historias '||vl_error);

                                Begin

                                        For alumno in (


                                                         Select x.pidm,
                                                            x.campus,
                                                            x.nivel,
                                                            x.matricula,
                                                            x.SFRSTCR_CRN,
                                                            x.SFRSTCR_TERM_CODE,
                                                            x.SSBSECT_CRSE_TITLE,
                                                            x.numero
                                                    from (
                                                     select distinct sfrstcr_pidm pidm, 
                                                                    a.SFRSTCR_CAMP_CODE Campus, 
                                                                    a.SFRSTCR_LEVL_CODE Nivel, 
                                                                    spriden_id matricula, 
                                                                    a.SFRSTCR_CRN, 
                                                                    a.SFRSTCR_TERM_CODE, 
                                                                    SSBSECT_CRSE_TITLE,
                                                                    row_number() over(partition by a.sfrstcr_pidm, SSBSECT_CRSE_TITLE order by a.SFRSTCR_GRDE_CODE desc) numero, 
                                                                    a.SFRSTCR_GRDE_CODE
                                                     from sfrstcr a
                                                     join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('SESO1001')
                                                     join spriden on spriden_pidm = sfrstcr_pidm and spriden_change_ind is null
                                                     join shrgrde on  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE  and  SHRGRDE_CODE =SFRSTCR_GRDE_CODE and shrgrde_passed_ind = 'Y'
                                                     where   1=1
                                                     and a.SFRSTCR_GRDE_CODE is not null
                                                     And a.SFRSTCR_GRDE_DATE is null
                                                     And a.SFRSTCR_RSTS_CODE = 'RE'
                                                     And a.SFRSTCR_TERM_CODE = p_term
                                                     And  a.sfrstcr_pidm =  p_pidm
                                                     ) x
                                                     where x.numero = 1


                                       ) loop


                                             --   dbms_output.put_line('Alumnos '||alumno.pidm||'*'||alumno.Campus||'*'||alumno.nivel||'*'||alumno.SFRSTCR_CRN);

                                                   For c1 in (


                                                                 select x.pidm pidm, 
                                                                        x.matricula matricula,  
                                                                        x.SSBSECT_SUBJ_CODE ,  
                                                                        x.SSBSECT_CRSE_NUMB, 
                                                                        x.Calificacion, 
                                                                        x.Campus, 
                                                                        x.Nivel, 
                                                                        x.SP, 
                                                                        x.parte, max (x.fecha) fecha,
                                                                        x.SFRSTCR_CRN
                                                                 from (
                                                                         select distinct
                                                                         a.sfrstcr_pidm pidm,
                                                                         c.spriden_id matricula,
                                                                         b.SSBSECT_SUBJ_CODE,
                                                                         b.SSBSECT_CRSE_NUMB,
                                                                         a.SFRSTCR_GRDE_CODE Calificacion,
                                                                         a.SFRSTCR_CAMP_CODE Campus,
                                                                         a.SFRSTCR_LEVL_CODE Nivel,
                                                                         nvl (a.SFRSTCR_STSP_KEY_SEQUENCE,1) SP,
                                                                         a.SFRSTCR_PTRM_CODE parte,
                                                                         trunc (b.SSBSECT_PTRM_START_DATE) fecha,
                                                                         a.SFRSTCR_GRDE_DATE,
                                                                         a.SFRSTCR_CRN
                                                                 from sfrstcr a, ssbsect b, spriden c
                                                                 where b.ssbsect_term_code = a.sfrstcr_term_code
                                                                     and a.sfrstcr_crn = b.ssbsect_crn
                                                                     and a.sfrstcr_pidm = spriden_pidm
                                                                     and c.spriden_change_ind is null
                                                                     and a.SFRSTCR_GRDE_CODE is not null
                                                                     and a.SFRSTCR_GRDE_DATE is null
                                                                     And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                     and c.spriden_pidm = alumno.pidm
                                                                     and a.SFRSTCR_CAMP_CODE = alumno.campus
                                                                     and a.SFRSTCR_LEVL_CODE = alumno.nivel
                                                                     And a.SFRSTCR_CRN = alumno.SFRSTCR_CRN
                                                                    and TO_NUMBER (decode (a.SFRSTCR_GRDE_CODE,  'AC',1,'NA',1,'NP',1
                                                                          ,'10',10,'10.0',10,'100',10
                                                                          ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                                          ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                                          ,'6.0',6,'6',6,'60',6,'6.1',6,'61',6,'6.2',6,'62',6,'6.3',6,'63',6,'6.4',6,'64',6,'6.5',6,'65',6,'6.6',6,'66',6,'6.7',6,'67',6,'6.8',6,'68',6,'6.9',6,'69',6
                                                                          ,'7.0',7,'7',7,'70',7,'7.1',7,'71',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'76',7,'7.7',7,'77',7,'7.8',7,'78',7,'7.9',7,'79',7
                                                                          ,'8.0',8,'8',8,'80',8,'8.1',8,'81',8,'8.2',8,'82',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                                          ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9 
                                                                          )) =
                                                                            (select max (TO_NUMBER (decode (xx1.SFRSTCR_GRDE_CODE,  'AC',1,'NA',1,'NP',1
                                                                          ,'10',10,'10.0',10,'100',10
                                                                          ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                                          ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                                          ,'6.0',6,'6',6,'60',6,'6.1',6,'61',6,'6.2',6,'62',6,'6.3',6,'63',6,'6.4',6,'64',6,'6.5',6,'65',6,'6.6',6,'66',6,'6.7',6,'67',6,'6.8',6,'68',6,'6.9',6,'69',6
                                                                          ,'7.0',7,'7',7,'70',7,'7.1',7,'71',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'76',7,'7.7',7,'77',7,'7.8',7,'78',7,'7.9',7,'79',7
                                                                          ,'8.0',8,'8',8,'80',8,'8.1',8,'81',8,'8.2',8,'82',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                                          ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9 
                                                                         )))
                                                                                                        from SFRSTCR xx1, ssbsect xx2
                                                                                                         where 1=1
                                                                                                         And  xx1.SFRSTCR_TERM_CODE = xx2.SSBSECT_TERM_CODE
                                                                                                        And xx1.SFRSTCR_CRN = xx2.SSBSECT_CRN
                                                                                                         And xx1.SFRSTCR_PIDM = a.sfrstcr_pidm
                                                                                                        And xx2.SSBSECT_SUBJ_CODE||xx2.SSBSECT_CRSE_NUMB  = b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB
                                                                                                          )
                                                                     order by 1, 2,3, 4
                                                                     ) x
                                                                     group by x.pidm , x.matricula ,  
                                                                              x.SSBSECT_SUBJ_CODE ,  
                                                                              x.SSBSECT_CRSE_NUMB, 
                                                                              x.Calificacion, 
                                                                              x.Campus, 
                                                                              x.Nivel, 
                                                                              x.SP, 
                                                                              x.parte,
                                                                              x.SFRSTCR_CRN
                                                                     order by 1, 2, 3, 4,10



                                                 ) loop
                              
                             --   dbms_output.put_line('MAteria c1: '||c1.matricula||'*'||c1.SSBSECT_SUBJ_CODE||'*'||c1.SSBSECT_CRSE_NUMB||'*'||c1.Calificacion||'*'||c1.SFRSTCR_CRN);
                    
                                                                   conta_materia :=0;
                                                                   conta_seq :=0;
                                                                   vl_exito := null;
                                                                   coll:= null;
                                                                   dept:= null;
                                                                   cred:= null;
                                                                   schd:= null;
                                                                   long_course:= null;
                                                                   short_course:= null;

                                                                 For c in (

                                                                            Select x.pidm, 
                                                                                   x.matricula, 
                                                                                   x.periodo,
                                                                                   x.id_materia,
                                                                                   x.SSBSECT_SUBJ_CODE,
                                                                                   x.SSBSECT_CRSE_NUMB,
                                                                                   x.crn,
                                                                                   x.grupo,
                                                                                   x.calificacion,
                                                                                   x.fecha_rolado,
                                                                                   x.campus,
                                                                                   x.nivel,
                                                                                   x.fecha,
                                                                                   x.sp,
                                                                                   x.numero,
                                                                                   x.parte
                                                                            from (
                                                                             select distinct a.sfrstcr_pidm pidm,
                                                                             c.spriden_id matricula,
                                                                             a.sfrstcr_term_code periodo,
                                                                             b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB id_materia,
                                                                             b.SSBSECT_SUBJ_CODE,
                                                                             b.SSBSECT_CRSE_NUMB,
                                                                             a.sfrstcr_crn crn,
                                                                             b.SSBSECT_SEQ_NUMB grupo,
                                                                             a.SFRSTCR_GRDE_CODE Calificacion,
                                                                             a.SFRSTCR_GRDE_DATE fecha_rolado,
                                                                             a.SFRSTCR_CAMP_CODE Campus,
                                                                             a.SFRSTCR_LEVL_CODE Nivel,
                                                                             b.SSBSECT_PTRM_START_DATE fecha,
                                                                             a.SFRSTCR_STSP_KEY_SEQUENCE SP,
                                                                             row_number() over(partition by a.sfrstcr_pidm, a.sfrstcr_term_code order by a.sfrstcr_pidm) numero,
                                                                             a.SFRSTCR_PTRM_CODE parte
                                                                             from sfrstcr a, ssbsect b, spriden c
                                                                             where b.ssbsect_term_code = a.sfrstcr_term_code
                                                                             and a.sfrstcr_crn = b.ssbsect_crn
                                                                             and a.SFRSTCR_CAMP_CODE = c1.campus
                                                                             and a.SFRSTCR_LEVL_CODE = c1.nivel
                                                                             and a.sfrstcr_pidm = spriden_pidm
                                                                             and c.spriden_change_ind is null
                                                                             and a.SFRSTCR_GRDE_CODE is not null
                                                                             and a.SFRSTCR_GRDE_DATE is null
                                                                             And a.SFRSTCR_RSTS_CODE = 'RE'
                                                                              and c.spriden_pidm = c1.pidm
                                                                              And a.SFRSTCR_CRN = c1.SFRSTCR_CRN
                                                                              and b.SSBSECT_SUBJ_CODE = c1.SSBSECT_SUBJ_CODE
                                                                              and b.SSBSECT_CRSE_NUMB = c1.SSBSECT_CRSE_NUMB
                                                                              and  a.SFRSTCR_GRDE_CODE = c1.calificacion
                                                                              and trunc (b.SSBSECT_PTRM_START_DATE)  =  trunc (c1.fecha)
                                                                              ) x
                                                                             order by 1, 2,3, 15

                                                                ) loop

                                                                            conta_shrttrm :=0;
                                                                            conta_materia :=0;
                                                                            conta_seq :=0;
                                                                            vl_exito := null;
                                                                            coll:= null;
                                                                            dept:= null;
                                                                            cred:= null;
                                                                            schd:= null;
                                                                            long_course:= null;
                                                                            short_course:= null;
              ---   dbms_output.put_line('Secuencia:'||c.matricula||'*'||c.periodo||'*'||c.id_materia||'*'||c.Calificacion||'*'||c.numero||'*'||c.crn);

                                                                             Begin
                                                                                     select count(*)
                                                                                     into conta_shrttrm
                                                                                     from shrttrm
                                                                                     where shrttrm_pidm=c.pidm
                                                                                     and shrttrm_term_code=c.periodo;
                                                                             Exception
                                                                             when Others then
                                                                                     conta_shrttrm :=0;
                                                                             End;

                                                                             if conta_shrttrm = 0 then
                                                                                 conta_origen_shrttrm:=conta_origen_shrttrm+1;
                                                                          --   dbms_output.put_line('periodo:'||periodo);
                                                                                 begin
                                                                                             insert into shrttrm ( shrttrm_pidm, shrttrm_term_code, shrttrm_update_source_ind, shrttrm_pre_catalog_ind, shrttrm_record_status_ind, shrttrm_record_status_date,
                                                                                                                          shrttrm_activity_date, shrttrm_user_id, shrttrm_data_origin)
                                                                                             values(c.pidm, c.periodo,'S', 'N', 'G', c.fecha, c.fecha, user, 'CARG_HHH');

                                                                                          ---    dbms_output.put_line('Inserta en shrttrm ');
                                                                                              vl_exito := 'Exito';
                                                                                    exception
                                                                                     when DUP_VAL_ON_INDEX then
                                                                                  --   dbms_output.put_line('Error duplicidad shrttrm '||sqlerrm);
                                                                                     vl_exito := sqlerrm;
                                                                                     when others then
                                                                                   --   dbms_output.put_line('Error Othrs shrttrm '||sqlerrm);
                                                                                      vl_exito := sqlerrm;
                                                                                 end;


                                                                                 Begin
                                                                                            Insert into SHRCHRT values (c.pidm, c.periodo, c.periodo, null, null, sysdate, null, null, user, 'MASIVO', null);
                                                                                 --   dbms_output.put_line('Inserta en SHRCHRT ');
                                                                                              vl_exito := 'Exito';
                                                                                    exception
                                                                                     when DUP_VAL_ON_INDEX then
                                                                                   --  dbms_output.put_line('Error duplicidad SHRCHRT '||sqlerrm||'*'||c.periodo);
                                                                                     vl_exito := 'Exito';
                                                                                     when others then
                                                                                   --   dbms_output.put_line('Error Othrs SHRCHRT '||sqlerrm||'*'||c.periodo);
                                                                                      vl_exito := sqlerrm;
                                                                                 end;

                                                                             end if;

                                                                             begin
                                                                                     select distinct scbcrse_coll_code, scbcrse_dept_code, scbcrse_credit_hr_low , scrschd_schd_code , scrsyln_long_course_title, SCBCRSE_TITLE
                                                                                            into coll,dept, cred , schd , long_course, short_course
                                                                                     from scbcrse , scrschd, scrsyln
                                                                                     where scbcrse_subj_code= c.SSBSECT_SUBJ_CODE
                                                                                     and scbcrse_crse_numb= c.SSBSECT_CRSE_NUMB
                                                                                     and scbcrse_eff_term='000000'
                                                                                     and scrschd_subj_code=scbcrse_subj_code
                                                                                     and scrschd_crse_numb=scbcrse_crse_numb
                                                                                     and scrsyln_subj_code=scbcrse_subj_code
                                                                                     and scrsyln_crse_numb=scbcrse_crse_numb;
                                                                             Exception when others then
                                                                                    --  dbms_output.put_line(' Materia NO cargada en SCBCRSE');
                                                                                     cuenta:=c.matricula;
                                                                             end;


                                                                             Begin
                                                                                     select nvl (max (shrtckn_seq_no), 0) +1
                                                                                     into conta_materia
                                                                                     from shrtckn
                                                                                     where shrtckn_pidm = c.pidm
                                                                                     And shrtckn_term_code = c.periodo;
                                                                             Exception
                                                                                when Others then
                                                                                 conta_materia :=1;
                                                                             End;


                                                                             begin
                                                                                     insert into shrtckn ( shrtckn_pidm, shrtckn_term_code, shrtckn_seq_no, shrtckn_crn, shrtckn_subj_code, shrtckn_crse_numb,
                                                                                                                 shrtckn_coll_code, shrtckn_camp_code, shrtckn_dept_code, shrtckn_crse_title,
                                                                                                                 shrtckn_course_comment, shrtckn_activity_date, shrtckn_seq_numb, shrtckn_schd_code,
                                                                                                                 shrtckn_user_id, shrtckn_data_origin,shrtckn_stsp_key_sequence,shrtckn_long_course_title, shrtckn_ptrm_code)
                                                                                                                 values (c.pidm, c.periodo, conta_materia, c.crn, c.SSBSECT_SUBJ_CODE, c.SSBSECT_CRSE_NUMB,
                                                                                                                 coll, c.campus, dept, short_course,
                                                                                                                 null, sysdate, conta_materia, schd,
                                                                                                                 user, 'CARG_HHH',c.sp, long_course,c.parte);

                                                                                     vl_exito :='Exito';
                                                                                   --  dbms_output.put_line('Inserta en shrtckn ' ||vl_exito);

                                                                             exception
                                                                                 when DUP_VAL_ON_INDEX then
                                                                                 vl_exito := 'Exito';
                                                                                -- dbms_output.put_line('Error duplicidad shrtckn '||sqlerrm);
                                                                                 when others then
                                                                              --   dbms_output.put_line('Error duplicidad shrtckn '||sqlerrm);
                                                                                 vl_exito := sqlerrm;
                                                                             end;

                                                                            If vl_exito = 'Exito' then

                                                                                     begin
                                                                                     select scrgmod_gmod_code
                                                                                             into gmod
                                                                                     from scrgmod
                                                                                     where scrgmod_subj_code=c.ssbsect_subj_code
                                                                                     and scrgmod_crse_numb=c.ssbsect_crse_numb
                                                                                     And SCRGMOD_DEFAULT_IND ='D';
                                                                                     exception
                                                                                        when others then
                                                                                        gmod:=null;
                                                                                     end;

                                                                                    gchg_code:='OE';

                                                                                     Begin
                                                                                     select nvl (max (shrtckg_seq_no), 0) +1
                                                                                           Into conta_seq
                                                                                     from shrtckg
                                                                                     Where shrtckg_pidm = c.pidm
                                                                                     And shrtckg_term_code = c.periodo
                                                                                     And shrtckg_tckn_seq_no = conta_materia;
                                                                                      Exception
                                                                                     when Others then
                                                                                      conta_seq:=1;
                                                                                     End;



                                                                                     begin

                                                                                         insert into shrtckg(shrtckg_pidm,
                                                                                                                 shrtckg_term_code,
                                                                                                                 shrtckg_tckn_seq_no,
                                                                                                                 shrtckg_seq_no,
                                                                                                                 shrtckg_grde_code_final,
                                                                                                                 shrtckg_gmod_code,
                                                                                                                 shrtckg_credit_hours,
                                                                                                                 shrtckg_activity_date,
                                                                                                                 shrtckg_data_origin,
                                                                                                                 shrtckg_user_id,
                                                                                                                 shrtckg_gchg_code,
                                                                                                                 shrtckg_final_grde_chg_date,
                                                                                                                 shrtckg_final_grde_chg_user,
                                                                                                                 shrtckg_gcmt_code,
                                                                                                                 shrtckg_term_code_grade,
                                                                                                                 SHRTCKG_HOURS_ATTEMPTED)
                                                                                                     values(c.pidm, c.periodo, conta_materia, conta_seq, c.calificacion, gmod, cred, sysdate, 'CARG_HHH', sysdate,gchg_code, c.fecha, user,'INTMOO', c.periodo,cred );
                                                                                                     vl_exito := 'Exito';

                                                                                                  --   dbms_output.put_line('LLEGA A CKG ');
                                                                                     Exception
                                                                                        when DUP_VAL_ON_INDEX then
                                                                                            vl_exito := 'Exito';
                                                                                        When Others then
                                                                                            vl_exito := sqlerrm;
                                                                                           -- dbms_output.put_line('Error  SHRTCKG '||vl_exito);
                                                                                     End;



                                                                                If vl_exito = 'Exito' then

                                                                                         begin
                                                                                                 insert into shrtckl(shrtckl_pidm, shrtckl_term_code, shrtckl_tckn_seq_no, shrtckl_levl_code, shrtckl_activity_date, shrtckl_user_id, shrtckl_data_origin, shrtckl_primary_levl_ind)
                                                                                                 values( c.pidm, c.periodo, conta_materia, c.nivel, c.fecha, user, 'CARG_HHH','Y');
                                                                                                  vl_exito := 'Exito';
                                                                                                --  dbms_output.put_line('LLEGA A CKL ');
                                                                                         exception
                                                                                         when DUP_VAL_ON_INDEX then
                                                                                             vl_exito := 'Exito';
                                                                                         --   dbms_output.put_line('Error  shrtckl '||vl_exito);
                                                                                         when others then
                                                                                            vl_exito := sqlerrm;
                                                                                         --   dbms_output.put_line('Error  shrtckl '||vl_exito);
                                                                                         end;

                                                                                    If vl_exito = 'Exito' then
                                                                                         Begin
                                                                                             Update SFRSTCR
                                                                                             set SFRSTCR_GRDE_DATE = sysdate
                                                                                             where SFRSTCR_TERM_CODE = c.periodo
                                                                                             And SFRSTCR_PIDM = c.pidm
                                                                                             And SFRSTCR_CRN = c.crn;
                                                                                              dbms_output.put_line('UPDATE A SFRSTCR ');
                                                                                         Exception
                                                                                         when Others then
                                                                                          vl_exito := sqlerrm;
                                                                                          --  dbms_output.put_line('Error  SFRSTCR '||vl_exito);
                                                                                         End;

                                                                                    End if;

                                                                                End if;

                                                                            End if;

                                                                            Commit;

                                                                End loop c;

                                                 End loop c1;

                                        Commit;

                                     End loop alumno;

                                     Begin

                                            insert into shrtgpa
                                            select shrttrm_pidm, shrttrm_term_code, sgbstdn_levl_code, 'I', null,null, 0,0,0,0,0,sysdate,0,null,null,user,null,null
                                            from shrttrm, sgbstdn a
                                            where shrttrm_pidm=sgbstdn_pidm
                                            And sgbstdn_pidm = p_pidm
                                            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                                                                              where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                                                              and    b.sgbstdn_term_code_eff <= shrttrm_term_code)
                                            and     shrttrm_term_code= p_term;
                                            commit;

                                     Exception
                                        When Others then
                                            null;
                                     End;


                                Exception
                                    When Others then
                                        null;
                                End;
                                
                 End if;
                 Commit;

        End if;


End p_rolado_academico_mat;

PROCEDURE P_Desicion_53 is


vl_salida varchar2(500):= null;

Begin 

        For cx in (
        
                    select distinct b.sarappd_pidm pidm, 
                                    trunc (b.SARAPPD_APDC_DATE) + ( select distinct ZSTPARA_PARAM_ID dias
                                                                                from ZSTPARA 
                                                                                where ZSTPARA_MAPA_ID = 'RANGO_DIAS_53'
                                                                                And ZSTPARA_PARAM_VALOR = c.saradap_camp_code)+1 Fecha_decision,
                                      d.Matricula,
                                      c.SARADAP_CAMP_CODE Campus,
                                      c.SARADAP_LEVL_CODE Nivel,
                                      c.SARADAP_PROGRAM_1 Programa,
                                      b.SARAPPD_APPL_NO Solicitud,
                                      ( Select count(*)
                                        from  SARCHKL  
                                        where 1=1   
                                        And SARCHKL_PIDM  = b.sarappd_pidm               
                                        AND SARCHKL_ADMR_CODE  in (select distinct ZSTPARA_PARAM_ID
                                                                    from ZSTPARA 
                                                                    where ZSTPARA_MAPA_ID = 'DOCTOS_53'
                                                                    And ZSTPARA_PARAM_VALOR = c.saradap_camp_code  --> duda porque se debe dar de alta en el parametrizador
                                                                    ) 
                                        and  SARCHKL_CKST_CODE  != 'VALIDADO' ) sin_validar,
                                        pkg_utilerias.f_tipo_etiqueta(b.sarappd_pidm,'ENVA')Etiqueta     
                     from sarappd b 
                     join saradap c on c.saradap_pidm = b.sarappd_pidm and c.SARADAP_TERM_CODE_ENTRY = b.SARAPPD_TERM_CODE_ENTRY And c.SARADAP_APPL_NO = SARAPPD_APPL_NO
                     join tztprog d on d.pidm = b.sarappd_pidm and d.programa = c.SARADAP_PROGRAM_1 and  estatus ='MA' and d.sp in  (select max(d1.sp)
                                                                                                                                      from tztprog d1
                                                                                                                                         Where d.pidm = d1.pidm  
                                                                                                                                     )
                    where 1=1 
                    And b.SARAPPD_APDC_CODE = '53'
                    And b.SARAPPD_SEQ_NO = (select max (b1.SARAPPD_SEQ_NO)
                                             from sarappd b1
                                            Where 1=1
                                            And b.sarappd_pidm = b1.sarappd_pidm
                                            )
                   And pkg_utilerias.f_tipo_etiqueta(b.sarappd_pidm,'ENVA') = 'ENVA'



        ) loop
    
              If cx.Fecha_decision is not null then 
                dbms_output.put_line('Empieza con el alumno '|| cx.matricula);
    
        

                If cx.sin_validar = 0 and cx.etiqueta is not null then 
                    dbms_output.put_line('Alumno Regular');
                    Begin 
                        delete goradid
                        where 1=1
                        And GORADID_PIDM = cx.pidm
                        And GORADID_ADID_CODE = 'ENVA';
                        
                    Exception
                        When Others then 
                            null;
                    End;
                Elsif cx.sin_validar > 0 and cx.fecha_decision <= sysdate then 
                      dbms_output.put_line('Alumno Iregular'||cx.matricula ||' * '||cx.programa||' * '||'Matriculado sin documentos' ||' * '||'MS');
                        Begin
                        
                             vl_salida:=PKG_FINANZAS.F_BAJA_ACADEMICA ( cx.matricula,
                                                            cx.programa,
                                                            'BT',
                                                            sysdate,
                                                            'Matriculado sin documentos',
                                                            'MS' );    
                                                            
                         dbms_output.put_line('Salida Proceso '||vl_salida);            
                        
                        End;                
                End if;
             End if;
        
        End loop;
        
End P_Desicion_53;     

function f_bitacora_53(p_pidm number) RETURN pkg_utilerias.bita53_out as



                bita53_out_aut pkg_utilerias.bita53_out;

Begin
                          open bita53_out_aut
                            FOR
                                Select distinct b.saradap_pidm pidm,
                                                c.matricula,
                                                b.SARADAP_PROGRAM_1 Programa, 
                                                a.SARAPPD_APDC_DATE Fecha_Desicion, 
                                                c.estatus, 
                                                c.fecha_mov Fecha_Estatus,
                                                (select distinct a.GZTADID_ACTIVIDAD 
                                                    from GZTADID a
                                                    where 1 = 1
                                                    And a.GZTADID_GORA_ADID_CODE = 'ENVA'
                                                    And a.GZTADID_ACCION = 'INSERT'
                                                    And a.GZTADID_GORA_PIDM = a.sarappd_pidm
                                                    and a.GZTADID_SEQNO = (select max (a1.GZTADID_SEQNO)
                                                                            from GZTADID a1
                                                                           Where a.GZTADID_GORA_PIDM = a1.GZTADID_GORA_PIDM
                                                                           And a1.GZTADID_ACCION = 'INSERT'
                                                                           And a1.GZTADID_GORA_ADID_CODE = 'ENVA'
                                                                           )
                                                 ) Fecha_registro_etiqueta,
                                                (select distinct a.GZTADID_ACTIVIDAD 
                                                    from GZTADID a
                                                    where 1 = 1
                                                    And a.GZTADID_GORA_ADID_CODE = 'ENVA'
                                                    And a.GZTADID_ACCION = 'DELETE'
                                                    And a.GZTADID_GORA_PIDM = a.sarappd_pidm
                                                    and a.GZTADID_SEQNO = (select max (a1.GZTADID_SEQNO)
                                                                            from GZTADID a1
                                                                           Where a.GZTADID_GORA_PIDM = a1.GZTADID_GORA_PIDM
                                                                           And a1.GZTADID_ACCION = 'DELETE'
                                                                           And a1.GZTADID_GORA_ADID_CODE = 'ENVA'
                                                                           )
                                                 ) Fecha_Eliminacion_etiqueta                
                                from sarappd a
                                join saradap b on b.saradap_pidm = a.sarappd_pidm and b.SARADAP_TERM_CODE_ENTRY = a.SARAPPD_TERM_CODE_ENTRY and b.SARADAP_APPL_NO = a.SARAPPD_APPL_NO
                                join tztprog c on c.pidm = a.sarappd_pidm and c.programa = b.SARADAP_PROGRAM_1
                                where 1=1
                                And a.SARAPPD_PIDM = p_pidm
                                and a.SARAPPD_APDC_CODE ='53'
                                and a.SARAPPD_SEQ_NO = (select max (a1.SARAPPD_SEQ_NO)
                                                          from sarappd a1
                                                          Where 1=1
                                                          And a.sarappd_pidm = a1.sarappd_pidm
                                                       );

                        RETURN (bita53_out_aut);

END f_bitacora_53;


Procedure p_aplica_etiqueta_dina is

--------------------- Pone la etiqueta a los alumnos que tienen accesorios dinamicos y no llego su etiqueta ------------------


vl_salida varchar2(250):= null;


Begin 

        For cx in (

                    Select x.pidm, x.etiqueta
                    from (                 
                    select distinct a.pidm, a.matricula, a.campus, a.nivel, a.estatus, pkg_utilerias.f_tipo_etiqueta( a.pidm, 'DINA') etiqueta,  b.TZTPADI_FLAG --TZTPADI_DETAIL_CODE Codigo,
                    from tztprog a
                    join tztpadi b on b.TZTPADI_PIDM = a.pidm and b.TZTPADI_FLAG = '0'
                    where 1=1
                    and a.estatus = 'MA'
                    And a.sp = (select max (a1.sp)
                                  from tztprog a1
                                  Where a.pidm = a1.pidm )
                    ) x 
                    where x.etiqueta !='DINA'
                   -- And x.pidm = 116829
                    
         ) loop
         
                vl_salida:=pkg_utilerias.F_Genera_Etiqueta(cx.pidm, 'DINA', 'PAQUETES DINAMICOS', 'MASIVO'); 

     
         
         end loop;
         Commit;

End p_aplica_etiqueta_dina;         


   -- Version 1.0.00        04/ABR/2024     Omar Meza Sol
   -- Implementacion de 7 funciones para consumir por el Reporte SOAD (Python), prefijo "f_Phy"

   FUNCTION f_Phy_Datos_Personales (p_pidm IN VARCHAR2) RETURN SYS_REFCURSOR IS 
     -- PROPOSITO: Obtener los datos personales del interesado, consume el proyecto Phyton
     -- FECHA....: 25/Mayo/2023
     -- AUTOR....: Omar L Meza Sol
     -- VERSION..: 2.0.00
     
     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;	-- Registros recuperados en la consulta

   BEGIN
     OPEN Vm_Registros FOR 
          SELECT a.spriden_first_name Nombre, SUBSTR (a.spriden_last_name, 1, INSTR(a.spriden_last_name, '/') -1) Paterno,
                 SUBSTR (a.spriden_last_name, INSTR  (a.spriden_last_name, '/') +1) Materno,
                 TO_CHAR (b.spbpers_birth_date,'dd/mm/yyyy') Nacimiento,     
                 DECODE (b.spbpers_Sex, 'M', 'Masculino', 'F', 'Femenino', 'Otro') Genero, 
                 c.goradid_additional_Id CURP, 
                 d.sprtele_phone_area || d.sprtele_phone_number Celular_Numero, 
                 e.sprtele_phone_area || e.sprtele_phone_number Alternativo_Numero, 
                 f.sprtele_phone_area || f.sprtele_phone_number Casa_Numero, 
                 g.goradid_additional_Id Dependientes, NVL (t.sprmedi_medi_code, 'NO') Discapacidad
            FROM SPRIDEN a, SPBPERS b, 
                 (SELECT * FROM GORADID WHERE goradid_surrogate_Id = (SELECT MAX (goradid_surrogate_Id) Surrogate_Id FROM GORADID WHERE goradid_pidm = p_pidm AND goradid_adid_code = 'CURP')) c,
                 (SELECT * FROM SPRTELE WHERE sprtele_surrogate_Id = (SELECT MAX (sprtele_surrogate_Id) Surrogate_Id FROM SPRTELE WHERE sprtele_pidm = p_pidm AND sprtele_tele_code = 'CELU')) d,
                 (SELECT * FROM SPRTELE WHERE sprtele_surrogate_Id = (SELECT MAX (sprtele_surrogate_Id) Surrogate_Id FROM SPRTELE WHERE sprtele_pidm = p_pidm AND sprtele_tele_code = 'ALTE')) e,
                 (SELECT * FROM SPRTELE WHERE sprtele_surrogate_Id = (SELECT MAX (sprtele_surrogate_Id) Surrogate_Id FROM SPRTELE WHERE sprtele_pidm = p_pidm AND sprtele_tele_code = 'RESI')) f,
                 (SELECT * FROM GORADID WHERE goradid_surrogate_Id = (SELECT MAX (goradid_surrogate_Id) Surrogate_Id FROM GORADID WHERE goradid_pidm = p_pidm AND goradid_adid_code = 'DEPE')) g,
                 SPRMEDI t
           WHERE a.spriden_pidm             = p_pidm
           and spriden_change_ind is null
           --AND a.spriden_user_Id      IS NOT NULL
             AND b.spbpers_pidm         (+) = a.spriden_pidm
             AND c.goradid_pidm         (+) = a.spriden_pidm
             AND c.goradid_adid_code    (+) = 'CURP'           
             AND d.sprtele_pidm         (+) = a.spriden_pidm
             AND d.sprtele_tele_code    (+) = 'CELU'
             AND e.sprtele_pidm         (+) = a.spriden_pidm
             AND e.sprtele_tele_code    (+) = 'ALTE'
             AND f.sprtele_pidm         (+) = a.spriden_pidm
             AND f.sprtele_tele_code    (+) = 'RESI' -- 'PRIN'   
             AND g.goradid_pidm         (+) = a.spriden_pidm
             AND g.goradid_adid_code    (+) = 'DEPE'
             AND t.sprmedi_pidm         (+) = a.spriden_pidm
               ;
         
     RETURN Vm_Registros;
   END f_Phy_Datos_Personales;



   FUNCTION f_Phy_Direccion (p_pidm IN VARCHAR2, p_tipo_direccion IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene los datos de residencia  Secundario, consume el proyecto Phyton
     -- PARAMETROS: p_tipo_direccion --> RE=Residencias, CO=Correspondencia, RF=Referencia
     -- FECHA.....: 25/Mayo/2023
     -- AUTOR.....: Omar L Meza Sol
     -- VERSION...: 2.0.00

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;	-- Registros recuperados en la consulta

   BEGIN
     OPEN Vm_Registros FOR 
          SELECT DISTINCT a.spriden_pidm, 
                 f.goremal_email_address Email_Secundario,
                 c.stvnatn_nation Pais,      -- c.stvnatn_code || '#' || 
                 d.stvstat_desc   Estado,    -- d.stvstat_code || '#' || 
                 e.stvcnty_desc   Municipio, -- e.stvcnty_code || '#' || 
                 b.spraddr_ZIP CPostal, b.spraddr_street_line3 Colonia, b.spraddr_city Ciudad, 
                 b.spraddr_street_line1 Calle, NULL Numero_Interior, NULL Numero_Exterior,
                 
                 /* Version Anterior
                    OMS 29/Febrero/2024
                 DECODE (INSTR (b.spraddr_street_line1, '#'), 0, b.spraddr_street_line1,
                 SUBSTR (b.spraddr_street_line1, 1, INSTR (b.spraddr_street_line1, '#')-1)) Calle, 
                 DECODE (INSTR (b.spraddr_street_line1, '#Int: '), 0, NULL,
                         SUBSTR (b.spraddr_street_line1, INSTR (b.spraddr_street_line1, '#Int: '))) Numero_Interior, 
                 DECODE (INSTR (b.spraddr_street_line1, '#Ext: '), 0, NULL,
                         SUBSTR (b.spraddr_street_line1, INSTR (b.spraddr_street_line1, '#Ext: '),
                         DECODE (INSTR(b.spraddr_street_line1, '#Int:'), 0, 1000, 
                         INSTR(b.spraddr_street_line1, '#Int:')-INSTR (b.spraddr_street_line1, '#Ext: ')))) Numero_Exterior,
                 */
                 g.sprtele_phone_area || g.sprtele_phone_number Telefono_Referencia
            FROM SPRIDEN a, STVNATN c, 
                 STVSTAT d, STVCNTY e, GOREMAL f,
                 (SELECT * 
                    FROM spraddr h
                   WHERE (h.spraddr_pidm, h.spraddr_atyp_code, h.spraddr_surrogate_id) IN (
                               SELECT a.spraddr_pidm, a.spraddr_atyp_code, MAX (a.spraddr_surrogate_id) Surrogate_Id
                                 FROM spraddr a
                                WHERE a.spraddr_pidm      = p_pidm
                                  AND a.spraddr_atyp_code = p_tipo_direccion
                                GROUP BY a.spraddr_pidm,  a.spraddr_atyp_code 
                         )
                 ) b,
                 (SELECT * FROM SPRTELE 
                   WHERE 1 = 1
                     AND sprtele_Activity_Date = (SELECT MAX (sprtele_Activity_Date) Surrogate_Id 
                                                   FROM SPRTELE WHERE sprtele_pidm = p_pidm AND sprtele_tele_code = 'REFE')
                 ) g
           WHERE a.spriden_pidm            = p_pidm
             AND b.spraddr_pidm        (+) = a.spriden_pidm
             AND b.spraddr_atyp_code   (+) = p_tipo_direccion
             AND c.stvnatn_code        (+) = b.spraddr_natn_code
             AND d.stvstat_ipeds_cde   (+) = b.spraddr_natn_code
             AND d.stvstat_code        (+) = b.spraddr_stat_code
             AND e.stvcnty_data_origin (+) = b.spraddr_stat_code
             AND e.stvcnty_code        (+) = b.spraddr_cnty_code
             AND f.goremal_pidm        (+) = a.spriden_pidm
             AND f.goremal_emal_code   (+) = 'ALTE'                             -- 'REFE' -- 
             AND g.sprtele_pidm        (+) = a.spriden_pidm
             AND g.sprtele_tele_code   (+) = 'REFE'   
             ;     
     
     RETURN Vm_Registros;
   END f_Phy_Direccion;


   FUNCTION f_Phy_Direccion_Laboral (p_pidm IN VARCHAR2, p_tipo_direccion IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene los datos de laborales
     -- PARAMETROS: p_tipo_direccion --> LA=Laboral
     -- FECHA.....: 25/Mayo/2023
     -- AUTOR.....: Omar L Meza Sol
     -- VERSION...: 2.0.00

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;	-- Registros recuperados en la consulta

   BEGIN
     OPEN Vm_Registros FOR 
          SELECT goradid_pidm, 
                 MAX (Trabaja)             Trabaja,             MAX (Jornada_Laboral)   Jornada_Laboral, 
                 MAX (Nombre_Empresa)      Nombre_Empresa,      MAX (Tipo_Puesto)       Tipo_Puesto,
                 MAX (Antiguedad)          Antiguedad,          MAX (Salario)           Salario,
                 MAX (Email_Secundario)    Email_Secundario,    MAX (Pais)              Pais,      
                 MAX (Estado)              Estado,              MAX (Municipio)         Municipio,       
                 MAX (CPostal)             CPostal,             MAX (Colonia)           Colonia, 
                 MAX (Ciudad)              Ciudad,              MAX (Calle)             Calle,
                 MAX (Numero_Interior)     Numero_Interior,     MAX (Numero_Exterior)   Numero_Exterior, 
                 MAX (Referencia_Telefono) Referencia_Telefono, MAX (Referencia_Nombre) Referencia_Nombre,
                 MAX (Referencia_Apellido) Referencia_Apellido, MAX (Referencia_Codigo) Referencia_Codigo,
                 MAX (Giro_Empresa)        Giro_Empresa
                 , MAX (Dato01) Dato01
            FROM (
          SELECT goradid_pidm, 
                 MAX (Trabaja)             Trabaja,        MAX (Jornada_Laboral) Jornada_Laboral, 
                 MAX (Nombre_Empresa)      Nombre_Empresa, MAX (Tipo_Puesto)     Tipo_Puesto,
                 MAX (Antiguedad)          Antiguedad,     MAX (Salario)         Salario,
                 NULL Email_Secundario,    NULL Pais,      NULL Estado, NULL Municipio,       NULL CPostal, 
                 NULL Colonia,             NULL Ciudad,    NULL Calle,  NULL Numero_Interior, NULL Numero_Exterior, 
                 NULL Referencia_Telefono, NULL Referencia_Nombre,      NULL Referencia_Apellido,
                 NULL Referencia_Codigo,   MAX (Giro_Empresa) Giro_Empresa
                 , NULL Dato01
            FROM (SELECT b.goradid_pidm, 
                         DECODE (b.goradid_adid_code, 'TRAB', b.goradid_additional_id, 
                                 DECODE (b.goradid_adid_code, 'NEMP', 'SI', 'NO')) Trabaja,
                         DECODE (b.goradid_adid_code, 'JORL', b.goradid_additional_id, NULL) Jornada_Laboral,
                         DECODE (b.goradid_adid_code, 'NEMP', b.goradid_additional_id, NULL) Nombre_Empresa,
                         DECODE (b.goradid_adid_code, 'TPUE', b.goradid_additional_id, NULL) Tipo_Puesto,
                         DECODE (b.goradid_adid_code, 'ANTI', b.goradid_additional_id, NULL) Antiguedad,
                         DECODE (b.goradid_adid_code, 'SALM', b.goradid_additional_id, NULL) Salario,
                         DECODE (b.goradid_adid_code, 'GIRE', b.goradid_additional_id, NULL) Giro_Empresa
                    FROM goradid b
                   WHERE (b.goradid_pidm, b.goradid_adid_code, b.goradid_surrogate_id) IN (
                                     SELECT a.goradid_pidm, a.goradid_adid_code, MAX (a.goradid_surrogate_id) Max_surrogate_id
                                       FROM goradid a
                                      WHERE a.goradid_pidm = p_pidm
                                        AND a.goradid_adid_code IN ('JORL','NEMP','TRAB','TPUE','ANTI','SALM', 'GIRE')
                                      GROUP BY a.goradid_pidm, a.goradid_adid_code   
                         )
                 )
           GROUP BY goradid_pidm
           UNION ALL     
          SELECT a.spriden_pidm, 
                 NULL Trabaja, NULL Jornada_Laboral, NULL Nombre_Empresa, NULL Tipo_Puesto, NULL Antiguedad, NULL Salario,
                 f.goremal_email_address Email_Secundario,
                 c.stvnatn_nation Pais,           -- c.stvnatn_code || '#' || 
                 d.stvstat_desc   Estado,         -- d.stvstat_code || '#' || 
                 e.stvcnty_desc   Municipio,      -- e.stvcnty_code || '#' || 
                 b.spraddr_ZIP CPostal, b.spraddr_street_line3 Colonia, b.spraddr_city Ciudad, 
                 
                 b.spraddr_street_line1 Calle, NULL Numero_Interior, NULL Numero_Exterior,
                 
                 /* Version Anterior
                    OMS 29/Febrero/2024
                 DECODE (INSTR (b.spraddr_street_line1, '#'), 0, b.spraddr_street_line1,
                 SUBSTR (b.spraddr_street_line1, 1, INSTR (b.spraddr_street_line1, '#')-1)) Calle, 
                 DECODE (INSTR (b.spraddr_street_line1, '#Int: '), 0, NULL,
                         SUBSTR (b.spraddr_street_line1, INSTR (b.spraddr_street_line1, '#Int: '))) Numero_Interior, 
                 DECODE (INSTR (b.spraddr_street_line1, '#Ext: '), 0, NULL,
                         SUBSTR (b.spraddr_street_line1, INSTR (b.spraddr_street_line1, '#Ext: '),
                         DECODE (INSTR(b.spraddr_street_line1, '#Int:'), 0, 1000, 
                         INSTR(b.spraddr_street_line1, '#Int:')-INSTR (b.spraddr_street_line1, '#Ext: ')))) Numero_Exterior,
                */
                 g.sprtele_phone_area || g.sprtele_phone_number Referencia_Telefono,
                 h.sorfolk_parent_first Referencia_Nombre, h.sorfolk_parent_last Referencia_Apellido, 
                 h.stvrelt_desc Referencia_Codigo,          --h.sorfolk_relt_code Referencia_Codigo,   OMS 29/Febrero/2024 
                 NULL Gio_Empresa
                 , b.spraddr_street_line1 Dato01
            FROM SPRIDEN a, STVNATN c,  -- OMS 21/Marzo/2024   SPRTELE g, 
                 STVSTAT d, STVCNTY e, GOREMAL f,
                 (SELECT * 
                    FROM spraddr h
                   WHERE (h.spraddr_pidm, h.spraddr_atyp_code, h.spraddr_surrogate_id) IN (
                               SELECT a.spraddr_pidm, a.spraddr_atyp_code, MAX (a.spraddr_surrogate_id) Surrogate_Id
                                 FROM spraddr a
                                WHERE a.spraddr_pidm      = p_pidm
                                  AND a.spraddr_atyp_code = p_tipo_direccion
                                GROUP BY a.spraddr_pidm,  a.spraddr_atyp_code 
                         )
                 ) b,
                 (SELECT j.*, h2.stvrelt_desc
                    FROM SORFOLK j, STVRELT h2
                   WHERE (j.sorfolk_pidm, j.sorfolk_relt_code, j.sorfolk_atyp_code, j.sorfolk_surrogate_id) IN (
                                SELECT h.sorfolk_pidm, h.sorfolk_relt_code, h.sorfolk_atyp_code, MAX (h.sorfolk_surrogate_id) surrogate_id
                                  FROM SORFOLK h
                                 WHERE h.sorfolk_pidm      = p_pidm
--                                 AND h.sorfolk_relt_code = 'R'                -- OMS 29/Febrero/2024 
                                   AND h.sorfolk_atyp_code = 'RF'               -- OMS 29/Febrero/2024 
                                 GROUP BY  h.sorfolk_pidm, h.sorfolk_relt_code, h.sorfolk_atyp_code   
                         )
                     AND h2.stvrelt_code = j.sorfolk_relt_code 
                 ) h,
                 (SELECT * FROM SPRTELE 
                   WHERE 1 = 1
                     AND sprtele_Activity_Date = (SELECT MAX (sprtele_Activity_Date) Surrogate_Id 
                                                   FROM SPRTELE WHERE sprtele_pidm = p_pidm AND sprtele_tele_code = 'REFE')
                 ) g
           WHERE a.spriden_pidm            = p_pidm
             AND b.spraddr_pidm        (+) = a.spriden_pidm
             AND b.spraddr_atyp_code   (+) = p_tipo_direccion
             AND c.stvnatn_code        (+) = b.spraddr_natn_code
             AND d.stvstat_ipeds_cde   (+) = b.spraddr_natn_code
             AND d.stvstat_code        (+) = b.spraddr_stat_code
             AND e.stvcnty_data_origin (+) = b.spraddr_stat_code
             AND e.stvcnty_code        (+) = b.spraddr_cnty_code
             AND f.goremal_pidm        (+) = a.spriden_pidm
             AND f.goremal_emal_code   (+) = 'ALTE'
             AND g.sprtele_pidm        (+) = a.spriden_pidm
             AND g.sprtele_tele_code   (+) = 'REFE'    -- Se regresa al mismo 21/Mar/2024 'RESI'   -- OMS 29/Febrero/2024 'REFE'
             AND h.sorfolk_pidm        (+) = a.spriden_pidm
               )
           GROUP BY goradid_pidm
             ;     
     
     RETURN Vm_Registros;
   END f_Phy_Direccion_Laboral;



   FUNCTION f_Phy_Datos_Facturacion (p_pidm IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene los datos de facturación
     -- FECHA.....: 25/Mayo/2023
     -- AUTOR.....: Omar L Meza Sol
     -- VERSION...: 2.0.00

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;	-- Registros recuperados en la consulta

   BEGIN
     OPEN Vm_Registros FOR 
          SELECT a.spremrg_mi Rfc,               a.spremrg_last_name Razon_Social,
                 c.stvnatn_nation Pais,       -- a.spremrg_natn_code || '#' || 
                 d.stvstat_desc   Estado,     -- a.spremrg_stat_code || '#' || 
                 a.spremrg_street_line3 Colonia, a.spremrg_street_line1 Calle, a.spremrg_zip CPostal,
                 a.spremrg_City Municipio,       a.spremrg_City Ciudad
            FROM SPREMRG a,STVNATN c, STVSTAT d
           WHERE a.spremrg_pidm = p_pidm
             AND c.stvnatn_code      (+) = a.spremrg_natn_code
             AND d.stvstat_ipeds_cde (+) = a.spremrg_natn_code
             AND D.stvstat_code      (+) = a.spremrg_stat_code
               ;
  
     RETURN Vm_Registros;
   END f_Phy_Datos_Facturacion;


   
    FUNCTION f_Phy_Datos_Inscripcion (p_pidm IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene los datos de Inscripción
     -- FECHA.....: 29/Mayo/2023
     -- AUTOR.....: Omar L Meza Sol
     -- VERSION...: 2.0.00

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;	-- Registros recuperados en la consulta

   BEGIN
     OPEN Vm_Registros FOR 
          SELECT a.spriden_pidm, m.szvcamp_Desc campus, n.stvlevl_Desc nivel, UPPER (r.sztdtec_Programa_Comp) programa, 
                 s.stvadmt_Desc tipo_ingreso, j.fecha_inicio, d.stvatts_Desc Jornada,
              -- a.spriden_pidm, j.campus, j.nivel, j.programa, j.tipo_ingreso, j.fecha_inicio,  p.sgrsatt_atts_code Jornada,
                 DECODE (SUBSTR (d.stvatts_Code,3,1), 'R', 1, 2) No_Materias_Iniciales, 
                 k.saracmt_term_code Plan
            FROM SPRIDEN a, (SELECT j.pidm, j.campus, j.nivel, j.programa, j.tipo_ingreso, j.fecha_inicio
                               FROM TZTPROG j         
                              WHERE (j.pidm, j.sp) IN (SELECT h.pidm, MAX (h.sp) Sp_Max
                                                         FROM TZTPROG h
                                                        WHERE h.pidm = p_pidm
                                                        GROUP BY h.pidm
                                                      )
                            ) j,
                           (SELECT p.sgrsatt_pidm, p.sgrsatt_atts_code
                              FROM SGRSATT p
                             WHERE (p.sgrsatt_pidm, p.sgrsatt_surrogate_id) IN (SELECT q.sgrsatt_pidm, MAX (q.sgrsatt_surrogate_id) surrogate_id 
                                                                                  FROM SGRSATT q 
                                                                                 WHERE q.sgrsatt_pidm = p_pidm
                                                                                GROUP BY q.sgrsatt_pidm
                                                                               )
                           ) p,
                           ( SELECT k.saracmt_pidm, k.saracmt_term_code
                               FROM SARACMT k
                              WHERE k.saracmt_orig_code = 'PAQT'
                                AND (k.saracmt_pidm, k.saracmt_SEQno) IN (SELECT a.saracmt_pidm, MAX(a.saracmt_SEQno) appl_no
                                                                              FROM SARACMT a
                                                                             WHERE a.saracmt_pidm      = p_pidm
                                                                               AND a.saracmt_orig_code = 'PAQT'
                                                                             GROUP BY a.saracmt_pidm
                                                                           )
                           ) k,
                 szvcamp m, stvlevl n, sztdtec r, stvadmt s, stvatts d
           WHERE a.spriden_pidm      = p_pidm
             AND j.pidm          (+) = a.spriden_pidm
             AND p.sgrsatt_pidm  (+) = a.spriden_pidm
             AND k.saracmt_pidm  (+) = a.spriden_pidm
             AND m.szvcamp_camp_code = j.campus
             AND n.stvlevl_code      = j.nivel
             AND r.sztdtec_camp_code = j.campus
             AND r.sztdtec_program   = j.programa
             AND s.stvadmt_code      = j.tipo_ingreso
             AND d.stvatts_code      = p.sgrsatt_atts_code
               ;
               
     RETURN Vm_Registros;     
   END f_Phy_Datos_Inscripcion;
   
   
   
   FUNCTION f_Phy_Planes_Vida (p_pidm IN VARCHAR2, p_no_respuesta IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene las respuestas para el plan e vida
     -- PARAMETROS: p_No_Respuesta -> V001= Respuesta 1 ... V009=Respuesta 9
     -- FECHA.....: 29/Mayo/2023
     -- AUTOR.....: Omar L Meza Sol
     -- VERSION...: 2.0.00

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;	-- Registros recuperados en la consulta

   BEGIN
     OPEN Vm_Registros FOR 
          SELECT m.saracmt_pidm, m.saracmt_orig_code, n.stvorig_desc, m.saracmt_comment_text
            FROM SARACMT m, STVORIG n
           WHERE n.stvorig_code = m.saracmt_orig_code
             AND (m.saracmt_pidm, m.saracmt_orig_code, m.saracmt_appl_no) IN 
                         (SELECT a.saracmt_pidm, a.saracmt_orig_code, MAX (a.saracmt_appl_no) appl_no
                            FROM SARACMT a
                           WHERE a.saracmt_pidm      = p_pidm
                             AND a.saracmt_orig_code = p_no_respuesta
                           GROUP BY a.saracmt_pidm, a.saracmt_orig_code
                         );

     RETURN Vm_Registros;     
   END f_Phy_Planes_Vida;


   
   FUNCTION f_Phy_Info_Academica (p_pidm IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene datos academicos del alumno
     -- FECHA.....: 29/Mayo/2023
     -- AUTOR.....: Omar L Meza Sol
     -- VERSION...: 2.0.00

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;	-- Registros recuperados en la consulta

   BEGIN
     OPEN Vm_Registros FOR 
          SELECT a.sorpcol_pidm, a.sorpcol_sbgi_code, d.stvsbgi_desc, b.sordegr_degc_code, 
                 c.sorhsch_graduation_date, c.sorhsch_gpa
            FROM SORPCOL a, SORDEGR b, 
                 SORHSCH c, STVSBGI d
           WHERE a.sorpcol_pidm          = p_pidm
             AND b.sordegr_pidm      (+) = a.sorpcol_pidm
             AND b.sordegr_sbgi_code (+) = a.sorpcol_sbgi_code
             AND c.sorhsch_pidm      (+) = a.sorpcol_pidm
             AND c.sorhsch_sbgi_code (+) = a.sorpcol_sbgi_code
             AND d.stvsbgi_code          = a.sorpcol_sbgi_code
               ;
     
     RETURN Vm_Registros;     
   END f_Phy_Info_Academica;  
   -- Implementacion de 7 funciones para consumir por el Reporte SOAD (Python), prefijo "f_Phy"

--

Function  f_ultimo_estatus_decision (p_pidm in number, p_programa IN VARCHAR2 ) return varchar2

As

            vl_resultado varchar2(250) := null;

    Begin

              Begin
                        Select distinct decode (SARAPPD_APDC_CODE, '40', 'Rechazado', '50', 'Cancelado', '45', 'Vuelta a Venta', '35', 'NUEVO INGRESO', '53', 'FUTURO') Estatus
                            Into vl_resultado
                        from SARAPPD a
                        join saradap b on saradap_pidm = sarappd_pidm and SARADAP_APPL_NO = SARADAP_APPL_NO and SARADAP_PROGRAM_1 = p_programa
                        join stvAPDC on stvAPDC_code = SARAPPD_APDC_CODE 
                       Where a.sarappd_pidm = p_pidm
                       AND a.SARAPPD_SEQ_NO = (SELECT MAX (a1.SARAPPD_SEQ_NO)
                                                                 FROM SARAPPD a1
                                                                WHERE a.sarappd_pidm = a1.sarappd_pidm
                                                                      AND a.SARAPPD_TERM_CODE_ENTRY = a1.SARAPPD_TERM_CODE_ENTRY
                                                                      AND a.SARAPPD_APPL_NO = a1.SARAPPD_APPL_NO
                                                              );
              Exception
                    When Others then
                      vl_resultado := 'N/A';
              End;

                Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := 'N/A';
          Return (vl_resultado);
    End f_ultimo_estatus_decision;



Function   f_fecha_egreso (p_pidm in number,  p_sp in number) Return date
is
--vl_fecha_ini date;
--vl_salida varchar2(250):= 'EXITO';
--vl_fecha varchar2(25):= null;
vl_fecha date;

BEGIN

    Begin

          select 
            e.FECHA_MOV
            into vl_fecha
                from tztprog E
                where 1=1
                AND  e.ESTATUS = 'EG'
                and  e.pidm = p_pidm
                and  e.sp=p_sp;

    Exception
    When Others then
      vl_fecha := null;
    End;

        return vl_fecha;

Exception
When Others then
  vl_fecha := null;
 return vl_fecha;
END f_fecha_egreso;

Function   f_fecha_ultima_miperfil (p_pidm in number,  p_sp in number) Return date
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

    Begin



        select   distinct  max (x.fecha_inicio) --, rownum
            into   vl_salida
        from (
        SELECT DISTINCT
                   max (SSBSECT_PTRM_START_DATE) fecha_inicio--, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                FROM SFRSTCR a, SSBSECT b
               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                     And  a.SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                     AND a.SFRSTCR_RSTS_CODE = 'RE'
                     And  substr (a.SFRSTCR_TERM_CODE,5,1) not in ('9')
                     And  b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB  not in ( 'IND00001','UTEL001','L1HP401', 'L1HB401','M1HB401' )
                    AND b.SSBSECT_PTRM_START_DATE =
                                                                                (SELECT max (b1.SSBSECT_PTRM_START_DATE)
                                                                                   FROM SSBSECT b1
                                                                                  WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                                                                        AND b.SSBSECT_CRN = b1.SSBSECT_CRN
                                                                                        And b.SSBSECT_SUBJ_CODE||b.SSBSECT_CRSE_NUMB = b1.SSBSECT_SUBJ_CODE||b1.SSBSECT_CRSE_NUMB)
              and  SFRSTCR_pidm = p_pidm
            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
            order by 1 desc
            )  x
            where rownum = 1
          order by 1 asc;

    Exception
    When Others then
      vl_salida := null;
    End;

        return vl_salida;

Exception
When Others then
  vl_salida := '01/01/1900';
 return vl_salida;
END f_fecha_ultima_miperfil;

--
--

FUNCTION f_matriculas_duplicadas (p_curp in varchar2 default null, p_dni in varchar2 default null,p_campus in varchar2 default null,p_email in varchar2 default null) return VARCHAR2 IS

	lv_respuesta VARCHAR2(400);
	ln_existe_curp NUMBER;
	ln_existe_dni NUMBER;
	lv_code_campus VARCHAR2 (3);
	lv_pidm VARCHAR2(20);
	ln_existe_campus NUMBER;
	lv_matricula VARCHAR2(50);
	lv_nombre VARCHAR2(2000);
	ln_existe_email NUMBER;
	lv_error   VARCHAR2(2000);

BEGIN


IF p_email is not null then 
	select count(1) 
	into ln_existe_email
	from goremal 
	where goremal_email_address = p_email;  
	
	if ln_existe_email > 0 then 
	select unique GOREMAL_PIDM
	into lv_pidm
	from goremal 
	where goremal_email_address = p_email; 
	
			select UNIQUE a.spriden_id, trim(a.SPRIDEN_FIRST_NAME)||' '||trim(REPLACE(a.SPRIDEN_LAST_NAME,'/',' ')) nombre_completo 
			into lv_matricula, lv_nombre
			from spriden a 
			where a.spriden_pidm =lv_pidm
			and a.spriden_activity_date in (select max(b.spriden_activity_date) 
											  from spriden b 
											 where b.spriden_pidm = a.spriden_pidm);
			
			
									  
		lv_respuesta := 'EMAIL ya esta asociado a la matricula: '||lv_matricula||' / '||lv_nombre||' no cuentas con permisos para crear una segunda solicitud.';
	else
		lv_respuesta := 'EXITO';
			 
	end if;
	
ELSE 
	IF p_curp is not null and p_campus is not null then 
	
	select SZVCAMP_CAMP_ALT_CODE 
	into lv_code_campus 
	from SZVCAMp 
	where SZVCAMP_CAMP_CODE =p_Campus;
						
	 select COUNT(1)
			into ln_existe_curp
			from GORADID A
			where A.GORADID_ADID_CODE = 'CURP'
			and A.GORADID_ADDITIONAL_ID = p_curp
		   AND EXISTS
				  (SELECT 1
					 FROM GORADID b
					WHERE     b.GORADID_ADID_CODE = 'CAMP'
						  AND b.GORADID_PIDM = a.GORADID_PIDM
						  AND b.GORADID_ADDITIONAL_ID = lv_code_campus); 


			if ln_existe_curp > 0 then 

				SELECT a.GORADID_PIDM
				  into lv_pidm
				  FROM GORADID a
				 WHERE     a.GORADID_ADID_CODE = 'CURP'
					   AND a.GORADID_ADDITIONAL_ID = p_curp
					   AND EXISTS
							  (SELECT 1
								 FROM GORADID b
								WHERE     b.GORADID_ADID_CODE = 'CAMP'
									  AND b.GORADID_PIDM = a.GORADID_PIDM
									  AND b.GORADID_ADDITIONAL_ID = lv_code_campus);       

			select count(1)
			into ln_existe_campus 
			from GORADID
			where GORADID_ADID_CODE = 'CAMP'
			and GORADID_PIDM =lv_pidm
			AND GORADID_ADDITIONAL_ID = lv_code_campus;  
			
				select UNIQUE a.spriden_id, trim(a.SPRIDEN_FIRST_NAME)||' '||trim(REPLACE(a.SPRIDEN_LAST_NAME,'/',' ')) nombre_completo 
				into lv_matricula, lv_nombre
				from spriden a 
				where a.spriden_pidm =lv_pidm
				and a.SPRIDEN_CREATE_DATE in (select max(b.SPRIDEN_CREATE_DATE) 
												  from spriden b 
												 where b.spriden_pidm = a.spriden_pidm);

			
				IF ln_existe_campus > 0 THEN                          
				lv_respuesta := 'CURP ya esta asociado a la matricula: '||lv_matricula||' / '||lv_nombre||' debes crear una segunda solicitud.';
				else
				lv_respuesta := 'EXITO';
				END IF;
			ELSE
			lv_respuesta := 'EXITO';                      
			end if ;
			
	ELSIF p_dni is not null and p_campus is not null THEN 
		SELECT count(1)
		 into ln_existe_dni
		FROM Spbpers 
		WHERE spbpers_ssn =p_dni ;
		
			if ln_existe_dni > 0 then 

			 select SPBPERS_PIDM
			 into lv_pidm
			FROM Spbpers 
			WHERE spbpers_ssn =p_dni ;                
			
			select SZVCAMP_CAMP_ALT_CODE 
			into lv_code_campus 
			from SZVCAMp 
			where SZVCAMP_CAMP_CODE =p_Campus;
			
			
			select count(1)
			into ln_existe_campus 
			from GORADID
			where GORADID_ADID_CODE = 'CAMP'
			and GORADID_PIDM =lv_pidm
			AND GORADID_ADDITIONAL_ID = lv_code_campus;  
			
			select UNIQUE a.spriden_id, trim(a.SPRIDEN_FIRST_NAME)||' '||trim(REPLACE(a.SPRIDEN_LAST_NAME,'/',' ')) nombre_completo 
			into lv_matricula, lv_nombre
			from spriden a 
			where a.spriden_pidm =lv_pidm
			and a.SPRIDEN_CREATE_DATE in (select max(b.SPRIDEN_CREATE_DATE) 
											  from spriden b 
											 where b.spriden_pidm = a.spriden_pidm);
			
				IF ln_existe_campus > 0 THEN                          
				lv_respuesta := 'DNI ya esta asociado a la matricula: '||lv_matricula||' / '||lv_nombre||' debes crear una segunda solicitud.';
				else
				lv_respuesta := 'EXITO';
				END IF;                
			ELSE
			lv_respuesta := 'EXITO';  
			end if ;            
	END IF;   
	
END IF;
	RETURN (lv_respuesta);
EXCEPTION WHEN OTHERS THEN 
lv_respuesta := 'ERROR : '||sqlerrm;
RETURN (lv_respuesta);
END f_matriculas_duplicadas;
  

FUNCTION f_valida_exist_matricula (p_matricula in varchar2)return VARCHAR2 --21-01-2025 ICJ V1
        AS

        vl_return VARCHAR2(250);
        NUM_DATO number:=0;

    Begin
            Begin
            
                Select count(1)
                    Into NUM_DATO
                 from TZTPROG
                 where matricula = p_matricula;
            Exception
                When Others then 
                    NUM_DATO:=0;
            End;

            If NUM_DATO >= 1 then 
               vl_return := 'EXISTE';
            Else 
               vl_return := 'NO_EXISTE';
            End if;


        RETURN vl_return;
 
Exception
    When Others then 
    vl_return := 'NO_EXISTE';
    RETURN vl_return;
    
END f_valida_exist_matricula;   


Function  f_dashboard_saldototal_SP (p_pidm in number, p_sp in number) return varchar2

Is

vl_monto number:=0;
vl_moneda varchar2(10);

    Begin
            select sum(nvl (tbraccd_balance, 0)) balance
            Into vl_monto
            from tbraccd
            Where tbraccd_pidm =  p_pidm
            And nvl (TBRACCD_STSP_KEY_SEQUENCE,1) = p_sp ; --39423
           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
        Return (vl_monto);
        --Return(vl_moneda);
 END f_dashboard_saldototal_SP;
            
END pkg_utilerias;
/

DROP PUBLIC SYNONYM PKG_UTILERIAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_UTILERIAS FOR BANINST1.PKG_UTILERIAS;


GRANT EXECUTE ON BANINST1.PKG_UTILERIAS TO PUBLIC;
