DROP PACKAGE BODY BANINST1.PKG_PREDICTAMEN;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_predictamen
IS
   FUNCTION  f_consulta_escuela (p_primera_letra VARCHAR2,
                                 p_escuela       VARCHAR2)
   RETURN pkg_predictamen.cursor_out
   as
   c_out pkg_predictamen.cursor_out;
   
   begin
    
    open c_out
        for 
            SELECT DISTINCT stvsbgi_code codigo,
                   TRIM(stvsbgi_desc) descripcion,
                   stvsbgi_type_ind tipo_escuela,
                   DECODE(stvsbgi_type_ind,'H','Preparatoria','C','Escuela') nivel
            FROM stvsbgi  
            WHERE 1 = 1
            AND stvsbgi_srce_ind ='Y'
            AND stvsbgi_desc LIKE '%'||p_primera_letra||'%'
            AND stvsbgi_type_ind = p_escuela
            AND stvsbgi_data_origin ='PREDICTAMEN'
            AND stvsbgi_code NOT IN(999999,
                                       999998,
                                       999995,
                                       999993,
                                       999992
                                       )
            ORDER BY 2;
               
         RETURN (c_out);         
   
   end f_consulta_escuela;
   
--
--
   FUNCTION  f_actualiza_escuela (p_descripcion VARCHAR2, 
                                  p_id          VARCHAR2,
                                  p_transaccion VARCHAR2)
   RETURN VARCHAR2
   AS
   BEGIN
   
       IF p_transaccion = 'A' THEN
          
           UPDATE stvsbgi SET stvsbgi_desc = p_descripcion,
                  stvsbgi_data_origin ='PREDICTAMEN'
           WHERE 1 = 1
           AND stvsbgi_code = p_id;
           
       ELSIF p_transaccion = 'E' THEN
       
           UPDATE stvsbgi SET stvsbgi_srce_ind = 'N',
                  stvsbgi_data_origin ='PREDICTAMEN'
           WHERE 1 = 1
           AND stvsbgi_code = p_id;
           
       ELSIF p_transaccion = 'P' THEN    
       
            
           UPDATE stvsbgi SET stvsbgi_srce_ind = 'Y',
                  stvsbgi_data_origin ='PREDICTAMEN'
           WHERE 1 = 1
           AND stvsbgi_code = p_id;

       END IF;
       
       COMMIT;
            
    RETURN('Exito');
   
   EXCEPTION WHEN OTHERS THEN
   
         RETURN('Error en transacción '||p_transaccion||' Error: '||sqlerrm);
   
   END f_actualiza_escuela;
