DROP PACKAGE BODY BANINST1.PKG_SERVICIO_SOCIAL;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SERVICIO_SOCIAL AS
/******************************************************************************
   NAME:       PKG_SERVICIO_SOCIAL
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        23/01/2020      fgalleme       1. Created this package.
******************************************************************************/

   FUNCTION f_empresa_ss (p_primera_letra VARCHAR2) RETURN PKG_SERVICIO_SOCIAL.cursor_out_empresa_ss  --FER V1.23/01/2020
           AS
                c_out_empresa_ss PKG_SERVICIO_SOCIAL.cursor_out_empresa_ss;

  BEGIN 
       open c_out_empresa_ss            
         FOR SELECT 
             stvempl_code COD_EMPL,
             stvempl_desc STVEMPL_DESC
             FROM stvempl
             WHERE 1=1
             AND stvempl_desc LIKE '%'||p_primera_letra||'%';


       RETURN (c_out_empresa_ss);
       
       
  END;
  
--
--

   FUNCTION f_dato_grls (p_pidm in number) RETURN PKG_SERVICIO_SOCIAL.cursor_out_dato_grls  --FER V1.24/01/2020
           AS
                c_out_dato_grls PKG_SERVICIO_SOCIAL.cursor_out_dato_grls;

  BEGIN 
       open c_out_dato_grls            
         FOR 
                SELECT DISTINCT
                    pidm PIDM,
                    spriden_id ID,
                    spriden_first_name||' '||replace(spriden_last_name,'/',' ') NOMBRE_ALUMNO,
                    (SELECT goremal_email_address 
                    FROM goremal 
                    WHERE 
                    1=1
                    AND a.pidm = goremal_pidm 
                    AND goremal_emal_code = 'PRIN'
                    AND GOREMAL_PREFERRED_IND = 'Y') CORREO,
                    a.estatus ESTATUS,
                    INITCAP (a.estatus_d) DESCRIP,
                    a.programa, 
                    (SELECT sztdtec_programa_comp  
                    FROM sztdtec 
                    WHERE 1=1 
                    AND sztdtec_program = a.programa
                    AND sztdtec_term_code = a.ctlg 
                    AND sztdtec_camp_code = a.campus
                    ) DESCRIP_PROGRA,
                    sgrcoop_empl_contact_title COD_SS,
                    (SELECT zstpara_param_desc 
                     FROM zstpara
                     WHERE 1=1
                     AND zstpara_mapa_id = 'TIPO_SS'
                     AND zstpara_param_valor = (SELECT sgrcoop_empl_contact_title 
                                                                FROM sgrcoop
                                                                WHERE 1=1
                                                                AND zstpara_param_valor = sgrcoop_empl_contact_title
                                                                AND sgrcoop_pidm =  a.pidm)) DESC_SS,
                    sgrcoop_term_code PERIODO_SS
                FROM tztprog_all A,sgrcoop, spriden
                WHERE 1=1
                AND a.pidm = sgrcoop_pidm (+)
                AND a.nivel = sgrcoop_levl_code (+)
                AND spriden_pidm = sgrcoop_pidm (+)
                AND a.pidm = spriden_pidm
                AND a.matricula = spriden_id
                AND spriden_change_ind IS NULL
                AND a.pidm = p_pidm -- fget_pidm ('010017225')
                AND a.nivel = 'LI'
                AND sgrcoop_copc_code(+)  != 'EQ'
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg);   
                         
       RETURN (c_out_dato_grls);

  END;  
  
--
--

 FUNCTION  f_periodos (p_sysdate date, p_camp varchar2 ) --FER V2.28/09/2022

   RETURN VARCHAR2
   AS

    l_periodo VARCHAR2 (6);    
    l_error  VARCHAR2(2000) := 'EXITO';
   
BEGIN 

    BEGIN
     
     SELECT DISTINCT stvterm_code
     INTO l_periodo
     FROM stvterm
     WHERE 1=1
     AND substr (stvterm_code, 5,1) = 9
     AND stvterm_code != '999996'
     AND SUBSTR (STVTERM_CODE,1,2) = p_camp
     AND (TO_DATE (TRUNC (p_sysdate)) BETWEEN TO_DATE (TRUNC (stvterm_start_date)) AND TO_DATE (TRUNC (stvterm_end_date))
     AND stvterm_start_date IS NOT NULL
     AND stvterm_end_date IS NOT NULL)
     OR (stvterm_start_date IS NULL
     AND stvterm_end_date IS NULL)
     OR TO_DATE (TRUNC (p_sysdate)) <= TRUNC (stvterm_end_date)
     AND stvterm_start_date IS NULL
     AND stvterm_end_date IS NOT NULL;
     
--     DBMS_OUTPUT.PUT_LINE('PERIODO : '||l_periodo);

    EXCEPTION 
    WHEN OTHERS THEN
    
    l_periodo:=('ERROR: NO HAY PERIODODS CONFIGURADOS EN STVTERM '||sqlerrm);
--    DBMS_OUTPUT.PUT_LINE('ERROR: NO HAY PERIODODS CONFIGURADOS EN STVTERM ');
    
    END;

    RETURN(l_periodo);

END f_periodos;


--
--
   FUNCTION f_parte_p (l_periodo VARCHAR2) RETURN PKG_SERVICIO_SOCIAL.cursor_out_parte_p  --FER V1.23/01/2020
           AS
                c_out_parte_p PKG_SERVICIO_SOCIAL.cursor_out_parte_p;

  BEGIN 
       open c_out_parte_p            
         FOR SELECT 
                 sobptrm_term_code TERM,
                 sobptrm_ptrm_code PARTE,
                 sobptrm_start_date INICIO,
                 sobptrm_end_date FIN
             FROM sobptrm
             WHERE 1=1
             AND sobptrm_term_code = l_periodo
