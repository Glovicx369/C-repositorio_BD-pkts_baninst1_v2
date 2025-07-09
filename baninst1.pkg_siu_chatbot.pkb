DROP PACKAGE BODY BANINST1.PKG_SIU_CHATBOT;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_SIU_CHATBOT" AS
/******************************************************************************
   NAME:       pkg_siu_chatbot
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        14/11/2024      agolvera       1. Created this package.
   1.1        05/06/2025      agolvera       2. Nueva función f_siu_avance_curr
   1.2        01/07/2025      agolvera       3. Obtiene Saldo al dia
******************************************************************************/

--
--
  FUNCTION f_siu_chatbot (p_matricula IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene datos para SIU Chat Bot

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;    -- Registros recuperados en la consulta
     lv_url VARCHAR2(100);
     VL_INICIO VARCHAR2(10);
     VL_FIN VARCHAR2 (10);
     lv_estatus VARCHAR2(50);
     LV_MAIL VARCHAR2(100);
     lv_PROG VARCHAR2(32767);
     lv_USU_SIU VARCHAR2(32767);
     lv_tipo_ingreso_desc VARCHAR2(200);
     lv_desc_type VARCHAR2(200); 
     lv_desc_programa VARCHAR2(100);
     ln_pidm VARCHAR2(20);
     RetVal PKG_DASHBOARD_ALUMNO.avcu_out;
     
BEGIN

    BEGIN     
    SELECT fget_pidm(p_matricula)
      INTO ln_pidm
      FROM DUAL;
     EXCEPTION WHEN OTHERS THEN 
     ln_pidm := NULL;
     END;
       
    BEGIN 
    SELECT ZSTPARA_PARAM_DESC
      INTO lv_url
      FROM ZSTPARA
     WHERE ZSTPARA_mapa_id = 'CAMP_URL_MONEDA' AND ZSTPARA_PARAM_ID = substr(p_matricula,1,2);
     EXCEPTION WHEN OTHERS THEN 
     lv_url := NULL;
    END;     

    BEGIN 
    SELECT TO_CHAR(MAX (b.ssbsect_ptrm_start_date),'DD/MM/YYYY'), 
           TO_CHAR(MAX (b.ssbsect_ptrm_end_date),'DD/MM/YYYY')
      INTO VL_INICIO, VL_FIN
      FROM sfrstcr A, ssbsect B
     WHERE     1 = 1
           AND b.ssbsect_crn = a.sfrstcr_crn
           AND b.ssbsect_term_code = a.sfrstcr_term_code
           AND a.sfrstcr_pidm = ln_pidm
           AND sfrstcr_rsts_code = 'RE';
    EXCEPTION WHEN OTHERS THEN 
    VL_INICIO := NULL;
    VL_FIN :=  NULL;
    END;
    
    BEGIN 
         
    SELECT UNIQUE A.ESTATUS_D, C.SZTDTEC_PROGRAMA_COMP, B.STVSTYP_DESC ,A.TIPO_INGRESO_DESC, A.PROGRAMA
      INTO lv_estatus , lv_desc_programa,lv_desc_type,lv_tipo_ingreso_desc, lv_prog
      FROM TZTPROG A, stvstyp B , SZTDTEC c
     WHERE A.SGBSTDN_STYP_CODE =  B.STVSTYP_CODE   
       AND A.PROGRAMA = C.SZTDTEC_PROGRAM
       AND A.PIDM = ln_pidm
       AND A.SP IN (SELECT MAX (B.SP)
                          FROM TZTPROG B
                         WHERE A.PIDM = B.PIDM);
    EXCEPTION WHEN OTHERS THEN 
    lv_estatus := NULL;
    lv_desc_programa := NULL;
    lv_desc_type := NULL;
    lv_tipo_ingreso_desc := NULL;
    END;
    
    BEGIN 
    SELECT goremal_email_address
      INTO LV_MAIL
      FROM goremal s
     WHERE     s.goremal_pidm = ln_pidm
           AND s.goremal_emal_code = 'PRIN'
           AND s.GOREMAL_PREFERRED_IND = 'Y'
           AND s.GOREMAL_STATUS_IND = 'A'
           AND s.GOREMAL_SURROGATE_ID =
                  (SELECT MAX (ss.GOREMAL_SURROGATE_ID)
                     FROM GOREMAL ss
                    WHERE     ss.GOREMAL_pidm = s.GOREMAL_pidm
                          AND ss.GOREMAL_EMAL_CODE = s.GOREMAL_EMAL_CODE);
    EXCEPTION WHEN OTHERS THEN 
    LV_MAIL := NULL;
    END;             
	
    BEGIN 

    DELETE FROM avance_n
          WHERE pidm_alu = ln_pidm;

    COMMIT;          

      RetVal := BANINST1.PKG_DASHBOARD_ALUMNO.F_DASHBOARD_AVCU_OUT ( ln_pidm, lv_prog, user );

    EXCEPTION WHEN OTHERS THEN 
    RetVal := NULL;
    END;
                      
                      
                      
    OPEN Vm_Registros FOR 
          SELECT lv_url url,
                 LV_MAIL mail,
                 VL_INICIO fec_ini,
                 VL_FIN fec_fin,
                 lv_estatus estatus,
                 lv_desc_programa programa,
                 lv_desc_type inscripcion_desc,
                 lv_tipo_ingreso_desc tipo_ingreso_desc,
                 nombre_mat asignatura,
                 nombre_area cuatrimestre,
                 materia clave,
                 CASE WHEN APR IN ('EC','PC') 
                 THEN 
                 apr
                 WHEN APR IN ('EQ') 
                 THEN
                 apr ||' ' ||calif 
                 ELSE
                 to_char(NVL (calif, apr)) 
                 END estado_asignatura
            FROM avance_n 
           WHERE pidm_alu = ln_pidm 
        ORDER BY nombre_area;                
               
     
     RETURN Vm_Registros;     
   END f_siu_chatbot;  

    --
    --
  FUNCTION f_siu_chatbot_cargos (p_matricula IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene datos para SIU Chat Bot
     -- FECHA.....: 17/Oct/2024

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;    -- Registros recuperados en la consulta
     lv_url VARCHAR2(100);
     ln_pidm VARCHAR2(20);
     ln_count_esca NUMBER;
     lv_pago_unico VARCHAR2(2);
     lv_saldo_dia VARCHAR2(100);
     lv_saldo_total VARCHAR2(100);
     --
     lv_referencia_pago VARCHAR2(50);
     lv_dia_pago VARCHAR2(2);
     
    BEGIN
    --Elimina tablas de trabajo
    execute immediate 'truncate table baninst1.det_edo_cta_bot';
    --
     BEGIN     
     SELECT fget_pidm(p_matricula)
       INTO ln_pidm
       FROM DUAL;
     EXCEPTION WHEN OTHERS THEN 
     ln_pidm := NULL;
     END;
    DBMS_OUTPUT.PUT_LINE (ln_pidm);
    
    
    Begin            
        SELECT unique GORADID_ADDITIONAL_ID
        INTO lv_referencia_pago
         FROM GORADID 
         WHERE GORADID_PIDM =ln_pidm 
         AND GORADID_ADID_CODE IN ('REFS','REFH');    
    Exception
        When Others then 
          lv_referencia_pago:= null;  
    End;
    --
    
    Begin 
        SELECT DECODE (SUBSTR (a.SORLCUR_RATE_CODE, 4, 1),
                      'A', 15,
                      'B', 30,
                      'C', 10)
              DIA_PAGO
        INTO lv_dia_pago
        FROM SORLCUR a
        WHERE a.SORLCUR_PIDM = ln_pidm 
        AND a.SORLCUR_SEQNO = (SELECT MAX (h.SORLCUR_SEQNO)
                                  FROM SORLCUR h
                                 WHERE h.SORLCUR_pidm = a.SORLCUR_pidm
                                   AND h.SORLCUR_LMOD_CODE = 'LEARNER')  ;
    Exception
      When Others then 
        null;
    End;

    BEGIN 
        insert into baninst1.det_edo_cta_bot  
                     SELECT DISTINCT  TBRACCD_TERM_CODE Periodo,
                                      TBRACCD_TRAN_NUMBER Secuencia,
                                      TBRACCD_DETAIL_CODE Concepto,
                                      NVL (TZTEDTC_DESC_NE, TBBDETC_DESC || '.') Descripcion_Concepto,
                                      (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN TBRACCD_AMOUNT
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN NULL
                                       END)
                                         AS Monto_Inicial_Cargo,
                                      TBRACCD_BALANCE Saldo_Actual_Cargo,
                                      TRUNC (TBRACCD_TRANS_DATE) Fecha_Cargo,                                                                                            
                                      --
                                      TRUNC (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                      (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN NULL
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN TBRACCD_AMOUNT
                                       END)
                                         AS Monto_Pago,
                                      DECODE (TBBDETC_TYPE_IND,  'C', 'Cargo',  'P', 'Pago') Tipo
                        FROM tbraccd, tbbdetc, TVRTAXD, TZTEDTC
                       WHERE TBRACCD_PIDM = ln_pidm
                             AND TBRACCD_DETAIL_CODE IN
                                     (SELECT TVRDCTX_DETC_CODE
                                        FROM TVRDCTX
                                       WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                             )
                             AND TZTEDTC_DETAIL_CODE (+) = TBRACCD_DETAIL_CODE
                             AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                             AND TVRTAXD_PIDM(+) = TBRACCD_PIDM
                             AND TVRTAXD_ACCD_TRAN_NUMBER(+) = TBRACCD_TRAN_NUMBER
                             AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2) =  SUBSTR (TBRACCD_TERM_CODE, 1, 2)
                             AND TBRACCD_DETAIL_CODE NOT IN 
                                    (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD 
                                                                            WHERE TZTCODD_ORIGEN IN ('C1','C2')
                                                                            And TZTCODD_PIDM = ln_pidm
                                                                                )
                             AND (--Para quitar blancos y ceros en cargos y pagos
                                   (CASE
                                     WHEN TBBDETC_TYPE_IND = 'C' THEN TBRACCD_AMOUNT
                                     WHEN TBBDETC_TYPE_IND = 'P' THEN NULL
                                  END) IS NOT NULL
                                  OR
                                  (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN NULL
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN TBRACCD_AMOUNT
                                  END) IS NOT NULL
                                    )
                             --Para Quitar los cargos negativos que se matan asi  mismos
                             AND TBRACCD_TRAN_NUMBER NOT IN(
                                     (SELECT TBRACCD_TRAN_NUMBER
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = ln_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                        UNION
                                        SELECT TBRAPPL_CHG_TRAN_NUMBER
                                        FROM TBRAPPL,TBRACCD
                                        WHERE TBRACCD_PIDM = ln_pidm
                                        AND TBRAPPL_PIDM= TBRACCD_PIDM
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                        AND TBRAPPL_PAY_TRAN_NUMBER IN (
                                                                        SELECT TBRACCD_TRAN_NUMBER
                                                                        FROM TBRACCD, TBBDETC
                                                                        WHERE     TBRACCD_PIDM = ln_pidm
                                                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                                                        AND TBBDETC_TYPE_IND = 'C'
                                                                        AND TBRACCD_AMOUNT < 0
                                                                        )
                                        UNION
                                        SELECT NVL(TBRACCD_TRAN_NUMBER_PAID,0)
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = ln_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                         )
                                        UNION --Excluye Tanto categoria como Detalle configurados en Param (Si existe detalle, no toma la Categoria)
                                        --En cancelaciones definidas en Param y que se requiere que no se muestre la transaccion pagada que cubrio
                                        (SELECT TBRACCD_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = ln_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_PAY_TRAN_NUMBER= TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = ln_pidm
                                                                                 )
                                        UNION
                                         SELECT TBRAPPL_CHG_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = ln_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_PAY_TRAN_NUMBER= TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE 
                                                                                FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = ln_pidm
                                                                                 )
                                        UNION
                                         SELECT TBRAPPL_PAY_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = ln_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_CHG_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE 
                                                                                FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = ln_pidm
                                                                                 )
                                          )
                                          )
                    ORDER BY TRUNC (TBRACCD_TRANS_DATE) desc;    
    Exception
        When Others then 
            null;
    END;


        lv_saldo_dia := PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(ln_pidm) ;
        lv_saldo_total := PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(ln_pidm);


    OPEN Vm_Registros FOR 
    
