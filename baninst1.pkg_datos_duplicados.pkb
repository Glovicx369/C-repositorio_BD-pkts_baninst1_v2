DROP PACKAGE BODY BANINST1.PKG_DATOS_DUPLICADOS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_DATOS_DUPLICADOS AS
   /******************************************************************************
      NAME:       BANINST1.PKG_DATOS_DUPLICADOS
      PURPOSE:

      REVISIONS:
      Ver        Date        Author           Description
      ---------  ----------  ---------------  ------------------------------------
      1.0        14/04/2025      GOLVERA       1. Created this package.
	  1.1        02/06/2025      GOLVERA       1.1 Se agrega condición 
												   SPRIDEN_CHANGE_IND is null
   ******************************************************************************/
--
--
FUNCTION f_valida_curp_dni (p_curp in varchar2 default null, p_dni in varchar2 default null,p_campus in varchar2 default null) RETURN SYS_REFCURSOR is

    ln_existe_curp NUMBER;
    ln_existe_dni NUMBER;
    lv_error   VARCHAR2(2000);
    Vm_Registros SYS_REFCURSOR;
    lv_campus   VARCHAR2(5);
   

BEGIN

    IF p_curp is not null then 
    
        IF p_Campus is null then                     
         select COUNT(1)
                into ln_existe_curp
                from GORADID A
                where A.GORADID_ADID_CODE = 'CURP'
                and A.GORADID_ADDITIONAL_ID = p_curp;


                if ln_existe_curp > 0 then 

                       
                    OPEN Vm_Registros FOR 
                    SELECT    (SELECT g.SZVCAMP_CAMP_CODE
                                 FROM SZVCAMp g, GORADID f
                                WHERE     g.SZVCAMP_CAMP_ALT_CODE = f.GORADID_ADDITIONAL_ID
                                      AND f.GORADID_ADID_CODE = 'CAMP'
                                      AND f.GORADID_PIDM = a.spriden_pidm)
                           || ' '
                           || a.spriden_id
                           || ' '
                           || TRIM (a.SPRIDEN_FIRST_NAME)
                           || ' '
                           || TRIM (REPLACE (a.SPRIDEN_LAST_NAME, '/', ' '))
                              respuesta,
                           a.spriden_id matricula
                      FROM spriden a, GORADID b
                     WHERE     a.spriden_pidm = b.GORADID_PIDM
                           AND b.GORADID_ADID_CODE = 'CURP'
                           AND b.GORADID_ADDITIONAL_ID= p_curp 
                           and a.SPRIDEN_CHANGE_IND is null ; 
                                     
                     RETURN Vm_Registros;                   


                ELSE
                    OPEN Vm_Registros FOR 
                               select 'EXITO' as respuesta , 'N/A' matricula from dual ;            
                               
                     
                     RETURN Vm_Registros;                         
                end if ;
        ELSE

        SELECT SZVCAMP_CAMP_ALT_CODE
          INTO lv_campus
          FROM SZVCAMP
         WHERE SZVCAMP_CAMP_CODE = p_campus;

        SELECT COUNT (1)
          INTO ln_existe_curp
          FROM GORADID A
         WHERE     A.GORADID_ADID_CODE = 'CURP'
               AND A.GORADID_ADDITIONAL_ID = p_curp
               AND EXISTS
                      (SELECT 1
                         FROM GORADID b
                        WHERE     b.GORADID_ADID_CODE = 'CAMP'
                              AND b.GORADID_PIDM = a.GORADID_PIDM
                              AND b.GORADID_ADDITIONAL_ID = lv_campus);

                if ln_existe_curp > 0 then 

                       
                    OPEN Vm_Registros FOR 
                SELECT    (SELECT g.SZVCAMP_CAMP_CODE
                             FROM SZVCAMp g, GORADID f
                            WHERE     g.SZVCAMP_CAMP_ALT_CODE = f.GORADID_ADDITIONAL_ID
                                  AND f.GORADID_ADID_CODE = 'CAMP'
                                  AND f.GORADID_PIDM = a.spriden_pidm)
                       || ' '
                       || a.spriden_id
                       || ' '
                       || TRIM (a.SPRIDEN_FIRST_NAME)
                       || ' '
                       || TRIM (REPLACE (a.SPRIDEN_LAST_NAME, '/', ' '))
                          respuesta,
                       a.spriden_id matricula
                  FROM spriden a, GORADID b, GORADID c
                 WHERE     a.spriden_pidm = b.GORADID_PIDM
                       AND c.GORADID_PIDM = b.GORADID_PIDM
                       AND b.GORADID_ADID_CODE = 'CURP'
                       AND b.GORADID_ADDITIONAL_ID= p_curp  
                       AND c.GORADID_ADID_CODE = 'CAMP'
                       AND c.GORADID_ADDITIONAL_ID = lv_campus
                       AND a.SPRIDEN_CHANGE_IND is null ; 
                                     
                     RETURN Vm_Registros;                   


                ELSE
                    OPEN Vm_Registros FOR 
                               select 'EXITO' as respuesta , 'N/A' matricula from dual ;            
                               
                     
                     RETURN Vm_Registros;                         
                end if ;    
        END IF;
    
    ELSIF p_dni is not null THEN 
    DBMS_OUTPUT.PUT_LINE('DNI NO NULL');
        IF p_Campus is null THEN 
        SELECT count(1)
         into ln_existe_dni
        FROM Spbpers 
        WHERE spbpers_ssn =p_dni ;
        
            if ln_existe_dni > 0 then 

                OPEN Vm_Registros FOR 
                SELECT    (SELECT g.SZVCAMP_CAMP_CODE
                             FROM SZVCAMp g, GORADID f
                            WHERE     g.SZVCAMP_CAMP_ALT_CODE = f.GORADID_ADDITIONAL_ID
                                  AND f.GORADID_ADID_CODE = 'CAMP'
                                  AND f.GORADID_PIDM = a.spriden_pidm)
                       || ' '||a.spriden_id||' / '||
                                        trim(a.SPRIDEN_FIRST_NAME)||' '||trim(REPLACE(a.SPRIDEN_LAST_NAME,'/',' ')) respuesta 
                                        ,a.spriden_id matricula
                                        from spriden a , SPBPERS b
                                        where a.spriden_pidm =b.SPBPERS_PIDM
                                        and  b.spbpers_ssn = p_dni 
                                        and a.SPRIDEN_CHANGE_IND is null ;                    
                 
                 RETURN Vm_Registros;                   


            ELSE
                OPEN Vm_Registros FOR 
                           select 'EXITO' as respuesta , 'N/A' matricula from dual ;   
                     RETURN Vm_Registros;                   

            end if ;
            
        ELSE
        
        SELECT SZVCAMP_CAMP_ALT_CODE
          INTO lv_campus
          FROM SZVCAMP
         WHERE SZVCAMP_CAMP_CODE = p_campus;
                 
        SELECT COUNT (1)
          INTO ln_existe_dni
          FROM Spbpers a
         WHERE     a.spbpers_ssn = p_dni
               AND EXISTS
                      (SELECT 1
                         FROM GORADID b
                        WHERE     b.GORADID_ADID_CODE = 'CAMP'
                              AND b.GORADID_PIDM = a.SPBPERS_PIDM
                              AND b.GORADID_ADDITIONAL_ID = lv_campus);   
                
            if ln_existe_dni > 0 then 

                OPEN Vm_Registros FOR 
                SELECT    (SELECT g.SZVCAMP_CAMP_CODE
                             FROM SZVCAMp g, GORADID f
                            WHERE     g.SZVCAMP_CAMP_ALT_CODE = f.GORADID_ADDITIONAL_ID
                                  AND f.GORADID_ADID_CODE = 'CAMP'
                                  AND f.GORADID_PIDM = a.spriden_pidm)
                       || ' '||a.spriden_id||' / '||
                                        trim(a.SPRIDEN_FIRST_NAME)||' '||trim(REPLACE(a.SPRIDEN_LAST_NAME,'/',' ')) respuesta 
                                        ,a.spriden_id matricula
                                        from spriden a , SPBPERS b,GORADID c 
                                        where a.spriden_pidm =b.SPBPERS_PIDM
                                        and c.GORADID_PIDM = b.SPBPERS_PIDM
                                        and  b.spbpers_ssn = p_dni 
                                        AND c.GORADID_ADID_CODE = 'CAMP'
                                        AND c.GORADID_ADDITIONAL_ID = lv_campus 
                                        and a.SPRIDEN_CHANGE_IND is null;            
                                    
                           
                 
                 RETURN Vm_Registros;                   


            ELSE
                OPEN Vm_Registros FOR 
                           select 'EXITO' as respuesta , 'N/A' matricula from dual ;   
                     RETURN Vm_Registros;                   

            end if ;          
        END IF;          
    END IF;   
    
EXCEPTION WHEN OTHERS THEN 
lv_error := 'ERROR : '||sqlerrm;
END f_valida_curp_dni;
  

--
--

    FUNCTION f_valida_mail (p_email in varchar2 default null) return VARCHAR2 IS
    
    lv_respuesta VARCHAR2(400);
    lv_pidm VARCHAR2(20);
    lv_matricula VARCHAR2(50);
    lv_nombre VARCHAR2(2000);
    ln_existe_email NUMBER;
    
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

    END IF;
        RETURN (lv_respuesta);
    EXCEPTION WHEN OTHERS THEN 
    lv_respuesta := 'ERROR : '||sqlerrm;
    RETURN (lv_respuesta);
    END f_valida_mail;
   
END PKG_DATOS_DUPLICADOS;
/

DROP PUBLIC SYNONYM PKG_DATOS_DUPLICADOS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_DATOS_DUPLICADOS FOR BANINST1.PKG_DATOS_DUPLICADOS;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_DATOS_DUPLICADOS TO PUBLIC;
