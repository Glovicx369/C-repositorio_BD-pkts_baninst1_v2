DROP PACKAGE BODY BANINST1.PKG_ACTAS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_ACTAS IS
PROCEDURE sp_actas(p_regla number, p_fecha_inicio date)
IS

vl_exito varchar2(250):= null;
vl_number number:=0;


      Begin

      
                Begin 
      
                   delete SZTACTA;
                   
                   Commit;
                Exception
                    When Others then 
                        DBMS_OUTPUT.PUT_LINE('Error    '||sqlerrm);

                End;
                 
               Begin
                        Select count(*)
                            Into vl_number
                        from SZTACTA
                        Where trim (to_number (regla)) = trim (p_regla);
                Exception
                    When others then 
                        vl_number :=0;
               End;
                
               If vl_number > 0 then 
                   Begin 
                       delete SZTACTA
                       where trim (to_number (regla)) = trim (p_regla);
                       Commit;                 
                   Exception
                    When Others then 
                        null;
                   End;
               End if;
                
        For xxx in (
        
                select distinct SZSGNME_PIDM pidm , SZSGNME_NO_REGLA regla
                    from SZSGNME
                    where SZSGNME_NO_REGLA =  trim (p_regla)
                    And trunc (SZSGNME_START_DATE)   = p_fecha_inicio
                   -- and SZSGNME_PIDM = '019815638'

                    
                    ) loop


                 Begin 

                    Insert into SZTACTA
                   select distinct
                                x.seq,
                                x.pidm,
                                x.ESTADO_ALUMNO,
                                x.TIPO_EVALUACION,
                                x.Periodo,
                                x.Grupo,
                                x.Cve_Materia,
                                nvl(x.Materia, x.matcrse) Materia,
                                x.clave_prof,
                                x.NOMBRE_PROF,
                                x.Matricula,
                                x.NOMBRE_ALUMNO,
                                x.cve_programa,
                                x.PROGRAMA,
                                x.Calificacion,
                                x.CALIF_LETRA,
                                x.FECHA_FIN,
                                x.campus,
                                x.Nivel,
                                x.Fecha_inicio,
                                x.Regla,
                               -- x.Fecha_inicio||'-'||x.periodo_nrc||'-'||get_crn (x.pidm, x.Periodo, x.PTRM, x.Cve_Materia) folio,
                                x.Fecha_inicio||'-'|| x.Cve_Materia||'-'||x.grupo folio,
                                x.EMAIL
                            from (  
                                      select distinct --ROW_NUMBER() OVER(PARTITION BY  e.SZTGPME_TERM_NRC_COMP||substr (e.SZTGPME_TERM_NRC, length (e.SZTGPME_TERM_NRC) -1, 2) ORDER BY e.SZTGPME_TERM_NRC_COMP||substr (e.SZTGPME_TERM_NRC, length (e.SZTGPME_TERM_NRC) -1, 2)) REG,
                                        1 seq,
                                        d.spriden_pidm pidm,
                                        ' ' ESTADO_ALUMNO,
                                           CASE WHEN  trim (p_regla) = 99 THEN       
                                             'EXTRAORDINARIO'             
                                                WHEN  trim (p_regla) != 99 THEN
                                                 'ORDINARIO'       
                                           END TIPO_EVALUACION,           
                                        CASE WHEN  trim (p_regla) = 99 THEN    
                                                    ( Select distinct SOBPTRM_TERM_CODE
                                                    from SOBPTRM
                                                    where SOBPTRM_PTRM_CODE = '1'
                                                    And trunc (SOBPTRM_START_DATE) = trunc (a.SZSGNME_START_DATE)
                                                    And substr (SOBPTRM_TERM_CODE, 5,1) = '8'
                                                    And substr (SOBPTRM_TERM_CODE, 1,2) = '01'
                                                    )    
                                                 WHEN  trim (p_regla) != 99 THEN                   
                                                        (select distinct SZTPRONO_TERM_CODE
                                                            from sztprono
                                                            where SZTPRONO_PIDM =  c.SZSTUME_PIDM
                                                            and rownum = 1
                                                            And SZTPRONO_NO_REGLA =  trim (p_regla)
                                                        ) 
                                                        END Periodo,
                                        (select distinct SZTPRONO_PTRM_CODE
                                            from sztprono
                                            where SZTPRONO_PIDM =  c.SZSTUME_PIDM
                                            and rownum = 1
                                            And SZTPRONO_NO_REGLA =  trim (p_regla)
                                        ) PTRM,
                                        substr (e.SZTGPME_TERM_NRC, length (e.SZTGPME_TERM_NRC) -1, 2) Grupo, 
                                        e.SZTGPME_SUBJ_CRSE Cve_Materia,
                                        UPPER((SELECT SCRSYLN_LONG_COURSE_TITLE
                                        FROM SCRSYLN
                                        WHERE 1=1
                                        AND SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = SZTGPME_SUBJ_CRSE
                                        ))MATERIA,
                                         (SELECT SCBCRSE_TITLE 
                                        FROM SCBCRSE
                                        WHERE 1=1
                                        AND e.SZTGPME_SUBJ_CRSE = SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB
                                        AND SCBCRSE_CSTA_CODE = 'A') MATERIA2,
                                        b.spriden_id clave_prof, 
                                        b.SPRIDEN_FIRST_NAME||' '||REPLACE(b.SPRIDEN_LAST_NAME,'/',' ') NOMBRE_PROF, 
                                        c.SZSTUME_ID Matricula,
                                        d.SPRIDEN_FIRST_NAME||' '||REPLACE(d.SPRIDEN_LAST_NAME,'/',' ') NOMBRE_ALUMNO, 
                                        h.programa cve_programa ,
                                        (select distinct SZTDTEC_PROGRAMA_COMP
                                            from SZTDTEC
                                            where 1= 1 
                                            And SZTDTEC_PROGRAM = h.programa
                                            And SZTDTEC_TERM_CODE = h.CTLG ) PROGRAMA, 
                                       c.SZSTUME_GRDE_CODE_FINAL Calificacion,--h.calif Calificacion, 
                                       f.SHRGRDE_ABBREV CALIF_LETRA,--h.CALIF_LETR CALIF_LETRA, 
                                        TRUNC (SYSDATE) FECHA_FIN,
                                        null  campus,
                                        null Nivel,
                                        trunc (e.SZTGPME_START_DATE)  Fecha_inicio,
                                        e.SZTGPME_NO_REGLA Regla,
                                        e.SZTGPME_TERM_NRC_COMP periodo_nrc,
                                        g.SCBCRSE_TITLE matcrse,
                                        szstume_rsts_code PR,
                                        PKG_UTILERIAS. f_correo (xxx.pidm, 'PRIN' ) EMAIL
                    from SZSGNME a
                    join spriden b on b.spriden_pidm = a.SZSGNME_PIDM
                                      and b.spriden_pidm = xxx.pidm
                                       and b.spriden_change_ind is null
                    join SZSTUME c on  c.SZSTUME_TERM_NRC = a.SZSGNME_TERM_NRC
                    join spriden d on d.spriden_pidm = c.SZSTUME_PIDM
                     and d.SPRIDEN_CHANGE_IND is null
                        and c.SZSTUME_STAT_IND = '1'
                        and c.SZSTUME_NO_REGLA =  trim (p_regla)
                        and c.SZSTUME_RSTS_CODE =  'RE'
                      --  And c.SZSTUME_PTRM  = '2'
                        And trunc (c.SZSTUME_START_DATE) =  p_fecha_inicio
                        AND c.szstume_seq_no = (SELECT MAX (c1.szstume_seq_no)
                                                            FROM szstume c1
                                                            WHERE 1=1
                                                            AND c.szstume_pidm = c1.szstume_pidm
                                                            AND c.szstume_no_regla = c1.szstume_no_regla
                                                          --  And trunc (c.SZSTUME_START_DATE)  = trunc (c1.SZSTUME_START_DATE) 
                                                            AND c.szstume_term_nrc = c1.szstume_term_nrc
                                                           -- and c.SZSTUME_RSTS_CODE = c1.SZSTUME_RSTS_CODE
                                                          --  And c.SZSTUME_PTRM = c1.SZSTUME_PTRM
                                                            )
                    join SZTGPME e on e.SZTGPME_TERM_NRC = a.SZSGNME_TERM_NRC and SZTGPME_STAT_IND = '1' and e.SZTGPME_NO_REGLA =  trim (p_regla) and trunc (e.SZTGPME_START_DATE) = p_fecha_inicio
                    left join SHRGRDE f on f.SHRGRDE_CODE = c.SZSTUME_GRDE_CODE_FINAL 
                    join SCBCRSE g on e.SZTGPME_SUBJ_CRSE = g.SCBCRSE_SUBJ_CODE||g.SCBCRSE_CRSE_NUMB
                    join tztprog h on h.pidm = c.SZSTUME_PIDM
                   /* And h.sp = (Select max (h1.sp)
                                        from tztprog h1
                                        Where h.pidm = h1.pidm)   */
                     And h.programa = (Select distinct h1.SZTPRONO_PROGRAM
                                        from sztprono h1
                                        Where h.pidm = h1.SZTPRONO_PIDM
                                        and h1.SZTPRONO_MATERIA_LEGAL=c.SZSTUME_SUBJ_CODE_COMP
                                        and h1.SZTPRONO_NO_REGLA = trim (p_regla)
                                        )
                   -- AND h.ESTATUS  IN ('MA', 'EG', 'SG')                  
                    where a.SZSGNME_NO_REGLA =  trim (p_regla)
                    And trunc (a.SZSGNME_START_DATE)  = p_fecha_inicio
                    And a.SZSGNME_STAT_IND = '1'
                    and f.SHRGRDE_LEVL_CODE in  (SELECT DISTINCT e1.SZTGPME_LEVL_CODE  FROM SZTGPME e1
                                                                    WHERE e1.SZTGPME_NO_REGLA =  trim (p_regla)
                                                                    And SZTGPME_START_DATE  = p_fecha_inicio
                                                                    )  
                    And a.SZSGNME_SEQ_NO = (select max (a1.SZSGNME_SEQ_NO)
                                                            from SZSGNME a1
                                                            Where a1.SZSGNME_NO_REGLA = a.SZSGNME_NO_REGLA
                                                           And a.SZSGNME_STAT_IND = a1.SZSGNME_STAT_IND
                                                            And a.SZSGNME_TERM_NRC = a1.SZSGNME_TERM_NRC
                                                             And trunc (a.SZSGNME_START_DATE) = trunc ( a1.SZSGNME_START_DATE)
                                                            )
                    ) x
                             where 1=1    ;                             
                    
            
                Exception
                    When Others then 
                    null;
                              --   DBMS_OUTPUT.PUT_LINE('SALIDA    '||sqlerrm);
               End;
               Commit;
               
            End Loop;
            
          /*  
       For xxx in (
        
                select distinct SZSGNME_PIDM pidm , SZSGNME_NO_REGLA regla
                    from SZSGNME
                    where SZSGNME_NO_REGLA =  trim (p_regla)
                    And trunc (SZSGNME_START_DATE)   = p_fecha_inicio
                   -- and SZSGNME_PIDM = '019815638'

                    
                    ) loop


                 Begin 

                    Insert into SZTACTA
                   select distinct
                                x.seq,
                                x.pidm,
                                x.ESTADO_ALUMNO,
                                x.TIPO_EVALUACION,
                                x.Periodo,
                                x.Grupo,
                                x.Cve_Materia,
                                nvl(x.Materia, x.matcrse) Materia,
                                x.clave_prof,
                                x.NOMBRE_PROF,
                                x.Matricula,
                                x.NOMBRE_ALUMNO,
                                x.cve_programa,
                                x.PROGRAMA,
                                x.Calificacion,
                                x.CALIF_LETRA,
                                x.FECHA_FIN,
                                x.campus,
                                x.Nivel,
                                x.Fecha_inicio,
                                x.Regla,
                               -- x.Fecha_inicio||'-'||x.periodo_nrc||'-'||get_crn (x.pidm, x.Periodo, x.PTRM, x.Cve_Materia) folio,
                                x.Fecha_inicio||'-'|| x.Cve_Materia||'-'||x.grupo folio,
                                x.EMAIL
                            from (  
                                      select distinct --ROW_NUMBER() OVER(PARTITION BY  e.SZTGPME_TERM_NRC_COMP||substr (e.SZTGPME_TERM_NRC, length (e.SZTGPME_TERM_NRC) -1, 2) ORDER BY e.SZTGPME_TERM_NRC_COMP||substr (e.SZTGPME_TERM_NRC, length (e.SZTGPME_TERM_NRC) -1, 2)) REG,
                                        1 seq,
                                        d.spriden_pidm pidm,
                                        ' ' ESTADO_ALUMNO,
                                           CASE WHEN  trim (p_regla) = 99 THEN       
                                             'EXTRAORDINARIO'             
                                                WHEN  trim (p_regla) != 99 THEN
                                                 'ORDINARIO'       
                                           END TIPO_EVALUACION,           
                                        CASE WHEN  trim (p_regla) = 99 THEN    
                                                    ( Select distinct SOBPTRM_TERM_CODE
                                                    from SOBPTRM
                                                    where SOBPTRM_PTRM_CODE = '1'
                                                    And trunc (SOBPTRM_START_DATE) = trunc (a.SZSGNME_START_DATE)
                                                    And substr (SOBPTRM_TERM_CODE, 5,1) = '8'
                                                    And substr (SOBPTRM_TERM_CODE, 1,2) = '01'
                                                    )    
                                                 WHEN  trim (p_regla) != 99 THEN                   
                                                        (select distinct SZTPRONO_TERM_CODE
                                                            from sztprono
                                                            where SZTPRONO_PIDM =  c.SZSTUME_PIDM
                                                            and rownum = 1
                                                            And SZTPRONO_NO_REGLA =  trim (p_regla)
                                                        ) 
                                                        END Periodo,
                                        (select distinct SZTPRONO_PTRM_CODE
                                            from sztprono
                                            where SZTPRONO_PIDM =  c.SZSTUME_PIDM
                                            and rownum = 1
                                            And SZTPRONO_NO_REGLA =  trim (p_regla)
                                        ) PTRM,
                                        substr (e.SZTGPME_TERM_NRC, length (e.SZTGPME_TERM_NRC) -1, 2) Grupo, 
                                        e.SZTGPME_SUBJ_CRSE Cve_Materia,
                                        UPPER((SELECT SCRSYLN_LONG_COURSE_TITLE
                                        FROM SCRSYLN
                                        WHERE 1=1
                                        AND SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB = SZTGPME_SUBJ_CRSE
                                        ))MATERIA,
                                         (SELECT SCBCRSE_TITLE 
                                        FROM SCBCRSE
                                        WHERE 1=1
                                        AND e.SZTGPME_SUBJ_CRSE = SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB
                                        AND SCBCRSE_CSTA_CODE = 'A') MATERIA2,
                                        b.spriden_id clave_prof, 
                                        b.SPRIDEN_FIRST_NAME||' '||REPLACE(b.SPRIDEN_LAST_NAME,'/',' ') NOMBRE_PROF, 
                                        c.SZSTUME_ID Matricula,
                                        d.SPRIDEN_FIRST_NAME||' '||REPLACE(d.SPRIDEN_LAST_NAME,'/',' ') NOMBRE_ALUMNO, 
                                        h.programa cve_programa ,
                                        (select distinct SZTDTEC_PROGRAMA_COMP
                                            from SZTDTEC
                                            where 1= 1 
                                            And SZTDTEC_PROGRAM = h.programa
                                            And SZTDTEC_TERM_CODE = h.CTLG ) PROGRAMA, 
                                       c.SZSTUME_GRDE_CODE_FINAL Calificacion,--h.calif Calificacion, 
                                       f.SHRGRDE_ABBREV CALIF_LETRA,--h.CALIF_LETR CALIF_LETRA, 
                                        TRUNC (SYSDATE) FECHA_FIN,
                                        null  campus,
                                        null Nivel,
                                        trunc (e.SZTGPME_START_DATE)  Fecha_inicio,
                                        e.SZTGPME_NO_REGLA Regla,
                                        e.SZTGPME_TERM_NRC_COMP periodo_nrc,
                                        g.SCBCRSE_TITLE matcrse,
                                        szstume_rsts_code PR,
                                        PKG_UTILERIAS. f_correo (xxx.pidm, 'PRIN' ) EMAIL
                    from SZSGNME a
                    join spriden b on b.spriden_pidm = a.SZSGNME_PIDM
                                      and b.spriden_pidm = xxx.pidm
                                       and b.spriden_change_ind is null
                    join SZSTUME c on  c.SZSTUME_TERM_NRC = a.SZSGNME_TERM_NRC
                    join spriden d on d.spriden_pidm = c.SZSTUME_PIDM
                     and d.SPRIDEN_CHANGE_IND is null
                        and c.SZSTUME_STAT_IND = '1'
                        and c.SZSTUME_NO_REGLA =  trim (p_regla)
                        and c.SZSTUME_RSTS_CODE =  'RE'
                       -- And c.SZSTUME_PTRM  = '2'
                        And trunc (c.SZSTUME_START_DATE) =  p_fecha_inicio
                        AND c.szstume_seq_no = (SELECT MAX (c1.szstume_seq_no)
                                                            FROM szstume c1
                                                            WHERE 1=1
                                                            AND c.szstume_pidm = c1.szstume_pidm
                                                            AND c.szstume_no_regla = c1.szstume_no_regla
                                                            And trunc (c.SZSTUME_START_DATE)  = trunc (c1.SZSTUME_START_DATE) 
                                                            AND c.szstume_term_nrc = c1.szstume_term_nrc
                                                            and c.SZSTUME_RSTS_CODE = c1.SZSTUME_RSTS_CODE
                                                          --  And c.SZSTUME_PTRM = c1.SZSTUME_PTRM
                                                            )
                    join SZTGPME e on e.SZTGPME_TERM_NRC = a.SZSGNME_TERM_NRC and SZTGPME_STAT_IND = '1' and e.SZTGPME_NO_REGLA =  trim (p_regla) and trunc (e.SZTGPME_START_DATE) = p_fecha_inicio
                    left join SHRGRDE f on f.SHRGRDE_CODE = c.SZSTUME_GRDE_CODE_FINAL 
                    join SCBCRSE g on e.SZTGPME_SUBJ_CRSE = g.SCBCRSE_SUBJ_CODE||g.SCBCRSE_CRSE_NUMB
                    join tztprog h on h.pidm = c.SZSTUME_PIDM
                    And h.sp = (Select max (h1.sp)
                                        from tztprog h1
                                        Where h.pidm = h1.pidm)   
                    AND h.ESTATUS Not IN ('MA', 'EG', 'SG')       
                    And h.fecha_mov > pkg_utilerias.f_fecha_fin(h.pidm, a.SZSGNME_NO_REGLA, h.sp)                    
                    where a.SZSGNME_NO_REGLA =  trim (p_regla)
                    And trunc (a.SZSGNME_START_DATE)  = p_fecha_inicio
                    And a.SZSGNME_STAT_IND = '1'
                    and f.SHRGRDE_LEVL_CODE in  (SELECT DISTINCT e1.SZTGPME_LEVL_CODE  FROM SZTGPME e1
                                                                    WHERE e1.SZTGPME_NO_REGLA =  trim (p_regla)
                                                                    And SZTGPME_START_DATE  = p_fecha_inicio
                                                                    )  
                    And a.SZSGNME_SEQ_NO = (select max (a1.SZSGNME_SEQ_NO)
                                                            from SZSGNME a1
                                                            Where a1.SZSGNME_NO_REGLA = a.SZSGNME_NO_REGLA
                                                           And a.SZSGNME_STAT_IND = a1.SZSGNME_STAT_IND
                                                            And a.SZSGNME_TERM_NRC = a1.SZSGNME_TERM_NRC
                                                             And trunc (a.SZSGNME_START_DATE) = trunc ( a1.SZSGNME_START_DATE)
                                                            )
                    ) x
                             where 1=1    ;                             
                    
            
                Exception
                    When Others then 
                    null;
                          --       DBMS_OUTPUT.PUT_LINE('SALIDA    '||sqlerrm);
               End;
               Commit;
               
            End Loop;
            */
            
            
            
            
            
             vl_exito := PKG_MOODLE2.F_UPDATE_TMP_SYNC ( 3,  trim (p_regla), p_fecha_inicio, 'genera_historias' );        
        
     End;
 