--             AND sobptrm_term_code = '012090'
             AND sobptrm_ptrm_code != '1'
             ORDER BY PARTE ASC;
             
         RETURN (c_out_parte_p);
      
  END;

--
--
FUNCTION f_tipo_ss (p_mapa_id VARCHAR2) RETURN PKG_SERVICIO_SOCIAL.cursor_out_tipo_ss --FER 31/01/2020
           AS
                c_out_tipo_ss PKG_SERVICIO_SOCIAL.cursor_out_tipo_ss;


BEGIN 
      OPEN c_out_tipo_ss
        FOR SELECT 
                zstpara_param_valor COD_TIPO_SS, 
                zstpara_param_desc DESCRIPCION
            FROM zstpara
            WHERE 1=1
            AND zstpara_mapa_id = p_mapa_id;

RETURN (c_out_tipo_ss);

END;

--
--  
FUNCTION f_inserta_ss (p_pidm NUMBER, p_periodo VARCHAR2,  p_nom_empresa VARCHAR2, p_tiposerv VARCHAR2, p_usuario VARCHAR2) RETURN VARCHAR2 -- Fer V1 27/01/2020

      IS 

l_contar NUMBER;
l_max_sgrcoop_surrogate_id NUMBER;
l_error VARCHAR2 (1000) := 'EXITO';


BEGIN 
  
   BEGIN
        
    SELECT DISTINCT COUNT (*)
    INTO l_contar
    FROM sgrcoop
    WHERE 1=1
    --AND sgrcoop_pidm = FGET_PIDM ('010017225')
    and SGRCOOP_COPC_CODE = 'SS'
    AND sgrcoop_pidm = p_pidm;

  --  DBMS_OUTPUT.PUT_LINE('CONTAR : '||l_contar);
  
   END;
   
   
   BEGIN
   
       SELECT (sgrcoop_surrogate_id_sequence.NEXTVAL)
       INTO l_max_sgrcoop_surrogate_id
       FROM dual
       WHERE 1=1;
   
        --DBMS_OUTPUT.PUT_LINE('CONTAR : '||l_max_sgrcoop_surrogate_id);
   
   END;


      IF l_contar = 0 THEN
      
         BEGIN 
           
          INSERT INTO sgrcoop --(SGRCOOP_PIDM,SGRCOOP_TERM_CODE,SGRCOOP_LEVL_CODE,SGRCOOP_EMPL_CODE,SGRCOOP_COPC_CODE,SGRCOOP_END_DATE,SGRCOOP_BEGIN_DATE,SGRCOOP_INTEREST_IND,SGRCOOP_EMPL_CONTACT_NAME,SGRCOOP_EMPL_CONTACT_TITLE,SGRCOOP_ACTIVITY_DATE,SGRCOOP_PHONE_AREA,SGRCOOP_PHONE_NUMBER,SGRCOOP_PHONE_EXT,SGRCOOP_SEQ_NO,SGRCOOP_CRN,SGRCOOP_EVAL_PREPARED_DATE,SGRCOOP_EVAL_RECEIVED_DATE,SGRCOOP_OVERRIDE_IND,SGRCOOP_CTRY_CODE_PHONE,SGRCOOP_SURROGATE_ID,SGRCOOP_VERSION,SGRCOOP_USER_ID,SGRCOOP_DATA_ORIGIN,SGRCOOP_VPDI_CODE)
          VALUES 
          (p_pidm, 
          p_periodo,
          'LI',
          p_nom_empresa,
          'SS', 
          SYSDATE + 180,
          SYSDATE,
          NULL,
          NULL,
          p_tiposerv,
          SYSDATE,
          NULL,
          NULL,
          NULL,
          '1',
          NULL,
          NULL,
          NULL,
          NULL,
          NULL,
          l_max_sgrcoop_surrogate_id,
          NULL,
          'SIU_INSERT',
          p_usuario,
          NULL);

          
         Exception 
         When Others then
         l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP ' ||sqlerrm;
          
         --DBMS_OUTPUT.PUT_LINE('ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP '||l_error);
            
                  
         END;
               
      ELSIF l_contar > 0 THEN 
      
       l_error:='ALUMNO CUENTA CON REGISTRO DE SERVICIO SOCIAL EN SZFCOOP ';   
      
      END IF;

COMMIT;
      
RETURN (l_error);   

END;

--
--
FUNCTION   p_fechas_ss (P_PERIODO VARCHAR2, P_PARTE VARCHAR2) Return varchar2 -- Fer V1 27/01/2020 

IS
    L_INICIO DATE; 
    L_FIN DATE;
--    L_ERROR VARCHAR (1000) := 'EXITO';

BEGIN 

    SELECT 
        sobptrm_start_date L_INICIO,
        sobptrm_end_date L_FIN
    INTO 
        L_INICIO, 
        L_FIN
    FROM sobptrm
    WHERE 1=1
    AND sobptrm_term_code = '012090'
    AND sobptrm_ptrm_code = 'SS1'
    --AND sobptrm_term_code = '012090'
    AND sobptrm_ptrm_code != '1';

--    DBMS_OUTPUT.PUT_LINE ('INICIO ' || L_INICIO);
--    DBMS_OUTPUT.PUT_LINE ('FIN ' || L_FIN);

RETURN ('INICIO ' || L_INICIO);
RETURN ('FIN ' || L_FIN);

END;

--
--
FUNCTION f_inserta_mat_ss (p_pidm NUMBER, p_periodo VARCHAR2,  p_parte_p VARCHAR2,p_usuario VARCHAR2) RETURN VARCHAR2 -- Fer V1 31/01/2020

      IS 
      
