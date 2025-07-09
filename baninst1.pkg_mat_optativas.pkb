DROP PACKAGE BODY BANINST1.PKG_MAT_OPTATIVAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_MAT_OPTATIVAS AS

--
--
FUNCTION f_num_mat_opta  (P_PROGRAM in varchar2, P_CTLG in varchar2) RETURN PKG_MAT_OPTATIVAS.cursor_num_mat_opta -- FER V1 07/08/2024

                    AS regist_num_mat_opta_out PKG_MAT_OPTATIVAS.cursor_num_mat_opta;
 BEGIN
     OPEN regist_num_mat_opta_out FOR
                                                             select distinct --a.*
                                                                a.SZTOPTA_REVOE,
                                                                a.SZTOPTA_PROGRAMA, 
                                                                a.SZTOPTA_PERIODO_CTG, 
                                                                a.SZTOPTA_CVE_AREA, 
                                                                SMRALIB_AREA_DESC,
                                                                a.SZTOPTA_DEBE_CURSAR,
                                                                a.SZTOPTA_CVE_HIJO, 
                                                                a.SZTOPTA_DESCRIPCION
                                                            from SZTOPTA A, SMRALIB
                                                            where 1=1
                                                            and a.SZTOPTA_CVE_AREA = SMRALIB_AREA
                                                            and a.SZTOPTA_PROGRAMA =  p_program
                                                            and a.SZTOPTA_PERIODO_CTG = P_CTLG 
                                                            order by SZTOPTA_CVE_AREA, SZTOPTA_CVE_HIJO
                                                                ;

     RETURN(regist_num_mat_opta_out);
     
 END f_num_mat_opta;
 
--
--
FUNCTION F_INSER_ZSTPARA (p_mapa VARCHAR2, p_param_id VARCHAR2,  P_param_desc VARCHAR2, p_param_valor VARCHAR2, p_user VARCHAR2) RETURN VARCHAR2 -- Fer V1 30/11/2023

      IS 
      
l_error VARCHAR2 (1000) := 'EXITO';      

begin 

            BEGIN 
                    INSERT INTO ZSTPARA
                    VALUES (
                                    p_mapa, 
                                    (select count (ZSTPARA_PARAM_SEC) from ZSTPARA where 1=1 and ZSTPARA_MAPA_ID =   p_mapa) +1,                                     
                                    p_param_id,                                   
                                    P_param_desc,                                    
                                    p_param_valor,                                     
                                    sysdate,                                       
                                    sysdate,
                                    p_user
                                   );
                                   
                    Exception 
                    When Others then
                    l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZFCOOP ' ||sqlerrm;  

            END;    
            
COMMIT;
      
RETURN (l_error);                

END;

--
--

FUNCTION f_per_catalogo  (P_MATRICULA in VARCHAR2) RETURN PKG_MAT_OPTATIVAS.cursor_per_catalogo -- FER V1 28/02/2025

                    AS regist_per_catalogo PKG_MAT_OPTATIVAS.cursor_per_catalogo;
 BEGIN
     OPEN regist_per_catalogo FOR
                                                    Select 
                                                    MATRICULA,
                                                    PROGRAMA,
                                                    CTLG
                                                    from TZTPROG A
                                                    where 1=1
                                                    AND A.MATRICULA = P_MATRICULA--'010017225'
                                                    and a.ESTATUS != 'CP'
                                                    AND A.SP = (SELECT MAX (A1.SP) 
                                                                        FROM TZTPROG A1 
                                                                        WHERE 1=1 
                                                                        AND A.MATRICULA = A1.MATRICULA
                                                                        )
                                                    AND ROWNUM = 1                    
--                                                     AND TRUNC (a.FECHA_MOV) = (SELECT MAX (TRUNC (a1.FECHA_MOV))
--                                                                                                    FROM tztprog a1
--                                                                                                    WHERE 1=1
--                                                                                                    AND A.MATRICULA = A1.MATRICULA)                                                                                                                        
                ;

     RETURN(regist_per_catalogo);
     
 END f_per_catalogo;  