--
--
   FUNCTION f_inserta_escuela (p_nombre_escuela VARCHAR2,
                               p_nivel          VARCHAR2)
   RETURN VARCHAR2
   AS
   l_maximo number;
   l_nivel  varchar2(2);
   l_error  varchar2(2000);
   
   BEGIN
    
       IF p_nombre_escuela IS NOT NULL THEN
       
           dbms_output.put_line(' entra 1');
   
           BEGIN
           
            SELECT DECODE(p_nivel,'BA','H','LI','C') nivel
            into l_nivel
            from dual;
            
           END;    
       
           BEGIN
           
               SELECT COUNT(MAX(stvsbgi_code))+1
               INTO l_maximo
               FROM stvsbgi
               WHERE 1 = 1
               AND stvsbgi_code NOT IN(999999,
                                       999998,
                                       999995,
                                       999993,
                                       999992
                                       )
                AND stvsbgi_code NOT IN (select stvsbgi_code
                            from STVSBGI
                            where 1 = 1
                            and STVSBGI_TYPE_IND ='H')                       
                GROUP BY stvsbgi_code; 
           END;
          
           BEGIN
               INSERT INTO STVSBGI VALUES(
                                           l_maximo,
                                           l_nivel,
                                           'Y',
                                           p_nombre_escuela,
                                           SYSDATE,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           USER,
                                           'PREDICTAMEN',
                                           NULL
                                          );
                                          
           EXCEPTION WHEN OTHERS THEN
            rollback;
            dbms_output.put_line('Error al insertar tabla de escuelas de origen '||SQLERRM);
            l_error:=('Error al insertar tabla de escuelas de origen '||SQLERRM);
            
           END;     
           
           BEGIN
            
            INSERT INTO sobsbgi VALUES (
                                        l_maximo,
                                        'CALZADA DE LA NARANJA No. 159 PISO 4 ',
                                        NULL,
                                        'IND ALCE BLANCO',
                                        'NAUCALPAN DE JUAREZ,',
                                        'MME',
                                        'ME057',
                                        53370,
                                        'MX',
                                        SYSDATE,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        USER,
                                        'PREDICTAMEN',
                                        NULL
                                        );
           
           
           EXCEPTION WHEN OTHERS THEN
                ROLLBACK;
                dbms_output.put_line('Error al insertar tabla de escuelas de origen SOBSBGI '||SQLERRM);
                l_error:=('Error al insertar tabla de escuelas de origen '||SQLERRM);
            
           END;  
           
           BEGIN                          
           
               INSERT INTO sorbtag VALUES(l_maximo,
                                          '000000',
                                          'LI',
                                          'AC',
                                          'CUAT',
                                          NULL,
                                          NULL,
                                          NULL,                              
                                          SYSDATE,
                                          NULL,
                                          NULL,
                                          NULL,
                                          'PREDICTAMEN',
                                          NULL
                                          );
           
           EXCEPTION WHEN OTHERS THEN
               rollback;
               dbms_output.put_line('Error al insertar tabla de escuelas de origen SORBTAG '||SQLERRM);                
               l_error:=('Error al insertar tabla de escuelas de origen SORBTAG '||SQLERRM);
           END;     
           
           BEGIN
           
           
                INSERT INTO sorbcnt VALUES(
                                           l_maximo,
                                           p_nombre_escuela,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           SYSDATE,
                                           NULL,
                                           NULL,
                                           NULL,
                                           USER,
                                           'PREDICTAMEN',
                                           NULL
                                          );
           
           
           
           EXCEPTION WHEN OTHERS THEN
               ROLLBACK;
               dbms_output.put_line('Error al insertar tabla de escuelas de origen SORBCNT '||SQLERRM); 
               l_error:=('Error al insertar tabla de escuelas de origen SORBTAG '||SQLERRM);            
           END;   
           
           BEGIN
           
               INSERT INTO SORBTAL VALUES(l_maximo,
                                           '000000',
                                           'LI',
                                           SYSDATE,
                                           NULL,
                                           NULL,
                                           USER,
                                           'PREDICTAMEN',
                                           NULL
                                         );
                                         
           EXCEPTION WHEN OTHERS THEN
               ROLLBACK;
               dbms_output.put_line('Error al insertar tabla de escuelas de origen SORBTAL '||SQLERRM);
               l_error:=('Error al insertar tabla de escuelas de origen SORBTAL '||SQLERRM);
                
           END;      
           
           FOR C IN (SELECT calificacion,
                       descripcion,
                       ORDEN
                    FROM
                    (   
                    SELECT '10.0' calificacion,
                           'DIEZ' descripcion,
                           1 ORDEN
                    FROM dual
                    UNION
                    SELECT '9.0' calificacion,
                           'NUEVE' descripcion,
                           2 ORDEN
                    FROM dual
                    UNION
                    SELECT '8.0' calificacion,
                           'OCHO' descripcion,
                           3 ORDEN
                    FROM DUAL
                    UNION
                    SELECT '7.0' calificacion,
                           'SIETE' descripcion,
                           4 ORDEN
                    FROM DUAL
                    UNION
                    SELECT '6.0' calificacion,
                           'SEIS' descripcion,
                           5 ORDEN
                    FROM DUAL
                    )
                 ORDER BY 3  
           )
           LOOP
           
           
                INSERT INTO shrtgrd VALUES(
                                          l_maximo,
                                          c.calificacion,
                                          'LI',
                                          c.descripcion,
                                          '000000',
                                          to_number(c.calificacion),
                                          'Y',
                                          'Y',
                                          'Y',
                                          'Y',
                                          'A',
                                          SYSDATE,
                                          NULL,
                                          1,
                                          c.calificacion,
                                          to_number(c.calificacion),
                                          NULL,
                                          NULL,
                                          USER,
                                          'PREDICTAMEN',
                                          null
                                          );
          
           
           END LOOP;                          
           
           COMMIT;
           RETURN('Exito');
           DBMS_OUTPUT.PUT_LINE('Exito ');
           
       ELSE
            DBMS_OUTPUT.PUT_LINE('No se puede hacer una inserción nula en descripción de escuela   ');
            raise_application_error (-20002,'No se puede hacer una inserción nula en descripción de escuela ');
     
       END IF;
     
   EXCEPTION WHEN OTHERS THEN
   
         RETURN('Error '||l_error);    
         ROLLBACK;
   
   END f_inserta_escuela;
--
--   
   FUNCTION  f_consulta_carrera (p_primera_letra VARCHAR2,
                                 p_nivel         VARCHAR2)
   RETURN pkg_predictamen.cursor_carrera_out
   as
   c_carrera pkg_predictamen.cursor_carrera_out;
   BEGIN
    
    OPEN c_carrera 
        FOR
            SELECT smrprle_program PROGRAMA,
                   TRIM(smrprle_program_desc) DESCRIPCION,
                   smrprle_activity_date FECHA_ACTIVO
            FROM   smrprle
            WHERE 1 = 1
            AND  SUBSTR(smrprle_program_desc,1,20) LIKE p_primera_letra||'%'
            AND smrprle_levl_code =p_nivel
            AND smrprle_curr_ind ='Y'
            AND SUBSTR(smrprle_program,1,3)='UTL'
            ORDER BY 2;
    
        RETURN (c_carrera);
        
   EXCEPTION WHEN OTHERS THEN   
    null;
   END f_consulta_carrera;