--    
--            SELECT 
--                nvl (lv_saldo_dia,0) SALDO_DIA, 
--                a.descripcion_concepto descripcion_cargo,
--                a.monto_inicial_cargo monto_cargo,
--                 'https://siu-'||lv_campus||'.scalahed.com/pagos/' LIGA_PAGOS,
--                 lv_dia_pago DIA_PAGO,
--                 lv_referencia_pago REFERENCIA_PAGO
--              FROM baninst1.det_edo_cta_bot a
--             WHERE a.saldo_actual_cargo >0;
             
             
             with cargos as ( select a.descripcion_concepto descripcion_cargo,
                                     a.monto_inicial_cargo monto_cargo
                            from baninst1.det_edo_cta_bot a
                            where a.saldo_actual_cargo >0
                          )
             select nvl (lv_saldo_dia,0) SALDO_DIA, 
                    nvl (cargos.descripcion_cargo,null) descripcion_cargo,
                    nvl (cargos.monto_cargo,0) monto_cargo, 
                     'https://siu-'||substr(p_matricula,1,2)||'.scalahed.com/pagos/' LIGA_PAGOS,
                     lv_dia_pago DIA_PAGO,
                     lv_referencia_pago REFERENCIA_PAGO
             from dual
             left join cargos on 1=1;         
             
             
             
             