l_contar_sect NUMBER;
l_contar_meet NUMBER;
l_contar_tcr NUMBER;
l_conta_ptrm NUMBER;
l_error VARCHAR2 (1000):='EXITO';
l_inicio DATE;
l_fin DATE;
l_nombre_mat VARCHAR2 (1000);
l_creditos NUMBER;
l_cobro NUMBER;
l_subj VARCHAR2 (1000) := 'SESO';
l_crse VARCHAR2 (1000) := '1001';
l_crn VARCHAR2 (1000);
l_numcrn NUMBER;
l_calificar NUMBER;
l_nivel VARCHAR2 (1000);
l_campus VARCHAR2 (1000);
l_studypath NUMBER;
l_grupo VARCHAR2 (20) := NULL;


    BEGIN 

        BEGIN 

            SELECT COUNT (*)
            INTO  l_contar_sect
            FROM ssbsect
            WHERE 1=1
            AND ssbsect_term_code = p_periodo
            AND ssbsect_ptrm_code = p_parte_p
            AND ssbsect_subj_code || ssbsect_crse_numb = l_subj||l_crse;
            
           -- DBMS_OUTPUT.PUT_LINE('CONTAR SSBSECT : '||l_contar_sect);

        END;

              BEGIN 

                    SELECT 
                        scbcrse_credit_hr_low L_CREDITOS,
                        scbcrse_bill_hr_low L_COBRO 
                    INTO l_creditos,l_cobro
                    FROM scbcrse
                    WHERE 1=1
                    AND scbcrse_subj_code||scbcrse_crse_numb = l_subj||l_crse;

--                    DBMS_OUTPUT.PUT_LINE ('CREDITOS: ' || l_creditos);
--                    DBMS_OUTPUT.PUT_LINE ('COBRO: ' || l_cobro);

                    EXCEPTION 
                    WHEN OTHERS THEN
                    l_creditos := ('ERROR AL BUSCAR LA MATERIA, FAVOR DE REVISAR EL CATALOGO SCACRSE '||sqlerrm);
                  --  DBMS_OUTPUT.PUT_LINE('ERROR AL BUSCAR LA MATERIA, FAVOR DE REVISAR EL CATALOGO SCACRSE ');

                END;
                
                BEGIN 

                    SELECT 
                        sobptrm_start_date L_INICIO,
                        sobptrm_end_date L_FIN
                    INTO 
                        l_inicio, 
                        l_fin
                    FROM sobptrm
                    WHERE 1=1
                    AND sobptrm_term_code = p_periodo
                    AND sobptrm_ptrm_code = p_parte_p
                    AND sobptrm_ptrm_code != '1';

