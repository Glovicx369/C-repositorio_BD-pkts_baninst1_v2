DROP PACKAGE BODY BANINST1.PKG_FUNCIONALIDAD_ALGO;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_funcionalidad_algo
as
    procedure p_replica_utel (p_campus varchar2,
                              p_codigo_campus varchar2,
                              p_regla  number)
    is
    
    VL_NIVEL VARCHAR(2);
    
    begin
        
    
     FOR C IN 
        (       
        SELECT SZTALGO_CAMP_CODE campus,
               SZTALGO_LEVL_CODE nivel,
               SUBSTR(SZTALGO_TERM_CODE,3,5) TERM_CODE,
               SZTALGO_PTRM_CODE,
               SZTALGO_TIPO_CARGA,
               SZTALGO_FECHA_ANT,
               SZTALGO_FECHA_NEW,
               SZTALGO_PTRM_CODE_NEW,
               SUBSTR(SZTALGO_TERM_CODE_NEW,3,5) TERM_CODE_NEW,
               SZTALGO_NO_REGLA,
               SZTALGO_ESTATUS_CERRADO,
               SZTALGO_USUARIO,
               SZTALGO_TOPE_ALUMNOS,
               SZTALGO_SOBRECUPO_ALUMNOS,
               SZTALGO_ANTICIPADO,
               SZTALGO_FECHA_INSERTO,
               SZTALGO_FECHA_INICIO_INSC,
               SZTALGO_FECHA_FIN_INSC
            from sztalgo
            where 1 = 1
            and sztalgo_no_regla =p_regla
            and SZTALGO_CAMP_CODE='UTL'
            
            )
            
        loop    
        
            IF p_codigo_campus='02' THEN
             
                VL_NIVEL:='MS';
                
            else
            
                VL_NIVEL:= c.nivel;
                -- para todo lo que no sea uts
            END IF;  
          
             INSERT INTO SZTALGO 
             values(          
               p_campus,
               VL_nivel,
               p_codigo_campus||c.TERM_CODE,
               c.SZTALGO_PTRM_CODE,
               c.SZTALGO_TIPO_CARGA,
               c.SZTALGO_FECHA_ANT,
               c.SZTALGO_FECHA_NEW,
               c.SZTALGO_PTRM_CODE_NEW,
               p_codigo_campus||c.TERM_CODE_NEW,
               c.SZTALGO_NO_REGLA,
               c.SZTALGO_ESTATUS_CERRADO,
               user,
               c.SZTALGO_TOPE_ALUMNOS,
               c.SZTALGO_SOBRECUPO_ALUMNOS,
               c.SZTALGO_ANTICIPADO,
               sysdate,
               c.SZTALGO_FECHA_INICIO_INSC,
               c.SZTALGO_FECHA_FIN_INSC
               );
                                    
           COMMIT; 
    
        end loop;
          
    end;
      
    /*
        
    */   
END;
/