/*
             
               SELECT 
                a.periodo PERIODO,
                lv_saldo_dia SALDO_DIA, 
                lv_saldo_total SALDO_TOTAL,                
                a.secuencia secuencia,
                a.descripcion_concepto descripcion_cargo,
                a.monto_inicial_cargo monto_cargo,
                d.sec_pago  secuencia_pago, 
                a.fecha_cargo fecha_registro,
                a.fecha_vencimiento fecha_limite_pago,
                null descripcion_pago,
                null monto_pago,
                null fecha_pago,
                null  secuencia_cargo,
                tipo  , 
                 'https://siu-'||lv_campus||'.scalahed.com/pagos/' LIGA_PAGOS,
                 case when ln_count_esca = 2 then 
                 'VERDADERO'
                 when ln_count_esca <> 2 then 
                 'FALSO'
                 END  PAGOS_ESCALONADOS,
                 case when lv_pago_unico = '01' then 
                 'VERDADERO'
                  when lv_pago_unico <> '01' then 
                  'FALSO'
                  end PAGO_UNICO                    
              FROM det_edo_cta_bot a, det_cargos c,det_pagos_sec d
             WHERE c.TBRAPPL_CHG_TRAN_NUMBER(+) = a.secuencia
             and d.sec_cargo(+) = a.secuencia
             and (a.monto_inicial_cargo is not null or a.monto_inicial_cargo >0 )
            union
            select
                a.periodo PERIODO,
                lv_saldo_dia SALDO_DIA, 
                lv_saldo_total SALDO_TOTAL,                
                a.secuencia secuencia,
                null descripcion_cargo,
                null monto_cargo,
                null  secuencia_pago,                 
                null fecha_registro,
                null fecha_limite_pago,
                a.descripcion_concepto descripcion_pago,
                a.monto_pago monto_pago,
                null fecha_pago,
                null  secuencia_cargo,                 
                tipo       , 
                 'https://siu-'||lv_campus||'.scalahed.com/pagos/' LIGA_PAGOS,
                 case when ln_count_esca = 2 then 
                 'VERDADERO'
                 when ln_count_esca <> 2 then 
                 'FALSO'
                 END  PAGOS_ESCALONADOS,
                 case when lv_pago_unico = '01' then 
                 'VERDADERO'
                  when lv_pago_unico <> '01' then 
                  'FALSO'
                  end PAGO_UNICO                             
              FROM det_edo_cta_bot a, det_pagos b
             WHERE b.TBRAPPL_PAY_TRAN_NUMBER(+) = a.secuencia
             --and d.sec_pago(+) = a.secuencia
             and monto_pago is not null  
             order by secuencia desc ;              
*/
    
     RETURN Vm_Registros;     
    END f_siu_chatbot_cargos;
    
    --
    --           
	--AGOG SIU CHAT BOT 05/06/2025
  FUNCTION f_siu_avance_curr (p_matricula IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene datos para SIU Avance curricular

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;    -- Registros recuperados en la consulta

    
BEGIN

  
    OPEN Vm_Registros FOR 
        SELECT a.pidm,
               a.matricula,
               a.programa,
               (SELECT UNIQUE UPPER (c.SZTDTEC_PROGRAMA_COMP)
                  FROM SZTDTEC c
                 WHERE c.SZTDTEC_PROGRAM = a.programa)
                  nombre,
               a.estatus_d estatus_alumno,
               b.szthita_avance avance_curricular
          FROM TZTPROG a, SZTHITA b
         WHERE     a.pidm = b.szthita_pidm
               AND a.programa = SZTHITA_PROG
               AND a.matricula = p_matricula
               ;         
               
     
     RETURN Vm_Registros;   
   END f_siu_avance_curr;  
    --
    --
  FUNCTION f_siu_chatbot_sd (p_matricula IN VARCHAR2) RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Obtiene datos para SIU Chat Bot Saldo al dia
     -- FECHA.....: 01/07/2025

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;    -- Registros recuperados en la consulta
     lv_campus VARCHAR2(5);
     lv_url VARCHAR2(100);
     ln_pidm VARCHAR2(20);
     lv_saldo_dia VARCHAR2(100);
     --
     
    BEGIN
    --Elimina tablas de trabajo
    execute immediate 'truncate table baninst1.det_edo_cta_bot_sd';
    --
     BEGIN     
     SELECT fget_pidm(p_matricula)
       INTO ln_pidm
       FROM DUAL;
     EXCEPTION WHEN OTHERS THEN 
     ln_pidm := NULL;
     END;
    DBMS_OUTPUT.PUT_LINE (ln_pidm);
    
    --
    --campus para la liga de pagos
    Begin 
        SELECT unique lower(SZVCAMP_CAMP_CODE)
        into lv_campus
      FROM TBRACCD a, SZVCAMP b
     WHERE    SUBSTR (a.TBRACCD_DETAIL_CODE, 1, 2) = b.SZVCAMP_CAMP_ALT_CODE
           AND a.TBRACCD_PIDM = ln_pidm
           AND a.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE 
                                         FROM TBBDETC 
                                        WHERE TBBDETC_DCAT_CODE = 'COL');
    Exception
        When Others then 
          lv_campus:= null;  
    End;
    --



    BEGIN 
        insert into baninst1.det_edo_cta_bot_sd  
                     SELECT DISTINCT  TBRACCD_TERM_CODE Periodo,
                                      TBRACCD_TRAN_NUMBER Secuencia,
                                      TBRACCD_DETAIL_CODE Concepto,
                                      NVL (TZTEDTC_DESC_NE, TBBDETC_DESC || '.') Descripcion_Concepto,
                                      (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN TBRACCD_AMOUNT
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN NULL
                                       END)
                                         AS Monto_Inicial_Cargo,
                                      TBRACCD_BALANCE Saldo_Actual_Cargo,
                                      TRUNC (TBRACCD_TRANS_DATE) Fecha_Cargo,                                                                                            
                                      --
                                      TRUNC (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                      (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN NULL
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN TBRACCD_AMOUNT
                                       END)
                                         AS Monto_Pago,
                                      DECODE (TBBDETC_TYPE_IND,  'C', 'Cargo',  'P', 'Pago') Tipo
                        FROM tbraccd, tbbdetc, TVRTAXD, TZTEDTC
                       WHERE TBRACCD_PIDM = ln_pidm
                             AND TBRACCD_DETAIL_CODE IN
                                     (SELECT TVRDCTX_DETC_CODE
                                        FROM TVRDCTX
                                       WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                             )
                             AND TZTEDTC_DETAIL_CODE (+) = TBRACCD_DETAIL_CODE
                             AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                             AND TVRTAXD_PIDM(+) = TBRACCD_PIDM
                             AND TVRTAXD_ACCD_TRAN_NUMBER(+) = TBRACCD_TRAN_NUMBER
                             AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2) =  SUBSTR (TBRACCD_TERM_CODE, 1, 2)
                             AND TBRACCD_DETAIL_CODE NOT IN 
                                    (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD 
                                                                            WHERE TZTCODD_ORIGEN IN ('C1','C2')
                                                                            And TZTCODD_PIDM = ln_pidm
                                                                                )
                             AND (--Para quitar blancos y ceros en cargos y pagos
                                   (CASE
                                     WHEN TBBDETC_TYPE_IND = 'C' THEN TBRACCD_AMOUNT
                                     WHEN TBBDETC_TYPE_IND = 'P' THEN NULL
                                  END) IS NOT NULL
                                  OR
                                  (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN NULL
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN TBRACCD_AMOUNT
                                  END) IS NOT NULL
                                    )
                             --Para Quitar los cargos negativos que se matan asi  mismos
                             AND TBRACCD_TRAN_NUMBER NOT IN(
                                     (SELECT TBRACCD_TRAN_NUMBER
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = ln_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                        UNION
                                        SELECT TBRAPPL_CHG_TRAN_NUMBER
                                        FROM TBRAPPL,TBRACCD
                                        WHERE TBRACCD_PIDM = ln_pidm
                                        AND TBRAPPL_PIDM= TBRACCD_PIDM
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                        AND TBRAPPL_PAY_TRAN_NUMBER IN (
                                                                        SELECT TBRACCD_TRAN_NUMBER
                                                                        FROM TBRACCD, TBBDETC
                                                                        WHERE     TBRACCD_PIDM = ln_pidm
                                                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                                                        AND TBBDETC_TYPE_IND = 'C'
                                                                        AND TBRACCD_AMOUNT < 0
                                                                        )
                                        UNION
                                        SELECT NVL(TBRACCD_TRAN_NUMBER_PAID,0)
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = ln_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                         )
                                        UNION --Excluye Tanto categoria como Detalle configurados en Param (Si existe detalle, no toma la Categoria)
                                        --En cancelaciones definidas en Param y que se requiere que no se muestre la transaccion pagada que cubrio
                                        (SELECT TBRACCD_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = ln_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_PAY_TRAN_NUMBER= TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = ln_pidm
                                                                                 )
                                        UNION
                                         SELECT TBRAPPL_CHG_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = ln_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_PAY_TRAN_NUMBER= TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE 
                                                                                FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = ln_pidm
                                                                                 )
                                        UNION
                                         SELECT TBRAPPL_PAY_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = ln_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_CHG_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE 
                                                                                FROM TZTCODD 
                                                                                WHERE TZTCODD_ORIGEN IN ('C3','C4')
                                                                                And TZTCODD_PIDM = ln_pidm
                                                                                 )
                                          )
                                          )
                    ORDER BY TRUNC (TBRACCD_TRANS_DATE) desc;    
    Exception
        When Others then 
            null;
    END;


        lv_saldo_dia := PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(ln_pidm) ;


    OPEN Vm_Registros FOR 
    
             with cargos as ( select a.concepto, a.descripcion_concepto descripcion_cargo,
                                     a.monto_inicial_cargo monto_cargo
                            from baninst1.det_edo_cta_bot_sd a
                            where a.saldo_actual_cargo >0
                          )
             select nvl (lv_saldo_dia,0) SALDO_DIA, 
                    nvl (cargos.concepto,null) codigo_detalle,
                    nvl (cargos.descripcion_cargo,null) descripcion_detalle,
                    nvl (cargos.monto_cargo,0) monto
                    -- 'https://siu-'||lv_campus||'.scalahed.com/pagos/' LIGA_PAGOS,
                   --  lv_dia_pago DIA_PAGO,
                   --  lv_referencia_pago REFERENCIA_PAGO					
             from dual
             left join cargos on 1=1;         
             
     RETURN Vm_Registros;     
    END f_siu_chatbot_sd;
    
    ------------------ Proceso de Moras para el Voice Bot de EE ---
    
          Procedure p_Voice_Mora_genera IS
     -- PROPOSITO.: Genera la salida de informacion para el Voice de Mora

     -- Variables Locales
     vl_existe number:=0;
     vl_campo varchar2(200):= null;

    