PROCEDURE sp_email
IS
    vl_email_prof varchar2(100);

    begin

        for c in (select distinct 
                                spriden_pidm PIDM_PROF,
                                CLAVE_PROF
                  from SATURN.SZTACTA, SPRIDEN
                  where 1  = 1
                            and spriden_change_ind is null
                            and spriden_id = CLAVE_PROF 
                  )loop
                  
                        
                        begin
                        
                         select distinct GOREMAL_EMAIL_ADDRESS MAIL
                         into vl_email_prof
                        from GOREMAL
                        where GOREMAL_EMAL_CODE = 'PRIN'
                        and GOREMAL_pidm = c.PIDM_PROF;               
                        
                        exception when others then
                            null;
                        end;
                   
                         Begin
                            update SATURN.SZTACTA
                            set EMAIL = vl_email_prof
                            where CLAVE_PROF = c.CLAVE_PROF;
                                
                          Exception
                            When others then
                          null;
                         End;        
                             
                  end loop;
              
              
    end;              
       
     
PROCEDURE sp_sube_OPM(p_regla number, p_fecha_inicio date, p_tabla varchar2) is
    
v_sal  varchar2(2500):= null;
vl_existe number :=0;


Begin 
---CREADO PARA SUBIR CLAIFICACIONES A BANNER DESDE SIR CON ARCHIVO CSV
    
        For c in (            
             select distinct 
                                        a.pidm Pidm, 
                                        a.Matricula Matricula,
                                        a.CALIFICACION Califica, 
                                        a.CVE_MATERIA, 
                                        a.FECHA_INICIO, 
                                        decode(SZTPRONO_TERM_CODE,null,a.periodo,SZTPRONO_TERM_CODE) Periodo,
                                        a.GRUPO,
                                        SFRSTCR_GRDE_CODE ,
                                        SFRSTCR_TERM_CODE , 
                                        SFRSTCR_CAMP_CODE Campus,    
                                        SFRSTCR_LEVL_CODE Nivel , 
                                        SFRSTCR_CRN CRN , 
                                        SFRSTCR_RSTS_CODE, 
                                        ESTATUS_MAT , 
                                        SSBSECT_PTRM_START_DATE,
                                        a.REGLA regla
                     from MIGRA.SZTACTA_TMP a    
                      left  join sztprono on SZTPRONO_ID = a.matricula and SZTPRONO_MATERIA_LEGAL = a.CVE_MATERIA and SZTPRONO_NO_REGLA = a.regla and SZTPRONO_ENVIO_MOODL = 'S'
                      join  sfrstcr  on sfrstcr_pidm =  a.pidm and   trim (SFRSTCR_TERM_CODE) = trim (a.periodo) and SFRSTCR_PTRM_CODE = parte
                      left join  ssbsect b on b.SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE 
                                                and b.SSBSECT_CRN = SFRSTCR_CRN  
                                                And b.SSBSECT_SEQ_NUMB =lpad(a.grupo,2,'0')
                      join sztmaco on SZTMACO_MATPADRE  =  a.CVE_MATERIA and SZTMACO_MATHIJO = SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB 
                    where 1=1
            --         and regla= p_regla
              --       and fecha_inicio = p_fecha_inicio
                 --  And matricula = '010199273'
                      order by  2  
                    
              --     end if;                                                     
            ) 
          
            Loop
       
    
