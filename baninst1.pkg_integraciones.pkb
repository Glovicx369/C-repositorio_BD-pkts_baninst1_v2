DROP PACKAGE BODY BANINST1.PKG_INTEGRACIONES;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_INTEGRACIONES IS

function f_alumnos_info(p_matricula in varchar2 DEFAULT NULL)RETURN PKG_INTEGRACIONES.cursor_alums_info AS
  
 c_out_alums_info PKG_INTEGRACIONES.cursor_alums_info;
 
 BEGIN
 
  open c_out_alums_info
                 FOR
                 --Cambiar5 a sarappd, último registro decisión 35 y 53
                        Select distinct 
                                spriden_id Matricula,
                                INITCAP (spriden_first_name)||INITCAP (replace(spriden_last_name,'/',' ')) NOMBRE_ALUMNO, 
                                (SELECT DISTINCT STVNATN_NATION FROM SPRADDR, STVNATN WHERE 1=1 AND SPRADDR_NATN_CODE = STVNATN_CODE AND SPRADDR_PIDM = PIDM and SPRADDR_ATYP_CODE = 'RE') PAIS,
                                pkg_utilerias.f_edad(pidm) EDAD,  
                                a.nombre LICENCIATURA,
                                pkg_utilerias.f_ocupacion(pidm) OCUPACION,                                
                                DECODE(pkg_utilerias.f_genero(PIDM),'Femenino','MUJER','HOMBRE')GENERO_SEX                               
                            from tztprog a
                                join spriden on a.PIDM = spriden_pidm                                      
                                where 1=1
                                  and spriden_change_ind is null
                                  AND spriden_id  = DECODE(p_matricula,null,matricula,p_matricula);
                                  
                  return(c_out_alums_info);                
 
 
  END f_alumnos_info;
  
 function f_alumnos_bienvenida(p_matricula in varchar2 DEFAULT NULL)RETURN PKG_INTEGRACIONES.cursor_alums AS
  
 c_out_alums PKG_INTEGRACIONES.cursor_alums;
 
 BEGIN
 
  open c_out_alums
                 FOR
                                 Select distinct 
                                    spriden_id Matricula,
                                    INITCAP (spriden_first_name) NOMBRE_ALUMNO, 
                                    INITCAP (replace(spriden_last_name,'/',' '))APELLIDOS,                               
                                    (   select 
                                            SPRADDR_CITY 
                                        from SPRADDR                                     
                                        where 
                                            SPRADDR_PIDM = spriden_pidm
                                        And SPRADDR_ATYP_CODE ='NA'   
                                        and SPRADDR_SEQNO in (select max (sp.SPRADDR_SEQNO) from SPRADDR sp
                                                                where sp.SPRADDR_PIDM = spriden_pidm
                                                                And   sp.SPRADDR_ATYP_CODE ='NA'
                                                                )  )CIUDAD,
                                    to_char(f.SORLCUR_START_DATE,'dd/mm/yyyy') FECHA_INICIO, 
                                   -- PKG_UTILERIAS.f_celular (spriden_pidm, 'CELU' )CELULAR,
                                    case 
                                        when
                                             substr(PKG_UTILERIAS.f_celular (spriden_pidm, 'CELU' ),1,1)= '+' then
                                                PKG_UTILERIAS.f_celular (spriden_pidm, 'CELU' )
                                        when    substr(PKG_UTILERIAS.f_celular (spriden_pidm, 'CELU' ),1,1) != '+' then 
                                            '+'||PKG_UTILERIAS.f_celular (spriden_pidm, 'CELU' )
                                       end CELULAR,
                                    pkg_utilerias.f_correo(spriden_pidm,'PRIN')CORREO,
                                    (
                                        Select   sprtele_phone_area COD_AREA                      
                                         from sprtele tele
                                         Where  tele.sprtele_pidm = spriden_pidm
                                         and tele.sprtele_tele_code = 'CELU'
                                         and tele.sprtele_surrogate_id = (select max (tele1.sprtele_surrogate_id)
                                                                                  from sprtele tele1
                                                                                  where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                                  and  tele.sprtele_tele_code =  tele1.sprtele_tele_code)
                                    )COD_AREA,
                                    f.sorlcur_program PROGRAMA,
                                    f.sorlcur_levl_code NIVEL,
                                    g.GORADID_ADDITIONAL_ID REFERENCIA_PAGO,
                                    (SELECT DISTINCT STVNATN_NATION FROM SPRADDR, STVNATN WHERE 1=1 AND SPRADDR_NATN_CODE = STVNATN_CODE AND SPRADDR_PIDM = spriden_pidm and SPRADDR_ATYP_CODE = 'RE') PAIS
                                from   sarappd a
                                    join spriden on a.sarappd_pidm = spriden_pidm
                                    join saradap p on a.sarappd_pidm = p.saradap_pidm   
                                    join sorlcur f on f.sorlcur_pidm = spriden_pidm 
                                    left join goradid g on g.GORADID_PIDM = spriden_pidm
                                    where 1=1
                                        and a.SARAPPD_APDC_CODE in (35,53)
                                        and spriden_change_ind is null
                                        AND a.sarappd_seq_no = (select max(pp.sarappd_seq_no)
                                                    FROM sarappd pp
                                                    WHERE a.sarappd_pidm=pp.sarappd_pidm
                                                    and a.sarappd_term_code_entry =pp.sarappd_term_code_entry
                                                    And a.SARAPPD_APPL_NO = pp.SARAPPD_APPL_NO)
                                        and a.sarappd_appl_no = (select max(ppl.sarappd_appl_no)
                                                    FROM sarappd ppl
                                                    WHERE a.sarappd_pidm=ppl.sarappd_pidm
                                                    and a.sarappd_term_code_entry =ppl.sarappd_term_code_entry
                                                    And a.SARAPPD_APPL_NO = ppl.SARAPPD_APPL_NO)  
                                       AND a.sarappd_appl_no=p.saradap_appl_no
                                       and a.sarappd_term_code_entry=p.saradap_term_code_entry
                                     --  And p.SARADAP_APST_CODE in ('A', 'R') 
                                       And f.sorlcur_program = p.SARADAP_PROGRAM_1
                                       and f.SORLCUR_LMOD_CODE = 'LEARNER'
                                       and f.SORLCUR_SEQNO = (select max (f1.SORLCUR_SEQNO)
                                                                 from sorlcur f1
                                                                 Where f.sorlcur_pidm = f1.sorlcur_pidm
                                                                 and f.sorlcur_camp_code = f1.sorlcur_camp_code
                                                                 and f.sorlcur_levl_code = f1.sorlcur_levl_code
                                                                 and f.SORLCUR_LMOD_CODE = f1.SORLCUR_LMOD_CODE
                                                                 And f.SORLCUR_PROGRAM = f1.SORLCUR_PROGRAM
                                                                 aND f.SORLCUR_TERM_CODE_CTLG = f1.SORLCUR_TERM_CODE_CTLG)
                                      and g.GORADID_ACTIVITY_DATE in (select max(gg.GORADID_ACTIVITY_DATE) from goradid gg
                                                                         where g.GORADID_PIDM = gg.GORADID_PIDM
                                                                         and gg.GORADID_ADID_CODE = 'REFH')
                                      and g.GORADID_ADID_CODE = 'REFH'
                                      AND spriden_id  = p_matricula;                             
                                  
                  return(c_out_alums);                
 
 
  END f_alumnos_bienvenida;
  
 function f_actualiza_reg(p_matricula in varchar2 DEFAULT NULL)RETURN PKG_INTEGRACIONES.cursor_actu_reg AS
  
 c_out_actu_reg PKG_INTEGRACIONES.cursor_actu_reg;
 
 BEGIN
 
 open c_out_actu_reg
    for
   
                      select distinct 
                                       spriden_id MATRICULA,
                                      ( SELECT STVLEVL_DESC 
                                        FROM STVLEVL
                                        WHERE
                                            STVLEVL_CODE = SGBSTDN_LEVL_CODE)NIVEL,
                                      ( select distinct SZTDTEC_PROGRAMA_COMP from sztdtec 
                                        where SGBSTDN_PROGRAM_1=SZTDTEC_PROGRAM and
                                              SZTDTEC_TERM_CODE=SGBSTDN_TERM_CODE_CTLG_1 and
                                              SZTDTEC_CAMP_CODE=SGBSTDN_CAMP_CODE) PROGRAMA,
                                       f.sorlcur_start_date  FECHA_INICIO,
                                      ( SELECT STVSTYP_DESC 
                                        FROM 
                                            STVSTYP
                                        WHERE    
                                            STVSTYP_CODE = SGBSTDN_STYP_CODE
                                       )TIPO_ALUMNO,
                                       STVSTST_DESC  ESTATUS_ALUMNO,
                                       SGBSTDN_CAMP_CODE,
                                       SGRSTSP_KEY_SEQNO
                                    from   sarappd a
                                    join spriden on a.sarappd_pidm = spriden_pidm 
                                    join SGBSTDN s on s.SGBSTDN_pidm = a.sarappd_pidm
                                    join saradap p on a.sarappd_pidm = p.saradap_pidm
                                    join sorlcur f on a.sarappd_pidm = f.sorlcur_pidm
                                    left join STVSTST on STVSTST_CODE = SGBSTDN_STST_CODE
                                    left join SGRSTSP sg on sg.SGRSTSP_PIDM =  a.sarappd_pidm 
                                                            and sg.SGRSTSP_KEY_SEQNO in (
                                                                                       select max(sgg.SGRSTSP_KEY_SEQNO) 
                                                                                       from SGRSTSP sgg
                                                                                       where sgg.SGRSTSP_PIDM =  a.sarappd_pidm)
                                    where 1=1
                                        and spriden_change_ind is null
                                        and a.SARAPPD_APDC_CODE in (35,53)                                       
                                        AND a.sarappd_seq_no = (select max(pp.sarappd_seq_no)
                                                    FROM sarappd pp
                                                    WHERE a.sarappd_pidm=pp.sarappd_pidm
                                                    and a.sarappd_term_code_entry =pp.sarappd_term_code_entry
                                                    And a.SARAPPD_APPL_NO = pp.SARAPPD_APPL_NO)
                                        and a.sarappd_appl_no = (select max(ppl.sarappd_appl_no)
                                                    FROM sarappd ppl
                                                    WHERE a.sarappd_pidm=ppl.sarappd_pidm
                                                    and a.sarappd_term_code_entry =ppl.sarappd_term_code_entry
                                                    And a.SARAPPD_APPL_NO = ppl.SARAPPD_APPL_NO)  
                                       AND a.sarappd_appl_no=p.saradap_appl_no
                                       and a.sarappd_term_code_entry=p.saradap_term_code_entry
                                     --  And p.SARADAP_APST_CODE in ('A', 'R') 
                                       And s.SGBSTDN_PROGRAM_1 = p.SARADAP_PROGRAM_1 
                                       and s.SGBSTDN_TERM_CODE_EFF = ( select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                         from sgbstdn a1
                                                                         where s.sgbstdn_pidm = a1.sgbstdn_pidm
                                                                         And s.sgbstdn_camp_code = a1.sgbstdn_camp_code
                                                                         and s.sgbstdn_levl_code = a1.sgbstdn_levl_code
                                                                         and s.sgbstdn_program_1 = a1.sgbstdn_program_1
                                                                         )
                                        and f.sorlcur_pidm = s.sgbstdn_pidm
                                        And f.sorlcur_program = s.sgbstdn_program_1
                                        and f.SORLCUR_LMOD_CODE = 'LEARNER'
                                        and f.SORLCUR_SEQNO = (select max (f1.SORLCUR_SEQNO)
                                                                 from sorlcur f1
                                                                 Where f.sorlcur_pidm = f1.sorlcur_pidm
                                                                 and f.sorlcur_camp_code = f1.sorlcur_camp_code
                                                               --  and f.sorlcur_levl_code = f1.sorlcur_levl_code
                                                                 and f.SORLCUR_LMOD_CODE = f1.SORLCUR_LMOD_CODE
                                                               --  And f.SORLCUR_PROGRAM = f1.SORLCUR_PROGRAM
                                                                  )
                                         AND s.sgbstdn_pidm  = fget_pidm(p_matricula);
            return(c_out_actu_reg);
 END f_actualiza_reg;

 function f_alumnos_hub(p_matricula in varchar2 DEFAULT NULL, p_email in varchar2 DEFAULT NULL)RETURN PKG_INTEGRACIONES.cursor_hub AS
  
 c_out_alums_hub PKG_INTEGRACIONES.cursor_hub;
 
 BEGIN
 
                IF p_matricula IS NOT NULL AND p_email IS NOT NULL THEN
                    open c_out_alums_hub
                             FOR                
                
                                    select distinct 
                                            spriden_id MATRICULA,
                                            upper (spriden_first_name)||' '||upper(replace(spriden_last_name,'/',' ')) NOMBRE_ALUMNO,
                                            decode(a.estatus,'EG','EGRESADO','ESTUDIANTE')Tipo_Usuario,
                                            STVLEVL_DESC NIVEL,
                                            STVSTST_DESC ESTATUS,
                                            b.nivel_riesgo NIVEL_RIESGO,
                                            SZTHITA_AVANCE AVANCE,
                                            pkg_utilerias.f_calcula_bimestres(a.PIDM,a.sp)BIMESTRE,
                                            pkg_utilerias.f_mora(a.pidm) MORA,
                                            pkg_utilerias.f_correo(a.pidm,'PRIN')EMAIL,
                                            pkg_utilerias.f_celular (a.pidm, 'CELU' )MOVIL
                                     from tztprog a
                                     join spriden on   spriden_pidm = a.PIDM   and spriden_change_ind is null
                                     left join szthita on szthita_pidm = a.PIDM and SZTHITA_PROG = a.programa
                                     LEFT JOIN NIVEL_RIESGO b on b.matricula = a.matricula
                                     join STVLEVL on STVLEVL_CODE = a.nivel
                                     left join goremal on goremal_pidm = a.pidm and GOREMAL_EMAL_CODE='PRIN'  and GOREMAL_PREFERRED_IND = 'Y'
                                     left join STVSTST on STVSTST_CODE = A.ESTATUS
                                     where   1=1
                                       and spriden_change_ind is null 
                                       and a.sp in (select max(aa.sp) 
                                                    from tztprog aa
                                                    where
                                                        aa.PIDM = spriden_pidm
                                                    )
                                       and spriden_id = p_matricula
                                       and goremal_email_address = p_email                                                
                                    order by matricula,nivel;
                   
                    end if;
                   
                    if  p_matricula IS NOT NULL AND p_email IS  NULL THEN
                        open c_out_alums_hub
                        FOR    
                          select distinct 
                                    spriden_id MATRICULA,
                                    upper (spriden_first_name)||' '||upper(replace(spriden_last_name,'/',' ')) NOMBRE_ALUMNO,
                                    decode(a.estatus,'EG','EGRESADO','ESTUDIANTE')Tipo_Usuario,
                                    STVLEVL_DESC NIVEL,
                                    STVSTST_DESC ESTATUS,
                                    b.nivel_riesgo NIVEL_RIESGO,
                                    SZTHITA_AVANCE AVANCE,
                                    pkg_utilerias.f_calcula_bimestres(a.PIDM,a.sp)BIMESTRE,
                                    pkg_utilerias.f_mora(a.pidm) MORA,
                                    pkg_utilerias.f_correo(a.pidm,'PRIN')EMAIL,
                                    pkg_utilerias.f_celular (a.pidm, 'CELU' )MOVIL
                             from tztprog a
                             join spriden on  spriden_pidm = a.PIDM  and spriden_change_ind is null
                             left join szthita on szthita_pidm = a.PIDM and SZTHITA_PROG = a.programa
                             LEFT JOIN NIVEL_RIESGO b on b.matricula = a.matricula
                             join STVLEVL on  STVLEVL_CODE = a.nivel 
                             left join STVSTST on STVSTST_CODE = A.ESTATUS
                             where   1=1
                               and spriden_change_ind is null 
                               and a.sp in (select max(aa.sp) 
                                            from tztprog aa
                                            where
                                                aa.PIDM = a.pidm
                                            )
                               and a.matricula = p_matricula                                              
                            order by matricula,nivel;
                       
                   end if;
                   
                   if  p_matricula IS  NULL AND p_email IS NOT NULL THEN
                       open c_out_alums_hub
                         FOR    
                         select distinct 
                                spriden_id MATRICULA,
                                upper (spriden_first_name)||' '||upper(replace(spriden_last_name,'/',' ')) NOMBRE_ALUMNO,
                                decode(a.estatus,'EG','EGRESADO','ESTUDIANTE')Tipo_Usuario,
                                STVLEVL_DESC NIVEL,
                                STVSTST_DESC ESTATUS,
                                b.nivel_riesgo NIVEL_RIESGO,
                                SZTHITA_AVANCE AVANCE,
                                pkg_utilerias.f_calcula_bimestres(a.PIDM,a.sp)BIMESTRE,
                                pkg_utilerias.f_mora(a.pidm) MORA,
                                pkg_utilerias.f_correo(a.pidm,'PRIN')EMAIL,
                                pkg_utilerias.f_celular (a.pidm, 'CELU' )MOVIL
                         from tztprog a
                         join spriden on  spriden_pidm = a.PIDM  and spriden_change_ind is null
                         left join szthita on szthita_pidm = a.PIDM and SZTHITA_PROG = a.programa
                         LEFT JOIN NIVEL_RIESGO b on b.matricula = a.matricula
                         join STVLEVL on  STVLEVL_CODE = a.nivel
                         left join goremal on goremal_pidm = a.pidm and GOREMAL_EMAL_CODE='PRIN'  and GOREMAL_PREFERRED_IND = 'Y'
                         left join STVSTST on STVSTST_CODE = A.ESTATUS
                         where   1=1                           
                           and a.sp in (select max(aa.sp) 
                                        from tztprog aa
                                        where
                                            aa.PIDM = a.pidm
                                        )
                           and goremal_email_address = p_email                                                 
                        order by matricula,nivel;
                        
                    END IF;  
                 
                  return(c_out_alums_hub); 
 
 END f_alumnos_hub;

END PKG_INTEGRACIONES;
/

DROP PUBLIC SYNONYM PKG_INTEGRACIONES;

CREATE OR REPLACE PUBLIC SYNONYM PKG_INTEGRACIONES FOR BANINST1.PKG_INTEGRACIONES;