--
--
FUNCTION f_mat_vinc_out  (p_pidm in number) RETURN PKG_MAT_OPTATIVAS.cursor_mat_vinc_out -- FER V1 17/04/2023

                    AS regist_mat_vinc_out PKG_MAT_OPTATIVAS.cursor_mat_vinc_out;
 BEGIN
     OPEN regist_mat_vinc_out FOR
                                                SELECT 
                                                PIDM
                                                , MATRICULA
                                                , MATRICULACION
                                                , spriden_first_name||' '||replace(spriden_last_name,'/',' ') NOMBRE_ALUMNO
                                                , (SELECT A.GOREMAL_EMAIL_ADDRESS FROM GOREMAL A WHERE 1=1 AND A.GOREMAL_PIDM = PIDM AND A.GOREMAL_EMAL_CODE = 'PRIN' AND GOREMAL_STATUS_IND  = 'A' AND A.GOREMAL_ACTIVITY_DATE = (SELECT MAX (A1.GOREMAL_ACTIVITY_DATE)
                                                                                                                                                                                                                                   FROM GOREMAL A1
                                                                                                                                                                                                                                   WHERE 1=1
                                                                                                                                                                                                                                   AND A1.GOREMAL_PIDM = A.GOREMAL_PIDM
                                                                                                                                                                                                                                   AND A1.GOREMAL_EMAL_CODE =A.GOREMAL_EMAL_CODE) ) CORREO
                                                , (SELECT STVSTST_DESC FROM stvstst WHERE 1=1 AND STVSTST_CODE = ESTATUS ) DESCRIPCION
                                                , PROGRAMA
                                                , NOMBRE
                                                FROM TZTPROG B, SPRIDEN
                                                WHERE 1=1
                                                AND B.PIDM = SPRIDEN_PIDM 
                                                AND B.MATRICULA =  SPRIDEN_ID
                                                AND SPRIDEN_CHANGE_IND IS NULL
                                                AND B.PIDM = p_pidm --240820
                                                --AND SUBSTR ('p_periodo', 3,6) = '2342'
                                                AND B.SP = (SELECT MAX (B1.SP)
                                                                   FROM TZTPROG B1
                                                                   WHERE 1=1
                                                                   AND B1.PIDM = B.PIDM )
                ;

     RETURN(regist_mat_vinc_out);
     
 END f_mat_vinc_out;

--
--  
--FUNCTION f_insert_SZTMTOP RETURN VARCHAR2 -- Fer V1 20/03/2024
PROCEDURE p_insert_SZTMTOP IS 
     
l_error VARCHAR2 (1000) := 'EXITO';

BEGIN 


    FOR C IN (
    
    
                   select *
                   from (
                   select DISTINCT 
                    PIDM, 
                    programa,
                    CTLG
                    from (
                    SELECT 
                    pidm, 
                    programa,
                    ctlg,
                    AC 
                    FROM (
                    select DISTINCT 
                    (select  distinct ZSTPARA_PARAM_ID from zstpara where 1=1 and ZSTPARA_MAPA_ID = 'MAT_OPTA_ACEP' AND ZSTPARA_PARAM_ID = GB_COMMON.F_GET_ID(a.pidm)) valida, 
                    a.pidm, 
                    a.programa,
                    a.ctlg,
                    SZTHITA_AVANCE AC 
                    from TZTPROG a, sztopta, SZTHITA 
                    where 1=1
                    AND a.pidm = SZTHITA_PIDM
                    AND a.estatus IN ('MA')
                    and a.programa = SZTOPTA_PROGRAMA
                    and SZTHITA_PROG = SZTOPTA_PROGRAMA
                    and a.CTLG = SZTOPTA_PERIODO_CTG
                    and SZTHITA_PER_CATALOGO = SZTOPTA_PERIODO_CTG
--                    and a.pidm = fget_pidm ('200577246')
                    and a.sp = (select max (a1.sp)
                                FROM tztprog a1
                                where 1=1
                                and a1.PIDM = a.pidm
                                AND a1.programa = a.programa
                                and a1.CTLG = a.CTLG)
                   )
                   WHERE 1=1
                   AND valida IS NULL
                    )
                    where 1=1
                    and AC >= 50  
                    MINUS
                    SELECT DISTINCT
                    SZTMTOP_PIDM PIDM,
                    SZTMTOP_PROGRAMA PROGRAMA,
                    SZTMTOP_CTLG CTLG
                    FROM SZTMTOP
                    WHERE 1=1
--                    and SZTMTOP_PIDM = fget_pidm ('200577246')
                    )
                    where 1=1    
--                    and pidm = fget_pidm ('200577246') 

    
--                    select DISTINCT 
--                    PIDM, 
--                    programa,
--                    CTLG
--                    from (
--                    select DISTINCT 
--                    a.pidm, 
--                    a.programa,
--                    a.ctlg,
--                    SZTHITA_AVANCE AC
--                    --(SELECT BANINST1.PKG_DATOS_ACADEMICOS.AVANCE1 (A.PIDM, a.programa)FROM DUAL) AC 
--                    from TZTPROG a, sztopta, SZTHITA 
--                    where 1=1
--                    AND a.pidm = SZTHITA_PIDM
--                    AND a.estatus IN ('MA')
--                    and a.programa = SZTOPTA_PROGRAMA
--                    and SZTHITA_PROG = SZTOPTA_PROGRAMA
--                    and a.CTLG = SZTOPTA_PERIODO_CTG
--                    and SZTHITA_PER_CATALOGO = SZTOPTA_PERIODO_CTG
--                    and a.sp = (select max (a1.sp)
--                                FROM tztprog a1
--                                where 1=1
--                                and a1.PIDM = a.pidm
--                                AND a1.programa = a.programa
--                                and a1.CTLG = a.CTLG)
--                    )
--                    where 1=1
--                    and AC >= 50  
--                    MINUS
--                    SELECT DISTINCT
--                    SZTMTOP_PIDM PIDM,
--                    SZTMTOP_PROGRAMA PROGRAMA,
--                    SZTMTOP_CTLG CTLG
--                    FROM SZTMTOP
--                    WHERE 1=1    
    
    
    
    
               )
               
               
               LOOP
               
               
                BEGIN
                
                    INSERT INTO SZTMTOP
                    VALUES (
                    C.PROGRAMA, --SZTMTOP_PROGRAMA
                    C.CTLG,--SZTMTOP_CTLG,
                    SYSDATE,--SZTMTOP_ACTIVITY_INSERT,
                    'MASIVO_OPTA',--SZTMTOP_USUARIO,
                    '0',--SZTMTOP_ESTATUS,
                    NULL,--SZTMTOP_COMENTARIOS,
                    NULL, --SZTMTOP_ACTIVITY_CONSUMO, 
                    C.PIDM --SZTMTOP_PIDM
                    );                
                    Exception 
                    When Others then
                    l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN SZTMTOP ' ||sqlerrm;                
                
                
                END;
               
               
               
               END LOOP;
    
    COMMIT;
    
  --  RETURN (l_error); 