v_sal := null;   

 --dbms_output.put_line('LLEGA..');
                If  c.SFRSTCR_RSTS_CODE = c.estatus_mat and c.SFRSTCR_RSTS_CODE = 'RE' and c.califica = c.SFRSTCR_GRDE_CODE then 
                                    Update SZSTUME a
                                    set a.SZSTUME_GRDE_CODE_FINAL = c.califica,
                                         a.SZSTUME_POBI_SEQ_NO = 1,
                                         a.SZSTUME_OBS = 'Calificacion Actualizada Carga'
                                     Where a.SZSTUME_PIDM = c.pidm
                                     And a.SZSTUME_SUBJ_CODE = c.cve_materia
                                     And a.SZSTUME_NO_REGLA = c.regla
                                     And  a.SZSTUME_STAT_IND = '1'
                                    And a.SZSTUME_RSTS_CODE = 'RE'
                                    And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                from SZSTUME a1
                                                                                Where 1=1
                                                                                And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                                                And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                                                And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                            )  ;                                                                        
                                                                            

                ElsIf  c.califica != c.SFRSTCR_GRDE_CODE  then                 
                    dbms_output.put_line('Actualiza la calificacion');
 
                                    Begin
                                    
                                        Update SZSTUME a
                                        set a.SZSTUME_GRDE_CODE_FINAL = c.califica,
                                             a.SZSTUME_POBI_SEQ_NO = 1,
                                             a.SZSTUME_OBS = 'Calificacion Actualizada Carga'
                                         Where a.SZSTUME_PIDM = c.pidm
                                         And a.SZSTUME_SUBJ_CODE = c.cve_materia
                                         And a.SZSTUME_NO_REGLA = c.regla
                                         And  a.SZSTUME_STAT_IND = '1'
                                        And a.SZSTUME_RSTS_CODE = c.estatus_mat
                                        And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                    from SZSTUME a1
                                                                                    Where 1=1
                                                                                    And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                                                    And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                                                    And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                                )  ;      
                                          Commit;                       
                                    Exception
                                        When Others then 
                                            null;
                                    End;
 
 
                                   Begin
                                            Update sfrstcr
                                            set  SFRSTCR_GRDE_CODE  = c.califica,
                                            SFRSTCR_DATA_ORIGIN = 'CALIFICA',
                                            SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                         --   SFRSTCR_RSTS_CODE = c.estatus_mat,
                                            SFRSTCR_GRDE_DATE = sysdate,
                                            SFRSTCR_RSTS_CODE ='RE'
                                            Where SFRSTCR_TERM_CODE = c.periodo
                                            And  SFRSTCR_CRN = c.crn
                                            And SFRSTCR_PIDM = c.pidm;
                                            Commit;
                                   Exception
                                    When Others then 
                                       dbms_output.put_line('Error al actulizar Calficacion '   ||sqlerrm);
                                   End;
                                   
                                   vl_existe :=0;
                                   
                                   Begin
                                            select count(1)
                                            Into vl_existe
                                            from shrtckn
                                            Where SHRTCKN_PIDM = c.pidm
                                            And SHRTCKN_TERM_CODE = c.periodo
                                            And SHRTCKN_CRN= c.crn;
                                   Exception
                                        When Others then 
                                              vl_existe :=0;  
                                   End;
                                   
                                   
                                   If vl_existe >= 1 then 
                                       
                                       Begin 
                                       dbms_output.put_line('Actualiza Historia'); 
                                               Update shrtckg
                                               set SHRTCKG_GRDE_CODE_FINAL = c.califica
                                               Where (SHRTCKG_PIDM, SHRTCKG_TERM_CODE, SHRTCKG_TCKN_SEQ_NO) in (select SHRTCKN_PIDM, SHRTCKN_TERM_CODE, SHRTCKN_SEQ_NO
                                                                                                                                                                    from SHRTCKN
                                                                                                                                                                    Where SHRTCKN_PIDM = c.pidm
                                                                                                                                                                    And SHRTCKN_TERM_CODE = c.periodo
                                                                                                                                                                    And SHRTCKN_CRN= c.crn);
                                       Exception
                                        When Others then 
                                            dbms_output.put_line('Error al actulizar historia '   ||sqlerrm);
                                       End;
                                   Else

                                            v_sal := PKG_MOODLE2.F_PASE_HISTORIA_CALIFICA ( c.campus, c.nivel, c.periodo, c.crn, c.pidm );  --- Envia a Historia Academica
                                            dbms_output.put_line('SALIDA X MATERIA NUEVA '||c.cve_materia ||'*'||v_sal);
                                            
                                            If v_sal = 'Exito' then 
                                                     dbms_output.put_line('Actualiza por Historias');
                                            
                                            End if;                                            
                                   
                                   End if;
                                                                   
               ElsIf  c.califica is not null and  c.SFRSTCR_GRDE_CODE is null   then                 
                    dbms_output.put_line('Actualiza la calificacion vacio');
                                  Begin
                                            Update SZSTUME a
                                            set a.SZSTUME_GRDE_CODE_FINAL = c.califica,
                                                 a.SZSTUME_POBI_SEQ_NO = 1,
                                                 a.SZSTUME_OBS = 'Calificacion Actualizada Carga'
                                             Where a.SZSTUME_PIDM = c.pidm
                                             And a.SZSTUME_SUBJ_CODE = c.cve_materia
                                             And a.SZSTUME_NO_REGLA = c.regla
                                             And  a.SZSTUME_STAT_IND = '1'
                                            And a.SZSTUME_RSTS_CODE = 'RE'
                                            And a.SZSTUME_SEQ_NO = (select max (a1.SZSTUME_SEQ_NO)
                                                                                        from SZSTUME a1
                                                                                        Where 1=1
                                                                                        And a.SZSTUME_TERM_NRC = a1.SZSTUME_TERM_NRC
                                                                                        And a.SZSTUME_PIDM = a1.SZSTUME_PIDM
                                                                                        And a.SZSTUME_STAT_IND =  a1.SZSTUME_STAT_IND
                                                                                        And a.SZSTUME_RSTS_CODE = a1.SZSTUME_RSTS_CODE
                                                                                        And a.SZSTUME_NO_REGLA = a1.SZSTUME_NO_REGLA
                                                                                    )  ;
                                              Commit;
                                  Exception
                                    When Others then 
                                        null;     
                                  End;                   
 
                                   Begin
                                            Update sfrstcr
                                            set  SFRSTCR_GRDE_CODE  = c.califica,
                                            SFRSTCR_DATA_ORIGIN = 'CALIFICA',
                                            SFRSTCR_ACTIVITY_DATE = SYSDATE,
                                            SFRSTCR_RSTS_CODE = c.estatus_mat,
                                            SFRSTCR_GRDE_DATE = sysdate
                                            Where SFRSTCR_TERM_CODE = c.periodo
                                            And  SFRSTCR_CRN = c.crn
                                            And SFRSTCR_PIDM = c.pidm;
                                            Commit;
                                   Exception
                                    When Others then 
                                       dbms_output.put_line('Error al actulizar Calficacion '   ||sqlerrm);
                                   End;
                                   
                                   vl_existe :=0;
                                   
                                   Begin
                                            select count(1)
                                            Into vl_existe
                                            from shrtckn
                                            Where SHRTCKN_PIDM = c.pidm
                                            And SHRTCKN_TERM_CODE = c.periodo
                                            And SHRTCKN_CRN= c.crn;
                                   Exception
                                        When Others then 
                                              vl_existe :=0;  
                                   End;
                                   
                                   
                                   If vl_existe >= 1 then 
                                       
                                       Begin 
                                       dbms_output.put_line('Actualiza Historia'); 
                                               Update shrtckg
                                               set SHRTCKG_GRDE_CODE_FINAL = c.califica
                                               Where (SHRTCKG_PIDM, SHRTCKG_TERM_CODE, SHRTCKG_TCKN_SEQ_NO) in (select SHRTCKN_PIDM, SHRTCKN_TERM_CODE, SHRTCKN_SEQ_NO
                                                                                                                                                                    from SHRTCKN
                                                                                                                                                                    Where SHRTCKN_PIDM = c.pidm
                                                                                                                                                                    And SHRTCKN_TERM_CODE = c.periodo
                                                                                                                                                                    And SHRTCKN_CRN= c.crn);
                                       Exception
                                        When Others then 
                                            dbms_output.put_line('Error al actulizar historia '   ||sqlerrm);
                                       End;
                                   Else

                                            v_sal := PKG_MOODLE2.F_PASE_HISTORIA_CALIFICA ( c.campus, c.nivel, c.periodo, c.crn, c.pidm );  --- Envia a Historia Academica
                                            dbms_output.put_line('SALIDA X MATERIA NUEVA '||c.cve_materia ||'*'||v_sal);
                                            
                                            If v_sal = 'Exito' then 
                                                     dbms_output.put_line('Actualiza por Historias');
                                            
                                            End if;                                            
                                   
                                   End if;
                                
                Elsif c.SFRSTCR_RSTS_CODE is null then 
                      Begin
                            Update SFRSTCR
                            set SFRSTCR_RSTS_CODE = 'RE'
                            Where SFRSTCR_pidm = c.pidm
                            And SFRSTCR_TERM_CODE = c.periodo
                            And  SFRSTCR_CRN = c.crn ;
                      Exception
                        When Others then 
                            null;
                      End;
                                    
                End if;

End Loop;
Commit;
    
end;                                                                 
END PKG_ACTAS;
/

DROP PUBLIC SYNONYM PKG_ACTAS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ACTAS FOR BANINST1.PKG_ACTAS;