--                    DBMS_OUTPUT.PUT_LINE ('INICIO ' || L_INICIO);
--                    DBMS_OUTPUT.PUT_LINE ('FIN ' || L_FIN);

                    EXCEPTION 
                    WHEN OTHERS THEN
                    l_error := ('ERROR AL BUSCAR EL PERIODO, FAVOR DE REVISAR STVTERM Y SOATERM '||sqlerrm);
                  --  DBMS_OUTPUT.PUT_LINE('ERROR AL BUSCAR EL PERIODO, FAVOR DE REVISAR STVTERM Y SOATERM ');

                END;            
            
         
            IF l_contar_sect = 0 THEN
                
                BEGIN 
                
                    SELECT 
                        scbcrse_title L_NOMBRE_MAT
                    INTO l_nombre_mat
                    FROM scbcrse
                    WHERE 1=1
                    AND scbcrse_subj_code||scbcrse_crse_numb = l_subj||l_crse;

                  --  DBMS_OUTPUT.PUT_LINE ('NOMBRE MATERIA : ' || l_nombre_mat);

                    EXCEPTION 
                    WHEN OTHERS THEN
                    l_nombre_mat := ('ERROR AL BUSCAR LA MATERIA, FAVOR DE REVISAR EL CATALOGO SCACRSE '||sqlerrm);
                  --  DBMS_OUTPUT.PUT_LINE('ERROR AL BUSCAR LA MATERIA, FAVOR DE REVISAR EL CATALOGO SCACRSE ');

                END;  


                BEGIN 

                SELECT 'L'||sztcrnv_crn
                INTO l_crn
                FROM sztcrnv 
                WHERE 1 = 1
                AND ROWNUM = 1
                AND sztcrnv_crn NOT IN (SELECT TO_NUMBER(l_crn)
                                        FROM (SELECT CASE WHEN SUBSTR(ssbsect_crn,1,1) IN('L','M','A','S') THEN TO_NUMBER(SUBSTR(ssbsect_crn,2,10))
                                              ELSE
                                              TO_NUMBER(ssbsect_crn)                
                                              END l_crn,
                                              ssbsect_crn
                                              FROM ssbsect 
                                              WHERE 1 = 1
                                              AND ssbsect_term_code= p_periodo)
                                        WHERE 1 = 1)
                ORDER BY 1;

             --   DBMS_OUTPUT.PUT_LINE ('CRN: ' ||l_crn);

                EXCEPTION 
                WHEN OTHERS THEN
                    l_crn := ('ERROR AL CALCULAR EL CRN '||sqlerrm);
                  --  DBMS_OUTPUT.PUT_LINE('ERROR AL CALCULAR EL CRN ');

                END;
                
                
                 BEGIN --SSBSECT_GMOD_CODE
                   
                  INSERT INTO ssbsect 
                  VALUES 
                  (p_periodo, --SSBSECT_TERM_CODE
                  l_CRN,  --SSBSECT_CRN
                  p_parte_p, --SSBSECT_PTRM_CODE
                  l_subj, --SSBSECT_SUBJ_CODE
                  l_crse, --SSBSECT_CRSE_NUMB
                  '01', --SSBSECT_SEQ_NUMB
                  'A', --SSBSECT_SSTS_CODE
                  'SS', --SSBSECT_SCHD_CODE
                  'UTL',  --SSBSECT_CAMP_CODE
                  l_nombre_mat,  --SSBSECT_CRSE_TITLE
                  l_creditos, --SSBSECT_CREDIT_HRS
                  l_cobro, --SSBSECT_BILL_HRS
                  3,  --SSBSECT_GMOD_CODE
                  NULL, --SSBSECT_SAPR_CODE
                  NULL,  --SSBSECT_SESS_CODE
                  NULL,  --SSBSECT_LINK_IDENT
                  NULL,  --SSBSECT_PRNT_IND
                  'Y',  --SSBSECT_GRADABLE_IND
                  NULL,  -- SSBSECT_TUIW_IND
                  0,  --SSBSECT_REG_ONEUP
                  0, --SSBSECT_PRIOR_ENRL
                  0,  --SSBSECT_PROJ_ENRL
                  50,  --SSBSECT_MAX_ENRL
                  0,  --SSBSECT_ENRL
                  50,  --SSBSECT_SEATS_AVAIL
                  NULL,  --SSBSECT_TOT_CREDIT_HRS
                  '0',  --SSBSECT_CENSUS_ENRL
                  TO_DATE(l_inicio),  --SSBSECT_CENSUS_ENRL_DATE
                  SYSDATE,  --SSBSECT_ACTIVITY_DATE
                  TO_DATE(l_inicio),  --SSBSECT_PTRM_START_DATE
                  TO_DATE(l_fin), --SSBSECT_PTRM_END_DATE
                  '52',  --SSBSECT_PTRM_WEEKS
                  NULL,  --SSBSECT_RESERVED_IND
                  NULL, --SSBSECT_WAIT_CAPACITY
                  NULL,  --SSBSECT_WAIT_COUNT
                  NULL,  --SSBSECT_WAIT_AVAIL
                  NULL,  --SSBSECT_LEC_HR
                  NULL,  --SSBSECT_LAB_HR
                  NULL,  --SSBSECT_OTH_HR
                  NULL,  --SSBSECT_CONT_HR
                  NULL,  --SSBSECT_ACCT_CODE
                  NULL,  --SSBSECT_ACCL_CODE
                  NULL,  --SSBSECT_CENSUS_2_DATE
                  NULL,  --SSBSECT_ENRL_CUT_OFF_DATE
                  NULL,  --SSBSECT_ACAD_CUT_OFF_DATE
                  NULL,  --SSBSECT_DROP_CUT_OFF_DATE
                  NULL,  --SSBSECT_CENSUS_2_ENRL
                  'Y',  --SSBSECT_VOICE_AVAIL
                  'N',  --SSBSECT_CAPP_PREREQ_TEST_IND
                  NULL,  --SSBSECT_GSCH_NAME
                  NULL,  --SSBSECT_BEST_OF_COMP
                  NULL,  --SSBSECT_SUBSET_OF_COMP
                  'NOP',  --SSBSECT_INSM_CODE
                  NULL,  --SSBSECT_REG_FROM_DATE
                  NULL,  --SSBSECT_REG_TO_DATE
                  NULL,  --SSBSECT_LEARNER_REGSTART_FDATE
                  NULL,  --SSBSECT_LEARNER_REGSTART_TDATE
                  NULL,  --SSBSECT_DUNT_CODE
                  NULL,  --SSBSECT_NUMBER_OF_UNITS                
                  '0',  --SSBSECT_NUMBER_OF_EXTENSIONS
                  'SS_CARGA',  --SSBSECT_DATA_ORIGIN
                  p_usuario,  --SSBSECT_USER_ID
                  'MOOD',  --SSBSECT_INTG_CDE
                  'B',  --SSBSECT_PREREQ_CHK_METHOD_CDE
                  p_usuario, --SSBSECT_KEYWORD_INDEX_ID
                  NULL,    --SSBSECT_SCORE_OPEN_DATE
                  NULL,  --SSBSECT_SCORE_CUTOFF_DATE
                  NULL,  --SSBSECT_REAS_SCORE_OPEN_DATE
                  NULL,  --SSBSECT_REAS_SCORE_CTOF_DATE
                  NULL,  --SSBSECT_SURROGATE_ID
                  NULL,  --SSBSECT_VERSION 
                  NULL);  --SSBSECT_VPDI_CODE);

                 COMMIT;
                  
                 EXCEPTION 
                 WHEN OTHERS THEN
                 l_error := 'ERROR: SE PRESENTO UN ERROR AL INSERTAR EL NUEVO GRUPO ' ||sqlerrm;
                  
                -- DBMS_OUTPUT.PUT_LINE('ERROR: SE PRESENTO UN ERROR AL INSERTAR EL NUEVO GRUPO '||l_error);
          
                 END;
            
            ELSIF  l_contar_sect > 0 THEN
            
                BEGIN 
                
                    SELECT ssbsect_crn AS l_crn
                    INTO  l_crn
                    FROM ssbsect
                    WHERE 1=1
                    AND ssbsect_term_code = p_periodo
                    AND ssbsect_ptrm_code = p_parte_p
                    AND ssbsect_subj_code || ssbsect_crse_numb = l_subj||l_crse; 
                
                   -- DBMS_OUTPUT.PUT_LINE('CRN EXISTENTE: '|| l_crn);
                
                EXCEPTION 
                WHEN OTHERS THEN
                l_crn := ('ERROR AL BUSCAR EL CRN, FAVOR DE REVISAR SSBSECT '||sqlerrm);
              --  DBMS_OUTPUT.PUT_LINE('ERROR AL BUSCAR EL CRN, FAVOR DE REVISAR SSBSECT  ');         
                
                END;     
                 
               
            END IF;

      --  DBMS_OUTPUT.PUT_LINE('CRN HORARIO GENERADO: '|| l_error);


            BEGIN 
                   
            SELECT COUNT(*)
            INTO l_contar_meet
            FROM  ssrmeet
            WHERE 1=1
            AND ssrmeet_term_code = p_periodo
            AND ssrmeet_crn = l_crn;
            
               -- DBMS_OUTPUT.PUT_LINE('CONTAR SSRMEET: '||l_contar_meet);
             
            END; --SSRMEET_START_DATE

                IF l_contar_meet = 0 THEN
                
                    BEGIN 
                            
                    INSERT INTO ssrmeet
                    VALUES
                    (p_periodo,-- SSRMEET_TERM_CODE
                     l_crn,--SSRMEET_CRN
                     NULL,--SSRMEET_DAYS_CODE
                     NULL,--SSRMEET_DAY_NUMBER
                     NULL,--SSRMEET_BEGIN_TIME
                     NULL,--SSRMEET_END_TIME
                     NULL,--SSRMEET_BLDG_CODE
                     NULL,--SSRMEET_ROOM_CODE
                     SYSDATE,--SSRMEET_ACTIVITY_DATE
                     TO_DATE(l_inicio),
                     TO_DATE(l_fin),
                     '01',--SSRMEET_CATAGORY
                     NULL,--SSRMEET_SUN_DAY
                     NULL,--SSRMEET_MON_DAY
                     NULL,--SSRMEET_TUE_DAY
                     NULL,--SSRMEET_WED_DAY
                     NULL,--SSRMEET_THU_DAY
                     NULL,--SSRMEET_FRI_DAY
                     NULL,--SSRMEET_SAT_DAY
                     'ENL',--SSRMEET_SCHD_CODE
                     NULL,--SSRMEET_OVER_RIDE
                     l_creditos,--SSRMEET_CREDIT_HR_SESS
                     NULL,--SSRMEET_MEET_NO
                     0,--SSRMEET_HRS_WEEK  SSBSECT
                     NULL,--SSRMEET_FUNC_CODE
                     NULL,--SSRMEET_COMT_CODE
                     NULL,--SSRMEET_SCHS_CODE
                     'CLVI',--SSRMEET_MTYP_CODE
                     'SS_CARGA',--SSRMEET_DATA_ORIGIN
                     p_usuario,--user,--SSRMEET_USER_ID
                     NULL,--SSRMEET_SURROGATE_ID
                     0,--SSRMEET_VERSION
                     NULL);--SSRMEET_VPDI_CODE
                    
                    COMMIT;
                    
                    EXCEPTION 
                    WHEN OTHERS THEN
                    
                        l_error := 'ERROR: SE PRESENTO UN ERROR AL INSERTAR EN SSRMEET ' ||sqlerrm;
                      
                       -- DBMS_OUTPUT.PUT_LINE('ERROR: SE PRESENTO UN ERROR AL INSERTAR EN SSRMEET '||l_error);
                     
                    END;
                
                END IF;

       -- DBMS_OUTPUT.PUT_LINE('INSERTAR EN SSRMEET: ' || l_error);

               
        BEGIN

        SELECT COUNT(*) 
        INTO l_conta_ptrm
        FROM sfbetrm
        WHERE 1=1
        AND sfbetrm_term_code = p_periodo
        AND sfbetrm_pidm= p_pidm;

           -- DBMS_OUTPUT.PUT_LINE('CONTAR SFBETRM: ' ||l_conta_ptrm);

        END;

            IF l_conta_ptrm =0 THEN
                
                BEGIN
                
                INSERT INTO sfbetrm 
                VALUES
                (p_periodo, 
                p_pidm, 
                'EL', 
                SYSDATE, 
                99.99, 
                'Y', 
                NULL, 
                SYSDATE, 
                SYSDATE,
                NULL,
                NULL,
                NULL,
                NULL,
                'SS_CARGA', 
                null,
                'SS_CARGA', 
                NULL, 
                0,
                NULL,
                NULL, 
                NULL,
                NULL,
                p_usuario, --user
                NULL);
                
                EXCEPTION
                WHEN OTHERS THEN 
                    l_error  := ('SE PRESENTO UN ERROR AL INSERTAR EN LA TABLA SFBETRM ' || sqlerrm);   
                   -- DBMS_OUTPUT.PUT_LINE('SE PRESENTO UN ERROR AL INSERTAR EN LA TABLA SFBETRM  '||l_error);
                    
                COMMIT;
                    
                END;
                
            END IF;



         BEGIN 

            BEGIN 
                   
            SELECT COUNT(*) l_contar_tcr
            INTO l_contar_tcr
            FROM  sfrstcr
            WHERE 1=1
            AND sfrstcr_pidm = p_pidm
            AND sfrstcr_term_code = p_periodo
            AND sfrstcr_ptrm_code = p_parte_p