BEGIN

        For cx in (
        

            Select x.pidm,
                   x.matricula, 
                   x.estatus,
                   x.campus,
                   x.nivel,
                   x.apellido, 
                   x.nombre,
                   x.pais,
                   x.celular,
                   x.correo_principal,
                   x.nivel_descripcion,
                   x.programa,
                   x.sp,
                   x.fecha_inicio,
                   nvl (x.vencimiento_mes,0) vencimiento_mes,
                   nvl (x.vencimiento_general, 0) vencimiento_general,
                   nvl (x.Saldo_complemento,0) Saldo_complemento,
                   x.fecha_corte,
                   x.Fecha_Pago_realizado,
                   Nvl (x.Tipo_Alumno,'C') Tipo_Alumno,
                   x.Moneda,
                   x.Mora,
                   decode (x.Domiciliado,'1', 'SI', '0', 'NO') Domiciliado
             from (
                    select  a.pidm, 
                    a.matricula,
                    a.campus,
                    a.nivel,
                    SUBSTR(b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME, '/') - 1) ||' '|| SUBSTR(b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME, '/') + 1, 150)  Apellido,
                    b.SPRIDEN_FIRST_NAME AS Nombre,
                    SZVCAMP_COUNTRY pais,
                    pkg_utilerias.f_celular(a.pidm, 'CELU') AS Celular,
                    NVL(TRIM(pkg_utilerias.f_correo(a.pidm, 'PRIN')), NVL(TRIM(pkg_utilerias.f_correo(a.pidm, 'UCAM')), TRIM(pkg_utilerias.f_correo(a.pidm, 'UTLX')))) AS Correo_Principal,
                    STVLEVL_DESC Nivel_Descripcion,
                    a.programa,
                    a.sp,
                    a.fecha_inicio,
                    (select sum(nvl (tbraccd_balance, 0)) 
                     from tbraccd 
                     Where tbraccd_pidm = a.pidm 
                     and TBRACCD_STSP_KEY_SEQUENCE = a.sp 
                     and trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and  last_day(trunc (sysdate))
                     And tbraccd_detail_code not in (Select codigo from TZTINC where campus = a.campus and nivel = a.nivel)
                    ) Vencimiento_mes,
                    (select sum(nvl (tbraccd_balance, 0)) 
                        from tbraccd 
                        Where tbraccd_pidm =  a.pidm 
                        and TBRACCD_STSP_KEY_SEQUENCE = a.sp 
                        and trunc (TBRACCD_EFFECTIVE_DATE) < TRUNC(SYSDATE, 'MM')
                    ) Vencimiento_General,
                    (select sum(nvl (tbraccd_balance, 0)) 
                     from tbraccd 
                     Where tbraccd_pidm = a.pidm 
                     and TBRACCD_STSP_KEY_SEQUENCE = a.sp 
                     and trunc (TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and  last_day(trunc (sysdate))
                     And tbraccd_detail_code in (Select codigo from TZTINC where campus = a.campus and nivel = a.nivel)
                    ) Saldo_Complemento ,
                     DECODE(SUBSTR(pkg_utilerias.f_calcula_rate(a.pidm, a.programa), LENGTH(pkg_utilerias.f_calcula_rate(a.pidm, a.programa)) - 1, 1), 'A', '15', 'B', '30', 'C', '10') Fecha_Corte,
                    (select max (trunc (TBRACCD_EFFECTIVE_DATE)) 
                        from tbraccd 
                     where tbraccd_pidm = a.pidm 
                     and TBRACCD_STSP_KEY_SEQUENCE = a.sp 
                     and tbraccd_detail_code in (select TZTNCD_CODE from TZTNCD where 1=1 And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion'))
                     ) Fecha_Pago_realizado,
                     a.SGBSTDN_STYP_CODE Tipo_Alumno,
                    ( select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='CAMP_URL_MONEDA' AND ZSTPARA_PARAM_ID = substr (a.matricula,1,2))  Moneda, 
                     0 Mora,
                     0 Domiciliado,-- (select count(1) from goradid where goradid_pidm = a.pidm and GORADID_ADID_CODE like '%DOM%') Domiciliado,
                     a.estatus
            from tztprog a
            join spriden b on b.spriden_pidm = a.pidm and spriden_change_ind is null
            join SZVCAMP on SZVCAMP_CAMP_CODE = a.campus
            join stvlevl on STVLEVL_CODE = a.nivel 
            where 1=1
            and a.pidm not in (select goradid_pidm from goradid where GORADID_ADID_CODE in ('NOMR', 'IZZI', 'EUTL'))
            and campus in ( select distinct ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='HS_COBRANZA_CAM')
            And nivel in ( select distinct ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='HS_COBRANZA_NIV')
            and a.estatus in ('MA')
            --and matricula ='010000454'
            ) x
            where x.Vencimiento_General =0

        ) loop
        
            vl_existe:=0;
        
            Begin
                Select COUNT(1)
                    Into vl_existe
                from integra_cobranza
                Where matricula = cx.MATRICULA
                And sp = cx.sp;
            Exception
               When Others then 
                vl_existe:=0;
            end;
            
            If vl_existe = 0 then 
            
                Begin
                    Insert into integra_cobranza values (cx.pidm,
                                                         cx.matricula, 
                                                         cx.estatus,
                                                         cx.campus,
                                                         cx.nivel,
                                                         cx.apellido,
                                                         cx.nombre,
                                                         cx.pais,
                                                         cx.celular,
                                                         cx.correo_principal,
                                                         cx.nivel_descripcion,
                                                         cx.programa,
                                                         cx.sp, 
                                                         cx.fecha_inicio,
                                                         cx.vencimiento_mes,
                                                         cx.vencimiento_general,
                                                         cx.saldo_complemento,
                                                         cx.fecha_corte, 
                                                         cx.fecha_pago_realizado,
                                                         cx.tipo_alumno,
                                                         cx.moneda,
                                                         cx.mora,
                                                         cx.domiciliado,
                                                         null,
                                                         null,
                                                         null,
                                                         0,
                                                         null,
                                                         null);
                Commit;
                Exception
                   When others then 
                    null;
                End;
            
            Elsif vl_existe >= 1 then

                            ------------------- Se actualiza Celular ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (CELULAR)
                                            into vl_campo
                                         From integra_cobranza a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CELULAR) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CELULAR) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_cobranza a
                                            set a.CELULAR = cx.CELULAR
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo Celular'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;
            
                            ------------------- Se actualiza CORREO_PRINCIPAL ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (CORREO_PRINCIPAL)
                                            into vl_campo
                                         From integra_cobranza a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CORREO_PRINCIPAL) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CORREO_PRINCIPAL) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_cobranza a
                                            set a.CORREO_PRINCIPAL = cx.CORREO_PRINCIPAL
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo CORREO_PRINCIPAL'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;
            
                           ------------------- Se actualiza FECHA_INICIO ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (FECHA_INICIO)
                                            into vl_campo
                                         From integra_cobranza a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_INICIO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_INICIO) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_cobranza a
                                            set a.FECHA_INICIO = cx.FECHA_INICIO
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo FECHA_INICIO'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;
                                
            
                           ------------------- Se actualiza VENCIMIENTO_MES ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (VENCIMIENTO_MES)
                                            into vl_campo
                                         From integra_cobranza a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.VENCIMIENTO_MES) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.VENCIMIENTO_MES) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_cobranza a
                                            set a.VENCIMIENTO_MES = cx.VENCIMIENTO_MES
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo VENCIMIENTO_MES'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;                                


                           ------------------- Se actualiza SALDO_COMPLEMENTO ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (SALDO_COMPLEMENTO)
                                            into vl_campo
                                         From integra_cobranza a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.SALDO_COMPLEMENTO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.SALDO_COMPLEMENTO) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_cobranza a
                                            set a.SALDO_COMPLEMENTO = cx.SALDO_COMPLEMENTO
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo SALDO_COMPLEMENTO'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;     

                           ------------------- Se actualiza FECHA_PAGO_REALIZADO ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (FECHA_PAGO_REALIZADO)
                                            into vl_campo
                                         From integra_cobranza a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_PAGO_REALIZADO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_PAGO_REALIZADO) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_cobranza a
                                            set a.FECHA_PAGO_REALIZADO = cx.FECHA_PAGO_REALIZADO
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo FECHA_PAGO_REALIZADO'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;   

                           ------------------- Se actualiza TIPO_ALUMNO ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (TIPO_ALUMNO)
                                            into vl_campo
                                         From integra_cobranza a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.TIPO_ALUMNO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.TIPO_ALUMNO) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_cobranza a
                                            set a.TIPO_ALUMNO = cx.TIPO_ALUMNO
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo TIPO_ALUMNO'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;                                   
                                

            End if;  
        
        
        End loop;



  
   END p_Voice_Mora_genera;  
    
    

      FUNCTION f_Voice_Mora  RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Genera la salida de informacion para el Voice de Mora

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;    -- Registros recuperados en la consulta

    
BEGIN


  
    OPEN Vm_Registros FOR 

                    select distinct pidm,
                                     matricula, 
                                     estatus,
                                     campus,
                                     nivel,
                                     apellido,
                                     nombre,
                                     pais,
                                     celular,
                                     correo_principal,
                                     nivel_descripcion,
                                     programa,
                                     (select distinct a.SZTDTEC_PROGRAMA_COMP
                                        from sztdtec a
                                        where a.SZTDTEC_PROGRAM = programa
                                        And a.SZTDTEC_CAMP_CODE = campus
                                        And a.SZTDTEC_TERM_CODE = (select max(a1.SZTDTEC_TERM_CODE) 
                                                                   from sztdtec a1 
                                                                   where 1=1
                                                                   And a.SZTDTEC_CAMP_CODE = a1.SZTDTEC_CAMP_CODE
                                                                   And a.SZTDTEC_PROGRAM = a1.SZTDTEC_PROGRAM)) Descripcion_Programa,                                     
                                     sp, 
                                     fecha_inicio,
                                     vencimiento_mes,
                                     vencimiento_general,
                                     saldo_complemento,
                                     fecha_corte, 
                                     fecha_pago_realizado,
                                     tipo_alumno,
                                     moneda,
                                     mora,
                                     domiciliado,
                                     CONTACTO_HUBSPOT,
                                     REGISTRO_ACADEMICO
                    from integra_cobranza
                    where ESTATUS_ENVIO = 0
                    and pidm not in (select goradid_pidm from goradid where GORADID_ADID_CODE in ('NOMR', 'IZZI', 'EUTL'))
                    and rownum <= 1000;
     
     RETURN Vm_Registros;   
   END f_Voice_Mora;      
              

   
 Function f_Voice_Mora_actualiza (p_matricula in varchar2, p_sp in number, p_ESTATUS_ENVIO in number, p_contacto_hubspot in varchar2, p_registro_academico in varchar2, p_comentario_hubspot in varchar2) return varchar2 
   is 
   

    vl_resultado varchar2(250) := 'EXITO';

    begin

            If trim (p_contacto_hubspot) is not null and  trim (p_registro_academico) is not null then 
            
                    Begin
                        update integra_cobranza
                        set ESTATUS_ENVIO = p_ESTATUS_ENVIO, 
                        CONTACTO_HUBSPOT = p_contacto_hubspot,
                            REGISTRO_ACADEMICO = p_registro_academico,
                            COMENTARIO_HUBSPOT = p_comentario_hubspot
                        Where matricula = p_matricula
                        And sp = p_sp;
                        commit;
                    Exception
                        When Others then
                          vl_resultado := 'Erorr al actualizar Regisro '||sqlerrm;
                    End;

            End if;
               
            Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := ' ';
          Return (vl_resultado);
    End f_Voice_Mora_actualiza;
   
    
      Procedure  p_Voice_nivelacion_genera  IS
     -- PROPOSITO.: Genera la salida de informacion para el Voice de Nivelaciones

     -- Variables Locales
     vl_existe number:=0;
     vl_campo varchar2(500):= null;

    
