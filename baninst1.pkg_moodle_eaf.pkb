DROP PACKAGE BODY BANINST1.PKG_MOODLE_EAF;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_MOODLE_EAF 
    
 IS

/******************************************************************************
   NAME:    F_BNDA_EAF_OUT
   PURPOSE: funciÛn creada para enviar a sincronizar el curso de bienvenia de
            los alumnos del campus EAFIT 

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        15/07/2021      emontadi       1. Created this package.
******************************************************************************/

  FUNCTION f_bnda_eaf_out  RETURN PKG_MOODLE_EAF.cursor_bnda_eaf_out 
       AS
          bnda_eaf_out PKG_MOODLE_EAF.cursor_bnda_eaf_out;


    BEGIN
        
          BEGIN
             OPEN bnda_eaf_out FOR
             
                SELECT DISTINCT
                         SZTBNDA_PIDM PIDM,
                         SZTBNDA_ID MATRICULA,
                         REPLACE (TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄','aeiouAEIOU'),'/',' ')LAST_NAME,
                         SPRIDEN_FIRST_NAME FIRST_NAME,
                         GOREMAL_EMAIL_ADDRESS EMAIL,
                         SZTCOMD_SERVIDOR SERVIDOR,
                         SZTBNDA_TERM_NRC TERM,
                         SZTBNDA_PWD PWD,
                         SZTBNDA_CRSE_SUBJ CRS_MOODLE,
                         SZTCOMD_GRP_MDL_ID id_grupo,
                         SZTCOMD_CRSE_MDL_ID id_curso,
                         SZTCOMD_CAMP_CODE campus
                    FROM SZTBNDA,
                         SPRIDEN,
                         GOREMAL,
                         SZTCOMD,
                         ZSTPARA
                   WHERE SZTBNDA_STAT_IND = '0'
                         AND SZTBNDA_PIDM = SPRIDEN_PIDM
                         AND GOREMAL_PIDM = SZTBNDA_PIDM(+)
                         AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
                         AND SZTBNDA_CAMP_CODE = SZTCOMD_CAMP_CODE
                         AND SZTBNDA_LEVL_CODE = SZTCOMD_LEVL_CODE
                         AND SZTBNDA_CRSE_SUBJ = SZTCOMD_GRP_CODE 
                         AND SZTCOMD_ENABLE_IND = 'Y'
                         AND SZTBNDA_CAMP_CODE  IN(SELECT ZSTPARA_PARAM_ID
                                                FROM ZSTPARA
                                                WHERE 1=1
                                                AND ZSTPARA_MAPA_ID = 'CAMPUS_UNIVERSI')
                         AND SZTCOMD_CAMP_CODE = ZSTPARA_PARAM_ID
                         AND SPRIDEN_CHANGE_IND IS NULL 
                         AND SZTBNDA_MDLE_STAT IS NULL 
                         --AND SZTBNDA_ID = '460000023'
              ORDER BY CRS_MOODLE DESC;

             RETURN (bnda_eaf_out);
          END;
          
    END f_bnda_eaf_out;
    
/***************************************************************************************
*                                                                                      *
*   FUNCION: F_BNDA_EAF_UPDATE                                FECHA: 15/07/2021        *
*   TIPO: CURSOR                                                                       *
*   DESCRIPCION: ESTA FUNCI”N ACTUALIZA EL ESTATUS DE  SINCRONIZACI”N                  *
*                DEL CURSO DE BIENVENIDA  PARA A LOS ALUMNOS DE EC                     *
*                DEL CAMPUS EAF(EAFIT)                                                 *
*                                                                                      *
*   PARAMETROS DE ENTRADA: N/A                                                         *
*                                                                                      *
*   SALIDA: bnda_eaf_out                                                               *
*                                                                                      *
****************************************************************************************/

 FUNCTION F_BNDA_EAF_UPDATE(p_pidm in number, p_term in varchar2, p_stat_ind in varchar2,  p_obs in varchar2, p_grp_id in number, p_shrt_name in varchar2) Return Varchar2
 
    AS
      vl_error   VARCHAR2 (250) := 'FunciÛn F_BNDA_EAF_UPDATE: Exitosa';
      
 BEGIN    
        FOR c IN (SELECT a.SZTBNDA_PIDM pidm, 
               a.SZTBNDA_ID matricula,
               a.SZTBNDA_TERM_NRC perido,
               a.SZTBNDA_GRP_MDL_ID id_grupo, 
               a.SZTBNDA_CRSE_SUBJ short_name, 
               a.SZTBNDA_CAMP_CODE campus, 
               a.SZTBNDA_LEVL_CODE nivel,
               a.SZTBNDA_SEQ_NO consecutivo    
            FROM SZTBNDA a
            WHERE 1=1     
            AND a.SZTBNDA_SEQ_NO IN (SELECT MAX(SZTBNDA_SEQ_NO)
                                   FROM SZTBNDA b
                                   WHERE 1=1
                                   AND b.SZTBNDA_PIDM = a.SZTBNDA_PIDM
                                   AND b.SZTBNDA_TERM_NRC = a.SZTBNDA_TERM_NRC
                                   AND b.SZTBNDA_CRSE_SUBJ = a.SZTBNDA_CRSE_SUBJ)          
            AND SZTBNDA_TERM_NRC = p_term --'012041'
            AND SZTBNDA_PIDM = p_pidm --219077
            AND SZTBNDA_CRSE_SUBJ = p_shrt_name 
     )loop   
   
   
      BEGIN
         UPDATE SZTBNDA
            SET SZTBNDA_STAT_IND = p_stat_ind,
                SZTBNDA_OBS = SUBSTR(p_obs,1,250),
                SZTBNDA_GRP_MDL_ID = p_grp_id
          WHERE SZTBNDA_PIDM = p_pidm
                AND SZTBNDA_TERM_NRC = c.perido
                AND SZTBNDA_CRSE_SUBJ = c.short_name
                AND SZTBNDA_SEQ_NO = c.consecutivo;
      END;
    end loop;
    COMMIT;
    RETURN vl_error;
    EXCEPTION
    WHEN OTHERS
    THEN
    vl_error := 'Error en F_BNDA_EAF_UPDATE' || SQLERRM;
    RETURN vl_error;
 
 
 END F_BNDA_EAF_UPDATE;  
 
 
 /******************************************************************************
   NAME:     f_detona_moodle
   PURPOSE: Dotonar la descarga de los id de short_names del aula
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/

    FUNCTION f_detona_moodle_eaf (p_stat in varchar2)return Varchar2
    
      as

    vl_return Varchar2(250);

   BEGIN
   
          if p_stat = '0' then
                
                vl_return:=0;
                
                begin
                 update SZTMEAF set SZTMEAF_STAT_IND = p_stat,SZTMEAF_USER = 'sync-'||user, SZTMEAF_ACTIVITY_DATE = sysdate;
                 return(vl_return);   
                 end;
                 commit;
                             
          elsif  p_stat = 1 then
                   
                 begin
                 SELECT SZTMEAF_STAT_IND
                 INTO vl_return
                 FROM SZTMEAF;
                 end;
                 
          end if;         
        return (vl_return);
        
   END f_detona_moodle_eaf ;
   
 
 
/******************************************************************************
   NAME:     f_moodle_ini_eaf
   PURPOSE: Recibir los id's de los cursos encontrados en AV
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/
   
   
    FUNCTION f_moodle_ini_eaf (p_crse_id IN NUMBER, p_short_name IN VARCHAR2, p_servidor in varchar2) return varchar2
   AS
    --p_short_name Varchar2 (100):='MB019_0_0312_M1DJO114';
    --p_servidor varchar2(10):= '12';
    --p_crse_id number:= 2345;

    vl_servidor varchar2(10);
    vl_msje Varchar2(200);
    vl_subj_maur   VARCHAR2 (100);
    vl_no_regla number:= 0;
    row_count number := 0;

    BEGIN

      
          BEGIN 
          
            SELECT a.SZTGPME_NO_REGLA 
            INTO vl_no_regla
            FROM SZTGPME a
            WHERE 1=1
            AND a.SZTGPME_CRSE_MDLE_CODE = p_short_name
            AND a.SZTGPME_CAMP_CODE = 'EAF' 
            AND a.SZTGPME_GRUPO = (SELECT MAX(a1.SZTGPME_GRUPO) FROM SZTGPME a1
                                  WHERE 1=1
                                  AND a1.SZTGPME_SUBJ_CRSE= a.SZTGPME_SUBJ_CRSE
                                  AND a1.SZTGPME_NO_REGLA =a.SZTGPME_NO_REGLA
                                  AND a1.SZTGPME_CRSE_MDLE_CODE = a.SZTGPME_CRSE_MDLE_CODE);
          EXCEPTION WHEN OTHERS THEN
          vl_msje:='Error al obtener regla -line:169:- '||sqlerrm; 
          END;
            
          --dbms_output.put_line(vl_msje);
      
           BEGIN
            SELECT DISTINCT SZTMAUR_SZTURMD_ID, SZTMAUR_MACO_PADRE
            INTO vl_servidor, vl_subj_maur
            FROM SZTMAUR
            WHERE 1= 1
            And SZTMAUR_MACO_PADRE = (SELECT DISTINCT (SZTGPME_SUBJ_CRSE_COMP)
                                        FROM SZTGPME
                                        WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                                        AND SZTGPME_STAT_IND IS NOT NULL
                                        AND SZTGPME_NO_REGLA != 0
                                        AND SZTGPME_NO_REGLA = vl_no_regla)
            AND SZTMAUR_ACTIVO ='S'
            AND SZTMAUR_SZTURMD_ID = p_servidor;
            EXCEPTION WHEN NO_DATA_FOUND THEN
            vl_msje:='Error al obtener vl_servidor != 12 -line:186:- '||sqlerrm; 
           END; 
           
           --dbms_output.put_line(vl_msje);
           
             IF vl_servidor IS NOT NULL AND vl_subj_maur IS NOT NULL THEN
               
                 BEGIN           
                   
                    UPDATE SZTGPME
                    SET SZTGPME_CRSE_MDLE_ID = p_crse_id, SZTGPME_PTRM_CODE_COMP = vl_servidor
                    WHERE SZTGPME_CRSE_MDLE_CODE = p_short_name
                    AND SZTGPME_SUBJ_CRSE = vl_subj_maur
                    AND SZTGPME_STAT_IND IS NOT NULL;
                    row_count := SQL%ROWCOUNT;
                    
                   --DBMS_OUTPUT.PUT_LINE('CUENTA REG: '|| row_count);
                                                                   
                            IF SQL%ROWCOUNT > 0 THEN
                              vl_msje := ('Registros afectados: '|| row_count||' '||'Para servidor:'|| vl_servidor);
                              --DBMS_OUTPUT.put_line (vl_msje);
                            ELSE
                                vl_msje := ('Registros afectados: '|| row_count);
                                --DBMS_OUTPUT.put_line (vl_msje);
                            END IF;
                    
                   EXCEPTION
                   WHEN OTHERS
                   THEN
                   vl_msje := 'Error' || SQLERRM; 
                   END; 
                   
               END IF;
            COMMIT;
        
    RETURN(vl_msje);

    END f_moodle_ini_eaf;    
 
 
       /******************************************************************************
   NAME:     f_grupos_eaf_out
   PURPOSE: Sincronizar los grupos con el Aula Virtual
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/

 FUNCTION f_grupos_eaf_out  RETURN PKG_MOODLE_EAF.crsr_gps_out
   AS
      c_gps_out   PKG_MOODLE_EAF.crsr_gps_out;
      
   BEGIN
   
    BEGIN
      
         OPEN c_gps_out FOR  
                    SELECT SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_CRSE_MDLE_ID crs_mdle_id,
                     SZTGPME_START_DATE Fecha,
                     CONCAT ('Grupo_',SUBSTR (SZTGPME_TERM_NRC,LENGTH (SZTGPME_TERM_NRC) - 1,99))grupo,
                     SZSGNME_PIDM Docente,
                     SZTGPME_STAT_IND Indicador,
                     SZTGPME_MAX_ENRL sobrecupo,
                     SZTGPME_MAX_ENRL CupoMaximo,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZTGPME_NO_REGLA no_regla,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     SZTMEAF,
                     SZSGNME,
                     SZTMAUR,
                     SZTURMD,
                     ZSTPARA a
               WHERE 1=1
               AND SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE = SZSGNME_START_DATE
                     AND SZTGPME_STAT_IND = '0'
                     AND SZTMEAF_STAT_IND = 0
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTGPME_CRSE_MDLE_ID IS NOT NULL
                     AND SZTGPME_PTRM_CODE_COMP = SZTURMD_ID
                     AND SZTURMD_ACTIVO ='S'
                     AND a.ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND a.ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND a.ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND SZTGPME_NO_REGLA <> 99
                     AND SZTMAUR_ORIGEN <> 'E'
                     AND SZTGPME_CAMP_CODE = 'EAF';
      RETURN(c_gps_out);
    END;
  END f_grupos_eaf_out;
  
  
/******************************************************************************
   NAME:     f_update_grupos_eaf
   PURPOSE: Sincronizar a los docentes en los curos del Aula Virtual
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/   

   FUNCTION f_update_grupos_eaf (p_materia in varchar2,  p_fecha_ini in varchar2, p_stat_upte_ind in varchar2,  p_crse_mdle_code in number default null, p_obs in varchar2,
                                 p_error_code in number default null, p_error_desc in varchar2, p_gpmdle_code in number default null, p_pidm in number default null, p_no_regla in number) return varchar
   AS
      vl_maximo number := 0;
      vl_error varchar2 (5000) := 'Termino';
      row_count number := 0;
      
   BEGIN
   
      FOR c IN (SELECT SZTGPME_TERM_NRC,
                SZTGPME_STAT_IND,
                SZTGPME_OBS,
                SZTGPME_GPMDLE_ID,
                SZTGPME_START_DATE
                FROM SZTGPME
                WHERE SZTGPME_TERM_NRC = p_materia
                AND SZTGPME_START_DATE = TO_DATE (p_fecha_ini, 'dd/mm/yyyy')
                AND SZTGPME_NO_REGLA = p_no_regla
                AND SZTGPME_CAMP_CODE = 'EAF'
               ) 
      LOOP
         -- CÛdigo 2 para identidficar a los errores de sinconizaciÛn con Moodle Trae el registro m·ximo del grupo de la tabla de bitacora--

         IF p_stat_upte_ind = 2
         THEN
            BEGIN
            SELECT NVL (MAX (SZTMEBI_SEQ_NO), 0) + 1
            INTO vl_maximo
            FROM SZTMEBI
            WHERE SZTMEBI_TERM_NRC = c.SZTGPME_TERM_NRC
            AND SZTMEBI_CTGY_ID = 'Curso-Grupo';
            EXCEPTION
            WHEN OTHERS
            THEN
            vl_maximo := 1;
            END;

            BEGIN
               INSERT INTO SZTMEBI
               VALUES (c.SZTGPME_TERM_NRC,
                       p_stat_upte_ind,
                       p_error_code,
                       p_error_desc,
                       1,
                       SYSDATE,
                       USER,
                      'Curso-Grupo-EAF',
                       p_pidm);

               row_count := SQL%ROWCOUNT;
               --DBMS_OUTPUT.put_line ('Registros insertados en bitacora' || ' ' || row_count);

               vl_error := 'Registros insertados en bitacora '||row_count;
            EXCEPTION
            WHEN OTHERS
            THEN
            vl_error := 'Error al insertar Curso-Grupo en la Bitacora:'||SQLERRM;
            END;

            --Actualiza el status indicator a 2 e inserta las observaciones de error--

            BEGIN
               UPDATE SZTGPME
               SET SZTGPME_STAT_IND = p_stat_upte_ind,
               SZTGPME_OBS = p_obs, -- 'Error de sincronia ver SZTMEBI',
               SZTGPME_ACTIVITY_DATE = SYSDATE
               WHERE SZTGPME_TERM_NRC = c.SZTGPME_TERM_NRC
               AND SZTGPME_NO_REGLA = p_no_regla
               AND SZTGPME_START_DATE = c.SZTGPME_START_DATE;

               row_count := SQL%ROWCOUNT;
               --DBMS_OUTPUT.put_line ('Registros acualizados con error:' || ' ' || row_count);
               vl_error := 'Registros acualizados con error: '||row_count;
            END;
         ELSE
            -- CÛdigo 1 Èxito de inconizaciÛn con Moodle--
            --Actualiza el status indicator a 1 e inserta las observaciones de exito--
            BEGIN
            
               UPDATE SZTGPME
               SET SZTGPME_STAT_IND = p_stat_upte_ind,
               SZTGPME_OBS = p_obs || p_gpmdle_code,
               SZTGPME_GPMDLE_ID = p_gpmdle_code,
               SZTGPME_ACTIVITY_DATE = SYSDATE
               WHERE SZTGPME_TERM_NRC = c.SZTGPME_TERM_NRC
               AND SZTGPME_NO_REGLA = p_no_regla
               AND SZTGPME_START_DATE = c.SZTGPME_START_DATE;

               row_count := SQL%ROWCOUNT;
               --DBMS_OUTPUT.put_line ('Registros acualizados con exito:' || ' ' || row_count);
               vl_error := 'Registros acualizados con exitor: '||row_count;
            EXCEPTION
            WHEN OTHERS THEN
            vl_error := 'Error al actualizar tabla intermedia' ||SQLERRM;
            END;
            
         END IF;
      END LOOP;

   COMMIT;
   RETURN  vl_error||'-'||row_count||'-'||p_stat_upte_ind||'-'|| p_error_code||'-'|| p_error_desc;
   EXCEPTION
   WHEN OTHERS
   THEN
   vl_error := 'Error General f_update_sztgpme '||SQLERRM;
   RETURN vl_error;
   END;
  
   
  /******************************************************************************
   NAME:     f_docentes_eaf_out
   PURPOSE: Sincronizar a los docentes en los curos del Aula Virtual
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/   
   
 FUNCTION f_docentes_eaf_out
      RETURN PKG_MOODLE_EAF.cursor_dctes_out
   AS
      dctes_out   PKG_MOODLE_EAF.cursor_dctes_out;

   BEGIN
   
      BEGIN
         OPEN dctes_out FOR
              SELECT SZTGPME_TERM_NRC,
                     SZTGPME_CRSE_MDLE_CODE short_name,
                     SZTGPME_START_DATE Fecha_inicio,
                     SZTGPME_SUBJ_CRSE_COMP SZTGPME_SUBJ_CRSE,
                     SZTGPME_GPMDLE_ID,
                     SZTGPME_CRSE_MDLE_ID,
                     SZSGNME_PIDM,
                     SPRIDEN_ID,
                     SZSGNME_STAT_IND,
                     REPLACE (TRANSLATE (SPRIDEN.SPRIDEN_LAST_NAME,'·ÈÌÛ˙¡…Õ”⁄','aeiouAEIOU'),'/',' ') LAST_NAME,
                     SPRIDEN_FIRST_NAME,
                     SZSGNME_PWD,
                     CASE
                     WHEN GOREMAL_EMAIL_ADDRESS IS NULL
                     THEN
                     SPRIDEN_ID || '@utel.edu.mx'
                     ELSE
                     GOREMAL_EMAIL_ADDRESS
                     END
                     CORREO,
                     SZTGPME_PTRM_CODE_COMP servidor,
                     SZSGNME_NO_REGLA no_regla,
                     SZTGPME_CAMP_CODE campus,
                     SZTGPME_LEVL_CODE Nivel,
                     SZTMAUR_ORIGEN tipo_curso
                FROM SZTGPME,
                     SZSGNME,
                     SPRIDEN,
                     GOREMAL,
                     ZSTPARA,
                     SZTMAUR
               WHERE SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_START_DATE = SZSGNME_START_DATE
                     AND SZSGNME_PIDM = SPRIDEN_PIDM
                     AND SZSGNME_PIDM = GOREMAL_PIDM(+)
                     AND GOREMAL_EMAL_CODE = NVL ('PRIN', GOREMAL_EMAL_CODE)
                     AND SZTGPME_STAT_IND = '1'
                     AND SZTGPME_CRSE_MDLE_ID != 0
                     AND SZSGNME_STAT_IND IN ('0')
                     AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                     AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2)
                     AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                     AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                     AND SZTMAUR_ACTIVO = 'S'
                     AND SZTMAUR_ORIGEN <> 'E'
                     AND SZSGNME_NO_REGLA <> 99
                     AND SPRIDEN_CHANGE_IND IS NULL  
                     AND SZTGPME_CAMP_CODE = 'EAF';      
         RETURN (dctes_out);
      END;
   END f_docentes_eaf_out;
       
   
   /******************************************************************************
   NAME:     f_updte_docentes_eaf
   PURPOSE: Recibir la respuesta de sincronia de docentes
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/   
   
 FUNCTION f_updte_docentes_eaf (p_crsemdle_id in number, p_pidm in number, p_stat_upte_ind in Varchar2, p_obs in Varchar2, p_asgn_mdle in Varchar2,p_error_code in Number,  p_error_desc in Varchar2,  p_pidm_ant in number, p_no_regla in number, p_term_nrc in varchar2, p_fecha_ini in varchar2) Return Varchar2
    AS 
        vl_maximo number:=0;         
        vl_error  varchar2(250) := 'Proceso exitoso';

                  
            BEGIN

                  for c in (  SELECT SZSGNME_STAT_IND, SZSGNME_OBS, SZSGNME_ASGNMDLE_ID, SZSGNME_TERM_NRC, SZSGNME_START_DATE
                                FROM SZSGNME, SZTGPME
                                WHERE  SZTGPME_TERM_NRC=SZSGNME_TERM_NRC     
                                AND SZTGPME_CRSE_MDLE_ID= p_crsemdle_id 
                                AND SZSGNME_PIDM = p_pidm
                                AND SZSGNME_NO_REGLA = p_no_regla 
                                AND SZSGNME_TERM_NRC = p_term_nrc
                                AND SZSGNME_START_DATE = p_fecha_ini
                                AND SZTGPME_CAMP_CODE = 'EAF'
                                ) 
                                
                   loop
                                
                                
                                
                             IF  p_stat_upte_ind = 2 THEN
                                    
                                 Begin
                                      Select nvl (max (SZTMEBI_SEQ_NO), 0 ) +1
                                      Into vl_maximo
                                      from SZTMEBI
                                      Where SZTMEBI_TERM_NRC = c.SZSGNME_TERM_NRC
                                      and SZTMEBI_CTGY_ID = 'Docentes-EAF';
                                      Exception
                                      When Others then 
                                      vl_maximo :=1;
                                END;
                                        
                                        
                                begin
                                     INSERT INTO SZTMEBI 
                                     VALUES(c.SZSGNME_TERM_NRC, p_stat_upte_ind, p_error_code, p_error_desc,vl_maximo, sysdate,USER, 'Docentes-EAF',p_pidm );
                                Exception
                                When others then 
                                vl_error := 'Error al insertar Docentes en la Bitacora'||sqlerrm;
                                End; 
                              
                                         
                                begin        
                                     UPDATE SZSGNME
                                     SET SZSGNME_STAT_IND = p_stat_upte_ind, 
                                     SZSGNME_OBS = 'Error de sincronia ver SZTMEBI',
                                     SZSGNME_ACTIVITY_DATE = sysdate
                                     WHERE SZSGNME_TERM_NRC = c.SZSGNME_TERM_NRC   
                                     AND SZSGNME_PIDM = p_pidm
                                     AND SZSGNME_NO_REGLA = p_no_regla
                                     AND SZSGNME_START_DATE = c.SZSGNME_START_DATE;   
                                Exception
                                When others then 
                                  vl_error := 'Error al actualizar Docentes'||sqlerrm;                
                                end;
                                    
                                                  
                             ELSIF p_stat_upte_ind =5 THEN

                               begin
                                   UPDATE SZSGNME 
                                   SET SZSGNME_FCST_CODE = 'IN',
                                   SZSGNME_OBS = p_obs,
                                   SZSGNME_ACTIVITY_DATE = sysdate
                                   WHERE SZSGNME_TERM_NRC = c.SZSGNME_TERM_NRC
                                  AND SZSGNME_ASGNMDLE_ID = p_pidm_ant
                                  AND SZSGNME_NO_REGLA = p_no_regla
                                  AND SZSGNME_START_DATE = c.SZSGNME_START_DATE; 
                                Exception
                                When others then 
                                vl_error := 'Error al actualizar Docentes'||sqlerrm;
                             end;

                             ELSIF   p_stat_upte_ind =1 then 
                                 Begin
                                  UPDATE SZSGNME
                                  SET SZSGNME_STAT_IND = p_stat_upte_ind,
                                  SZSGNME_OBS = p_obs,
                                  SZSGNME_ASGNMDLE_ID = p_asgn_mdle,
                                  SZSGNME_ACTIVITY_DATE = sysdate
                                  WHERE SZSGNME_TERM_NRC = c.SZSGNME_TERM_NRC
                                  AND SZSGNME_PIDM = p_pidm
                                  AND SZSGNME_NO_REGLA = p_no_regla
                                  AND SZSGNME_START_DATE = c.SZSGNME_START_DATE;   
                                Exception
                                When others then 
                                  vl_error := 'Error al actualizar Docentes 2'||sqlerrm;
                                End;  
                             end if;                                                
                                              
                 End Loop;
                 
                
                COMMIT;
                Return vl_error;
             
                 
            END f_updte_docentes_eaf;
                        
 
  /******************************************************************************
   NAME:     f_alumnos_eaf_out
   PURPOSE: Sincronizar a los docentes en los curos del Aula Virtual
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/  

           
 FUNCTION f_alumnos_eaf_out (p_aula in varchar2)
      RETURN PKG_MOODLE_EAF.cursor_alumnos_out
   AS
      alumnos_out PKG_MOODLE_EAF.cursor_alumnos_out; 

    BEGIN 
    
        OPEN alumnos_out FOR
           SELECT SPRIDEN_PIDM PIDM,
                   SPRIDEN_ID MATRICULA,
                   REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
                   SPRIDEN_FIRST_NAME FIRST_NAME,
                   a.GOREMAL_EMAIL_ADDRESS EMAIL,
                   SZSTUME_RSTS_CODE ESTATUS,
                   SZSTUME_TERM_NRC TERM_NRC,
                   GOZTPAC_PIN pwd,
                   SZTGPME_PTRM_CODE_COMP servidor,
                   SZTGPME_CRSE_MDLE_ID id_curso,
                   SZTGPME_GPMDLE_ID id_grupo,
                   SZSTUME_SEQ_NO secuencia,
                   SZSTUME_NO_REGLA no_regla,
                   SORLCUR_CAMP_CODE campus,
                   SORLCUR_LEVL_CODE Nivel,
                   --SORLCUR_PROGRAM programa,
                   --SORLCUR_TERM_CODE_CTLG periodo_catalogo,
                   SZTMAUR_ORIGEN tipo_curso,
                   SZTDTEC_MOD_TYPE,
                   --SGBSTDN_TERM_CODE_EFF periodo,
                   SZSTUME_START_DATE Fecha_inicio
              FROM SPRIDEN,
                   STVRSTS,
                   GOREMAL a,
                   SZSTUME,
                   GOZTPAC,
                   ZSTPARA,
                   SZTGPME,
                   SGBSTDN A,
                   SORLCUR B,
                   SZTMAUR,
                   SZSGNME,
                   SZTDTEC
             WHERE SPRIDEN_CHANGE_IND IS NULL
                   AND SPRIDEN_PIDM = SZSTUME_PIDM
                   AND SPRIDEN_PIDM = GOZTPAC_PIDM
                   AND SZSTUME_RSTS_CODE = STVRSTS_CODE
                   AND SPRIDEN_PIDM = a.GOREMAL_PIDM
                   AND SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                   AND SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                   AND SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                   AND SZSTUME_STAT_IND = '0'
                   AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
                   AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
                   AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
                   AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
                   AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
                   AND SZSTUME_START_DATE = SZTGPME_START_DATE 
                   AND SZTGPME_STAT_IND = '1'
                   AND SZTGPME_CRSE_MDLE_ID != 0
                   AND SZSTUME_RSTS_CODE = 'RE'
                   and SZSTUME_CAMP_CODE_COMP is null
                   AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
                   AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                                 FROM GOREMAL a1
                                                 WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                                 AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)
                   AND SPRIDEN_PIDM = A.SGBSTDN_PIDM
                   AND A.SGBSTDN_STST_CODE  IN ('MA', 'PR', 'AS')
                   AND A.SGBSTDN_TERM_CODE_EFF = (SELECT MAX (SGBSTDN_TERM_CODE_EFF)
                                                  FROM SGBSTDN A1
                                                  WHERE A.SGBSTDN_PIDM = A1.SGBSTDN_PIDM
                                                  AND A.SGBSTDN_TERM_CODE_EFF = A1.SGBSTDN_TERM_CODE_EFF
                                                  AND A.SGBSTDN_LEVL_CODE = A1.SGBSTDN_LEVL_CODE
                                                  AND A.SGBSTDN_CAMP_CODE = A1.SGBSTDN_CAMP_CODE
                                                  AND A.SGBSTDN_STST_CODE = A1.SGBSTDN_STST_CODE )                                              
                    AND B.SORLCUR_PIDM = SZSTUME_PIDM    
                    And  b.SORLCUR_LMOD_CODE = 'LEARNER'
                    And b.SORLCUR_CACT_CODE = 'ACTIVE'
                    and b.sorlcur_camp_code = SGBSTDN_CAMP_CODE
                    And b.sorlcur_levl_code = SGBSTDN_LEVL_CODE
                    And b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
                                                            from SORLCUR b1
                                                            where b.SORLCUR_PIDM = b1.SORLCUR_PIDM
                                                            And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
                                                            And b.SORLCUR_CACT_CODE = b1.SORLCUR_CACT_CODE
                                                            And b.sorlcur_camp_code = b1.sorlcur_camp_code
                                                            And b.sorlcur_levl_code = b1.sorlcur_levl_code
                                                            and b.SORLCUR_ADMT_CODE = b1.SORLCUR_ADMT_CODE)
                    AND SZTMAUR_MACO_PADRE = SZTGPME_SUBJ_CRSE
                    AND SZTMAUR_ACTIVO = 'S'  
                    AND SZSTUME_TERM_NRC = SZSGNME_TERM_NRC
                    AND SZSTUME_NO_REGLA = SZSGNME_NO_REGLA
                    AND SZSTUME_START_DATE = SZSGNME_START_DATE
                    AND SZTGPME_NO_REGLA <> 99
                    AND SZTMAUR_ORIGEN <> 'E'
                    AND SZTGPME_CAMP_CODE = 'EAF'
                    AND SZTGPME_PTRM_CODE_COMP = p_aula;
                    
              RETURN (alumnos_out);
 
END f_alumnos_eaf_out;



/******************************************************************************
   NAME:     f_baja_alumnos_eaf_out
   PURPOSE: Sincronizar las baja de materia con el AV
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/  


 FUNCTION f_baja_alumnos_eaf_out
     RETURN PKG_MOODLE_EAF.cursor_baja_alumnos_out
   AS
      baja_alumnos_out PKG_MOODLE_EAF.cursor_baja_alumnos_out;
   ---- Esta Funcion realiza el envio de los alumnos a dar de  baja y con materias registradas hacia Moodle ---
   BEGIN
      BEGIN
      OPEN baja_alumnos_out FOR
      SELECT SPRIDEN_PIDM PIDM,
       SPRIDEN_ID MATRICULA,
       REPLACE (TRANSLATE (SPRIDEN_LAST_NAME, '·ÈÌÛ˙¡…Õ”⁄', 'aeiouAEIOU'),'/', ' ') LAST_NAME,
       SPRIDEN_FIRST_NAME FIRST_NAME,
       a.GOREMAL_EMAIL_ADDRESS EMAIL,
       SZSTUME_RSTS_CODE ESTATUS,
       SZSTUME_TERM_NRC TERM_NRC,
       GOZTPAC_PIN pwd,
       SZTGPME_PTRM_CODE_COMP servidor,
       SZTGPME_CRSE_MDLE_ID id_curso,
       SZTGPME_GPMDLE_ID id_grupo,
       SZSTUME_SEQ_NO secuencia,
       SZSTUME_NO_REGLA no_regla,
       SZTGPME_CAMP_CODE campus,
       SZTGPME_LEVL_CODE Nivel,
       SZSTUME_START_DATE Fecha_inicio
  FROM SPRIDEN,
       STVRSTS,
       GOREMAL a,
       SZSTUME,
       GOZTPAC,
       ZSTPARA,
       SZTGPME,
       SORLCUR c
       WHERE SPRIDEN_CHANGE_IND IS NULL
       AND SPRIDEN_PIDM = SZSTUME_PIDM
       AND SPRIDEN_PIDM = GOZTPAC_PIDM
       AND SZSTUME_RSTS_CODE = STVRSTS_CODE
       AND SPRIDEN_PIDM = a.GOREMAL_PIDM
       AND SZSTUME_STAT_IND = '0'
       AND ZSTPARA_MAPA_ID = 'MOODLE_ID'
       AND ZSTPARA_PARAM_ID = SUBSTR (SZTGPME_TERM_NRC_COMP, 1, 2) --SZTGPME_TERM_NRC
       AND ZSTPARA_PARAM_DESC = SZTGPME_LEVL_CODE
       AND RTRIM (SZSTUME_TERM_NRC) = RTRIM (SZTGPME_TERM_NRC)
       AND SZSTUME_NO_REGLA = SZTGPME_NO_REGLA
       AND SZSTUME_START_DATE = SZTGPME_START_DATE
       AND SZTGPME_STAT_IND = '1'
       AND SZTGPME_CRSE_MDLE_ID != 0
       AND SZSTUME_RSTS_CODE != 'RE'          
       and SZSTUME_CAMP_CODE_COMP is null
       AND a.GOREMAL_EMAL_CODE = NVL ('PRIN', a.GOREMAL_EMAL_CODE)
       AND a.GOREMAL_SURROGATE_ID = (SELECT MAX (A1.GOREMAL_SURROGATE_ID)
                                     FROM GOREMAL a1
                                     WHERE a.GOREMAL_pidm = a1.GOREMAL_pidm
                                     AND a.GOREMAL_EMAL_CODE = a1.GOREMAL_EMAL_CODE)                 
        AND c.SORLCUR_PIDM = SZSTUME_PIDM  
        AND c.SORLCUR_SEQNO = (select max (c1.SORLCUR_SEQNO)
                              from SORLCUR c1
                              where c.SORLCUR_PIDM = c1.SORLCUR_PIDM)
        AND SZTGPME_CAMP_CODE = 'EAF';

         RETURN (baja_alumnos_out);
      END;
   END f_baja_alumnos_eaf_out;
    

  /******************************************************************************
   NAME:     f_updte_alumnos_eaf
   PURPOSE: Sincronizar a los docentes en los curos del Aula Virtual
   
   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        19/07/2021      emontadi       1. Created this package.
******************************************************************************/  

 FUNCTION f_updte_alumnos_eaf(p_trem_nrc in Varchar2, p_pidm in number, p_stat_upte_ind in Varchar2, p_obs in Varchar2, 
                              p_asgn_mdle in Varchar2,p_error_code in Number,  p_error_desc in Varchar2, p_grade_final in Varchar2, 
                              p_enrl_id_grpmoodle in varchar2, p_seq_no in number, p_no_regla in number, p_fecha_ini in varchar2) Return Varchar2
    AS 
        vl_maximo number:=0;
        vl_error varchar2(250);

      BEGIN

                  IF  p_stat_upte_ind = 2 THEN
                         
                         begin
                            
                                 Begin
                                 
                                      Select nvl (max (SZTMEBI_SEQ_NO), 0 ) +1
                                      Into vl_maximo
                                      from SZTMEBI
                                      Where SZTMEBI_TERM_NRC = p_trem_nrc
                                      and SZTMEBI_CTGY_ID = 'Alumnos-EAF';
                                      Exception
                                      When Others then 
                                      vl_maximo :=1;
                                      
                                END;  
                                
                                begin 

                                    INSERT INTO SZTMEBI 
                                    VALUES(p_trem_nrc, p_stat_upte_ind, p_error_code, p_error_desc, vl_maximo, sysdate,user, 'Alumnos-EAF', p_pidm);
                                    Exception
                                    When others then 
                                    vl_error := 'Error al insertar Alumnos en la Bitacora'||sqlerrm;
                                    
                                End;
                                
                                begin 
                                                                                         
                                    UPDATE SZSTUME
                                    SET SZSTUME_STAT_IND = p_stat_upte_ind, 
                                           SZSTUME_OBS = p_obs,
                                           SZSTUME_ACTIVITY_DATE = sysdate
                                    WHERE SZSTUME_TERM_NRC = p_trem_nrc
                                    AND SZSTUME_PIDM = p_pidm
                                    AND SZSTUME_SEQ_NO = p_seq_no 
                                    AND SZSTUME_NO_REGLA = p_no_regla
                                    AND SZSTUME_START_DATE = p_fecha_ini;    
                                                             
                                end;
                         Exception when others then
                         vl_error:= 'Error al trartar el szstume.stat_ind 2'||sqlerrm;
                         end;  
                                                            
                  ELSE
                    
                       begin
                            UPDATE SZSTUME a
                            SET a.SZSTUME_STAT_IND = p_stat_upte_ind,
                            a.SZSTUME_OBS = p_obs,
                            a.SZSTUME_MDLE_ID = p_asgn_mdle,
                            a.SZSTUME_ACTIVITY_DATE = sysdate
                            WHERE a.SZSTUME_TERM_NRC = p_trem_nrc
                            AND a.SZSTUME_PIDM = p_pidm
                            AND a.SZSTUME_SEQ_NO = p_seq_no
                            AND a.SZSTUME_NO_REGLA = p_no_regla
                            AND a.SZSTUME_START_DATE = p_fecha_ini;
                         
                       Exception
                        When Others then
                          vl_error := 'Error al actualizar el alumno *'||p_trem_nrc ||'*'||p_pidm ||'*'||p_seq_no ||'*'||p_no_regla||' *'||sqlerrm;
                        end;  
                                
                  END IF;  
                  
              COMMIT;
              
                Return vl_error;    
                
      END f_updte_alumnos_eaf;




END;
/

DROP PUBLIC SYNONYM PKG_MOODLE_EAF;

CREATE OR REPLACE PUBLIC SYNONYM PKG_MOODLE_EAF FOR BANINST1.PKG_MOODLE_EAF;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_MOODLE_EAF TO PUBLIC;