--            AND sfrstcr_grde_code NOT IN ('NP', 'NA')
            ;
            
             --   DBMS_OUTPUT.PUT_LINE('CONTAR SFRSTCR : '||l_contar_tcr);
             
            END; 
            
                IF l_contar_tcr = 0 THEN 

                    BEGIN 
                    
                        SELECT DISTINCT
                            sorlcur_levl_code l_nivel,
                            sorlcur_camp_code l_campus
                        INTO l_nivel, l_campus
                        FROM sorlcur c
                        WHERE 1=1
                        AND c.sorlcur_pidm = p_pidm
                        AND c.sorlcur_lmod_code = 'LEARNER'
                        AND c.sorlcur_seqno = (SELECT DISTINCT MAX (c1.sorlcur_seqno)
                                               FROM sorlcur c1
                                               WHERE 1=1
                                               AND c.sorlcur_pidm= c1.sorlcur_pidm
                                               AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code);
                    
                      --  dbms_output.put_line ('NIVEL DEL ALUMNO: ' || l_nivel);
                    
                    EXCEPTION WHEN OTHERS THEN
                      --  dbms_output.put_line ('ERROR AL BUSCAR SU REGISTRO ESTUDIANTIL '||sqlerrm);
                        l_error:='ERROR AL BUSCAR SU REGISTRO ESTUDIANTIL '||sqlerrm;                        
                    
                    END; 
                    
                    BEGIN 
    
                        SELECT sorlcur_key_seqno
                        INTO l_studypath
                        FROM sorlcur c
                        WHERE 1=1 
                        AND c.sorlcur_pidm = p_pidm
                        AND c.sorlcur_lmod_code  = 'LEARNER'
                        AND c.sorlcur_seqno = (SELECT DISTINCT MAX (c1.sorlcur_seqno)
                                                    FROM sorlcur c1
                                                    WHERE 1=1
                                                    AND c.sorlcur_pidm= c1.sorlcur_pidm
                                                    AND c.sorlcur_lmod_code = c1.sorlcur_lmod_code);    
                    
                            --    DBMS_OUTPUT.PUT_LINE ('STUDYPATH: ' || l_studypath);

                   EXCEPTION 
                   WHEN OTHERS THEN
                   l_studypath := ('ERROR AL BUSCAR STUDYPATH, FAVOR DE REVISAR EL CATALOGO SORLCUR_KEY_SEQNO '||sqlerrm);
                 --  DBMS_OUTPUT.PUT_LINE('ERROR AL BUSCAR STUDYPATH, FAVOR DE REVISAR EL CATALOGO SORLCUR_KEY_SEQNO ');
                    
                    END;

                    BEGIN 
                    
                    INSERT INTO sfrstcr
                    VALUES 
                    (p_periodo,        --SFRSTCR_TERM_CODE
                     p_pidm,           --SFRSTCR_PIDM
                     l_crn,       --SFRSTCR_CRN
                     '1',              --SFRSTCR_CLASS_SORT_KEY
                     '01',             --SFRSTCR_REG_SEQ
                     p_parte_p,        --SFRSTCR_PTRM_CODE
                     'RE',             --SFRSTCR_RSTS_CODE
                     SYSDATE,          --SFRSTCR_RSTS_DATE
                     NULL,             --SFRSTCR_ERROR_FLAG
                     NULL,             --SFRSTCR_MESSAGE
                     l_cobro,          --SFRSTCR_BILL_HR
                     '3',              --SFRSTCR_WAIV_HR
                     l_creditos,       --SFRSTCR_CREDIT_HR
                     l_cobro,          --SFRSTCR_BILL_HR_HOLD
                     l_creditos,       --SFRSTCR_CREDIT_HR_HOLD
                     l_calificar,      --SFRSTCR_GMOD_CODE
                     NULL,             --SFRSTCR_GRDE_CODE
                     NULL,             --SFRSTCR_GRDE_CODE_MID
                     NULL,             --SFRSTCR_GRDE_DATE
                     'N',              --SFRSTCR_DUPL_OVER
                     'N',              --SFRSTCR_LINK_OVER
                     'N',              --SFRSTCR_CORQ_OVER
                     'N',              --SFRSTCR_PREQ_OVER
                     'N',              --SFRSTCR_TIME_OVER
                     'N',              --SFRSTCR_CAPC_OVER
                     'N',              --SFRSTCR_LEVL_OVER
                     'N',              --SFRSTCR_COLL_OVER
                     'N',              --SFRSTCR_MAJR_OVER
                     'N',              --SFRSTCR_CLAS_OVER
                     'N',              --SFRSTCR_APPR_OVER
                     'N',              --SFRSTCR_APPR_RECEIVED_IND
                     SYSDATE,          --SFRSTCR_ADD_DATE
                     SYSDATE,          --SFRSTCR_ACTIVITY_DATE
                     l_nivel,          --SFRSTCR_LEVL_CODE
                     l_campus,         --SFRSTCR_CAMP_CODE
                     l_subj||l_crse,   --SFRSTCR_RESERVED_KEY
                     NULL,             --SFRSTCR_ATTEND_HR
                     'Y',              --SFRSTCR_REPT_OVER
                     'N',              --SFRSTCR_RPTH_OVER
                     NULL,             --SFRSTCR_TEST_OVER
                     'N',              --SFRSTCR_CAMP_OVER
                     p_usuario, --user--SFRSTCR_USER
                     'N',              --SFRSTCR_DEGC_OVER
                     'N',              --SFRSTCR_PROG_OVER
                     NULL,             --SFRSTCR_LAST_ATTEND
                     NULL,             --SFRSTCR_GCMT_CODE
                     'SS_CARGA',       --SFRSTCR_DATA_ORIGIN
                     SYSDATE,           --SFRSTCR_ASSESS_ACTIVITY_DATE
                     'N',              --SFRSTCR_DEPT_OVER
                     'N',              --SFRSTCR_ATTS_OVER
                     'N',              --SFRSTCR_CHRT_OVER
                     '01',             --SFRSTCR_RMSG_CDE
                     NULL,             --SFRSTCR_WL_PRIORITY
                     NULL,             --SFRSTCR_WL_PRIORITY_ORIG
                     NULL,             --SFRSTCR_GRDE_CODE_INCMP_FINAL
                     NULL,             --SFRSTCR_INCOMPLETE_EXT_DATE
                     'N',              --SFRSTCR_MEXC_OVER
                     l_studypath,      --SFRSTCR_STSP_KEY_SEQUENCE
                     NULL,             --SFRSTCR_BRDH_SEQ_NUM
                     '01',             --SFRSTCR_BLCK_CODE
                     NULL,             --SFRSTCR_STRH_SEQNO
                     NULL,             --SFRSTCR_STRD_SEQNO
                     NULL,             --SFRSTCR_SURROGATE_ID
                     NULL,             --SFRSTCR_VERSION
                     p_usuario, --user, --SFRSTCR_USER_ID
                     NULL);            --SFRSTCR_VPDI_CODE
                    
                    EXCEPTION 
                    WHEN OTHERS THEN
                        l_error := 'ERROR: SE PRESENTO UN ERROR AL INSERTAR EL NUEVO GRUPO ' ||sqlerrm;
                  
                      --  DBMS_OUTPUT.PUT_LINE('ERROR: SE PRESENTO UN ERROR AL INSERTAR EL NUEVO GRUPO '||l_error);
                    
                    COMMIT;
                    
                    END;
                    
                ELSIF l_contar_tcr > 0 THEN 
              
                    l_error:=('ALUMNO CUENTA CON HORARIO GENERADO, FAVOR DE REVISAR SFARHST '); 
                
                END IF;
         
      --   DBMS_OUTPUT.PUT_LINE('SE INSERTA HORARIO AL ALUMNO EN SFRSTCR : ' || l_error);
         
         
                IF l_error = 'EXITO' THEN 
                
                    BEGIN 
                    
                        SELECT sfrstcr_crn L_GRUPO
                        INTO l_grupo
                        FROM sfrstcr
                        WHERE 1=1
                        AND sfrstcr_pidm = p_pidm
                        AND sfrstcr_term_code = p_periodo
                        AND sfrstcr_ptrm_code = p_parte_p;
                        
                       --     DBMS_OUTPUT.PUT_LINE (l_grupo);
                    
                    EXCEPTION WHEN OTHERS THEN
                      --  dbms_output.put_line ('ERROR AL OBTENER NÚMERO DE GRUPO EN SFRSTCR '||sqlerrm);
                        l_error:='ERROR AL OBTENER NÚMERO DE GRUPO EN SFRSTCR '||sqlerrm;
                    
                    END; 
                    
                    
                    BEGIN 
                    
                        UPDATE sgrcoop
                        SET sgrcoop_crn = l_grupo
                        WHERE 1=1
                        AND sgrcoop_pidm = p_pidm
                        AND sgrcoop_term_code = p_periodo;
                        
                    EXCEPTION WHEN OTHERS THEN
                      --  dbms_output.put_line ('ERROR AL ACTUALIZAR GRUPO EN LA FORMA SZFCOOP '||sqlerrm);
                        l_error:='ERROR AL ACTUALIZAR GRUPO EN LA FORMA SZFCOOP '||sqlerrm;     
                    
                    END;
                    
                END IF;
         END;

    COMMIT;
    
    RETURN (l_error);
    
    END;