--
--    
    FUNCTION f_consulta_materia (p_primera_letra VARCHAR2)
                                 
    RETURN pkg_predictamen.cursor_c_materia_out
    as
    c_materia pkg_predictamen.cursor_c_materia_out;           
    BEGIN
        OPEN c_materia
            FOR 
            SELECT MATERIA,
                   SUBJECT,
                   NUMB
            FROM
            (       
            select translate(MATERIA, 'áéíóúÁÉÍÓÚ', 'aeiouAEIOU')MATERIA,
                                       SUBJECT,
                                       NUMB
                                from 
                                (
                                    SELECT DISTINCT SUBSTR(subject,2,1) sd,
                                           TRIM(materia) materia,
                                           subject,
                                           numb
                                    FROM 
                                    (
                                    -- se comento para agregar el para
--                                    SELECT DISTINCT yln.scrsyln_long_course_title||' | '||scrsyln_subj_code||' | '||scrsyln_crse_numb MATERIA,
--                                                    yln.scrsyln_subj_code SUBJECT,
--                                                    yln.scrsyln_crse_numb NUMB
--                                    FROM scrsyln yln,
--                                         scrlevl evl,
--                                         scrrcam cam           
--                                    WHERE 1 = 1
--                                    AND yln.scrsyln_subj_code = evl.scrlevl_subj_code
--                                    AND yln.scrsyln_crse_numb = evl.scrlevl_crse_numb
--                                    AND yln.scrsyln_crse_numb = cam.scrrcam_crse_numb
--                                    AND yln.scrsyln_subj_code = cam.scrrcam_subj_code
--                                    AND evl.scrlevl_levl_code ='LI'
--                                    AND cam.scrrcam_camp_code ='UTL'
                                    select ZSTPARA_PARAM_VALOR||' | '||ZSTPARA_PARAM_ID||' | '||ZSTPARA_PARAM_DESC MATERIA,
                                           ZSTPARA_PARAM_ID SUBJECT,
                                           ZSTPARA_PARAM_DESC NUMB
                                    from ZSTPARA                        
                                    where 1 = 1
                                    and ZSTPARA_MAPA_ID ='MAT_CALCULADORA'
                                    )
                                )
                        WHERE 1 = 1
--                        AND sd ='2' 
                        )
                        WHERE 1 = 1
                        AND   UPPER(materia) LIKE '%'||p_primera_letra||'%' ;      
                        
            RETURN (c_materia);
        
    END;                       
