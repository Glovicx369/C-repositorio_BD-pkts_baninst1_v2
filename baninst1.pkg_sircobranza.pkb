DROP PACKAGE BODY BANINST1.PKG_SIRCOBRANZA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SIRCOBRANZA 
AS
FUNCTION CARTERASREG(p_campus VARCHAR2,
                     p_nivel VARCHAR2,
                     p_fechainicio DATE 
                     )
                     RETURN VARCHAR2 
         IS
            VL_RETORNA       VARCHAR2(100):='EXITO';
            VL_COL           NUMBER;
            VL_DESC          NUMBER;
            VL_PL_PAG        NUMBER;
            VL_PARC          NUMBER;
--            VL_ORB           VARCHAR2(30);
            VL_PR_PAGO       DATE;
            VL_FIN_PAGO      DATE;
            VL_ERROR VARCHAR2 (1000);
            VL_CADENAERROR VARCHAR2 (1000);
            VL_ACTUALIZA_TODO   VARCHAR2(900);   
            DESC_COD varchar2(7):= null;
            MONTO_DSI  number:=0;
            COLEG_ANTE number:=0;
            DSI_ANTE   Number:=0;
            DESCU_ANTE Number:=0;
            PLPA_ANTE  Number:=0;
            PARCI_ANTE Number:=0;
            OBSERVACION Varchar2(500):= null;
            PROMOCION number;
            FECHA_EFECTIVA_PROMOCION date:= null;

              BEGIN 
                   
                    PKG_SIRCOBRANZA.p_cargatztprog_cart; commit;
                    VL_ACTUALIZA_TODO := PKG_FINANZAS_REZA.F_ACTUALIZA_RATE_DSI ( null, p_fechainicio);
                    
                    DELETE SZTCART;
                    
                    COMMIT;
                            
                    For cx in (
                            
                                    Select a.matricula, a.campus, a.nivel, a.fecha_inicio, a.pidm ,
                                       pkg_utilerias.f_calcula_rate(a.pidm, a.programa) Rate                      
                                    from TZTPROG_CART a 
                                    Where 1= 1
                                    And a.estatus = 'MA'
                                    And a.fecha_inicio = p_fechainicio
                                    AND a.campus  = nvl(p_campus,a.campus) -------------------------------------PARAMETRO EN
                                    AND a.nivel  =nvl(p_nivel,a.nivel)-------------------------------------PARAMETRO ENTRADA
                                    and a.campus||a.nivel not in ( 'UTSID', 'UTSEC', 'INIEC')
                                    And a.sp = (select max (a1.sp)
                                                    from TZTPROG_CART a1
                                                    Where a.pidm = a1.pidm
                                                    and a1.campus||a1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                                                    And a1.fecha_inicio = a.fecha_inicio
                                                    )        
                                    And a.pidm not in (select goradid_pidm
                                                                from GORADID
                                                                Where 1=1
                                                                And GORADID_ADID_CODE ='SBTI' ----> Se excluyen a los alumnos que cuenten con la etiqueta de Retencion 
                                                                )                                                                    
                                    order by 2,1 desc
                     ) loop  
  
                             FOR alumno in (
                             
                             SELECT distinct
                                            A.campus CAMPUS,
                                            A.nivel NIVEL,
                                            A.programa PROGRAMA,
                                            A.pidm PIDM,
                                            a.matricula MATRICULA,
                                            a.SGBSTDN_STYP_CODE TIPO_ALUM,
                                            A.sp STUDY,
                                            A.fecha_inicio  FECHAVIG,
                                            f.SFRSTCR_TERM_CODE PERIODO,
                                            f.SFRSTCR_PTRM_CODE Pperiodo,
                                            g.SSBSECT_PTRM_START_DATE FECHA,
                                            A.fecha_inicio fechainicio,
                                            trim (substr (pkg_utilerias.f_jornada (a.pidm, a.sp),1,5)) Jornada, ----------------------
                                            NVL( DECODE(SUBSTR (cx.rate, 4, 1),'A',15,'B',30),15)VIGENCIA,
                                            NVL(CASE 
                                            SUBSTR (cx.rate, 1, 1)  
                                            WHEN  ('P') THEN SUBSTR (cx.rate, 2, 2)
                                            WHEN  ('C') THEN SUBSTR (cx.rate, 3, 1)-- Se agrega
                                            WHEN  ('J') THEN SUBSTR (cx.rate, 3, 1)
                                            END,0) NUM_PAG,
                                            NVL((select rm.SZTPTRM_PROPEDEUTICO
                                                    from sztptrm rm 
                                                    where 1=1
                                                    AND rm.SZTPTRM_CAMP_CODE=A.campus
                                                    AND RM.SZTPTRM_LEVL_CODE=A.nivel
                                                    AND RM.SZTPTRM_TERM_CODE=A.MATRICULACION
                                                    AND  rm.SZTPTRM_PROGRAM=A.programa
                                                    and rownum=1
                                                    ),0)Propedeutico,                                                                                          
                                     (SELECT DISTINCT cur.SORLCUR_SITE_CODE
                                      FROM SORLCUR CUR
                                      WHERE CUR.SORLCUR_PIDM = a.pidm
                                      AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                      AND CUR.SORLCUR_SEQNO in (SELECT MAX (SORLCUR_SEQNO)
                                                               FROM SORLCUR CUR2
                                                               WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                               AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO
                                    FROM TZTPROG_CART A
                                    join SFRSTCR F on F.SFRSTCR_PIDM = a.pidm 
                                            AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
                                            AND F.SFRSTCR_RSTS_CODE ='RE'
                                            AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.sp
                                            AND (SFRSTCR_RESERVED_KEY != 'M1HB401'OR SFRSTCR_RESERVED_KEY IS NULL )
                                            AND (F.SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL )
                                            AND (F.SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
                                         --   and (SFRSTCR_USER_ID != 'MIGRA_D'OR SFRSTCR_USER_ID IS NULL)
                                     join SSBSECT G on G.SSBSECT_TERM_CODE = F.SFRSTCR_TERM_CODE
                                             AND  G.SSBSECT_CRN = F.SFRSTCR_CRN 
                                             And G.SSBSECT_PTRM_CODE =  F.SFRSTCR_PTRM_CODE  
                                            AND TRUNC (G.SSBSECT_PTRM_START_DATE) =  a.fecha_inicio
                                    Where 1= 1
                                    AND a.matricula = cx.matricula
                                    AND A.PIDM= cx.pidm
                                    AND a.campus  = cx.campus
                                    AND a.nivel  = cx.nivel    
                                    And a.fecha_inicio = cx.fecha_inicio   
                                    
                              )
                              LOOP
                              
                             --   DBMS_OUTPUT.PUT_LINE ('Salida mia'||'---'||alumno.pidm);
                              
                                VL_COL           :=NULL;
                                VL_DESC          :=NULL;
                                VL_PL_PAG        :=NULL;
                                VL_PARC          :=NULL;
        --                        VL_ORB           :=NULL;
                                VL_PR_PAGO       :=NULL;
                                VL_FIN_PAGO      :=NULL;
                                VL_ERROR         :=NULL;
                                VL_CADENAERROR   :=NULL;
                                DESC_COD         := null;
                                MONTO_DSI        :=0;
                                COLEG_ANTE       :=0;
                                DSI_ANTE         :=0;
                                PLPA_ANTE        :=0;
                                PROMOCION        :=0;
                                DESCU_ANTE       :=0;
                                PARCI_ANTE       :=0;
                                OBSERVACION      := null;
                                
                                ------------------- Descuento -----------
                                       Begin      
                                            SELECT distinct max (TBBESTU_EXEMPTION_CODE)
                                                Into DESC_COD
                                            FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
                                            WHERE TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                            AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE 
                                            AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE  
                                            AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                                            AND A.TBBESTU_DEL_IND IS NULL
                                            AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE    
                                            AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE    
                                            AND A.TBBESTU_TERM_CODE in (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                                                         FROM TBBESTU A1,TBBEXPT,TBREDET
                                                                        WHERE A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                                              AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE 
                                                                              AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                                              AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE    
                                                                              AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE     
                                                                              AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                                              AND A1.TBBESTU_DEL_IND IS NULL
                                                                             -- AND A1.TBBESTU_TERM_CODE <= F.SFRSTCR_TERM_CODE
                                                                              )
                                            AND A.TBBESTU_EXEMPTION_PRIORITY in (SELECT MAX(TBBESTU_EXEMPTION_PRIORITY)
                                                                                FROM TBBESTU A1
                                                                                WHERE A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                                                AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = A.TBBESTU_STUDENT_EXPT_ROLL_IND
                                                                                AND A1.TBBESTU_DEL_IND IS NULL
                                                                                AND A1.TBBESTU_TERM_CODE = A.TBBESTU_TERM_CODE)           
                                            AND TBBESTU_PIDM = Alumno.pidm 
                                            AND TBBDETC_DCAT_CODE = 'DSP';                                
                                       Exception
                                        When OThers then 
                                        DESC_COD:= null;
                                       End;
                                    
                                
                                --------------------- Monto MONTO_DSI   -------------------
                                      Begin
                                           SELECT DISTINCT nvl (TZTDMTO_MONTO,0) 
                                            Into MONTO_DSI
                                            FROM TZTDMTO A
                                            WHERE A.TZTDMTO_PIDM   = alumno.pidm
                                            AND  A.TZTDMTO_CAMP_CODE = alumno.campus
                                            AND  A.TZTDMTO_NIVEL  = alumno.nivel
                                            AND A.TZTDMTO_PROGRAMA =  alumno.programa
                                            AND A.TZTDMTO_IND = 1
                                            AND A.TZTDMTO_STUDY_PATH = alumno.STUDY
                                            AND ( A.TZTDMTO_TERM_CODE  = alumno.periodo
                                                 OR A.TZTDMTO_TERM_CODE in (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                           FROM TZTDMTO TZT
                                                                           WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                           AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                           AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                           AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                           AND TZT.TZTDMTO_IND = 1
                                                                           AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                           AND TZT.TZTDMTO_TERM_CODE  <= alumno.periodo))
                                            AND A.TZTDMTO_ACTIVITY_DATE in (SELECT MAX (A1.TZTDMTO_ACTIVITY_DATE)
                                                                            FROM TZTDMTO A1
                                                                            WHERE A1.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                            AND   A1.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                            AND  A1.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                            AND A1.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                            AND A1.TZTDMTO_IND = 1
                                                                            AND A1.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                            AND ( A1.TZTDMTO_TERM_CODE  = alumno.periodo
                                                                                  OR A1.TZTDMTO_TERM_CODE in (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                                                             FROM TZTDMTO TZT
                                                                                                             WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                                                             AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                                                             AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                                                             AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                                                             AND TZT.TZTDMTO_IND = 1
                                                                                                             AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                                                             AND TZT.TZTDMTO_TERM_CODE  <= alumno.periodo))) 
                                             AND A.TZTDMTO_TERM_CODE  <= alumno.periodo
                                             AND ROWNUM = 1;
                                             
                                      Exception
                                        When Others then 
                                           MONTO_DSI:=0;  
                                      End;                         
                                
                                ---------------------------------------Colegiatura Anterior ----------
                                     Begin 
                                
                                           SELECT SUM(nvl (TBRACCD_AMOUNT,0))
                                             Into COLEG_ANTE
                                            FROM TBRACCD CD,TBBDETC
                                            WHERE CD.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            AND CD.TBRACCD_PIDM =alumno.pidm
                                            AND CD.TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                                          FROM TBBDETC
                                                                          WHERE TBBDETC_DCAT_CODE IN ('TUI'))
                                            AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                         FROM TBRACCD A1
                                                                         WHERE A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                         AND A1.TBRACCD_TERM_CODE = CD.TBRACCD_TERM_CODE
                                                                         AND A1.TBRACCD_PIDM = CD.TBRACCD_PIDM)                               
                                            AND CD.TBRACCD_TERM_CODE in (SELECT MAX (A1.TBRACCD_TERM_CODE)
                                                                       FROM TBRACCD A1
                                                                       WHERE A1.TBRACCD_PIDM = CD.TBRACCD_PIDM
                                                                       AND A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                       AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio OR A1.TBRACCD_FEED_DATE is null));                                
                                    Exception
                                        When OThers then 
                                         COLEG_ANTE:=0;
                                    End;
                                
                                      --------------------------------Descuento Anterior --------------
                                
                                    Begin                     
                                            SELECT SUM(nvl (TBRACCD_AMOUNT,0)) 
                                              into DESCU_ANTE    
                                            FROM TBRACCD CD,TBBDETC
                                            WHERE CD.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            AND CD.TBRACCD_PIDM = Alumno.pidm
                                            AND CD.TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                                          FROM TBBDETC
                                                                          WHERE TBBDETC_DCAT_CODE IN ('DSP'))
                                            AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                         FROM TBRACCD A1
                                                                         WHERE A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                         AND A1.TBRACCD_TERM_CODE = CD.TBRACCD_TERM_CODE
                                                                         AND A1.TBRACCD_PIDM = CD.TBRACCD_PIDM)                               
                                            AND CD.TBRACCD_TERM_CODE in (SELECT MAX (A1.TBRACCD_TERM_CODE)
                                                                       FROM TBRACCD A1
                                                                       WHERE A1.TBRACCD_PIDM = CD.TBRACCD_PIDM
                                                                       AND A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                       AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio or A1.TBRACCD_FEED_DATE is null)
                                                                       );
                                    Exception
                                        When Others then 
                                          DESCU_ANTE:=0;                                  
                                    End;
                                
                                
                                ----------------------------------------------DSI_ANTE --------------------------------------
                                
                                    Begin
                                            SELECT SUM(nvl (TBRACCD_AMOUNT,0))
                                                Into DSI_ANTE
                                            FROM TBRACCD CD,TZTNCD
                                            WHERE CD.TBRACCD_DETAIL_CODE = TZTNCD_CODE
                                            And TZTNCD_CONCEPTO = 'Descuento'
                                            And substr (TZTNCD_DESCP, 1,3)= 'DSI'
                                            AND CD.TBRACCD_PIDM = Alumno.pidm
                                            AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                         FROM TBRACCD A1
                                                                         WHERE A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                         AND A1.TBRACCD_TERM_CODE = CD.TBRACCD_TERM_CODE
                                                                         AND A1.TBRACCD_PIDM = CD.TBRACCD_PIDM)                               
                                            AND CD.TBRACCD_TERM_CODE in (SELECT MAX (A1.TBRACCD_TERM_CODE)
                                                                         FROM TBRACCD A1
                                                                         WHERE A1.TBRACCD_PIDM = CD.TBRACCD_PIDM
                                                                         AND A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                         AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio or A1.TBRACCD_FEED_DATE is null));
                                    Exception
                                        When Others then  
                                        DSI_ANTE:=0;                                 
                                    End;
                                
                                
                                 ---------------------------------PLPA_ANTE --------------------------------------
                                 
                                    Begin 
                                        SELECT SUM( (CASE WHEN TBBDETC_DETAIL_CODE = 'PLPA' THEN 
                                                        nvl (TBRACCD_AMOUNT,0)
                                                    END)) AS COLEGIATURA
                                          Into PLPA_ANTE
                                        FROM TBRACCD CD,TBBDETC
                                        WHERE CD.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                        AND CD.TBRACCD_PIDM = alumno.pidm
                                        AND CD.TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                                      FROM TBBDETC
                                                                      WHERE TBBDETC_DCAT_CODE IN ('LPC'))
                                        AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                     FROM TBRACCD A1
                                                                     WHERE A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                     AND A1.TBRACCD_TERM_CODE = CD.TBRACCD_TERM_CODE
                                                                     AND A1.TBRACCD_PIDM = CD.TBRACCD_PIDM)                               
                                        AND CD.TBRACCD_TERM_CODE in (SELECT MAX (A1.TBRACCD_TERM_CODE)
                                                                      FROM TBRACCD A1
                                                                     WHERE A1.TBRACCD_PIDM = CD.TBRACCD_PIDM
                                                                     AND A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                     AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio or A1.TBRACCD_FEED_DATE is null));                                  
                                
                                    Exception
                                        When Others then 
                                        PLPA_ANTE:=0;
                                    End;
                                
                                --------------------------PARCI_ANTE -----------------------------------------------
                                 
                                   Begin 

                                                SELECT SUM (nvl (TBRACCD_AMOUNT,0))
                                                  Into PARCI_ANTE
                                                FROM TBRACCD CD, TZTNCD
                                                WHERE CD.TBRACCD_DETAIL_CODE = TZTNCD_CODE
                                                And TZTNCD_CONCEPTO ='Venta'
                                                AND CD.TBRACCD_PIDM = Alumno.pidm
                                                And CD.TBRACCD_STSP_KEY_SEQUENCE = Alumno.study
                                                AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                                 FROM TBRACCD A1
                                                                                 WHERE 1= 1
                                                                                 And cd.TBRACCD_PIDM = a1.TBRACCD_PIDM
                                                                                 And cd.TBRACCD_DETAIL_CODE = a1.TBRACCD_DETAIL_CODE
                                                                                 AND cd.TBRACCD_STSP_KEY_SEQUENCE = A1.TBRACCD_STSP_KEY_SEQUENCE
                                                                                  AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio OR A1.TBRACCD_FEED_DATE IS NULL) 
                                                                                 AND A1.TBRACCD_TERM_CODE in (SELECT MAX (A2.TBRACCD_TERM_CODE)
                                                                                                                 FROM TBRACCD A2
                                                                                                                 WHERE a1.TBRACCD_PIDM = a2.TBRACCD_PIDM
                                                                                                                 And a1.TBRACCD_DETAIL_CODE = a2.TBRACCD_DETAIL_CODE
                                                                                                                 AND a1.TBRACCD_STSP_KEY_SEQUENCE = a2.TBRACCD_STSP_KEY_SEQUENCE
                                                                                                                 AND (A2.TBRACCD_FEED_DATE != alumno.fechainicio OR A2.TBRACCD_FEED_DATE IS NULL)
                                                                                                                ));
                                                                                                                                            
                                   Exception
                                    When Others then 
                                    PARCI_ANTE:=0;
                                   End;
                                
                                
                                -----------------------OBSERVACION -------------------------------------------------
                                
                                  Begin 
                                       SELECT DISTINCT TZDOCTR_OBSERVACIONES
                                            Into OBSERVACION
                                       FROM TZDOCTR b
                                       WHERE 1=1
                                       and b.TZDOCTR_PIDM= Alumno.pidm
                                       AND b.TZDOCTR_TERM_CODE = alumno.periodo
                                       AND b.TZDOCTR_PTRM_CODE = alumno.pperiodo
                                       AND TRUNC (b.TZDOCTR_START_DATE) = TRUNC (alumno.fechainicio)
                                       AND b.TZDOCTR_PROGRAM = alumno.programa
                                       AND b.TZDOCTR_IND in (1,0)
                                       AND b.TZDOCTR_TIPO_PROC != 'AUME'
                                       AND b.FECHA_PROCESO in (SELECT MAX(a1.FECHA_PROCESO)
                                                               FROM TZDOCTR A1
                                                               WHERE 1=1 
                                                              AND a1.TZDOCTR_PIDM= b.TZDOCTR_PIDM
                                                              AND a1.TZDOCTR_TERM_CODE = b.TZDOCTR_TERM_CODE 
                                                              AND a1.TZDOCTR_PTRM_CODE = b.TZDOCTR_PTRM_CODE
                                                              AND TRUNC (A1.TZDOCTR_START_DATE) = TRUNC (alumno.fechainicio)
                                                              AND a1.TZDOCTR_PROGRAM =b.TZDOCTR_PROGRAM 
                                                              AND a1.TZDOCTR_IND in (1,0)
                                                              AND a1.TZDOCTR_TIPO_PROC != 'AUME');
                                  Exception
                                    When Others then 
                                     OBSERVACION:=null;
                                  End;
                                
                                
                                ------------------------------------------------------------------------
                                  Begin 
                                        SELECT DISTINCT max (TZFACCE_AMOUNT)
                                            Into PROMOCION
                                           FROM TZFACCE T
                                          WHERE     1=1
                                                AND T.TZFACCE_PIDM = alumno.pidm
                                                AND SUBSTR(T.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                                                AND T.TZFACCE_FLAG = 0
                                                AND LAST_DAY(T.TZFACCE_EFFECTIVE_DATE) = LAST_DAY(TO_DATE(alumno.fechainicio)+12) 
                                                AND T.TZFACCE_STUDY in ( SELECT MAX(TZFACCE_STUDY)
                                                                          FROM TZFACCE
                                                                         WHERE 1=1
                                                                              AND TZFACCE_PIDM = T.TZFACCE_PIDM);
                                  Exception
                                    When Others then 
                                      PROMOCION:= 0;                                          
                                  End;                                 
                                
                                ------------------------------------------------------------------------

                                  Begin
                                        SELECT DISTINCT trunc (TZFACCE_EFFECTIVE_DATE)
                                            Into FECHA_EFECTIVA_PROMOCION
                                           FROM TZFACCE T
                                          WHERE     1=1
                                                AND T.TZFACCE_PIDM = alumno.pidm
                                                AND SUBSTR(T.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                                                AND T.TZFACCE_FLAG = 0
                                                AND LAST_DAY(T.TZFACCE_EFFECTIVE_DATE) = LAST_DAY(TO_DATE(alumno.fechainicio)+12) 
                                                AND T.TZFACCE_STUDY in ( SELECT MAX(TZFACCE_STUDY)
                                                                          FROM TZFACCE
                                                                         WHERE 1=1
                                                                              AND TZFACCE_PIDM = T.TZFACCE_PIDM);                                
                                  Exception
                                    When Others then  
                                    FECHA_EFECTIVA_PROMOCION:= null;
                                  End;
                                
                                ------------------------------------------------------------------------
                                
                                    
                                                 IF ALUMNO.PRE_ACTUALIZADO IS NOT NULL THEN
                                                
                                                                    BEGIN

                                                                        SELECT A.SFRRGFE_MAX_CHARGE 
                                                                        INTO VL_COL
                                                                        FROM SFRRGFE A , TBBDETC 
                                                                        WHERE TBBDETC_DETAIL_CODE = SFRRGFE_DETL_CODE
                                                                        AND A.SFRRGFE_TERM_CODE= ALUMNO.PERIODO
                                                                        AND A.SFRRGFE_TYPE = 'STUDENT'
                                                                        AND A.SFRRGFE_ENTRY_TYPE = 'R'
                                                                        AND A.SFRRGFE_LEVL_CODE = ALUMNO.NIVEL
                                                                        AND A.SFRRGFE_CAMP_CODE = ALUMNO.CAMPUS
                                                                        AND A.SFRRGFE_ATTS_CODE = ALUMNO.JORNADA--ALUMNO.JORNADA
                                                                        AND A.SFRRGFE_RATE_CODE = cx.RATE
                                                                        AND A.SFRRGFE_DEPT_CODE = ALUMNO.PRE_ACTUALIZADO
                                                                        AND A.SFRRGFE_PROGRAM = ALUMNO.PROGRAMA
                                                                        AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                                                                              FROM SFRRGFE A1
                                                                                              WHERE A1.SFRRGFE_TERM_CODE = A.SFRRGFE_TERM_CODE
                                                                                              AND A1.SFRRGFE_TYPE = A.SFRRGFE_TYPE
                                                                                              AND A1.SFRRGFE_ENTRY_TYPE = A.SFRRGFE_ENTRY_TYPE
                                                                                              AND A1.SFRRGFE_LEVL_CODE = A.SFRRGFE_LEVL_CODE
                                                                                              AND A1.SFRRGFE_CAMP_CODE = A.SFRRGFE_CAMP_CODE
                                                                                              AND A1.SFRRGFE_ATTS_CODE = A.SFRRGFE_ATTS_CODE
                                                                                              AND A1.SFRRGFE_RATE_CODE = A.SFRRGFE_RATE_CODE
                                                                                              AND A1.SFRRGFE_DEPT_CODE = A.SFRRGFE_DEPT_CODE
                                                                                              AND A1.SFRRGFE_PROGRAM = ALUMNO.PROGRAMA
                                                                                              );

                                                           EXCEPTION 
                                                           WHEN NO_DATA_FOUND THEN

                                                                    BEGIN

                                                                        SELECT A.SFRRGFE_MAX_CHARGE
                                                                        INTO VL_COL 
                                                                        FROM SFRRGFE A , TBBDETC 
                                                                        WHERE TBBDETC_DETAIL_CODE = SFRRGFE_DETL_CODE
                                                                        AND  A.SFRRGFE_TERM_CODE= ALUMNO.PERIODO
                                                                        AND A.SFRRGFE_TYPE = 'STUDENT'
                                                                        AND SFRRGFE_ENTRY_TYPE = 'R'
                                                                        AND A.SFRRGFE_LEVL_CODE = ALUMNO.NIVEL
                                                                        AND A.SFRRGFE_CAMP_CODE = ALUMNO.CAMPUS
                                                                        AND A.SFRRGFE_ATTS_CODE = ALUMNO.JORNADA--ALUMNO.JORNADA
                                                                        AND A.SFRRGFE_RATE_CODE = cx.RATE
                                                                        AND A.SFRRGFE_DEPT_CODE = ALUMNO.PRE_ACTUALIZADO
                                                                        AND A.SFRRGFE_PROGRAM IS NULL
                                                                        AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                                                                              FROM SFRRGFE A1
                                                                                              WHERE A1.SFRRGFE_TERM_CODE = A.SFRRGFE_TERM_CODE
                                                                                              AND A1.SFRRGFE_TYPE = A.SFRRGFE_TYPE
                                                                                              AND A1.SFRRGFE_ENTRY_TYPE = A.SFRRGFE_ENTRY_TYPE
                                                                                              AND A1.SFRRGFE_LEVL_CODE = A.SFRRGFE_LEVL_CODE
                                                                                              AND A1.SFRRGFE_CAMP_CODE = A.SFRRGFE_CAMP_CODE
                                                                                              AND A1.SFRRGFE_ATTS_CODE = A.SFRRGFE_ATTS_CODE
                                                                                              AND A1.SFRRGFE_RATE_CODE = A.SFRRGFE_RATE_CODE
                                                                                              AND A1.SFRRGFE_DEPT_CODE = A.SFRRGFE_DEPT_CODE
                                                                                              AND A1.SFRRGFE_PROGRAM IS NULL);

                                                            EXCEPTION 
                                                            WHEN OTHERS THEN 
                                                              VL_ERROR :='Validar Regla de Cobro, Parametros = '||ALUMNO.PERIODO||'  -  '||NVL(ALUMNO.JORNADA,'SIN JORNADA')||'  -  '||cx.RATE; 
                                                              VL_CADENAERROR:=VL_CADENAERROR||'|'||VL_ERROR;
                                                              VL_COL := NULL;
                                                            END;
                                        
                                                         END;
                                        
                                           
                                                ELSIF ALUMNO.PRE_ACTUALIZADO IS  NULL THEN        
                                                
                                                
                                                        BEGIN      
                                                                                                                                         
                                                            SELECT A.SFRRGFE_MAX_CHARGE
                                                            INTO VL_COL
                                                            FROM SFRRGFE A , TBBDETC 
                                                            WHERE TBBDETC_DETAIL_CODE = SFRRGFE_DETL_CODE
                                                            AND  A.SFRRGFE_TERM_CODE = ALUMNO.PERIODO
                                                            AND A.SFRRGFE_TYPE = 'STUDENT'
                                                            AND SFRRGFE_ENTRY_TYPE = 'R'
                                                            AND A.SFRRGFE_LEVL_CODE = ALUMNO.NIVEL
                                                            AND A.SFRRGFE_CAMP_CODE = ALUMNO.CAMPUS
                                                            AND A.SFRRGFE_ATTS_CODE = ALUMNO.JORNADA
                                                            AND A.SFRRGFE_RATE_CODE = cx.RATE
                                                            AND A.SFRRGFE_PROGRAM = ALUMNO.PROGRAMA
                                                            AND A.SFRRGFE_DEPT_CODE IS NULL
                                                            AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                                                                  FROM SFRRGFE A1
                                                                                  WHERE A1.SFRRGFE_TERM_CODE = A.SFRRGFE_TERM_CODE
                                                                                  AND A1.SFRRGFE_TYPE = A.SFRRGFE_TYPE
                                                                                  AND A1.SFRRGFE_ENTRY_TYPE = A.SFRRGFE_ENTRY_TYPE
                                                                                  AND A1.SFRRGFE_LEVL_CODE = A.SFRRGFE_LEVL_CODE
                                                                                  AND A1.SFRRGFE_CAMP_CODE = A.SFRRGFE_CAMP_CODE
                                                                                  AND A1.SFRRGFE_ATTS_CODE = A.SFRRGFE_ATTS_CODE
                                                                                  AND A1.SFRRGFE_RATE_CODE = A.SFRRGFE_RATE_CODE
                                                                                  AND A1.SFRRGFE_DEPT_CODE IS NULL
                                                                                  AND A1.SFRRGFE_PROGRAM = ALUMNO.PROGRAMA
                                                                                  );
                                                 EXCEPTION
                                                 WHEN OTHERS THEN 

                                                                BEGIN      
                                                                                                                                                 
                                                                    SELECT A.SFRRGFE_MAX_CHARGE
                                                                    INTO VL_COL
                                                                    FROM SFRRGFE A , TBBDETC 
                                                                    WHERE TBBDETC_DETAIL_CODE = SFRRGFE_DETL_CODE
                                                                    AND  A.SFRRGFE_TERM_CODE= ALUMNO.PERIODO
                                                                    AND A.SFRRGFE_TYPE = 'STUDENT'
                                                                    AND SFRRGFE_ENTRY_TYPE = 'R'
                                                                    AND A.SFRRGFE_LEVL_CODE = ALUMNO.NIVEL
                                                                    AND A.SFRRGFE_CAMP_CODE = ALUMNO.CAMPUS
                                                                    AND A.SFRRGFE_ATTS_CODE = ALUMNO.JORNADA--ALUMNO.JORNADA
                                                                    AND A.SFRRGFE_RATE_CODE = cx.RATE
                                                                    AND A.SFRRGFE_DEPT_CODE IS NULL
                                                                    AND A.SFRRGFE_PROGRAM IS NULL
                                                                    AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                                                                          FROM SFRRGFE A1
                                                                                          WHERE A1.SFRRGFE_TERM_CODE = A.SFRRGFE_TERM_CODE
                                                                                          AND A1.SFRRGFE_TYPE = A.SFRRGFE_TYPE
                                                                                          AND A1.SFRRGFE_ENTRY_TYPE = A.SFRRGFE_ENTRY_TYPE
                                                                                          AND A1.SFRRGFE_LEVL_CODE = A.SFRRGFE_LEVL_CODE
                                                                                          AND A1.SFRRGFE_CAMP_CODE = A.SFRRGFE_CAMP_CODE
                                                                                          AND A1.SFRRGFE_ATTS_CODE = A.SFRRGFE_ATTS_CODE
                                                                                          AND A1.SFRRGFE_RATE_CODE = A.SFRRGFE_RATE_CODE
                                                                                          AND A1.SFRRGFE_DEPT_CODE IS NULL
                                                                                          AND A1.SFRRGFE_PROGRAM IS NULL);
                                                  EXCEPTION
                                                  WHEN OTHERS THEN 
                                                  VL_ERROR :='Validar Regla de Cobro, Parametros = '||ALUMNO.PERIODO||'  -  '||NVL(ALUMNO.JORNADA,'SIN JORNADA')||'  -  '||cx.RATE; 
                                                  VL_CADENAERROR:=VL_CADENAERROR||'|'||VL_ERROR;
                                                  VL_COL:= NULL; 
                                                  END;
                                                                                            
                                          --        DBMS_OUTPUT.PUT_LINE ('reza valida 1'||'---'||VL_ERROR);
                                                                                            
                                                 END;
                                              
                                                
                                                END IF; 
                                     
                                            --      DBMS_OUTPUT.PUT_LINE(VL_COL||'  COLEGIATURA');
                                                  
                                                IF VL_COL<>0 THEN
                                                
                                              
                                                  -- Se agregó la condición porque el código de descuento es de 7 dígitos 
                                                    IF LENGTH(DESC_COD) = 6 THEN
                                                        VL_DESC:=(VL_COL*substr (DESC_COD,4,3))/100;
                                                    END IF;
                                                    
                                                    IF LENGTH(DESC_COD) = 7 THEN
                                                        VL_DESC:=(VL_COL*substr (DESC_COD,5,3))/100;
                                                    END IF;
                                                   
                                                   VL_PL_PAG:=VL_COL-VL_DESC-MONTO_DSI;
                                                   VL_PARC:=VL_PL_PAG/ALUMNO.NUM_PAG;
                                                    
                                                ELSE
                                                   VL_DESC:=0;
                                                   VL_PL_PAG:=0;
                                                   VL_PARC:=0;                  
                                                END IF;
                                                
                                                IF ALUMNO.PROPEDEUTICO=0 THEN
                                                
                                                   IF EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))=2 
                                                     AND ALUMNO.VIGENCIA=30 THEN
                                                     
                                                    VL_PR_PAGO:= TO_DATE('27'||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)));
                                                    
                                                    BEGIN
                                                       SELECT to_char(TO_DATE('27'||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)),'DD/MM/YYYY') + numtoyminterval(ALUMNO.NUM_PAG-1, 'MONTH'), 'DD/MM/YYYY') 
                                                       INTO VL_FIN_PAGO
                                                       FROM dual;
                                              --         DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                    EXCEPTION WHEN OTHERS THEN 
                                                    
                                                    NULL;
                                                 
                                                    END;  
                                                      
                                                   ELSE
                                      
                                                    VL_PR_PAGO:=TO_DATE(ALUMNO.VIGENCIA||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)));
                                                    
                                                     BEGIN
                                                       SELECT to_char(TO_DATE(ALUMNO.VIGENCIA||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)),'DD/MM/YYYY') + numtoyminterval((ALUMNO.NUM_PAG-1), 'MONTH'), 'DD/MM/YYYY') 
                                                       INTO VL_FIN_PAGO
                                                       FROM dual;
                                                --       DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                    EXCEPTION WHEN OTHERS THEN 
                                                    
                                                    NULL;
                                                 
                                                    END;  
                                                    
                                                                                
                                                    END IF;  
                                                                      
                                                ELSIF ALUMNO.PROPEDEUTICO=1 THEN 
                                                
                                                     IF EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))=2 
                                                     AND ALUMNO.VIGENCIA=30 THEN
                                                     
                                                      VL_PR_PAGO:= TO_DATE('27'||'/'||(EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))+1)||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)));
                                                      
                                                               BEGIN
                                                               SELECT to_char(TO_DATE('27'||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)),'DD/MM/YYYY') + numtoyminterval((ALUMNO.NUM_PAG+1-1), 'MONTH'), 'DD/MM/YYYY') 
                                                               INTO VL_FIN_PAGO
                                                               FROM dual;
                                                  --             DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                               EXCEPTION WHEN OTHERS THEN 
                                                            
                                                                NULL;
                                                         
                                                            END; 
                                                            
                                                     ELSE 
                                                            
                                                             BEGIN
                                                               SELECT to_char(TO_DATE(ALUMNO.VIGENCIA)||'/'||(EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))+1)||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)))
                                                               INTO VL_PR_PAGO
                                                               FROM dual;
                                                    --           DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                               EXCEPTION WHEN OTHERS THEN 
                                                            
                                                                NULL;
                                                         
                                                            END; 
                                                            
                                                             BEGIN
                                                               SELECT to_char(TO_DATE(ALUMNO.VIGENCIA||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)),'DD/MM/YYYY') + numtoyminterval(ALUMNO.NUM_PAG+1-1, 'MONTH'), 'DD/MM/YYYY') 
                                                               INTO VL_FIN_PAGO
                                                               FROM dual;
                                                      --         DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                               EXCEPTION WHEN OTHERS THEN 
                                                            
                                                                NULL;
                                                         
                                                            END; 
                                                                                        
                                                     END IF; 
                                                   
                                                        
                                                END IF;    
                                                   
                                                BEGIN 
                                                      INSERT INTO SZTCART
                                                                                                         VALUES(  
                                                            ALUMNO.CAMPUS,
                                                            ALUMNO.NIVEL,
                                                            ALUMNO.MATRICULA,
                                                            ALUMNO.TIPO_ALUM,
                                                            ALUMNO.STUDY,
                                                            ALUMNO.JORNADA,
                                                            cx.RATE,
                                                            ALUMNO.PROGRAMA,
                                                            ALUMNO.FECHAINICIO,
                                                            VL_PR_PAGO,
                                                            VL_FIN_PAGO,
                                                            VL_COL,
                                                            VL_DESC,
                                                            MONTO_DSI,
                                                            VL_PL_PAG,
                                                            ALUMNO.NUM_PAG,
                                                            VL_PARC,
                                                            COLEG_ANTE,
                                                            DESCU_ANTE,
                                                            DSI_ANTE,
                                                            PLPA_ANTE,
                                                            PARCI_ANTE,
                                                            substr( OBSERVACION,1,30),
                                                            ALUMNO.PRE_ACTUALIZADO,
                                                            ALUMNO.PERIODO,
                                                            PROMOCION,
                                                            FECHA_EFECTIVA_PROMOCION
                                                            );
   
                                                                                        
                                                EXCEPTION WHEN OTHERS THEN
                                                    null;
                                                                            
                            --                         DBMS_OUTPUT.PUT_LINE('Error '||sqlerrm);            
                               
                                                END;
                                              

                                             
                               END LOOP;
                   
        
                              COMMIT;
                
                End loop;
                
                commit;
                      
                RETURN (VL_RETORNA);
                
              END;
              
    procedure CONSULTACART(p_campus in varchar2, p_nivel in varchar2,p_fechainicio DATE, c_out out CURSOR_OUT)
    IS
    --    
      l_retorna varchar2(100);
    BEGIN
        
        BEGIN              
           
              l_retorna:=PKG_SIRCOBRANZA.CARTERASREG(
                                                      p_campus  =>p_campus,
                                                      p_nivel   =>p_nivel,
                                                      p_fechainicio =>p_fechainicio 
                                                      );
        END; 
          
        IF l_retorna= 'EXITO' then
         OPEN C_OUT
         FOR 
           SELECT 
                   sztcart_campus campus,
                   sztcart_nivel nivel, 
                   sztcart_matricula matricula,
                   sztcart_tipo_alum tipo_alum,
                   sztcar_study study, 
                   sztcar_jornada jornada, 
                   sztcart_periodo periodo,
                   sztcart_rate rate, 
                   sztcart_programa programa, 
                   sztcart_fechainicio fecha_inicio, 
                   sztcart_fecha_vigencia_inicial fecha_vigencia_inicial, 
                   sztcart_fecha_vigencia_final fecha_vigencia_final, 
                   ROUND (sztcart_colegiatura,0) colegiatura, 
                   ROUND (sztcart_descuento,0) descuento, 
                   ROUND (sztcart_mon_dsi,0) mon_dsi, 
                   ROUND (sztcart_plan_pagos,0) plan_pagos, 
                   sztcart_num_pag num_pag, 
                   ROUND (sztcart_parcialidad,0) parcialidad, 
                   sztcart_coleg_ante coleg_ante, 
                   sztcart_descu_ante descu_ante, 
                   sztcart_dsi_ante dsi_ante, 
                   sztcart_plpa_ante plpa_ante,
                   sztcart_parci_ante parci_ante, 
                   sztcart_observaciones observaciones,
                   nvl(sztcart_codigo_incre,0)codigo_incremento,
                   SZTCART_PROMOCION PROMOCION,
                   sztcart_FECHA_EFEC_PROM 
           FROM sztcart ;
           
        else    
        
            OPEN C_OUT
            FOR 
                SELECT 
                      'No se encontraron datos'
               FROM dual;   
            
        
        
        END IF;   
        
    END;
    


        
