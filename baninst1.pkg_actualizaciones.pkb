DROP PACKAGE BODY BANINST1.PKG_ACTUALIZACIONES;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_actualizaciones AS
/******************************************************************************
   NAME:       pkg_actualizaciones
   PURPOSE:

   REVISIONS:
   Ver        Date        Author           Description
   ---------  ----------  ---------------  ------------------------------------
   1.0        10/01/2018      vramirlo       1. Created this package body.
******************************************************************************/
--Con esta consulta se llena la tabla de primera vez de SZTACTU
--


--drop view szwactu;
--
--
--create view szwactu as (
--select x.pidm, x.id, x.programa, x.solicitud, x.estatus, x.evento, max (x.SARAPPD_SEQ_NO) secuencia
--from (
--        select saradap_pidm pidm,
--                                    spriden_id id,
--                                    saradap_program_1 programa,
--                                     SARADAP_APPL_NO  SOLICITUD,
--                                --    decode (sarappd_apdc_code, '35', '3', '40', '5', '45', '7') Estatus,
--                                   case
--                                        when sarappd_apdc_code = '35' and SARADAP_APST_CODE = 'A' then 
--                                             '3'
--                                         when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'A' then 
--                                             '5'
--                                        when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'N' then 
--                                             '5'
--                                         when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'X' then 
--                                             '6'
--                                         when sarappd_apdc_code = '45' and SARADAP_APST_CODE = 'A' then 
--                                             '7'
--                                         when sarappd_apdc_code = '45' and SARADAP_APST_CODE = 'X' then 
--                                             '7'
--                                           else 
--                                             '2'
--                                     end Estatus,
--                                    decode (sarappd_apdc_code, '35', '7', '40', '8', '45', '9', null, '7') Evento,
--                                    null,
--                                    null,
--                                    SARAPPD_SEQ_NO
--                             from sarappd a, saradap b , spriden c
--                            where  b.SARADAP_PIDM =  a.SARAPPD_PIDM (+)
--                            and    b.SARADAP_TERM_CODE_ENTRY  = a.SARAPPD_TERM_CODE_ENTRY  (+)
--                            and    b.SARADAP_APPL_NO =  a.SARAPPD_APPL_NO (+)
--                            and c.spriden_pidm = b.saradap_pidm
--                            AND c.spriden_change_ind IS NULL
--                         --  and c.spriden_id = '100083298'
--                            and b.SARADAP_APPL_NO = (select max (b1.SARADAP_APPL_NO)
--                                                                        from SARADAP b1
--                                                                        where b1.saradap_pidm = b.saradap_pidm
--                                                                        and b1.saradap_camp_code = b.saradap_camp_code
--                                                                        and b1.saradap_levl_code = b.saradap_levl_code
--                                                                        and b1.saradap_program_1 = b.saradap_program_1
--                                                                         )
--                           and a.SARAPPD_SEQ_NO  = (select max (a2.SARAPPD_SEQ_NO)
--                                                                        from sarappd a2
--                                                                        where a.SARAPPD_PIDM = a2.SARAPPD_PIDM (+)
--                                                                        and a.SARAPPD_TERM_CODE_ENTRY = a2.SARAPPD_TERM_CODE_ENTRY (+)
--                                                                        and a.SARAPPD_APPL_NO  = a2.SARAPPD_APPL_NO (+) ) 
--        union
--       select saradap_pidm pidm,
--                                    spriden_id id,
--                                    saradap_program_1 programa,
--                                     SARADAP_APPL_NO  SOLICITUD,
--                                --    decode (sarappd_apdc_code, '35', '3', '40', '5', '45', '7') Estatus,
--                                   case
--                                        when sarappd_apdc_code = '35' and SARADAP_APST_CODE = 'A' then 
--                                             '3'
--                                         when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'A' then 
--                                             '5'
--                                        when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'N' then 
--                                             '5'
--                                         when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'X' then 
--                                             '6'
--                                         when sarappd_apdc_code = '45' and SARADAP_APST_CODE = 'A' then 
--                                             '7'
--                                         when sarappd_apdc_code = '45' and SARADAP_APST_CODE = 'X' then 
--                                             '7'
--                                           else 
--                                             '2'
--                                     end Estatus,
--                                    decode (sarappd_apdc_code, '35', '7', '40', '8', '45', '9', null, '7') Evento,
--                                    null,
--                                    null,
--                                    SARAPPD_SEQ_NO
--                             from sarappd a, saradap b , spriden c
--                            where  b.SARADAP_PIDM =  a.SARAPPD_PIDM (+)
--                            and    b.SARADAP_TERM_CODE_ENTRY  = a.SARAPPD_TERM_CODE_ENTRY  (+)
--                            and    b.SARADAP_APPL_NO =  a.SARAPPD_APPL_NO (+)
--                            and c.spriden_pidm = b.saradap_pidm
--                            AND c.spriden_change_ind IS NULL
--                       --   and c.spriden_id = '100083298'
--                            and b.SARADAP_APPL_NO = (select max (b1.SARADAP_APPL_NO)
--                                                                        from SARADAP b1
--                                                                        where b1.saradap_pidm = b.saradap_pidm
--                                                                        and b1.saradap_camp_code = b.saradap_camp_code
--                                                                        and b1.saradap_levl_code = b.saradap_levl_code
--                                                                        and b1.saradap_program_1 = b.saradap_program_1
--                                                                         )
--                           union
--       select saradap_pidm pidm,
--                                    spriden_id id,
--                                    saradap_program_1 programa,
--                                     SARADAP_APPL_NO  SOLICITUD,
--                                --    decode (sarappd_apdc_code, '35', '3', '40', '5', '45', '7') Estatus,
--                                   case
--                                        when sarappd_apdc_code = '35' and SARADAP_APST_CODE = 'A' then 
--                                             '3'
--                                         when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'A' then 
--                                             '5'
--                                        when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'N' then 
--                                             '5'
--                                         when sarappd_apdc_code = '40' and SARADAP_APST_CODE = 'X' then 
--                                             '6'
--                                         when sarappd_apdc_code = '45' and SARADAP_APST_CODE = 'A' then 
--                                             '7'
--                                         when sarappd_apdc_code = '45' and SARADAP_APST_CODE = 'X' then 
--                                             '7'
--                                           else 
--                                             '2'
--                                     end Estatus,
--                                    decode (sarappd_apdc_code, '35', '7', '40', '8', '45', '9', null, '7') Evento,
--                                    null,
--                                    null,
--                                    SARAPPD_SEQ_NO
--                             from sarappd a, saradap b , spriden c
--                            where  b.SARADAP_PIDM =  a.SARAPPD_PIDM (+)
--                            and    b.SARADAP_TERM_CODE_ENTRY  = a.SARAPPD_TERM_CODE_ENTRY  (+)
--                            and    b.SARADAP_APPL_NO =  a.SARAPPD_APPL_NO (+)
--                            and c.spriden_pidm = b.saradap_pidm
--                            AND c.spriden_change_ind IS NULL
--                          --and c.spriden_id = '100083298'  
--                   )x    
--                   group by x.pidm, x.id, x.programa, x.solicitud, x.estatus, x.evento           )  ;
--                   
--                   
--                     
--                   
--delete sztactu;
--commit;
--
--
--insert into sztactu  
--                 select pidm, id, programa, solicitud, estatus, evento, null, null 
--from szwactu a
--where  a.SECUENCIA = (select max (a1.SECUENCIA)
--                                   from  szwactu a1
--                                    where a.PIDM = a1.PIDM
--                                   and   a.PROGRAMA = a1.PROGRAMA
--                                   and   a.SOLICITUD = a1.SOLICITUD)
--order by 2, 3, 4     ;
--
--Commit;                                 


