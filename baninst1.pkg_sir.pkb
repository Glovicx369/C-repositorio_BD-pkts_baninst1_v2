DROP PACKAGE BODY BANINST1.PKG_SIR;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_sir is

FUNCTION f_reporte_equivalencia(p_num_univ varchar2,
                                    p_carrera   varchar2,
                                    p_materia_ext varchar2,
                                    p_desc_materia_ext varchar2,
                                    p_materia_banner varchar2,
                                    p_usuario varchar2,
                                    p_fecha_de_acti varchar2,
                                    p_estatus varchar2,
                                    p_usuario_des varchar2
                                    )
                     RETURN VARCHAR2 
    IS 
     L_RETORNA    VARCHAR2(100):='EXITO';
     l_cont       number;
    BEGIN
       BEGIN
        
            SELECT COUNT(*)
            INTO l_cont
            FROM sztequv
            WHERE 1 = 1
            AND sztequv_num_univ=p_num_univ
            AND SZTEQUV_DES_PROGRAMA=p_carrera
            AND sztequv_materia_ext= p_materia_ext 
            AND sztequv_materia_banner=p_materia_banner
--            AND sztequv_usuario=p_usuario
--            AND sztequv_fecha_de_acti=p_fecha_de_acti
--            AND SZTEQUV_ESTATUS=p_estatus;
                     ;
        EXCEPTION WHEN OTHERS THEN
            l_cont:=0;
        END;
        
        IF l_cont>0 THEN
           
               BEGIN                  
               
                  UPDATE sztequv SET
                  SZTEQUV_ESTATUS =p_estatus,
                  SZTEQUV_DESCRIP_USU=p_usuario_des
                  where 1=1
                   AND sztequv_num_univ=p_num_univ
                   AND SZTEQUV_DES_PROGRAMA=p_carrera
                   AND sztequv_materia_ext= p_materia_ext 
                   AND sztequv_materia_banner=p_materia_banner;        
                   
                 EXCEPTION WHEN OTHERS THEN
                      dbms_output.put_line('YA EXISTE '||p_num_univ||' '||SQLERRM);  
                 END;   
        L_RETORNA:=('Si existe el num_universidad  '||p_num_univ||' En Equivalencia ');   
         
        ELSIF l_cont=0 then 
      
        BEGIN 
        
         INSERT INTO sztequv (sztequv_num_univ,
                               sztequv_des_programa,
                               sztequv_materia_ext,
                               sztequv_desc_materia_ext,
                               sztequv_materia_banner,
                               sztequv_desc_materia_banner,
                               sztequv_usuario,
                               sztequv_fecha_de_acti,
                               sztequv_estatus,
                               SZTEQUV_DESCRIP_USU)
         SELECT p_num_univ num_univ,
                p_carrera carrera,
                p_materia_ext materia_ext ,
                p_desc_materia_ext desc_materia_ext ,
                p_materia_banner materia_banner,
                (SELECT  SCRSYLN_LONG_COURSE_TITLE 
                    FROM  SCRSYLN
                    WHERE     1 = 1
                  AND SCRSYLN_SUBJ_CODE || SCRSYLN_CRSE_NUMB = p_materia_banner)DESC_MATERIA_BANNER,
                p_usuario usuario ,
                p_fecha_de_acti fecha_de_acti,
                p_estatus estatus,
                p_usuario_des descrip_usu
           FROM dual;
           
         EXCEPTION WHEN OTHERS THEN
              dbms_output.put_line('Error se encontro mas de un pidm '||p_num_univ||' '||SQLERRM);  
         END;               
        END IF;      
        COMMIT; 
       RETURN (L_RETORNA); 
    END;
--
--
    PROCEDURE p_llena_vetas(p_pidm number,
                            p_mes  varchar2)
    is
        l_contar        number;
        l_cuenta_existe number;
    BEGIN
    
        --INSERTAR PARTE DE VENTAS
        
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
            
                dbms_output.put_line('Si existe el pidm  '||p_pidm||' En Spaiden ');    
            
                BEGIN
                
                    SELECT COUNT(*)
                    INTO l_cuenta_existe
                    FROM sztlins
                    WHERE 1 = 1
                    AND sztlins_pidm = p_pidm
                    AND sztlins_mes_venta =p_mes; 
                
                
                EXCEPTION WHEN OTHERS THEN
                    l_cuenta_existe:=0;
                END;
                
                IF l_cuenta_existe = 0 THEN
                    
                    BEGIN
                    
                        INSERT INTO sztlins (sztlins_pidm, 
                                             sztlins_matricula, 
                                             sztlins_mes_venta, 
                                             sztlins_nombre, 
                                             sztlins_correo)        
                        SELECT p_pidm pidm,
                               (SELECT spriden_id
                                FROM spriden
                                WHERE 1 = 1
                                AND spriden_change_ind is null
                                AND spriden_pidm = p_pidm) matricula,
                                TO_CHAR(TO_DATE(p_mes,'MM-YYYY'),'MM-YYYY') mes_venta,
                               (SELECT spriden_last_name||' '||spriden_first_name
                               FROM spriden
                               WHERE 1 = 1
                               AND spriden_change_ind is null
                               AND spriden_pidm = p_pidm) nombre,
                               (SELECT goremal_email_address
                                FROM goremal pac
                                WHERE 1 = 1
                                AND goremal_emal_code ='PRIN'
                                AND goremal_pidm= p_pidm)correo
                           FROM dual;
                           
                            dbms_output.put_line('Insrsicón exitos '||p_pidm);  
                           
                    EXCEPTION WHEN OTHERS THEN
                      dbms_output.put_line('Error se encontro mas de un pidm '||p_pidm||' '||SQLERRM);  
                    END;
                    
                    
                ELSE
                
                    dbms_output.put_line('Este pidm '||p_pidm||' ya se encuentra en el reporte');    
                    
                                   
                END IF;
                
            ELSE    
                dbms_output.put_line('Este pidm '||p_pidm||' No se encuentra en SPAIDEN');
                            
            END IF;
                   
            COMMIT;                               
    
    END;                             
--
--                                 
END pkg_sir;
/

DROP PUBLIC SYNONYM PKG_SIR;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SIR FOR BANINST1.PKG_SIR;