procedure p_cargatztprog_cart is

/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */
 vl_pago number:=0;
 vl_pago_minimo number:=0;
 vl_sp number:=0;

BEGIN


EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.TZTPROG_CART';
COMMIT;



 insert into migra.tztprog_CART
 select distinct b.spriden_pidm pidm,
 b.spriden_id Matricula,
 a.SGBSTDN_STST_CODE Estatus,
 STVSTST_DESC Estatus_D,
 a.SGBSTDN_STYP_CODE,
 f.sorlcur_camp_code Campus,
 f.sorlcur_levl_code Nivel ,
 a.sgbstdn_program_1 programa,
 SMRPRLE_PROGRAM_DESC Nombre,
 f.SORLCUR_KEY_SEQNO sp,
 trunc (SGBSTDN_ACTIVITY_DATE) Fecha_Mov,
 f.SORLCUR_TERM_CODE_CTLG ctlg,
 nvl ( f.SORLCUR_TERM_CODE_MATRIC,SORLCUR_TERM_CODE_ADMIT )  Matriculacion,
 b.SPRIDEN_CREATE_FDMN_CODE,
 f.SORLCUR_START_DATE fecha_inicio
 ,sysdate as fecha_carga,
 f.sorlcur_ADMT_CODE,
 STVADMT_DESC
 from sgbstdn a, spriden b, STVSTYP, stvSTST, smrprle, sorlcur f, stvADMT
 where 1= 1
