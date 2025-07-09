DROP PACKAGE BODY BANINST1.PKG_MATRICULAS_SEP;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_matriculas_sep
AS
    function f_carga_masivo
    return varchar2
    is
    l_retorna varchar2(100):='EXITO';
    
    begin
    
        delete SZTMSEP;

    for c in (select pa.*,
                    (select distinct spriden_pidm
                     from spriden
                     where 1 = 1
                     and spriden_change_ind is null
                     and spriden_id = pa.SZTMSEP_ID ) pidm
              from SZTMSEP_paso pa
              )loop
              
                begin
                    insert into SZTMSEP values(c.pidm,
                                               c.SZTMSEP_ID,
                                               c.SZTMSEP_ID_SEP,
                                               'N',
                                               NULL,
                                               SYSDATE,
                                               USER);   
                                                      
                exception when others then
                    l_retorna:='Error en '||sqlerrm;
                end;                                               
                
              end loop;
              
              COMMIT;
        
              return(l_retorna);
    
    end;
--
--    
    function f_matriculas_sep
    return varchar2
    IS 
        vl_existe number:= 0;
        vl_return varchar2(500) :='Exito';

   BEGIN
   
        FOR c in (SELECT SZTMSEP_PIDM pidm, SZTMSEP_ID_SEP msep
                  FROM SZTMSEP
                  WHERE 1=1
                 --- AND SZTMSEP_PIDM = 248276
                  )
        loop

          BEGIN      
            SELECT COUNT(GORADID_PIDM)
                    into vl_existe
                    FROM
                    GORADID
                    WHERE 1=1
                    AND GORADID_PIDM = c.pidm --66699
                    AND GORADID_ADID_CODE = 'MSEP';
          END;


          DBMS_OUTPUT.PUT_LINE('Valor de : '||vl_existe);
          
         BEGIN
               
            IF vl_existe = 1 THEN
                
               BEGIN
                    UPDATE SZTMSEP SET SZTMSEP_PROCESADO = 'N', SZTMSEP_DESC1 = 'El alumno ya cuenta con matricula SEP', 
                    SZTMSEP_FECHA_INSERTO = SYSDATE, SZTMSEP_USUARIO_INSERTO = USER
                    WHERE 1=1
                    AND SZTMSEP_PIDM = c.pidm; -- 66699
                EXCEPTION WHEN OTHERS THEN 
                NULL;
               END;
               
              DBMS_OUTPUT.PUT_LINE('Existe: '||vl_existe);
                    
            ELSIF vl_existe = 0 THEN
            
                BEGIN
                INSERT INTO GORADID 
                            (GORADID_PIDM,
                            GORADID_ADDITIONAL_ID,
                            GORADID_ADID_CODE,
                            GORADID_USER_ID,
                            GORADID_ACTIVITY_DATE,
                            GORADID_DATA_ORIGIN,
                            GORADID_SURROGATE_ID,
                            GORADID_VERSION,
                            GORADID_VPDI_CODE) 
                          VALUES
                            (c.pidm,
                             c.msep,
                            'MSEP',
                            USER,
                            SYSDATE,
                            'Banner',
                            NULL,
                            0,
                            NULL);
                EXCEPTION WHEN OTHERS THEN
                vl_return:= 'Error al inserta en GORADID'||sqlerrm;
                END;
            
                
                BEGIN
                    
                    UPDATE SZTMSEP SET SZTMSEP_PROCESADO = 'Y', SZTMSEP_DESC1 = 'Registro de matrícula exitoso', 
                    SZTMSEP_FECHA_INSERTO = SYSDATE, SZTMSEP_USUARIO_INSERTO = USER
                    WHERE 1=1
                    AND SZTMSEP_PIDM = c.pidm; -- 66699
                    
                EXCEPTION WHEN OTHERS THEN 
                NULL;    
                END;
               
                DBMS_OUTPUT.PUT_LINE('No existe: '||vl_existe);
                
            END IF;
         END;
       END LOOP;
        COMMIT;
        return(vl_return);
    END;
    
--
--

  FUNCTION f_procesa
  RETURN VARCHAR2

  IS 
        vl_existe number:= 0;
        vl_return varchar2(500) :='Exito';

   BEGIN
   
        FOR c in (SELECT SZTMSEP_PIDM pidm, SZTMSEP_ID_SEP msep
                  FROM SZTMSEP
                  WHERE 1=1
                 --- AND SZTMSEP_PIDM = 248276
                  )
        loop

          BEGIN      
            SELECT COUNT(GORADID_PIDM)
                    into vl_existe
                    FROM
                    GORADID
                    WHERE 1=1
                    AND GORADID_PIDM = c.pidm --66699
                    AND GORADID_ADID_CODE = 'MSEP';
          END;


          DBMS_OUTPUT.PUT_LINE('Valor de : '||vl_existe);
          
         BEGIN
               
            IF vl_existe = 1 THEN
                
               BEGIN
                    UPDATE SZTMSEP SET SZTMSEP_PROCESADO = 'N', SZTMSEP_DESC1 = 'El alumno ya cuenta con matricula SEP', 
                    SZTMSEP_FECHA_INSERTO = SYSDATE, SZTMSEP_USUARIO_INSERTO = USER
                    WHERE 1=1
                    AND SZTMSEP_PIDM = c.pidm; -- 66699
                EXCEPTION WHEN OTHERS THEN 
                NULL;
               END;
               
              DBMS_OUTPUT.PUT_LINE('Existe: '||vl_existe);
                    
            ELSIF vl_existe = 0 THEN
            
                BEGIN
                INSERT INTO GORADID 
                            (GORADID_PIDM,
                            GORADID_ADDITIONAL_ID,
                            GORADID_ADID_CODE,
                            GORADID_USER_ID,
                            GORADID_ACTIVITY_DATE,
                            GORADID_DATA_ORIGIN,
                            GORADID_SURROGATE_ID,
                            GORADID_VERSION,
                            GORADID_VPDI_CODE) 
                          VALUES
                            (c.pidm,
                             c.msep,
                            'MSEP',
                            USER,
                            SYSDATE,
                            'Banner',
                            NULL,
                            0,
                            NULL);
                EXCEPTION WHEN OTHERS THEN
                vl_return:= 'Error al inserta en GORADID'||sqlerrm;
                END;
            
                
                BEGIN
                    
                    UPDATE SZTMSEP SET SZTMSEP_PROCESADO = 'Y', SZTMSEP_DESC1 = 'Registro de matrícula exitoso', 
                    SZTMSEP_FECHA_INSERTO = SYSDATE, SZTMSEP_USUARIO_INSERTO = USER
                    WHERE 1=1
                    AND SZTMSEP_PIDM = c.pidm; -- 66699
                    
                EXCEPTION WHEN OTHERS THEN 
                NULL;    
                END;
               
                DBMS_OUTPUT.PUT_LINE('No existe: '||vl_existe);
                
            END IF;
         END;
       END LOOP;
        COMMIT;
        return(vl_return);
    END;
    
end;
/

DROP PUBLIC SYNONYM PKG_MATRICULAS_SEP;

CREATE OR REPLACE PUBLIC SYNONYM PKG_MATRICULAS_SEP FOR BANINST1.PKG_MATRICULAS_SEP;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_MATRICULAS_SEP TO PUBLIC;