BEGIN

        EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.NIVELACION_VOICE';
        
        Begin
        
            Insert /*Append*/ into nivelacion_voice 
            with reprobadas as (
                select SFRSTCR_PIDM
                ,SFRSTCR_CAMP_CODE
                , SFRSTCR_LEVL_CODE 
                ,SFRSTCR_RESERVED_KEY
                ,SFRSTCR_GRDE_CODE
                ,SFRSTCR_TERM_CODE
                ,SFRSTCR_CRN
                ,SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB Materia
                ,SSBSECT_PTRM_START_DATE
                ,SSBSECT_PTRM_END_DATE
                ,SFRSTCR_STSP_KEY_SEQUENCE
                from sfrstcr
                join ssbsect b on ssbsect_term_code = SFRSTCR_TERM_CODE and SSBSECt_CRN = SFRSTCR_CRN
                join shrgrde on SHRGRDE_CODE = SFRSTCR_GRDE_CODE and SHRGRDE_PASSED_IND ='N' and  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE
                where 1=1
                And substr (SFRSTCR_TERM_CODE, 5,1) not in ('8', '9')
                And SFRSTCR_RSTS_CODE ='RE'
                and SFRSTCR_GRDE_CODE is not null
                And SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='SIN_MAT_MOODLE')
                ),
            fecha_max as (
                select distinct max (SSBSECT_PTRM_START_DATE) Fecha_inicio_max
                ,SFRSTCR_PIDM
                ,SFRSTCR_STSP_KEY_SEQUENCE
                from sfrstcr
                join ssbsect b on ssbsect_term_code = SFRSTCR_TERM_CODE and SSBSECt_CRN = SFRSTCR_CRN
                join shrgrde on SHRGRDE_CODE = SFRSTCR_GRDE_CODE and SHRGRDE_PASSED_IND ='N' and  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE
                where 1=1
                And substr (SFRSTCR_TERM_CODE, 5,1) not in ('8', '9')
                And SFRSTCR_RSTS_CODE ='RE'
                and SFRSTCR_GRDE_CODE is not null
                And SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='SIN_MAT_MOODLE')
                group by SFRSTCR_PIDM ,SFRSTCR_STSP_KEY_SEQUENCE
            )                  
            Select distinct  
            c.SFRSTCR_PIDM Pidm
            , a.matricula
            ,a.fecha_inicio
            ,c.SFRSTCR_CAMP_CODE Campus
            ,c.SFRSTCR_LEVL_CODE Nivel
            ,a.programa
            ,c.SFRSTCR_RESERVED_KEY Materia_Hija
            ,c.SFRSTCR_GRDE_CODE Calificacion
            ,c.SFRSTCR_TERM_CODE Periodo
            ,c.SFRSTCR_CRN CRN
            ,c.Materia
            ,c.SSBSECT_PTRM_START_DATE Fecha_Inicio_Horario
            ,c.SSBSECT_PTRM_END_DATE Fecha_termino_Horario
            ,c.SFRSTCR_STSP_KEY_SEQUENCE sp,
            Decode (baninst1.pkg_serv_siu.F_NIVE_CERO (a.pidm, 'NIVE', a.programa, c.materia  ), 'EXITO', 'Gratis', 'ERROR No cumple con las reglas', 'Costo') Costo,
            (select nvl (sum (tbraccd_balance),0) from tbraccd where 1=1 and tbraccd_pidm = a.pidm and TBRACCD_STSP_KEY_SEQUENCE = a.sp) Saldo_total,
            null ESTATUS_NIVELACION,
            null FECHA_INICIO_NIVE,
            null FECHA_FIN_NIVE
            from tztprog a
            join szthita b on b.SZTHITA_PIDM = a.pidm and b.SZTHITA_PROG = a.programa
            join reprobadas c on c.SFRSTCR_PIDM = a.pidm and c.SFRSTCR_CAMP_CODE = a.campus and c.SFRSTCR_LEVL_CODE = a.nivel and c.SFRSTCR_STSP_KEY_SEQUENCE = a.sp and trunc (c.SSBSECT_PTRM_START_DATE) != a.fecha_inicio
            join fecha_max d on d.SFRSTCR_PIDM = a.pidm and d.SFRSTCR_STSP_KEY_SEQUENCE = a.sp
            where 1=1
            and a.estatus ='MA'
            and SZTHITA_REPROB > 0
            and trunc (c.SSBSECT_PTRM_START_DATE) = trunc (d.FECHA_INICIO_MAX) 
            --and a.pidm not in (select goradid_pidm from goradid where GORADID_ADID_CODE in ('NOMR', 'IZZI'))
            and a.campus in ( select distinct ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='VB_NIVE_CAMPUS')
            And a.nivel in ( select distinct ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='VB_NIVE_LVL');
            --and matricula ='010000454'
            commit;
        Exception
            When Others then 
                null;
        End;



        Begin 

            For cx in (
                        select a.*,'En Curso' Estatus, trunc (SSBSECT_PTRM_START_DATE) Inicio_NIVE, trunc (SSBSECT_PTRM_END_DATE) Fin_NIVE
                        from nivelacion_voice a
                        join sfrstcr on sfrstcr_pidm = pidm And substr (SFRSTCR_TERM_CODE, 5,1) in ('8')  and SFRSTCR_STSP_KEY_SEQUENCE = a.sp
                        join ssbsect on ssbsect_term_code = sfrstcr_term_code and ssbsect_crn = sfrstcr_crn and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = materia and trunc (SSBSECT_PTRM_START_DATE) > trunc (FECHA_TERMINO_HORARIO)
                        where 1=1
                        and SFRSTCR_RSTS_CODE ='RE'
                        and SFRSTCR_GRDE_CODE is null
                     --   and sfrstcr_pidm= 298303
                        union
                        select a.*, 'Aprobadas' Estatus, trunc (SSBSECT_PTRM_START_DATE) Inicio_NIVE, trunc (SSBSECT_PTRM_END_DATE) Fin_NIVE
                        from nivelacion_voice a
                        join sfrstcr on sfrstcr_pidm = pidm And substr (SFRSTCR_TERM_CODE, 5,1) in ('8')  and SFRSTCR_STSP_KEY_SEQUENCE = a.sp
                        join ssbsect on ssbsect_term_code = sfrstcr_term_code and ssbsect_crn = sfrstcr_crn and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = materia and trunc (SSBSECT_PTRM_START_DATE) > trunc (FECHA_TERMINO_HORARIO)
                        join shrgrde on SHRGRDE_CODE = SFRSTCR_GRDE_CODE and SHRGRDE_PASSED_IND ='Y' and  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE
                        where 1=1
                        and SFRSTCR_RSTS_CODE ='RE'
                        and SFRSTCR_GRDE_CODE is not null
                       -- and sfrstcr_pidm= 298303
                         union
                        select a.*, 'Reprobada' Estatus, trunc (SSBSECT_PTRM_START_DATE) Inicio_NIVE, trunc (SSBSECT_PTRM_END_DATE) Fin_NIVE
                        from nivelacion_voice a
                        join sfrstcr on sfrstcr_pidm = pidm And substr (SFRSTCR_TERM_CODE, 5,1) in ('8') and SFRSTCR_STSP_KEY_SEQUENCE = a.sp
                        join ssbsect on ssbsect_term_code = sfrstcr_term_code and ssbsect_crn = sfrstcr_crn and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = materia and trunc (SSBSECT_PTRM_START_DATE) > trunc (FECHA_TERMINO_HORARIO)
                        join shrgrde on SHRGRDE_CODE = SFRSTCR_GRDE_CODE and SHRGRDE_PASSED_IND ='N' and  SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE
                        where 1=1
                        and SFRSTCR_RSTS_CODE ='RE'
                        and SFRSTCR_GRDE_CODE is not null
                       -- and sfrstcr_pidm= 298303
                        
            ) loop
            
                    Begin
                        Update nivelacion_voice 
                        set ESTATUS_NIVELACION = cx.estatus,
                        FECHA_INICIO_NIVE = cx.INICIO_NIVE,
                        FECHA_FIN_NIVE = cx.FIN_NIVE
                        where pidm = cx.pidm
                        and crn = cx.crn;
                    Exception
                        When Others then 
                            null;
                    End;
            

            End Loop;
            Commit;
            
        End;



        For cx in (

                    select distinct a.pidm, 
                    a.matricula,
                    a.campus,
                    a.nivel,
                    SUBSTR(b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME, '/') - 1) ||' '|| SUBSTR(b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME, '/') + 1, 150)  Apellido,
                    b.SPRIDEN_FIRST_NAME AS Nombre,
                    SZVCAMP_COUNTRY pais,
                    pkg_utilerias.f_celular(a.pidm, 'CELU') AS Celular,
                    NVL(TRIM(pkg_utilerias.f_correo(a.pidm, 'PRIN')), NVL(TRIM(pkg_utilerias.f_correo(a.pidm, 'UCAM')), TRIM(pkg_utilerias.f_correo(a.pidm, 'UTLX')))) AS Correo_Principal,
                    STVLEVL_DESC Nivel_Descripcion,
                    a.programa,
                    a.sp,
                    a.fecha_inicio,
                    a.materia,
                    a.matricula||a.SP||materia id_Materia,
                    SCRSYLN_LONG_COURSE_TITLE Nombre_Materia,
                    a.FECHA_INICIO_HORARIO,
                    a.COSTO,
                    a.SALDO_TOTAL,
                    a.ESTATUS_NIVELACION,
                    a.FECHA_INICIO_NIVE,
                    a.FECHA_FIN_NIVE
            from NIVELACION_VOICE a
            join spriden b on b.spriden_pidm = a.pidm and spriden_change_ind is null
            join SZVCAMP on SZVCAMP_CAMP_CODE = a.campus
            join stvlevl on STVLEVL_CODE = a.nivel 
            join SCRSYLN on SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = a.materia
            where 1=1
            
        ) loop        
        
                vl_existe:=0;
        
                Begin
                    Select COUNT(*)
                        Into vl_existe
                        from integra_nivelacion
                        where 1=1
                        and matricula = cx.MATRICULA
                        And sp = cx.sp
                        And materia = cx.materia;
                Exception
                    When others then 
                        vl_existe:=0;
                End;
        
                If vl_existe = 0 then 
                    Begin
                        Insert into integra_nivelacion values ( cx.pidm,
                                                                cx.matricula,
                                                                cx.campus,
                                                                cx.nivel,
                                                                cx.apellido,
                                                                cx.nombre,
                                                                cx.pais,
                                                                cx.celular,
                                                                cx.correo_principal,
                                                                cx.nivel_descripcion,
                                                                cx.programa,
                                                                cx.sp,
                                                                cx.fecha_inicio,
                                                                cx.materia,
                                                                cx.id_materia, 
                                                                cx.nombre_materia,
                                                                cx.fecha_inicio_horario,
                                                                cx.costo,
                                                                cx.saldo_total,
                                                                cx.estatus_nivelacion,
                                                                cx.fecha_inicio_nive,
                                                                cx.fecha_fin_nive,
                                                                null,
                                                                null,
                                                                null,
                                                                0,
                                                                null,
                                                                null,
                                                                null
                                                                );
                    Commit;
                                                                
                    Exception
                        When Others then 
                            null;
                    End;
                   
                
                Elsif vl_existe >= 1 then


                           ------------------- Se actualiza CELULAR ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (CELULAR)
                                            into vl_campo
                                         From integra_nivelacion a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp
                                         And a.materia = cx.materia;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CELULAR) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CELULAR) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_nivelacion a
                                            set a.CELULAR = cx.CELULAR
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo CELULAR'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp
                                        And a.materia = cx.materia;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;  


                           ------------------- Se actualiza CORREO_PRINCIPAL ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (CORREO_PRINCIPAL)
                                            into vl_campo
                                         From integra_nivelacion a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp
                                         And a.materia = cx.materia;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CORREO_PRINCIPAL) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CORREO_PRINCIPAL) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_nivelacion a
                                            set a.CORREO_PRINCIPAL = cx.CORREO_PRINCIPAL
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo CORREO_PRINCIPAL'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp
                                        And a.materia = cx.materia;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;  

                           ------------------- Se actualiza COSTO ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (COSTO)
                                            into vl_campo
                                         From integra_nivelacion a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp
                                         And a.materia = cx.materia;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.COSTO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.COSTO) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_nivelacion a
                                            set a.COSTO = cx.COSTO
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo COSTO'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp
                                        And a.materia = cx.materia;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;  

                           ------------------- Se actualiza SALDO_TOTAL ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (SALDO_TOTAL)
                                            into vl_campo
                                         From integra_nivelacion a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp
                                         And a.materia = cx.materia;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.SALDO_TOTAL) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.SALDO_TOTAL) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_nivelacion a
                                            set a.SALDO_TOTAL = cx.SALDO_TOTAL
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo SALDO_TOTAL'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp
                                        And a.materia = cx.materia;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;                  


                           ------------------- Se actualiza ESTATUS_NIVELACION ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (ESTATUS_NIVELACION)
                                            into vl_campo
                                         From integra_nivelacion a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp
                                         And a.materia = cx.materia;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ESTATUS_NIVELACION) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ESTATUS_NIVELACION) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_nivelacion a
                                            set a.ESTATUS_NIVELACION = cx.ESTATUS_NIVELACION
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo ESTATUS_NIVELACION'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp
                                        And a.materia = cx.materia;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;                  


                        ------------------- Se actualiza FECHA_INICIO_NIVE ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (FECHA_INICIO_NIVE)
                                            into vl_campo
                                         From integra_nivelacion a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp
                                         And a.materia = cx.materia;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_INICIO_NIVE) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_INICIO_NIVE) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_nivelacion a
                                            set a.FECHA_INICIO_NIVE = cx.FECHA_INICIO_NIVE
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo FECHA_INICIO_NIVE'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp
                                        And a.materia = cx.materia;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;                  


                        ------------------- Se actualiza FECHA_FIN_NIVE ----------------
                                vl_campo:= null;
                                Begin
                                        Select trim (FECHA_FIN_NIVE)
                                            into vl_campo
                                         From integra_nivelacion a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.sp = cx.sp
                                         And a.materia = cx.materia;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_FIN_NIVE) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_FIN_NIVE) is null then
                                    null;
                                Else
                                    Begin
                                        Update integra_nivelacion a
                                            set a.FECHA_FIN_NIVE = cx.FECHA_FIN_NIVE
                                                 ,a.ESTATUS_ENVIO = 0,
                                                 a.FECHA_ACTUALIZACION = sysdate,
                                                a.OBSERVACION_ESTATUS = 'Se actualizo FECHA_FIN_NIVE'
                                         where  a.matricula = cx.matricula
                                        And a.sp = cx.sp
                                        And a.materia = cx.materia;
                                        commit;
                                   Exception
                                    When Others then
                                        null;
                                   End;
                                End if;                  



                End if;
        
        
        End Loop;
  
  

   END p_Voice_nivelacion_genera;  
            
    
    
      FUNCTION f_Voice_Nivelacion  RETURN SYS_REFCURSOR IS
     -- PROPOSITO.: Genera la salida de informacion para el Voice de Nivelaciones

     -- Variables Locales
     Vm_Registros SYS_REFCURSOR;    -- Registros recuperados en la consulta

    