--
--            
   FUNCTION f_inserta_prospecto( p_id            NUMBER,
                                 p_subj_code     VARCHAR2,
                                 p_crse_numb_low VARCHAR2
                               )
   RETURN VARCHAR2
   AS
   BEGIN
   
        INSERT INTO sztpaeq VALUES(p_id,p_subj_code,p_crse_numb_low);
   
        COMMIT;
        RETURN('Exito');
        DBMS_OUTPUT.PUT_LINE('Exito ');
    
   EXCEPTION WHEN OTHERS THEN   
        ROLLBACK;   
        DBMS_OUTPUT.PUT_LINE('Falso '||SQLERRM);       
        RETURN('Falso '||SQLERRM); 
   END f_inserta_prospecto;
   --
   --
   FUNCTION f_elimina_prospecto( p_id NUMBER)
   RETURN VARCHAR2
   AS
   BEGIN
   
        DELETE  sztpaeq 
        WHERE 1 = 1
        AND sztpaeq_ID =p_id;
   
        COMMIT;
        RETURN('Exito');
        DBMS_OUTPUT.PUT_LINE('Exito ');
    
   EXCEPTION WHEN OTHERS THEN   
        ROLLBACK;   
        DBMS_OUTPUT.PUT_LINE('Falso '||SQLERRM);       
        RETURN('Falso '||SQLERRM); 
   END f_elimina_prospecto;
   --
   --
   
   FUNCTION  f_consulta_programa (p_id NUMBER)
   RETURN pkg_predictamen.cursor_programa_out
   as
   c_programa pkg_predictamen.cursor_programa_out;
 
   BEGIN
        open c_programa
            for SELECT DISTINCT aap.SMRPAAP_PROGRAM PROGRAMA,
                UPPER(TRIM(rle.SZTDTEC_PROGRAMA_COMP)) DESCRIPCION
                FROM smrpaap aap,
                     smrarul rul,
                     SZTDTEC rle,
                     smracaa caa
                WHERE 1 = 1
                AND aap.smrpaap_area=rul.smrarul_area    
                AND aap.smrpaap_program = rle.SZTDTEC_PROGRAM
                AND SUBSTR(rle.SZTDTEC_PROGRAM,4,2)  ='LI'
                AND substr(SMRPAAP_PROGRAM,1,5)='UTLLI' 
                AND caa.smracaa_rule=rul.smrarul_key_rule
                AND (SMRARUL_SUBJ_CODE,SMRARUL_CRSE_NUMB_LOW) IN (SELECT sztpaeq_subj_code,
                                                                         sztpaeq_crse_numb_low 
                                                                 FROM sztpaeq
                                                                 WHERE 1 = 1
                                                                 AND sztpaeq_id =p_id )
                AND caa.smracaa_area NOT IN ('UTLMTI0101',
                                             'UTLLTE0101',
                                             'UTLLTI0101',
                                             'UTLLTS0101',
                                             'UTLLTT0110',
                                             'UOCATN0101',
                                             'UTSMTI0101',
                                             'UNAMPT0111',
                                             'UVEBTB0101');
   
                RETURN(c_programa);
                
   EXCEPTION WHEN OTHERS THEN   
            null;                  
   END f_consulta_programa;
   --
   --
                                     
   FUNCTION f_consulta_total_requerido (p_programa VARCHAR2)
   RETURN pkg_predictamen.cursor_total_out
   AS
   c_total pkg_predictamen.cursor_total_out;
   BEGIN
        OPEN c_total
           FOR SELECT smbpgen_req_courses_overall total_requerido
               FROM smbpgen gen
               WHERE 1 = 1
               AND gen.smbpgen_program=p_programa
               AND gen.smbpgen_term_code_eff = (SELECT MAX(gen1.smbpgen_term_code_eff)
                                                FROM smbpgen gen1
                                                WHERE 1 = 1
                                                AND gen1.smbpgen_program= gen.smbpgen_program);
               
                RETURN(c_total);
                
   EXCEPTION WHEN OTHERS THEN   
            null;                  
   END f_consulta_total_requerido;