-- And a.sgbstdn_camp_code = 'UTL'
-- and a.sgbstdn_levl_code = 'LI'
and a.SGBSTDN_STYP_CODE = STVSTYP_CODE
 and a.sgbstdn_pidm = b.spriden_pidm
 and b.spriden_change_ind is null
 and a.SGBSTDN_STST_CODE = STVSTST_CODE
 And a.sgbstdn_program_1 = SMRPRLE_PROGRAM
 and a.SGBSTDN_STST_CODE != 'CP'
 And nvl (f.sorlcur_ADMT_CODE,'RE') = stvADMT_code
 and a.SGBSTDN_TERM_CODE_EFF = ( select max (a1.SGBSTDN_TERM_CODE_EFF)
                                 from sgbstdn a1
                                 where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                 And a.sgbstdn_camp_code = a1.sgbstdn_camp_code
                                 and a.sgbstdn_levl_code = a1.sgbstdn_levl_code
                                 and a.sgbstdn_program_1 = a1.sgbstdn_program_1
                                 )
and f.sorlcur_pidm = a.sgbstdn_pidm
And f.sorlcur_program = a.sgbstdn_program_1
and f.SORLCUR_LMOD_CODE = 'LEARNER'
and f.SORLCUR_SEQNO = (select max (f1.SORLCUR_SEQNO)
                         from sorlcur f1
                         Where f.sorlcur_pidm = f1.sorlcur_pidm
                         and f.sorlcur_camp_code = f1.sorlcur_camp_code
                         and f.sorlcur_levl_code = f1.sorlcur_levl_code
                         and f.SORLCUR_LMOD_CODE = f1.SORLCUR_LMOD_CODE
                         And f.SORLCUR_PROGRAM = f1.SORLCUR_PROGRAM )