BEGIN

  
    OPEN Vm_Registros FOR 

                    select distinct pidm,
                                    matricula,
                                    campus,
                                    nivel,
                                    apellido,
                                    nombre,
                                    pais,
                                    celular,
                                    correo_principal,
                                    nivel_descripcion,
                                    programa,
                                    (select distinct a.SZTDTEC_PROGRAMA_COMP
                                        from sztdtec a
                                        where a.SZTDTEC_PROGRAM = programa
                                        And a.SZTDTEC_CAMP_CODE = campus
                                        And a.SZTDTEC_TERM_CODE = (select max(a1.SZTDTEC_TERM_CODE) 
                                                                   from sztdtec a1 
                                                                   where 1=1
                                                                   And a.SZTDTEC_CAMP_CODE = a1.SZTDTEC_CAMP_CODE
                                                                   And a.SZTDTEC_PROGRAM = a1.SZTDTEC_PROGRAM)) Descripcion_Programa,
                                    sp,
                                    fecha_inicio,
                                    materia,
                                    id_materia, 
                                    nombre_materia,
                                    fecha_inicio_horario,
                                    costo,
                                    saldo_total,
                                    estatus_nivelacion,
                                    fecha_inicio_nive,
                                    fecha_fin_nive,
                                    CONTACTO_HUBSPOT,
                                    REGISTRO_ACADEMICO,
                                    CURSO_HUBSPOT
                    from integra_nivelacion
                    Where ESTATUS_ENVIO = 0
                    And rownum <= 200;
     
     RETURN Vm_Registros;   
   END f_Voice_Nivelacion;  
        
    
   