--
--
   FUNCTION f_consulta_prog_materia (p_id       NUMBER,
                                     p_programa VARCHAR2)
   RETURN pkg_predictamen.cursor_prog_materia_out
   AS
   c_programa_materia pkg_predictamen.cursor_prog_materia_out;  
   BEGIN
        OPEN c_programa_materia
           FOR SELECT   DISTINCT smrarul_subj_code subj,
                                 smrarul_crse_numb_low crse,
                                 UPPER(scrsyln_long_course_title) TITULO
                FROM     smrprle rle,
                         smrpaap aap,
                         smrarul rul,
                         scrsyln yln
                WHERE 1= 1
                AND rle.smrprle_program = aap.smrpaap_program
                AND aap.smrpaap_area = rul.smrarul_area
                AND SUBSTR(aap.smrpaap_program,1,5)='UTLLI'
                AND smrprle_levl_code ='LI'
                AND yln.scrsyln_subj_code =smrarul_subj_code(+)  
                AND yln.scrsyln_crse_numb= smrarul_crse_numb_low(+)
                AND smrarul_subj_code||smrarul_crse_numb_low IN (SELECT sztpaeq_subj_code||sztpaeq_crse_numb_low 
                                                                 FROM sztpaeq
                                                                 WHERE 1 = 1
                                                                 AND sztpaeq_id =p_id )
                AND aap.smrpaap_program = p_programa                                                                 
                AND rul.smrarul_area NOT IN ('UTLMTI0101',
                                             'UTLLTE0101',
                                             'UTLLTI0101',
                                             'UTLLTS0101',
                                             'UTLLTT0110',
                                             'UOCATN0101',
                                             'UTSMTI0101',
                                             'UNAMPT0111',
                                             'UVEBTB0101');
               
                RETURN(c_programa_materia);
                
   EXCEPTION WHEN OTHERS THEN   
            null;                  
   END f_consulta_prog_materia;     
   --
   --
   FUNCTION f_inserta_equivalencia( p_id_origen     NUMBER,
                                    p_programa_int  varchar2,
                                    p_programa_ext  varchar2,
                                    p_descripcion   varchar2,
                                    p_int_subj_code varchar2,
                                    p_ext_subj_code varchar2,
                                    p_int_crse_numb varchar2,
                                    p_ext_crse_numb varchar2
                                   )
   RETURN VARCHAR2
   AS   
   l_secuencia number;
   l_descripcion_banner varchar2(500);
   l_creditos number(10,2);                      
   BEGIN
     
       INSERT INTO SZTEQUI VALUES (p_id_origen,
                                   p_programa_INT,
                                   p_programa_ext,
                                   p_descripcion,
                                   'LI',
                                   p_int_subj_code,
                                   p_ext_subj_code,
                                   p_int_crse_numb,
                                   p_ext_crse_numb,
                                   'EQUIVALENCIA',
                                   'N',
                                    USER,
                                    SYSDATE,
                                    USER,
                                    SYSDATE
                                    );
                                    
       FOR C IN (SELECT sztequi_id_origen escuela, 
                        sztequi_programa_int programa, 
                        sztequi_descripcion_ext descripcion,
                        sztequi_nivel nivel, 
                        sztequi_int_subj_code int_subj_code, 
                        sztequi_ext_subj_code ext_subj_code, 
                        sztequi_int_crse_numb int_crse_numb, 
                        sztequi_ext_crse_numb ext_crse_numb
                FROM sztequi
                WHERE 1 = 1
                AND sztequi_estatus_procesado ='N')
                loop
                
                    INSERT INTO SHBTATC VALUES (c.escuela,
                                                c.programa,
                                                c.nivel,
                                                c.ext_subj_code,
                                                c.ext_crse_numb,
                                                '000000',
                                                SYSDATE,
                                                c.descripcion,
                                                1,
                                                1,
                                                'Y',
                                                'AC',
                                                null,
                                                to_char('6.0'),
                                                null,
                                                null,
                                                NULL,
                                                USER,
                                                'PREDICTAMEN',
                                                'N',
                                                NULL,
                                                NULL,
                                                NULL
                                                );
                                                
                    l_secuencia:=l_shrtcat_sq.NextVal;
                                                
                    INSERT INTO shrtcat VALUES(l_secuencia,
                                               c.escuela,
                                               c.programa,
                                               c.nivel,
                                               c.ext_subj_code,
                                               c.ext_crse_numb,
                                               '000000',
                                               'AC',
                                               'TEST',
                                               USER,
                                               SYSDATE,
                                               l_secuencia,
                                               'PREDICTAMEN',
                                               NULL,
                                               NULL,
                                               NULL
                                               );     
                                               
                     
                    BEGIN 
                    
                        SELECT DISTINCT yln.scrsyln_long_course_title MATERIA
                        INTO l_descripcion_banner
                        from scrsyln yln
                        where 1 = 1
                        AND yln.scrsyln_subj_code = c.INT_SUBJ_CODE
                        AND yln.scrsyln_crse_numb =  c.INT_CRSE_NUMB;
                    
                    EXCEPTION WHEN OTHERS THEN                    
                        l_descripcion_banner:='No existe descripción';
                    END;
                    
                    
                    BEGIN
                    
                        SELECT scbcrse_credit_hr_low
                        INTO l_creditos
                        FROM SCBCRSE 
                        WHERE 1 = 1
                        AND scbcrse_subj_code||scbcrse_crse_numb = p_int_subj_code||p_ext_subj_code
                        AND rownum = 1;
                        
                    EXCEPTION WHEN OTHERS THEN
                     NULL;    
                    END;                                             
                                               
                    INSERT INTO SHRTATC VALUES (
                                                c.escuela,
                                                c.programa,
                                                c.nivel,
                                                c.ext_subj_code,
                                                c.ext_crse_numb,
                                                '000000',
                                                l_secuencia,
                                                SYSDATE,
                                                NULL,
                                                NULL,
                                                c.int_subj_code,
                                                c.int_crse_numb,
                                                SUBSTR(l_descripcion_banner,1,30),
                                                l_creditos,
                                                NULL,
                                                NULL,
                                                NULL,
                                                NULL,
                                                USER,
                                                'PREDICTAMEN',
                                                NULL
                                               );                                                          
                    
                end loop;   
                
                BEGIN             
                
                    UPDATE sztequi SET sztequi_estatus_procesado ='Y'
                    WHERE 1 = 1
                    AND sztequi_id_origen =  p_id_origen
                    AND sztequi_programa_int = p_programa_int
                    AND sztequi_nivel ='LI'
                    AND sztequi_int_subj_code =p_int_subj_code
                    AND sztequi_ext_subj_code = p_ext_subj_code 
                    AND sztequi_int_crse_numb = p_int_crse_numb
                    AND sztequi_ext_crse_numb = p_ext_crse_numb
                    AND sztequi_estatus_procesado ='N'; 
                    
                EXCEPTION WHEN OTHERS THEN
                    NULL;
                END;
                                  
                                    
        COMMIT;
        
        RETURN('Exito');
        DBMS_OUTPUT.PUT_LINE('Exito');
       
       
   EXCEPTION WHEN OTHERS THEN
   
        ROLLBACK;
   
        DBMS_OUTPUT.PUT_LINE('Este registro se encuentra en la base de datos  '||sqlerrm);
       
        RETURN('Falso '||sqlerrm);
       
   END f_inserta_equivalencia ;                                         