--and f.sorlcur_pidm = 460
UNION
select distinct b.spriden_pidm pidm,
b.spriden_id matricula,
nvl (c.ESTATUS, decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' )) Estatus,
stvSTST_desc TIPO_ALUMNO,
a.SORLCUR_STYP_CODE ,
a.sorlcur_camp_code CAMPUS,
a.sorlcur_levl_code NIVEL,
a.sorlcur_program Programa,
SMRPRLE_PROGRAM_DESC Nombre,
a.SORLCUR_KEY_SEQNO sp,
trunc (a.SORLCUR_ACTIVITY_DATE) Fecha_Mov,
a.SORLCUR_TERM_CODE_CTLG ctlg,
nvl (a.SORLCUR_TERM_CODE_MATRIC,SORLCUR_TERM_CODE_ADMIT)  Matriculacion,
b.SPRIDEN_CREATE_FDMN_CODE,
 a.SORLCUR_START_DATE fecha_inicio,
 sysdate as fecha_carga,
a.sorlcur_ADMT_CODE,
STVADMT_DESC
from sorlcur a
join spriden b on b.spriden_pidm = a.sorlcur_pidm and spriden_change_ind is null
left join migra.ESTATUS_REPORTE c on c.SPRIDEN_PIDM =a.sorlcur_pidm and c.PROGRAMAS = a.SORLCUR_PROGRAM
join SMRPRLE on SMRPRLE_PROGRAM = a.SORLCUR_PROGRAM
join stvADMT on stvADMT_code = nvl (a.sorlcur_ADMT_CODE,'RE')
left join stvSTST on stvSTST_code = nvl (c.ESTATUS, decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' ))
where 1= 1
and a.SORLCUR_LMOD_CODE = 'LEARNER'
--and a.SORLCUR_CACT_CODE != 'CHANGE'
--and a.SGBSTDN_STST_CODE != 'CP'
and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
 from sorlcur a1
 Where a.sorlcur_pidm = a1.sorlcur_pidm
 and a.sorlcur_camp_code = a1.sorlcur_camp_code
 and a.sorlcur_levl_code = a1.sorlcur_levl_code
 and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
 And a.SORLCUR_PROGRAM = a1.SORLCUR_PROGRAM )
and (a.sorlcur_camp_code, a.sorlcur_levl_code, a.SORLCUR_PROGRAM) not in (select sgbstdn_camp_code, sgbstdn_levl_code, ax.sgbstdn_program_1
                                                                             from sgbstdn ax
                                                                             Where ax.sgbstdn_pidm = a.sorlcur_pidm) ;

 --and a.sorlcur_pidm = 460;
commit;


-----------------------------------------------------------Se actualiza la fecha de movimientos ---------------------------------------------------------------------------
 ----------------se modifica 17/07/2019 para realizara actualizacion de la fecha de movimiento--------------------------------------
 Begin

 For c in (

 Select distinct pidm, sp, nvl (fecha_inicio, '04/03/2017' ) fecha_inicio, campus||nivel campus, FECHA_MOV
 from tztprog_CART
 where 1= 1
 --CAMPUS||nivel = 'ULTLI'
 --and fecha_mov is null

 ) loop

 If c.fecha_inicio < '04/03/2017' and c.campus != 'UTLLI' then

 Begin
 Update tztprog_cART
 set FECHA_MOV = '04/03/2017'
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 ElsIf c.fecha_inicio >= '04/03/2017' and c.fecha_mov is null then

 Begin
 Update tztprog_CART
 set FECHA_MOV = c.fecha_inicio
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 End if;

 Commit;
 End Loop;
 End;

 Update tztprog_CART
 set FECHA_MOV = '03/04/2017'
 Where FECHA_MOV is null;
 Commit;


 ---- Se actualiza la fecha de la primera inscripcion ----------


 begin


 for c in (
 select *
 from tztprog_CART
 where 1 = 1
 -- and rownum <= 50
 )loop



 Begin


 Update tztprog_CART
 set FECHA_PRIMERA = (
 select min (x.fecha_inicio) --, rownum
 from (
 SELECT DISTINCT
 min (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
 FROM SFRSTCR a, SSBSECT b
 WHERE a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
 AND a.SFRSTCR_CRN = b.SSBSECT_CRN
 AND a.SFRSTCR_RSTS_CODE = 'RE'
 AND b.SSBSECT_PTRM_START_DATE =
 (SELECT min (b1.SSBSECT_PTRM_START_DATE)
 FROM SSBSECT b1
 WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
 AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
 and sfrstcr_pidm = c.pidm
 AND SFRSTCR_STSP_KEY_SEQUENCE = c.sp
 GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
 order by 1,3 asc
 ) x
 )
 Where pidm = c.pidm
 And sp = c.sp;

 exception when others then

 null;
 end;

 end loop;
 Commit;

 end;

---------- Pone el tipoo de estatus desercion para todos las bajas

Begin

    For cx in (

                    select *
                    from tztprog_CART
                    where 1= 1
                    and estatus in ('BT','BD','CM','CV','BI')
                    and SGBSTDN_STYP_CODE !='D'


     ) loop

        Begin
            Update tztprog_CART
            set SGBSTDN_STYP_CODE ='D'
            where pidm = cx.pidm
            And estatus = cx.estatus
            And programa = cx.programa
            And SGBSTDN_STYP_CODE = cx.SGBSTDN_STYP_CODE;
       Exception
        When Others then
            null;
       End;


     End Loop;

     Commit;

End;




end p_cargatztprog_CART;



FUNCTION CARTERASREG_rete(p_campus VARCHAR2,
                     p_nivel VARCHAR2,
                     p_fechainicio DATE ,
                     p_matricula varchar2
                     )
                     RETURN VARCHAR2 
         IS
            VL_RETORNA       VARCHAR2(100):='EXITO';
            VL_COL           NUMBER;
            VL_DESC          NUMBER;
            VL_PL_PAG        NUMBER;
            VL_PARC          NUMBER;
--            VL_ORB           VARCHAR2(30);
            VL_PR_PAGO       DATE;
            VL_FIN_PAGO      DATE;
            VL_ERROR VARCHAR2 (1000);
            VL_CADENAERROR VARCHAR2 (1000);
            VL_ACTUALIZA_TODO   VARCHAR2(900);   
            DESC_COD varchar2(7):= null;
            MONTO_DSI  number:=0;
            COLEG_ANTE number:=0;
            DSI_ANTE   Number:=0;
            DESCU_ANTE Number:=0;
            PLPA_ANTE  Number:=0;
            PARCI_ANTE Number:=0;
            OBSERVACION Varchar2(500):= null;
            PROMOCION number;
            FECHA_EFECTIVA_PROMOCION date:= null;

              BEGIN 
                   
                    PKG_SIRCOBRANZA.p_cargatztprog_cart_rete(p_matricula); commit;
                    VL_ACTUALIZA_TODO := PKG_FINANZAS_REZA.F_ACTUALIZA_RATE_DSI ( p_matricula, p_fechainicio);
                    
                    DELETE SZTCART;
                    
                    COMMIT;
                            
                    For cx in (
                            
                                    Select a.matricula, a.campus, a.nivel, a.fecha_inicio, a.pidm ,
                                       pkg_utilerias.f_calcula_rate(a.pidm, a.programa) Rate                      
                                    from TZTPROG_CART a 
                                    Where 1= 1
                                    And a.estatus = 'MA'
                                    And a.matricula = p_matricula 
                                    And a.fecha_inicio = p_fechainicio
                                    AND a.campus  = nvl(p_campus,a.campus) -------------------------------------PARAMETRO EN
                                    AND a.nivel  =nvl(p_nivel,a.nivel)-------------------------------------PARAMETRO ENTRADA
                                    and a.campus||a.nivel not in ( 'UTSID', 'UTSEC', 'INIEC')
                                    And a.sp = (select max (a1.sp)
                                                    from TZTPROG_CART a1
                                                    Where a.pidm = a1.pidm
                                                    and a1.campus||a1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                                                    And a1.fecha_inicio = a.fecha_inicio
                                                    )        
                                    And a.pidm in (select goradid_pidm
                                                                from GORADID
                                                                Where 1=1
                                                                And GORADID_ADID_CODE ='SBTI' ----> Se excluyen a los alumnos que cuenten con la etiqueta de Retencion 
                                                                )                                                                    
                                    order by 2,1 desc
                     ) loop  
  
                             FOR alumno in (
                             
                             SELECT distinct
                                            A.campus CAMPUS,
                                            A.nivel NIVEL,
                                            A.programa PROGRAMA,
                                            A.pidm PIDM,
                                            a.matricula MATRICULA,
                                            a.SGBSTDN_STYP_CODE TIPO_ALUM,
                                            A.sp STUDY,
                                            A.fecha_inicio  FECHAVIG,
                                            f.SFRSTCR_TERM_CODE PERIODO,
                                            f.SFRSTCR_PTRM_CODE Pperiodo,
                                            g.SSBSECT_PTRM_START_DATE FECHA,
                                            A.fecha_inicio fechainicio,
                                            trim (substr (pkg_utilerias.f_jornada (a.pidm, a.sp),1,5)) Jornada, ----------------------
                                            NVL( DECODE(SUBSTR (cx.rate, 4, 1),'A',15,'B',30),15)VIGENCIA,
                                            NVL(CASE 
                                            SUBSTR (cx.rate, 1, 1)  
                                            WHEN  ('P') THEN SUBSTR (cx.rate, 2, 2)
                                            WHEN  ('C') THEN SUBSTR (cx.rate, 3, 1)-- Se agrega
                                            WHEN  ('J') THEN SUBSTR (cx.rate, 3, 1)
                                            END,0) NUM_PAG,
                                            NVL((select rm.SZTPTRM_PROPEDEUTICO
                                                    from sztptrm rm 
                                                    where 1=1
                                                    AND rm.SZTPTRM_CAMP_CODE=A.campus
                                                    AND RM.SZTPTRM_LEVL_CODE=A.nivel
                                                    AND RM.SZTPTRM_TERM_CODE=A.MATRICULACION
                                                    AND  rm.SZTPTRM_PROGRAM=A.programa
                                                    and rownum=1
                                                    ),0)Propedeutico,                                                                                          
                                     (SELECT DISTINCT cur.SORLCUR_SITE_CODE
                                      FROM SORLCUR CUR
                                      WHERE CUR.SORLCUR_PIDM = a.pidm
                                      AND CUR.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                                      AND CUR.SORLCUR_SEQNO in (SELECT MAX (SORLCUR_SEQNO)
                                                               FROM SORLCUR CUR2
                                                               WHERE CUR2.SORLCUR_PIDM = CUR.SORLCUR_PIDM
                                                               AND CUR2.SORLCUR_LMOD_CODE = CUR.SORLCUR_LMOD_CODE))PRE_ACTUALIZADO
                                    FROM TZTPROG_CART A
                                    join SFRSTCR F on F.SFRSTCR_PIDM = a.pidm 
                                            AND SUBSTR(F.SFRSTCR_TERM_CODE,5,1) NOT IN (8,9)
                                            AND F.SFRSTCR_RSTS_CODE ='RE'
                                            AND F.SFRSTCR_STSP_KEY_SEQUENCE = A.sp
                                            AND (SFRSTCR_RESERVED_KEY != 'M1HB401'OR SFRSTCR_RESERVED_KEY IS NULL )
                                            AND (F.SFRSTCR_DATA_ORIGIN != 'CONVALIDACION' OR F.SFRSTCR_DATA_ORIGIN IS NULL )
                                            AND (F.SFRSTCR_DATA_ORIGIN != 'EXCLUIR' OR SFRSTCR_DATA_ORIGIN IS NULL)
                                         --   and (SFRSTCR_USER_ID != 'MIGRA_D'OR SFRSTCR_USER_ID IS NULL)
                                     join SSBSECT G on G.SSBSECT_TERM_CODE = F.SFRSTCR_TERM_CODE
                                             AND  G.SSBSECT_CRN = F.SFRSTCR_CRN 
                                             And G.SSBSECT_PTRM_CODE =  F.SFRSTCR_PTRM_CODE  
                                            AND TRUNC (G.SSBSECT_PTRM_START_DATE) =  a.fecha_inicio
                                    Where 1= 1
                                    AND a.matricula = cx.matricula
                                    AND A.PIDM= cx.pidm
                                    AND a.campus  = cx.campus
                                    AND a.nivel  = cx.nivel    
                                    And a.fecha_inicio = cx.fecha_inicio   
                                    
                              )
                              LOOP
                              
                             --   DBMS_OUTPUT.PUT_LINE ('Salida mia'||'---'||alumno.pidm);
                              
                                VL_COL           :=NULL;
                                VL_DESC          :=NULL;
                                VL_PL_PAG        :=NULL;
                                VL_PARC          :=NULL;
        --                        VL_ORB           :=NULL;
                                VL_PR_PAGO       :=NULL;
                                VL_FIN_PAGO      :=NULL;
                                VL_ERROR         :=NULL;
                                VL_CADENAERROR   :=NULL;
                                DESC_COD         := null;
                                MONTO_DSI        :=0;
                                COLEG_ANTE       :=0;
                                DSI_ANTE         :=0;
                                PLPA_ANTE        :=0;
                                PROMOCION        :=0;
                                DESCU_ANTE       :=0;
                                PARCI_ANTE       :=0;
                                OBSERVACION      := null;
                                
                                ------------------- Descuento -----------
                                       Begin      
                                            SELECT distinct max (TBBESTU_EXEMPTION_CODE)
                                                Into DESC_COD
                                            FROM TBBEXPT, TBBESTU A, TBBDETC, TBREDET
                                            WHERE TBBDETC_DETAIL_CODE = TBBEXPT_DETAIL_CODE
                                            AND A.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE 
                                            AND A.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE  
                                            AND A.TBBESTU_STUDENT_EXPT_ROLL_IND= 'Y'
                                            AND A.TBBESTU_DEL_IND IS NULL
                                            AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE    
                                            AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE    
                                            AND A.TBBESTU_TERM_CODE in (SELECT MAX(A1.TBBESTU_TERM_CODE)
                                                                         FROM TBBESTU A1,TBBEXPT,TBREDET
                                                                        WHERE A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                                              AND A1.TBBESTU_EXEMPTION_CODE  = TBBEXPT_EXEMPTION_CODE 
                                                                              AND A1.TBBESTU_TERM_CODE = TBBEXPT_TERM_CODE
                                                                              AND TBREDET_EXEMPTION_CODE = TBBEXPT_EXEMPTION_CODE    
                                                                              AND TBREDET_TERM_CODE = TBBEXPT_TERM_CODE     
                                                                              AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
                                                                              AND A1.TBBESTU_DEL_IND IS NULL
                                                                             -- AND A1.TBBESTU_TERM_CODE <= F.SFRSTCR_TERM_CODE
                                                                              )
                                            AND A.TBBESTU_EXEMPTION_PRIORITY in (SELECT MAX(TBBESTU_EXEMPTION_PRIORITY)
                                                                                FROM TBBESTU A1
                                                                                WHERE A1.TBBESTU_PIDM = A.TBBESTU_PIDM
                                                                                AND A1.TBBESTU_STUDENT_EXPT_ROLL_IND = A.TBBESTU_STUDENT_EXPT_ROLL_IND
                                                                                AND A1.TBBESTU_DEL_IND IS NULL
                                                                                AND A1.TBBESTU_TERM_CODE = A.TBBESTU_TERM_CODE)           
                                            AND TBBESTU_PIDM = Alumno.pidm 
                                            AND TBBDETC_DCAT_CODE = 'DSP';                                
                                       Exception
                                        When OThers then 
                                        DESC_COD:= null;
                                       End;
                                    
                                
                                --------------------- Monto MONTO_DSI   -------------------
                                      Begin
                                           SELECT DISTINCT nvl (TZTDMTO_MONTO,0) 
                                            Into MONTO_DSI
                                            FROM TZTDMTO A
                                            WHERE A.TZTDMTO_PIDM   = alumno.pidm
                                            AND  A.TZTDMTO_CAMP_CODE = alumno.campus
                                            AND  A.TZTDMTO_NIVEL  = alumno.nivel
                                            AND A.TZTDMTO_PROGRAMA =  alumno.programa
                                            AND A.TZTDMTO_IND = 1
                                            AND A.TZTDMTO_STUDY_PATH = alumno.STUDY
                                            AND ( A.TZTDMTO_TERM_CODE  = alumno.periodo
                                                 OR A.TZTDMTO_TERM_CODE in (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                           FROM TZTDMTO TZT
                                                                           WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                           AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                           AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                           AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                           AND TZT.TZTDMTO_IND = 1
                                                                           AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                           AND TZT.TZTDMTO_TERM_CODE  <= alumno.periodo))
                                            AND A.TZTDMTO_ACTIVITY_DATE in (SELECT MAX (A1.TZTDMTO_ACTIVITY_DATE)
                                                                            FROM TZTDMTO A1
                                                                            WHERE A1.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                            AND   A1.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                            AND  A1.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                            AND A1.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                            AND A1.TZTDMTO_IND = 1
                                                                            AND A1.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                            AND ( A1.TZTDMTO_TERM_CODE  = alumno.periodo
                                                                                  OR A1.TZTDMTO_TERM_CODE in (SELECT MAX (TZT.TZTDMTO_TERM_CODE)
                                                                                                             FROM TZTDMTO TZT
                                                                                                             WHERE TZT.TZTDMTO_PIDM = A.TZTDMTO_PIDM
                                                                                                             AND   TZT.TZTDMTO_CAMP_CODE = A.TZTDMTO_CAMP_CODE
                                                                                                             AND  TZT.TZTDMTO_NIVEL = A.TZTDMTO_NIVEL
                                                                                                             AND TZT.TZTDMTO_PROGRAMA = A.TZTDMTO_PROGRAMA
                                                                                                             AND TZT.TZTDMTO_IND = 1
                                                                                                             AND TZT.TZTDMTO_STUDY_PATH = A.TZTDMTO_STUDY_PATH
                                                                                                             AND TZT.TZTDMTO_TERM_CODE  <= alumno.periodo))) 
                                             AND A.TZTDMTO_TERM_CODE  <= alumno.periodo
                                             AND ROWNUM = 1;
                                             
                                      Exception
                                        When Others then 
                                           MONTO_DSI:=0;  
                                      End;                         
                                
                                ---------------------------------------Colegiatura Anterior ----------
                                     Begin 
                                
                                           SELECT SUM(nvl (TBRACCD_AMOUNT,0))
                                             Into COLEG_ANTE
                                            FROM TBRACCD CD,TBBDETC
                                            WHERE CD.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            AND CD.TBRACCD_PIDM =alumno.pidm
                                            AND CD.TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                                          FROM TBBDETC
                                                                          WHERE TBBDETC_DCAT_CODE IN ('TUI'))
                                            AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                         FROM TBRACCD A1
                                                                         WHERE A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                         AND A1.TBRACCD_TERM_CODE = CD.TBRACCD_TERM_CODE
                                                                         AND A1.TBRACCD_PIDM = CD.TBRACCD_PIDM)                               
                                            AND CD.TBRACCD_TERM_CODE in (SELECT MAX (A1.TBRACCD_TERM_CODE)
                                                                       FROM TBRACCD A1
                                                                       WHERE A1.TBRACCD_PIDM = CD.TBRACCD_PIDM
                                                                       AND A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                       AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio OR A1.TBRACCD_FEED_DATE is null));                                
                                    Exception
                                        When OThers then 
                                         COLEG_ANTE:=0;
                                    End;
                                
                                      --------------------------------Descuento Anterior --------------
                                
                                    Begin                     
                                            SELECT SUM(nvl (TBRACCD_AMOUNT,0)) 
                                              into DESCU_ANTE    
                                            FROM TBRACCD CD,TBBDETC
                                            WHERE CD.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            AND CD.TBRACCD_PIDM = Alumno.pidm
                                            AND CD.TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                                          FROM TBBDETC
                                                                          WHERE TBBDETC_DCAT_CODE IN ('DSP'))
                                            AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                         FROM TBRACCD A1
                                                                         WHERE A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                         AND A1.TBRACCD_TERM_CODE = CD.TBRACCD_TERM_CODE
                                                                         AND A1.TBRACCD_PIDM = CD.TBRACCD_PIDM)                               
                                            AND CD.TBRACCD_TERM_CODE in (SELECT MAX (A1.TBRACCD_TERM_CODE)
                                                                       FROM TBRACCD A1
                                                                       WHERE A1.TBRACCD_PIDM = CD.TBRACCD_PIDM
                                                                       AND A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                       AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio or A1.TBRACCD_FEED_DATE is null)
                                                                       );
                                    Exception
                                        When Others then 
                                          DESCU_ANTE:=0;                                  
                                    End;
                                
                                
                                ----------------------------------------------DSI_ANTE --------------------------------------
                                
                                    Begin
                                            SELECT SUM(nvl (TBRACCD_AMOUNT,0))
                                                Into DSI_ANTE
                                            FROM TBRACCD CD,TZTNCD
                                            WHERE CD.TBRACCD_DETAIL_CODE = TZTNCD_CODE
                                            And TZTNCD_CONCEPTO = 'Descuento'
                                            And substr (TZTNCD_DESCP, 1,3)= 'DSI'
                                            AND CD.TBRACCD_PIDM = Alumno.pidm
                                            AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                         FROM TBRACCD A1
                                                                         WHERE A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                         AND A1.TBRACCD_TERM_CODE = CD.TBRACCD_TERM_CODE
                                                                         AND A1.TBRACCD_PIDM = CD.TBRACCD_PIDM)                               
                                            AND CD.TBRACCD_TERM_CODE in (SELECT MAX (A1.TBRACCD_TERM_CODE)
                                                                         FROM TBRACCD A1
                                                                         WHERE A1.TBRACCD_PIDM = CD.TBRACCD_PIDM
                                                                         AND A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                         AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio or A1.TBRACCD_FEED_DATE is null));
                                    Exception
                                        When Others then  
                                        DSI_ANTE:=0;                                 
                                    End;
                                
                                
                                 ---------------------------------PLPA_ANTE --------------------------------------
                                 
                                    Begin 
                                        SELECT SUM( (CASE WHEN TBBDETC_DETAIL_CODE = 'PLPA' THEN 
                                                        nvl (TBRACCD_AMOUNT,0)
                                                    END)) AS COLEGIATURA
                                          Into PLPA_ANTE
                                        FROM TBRACCD CD,TBBDETC
                                        WHERE CD.TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                        AND CD.TBRACCD_PIDM = alumno.pidm
                                        AND CD.TBRACCD_DETAIL_CODE IN (SELECT(TBBDETC_DETAIL_CODE)
                                                                      FROM TBBDETC
                                                                      WHERE TBBDETC_DCAT_CODE IN ('LPC'))
                                        AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                     FROM TBRACCD A1
                                                                     WHERE A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                     AND A1.TBRACCD_TERM_CODE = CD.TBRACCD_TERM_CODE
                                                                     AND A1.TBRACCD_PIDM = CD.TBRACCD_PIDM)                               
                                        AND CD.TBRACCD_TERM_CODE in (SELECT MAX (A1.TBRACCD_TERM_CODE)
                                                                      FROM TBRACCD A1
                                                                     WHERE A1.TBRACCD_PIDM = CD.TBRACCD_PIDM
                                                                     AND A1.TBRACCD_DETAIL_CODE = CD.TBRACCD_DETAIL_CODE
                                                                     AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio or A1.TBRACCD_FEED_DATE is null));                                  
                                
                                    Exception
                                        When Others then 
                                        PLPA_ANTE:=0;
                                    End;
                                
                                --------------------------PARCI_ANTE -----------------------------------------------
                                 
                                   Begin 

                                                SELECT SUM (nvl (TBRACCD_AMOUNT,0))
                                                  Into PARCI_ANTE
                                                FROM TBRACCD CD, TZTNCD
                                                WHERE CD.TBRACCD_DETAIL_CODE = TZTNCD_CODE
                                                And TZTNCD_CONCEPTO ='Venta'
                                                AND CD.TBRACCD_PIDM = Alumno.pidm
                                                And CD.TBRACCD_STSP_KEY_SEQUENCE = Alumno.study
                                                AND CD.TBRACCD_TRAN_NUMBER in (SELECT MAX(A1.TBRACCD_TRAN_NUMBER)
                                                                                 FROM TBRACCD A1
                                                                                 WHERE 1= 1
                                                                                 And cd.TBRACCD_PIDM = a1.TBRACCD_PIDM
                                                                                 And cd.TBRACCD_DETAIL_CODE = a1.TBRACCD_DETAIL_CODE
                                                                                 AND cd.TBRACCD_STSP_KEY_SEQUENCE = A1.TBRACCD_STSP_KEY_SEQUENCE
                                                                                  AND (A1.TBRACCD_FEED_DATE != alumno.fechainicio OR A1.TBRACCD_FEED_DATE IS NULL) 
                                                                                 AND A1.TBRACCD_TERM_CODE in (SELECT MAX (A2.TBRACCD_TERM_CODE)
                                                                                                                 FROM TBRACCD A2
                                                                                                                 WHERE a1.TBRACCD_PIDM = a2.TBRACCD_PIDM
                                                                                                                 And a1.TBRACCD_DETAIL_CODE = a2.TBRACCD_DETAIL_CODE
                                                                                                                 AND a1.TBRACCD_STSP_KEY_SEQUENCE = a2.TBRACCD_STSP_KEY_SEQUENCE
                                                                                                                 AND (A2.TBRACCD_FEED_DATE != alumno.fechainicio OR A2.TBRACCD_FEED_DATE IS NULL)
                                                                                                                ));
                                                                                                                                            
                                   Exception
                                    When Others then 
                                    PARCI_ANTE:=0;
                                   End;
                                
                                
                                -----------------------OBSERVACION -------------------------------------------------
                                
                                  Begin 
                                       SELECT DISTINCT TZDOCTR_OBSERVACIONES
                                            Into OBSERVACION
                                       FROM TZDOCTR b
                                       WHERE 1=1
                                       and b.TZDOCTR_PIDM= Alumno.pidm
                                       AND b.TZDOCTR_TERM_CODE = alumno.periodo
                                       AND b.TZDOCTR_PTRM_CODE = alumno.pperiodo
                                       AND TRUNC (b.TZDOCTR_START_DATE) = TRUNC (alumno.fechainicio)
                                       AND b.TZDOCTR_PROGRAM = alumno.programa
                                       AND b.TZDOCTR_IND in (1,0)
                                       AND b.TZDOCTR_TIPO_PROC != 'AUME'
                                       AND b.FECHA_PROCESO in (SELECT MAX(a1.FECHA_PROCESO)
                                                               FROM TZDOCTR A1
                                                               WHERE 1=1 
                                                              AND a1.TZDOCTR_PIDM= b.TZDOCTR_PIDM
                                                              AND a1.TZDOCTR_TERM_CODE = b.TZDOCTR_TERM_CODE 
                                                              AND a1.TZDOCTR_PTRM_CODE = b.TZDOCTR_PTRM_CODE
                                                              AND TRUNC (A1.TZDOCTR_START_DATE) = TRUNC (alumno.fechainicio)
                                                              AND a1.TZDOCTR_PROGRAM =b.TZDOCTR_PROGRAM 
                                                              AND a1.TZDOCTR_IND in (1,0)
                                                              AND a1.TZDOCTR_TIPO_PROC != 'AUME');
                                  Exception
                                    When Others then 
                                     OBSERVACION:=null;
                                  End;
                                
                                
                                ------------------------------------------------------------------------
                                  Begin 
                                        SELECT DISTINCT max (TZFACCE_AMOUNT)
                                            Into PROMOCION
                                           FROM TZFACCE T
                                          WHERE     1=1
                                                AND T.TZFACCE_PIDM = alumno.pidm
                                                AND SUBSTR(T.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                                                AND T.TZFACCE_FLAG = 0
                                                AND LAST_DAY(T.TZFACCE_EFFECTIVE_DATE) = LAST_DAY(TO_DATE(alumno.fechainicio)+12) 
                                                AND T.TZFACCE_STUDY in ( SELECT MAX(TZFACCE_STUDY)
                                                                          FROM TZFACCE
                                                                         WHERE 1=1
                                                                              AND TZFACCE_PIDM = T.TZFACCE_PIDM);
                                  Exception
                                    When Others then 
                                      PROMOCION:= 0;                                          
                                  End;                                 
                                
                                ------------------------------------------------------------------------

                                  Begin
                                        SELECT DISTINCT trunc (TZFACCE_EFFECTIVE_DATE)
                                            Into FECHA_EFECTIVA_PROMOCION
                                           FROM TZFACCE T
                                          WHERE     1=1
                                                AND T.TZFACCE_PIDM = alumno.pidm
                                                AND SUBSTR(T.TZFACCE_DETAIL_CODE,3,2) = 'M3'
                                                AND T.TZFACCE_FLAG = 0
                                                AND LAST_DAY(T.TZFACCE_EFFECTIVE_DATE) = LAST_DAY(TO_DATE(alumno.fechainicio)+12) 
                                                AND T.TZFACCE_STUDY in ( SELECT MAX(TZFACCE_STUDY)
                                                                          FROM TZFACCE
                                                                         WHERE 1=1
                                                                              AND TZFACCE_PIDM = T.TZFACCE_PIDM);                                
                                  Exception
                                    When Others then  
                                    FECHA_EFECTIVA_PROMOCION:= null;
                                  End;
                                
                                ------------------------------------------------------------------------
                                
                                    
                                                 IF ALUMNO.PRE_ACTUALIZADO IS NOT NULL THEN
                                                
                                                                    BEGIN

                                                                        SELECT A.SFRRGFE_MAX_CHARGE 
                                                                        INTO VL_COL
                                                                        FROM SFRRGFE A , TBBDETC 
                                                                        WHERE TBBDETC_DETAIL_CODE = SFRRGFE_DETL_CODE
                                                                        AND A.SFRRGFE_TERM_CODE= ALUMNO.PERIODO
                                                                        AND A.SFRRGFE_TYPE = 'STUDENT'
                                                                        AND A.SFRRGFE_ENTRY_TYPE = 'R'
                                                                        AND A.SFRRGFE_LEVL_CODE = ALUMNO.NIVEL
                                                                        AND A.SFRRGFE_CAMP_CODE = ALUMNO.CAMPUS
                                                                        AND A.SFRRGFE_ATTS_CODE = ALUMNO.JORNADA--ALUMNO.JORNADA
                                                                        AND A.SFRRGFE_RATE_CODE = cx.RATE
                                                                        AND A.SFRRGFE_DEPT_CODE = ALUMNO.PRE_ACTUALIZADO
                                                                        AND A.SFRRGFE_PROGRAM = ALUMNO.PROGRAMA
                                                                        AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                                                                              FROM SFRRGFE A1
                                                                                              WHERE A1.SFRRGFE_TERM_CODE = A.SFRRGFE_TERM_CODE
                                                                                              AND A1.SFRRGFE_TYPE = A.SFRRGFE_TYPE
                                                                                              AND A1.SFRRGFE_ENTRY_TYPE = A.SFRRGFE_ENTRY_TYPE
                                                                                              AND A1.SFRRGFE_LEVL_CODE = A.SFRRGFE_LEVL_CODE
                                                                                              AND A1.SFRRGFE_CAMP_CODE = A.SFRRGFE_CAMP_CODE
                                                                                              AND A1.SFRRGFE_ATTS_CODE = A.SFRRGFE_ATTS_CODE
                                                                                              AND A1.SFRRGFE_RATE_CODE = A.SFRRGFE_RATE_CODE
                                                                                              AND A1.SFRRGFE_DEPT_CODE = A.SFRRGFE_DEPT_CODE
                                                                                              AND A1.SFRRGFE_PROGRAM = ALUMNO.PROGRAMA
                                                                                              );

                                                           EXCEPTION 
                                                           WHEN NO_DATA_FOUND THEN

                                                                    BEGIN

                                                                        SELECT A.SFRRGFE_MAX_CHARGE
                                                                        INTO VL_COL 
                                                                        FROM SFRRGFE A , TBBDETC 
                                                                        WHERE TBBDETC_DETAIL_CODE = SFRRGFE_DETL_CODE
                                                                        AND  A.SFRRGFE_TERM_CODE= ALUMNO.PERIODO
                                                                        AND A.SFRRGFE_TYPE = 'STUDENT'
                                                                        AND SFRRGFE_ENTRY_TYPE = 'R'
                                                                        AND A.SFRRGFE_LEVL_CODE = ALUMNO.NIVEL
                                                                        AND A.SFRRGFE_CAMP_CODE = ALUMNO.CAMPUS
                                                                        AND A.SFRRGFE_ATTS_CODE = ALUMNO.JORNADA--ALUMNO.JORNADA
                                                                        AND A.SFRRGFE_RATE_CODE = cx.RATE
                                                                        AND A.SFRRGFE_DEPT_CODE = ALUMNO.PRE_ACTUALIZADO
                                                                        AND A.SFRRGFE_PROGRAM IS NULL
                                                                        AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                                                                              FROM SFRRGFE A1
                                                                                              WHERE A1.SFRRGFE_TERM_CODE = A.SFRRGFE_TERM_CODE
                                                                                              AND A1.SFRRGFE_TYPE = A.SFRRGFE_TYPE
                                                                                              AND A1.SFRRGFE_ENTRY_TYPE = A.SFRRGFE_ENTRY_TYPE
                                                                                              AND A1.SFRRGFE_LEVL_CODE = A.SFRRGFE_LEVL_CODE
                                                                                              AND A1.SFRRGFE_CAMP_CODE = A.SFRRGFE_CAMP_CODE
                                                                                              AND A1.SFRRGFE_ATTS_CODE = A.SFRRGFE_ATTS_CODE
                                                                                              AND A1.SFRRGFE_RATE_CODE = A.SFRRGFE_RATE_CODE
                                                                                              AND A1.SFRRGFE_DEPT_CODE = A.SFRRGFE_DEPT_CODE
                                                                                              AND A1.SFRRGFE_PROGRAM IS NULL);

                                                            EXCEPTION 
                                                            WHEN OTHERS THEN 
                                                              VL_ERROR :='Validar Regla de Cobro, Parametros = '||ALUMNO.PERIODO||'  -  '||NVL(ALUMNO.JORNADA,'SIN JORNADA')||'  -  '||cx.RATE; 
                                                              VL_CADENAERROR:=VL_CADENAERROR||'|'||VL_ERROR;
                                                              VL_COL := NULL;
                                                            END;
                                        
                                                         END;
                                        
                                           
                                                ELSIF ALUMNO.PRE_ACTUALIZADO IS  NULL THEN        
                                                
                                                
                                                        BEGIN      
                                                                                                                                         
                                                            SELECT A.SFRRGFE_MAX_CHARGE
                                                            INTO VL_COL
                                                            FROM SFRRGFE A , TBBDETC 
                                                            WHERE TBBDETC_DETAIL_CODE = SFRRGFE_DETL_CODE
                                                            AND  A.SFRRGFE_TERM_CODE = ALUMNO.PERIODO
                                                            AND A.SFRRGFE_TYPE = 'STUDENT'
                                                            AND SFRRGFE_ENTRY_TYPE = 'R'
                                                            AND A.SFRRGFE_LEVL_CODE = ALUMNO.NIVEL
                                                            AND A.SFRRGFE_CAMP_CODE = ALUMNO.CAMPUS
                                                            AND A.SFRRGFE_ATTS_CODE = ALUMNO.JORNADA
                                                            AND A.SFRRGFE_RATE_CODE = cx.RATE
                                                            AND A.SFRRGFE_PROGRAM = ALUMNO.PROGRAMA
                                                            AND A.SFRRGFE_DEPT_CODE IS NULL
                                                            AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                                                                  FROM SFRRGFE A1
                                                                                  WHERE A1.SFRRGFE_TERM_CODE = A.SFRRGFE_TERM_CODE
                                                                                  AND A1.SFRRGFE_TYPE = A.SFRRGFE_TYPE
                                                                                  AND A1.SFRRGFE_ENTRY_TYPE = A.SFRRGFE_ENTRY_TYPE
                                                                                  AND A1.SFRRGFE_LEVL_CODE = A.SFRRGFE_LEVL_CODE
                                                                                  AND A1.SFRRGFE_CAMP_CODE = A.SFRRGFE_CAMP_CODE
                                                                                  AND A1.SFRRGFE_ATTS_CODE = A.SFRRGFE_ATTS_CODE
                                                                                  AND A1.SFRRGFE_RATE_CODE = A.SFRRGFE_RATE_CODE
                                                                                  AND A1.SFRRGFE_DEPT_CODE IS NULL
                                                                                  AND A1.SFRRGFE_PROGRAM = ALUMNO.PROGRAMA
                                                                                  );
                                                 EXCEPTION
                                                 WHEN OTHERS THEN 

                                                                BEGIN      
                                                                                                                                                 
                                                                    SELECT A.SFRRGFE_MAX_CHARGE
                                                                    INTO VL_COL
                                                                    FROM SFRRGFE A , TBBDETC 
                                                                    WHERE TBBDETC_DETAIL_CODE = SFRRGFE_DETL_CODE
                                                                    AND  A.SFRRGFE_TERM_CODE= ALUMNO.PERIODO
                                                                    AND A.SFRRGFE_TYPE = 'STUDENT'
                                                                    AND SFRRGFE_ENTRY_TYPE = 'R'
                                                                    AND A.SFRRGFE_LEVL_CODE = ALUMNO.NIVEL
                                                                    AND A.SFRRGFE_CAMP_CODE = ALUMNO.CAMPUS
                                                                    AND A.SFRRGFE_ATTS_CODE = ALUMNO.JORNADA--ALUMNO.JORNADA
                                                                    AND A.SFRRGFE_RATE_CODE = cx.RATE
                                                                    AND A.SFRRGFE_DEPT_CODE IS NULL
                                                                    AND A.SFRRGFE_PROGRAM IS NULL
                                                                    AND A.SFRRGFE_SEQNO = (SELECT MAX(A1.SFRRGFE_SEQNO)
                                                                                          FROM SFRRGFE A1
                                                                                          WHERE A1.SFRRGFE_TERM_CODE = A.SFRRGFE_TERM_CODE
                                                                                          AND A1.SFRRGFE_TYPE = A.SFRRGFE_TYPE
                                                                                          AND A1.SFRRGFE_ENTRY_TYPE = A.SFRRGFE_ENTRY_TYPE
                                                                                          AND A1.SFRRGFE_LEVL_CODE = A.SFRRGFE_LEVL_CODE
                                                                                          AND A1.SFRRGFE_CAMP_CODE = A.SFRRGFE_CAMP_CODE
                                                                                          AND A1.SFRRGFE_ATTS_CODE = A.SFRRGFE_ATTS_CODE
                                                                                          AND A1.SFRRGFE_RATE_CODE = A.SFRRGFE_RATE_CODE
                                                                                          AND A1.SFRRGFE_DEPT_CODE IS NULL
                                                                                          AND A1.SFRRGFE_PROGRAM IS NULL);
                                                  EXCEPTION
                                                  WHEN OTHERS THEN 
                                                  VL_ERROR :='Validar Regla de Cobro, Parametros = '||ALUMNO.PERIODO||'  -  '||NVL(ALUMNO.JORNADA,'SIN JORNADA')||'  -  '||cx.RATE; 
                                                  VL_CADENAERROR:=VL_CADENAERROR||'|'||VL_ERROR;
                                                  VL_COL:= NULL; 
                                                  END;
                                                                                            
                                          --        DBMS_OUTPUT.PUT_LINE ('reza valida 1'||'---'||VL_ERROR);
                                                                                            
                                                 END;
                                              
                                                
                                                END IF; 
                                     
                                            --      DBMS_OUTPUT.PUT_LINE(VL_COL||'  COLEGIATURA');
                                                  
                                                IF VL_COL<>0 THEN
                                                
                                              
                                                  -- Se agregó la condición porque el código de descuento es de 7 dígitos 
                                                    IF LENGTH(DESC_COD) = 6 THEN
                                                        VL_DESC:=(VL_COL*substr (DESC_COD,4,3))/100;
                                                    END IF;
                                                    
                                                    IF LENGTH(DESC_COD) = 7 THEN
                                                        VL_DESC:=(VL_COL*substr (DESC_COD,5,3))/100;
                                                    END IF;
                                                   
                                                   VL_PL_PAG:=VL_COL-VL_DESC-MONTO_DSI;
                                                   VL_PARC:=VL_PL_PAG/ALUMNO.NUM_PAG;
                                                    
                                                ELSE
                                                   VL_DESC:=0;
                                                   VL_PL_PAG:=0;
                                                   VL_PARC:=0;                  
                                                END IF;
                                                
                                                IF ALUMNO.PROPEDEUTICO=0 THEN
                                                
                                                   IF EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))=2 
                                                     AND ALUMNO.VIGENCIA=30 THEN
                                                     
                                                    VL_PR_PAGO:= TO_DATE('27'||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)));
                                                    
                                                    BEGIN
                                                       SELECT to_char(TO_DATE('27'||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)),'DD/MM/YYYY') + numtoyminterval(ALUMNO.NUM_PAG-1, 'MONTH'), 'DD/MM/YYYY') 
                                                       INTO VL_FIN_PAGO
                                                       FROM dual;
                                              --         DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                    EXCEPTION WHEN OTHERS THEN 
                                                    
                                                    NULL;
                                                 
                                                    END;  
                                                      
                                                   ELSE
                                      
                                                    VL_PR_PAGO:=TO_DATE(ALUMNO.VIGENCIA||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)));
                                                    
                                                     BEGIN
                                                       SELECT to_char(TO_DATE(ALUMNO.VIGENCIA||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)),'DD/MM/YYYY') + numtoyminterval((ALUMNO.NUM_PAG-1), 'MONTH'), 'DD/MM/YYYY') 
                                                       INTO VL_FIN_PAGO
                                                       FROM dual;
                                                --       DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                    EXCEPTION WHEN OTHERS THEN 
                                                    
                                                    NULL;
                                                 
                                                    END;  
                                                    
                                                                                
                                                    END IF;  
                                                                      
                                                ELSIF ALUMNO.PROPEDEUTICO=1 THEN 
                                                
                                                     IF EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))=2 
                                                     AND ALUMNO.VIGENCIA=30 THEN
                                                     
                                                      VL_PR_PAGO:= TO_DATE('27'||'/'||(EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))+1)||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)));
                                                      
                                                               BEGIN
                                                               SELECT to_char(TO_DATE('27'||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)),'DD/MM/YYYY') + numtoyminterval((ALUMNO.NUM_PAG+1-1), 'MONTH'), 'DD/MM/YYYY') 
                                                               INTO VL_FIN_PAGO
                                                               FROM dual;
                                                  --             DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                               EXCEPTION WHEN OTHERS THEN 
                                                            
                                                                NULL;
                                                         
                                                            END; 
                                                            
                                                     ELSE 
                                                            
                                                             BEGIN
                                                               SELECT to_char(TO_DATE(ALUMNO.VIGENCIA)||'/'||(EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))+1)||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)))
                                                               INTO VL_PR_PAGO
                                                               FROM dual;
                                                    --           DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                               EXCEPTION WHEN OTHERS THEN 
                                                            
                                                                NULL;
                                                         
                                                            END; 
                                                            
                                                             BEGIN
                                                               SELECT to_char(TO_DATE(ALUMNO.VIGENCIA||'/'||EXTRACT(MONTH FROM (ALUMNO.FECHAVIG))||'/'||EXTRACT(YEAR FROM (ALUMNO.FECHAVIG)),'DD/MM/YYYY') + numtoyminterval(ALUMNO.NUM_PAG+1-1, 'MONTH'), 'DD/MM/YYYY') 
                                                               INTO VL_FIN_PAGO
                                                               FROM dual;
                                                      --         DBMS_OUTPUT.PUT_LINE(VL_FIN_PAGO||'  COLEGIATURA');
                                                               EXCEPTION WHEN OTHERS THEN 
                                                            
                                                                NULL;
                                                         
                                                            END; 
                                                                                        
                                                     END IF; 
                                                   
                                                        
                                                END IF;    
                                                   
                                                BEGIN 
                                                      INSERT INTO SZTCART
                                                                                                         VALUES(  
                                                            ALUMNO.CAMPUS,
                                                            ALUMNO.NIVEL,
                                                            ALUMNO.MATRICULA,
                                                            ALUMNO.TIPO_ALUM,
                                                            ALUMNO.STUDY,
                                                            ALUMNO.JORNADA,
                                                            cx.RATE,
                                                            ALUMNO.PROGRAMA,
                                                            ALUMNO.FECHAINICIO,
                                                            VL_PR_PAGO,
                                                            VL_FIN_PAGO,
                                                            VL_COL,
                                                            VL_DESC,
                                                            MONTO_DSI,
                                                            VL_PL_PAG,
                                                            ALUMNO.NUM_PAG,
                                                            VL_PARC,
                                                            COLEG_ANTE,
                                                            DESCU_ANTE,
                                                            DSI_ANTE,
                                                            PLPA_ANTE,
                                                            PARCI_ANTE,
                                                            substr( OBSERVACION,1,30),
                                                            ALUMNO.PRE_ACTUALIZADO,
                                                            ALUMNO.PERIODO,
                                                            PROMOCION,
                                                            FECHA_EFECTIVA_PROMOCION
                                                            );
   
                                                                                        
                                                EXCEPTION WHEN OTHERS THEN
                                                    null;
                                                                            
                            --                         DBMS_OUTPUT.PUT_LINE('Error '||sqlerrm);            
                               
                                                END;
                                              

                                             
                               END LOOP;
                   
        
                              COMMIT;
                
                End loop;
                
                commit;
                      
                RETURN (VL_RETORNA);
                
  END CARTERASREG_rete;
                 