Function f_Voice_nivelacion_actualiza (p_matricula in varchar2, p_sp in number, p_materia in varchar2, p_ESTATUS_ENVIO in number,p_contacto_hubspot in varchar2, p_registro_academico in varchar2, p_comentario_hubspot in varchar2, p_CURSO_HUBSPOT in varchar2) return varchar2
   is 
   

    vl_resultado varchar2(250) := 'EXITO';

    begin

            If trim (p_contacto_hubspot) is not null and trim (p_registro_academico) is not null and trim (p_CURSO_HUBSPOT) is not null then 
                Begin
                    update integra_nivelacion
                    set ESTATUS_ENVIO = p_ESTATUS_ENVIO, 
                        CONTACTO_HUBSPOT = p_contacto_hubspot,
                        REGISTRO_ACADEMICO = p_registro_academico,
                        COMENTARIO_HUBSPOT = p_comentario_hubspot,
                        CURSO_HUBSPOT = p_CURSO_HUBSPOT
                    Where matricula = p_matricula
                    And sp = p_sp
                    And materia = p_materia;
                    commit;
                Exception
                    When Others then
                      vl_resultado := 'Erorr al actualizar Regisro '||sqlerrm;
                End;

            End if;
               
            Return (vl_resultado);

    Exception
        when Others then
         vl_resultado := ' ';
          Return (vl_resultado);
    End f_Voice_nivelacion_actualiza;

   
   
END PKG_SIU_CHATBOT;
/

DROP PUBLIC SYNONYM PKG_SIU_CHATBOT;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SIU_CHATBOT FOR BANINST1.PKG_SIU_CHATBOT;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_SIU_CHATBOT TO PUBLIC;