--
--
FUNCTION   f_act_calif (p_pidm NUMBER, p_user VARCHAR2) Return varchar2 -- V2 fer 05/10/2022

  IS
  
  BEGIN 

    FOR C IN (

                           select 
                                a.sfrstcr_term_code PERIODO,
                                a.sfrstcr_pidm PIDM,
                                a.sfrstcr_crn CRN,
                                a.sfrstcr_ptrm_code PTRM,
                                a.sfrstcr_rsts_code ESTATUS
                            from sfrstcr A, ssbsect
                            where 1=1
                            AND a.sfrstcr_term_code = ssbsect_term_code
                            AND a.sfrstcr_crn = ssbsect_crn
                            AND a.sfrstcr_ptrm_code = ssbsect_ptrm_code
                            AND substr(sfrstcr_term_code,-2)='90'
            --                AND SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = 'SESO1001'
                            AND a.sfrstcr_grde_code is NULL
                            AND a.sfrstcr_rsts_code='RE'
                            AND a.sfrstcr_pidm = P_PIDM --FGET_PIDM ('240219788')

--               select 
--                    a.sfrstcr_term_code PERIODO,
--                    a.sfrstcr_pidm PIDM,
--                    a.sfrstcr_crn CRN,
--                    a.sfrstcr_ptrm_code PTRM,
--                    a.sfrstcr_rsts_code ESTATUS
--                from sfrstcr A, sorlcur B, ssbsect
--                where 1=1
--                AND b.sorlcur_pidm = sfrstcr_pidm
--                AND a.sfrstcr_term_code = ssbsect_term_code
--                AND a.sfrstcr_crn = ssbsect_crn
--                AND a.sfrstcr_ptrm_code = ssbsect_ptrm_code
--                AND b.sorlcur_camp_code= ssbsect_camp_code
--                AND b.sorlcur_lmod_code = 'LEARNER'
--                AND substr(sfrstcr_term_code,-2)='90'
--                AND a.sfrstcr_grde_code is NULL
--                AND a.sfrstcr_rsts_code='RE'
--                AND sorlcur_pidm = (SELECT spriden_pidm
--                                          FROM spriden
--                                          WHERE 1=1
--                                            AND spriden_pidm = sorlcur_pidm
--                                            AND spriden_change_ind IS NULL
--                                            AND spriden_pidm = P_PIDM)
--                and b.sorlcur_seqno IN (SELECT MAX (a1.sorlcur_seqno)
--                                            FROM sorlcur a1
--                                            WHERE b.sorlcur_pidm = a1.sorlcur_pidm
--                                              AND b.sorlcur_lmod_code = a1.sorlcur_lmod_code)
                                              
              )
              
              
              LOOP
              
                BEGIN 
                  UPDATE sfrstcr
                  SET sfrstcr_grde_code = 'AC',
                      sfrstcr_activity_date=sysdate,
                      sfrstcr_user=p_user,
                      sfrstcr_user_id=p_user
                  WHERE 1=1
                  AND sfrstcr_pidm = C.PIDM
                  AND sfrstcr_term_code = C.PERIODO
                  AND sfrstcr_crn = C.CRN;

                EXCEPTION
                    WHEN OTHERS THEN
                     return ('Fallo Actualizar Califcacion ');  
                END;
                
              END LOOP;
  
      COMMIT;

    RETURN ('EXITO');            
                
  END;
   
  