procedure p_cargatztprog_cart_rete(p_matricula varchar2) is

/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */
 vl_pago number:=0;
 vl_pago_minimo number:=0;
 vl_sp number:=0;

BEGIN


EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.TZTPROG_CART';
COMMIT;



 insert into migra.tztprog_CART
 select distinct b.spriden_pidm pidm,
 b.spriden_id Matricula,
 a.SGBSTDN_STST_CODE Estatus,
 STVSTST_DESC Estatus_D,
 a.SGBSTDN_STYP_CODE,
 f.sorlcur_camp_code Campus,
 f.sorlcur_levl_code Nivel ,
 a.sgbstdn_program_1 programa,
 SMRPRLE_PROGRAM_DESC Nombre,
 f.SORLCUR_KEY_SEQNO sp,
 trunc (SGBSTDN_ACTIVITY_DATE) Fecha_Mov,
 f.SORLCUR_TERM_CODE_CTLG ctlg,
 nvl ( f.SORLCUR_TERM_CODE_MATRIC,SORLCUR_TERM_CODE_ADMIT )  Matriculacion,
 b.SPRIDEN_CREATE_FDMN_CODE,
 f.SORLCUR_START_DATE fecha_inicio
 ,sysdate as fecha_carga,
 f.sorlcur_ADMT_CODE,
 STVADMT_DESC
 from sgbstdn a, spriden b, STVSTYP, stvSTST, smrprle, sorlcur f, stvADMT
 where 1= 1