--
--
    
   FUNCTION f_inserta_alumnos (
                                p_id_origen     NUMBER,
                                p_programa_int  VARCHAR2,
                                p_int_subj_code VARCHAR2,
                                p_ext_subj_code VARCHAR2,
                                p_int_crse_numb VARCHAR2,
                                p_ext_crse_numb VARCHAR2,
                                p_calificacion  varchar2,
                                p_matricula     VARCHAR2,
                                p_pidm          NUMBER,
                                p_periodo       varchar2
                                )    
   RETURN VARCHAR2
   AS      
   l_descripcion VARCHAR2(500):='EXITO';  
   l_titulo      VARCHAR2(500);
   l_seq_no      NUMBER;
   l_creditos    NUMBER(10,2);
   l_SURROGATE_ID  number;
   l_contar      number;
   
   BEGIN
   
        DELETE sztalpb;
        
        COMMIT;
        
        BEGIN
                    
             SELECT scbcrse_credit_hr_low
             INTO l_creditos
             FROM SCBCRSE 
             WHERE 1 = 1
             AND scbcrse_subj_code||scbcrse_crse_numb =  p_int_subj_code||p_int_crse_numb
             AND ROWNUM = 1;
                        
        EXCEPTION WHEN OTHERS THEN
         NULL;    
        END; 
   
        BEGIN
        
            BEGIN
        
                INSERT INTO sztalpr VALUES (
                                             p_id_origen,
                                             p_programa_int,
                                             p_int_subj_code,
                                             p_int_crse_numb,
                                             p_ext_subj_code,
                                             p_ext_crse_numb,
                                             p_calificacion,
                                             p_matricula,
                                             p_pidm,
                                             'PREDICTAMEN',
                                             USER,
                                             SYSDATE,
                                             USER,
                                             SYSDATE,
                                             p_periodo
                                           );
            EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN
               l_descripcion:=' Este Alumno '||p_matricula||' ya se encuentra en la base de datos 1 '||sqlerrm;
               RETURN(l_descripcion);
            END;                                  
                                       
        EXCEPTION WHEN OTHERS THEN
        
            l_descripcion:=' Error al insertar SZTALPR --> '||SQLERRM;
            
            ROLLBACK;
            
            BEGIN 
            
                INSERT INTO sztalpb VALUES (
                                           p_id_origen,
                                           p_programa_int,
                                           p_int_subj_code,
                                           p_int_crse_numb,
                                           p_ext_subj_code,
                                           p_ext_crse_numb,
                                           p_calificacion,
                                           p_matricula,
                                           p_pidm,
                                           'PREDICTAMEN',
                                           USER,
                                           SYSDATE,
                                           USER,
                                           SYSDATE,
                                           l_descripcion 
                                           );
            
            END;    
            
               
        END;          
        
        BEGIN
        
            SELECT SUBSTR(scrsyln_long_course_title,1,30) TITULO
            INTO l_titulo
            FROM scrsyln
            WHERE 1 = 1
            AND scrsyln_subj_code||scrsyln_crse_numb = p_int_subj_code||p_int_crse_numb;
            
        EXCEPTION WHEN OTHERS THEN
            l_titulo:='No existe descripción';
        END;
        
        
        BEGIN

            BEGIN
        
                INSERT INTO shrtrtk VALUES(
                                           p_pidm,
                                           p_id_origen,
                                           'LI',
                                           '000000',
                                            p_ext_subj_code,
                                            p_ext_crse_numb,
                                           1,
                                           '*',
                                           p_calificacion,
                                           p_int_subj_code,
                                           p_int_crse_numb,
                                           l_creditos,
                                           p_calificacion,
                                           1,
                                           SYSDATE,
                                           1,
                                           p_programa_int,
                                           'A',
                                           'LI',
                                           p_periodo,
                                           'Y',
                                           NULL,
                                           l_titulo,--TITULO
                                           NULL,
                                           NULL,
                                           l_titulo,--TITULO
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           NULL,
                                           USER,
                                           'PREDICTAMEN',
                                           NULL
                                          );
                                          
            EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN
               l_descripcion:=' Este Alumno '||p_matricula||' ya se encuentra en la base de datos 3 '||sqlerrm;
               RETURN(l_descripcion);
            END;                              
        
        EXCEPTION WHEN OTHERS THEN
        
            l_descripcion:=' Error al insertar SHRTRTK --> '||SQLERRM;
            
            ROLLBACK;
          
               
            BEGIN 
            
                INSERT INTO sztalpb VALUES (
                                           p_id_origen,
                                           p_programa_int,
                                           p_int_subj_code,
                                           p_int_crse_numb,
                                           p_ext_subj_code,
                                           p_ext_crse_numb,
                                           p_calificacion,
                                           p_matricula,
                                           p_pidm,
                                           'PREDICTAMEN',
                                           USER,
                                           SYSDATE,
                                           USER,
                                           SYSDATE,
                                           l_descripcion 
                                           );
            EXCEPTION  WHEN OTHERS THEN
               l_descripcion:=' Error al insertar sztalpb '||sqlerrm;
               RETURN(l_descripcion);
            END;                                                        
            
               
        END;   
        
        BEGIN
        
            SELECT NVL(MAX(SHRTRIT_SEQ_NO),0)+1 
            INTO l_seq_no
            FROM SHRTRIT
            WHERE 1 = 1
            AND SHRTRIT_pidm = p_pidm ;
                    
        END;
        
        BEGIN             
        
            BEGIN
        
                INSERT INTO shrtrit VALUES(
                                           p_pidm,
                                           l_seq_no,
                                           p_id_origen,
                                           null,
                                           null,
                                           sysdate,
                                           sysdate,
                                           null,
                                           null,
                                           user,
                                           'PREDICTAMEN',
                                           NULL
                                           );
                                           
            EXCEPTION  WHEN DUP_VAL_ON_INDEX THEN
               l_descripcion:=' Este Alumno '||p_matricula||' ya se encuentra en la base de datos 4 '||sqlerrm;
               RETURN(l_descripcion);
            END;  
        
        
        EXCEPTION WHEN OTHERS THEN
        
            l_descripcion:=' Error al insertar SHRTRIT --> '||SQLERRM;
            
            ROLLBACK;
     
            BEGIN 
            
                INSERT INTO sztalpb VALUES (
                                           p_id_origen,
                                           p_programa_int,
                                           p_int_subj_code,
                                           p_int_crse_numb,
                                           p_ext_subj_code,
                                           p_ext_crse_numb,
                                           p_calificacion,
                                           p_matricula,
                                           p_pidm,
                                           'PREDICTAMEN',
                                           USER,
                                           SYSDATE,
                                           USER,
                                           SYSDATE,
                                           l_descripcion 
                                           );
            EXCEPTION  WHEN OTHERS THEN
               l_descripcion:=' Error al insertar sztalpb '||sqlerrm;
               RETURN(l_descripcion);
            END;                                             
                        
               
        END;     
        
        begin 
            select NVL(max (SHRTRAM_SURROGATE_ID),0)+1
            into l_SURROGATE_ID
            from SHRTRAM;
        end;
        
        begin
        
            select count(*)
            into l_contar
            from shrtram
            where 1 = 1
            and shrtram_pidm =p_pidm;
        
        end;
        
        if l_contar = 0 then
        
            BEGIN
            
                INSERT INTO shrtram VALUES(
                                           p_pidm,
                                           l_seq_no,
                                           l_seq_no,
                                           'LI',
                                           p_periodo,
                                           p_periodo,
                                           'LICE',
                                           NULL,
                                           SYSDATE,
                                           SYSDATE,
                                           NULL,
                                           NULL,
                                           l_SURROGATE_ID,
                                           1,
                                           USER,
                                           'PREDICTAMEN',
                                           NULL
                                           );
                                           
            EXCEPTION WHEN OTHERS THEN
            
               l_descripcion:=' Error al insertar shrtram '||sqlerrm;
               RETURN(l_descripcion);
                 
                BEGIN 
            
                    INSERT INTO sztalpb VALUES (
                                               p_id_origen,
                                               p_programa_int,
                                               p_int_subj_code,
                                               p_int_crse_numb,
                                               p_ext_subj_code,
                                               p_ext_crse_numb,
                                               p_calificacion,
                                               p_matricula,
                                               p_pidm,
                                               'PREDICTAMEN',
                                               USER,
                                               SYSDATE,
                                               USER,
                                               SYSDATE,
                                               l_descripcion 
                                               );
            
                END;    
                                           
               
            END;
              
        end if;    
       
        COMMIT;
       
        RETURN(l_descripcion);
   END;