FUNCTION   f_act_status(p_pidm NUMBER, p_user VARCHAR2, p_fecha date) Return varchar2

  IS
  
  BEGIN 

    FOR C IN (
                select 
                    SHRNCRS_PIDM PIDM,
                    SHRNCRS_SEQ_NO SEQNO,
                    SHRNCRS_NCRQ_CODE NCRQ
                from SHRNCRS, SGRCOOP
                where 1=1
                AND SHRNCRS_pidm = SGRCOOP_pidm
                AND SHRNCRS_PIDM = (SELECT spriden_pidm
                                          FROM spriden
                                          WHERE 1=1
                                            AND spriden_pidm = SHRNCRS_PIDM
                                            AND spriden_change_ind IS NULL
                                            AND spriden_pidm = P_PIDM)
                AND SHRNCRS_NCST_CODE is null
                AND SHRNCRS_NCRQ_CODE = 'SS'
              )
              
              
              LOOP
              
                BEGIN 
                  UPDATE SHRNCRS
                  SET SHRNCRS_NCST_CODE = 'AP',
                      SHRNCRS_NCST_DATE=p_fecha,
                      SHRNCRS_USER_ID=p_user
                  WHERE 1=1
                  AND SHRNCRS_PIDM = C.PIDM
                  AND SHRNCRS_SEQ_NO = C.SEQNO
                  AND SHRNCRS_NCRQ_CODE = C.NCRQ;
                  COMMIT;
                  return ('EXITO');
                EXCEPTION
                    WHEN OTHERS THEN
                     return ('Fallo Actualiza Estatus ');  
                END;
               
              END LOOP;
              
           
  END;