-- And a.sgbstdn_camp_code = 'UTL'
-- and a.sgbstdn_levl_code = 'LI'
and a.SGBSTDN_STYP_CODE = STVSTYP_CODE
 and a.sgbstdn_pidm = b.spriden_pidm
 and b.spriden_change_ind is null
 and a.SGBSTDN_STST_CODE = STVSTST_CODE
 And a.sgbstdn_program_1 = SMRPRLE_PROGRAM
 and a.SGBSTDN_STST_CODE != 'CP'
 And nvl (f.sorlcur_ADMT_CODE,'RE') = stvADMT_code
 and a.SGBSTDN_TERM_CODE_EFF = ( select max (a1.SGBSTDN_TERM_CODE_EFF)
                                 from sgbstdn a1
                                 where a.sgbstdn_pidm = a1.sgbstdn_pidm
                                 And a.sgbstdn_camp_code = a1.sgbstdn_camp_code
                                 and a.sgbstdn_levl_code = a1.sgbstdn_levl_code
                                 and a.sgbstdn_program_1 = a1.sgbstdn_program_1
                                 )
and f.sorlcur_pidm = a.sgbstdn_pidm
And f.sorlcur_program = a.sgbstdn_program_1
and f.SORLCUR_LMOD_CODE = 'LEARNER'
and f.SORLCUR_SEQNO = (select max (f1.SORLCUR_SEQNO)
                         from sorlcur f1
                         Where f.sorlcur_pidm = f1.sorlcur_pidm
                         and f.sorlcur_camp_code = f1.sorlcur_camp_code
                         and f.sorlcur_levl_code = f1.sorlcur_levl_code
                         and f.SORLCUR_LMOD_CODE = f1.SORLCUR_LMOD_CODE
                         And f.SORLCUR_PROGRAM = f1.SORLCUR_PROGRAM )
