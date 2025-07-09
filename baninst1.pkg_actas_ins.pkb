DROP PACKAGE BODY BANINST1.PKG_ACTAS_INS;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_ACTAS_INS IS
PROCEDURE sp_actas(p_regla number, p_fecha_inicio date)
IS


      Begin
       delete SZTACTA_INS
       Commit;
        For xxx in (
        
                select distinct SZSGNME_PIDM pidm , SZSGNME_NO_REGLA regla
                    from SZSGNME
                    where SZSGNME_NO_REGLA in (p_regla)
                     And trunc (SZSGNME_START_DATE)   = p_fecha_inicio
                   -- and SZSGNME_PIDM = 205873

                    
                    ) loop


                 Begin 


   Insert into SZTACTA_INS
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
                             (select PARCIAL1 from SZTACTA_TMP_INSUR where PIDM = x.pidm and MATRICULA = x.matricula and regla = xxx.regla and cve_materia=x.cve_materia and grupo=x.grupo) PARCIAL1,
                             (select PARCIAL2 from SZTACTA_TMP_INSUR where PIDM = x.pidm and MATRICULA = x.matricula and regla = xxx.regla and cve_materia=x.cve_materia and grupo=x.grupo) PARCIAL2,
                             (select PARCIAL3 from SZTACTA_TMP_INSUR where PIDM = x.pidm and MATRICULA = x.matricula and regla = xxx.regla and cve_materia=x.cve_materia and grupo=x.grupo) PARCIAL3,
                                x.Calificacion,
                                x.CALIF_LETRA,
                                x.FECHA_FIN,
                                x.campus,
                                x.Nivel,
                                x.Fecha_inicio,
                                x.Regla,
                                x.Fecha_inicio||'-'||x.periodo_nrc||'-'||get_crn_regla (x.pidm,  null,   x.Cve_Materia,x.regla) folio,
                                x.EMAIL
                            from (  
                                      select distinct --ROW_NUMBER() OVER(PARTITION BY  e.SZTGPME_TERM_NRC_COMP||substr (e.SZTGPME_TERM_NRC, length (e.SZTGPME_TERM_NRC) -1, 2) ORDER BY e.SZTGPME_TERM_NRC_COMP||substr (e.SZTGPME_TERM_NRC, length (e.SZTGPME_TERM_NRC) -1, 2)) REG,
                                        1 seq,
                                        d.spriden_pidm pidm,
                                        ' ' ESTADO_ALUMNO,
                                        'ORDINARIO' TIPO_EVALUACION,
                                        NVL((select distinct SZTPRONO_TERM_CODE
                                            from sztprono
                                            where SZTPRONO_PIDM =  c.SZSTUME_PIDM
                                            and rownum = 1
                                            And SZTPRONO_NO_REGLA = xxx.regla
                                        ),xx.periodo) Periodo,
                                        (select distinct SZTPRONO_PTRM_CODE
                                            from sztprono
                                            where SZTPRONO_PIDM =  c.SZSTUME_PIDM
                                            and rownum = 1
                                            And SZTPRONO_NO_REGLA = xxx.regla
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
                                        nvl((select distinct SZTPRONO_PROGRAM
                                            from sztprono
                                            where SZTPRONO_PIDM =  c.SZSTUME_PIDM
                                            and rownum = 1
                                            And SZTPRONO_NO_REGLA = xxx.regla
                                            and xx.CVE_MATERIA=SZTPRONO_MATERIA_LEGAL
                                        ),xx.programa) cve_programa ,
                                        (select distinct SZTDTEC_PROGRAMA_COMP
                                            from SZTDTEC
                                            where 1= 1 
                                            And (SZTDTEC_PROGRAM = (select distinct SZTPRONO_PROGRAM
                                                                                            from sztprono
                                                                                            where SZTPRONO_PIDM =  c.SZSTUME_PIDM
                                                                                            And SZTPRONO_NO_REGLA = xxx.regla
                                                                                            and xx.CVE_MATERIA=SZTPRONO_MATERIA_LEGAL
                                                                                            and rownum = 1
                                                                                            )
                                                 
                                                 or
                                                 (SZTDTEC_PROGRAM = xx.programa)
                                                 )
                                            and rownum = 1
                                          ) PROGRAMA,
                                        --  '', PARCIAL1,
                                       --   '', PARCIAL2,
                                        --  '', PARCIAL3,
                                       c.SZSTUME_GRDE_CODE_FINAL Calificacion,--h.calif Calificacion, 
                                       f.SHRGRDE_ABBREV CALIF_LETRA,--h.CALIF_LETR CALIF_LETRA, 
                                        TRUNC (SYSDATE) FECHA_FIN,
                                        e.SZTGPME_CAMP_CODE campus,
                                        e.SZTGPME_LEVL_CODE Nivel,
                                        trunc (e.SZTGPME_START_DATE)  Fecha_inicio,
                                        e.SZTGPME_NO_REGLA Regla,
                                        e.SZTGPME_TERM_NRC_COMP periodo_nrc,
                                        g.SCBCRSE_TITLE matcrse,
                                        szstume_rsts_code PR,
                                        '' EMAIL
                    from SZSGNME a
                    join spriden b on b.spriden_pidm = a.SZSGNME_PIDM
                                      and b.spriden_pidm = xxx.pidm
                                       and b.spriden_change_ind is null
                    join SZSTUME c on  c.SZSTUME_TERM_NRC = a.SZSGNME_TERM_NRC
                        and c.SZSTUME_STAT_IND in ('1','0')--,'2'
                        and c.SZSTUME_NO_REGLA = xxx.regla
                        and c.SZSTUME_START_DATE=p_fecha_inicio
                       /* and c.SZSTUME_RSTS_CODE= ( select estatus_mat from sztacta_tmp_insur
                                                   where pidm=c.szstume_pidm 
                                                     and CVE_MATERIA = c.SZSTUME_SUBJ_CODE
                                                )*/
                      --  and c.SZSTUME_RSTS_CODE =  'RE'
                    --    And SZSTUME_GRDE_CODE_FINAL != '0'
                    join spriden d on d.spriden_pidm = c.SZSTUME_PIDM
                        and d.SPRIDEN_CHANGE_IND is null --and d.spriden_id = '020047259'
                        AND c.szstume_seq_no = (SELECT MAX (c1.szstume_seq_no)
                                        FROM szstume c1
                                        WHERE 1=1
                                        AND c.szstume_pidm = c1.szstume_pidm
                                        AND c.szstume_no_regla = c1.szstume_no_regla
                                        AND c.szstume_term_nrc = c1.szstume_term_nrc
                                        AND c.SZSTUME_START_DATE=c1.SZSTUME_START_DATE
                                        )
                    join migra.sztacta_tmp_insur xx  on xx.pidm =  SZSTUME_PIDM and xx.CVE_MATERIA = c.SZSTUME_SUBJ_CODE
                    join SZTGPME e on e.SZTGPME_TERM_NRC = a.SZSGNME_TERM_NRC and SZTGPME_STAT_IND = '1' and e.SZTGPME_NO_REGLA = xxx.regla and  SZTGPME_START_DATE=p_fecha_inicio  and SZTGPME_GRUPO=xx.grupo
                    left join SHRGRDE f on f.SHRGRDE_CODE = c.SZSTUME_GRDE_CODE_FINAL 
                                               AND f.SHRGRDE_LEVL_CODE = e.sztgpme_levl_code
                    join SCBCRSE g on e.SZTGPME_SUBJ_CRSE = g.SCBCRSE_SUBJ_CODE||g.SCBCRSE_CRSE_NUMB
                
                    where a.SZSGNME_NO_REGLA = xxx.regla
                    And a.SZSGNME_STAT_IND = '1'
                    And a.SZSGNME_SEQ_NO = (select max (a1.SZSGNME_SEQ_NO)
                                                            from SZSGNME a1
                                                            Where a1.SZSGNME_NO_REGLA = a.SZSGNME_NO_REGLA
                                                           And a.SZSGNME_STAT_IND = a1.SZSGNME_STAT_IND
                                                            And a.SZSGNME_TERM_NRC = a1.SZSGNME_TERM_NRC
                                                          --  and  a1.SZSGNME_PIDM=xxx.pidm
                                                          --  and a1.SZSGNME_PTRM=xx.parte
                                                          --  and SZSGNME_START_DATE=p_fecha_inicio
                                                            )
                    ) x
                             where 1=1
--                             AND  x.pidm  in (select 
--                                                           PIDM
--                                                       from TZTPROG A
--                                                       where 1=1
--                                                       AND a.ESTATUS not in ('CV')
--                                                       AND a.MATRICULACION = (SELECT MAX (a1.MATRICULACION)
--                                                                                               FROM TZTPROG A1
--                                                                                               WHERE 1=1
--                                                                                               AND a.PIDM = a1.PIDM
--                                                                                               AND a1.ESTATUS not in ('CV')
--                                                                                               )
--                                                                                                           )
 --                  And  x.Matricula = '020081050'
-- and x.matricula='230345091'
                                                            ;
            
                Exception
                    When Others then 
                    null;
                                -- DBMS_OUTPUT.PUT_LINE('SALIDA    '||sqlerrm);
               End;
               Commit;
               
            End Loop;
        
     End;
 
PROCEDURE sp_email
IS
    vl_email_prof varchar2(100);

    begin

        for c in (select distinct 
                                spriden_pidm PIDM_PROF,
                                CLAVE_PROF
                  from SATURN.SZTACTA_INS, SPRIDEN
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
                            update SATURN.SZTACTA_INS
                            set EMAIL = vl_email_prof
                            where CLAVE_PROF = c.CLAVE_PROF;
                                
                          Exception
                            When others then
                          null;
                         End;        
                             
                  end loop;
              
              
    end;              
                                                                  
END PKG_ACTAS_INS;
/

DROP PUBLIC SYNONYM PKG_ACTAS_INS;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ACTAS_INS FOR BANINST1.PKG_ACTAS_INS;