END p_insert_SZTMTOP;

--
--  
--FUNCTION f_actu_matopta RETURN VARCHAR2 -- Fer V1 20/03/2025
PROCEDURE p_actu_matopta IS

l_CONTAR number;
l_error VARCHAR2 (1000) := 'EXITO';

begin 

    for c in (
    
    
    
                    SELECT
                    SZTMTOP_PIDM pidm,
                    GB_COMMON.F_GET_ID(SZTMTOP_PIDM) MATRICULA,
                    SZTOPTA_PROGRAMA,
                    SZTOPTA_PERIODO_CTG,
                    SZTOPTA_CVE_HIJO,
                    SZTOPTA_CHECK, 
                    DECODE (SZTOPTA_CHECK, 'S', 'MAT_OPTA_ACEP',
                                           'N', 'NOVER_MAT_DASHB') result
                    FROM SZTOPTA,SZTMTOP 
                    WHERE 1=1
                    AND SZTOPTA_PROGRAMA = SZTMTOP_PROGRAMA
                    AND SZTOPTA_PERIODO_CTG = SZTMTOP_CTLG
--                    and SZTMTOP_pidm = 726601
                    AND SZTMTOP_ESTATUS = '0'    
    
    
    
             )
             
             
             loop 
             
                l_error := null;
             
                
                    begin
                     
                    SELECT COUNT (ZSTPARA_PARAM_SEC +1) CONTAR
                    INTO l_CONTAR
                    FROM ZSTPARA
                    WHERE 1=1
                    AND ZSTPARA_MAPA_ID = c.result;
                    end;             
             
                    begin
                    INSERT INTO ZSTPARA
                    VALUES (
                    C.result,--ZSTPARA_MAPA_ID  
                    l_CONTAR,--ZSTPARA_PARAM_SEC
                    C.MATRICULA,--ZSTPARA_PARAM_ID
                    C.SZTOPTA_PROGRAMA,--ZSTPARA_PARAM_DESC
                    C.SZTOPTA_CVE_HIJO,--ZSTPARA_PARAM_VALOR
                    SYSDATE,--ZSTPARA_PARAM_ACT_DATE
                    SYSDATE,--ZSTPARA_PARAM_VIG_DATE
                    'AUTOMATICO_OPTA'--ZSTPARA_PARAM_USER 
                    );
                    
                    Exception 
                    When Others then
                    l_error := 'ERROR: SE PRESENTO AL INSERTAR REGISTRO EN ZSTPARA ' ||sqlerrm; 
                    end;
                    
                    
                    
                    begin 
                    
                    update SZTMTOP
                    set SZTMTOP_ESTATUS = '1',
                    SZTMTOP_COMENTARIOS = 'REGISTRO ACTUALIZADO CORRECTAMENTE',
                    SZTMTOP_ACTIVITY_CONSUMO = SYSDATE
                    where 1=1
                    and SZTMTOP_PIDM = c.pidm
                    and SZTMTOP_PROGRAMA= c.SZTOPTA_PROGRAMA
                    and SZTMTOP_CTLG = c.SZTOPTA_PERIODO_CTG;
                    
                    Exception 
                    When Others then
                    l_error := 'ERROR: SE PRESENTO AL ACTUALIZAR REGISTRO EN SZTMTOP ' ||sqlerrm;
                    
                    end;
                    
                    
                    
             end loop;

    COMMIT;
    
  --  RETURN (l_error); 

end p_actu_matopta;

                    
                    
--
--  

END PKG_MAT_OPTATIVAS;
/

DROP PUBLIC SYNONYM PKG_MAT_OPTATIVAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_MAT_OPTATIVAS FOR BANINST1.PKG_MAT_OPTATIVAS;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_MAT_OPTATIVAS TO PUBLIC;