--
--

   FUNCTION f_estatus_glo (p_pidm Number) RETURN PKG_SERVICIO_SOCIAL.cursor_out_estatus_glo  --FER V1.08/06/2022
           AS
                c_out_estatus_glo PKG_SERVICIO_SOCIAL.cursor_out_estatus_glo;

  BEGIN 
       open c_out_estatus_glo            
         FOR SELECT a.ESTATUS
                FROM tztprog A
                WHERE 1=1
                AND a.PIDM = p_pidm--fget_pidm ('010017225')
                AND a.SP = (SELECT MAX (a1.SP)
                                FROM tztprog a1
                                WHERE 1=1
                                and a.PIDM = a1.PIDM);
                


       RETURN (c_out_estatus_glo);
       
       
  END;
  
--
--  

  FUNCTION f_dato_grls_lib  (p_pidm in number) RETURN PKG_SERVICIO_SOCIAL.cursor_out_dato_grls_lib  --FER V1.28/09/2022
           AS
                c_out_dato_grls_lib PKG_SERVICIO_SOCIAL.cursor_out_dato_grls_lib;

  BEGIN 
       open c_out_dato_grls_lib            
         FOR 
                   SELECT DISTINCT
                    pidm PIDM,
                    spriden_id ID,
                    spriden_first_name||' '||replace(spriden_last_name,'/',' ') NOMBRE_ALUMNO,
                    (SELECT goremal_email_address 
                    FROM goremal 
                    WHERE 
                    1=1
                    AND a.pidm = goremal_pidm 
                    AND goremal_emal_code = 'PRIN'
                    AND GOREMAL_PREFERRED_IND = 'Y') CORREO,
                    a.estatus ESTATUS,
                    INITCAP (a.estatus_d) DESCRIP,
--                    a.campus, 
                    a.programa, 
                    (SELECT sztdtec_programa_comp  
                    FROM sztdtec 
                    WHERE 1=1 
                    AND sztdtec_program = a.programa 
                    AND  sztdtec_term_code = a.ctlg 
                    and sztdtec_camp_code = a.campus) DESCRIP_PROGRA,
                    sgrcoop_empl_contact_title COD_SS,
                    (SELECT zstpara_param_desc 
                     FROM zstpara
                     WHERE 1=1
                     AND zstpara_mapa_id = 'TIPO_SS'
                     AND zstpara_param_valor = (SELECT sgrcoop_empl_contact_title 
                                                                FROM sgrcoop
                                                                WHERE 1=1
                                                                AND zstpara_param_valor = sgrcoop_empl_contact_title
                                                                AND sgrcoop_pidm =  a.pidm)) DESC_SS,
                    sgrcoop_term_code PERIODO_SS, 
                     shrncrs_ncst_code SS_ESTATUS
                FROM tztprog_all A,sgrcoop, spriden, shrncrs
                WHERE 1=1
                AND a.pidm = sgrcoop_pidm (+)
                AND a.nivel = sgrcoop_levl_code (+)
                AND spriden_pidm = sgrcoop_pidm (+)
                AND a.pidm = spriden_pidm
                AND a.matricula = spriden_id
                AND a.pidm = shrncrs_pidm
                AND sgrcoop_pidm = shrncrs_pidm
                AND spriden_pidm = shrncrs_pidm
                AND spriden_change_ind IS NULL
                AND a.pidm =  p_pidm -- FGET_PIDM ('240346972')
                AND a.nivel = 'LI'
                AND SHRNCRS_NCRQ_CODE = 'SS'
                AND a.sp = (SELECT MAX (a1.sp)
                                   FROM tztprog_all A1
                                   WHERE 1=1
                                   AND a.pidm = a1.pidm
                                   AND a.programa = a1.programa
                                   and a.ctlg = a1.ctlg);

       RETURN (c_out_dato_grls_lib);

  END;                                     
       
    
END PKG_SERVICIO_SOCIAL;
/

DROP PUBLIC SYNONYM PKG_SERVICIO_SOCIAL;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SERVICIO_SOCIAL FOR BANINST1.PKG_SERVICIO_SOCIAL;
