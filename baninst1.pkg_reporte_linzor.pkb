DROP PACKAGE BODY BANINST1.PKG_REPORTE_LINZOR;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_reporte_linzor
IS 
    FUNCTION f_alumnos_ventas(p_campus       VARCHAR2,
                              p_nivel        VARCHAR2,
                              p_programa     VARCHAR2,
                              p_tipo_alumno  VARCHAR2,
                              p_pidm         NUMBER,
                              p_correo       VARCHAR2,
                              p_mes_venta    VARCHAR2,
                              p_mes_pago     VARCHAR2                           
                               ) RETURN VARCHAR2
    IS                     
        l_retorna   VARCHAR2(100):='EXITO';  
        l_mes_pago  VARCHAR2(20);
        l_mes_venta VARCHAR2(20);
        l_nombre    VARCHAR2(100);
        l_linzor    VARCHAR2(20);
        l_id        VARCHAR2(9);      
        l_ejercicio NUMBER;         
        l_contar    NUMBER;
    BEGIN
    
        BEGIN
            SELECT COUNT(*)
            INTO l_contar
            FROM spriden
            WHERE 1 = 1
            AND spriden_change_ind IS NULL
            AND spriden_pidm = p_pidm;
            
        EXCEPTION WHEN OTHERS THEN        
            l_contar:=0;
        END;    
        
        IF l_contar > 0 THEN    
    
            BEGIN

                SELECT SUBSTR(p_mes_pago,5,2)||SUBSTR(p_mes_pago,1,4) dato
                INTO l_mes_pago
                FROM dual;

            EXCEPTION WHEN OTHERS THEN
                l_mes_pago:=NULL;
                l_retorna:='Error al obtener el mes '||SQLERRM;
            END;
            
            BEGIN

                SELECT (TO_CHAR(TO_DATE(p_mes_venta),'MMYYYY')) dato
                INTO l_mes_venta
                FROM dual;

            EXCEPTION WHEN OTHERS THEN
                l_mes_pago:=NULL;
                l_retorna:='Error al obtener el mes '||SQLERRM;
            END;
            
            BEGIN

                SELECT SUBSTR(p_mes_pago,1,4)dato
                INTO l_ejercicio
                FROM dual;

            EXCEPTION WHEN OTHERS THEN
                l_ejercicio:=NULL;
                l_retorna:='Error al obtener el mes '||SQLERRM;
            END;
            
        
            BEGIN

                SELECT spriden_last_name||spriden_first_name
                INTO l_nombre
                FROM spriden
                WHERE 1 = 1
                AND spriden_change_ind IS NULL
                AND spriden_pidm = p_pidm;

            EXCEPTION WHEN OTHERS THEN
                l_nombre:=NULL;
                l_retorna:='Error al obtener el nombre '||SQLERRM;
            END;
        
            BEGIN

                SELECT SPRIDEN_id
                INTO l_id
                FROM spriden
                WHERE 1 = 1
                AND spriden_change_ind IS NULL
                AND spriden_pidm = p_pidm;

            EXCEPTION WHEN OTHERS THEN
                l_nombre:=NULL;
                l_retorna:='Error al obtener la matricula '||SQLERRM;
            END;
            
            IF  p_tipo_alumno = 'Reingreso' THEN                 
                 
                IF  l_mes_pago = l_mes_venta THEN
                
                    l_linzor:='Reingreso'||TO_NUMBER(SUBSTR(l_mes_pago,1,2));
                
                ELSIF   l_mes_pago <> l_mes_venta then
                
                    l_linzor:='Reingresofuturo'||TO_NUMBER(SUBSTR(l_mes_pago,1,2));
                    
                end if;
                
            ELSIF p_tipo_alumno = 'Pmatricular' THEN     
            
                IF  l_mes_pago = l_mes_venta THEN
                
                    l_linzor:='PmatricularN'||TO_NUMBER(SUBSTR(l_mes_pago,1,2));
                
                ELSIF   l_mes_pago <> l_mes_venta then
                
                    l_linzor:='PmatricularF'||TO_NUMBER(SUBSTR(l_mes_pago,1,2));
                    
                end if;
                
            ELSIF p_tipo_alumno = 'Nuevo Ingreso' THEN       
            
                IF  l_mes_pago = l_mes_venta THEN
                
                    l_linzor:='Inician'||TO_NUMBER(SUBSTR(l_mes_pago,1,2));
                
                ELSIF   l_mes_pago <> l_mes_venta then
                
                    l_linzor:='Futuro'||TO_NUMBER(SUBSTR(l_mes_pago,1,2));
                    
                END IF;   
                 
            END IF;
            
            BEGIN

                INSERT INTO sztbase_v2 (campus, 
                                        nivel,
                                        programa,
                                        mes_venta, 
                                        mes_pago,
                                        correo,
                                        mes,
                                        nombre,
                                        linzor,
                                        matricula_banner, 
                                        pidm,
                                        ejercicio,
                                        tipo_alumno,
                                        fecha_inserto)
                                        VALUES
                                        (
                                        p_campus,  
                                        p_nivel,   
                                        p_programa,
                                        '01'||SUBSTR(p_mes_venta,3,9),
                                        '01'||SUBSTR(p_mes_pago,3,9),
                                        p_correo,
                                        l_mes_pago,
                                        l_nombre,
                                        l_linzor,
                                        l_id,
                                        p_pidm,
                                        l_ejercicio,
                                        p_tipo_alumno,
                                        SYSDATE
                                        );
                                    
            EXCEPTION WHEN OTHERS THEN
                l_retorna:='Error al insertar en tabla  '||SQLERRM;
               -- RETURN(l_retorna);
            END;                                
                                    
            COMMIT;      
        
            RETURN(l_retorna);
            
        ELSE
         
         l_retorna:='No existe este pidm '||p_pidm;
         
         RETURN(l_retorna);
         
        END IF;
           
    END;                                
  
END pkg_reporte_linzor;
/

DROP PUBLIC SYNONYM PKG_REPORTE_LINZOR;

CREATE OR REPLACE PUBLIC SYNONYM PKG_REPORTE_LINZOR FOR BANINST1.PKG_REPORTE_LINZOR;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_REPORTE_LINZOR TO PUBLIC;