FUNCTION f_actualiza_solicitud_out  RETURN pkg_actualizaciones.cursor_out
                AS
           c_out pkg_actualizaciones.cursor_out;
           
     Begin
                open c_out            
                      FOR   
                            Select x.pidm, x.id, x.programa, x.solicitud, x.estatus, x.evento
                            from (
                             select DISTINCT PIDM,
                                                       ID,
                                                       PROGRAMA,
                                                       SOLICITUD,
                                                       ESTATUS,
                                                       EVENTO,
                                                       nvl(FECHA_REGISTRO, sysdate)
                                                       from SZTACTU
                                                       where 1= 1 
                                                   --    And pidm in (225301)
                                                       And procesado is null
                                                        order by 2, 3, 4,7 asc
                            ) x  ;
                     RETURN (c_out);   
     
     
     End f_actualiza_solicitud_out;
     
     

Procedure  p_actualiza_registro  (vn_pidm in number, vl_matricula in varchar2, vl_programa in varchar2, vn_secuencia number , vl_estatus varchar2, vl_evento varchar2, vl_resultado varchar2, vl_observaciones varchar2)

    As
    
    Begin
            Begin
                Update SZTACTU
                    set PROCESADO = vl_resultado, 
                     OBSERVACIONES = vl_observaciones
                where PIDM = vn_pidm
                and ID = vl_matricula
                and PROGRAMA = vl_programa
                and SOLICITUD = vn_secuencia
                and ESTATUS = vl_estatus
                and EVENTO = vl_evento;
                
                Commit;
            Exception
                when Others then 
                  null;
            End;
             
            commit;   
    
    End p_actualiza_registro;      



    
    
        FUNCTION f_actualiza_solicitud_alumno RETURN pkg_actualizaciones.cursor_alumno
                AS
           c_alu pkg_actualizaciones.cursor_alumno;
           
     Begin
                OPEN c_alu            
                
                      FOR   
                           SELECT DISTINCT sztbima_pidm Pidm,
                                                        sztbima_first_name  First_Name,     
                                                        sztbima_last_name Last_Name,
                                                        sztbima_proceso  Proceso,     
                                                        sztbima_estatus  Estatus,
                                                        sztbima_observaciones Observaciones,
                                                        sztbima_id Id,          
                                                        sztbima_email_address  Email,
                                                        sztbima_additional_id  Referencia_Bancaria,
                                                        sztbima_birth_date Fecha_Nacimiento,
                                                        sztbima_sex         Sexo
                            FROM sztbima
                            WHERE 1 = 1
                            AND  sztbima_estatus IS NULL
                            ORDER BY 2, 3, 4;
                            
                     RETURN (c_alu);   
          
     End f_actualiza_solicitud_alumno;
     
     Procedure  p_actualiza_alumno  (p_pidm in number, p_matricula in varchar2,p_proceso in varchar2,p_estatus in varchar2,p_observaciones in varchar2)
       As
       
    BEGIN

        IF p_proceso = 'SPRIDEN' THEN

            BEGIN
                        
                UPDATE sztbima SET sztbima_estatus = p_estatus, 
                                                  sztbima_observaciones = p_observaciones
                 WHERE 1 = 1
                 AND sztbima_pidm = p_pidm
                 AND sztbima_id = p_matricula;
                 
            EXCEPTION
                WHEN OTHERS THEN
                null;
                  --  DBMS_OUTPUT.PUT_LINE('Error al actualizar   tabla de paso con valor SPRIDEN  ');
                    raise_application_error (-20002,'Error al actualizar   tabla de paso con valor SPRIDEN  '|| SQLCODE||' Error: '||SQLERRM);
            END;
            
            COMMIT;
        END IF;
        
        IF p_proceso ='GORADID' THEN      

             BEGIN
                             
                  UPDATE sztbima SET sztbima_estatus = p_estatus,
                                                    sztbima_observaciones = p_observaciones
                 WHERE 1 = 1
                 AND sztbima_pidm = p_pidm
                 AND sztbima_id = p_matricula;
                 
            EXCEPTION
                WHEN OTHERS THEN
                null;
                    --DBMS_OUTPUT.PUT_LINE('Error al actualizar   tabla de paso con valor GORADID  ');
                    raise_application_error (-20002,'Error al actualizar   tabla de paso con valor GORADID  '|| SQLCODE||' Error: '||SQLERRM);
            END;
            
            COMMIT;        
        END IF;
     
        IF p_proceso ='GOREMAL' THEN      

            BEGIN
                
                 UPDATE sztbima SET sztbima_estatus = p_estatus,
                                                 sztbima_observaciones = p_observaciones
                 WHERE 1 = 1
                 AND sztbima_pidm = p_pidm
                 AND sztbima_id = p_matricula;
                 
            EXCEPTION
                WHEN OTHERS THEN
                null;
                    --DBMS_OUTPUT.PUT_LINE('Error al actualizar   tabla de paso con valor GOREMAL  ');
                    raise_application_error (-20002,'Error al actualizar   tabla de paso con valor GOREMAL  '|| SQLCODE||' Error: '||SQLERRM);
            END;
            
            COMMIT;  
        END IF;
        
        IF p_proceso ='SPBPERS' THEN      
                
            BEGIN

                 UPDATE sztbima SET sztbima_estatus = p_estatus,
                                                sztbima_observaciones = p_observaciones
                 WHERE 1 = 1
                 AND sztbima_pidm = p_pidm
                 AND sztbima_id = p_matricula; 
            EXCEPTION
                WHEN OTHERS THEN
                null;
                    --DBMS_OUTPUT.PUT_LINE('Error al actualizar   tabla de paso con valor SPBPERS  ');
                    raise_application_error (-20002,'Error al actualizar   tabla de paso con valor SPBPERS  '|| SQLCODE||' Error: '||SQLERRM);
            END;
           
            COMMIT;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
        null;
            ---DBMS_OUTPUT.PUT_LINE('Error al actualizar  valores de tabla de paso ');
            raise_application_error (-20002,'Error al actualizar  valores de tabla de paso  '|| SQLCODE||' Error: '||SQLERRM);
    END;

END pkg_actualizaciones;
/

DROP PUBLIC SYNONYM PKG_ACTUALIZACIONES;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ACTUALIZACIONES FOR BANINST1.PKG_ACTUALIZACIONES;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_ACTUALIZACIONES TO PUBLIC;