--
--
    
    FUNCTION p_carga_predictamen (p_pidm          NUMBER,
                                  p_id_origen     NUMBER,
                                  p_matricula     VARCHAR2,
                                  p_periodo       VARCHAR2,
                                  p_int_subj_code VARCHAR2,
                                  p_int_crse_numb VARCHAR2,
                                  p_programa_int  VARCHAR2,
                                  p_calificacion  VARCHAR2,
                                  p_ext_subj_code VARCHAR2,
                                  p_ext_crse_numb VARCHAR2)
    RETURN VARCHAR2 
    AS
        l_retorna      VARCHAR2(100):='EXITO';
        l_seq_no       NUMBER;
        l_SURROGATE_ID NUMBER;
        l_titulo       VARCHAR2(30);
        l_creditos     NUMBER(10,2);
    BEGIN
    
        BEGIN
        
            SELECT NVL(MAX(SHRTRIT_SEQ_NO),0)+1 
            INTO l_seq_no
            FROM SHRTRIT
            WHERE 1 = 1
            AND SHRTRIT_pidm = p_pidm ;
                    
        END;
        
        BEGIN
        
            INSERT INTO shrtrit VALUES(
                                       p_pidm,
                                       l_seq_no,
                                       p_id_origen,
                                       NULL,
                                       NULL,
                                       SYSDATE,
                                       SYSDATE,
                                       NULL,
                                       NULL,
                                       USER,
                                       'KEKO',
                                       NULL
                                       );
                                       
        EXCEPTION 
        
        
         WHEN OTHERS THEN
           null;
        END;
        
        BEGIN 
            SELECT NVL(MAX (SHRTRAM_SURROGATE_ID),0)+1
            INTO l_SURROGATE_ID
            FROM SHRTRAM;
        end;
        
        BEGIN
        
            INSERT INTO shrtram VALUES(
                                       p_pidm,
                                       l_seq_no,
                                       l_seq_no,
                                       'LI',
                                       p_periodo,
                                       p_periodo,
                                       'LICE',
                                       NULL,
                                       SYSDATE,
                                       SYSDATE,
                                       NULL,
                                       NULL,
                                       l_SURROGATE_ID,
                                       1,
                                       USER,
                                       'KEKO',
                                       NULL
                                       );
                                       
        EXCEPTION WHEN OTHERS THEN
        
           null;
           
        END;
        
        BEGIN
        
            SELECT SUBSTR(scrsyln_long_course_title,1,30) TITULO
            INTO l_titulo
            FROM scrsyln
            WHERE 1 = 1
            AND scrsyln_subj_code||scrsyln_crse_numb = p_int_subj_code||p_int_crse_numb;
            
        EXCEPTION WHEN OTHERS THEN
            l_titulo:='No existe descripción';
        END;
        
        BEGIN
                    
             SELECT scbcrse_credit_hr_low
             INTO l_creditos
             FROM SCBCRSE 
             WHERE 1 = 1
             AND scbcrse_subj_code||scbcrse_crse_numb =  p_int_subj_code||p_int_crse_numb
             AND ROWNUM = 1;
                        
        EXCEPTION WHEN OTHERS THEN
         NULL;    
        END; 
        
        BEGIN
        
            INSERT INTO shrtrtk VALUES(
                                       p_pidm,
                                       p_id_origen,
                                       'LI',
                                       '000000',
                                       p_ext_subj_code,
                                       p_ext_crse_numb,
                                       1,
                                       '*',
                                       p_calificacion,
                                       p_int_subj_code,
                                       p_int_crse_numb,
                                       l_creditos,
                                       p_calificacion,
                                       1,
                                       SYSDATE,
                                       1,
                                       p_programa_int,
                                       'A',
                                       'LI',
                                       p_periodo,
                                       'Y',
                                       NULL,
                                       l_titulo,--TITULO
                                       NULL,
                                       NULL,
                                       l_titulo,--TITULO
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       USER,
                                       'KEKO',
                                       NULL
                                      );
                                      
        EXCEPTION  WHEN OTHERS THEN
           l_retorna:=' Este Alumno '||p_matricula||' ya se encuentra en la base de datos en shrtrtk '||SQLERRM;
           RETURN(l_retorna);
        END;
        
        
        BEGIN
        
            INSERT INTO SZTTAEQ VALUES(
                                       p_pidm,
                                       p_id_origen,
                                       'LI',
                                       '000000',
                                       p_ext_subj_code,
                                       p_ext_crse_numb,
                                       1,
                                       '*',
                                       p_calificacion,
                                       p_int_subj_code,
                                       p_int_crse_numb,
                                       l_creditos,
                                       p_calificacion,
                                       1,
                                       SYSDATE,
                                       1,
                                       p_programa_int,
                                       'A',
                                       'LI',
                                       p_periodo,
                                       'Y',
                                       NULL,
                                       l_titulo,--TITULO
                                       NULL,
                                       NULL,
                                       l_titulo,--TITULO
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       NULL,
                                       USER,
                                       'KEKO',
                                       NULL
                                      );
                                      
        EXCEPTION  WHEN OTHERS THEN
           l_retorna:=' Este Alumno '||p_matricula||' ya se encuentra en la base de datos en shrtrtk '||SQLERRM;
           RETURN(l_retorna);
        END;
    
        RETURN(l_retorna);
    
    END;
--
--    
   
END pkg_predictamen;
/

DROP PUBLIC SYNONYM PKG_PREDICTAMEN;

CREATE OR REPLACE PUBLIC SYNONYM PKG_PREDICTAMEN FOR BANINST1.PKG_PREDICTAMEN;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_PREDICTAMEN TO PUBLIC;