And b.spriden_id = p_matricula                         
--and f.sorlcur_pidm = 460
UNION
select distinct b.spriden_pidm pidm,
b.spriden_id matricula,
nvl (c.ESTATUS, decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' )) Estatus,
stvSTST_desc TIPO_ALUMNO,
a.SORLCUR_STYP_CODE ,
a.sorlcur_camp_code CAMPUS,
a.sorlcur_levl_code NIVEL,
a.sorlcur_program Programa,
SMRPRLE_PROGRAM_DESC Nombre,
a.SORLCUR_KEY_SEQNO sp,
trunc (a.SORLCUR_ACTIVITY_DATE) Fecha_Mov,
a.SORLCUR_TERM_CODE_CTLG ctlg,
nvl (a.SORLCUR_TERM_CODE_MATRIC,SORLCUR_TERM_CODE_ADMIT)  Matriculacion,
b.SPRIDEN_CREATE_FDMN_CODE,
 a.SORLCUR_START_DATE fecha_inicio,
 sysdate as fecha_carga,
a.sorlcur_ADMT_CODE,
STVADMT_DESC
from sorlcur a
join spriden b on b.spriden_pidm = a.sorlcur_pidm and spriden_change_ind is null
left join migra.ESTATUS_REPORTE c on c.SPRIDEN_PIDM =a.sorlcur_pidm and c.PROGRAMAS = a.SORLCUR_PROGRAM
join SMRPRLE on SMRPRLE_PROGRAM = a.SORLCUR_PROGRAM
join stvADMT on stvADMT_code = nvl (a.sorlcur_ADMT_CODE,'RE')
left join stvSTST on stvSTST_code = nvl (c.ESTATUS, decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' ))
where 1= 1
and a.SORLCUR_LMOD_CODE = 'LEARNER'
--and a.SORLCUR_CACT_CODE != 'CHANGE'
--and a.SGBSTDN_STST_CODE != 'CP'
and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
 from sorlcur a1
 Where a.sorlcur_pidm = a1.sorlcur_pidm
 and a.sorlcur_camp_code = a1.sorlcur_camp_code
 and a.sorlcur_levl_code = a1.sorlcur_levl_code
 and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
 And a.SORLCUR_PROGRAM = a1.SORLCUR_PROGRAM )
and (a.sorlcur_camp_code, a.sorlcur_levl_code, a.SORLCUR_PROGRAM) not in (select sgbstdn_camp_code, sgbstdn_levl_code, ax.sgbstdn_program_1
                                                                             from sgbstdn ax
                                                                             Where ax.sgbstdn_pidm = a.sorlcur_pidm)
And b.spriden_id = p_matricula   ;

 --and a.sorlcur_pidm = 460;
commit;


-----------------------------------------------------------Se actualiza la fecha de movimientos ---------------------------------------------------------------------------
 ----------------se modifica 17/07/2019 para realizara actualizacion de la fecha de movimiento--------------------------------------
 Begin

 For c in (

 Select distinct pidm, sp, nvl (fecha_inicio, '04/03/2017' ) fecha_inicio, campus||nivel campus, FECHA_MOV
 from tztprog_CART
 where 1= 1
 --CAMPUS||nivel = 'ULTLI'
 --and fecha_mov is null

 ) loop

 If c.fecha_inicio < '04/03/2017' and c.campus != 'UTLLI' then

 Begin
 Update tztprog_cART
 set FECHA_MOV = '04/03/2017'
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 ElsIf c.fecha_inicio >= '04/03/2017' and c.fecha_mov is null then

 Begin
 Update tztprog_CART
 set FECHA_MOV = c.fecha_inicio
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 End if;

 Commit;
 End Loop;
 End;

 Update tztprog_CART
 set FECHA_MOV = '03/04/2017'
 Where FECHA_MOV is null;
 Commit;


 ---- Se actualiza la fecha de la primera inscripcion ----------


 begin


 for c in (
 select *
 from tztprog_CART
 where 1 = 1
 -- and rownum <= 50
 )loop



 Begin


 Update tztprog_CART
 set FECHA_PRIMERA = (
 select min (x.fecha_inicio) --, rownum
 from (
 SELECT DISTINCT
 min (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
 FROM SFRSTCR a, SSBSECT b
 WHERE a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
 AND a.SFRSTCR_CRN = b.SSBSECT_CRN
 AND a.SFRSTCR_RSTS_CODE = 'RE'
 AND b.SSBSECT_PTRM_START_DATE =
 (SELECT min (b1.SSBSECT_PTRM_START_DATE)
 FROM SSBSECT b1
 WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
 AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
 and sfrstcr_pidm = c.pidm
 AND SFRSTCR_STSP_KEY_SEQUENCE = c.sp
 GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
 order by 1,3 asc
 ) x
 )
 Where pidm = c.pidm
 And sp = c.sp;

 exception when others then

 null;
 end;

 end loop;
 Commit;

 end;

---------- Pone el tipoo de estatus desercion para todos las bajas

Begin

    For cx in (

                    select *
                    from tztprog_CART
                    where 1= 1
                    and estatus in ('BT','BD','CM','CV','BI')
                    and SGBSTDN_STYP_CODE !='D'


     ) loop

        Begin
            Update tztprog_CART
            set SGBSTDN_STYP_CODE ='D'
            where pidm = cx.pidm
            And estatus = cx.estatus
            And programa = cx.programa
            And SGBSTDN_STYP_CODE = cx.SGBSTDN_STYP_CODE;
       Exception
        When Others then
            null;
       End;


     End Loop;

     Commit;

End;




end p_cargatztprog_CART_RETE;   
  
              
END;
/

DROP PUBLIC SYNONYM PKG_SIRCOBRANZA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SIRCOBRANZA FOR BANINST1.PKG_SIRCOBRANZA;
