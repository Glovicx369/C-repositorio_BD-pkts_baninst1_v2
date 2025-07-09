DROP PACKAGE BODY BANINST1.PKG_DASHBOARD_DOCENTES;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_DASHBOARD_DOCENTES 
IS

  FUNCTION f_dashboard_docentes_out (p_matricula in varchar) RETURN PKG_DASHBOARD_DOCENTES.cursor_out
           AS
                c_out PKG_DASHBOARD_DOCENTES.cursor_out;

            BEGIN
                          open c_out
                            FOR
                                          with mayor as (
                                                      select distinct SORLFOS_PIDM, SORLFOS_LCUR_SEQNO, SORLFOS_SEQNO, SORLFOS_LFST_CODE, SORLFOS_MAJR_CODE, STVMAJR_DESC, s.sorlcur_program, s.sorlcur_key_seqno Study_Path    -- OMS 29/Febrero/2024
                                                                                   from sorlfos, stvmajr, sorlcur s
                                                                                   where SORLFOS_LFST_CODE = 'MAJOR'
                                                                                   and STVMAJR_CODE = SORLFOS_MAJR_CODE
                                                                                    and s.sorlcur_lmod_code='LEARNER'
                                                                                    and s.SORLCUR_CACT_CODE  != 'CHANGE'
                                                                                    and s.SORLCUR_PIDM    = SORLFOS_PIDM
                                                                                    and s.SORLCUR_SEQNO = SORLFOS_LCUR_SEQNO
                                                                                    and s.sorlcur_pidm= fget_pidm (p_matricula)
                                                                                    and s.sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ss
                                                                                                                   where  s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                                   and s.sorlcur_program=ss.sorlcur_program
                                                                                                                   and s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                   )
                                                           ),
                                        menor1 as (
                                                           select distinct a.SORLFOS_PIDM, a.SORLFOS_LCUR_SEQNO, a.SORLFOS_SEQNO, a.SORLFOS_LFST_CODE, a.SORLFOS_MAJR_CODE, STVMAJR_DESC, s.sorlcur_program
                                                                                   from sorlfos a, stvmajr, sorlcur s
                                                                                   where a.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                   and STVMAJR_CODE = a.SORLFOS_MAJR_CODE
                                                                                    and s.sorlcur_lmod_code='LEARNER'
                                                                                    and s.SORLCUR_CACT_CODE  != 'CHANGE'
                                                                                    and s.sorlcur_pidm= fget_pidm (p_matricula)
                                                                                    and s.SORLCUR_PIDM    = a.SORLFOS_PIDM
                                                                                    and s.SORLCUR_SEQNO = a.SORLFOS_LCUR_SEQNO
                                                                                    and a.SORLFOS_SEQNO = (select min (xx.SORLFOS_SEQNO)
                                                                                                                         from SORLFOS xx
                                                                                                                         where a.SORLFOS_PIDM = xx.SORLFOS_PIDM
                                                                                                                         and a.SORLFOS_LCUR_SEQNO = xx.SORLFOS_LCUR_SEQNO
                                                                                                                         and a.SORLFOS_LFST_CODE =  xx.SORLFOS_LFST_CODE)
                                                                                    and s.sorlcur_seqno in (select max(ss.sorlcur_seqno)
                                                                                                                        from sorlcur ss
                                                                                                                   where s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                                   and s.sorlcur_program=ss.sorlcur_program
                                                                                                                   and s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                   )
                                                           ) ,
                                         menor2 as (
                                                           select distinct c.SORLFOS_PIDM, c.SORLFOS_LCUR_SEQNO, c.SORLFOS_SEQNO, c.SORLFOS_LFST_CODE, c.SORLFOS_MAJR_CODE, STVMAJR_DESC, p.sorlcur_program
                                                                                   from sorlfos c, stvmajr, sorlcur p
                                                                                   where c.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                   and STVMAJR_CODE = c.SORLFOS_MAJR_CODE
                                                                                    and  p.sorlcur_pidm= fget_pidm (p_matricula)
                                                                                    and p.SORLCUR_PIDM    = c.SORLFOS_PIDM
                                                                                    and p.SORLCUR_SEQNO = c.SORLFOS_LCUR_SEQNO
                                                                                    and p.sorlcur_lmod_code='LEARNER'
                                                                                     and p.SORLCUR_CACT_CODE  != 'CHANGE'
                                                                                    and c.SORLFOS_SEQNO = (select max (xx.SORLFOS_SEQNO)
                                                                                                                         from SORLFOS xx
                                                                                                                             where c.SORLFOS_PIDM = xx.SORLFOS_PIDM
                                                                                                                             and c.SORLFOS_LCUR_SEQNO = xx.SORLFOS_LCUR_SEQNO
                                                                                                                             and c.SORLFOS_LFST_CODE =  xx.SORLFOS_LFST_CODE
                                                                                                                           )
                                                                                    and p.sorlcur_seqno in (select max(sn.sorlcur_seqno)
                                                                                                                        from sorlcur sn
                                                                                                                           where p.sorlcur_pidm=sn.sorlcur_pidm
                                                                                                                           and p.sorlcur_program=sn.sorlcur_program
                                                                                                                           and p.sorlcur_lmod_code=sn.sorlcur_lmod_code
                                                                                                                       )
                                                                                   and (c.SORLFOS_MAJR_CODE,p.sorlcur_program) not in ( select distinct  b.SORLFOS_MAJR_CODE,n.sorlcur_program
                                                                                                                                            from sorlfos b, stvmajr, sorlcur n
                                                                                                                                               where b.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                               and STVMAJR_CODE = b.SORLFOS_MAJR_CODE
                                                                                                                                               and  n.sorlcur_pidm=fget_pidm (p_matricula)
                                                                                                                                                and n.sorlcur_lmod_code='LEARNER'
                                                                                                                                                and n.SORLCUR_CACT_CODE  != 'CHANGE'
                                                                                                                                                and n.SORLCUR_PIDM    = b.SORLFOS_PIDM
                                                                                                                                                and n.SORLCUR_SEQNO = b.SORLFOS_LCUR_SEQNO
                                                                                                                                                and p.sorlcur_program = n.sorlcur_program
                                                                                                                                                and b.SORLFOS_SEQNO = (select min (xx.SORLFOS_SEQNO)
                                                                                                                                                                                           from SORLFOS xx
                                                                                                                                                                                             where b.SORLFOS_PIDM = xx.SORLFOS_PIDM
                                                                                                                                                                                             and b.SORLFOS_LCUR_SEQNO = xx.SORLFOS_LCUR_SEQNO
                                                                                                                                                                                             and b.SORLFOS_LFST_CODE =  xx.SORLFOS_LFST_CODE)
                                                                                                                                                and n.sorlcur_seqno in (select max(ss.sorlcur_seqno)
                                                                                                                                                                                    from sorlcur ss
                                                                                                                                                                                       where n.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                                                                                                       and n.sorlcur_program=ss.sorlcur_program
                                                                                                                                                                                       and n.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                   )
                                                                                                                                      )
                                                           )
                                                           select        (select  SPRIDEN_id 
                                                                       from SPRIDEN
                                                                       where 1=1
                                                                       and SPRIDEN_PIDM=sgbstdn_pidm
                                                                       and SPRIDEN_CHANGE_IND is null)matricula, 
                                                                       sgbstdn_pidm pidm,
                                                                           sgbstdn_stst_code Estatus_final,
                                                                           stvstst_desc Estatus,
                                                                           sgbstdn_program_1 Clave_Carrera,
                                                                           sgbstdn_program_1||'|'||sztdtec_programa_comp ||'|'||(select   SORLCUR_TERM_CODE_CTLG  from sorlcur s   where s.sorlcur_pidm= fget_pidm (p_matricula)
                                                                                                                                                                and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                                                and s.sorlcur_seqno in (select max(ss.sorlcur_seqno) from sorlcur ss
                                                                                                                                                                                           where  s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                                                                                                            and ss.sorlcur_program=a.sorlcur_program
                                                                                                                                                                                            and s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                            )) Carrera,    -- cambio para agregar periodo catalogo
                                                                           sgbstdn_camp_code Campus ,
                                                                           sgbstdn_levl_code Nivel,
                                                                           SGBSTDN_STYP_CODE tipo_inscripcion,
                                                                          stvstyp_desc inscripcion_desc,
                                                                         a.SORLFOS_MAJR_CODE Area_Mayor,
                                                                         a.STVMAJR_DESC Descripcion_Mayor,
                                                                         b.SORLFOS_MAJR_CODE Area_Menor_1,
                                                                         b.STVMAJR_DESC Descripcion_Salida_1,
                                                                         c.SORLFOS_MAJR_CODE Area_Menor_2,
                                                                         c.STVMAJR_DESC Descripcion_Salida_2,
                                                                         a.Study_Path                   -- OMS 29/Febrero/2024
                                                            from sgbstdn x, sztdtec, stvstst, stvstyp , mayor a, menor1 b, menor2 c
                                                                        where  sgbstdn_pidm = fget_pidm (p_matricula)
                                                                        AND     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn xx
                                                                                                                         where x.sgbstdn_pidm=xx.sgbstdn_pidm and x.sgbstdn_program_1=xx.sgbstdn_program_1)
                                                                        AND     sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO'
                                                                        AND     stvstst_code=sgbstdn_stst_code
                                                                        AND     stvstyp_code=sgbstdn_styp_code
                                                                        and      sgbstdn_pidm = a.SORLFOS_PIDM (+)
                                                                        and      sgbstdn_program_1 =  a.SORLCUR_PROGRAM (+)
                                                                        and      sgbstdn_pidm = b.SORLFOS_PIDM (+)
                                                                        and      sgbstdn_program_1 =  b.SORLCUR_PROGRAM   (+)
                                                                        and      sgbstdn_pidm = c.SORLFOS_PIDM (+)
                                                                        and      sgbstdn_program_1 =  c.SORLCUR_PROGRAM   (+)
                                                            union
                                                            select   distinct (select  SPRIDEN_id 
                                                                       from SPRIDEN
                                                                       where 1=1
                                                                       and SPRIDEN_PIDM=s.sorlcur_pidm
                                                                       and SPRIDEN_CHANGE_IND is null)matricula,
                                                                     s.sorlcur_pidm pidm,
                                                                     null Estatus_final,
                                                                     decode(s.sorlcur_cact_code,'ACTIVE','ACTIVO', 'INACTIVE','INACTIVO', 'CHANGE', 'CAMBIO PROGRAMA') Estatus,
                                                                     s.sorlcur_program Clave_Carrera,
                                                                     s.sorlcur_program||' '||sztdtec_programa_comp||'|'||SORLCUR_TERM_CODE_CTLG Carrera,    -- cambio para agregar periodo catalogo
                                                                     s.sorlcur_camp_code Campus,
                                                                     smrprle_levl_code nivel,
                                                                     null  tipo_inscripcion, '  ' inscripcion_desc,
                                                                     a.SORLFOS_MAJR_CODE Area_Mayor,
                                                                     a.STVMAJR_DESC Descripcion_Mayor,
                                                                     b.SORLFOS_MAJR_CODE Area_Menor_1,
                                                                     b.STVMAJR_DESC Descripcion_Salida_1,
                                                                     c.SORLFOS_MAJR_CODE Area_Menor_2,
                                                                     c.STVMAJR_DESC Descripcion_Salida_2,
                                                                     s.sorlcur_key_seqno Study_Path         -- OMS 29/Febrero/2024
                                                                     
                                                            from sorlcur s,  sztdtec, smrprle, mayor a, menor1 b, menor2 c
                                                                        where s.sorlcur_pidm=fget_pidm (p_matricula)
                                                                        and s.sorlcur_lmod_code='LEARNER'
                                                                        and s.sorlcur_seqno in (select max(ss.sorlcur_seqno) from sorlcur ss
                                                                                                       where  s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                       and s.sorlcur_program=ss.sorlcur_program
                                                                                                       and s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                       )
                                                                        and     smrprle_program=s.sorlcur_program
                                                                        and     sztdtec_program=s.sorlcur_program
                                                                        and     sztdtec_status='ACTIVO'
                                                                        and     s.SORLCUR_LMOD_CODE ='LEARNER'
                                                                        and     s.sorlcur_program not in (select sgbstdn_program_1 from sgbstdn
                                                                                                                    where sgbstdn_pidm=s.sorlcur_pidm)
                                                                         and    s.SORLCUR_PIDM = a.SORLFOS_PIDM
                                                                         and    s.SORLCUR_SEQNO = a.SORLFOS_LCUR_SEQNO
                                                                         and    s.SORLCUR_PROGRAM = a.SORLCUR_PROGRAM
                                                                         and    s.SORLCUR_PIDM = b.SORLFOS_PIDM (+)
                                                                         and    s.SORLCUR_SEQNO = b.SORLFOS_LCUR_SEQNO  (+)
                                                                         and    s.SORLCUR_PROGRAM = b.SORLCUR_PROGRAM  (+)
                                                                         and    s.SORLCUR_PIDM = c.SORLFOS_PIDM (+)
                                                                         and    s.SORLCUR_SEQNO = c.SORLFOS_LCUR_SEQNO  (+)
                                                                         and    s.SORLCUR_PROGRAM = c.SORLCUR_PROGRAM  (+)
                                                            Order by 3 desc;

                        RETURN (c_out);

            END f_dashboard_docentes_out;


FUNCTION f_dashboard_datos_out (p_matricula in varchar) RETURN PKG_DASHBOARD_DOCENTES.datos_out
           AS
                dat_out PKG_DASHBOARD_DOCENTES.datos_out;
                
             
            BEGIN
            
                          open dat_out
                            FOR
                             Select spriden_id matricula, spriden_first_name||' '||spriden_last_name nombre ,
                                   ( select goremal_email_address  from goremal s
                                      where s.goremal_pidm=spriden_pidm
                                        and s.goremal_emal_code='PRIN'
                                        and s.GOREMAL_PREFERRED_IND = 'Y'
                                        and s.GOREMAL_STATUS_IND ='A'
                                        and s.GOREMAL_SURROGATE_ID = (SELECT MAX (ss.GOREMAL_SURROGATE_ID)
                                                                        FROM GOREMAL ss
                                                                       WHERE ss.GOREMAL_pidm = s.GOREMAL_pidm
                                                                         AND ss.GOREMAL_EMAL_CODE = s.GOREMAL_EMAL_CODE))correo_prin,
                                        SIBINST_FCST_CODE estatus ,
                                        SIRCMNT_TEXT campus ,   
                                        SZTMACF_PROGRAM  programa                    
                                     from spriden
                                     left outer join spbpers on spbpers_pidm=spriden_pidm
                                     left outer join stvsexo on stvsexo_code=spbpers_sex
                                     left outer join stvmrtl on stvmrtl_code=spbpers_mrtl_code
                                     left outer join SIBINST ON SIBINST_PIDM=SPRIDEN_pidm and SIBINST_FCST_CODE='AC'
                                     left outer join SIRCMNT ON SIRCMNT_PIDM=SPRIDEN_pidm 
                                     left outer join GOREMAL ON  GOREMAL_PIDM= SPRIDEN_pidm 
                                     left outer join sztmacf ON  SZTMACF_CAMP=SIRCMNT_TEXT 
                                     where 1=1
--                                     AND spriden_pidm= fget_pidm ('019836875')
                                     AND spriden_id= p_matricula
                                     and SPRIDEN_CHANGE_IND is null;
                        RETURN (dat_out);
            END f_dashboard_datos_out;

FUNCTION f_dashboard_dir_resi_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.r1_out
           AS
                resi_out PKG_DASHBOARD_DOCENTES.r1_out;

                       BEGIN
                          open resi_out
                            FOR   select spraddr_street_line1||' '||spraddr_street_line2 calle, spraddr_street_line3 colonia , spraddr_zip cod_postal , spraddr_city ciudad ,
                                        stvcnty_desc delegacion , stvstat_desc estado , stvnatn_nation pais
                                        from spraddr r
                                        left outer join stvnatn on stvnatn_code=spraddr_natn_code
                                        left outer join stvstat on stvstat_code=spraddr_stat_code
                                        left outer join stvcnty on stvcnty_code=spraddr_cnty_code
                                        where spraddr_pidm=p_pidm
                                        and     spraddr_atyp_code='RE'
                                        and      spraddr_seqno in (select max(spraddr_seqno) from spraddr rr
                                                                          where r.spraddr_pidm=rr.spraddr_pidm
                                                                          and    r.spraddr_atyp_code=rr.spraddr_atyp_code);
                        RETURN (resi_out);
            END f_dashboard_dir_resi_out;


FUNCTION f_dashboard_dir_corresp_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.co1_out
           AS
                corresp_out PKG_DASHBOARD_DOCENTES.co1_out;

                       BEGIN
                          open corresp_out
                            FOR   select spraddr_street_line1||' '||spraddr_street_line2 calle, spraddr_street_line3 colonia , spraddr_zip cod_postal , spraddr_city ciudad ,
                                        stvcnty_desc delegacion , stvstat_desc estado , stvnatn_nation pais
                                        from spraddr r
                                        left outer join stvnatn on stvnatn_code=spraddr_natn_code
                                        left outer join stvstat on stvstat_code=spraddr_stat_code
                                        left outer join stvcnty on stvcnty_code=spraddr_cnty_code
                                        where spraddr_pidm=p_pidm
                                        and     spraddr_atyp_code='CO'
                                        and      spraddr_seqno in (select max(spraddr_seqno) from spraddr rr
                                                                          where r.spraddr_pidm=rr.spraddr_pidm
                                                                          and    r.spraddr_atyp_code=rr.spraddr_atyp_code);
                        RETURN (corresp_out);
            END f_dashboard_dir_corresp_out;

FUNCTION f_dashboard_dir_fiscal_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.fi1_out
           AS
                fiscal_out PKG_DASHBOARD_DOCENTES.fi1_out;

                       BEGIN
                          open fiscal_out
                            FOR   select spraddr_street_line1||' '||spraddr_street_line2 calle, spraddr_street_line3 colonia , spraddr_zip cod_postal , spraddr_city ciudad ,
                                        stvcnty_desc delegacion , stvstat_desc estado , stvnatn_nation pais
                                        from spraddr r
                                        left outer join stvnatn on stvnatn_code=spraddr_natn_code
                                        left outer join stvstat on stvstat_code=spraddr_stat_code
                                        left outer join stvcnty on stvcnty_code=spraddr_cnty_code
                                        where spraddr_pidm=p_pidm
                                        and     spraddr_atyp_code='FI'
                                        and      spraddr_seqno in (select max(spraddr_seqno) from spraddr rr
                                                                          where r.spraddr_pidm=rr.spraddr_pidm
                                                                          and    r.spraddr_atyp_code=rr.spraddr_atyp_code);
                        RETURN (fiscal_out);
            END f_dashboard_dir_fiscal_out;

FUNCTION f_dashboard_dir_laboral_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.la1_out
           AS
                laboral_out PKG_DASHBOARD_DOCENTES.la1_out;

                       BEGIN
                          open laboral_out
                            FOR   select spraddr_street_line1||' '||spraddr_street_line2 calle, spraddr_street_line3 colonia , spraddr_zip cod_postal , spraddr_city ciudad ,
                                        stvcnty_desc delegacion , stvstat_desc estado , stvnatn_nation pais
                                        from spraddr r
                                        left outer join stvnatn on stvnatn_code=spraddr_natn_code
                                        left outer join stvstat on stvstat_code=spraddr_stat_code
                                        left outer join stvcnty on stvcnty_code=spraddr_cnty_code
                                        where spraddr_pidm=p_pidm
                                        and     spraddr_atyp_code='LA'
                                        and      spraddr_seqno in (select max(spraddr_seqno) from spraddr rr
                                                                          where r.spraddr_pidm=rr.spraddr_pidm
                                                                          and    r.spraddr_atyp_code=rr.spraddr_atyp_code);
                        RETURN (laboral_out);
            END f_dashboard_dir_laboral_out;

FUNCTION f_dashboard_dir_nacim_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.na1_out
           AS
                nacim_out PKG_DASHBOARD_DOCENTES.na1_out;

                       BEGIN
                          open nacim_out
                            FOR   select spraddr_street_line1||' '||spraddr_street_line2 calle, spraddr_street_line3 colonia , spraddr_zip cod_postal , spraddr_city ciudad ,
                                        stvcnty_desc delegacion , stvstat_desc estado , stvnatn_nation pais
                                        from spraddr r
                                        left outer join stvnatn on stvnatn_code=spraddr_natn_code
                                        left outer join stvstat on stvstat_code=spraddr_stat_code
                                        left outer join stvcnty on stvcnty_code=spraddr_cnty_code
                                        where spraddr_pidm=p_pidm
                                        and     spraddr_atyp_code='NA'
                                        and      spraddr_seqno in (select max(spraddr_seqno) from spraddr rr
                                                                          where r.spraddr_pidm=rr.spraddr_pidm
                                                                          and    r.spraddr_atyp_code=rr.spraddr_atyp_code);
                        RETURN (nacim_out);
            END f_dashboard_dir_nacim_out;

FUNCTION f_dashboard_dir_referen_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.re1_out
           AS
                referen_out PKG_DASHBOARD_DOCENTES.re1_out;

                       BEGIN
                          open referen_out
                            FOR   select spraddr_street_line1||' '||spraddr_street_line2 calle, spraddr_street_line3 colonia , spraddr_zip cod_postal , spraddr_city ciudad ,
                                        stvcnty_desc delegacion , stvstat_desc estado , stvnatn_nation pais
                                        from spraddr r
                                        left outer join stvnatn on stvnatn_code=spraddr_natn_code
                                        left outer join stvstat on stvstat_code=spraddr_stat_code
                                        left outer join stvcnty on stvcnty_code=spraddr_cnty_code
                                        where spraddr_pidm=p_pidm
                                        and     spraddr_atyp_code='NA'
                                        and      spraddr_seqno in (select max(spraddr_seqno) from spraddr rr
                                                                          where r.spraddr_pidm=rr.spraddr_pidm
                                                                          and    r.spraddr_atyp_code=rr.spraddr_atyp_code);
                        RETURN (referen_out);
            END f_dashboard_dir_referen_out;

FUNCTION f_dashboard_dat_laboral_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.dlab_out
           AS
                dat_laboral_out PKG_DASHBOARD_DOCENTES.dlab_out;

                       BEGIN
                          open dat_laboral_out
                            FOR  select (select  goradid_additional_id from goradid where goradid_pidm=spriden_pidm and goradid_adid_code='TRAB') trabaja,
                                  (select  goradid_additional_id from goradid where goradid_pidm=spriden_pidm and goradid_adid_code='JORL') jornada,
                                  (select  goradid_additional_id from goradid where goradid_pidm=spriden_pidm and goradid_adid_code='NEMP') empresa,
                                  (select  goradid_additional_id from goradid where goradid_pidm=spriden_pidm and goradid_adid_code='GIRE') giro,
                                  (select  goradid_additional_id from goradid where goradid_pidm=spriden_pidm and goradid_adid_code='TPUE') puesto,
                                  (select  goradid_additional_id from goradid where goradid_pidm=spriden_pidm and goradid_adid_code='ANTI') antiguedad,
                                  (select  goradid_additional_id from goradid where goradid_pidm=spriden_pidm and goradid_adid_code='SALM') sueldo,
                                                                     ( select '('||sprtele_phone_area||') '||sprtele_phone_number  from sprtele s
                                                                         where sprtele_pidm=spriden_pidm  and sprtele_tele_code='OFIC'
                                                                         and sprtele_seqno in (select max(sprtele_seqno) from sprtele ss
                                                                                                          where s.sprtele_pidm=ss.sprtele_pidm and s.sprtele_tele_code=ss.sprtele_tele_code)) telefono
                        from spriden
                        where spriden_pidm=p_pidm and spriden_change_ind is null;
                        RETURN (dat_laboral_out);
            END f_dashboard_dat_laboral_out;

FUNCTION f_dashboard_dat_referen_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.dref_out
           AS
                dat_referen_out PKG_DASHBOARD_DOCENTES.dref_out;

                       BEGIN
                          open dat_referen_out
                            FOR  select sorfolk_parent_first nombre,sorfolk_parent_last apellidos,  sorfolk_parent_job_title correo, stvrelt_desc parentezco,
                                        stvdegc_desc grado, spraddr_street_line1||' '||spraddr_street_line2 calle, spraddr_street_line3 colonia , spraddr_zip cod_postal , spraddr_city ciudad ,
                                             stvcnty_desc delegacion , stvstat_desc estado , stvnatn_nation pais ,
                                             ( select '('||sprtele_phone_area||') '||sprtele_phone_number  from sprtele s
                                                                                         where sprtele_pidm=sorfolk_pidm  and sprtele_atyp_code=spraddr_atyp_code
                                                                                         and sprtele_seqno in (select max(sprtele_seqno) from sprtele ss
                                                                                                                          where s.sprtele_pidm=ss.sprtele_pidm and s.sprtele_tele_code=ss.sprtele_tele_code)) telefono
                                        from sorfolk
                                        left outer join stvrelt on stvrelt_code=sorfolk_relt_code
                                        left outer join stvdegc on stvdegc_code=sorfolk_parent_degree
                                        left outer join spraddr r on spraddr_pidm=sorfolk_pidm and spraddr_atyp_code=sorfolk_atyp_code
                                        and      spraddr_seqno in (select max(spraddr_seqno) from spraddr rr
                                                                          where r.spraddr_pidm=rr.spraddr_pidm
                                                                          and    r.spraddr_atyp_code=rr.spraddr_atyp_code)
                                        left outer join stvnatn on stvnatn_code=spraddr_natn_code
                                        left outer join stvstat on stvstat_code=spraddr_stat_code
                                        left outer join stvcnty on stvcnty_code=spraddr_cnty_code
                                        where sorfolk_pidm=p_pidm and sorfolk_relt_code='R';
                        RETURN (dat_referen_out);
            END f_dashboard_dat_referen_out;

FUNCTION f_dashboard_dat_factu_out (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.dfac_out
           AS
                dat_factu_out PKG_DASHBOARD_DOCENTES.dfac_out;

                       BEGIN
                          open dat_factu_out
                            FOR
                                    select upper (s.spremrg_mi) rfc,
                                             upper (s.spremrg_last_name) razon_social,
                                             upper (s.spremrg_street_line1||' '||s.spremrg_street_line2) calle,
                                             upper (s.spremrg_street_line3)  colonia,
                                             s.spremrg_zip cod_postal,
                                             upper (s.spremrg_city) ciudad,
                                             upper (stvstat_desc) estado ,
                                             upper (stvnatn_nation) pais,
                                             SPREMRG_ACTIVITY_DATE Fecha_Registro,
                                             s.spremrg_priority prioridad,
                                             upper (GORADID_ADDITIONAL_ID) curp,
                                             upper (stvnatn_code) pais_code,
                                             upper (stvstat_code) estado_code,
                                             upper (stvcnty_code) ciudad_code
                                        from spremrg s
                                        left outer join stvnatn on stvnatn_code= s.spremrg_natn_code
                                        left outer join stvstat on stvstat_code= s.spremrg_stat_code
                                        left outer join stvcnty on stvcnty_code=s.spremrg_city
                                        left outer join goradid on GORADID_PIDM = SPREMRG_PIDM and GORADID_ADID_CODE = 'CURP'
                                        WHERE 1= 1
                                        AND spremrg_pidm= p_pidm
                                        order by to_number (spremrg_priority) desc;

                        RETURN (dat_factu_out);
            END f_dashboard_dat_factu_out;

    FUNCTION f_dashboard_datout_opm (p_pidm in number, p_tran in varchar2) RETURN PKG_DASHBOARD_DOCENTES.opm_out
           AS
                dat_factu_opm PKG_DASHBOARD_DOCENTES.opm_out;

                       BEGIN
                          open dat_factu_opm
                            FOR
                              SELECT UPPER(SUBSTR(a.TZTCRTE_CAMPO2,1,15)) rfc,
                                   TZTCRTE_CAMPO1 razon_social,
                                   REGEXP_SUBSTR(a.TZTCRTE_CAMPO3, '[^#"]+', 1, 1) calle,
                                   REPLACE (TZTCRTE_CAMPO27,'"',Null) colonia,
                                   a.TZTCRTE_CAMPO5 cod_postal,
                                   a.TZTCRTE_CAMPO4 ciudad,
                                   'MME' estado,
                                   a.TZTCRTE_CAMPO6 pais,
                                   (SELECT (SPREMRG_ACTIVITY_DATE)
                                        FROM SPREMRG s
                                        WHERE 1=1
                                        AND s.SPREMRG_PRIORITY = (select MAX(s1.SPREMRG_PRIORITY)
                                                                    FROM SPREMRG s1, TZTFACT
                                                                    WHERE s.SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                                    AND TZTFACT_PIDM = SPREMRG_PIDM
                                                                    AND TZTFACT_RFC = UPPER(SPREMRG_MI)
                                                                    AND TZTFACT_STST_TIMBRADO = 'FM_OPM'
                                                                    AND TZTFACT_PIDM = p_pidm --263280
                                                                    AND TZTFACT_TRAN_NUMBER = p_tran)-- 20)
                                        )Fecha_Registro,
                                   '1' prioridad
                            FROM TZTCRTE a--@PROD a
                            WHERE 1=1
                            AND a.TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
                            AND a.TZTCRTE_PIDM = p_pidm --263280 --p_pidm --263280 --262265-- p_pidm
                            AND TO_CHAR(TZTCRTE_CAMPO10) = p_tran; --20 --p_tran  --20--12 --p_tran;
                        RETURN (dat_factu_opm);
            END f_dashboard_datout_opm;



FUNCTION f_dashboard_dat_anterior_out (p_pidm in number, p_prog in varchar2) RETURN PKG_DASHBOARD_DOCENTES.dant_out
           AS
                dat_ant_out PKG_DASHBOARD_DOCENTES.dant_out;

                       BEGIN
                          open dat_ant_out
                            FOR select stvdegc_desc ult_grado, stvsbgi_desc esc_anterior, sordegr_degc_date ult_fecha,  sordegr_gpa_transferred prom_esc_anterior from saradap sa
                                   left outer join sordegr sord on sordegr_pidm=saradap_pidm and trunc(sordegr_activity_date) in (select min(trunc(sordegr_activity_date)) from sordegr sord1
                                                                                                                                  where sord.sordegr_pidm=sord1.sordegr_pidm and trunc(sord1.sordegr_activity_date) >= trunc(saradap_activity_date))
                                   left outer join sorpcol sorp on sorpcol_pidm=saradap_pidm and trunc(sorpcol_activity_date) in (select min(trunc(sorpcol_activity_date)) from sorpcol sorp1
                                                                                                                                  where sorp.sorpcol_pidm=sorp1.sorpcol_pidm and trunc(sorp1.sorpcol_activity_date) >= trunc(saradap_activity_date))
                                    left outer join stvsbgi on stvsbgi_code=sorpcol_sbgi_code
                                    left outer join stvdegc on stvdegc_code=sordegr_degc_code
                                    where saradap_pidm= p_pidm
                                    and     saradap_program_1=p_prog
                                    and     saradap_appl_no in (select max(saradap_appl_no) from saradap sa1
                                                                          where sa.saradap_pidm=sa1.saradap_pidm and sa.saradap_program_1=sa1.saradap_program_1);
                        RETURN (dat_ant_out);
            END f_dashboard_dat_anterior_out;

FUNCTION f_dashboard_hiac_out (p_matricula varchar2) RETURN PKG_DASHBOARD_DOCENTES.hiac_out
           AS
                histac_out PKG_DASHBOARD_DOCENTES.hiac_out;
                
                l_pidm number;
                
                
                       BEGIN
                       
                       select spriden_pidm
                         into l_pidm
                       from spriden
                       where 1=1
                       and spriden_id=p_matricula
                       and SPRIDEN_CHANGE_IND is null;
                          


                          open histac_out
                            FOR
                                  select distinct
                                      spriden_first_name||' '||replace(spriden_last_name,'/',' ') "Estudiante",
                                      spriden_id "Matricula",
                                      SZTMACF_PROGRAM "Programa",
                                      SZTMACF_SERIACION"per",
                                      substr (SZTMACF_SUBJ,4,2) "nombre_area",
                                      SZTMACF_SUBJ "materia",
                                      SZTMACF_SUBJDES "nombre_mat",
                                      null "periodo",
                                      SZSTUME_GRDE_CODE_FINAL "calif",
                                      null"letra",
                                      0 "Avance",
                                      0 "Promedio",
                                      null"aprobatoria",
                                      SZTMACF_MAXAPRO "creditos",
                                     'ORD' "evaluacion"
                                    from spriden,STVCAMP,sztmacf
                                    ,SZSTUME
                                    where 1=1
                                    and SZSTUME_PIDM=spriden_pidm(+)
                                    and  spriden_pidm=l_pidm
                                    and spriden_change_ind is null
                                    and substr(spriden_id,1,2)=STVCAMP_DICD_CODE
                                    and STVCAMP_CODE=SZTMACF_CAMP
                                    order by  "Matricula",  "per","nombre_area","materia";
                        RETURN (histac_out);
            END f_dashboard_hiac_out;


function f_dashboard_avcu_out(pidm number, prog varchar2,usu_siu varchar2) RETURN PKG_DASHBOARD_DOCENTES.avcu_out
           AS
                avance_n_out PKG_DASHBOARD_DOCENTES.avcu_out;

  VL_DIPLO NUMBER:=0;
  VL_DIPLO2 NUMBER:=0;
  VL_PIDM NUMBER:=pidm;
 BEGIN

      BEGIN
                SELECT NVL(count(*),0)
                INTO  VL_DIPLO2
                FROM TZTPROG A
                WHERE 1=1
                and A.PIDM = VL_PIDM
                and A.CAMPUS='UTS'
                AND A.NIVEL='EC';
                --AND A.PROGRAMA=prog
                --AND A.ESTATUS  NOT IN('BT','EG','BI','BD');

        EXCEPTION
            WHEN OTHERS THEN
             VL_DIPLO2 := 0;
        END;


     IF   VL_DIPLO2>1 THEN

           VL_DIPLO:=1;

     ELSIF VL_DIPLO2 =1 THEN
             VL_DIPLO:=0;
--        BEGIN
--                SELECT NVL(count(*),0)
--                INTO  VL_DIPLO
--                FROM TZTPROG A
--                WHERE 1=1
--                and A.PIDM = VL_PIDM
--                and A.CAMPUS='UTS'
--                AND A.NIVEL='EC'
--                AND A.PROGRAMA=prog;
--        EXCEPTION
--            WHEN OTHERS THEN
--             VL_DIPLO := 0;
--        END;

     END IF;

 IF VL_DIPLO = 0 THEN


   BEGIN

                       delete from avance_n
                       where protocolo=9999
                       and USUARIO_SIU=usu_siu;
                       commit;


              insert into avance_n
                    select DISTINCT /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                    case
                        when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                        when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                        else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                    end  per,  ----
                    smrpaap_area area,   ----
                                                  case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                      case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             else smralib_area_desc
                                                       end
                                                    else smralib_area_desc
                                                    end
                                                     nombre_area,  ---
                                    smrarul_subj_code||smrarul_crse_numb_low materia, ----
                                    scrsyln_long_course_title nombre_mat, ----
                                     case when k.calif in ('NA','NP','AC') then '1'
                                            when k.st_mat='EC' then '101'
                                     else  k.calif
                                     end calif, ---
                                     nvl(k.st_mat,'PC'),  ---
                                     smracaa_rule regla,   ---
                                     case when k.st_mat='EC' then null
                                       else k.calif
                                     end  origen,
                                     k.fecha, ---
                                     pidm ,
                                     usu_siu
                                    from smrpaap s, smrarul, sgbstdn y, sorlcur so, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
                                    (
                                               select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                 w.shrtckn_subj_code subj, w.shrtckn_crse_numb code,
                                                 shrtckg_grde_code_final CALIF, decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, shrtckg_final_grde_chg_date fecha
                                                from shrtckn w,shrtckg, shrgrde, smrprle
                                                where shrtckn_pidm=pidm
                                                 and  shrtckg_pidm=w.shrtckn_pidm
                                                 and  SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                 )
                                                 and  shrtckg_tckn_seq_no=w.shrtckn_seq_no
                                                 and  shrtckg_term_code=w.shrtckn_term_code
                                                 and  smrprle_program=prog
                                                 and  shrgrde_levl_code=smrprle_levl_code  -------------------
      /* cambio escalas para prod */             and shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                                 and  shrgrde_code=shrtckg_grde_code_final
                                                 and  decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))   -- anadido para sacar la calificacion mayor  OLC
                                                                  in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))) from shrtckn ww, shrtckg zz
                                                                       where w.shrtckn_pidm=ww.shrtckn_pidm
                                                                         and  w.shrtckn_subj_code=ww.shrtckn_subj_code  and w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                                                         and  ww.shrtckn_pidm=zz.shrtckg_pidm and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no and ww.shrtckn_term_code=zz.shrtckg_term_code)
                                                and   SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                    where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                      and shrtckn_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                union
                                                select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                       shrtrce_grde_code  CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                  from shrtrce
                                                 where shrtrce_pidm=pidm
                                                   and SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                   )
                                                union
                                                 select SHRTRTK_SUBJ_CODE_INST subj, SHRTRTK_CRSE_NUMB_INST code,
                                                   /*nvl(SHRTRTK_GRDE_CODE_INST,0)*/  '0' CALIF, 'EQ'  ST_MAT, trunc(SHRTRTK_ACTIVITY_DATE) fecha
                                                   from  SHRTRTK
                                                  where  SHRTRTK_PIDM=pidm
                                                union
                                                 select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                   from sfrstcr, smrprle, ssbsect, spriden
                                                  where smrprle_program=prog
                                                    and sfrstcr_pidm=pidm  and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                    and  sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB = SFRSTCR_RESERVED_KEY ) 
                                                    and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                    )
                                                    and spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
    --                                              and    sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                    and ssbsect_term_code=sfrstcr_term_code
                                                    and ssbsect_crn=sfrstcr_crn
                                                union
                                                 select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                   ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)/*+120*/  fecha
                                                   from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                                  where smrprle_program=prog
                                                   and  sfrstcr_pidm=pidm  and sfrstcr_grde_code is not null
                                                   and  sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and shrtckn_crn=sfrstcr_crn)
                                                   and  sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB = SFRSTCR_RESERVED_KEY ) ------ Agego este linea para quitar materias que ya estan en Roladas
                                                   and  SFRSTCR_RSTS_CODE!='DD'  --- agregado
                                                   and  spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
    --                                             and   sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                   and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                   )
                                                   and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                      where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                        and sfrstcr_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                   and  ssbsect_term_code=sfrstcr_term_code
                                                   and  ssbsect_crn=sfrstcr_crn
                                                   and  shrgrde_levl_code=smrprle_levl_code   -------------------
         /* cambio escalas para prod */            and shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                                   and  shrgrde_code=sfrstcr_grde_code
                                   ) k
                                  where   spriden_pidm=pidm  and spriden_change_ind is null
                                    and   sorlcur_pidm= spriden_pidm
                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                    and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                             where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                               and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                               and ss.sorlcur_program =prog)
                                   and    smrpaap_program=prog
                                   AND    smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                                   and    smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                   and    SMBAGEN_ACTIVE_IND='Y'           --solo areas activas  OLC
                                   and    SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF   --solo areas activas  OLC
                                   and    smrpaap_area=smrarul_area
                                   and    sgbstdn_pidm=spriden_pidm
                                   and    sgbstdn_program_1=smrpaap_program
                                   and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                     where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                       and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                   and    sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO'  and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                   and    SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                   and    SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
                                   and    stvstst_code=sgbstdn_stst_code
                                   and    smralib_area=smrpaap_area
                                   AND    smracaa_area = smrarul_area
                                   AND    smracaa_rule = smrarul_key_rule
                                   and    SMRACAA_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG
                                   and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                   )
                                   and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                              and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                              and   cu.sorlcur_pidm=pidm
                                                                                              and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                              and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                              and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                            and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                            and ss.sorlcur_program =prog)
                                                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                           )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                              and ss.sorlcur_program =prog )
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                                 ) )) )
                                   and    k.subj=smrarul_subj_code and k.code=smrarul_crse_numb_low
                                   and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                   and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=sgbstdn_program_1 and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                 union
                                 select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                                    case
                                            when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                            when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                           else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                                    end  per,  ---
                                    smrpaap_area area, ---
                                                              case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                                  case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         else smralib_area_desc
                                                                   end
                                                                else smralib_area_desc
                                                                end   nombre_area, ---
                                                smrarul_subj_code||smrarul_crse_numb_low materia, ---
                                                 scrsyln_long_course_title nombre_mat, ---
                                                 null calif,  ---
                                                 'PC' ,  ---
                                                 smracaa_rule regla, ---
                                                 null origen, ---
                                                 null fecha, --
                                                 pidm ,
                                                 usu_siu
                                    from spriden, smrpaap, sgbstdn y, sorlcur so,SZTDTEC, smrarul, smracaa, smralib, stvstst, scrsyln, zstpara,smbagen
                                     where    spriden_pidm=pidm  and spriden_change_ind is null
                                               and   sorlcur_pidm= spriden_pidm
                                               and   SORLCUR_LMOD_CODE = 'LEARNER'
                                               and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                          and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                          and ss.sorlcur_program =prog)
                                               and   smrpaap_program=prog
                                               AND   smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                                               and   smrpaap_area=SMBAGEN_AREA
                                               and   SMBAGEN_ACTIVE_IND='Y'
                                               and   SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                               and   smrpaap_area=smrarul_area
                                               and   sgbstdn_pidm=spriden_pidm
                                               and   sgbstdn_program_1=smrpaap_program
                                               and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                  and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                               and   sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO' and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                               and   SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                               and   stvstst_code=sgbstdn_stst_code
                                               and   smralib_area=smrpaap_area
                                               AND   smracaa_area = smrarul_area
                                               AND   smracaa_rule = smrarul_key_rule
                                               AND   SMRARUL_TERM_CODE_EFF = SORLCUR_TERM_CODE_CTLG
                                               and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001'
                                               )
                                               and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                            and spriden_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                               and   (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                     (smrarul_area in (select smriemj_area from smriemj
                                                                        where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                     from sorlcur cu, sorlfos ss
                                                                                                    where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                      and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                      and cu.sorlcur_pidm=pidm
                                                                                                      and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                      and SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                      and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                      and cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                      and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                      and   sorlcur_program   =prog
                                                                                                    )    )
                                               and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                              and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                              and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                          and ss.sorlcur_program =prog )
                                                                                              and   cu.sorlcur_pidm=pidm
                                                                                              and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                              and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                              and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                              and   sorlcur_program   =prog
                                                                                           ) )) )
                                               and  scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTCKN_SUBJ_CODE,SHRTCKN_CRSE_NUMB  from shrtckn where shrtckn_pidm=pidm )
                                               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRCE_SUBJ_CODE,SHRTRCE_CRSE_NUMB  from SHRTRCE where SHRTRCE_pidm=pidm )     --agregado
                                               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRTK_SUBJ_CODE_INST,SHRTRTK_CRSE_NUMB_INST  from SHRTRTK where SHRTRTK_pidm=pidm )  --agregado
                                               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select ssbsect_subj_code subj, ssbsect_crse_numb code  from  sfrstcr, smrprle, ssbsect, spriden  --agregado para materias EC y aprobadas sin rolar
                                                                                                       where  smrprle_program=prog
                                                                                                         and  sfrstcr_pidm=pidm  and (sfrstcr_grde_code is null or sfrstcr_grde_code is not null)  and sfrstcr_rsts_code='RE'
                                                                                                         and  spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                                         and  ssbsect_term_code=sfrstcr_term_code
                                                                                                         and  ssbsect_crn=sfrstcr_crn)
                                               and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=sgbstdn_program_1 and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG;

                                 commit;


                        Begin 
                            For cx in (

                                        select count(*), MATERIA, PIDM_ALU
                                        from avance_n
                                        where PIDM_ALU = pidm
                                        and USUARIO_SIU = usu_siu
                                        group by MATERIA, PIDM_ALU
                                        having count(*) > 1 
                                        
                                  ) loop
                                  
                                  
                                    For cx2 in (
                                  
                                                Select *
                                                    from  avance_n a
                                                    where a.PIDM_ALU = cx.PIDM_ALU
                                                    and a.USUARIO_SIU = usu_siu
                                                    And a.materia = cx.materia
                                                       and TO_NUMBER (decode (trim (a.CALIF)
                                                   ,'NA',1,'NP',1 , 'AC', 1
                                                  ,'10',10,'10.0',10,'100',10
                                                  ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                  ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                  ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                                  ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                                  ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                 ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9
                                                )) =
                                                (select Max (TO_NUMBER (decode (trim(a1.CALIF)
                                                                         ,'NA',1,'NP',1 , 'AC', 1
                                                                        ,'10',10,'10.0',10,'100',10
                                                                        ,'4.0',4,'4',4,'4.1',4,'4.2',4,'4.3',4,'4.4',4,'4.5',4,'46',4,'4.7',4,'48',4
                                                                       ,'5.0',5,'5',5,'5.1',5,'5.2',5,'53',5,'5.4',5,'5.5',5,'5.6',5,'5.7',5,'57',5,'5.8',5,'5.9',5,'59',5
                                                                        ,'6.0',6,'6',6,'6.1',6,'61',6,'6.2',6,'6.3',6,'63',6,'6.5',6,'65',6,'6.6',6,'6.7',6,'6.8',6,'6.9',6
                                                                        ,'7.0',7,'7',7,'7.1',7,'7.2',7,'72',7,'7.3',7,'73',7,'7.4',7,'74',7,'7.5',7,'75',7,'7.6',7,'7.7',7,'77',7,'7.8',7,'7.9',7
                                                                        ,'8.0',8,'8',8,'80',8,'8.1',8,'8.2',8,'8.3',8,'83',8,'8.4',8,'84',8,'8.5',8,'85',8,'8.6',8,'86',8,'8.7',8,'87',8,'8.8',8,'88',8,'8.9',8,'89',8
                                                                       ,'9.0',9,'9',9,'90',9,'9.1',9,'91',9,'9.2',9,'92',9,'9.3',9,'93',9,'9.4',9,'94',9,'9.5',9,'95',9,'9.6',9,'96',9,'9.7',9,'97',9,'9.8',9,'98',9,'9.9',9,'99',9
                                                    ))) calif 
                                                                            from avance_n a1
                                                                            where a1.PIDM_ALU = cx.PIDM_ALU
                                                                            and a1.USUARIO_SIU =usu_siu
                                                                            And a1.materia = cx.materia
                                                                           )
                                    ) loop
                                    
                                        Begin
                                        
                                             delete avance_n a
                                             where a.PIDM_ALU = cx2.PIDM_ALU
                                             and a.USUARIO_SIU = usu_siu
                                             And a.materia = cx2.materia
                                             And a.CALIF != cx2.CALIF;
                                        Exception
                                            When Others then 
                                                null;
                                        End;
                                        Commit;
                                    
                                    End Loop;   


       
                             
                            End loop;

                        End;  



                          open avance_n_out
                            FOR
                             select   spriden_id matricula, spriden_first_name||' '||replace(spriden_last_name,'/',' ') nombre ,  sztdtec_programa_comp programa, stvstst_desc estatus,
                                      avance1.per, avance1.area,
                                      case when substr(spriden_id,1,2)='08' then ' '
                                      else
                                          case when substr(avance1.materia,1,4)='L1HB' then 'MATERIAS INTRODUCTORIAS'
                                                when substr(avance1.materia,1,4)='M1HB' then 'MATERIAS INTRODUCTORIAS'
                                          else upper(avance1.nombre_area)
                                          end
                                      end   "nombre_area",avance1.materia, avance1.nombre_mat,
                                       avance1.calif, avance1.ord,
                                     case when avance1.apr='AP' then null
                                         else apr
                                         end tipo,
                                         case when sztdtec_incorporante='SEGEM' then null
                                         else n_area
                                         end n_area,
                                     case when avance1.per < 7 then 1
                                           else 2
                                     end hoja,
                                   ----------------------------------------
                                   CASE  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                       where SMBPGEN_program=prog
                                                                           and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                       where s.sorlcur_pidm=pidm
                                                                                                         and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                         and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                 where ss.sorlcur_pidm=pidm
                                                                                                                                   and ss.sorlcur_program=prog
                                                                                                                                   and ss.sorlcur_lmod_code='LEARNER'))) ='40' then
                                                                                                                                                         (select count(unique materia)  from avance_n x
                                                                                                                                                           where  apr in ('AP','EQ')
                                                                                                                                                             and    protocolo=9999
                                                                                                                                                             and    pidm_alu=pidm
                                                                                                                                                             and    usuario_siu=usu_siu
                                                                                                                                                             and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                                                                                                                             and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                     where x.materia=xx.materia
                                                                                                                                                                                       and x.protocolo=xx.protocolo
                                                                                                                                                                                       and x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                       and x.usuario_siu=xx.usuario_siu)
                                                                                                                                                                                       and CALIF!=0
                                                    and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )

                                                  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                       where SMBPGEN_program=prog
                                                                           and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                                                 where  s.sorlcur_pidm=pidm
                                                                                                                                      and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                      and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                              where ss.sorlcur_pidm=pidm
                                                                                                                                                                and ss.sorlcur_program=prog
                                                                                                                                                                and ss.sorlcur_lmod_code='LEARNER'))) ='42' then
                                                                                                                                                                               (select count(unique materia)  from avance_n x
                                                                                                                                                                                 where  apr in ('AP','EQ')
                                                                                                                                                                                   and  protocolo=9999
                                                                                                                                                                                   and  pidm_alu=pidm
                                                                                                                                                                                   and  usuario_siu=usu_siu
                                                                                                                                                                                   and  area not in  ((select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' ) )
                                                                                                                                                                                   and  calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                                    where x.materia=xx.materia
                                                                                                                                                                                                      and x.protocolo=xx.protocolo
                                                                                                                                                                                                      and x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                                      and x.usuario_siu=xx.usuario_siu)
                                                                                                                                                                                                      and CALIF!=0
                                                    and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )
                                            ELSE
                                                  (select count(unique materia)  from avance_n x
                                                     where  apr in ('AP','EQ')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    usuario_siu=usu_siu
                                                     and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                     and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            and   x.usuario_siu=xx.usuario_siu)
                                                                            and CALIF!=0
                                                     and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )
                                      end  aprobadas_curr,
                                   ---------------------------
                                     (select count(unique materia)  from avance_n x
                                     where  apr in ('NA')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                     and    materia not in (select materia from avance_n xx
                                                               where x.materia=xx.materia
                                                                and  x.protocolo=xx.protocolo
                                                                and  x.pidm_alu=xx.pidm_alu
                                                                and  x.usuario_siu=xx.usuario_siu
                                                                and  xx.apr='EC')
                                     and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu)) no_aprobadas_curr,
                                     (select count(unique materia) from avance_n x
                                     where  apr in ('EC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                                  ) curso_curr,
                                         (select count(unique materia)  from avance_n x
                                                     where apr in ('PC')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    usuario_siu=usu_siu
                                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                     and materia not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB' and ZSTPARA_PARAM_VALOR=materia and
                                                           pidm_alu in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                           ) por_cursar_curr,
                                  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                where SMBPGEN_program=prog
                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                  where  sorlcur_pidm=pidm
                                                                                    and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                    and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                            where ss.sorlcur_pidm=pidm
                                                                                                             and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))) total_curr,
                                       case when
                                              round ((select count(unique materia) from avance_n x
                                             where  apr in ('AP','EQ')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    usuario_siu=usu_siu
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and     calif not in ('NP','AC')
                                             and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) or calif is null)
                                                      and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
                                                                    ) *100 /
                                            (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                    where  sorlcur_pidm=pidm
                                                                                                                       and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                       and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where ss.sorlcur_pidm=pidm
                                                                                                                                                                   and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))>100  then 100
                                         else
                                            round ((select count(unique materia) from avance_n x
                                             where  apr in ('AP','EQ')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    usuario_siu=usu_siu
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and     calif not in ('NP','AC')
                                             and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) or calif is null)
                                                     and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
                                                                    ) *100 /
                                            (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                    where  sorlcur_pidm=pidm
                                                                                                                       and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                       and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                             where ss.sorlcur_pidm=pidm
                                                                                                                                                             and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))
                                       end Avance_n_curr,
                                    (select count(unique materia) from avance_n x
                                     where apr in ('AP','EQ')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                     and    to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu))  aprobadas_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('NA')
                                     and    protocolo=9999
                                      and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                     and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu)) no_aprobadas_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('EC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                  ) curso_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('PC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                  )  por_cursar_tall,
                                    (select count(unique materia) from avance_n x
                                     where area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu) or calif is null)) total_tall
                                    from spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
                                    (SELECT 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
                                       FROM  (
                                                        select 9999, per, area, nombre_area, materia, nombre_mat,
                                                                       case when calif='1' then cal_origen
                                                                                when apr='EC' then null
                                                                        else calif
                                                                        end calif, apr, regla, null n_area,
                                                                       case when substr(materia,1,2)='L3' then 5
                                                                        else 1
                                                                       end ord,fecha
                                                                 from  sgbstdn y, avance_n x
                                                                   where  x.protocolo=9999
                                                                    and    sgbstdn_pidm=pidm
                                                                    and    sgbstdn_program_1=prog
                                                                    and    x.pidm_alu=pidm
                                                                    and    x.usuario_siu=usu_siu
                                                                    and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                        and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                    and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and  x.protocolo=xx.protocolo   ----cambio
                                                                          and  x.pidm_alu=sgbstdn_pidm  ----cambio
                                                                          and  x.pidm_alu=xx.pidm_alu   ---- cambio
                                                                          and  x.usuario_siu=xx.usuario_siu) or calif is null)
                                                        union
                                                        select distinct 9999, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                                                        case when calif='1' then cal_origen
                                                                when apr='EC' then null
                                                        else calif
                                                        end calif, apr, regla, null n_area,
                                                        case when substr(materia,1,2)='L3' then 5
                                                        else 1
                                                        end ord, fecha
                                                                    from  sgbstdn y, avance_n x
                                                                   where   x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                     and    x.pidm_alu=sgbstdn_pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     apr='EC'
                                                                    and     sgbstdn_program_1=prog
                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                       where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                         and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                        union
                                                        select protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                    case when calif='1' then cal_origen
                                                                           when apr='EC' then null
                                                                    else calif
                                                                    end calif, apr, regla, stvmajr_desc n_area, 2 ord, fecha
                                                                    from  sgbstdn y, avance_n x, smriemj, stvmajr
                                                                   where   x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                    and     x.pidm_alu=sgbstdn_pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     sgbstdn_program_1=prog
                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                       where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                         and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and    area=smriemj_area
--                                                                   and smriemj_majr_code=sgbstdn_majr_code_1   --vic
                                                                   and smriemj_majr_code= (select distinct SORLFOS_MAJR_CODE
                                                                                            from  sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                          and ss.sorlcur_program =prog)
                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                              and ss.sorlcur_program =prog)
                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                                            and   sorlcur_program   =prog
                                                                                          )
                                                                   and    area not in (select smriecc_area from smriecc)
                                                                   and    smriemj_majr_code=stvmajr_code
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or calif is null)
                                                        union
                                                          select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                case when calif='1' then cal_origen
                                                                         when apr='EC' then null
                                                                 else calif
                                                                end  calif, apr, regla, smralib_area_desc n_area, 3 ord, fecha
                                                                    from sgbstdn y, avance_n x ,smralib, smriecc a
                                                                   where  x.protocolo=9999
                                                                    and   sgbstdn_pidm=pidm
                                                                    and   x.pidm_alu=sgbstdn_pidm
                                                                    and   x.usuario_siu=usu_siu
                                                                    and   sgbstdn_program_1=prog
                                                                    and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                     where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                       and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and    area=smralib_area
                                                                   and    area=smriecc_area
--                                                                   and    smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)---modifico vic   18.04.2018
                                                                   and     smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
--                                                                                                        and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
--                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
--                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
--                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                        and   cu.sorlcur_pidm=pidm
                                                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                                                                        and   sorlcur_program   =prog
                                                                                                         )
--                                                                   and    smriecc_majr_code_conc=stvmajr_code
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or calif is null)
--                                                                          or calif='1')   -----------------
                                                                   and    (fecha in (select distinct fecha from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or fecha is null)
                                                        order by   n_area desc, per, nombre_area,regla
                                          )
                                        GROUP BY 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
                                    )  avance1
                                    where  spriden_pidm=pidm
                                    and   sorlcur_pidm= spriden_pidm
                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                    and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                               and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                               and ss.sorlcur_program =prog)
                                    and     spriden_change_ind is null
                                    and     sgbstdn_pidm=spriden_pidm
                                    and     sgbstdn_program_1=prog
                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                                                       where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                                         and a.sgbstdn_program_1=b.sgbstdn_program_1)
                                    and     sztdtec_program=sgbstdn_program_1
                                    and     sztdtec_status='ACTIVO'
                                    and     SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE
                                    and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                    and     sgbstdn_stst_code=stvstst_code
                                     order by  avance1.per,
                                       CASE WHEN sgbstdn_program_1 in (select ZSTPARA_PARAM_ID from ZSTPARA where ZSTPARA_MAPA_ID='PROG_ESPECIAL' and ZSTPARA_PARAM_ID=sgbstdn_program_1)  THEN
                                             avance1.n_area||','||avance1.regla||','||avance1.materia||','||avance1.ord||','||hoja
                                        WHEN sgbstdn_program_1 not in (select ZSTPARA_PARAM_ID from ZSTPARA where ZSTPARA_MAPA_ID='PROG_ESPECIAL' and ZSTPARA_PARAM_ID=sgbstdn_program_1)  THEN
                                             avance1.n_area||','||avance1.materia||','||avance1.regla||','||avance1.ord||','||hoja
                                       END;
  END;

  ELSIF VL_DIPLO >=1 THEN

        BEGIN   /*DIPLOMADOS*/
          delete from avance_n
                       where protocolo=9999
                       and USUARIO_SIU=usu_siu;
                       commit;


              insert into avance_n
                    select   DISTINCT /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                    case
                        when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                        when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                        else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                    end  per,  ----
                    smrpaap_area area,   ----
                                                  case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                      case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                             else smralib_area_desc
                                                       end
                                                    else smralib_area_desc
                                                    end
                                                     nombre_area,  ---
                                    smrarul_subj_code||smrarul_crse_numb_low materia, ----
                                    scrsyln_long_course_title nombre_mat, ----
                                     case when k.calif in ('NA','NP','AC') then '1'
                                            when k.st_mat='EC' then '101'
                                     else  k.calif
                                     end calif, ---
                                     nvl(k.st_mat,'PC'),  ---
                                     smracaa_rule regla,   ---
                                     case when k.st_mat='EC' then null
                                       else k.calif
                                     end  origen,
                                     k.fecha, ---
                                     pidm ,
                                     usu_siu
                                    from smrpaap s, smrarul, sgbstdn y, sorlcur so, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
                                    (
                                               select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                 w.shrtckn_subj_code subj, w.shrtckn_crse_numb code,
                                                 shrtckg_grde_code_final CALIF, decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, shrtckg_final_grde_chg_date fecha
                                                from shrtckn w,shrtckg, shrgrde, smrprle
                                                where shrtckn_pidm=pidm
                                                 and  shrtckg_pidm=w.shrtckn_pidm
                                                 and  SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                 )
                                                 and  shrtckg_tckn_seq_no=w.shrtckn_seq_no
                                                 and  shrtckg_term_code=w.shrtckn_term_code
                                                 and  smrprle_program=prog
                                                 and  shrgrde_levl_code=smrprle_levl_code  -------------------
      /* cambio escalas para prod */             and shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                                 and  shrgrde_code=shrtckg_grde_code_final
                                                 and  decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))   -- anadido para sacar la calificacion mayor  OLC
                                                                  in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))) from shrtckn ww, shrtckg zz
                                                                       where w.shrtckn_pidm=ww.shrtckn_pidm
                                                                         and  w.shrtckn_subj_code=ww.shrtckn_subj_code  and w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                                                         and  ww.shrtckn_pidm=zz.shrtckg_pidm and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no and ww.shrtckn_term_code=zz.shrtckg_term_code)
                                                and   SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                    where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                      and shrtckn_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                union
                                                select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                       shrtrce_grde_code  CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                  from shrtrce
                                                 where shrtrce_pidm=pidm
                                                   and SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                   )
                                                union
                                                 select SHRTRTK_SUBJ_CODE_INST subj, SHRTRTK_CRSE_NUMB_INST code,
                                                   /*nvl(SHRTRTK_GRDE_CODE_INST,0)*/  '0' CALIF, 'EQ'  ST_MAT, trunc(SHRTRTK_ACTIVITY_DATE) fecha
                                                   from  SHRTRTK
                                                  where  SHRTRTK_PIDM=pidm
                                                union
                                                 select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                   from sfrstcr, smrprle, ssbsect, spriden
                                                  where smrprle_program=prog
                                                    and sfrstcr_pidm=pidm  and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                    and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                    )
                                                    and spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
    --                                              and    sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                    and ssbsect_term_code=sfrstcr_term_code
                                                    and ssbsect_crn=sfrstcr_crn
                                                union
                                                 select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                   ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)/*+120*/  fecha
                                                   from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                                  where smrprle_program=prog
                                                   and  sfrstcr_pidm=pidm  and sfrstcr_grde_code is not null
                                                   and  sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and shrtckn_crn=sfrstcr_crn)
                                                   and  SFRSTCR_RSTS_CODE!='DD'  --- agregado
                                                   and  spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
    --                                             and   sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                   and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                   )
                                                   and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                      where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                        and sfrstcr_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                   and  ssbsect_term_code=sfrstcr_term_code
                                                   and  ssbsect_crn=sfrstcr_crn
                                                   and  shrgrde_levl_code=smrprle_levl_code   -------------------
         /* cambio escalas para prod */            and shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                                   and  shrgrde_code=sfrstcr_grde_code
                                   ) k
                                  where   spriden_pidm=pidm  and spriden_change_ind is null
                                    and   sorlcur_pidm= spriden_pidm
                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
--                                    and   SORLCUR_CACT_CODE='ACTIVE'
                                    and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                             where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                               and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                               and ss.sorlcur_program =prog)
                                   and    smrpaap_program=prog
                                   AND    smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                                   and    smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                   and    SMBAGEN_ACTIVE_IND='Y'           --solo areas activas  OLC
                                   and    SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF   --solo areas activas  OLC
                                   and    smrpaap_area=smrarul_area
                                   and    sgbstdn_pidm=spriden_pidm
                                   and    SORLCUR_program=smrpaap_program
--                                   and    sgbstdn_program_1=smrpaap_program
--                                   and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
--                                                                     where x.sgbstdn_pidm=y.sgbstdn_pidm
--                                                                       and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                   and    sztdtec_program=SORLCUR_program and sztdtec_status='ACTIVO'  and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                   and    SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                   and    SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
                                   and    stvstst_code=sgbstdn_stst_code
                                   and    smralib_area=smrpaap_area
                                   AND    smracaa_area = smrarul_area
                                   AND    smracaa_rule = smrarul_key_rule
                                   and    SMRACAA_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG
                                   and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                   )
                                   and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area from smriemj
                                                               where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                              and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                              and   cu.sorlcur_pidm=pidm
                                                                                              and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                              and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                              and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                            and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                            and ss.sorlcur_program =prog)
                                                                                                and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                           )    )
                                                   and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from  sorlcur cu, sorlfos ss
                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                              and ss.sorlcur_program =prog )
                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                and   sorlcur_program   =prog
                                                                                                 ) )) )
                                   and    k.subj=smrarul_subj_code and k.code=smrarul_crse_numb_low
                                   and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                   and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=SORLCUR_program and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                 union
                                 select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                                    case
                                            when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                            when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                           else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                                    end  per,  ---
                                    smrpaap_area area, ---
                                                              case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                                  case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                         else smralib_area_desc
                                                                   end
                                                                else smralib_area_desc
                                                                end   nombre_area, ---
                                                smrarul_subj_code||smrarul_crse_numb_low materia, ---
                                                 scrsyln_long_course_title nombre_mat, ---
                                                 null calif,  ---
                                                 'PC' ,  ---
                                                 smracaa_rule regla, ---
                                                 null origen, ---
                                                 null fecha, --
                                                 pidm ,
                                                 usu_siu
                                    from spriden, smrpaap, sgbstdn y, sorlcur so,SZTDTEC, smrarul, smracaa, smralib, stvstst, scrsyln, zstpara,smbagen
                                     where    spriden_pidm=pidm  and spriden_change_ind is null
                                               and   so.sorlcur_pidm= spriden_pidm
                                               and   so.SORLCUR_LMOD_CODE = 'LEARNER'
--                                               and   so.SORLCUR_CACT_CODE='ACTIVE'
                                               and   so.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                          and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                          and   ss.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                                          and   ss.SORLCUR_CACT_CODE='ACTIVE'
                                                                          and ss.sorlcur_program =prog)
                                               and   smrpaap_program=prog
                                               AND   smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                                               and   smrpaap_area=SMBAGEN_AREA
                                               and   SMBAGEN_ACTIVE_IND='Y'
                                               and   SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                               and   smrpaap_area=smrarul_area
                                               and   sgbstdn_pidm=spriden_pidm
                                               and   so.SORLCUR_program=smrpaap_program
--                                               and    sgbstdn_program_1=smrpaap_program
--                                               and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
--                                                                                where x.sgbstdn_pidm=y.sgbstdn_pidm
--                                                                                  and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                               and   sztdtec_program=so.SORLCUR_program and sztdtec_status='ACTIVO' and  SZTDTEC_CAMP_CODE=so.SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                               and   SZTDTEC_TERM_CODE=so.SORLCUR_TERM_CODE_CTLG
                                               and   stvstst_code=sgbstdn_stst_code
                                               and   smralib_area=smrpaap_area
                                               AND   smracaa_area = smrarul_area
                                               AND   smracaa_rule = smrarul_key_rule
                                               AND   SMRARUL_TERM_CODE_EFF = so.SORLCUR_TERM_CODE_CTLG
                                               and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001'
                                               )
                                               and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                            and spriden_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                               and   (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                     (smrarul_area in (select smriemj_area from smriemj
                                                                        where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                     from sorlcur cu, sorlfos ss
                                                                                                    where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                      and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                      and cu.sorlcur_pidm=pidm
                                                                                                      and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                      and SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                      and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                      and cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                      and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                      and   sorlcur_program   =prog
                                                                                                    )    )
                                               and smrarul_area not in (select smriecc_area from smriecc)) or
                                                     (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                         ( select distinct SORLFOS_MAJR_CODE
                                                                                             from sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                              and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                              and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                          and ss.sorlcur_program =prog )
                                                                                              and   cu.sorlcur_pidm=pidm
                                                                                              and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                              and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                              and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                              and   sorlcur_program   =prog
                                                                                           ) )) )
                                               and  scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTCKN_SUBJ_CODE,SHRTCKN_CRSE_NUMB  from shrtckn where shrtckn_pidm=pidm )
                                               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRCE_SUBJ_CODE,SHRTRCE_CRSE_NUMB  from SHRTRCE where SHRTRCE_pidm=pidm )     --agregado
                                               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRTK_SUBJ_CODE_INST,SHRTRTK_CRSE_NUMB_INST  from SHRTRTK where SHRTRTK_pidm=pidm )  --agregado
                                               and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select ssbsect_subj_code subj, ssbsect_crse_numb code  from  sfrstcr, smrprle, ssbsect, spriden  --agregado para materias EC y aprobadas sin rolar
                                                                                                       where  smrprle_program=prog
                                                                                                         and  sfrstcr_pidm=pidm  and (sfrstcr_grde_code is null or sfrstcr_grde_code is not null)  and sfrstcr_rsts_code='RE'
                                                                                                         and  spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                                         and  ssbsect_term_code=sfrstcr_term_code
                                                                                                         and  ssbsect_crn=sfrstcr_crn)
                                               and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=SORLCUR_program and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG;

                                 commit;


                          open avance_n_out
                            FOR
                             select   spriden_id matricula, spriden_first_name||' '||replace(spriden_last_name,'/',' ') nombre ,  sztdtec_programa_comp programa, stvstst_desc estatus,
                                      avance1.per, avance1.area,
                                      case when substr(spriden_id,1,2)='08' then ' '
                                      else
                                          case when substr(avance1.materia,1,4)='L1HB' then 'MATERIAS INTRODUCTORIAS'
                                                when substr(avance1.materia,1,4)='M1HB' then 'MATERIAS INTRODUCTORIAS'
                                          else upper(avance1.nombre_area)
                                          end
                                      end   "nombre_area",avance1.materia, avance1.nombre_mat,
                                       avance1.calif, avance1.ord,
                                     case when avance1.apr='AP' then null
                                         else apr
                                         end tipo,
                                         case when sztdtec_incorporante='SEGEM' then null
                                         else n_area
                                         end n_area,
                                     case when avance1.per < 7 then 1
                                           else 2
                                     end hoja,
                                   ----------------------------------------
                                   CASE  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                       where SMBPGEN_program=prog
                                                                           and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                       where s.sorlcur_pidm=pidm
                                                                                                         and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                         and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                 where ss.sorlcur_pidm=pidm
                                                                                                                                   and ss.sorlcur_program=prog
                                                                                                                                   and ss.sorlcur_lmod_code='LEARNER'))) ='40' then
                                                                                                                                                         (select count(unique materia)  from avance_n x
                                                                                                                                                           where  apr in ('AP','EQ')
                                                                                                                                                             and    protocolo=9999
                                                                                                                                                             and    pidm_alu=pidm
                                                                                                                                                             and    usuario_siu=usu_siu
                                                                                                                                                             and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                                                                                                                             and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                     where x.materia=xx.materia
                                                                                                                                                                                       and x.protocolo=xx.protocolo
                                                                                                                                                                                       and x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                       and x.usuario_siu=xx.usuario_siu)
                                                                                                                                                                                       and CALIF!=0
                                                    and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )

                                                  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                       where SMBPGEN_program=prog
                                                                           and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                                                 where  s.sorlcur_pidm=pidm
                                                                                                                                      and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                      and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                              where ss.sorlcur_pidm=pidm
                                                                                                                                                                and ss.sorlcur_program=prog
                                                                                                                                                                and ss.sorlcur_lmod_code='LEARNER'))) ='42' then
                                                                                                                                                                               (select count(unique materia)  from avance_n x
                                                                                                                                                                                 where  apr in ('AP','EQ')
                                                                                                                                                                                   and  protocolo=9999
                                                                                                                                                                                   and  pidm_alu=pidm
                                                                                                                                                                                   and  usuario_siu=usu_siu
                                                                                                                                                                                   and  area not in  ((select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' ) )
                                                                                                                                                                                   and  calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                                    where x.materia=xx.materia
                                                                                                                                                                                                      and x.protocolo=xx.protocolo
                                                                                                                                                                                                      and x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                                      and x.usuario_siu=xx.usuario_siu)
                                                                                                                                                                                                      and CALIF!=0
                                                    and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )
                                            ELSE
                                                  (select count(unique materia)  from avance_n x
                                                     where  apr in ('AP','EQ')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    usuario_siu=usu_siu
                                                     and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                     and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            and   x.usuario_siu=xx.usuario_siu)
                                                                            and CALIF!=0
                                                     and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )              )
                                      end  aprobadas_curr,
                                   ---------------------------
                                     (select count(unique materia)  from avance_n x
                                     where  apr in ('NA')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                     and    materia not in (select materia from avance_n xx
                                                               where x.materia=xx.materia
                                                                and  x.protocolo=xx.protocolo
                                                                and  x.pidm_alu=xx.pidm_alu
                                                                and  x.usuario_siu=xx.usuario_siu
                                                                and  xx.apr='EC')
                                     and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu)) no_aprobadas_curr,
                                     (select count(unique materia) from avance_n x
                                     where  apr in ('EC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                                  ) curso_curr,
                                         (select count(unique materia)  from avance_n x
                                                     where apr in ('PC')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    usuario_siu=usu_siu
                                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                     and materia not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB' and ZSTPARA_PARAM_VALOR=materia and
                                                           pidm_alu in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                           ) por_cursar_curr,
                                  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                where SMBPGEN_program=prog
                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                  where  sorlcur_pidm=pidm
                                                                                    and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                    and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                            where ss.sorlcur_pidm=pidm
                                                                                                             and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))) total_curr,
                                       case when
                                              round ((select count(unique materia) from avance_n x
                                             where  apr in ('AP','EQ')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    usuario_siu=usu_siu
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and     calif not in ('NP','AC')
                                             and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) or calif is null)
                                                      and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                          where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
                                                                    ) *100 /
                                            (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                    where  sorlcur_pidm=pidm
                                                                                                                       and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                       and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where ss.sorlcur_pidm=pidm
                                                                                                                                                                   and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))>100  then 100
                                         else
                                            round ((select count(unique materia) from avance_n x
                                             where  apr in ('AP','EQ')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    usuario_siu=usu_siu
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and     calif not in ('NP','AC')
                                             and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    and   x.usuario_siu=xx.usuario_siu and CALIF!=0) or calif is null)
                                                     and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                   (area in (select smriemj_area from smriemj
                                                                                           where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                              where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                   where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                       )    )
                                                      and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                 (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                     ( select distinct SORLFOS_MAJR_CODE
                                                                                                                         from  sorlcur cu, sorlfos ss
                                                                                                                          where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and   sorlcur_program   =prog
                                                                                                                             ) )) )
                                                                    ) *100 /
                                            (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                    where  sorlcur_pidm=pidm
                                                                                                                       and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                       and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                             where ss.sorlcur_pidm=pidm
                                                                                                                                                             and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))
                                       end Avance_n_curr,
                                    (select count(unique materia) from avance_n x
                                     where apr in ('AP','EQ')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                     and    to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu))  aprobadas_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('NA')
                                     and    protocolo=9999
                                      and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                     and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu)) no_aprobadas_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('EC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                  ) curso_tall,
                                     (select count(unique materia) from avance_n x
                                     where apr in ('PC')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                  )  por_cursar_tall,
                                    (select count(unique materia) from avance_n x
                                     where area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                     and    protocolo=9999
                                     and    pidm_alu=pidm
                                     and    usuario_siu=usu_siu
                                     and    (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                            where x.materia=xx.materia
                                                            and   x.protocolo=xx.protocolo
                                                            and   x.pidm_alu=xx.pidm_alu
                                                            and   x.usuario_siu=xx.usuario_siu) or calif is null)) total_tall
                                    from spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
                                    (SELECT 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
                                       FROM  (
                                                        select 9999, per, area, nombre_area, materia, nombre_mat,
                                                                       case when calif='1' then cal_origen
                                                                                when apr='EC' then null
                                                                        else calif
                                                                        end calif, apr, regla, null n_area,
                                                                       case when substr(materia,1,2)='L3' then 5
                                                                        else 1
                                                                       end ord,fecha
                                                                 from  sgbstdn y, avance_n x,sorlcur co
                                                                   where  x.protocolo=9999
                                                                    and    sgbstdn_pidm=pidm
                                                                    and    co.sorlcur_pidm=pidm
                                                                    and    co.sorlcur_program=prog
                                                                    and    x.pidm_alu=pidm
                                                                    and    x.usuario_siu=usu_siu
--                                                                    and    sgbstdn_program_1=prog
--                                                                    and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
--                                                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
--                                                                                                        and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                    and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and  x.protocolo=xx.protocolo   ----cambio
                                                                          and  x.pidm_alu=sgbstdn_pidm  ----cambio
                                                                          and  x.pidm_alu=xx.pidm_alu   ---- cambio
                                                                          and  x.usuario_siu=xx.usuario_siu) or calif is null)
                                                        union
                                                        select distinct 9999, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                                                        case when calif='1' then cal_origen
                                                                when apr='EC' then null
                                                        else calif
                                                        end calif, apr, regla, null n_area,
                                                        case when substr(materia,1,2)='L3' then 5
                                                        else 1
                                                       end ord, fecha
                                                                    from  sgbstdn y, avance_n x,sorlcur co
                                                                   where   x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                     and    x.pidm_alu=sgbstdn_pidm
                                                                     and    co.sorlcur_pidm=pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     apr='EC'
                                                                    and     co.sorlcur_program=prog
--                                                                    and    sgbstdn_program_1=prog
--                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
--                                                                                                       where x.sgbstdn_pidm=y.sgbstdn_pidm
--                                                                                                         and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                        union
                                                        select protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                    case when calif='1' then cal_origen
                                                                           when apr='EC' then null
                                                                    else calif
                                                                    end calif, apr, regla, stvmajr_desc n_area, 2 ord, fecha
                                                                    from  sgbstdn y, avance_n x, smriemj, stvmajr,sorlcur co
                                                                   where   x.protocolo=9999
                                                                    and     sgbstdn_pidm=pidm
                                                                    and     x.pidm_alu=sgbstdn_pidm
                                                                    and     co.sorlcur_pidm=pidm
                                                                    and     x.usuario_siu=usu_siu
                                                                    and     co.SORLCUR_PROGRAM=prog
--                                                                    and    sgbstdn_program_1=prog
--                                                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
--                                                                                                       where x.sgbstdn_pidm=y.sgbstdn_pidm
--                                                                                                         and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and    area=smriemj_area
--                                                                   and smriemj_majr_code=sgbstdn_majr_code_1   --vic
                                                                   and smriemj_majr_code= (select distinct SORLFOS_MAJR_CODE
                                                                                            from  sorlcur cu, sorlfos ss
                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                            and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                            and   cu.sorlcur_pidm=pidm
                                                                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                            and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                            and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                          and ss.sorlcur_program =prog)
                                                                                            and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                              and ss.sorlcur_program =prog)
                                                                                            and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                                            and   sorlcur_program   =prog
                                                                                          )
                                                                   and    area not in (select smriecc_area from smriecc)
                                                                   and    smriemj_majr_code=stvmajr_code
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or calif is null)
                                                        union
                                                          select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                case when calif='1' then cal_origen
                                                                         when apr='EC' then null
                                                                 else calif
                                                                end  calif, apr, regla, smralib_area_desc n_area, 3 ord, fecha
                                                                    from sgbstdn y, avance_n x ,smralib, smriecc a,sorlcur co
                                                                   where  x.protocolo=9999
                                                                    and   sgbstdn_pidm=pidm
                                                                    and   co.sorlcur_pidm=pidm
                                                                    and   x.pidm_alu=sgbstdn_pidm
                                                                    and   x.usuario_siu=usu_siu
                                                                    and   co.SORLCUR_PROGRAM=prog
--                                                                    and    sgbstdn_program_1=prog
--                                                                    and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
--                                                                                                     where x.sgbstdn_pidm=y.sgbstdn_pidm
--                                                                                                       and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                   and    area=smralib_area
                                                                   and    area=smriecc_area
--                                                                   and    smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)---modifico vic   18.04.2018
                                                                   and     smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
--                                                                                                        and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
--                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
--                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
--                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                        and   cu.sorlcur_pidm=pidm
                                                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                                                                        and   sorlcur_program   =prog
                                                                                                         )
--                                                                   and    smriecc_majr_code_conc=stvmajr_code
                                                                   and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or calif is null)
--                                                                          or calif='1')   -----------------
                                                                   and    (fecha in (select distinct fecha from avance_n xx
                                                                          where x.materia=xx.materia
                                                                          and   x.protocolo=xx.protocolo
                                                                          and   x.pidm_alu=xx.pidm_alu
                                                                          and   x.usuario_siu=xx.usuario_siu) or fecha is null)
                                                        order by   n_area desc, per, nombre_area,regla
                                          )
                                        GROUP BY 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
                                    )  avance1
                                    where  spriden_pidm=pidm
                                    and   so.sorlcur_pidm= spriden_pidm
                                    and   so.SORLCUR_LMOD_CODE = 'LEARNER'
--                                    and   so.SORLCUR_CACT_CODE='ACTIVE'
--                                    AND   avance_n.Programa=so.SORLCUR_PROGRAM
                                    and   so.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                               and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                 and  ss.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                                and  ss.SORLCUR_CACT_CODE='ACTIVE'
                                                               and ss.sorlcur_program =prog)
                                    and     spriden_change_ind is null
                                    and     sgbstdn_pidm=spriden_pidm
                                    and     so.SORLCUR_PROGRAM=prog
--                                    and    sgbstdn_program_1=prog
--                                    and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
--                                                                       where a.sgbstdn_pidm=b.sgbstdn_pidm
--                                                                         and a.sgbstdn_program_1=b.sgbstdn_program_1)
                                    and     sztdtec_program=so.SORLCUR_PROGRAM
                                    and     sztdtec_status='ACTIVO'
                                    and     SZTDTEC_CAMP_CODE=so.SORLCUR_CAMP_CODE
                                    and     SZTDTEC_TERM_CODE=so.SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                    and     sgbstdn_stst_code=stvstst_code
                                     order by  avance1.per,
                                       CASE WHEN so.SORLCUR_PROGRAM in (select ZSTPARA_PARAM_ID from ZSTPARA where ZSTPARA_MAPA_ID='PROG_ESPECIAL' and ZSTPARA_PARAM_ID=so.sorlcur_program)  THEN
                                             avance1.n_area||','||avance1.regla||','||avance1.materia||','||avance1.ord||','||hoja
                                        WHEN so.sorlcur_program not in (select ZSTPARA_PARAM_ID from ZSTPARA where ZSTPARA_MAPA_ID='PROG_ESPECIAL' and ZSTPARA_PARAM_ID=so.sorlcur_program)  THEN
                                             avance1.n_area||','||avance1.materia||','||avance1.regla||','||avance1.ord||','||hoja
                                       END;
        END;

   END IF;

   RETURN (avance_n_out);

 END f_dashboard_avcu_out;


FUNCTION f_dashboard_materias_out (P_MATRICULA in varchar2) RETURN PKG_DASHBOARD_DOCENTES.m_out
           AS
                mat_out PKG_DASHBOARD_DOCENTES.m_out;
    
    vl_mensaje varchar2(100);
    vl_valida number;
   
                       BEGIN
                        begin 
                           select count (*)
                            into vl_valida
                                              from szstume,SZTMACF
                                               where 1=1
                                               and  SZSTUME_ID=P_MATRICULA
                                               and SZSTUME_NO_REGLA=1
                                               and SZSTUME_SUBJ_CODE=SZTMACF_SUBJ
                                               and SZSTUME_START_DATE=SZTMACF_FECHA_INICIO
                                               and SZSTUME_TERM_NRC_COMP is  NULL
                                               and SZSTUME_GRDE_CODE_FINAL =0
                                               and SZSTUME_PTRM is NULL
--                                               AND SZSTUME_STAT_IND=1
                                               and SZSTUME_SUBJ_CODE  in (select a.SZSTUME_SUBJ_CODE
                                                                             from szstume a
                                                                               where 1=1
                                                                               and a.SZSTUME_ID=P_MATRICULA
                                                                               and a.SZSTUME_NO_REGLA=1 
                                                                               and a.SZSTUME_SUBJ_CODE=SZSTUME_SUBJ_CODE
                                                                               and a.SZSTUME_START_DATE=SZSTUME_START_DATE );
                         
                        end ;
                        
                if vl_valida=2 then
                null;
                                   
                elsif  vl_valida=1 then       
                          open mat_out
                           FOR
                   select clave_materia,nom_materia,fecha_ini
                       from (   
                          select
                           SZTMACF_SUBJ clave_materia,
                           SZTMACF_SUBJDES nom_materia,
                           SZTMACF_FECHA_INICIO fecha_ini,
                           SZTMACF_SERIACION seriacion
                            from sztmacf 
                            join SIRCMNT ON SIRCMNT_TEXT=SZTMACF_CAMP
                            join SPRIDEN ON SPRIDEN_pidm=SIRCMNT_PIDM  and SPRIDEN_CHANGE_IND is null
                            join SIBINST on SIBINST_pidm = SPRIDEN_pidm and SIBINST_FCST_CODE not in ('BA', 'IN') 
                            where 1=1
                            AND SPRIDEN_id=P_MATRICULA
                            and (exists (
                                 select 1
                                              from szstume A
                                               where A.SZSTUME_ID=SPRIDEN_id
                                               and SZTMACF_SUBJ= A.SZSTUME_SUBJ_CODE
                                               and A.SZSTUME_NO_REGLA=1
                                               and to_number(A.SZSTUME_GRDE_CODE_FINAL) < to_number(SZTMACF_MINAPRO )
                                               and not exists  (
                                                                 select 1
                                                                              from szstume b
                                                                               where b.SZSTUME_ID=SPRIDEN_id 
                                                                               and SZTMACF_SUBJ= b.SZSTUME_SUBJ_CODE
                                                                               and b.SZSTUME_TERM_NRC_COMP is null 
                                                                               ))
                                 or not exists 
                                   (select 1
                                              from szstume A
                                               where A.SZSTUME_ID=SPRIDEN_id
                                               and SZTMACF_SUBJ= A.SZSTUME_SUBJ_CODE
                                               and A.SZSTUME_NO_REGLA=1)
                                 )                                 
                            And trunc (sysdate) between trunc (SZTMACF_FECHA_INICIO) - SZTMACF_NUM_INI and trunc (SZTMACF_FECHA_INICIO) + SZTMACF_NUM_CIERRE
                                order by seriacion                             
                               )
                               where 1=1 and rownum <=1;                               
                   RETURN (mat_out);           
              else  
                 open mat_out
                           FOR
                select clave_materia,nom_materia,fecha_ini
                       from (   
                          select
                           SZTMACF_SUBJ clave_materia,
                           SZTMACF_SUBJDES nom_materia,
                           SZTMACF_FECHA_INICIO fecha_ini,
                           SZTMACF_SERIACION seriacion
                            from sztmacf 
                            join SIRCMNT ON SIRCMNT_TEXT=SZTMACF_CAMP
                            join SPRIDEN ON SPRIDEN_pidm=SIRCMNT_PIDM  and SPRIDEN_CHANGE_IND is null
                            join SIBINST on SIBINST_pidm = SPRIDEN_pidm and SIBINST_FCST_CODE not in ('BA', 'IN') 
                            where 1=1
                            AND SPRIDEN_id=P_MATRICULA
                            and SZTMACF_SUBJ not in (select SZSTUME_SUBJ_CODE
                                              from szstume
                                               where 1=1
                                               and SZTMACF_SUBJ= SZSTUME_SUBJ_CODE
                                               and SZSTUME_ID=P_MATRICULA
                                               and SZSTUME_NO_REGLA=1
                                               and to_number(SZSTUME_GRDE_CODE_FINAL) >= to_number(SZTMACF_MINAPRO))
                            And trunc (sysdate) between trunc (SZTMACF_FECHA_INICIO) - SZTMACF_NUM_INI and trunc (SZTMACF_FECHA_INICIO) + SZTMACF_NUM_CIERRE
                            order by SZTMACF_SUBJ asc)
                            where 1=1
                            and  rownum <= 2;
               RETURN (mat_out);  
                          
              end if;
              
         RETURN (mat_out);    
         
      Exception when Others then
      vl_mensaje:='No cuentas con materias para inscribir';
      Return (mat_out);
END f_dashboard_materias_out;

Function  f_dashboard_saldototal (p_pidm in number) return varchar2

Is

vl_monto number:=0;
vl_moneda varchar2(10);

    Begin
            select sum(nvl (tbraccd_balance, 0)) balance
            Into vl_monto
            from tbraccd
            Where tbraccd_pidm =  p_pidm; --39423
           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
        Return (vl_monto);
        --Return(vl_moneda);
       END f_dashboard_saldototal;



Function  f_dashboard_saldodia (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
    Begin
--            select sum(nvl (tbraccd_balance, 0)) balance
--            Into vl_monto
--            from tbraccd
--            Where tbraccd_pidm = p_pidm
--            And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate); --39423


  select sum(nvl (tbraccd_balance, 0)) balance
            Into vl_monto
            from tbraccd, TBBDETC
            Where tbraccd_pidm = p_pidm
           And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
--            And TBBDETC_TYPE_IND = 'C'
            And TRUNC(TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate); --39423

           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
        vl_moneda:=Null;
      Return (vl_monto);
    --  Return(vl_moneda);
    END f_dashboard_saldodia;


Function  f_dashboard_saldocorte (p_pidm in number ) RETURN PKG_DASHBOARD_DOCENTES.desc_corte_out
As

 desc_corte PKG_DASHBOARD_DOCENTES.desc_corte_out;

vl_vencimiento number;
vl_fecha varchar2(10);
vl_monto number:=0;
vl_moneda varchar2(10);
vl_mes varchar2(2);
 v_error varchar2(4000);
 vl_vence varchar2(10);


        Begin

            Begin
                select distinct to_number (decode (substr (sgbstdn_rate_code, 4, 1), 'A', 15, 'B', '30','C', '10')) vencimiento
                    Into vl_vencimiento
                from sgbstdn a
                Where sgbstdn_pidm = p_pidm
                and sgbstdn_term_code_eff = (select max( sgbstdn_term_code_eff )
                                              from sgbstdn
                                              where sgbstdn_pidm = a.sgbstdn_pidm);
            Exception
                When Others then
                vl_vencimiento := 30;
            End;

           Begin
              select to_char (sysdate,'YYYY/MM')
                Into vl_fecha
              from dual;
           End;


           Begin
              select to_char (sysdate,'MM')
                Into vl_mes
              from dual;
           End;

           If  vl_mes = '02' and vl_vencimiento = '30' then
               vl_vencimiento := '28';
           End if;

          vl_vence :=   (vl_fecha||'/'|| vl_vencimiento);
          --vl_vence :=   (vl_fecha||vl_vencimiento );
          --  vl_vence := '28/02/2017';
               BEGIN
                  open desc_corte
                   FOR
                      SELECT DISTINCT
                            NVL((SELECT SUM(MONTO)
                            FROM(SELECT SUM(NVL (TBRACCD_BALANCE, 0)) MONTO
                                 FROM TBRACCD
                                 WHERE TBRACCD_PIDM = P_PIDM
                                 AND TBRACCD_BALANCE > 0
                                 AND TBRACCD_DETAIL_CODE NOT IN (SELECT TBBDETC_DETAIL_CODE
                                                                 FROM TBBDETC
                                                                 WHERE TBBDETC_DCAT_CODE = 'INT')
                                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) <=  TO_DATE (VL_VENCE,'yyyy/mm/dd')
                                 UNION
                                 SELECT SUM(NVL (TBRACCD_BALANCE, 0)) MONTO
                                 FROM TBRACCD
                                 WHERE TBRACCD_PIDM = P_PIDM
                                 AND TBRACCD_BALANCE > 0
                                 AND TRUNC (TBRACCD_EFFECTIVE_DATE) <= TRUNC (SYSDATE)
                                 AND TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                            FROM TBBDETC
                                                            WHERE TBBDETC_DCAT_CODE IN ('INT')))),0) + NVL((SELECT SUM(NVL (TBRACCD_BALANCE, 0)) MONTO
                                                                                                         FROM TBRACCD
                                                                                                         WHERE TBRACCD_PIDM = P_PIDM
                                                                                                         AND TBRACCD_BALANCE < 0),0)SALDO,
                        TO_DATE (VL_VENCE,'yyyy/mm/dd')  FECHA,
                        NVL(TBRACCD_CURR_CODE,'MXN') MONEDA
                    FROM TBRACCD A
                    WHERE A.TBRACCD_PIDM = P_PIDM
                    GROUP BY TBRACCD_PIDM,TBRACCD_CURR_CODE,VL_VENCE;

-- select 1000 Monto, trunc (sysdate )  Fecha, 'MX' Moneda
--                            from dual;

              Exception
              When Others then
                vl_monto :=0;
                vl_moneda:=Null;
              End;
           RETURN (desc_corte);
        Exception
        when Others then
        v_error:='Se presento el Error:= '||sqlerrm;
                       open desc_corte for select null, null,  v_error from dual;
                                RETURN (desc_corte);
        End f_dashboard_saldocorte;

Function  f_dashboard_saldoiva (p_pidm in number ) return varchar2
Is

vl_monto number:=0;


Begin

 select sum(nvl (tbraccd_balance, 0)) balance
Into vl_monto
from tbbdetc a , tbraccd b
Where a.TBBDETC_DCAT_CODE = 'INT'  ---> Categoria de Intereses
And b.tbraccd_pidm = p_pidm
And b.TBRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
And b.TBRACCD_BALANCE >0
And b.TBRACCD_EFFECTIVE_DATE <= sysdate;

   Return (vl_monto);


Exception
    When Others then
    vl_monto:=0;
    Return (vl_monto);
End f_dashboard_saldoiva;

Function  f_dashboard_saldobeca (p_pidm in number ) return varchar2
Is

vl_monto number:=0;


Begin

select sum(nvl (c.TBRAPPL_AMOUNT, 0)) balance
Into vl_monto
from tbbdetc a , tbraccd b, tbrappl c
Where a.TBBDETC_DCAT_CODE in ('BEC', 'BEI')  ---> Categoria de Becas
And b.tbraccd_pidm = p_pidm
And b.TBRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
And b.tbraccd_pidm = c.tbrappl_pidm
And b.TBRACCD_TRAN_NUMBER = c.TBRAPPL_PAY_TRAN_NUMBER
And c.TBRAPPL_DIRECT_PAY_IND = 'Y'
And b.TBRACCD_EFFECTIVE_DATE <= sysdate;


   Return (vl_monto);


Exception
    When Others then
    vl_monto:=0;
    Return (vl_monto);
End f_dashboard_saldobeca;


Function  f_dashboard_edo_cta (p_pidm in number )RETURN PKG_DASHBOARD_DOCENTES.desc_edocta_out
As

   desc_edocta PKG_DASHBOARD_DOCENTES.desc_edocta_out;
   v_error varchar2(4000);

               BEGIN

                 P_dashboard_detail_code;

                 open desc_edocta
                   FOR
                     SELECT DISTINCT TBRACCD_TERM_CODE Periodo,
                                      TBRACCD_TRAN_NUMBER Secuencia,
                                      TBRACCD_DETAIL_CODE Concepto,
                                      TBBDETC_DESC Descripcion_Concepto,
                                      (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN TBRACCD_AMOUNT
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN NULL
                                       END)
                                         AS Monto_Inicial_Cargo,
                                      TBRACCD_BALANCE Saldo_Actual_Cargo,
                                      TRUNC (TBRACCD_EFFECTIVE_DATE) Fecha_Cargo,
                                      TRUNC (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                      (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN NULL
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN TBRACCD_AMOUNT
                                       END)
                                         AS Monto_Pago,
                                      DECODE (TBBDETC_TYPE_IND,  'C', 'Cargo',  'P', 'Pago') Tipo,
                                      TVRTAXD_TAX_AMOUNT Iva,
                                      TVRTAXD_DETAIL_CODE Concepto_IVA,
                                      NVL (TBRACCD_CURR_CODE, 'MXN') MONEDA,
                                      TBRACCD_RECEIPT_NUMBER ORDEN
                        FROM tbraccd, tbbdetc, TVRTAXD
                       WHERE TBRACCD_PIDM = p_pidm
                             AND (TBRACCD_DETAIL_CODE IN
                                     (SELECT TVRDCTX_DETC_CODE
                                        FROM TVRDCTX
                                       WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                             --AND TVRDCTX_CURR_CODE = 'MXN'
                                             )
                                  OR (TBRACCD_DETAIL_CODE NOT IN
                                         (SELECT TVRDCTX_DETC_CODE
                                            FROM TVRDCTX
                                           WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                 --AND TVRDCTX_CURR_CODE != 'MXN'
                                                 )
                                      --AND 'MXN' = (  SELECT GUBINST_BASE_CURR_CODE FROM GUBINST)
                                      ))
                                     AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                     AND TVRTAXD_PIDM(+) = TBRACCD_PIDM
                                     AND TVRTAXD_ACCD_TRAN_NUMBER(+) = TBRACCD_TRAN_NUMBER
                             --Se agreg??                            --and TBBDETC_DETC_ACTIVE_IND = 'Y'  Debe se saber su Edo de Cta aunque no est?activos
                             --Para homologar el mismo campus
                             AND SUBSTR (TBBDETC_DETAIL_CODE, 1, 2) =  SUBSTR (TBRACCD_TERM_CODE, 1, 2)
                             AND TBRACCD_DETAIL_CODE NOT IN --Excluye Tanto categoria como Detalle configurados en Param (Si existe detalle, no toma la Categoria)
                             --En caso de ser abonos, no se lleva el cargo que cubrio
                                    (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD WHERE TZTCODD_ORIGEN IN ('C1','C2'))
                             AND (--Para quitar blancos y ceros en cargos y pagos
                                   (CASE
                                     WHEN TBBDETC_TYPE_IND = 'C' THEN TBRACCD_AMOUNT
                                     WHEN TBBDETC_TYPE_IND = 'P' THEN NULL
                                  END) IS NOT NULL
                                  OR
                                  (CASE
                                          WHEN TBBDETC_TYPE_IND = 'C' THEN NULL
                                          WHEN TBBDETC_TYPE_IND = 'P' THEN TBRACCD_AMOUNT
                                  END) IS NOT NULL
                                    )
                             --Para Quitar los cargos negativos que se matan asi  mismos
                             AND TBRACCD_TRAN_NUMBER NOT IN(
                                     (SELECT TBRACCD_TRAN_NUMBER
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = p_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                        UNION
                                        SELECT TBRAPPL_CHG_TRAN_NUMBER
                                        FROM TBRAPPL,TBRACCD
                                        WHERE TBRACCD_PIDM = p_pidm
                                        AND TBRAPPL_PIDM= TBRACCD_PIDM
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                        AND TBRAPPL_PAY_TRAN_NUMBER IN (
                                                                                                SELECT TBRACCD_TRAN_NUMBER
                                                                                                FROM TBRACCD, TBBDETC
                                                                                                WHERE     TBRACCD_PIDM = p_pidm
                                                                                                AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                                                                                AND TBBDETC_TYPE_IND = 'C'
                                                                                                AND TBRACCD_AMOUNT < 0
                                                                                                )
                                        UNION
                                        SELECT NVL(TBRACCD_TRAN_NUMBER_PAID,0)
                                        FROM TBRACCD, TBBDETC
                                        WHERE     TBRACCD_PIDM = p_pidm
                                        AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                        AND TBBDETC_TYPE_IND = 'C'
                                        AND TBRACCD_AMOUNT < 0
                                         )
                                        UNION --Excluye Tanto categoria como Detalle configurados en Param (Si existe detalle, no toma la Categoria)
                                        --En cancelaciones definidas en Param y que se requiere que no se muestre la transaccion pagada que cubrio
                                        (SELECT TBRACCD_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = p_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_PAY_TRAN_NUMBER= TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD WHERE TZTCODD_ORIGEN IN ('C3','C4') )
                                        UNION
                                         SELECT TBRAPPL_CHG_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = p_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_PAY_TRAN_NUMBER= TBRACCD_TRAN_NUMBER  ---------aqu
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD WHERE TZTCODD_ORIGEN IN ('C3','C4') )
                                        UNION
                                         SELECT TBRAPPL_PAY_TRAN_NUMBER
                                            FROM TBRAPPL,TBRACCD
                                            WHERE TBRACCD_PIDM = p_pidm
                                            AND TBRAPPL_PIDM= TBRACCD_PIDM
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            AND TBRAPPL_CHG_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                                            AND   TBRACCD_DETAIL_CODE  IN   (  SELECT DISTINCT TZTCODD_DETAIL_CODE FROM TZTCODD WHERE TZTCODD_ORIGEN IN ('C3','C4') )
                                          )
                                          )
                    ORDER BY TRUNC (TBRACCD_EFFECTIVE_DATE) desc;    --------------- Aqui
                        RETURN (desc_edocta);
               Exception when others then
                       v_error:='No se encontraron registros'||sqlerrm;
                       open desc_edocta for select null, null, null, null, null, null, null, null, null, null, null,null,NULL, v_error from dual;
                                RETURN (desc_edocta);

               End f_dashboard_edo_cta;





Function  f_dashboard_descuento_apl (p_pidm in number ) RETURN PKG_DASHBOARD_DOCENTES.apl_out
   AS

        desc_apl PKG_DASHBOARD_DOCENTES.apl_out;
       v_error varchar2(4000);
       vl_moneda varchar2(10);

               BEGIN
                  open desc_apl
                   FOR
                        select  distinct SW.SWTMDAC_DETAIL_CODE_ACC Cargo, SW.SWTMDAC_DETAIL_CODE_DESC Descuento, SW.SWTMDAC_PERCENT_DESC Porcentaje ,
                                 SW.SWTMDAC_AMOUNT_DESC Monto, TBRACCD_CURR_CODE Moneda, tbraccd_term_code Periodo,
                                 SW.SWTMDAC_APPLICATION_DATE Fecha_Aplicacion
                        from  SWTMDAC SW, TBRACCD
                        where SW.SWTMDAC_pidm =  p_pidm
                        and  SW.SWTMDAC_MASTER_IND = 'Y'
                        and   SWTMDAC_APPLICATION_INDICATOR>=1
                        And SWTMDAC_APPLICATION_DATE is not null
                        AND  SW.SWTMDAC_pidm  = TBRACCD_PIDM
                        And SWTMDAC_DETAIL_CODE_ACC = TBRACCD_DETAIL_CODE
                        And  trunc (SWTMDAC_APPLICATION_DATE) = trunc (TBRACCD_ENTRY_DATE);
                        RETURN (desc_apl);
               Exception when others then
                       v_error:='No se encontraron registros'||sqlerrm;
                       open desc_apl for select null, null, null, null, null ,null, v_error from dual;
                                RETURN (desc_apl);
               End f_dashboard_descuento_apl;




Function  f_dashboard_descuento_no_apl (p_pidm in number )RETURN PKG_DASHBOARD_DOCENTES.Noapl_out

   AS

        desc_Noapl PKG_DASHBOARD_DOCENTES.Noapl_out;
        v_error varchar2(4000);

               BEGIN
                  open desc_Noapl
                   FOR
                        select distinct    SW.SWTMDAC_DETAIL_CODE_ACC Cargo, SW.SWTMDAC_DETAIL_CODE_DESC Descuento, SW.SWTMDAC_PERCENT_DESC Porcentaje , SW.SWTMDAC_AMOUNT_DESC Monto, TBRACCD_CURR_CODE Moneda,
                                  SW.SWTMDAC_EFFECTIVE_DATE_FIN Fecha_Inicio, SWTMDAC_EFFECTIVE_DATE_FIN Fecha_fin
                        from  SWTMDAC SW, TBRACCD
                        where SW.SWTMDAC_pidm = p_pidm
                        and  SW.SWTMDAC_MASTER_IND = 'Y'
                        and SWTMDAC_NUM_REAPPLICATION  >  SWTMDAC_APPLICATION_INDICATOR
                         and SWTMDAC_EFFECTIVE_DATE_FIN >=  sysdate
                        AND  SW.SWTMDAC_pidm  = TBRACCD_PIDM;

                        RETURN (desc_Noapl);
               Exception when others then
                       v_error:='No se encontraron registros'||sqlerrm;
                       open desc_Noapl for select null, null, null, null,null, null, v_error from dual;
                                RETURN (desc_Noapl);

               End f_dashboard_descuento_no_apl;





Function  f_dashboard_saldo_pendiente (p_pidm in number )RETURN PKG_DASHBOARD_DOCENTES.desc_edocta_out
As

 desc_edocta PKG_DASHBOARD_DOCENTES.desc_edocta_out;
  v_error varchar2(4000);

               BEGIN
                  open desc_edocta
                   FOR
                        Select distinct TBRACCD_TERM_CODE Periodo,
                                    TBRACCD_TRAN_NUMBER Secuencia,
                                    TBRACCD_DETAIL_CODE Concepto,
                                    TBBDETC_DESC Descripcion_Concepto,
                                    case when TBBDETC_TYPE_IND = 'C' then
                                         TBRACCD_AMOUNT
                                    when TBBDETC_TYPE_IND = 'P' then
                                          null
                                    End  as Monto_Inicial_Cargo  ,
                                    TBRACCD_BALANCE Saldo_Actual_Cargo,
                                    trunc (TBRACCD_ENTRY_DATE)  Fecha_Cargo,
                                    trunc (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                    case when TBBDETC_TYPE_IND = 'C' then
                                        null
                                    when TBBDETC_TYPE_IND = 'P' then
                                        null
                                    End  as Monto_Pago  ,
                                    decode (TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                                    TVRTAXD_TAX_AMOUNT Iva,
                                    TVRTAXD_DETAIL_CODE Concepto_IVA,
                                    TBRACCD_CURR_CODE MONEDA,
                                    TBRACCD_RECEIPT_NUMBER orden
                                from tbraccd, tbbdetc, TVRTAXD
                                Where TBRACCD_PIDM = p_pidm
                                AND ( TBRACCD_DETAIL_CODE IN  (Select TVRDCTX_DETC_CODE
                                                                                   FROM TVRDCTX
                                                                                   WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                    AND TVRDCTX_CURR_CODE = 'MXN')
                                OR  (TBRACCD_DETAIL_CODE NOT IN (SELECT TVRDCTX_DETC_CODE
                                                                                        FROM TVRDCTX
                                                                                        WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                        AND TVRDCTX_CURR_CODE != 'MXN' )
                                                                                        AND 'MXN' =  (SELECT GUBINST_BASE_CURR_CODE
                                                                                        FROM GUBINST) ))
                                And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                And  TVRTAXD_PIDM (+) = TBRACCD_PIDM
                                And TVRTAXD_ACCD_TRAN_NUMBER  (+) =  TBRACCD_TRAN_NUMBER
                                And TBBDETC_TYPE_IND = 'C'
                                And TBRACCD_BALANCE > 0
                                order by 8 asc ;

                        RETURN (desc_edocta);
               Exception when others then
                       v_error:='No se encontraron registros'||sqlerrm;
                       open desc_edocta for select null, null, null, null, null, null, null, null, null, null, null,null, null, v_error from dual;
                                RETURN (desc_edocta);

               End f_dashboard_saldo_pendiente;

 Function  f_dashboard_pagos_vencidos (p_pidm in number )RETURN PKG_DASHBOARD_DOCENTES.pagos_vencidos_out
As

 pagos_vencidos PKG_DASHBOARD_DOCENTES.pagos_vencidos_out;
  v_error varchar2(4000);

               BEGIN
                  open pagos_vencidos
                   FOR   /*
                        Select distinct ('COLEGIATURA') c_tipo,
                                    SUBSTR(TBRACCD_EFFECTIVE_DATE,4,2) mes,
                                    TBRACCD_TERM_CODE Periodo,
                                    TBRACCD_TRAN_NUMBER Secuencia,
                                    TBRACCD_DETAIL_CODE Concepto,
                                    TBBDETC_DESC Descripcion_Concepto,
                                    TBRACCD_BALANCE Saldo_Actual_Cargo,
                                    trunc (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                    decode (TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                                    TBRACCD_CURR_CODE MONEDA
                                from tbraccd, tbbdetc, TVRTAXD
                                Where TBRACCD_PIDM = p_pidm
                                AND ( TBRACCD_DETAIL_CODE IN  (Select TVRDCTX_DETC_CODE
                                                                                   FROM TVRDCTX
                                                                                   WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                    AND TVRDCTX_CURR_CODE = 'MXN')
                                OR  (TBRACCD_DETAIL_CODE NOT IN (SELECT TVRDCTX_DETC_CODE
                                                                                        FROM TVRDCTX
                                                                                        WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                        AND TVRDCTX_CURR_CODE != 'MXN' )
                                                                                        AND 'MXN' =  (SELECT GUBINST_BASE_CURR_CODE
                                                                                        FROM GUBINST) ))
                                And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                and TBBDETC_DESC LIKE 'COLEG%'
                                And  TVRTAXD_PIDM (+) = TBRACCD_PIDM
                                And TVRTAXD_ACCD_TRAN_NUMBER  (+) =  TBRACCD_TRAN_NUMBER
                                And TBBDETC_TYPE_IND = 'C'
                                and TBRACCD_EFFECTIVE_DATE<sysdate
                                And TBRACCD_BALANCE > 0
                        UNION
                            Select distinct ('INTERES ') c_tipo,
                                    SUBSTR(TBRACCD_EFFECTIVE_DATE,4,2) mes,
                                    TBRACCD_TERM_CODE Periodo,
                                    TBRACCD_TRAN_NUMBER Secuencia,
                                    TBRACCD_DETAIL_CODE Concepto,
                                    TBBDETC_DESC Descripcion_Concepto,
                                    TBRACCD_BALANCE Saldo_Actual_Cargo,
                                    trunc (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                    decode (TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                                    TBRACCD_CURR_CODE MONEDA
                                from tbraccd, tbbdetc, TVRTAXD
                                Where TBRACCD_PIDM = p_pidm
                                AND ( TBRACCD_DETAIL_CODE IN  (Select TVRDCTX_DETC_CODE
                                                                                   FROM TVRDCTX
                                                                                   WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                    AND TVRDCTX_CURR_CODE = 'MXN')
                                OR  (TBRACCD_DETAIL_CODE NOT IN (SELECT TVRDCTX_DETC_CODE
                                                                                        FROM TVRDCTX
                                                                                        WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                        AND TVRDCTX_CURR_CODE != 'MXN' )
                                                                                        AND 'MXN' =  (SELECT GUBINST_BASE_CURR_CODE
                                                                                        FROM GUBINST) ))
                                And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                and TBBDETC_DESC LIKE 'INTERES%'
                                And  TVRTAXD_PIDM (+) = TBRACCD_PIDM
                                And TVRTAXD_ACCD_TRAN_NUMBER  (+) =  TBRACCD_TRAN_NUMBER
                                And TBBDETC_TYPE_IND = 'C'
                                and TBRACCD_EFFECTIVE_DATE<sysdate
                                And TBRACCD_BALANCE > 0
                                order by 2,1 asc;
                                */

                                select decode (TZTNCD_CONCEPTO, 'Venta', 'COLEGIATURA', 'Nota Debito','ACCESORIOS', 'Interes' ,'INTERESES') c_tipo,
                                SUBSTR(a.TBRACCD_EFFECTIVE_DATE,4,2) mes,
                                    a.TBRACCD_TERM_CODE Periodo,
                                    a.TBRACCD_TRAN_NUMBER Secuencia,
                                    a.TBRACCD_DETAIL_CODE Concepto,
                                    c.TBBDETC_DESC Descripcion_Concepto,
                                    a.TBRACCD_BALANCE Saldo_Actual_Cargo,
                                    trunc (a.TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                    decode (c.TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                                    a.TBRACCD_CURR_CODE MONEDA
                                from tbraccd a
                                join TZTNCD b on b.TZTNCD_CODE = a.tbraccd_detail_code
                                join tbbdetc c on c.TBBDETC_DETAIL_CODE = a.tbraccd_detail_code and c.TBBDETC_TYPE_IND = 'C'
                                where 1=1
                                and a.tbraccd_pidm = p_pidm
                                and a.TBRACCD_EFFECTIVE_DATE<sysdate
                                And a.TBRACCD_BALANCE > 0
                               And b.TZTNCD_CONCEPTO in (  'Venta', 'Nota Debito', 'Interes')
                               order by 2,1 asc;
                        RETURN (pagos_vencidos);
               Exception when others then
                       v_error:='No se encontraron pagos vencidos'||sqlerrm;
                       open pagos_vencidos for select null, null, null, null, null,  null, null, null, null, v_error from dual;
                         RETURN (pagos_vencidos);

               End f_dashboard_pagos_vencidos;


Function  f_dashboard_pagos_futuros (p_pidm in number )RETURN PKG_DASHBOARD_DOCENTES.pagos_futuros_out
As

 pagos_futuros PKG_DASHBOARD_DOCENTES.pagos_futuros_out;
  v_error varchar2(4000);

               BEGIN
                  open pagos_futuros
                   FOR   /*
                       Select distinct ('COLEGIATURA') c_tipo,
                                    SUBSTR(TBRACCD_EFFECTIVE_DATE,4,2) mes,
                                    TBRACCD_TERM_CODE Periodo,
                                    TBRACCD_TRAN_NUMBER Secuencia,
                                    TBRACCD_DETAIL_CODE Concepto,
                                    TBBDETC_DESC Descripcion_Concepto,
                                    TBRACCD_BALANCE Saldo_Actual_Cargo,
                                    trunc (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                    decode (TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                                    TBRACCD_CURR_CODE MONEDA
                                from tbraccd, tbbdetc, TVRTAXD
                                Where TBRACCD_PIDM = p_pidm
                                AND ( TBRACCD_DETAIL_CODE IN  (Select TVRDCTX_DETC_CODE
                                                                                   FROM TVRDCTX
                                                                                   WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                    AND TVRDCTX_CURR_CODE = 'MXN')
                                OR  (TBRACCD_DETAIL_CODE NOT IN (SELECT TVRDCTX_DETC_CODE
                                                                                        FROM TVRDCTX
                                                                                        WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                        AND TVRDCTX_CURR_CODE != 'MXN' )
                                                                                        AND 'MXN' =  (SELECT GUBINST_BASE_CURR_CODE
                                                                                        FROM GUBINST) ))
                                And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                and TBBDETC_DESC LIKE 'COLEG%'
                                And  TVRTAXD_PIDM (+) = TBRACCD_PIDM
                                And TVRTAXD_ACCD_TRAN_NUMBER  (+) =  TBRACCD_TRAN_NUMBER
                                And TBBDETC_TYPE_IND = 'C'
                                and TBRACCD_EFFECTIVE_DATE>=sysdate
                                And TBRACCD_BALANCE > 0
                        UNION
                            Select distinct ('INTERES ') c_tipo,
                                    SUBSTR(TBRACCD_EFFECTIVE_DATE,4,2) mes,
                                    TBRACCD_TERM_CODE Periodo,
                                    TBRACCD_TRAN_NUMBER Secuencia,
                                    TBRACCD_DETAIL_CODE Concepto,
                                    TBBDETC_DESC Descripcion_Concepto,
                                    TBRACCD_BALANCE Saldo_Actual_Cargo,
                                    trunc (TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                    decode (TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                                    TBRACCD_CURR_CODE moneda
                                from tbraccd, tbbdetc, TVRTAXD
                                Where TBRACCD_PIDM = p_pidm
                                AND ( TBRACCD_DETAIL_CODE IN  (Select TVRDCTX_DETC_CODE
                                                                                   FROM TVRDCTX
                                                                                   WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                    AND TVRDCTX_CURR_CODE = 'MXN')
                                OR  (TBRACCD_DETAIL_CODE NOT IN (SELECT TVRDCTX_DETC_CODE
                                                                                        FROM TVRDCTX
                                                                                        WHERE TVRDCTX_DETC_CODE = TBRACCD_DETAIL_CODE
                                                                                        AND TVRDCTX_CURR_CODE != 'MXN' )
                                                                                        AND 'MXN' =  (SELECT GUBINST_BASE_CURR_CODE
                                                                                        FROM GUBINST) ))
                                And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                and TBBDETC_DESC LIKE 'INTERES%'
                                And  TVRTAXD_PIDM (+) = TBRACCD_PIDM
                                And TVRTAXD_ACCD_TRAN_NUMBER  (+) =  TBRACCD_TRAN_NUMBER
                                And TBBDETC_TYPE_IND = 'C'
                                and TBRACCD_EFFECTIVE_DATE>=sysdate
                                And TBRACCD_BALANCE > 0
                                order by 2,1 asc;*/

                                select decode (TZTNCD_CONCEPTO, 'Venta', 'COLEGIATURA', 'Nota Debito','ACCESORIOS', 'Interes' ,'INTERESES') c_tipo,
                                SUBSTR(a.TBRACCD_EFFECTIVE_DATE,4,2) mes,
                                    a.TBRACCD_TERM_CODE Periodo,
                                    a.TBRACCD_TRAN_NUMBER Secuencia,
                                    a.TBRACCD_DETAIL_CODE Concepto,
                                    c.TBBDETC_DESC Descripcion_Concepto,
                                    a.TBRACCD_BALANCE Saldo_Actual_Cargo,
                                    trunc (a.TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                                    decode (c.TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                                    a.TBRACCD_CURR_CODE MONEDA
                                from tbraccd a
                                join TZTNCD b on b.TZTNCD_CODE = a.tbraccd_detail_code
                                join tbbdetc c on c.TBBDETC_DETAIL_CODE = a.tbraccd_detail_code and c.TBBDETC_TYPE_IND = 'C'
                                where 1=1
                                and a.tbraccd_pidm = p_pidm
                                and a.TBRACCD_EFFECTIVE_DATE>= sysdate
                                And a.TBRACCD_BALANCE > 0
                               And b.TZTNCD_CONCEPTO in (  'Venta', 'Nota Debito', 'Interes')
                               order by 2,1 asc;

                        RETURN (pagos_futuros);
               Exception when others then
                       v_error:='No se encontraron pagos por vencer'||sqlerrm;
                       open pagos_futuros for select null, null, null, null, null, null, null, null, null, v_error from dual;
                         RETURN (pagos_futuros);

               End f_dashboard_pagos_futuros;

    FUNCTION f_referencias_out (p_pidm in varchar2) RETURN PKG_DASHBOARD_DOCENTES.refe_out

    as
        refer_out PKG_DASHBOARD_DOCENTES.refe_out;
         v_error varchar2(4000);

   BEGIN
        open  refer_out for
        select GORADID_ADDITIONAL_ID referencia
        from goradid
        where GORADID_PIDM =p_pidm
        and GORADID_ADID_CODE like 'REF%';
        return(refer_out);
        exception when others then
        v_error:='No se encontraron registros'||sqlerrm;
        open refer_out for select v_error from dual;
            return (refer_out);
    END f_referencias_out;


FUNCTION f_dashboard_inbec (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.datos_out_inbe
AS

dat_out_inbe PKG_DASHBOARD_DOCENTES.datos_out_inbe;
vl_msje varchar2(250);

            BEGIN
            open dat_out_inbe for
            Select spriden_id matricula, spriden_first_name||' '||spriden_last_name nombre, goradid_adid_code alumno_inbec
                    from spriden, goradid
                    where spriden_pidm=goradid_pidm
                    and spriden_pidm = p_pidm
                    and goradid_adid_code='INBE'
                    and SPRIDEN_CHANGE_IND is null;

            RETURN (dat_out_inbe);
            exception when others then
            vl_msje:='No se econtraron registros'||sqlerrm;
--            open dat_out_inbe for select vl_msje from dual;
--            return (dat_out_inbe);
            END f_dashboard_inbec;


 PROCEDURE P_dashboard_detail_code  as

    EXISTE NUMBER;

    cursor c1 is
    select DISTINCT x1.TBBDETC_DCAT_CODE, x1.TBBDETC_DETAIL_CODE
    from tbbdetc x1
    where  x1.TBBDETC_DETAIL_CODE  in   (  SELECT ZSTPARA_PARAM_VALOR
                                                                 FROM ZSTPARA WHERE ZSTPARA_MAPA_ID= 'COD_EDO_CTA'
                                                                 and ZSTPARA_PARAM_ID='DETAIL_CODE') ;
    --and  x1.TBBDETC_DCAT_CODE = 'LPC' ;

    cursor c2 is
    select  distinct x1.TBBDETC_DCAT_CODE, X1.TBBDETC_DETAIL_CODE --971
    from tbbdetc x1
    where x1.TBBDETC_DCAT_CODE in ( SELECT ZSTPARA_PARAM_VALOR
                                                            FROM ZSTPARA WHERE ZSTPARA_MAPA_ID= 'COD_EDO_CTA'
                                                            and ZSTPARA_PARAM_ID='DCAT_CODE') ;
    --and  x1.TBBDETC_DCAT_CODE = 'LPC' ;

    cursor c3 is
    select DISTINCT x1.TBBDETC_DCAT_CODE, x1.TBBDETC_DETAIL_CODE
    from tbbdetc x1
    where  x1.TBBDETC_DETAIL_CODE  in   (  SELECT ZSTPARA_PARAM_VALOR
                                                                 FROM ZSTPARA WHERE ZSTPARA_MAPA_ID= 'COD_EDO_CTA'
                                                                 and ZSTPARA_PARAM_ID='DETAIL_CODE2') ;

    cursor c4 is
    select  distinct x1.TBBDETC_DCAT_CODE, X1.TBBDETC_DETAIL_CODE --971
    from tbbdetc x1
    where x1.TBBDETC_DCAT_CODE in ( SELECT ZSTPARA_PARAM_VALOR
                                                            FROM ZSTPARA WHERE ZSTPARA_MAPA_ID= 'COD_EDO_CTA'
                                                            and ZSTPARA_PARAM_ID='DCAT_CODE') ;

begin

       DELETE TZTCODD;

       for z in c1 loop
                insert into TZTCODD (TZTCODD_DETAIL_CODE, TZTCODD_DCAT_CODE,TZTCODD_ORIGEN)
                             values    ( z.TBBDETC_DETAIL_CODE,z.TBBDETC_DCAT_CODE, 'C1');
       end loop;

       for y in c2 loop

           select  COUNT(*)
           INTO EXISTE
           from TZTCODD
           WHERE  TZTCODD_DCAT_CODE = Y.TBBDETC_DCAT_CODE
           AND TZTCODD_ORIGEN= 'C1';--y.TBBDETC_DETAIL_CODE
         -- and  x2.TBBDETC_DCAT_CODE = 'LPC'  ;

           IF EXISTE > 0 THEN
              CONTINUE;
           ELSE
              insert into TZTCODD (TZTCODD_DETAIL_CODE, TZTCODD_DCAT_CODE,TZTCODD_ORIGEN)
                             values    ( y.TBBDETC_DETAIL_CODE,y.TBBDETC_DCAT_CODE, 'C2');

           END IF;

       end loop;

       for z in c3 loop
                insert into TZTCODD (TZTCODD_DETAIL_CODE, TZTCODD_DCAT_CODE,TZTCODD_ORIGEN)
                             values    ( z.TBBDETC_DETAIL_CODE,z.TBBDETC_DCAT_CODE, 'C3');
       end loop;


       for y in c4 loop

           select  COUNT(*)
           INTO EXISTE
           from TZTCODD
           WHERE  TZTCODD_DCAT_CODE = Y.TBBDETC_DCAT_CODE
           AND TZTCODD_ORIGEN= 'C3';--y.TBBDETC_DETAIL_CODE
         -- and  x2.TBBDETC_DCAT_CODE = 'LPC'  ;

           IF EXISTE > 0 THEN
              CONTINUE;
           ELSE
              insert into TZTCODD (TZTCODD_DETAIL_CODE, TZTCODD_DCAT_CODE,TZTCODD_ORIGEN)
                             values    ( y.TBBDETC_DETAIL_CODE,y.TBBDETC_DCAT_CODE, 'C4');

           END IF;

       end loop;

       commit;

END P_dashboard_detail_code;


--FUNCTION   p_fecha_ini (p_pidm in number) Return varchar2
--is
----vl_fecha_ini date;
--vl_salida varchar2(250):= 'EXITO';
--vl_fecha varchar2(25):= null;
--
--BEGIN
--
--    Begin
--
--
--
--        select  to_CHAR (min (x.fecha_inicio),'dd/mm/rrrr')||' ' || ' Periodo  ' || x.Periodo  fecha, min (x.fecha_inicio) --, rownum
--            into   vl_salida, vl_fecha
--        from (
--        SELECT DISTINCT
--                   MIN (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
--                FROM SFRSTCR a, SSBSECT b
--               WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
--                     AND a.SFRSTCR_CRN = b.SSBSECT_CRN
--                --     AND a.SFRSTCR_RSTS_CODE = 'RE'
--                     AND b.SSBSECT_PTRM_START_DATE =
--                            (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
--                               FROM SSBSECT b1
--                              WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
--                                    AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
--               and  SFRSTCR_pidm = p_pidm
--            GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
--            order by 1,3 asc
--            )  x
--            where rownum = 1
--            group by x.Periodo
--            order by 2 asc;
--
--
--
--
--
--
--    Exception
--    When Others then
--      vl_salida := '01/01/1900';
--    End;
--
--        return vl_salida;
--
--Exception
--When Others then
--  vl_salida := '01/01/1900';
-- return vl_salida;
--END p_fecha_ini;
--

FUNCTION   p_fecha_ini (p_pidm in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;
id_alumno varchar2(10):= null;

BEGIN

       select  f_getspridenid(p_pidm) into id_alumno from dual;
       if substr(id_alumno,1,2) not in ('40','53','54') then
        begin
            select  to_CHAR (min (x.fecha_inicio),'dd/mm/rrrr')||' ' || ' Periodo  ' || x.Periodo  fecha, min (x.fecha_inicio) --, rownum
                into   vl_salida, vl_fecha
            from (
            SELECT DISTINCT
                       MIN (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
                    FROM SFRSTCR a, SSBSECT b
                   WHERE     a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
                         AND a.SFRSTCR_CRN = b.SSBSECT_CRN
                    --     AND a.SFRSTCR_RSTS_CODE = 'RE'
                         AND b.SSBSECT_PTRM_START_DATE =
                                (SELECT MIN (b1.SSBSECT_PTRM_START_DATE)
                                   FROM SSBSECT b1
                                  WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
                                        AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
                   and  SFRSTCR_pidm = p_pidm
                GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
                order by 1,3 asc
                )  x
                where rownum = 1
                group by x.Periodo
                order by 2 asc;

        Exception
        When Others then
          vl_salida := '01/01/1900';
        End;

      Elsif substr(id_alumno,1,2) in ('40','53') then
        begin
            select  to_CHAR (MAX (x.fecha_inicio),'dd/mm/rrrr')||' ' || ' Periodo  ' || x.Periodo  fecha, MAX (x.fecha_inicio) --, rownum
                into   vl_salida, vl_fecha
            from (
            SELECT DISTINCT
                       MAX (TZTBOOT_START_DATE) fecha_inicio, TZTBOOT_PIDM pidm,TZTBOOT_TERM_CODE Periodo
                    FROM tztboot
                   WHERE  TZTBOOT_PIDM=p_pidm
                   and (TZTBOOT_CAMP_CODE='BOT' OR TZTBOOT_CAMP_CODE='UDD')
                  GROUP BY TZTBOOT_START_DATE, TZTBOOT_PIDM,TZTBOOT_TERM_CODE
                order by 1,3 asc
                ) x
                where rownum = 1
                group by x.Periodo
                order by 2 asc;


        Exception
        When Others then
          vl_salida := '01/01/1900';
        End;

       Elsif substr(id_alumno,1,2) = '54' then
        begin
            select  to_CHAR (MAX (x.fecha_inicio),'dd/mm/rrrr')||' ' || ' Periodo  ' || x.Periodo  fecha, MAX (x.fecha_inicio) --, rownum
                into   vl_salida, vl_fecha
            from (
            SELECT DISTINCT
                       MAX (TZTUTLX_START_DATE) fecha_inicio, TZTUTLX_PIDM pidm,TZTUTLX_TERM_CODE Periodo
                    FROM TZTUTLX
                   WHERE  TZTUTLX_PIDM=p_pidm
                   and TZTUTLX_CAMP_CODE='UTX'
                  GROUP BY TZTUTLX_START_DATE, TZTUTLX_PIDM,TZTUTLX_TERM_CODE
                order by 1,3 asc
                ) x
                where rownum = 1
                group by x.Periodo
                order by 2 asc;


        Exception
        When Others then
          vl_salida := '01/01/1900';
        End;

      end if;

      return vl_salida;

 Exception
 When Others then
   vl_salida := '01/01/1900';
  return vl_salida;
 END p_fecha_ini;

FUNCTION f_materia_faltante (p_pidm in number, p_camp in varchar2, p_levl in varchar2) RETURN varchar2
    IS

    vl_faltantes varchar2(10);
    vl_numero number :=0;
    vl_periodicidad varchar2 (2):= null;

   Begin

            Begin
                        select count (*) Numero ---, SFRSTCR_TERM_CODE, SFRSTCR_PIDM, SFRSTCR_PTRM_CODE
                           Into vl_numero
                        from MATERIA_CURSADA a
                        where a.PIDM = p_pidm;

            Exception
            When Others then
              vl_numero :=0;
              --dbms_output.put_line ('Error 1 '||sqlerrm);
            End;


            BEGIN
                    select
                        count(*) faltantes
                        Into vl_faltantes
                    from MATERIA_FALTANTE
                    where  PIDM = p_pidm
                    and CAMPUS = p_camp
                    and NIVEL = p_levl;
            Exception
            When Others then
                vl_faltantes :=0;
            End;

            Begin

                select distinct SZTDTEC_PERIODICIDAD
                    Into vl_periodicidad
                from AS_ALUMNOS a, REL_PROGRAMAXALUMNO b, SZTDTEC c
                where a.id_estadoactivo = 'A'
                AND b.PROGRAMA = c.SZTDTEC_PROGRAM
                And b.PERIODO_CATALOGO = SZTDTEC_TERM_CODE
                And a.SGBSTDN_PIDM = b.SGBSTDN_PIDM
                and b.SGBSTDN_PIDM = p_pidm
                And b.CAMPUS = p_camp
                and b.NIVEL = p_levl
                order by 1;
            Exception
            When Others then
              vl_periodicidad := 2;
            End;



        If vl_numero > 0  then


                If vl_numero <= 2  and vl_periodicidad= 2 then
                   vl_numero := 2;
                ElsIf vl_numero > 2 and vl_numero < 5    then
                        Begin
                                Select ZSTPARA_PARAM_VALOR Materias
                                   Into vl_numero
                                     from  ZSTPARA
                                where  ZSTPARA_MAPA_ID = 'SEL_MATERIA_DET'
                                And ZSTPARA_PARAM_ID = p_camp
                                and     substr (ZSTPARA_PARAM_DESC, 1, 2) = p_levl
                                and decode (substr (ZSTPARA_PARAM_DESC, 4, 3), 'BIM', 1, 'CUA', 2, 'SEM', 3, 'ANU', 4 )  = vl_periodicidad;
                        Exception
                        When Others then
                           vl_numero := 3;
                        End;

                ElsIf vl_numero >= 4 and vl_numero < 99  then
                        Begin
                                Select ZSTPARA_PARAM_VALOR Materias
                                   Into vl_numero
                                     from  ZSTPARA
                                where  ZSTPARA_MAPA_ID = 'SEL_MATERIA_DET'
                                And ZSTPARA_PARAM_ID = p_camp
                                and     substr (ZSTPARA_PARAM_DESC, 1, 2) = p_levl
                                and decode (substr (ZSTPARA_PARAM_DESC, 4, 3), 'BIM', 1, 'CUA', 2, 'SEM', 3, 'ANU', 4 )  = vl_periodicidad;
                        Exception
                        When Others then
                           vl_numero := 3;
                        End;
                End if;

                If vl_faltantes < vl_numero then
                   vl_numero := vl_faltantes;
                End if;

        else

               If vl_numero <= 2  and vl_periodicidad= 2 then
                   vl_numero := 2;
                ElsIf vl_numero > 2 and vl_numero < 5    then
                        Begin
                                Select ZSTPARA_PARAM_VALOR Materias
                                   Into vl_numero
                                     from  ZSTPARA
                                where  ZSTPARA_MAPA_ID = 'SEL_MATERIA_DET'
                                And ZSTPARA_PARAM_ID = p_camp
                                and     substr (ZSTPARA_PARAM_DESC, 1, 2) = p_levl
                                and decode (substr (ZSTPARA_PARAM_DESC, 4, 3), 'BIM', 1, 'CUA', 2, 'SEM', 3, 'ANU', 4 )  = vl_periodicidad;
                        Exception
                        When Others then
                           vl_numero := 3;
                        End;

                ElsIf vl_numero >= 4 and vl_numero < 99  then
                        Begin
                                Select ZSTPARA_PARAM_VALOR Materias
                                   Into vl_numero
                                     from  ZSTPARA
                                where  ZSTPARA_MAPA_ID = 'SEL_MATERIA_DET'
                                And ZSTPARA_PARAM_ID = p_camp
                                and     substr (ZSTPARA_PARAM_DESC, 1, 2) = p_levl
                                and decode (substr (ZSTPARA_PARAM_DESC, 4, 3), 'BIM', 1, 'CUA', 2, 'SEM', 3, 'ANU', 4 )  = vl_periodicidad;
                        Exception
                        When Others then
                           vl_numero := 3;
                        End;
                End if;

                If vl_faltantes < vl_numero then
                   vl_numero := vl_faltantes;
                End if;

        End if;

        RETURN (vl_numero);

   Exception
   When Others then
         vl_numero :=0;
   END f_materia_faltante;

FUNCTION f_jornada_sele (p_pidm in number, p_camp in varchar2, p_levl in varchar2, p_jorn in number) RETURN varchar2

  is

  p_error varchar2(2500) := 'EXITO';

      BEGIN
                  Begin
                       Update SZTPROC
                       set SZTPROC_JORNADA_NW = substr (SZTPROC_JORNADA,1,3)||  p_jorn
                       where SZTPROC_PIDM = p_pidm
                       and SZTPROC_CAMP_CODE = p_camp
                       and SZTPROC_LEVL_CODE = p_levl;

                  Exception
                          when Others then
                              p_error:= 'Error al insertar el numero de materias: '||sqlerrm;
                  End;

--                  If p_error = 'EXITO' then
--                           For c in (Select SZTPROC_PIDM, SZTPROC_JORNADA, SZTPROC_JORNADA_NW
--                                         from SZTPROC
--                                         where SZTPROC_PIDM = p_pidm
--                                          and SZTPROC_CAMP_CODE = p_camp
--                                          and SZTPROC_LEVL_CODE = p_levl ) loop
--                               Begin
--                                       Update SGRSATT
--                                       set SGRSATT_ATTS_CODE = c.SZTPROC_JORNADA_NW
--                                       Where SGRSATT_PIDM = c.SZTPROC_PIDM
--                                       and SGRSATT_ATTS_CODE = c.SZTPROC_JORNADA;
--                              Exception
--                                      when Others then
--                                          p_error:= 'Error al actualizar la Jornada proporcionada por el alumno: '||sqlerrm;
--                              End;
--
--                           End Loop;
--
--                           Commit;
--
--                  End if;

            Return (p_error);


      Exception
      When Others then
         p_error := 'Se presento un Error General  ' ||sqlerrm;
         Return (p_error);

    END f_jornada_sele;


Procedure p_solicita_materia (p_pidm in number, p_camp in varchar2, p_levl in varchar2, p_existe out number )

Is


    Begin

        Begin
            select  distinct count(1)
                Into p_existe
                from SZTPROC, SPRIDEN
            where  SZTPROC_PIDM = p_pidm
            and SZTPROC_CAMP_CODE = p_camp
            and SZTPROC_LEVL_CODE = p_levl
            and SZTPROC_JORNADA_NW is null
            And SZTPROC_PIDM = spriden_pidm
            and spriden_change_ind is null
            And spriden_id  not in (select  SZTEXCL_ID
                                            from SZTEXCL
                                            where SZTEXCL_PROGRAM = SZTPROC_PROGRAM);
        Exception
         When Others then
           p_existe :=0;
        End;

    Exception
        when Others then
           p_existe :=0;
    End p_solicita_materia;

   FUNCTION f_dashboard_matasigna_out (p_pidm in number,p_prog in varchar2) RETURN PKG_DASHBOARD_DOCENTES.matasigna_out
           AS
                asig_out PKG_DASHBOARD_DOCENTES.matasigna_out;

            BEGIN
                        open asig_out
                            FOR
                              with materias1 as (
                                                       select distinct SMRPAAP_PROGRAM PROG,
                                                                smrpaap_area area,
                                                                smralib_area_desc des,
                                                                SMRARUL_SEQNO Secuencia,
                                                                SMRPAAP_AREA_PRIORITY PRIO,
                                                                smrarul_subj_code||smrarul_crse_numb_low materia,
                                                                scrsyln_long_course_title nomb_m,
                                                                SMRIEMJ_MAJR_CODE MJR,
                                                                NULL MINO,
                                                                STVMAJR_DESC majr_desc
                                                               from smrpaap s, smrarul, sorlfos a, sorlcur C,SGBSTDN , sztdtec,spriden, stvstst, smralib,smracaa,scrsyln, zstpara,SMRIEMJ,STVMAJR,
                                                                            ( select shrtckn_subj_code subj, shrtckn_crse_numb code,
                                                                                     shrtckg_grde_code_final CALIF, decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, shrtckg_final_grde_chg_date fecha
                                                                                    from shrtckn,shrtckg, shrgrde, smrprle
                                                                                    where shrtckn_pidm=p_pidm
                                                                                    and     shrtckg_pidm=shrtckn_pidm
                                                                                    and     shrtckg_tckn_seq_no=shrtckn_seq_no   and shrtckg_term_code=shrtckn_term_code
                                                                                    and     smrprle_program=p_prog
                                                                                    and     shrgrde_levl_code=smrprle_levl_code
                                                                                    and     shrgrde_code=shrtckg_grde_code_final
           /* cambio escalas para prod */                                           and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                                                                                          where zstpara_mapa_id='ESC_SHAGRD'
                                                                                                                            and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=SMRPRLE_LEVL_CODE)
                                                                                    union
                                                                                    select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                                                    shrtrce_grde_code CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                                                    from  shrtrce
                                                                                    where  shrtrce_pidm=p_pidm
                                                                                    union
                                                                                    select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                                                    from sfrstcr, smrprle, ssbsect, spriden
                                                                                    where  smrprle_program=p_prog
                                                                                    and     sfrstcr_pidm=p_pidm and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                                                    and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                    and    ssbsect_term_code=sfrstcr_term_code
                                                                                    and    ssbsect_crn=sfrstcr_crn
                                                                                    union
                                                                                    select ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)+120  fecha
                                                                                    from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                                                                    where  smrprle_program=p_prog
                                                                                    and     sfrstcr_pidm=p_pidm and sfrstcr_grde_code is not null
                                                                                    and     sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and shrtckn_crn=sfrstcr_crn)
                                                                                    and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                    and    ssbsect_term_code=sfrstcr_term_code
                                                                                    and    ssbsect_crn=sfrstcr_crn
                                                                                    and    shrgrde_levl_code=smrprle_levl_code
                                                                                    and    shrgrde_code=sfrstcr_grde_code
                /* cambio escalas para prod */                                      and    shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                                                                                          where zstpara_mapa_id='ESC_SHAGRD'
                                                                                                                            and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=SFRSTCR_LEVL_CODE)
                                                                                    ) k
                                                                          where  spriden_pidm=p_pidm and spriden_change_ind is null and
                                                                                smrpaap_program=p_prog
                                                                            and     smrpaap_area=smrarul_area
                                                                            and     a.sorlfos_pidm=p_pidm
                                                                            and     a.sorlfos_pidm=sorlcur_pidm
                                                                            and     sgbstdn_pidm=sorlfos_pidm
                                                                            and     SGBSTDN_STST_CODE not in ('EG','BD','BT','BI','CV')
                                                                            and     C.SORLCUR_LMOD_CODE='LEARNER'
                                                                            and     C.SORLCUR_PROGRAM=smrpaap_program
                                                                            AND   a.SORLFOS_LCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)
                                                                                                          FROM SORLCUR c1x
                                                                                                         WHERE  a.sorlfos_pidm = c1x.sorlcur_pidm
                                                                                                               AND C.SORLCUR_LMOD_CODE = c1x.SORLCUR_LMOD_CODE
                                                                                                               AND C.SORLCUR_ROLL_IND     = c1x.SORLCUR_ROLL_IND
                                                                                                               AND C.SORLCUR_CACT_CODE = c1x.SORLCUR_CACT_CODE)
                                                                            AND   a.SORLFOS_TERM_CODE_CTLG = (SELECT MAX (c1x.SORLFOS_TERM_CODE_CTLG)
                                                                                                                  FROM SORLFOS c1x
                                                                                                               WHERE  a.sorlfos_pidm = c1x.SORLFOS_pidm
                                                                                                                    and c1x.SORLFOS_CACT_CODE='ACTIVE'
                                                                                                                    and a.SORLFOS_LCUR_SEQNO = c1x.SORLFOS_LCUR_SEQNO)
                                                                           and SMRPAAP_TERM_CODE_EFF= (select distinct sgbstdn_term_code_ctlg_1 from sgbstdn where  sgbstdn_pidm=c.SORLCUR_pidm
                                                                                                                  and c.SORLCUR_TERM_CODE_CTLG=sgbstdn_term_code_ctlg_1)
--                                                                            and        SMRPAAP_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG
                                                                            and     sztdtec_program=smrpaap_program and sztdtec_status='ACTIVO'
                                                                            and       SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE
                                                                            and     SZTDTEC_TERM_CODE=SGBSTDN_TERM_CODE_CTLG_1
                                                                            and     stvstst_code=sgbstdn_stst_code
                                                                            and     smralib_area=smrpaap_area
                                                                            AND    smracaa_area = smrarul_area
                                                                            AND    smracaa_rule = smrarul_key_rule
                                                                             and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                                               (smrarul_area in (select smriemj_area from smriemj
                                                                                       where smriemj_majr_code= ( select SORLFOS_MAJR_CODE
                                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                                      where cu.sorlcur_pidm = ss.SORLfos_PIDM
                                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                        and   a.SORLFOS_TERM_CODE_CTLG=ss.SORLFOS_TERM_CODE_CTLG
                                                                                                                        and   cu.sorlcur_pidm = p_pidm
                                                                                                                        and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                        and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                        and   cu.SORLCUR_CACT_CODE  = 'ACTIVE'
                                                                                                                        and   cu.sorlcur_program   = p_prog
                                                                                                                                  )   )
                                                                             and smrarul_area not in (select smriecc_area from smriecc)) or
                                                                               (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                 ( select SORLFOS_MAJR_CODE
                                                                                                                     from  sorlcur cu, sorlfos sss
                                                                                                                      where cu.sorlcur_pidm = sss.SORLfos_PIDM
                                                                                                                        and   cu.SORLCUR_SEQNO  = sss.SORLFOS_LCUR_SEQNO
                                                                                                                        and   a.SORLFOS_TERM_CODE_CTLG=sss.SORLFOS_TERM_CODE_CTLG
                                                                                                                        and   cu.sorlcur_pidm = p_pidm
                                                                                                                        and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                        and   sss.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                        and   cu.SORLCUR_CACT_CODE  = 'ACTIVE'
                                                                                                                        and   cu.sorlcur_program   = p_prog
                                                                                 ) ))
                                                                            )
                                                                             and    k.subj(+)=smrarul_subj_code and k.code(+)=smrarul_crse_numb_low
                                                                             and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low and SCRSYLN_TERM_CODE_EFF='000000'
                                                                             and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=smrpaap_program and zstpara_param_desc(+)=SMRPAAP_TERM_CODE_EFF
                                                                             and  substr(SMRPAAP_AREA,-2)  IN  (SELECT distinct min(substr(a.ZSTPARA_PARAM_VALOR,-2)) FROM ZSTPARA a
                                                                                                                                                                             WHERE a.ZSTPARA_MAPA_ID='AREAS_PROFESION'  AND a.ZSTPARA_PARAM_ID=p_prog
                                                                                                                                                                             AND a.ZSTPARA_PARAM_DESC=SMRPAAP_TERM_CODE_EFF)
                                                                              AND SMRIEMJ_AREA=SMRARUL_AREA
                                                                              and SMRIEMJ_MAJR_CODE=STVMAJR_CODE
                                                ),
                        materias2 as (
                                                  select SMRPAAP_PROGRAM PROG,
                                                            smrpaap_area area,
                                                            smralib_area_desc des,
                                                            SMRARUL_SEQNO Secuencia,
                                                            SMRPAAP_AREA_PRIORITY PRIO,
                                                            smrarul_subj_code||smrarul_crse_numb_low materia,
                                                            scrsyln_long_course_title nomb_m,
--                                                             (select distinct(SMRIEMJ_MAJR_CODE)
--                                                                FROM SMRIEMJ
--                                                                WHERE 1=1
--                                                                AND SMRIEMJ_AREA=SMRARUL_AREA
--                                                                and SMRIEMJ_AREA=smrpaap_area
--                                                                and rownum=1 )
                                                            null MJR,
                                                            SMRIECC_MAJR_CODE_CONC MINO,
                                                            STVMAJR_DESC majr_desc
                                                           from smrpaap s, smrarul, sgbstdn y, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,SMRIECC,STVMAJR,
                                                                        ( select shrtckn_subj_code subj, shrtckn_crse_numb code,
                                                                                 shrtckg_grde_code_final CALIF, decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, shrtckg_final_grde_chg_date fecha
                                                                                from shrtckn,shrtckg, shrgrde, smrprle
                                                                                where shrtckn_pidm=p_pidm
                                                                                and     shrtckg_pidm=shrtckn_pidm
                                                                                and     shrtckg_tckn_seq_no=shrtckn_seq_no   and shrtckg_term_code=shrtckn_term_code
                                                                                and     smrprle_program=p_prog
                                                                                and     shrgrde_levl_code=smrprle_levl_code
                                                                                and     shrgrde_code=shrtckg_grde_code_final
              /* cambio escalas para prod */                                    and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                                                                                      where zstpara_mapa_id='ESC_SHAGRD'
                                                                                                                        and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=SMRPRLE_LEVL_CODE)
                                                                                union
                                                                                select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                                                shrtrce_grde_code CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                                                from  shrtrce
                                                                                where  shrtrce_pidm=p_pidm
                                                                                union
                                                                                select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                                                from sfrstcr, smrprle, ssbsect, spriden
                                                                                where  smrprle_program=p_prog
                                                                                and     sfrstcr_pidm=p_pidm and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                                                and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                and    ssbsect_term_code=sfrstcr_term_code
                                                                                and    ssbsect_crn=sfrstcr_crn
                                                                                union
                                                                                select ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)+120  fecha
                                                                                from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                                                                where  smrprle_program=p_prog
                                                                                and     sfrstcr_pidm=p_pidm and sfrstcr_grde_code is not null
                                                                                and     sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and shrtckn_crn=sfrstcr_crn)
                                                                                and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                and    ssbsect_term_code=sfrstcr_term_code
                                                                                and    ssbsect_crn=sfrstcr_crn
                                                                                and     shrgrde_levl_code=smrprle_levl_code
                                                                                and     shrgrde_code=sfrstcr_grde_code
                     /* cambio escalas para prod */                             and     shrgrde_term_code_effective=(select zstpara_param_desc from zstpara
                                                                                                                      where zstpara_mapa_id='ESC_SHAGRD'
                                                                                                                        and substr((select f_getspridenid(p_pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=SMRPRLE_LEVL_CODE)
                                                                                ) k
                                                                      where   spriden_pidm=p_pidm and spriden_change_ind is null
                                                                       and      smrpaap_program=p_prog
                                                                       AND     smrpaap_term_code_eff = sgbstdn_term_code_ctlg_1
                                                                        and     smrpaap_area=smrarul_area
                                                                        and     sgbstdn_pidm=spriden_pidm
                                                                        and     sgbstdn_program_1=smrpaap_program
                                                                        and     SGBSTDN_STST_CODE not in ('EG','BD','BT','BI','CV')
                                                                        and     SGBSTDN_CAMP_CODE=SZTDTEC_CAMP_CODE   ---- nuevo  ----
                                                                        and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                                          where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                          and     x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                        and     sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO'
                                                                              and     SZTDTEC_TERM_CODE=y.SGBSTDN_TERM_CODE_CTLG_1
                                                                        and     stvstst_code=sgbstdn_stst_code
                                                                        and     smralib_area=smrpaap_area
                                                                        AND    smracaa_area = smrarul_area
                                                                        AND    smracaa_rule = smrarul_key_rule
                                                                        and     (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                                               (smrarul_area in (select smriemj_area from smriemj
                                                                                       where smriemj_majr_code= ( select SORLFOS_MAJR_CODE
                                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                                      where cu.sorlcur_pidm = ss.SORLfos_PIDM
                                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                        and   cu.sorlcur_pidm = p_pidm
                                                                                                                        and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                        and   ss.SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                        and   cu.SORLCUR_CACT_CODE  = 'ACTIVE'
                                                                                                                        and   cu.sorlcur_program   = p_prog
                                                                           )   )
                                                                             and smrarul_area not in (select smriecc_area from smriecc)) or
                                                                               (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                 ( select SORLFOS_MAJR_CODE
                                                                                                                     from  sorlcur cu, sorlfos sss
                                                                                                                      where cu.sorlcur_pidm = sss.SORLfos_PIDM
                                                                                                                        and   cu.SORLCUR_SEQNO  = sss.SORLFOS_LCUR_SEQNO
                                                                                                                        and   cu.sorlcur_pidm = p_pidm
                                                                                                                        and   cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                        and   sss.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                        and   cu.SORLCUR_CACT_CODE  = 'ACTIVE'
                                                                                                                        and   cu.sorlcur_program   = p_prog
                                                                                 ) ))
                                                                         )
                                                                         and    k.subj(+)=smrarul_subj_code and k.code(+)=smrarul_crse_numb_low
                                                                         and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low  and SCRSYLN_TERM_CODE_EFF='000000'
                                                                         and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=sgbstdn_program_1 and zstpara_param_desc(+)=sgbstdn_term_code_ctlg_1
                                                                         and  substr(SMRPAAP_AREA,-2) NOT IN  (SELECT distinct min(substr(a.ZSTPARA_PARAM_VALOR,-2)) FROM ZSTPARA a
                                                                                                                                                                         WHERE a.ZSTPARA_MAPA_ID='AREAS_PROFESION'  AND a.ZSTPARA_PARAM_ID=p_prog
                                                                                                                                                                         AND a.ZSTPARA_PARAM_DESC=SMRPAAP_TERM_CODE_EFF)
                                                                          AND SMRIECC_AREA=SMRARUL_AREA
                                                                          and SMRIECC_MAJR_CODE_CONC=STVMAJR_CODE
                                          )
                                             select distinct a.*,sorlfos_seqno seq_area
                                                           from sorlfos, stvmajr, sorlcur b,  materias1 a
                                                                   where  sorlfos_pidm=p_pidm
                                                                   and SORLFOS_LFST_CODE = 'MAJOR'
                                                                   and STVMAJR_CODE = SORLFOS_MAJR_CODE
                                                                    and b.sorlcur_lmod_code='LEARNER'
                                                                    and b.SORLCUR_PIDM    = SORLFOS_PIDM
                                                                    and b.SORLCUR_SEQNO = SORLFOS_LCUR_SEQNO
                                                                    and b.sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ss
                                                                                                   where  b.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                   and b.sorlcur_program=ss.sorlcur_program
                                                                                                   and b.sorlcur_lmod_code=ss.sorlcur_lmod_code)
                                                                    and a.MJR=SORLFOS_MAJR_CODE
                                                                     and a.prog=b.SORLCUR_PROGRAM
                                                          UNION
                                                                select distinct b.*,a.SORLFOS_SEQNO  seq_area
                                                                   from sorlfos a, stvmajr, sorlcur c,sfrstcr,materias2 b
                                                                   where a.sorlfos_pidm=p_pidm
                                                                   and a.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                   and STVMAJR_CODE = a.SORLFOS_MAJR_CODE
                                                                    and c.sorlcur_lmod_code='LEARNER'
                                                                    and c.SORLCUR_PIDM    = a.SORLFOS_PIDM
                                                                    and c.SORLCUR_SEQNO = a.SORLFOS_LCUR_SEQNO
                                                                    and a.SORLFOS_SEQNO = (select min (xx.SORLFOS_SEQNO)
                                                                                                         from SORLFOS xx
                                                                                                         where a.SORLFOS_PIDM = xx.SORLFOS_PIDM
                                                                                                         and a.SORLFOS_LCUR_SEQNO = xx.SORLFOS_LCUR_SEQNO
                                                                                                         and a.SORLFOS_LFST_CODE =  xx.SORLFOS_LFST_CODE)
                                                                    and c.sorlcur_seqno in (select max(ss.sorlcur_seqno)
                                                                                                        from sorlcur ss
                                                                                                   where  c.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                   and c.sorlcur_program=ss.sorlcur_program
                                                                                                   and c.sorlcur_lmod_code=ss.sorlcur_lmod_code)
                                                                     and b.MINO=a.SORLFOS_MAJR_CODE
                                                                     and c.SORLCUR_PROGRAM=b.prog
                                                               UNION
                                                                  select distinct c.*,b.SORLFOS_SEQNO seq_area
                                                                   from sorlfos b, stvmajr, sorlcur d,materias2 c
                                                                   where b.sorlfos_pidm=p_pidm
                                                                   and b.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                   and STVMAJR_CODE = b.SORLFOS_MAJR_CODE
                                                                    and d.sorlcur_lmod_code='LEARNER'
                                                                    and d.SORLCUR_PIDM    = b.SORLFOS_PIDM
                                                                    and d.SORLCUR_SEQNO = b.SORLFOS_LCUR_SEQNO
                                                                    and b.SORLFOS_SEQNO = (select max (xx.SORLFOS_SEQNO)
                                                                                                         from SORLFOS xx
                                                                                                         where b.SORLFOS_PIDM = xx.SORLFOS_PIDM
                                                                                                         and b.SORLFOS_LCUR_SEQNO = xx.SORLFOS_LCUR_SEQNO
                                                                                                         and b.SORLFOS_LFST_CODE =  xx.SORLFOS_LFST_CODE)
                                                                    and d.sorlcur_seqno in (select max(ss.sorlcur_seqno)
                                                                                                        from sorlcur ss
                                                                                                   where  d.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                   and d.sorlcur_program=ss.sorlcur_program
                                                                                                   and d.sorlcur_lmod_code=ss.sorlcur_lmod_code)
                                                                     and c.MINO=b.SORLFOS_MAJR_CODE
                                                                     and d.SORLCUR_PROGRAM=c.prog
                                                                     order by 2, 4;

                         RETURN (asig_out);

            END f_dashboard_matasigna_out;

   FUNCTION f_dashboard_matelegir_out (p_pidm in number,p_prog in varchar2) RETURN PKG_DASHBOARD_DOCENTES.matelegir_out
           AS
                elige_out PKG_DASHBOARD_DOCENTES.matelegir_out;

            BEGIN
                        open elige_out
                            FOR
                                  with salida1 as (
                                                             select distinct SOBCURR_program prog,
                                                                                 SOBCURR_CURR_RULE curr_r,
                                                                                 SORCMJR_CMJR_RULE cmjr_r,
                                                                                 SORCMJR_MAJR_CODE majr_c,
                                                                                 SMRIEMJ_AREA area_mjr,
                                                                                 NULL ccon_r,
                                                                                 NULL majr_cc,
                                                                                 NULL area_cc,
                                                                                 SMRALIB_AREA_DESC area_mdes,
                                                                                 STVMAJR_DESC majr_desc,
                                                                                 SORCMJR_TERM_CODE_EFF per
                                                             from SOBCURR,SORCMJR,SORCCON,SMRIEMJ,SMRALIB,STVMAJR
                                                             where SOBCURR_program=p_prog
                                                                 AND SOBCURR_CURR_RULE=SORCMJR_CURR_RULE
                                                                 and SORCMJR_CURR_RULE=SORCCON_CURR_RULE
                                                                 and SORCMJR_CMJR_RULE=SORCCON_CMJR_RULE
                                                                 AND SORCCON_ADM_IND = 'Y'
                                                                 AND SORCCON_REC_IND = 'Y'
                                                                 and  SORCMJR_MAJR_CODE=SMRIEMJ_MAJR_CODE
                                                                 and SMRALIB_AREA=SMRIEMJ_AREA
                                                                 and SORCMJR_MAJR_CODE=STVMAJR_CODE
                                                                 AND SMRIEMJ_TERM_CODE_EFF=SORCMJR_TERM_CODE_EFF
                                                                 and substr(SMRIEMJ_AREA,1,4)=substr(SOBCURR_PROGRAM,1,4)
                                                                 and substr(SMRIEMJ_AREA,-2) IN (SELECT distinct min(substr(ZSTPARA_PARAM_VALOR,-2)) FROM ZSTPARA
                                                                                                                      WHERE ZSTPARA_MAPA_ID='AREAS_PROFESION'  AND ZSTPARA_PARAM_ID=p_prog)
                                                                 and SMRIEMJ_AREA IN (SELECT distinct ZSTPARA_PARAM_VALOR FROM ZSTPARA
                                                                                                                      WHERE ZSTPARA_MAPA_ID='AREAS_PROFESION'  AND ZSTPARA_PARAM_ID=p_prog
                                                                                                                      AND SMRIEMJ_TERM_CODE_EFF=ZSTPARA_PARAM_DESC)
                                                                 ORDER BY SMRIEMJ_AREA
                                                   ),
                                    salida2 as (
                                                             select distinct SOBCURR_program prog,
                                                                     SOBCURR_CURR_RULE curr_r,
                                                                     SORCMJR_CMJR_RULE cmjr_r,
                                                                     SORCMJR_MAJR_CODE majr_c,
                                                                     NULL   area_mjr,
                                                                     SORCCON_CCON_RULE ccon_r,
                                                                     SORCCON_MAJR_CODE_CONC majr_cc,
                                                                     SMRIECC_AREA area_cc,
                                                                     SMRALIB_AREA_DESC area_mdes,
                                                                     STVMAJR_DESC majr_desc,
                                                                     SMRIECC_TERM_CODE_EFF per
                                                                     from SOBCURR,SORCMJR,SORCCON,SMRIECC,SMRALIB,STVMAJR
                                                                     where SOBCURR_PROGRAM=p_prog
                                                                     and SOBCURR_CURR_RULE=SORCMJR_CURR_RULE
                                                                     and SORCCON_ADM_IND = 'Y'
                                                                     and SORCCON_REC_IND = 'Y'
                                                                     and SORCMJR_CURR_RULE=SORCCON_CURR_RULE
                                                                     and SORCCON_CMJR_RULE=SORCMJR_CMJR_RULE
                                                                     and  SORCCON_MAJR_CODE_CONC=SMRIECC_MAJR_CODE_CONC
                                                                     and SORCMJR_VERSION=SORCMJR_VERSION
                                                                     and substr(SMRIECC_AREA,1,4)=substr(SOBCURR_PROGRAM,1,4)
                                                                     and SMRALIB_AREA=SMRIECC_AREA
                                                                     and SORCCON_MAJR_CODE_CONC=STVMAJR_CODE
                                                                     AND SMRIECC_TERM_CODE_EFF=SORCMJR_TERM_CODE_EFF
                                                                     and SMRIECC_AREA IN (SELECT distinct ZSTPARA_PARAM_VALOR FROM ZSTPARA
                                                                                                                      WHERE ZSTPARA_MAPA_ID='AREAS_PROFESION'  AND ZSTPARA_PARAM_ID=p_prog
                                                                                                                      AND SMRIECC_TERM_CODE_EFF=ZSTPARA_PARAM_DESC)
                                                                     ORDER BY SORCMJR_MAJR_CODE,SMRIECC_AREA

                                                    )
                                         select distinct a.*,SMRARUL_subj_code||SMRARUL_crse_numb_low mate,SCRSYLN_LONG_COURSE_TITLE NOMB_M,
                                                                    SORLFOS_LFST_CODE lfst
                                                            from sorlfos, stvmajr, sorlcur s,SMRARUL,SMRPAAP,SCRSYLN,salida1 a
                                                               where  sorlfos_pidm=p_pidm
                                                               and SORLFOS_LFST_CODE='MAJOR'
                                                               and (a.majr_cc,sorlfos_lcur_seqno)  not in (select p.SORLFOS_MAJR_CODE,p.sorlfos_lcur_seqno from sorlfos p
                                                                                                 where sorlfos_pidm=p.SORLFOS_pidm
                                                                                                    and a.majr_cc=p.SORLFOS_MAJR_CODE
                                                                                                    and sorlfos_lcur_seqno=p.sorlfos_lcur_seqno
                                                                                                    and sorlfos_seqno=p.sorlfos_seqno
                                                                                                    and  p.SORLFOS_LFST_CODE='CONCENTRATION')
                                                               and a.per= (select max(ss.SORLCUR_TERM_CODE_CTLG) from sorlcur ss
                                                                                                   where s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                   and s.sorlcur_program=ss.sorlcur_program
                                                                                                   and SORLCUR_ROLL_IND='Y'
                                                                                                   and ss.sorlcur_lmod_code='LEARNER')
                                                               and a.area_mjr=smrarul_area
                                                               and smrarul_area=SMRPAAP_area
                                                               and SMRPAAP_program=a.prog
                                                               AND SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB
--                                                               and SCRSYLN_TERM_CODE_EFF= a.per
                                                               and s.sorlcur_lmod_code='LEARNER'
                                                               and s.SORLCUR_PIDM    = SORLFOS_PIDM
                                                               and s.SORLCUR_SEQNO = SORLFOS_LCUR_SEQNO
                                                               and sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ss
                                                                                               where  s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                              and s.sorlcur_program=ss.sorlcur_program
                                                                                              and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
                                            UNION
                                                    select distinct b.*,SMRARUL_subj_code||SMRARUL_crse_numb_low mate,SCRSYLN_LONG_COURSE_TITLE NOMB_M,
                                                                                p.SORLFOS_LFST_CODE lfst
                                                               from sorlfos p, stvmajr, sorlcur s,SMRARUL q,SMRPAAP r,SCRSYLN,salida2 b
                                                               where  p.sorlfos_pidm=p_pidm
                                                               and p.SORLFOS_LFST_CODE='CONCENTRATION'
                                                               and b.area_cc=q.smrarul_area
                                                               and q.smrarul_area=r.SMRPAAP_area
                                                               and r.SMRPAAP_program=b.prog
                                                               AND q.SMRARUL_SUBJ_CODE||q.SMRARUL_CRSE_NUMB_LOW=SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB
                                                               and b.per=s.SORLCUR_TERM_CODE_CTLG
--                                                               and SCRSYLN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG) from sorlcur where  sorlcur_pidm=p_pidm
--                                                                                                                            and SORLCUR_LMOD_CODE='LEARNER')
                                                               and s.sorlcur_lmod_code='LEARNER'
                                                               and s.SORLCUR_PIDM    = p.SORLFOS_PIDM
                                                               and s.SORLCUR_ROLL_IND='Y'
                                                               and s.SORLCUR_SEQNO = p.SORLFOS_LCUR_SEQNO
                                                               and s.sorlcur_seqno in (select max(ss.sorlcur_seqno) from sorlcur ss
                                                                                                   where  s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                   and s.sorlcur_program=ss.sorlcur_program
                                                                                                   and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
                                                                and (b.majr_cc,s.sorlcur_seqno)  not in (select q.SORLFOS_MAJR_CODE,s.sorlcur_seqno from sorlfos q
                                                                                                 where  b.majr_cc=q.SORLFOS_MAJR_CODE
                                                                                                       and q.SORLFOS_pidm=p_pidm
                                                                                                       and s.sorlcur_seqno=q.SORLFOS_LCUR_SEQNO)
--                                                                and b.per=SCRSYLN_TERM_CODE_EFF
                                                               order by 4,7,5;

                        RETURN (elige_out);

            END f_dashboard_matelegir_out;

FUNCTION f_act_area(p_pidm in number,p_mcode_o in varchar2,p_mcod_r in varchar2, p_seqno in number, p_code in varchar2,p_user varchar2,  p_prog varchar2 ) RETURN varchar2
is
    l_error        NUMBER;
    l_existe       NUMBER;
    l_contar       Number;
    l_errores      number;
    l_text         VARCHAR2(500);
    texto          VARCHAR2(500);
    p_cat          VARCHAR2(6);
    id_a           varchar(9);
    carr           varchar(12);
    n_rule         Number;
    n_rulec        Number;


 BEGIN

   l_contar:=0;
   l_existe:=0;
   l_errores:=0;
   id_a:=0;
   carr:=NULL;

                   SELECT COUNT(*)  INTO l_contar
                    FROM  spriden
                    WHERE spriden_change_ind IS NULL
                    AND spriden_pidm =p_pidm;

         IF l_contar = 1 THEN

            BEGIN

               SELECT COUNT(*)  into l_existe
                 from SZTBMAS
                 where  SZTBMAS_pidm=p_pidm
                 AND SZTBMAS_FST_CODE=p_code;

            if p_user is NULL then    --- cuando el cambio lo hace el alumno

                IF l_existe=0 and p_code='MAJOR' then
                     begin
                          n_rule:=0;
                          l_errores:=0;
                          select distinct spriden_id into id_a from spriden
                             where spriden_pidm=p_pidm;

                          BEGIN
                            select SORCMJR_CMJR_RULE,SORCMJR_TERM_CODE_EFF into n_rule,p_cat  from SORCMJR    -- LOS DATOS DE MAJOR DE CAMBIO
                             where SORCMJR_MAJR_CODE=p_mcod_r    -- EL MAJOR A CAMBIAR
                               and SORCMJR_CURR_RULE in (select SOBCURR_CURR_RULE from sobcurr
                                                            where SOBCURR_PROGRAM=p_prog
                                                              and SOBCURR_CAMP_CODE=(SELECT SORLCUR_CAMP_CODE
                                                                                       FROM SORLCUR
                                                                                      WHERE sorlcur_pidm =p_pidm
                                                                                        AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                        AND SORLCUR_ROLL_IND     = 'Y'
                                                                                        AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                        AND SORLCUR_PROGRAM=p_prog)
                                                          )
                                  AND SORCMJR_TERM_CODE_EFF = (SELECT MAX (SORLCUR_TERM_CODE_CTLG)
                                                                 FROM SORLCUR
                                                                WHERE  sorlcur_pidm =p_pidm
                                                                  AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                  AND SORLCUR_ROLL_IND     = 'Y'
                                                                  AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                  AND SORLCUR_PROGRAM=p_prog);
                          EXCEPTION  WHEN OTHERS THEN
                            return ('Fallo al extraer regla de curso area Mayor 1');
                          END;


                          begin
                              update SORLFOS  SET  SORLFOS_TERM_CODE_CTLG=p_cat        --   new  actualizara  PER-CATALOGO de todos los MAJORS
                               where SORLFOS_PIDM=p_pidm
                                 and SORLFOS_LFST_CODE=p_code
                                 and SORLFOS_MAJR_CODE=p_mcode_o
                                 and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                               where sorlcur_pidm=p_pidm
                                                                 and sorlcur_program=p_prog);
                          EXCEPTION  WHEN OTHERS THEN
                             l_errores:=1;
                             return ('Fallo al actualizar periodo catalogo de sorlfos 1');
                          end;

                          begin
                             update SORLFOS  SET  SORLFOS_MAJR_CODE=p_mcod_r, SORLFOS_LFOS_RULE=n_rule
                              where SORLFOS_PIDM=p_pidm
                                and SORLFOS_LFST_CODE=p_code
                                and SORLFOS_MAJR_CODE=p_mcode_o
                                and SORLFOS_TERM_CODE_CTLG=p_cat
                                and SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                             where sorlcur_pidm=p_pidm
                                                               and sorlcur_program=p_prog);
                          EXCEPTION  WHEN OTHERS THEN
                            l_errores:=1;
                            return ('Fallo al actualizar periodo majr y numero de regla sorlfos 1');
                          end;

                          begin
                             update SGBSTDN SET SGBSTDN_MAJR_CODE_1=p_mcod_r,SGBSTDN_CMJR_RULE_1_1=n_rule
                              where SGBSTDN_pidm=p_pidm
                                and SGBSTDN_MAJR_CODE_1=p_mcode_o
                                and SGBSTDN_LEVL_CODE='LI'
                                and SGBSTDN_PROGRAM_1=p_prog
                                and SGBSTDN_TERM_CODE_CTLG_1=p_cat;
                          EXCEPTION  WHEN OTHERS THEN
                            l_errores:=1;
                            return ('Fallo al actualizar major y numero de regla 1_1 SGASTDN 1');
                          end;

                          begin
                             update SORLFOS  SET  SORLFOS_TERM_CODE_CTLG=p_cat                --new  actualizara  PER-CATALOGO de todos CONCENTRATION
                              where SORLFOS_PIDM=p_pidm
                                and SORLFOS_LFST_CODE='CONCENTRATION'
                                and SORLFOS_MAJR_CODE_ATTACH=p_mcode_o
                                and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                              where sorlcur_pidm=p_pidm
                                                                and sorlcur_program=p_prog);
                          EXCEPTION  WHEN OTHERS THEN
                            l_errores:=1;
                            return ('Fallo al actualizar periodo catalogo MAJR en sorlfos CONCENTRATION 1');
                          end;

                          begin
                            update SORLFOS  SET  SORLFOS_MAJR_CODE_ATTACH=p_mcod_r, SORLFOS_CONC_ATTACH_RULE=n_rule
                             where SORLFOS_PIDM=p_pidm
                               and SORLFOS_LFST_CODE='CONCENTRATION'
                               and SORLFOS_MAJR_CODE_ATTACH=p_mcode_o
                               and SORLFOS_TERM_CODE_CTLG=p_cat
                               and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                             where sorlcur_pidm=p_pidm
                                                               and sorlcur_program=p_prog);
                          EXCEPTION  WHEN OTHERS THEN
                            l_errores:=1;
                            return ('Fallo al actualizar MAJR  y regla en sorlfos CONCENTRATION 1');
                          end;

                         if l_errores=0 then

                           Insert into SGRSCMT
                              Values (
                                      p_pidm,
                                      p_seqno,
                                      (select max(SORLCUR_TERM_CODE)  from sorlcur
                                             where sorlcur_pidm=p_pidm
                                               AND SORLCUR_LMOD_CODE = 'LEARNER'
                                               AND SORLCUR_ROLL_IND     = 'Y'
                                               AND SORLCUR_CACT_CODE = 'ACTIVE'
                                               AND SORLCUR_PROGRAM  =p_prog
                                        ),
                                        ('Cambio Area Major SIU por alumno de '||p_mcode_o||'  a: '||p_mcod_r),
                                        TO_DATE(sysdate),
                                        NULL,
                                        0,
                                        NULL,
                                        'SIU',
                                        NULL);

                                   insert into SZTBMAS values  (
                                       p_pidm,
                                       id_a,
                                       p_mcode_o,
                                       p_mcod_r,
                                       p_seqno,
                                       p_code,
                                       p_prog,
                                       sysdate
                                       );
                             return ('EXITO');
                         end if;


                     EXCEPTION
                         WHEN OTHERS THEN
                         l_error := SQLCODE;
                         l_text  := SQLERRM;
                         return ('Fallo al actualizar el area MAYOR, opcion alumno');
                      end;
                  end IF;

                 IF l_existe<=1  and p_code='CONCENTRATION' then
                     begin
                                      n_rulec:=0;
                                      l_errores:=0;
                                      select distinct spriden_id into id_a from spriden
                                                         where spriden_pidm=p_pidm;


                                    BEGIN
                                     select  SORCCON_CCON_RULE,SORCCON_TERM_CODE_EFF into n_rulec, p_cat  from SORCCON
                                       where SORCCON_MAJR_CODE_CONC=p_mcod_r
                                       and   SORCCON_CURR_RULE in (select SOBCURR_CURR_RULE from sobcurr
                                                                    where SOBCURR_PROGRAM=p_prog
                                                                      and SOBCURR_CAMP_CODE=(SELECT SORLCUR_CAMP_CODE
                                                                                               FROM SORLCUR
                                                                                              WHERE sorlcur_pidm =p_pidm
                                                                                                AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                AND SORLCUR_ROLL_IND  = 'Y'
                                                                                                AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                                AND SORLCUR_PROGRAM=p_prog)
                                                          )
                                      AND SORCCON_TERM_CODE_EFF = (SELECT MAX (SORLCUR_TERM_CODE_CTLG)
                                                                     FROM SORLCUR
                                                                    WHERE sorlcur_pidm =p_pidm
                                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                      AND SORLCUR_ROLL_IND     = 'Y'
                                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                      AND SORLCUR_PROGRAM=p_prog);
                                    EXCEPTION  WHEN OTHERS THEN
                                        return ('Fallo al extraer regla de curso area de CONCENTRATION 1');
                                     END;

                                    begin
                                       update SORLFOS  SET  SORLFOS_TERM_CODE_CTLG=p_cat     --new  actualizara  PER-CATALOGO de todos CONCENTRATION
                                                 where SORLFOS_PIDM=p_pidm
                                                     and SORLFOS_LFST_CODE=p_code
                                                     and SORLFOS_MAJR_CODE=p_mcode_o
                                                     and SORLFOS_TERM_CODE_CTLG=p_cat
                                                     and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                                                   where sorlcur_pidm=p_pidm
                                                                                     and sorlcur_program=p_prog);
                                    EXCEPTION  WHEN OTHERS THEN
                                      l_errores:=1;
                                      return ('Fallo al actualizar periodo catalogo sorlfos CONCENTRATION 1');
                                    end;

                                    begin
                                         update SORLFOS  SET  SORLFOS_MAJR_CODE=p_mcod_r,SORLFOS_LFOS_RULE=n_rulec
                                                 where SORLFOS_PIDM=p_pidm
                                                   and SORLFOS_LFST_CODE=p_code
                                                   and SORLFOS_MAJR_CODE=p_mcode_o
                                                   and SORLFOS_TERM_CODE_CTLG=p_cat
                                                   and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                                                 where sorlcur_pidm=p_pidm
                                                                                   and sorlcur_program=p_prog);
                                    EXCEPTION  WHEN OTHERS THEN
                                     l_errores:=1;
                                     return ('Fallo al actualizar MAJR_CODE y regla en sorlfos CONCENTRATION 1');
                                    end;
                                          --------------------------
                                   if p_seqno=2 then
                                    begin
                                          update SGBSTDN SET SGBSTDN_MAJR_CODE_CONC_1=p_mcod_r,SGBSTDN_CCON_RULE_11_1=n_rulec
                                              where SGBSTDN_pidm=p_pidm
                                                and SGBSTDN_MAJR_CODE_CONC_1=p_mcode_o     --primer campo
                                                and SGBSTDN_LEVL_CODE='LI'
                                                and SGBSTDN_PROGRAM_1=p_prog
                                                and SGBSTDN_TERM_CODE_CTLG_1=p_cat;
                                    EXCEPTION  WHEN OTHERS THEN
                                       l_errores:=1;
                                       return ('Fallo al actualizar majr y numero de regla 1_1 SGASTDN 2');
                                    end;
                                   end if;
                                          --------------------------
                                   if p_seqno=3 then
                                     begin
                                          update SGBSTDN SET SGBSTDN_MAJR_CODE_CONC_1_2=p_mcod_r,SGBSTDN_CCON_RULE_11_2=n_rulec
                                              where SGBSTDN_pidm=p_pidm
                                                   and SGBSTDN_MAJR_CODE_CONC_1_2=p_mcode_o    --- segundo campo
                                                   and SGBSTDN_LEVL_CODE='LI'
                                                   and SGBSTDN_PROGRAM_1=p_prog
                                                   and SGBSTDN_TERM_CODE_CTLG_1=p_cat;
                                     EXCEPTION  WHEN OTHERS THEN
                                        l_errores:=1;
                                        return ('Fallo al actualizar majr y numero de regla 11_2 SGASTDN 2');
                                     end;
                                   end if;

                                  if l_errores=0 then

                                    Insert into SGRSCMT
                                      Values  (
                                         p_pidm,
                                         p_seqno,
                                         (select max(SORLCUR_TERM_CODE)  from sorlcur
                                             where sorlcur_pidm=p_pidm
                                               AND SORLCUR_LMOD_CODE = 'LEARNER'
                                               AND SORLCUR_ROLL_IND     = 'Y'
                                               AND SORLCUR_CACT_CODE = 'ACTIVE'
                                               AND SORLCUR_PROGRAM  =p_prog
                                         ),
                                        ('Cambio Area Minor SIU por alumno de '||p_mcode_o||'  a: '||p_mcod_r),
                                        TO_DATE(sysdate),
                                        NULL,
                                        0,
                                        NULL,
                                        'SIU',
                                        NULL
                                        );

                                     insert into SZTBMAS  values  (
                                            p_pidm,
                                            id_a,
                                            p_mcode_o,
                                            p_mcod_r,
                                            p_seqno,
                                            p_code,
                                            p_prog,
                                            sysdate
                                            );
                                    return ('EXITO');
                                   end if;

                       EXCEPTION
                         WHEN OTHERS THEN
                         l_error := SQLCODE;
                         l_text  := SQLERRM;
                         return ('Fallo al actualizar el area de CONCENTRATION opcion alumno ');
                       end;
                  end IF;
            else       --- cuando el cambio lo hace usuario con privilegios   (escolares y/o funcional)
            ----------------------------------------------------
                  IF l_existe=0 and p_code='MAJOR' then
                      begin
                            n_rule:=0;
                            l_errores:=0;
                            select distinct spriden_id into id_a from spriden
                             where spriden_pidm=p_pidm;

                                BEGIN
                                  select  SORCMJR_CMJR_RULE,SORCMJR_TERM_CODE_EFF into n_rule,p_cat  from SORCMJR    -- LOS DATOS DE MAJOR DE CAMBIO
                                   where SORCMJR_MAJR_CODE= p_mcod_r    -- EL MAJOR A CAMBIAR
                                     and   SORCMJR_CURR_RULE in (select SOBCURR_CURR_RULE from sobcurr
                                                                  where SOBCURR_PROGRAM=p_prog
                                                                    and SOBCURR_CAMP_CODE=(SELECT SORLCUR_CAMP_CODE FROM SORLCUR
                                                                                            WHERE sorlcur_pidm =p_pidm
                                                                                              AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                              AND SORLCUR_ROLL_IND     = 'Y'
                                                                                              AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                              AND SORLCUR_PROGRAM=p_prog)
                                                                   )
                                      AND SORCMJR_TERM_CODE_EFF = (SELECT MAX (SORLCUR_TERM_CODE_CTLG)
                                                                     FROM SORLCUR
                                                                    WHERE sorlcur_pidm =p_pidm
                                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                      AND SORLCUR_ROLL_IND     = 'Y'
                                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                      AND SORLCUR_PROGRAM = p_prog);
                                EXCEPTION  WHEN OTHERS THEN
                                return ('Fallo al extraer regla de curso area Mayor 2');
                                END;


                                begin
                                   update SORLFOS  SET  SORLFOS_TERM_CODE_CTLG=p_cat                --new  actualizara  PER-CATALOGO de todos los MAJORS
                                      where SORLFOS_PIDM=p_pidm
                                         and SORLFOS_LFST_CODE=p_code
                                         and SORLFOS_MAJR_CODE=p_mcode_o
                                         and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                                       where sorlcur_pidm=p_pidm
                                                                         and sorlcur_program=p_prog);
                                EXCEPTION  WHEN OTHERS THEN
                                  l_errores:=1;
                                  return ('Fallo al actualizar periodo catalogo de sorlfos 2');
                                end;

                                begin
                                   update SORLFOS  SET  SORLFOS_MAJR_CODE=p_mcod_r, SORLFOS_LFOS_RULE=n_rule
                                      where SORLFOS_PIDM=p_pidm
                                         and SORLFOS_LFST_CODE=p_code
                                         and SORLFOS_MAJR_CODE=p_mcode_o
                                         and SORLFOS_TERM_CODE_CTLG=p_cat
                                         and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                                       where sorlcur_pidm=p_pidm
                                                                         and sorlcur_program=p_prog);
                                EXCEPTION  WHEN OTHERS THEN
                                 l_errores:=1;
                                 return ('Fallo al actualizar periodo majr y numero de regla sorlfos 2');
                                end;

                                begin
                                    update SGBSTDN SET SGBSTDN_MAJR_CODE_1=p_mcod_r,SGBSTDN_CMJR_RULE_1_1=n_rule
                                       where SGBSTDN_pidm=p_pidm
                                               and SGBSTDN_MAJR_CODE_1=p_mcode_o
                                               and SGBSTDN_LEVL_CODE='LI'
                                               and SGBSTDN_PROGRAM_1=p_prog
                                               and SGBSTDN_TERM_CODE_CTLG_1=p_cat;
                                EXCEPTION  WHEN OTHERS THEN
                                  l_errores:=1;
                                  return ('Fallo al actualizar majr y numero de regla 1_1 SGASTDN 2');
                                end;

                                begin
                                   update SORLFOS  SET  SORLFOS_TERM_CODE_CTLG=p_cat                --new  actualizara  PER-CATALOGO de todos CONCENTRATION
                                       where SORLFOS_PIDM=p_pidm
                                           and SORLFOS_LFST_CODE='CONCENTRATION'
                                           and SORLFOS_MAJR_CODE_ATTACH=p_mcode_o
                                           and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                                         where sorlcur_pidm=p_pidm
                                                                           and sorlcur_program=p_prog);
                                EXCEPTION  WHEN OTHERS THEN
                                 return ('Fallo al actualizar periodo catalogo MAJR en sorlfos CONCENTRATION 2');
                                end;

                                begin
                                   update SORLFOS  SET  SORLFOS_MAJR_CODE_ATTACH=p_mcod_r, SORLFOS_CONC_ATTACH_RULE=n_rule
                                       where SORLFOS_PIDM=p_pidm
                                           and SORLFOS_LFST_CODE='CONCENTRATION'
                                           and SORLFOS_MAJR_CODE_ATTACH=p_mcode_o
                                           and SORLFOS_TERM_CODE_CTLG=p_cat
                                           and  SORLFOS_LCUR_SEQNO in (select SORLCUR_SEQNO from  sorlcur
                                                                        where sorlcur_pidm=p_pidm
                                                                          and sorlcur_program=p_prog);
                                EXCEPTION  WHEN OTHERS THEN
                                 l_errores:=1;
                                 return ('Fallo al actualizar MAJR  y regla en sorlfos CONCENTRATION 2');
                                end;

                               if l_errores=0 then

                                  Insert into SGRSCMT
                                  Values (
                                      p_pidm,
                                      p_seqno,
                                      (select max(SORLCUR_TERM_CODE)  from sorlcur
                                             where sorlcur_pidm=p_pidm
                                               AND SORLCUR_LMOD_CODE = 'LEARNER'
                                               AND SORLCUR_ROLL_IND     = 'Y'
                                               AND SORLCUR_CACT_CODE = 'ACTIVE'
                                               AND SORLCUR_PROGRAM  =p_prog
                                        ),
                                        ('Cambio Area Major SIU por '||p_user ||' de '||p_mcode_o||'  a: '||p_mcod_r),
                                        TO_DATE(sysdate),
                                        NULL,
                                        0,
                                        NULL,
                                        'SIU',
                                        NULL);

                                     insert into SZTBMAS  values  (
                                            p_pidm,
                                            id_a,
                                            p_mcode_o,
                                            p_mcod_r,
                                            p_seqno,
                                            p_code,
                                            p_prog,
                                            sysdate
                                            );
                                return ('EXITO');
                              end if;


                      EXCEPTION
                         WHEN OTHERS THEN
                         l_error := SQLCODE;
                         l_text  := SQLERRM;
                         dBMS_OUTPUT.PUT_LINE('Error al actualizar area MAJOR ');
                         return ('Fallo al actualizar el area Mayor opcion escolares');
                       end;
                  end IF;

                 IF  l_existe<=1 and p_code='CONCENTRATION' then
                      begin
                                   n_rulec:=0;
                                   l_errores:=0;
                                   select distinct spriden_id into id_a from spriden
                                              where spriden_pidm=p_pidm;


                                   BEGIN
                                     select  SORCCON_CCON_RULE,SORCCON_TERM_CODE_EFF into n_rulec,p_cat
                                     from SORCCON
                                       where SORCCON_MAJR_CODE_CONC= p_mcod_r
                                       and   SORCCON_CURR_RULE in (select SOBCURR_CURR_RULE from sobcurr
                                                                    where SOBCURR_PROGRAM=p_prog
                                                                      and SOBCURR_CAMP_CODE=(SELECT SORLCUR_CAMP_CODE
                                                                                               FROM SORLCUR
                                                                                              WHERE sorlcur_pidm =p_pidm
                                                                                                AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                AND SORLCUR_ROLL_IND     = 'Y'
                                                                                                AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                                                AND SORLCUR_PROGRAM=p_prog)
                                                                    )
                                      AND SORCCON_TERM_CODE_EFF = (SELECT MAX (SORLCUR_TERM_CODE_CTLG)
                                                                     FROM SORLCUR
                                                                    WHERE sorlcur_pidm =p_pidm
                                                                      AND SORLCUR_LMOD_CODE = 'LEARNER'
                                                                      AND SORLCUR_ROLL_IND     = 'Y'
                                                                      AND SORLCUR_CACT_CODE = 'ACTIVE'
                                                                      AND SORLCUR_PROGRAM=p_prog);
                                   EXCEPTION  WHEN OTHERS THEN
                                     return ('Fallo al extraer regla de curso area CONCENTRATION 2');
                                   END;
                                    -----------------------------------

                                    begin
                                            update SORLFOS  SET  SORLFOS_TERM_CODE_CTLG=p_cat     --new  actualizara  PER-CATALOGO de todos CONCENTRATION
                                                 where SORLFOS_PIDM=p_pidm
                                                     and SORLFOS_LFST_CODE=p_code
                                                     and SORLFOS_MAJR_CODE=p_mcode_o
                                                     and SORLFOS_TERM_CODE_CTLG=p_cat
                                                     and  SORLFOS_LCUR_SEQNO in  (select SORLCUR_SEQNO from  sorlcur
                                                                                   where sorlcur_pidm=p_pidm
                                                                                     and sorlcur_program=p_prog);
                                    EXCEPTION  WHEN OTHERS THEN
                                     l_errores:=1;
                                     return ('Fallo al actualizar periodo catalogo sorlfos CONCENTRATION 2');
                                    end;

                                    begin
                                            update SORLFOS  SET  SORLFOS_MAJR_CODE=p_mcod_r,SORLFOS_LFOS_RULE=n_rulec
                                                 where SORLFOS_PIDM=p_pidm
                                                     and SORLFOS_LFST_CODE=p_code
                                                     and SORLFOS_MAJR_CODE=p_mcode_o
                                                     and SORLFOS_TERM_CODE_CTLG=p_cat
                                                     and  SORLFOS_LCUR_SEQNO in  (select  SORLCUR_SEQNO from  sorlcur
                                                                                   where sorlcur_pidm=p_pidm
                                                                                     and sorlcur_program=p_prog);
                                    EXCEPTION  WHEN OTHERS THEN
                                     l_errores:=1;
                                     return ('Fallo al actualizar MAJR_CODE y regla en sorlfos CONCENTRATION 2');
                                    end;

                                  if p_seqno=2 then
                                    begin
                                           update SGBSTDN SET SGBSTDN_MAJR_CODE_CONC_1=p_mcod_r,SGBSTDN_CCON_RULE_11_1=n_rulec
                                              where SGBSTDN_pidm=p_pidm
                                                   and SGBSTDN_MAJR_CODE_CONC_1=p_mcode_o     --primer campo
                                                   and SGBSTDN_LEVL_CODE='LI'
                                                   and SGBSTDN_PROGRAM_1=p_prog
                                                   and SGBSTDN_TERM_CODE_CTLG_1=p_cat;
                                    EXCEPTION  WHEN OTHERS THEN
                                     l_errores:=1;
                                     return ('Fallo al actualizar majr y numero de regla 1_1 SGASTDN 2');
                                    end;
                                  end if;

                                  if p_seqno=3 then
                                    begin
                                             update SGBSTDN SET SGBSTDN_MAJR_CODE_CONC_1_2=p_mcod_r,SGBSTDN_CCON_RULE_11_2=n_rulec
                                              where SGBSTDN_pidm=p_pidm
                                                   and SGBSTDN_MAJR_CODE_CONC_1_2=p_mcode_o    --- segundo campo
                                                   and SGBSTDN_LEVL_CODE='LI'
                                                   and SGBSTDN_PROGRAM_1=p_prog
                                                   and SGBSTDN_TERM_CODE_CTLG_1=p_cat;
                                    EXCEPTION  WHEN OTHERS THEN
                                     l_errores:=1;
                                     return ('Fallo al actualizar majr y numero de regla 11_2 SGASTDN 2');
                                    end;
                                  end if;

                                  if l_errores=0 then

                                    Insert into SGRSCMT
                                      Values  (
                                         p_pidm,
                                         p_seqno,
                                         (select max(SORLCUR_TERM_CODE)  from sorlcur
                                             where sorlcur_pidm=p_pidm
                                               AND SORLCUR_LMOD_CODE = 'LEARNER'
                                               AND SORLCUR_ROLL_IND     = 'Y'
                                               AND SORLCUR_CACT_CODE = 'ACTIVE'
                                               AND SORLCUR_PROGRAM  =p_prog
                                         ),
                                        ('Cambio Area Minor SIU por '||p_user ||' de '||p_mcode_o||'  a: '||p_mcod_r),
                                        TO_DATE(sysdate),
                                        NULL,
                                        0,
                                        NULL,
                                        'SIU',
                                        NULL
                                        );

                                         insert into SZTBMAS  values  (
                                            p_pidm,
                                            id_a,
                                            p_mcode_o,
                                            p_mcod_r,
                                            p_seqno,
                                            p_code,
                                            p_prog,
                                            sysdate
                                            );
                                      return ('EXITO');
                                   end if;

                      EXCEPTION
                         WHEN OTHERS THEN
                         l_error := SQLCODE;
                         l_text  := SQLERRM;
                         dBMS_OUTPUT.PUT_LINE('Error al actualizar area CONCENTRATION ');
                         return ('Fallo al actualizar CONCENTRATION user escolares ');
                      end;
                  end IF;
              end IF;
           END;
        COMMIT;
     END IF;

  END f_act_area;

FUNCTION f_avance_individual (p_pidm in number,p_prog in varchar2) RETURN varchar2

as
        p_avance number:=0;

    Begin

        Begin
            select  SZTHITA_AVANCE
                Into p_avance
             from SZTHITA
            where  SZTHITA_PIDM = p_pidm
              and  SZTHITA_PROG = p_prog;

        Exception
         When Others then
           p_avance :=0;

        End;

        if p_avance is NULL then
         p_avance :=0;
        end if;

        RETURN(p_avance);
    Exception
        when Others then
           p_avance :=0;
           RETURN(p_avance);
    End f_avance_individual;


   FUNCTION f_bita_cambios_area(p_pidm in number,p_prog in varchar2) RETURN PKG_DASHBOARD_DOCENTES.bita_cambios_area_out
           AS
                b_cambios PKG_DASHBOARD_DOCENTES.bita_cambios_area_out;

            BEGIN
                open b_cambios
                   FOR
                        with CAMBIO as (
                                                      select DISTINCT SZTBMAS_ID ID_ALU,
                                                                          SZTBMAS_PIDM PIDM,
                                                                          SZTBMAS_LCUR_SEQNO SEC,
                                                                          SZTBMAS_FST_CODE CODE,
                                                                          SZTBMAS_PROGRAM_ALU CARR,
                                                                          SZTBMAS_MJR_C_ANT ANTE_A,
                                                                          SZTBMAS_MJR_C_NEW NEW_A,
                                                                          SZTBMAS_FECHA_CAMBIO FECHA_C
                                                      from SZTBMAS
                                                )
                                             select distinct ca.* from CAMBIO ca
                                                       where ca.PIDM=p_pidm
                                                       AND ca.CARR=p_prog;

                     RETURN (b_cambios);

            END f_bita_cambios_area;


 Procedure p_carga_alu_porc_ss(p_prog varchar2)
  AS
  existe number:=0;

    cursor p_ss(p_prog varchar2) is
                           with  avances1 as (
                                                     select DISTINCT SMRPAAP_PROGRAM PROG,
                                                                              SMRPAAP_AREA AREA,
                                                                              SMRPAAP_AREA_PRIORITY PRIO,
                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
                                                                              SHRTCKG_GRDE_CODE_FINAL  CAL_HIST,
                                                                              SSBSECT_TERM_CODE TCR_CODE,
                                                                              C.SORLCUR_pidm pidm
                                                               from SMRPAAP,SMRARUL, SORLCUR C, SSBSECT, SHRGRDE,SHRTCKN,SHRTCKG,SMBAGEN
                                                              where SMRPAAP_PROGRAM=p_prog
                                                              and SMRPAAP_TERM_CODE_EFF=SMRARUL_TERM_CODE_EFF
                                                              and smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                                              and SMBAGEN_ACTIVE_IND='Y'
                                                              and SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                                              and SMRPAAP_AREA=SMRARUL_AREA
                                                              and SMRARUL_AREA NOT IN  ('UTLMTI0101','UTLLTE0101','UTLLTI0101',/*'UTLLTS0101', 'UTLLTT0110',*/'UOCATN0101','UTSMTI0101','UNAMPT0111','UVEBTB0101','UTLTSS0110')
                                                              and SMRARUL_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF
                                                              and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                                              and SMRPAAP_PROGRAM=c.SORLCUR_PROGRAM
                                                              and c.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)
                                                                                                                             FROM SORLCUR c1x
                                                                                                         WHERE  c1x.sorlcur_pidm = c.sorlcur_pidm
                                                                                                               and c1x.SORLCUR_LMOD_CODE = c.SORLCUR_LMOD_CODE
                                                                                                               and c1x.SORLCUR_ROLL_IND     = c.SORLCUR_ROLL_IND
                                                                                                               and c1x.SORLCUR_PROGRAM = c.SORLCUR_PROGRAM
                                                                                                               )
                                                              and C.SORLCUR_PROGRAM=SMRPAAP_PROGRAM
                                                              and C.SORLCUR_CACT_CODE NOT IN (select SS.SORLCUR_CACT_CODE  from SORLCUR  SS
                                                                                                            WHERE SS.SORLCUR_pidm=C.SORLCUR_pidm
                                                                                                               and SS.SORLCUR_CACT_CODE='CHANGE'
                                                                                                               and SS.SORLCUR_LMOD_CODE = c.SORLCUR_LMOD_CODE
                                                                                                               and SS.SORLCUR_ROLL_IND     = c.SORLCUR_ROLL_IND
                                                                                                               and SS.SORLCUR_PROGRAM = c.SORLCUR_PROGRAM)
                                                              and SHRTCKN_pidm = c.sorlcur_pidm
                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct min(SORLCUR_TERM_CODE_CTLG) from sorlcur ii where
                                                                                                                             ii.sorlcur_pidm= c.SORLCUR_PIDM
                                                                                                                            and ii.SORLCUR_LMOD_CODE=c.sorlcur_lmod_code
                                                                                                                            and ii.sorlcur_seqno=c.sorlcur_seqno)
                                                              and SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB
--                                                              and SHRTCKN_pidm =6898
                                                              and SHRTCKN_pidm = SHRTCKG_PIDM
                                                              and SSBSECT_CRN=SHRTCKN_CRN
                                                              and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                                           and shrtckn_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                              and SHRTCKN_TERM_CODE = SHRTCKG_TERM_CODE
                                                              and SHRTCKN_SEQ_NO = SHRTCKG_TCKN_SEQ_NO
                                                              and SHRTCKN_TERM_CODE=SSBSECT_TERM_CODE
                                                              and SHRTCKG_GRDE_CODE_FINAL =  SHRGRDE_CODE
                                                              and c.SORLCUR_LEVL_CODE = SHRGRDE_LEVL_CODE
                                                              and SHRGRDE_PASSED_IND = 'Y'
                                                    ),
                                avances2 as (
                                                      select DISTINCT SMRPAAP_PROGRAM PROG,
                                                                              SMRPAAP_AREA AREA,
                                                                              SMRALIB_AREA_DESC DES,
                                                                              SMRPAAP_AREA_PRIORITY PRIO,
                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
                                                                              SHRTRCE_GRDE_CODE  CAL_HIST,
                                                                              d.SORLCUR_pidm pidm
                                                               from SMRPAAP,SMRALIB,SMRARUL,SORLCUR d,SHRGRDE,SHRTRCE,SHRTRCR,SMBAGEN
                                                              where SMRPAAP_PROGRAM=p_prog
                                                              and SMRPAAP_AREA=SMRALIB_AREA
                                                              and SMRPAAP_AREA=SMRARUL_AREA
                                                              and smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                                              and SMBAGEN_ACTIVE_IND='Y'
                                                              and SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                                              and SMRARUL_AREA NOT IN  ('UTLMTI0101','UTLLTE0101','UTLLTI0101','UTLLTS0101','UTLLTT0110','UOCATN0101','UTSMTI0101','UNAMPT0111','UVEBTB0101','UTLTSS0110')
                                                              and d.SORLCUR_LMOD_CODE = 'LEARNER'
                                                              and SMRPAAP_PROGRAM=SORLCUR_PROGRAM
                                                              and  ((smrarul_area not in (select smriecc_area from smriecc)) or (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=p_prog)) )
                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct min(SORLCUR_TERM_CODE_CTLG) from sorlcur jj where
                                                                                                                             jj.sorlcur_pidm= d.SORLCUR_PIDM
                                                                                                                            and jj.SORLCUR_LMOD_CODE=d.sorlcur_lmod_code
                                                                                                                            and jj.sorlcur_seqno=d.sorlcur_seqno)
                                                              and d.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)
                                                                                                          FROM SORLCUR c1x
                                                                                                         WHERE  c1x.sorlcur_pidm = d.sorlcur_pidm
                                                                                                               and c1x.SORLCUR_LMOD_CODE = d.SORLCUR_LMOD_CODE
                                                                                                               and c1x.SORLCUR_ROLL_IND     = d.SORLCUR_ROLL_IND
                                                                                                               and c1x.SORLCUR_PROGRAM = d.SORLCUR_PROGRAM)
--                                                              and SHRTRCE_pidm =6898
                                                              and SHRTRCE_pidm = d.sorlcur_pidm
                                                              and d.SORLCUR_PROGRAM=SMRPAAP_PROGRAM
                                                              and D.SORLCUR_CACT_CODE NOT IN (select SS.SORLCUR_CACT_CODE  from SORLCUR  SS
                                                                                                            WHERE SS.SORLCUR_pidm=D.SORLCUR_pidm
                                                                                                               and SS.SORLCUR_CACT_CODE='CHANGE'
                                                                                                               and SS.SORLCUR_LMOD_CODE = D.SORLCUR_LMOD_CODE
                                                                                                               and SS.SORLCUR_ROLL_IND     = D.SORLCUR_ROLL_IND
                                                                                                               and SS.SORLCUR_PROGRAM = D.SORLCUR_PROGRAM)
                                                              and SHRTRCE_pidm = d.sorlcur_pidm
                                                              and SHRTRCE_TERM_CODE_EFF = SHRTRCR_TERM_CODE
                                                              and SHRTRCE_pidm = SHRTRCR_PIDM
                                                              and SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB
                                                              and SHRTRCE_GRDE_CODE =  SHRGRDE_CODE
                                                              and SHRTRCE_LEVL_CODE = SHRGRDE_LEVL_CODE
                                                              and SHRGRDE_PASSED_IND = 'Y'
                                                              and SHRTRCE_TRCR_SEQ_NO=SHRTRCR_SEQ_NO
                                             ),
                     aproba1 as (
                                     select avances1.pidm,  count(*) aprobadas1 from avances1
                                     group by  avances1.pidm
                                      ),
                      aproba2 as (
                                         select avances2.pidm, count(*) aprobadas2 from avances2
                                          group by  avances2.pidm
                                        ),
                      aprobadas as (
                                             select aproba1.pidm pidm1,aproba2.pidm pidm2,
                                                      nvl(aproba1.aprobadas1,0)+nvl(aproba2.aprobadas2,0) tot_aprob
                                             from aproba1,aproba2
                                             where  aproba1.pidm=aproba2.pidm(+)
                                           )
                       select pidm,
                                   prog,
                                   p_avance,
                                   mat_aprob,
                                   tot_matxprog
                            from
                            (
                                select  distinct aprobadas.pidm1 pidm, p_prog  prog,
                                     case when
                                           (nvl(tot_aprob,0)*100/nvl((SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                                                                               WHERE SMBPGEN_PROGRAM=p_prog
                                                                                                  and SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
                                                                                                                              from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
                                                                                                                               and ee.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                               and ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
                                                                                                                                                                               WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
                                                                                                                                                                                   and c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
                                                                                                                                                                                   and c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
                                                                                                                                                                                   and c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
                                                                                                                                )),1))>100 then 100
                                     else
                                          (nvl(tot_aprob,0)*100/nvl((SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                                                                               WHERE SMBPGEN_PROGRAM=p_prog
                                                                                                  and SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
                                                                                                                              from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
                                                                                                                               and ee.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                               and ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
                                                                                                                                                                               WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
                                                                                                                                                                                   and c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
                                                                                                                                                                                   and c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
                                                                                                                                                                                   and c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
                                                                                                                                )),1))
                                      end  p_avance,
                                       aprobadas.tot_aprob  mat_aprob,
                                       (SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                                    WHERE SMBPGEN_PROGRAM=p_prog
                                                       and SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
                                                                                                            from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
                                                                                                                                    and ee.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
                                                                                                                                                                                        WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
                                                                                                                                                                                             and c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
                                                                                                                                                                                             and c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
                                                                                                                                                                                             and c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
                                                                                                          )
                                        )  tot_matxprog
                                      from aprobadas
                            );
--                    with  avances1 as (
--                                                     select DISTINCT SMRPAAP_PROGRAM PROG,
--                                                                              SMRPAAP_AREA AREA,
--                                                                              SMRPAAP_AREA_PRIORITY PRIO,
--                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
--                                                                              SHRTCKG_GRDE_CODE_FINAL  CAL_HIST,
--                                                                              SSBSECT_TERM_CODE TCR_CODE,
--                                                                              C.SORLCUR_pidm pidm
--                                                               from SMRPAAP,SMRARUL, SORLCUR C, SSBSECT, SHRGRDE,SHRTCKN,SHRTCKG
--                                                              where SMRPAAP_PROGRAM=p_prog
--                                                              and SMRPAAP_TERM_CODE_EFF=SMRARUL_TERM_CODE_EFF
--                                                              AND SMRPAAP_AREA=SMRARUL_AREA
--                                                              AND SMRARUL_AREA NOT IN  ('UTLMTI0101','UTLLTE0101','UTLLTI0101',/*'UTLLTS0101', 'UTLLTT0110',*/'UOCATN0101','UTSMTI0101','UNAMPT0111','UVEBTB0101','UTLTSS0110')
--                                                              and SMRARUL_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF
--                                                              AND c.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                              and SMRPAAP_PROGRAM=c.SORLCUR_PROGRAM
--                                                              AND c.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)
--                                                                                                                             FROM SORLCUR c1x
--                                                                                                         WHERE  c1x.sorlcur_pidm = c.sorlcur_pidm
--                                                                                                               AND c1x.SORLCUR_LMOD_CODE = c.SORLCUR_LMOD_CODE
--                                                                                                               AND c1x.SORLCUR_ROLL_IND     = c.SORLCUR_ROLL_IND
--                                                                                                               and c1x.SORLCUR_PROGRAM = c.SORLCUR_PROGRAM
--                                                                                                               )
--                                                              AND C.SORLCUR_PROGRAM=SMRPAAP_PROGRAM
--                                                              AND C.SORLCUR_CACT_CODE NOT IN (select SS.SORLCUR_CACT_CODE  from SORLCUR  SS
--                                                                                                            WHERE SS.SORLCUR_pidm=C.SORLCUR_pidm
--                                                                                                            AND SS.SORLCUR_CACT_CODE='CHANGE'
--                                                                                                               AND SS.SORLCUR_LMOD_CODE = c.SORLCUR_LMOD_CODE
--                                                                                                               AND SS.SORLCUR_ROLL_IND     = c.SORLCUR_ROLL_IND
--                                                                                                               and SS.SORLCUR_PROGRAM = c.SORLCUR_PROGRAM)
--                                                              AND SHRTCKN_pidm = c.sorlcur_pidm
--                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct min(SORLCUR_TERM_CODE_CTLG) from sorlcur ii where
--                                                                                                                             ii.sorlcur_pidm= c.SORLCUR_PIDM
--                                                                                                                            and ii.SORLCUR_LMOD_CODE=c.sorlcur_lmod_code
--                                                                                                                            and ii.sorlcur_seqno=c.sorlcur_seqno)
--                                                              AND SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB
--                                                              AND SHRTCKN_pidm = SHRTCKG_PIDM
--                                                              AND SSBSECT_CRN=SHRTCKN_CRN
--                                                              AND SHRTCKN_TERM_CODE = SHRTCKG_TERM_CODE
--                                                              AND SHRTCKN_SEQ_NO = SHRTCKG_TCKN_SEQ_NO
--                                                              AND SHRTCKN_TERM_CODE=SSBSECT_TERM_CODE
--                                                              AND SHRTCKG_GRDE_CODE_FINAL =  SHRGRDE_CODE
--                                                              AND c.SORLCUR_LEVL_CODE = SHRGRDE_LEVL_CODE
--                                                              AND SHRGRDE_PASSED_IND = 'Y'
--                                                    ),
--                                avances2 as (
--                                                      select DISTINCT SMRPAAP_PROGRAM PROG,
--                                                                              SMRPAAP_AREA AREA,
--                                                                              SMRALIB_AREA_DESC DES,
--                                                                              SMRPAAP_AREA_PRIORITY PRIO,
--                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
--                                                                              SHRTRCE_GRDE_CODE  CAL_HIST,
--                                                                              d.SORLCUR_pidm pidm
--                                                               from SMRPAAP,SMRALIB,SMRARUL,SORLCUR d,SHRGRDE,SHRTRCE,SHRTRCR
--                                                              where SMRPAAP_PROGRAM=p_prog
--                                                              and SMRPAAP_AREA=SMRALIB_AREA
--                                                              AND SMRPAAP_AREA=SMRARUL_AREA
--                                                              AND SMRARUL_AREA NOT IN  ('UTLMTI0101','UTLLTE0101','UTLLTI0101','UTLLTS0101','UTLLTT0110','UOCATN0101','UTSMTI0101','UNAMPT0111','UVEBTB0101','UTLTSS0110')
--                                                              AND d.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                              and SMRPAAP_PROGRAM=SORLCUR_PROGRAM
--                                                              AND  ((smrarul_area not in (select smriecc_area from smriecc)) or (smrarul_area in (select smriemj_area from smriemj where smriemj_majr_code=p_prog)) )
--                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct min(SORLCUR_TERM_CODE_CTLG) from sorlcur jj where
--                                                                                                                             jj.sorlcur_pidm= d.SORLCUR_PIDM
--                                                                                                                            and jj.SORLCUR_LMOD_CODE=d.sorlcur_lmod_code
--                                                                                                                            and jj.sorlcur_seqno=d.sorlcur_seqno)
--                                                              AND d.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)
--                                                                                                          FROM SORLCUR c1x
--                                                                                                         WHERE  c1x.sorlcur_pidm = d.sorlcur_pidm
--                                                                                                               AND c1x.SORLCUR_LMOD_CODE = d.SORLCUR_LMOD_CODE
--                                                                                                               AND c1x.SORLCUR_ROLL_IND     = d.SORLCUR_ROLL_IND
--                                                                                                               and c1x.SORLCUR_PROGRAM = d.SORLCUR_PROGRAM)
--                                                              AND SHRTRCE_pidm = d.sorlcur_pidm
--                                                              AND d.SORLCUR_PROGRAM=SMRPAAP_PROGRAM
--                                                              AND D.SORLCUR_CACT_CODE NOT IN (select SS.SORLCUR_CACT_CODE  from SORLCUR  SS
--                                                                                                            WHERE SS.SORLCUR_pidm=D.SORLCUR_pidm
--                                                                                                            AND SS.SORLCUR_CACT_CODE='CHANGE'
--                                                                                                               AND SS.SORLCUR_LMOD_CODE = D.SORLCUR_LMOD_CODE
--                                                                                                               AND SS.SORLCUR_ROLL_IND     = D.SORLCUR_ROLL_IND
--                                                                                                               and SS.SORLCUR_PROGRAM = D.SORLCUR_PROGRAM)
--                                                              AND SHRTRCE_pidm = d.sorlcur_pidm
--                                                              AND SHRTRCE_TERM_CODE_EFF = SHRTRCR_TERM_CODE
--                                                              AND SHRTRCE_pidm = SHRTRCR_PIDM
--                                                              AND SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB
--                                                              AND SHRTRCE_GRDE_CODE =  SHRGRDE_CODE
--                                                              AND SHRTRCE_LEVL_CODE = SHRGRDE_LEVL_CODE
--                                                              AND SHRGRDE_PASSED_IND = 'Y'
--                                                              AND SHRTRCE_TRCR_SEQ_NO=SHRTRCR_SEQ_NO
--                                             ),
--                     aproba1 as (
--                                     select avances1.pidm,  count(*) aprobadas1 from avances1
--                                     group by  avances1.pidm
--                                      ),
--                      aproba2 as (
--                                         select avances2.pidm, count(*) aprobadas2 from avances2
--                                          group by  avances2.pidm
--                                        ),
--                      aprobadas as (
--                                             select aproba1.pidm pidm1,aproba2.pidm pidm2,
--                                                      nvl(aproba1.aprobadas1,0)+nvl(aproba2.aprobadas2,0) tot_aprob
--                                             from aproba1,aproba2
--                                             where  aproba1.pidm=aproba2.pidm(+)
--                                           )
--                       select pidm,
--                                   prog,
--                                   p_avance,
--                                   mat_aprob,
--                                   tot_matxprog
--                            from
--                            (
--                            select  distinct aprobadas.pidm1 pidm, p_prog  prog,
--                                       (nvl(tot_aprob,0)*100/nvl((SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
--                                                                                           WHERE SMBPGEN_PROGRAM=p_prog
--                                                                                              AND SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
--                                                                                                                          from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
--                                                                                                                           AND ee.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                                                                                           AND ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
--                                                                                                                                                                           WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
--                                                                                                                                                                               AND c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
--                                                                                                                                                                               AND c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
--                                                                                                                                                                               AND c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
--                                                                                                                            )),1))  p_avance,
--                                       aprobadas.tot_aprob  mat_aprob,
--                                       (SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
--                                                    WHERE SMBPGEN_PROGRAM=p_prog
--                                                       AND SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
--                                                                                                            from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
--                                                                                                                                    AND ee.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                                                                                                     AND ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
--                                                                                                                                                                                        WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
--                                                                                                                                                                                             AND c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
--                                                                                                                                                                                             AND c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
--                                                                                                                                                                                             AND c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
--                                                                                                          )
--                                        )  tot_matxprog
--                                      from aprobadas
--                            )
--                             where p_avance between 1 and 150;
       begin
                           for x in p_ss(p_prog) loop
                                      DBMS_OUTPUT.PUT_LINE('ENTRO  '||x.pidm||' * '||x.prog);
                                    select count(*) into existe from  SZTPOSS
                                     where  SZTPOSS_PIDM=x.pidm
                                     and SZTPOSS_PROGRAM=x.prog;

                                     if existe=1 then
                                              UPDATE SZTPOSS
                                              SET  SZTPOSS_FECHA=sysdate,
                                              SZTPOSS_P_AVANCE=x.p_avance,
                                              SZTPOSS_MAT_APROB=x.mat_aprob,
                                              SZTPOSS_TOT_MATXPROG=x.tot_matxprog
                                              where SZTPOSS_PIDM=x.pidm
                                               and SZTPOSS_PROGRAM=x.prog;
                                     else
                                       begin
                                            INSERT INTO SZTPOSS
                                              VALUES
                                                (x.pidm,
                                                 x.prog,
                                                 sysdate,
                                                 x.p_avance,
                                                 x.mat_aprob,
                                                 x.tot_matxprog,
                                                 'N',
                                                 'N',
                                                 'N',
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                  'N',
                                                 'N',
                                                 NULL);
                                       EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              DBMS_OUTPUT.PUT_LINE('Error al insertar alumno');
                                          end;
                                     end if;
                                    COMMIT;
                                     existe:=0;
                           end loop;
       end;

Procedure encuentra_candidatos_SS  is

cursor c1 is

SELECT DISTINCT SMBPGEN_PROGRAM prog
FROM SMRPRLE,SMBPGEN
WHERE SMRPRLE_LEVL_CODE in ('LI')
AND SMRPRLE_PROGRAM=SMBPGEN_PROGRAM
AND substr(SMRPRLE_PROGRAM,1,3)='UTL'
AND SMBPGEN_ACTIVE_IND='Y';
      begin
            for x in c1  loop
                PKG_DASHBOARD_DOCENTES.p_carga_alu_porc_ss(x.prog);
             end loop;
       end;

Procedure p_carga_alu_porc_MA(p_prog varchar2)
  AS
  existe number:=0;

    cursor p_ma(p_prog varchar2) is
                    with avances1 as (
                                                     select DISTINCT SMRPAAP_PROGRAM PROG,
                                                                              SMRPAAP_AREA AREA,
                                                                              SMRPAAP_AREA_PRIORITY PRIO,
                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
                                                                              SFRSTCR_GRDE_CODE CAL_INSC,
                                                                              SHRTCKG_GRDE_CODE_FINAL  CAL_HIST,
                                                                              SFRSTCR_TERM_CODE TCR_CODE,
                                                                              C.SORLCUR_pidm pidm
                                                               from SMRPAAP,SMRARUL, SORLCUR C,SFRSTCR, SSBSECT, SHRGRDE,SHRTCKN,SHRTCKG,SMBAGEN
                                                              where SMRPAAP_PROGRAM=p_prog
                                                              and SMRPAAP_TERM_CODE_EFF=SMRARUL_TERM_CODE_EFF
                                                              and smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                                              and SMBAGEN_ACTIVE_IND='Y'
                                                              and SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                                              and SMRPAAP_AREA=SMRARUL_AREA
                                                              and SMRARUL_AREA NOT IN  ('UTLMTI0101','UTLLTE0101','UTLLTI0101',/*'UTLLTS0101',*/'UTLLTT0110','UOCATN0101','UTSMTI0101','UNAMPT0111','UVEBTB0101','UTLTSS0110')
                                                              and SMRARUL_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF
--                                                              and c.sorlcur_pidm= 6898
                                                              and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                                              and SMRPAAP_PROGRAM=c.SORLCUR_PROGRAM
                                                              and  c.sorlcur_seqno in (select max(ss.sorlcur_seqno) from sorlcur ss
                                                                                                    where c.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                    and c.sorlcur_program=ss.sorlcur_program
                                                                                                    and c.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                    and c.SORLCUR_PROGRAM=ss.SORLCUR_PROGRAM)
                                                              and C.SORLCUR_CACT_CODE NOT IN (select SS.SORLCUR_CACT_CODE  from SORLCUR  SS
                                                                                                            WHERE SS.SORLCUR_pidm=C.SORLCUR_pidm
                                                                                                            and SS.SORLCUR_CACT_CODE='CHANGE'
                                                                                                               and SS.SORLCUR_LMOD_CODE = C.SORLCUR_LMOD_CODE
                                                                                                               and SS.SORLCUR_ROLL_IND   = C.SORLCUR_ROLL_IND
                                                                                                               and SS.SORLCUR_PROGRAM = C.SORLCUR_PROGRAM)
                                                             and SFRSTCR_PIDM = c.sorlcur_pidm
                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct min(SORLCUR_TERM_CODE_CTLG) from sorlcur ii where
                                                                                                                             ii.sorlcur_pidm= c.SORLCUR_PIDM
                                                                                                                            and ii.sorlcur_pidm=c.sorlcur_pidm
                                                                                                                            and ii.SORLCUR_LMOD_CODE=c.sorlcur_lmod_code
                                                                                                                            and ii.sorlcur_seqno=c.sorlcur_seqno)
                                                              and SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB
                                                              and SFRSTCR_TERM_CODE=SSBSECT_TERM_CODE
                                                              and SSBSECT_CRN=SFRSTCR_CRN
                                                              and SSBSECT_CRN=SHRTCKN_CRN
                                                              and SFRSTCR_PIDM = SHRTCKG_PIDM
                                                              and SHRTCKN_pidm = SHRTCKG_PIDM
                                                              and SHRTCKN_TERM_CODE = SHRTCKG_TERM_CODE
                                                              and SHRTCKN_SEQ_NO = SHRTCKG_TCKN_SEQ_NO
                                                              and SHRTCKN_TERM_CODE=SFRSTCR_TERM_CODE
                                                              and SHRTCKG_GRDE_CODE_FINAL =  SHRGRDE_CODE
                                                              and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                                                           and shrtckn_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                              and c.SORLCUR_LEVL_CODE = SHRGRDE_LEVL_CODE
                                                              and SHRGRDE_PASSED_IND = 'Y'
                                                              and SFRSTCR_GRDE_CODE=SHRTCKG_GRDE_CODE_FINAL
                                                    ),
                                avances2 as (
                                                      select DISTINCT SMRPAAP_PROGRAM PROG,
                                                                              SMRPAAP_AREA AREA,
                                                                              SMRALIB_AREA_DESC DES,
                                                                              SMRPAAP_AREA_PRIORITY PRIO,
                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
                                                                              d.SORLCUR_pidm pidm
                                                               from SMRPAAP,SMRALIB,SMRARUL,SORLCUR d,SHRTRCE,SHRTRCR,SHRGRDE,SMBAGEN
                                                              where SMRPAAP_PROGRAM=p_prog
                                                              and SMRPAAP_AREA=SMRALIB_AREA
                                                              and SMRPAAP_AREA=SMRARUL_AREA
                                                              and smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                                              and SMBAGEN_ACTIVE_IND='Y'
                                                              and SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                                              and SMRARUL_AREA NOT IN  ('UTLMTI0101','UTLLTE0101','UTLLTI0101','UTLLTS0101','UTLLTT0110','UOCATN0101','UTSMTI0101','UNAMPT0111','UVEBTB0101','UTLTSS0110')
--                                                              and d.sorlcur_pidm= 6898
                                                              and d.SORLCUR_LMOD_CODE = 'LEARNER'
                                                              and d.SORLCUR_PROGRAM=SMRPAAP_PROGRAM
                                                              and  ((smrarul_area not in (select smriecc_area from smriecc)) or (smrarul_area in (select smriemj_area from smriemj)) )
                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct MIN(SORLCUR_TERM_CODE_CTLG) from sorlcur jj where
                                                                                                                             jj.sorlcur_pidm= d.SORLCUR_PIDM
                                                                                                                            and jj.sorlcur_pidm=d.sorlcur_pidm
                                                                                                                            and jj.SORLCUR_LMOD_CODE=d.sorlcur_lmod_code
                                                                                                                            and jj.sorlcur_seqno=d.sorlcur_seqno)
                                                              and SHRTRCE_pidm = d.sorlcur_pidm
                                                              and SHRTRCE_pidm = SHRTRCR_PIDM
--                                                              and SHRTRCE_TERM_CODE_EFF = SHRTRCR_TERM_CODE
                                                              and SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB
                                                              and SHRTRCE_GRDE_CODE =  SHRGRDE_CODE
                                                              and SHRTRCE_LEVL_CODE = SHRGRDE_LEVL_CODE
                                                              and SHRGRDE_PASSED_IND = 'Y'
                                                              and SHRTRCE_TRCR_SEQ_NO=SHRTRCR_SEQ_NO
                                             ),
                      aproba1 as (
                                         select avances1.pidm,  count(*) aprobadas1 from avances1
                                         group by  avances1.pidm
                                      ),
                      aproba2 as (
                                         select avances2.pidm, count(*) aprobadas2 from avances2
                                         group by  avances2.pidm
                                        ),
                      aprobadas as (
                                             select aproba1.pidm pidm1,aproba2.pidm pidm2,
                                                      nvl(aproba1.aprobadas1,0)+nvl(aproba2.aprobadas2,0) tot_aprob
                                             from aproba1,aproba2
                                             where  aproba1.pidm=aproba2.pidm(+)
                                           )
                       select pidm,
                                   prog,
                                   p_avance,
                                   mat_aprob,
                                   tot_matxprog
                            from
                            (
                                select  distinct aprobadas.pidm1 pidm, p_prog  prog,
                                       case when
                                           (nvl(tot_aprob,0)*100/nvl((SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                                                                               WHERE SMBPGEN_PROGRAM=p_prog
                                                                                                  and SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
                                                                                                                              from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
                                                                                                                               and ee.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                               and ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
                                                                                                                                                                               WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
                                                                                                                                                                                   and c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
                                                                                                                                                                                   and c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
                                                                                                                                                                                   and c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
                                                                                                                                )),1))>100 then 100
                                       else
                                          (nvl(tot_aprob,0)*100/nvl((SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                                                                               WHERE SMBPGEN_PROGRAM=p_prog
                                                                                                  and SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
                                                                                                                              from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
                                                                                                                               and ee.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                               and ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
                                                                                                                                                                               WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
                                                                                                                                                                                   and c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
                                                                                                                                                                                   and c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
                                                                                                                                                                                   and c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
                                                                                                                                )),1))
                                       end  p_avance,
                                       aprobadas.tot_aprob  mat_aprob,
                                       (SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
                                                    WHERE SMBPGEN_PROGRAM=p_prog
                                                       and SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
                                                                                                            from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
                                                                                                             and ee.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                             and ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
                                                                                                                                                                WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
                                                                                                                                                                     and c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
                                                                                                                                                                     and c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
                                                                                                                                                                     and c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
                                                                                                          )
                                        )  tot_matxprog
                                      from aprobadas
                            );
--                    with avances1 as (
--                                                     select DISTINCT SMRPAAP_PROGRAM PROG,
--                                                                              SMRPAAP_AREA AREA,
--                                                                              SMRPAAP_AREA_PRIORITY PRIO,
--                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
--                                                                              SFRSTCR_GRDE_CODE CAL_INSC,
--                                                                              SHRTCKG_GRDE_CODE_FINAL  CAL_HIST,
--                                                                              SFRSTCR_TERM_CODE TCR_CODE,
--                                                                              C.SORLCUR_pidm pidm
--                                                               from SMRPAAP,SMRARUL, SORLCUR C,SFRSTCR, SSBSECT, SHRGRDE,SHRTCKN,SHRTCKG
--                                                              where SMRPAAP_PROGRAM=p_prog
--                                                              and SMRPAAP_TERM_CODE_EFF=SMRARUL_TERM_CODE_EFF
--                                                              AND SMRPAAP_AREA=SMRARUL_AREA
--                                                              AND SMRARUL_AREA NOT IN  ('UTLMTI0101','UTLLTE0101','UTLLTI0101',/*'UTLLTS0101',*/'UTLLTT0110','UOCATN0101','UTSMTI0101','UNAMPT0111','UVEBTB0101','UTLTSS0110')
--                                                              and SMRARUL_TERM_CODE_EFF=SMRPAAP_TERM_CODE_EFF
----                                                              AND c.sorlcur_pidm= 21
--                                                              AND c.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                              and SMRPAAP_PROGRAM=c.SORLCUR_PROGRAM
--                                                              and  c.sorlcur_seqno in (select max(ss.sorlcur_seqno) from sorlcur ss
--                                                                                                    where c.sorlcur_pidm=ss.sorlcur_pidm
--                                                                                                    and c.sorlcur_program=ss.sorlcur_program
--                                                                                                    and c.sorlcur_lmod_code=ss.sorlcur_lmod_code
--                                                                                                    and c.SORLCUR_PROGRAM=ss.SORLCUR_PROGRAM)
--                                                              AND C.SORLCUR_CACT_CODE NOT IN (select SS.SORLCUR_CACT_CODE  from SORLCUR  SS
--                                                                                                            WHERE SS.SORLCUR_pidm=C.SORLCUR_pidm
--                                                                                                            AND SS.SORLCUR_CACT_CODE='CHANGE'
--                                                                                                               AND SS.SORLCUR_LMOD_CODE = C.SORLCUR_LMOD_CODE
--                                                                                                               AND SS.SORLCUR_ROLL_IND   = C.SORLCUR_ROLL_IND
--                                                                                                               and SS.SORLCUR_PROGRAM = C.SORLCUR_PROGRAM)
--                                                             AND SFRSTCR_PIDM = c.sorlcur_pidm
--                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct min(SORLCUR_TERM_CODE_CTLG) from sorlcur ii where
--                                                                                                                             ii.sorlcur_pidm= c.SORLCUR_PIDM
--                                                                                                                            and ii.sorlcur_pidm=c.sorlcur_pidm
--                                                                                                                            and ii.SORLCUR_LMOD_CODE=c.sorlcur_lmod_code
--                                                                                                                            and ii.sorlcur_seqno=c.sorlcur_seqno)
--                                                              AND SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SSBSECT_SUBJ_CODE || SSBSECT_CRSE_NUMB
--                                                              AND SFRSTCR_TERM_CODE=SSBSECT_TERM_CODE
--                                                              AND SSBSECT_CRN=SFRSTCR_CRN
--                                                              AND SSBSECT_CRN=SHRTCKN_CRN
--                                                              AND SFRSTCR_PIDM = SHRTCKG_PIDM
--                                                              AND SHRTCKN_pidm = SHRTCKG_PIDM
--                                                              AND SHRTCKN_TERM_CODE = SHRTCKG_TERM_CODE
--                                                              AND SHRTCKN_SEQ_NO = SHRTCKG_TCKN_SEQ_NO
--                                                              AND SHRTCKN_TERM_CODE=SFRSTCR_TERM_CODE
--                                                              AND SHRTCKG_GRDE_CODE_FINAL =  SHRGRDE_CODE
--                                                              AND c.SORLCUR_LEVL_CODE = SHRGRDE_LEVL_CODE
--                                                              AND SHRGRDE_PASSED_IND = 'Y'
--                                                              and SFRSTCR_GRDE_CODE=SHRTCKG_GRDE_CODE_FINAL
--                                                    ),
--                                avances2 as (
--                                                      select DISTINCT SMRPAAP_PROGRAM PROG,
--                                                                              SMRPAAP_AREA AREA,
--                                                                              SMRALIB_AREA_DESC DES,
--                                                                              SMRPAAP_AREA_PRIORITY PRIO,
--                                                                              SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW MATERIA,
----                                                                              SHRTRCE_GRDE_CODE  CAL_HIST,
--                                                                              d.SORLCUR_pidm pidm
--                                                               from SMRPAAP,SMRALIB,SMRARUL,SORLCUR d,SHRTRCE,SHRTRCR,SHRGRDE
--                                                              where SMRPAAP_PROGRAM=p_prog
--                                                              and SMRPAAP_AREA=SMRALIB_AREA
--                                                              AND SMRPAAP_AREA=SMRARUL_AREA
--                                                              AND SMRARUL_AREA NOT IN  ('UTLMTI0101','UTLLTE0101','UTLLTI0101','UTLLTS0101','UTLLTT0110','UOCATN0101','UTSMTI0101','UNAMPT0111','UVEBTB0101','UTLTSS0110')
----                                                              AND d.sorlcur_pidm= 21
--                                                              AND d.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                              AND d.SORLCUR_PROGRAM=SMRPAAP_PROGRAM
--                                                              AND  ((smrarul_area not in (select smriecc_area from smriecc)) or (smrarul_area in (select smriemj_area from smriemj)) )
--                                                              and SMRPAAP_TERM_CODE_EFF=  (select distinct MIN(SORLCUR_TERM_CODE_CTLG) from sorlcur jj where
--                                                                                                                             jj.sorlcur_pidm= d.SORLCUR_PIDM
--                                                                                                                            and jj.sorlcur_pidm=d.sorlcur_pidm
--                                                                                                                            and jj.SORLCUR_LMOD_CODE=d.sorlcur_lmod_code
--                                                                                                                            and jj.sorlcur_seqno=d.sorlcur_seqno)
--                                                              AND SHRTRCE_pidm = d.sorlcur_pidm
--                                                              AND SHRTRCE_pidm = SHRTRCR_PIDM
----                                                              AND SHRTRCE_TERM_CODE_EFF = SHRTRCR_TERM_CODE
--                                                              AND SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW=SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB
--                                                              AND SHRTRCE_GRDE_CODE =  SHRGRDE_CODE
--                                                              AND SHRTRCE_LEVL_CODE = SHRGRDE_LEVL_CODE
--                                                              AND SHRGRDE_PASSED_IND = 'Y'
--                                                              AND SHRTRCE_TRCR_SEQ_NO=SHRTRCR_SEQ_NO
--                                             ),
--                      aproba1 as (
--                                         select avances1.pidm,  count(*) aprobadas1 from avances1
--                                         group by  avances1.pidm
--                                      ),
--                      aproba2 as (
--                                         select avances2.pidm, count(*) aprobadas2 from avances2
--                                         group by  avances2.pidm
--                                        ),
--                      aprobadas as (
--                                             select aproba1.pidm pidm1,aproba2.pidm pidm2,
--                                                      nvl(aproba1.aprobadas1,0)+nvl(aproba2.aprobadas2,0) tot_aprob
--                                             from aproba1,aproba2
--                                             where  aproba1.pidm=aproba2.pidm(+)
--                                           )
--                       select pidm,
--                                   prog,
--                                   p_avance,
--                                   mat_aprob,
--                                   tot_matxprog
--                            from
--                            (
--                            select  distinct aprobadas.pidm1 pidm, p_prog  prog,
--                                       (nvl(tot_aprob,0)*100/nvl((SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
--                                                                                           WHERE SMBPGEN_PROGRAM=p_prog
--                                                                                              AND SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
--                                                                                                                          from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
--                                                                                                                                                        AND ee.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                                                                                                                        AND ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
--                                                                                                                                                                                                           WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
--                                                                                                                                                                                                               AND c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
--                                                                                                                                                                                                               AND c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
--                                                                                                                                                                                                               AND c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
--                                                                                                                            )),0))  p_avance,
--                                       aprobadas.tot_aprob  mat_aprob,
--                                       (SELECT SMBPGEN_REQ_COURSES_I_TRAD FROM SMBPGEN
--                                                    WHERE SMBPGEN_PROGRAM=p_prog
--                                                       AND SMBPGEN_TERM_CODE_EFF= (select distinct min(SORLCUR_TERM_CODE_CTLG)
--                                                                                                            from sorlcur ee where ee.sorlcur_pidm=aprobadas.pidm1
--                                                                                                             AND ee.SORLCUR_LMOD_CODE = 'LEARNER'
--                                                                                                             AND ee.SORLCUR_SEQNO = (SELECT MAX (c1x.SORLCUR_SEQNO)  FROM SORLCUR c1x
--                                                                                                                                                                WHERE  c1x.sorlcur_pidm = ee.sorlcur_pidm
--                                                                                                                                                                     AND c1x.SORLCUR_LMOD_CODE = ee.SORLCUR_LMOD_CODE
--                                                                                                                                                                     AND c1x.SORLCUR_ROLL_IND     = ee.SORLCUR_ROLL_IND
--                                                                                                                                                                     AND c1x.SORLCUR_PROGRAM = ee.SORLCUR_PROGRAM)
--                                                                                                          )
--                                        )  tot_matxprog
--                                      from aprobadas
--                            )
--                             where p_avance between 0 and 150;
    begin
                           for x in p_ma(p_prog) loop
                                      DBMS_OUTPUT.PUT_LINE('ENTRO  '||x.pidm||' * '||x.prog);
                                    select count(*) into existe from  SZTPOSS
                                     where  SZTPOSS_PIDM=x.pidm
                                     and SZTPOSS_PROGRAM=x.prog;

                                     if existe=1 then
                                              UPDATE SZTPOSS
                                              SET  SZTPOSS_FECHA=sysdate,
                                              SZTPOSS_P_AVANCE=x.p_avance,
                                              SZTPOSS_MAT_APROB=x.mat_aprob,
                                              SZTPOSS_TOT_MATXPROG=x.tot_matxprog
                                              where SZTPOSS_PIDM=x.pidm
                                               and SZTPOSS_PROGRAM=x.prog;
                                     else
                                       begin
                                            INSERT INTO SZTPOSS
                                              VALUES
                                                (x.pidm,
                                                 x.prog,
                                                 sysdate,
                                                 x.p_avance,
                                                 x.mat_aprob,
                                                 x.tot_matxprog,
                                                 'N',
                                                 'N',
                                                 'N',
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                 NULL,
                                                  'N',
                                                 'N',
                                                 NULL);
                                       EXCEPTION
                                             WHEN OTHERS THEN
                                               NULL;
                                              DBMS_OUTPUT.PUT_LINE('Error al insertar alumno');
                                          end;
                                     end if;
                                    COMMIT;
                                     existe:=0;
                           end loop;
       end;


 Procedure encuentra_candidatos_ma  is

cursor c1 is

SELECT DISTINCT SMBPGEN_PROGRAM prog
FROM SMRPRLE,SMBPGEN
WHERE SMRPRLE_LEVL_CODE in ('MA')
AND SMRPRLE_PROGRAM=SMBPGEN_PROGRAM
AND substr(SMRPRLE_PROGRAM,1,3)='UTL'
AND SMBPGEN_ACTIVE_IND='Y';
      begin
            for x in c1  loop
                PKG_DASHBOARD_DOCENTES.p_carga_alu_porc_MA(x.prog);
             end loop;
       end;

 Procedure p_act_envmail_ss(p_pidm number,p_prog varchar2,p_porc number)
  AS
         l_contar      Number:=0;
         l_contar1     Number:=0;

            BEGIN
                      SELECT COUNT(*)  INTO l_contar
                       FROM  SZTPOSS
                       WHERE SZTPOSS_PIDM =p_pidm
                       AND SZTPOSS_PROGRAM=p_prog
                       AND SZTPOSS_P_AVANCE=p_porc
                       AND SZTPOSS_EMAIL_60='N'
                       and SZTPOSS_PROGRAM in (SELECT DISTINCT SMBPGEN_PROGRAM FROM SMRPRLE,SMBPGEN
                                                                              WHERE SMRPRLE_LEVL_CODE in ('LI')
                                                                                   AND SMRPRLE_PROGRAM=SMBPGEN_PROGRAM
                                                                                   AND substr(SMRPRLE_PROGRAM,1,3)='UTL'
                                                                                   AND SZTPOSS_PROGRAM=SMRPRLE_PROGRAM
                                                                                   AND SMBPGEN_ACTIVE_IND='Y');

                IF l_contar = 1 THEN
                       UPDATE   SZTPOSS SET SZTPOSS_EMAIL_60='Y',SZTPOSS_FECHA_60=sysdate
                       where SZTPOSS_PIDM=p_pidm
                       and SZTPOSS_PROGRAM=p_prog
                       and SZTPOSS_P_AVANCE=p_porc
                       and SZTPOSS_EMAIL_60='N';
                       COMMIT;
                   END IF;

                   SELECT COUNT(*)  INTO l_contar1
                       FROM  SZTPOSS
                       WHERE SZTPOSS_PIDM =p_pidm
                       AND SZTPOSS_PROGRAM=p_prog
                       AND SZTPOSS_P_AVANCE=p_porc
                       AND SZTPOSS_EMAIL_70='N'
                       and SZTPOSS_PROGRAM in (SELECT DISTINCT SMBPGEN_PROGRAM FROM SMRPRLE,SMBPGEN
                                                                              WHERE SMRPRLE_LEVL_CODE in ('LI')
                                                                                   AND SMRPRLE_PROGRAM=SMBPGEN_PROGRAM
                                                                                   AND substr(SMRPRLE_PROGRAM,1,3)='UTL'
                                                                                   AND SZTPOSS_PROGRAM=SMRPRLE_PROGRAM
                                                                                   AND SMBPGEN_ACTIVE_IND='Y');

                IF l_contar1 = 1 THEN
                       UPDATE   SZTPOSS SET SZTPOSS_EMAIL_70='Y',SZTPOSS_FECHA_70=sysdate
                       where SZTPOSS_PIDM=p_pidm
                       and SZTPOSS_PROGRAM=p_prog
                       and SZTPOSS_P_AVANCE=p_porc
                       and SZTPOSS_EMAIL_70='N';
                       COMMIT;
                   END IF;
            END;

 FUNCTION f_extrae_alumnos_SS(p_avance number) RETURN PKG_DASHBOARD_DOCENTES.alumnos_ss
           AS
                extrae_out PKG_DASHBOARD_DOCENTES.alumnos_ss;
 -- 60 y 70 % es para SS unicamente
            BEGIN
                        open extrae_out
                            FOR
                                  with alumnos as (
                                                             select distinct SZTPOSS_PIDM PIDM,
                                                                                 SPRIDEN_ID ID_ALU,
                                                                                 SZTPOSS_PROGRAM PROG,
                                                                                 SZTPOSS_P_AVANCE PORC,
                                                                                 GOREMAL_EMAIL_ADDRESS EMAIL,
                                                                                 SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME NOMBRE
                                                             from SZTPOSS,GOREMAL,SPRIDEN
                                                             where SZTPOSS_PIDM=GOREMAL_PIDM
                                                                 AND SZTPOSS_PIDM=SPRIDEN_PIDM
                                                                 AND GOREMAL_EMAL_CODE='PRIN'
                                                                 AND  SZTPOSS_P_AVANCE=p_avance
                                                                 AND (SZTPOSS_EMAIL_60='N' OR SZTPOSS_EMAIL_70='N')
                                                                 and SZTPOSS_PROGRAM in (SELECT DISTINCT SMBPGEN_PROGRAM FROM SMRPRLE,SMBPGEN
                                                                                                            WHERE SMRPRLE_LEVL_CODE in ('LI')
                                                                                                            AND SMRPRLE_PROGRAM=SMBPGEN_PROGRAM
                                                                                                            AND SZTPOSS_PROGRAM=SMRPRLE_PROGRAM
                                                                                                            AND substr(SMRPRLE_PROGRAM,1,3)='UTL'
                                                                                                            AND SMBPGEN_ACTIVE_IND='Y')
                                                   )
                                         select distinct ALUMNOS.*  from ALUMNOS
                                         order by porc,pidm;

                        RETURN (extrae_out);

            END f_extrae_alumnos_SS;

FUNCTION f_max_desc ( PPIDM Number )  RETURN VarChar2
IS

v_porcentaje   varchar2(500);
v_code        varchar2(12);  --number:=0;
v_desc        varchar2(80);
NUMDEC NUMBER;
IDIOMA VARCHAR2(32767);
vletra   varchar2(200);


begin

NUMDEC := 2;
IDIOMA := 'ESP';


select SUBSTR(max(TBBESTU_EXEMPTION_CODE),-3) AS CODE, PT.TBBEXPT_DESC
     INTO  v_code, v_desc
from tbbestu bb , tbbexpt pt
where pt.TBBEXPT_EXEMPTION_CODE = BB.TBBESTU_EXEMPTION_CODE
and  PT.TBBEXPT_TERM_CODE     =  BB.TBBESTU_TERM_CODE
and  TBBESTU_STUDENT_EXPT_ROLL_IND = 'Y'
and  TBBESTU_DEL_IND is null
and   BB.TBBESTU_TERM_CODE = (select max(B2.TBBESTU_TERM_CODE)   from tbbestu b2
                                        where b2.tbbestu_pidm  = bb.tbbestu_pidm )
and  tbbestu_pidm = pPIDM
group by PT.TBBEXPT_DESC
order by 2
;

---------------------------comvierte  el numero de porcentaje en lestras---------------

v_porcentaje := BANINST1.NUMERO_A_TEXTO ( to_number(v_code), NUMDEC, IDIOMA );

---v_porcentaje:= to_char(; ----|| '  '|| v_desc;
vletra := v_porcentaje || ' PORCIENTO '   ;
return (vletra);
EXCEPTION WHEN OTHERS THEN
vletra:='NO SE ENCONTRO DESCUENTO';
return (vletra);

end f_max_desc;

procedure carga_alu_adeu_doc(prog varchar2)
 AS

begin

 declare cursor p_doc(prog varchar2) is
        SELECT DISTINCT A.SARCHKL_PIDM PIDM,
        SORLCUR_PROGRAM PROGRA,
        (select  DISTINCT SMRPRLE_PROGRAM_DESC from SMRPRLE where SMRPRLE_PROGRAM=SORLCUR_PROGRAM) DESCR,
        A.SARCHKL_ADMR_CODE COD,
        A.SARCHKL_CKST_CODE STAT,
        TRUNC(A.SARCHKL_SOURCE_DATE)  FREAL,
        TRUNC(A.SARCHKL_SOURCE_DATE)+to_number(ZSTPARA_PARAM_VALOR)  FVEN
        FROM SARCHKL A,SORLCUR,SARADAP,ZSTPARA
        WHERE A.SARCHKL_PIDM=SARADAP_PIDM
--        and  A.SARCHKL_PIDM=35699
        and SARADAP_PIDM=SORLCUR_PIDM
        AND SORLCUR_LMOD_CODE='LEARNER'
        AND SORLCUR_PROGRAM=prog
        AND SARADAP_PROGRAM_1=SORLCUR_PROGRAM
        and SORLCUR_PIDM in (SELECT SGBSTDN_PIDM FROM  SGBSTDN
                                                WHERE SORLCUR_PIDM=SGBSTDN_PIDM
                                                  AND SGBSTDN_STST_CODE IN ('MA', 'PR', 'AS')
                                                  AND SGBSTDN_PROGRAM_1=SORLCUR_PROGRAM)
        AND ZSTPARA_MAPA_ID='DOCUMENTOS_VENC'
        AND A.SARCHKL_ADMR_CODE=ZSTPARA_PARAM_ID
        AND TRUNC(SYSDATE)>A.SARCHKL_SOURCE_DATE+to_number(ZSTPARA_PARAM_VALOR)
        AND A.SARCHKL_CKST_CODE NOT IN ('VALIDADO','ENVALIDACION','PRESTAMO')
        AND (A.SARCHKL_PIDM NOT IN (SELECT B.SARCHKL_PIDM FROM SARCHKL B  WHERE  B.SARCHKL_PIDM=A.SARCHKL_PIDM
                                                           AND B.SARCHKL_ADMR_CODE IN ('ACND')  AND B.SARCHKL_CKST_CODE IN ('VALIDADO','ENVALIDACION','PRESTAMO'))
             or A.SARCHKL_PIDM NOT IN (SELECT B.SARCHKL_PIDM FROM SARCHKL B  WHERE  B.SARCHKL_PIDM=A.SARCHKL_PIDM
                                                           AND B.SARCHKL_ADMR_CODE IN ('ACNO')  AND B.SARCHKL_CKST_CODE IN ('VALIDADO','ENVALIDACION','PRESTAMO')));
       begin
                   for x in p_doc(prog) loop
                   Begin
                      INSERT INTO SZTADOC
                      VALUES
                       (
                        x.pidm,
                        x.progra,
                        x.cod,
                        x.stat,
                        x.fven,
                        'N',
                        NULL,
                        x.descr,
                        x.freal
                         );
                      Exception
                        When Others then
                        null;
                     End;
                  end loop;
       COMMIT;
       end;

end;


Procedure encuentra_alumnos_doc  is

cursor c2 is

SELECT DISTINCT SMBPGEN_PROGRAM prog
FROM SMRPRLE,SMBPGEN
WHERE SMRPRLE_PROGRAM=SMBPGEN_PROGRAM
AND substr(SMRPRLE_PROGRAM,1,3)='UTL'
AND SMBPGEN_ACTIVE_IND='Y';
      begin
            for y in c2  loop
                PKG_DASHBOARD_DOCENTES.carga_alu_adeu_doc(y.prog);
             end loop;
       end;

 Procedure p_act_envmail_doc(p_pidm number,p_prog varchar2,p_doc varchar2)
  AS
         l_contar      Number;

            BEGIN
                      SELECT COUNT(*)  INTO l_contar
                       FROM  SZTADOC
                       WHERE SZTADOC_PIDM =p_pidm
                       AND SZTADOC_PROGRAM=p_prog
                       AND SZTADOC_DOCTO=p_doc
                       AND SZTADOC_EMAIL='N';

                IF l_contar = 1 THEN
                       UPDATE SZTADOC SET SZTADOC_EMAIL='Y',SZTADOC_FEC_EMAIL=sysdate
                       where SZTADOC_PIDM=p_pidm
                       and SZTADOC_PROGRAM=p_prog
                       and SZTADOC_DOCTO=p_doc
                       and SZTADOC_EMAIL='N';
                       COMMIT;
                   END IF;
            END;

  FUNCTION f_extrae_alumnos_doc(p_docto varchar2) RETURN PKG_DASHBOARD_DOCENTES.alumnos_doc
           AS
                extrae_doc PKG_DASHBOARD_DOCENTES.alumnos_doc;

            BEGIN
                        open extrae_doc
                            FOR
                                  with alu_doc as (
                                                             select distinct SZTADOC_PIDM PIDM,
                                                                                 SPRIDEN_ID ID_ALU,
                                                                                 SZTADOC_PROGRAM PROG,
                                                                                 SZTADOC_DESCRIPCION DESCR,
                                                                                 SZTADOC_DOCTO DOC,
                                                                                 GOREMAL_EMAIL_ADDRESS EMAIL,
                                                                                 SZTADOC_FEC_EMAIL FEC_EMAIL,
                                                                                 SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME NOMBRE
                                                             from SZTADOC,GOREMAL,SPRIDEN
                                                             where SZTADOC_PIDM=GOREMAL_PIDM
                                                                 AND SZTADOC_PIDM=SPRIDEN_PIDM
                                                                 AND GOREMAL_EMAL_CODE='PRIN'
                                                                 AND  SZTADOC_DOCTO=p_docto
                                                                 AND SZTADOC_EMAIL IN ('N','Y')
                                                   )
                                         select distinct ALU_DOC.*  from ALU_DOC
                                         order by DOC,pidm;

                        RETURN (extrae_doc);

            END f_extrae_alumnos_doc;

--
--
   FUNCTION f_datos_fiscales(p_pidm NUMBER) RETURN VARCHAR2
   as
   l_resultado VARCHAR2(100);
   l_contar    NUMBER;

   BEGIN

        BEGIN

            SELECT COUNT(*)
            INTO l_contar
            FROM SPREMRG
            WHERE 1  = 1
            AND SPREMRG_PIDM = p_pidm;

        END;

        IF l_contar = 0 THEN

            l_resultado:='NO';

            RETURN(l_resultado);

        ELSIF  l_contar > 0 THEN


            BEGIN

                SELECT TRUNC(spremrg_activity_date) resultado
                INTO l_resultado
                FROM spremrg
                WHERE 1 = 1
                AND spremrg_pidm = p_pidm
                AND ROWNUM=1;

            EXCEPTION WHEN NO_DATA_FOUND THEN

                l_resultado:='Error --> '||SQLERRM;
                RETURN(l_resultado);

            END;

            RETURN(l_resultado);

        END IF;

   END;
   --
   --

   FUNCTION f_jornada_rate2 (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_f
           AS
                c_out_f PKG_DASHBOARD_DOCENTES.cursor_out_f;

  BEGIN
       open c_out_f
         FOR SELECT DISTINCT
                   b.sgrsatt_pidm vl_pidm,
                b.sgrsatt_atts_code vl_jornada,
                c.stvatts_desc vl_descripcion_jornada,
                a.sorlcur_rate_code vl_rate,
                d.stvrate_desc vl_descripcion_rate,
                a.sorlcur_program vl_programa,
                e.sztdtec_programa_comp vl_desc_programa
                FROM sorlcur A,sgrsatt B,stvatts C,stvrate D, SZTDTEC E
                WHERE 1=1
                AND a.sorlcur_program = e.sztdtec_program
                AND a.sorlcur_camp_code = e.sztdtec_camp_code
                AND a.sorlcur_pidm = b.sgrsatt_pidm(+)
                AND a.sorlcur_key_seqno = b.sgrsatt_stsp_key_sequence(+)
                AND b.sgrsatt_atts_code = c.stvatts_code
                AND a.sorlcur_rate_code = d.stvrate_code
                AND a.sorlcur_seqno = (SELECT MAX (a1.sorlcur_seqno)
                                                    FROM sorlcur a1
                                                    WHERE a.sorlcur_pidm = a1.sorlcur_pidm
                                                    And a.sorlcur_lmod_code = a1.sorlcur_lmod_code
                                                      )
                And b.sgrsatt_surrogate_id = (SELECT MAX (b1.sgrsatt_surrogate_id)
                                                             FROM sgrsatt b1
                                                             WHERE b.sgrsatt_pidm = b1.sgrsatt_pidm
                                                             AND b.sgrsatt_stsp_key_sequence = b1.sgrsatt_stsp_key_sequence
                                                             AND regexp_like (b1.sgrsatt_atts_code , '^[0-9]')
                                                             AND SUBSTR (b1.sgrsatt_term_code_eff, 5,1) NOT IN ( '8','9')
                                                             )
                AND a.sorlcur_lmod_code = 'LEARNER'
                and a.SORLCUR_CACT_CODE in ('ACTIVE', 'INACTIVE')
                And b.sgrsatt_pidm = p_pidm
             ;

       RETURN (c_out_f);

  end f_jornada_rate2;
--
--
--    FUNCTION f_fecha_inicio (p_pidm IN NUMBER) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_finicio
--            AS
--                c_out_inicio PKG_DASHBOARD_DOCENTES.cursor_out_finicio;
--
--        BEGIN
--             OPEN c_out_inicio
--                FOR SELECT DISTINCT
--                    cur.sorlcur_pidm vl_pidm,
--                    cur.sorlcur_start_date vl_fecha_inicio,
--                    cur.sorlcur_program vl_programa
--                    FROM sorlcur CUR
--                    WHERE 1=1
--                    AND cur.sorlcur_pidm = p_pidm
--                    AND cur.sorlcur_lmod_code = 'LEARNER'
--                    AND cur.sorlcur_seqno = (SELECT MAX (cur1.sorlcur_seqno)
--                                            FROM sorlcur CUR1
--                                            WHERE cur.sorlcur_pidm = cur1.sorlcur_pidm
--                                            AND cur.sorlcur_lmod_code = cur1.sorlcur_lmod_code)
--                    ;
--
--             RETURN (c_out_inicio);
--
--          END;
 FUNCTION f_fecha_inicio (p_pidm IN NUMBER) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_finicio
     AS
        c_out_inicio PKG_DASHBOARD_DOCENTES.cursor_out_finicio;
        id_alumno varchar2(10):= null;

        BEGIN
         select  f_getspridenid(p_pidm) into id_alumno from dual;

           if substr(id_alumno,1,2) not in ('40','53','54') then
             OPEN c_out_inicio
                FOR SELECT DISTINCT
                    cur.sorlcur_pidm vl_pidm,
                    cur.sorlcur_start_date vl_fecha_inicio,
                    cur.sorlcur_program vl_programa
                    FROM sorlcur CUR
                    WHERE 1=1
                    AND cur.sorlcur_pidm = p_pidm
                    AND cur.sorlcur_lmod_code = 'LEARNER'
                    AND cur.sorlcur_seqno = (SELECT MAX (cur1.sorlcur_seqno)
                                            FROM sorlcur CUR1
                                            WHERE cur.sorlcur_pidm = cur1.sorlcur_pidm
                                            AND cur.sorlcur_lmod_code = cur1.sorlcur_lmod_code);

           Elsif substr(id_alumno,1,2) in ('40','53') then
             OPEN c_out_inicio
                FOR SELECT DISTINCT
                    cur.tztboot_pidm vl_pidm,
                    cur.TZTBOOT_START_DATE vl_fecha_inicio,
                    'BOTECSEMCU' vl_programa
                    FROM tztboot CUR
                    WHERE 1=1
                    AND cur.tztboot_pidm = p_pidm
                    AND (cur.TZTBOOT_CAMP_CODE = 'BOT' OR cur.TZTBOOT_CAMP_CODE ='UDD')
                    AND cur.TZTBOOT_TERM_CODE = (SELECT MAX (cur1.TZTBOOT_TERM_CODE)
                                            FROM tztboot CUR1
                                            WHERE cur.tztboot_pidm = cur1.tztboot_pidm
                                            AND cur.TZTBOOT_CAMP_CODE = cur1.TZTBOOT_CAMP_CODE);

           Elsif substr(id_alumno,1,2) = '54' then
             OPEN c_out_inicio
                FOR SELECT DISTINCT
                    cur.TZTUTLX_pidm vl_pidm,
                    cur.TZTUTLX_START_DATE vl_fecha_inicio,
                    'UTXECSEMCU' vl_programa
                    FROM TZTUTLX CUR
                    WHERE 1=1
                    AND cur.TZTUTLX_pidm = p_pidm
                    AND cur.TZTUTLX_CAMP_CODE = 'UTX'
                    AND cur.TZTUTLX_TERM_CODE = (SELECT MAX (cur1.TZTUTLX_TERM_CODE)
                                            FROM TZTUTLX CUR1
                                            WHERE cur.TZTUTLX_pidm = cur1.TZTUTLX_pidm
                                            AND cur.TZTUTLX_CAMP_CODE = cur1.TZTUTLX_CAMP_CODE);
           end if;

          RETURN (c_out_inicio);

        END;

FUNCTION F_BAJA_ADEUDO(PPIDM  NUMBER, PTERM  VARCHAR2) RETURN NUMBER AS
/* funcion creada por glovicx 22-01-2019 para mostrar en el SIU unaleyenda de los alumnos que fueron
dados de baja por adeudo */
VREGRESA   VARCHAR2(30);
VTRUE   NUMBER;

BEGIN

 -- DBMS_OUTPUT.PUT_LINE('PRIMERO1---' || PPIDM||'-'||PTERM );

   SELECT DISTINCT f.sfbetrm_rgre_code
     INTO VREGRESA
      FROM SGRSCMT sg, sfbetrm f
       WHERE  SG.SGRSCMT_PIDM = F.SFBETRM_PIDM
     --  and   SG.SGRSCMT_TERM_CODE  = F.SFBETRM_TERM_CODE
       and     sg.SGRSCMT_PIDM =  PPIDM
      --  AND     sg.SGRSCMT_TERM_CODE = PTERM
        and   f.SFBETRM_RGRE_CODE  = 'BA';
         -- AND UPPER(SGRSCMT_COMMENT_TEXT) like '%ADEUDO%'
--         AND SGRSCMT_SEQ_NO =
--                                (SELECT MAX (SGRSCMT_SEQ_NO)
--                                   FROM SGRSCMT mt
--                                  WHERE     mt.SGRSCMT_PIDM = sg.SGRSCMT_PIDM
--                                        AND mt.SGRSCMT_TERM_CODE =
--                                              sg.SGRSCMT_TERM_CODE);


IF VREGRESA IS NOT NULL  THEN
VREGRESA := 'ADEUDO';
VTRUE  := 1;
  --DBMS_OUTPUT.PUT_LINE('SALIDA1---' || VREGRESA);
RETURN(1);
END IF;

 --DBMS_OUTPUT.PUT_LINE('SALIDA22---' || VREGRESA);

EXCEPTION WHEN OTHERS THEN
VREGRESA := 'NO';
--DBMS_OUTPUT.PUT_LINE('SALIDA33---' || VREGRESA);
RETURN(0);
END F_BAJA_ADEUDO;
--
--


   FUNCTION f_docapocrifo (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_apoc
           AS
                c_out_apoc PKG_DASHBOARD_DOCENTES.cursor_out_apoc;

  BEGIN
       open c_out_apoc
         FOR SELECT
                a.sfbetrm_rgre_code vl_codmotivo
            FROM sfbetrm A,stvrgre B
            WHERE 1=1
            AND b.stvrgre_code = sfbetrm_rgre_code
            AND a.sfbetrm_rgre_code = 'DA'
            AND a.sfbetrm_pidm = p_pidm
            AND a.sfbetrm_term_code IN (SELECT MAX (b1.sfbetrm_term_code)
                                                        FROM sfbetrm B1
                                                        WHERE a.sfbetrm_term_code = b1.sfbetrm_term_code
                                                        AND a.sfbetrm_rgre_code = b1.sfbetrm_rgre_code)
       ;

       RETURN (c_out_apoc);

  end;

   FUNCTION f_matbitacora (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES. cursor_out_matbita
           AS
                c_out_mat_bita PKG_DASHBOARD_DOCENTES.cursor_out_matbita;

     BEGIN
           open c_out_mat_bita
             FOR SELECT DISTINCT
                    sfrstca_term_code VL_PERIODO,
                    ssbsect_ptrm_code VL_P_PERIODO,
                    sfrstca_pidm VL_PIDM,
                    sfrstca_crn VL_CRN,
                    ssbsect_subj_code||ssbsect_crse_numb VL_MATERIA,
                    ssbsect_crse_title VL_DESCRIPCION,
                    sfrstca_rsts_code VL_ESTATUS,
                    sfrstca_activity_date VL_ACTIVIDAD,
                    sfrstca_user VL_USUARIO,
                    sfrstca_message VL_MENSAJE
                FROM sfrstca, ssbsect, sfrstcr
                WHERE  1=1
                AND sfrstca_crn = ssbsect_crn
                AND sfrstcr_crn = sfrstca_crn
                AND sfrstcr_ptrm_code = ssbsect_ptrm_code
                AND ssbsect_term_code = sfrstca_term_code
                AND sfrstca_pidm = sfrstcr_pidm
                AND sfrstca_pidm = p_pidm
                ORDER BY VL_MATERIA,VL_ACTIVIDAD
                ;

           RETURN (c_out_mat_bita);

  end;

   FUNCTION f_estadosbita (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_estabita
           AS
                c_out_esta_bita PKG_DASHBOARD_DOCENTES.cursor_out_estabita;

 BEGIN
       OPEN c_out_esta_bita
         FOR SELECT
                VL_SEMANA,
                VL_APLICADO,
                VL_PROGRAMA,
                VL_BIMESTRE,
                VL_PERIODO,
                VL_ESTADO,
                VL_MOTIVO,
                VL_SITUACION,
                VL_USUARIO
                FROM (
                      SELECT DISTINCT
                         sgrscmt_pidm PIDM,
                         NULL VL_SEMANA,
                         trunc (sgrscmt_activity_date)  VL_APLICADO,
                         SZTDTEC_PROGRAMA_COMP VL_PROGRAMA,
                         NULL VL_BIMESTRE,
                         sgrscmt_term_code VL_PERIODO,
                         stvstst_desc VL_ESTADO,
                         sgrscmt_comment_text VL_MOTIVO,
                         sgrscmt_comment_text VL_SITUACION,
                         sgrscmt_user_id VL_USUARIO
                      FROM sgrscmt A, sorlcur B, sztdtec C, sgbstdn D, stvstst E
                      WHERE 1=1
                      AND a.sgrscmt_pidm = b.sorlcur_pidm
                      AND c.sztdtec_program = b.sorlcur_program
                      AND b.sorlcur_lmod_code = 'LEARNER'
                      AND b.sorlcur_seqno = (SELECT MAX (b1.sorlcur_seqno)
                                             FROM sorlcur B1
                                             WHERE 1=1
                                             AND b.sorlcur_pidm = b1.sorlcur_pidm
                                             AND b.sorlcur_lmod_code = b1.sorlcur_lmod_code)
                       And b.sorlcur_pidm = d.sgbstdn_pidm
                       And d.sgbstdn_term_code_eff = (Select max (d1.sgbstdn_term_code_eff)
                                                                                     from sgbstdn d1
                                                                                     Where  d.sgbstdn_pidm = d1.sgbstdn_pidm
                                                                                     )
                       And e.stvstst_code = d.sgbstdn_stst_code
                      UNION ALL
                      SELECT DISTINCT
                         SPRIDEN_PIDM PIDM,
                         TO_CHAR(SEMANA) VL_SEMANA,
                         trunc (FECHA_CREACION)  VL_APLICADO,
                         TO_CHAR(PROGRAMA) VL_PROGRAMA,
                         TO_CHAR(BIMESTRE) VL_BIMESTRE,
                         'MIGRA' VL_PERIODO,
                         TO_CHAR(ESTADO)  VL_ESTADO,
                         TO_CHAR(MOTIVO) VL_MOTIVO,
                         TO_CHAR(SITUACION) VL_SITUACION,
                         'MIGRA_LI' VL_USUARIO
                      FROM SZTESTTS_MIG
                      WHERE 1=1
                               )
                WHERE 1=1
                AND PIDM = P_PIDM
                ORDER BY VL_APLICADO
             ;

       RETURN (c_out_esta_bita);

  END;


   FUNCTION f_bitmaterias (p_pidm in number) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_bitmaterias
           AS
                c_out_bitmaterias PKG_DASHBOARD_DOCENTES.cursor_out_bitmaterias;

 BEGIN
       OPEN c_out_bitmaterias
           FOR SELECT
                  a.sfrstcr_term_code VL_PERIODO,
                  a.sfrstcr_ptrm_code VL_P_PERIODO,
                  a.sfrstcr_crn VL_CRN,
                  b.ssbsect_subj_code||b.ssbsect_crse_numb VL_MATERIA,
                  b.ssbsect_crse_title VL_DESCRIPCION,
                  b.ssbsect_ptrm_start_date VL_INICIO,
                  b.ssbsect_ptrm_end_date VL_FIN,
                  a.sfrstcr_rsts_code VL_ESTATUS,
                  a.sfrstcr_grde_code VL_CALIFICACION
               FROM
                  sfrstcr A,
                  ssbsect B
               WHERE 1=1
               AND b.ssbsect_crn = a.sfrstcr_crn
               AND b.ssbsect_term_code = a.sfrstcr_term_code
               AND a.sfrstcr_pidm = P_PIDM
               ORDER BY VL_P_PERIODO,VL_P_PERIODO
            ;

       RETURN (c_out_bitmaterias);

  END;

FUNCTION f_fecha_cambio (p_pidm in number) RETURN varchar2 ---glovicx  11 03 2019
           AS
   regresa date;

 BEGIN

    select max(trunc(SPREMRG_activity_date))
      into regresa
    from SPREMRG
    where SPREMRG_PIDM = p_pidm;
    --AND SPREMRG_PRIORITY = 1;
    --DBMS_OUTPUT.PUT_LINE(regresa);

       RETURN (regresa);

   exception when others then
   regresa :=  'NO_EXISTE_FECHA';
      RETURN (regresa);
  END;

--
--FER 22/08/2019 V1

FUNCTION f_tienda_solic (P_PIDM IN NUMBER) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_tienda
           AS
                c_out_tienda PKG_DASHBOARD_DOCENTES.cursor_out_tienda;


 BEGIN
       OPEN c_out_tienda
         FOR    SELECT DISTINCT
                        svrrsso_srvc_code VL_CODE,
                        svvsrvc_desc VL_SERVICIO,
                        svrrsso_serv_amount VL_COSTO
                    FROM
                        svrrsrv A,
                        svrrsso,
                        svvsrvc
                    WHERE 1=1
                    AND  a.svrrsrv_srvc_code = svrrsso_srvc_code
                    AND a.svrrsrv_seq_no = svrrsso_rsrv_seq_no
                    AND svvsrvc_code = svrrsso_srvc_code
                    AND svrrsrv_inactive_ind = 'Y'
                    AND a.svrrsrv_web_ind = 'Y'
                    AND a.svrrsrv_seq_no =  BANINST1.bvgkptcl.F_apply_rule_protocol (P_PIDM, A.SVRRSRV_SRVC_CODE)
                    and a.svrrsrv_srvc_code in  (SELECT zstpara_param_id
                                                 FROM  zstpara
                                                 WHERE 1=1
                                                 AND zstpara_mapa_id ='AUTOSERVICIOSIU')
                    ORDER BY svvsrvc_desc;

       RETURN (c_out_tienda);

 END f_tienda_solic;

  FUNCTION f_dashboard_revoe_out (p_pidm in number, p_cat  varchar2, p_prog  varchar2  ) RETURN PKG_DASHBOARD_DOCENTES.revoe_out
           AS
                revo_out PKG_DASHBOARD_DOCENTES.revoe_out;

                       BEGIN
                          open revo_out
                            FOR
                            select  NULL area,
                                      substr(sztdtec_program,4,2) nivel,
                                       decode(sztdtec_mod_type,'OL','EN LINEA', 'S','SEMIPRESENCIAL') tipo,
                                       sztdtec_status estatus,
                                       sztdtec_num_rvoe num_revoe,
                                       sztdtec_fecha_rvoe fecha_rvoe,
                                       sztdtec_incorporante incor
                             from  sztdtec,sorlcur s  where 1=1
                                                  and s.sorlcur_pidm=p_pidm
                                                  and s.sorlcur_lmod_code='LEARNER'
                                                  and s.SORLCUR_CACT_CODE  != 'CHANGE'
                                                  and s.sorlcur_program= p_prog
                                                  and s.sorlcur_term_code_ctlg= p_cat
                                                  and s.sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ss
                                                                                     where  s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                        and s.sorlcur_program=ss.sorlcur_program
                                                                                        and s.sorlcur_lmod_code=ss.sorlcur_lmod_code)
                                                  and sztdtec_program=s.sorlcur_program
                                                  and sztdtec_term_code=s.sorlcur_term_code_ctlg;
                        RETURN (revo_out);
            END f_dashboard_revoe_out;

Function  f_dashboard_saldodia_Titulo (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
    Begin

                       select sum (x.balance)
                            Into vl_monto
                       from (
                                select sum(nvl (tbraccd_balance, 0)) balance
                                from tbraccd
                                join TBBDETC on TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
                                join TZTNCD on TZTNCD_CODE = TBRACCD_DETAIL_CODE and TZTNCD_CONCEPTO in ('Venta','Interes')
                                Where tbraccd_pidm = p_pidm
                                And TRUNC(TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate)
                                union
                                select sum(nvl (tbraccd_balance, 0)) balance
                                from tbraccd
                                 Where tbraccd_pidm = p_pidm
                                And TRUNC(TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate)
                                and tbraccd_detail_code in ( SELECT distinct ZSTPARA_PARAM_VALOR
                                                                          FROM ZSTPARA
                                                                          WHERE     ZSTPARA_MAPA_ID = 'COMPL_COSTOS'
                                                                        )
                                ) x;

           Return (vl_monto);
           --Return(vl_moneda);
    Exception
    when Others then
        vl_monto :=0;
        vl_moneda:=Null;
      Return (vl_monto);
    --  Return(vl_moneda);
    END f_dashboard_saldodia_Titulo;


function f_dashboard_avcu_out_prono(pidm number, prog varchar2,usu_siu varchar2) RETURN PKG_DASHBOARD_DOCENTES.avcu_out_prono
           AS
                avance_n_out_prono PKG_DASHBOARD_DOCENTES.avcu_out_prono;

  VL_DIPLO NUMBER:=0;
  VL_DIPLO2 NUMBER:=0;
  VL_PIDM NUMBER:=pidm;

 BEGIN


      BEGIN
                SELECT NVL(count(*),0)
                INTO  VL_DIPLO2
                FROM TZTPROGM A
                WHERE 1=1
                and A.PIDM = VL_PIDM
                and A.CAMPUS='UTS'
                AND A.NIVEL='EC'
                AND A.ESTATUS in('BT');

      EXCEPTION
            WHEN OTHERS THEN
             VL_DIPLO2 := 0;
      END;

      IF   VL_DIPLO2>=1 THEN

           VL_DIPLO:=0;

      ELSIF VL_DIPLO2 =0 THEN

        BEGIN
            SELECT NVL(count(*),0)
                INTO  VL_DIPLO
            FROM TZTPROGM A
            WHERE 1=1
            and A.PIDM = VL_PIDM
            and A.CAMPUS='UTS'
            AND A.NIVEL='EC';
        EXCEPTION
            WHEN OTHERS THEN
             VL_DIPLO := 0;
        END;

      END IF;


   IF VL_DIPLO =0  THEN


            BEGIN

                    Begin
                           delete from avance_n
                           where protocolo=9999
                           and pidm_alu=VL_PIDM;
                           commit;
                    Exception
                        When Others then
                         null;
                    End;

                      insert into avance_n
                            select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                            case
                                when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                            end  per,  ----
                            smrpaap_area area,
                            case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                  case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                     when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                     when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                     when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                     when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                     when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                     when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                     else smralib_area_desc
                                  end
                            else
                                smralib_area_desc
                            end
                            nombre_area,
                            smrarul_subj_code||smrarul_crse_numb_low materia,
                            scrsyln_long_course_title nombre_mat,
                            case when k.calif in ('NA','NP','AC') then '1'
                                 when k.st_mat='EC' then '101'
                            else
                                k.calif
                            end calif,
                            nvl(k.st_mat,'PC'),
                            smracaa_rule regla,
                            case
                                when k.st_mat='EC' then null
                               else
                               k.calif
                            end  origen,
                            k.fecha,
                            so.PIDM,
                            'PRONO' usuario
                            from smrpaap s, smrarul,  TZTPROGM so, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
                                 ( select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                    w.shrtckn_subj_code subj, w.shrtckn_crse_numb code,
                                    shrtckg_grde_code_final CALIF,
                                    decode(shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT,
                                    shrtckg_final_grde_chg_date fecha
                                   from shrtckn w,shrtckg, shrgrde, smrprle
                                    where shrtckn_pidm=VL_PIDM--pidm
                                    and  shrtckg_pidm=w.shrtckn_pidm
                                    and  SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401')
                                    and  shrtckg_tckn_seq_no=w.shrtckn_seq_no
                                    and  shrtckg_term_code=w.shrtckn_term_code
                                    and  smrprle_program=prog
                                    and  shrgrde_levl_code=smrprle_levl_code
                                    and shrgrde_term_code_effective=(select zstpara_param_desc
                                                                        from zstpara
                                                                     where zstpara_mapa_id='ESC_SHAGRD'
                                                                     and substr((select f_getspridenid(VL_PIDM)
                                                                                 from dual),1,2)=zstpara_param_id
                                                                                 and zstpara_param_valor=smrprle_levl_code)
                                   and  shrgrde_code=shrtckg_grde_code_final
                                   and  decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final)) in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final)))
                                                                                                                                    from shrtckn ww, shrtckg zz
                                                                                                                                    where w.shrtckn_pidm=ww.shrtckn_pidm
                                                                                                                                    and w.shrtckn_subj_code=ww.shrtckn_subj_code
                                                                                                                                    and w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                                                                                                                    and ww.shrtckn_pidm=zz.shrtckg_pidm
                                                                                                                                    and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no
                                                                                                                                    and ww.shrtckn_term_code=zz.shrtckg_term_code)
                                   and SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR
                                                                                       from ZSTPARA
                                                                                      where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                      and shrtckn_pidm in (select spriden_pidm
                                                                                                            from spriden
                                                                                                           where spriden_id=ZSTPARA_PARAM_ID))
                                                        union
                                                        select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                               shrtrce_grde_code  CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                          from shrtrce
                                                         where shrtrce_pidm=VL_PIDM
                                                           and SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401')
                                                        union
                                                         select SHRTRTK_SUBJ_CODE_INST subj, SHRTRTK_CRSE_NUMB_INST code,'0' CALIF, 'EQ'  ST_MAT, trunc(SHRTRTK_ACTIVITY_DATE) fecha
                                                           from  SHRTRTK
                                                          where  SHRTRTK_PIDM=VL_PIDM
                                                        union
                                                         select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                           from sfrstcr, smrprle, ssbsect
                                                          where smrprle_program=prog
                                                            and sfrstcr_pidm=VL_PIDM
                                                            and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                            and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                            )
                                                            and ssbsect_term_code=sfrstcr_term_code
                                                            and ssbsect_crn=sfrstcr_crn
                                                        union
                                                         select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                           ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)/*+120*/  fecha
                                                           from sfrstcr, smrprle, ssbsect, shrgrde
                                                          where smrprle_program=prog
                                                           and  sfrstcr_pidm=VL_PIDM
                                                           and sfrstcr_grde_code is not null
                                                           and  sfrstcr_pidm not in (select shrtckn_pidm
                                                                                      from shrtckn
                                                                                     where sfrstcr_term_code=shrtckn_term_code
                                                                                     and shrtckn_crn=sfrstcr_crn)
                                                           and  SFRSTCR_RSTS_CODE!='DD'  --- agregado
                                                           and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401')
                                                           and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR
                                                                                                                from ZSTPARA
                                                                                                              where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                and sfrstcr_pidm in (select spriden_pidm
                                                                                                                                        from spriden
                                                                                                                                     where spriden_id=ZSTPARA_PARAM_ID))
                                                           and  ssbsect_term_code=sfrstcr_term_code
                                                           and  ssbsect_crn=sfrstcr_crn
                                                           and  shrgrde_levl_code=smrprle_levl_code
                 /* cambio escalas para prod */            and shrgrde_term_code_effective=(select zstpara_param_desc
                                                                                             from zstpara
                                                                                            where zstpara_mapa_id='ESC_SHAGRD'
                                                                                            and substr((select f_getspridenid(VL_PIDM) from dual),1,2)=zstpara_param_id
                                                                                            and zstpara_param_valor=smrprle_levl_code)
                                                           and  shrgrde_code=sfrstcr_grde_code
                                           ) k
                                          where   1= 1
                                           and   so.pidm= VL_PIDM
                                           and   so.programa = prog
                                           and    smrpaap_program= prog
                                           AND    smrpaap_term_code_eff = so.CTLG
                                           and    smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                           and    SMBAGEN_ACTIVE_IND='Y'           --solo areas activas  OLC
                                           and    SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF   --solo areas activas  OLC
                                           and    smrpaap_area=smrarul_area
                                           and    smrpaap_program = so.programa
                                           and    sztdtec_program=so.programa
                                           and    sztdtec_status='ACTIVO'
                                           and    SZTDTEC_CAMP_CODE=so.campus  --- **** nuevo CAPP ****
                                           and    SZTDTEC_TERM_CODE = so.CTLG
                                           and    SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
                                           and    stvstst_code=so.estatus
                                           and    smralib_area=smrpaap_area
                                           AND    smracaa_area = smrarul_area
                                           AND    smracaa_rule = smrarul_key_rule
                                           and    SMRACAA_TERM_CODE_EFF = so.CTLG
                                           and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401')
                                           and    ((smrarul_area not in (select smriecc_area from smriecc)
                                                    and smrarul_area not in (select smriemj_area from smriemj)) or
                                                       (smrarul_area in (select smriemj_area
                                                            from smriemj
                                                             where smriemj_majr_code= ( select distinct ss.SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                    where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                      and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                      and   cu.sorlcur_pidm=VL_PIDM
                                                                                                      and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                      and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                      and   cu.SORLCUR_SEQNO in (select max(ss.SORLCUR_SEQNO)
                                                                                                                                    from sorlcur ss
                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                    and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                    and ss.sorlcur_program = prog
                                                                                                                                    )
                                                                                                        and   cu.SORLCUR_TERM_CODE in (select max(ss.SORLCUR_TERM_CODE)
                                                                                                                                        from sorlcur ss
                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                         and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                         and ss.sorlcur_program = prog
                                                                                                                                         )
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                        and   sorlcur_program   = prog
                                                                                                   )    )
                                                           and smrarul_area not in (select smriecc_area from smriecc)) or
                                                             (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                 ( select distinct SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                        and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO)
                                                                                                                                    from sorlcur ss
                                                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                    and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                    and ss.sorlcur_program =prog
                                                                                                                                    )
                                                                                                        and   cu.sorlcur_pidm=VL_PIDM
                                                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                        and   sorlcur_program   = prog
                                                                                                         ))))
                                           and k.subj=smrarul_subj_code
                                           and k.code=smrarul_crse_numb_low
                                           and scrsyln_subj_code=smrarul_subj_code
                                           and scrsyln_crse_numb=smrarul_crse_numb_low
                                           and zstpara_mapa_id(+)='MAESTRIAS_BIM'
                                           and zstpara_param_id(+)=so.programa
                                           and zstpara_param_desc(+)= so.CTLG
                                         union
                                         select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                                            case
                                                    when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                                    when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                                   else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                                            end  per,
                                            smrpaap_area area,
                                            case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                               case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                     when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                     when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                     when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                     when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                     when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                     when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                     else smralib_area_desc
                                               end
                                            else
                                                smralib_area_desc
                                            end nombre_area,
                                            smrarul_subj_code||smrarul_crse_numb_low materia,
                                            scrsyln_long_course_title nombre_mat,
                                            null calif,
                                            'PC',
                                            smracaa_rule regla,
                                            null origen,
                                            null fecha,
                                            so.PIDM,
                                            'PRONO' Usuario
                                            from smrpaap, TZTPROGM so,SZTDTEC, smrarul, smracaa, smralib, stvstst, scrsyln, zstpara,smbagen
                                             where 1= 1
                                             and   so.pidm = VL_PIDM
                                             and   smrpaap_program= prog
                                             AND   smrpaap_term_code_eff = so.CTLG
                                             and   smrpaap_area=SMBAGEN_AREA
                                             and   SMBAGEN_ACTIVE_IND='Y'
                                             and   SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                             and   smrpaap_area=smrarul_area
                                             and   smrpaap_program = so.programa
                                             and   sztdtec_program = so.programa
                                             and   sztdtec_status='ACTIVO'
                                             and  SZTDTEC_CAMP_CODE=so.campus
                                             and   SZTDTEC_TERM_CODE= so.ctlg
                                             and   stvstst_code=so.estatus
                                             and   smralib_area=smrpaap_area
                                             AND   smracaa_area = smrarul_area
                                             AND   smracaa_rule = smrarul_key_rule
                                             AND   SMRARUL_TERM_CODE_EFF = so.CTLG
                                             and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001')
                                             and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR
                                                                                                    from ZSTPARA
                                                                                                    where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                    and VL_PIDM in (select spriden_pidm
                                                                                                                           from spriden
                                                                                                                           where spriden_id=ZSTPARA_PARAM_ID))
                                             and   ((smrarul_area not in (select smriecc_area
                                                                            from smriecc)
                                                                            and smrarul_area not in (select smriemj_area from smriemj))
                                                                            or (smrarul_area in (select smriemj_area
                                                                                                from smriemj
                                                                                                where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                            from sorlcur cu, sorlfos ss
                                                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                            and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                            and cu.sorlcur_pidm=VL_PIDM
                                                                                                                            and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                            and SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                            and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO)
                                                                                                                                                      from sorlcur ss
                                                                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                    and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                    and ss.sorlcur_program =prog
                                                                                                                                                    )
                                                                                                                            and cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE)
                                                                                                                                                          from sorlcur ss
                                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                        and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                        and ss.sorlcur_program = prog
                                                                                                                                                        )
                                                                                                                            and  cu.SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                            and  cu.sorlcur_program = prog
                                                                                                                         ))
                                               and smrarul_area not in (select smriecc_area
                                                                        from smriecc)) or
                                                  (smrarul_area in (select smriecc_area
                                                                     from smriecc
                                                                     where smriecc_majr_code_conc in( select distinct SORLFOS_MAJR_CODE
                                                                                                       from sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                      and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                      and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO)
                                                                                                                                from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program = prog
                                                                                                                                   )
                                                                                                      and cu.sorlcur_pidm = VL_PIDM
                                                                                                      and cu.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                      and ss.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                      and cu.SORLCUR_CACT_CODE = SORLFOS_CACT_CODE
                                                                                                      and cu.sorlcur_program   = prog
                                                                                                   ))))
                                                       and  scrsyln_subj_code=smrarul_subj_code
                                                       and  scrsyln_crse_numb=smrarul_crse_numb_low
                                                       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTCKN_SUBJ_CODE,SHRTCKN_CRSE_NUMB  from shrtckn where shrtckn_pidm=VL_PIDM )
                                                       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRCE_SUBJ_CODE,SHRTRCE_CRSE_NUMB  from SHRTRCE where SHRTRCE_pidm=VL_PIDM )     --agregado
                                                       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRTK_SUBJ_CODE_INST,SHRTRTK_CRSE_NUMB_INST  from SHRTRTK where SHRTRTK_pidm=VL_PIDM )  --agregado
                                                       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select ssbsect_subj_code subj, ssbsect_crse_numb code  from  sfrstcr, smrprle, ssbsect  --agregado para materias EC y aprobadas sin rolar
                                                                                                               where  smrprle_program = prog
                                                                                                                 and  sfrstcr_pidm=VL_PIDM
                                                                                                                 and (sfrstcr_grde_code is null or sfrstcr_grde_code is not null)
                                                                                                                 and sfrstcr_rsts_code='RE'
                                                                                                                 and  ssbsect_term_code=sfrstcr_term_code
                                                                                                                 and  ssbsect_crn=sfrstcr_crn)
                                                       and zstpara_mapa_id(+)='MAESTRIAS_BIM'
                                                       and zstpara_param_id(+)= so.programa
                                                       and zstpara_param_desc(+)=so.CTLG;



                                        commit;



                                  open avance_n_out_prono
                                    FOR
                                     select  spriden_id matricula, spriden_first_name||' '||replace(spriden_last_name,'/',' ') nombre , sztdtec_programa_comp programa, stvstst_desc estatus,
                                              avance1.per, avance1.area,
                                              case when substr(spriden_id,1,2)='08' then ' '
                                              else
                                                  case when substr(avance1.materia,1,4)='L1HB' then 'MATERIAS INTRODUCTORIAS'
                                                        when substr(avance1.materia,1,4)='M1HB' then 'MATERIAS INTRODUCTORIAS'
                                                  else upper(avance1.nombre_area)
                                                  end
                                              end   "nombre_area",avance1.materia, avance1.nombre_mat,
                                               avance1.calif, avance1.ord,
                                             case when avance1.apr='AP' then null
                                                 else apr
                                                 end tipo,
                                                 case when sztdtec_incorporante='SEGEM' then null
                                                 else n_area
                                                 end n_area,
                                             case when avance1.per < 7 then 1
                                                   else 2
                                             end hoja,
                                           ----------------------------------------
                                           CASE  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                               where SMBPGEN_program=prog
                                                                                   and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                               where s.sorlcur_pidm=VL_PIDM
                                                                                                                 and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                 and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                         where ss.sorlcur_pidm=VL_PIDM
                                                                                                                                           and ss.sorlcur_program=prog
                                                                                                                                           and ss.sorlcur_lmod_code='LEARNER'))) ='40' then
                                                                                                                                                                 (select count(unique materia)  from avance_n x
                                                                                                                                                                   where  apr in ('AP','EQ')
                                                                                                                                                                     and    protocolo=9999
                                                                                                                                                                     and    pidm_alu=VL_PIDM
                                                                                                                                                                     and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                                                                                                                                     and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                             where x.materia=xx.materia
                                                                                                                                                                                               and x.protocolo=xx.protocolo
                                                                                                                                                                                               and x.pidm_alu=xx.pidm_alu)
                                                                                                                                                                                               and CALIF!=0
                                                            and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )              )

                                                          when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                               where SMBPGEN_program=prog
                                                                                   and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                                                         where  s.sorlcur_pidm=VL_PIDM
                                                                                                                                              and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                              and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                      where ss.sorlcur_pidm=VL_PIDM
                                                                                                                                                                        and ss.sorlcur_program=prog
                                                                                                                                                                        and ss.sorlcur_lmod_code='LEARNER'))) ='42' then
                                                                                                                                                                                       (select count(unique materia)  from avance_n x
                                                                                                                                                                                         where  apr in ('AP','EQ')
                                                                                                                                                                                           and  protocolo=9999
                                                                                                                                                                                           and  pidm_alu=VL_PIDM
                                                                                                                                                                                           and  area not in  ((select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' ) )
                                                                                                                                                                                           and  calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                                            where x.materia=xx.materia
                                                                                                                                                                                                              and x.protocolo=xx.protocolo
                                                                                                                                                                                                              and x.pidm_alu=xx.pidm_alu)
                                                                                                                                                                                                              and CALIF!=0
                                                            and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )              )
                                                    ELSE
                                                          (select count(unique materia)  from avance_n x
                                                             where  apr in ('AP','EQ')
                                                             and    protocolo=9999
                                                             and    pidm_alu=VL_PIDM
                                                             and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                             and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                    where x.materia=xx.materia
                                                                                    and   x.protocolo=xx.protocolo
                                                                                    and   x.pidm_alu=xx.pidm_alu)
                                                                                    and CALIF!=0
                                                             and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )              )
                                              end  aprobadas_curr,
                                           ---------------------------
                                             (select count(unique materia)  from avance_n x
                                             where  apr in ('NA')
                                             and    protocolo=9999
                                             and    pidm_alu=VL_PIDM
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and    materia not in (select materia from avance_n xx
                                                                       where x.materia=xx.materia
                                                                        and  x.protocolo=xx.protocolo
                                                                        and  x.pidm_alu=xx.pidm_alu
                                                                        and  xx.apr='EC')
                                             and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu)) no_aprobadas_curr,
                                             (select count(unique materia) from avance_n x
                                             where  apr in ('EC')
                                             and    protocolo=9999
                                             and    pidm_alu=VL_PIDM
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                                          ) curso_curr,
                                                 (select count(unique materia)  from avance_n x
                                                             where apr in ('PC')
                                                             and    protocolo=9999
                                                             and    pidm_alu=VL_PIDM
                                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                             and materia not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB' and ZSTPARA_PARAM_VALOR=materia and
                                                                   pidm_alu in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                   ) por_cursar_curr,
                                          (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                          where  sorlcur_pidm=VL_PIDM
                                                                                            and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                            and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                    where ss.sorlcur_pidm=VL_PIDM
                                                                                                                     and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))) total_curr,
                                               case when
                                                      round ((select count(unique materia) from avance_n x
                                                     where  apr in ('AP','EQ')
                                                     and    protocolo=9999
                                                     and    pidm_alu=VL_PIDM
                                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                     and     calif not in ('NP','AC')
                                                     and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            and CALIF!=0) or calif is null)
                                                              and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )
                                                                            ) *100 /
                                                    (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                                where SMBPGEN_program=prog
                                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                            where  sorlcur_pidm=VL_PIDM
                                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                        where ss.sorlcur_pidm=VL_PIDM
                                                                                                                                                                           and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))>100  then 100
                                                 else
                                                    round ((select count(unique materia) from avance_n x
                                                     where  apr in ('AP','EQ')
                                                     and    protocolo=9999
                                                     and    pidm_alu=VL_PIDM
                                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                     and     calif not in ('NP','AC')
                                                     and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            and CALIF!=0) or calif is null)
                                                             and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                                      where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )
                                                                            ) *100 /
                                                    (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                                where SMBPGEN_program=prog
                                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                            where  sorlcur_pidm=VL_PIDM
                                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                     where ss.sorlcur_pidm=VL_PIDM
                                                                                                                                                                     and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))
                                               end Avance_n_curr,
                                            (select count(unique materia) from avance_n x
                                             where apr in ('AP','EQ')
                                             and    protocolo=9999
                                             and    pidm_alu=VL_PIDM
                                             and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                             and    to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu))  aprobadas_tall,
                                             (select count(unique materia) from avance_n x
                                             where apr in ('NA')
                                             and    protocolo=9999
                                              and    pidm_alu=VL_PIDM
                                             and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                             and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu)) no_aprobadas_tall,
                                             (select count(unique materia) from avance_n x
                                             where apr in ('EC')
                                             and    protocolo=9999
                                             and    pidm_alu=VL_PIDM
                                             and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                          ) curso_tall,
                                             (select count(unique materia) from avance_n x
                                             where apr in ('PC')
                                             and    protocolo=9999
                                             and    pidm_alu=VL_PIDM
                                             and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                          )  por_cursar_tall,
                                            (select count(unique materia) from avance_n x
                                             where area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                             and    protocolo=9999
                                             and    pidm_alu=VL_PIDM
                                             and    (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu) or calif is null)) total_tall
                                            from  spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
                                            (SELECT 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
                                               FROM  (
                                                                select 9999, per, area, nombre_area, materia, nombre_mat,
                                                                               case when calif='1' then cal_origen
                                                                                        when apr='EC' then null
                                                                                else calif
                                                                                end calif, apr, regla, null n_area,
                                                                               case when substr(materia,1,2)='L3' then 5
                                                                                else 1
                                                                               end ord,fecha
                                                                         from  sgbstdn y, avance_n x
                                                                           where  x.protocolo=9999
                                                                            and    sgbstdn_pidm=VL_PIDM
                                                                            and    sgbstdn_program_1=prog
                                                                            and    x.pidm_alu=VL_PIDM
                                                                            and    sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                              where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                            and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                                           and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                                  where x.materia=xx.materia
                                                                                  and  x.protocolo=xx.protocolo   ----cambio
                                                                                  and  x.pidm_alu=sgbstdn_pidm  ----cambio
                                                                                  and  x.pidm_alu=xx.pidm_alu   ---- cambio
                                                                                  ) or calif is null)
                                                                union
                                                                select distinct 9999, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                                                                case when calif='1' then cal_origen
                                                                        when apr='EC' then null
                                                                else calif
                                                                end calif, apr, regla, null n_area,
                                                                case when substr(materia,1,2)='L3' then 5
                                                                else 1
                                                                end ord, fecha
                                                                            from  sgbstdn y, avance_n x
                                                                           where   x.protocolo=9999
                                                                            and     sgbstdn_pidm=VL_PIDM
                                                                             and    x.pidm_alu=sgbstdn_pidm
                                                                            and     apr='EC'
                                                                            and     sgbstdn_program_1=prog
                                                                            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                               where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                 and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                           and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                                union
                                                                select protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                            case when calif='1' then cal_origen
                                                                                   when apr='EC' then null
                                                                            else calif
                                                                            end calif, apr, regla, stvmajr_desc n_area, 2 ord, fecha
                                                                            from  sgbstdn y, avance_n x, smriemj, stvmajr
                                                                           where   x.protocolo=9999
                                                                            and     sgbstdn_pidm=VL_PIDM
                                                                            and     x.pidm_alu=sgbstdn_pidm
                                                                            and     sgbstdn_program_1=prog
                                                                            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                               where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                                 and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                           and    area=smriemj_area
        --                                                                   and smriemj_majr_code=sgbstdn_majr_code_1   --vic
                                                                           and smriemj_majr_code= (select distinct SORLFOS_MAJR_CODE
                                                                                                    from  sorlcur cu, sorlfos ss
                                                                                                    where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                    and   cu.sorlcur_pidm=VL_PIDM
                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                                                    and   sorlcur_program   =prog
                                                                                                  )
                                                                           and    area not in (select smriecc_area from smriecc)
                                                                           and    smriemj_majr_code=stvmajr_code
                                                                           and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                                  where x.materia=xx.materia
                                                                                  and   x.protocolo=xx.protocolo
                                                                                  and   x.pidm_alu=xx.pidm_alu) or calif is null)
                                                                union
                                                                  select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                        case when calif='1' then cal_origen
                                                                                 when apr='EC' then null
                                                                         else calif
                                                                        end  calif, apr, regla, smralib_area_desc n_area, 3 ord, fecha
                                                                            from sgbstdn y, avance_n x ,smralib, smriecc a
                                                                           where  x.protocolo=9999
                                                                            and   sgbstdn_pidm=VL_PIDM
                                                                            and   x.pidm_alu=sgbstdn_pidm
                                                                            and   sgbstdn_program_1=prog
                                                                            and   sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                                                             where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                                                               and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                                                           and    area=smralib_area
                                                                           and    area=smriecc_area
        --                                                                   and    smriecc_majr_code_conc in (sgbstdn_majr_code_conc_1, sgbstdn_majr_code_conc_1_2)---modifico vic   18.04.2018
                                                                           and     smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                                                                             from  sorlcur cu, sorlfos ss
                                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
        --                                                                                                        and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
        --                                                                                                                                                         where cu.SORLCUR_PIDM=ss.sorlcur_pidm
        --                                                                                                                                                           and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
        --                                                                                                                                                           and ss.sorlcur_program =prog )
                                                                                                                and   cu.sorlcur_pidm=VL_PIDM
                                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                                                                                and   sorlcur_program   =prog
                                                                                                                 )
        --                                                                   and    smriecc_majr_code_conc=stvmajr_code
                                                                           and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                                  where x.materia=xx.materia
                                                                                  and   x.protocolo=xx.protocolo
                                                                                  and   x.pidm_alu=xx.pidm_alu) or calif is null)
        --                                                                          or calif='1')   -----------------
                                                                           and    (fecha in (select distinct fecha from avance_n xx
                                                                                  where x.materia=xx.materia
                                                                                  and   x.protocolo=xx.protocolo
                                                                                  and   x.pidm_alu=xx.pidm_alu) or fecha is null)
                                                                order by   n_area desc, per, nombre_area,regla
                                                  )
                                                GROUP BY 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
                                            )  avance1
                                            where  1= 1
                                            And   spriden_pidm = VL_PIDM
                                            And   spriden_change_ind is null
                                            and   sorlcur_pidm= spriden_pidm
                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                            and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                       and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                       and ss.sorlcur_program =prog)
                                            and     sgbstdn_pidm=VL_PIDM
                                            and     sgbstdn_program_1=prog
                                            and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn b
                                                                               where a.sgbstdn_pidm=b.sgbstdn_pidm
                                                                                 and a.sgbstdn_program_1=b.sgbstdn_program_1)
                                            and     sztdtec_program=sgbstdn_program_1
                                            and     sztdtec_status='ACTIVO'
                                            and     SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE
                                            and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                            and     sgbstdn_stst_code=stvstst_code
                                             order by  avance1.per,
                                               CASE WHEN sgbstdn_program_1 in (select ZSTPARA_PARAM_ID from ZSTPARA where ZSTPARA_MAPA_ID='PROG_ESPECIAL' and ZSTPARA_PARAM_ID=sgbstdn_program_1)  THEN
                                                     avance1.n_area||','||avance1.regla||','||avance1.materia||','||avance1.ord||','||hoja
                                                WHEN sgbstdn_program_1 not in (select ZSTPARA_PARAM_ID from ZSTPARA where ZSTPARA_MAPA_ID='PROG_ESPECIAL' and ZSTPARA_PARAM_ID=sgbstdn_program_1)  THEN
                                                     avance1.n_area||','||avance1.materia||','||avance1.regla||','||avance1.ord||','||hoja
                                               END;
            End;

   ELSIF VL_DIPLO >= 1 THEN

           BEGIN   /*DIPLOMADOS*/
                            Begin
                              delete from avance_n
                               where protocolo=9999
                               and pidm_alu=pidm;
                               commit;
                            Exception
                                When Others then
                                    null;
                            End;

                            insert into avance_n
                            select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                            case
                                when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                            end  per,  ----
                            smrpaap_area area,   ----
                                                          case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                              case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                     when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                     when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                     when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                     when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                     when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                     when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                     else smralib_area_desc
                                                               end
                                                            else smralib_area_desc
                                                            end
                                                             nombre_area,  ---
                                            smrarul_subj_code||smrarul_crse_numb_low materia, ----
                                            scrsyln_long_course_title nombre_mat, ----
                                             case when k.calif in ('NA','NP','AC') then '1'
                                                    when k.st_mat='EC' then '101'
                                             else  k.calif
                                             end calif, ---
                                             nvl(k.st_mat,'PC'),  ---
                                             smracaa_rule regla,   ---
                                             case when k.st_mat='EC' then null
                                               else k.calif
                                             end  origen,
                                             k.fecha, ---
                                             pidm ,
                                             usu_siu
                                            from smrpaap s, smrarul, sgbstdn y, sorlcur so, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
                                            (
                                                       select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                         w.shrtckn_subj_code subj, w.shrtckn_crse_numb code,
                                                         shrtckg_grde_code_final CALIF, decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, shrtckg_final_grde_chg_date fecha
                                                        from shrtckn w,shrtckg, shrgrde, smrprle
                                                        where shrtckn_pidm=pidm
                                                         and  shrtckg_pidm=w.shrtckn_pidm
                                                         and  SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                         )
                                                         and  shrtckg_tckn_seq_no=w.shrtckn_seq_no
                                                         and  shrtckg_term_code=w.shrtckn_term_code
                                                         and  smrprle_program=prog
                                                         and  shrgrde_levl_code=smrprle_levl_code  -------------------
              /* cambio escalas para prod */             and shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                                         and  shrgrde_code=shrtckg_grde_code_final
                                                         and  decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))   -- anadido para sacar la calificacion mayor  OLC
                                                                          in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))) from shrtckn ww, shrtckg zz
                                                                               where w.shrtckn_pidm=ww.shrtckn_pidm
                                                                                 and  w.shrtckn_subj_code=ww.shrtckn_subj_code  and w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                                                                 and  ww.shrtckn_pidm=zz.shrtckg_pidm and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no and ww.shrtckn_term_code=zz.shrtckg_term_code)
                                                        and   SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                            where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                              and shrtckn_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                        union
                                                        select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                               shrtrce_grde_code  CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                          from shrtrce
                                                         where shrtrce_pidm=pidm
                                                           and SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                           )
                                                        union
                                                         select SHRTRTK_SUBJ_CODE_INST subj, SHRTRTK_CRSE_NUMB_INST code,
                                                           /*nvl(SHRTRTK_GRDE_CODE_INST,0)*/  '0' CALIF, 'EQ'  ST_MAT, trunc(SHRTRTK_ACTIVITY_DATE) fecha
                                                           from  SHRTRTK
                                                          where  SHRTRTK_PIDM=pidm
                                                        union
                                                         select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                           from sfrstcr, smrprle, ssbsect, spriden
                                                          where smrprle_program=prog
                                                            and sfrstcr_pidm=pidm  and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                            and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                            )
                                                            and spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                            and ssbsect_term_code=sfrstcr_term_code
                                                            and ssbsect_crn=sfrstcr_crn
                                                        union
                                                         select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                           ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)/*+120*/  fecha
                                                           from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                                          where smrprle_program=prog
                                                           and  sfrstcr_pidm=pidm  and sfrstcr_grde_code is not null
                                                           and  sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and shrtckn_crn=sfrstcr_crn)
                                                           and  SFRSTCR_RSTS_CODE!='DD'  --- agregado
                                                           and  spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
            --                                             and   sfrstcr_term_code=fget_periodo(substr(spriden_id,1,2),sfrstcr_pidm)
                                                           and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                                           )
                                                           and  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                              where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                and sfrstcr_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                           and  ssbsect_term_code=sfrstcr_term_code
                                                           and  ssbsect_crn=sfrstcr_crn
                                                           and  shrgrde_levl_code=smrprle_levl_code   -------------------
                 /* cambio escalas para prod */            and shrgrde_term_code_effective=(select zstpara_param_desc from zstpara where zstpara_mapa_id='ESC_SHAGRD' and substr((select f_getspridenid(pidm) from dual),1,2)=zstpara_param_id and zstpara_param_valor=smrprle_levl_code)
                                                           and  shrgrde_code=sfrstcr_grde_code
                                           ) k
                                          where   spriden_pidm=pidm  and spriden_change_ind is null
                                            and   sorlcur_pidm= spriden_pidm
                                            and   SORLCUR_LMOD_CODE = 'LEARNER'
                                            and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                     where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                       and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                       and ss.sorlcur_program =prog)
                                           and    smrpaap_program=prog
                                           AND    smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                                           and    smrpaap_area=SMBAGEN_AREA   --solo areas activas  OLC
                                           and    SMBAGEN_ACTIVE_IND='Y'           --solo areas activas  OLC
                                           and    SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF   --solo areas activas  OLC
                                           and    smrpaap_area=smrarul_area
                                           and    sgbstdn_pidm=spriden_pidm
                                           and    SORLCUR_program=smrpaap_program
                                           and    sztdtec_program=SORLCUR_program and sztdtec_status='ACTIVO'  and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                           and    SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                           and    SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
                                           and    stvstst_code=sgbstdn_stst_code
                                           and    smralib_area=smrpaap_area
                                           AND    smracaa_area = smrarul_area
                                           AND    smracaa_rule = smrarul_key_rule
                                           and    SMRACAA_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG
                                           and    SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001', 'M1HB401'
                                           )
                                           and    (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                               (smrarul_area in (select smriemj_area from smriemj
                                                                       where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                    where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                      and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                      and   cu.sorlcur_pidm=pidm
                                                                                                      and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                      and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                      and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                    and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                    and ss.sorlcur_program =prog)
                                                                                                        and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                        and   sorlcur_program   =prog
                                                                                                   )    )
                                                           and smrarul_area not in (select smriecc_area from smriecc)) or
                                                             (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                 ( select distinct SORLFOS_MAJR_CODE
                                                                                                     from  sorlcur cu, sorlfos ss
                                                                                                      where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                        and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                        and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog )
                                                                                                        and   cu.sorlcur_pidm=pidm
                                                                                                        and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                        and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                        and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                        and   sorlcur_program   =prog
                                                                                                         ) )) )
                                           and    k.subj=smrarul_subj_code and k.code=smrarul_crse_numb_low
                                           and    scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                           and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=SORLCUR_program and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG --sgbstdn_term_code_ctlg_1
                                         union
                                         select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/  9999,
                                            case
                                                    when smralib_area_desc like 'Servicio%' then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                                    when (smralib_area_desc like ('Taller%') OR smralib_area_desc like ('CERTIFICATION%')) then TO_NUMBER (SUBSTR (smralib_area,9,2))+1
                                                   else TO_NUMBER (SUBSTR (smrarul_area, 9, 2))
                                            end  per,  ---
                                            smrpaap_area area, ---
                                                                      case when smrpaap_area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES') then
                                                                          case when substr(smrpaap_area,9,2) in ('01','03') then substr(smrpaap_area,10,1)||'er. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                                 when substr(smrpaap_area,9,2) in ('02') then substr(smrpaap_area,10,1)||'do. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                                 when substr(smrpaap_area,9,2) in ('04','05','06') then substr(smrpaap_area,10,1)||'to. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                                 when substr(smrpaap_area,9,2) in ('07') then substr(smrpaap_area,10,1)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                                 when substr(smrpaap_area,9,2) in ('08') then substr(smrpaap_area,10,1)||'vo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                                 when substr(smrpaap_area,9,2) in ('09') then substr(smrpaap_area,10,1)||'no. '|| nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                                 when substr(smrpaap_area,9,2) in ('10') then substr(smrpaap_area,9,2)||'mo. '||nvl(zstpara_param_valor,'CUATRIMESTRE')
                                                                                 else smralib_area_desc
                                                                           end
                                                                        else smralib_area_desc
                                                                        end   nombre_area, ---
                                                        smrarul_subj_code||smrarul_crse_numb_low materia, ---
                                                         scrsyln_long_course_title nombre_mat, ---
                                                         null calif,  ---
                                                         'PC' ,  ---
                                                         smracaa_rule regla, ---
                                                         null origen, ---
                                                         null fecha, --
                                                         pidm ,
                                                         usu_siu
                                            from spriden, smrpaap, sgbstdn y, sorlcur so,SZTDTEC, smrarul, smracaa, smralib, stvstst, scrsyln, zstpara,smbagen
                                             where    spriden_pidm=pidm  and spriden_change_ind is null
                                                       and   so.sorlcur_pidm= spriden_pidm
                                                       and   so.SORLCUR_LMOD_CODE = 'LEARNER'
        --                                               and   so.SORLCUR_CACT_CODE='ACTIVE'
                                                       and   so.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                  and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                  and   ss.SORLCUR_LMOD_CODE = 'LEARNER'
        --                                                                          and   ss.SORLCUR_CACT_CODE='ACTIVE'
                                                                                  and ss.sorlcur_program =prog)
                                                       and   smrpaap_program=prog
                                                       AND   smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                                                       and   smrpaap_area=SMBAGEN_AREA
                                                       and   SMBAGEN_ACTIVE_IND='Y'
                                                       and   SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                                       and   smrpaap_area=smrarul_area
                                                       and   sgbstdn_pidm=spriden_pidm
                                                       and   so.SORLCUR_program=smrpaap_program
                                                       and   sztdtec_program=so.SORLCUR_program and sztdtec_status='ACTIVO' and  SZTDTEC_CAMP_CODE=so.SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                                       and   SZTDTEC_TERM_CODE=so.SORLCUR_TERM_CODE_CTLG
                                                       and   stvstst_code=sgbstdn_stst_code
                                                       and   smralib_area=smrpaap_area
                                                       AND   smracaa_area = smrarul_area
                                                       AND   smracaa_rule = smrarul_key_rule
                                                       AND   SMRARUL_TERM_CODE_EFF = so.SORLCUR_TERM_CODE_CTLG
                                                       and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001'
                                                       )
                                                       and   SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                                    and spriden_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                       and   (  (smrarul_area not in (select smriecc_area from smriecc) and smrarul_area not in (select smriemj_area from smriemj)) or
                                                             (smrarul_area in (select smriemj_area from smriemj
                                                                                where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                             from sorlcur cu, sorlfos ss
                                                                                                            where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                              and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                              and cu.sorlcur_pidm=pidm
                                                                                                              and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                              and SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                              and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                        where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                              and cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                            where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                              and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                              and   sorlcur_program   =prog
                                                                                                            )    )
                                                       and smrarul_area not in (select smriecc_area from smriecc)) or
                                                             (smrarul_area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                 ( select distinct SORLFOS_MAJR_CODE
                                                                                                     from sorlcur cu, sorlfos ss
                                                                                                    where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                      and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                      and cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program =prog )
                                                                                                      and   cu.sorlcur_pidm=pidm
                                                                                                      and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                      and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                      and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                      and   sorlcur_program   =prog
                                                                                                   ) )) )
                                                       and  scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                                       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTCKN_SUBJ_CODE,SHRTCKN_CRSE_NUMB  from shrtckn where shrtckn_pidm=pidm )
                                                       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRCE_SUBJ_CODE,SHRTRCE_CRSE_NUMB  from SHRTRCE where SHRTRCE_pidm=pidm )     --agregado
                                                       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select SHRTRTK_SUBJ_CODE_INST,SHRTRTK_CRSE_NUMB_INST  from SHRTRTK where SHRTRTK_pidm=pidm )  --agregado
                                                       and (SMRARUL_SUBJ_CODE, SMRARUL_CRSE_NUMB_LOW) not in (select ssbsect_subj_code subj, ssbsect_crse_numb code  from  sfrstcr, smrprle, ssbsect, spriden  --agregado para materias EC y aprobadas sin rolar
                                                                                                               where  smrprle_program=prog
                                                                                                                 and  sfrstcr_pidm=pidm  and (sfrstcr_grde_code is null or sfrstcr_grde_code is not null)  and sfrstcr_rsts_code='RE'
                                                                                                                 and  spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                                                                                 and  ssbsect_term_code=sfrstcr_term_code
                                                                                                                 and  ssbsect_crn=sfrstcr_crn)
                                                       and    zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=SORLCUR_program and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG;

                                         commit;


                                  open avance_n_out_prono
                                    FOR
                                     select  spriden_id matricula, spriden_first_name||' '||replace(spriden_last_name,'/',' ') nombre ,  sztdtec_programa_comp programa, stvstst_desc estatus,
                                              avance1.per, avance1.area,
                                              case when substr(spriden_id,1,2)='08' then ' '
                                              else
                                                  case when substr(avance1.materia,1,4)='L1HB' then 'MATERIAS INTRODUCTORIAS'
                                                        when substr(avance1.materia,1,4)='M1HB' then 'MATERIAS INTRODUCTORIAS'
                                                  else upper(avance1.nombre_area)
                                                  end
                                              end   "nombre_area",avance1.materia, avance1.nombre_mat,
                                               avance1.calif, avance1.ord,
                                             case when avance1.apr='AP' then null
                                                 else apr
                                                 end tipo,
                                                 case when sztdtec_incorporante='SEGEM' then null
                                                 else n_area
                                                 end n_area,
                                             case when avance1.per < 7 then 1
                                                   else 2
                                             end hoja,
                                           ----------------------------------------
                                           CASE  when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                               where SMBPGEN_program=prog
                                                                                   and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                               where s.sorlcur_pidm=pidm
                                                                                                                 and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                 and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                         where ss.sorlcur_pidm=pidm
                                                                                                                                           and ss.sorlcur_program=prog
                                                                                                                                           and ss.sorlcur_lmod_code='LEARNER'))) ='40' then
                                                                                                                                                                 (select count(unique materia)  from avance_n x
                                                                                                                                                                   where  apr in ('AP','EQ')
                                                                                                                                                                     and    protocolo=9999
                                                                                                                                                                     and    pidm_alu=pidm

                                                                                                                                                                     and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                                                                                                                                     and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                             where x.materia=xx.materia
                                                                                                                                                                                               and x.protocolo=xx.protocolo
                                                                                                                                                                                               and x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                               )
                                                                                                                                                                                               and CALIF!=0
                                                            and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )              )

                                                          when  (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN
                                                                               where SMBPGEN_program=prog
                                                                                   and SMBPGEN_TERM_CODE_EFF=(select distinct SORLCUR_TERM_CODE_CTLG from sorlcur s
                                                                                                                                         where  s.sorlcur_pidm=pidm
                                                                                                                                              and s.sorlcur_program=prog and s.sorlcur_lmod_code='LEARNER'
                                                                                                                                              and s.SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                      where ss.sorlcur_pidm=pidm
                                                                                                                                                                        and ss.sorlcur_program=prog
                                                                                                                                                                        and ss.sorlcur_lmod_code='LEARNER'))) ='42' then
                                                                                                                                                                                       (select count(unique materia)  from avance_n x
                                                                                                                                                                                         where  apr in ('AP','EQ')
                                                                                                                                                                                           and  protocolo=9999
                                                                                                                                                                                           and  pidm_alu=pidm
                                                                                                                                                                                           and  area not in  ((select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' ) )
                                                                                                                                                                                           and  calif  in (select max(to_number(calif)) from avance_n xx
                                                                                                                                                                                                            where x.materia=xx.materia
                                                                                                                                                                                                              and x.protocolo=xx.protocolo
                                                                                                                                                                                                              and x.pidm_alu=xx.pidm_alu
                                                                                                                                                                                                              )
                                                                                                                                                                                                              and CALIF!=0
                                                            and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )              )
                                                    ELSE
                                                          (select count(unique materia)  from avance_n x
                                                             where  apr in ('AP','EQ')
                                                             and    protocolo=9999
                                                             and    pidm_alu=pidm
                                                             and    area not in  (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                             and     calif  in (select max(to_number(calif)) from avance_n xx
                                                                                    where x.materia=xx.materia
                                                                                    and   x.protocolo=xx.protocolo
                                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                                    )
                                                                                    and CALIF!=0
                                                             and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )              )
                                              end  aprobadas_curr,
                                           ---------------------------
                                             (select count(unique materia)  from avance_n x
                                             where  apr in ('NA')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                             and    materia not in (select materia from avance_n xx
                                                                       where x.materia=xx.materia
                                                                        and  x.protocolo=xx.protocolo
                                                                        and  x.pidm_alu=xx.pidm_alu
                                                                        and  xx.apr='EC')
                                             and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            )) no_aprobadas_curr,
                                             (select count(unique materia) from avance_n x
                                             where  apr in ('EC')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                                          ) curso_curr,
                                                 (select count(unique materia)  from avance_n x
                                                             where apr in ('PC')
                                                             and    protocolo=9999
                                                             and    pidm_alu=pidm
                                                             and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                                             and materia not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB' and ZSTPARA_PARAM_VALOR=materia and
                                                                   pidm_alu in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                   ) por_cursar_curr,
                                          (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                        where SMBPGEN_program=prog
                                                            and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                          where  sorlcur_pidm=pidm
                                                                                            and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                            and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                    where ss.sorlcur_pidm=pidm
                                                                                                                     and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))) total_curr,
                                               case when
                                                      round ((select count(unique materia) from avance_n x
                                                     where  apr in ('AP','EQ')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                     and     calif not in ('NP','AC')
                                                     and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            and CALIF!=0) or calif is null)
                                                              and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                                  where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )
                                                                            ) *100 /
                                                    (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                                where SMBPGEN_program=prog
                                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                            where  sorlcur_pidm=pidm
                                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                        where ss.sorlcur_pidm=pidm
                                                                                                                                                                           and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))>100  then 100
                                                 else
                                                    round ((select count(unique materia) from avance_n x
                                                     where  apr in ('AP','EQ')
                                                     and    protocolo=9999
                                                     and    pidm_alu=pidm
                                                     and    area not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)<>'TT' )
                                                     and     calif not in ('NP','AC')
                                                     and     (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                            where x.materia=xx.materia
                                                                            and   x.protocolo=xx.protocolo
                                                                            and   x.pidm_alu=xx.pidm_alu
                                                                            and CALIF!=0) or calif is null)
                                                             and     (  (area not in (select smriecc_area from smriecc) and area not in (select smriemj_area from smriemj)) or   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                           (area in (select smriemj_area from smriemj
                                                                                                   where smriemj_majr_code= ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                                      where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                                          and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                                          and ss.sorlcur_program =prog)
                                                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                           where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                              and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                              and ss.sorlcur_program =prog)
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                               )    )
                                                              and area not in (select smriecc_area from smriecc)) or                   -- VALIDA LA EXITENCIA EN SMAALIB
                                                                                         (area in (select smriecc_area from smriecc where smriecc_majr_code_conc in
                                                                                                                             ( select distinct SORLFOS_MAJR_CODE
                                                                                                                                 from  sorlcur cu, sorlfos ss
                                                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                 where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                                                   and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                                                   and ss.sorlcur_program =prog )
                                                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                                    and   SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                    and   sorlcur_program   =prog
                                                                                                                                     ) )) )
                                                                            ) *100 /
                                                    (select  distinct SMBPGEN_REQ_COURSES_I_TRAD  from SMBPGEN    -- CAMBIO DE  MODO DE EXTRAER EL TOTAL DE MATERIAS DE  SMA'UTLLIATFED'
                                                                where SMBPGEN_program=prog
                                                                    and SMBPGEN_TERM_CODE_EFF = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur
                                                                                                                            where  sorlcur_pidm=pidm
                                                                                                                               and sorlcur_program=prog and sorlcur_lmod_code='LEARNER'
                                                                                                                               and SORLCUR_SEQNO = (select max(ss.SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                                                     where ss.sorlcur_pidm=pidm
                                                                                                                                                                     and ss.sorlcur_program=prog and ss.sorlcur_lmod_code='LEARNER'))))
                                               end Avance_n_curr,
                                            (select count(unique materia) from avance_n x
                                             where apr in ('AP','EQ')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES')
                                             and    to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    ))  aprobadas_tall,
                                             (select count(unique materia) from avance_n x
                                             where apr in ('NA')
                                             and    protocolo=9999
                                              and    pidm_alu=pidm
                                             and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                             and     to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu
                                                                    )) no_aprobadas_tall,
                                             (select count(unique materia) from avance_n x
                                             where apr in ('EC')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                          ) curso_tall,
                                             (select count(unique materia) from avance_n x
                                             where apr in ('PC')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                                                          )  por_cursar_tall,
                                            (select count(unique materia) from avance_n x
                                             where area in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='ORDEN_CUATRIMES' and substr(ZSTPARA_PARAM_VALOR,5,2)='TT')
                                             and    protocolo=9999
                                             and    pidm_alu=pidm
                                             and    (to_number(calif)  in (select max(to_number(calif)) from avance_n xx
                                                                    where x.materia=xx.materia
                                                                    and   x.protocolo=xx.protocolo
                                                                    and   x.pidm_alu=xx.pidm_alu) or calif is null)) total_tall
                                            from spriden, sztdtec, sorlcur so, sgbstdn a, stvstst,
                                            (SELECT 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area, ord, MAX(fecha)
                                               FROM  (
                                                                select 9999, per, area, nombre_area, materia, nombre_mat,
                                                                               case when calif='1' then cal_origen
                                                                                        when apr='EC' then null
                                                                                else calif
                                                                                end calif, apr, regla, null n_area,
                                                                               case when substr(materia,1,2)='L3' then 5
                                                                                else 1
                                                                               end ord,fecha
                                                                         from  avance_n x,sorlcur co
                                                                           where  x.protocolo=9999
                                                                            and    co.sorlcur_pidm=pidm
                                                                            and    co.sorlcur_program=prog
                                                                            and    x.pidm_alu=pidm
                                                                            and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                                            and    (to_number(calif) in (select max(to_number(calif))
                                                                                                            from avance_n xx
                                                                                                          where x.materia=xx.materia
                                                                                                          and  x.protocolo=xx.protocolo   ----cambio
                                                                                                          and  x.pidm_alu=co.sorlcur_program  ----cambio
                                                                                                          and  x.pidm_alu=xx.pidm_alu   ---- cambio
                                                                                                          ) or calif is null)
                                                                union
                                                                select distinct 9999, per, area, nombre_area, materia, nombre_mat,    --extraordinarios en curso por aplicarse OLC
                                                                case when calif='1' then cal_origen
                                                                        when apr='EC' then null
                                                                else calif
                                                                end calif, apr, regla, null n_area,
                                                                case when substr(materia,1,2)='L3' then 5
                                                                else 1
                                                                end ord, fecha
                                                                            from  avance_n x,sorlcur co
                                                                           where   x.protocolo=9999
                                                                            and    x.pidm_alu=co.sorlcur_pidm
                                                                            and    co.sorlcur_pidm=pidm
                                                                            and     apr='EC'
                                                                            and     co.sorlcur_program=prog
                                                                           and     area not in (select smriecc_area from smriecc) and   area not in (select smriemj_area from smriemj)
                                                                union
                                                                select protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                            case when calif='1' then cal_origen
                                                                                   when apr='EC' then null
                                                                            else calif
                                                                            end calif, apr, regla, stvmajr_desc n_area, 2 ord, fecha
                                                                            from  avance_n x, smriemj, stvmajr,sorlcur co
                                                                           where   x.protocolo=9999
                                                                            and     x.pidm_alu=co.sorlcur_pidm
                                                                            and     co.sorlcur_pidm=pidm
                                                                            and     co.SORLCUR_PROGRAM=prog
                                                                            and    area=smriemj_area
                                                                            and smriemj_majr_code= (select distinct SORLFOS_MAJR_CODE
                                                                                                    from  sorlcur cu, sorlfos ss
                                                                                                    where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                    and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                    and   cu.sorlcur_pidm=pidm
                                                                                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                    and   SORLFOS_LFST_CODE = 'MAJOR'
                                                                                                    and   cu.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                                                                                                where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                  and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                  and ss.sorlcur_program =prog)
                                                                                                    and   cu.SORLCUR_TERM_CODE in (select max(SORLCUR_TERM_CODE) from sorlcur ss
                                                                                                                                    where cu.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                                                                                      and cu.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                                      and ss.sorlcur_program =prog)
                                                                                                    and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE  --  modifica olc 19.06.2018 cuplicidad
                                                                                                    and   sorlcur_program   =prog
                                                                                                  )
                                                                           and    area not in (select smriecc_area from smriecc)
                                                                           and    smriemj_majr_code=stvmajr_code
                                                                           and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                                  where x.materia=xx.materia
                                                                                  and   x.protocolo=xx.protocolo
                                                                                  and   x.pidm_alu=xx.pidm_alu)
                                                                                   or calif is null)
                                                                union
                                                                  select distinct protocolo, per, area, nombre_area, materia, nombre_mat,
                                                                        case when calif='1' then cal_origen
                                                                                 when apr='EC' then null
                                                                         else calif
                                                                        end  calif, apr, regla, smralib_area_desc n_area, 3 ord, fecha
                                                                            from avance_n x ,smralib, smriecc a,sorlcur co
                                                                           where  x.protocolo=9999
                                                                            and   co.sorlcur_pidm=pidm
                                                                            and   x.pidm_alu=co.sorlcur_pidm
                                                                            and   co.SORLCUR_PROGRAM=prog
                                                                           and    area=smralib_area
                                                                           and    area=smriecc_area
                                                                           and     smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE
                                                                                                             from  sorlcur cu, sorlfos ss
                                                                                                              where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                                and   cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                                and   cu.sorlcur_pidm=pidm
                                                                                                                and   SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                                and   SORLFOS_LFST_CODE = 'CONCENTRATION'--CONCENTRATION
                                                                                                                and  SORLCUR_CACT_CODE=SORLFOS_CACT_CODE --  modifica olc 19.06.2018 duplicidad
                                                                                                                and   sorlcur_program   =prog
                                                                                                                 )
                                                                           and    (to_number(calif) in (select max(to_number(calif)) from avance_n xx
                                                                                  where x.materia=xx.materia
                                                                                  and   x.protocolo=xx.protocolo
                                                                                  and   x.pidm_alu=xx.pidm_alu)
                                                                                  or calif is null)
                                                                           and    (fecha in (select distinct fecha from avance_n xx
                                                                                  where x.materia=xx.materia
                                                                                  and   x.protocolo=xx.protocolo
                                                                                  and   x.pidm_alu=xx.pidm_alu)
                                                                                   or fecha is null)
                                                                order by   n_area desc, per, nombre_area,regla
                                                  )
                                                GROUP BY 9999, per, area, nombre_area, materia, nombre_mat, calif, apr, regla,  n_area,ord
                                            )  avance1
                                            where  spriden_pidm=pidm
                                            and   so.sorlcur_pidm= spriden_pidm
                                            and   so.SORLCUR_LMOD_CODE = 'LEARNER'
                                            and   so.SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                                       and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                         and  ss.SORLCUR_LMOD_CODE = 'LEARNER'
                                                                       and ss.sorlcur_program =prog)
                                            and     spriden_change_ind is null
                                            and     sgbstdn_pidm=spriden_pidm
                                            and     so.SORLCUR_PROGRAM=prog
                                            and     sztdtec_program=so.SORLCUR_PROGRAM
                                            and     sztdtec_status='ACTIVO'
                                            and     SZTDTEC_CAMP_CODE=so.SORLCUR_CAMP_CODE
                                            and     SZTDTEC_TERM_CODE=so.SORLCUR_TERM_CODE_CTLG --SGBSTDN_TERM_CODE_CTLG_1
                                            and     sgbstdn_stst_code=stvstst_code
                                             order by  avance1.per,
                                               CASE WHEN so.SORLCUR_PROGRAM in (select ZSTPARA_PARAM_ID from ZSTPARA where ZSTPARA_MAPA_ID='PROG_ESPECIAL' and ZSTPARA_PARAM_ID=so.sorlcur_program)  THEN
                                                     avance1.n_area||','||avance1.regla||','||avance1.materia||','||avance1.ord||','||hoja
                                                WHEN so.sorlcur_program not in (select ZSTPARA_PARAM_ID from ZSTPARA where ZSTPARA_MAPA_ID='PROG_ESPECIAL' and ZSTPARA_PARAM_ID=so.sorlcur_program)  THEN
                                                     avance1.n_area||','||avance1.materia||','||avance1.regla||','||avance1.ord||','||hoja
                                               END;

           END;




   End if;



 RETURN (avance_n_out_prono);


END f_dashboard_avcu_out_prono;

-- OMS 29/Agosto/2023
-- Ajuste el la obtención de los valores FUTUROS (Clausula GROUP BY)
-- Start:

 FUNCTION f_cargos_ucamp_out (p_pidm in number ) RETURN PKG_DASHBOARD_DOCENTES.ucamp_out
           AS
                camp_out PKG_DASHBOARD_DOCENTES.ucamp_out;

                       BEGIN
                          open camp_out
                                        FOR
                                    With saldo as (
                                            Select nvl (sum(TBRACCD_BALANCE),0) Saldo, tbraccd_pidm
                                            from tbraccd
                                            join TZTNCD  on TZTNCD_CODE = tbraccd_detail_code
                                                And TZTNCD_CONCEPTO IN ('Venta')
                                            group by tbraccd_pidm
                                            ),
                                            adeudo as (
                                            Select nvl (sum(TBRACCD_BALANCE),0) Adeudo, tbraccd_pidm
                                            from tbraccd
                                            join TZTNCD  on TZTNCD_CODE = tbraccd_detail_code
                                                And TZTNCD_CONCEPTO IN ('Venta')
                                            where 1=1
                                            And trunc (TBRACCD_EFFECTIVE_DATE) < TRUNC(SYSDATE, 'MM')
                                            group by tbraccd_pidm
                                            ),
                                            Vencimiento as (
                                            Select max(trunc (TBRACCD_EFFECTIVE_DATE))Vencimiento , tbraccd_pidm
                                            from tbraccd
                                            join TZTNCD  on TZTNCD_CODE = tbraccd_detail_code
                                                And TZTNCD_CONCEPTO IN ('Venta')
                                            where 1= 1
                                            And TBRACCD_BALANCE > 0
                                            And trunc (TBRACCD_EFFECTIVE_DATE) between  TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                                            group by tbraccd_pidm
                                            ),
                                            Actual as (
                                            Select nvl (sum(TBRACCD_BALANCE),0) Actual, tbraccd_pidm
                                            from tbraccd
                                            join TZTNCD  on TZTNCD_CODE = tbraccd_detail_code
                                                And TZTNCD_CONCEPTO IN ('Venta')
                                            where 1= 1
                                            And trunc (TBRACCD_EFFECTIVE_DATE) between  TRUNC(SYSDATE, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                                            group by tbraccd_pidm
                                            ),
                                            Futuro as (
                                                        Select nvl (sum(TBRACCD_BALANCE),0) futuro, tbraccd_pidm, MAX (TBRACCD_EFFECTIVE_DATE) vencimiento
                                                        -- OMS 18/Agosto/2023 nvl (sum(TBRACCD_BALANCE),0) futuro, tbraccd_pidm, TBRACCD_EFFECTIVE_DATE vencimiento
                                                        from tbraccd
                                                        join TZTNCD  on TZTNCD_CODE = tbraccd_detail_code
                                                            And TZTNCD_CONCEPTO IN ('Venta')
                                                        where 1= 1
                                                        And TBRACCD_DOCUMENT_NUMBER is not null
                                                        And trunc (TBRACCD_EFFECTIVE_DATE) > TRUNC(LAST_DAY(SYSDATE))
                                                    ---    and tbraccd_pidm = fget_pidm ('400582718')
                                                        And substr (TBRACCD_DOCUMENT_NUMBER,1,1) = '1'
                                                        group by tbraccd_pidm -- OMS 18/Agosto/2023   , TBRACCD_EFFECTIVE_DATE
                                            )
                                            Select distinct a.tbraccd_pidm Pidm,
                                                            nvl (b.saldo,0) saldo,
                                                            nvl (c.Adeudo,0) Adeudo,
                                                            (nvl (e.Actual,0)+ nvl (f.futuro,0)) Colegiatura,
                                                            (nvl(c.Adeudo,0) + nvl (e.Actual,0)+ nvl (f.futuro,0)) Monto_pagar , nvl (d.Vencimiento,f.Vencimiento) Vencimiento
                                            from tbraccd a
                                            join TZTNCD  on TZTNCD_CODE = a.tbraccd_detail_code
                                                And TZTNCD_CONCEPTO IN ('Venta')
                                            left join saldo b on b.tbraccd_pidm = a.tbraccd_pidm
                                            left join adeudo c on c.tbraccd_pidm = a.tbraccd_pidm
                                            left join Vencimiento d on d.tbraccd_pidm = a.tbraccd_pidm
                                            left join Actual e on e.tbraccd_pidm = a.tbraccd_pidm
                                            left join futuro f on f.tbraccd_pidm = a.tbraccd_pidm
                                            Where 1=1
                                            And  a.tbraccd_pidm = p_pidm;
                        RETURN (camp_out);
 END f_cargos_ucamp_out;

-- OMS 29/Agosto/2023
-- Ajuste el la obtención de los valores FUTUROS (Clausula GROUP BY)
-- End:



 Function  f_pagos_vencidos_ucamp (p_pidm in number )RETURN PKG_DASHBOARD_DOCENTES.pagos_vencidos_camp_out
    As

  pagos_vencidos_camp PKG_DASHBOARD_DOCENTES.pagos_vencidos_camp_out;
  v_error varchar2(4000);

   BEGIN
      open pagos_vencidos_camp
       FOR
            select decode (TZTNCD_CONCEPTO, 'Venta', 'COLEGIATURA', 'Nota Debito','ACCESORIOS', 'Interes' ,'INTERESES') c_tipo,
                    SUBSTR(a.TBRACCD_EFFECTIVE_DATE,4,2) mes,
                        a.TBRACCD_TERM_CODE Periodo,
                        a.TBRACCD_TRAN_NUMBER Secuencia,
                        a.TBRACCD_DETAIL_CODE Concepto,
                        c.TBBDETC_DESC Descripcion_Concepto,
                        a.TBRACCD_BALANCE Saldo_Actual_Cargo,
                        trunc (a.TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                        decode (c.TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                        a.TBRACCD_CURR_CODE MONEDA,
                        a.TBRACCD_DOCUMENT_NUMBER parcialidad
                    from tbraccd a
                    join TZTNCD b on b.TZTNCD_CODE = a.tbraccd_detail_code
                    join tbbdetc c on c.TBBDETC_DETAIL_CODE = a.tbraccd_detail_code and c.TBBDETC_TYPE_IND = 'C'
                    where 1=1
                    and a.tbraccd_pidm = p_pidm
                    and a.TBRACCD_EFFECTIVE_DATE<sysdate
                    And a.TBRACCD_BALANCE > 0
                   And b.TZTNCD_CONCEPTO in (  'Venta', 'Nota Debito', 'Interes')
                   order by 2,1 asc;
            RETURN (pagos_vencidos_camp);
   Exception when others then
           v_error:='No se encontraron pagos vencidos'||sqlerrm;
           open pagos_vencidos_camp for select null, null, null, null, null,  null, null, null, null, null, v_error from dual;
             RETURN (pagos_vencidos_camp);

   End f_pagos_vencidos_ucamp;



-- OMS 28/Agosto/2023
-- Se incluyen valores CEROS en el estado de Cuenta
-- Start:

Function  f_pagos_futuros_ucamp (p_pidm in number )RETURN PKG_DASHBOARD_DOCENTES.pagos_futuros_camp_out
As

 pagos_futuros_camp PKG_DASHBOARD_DOCENTES.pagos_futuros_camp_out;
  v_error varchar2(4000);

BEGIN
  open pagos_futuros_camp
       FOR
             select decode (TZTNCD_CONCEPTO, 'Venta', 'COLEGIATURA', 'Nota Debito','ACCESORIOS', 'Interes' ,'INTERESES') c_tipo,
                SUBSTR(a.TBRACCD_EFFECTIVE_DATE,4,2) mes,
                    a.TBRACCD_TERM_CODE Periodo,
                    a.TBRACCD_TRAN_NUMBER Secuencia,
                    a.TBRACCD_DETAIL_CODE Concepto,
                    c.TBBDETC_DESC Descripcion_Concepto,
                    a.TBRACCD_BALANCE Saldo_Actual_Cargo,
                    trunc (a.TBRACCD_EFFECTIVE_DATE) Fecha_Vencimiento,
                    decode (c.TBBDETC_TYPE_IND, 'C' ,'Cargo', 'P', 'Pago') Tipo,
                    a.TBRACCD_CURR_CODE MONEDA,
                    a.TBRACCD_DOCUMENT_NUMBER parcialidad
                from tbraccd a
                join TZTNCD b on b.TZTNCD_CODE = a.tbraccd_detail_code
                join tbbdetc c on c.TBBDETC_DETAIL_CODE = a.tbraccd_detail_code and c.TBBDETC_TYPE_IND = 'C'
                where 1=1
                and a.tbraccd_pidm = p_pidm
                and a.TBRACCD_EFFECTIVE_DATE>= sysdate
--              And a.TBRACCD_BALANCE > 0      -- OMS 24/Agosto/2023 (Se deben excluir importes en CERO
               And b.TZTNCD_CONCEPTO in (  'Venta', 'Nota Debito', 'Interes')
               order by 2,1 asc;

        RETURN (pagos_futuros_camp);
Exception when others then
       v_error:='No se encontraron pagos por vencer'||sqlerrm;
       open pagos_futuros_camp for select null, null, null, null, null, null, null, null, null, null, v_error from dual;
         RETURN (pagos_futuros_camp);

End f_pagos_futuros_ucamp;
                                       
function  f_integra_materias(p_matricula varchar2 ,p_materia varchar2, p_fecha_ini date) return varchar2
  is
 l_grupo varchar(2):='01';
 l_retorna varchar(300);   
 l_conta number;  
 L_PASSALUM VARCHAR(200);  
 l_seqno number;

begin 
  
  for d in (
   select regexp_substr(p_materia,'[^,]+', 1, level)materia,
   p_matricula matricula from dual
   connect by regexp_substr(p_materia, '[^,]+', 1, level) is not null  )
        
    loop  
      BEGIN
          dbms_output.put_line(' ENTRA 1 '||SQLERRM||D.materia||D.matricula);
       for c in ( 
              select 'MD_'||to_char(SZTMACF_FECHA_INICIO, 'ddmmyy')||'_'||SZTMACF_SUBJ Shortname,a.*
                            from sztmacf a
                            join SIRCMNT ON SIRCMNT_TEXT=SZTMACF_CAMP
                            join SPRIDEN ON SPRIDEN_pidm=SIRCMNT_PIDM  and SPRIDEN_CHANGE_IND is null
                            join SIBINST on SIBINST_pidm = SPRIDEN_pidm and SIBINST_FCST_CODE not in ('BA', 'IN') 
                            where 1=1
                            AND SPRIDEN_id= d.matricula--'019845659'
                            and SZTMACF_SUBJ=d.materia --'DOL03'
                            And trunc (SZTMACF_FECHA_INICIO) = p_fecha_ini
                            and  rownum <= 1
                            order by SZTMACF_SERIACION
                         )   
                       loop
                       
                             begin 
                                    select count(*)
                                    into l_conta
                                    from sztgpme
                                    where 1=1
                                    and SZTGPME_NO_REGLA=1
                                    and SZTGPME_SUBJ_CRSE=c.SZTMACF_SUBJ
                                    and trunc (SZTGPME_START_DATE) = C.SZTMACF_FECHA_INICIO;
                              EXCEPTION WHEN OTHERS THEN
                                 
                                  l_conta:=0;
                                 l_retorna:=l_conta||'no conto'; 
                              END;
                              
                             BEGIN  
                               select GOZTPAC_PIN
                               INTO L_PASSALUM 
                               from GOZTPAC 
                               where GOZTPAC_PIDM =FGET_PIDM(p_matricula);
                             EXCEPTION WHEN OTHERS THEN
                                  L_PASSALUM:=0; 
                                   l_retorna:=L_PASSALUM||'no pasw';       
                              END;
                              
                                begin 
                                    select  nvl(max(SZTGPME_NIVE_SEQNO),0)+1
                                    into l_seqno
                                    from sztgpme
                                    where 1=1
                                    and SZTGPME_NO_REGLA=1
                                    and SZTGPME_SUBJ_CRSE=c.SZTMACF_SUBJ;
                                         EXCEPTION WHEN OTHERS THEN
                                          l_seqno:=1;  
                                         l_retorna:=l_seqno||'no entro';      
                                      END; 

    dbms_output.put_line(' Recupara la info antes del IF '||l_seqno ||'*'||l_conta);  
                                      
                          if l_conta=0 then
                                dbms_output.put_line(' llega a Insertar en grupos '||c.Shortname);   
                                 
                         
                                         BEGIN
                                           INSERT INTO sztgpme VALUES( c.SZTMACF_SUBJ||l_grupo,--1
                                                                          c.SZTMACF_SUBJ,--2
                                                                          C.SZTMACF_SUBJDES,--3
                                                                          0,--4
                                                                          NULL,--5
                                                                          USER,--6
                                                                          SYSDATE,--7
                                                                           null, --8,
                                                                          C.SZTMACF_FECHA_INICIO,--9
                                                                          c.SZTMACF_ID_CRSE,--10
                                                                          null, --c.maximo,--11
                                                                          'EC', ---l_nivel ,--12
                                                                          C.SZTMACF_CAMP,--13
                                                                          NULL,--14
                                                                          c.SZTMACF_SUBJ,--15
                                                                          NULL,--16
                                                                          null, --17 ,
                                                                          NULL,--18
                                                                          c.SZTMACF_NUM_AULA,--19
                                                                          c.SZTMACF_ID_GROUP,--20
                                                                          c.Shortname,--21
                                                                          1 ,--22
                                                                          C.SZTMACF_SERIACION,--23
                                                                          l_grupo,--24
                                                                          'S',--25
                                                                          l_seqno,--26
                                                                          'E'--27
                                                                          );

                                        l_retorna:='EXITO';
                                        dbms_output.put_line(' INSERTA GRUPOS'||SQLERRM);
                                         COMMIT;
                                        
                                    EXCEPTION WHEN OTHERS THEN
                                        dbms_output.put_line(' Error en al insertar gpme '||SQLERRM);
                                        l_retorna:=' Error en al insertar gpme  '||sqlerrm;

                                    END;
                                    
                                    COMMIT;
                                    
                              begin

                                INSERT INTO SZSGNME VALUES(c.SZTMACF_SUBJ||l_grupo,--1
                                                           310784,  --l_pidm,--2
                                                           sysdate,--3
                                                           user,
                                                           '0',
                                                           null,
                                                           '16c4679fb4cdc47ffbfcf9bc2deb1545e248c053', --l_pwd,
                                                           null,
                                                           'AC',
                                                           c.SZTMACF_SERIACION,
                                                           null,
                                                           null,-- c.ptrm,
                                                           C.SZTMACF_FECHA_INICIO,
                                                           1,
                                                           c.SZTMACF_SERIACION,
                                                           l_seqno, 
                                                           'E'--c.idioma
                                                           );
                                l_retorna:='EXITO';
                                dbms_output.put_line(' INSERTA DOCENTES '||SQLERRM);
                            exception when others then
                                dbms_output.put_line(' Error al insertar tabla de profesores moodl '||c.SZTMACF_SERIACION||sqlerrm);
                                l_retorna:= ' Error al insertar tabla de profesores moodl '||c.SZTMACF_SERIACION||sqlerrm;
                            end;
                             COMMIT;
                          else
                              dbms_output.put_line(' Entra por el ELSE');
                          end if;
                          
                          
                          
                          begin

                                                            --dbms_output.put_line(' Materia  '||c.materia||' Padre '||c.padre||' alumnos '||' pidm' ||d.pidm||' Matriucla '||d.matricula||' Gaston '||l_estatus_gaston);

                                                            insert into SZSTUME values(c.SZTMACF_SUBJ||l_grupo,
                                                                                       FGET_PIDM(p_matricula),---d.pidm,
                                                                                       p_matricula,
                                                                                       sysdate,
                                                                                       user,
                                                                                       0,
                                                                                       null,
                                                                                       L_PASSALUM,  --d.pwd,
                                                                                       null,
                                                                                       (SELECT NVL((MAX(SZSTUME_SEQ_NO) + 1 ),1) 
                                                                                          FROM SZSTUME
                                                                                          WHERE
                                                                                          SZSTUME_TERM_NRC = TO_CHAR(c.SZTMACF_SUBJ||l_grupo)
                                                                                          AND SZSTUME_PIDM = FGET_PIDM(p_matricula)
                                                                                          AND SZSTUME_ID = p_matricula
                                                                                          AND SZSTUME_SUBJ_CODE = c.SZTMACF_SUBJ
                                                                                        ),
                                                                                       'RE', --d.estatus_alumno,
                                                                                       null,
                                                                                       c.SZTMACF_SUBJ,
                                                                                       'EC',-- c.nivel,
                                                                                       null,
                                                                                       null,--  c.ptrm,
                                                                                       null,
                                                                                       null,
                                                                                       null,
                                                                                       null,
                                                                                       c.SZTMACF_SUBJ,
                                                                                       c.SZTMACF_FECHA_INICIO,--  c.inicio_clases,
                                                                                       1,
                                                                                       c.SZTMACF_SERIACION,
                                                                                       1,
                                                                                       0,
                                                                                       NULL
                                                                                       );

                                                            l_retorna:='EXITO';
                                                            dbms_output.put_line(' Exito Insert ');
                                                        exception when others then

                                                            dbms_output.put_line(' Error al insertar '||sqlerrm);



                                                        end;
                                                        
                              COMMIT;                          
                       end loop;  
      
      EXCEPTION WHEN OTHERS THEN
      
      l_retorna:='NO  ENTRO'||d.materia||' '||d.matricula||'pruebas'||sqlerrm;
      
      end;
      COMMIT;               
   end loop;
   RETURN (l_retorna); 
 EXCEPTION WHEN OTHERS THEN
 l_retorna:='NO  ENTRO'||sqlerrm;
 RETURN (l_retorna);                                                    
END f_integra_materias;                
 FUNCTION  f_agrupado_docentes (p_pidm number) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_agrupa
           AS
                c_out_agrupa PKG_DASHBOARD_DOCENTES.cursor_out_agrupa;

  BEGIN
       open c_out_agrupa
                FOR  SELECT nombre,
                           matricula,
                           programa,
                           NVL(AC,0)AC,
                           NVL(EC,0)EC,
                           NVL(NA,0)NA,
                           num_materias TOTALMAT,
                           NVL(ROUND(AC*100/ num_materias),0) PROMEDIO
                    FROM
                    (
                        select nombre,
                               matricula,
                               programa,
                               COUNT(mat_acre)conteo,
                               COUNT(materia) num_materias,
                               MAT_ACRE
                        from
                        (
                        select REPLACE((select distinct SPRIDEN_FIRST_NAME||' '||SPRIDEN_LAST_NAME
                                from spriden
                                where 1 = 1
                                and spriden_change_ind is null
                                and spriden_pidm = a.szstume_pidm),'/',' ') nombre,
                                (select distinct spriden_id
                                from spriden
                                where 1 = 1
                                and spriden_change_ind is null
                                and spriden_pidm = a.szstume_pidm)
                                matricula,
                                b.SZTMACF_PROGRAM||' - '||
                                (   SELECT ZSTPARA_PARAM_DESC
                                FROM zstpara
                               WHERE     zstpara_mapa_id = 'PRO_DOCENTE'
                               and ZSTPARA_PARAM_ID = b.SZTMACF_PROGRAM
                                        and rownum =1  ) programa,
                                szstume_subj_code materia,
                                SZSTUME_GRDE_CODE_FINAL califica,
                               CASE WHEN SZSTUME_TERM_NRC_COMP IS NULL THEN 
                                    'EC'
                                    WHEN to_number(SZSTUME_GRDE_CODE_FINAL) < to_number(B.SZTMACF_MINAPRO) THEN 
                                    'NA'
                                    WHEN to_number(SZSTUME_GRDE_CODE_FINAL) >= to_number(B.SZTMACF_MAXAPRO) THEN
                                    'AC'
                                    END
                                   MAT_ACRE
                        from szstume a
                        join SZTMACF b on b.SZTMACF_SUBJ= a.szstume_subj_code
                        where 1 = 1
                        and SZSTUME_PIDM =p_pidm
                        )
                        group by MAT_ACRE,
                                 nombre,
                                 matricula,
                                 programa
                    )
                    PIVOT(MAX(conteo)
                            for MAT_ACRE
                            in ('AC' AS  AC, 'EC' AS EC,'NA' AS NA)
                    )
                    GROUP BY nombre,
                           matricula,
                           programa,
                           num_materias,
                           AC,
                           EC,
                           NA
                           ;

       RETURN (c_out_agrupa);

  END;

---
---
   FUNCTION  f_docentes_detalle (p_pidm number) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_agrupados
           AS
                c_out_agrupados PKG_DASHBOARD_DOCENTES.cursor_out_agrupados;

  BEGIN
       open c_out_agrupados
                 FOR                     SELECT
                       SZTMACF_SUBJDES ASIGNATURA,
                       SZSTUME_START_DATE FECHA,
                       SZSTUME_SUBJ_CODE CLAVE,
                       CASE WHEN SZSTUME_TERM_NRC_COMP IS NULL THEN 
                            'EC'
                            WHEN to_number(SZSTUME_GRDE_CODE_FINAL) < to_number(B.SZTMACF_MINAPRO) THEN 
                            'NA'
                            WHEN to_number(SZSTUME_GRDE_CODE_FINAL) >= to_number(B.SZTMACF_MAXAPRO) THEN
                            'AC'
                            END
                           MAT_ACRE,
                       SZTMACF_PROGRAM PROGRAMA
               FROM SZSTUME A
               join SZTMACF b on b.SZTMACF_SUBJ= a.szstume_subj_code
               WHERE 1 = 1
               -- and a.SZSTUME_ACTIVITY_DATE in (select max(c.SZSTUME_ACTIVITY_DATE) from SZSTUME c where c.SZSTUME_pidm =a.SZSTUME_pidm)
               AND SZSTUME_PIDM = p_pidm
              -- AND SZSTUME_RSTS_CODE='RE'
               ORDER BY A.SZSTUME_START_DATE ASC;
               
             RETURN (c_out_agrupados);

  END;

----
----
 FUNCTION f_prepara_sync_docentes(p_no_regla in number, p_start_date in varchar2) Return varchar2
  IS
 vl_msje varchar2(200) := Null;
 vl_valida number:=NULL;
 vl_process varchar2(30);

    BEGIN


     vl_valida:= NULL;

       BEGIN
        SELECT STAT_IND, PROCESS
        INTO vl_valida, vl_process
        FROM TMP_SYNC_STATUS
        WHERE 1=1
        AND REGLA = p_no_regla
        AND START_DATE = p_start_date
        GROUP BY STAT_IND, PROCESS;
       EXCEPTION
       WHEN OTHERS THEN
       vl_valida := NULL;
       vl_process := Null;
       END;

       IF vl_valida IS NULL AND vl_process IS NULL THEN

          BEGIN
            UPDATE SZSTUME SET SZSTUME_PTRM = '0', SZSTUME_ACTIVITY_DATE = SYSDATE, SZSTUME_USER_ID = USER, SZSTUME_OBS = 'Esperando||desgarga calificaciones'
            WHERE 1=1
            AND SZSTUME_NO_REGLA = p_no_regla
            AND SZSTUME_START_DATE = p_start_date
            AND SZSTUME_MDLE_ID IS NOT NULL
            AND SZSTUME_PTRM IS NULL;
        vl_msje:='Exito';
         EXCEPTION
         WHEN OTHERS THEN
         vl_msje:= 'Error en la petición de calificaciones '||sqlerrm||' Near of Line...6475';
        END;
       COMMIT;

      END IF;


       BEGIN
        INSERT INTO TMP_SYNC_STATUS
        (STAT_IND,
            REGLA,
            START_DATE,
            PROCESS,
            USER_UPDATE,
            COL1,
            COL2
          )
          VALUES
          (0,
           p_no_regla,
           p_start_date,
           'sync_gradocentes',
           USER,
           Null,
           Null
          );
       EXCEPTION
       WHEN OTHERS THEN
           BEGIN

            SELECT STAT_IND, PROCESS
            INTO vl_valida, vl_process
            FROM TMP_SYNC_STATUS
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_start_date
            GROUP BY STAT_IND, PROCESS;

            IF

            vl_valida = 0 AND vl_process = 'sync_grades' THEN
               vl_msje:='Sincronización de calificaciones iniciada para esta regla: '||p_no_regla||' y fecha de inicio: '||p_start_date;

            ELSIF vl_valida = 1 AND vl_process = 'sync_grades' THEN
               vl_msje:='Las calificaciones ya fueron sincronizadas para esta regla: '||p_no_regla||' y fecha de inicio: '||p_start_date;

              END IF;
           END;
       END;
       COMMIT;

        BEGIN
           DELETE TMP_SYNC_STATUS
            WHERE 1=1
            AND STAT_IND = 4
            AND PROCESS = 'fin_grades';
        END;
        COMMIT;

      RETURN(vl_msje);
      DBMS_OUTPUT.PUT_LINE(vl_msje);

    END f_prepara_sync_docentes;


FUNCTION f_sync_grades_docentes
      RETURN PKG_DASHBOARD_DOCENTES.cursor_gout
   AS
      c_out_grades  PKG_DASHBOARD_DOCENTES.cursor_gout;
   BEGIN
      BEGIN
       OPEN c_out_grades FOR
      SELECT
        SZSTUME_PIDM pidm,
        SZSTUME_ID matricula,
        SZSTUME_MDLE_ID user_moodle_id,
        to_number(SZTGPME_PTRM_CODE_COMP) aula,
        SZTGPME_CRSE_MDLE_ID id_crse_moodle,
        SZTGPME_NO_REGLA regla,
        SZSTUME_START_DATE fecha_inicio
        FROM SZSTUME C , SZTGPME,SIBINST,SZTMACF,SIRCMNT
        WHERE 1=1
       AND SZTGPME_NO_REGLA = c.SZSTUME_NO_REGLA
            AND SZTGPME_TERM_NRC = c.SZSTUME_TERM_NRC
            AND SZTGPME_START_DATE = c.SZSTUME_START_DATE
            AND SZTGPME_SUBJ_CRSE=SZTMACF_SUBJ
            AND c.SZSTUME_PIDM = SIBINST_PIDM
            AND c.SZSTUME_PIDM=SIRCMNT_PIDM
            AND SIRCMNT_TEXT=SZTMACF_CAMP
            and SIBINST_FCST_CODE not in ('BA', 'IN') 
--            AND c.SZSTUME_PIDM = 597236--p_pidm
            AND SZTGPME_NO_REGLA = 1
            and SZSTUME_SUBJ_CODE=SZTMACF_SUBJ 
            and SZSTUME_START_DATE=SZTMACF_FECHA_INICIO
        AND SZSTUME_PTRM = '0'
        AND SZSTUME_MDLE_ID IS NOT NULL
        GROUP BY SZSTUME_PIDM,SZSTUME_ID, SZSTUME_MDLE_ID, SZTGPME_PTRM_CODE_COMP, SZTGPME_CRSE_MDLE_ID, SZTGPME_NO_REGLA, SZSTUME_START_DATE--, COL3
        ORDER BY 7 ASC;

         RETURN (c_out_grades);
      END;
   END f_sync_grades_docentes;


   FUNCTION f_update_sync_docentes (P_MATRICULA varchar, p_no_regla in number, p_crse_moodle in number, p_aula in varchar2, p_grade in varchar2, p_obs in varchar2) Return Varchar2
   IS

   vl_grade Varchar2(10);
   vl_grade_final Varchar2(10);
   vl_error Varchar2(200):= Null;
   vl_type Varchar2(6);
   vl_obs Varchar2(500);
   vl_date_actual date;
   vl_ind number:=0;
   --vl_rsts Varchar2(2);

 BEGIN

   BEGIN

    FOR c IN (SELECT 
            SZSTUME_PIDM pidm,
            SZSTUME_MDLE_ID user_moodle_id,
            SZTMACF_CAMP camp_code,
            'EC'levl_code,
            SZTGPME_TERM_NRC term_nrc,
            SUBSTR(SZTGPME_SUBJ_CRSE,0,3)vtype,
            SZTGPME_NO_REGLA regla,
            SZSTUME_START_DATE start_date,
            SIBINST_FCST_CODE stst
            FROM SZTGPME , SZSTUME c,SIBINST,SZTMACF,SIRCMNT
            WHERE 1=1
            AND SZTGPME_NO_REGLA = c.SZSTUME_NO_REGLA
            AND SZTGPME_TERM_NRC = c.SZSTUME_TERM_NRC
            AND SZTGPME_START_DATE = c.SZSTUME_START_DATE
            AND SZTGPME_SUBJ_CRSE=SZTMACF_SUBJ
            AND c.SZSTUME_PIDM = SIBINST_PIDM
            AND c.SZSTUME_PIDM=SIRCMNT_PIDM
            AND SIRCMNT_TEXT=SZTMACF_CAMP
            and SIBINST_FCST_CODE not in ('BA', 'IN') 
            AND c.SZSTUME_ID = P_MATRICULA 
            AND SZTGPME_NO_REGLA = 1
            and SZSTUME_SUBJ_CODE=SZTMACF_SUBJ 
            and SZSTUME_START_DATE=SZTMACF_FECHA_INICIO
            AND SZTGPME_CRSE_MDLE_ID = p_crse_moodle
            AND SZTGPME_PTRM_CODE_COMP = p_aula
            AND c.SZSTUME_PTRM = '0'

          )

        LOOP

            vl_grade_final := null;


            vl_type:= NULL;

            vl_obs:= NULL;


            IF p_grade IS NULL AND c.stst NOT IN ('MA', 'TR', 'PR', 'EG', 'SG')THEN

              vl_grade :=  '0.00';

              vl_obs:= p_obs;

              ELSIF p_grade IS NULL THEN

              vl_grade :=  '0.00';
              vl_obs:= p_obs;

              ELSE

              vl_grade := p_grade;
              vl_obs:= p_obs;

            END IF;


            DBMS_OUTPUT.PUT_LINE('Entara a validación la calificación'|| vl_grade);

            IF c.regla <> '99' THEN

                vl_type := 'OR';

            ELSIF c.regla = '99' THEN

                vl_type := 'NIV';

            END IF;

            IF c.vtype IN ('SEL','IEB','MOD') THEN

                vl_type := c.vtype;

            ELSE
                vl_type:= vl_type;

            END IF;


            vl_ind:= null;
            vl_date_actual:= null;

            BEGIN
            SELECT TRUNC(SYSDATE)
            INTO vl_date_actual
            FROM DUAL;
            END;


             IF p_grade = '0.00'  AND c.regla = '99' AND vl_date_actual >=  c.start_date THEN

              vl_ind:=1;

             ELSIF p_grade != '0.00' OR c.regla != '99' THEN

               vl_ind:=1;

             ELSE

              vl_ind:=0;

             END IF;


             IF vl_ind = 1 THEN

                 BEGIN
                    SELECT distinct SZTRNDO_GRDE
                    Into   vl_grade_final
                    FROM SZTRNDO
                    WHERE SZTRNDO_CAMP_CODE = c.camp_code
                    AND SZTRNDO_LEVL_CODE = c.levl_code
                    AND SZTRNDO_CTGRY = c.camp_code||c.levl_code||vl_type
                    AND ROUND(vl_grade,2) BETWEEN SZTRNDO_MIN_GRDE AND SZTRNDO_MAX_GRDE ;
                 Exception
                 When Others then
                 vl_grade_final := 'ERCONV';
                 vl_error := 'No existe calificación o conversion de calificacion '||vl_grade||'Near of Line...6571';
                 END;


                 --DBMS_OUTPUT.PUT_LINE(vl_grade_final);


                 BEGIN
                    UPDATE SZSTUME SET SZSTUME_TERM_NRC_COMP = vl_grade, SZSTUME_GRDE_CODE_FINAL = vl_grade_final,
                    SZSTUME_PTRM = '1', SZSTUME_ACTIVITY_DATE = SYSDATE, SZSTUME_OBS = vl_obs||' '||USER||'|| sync_grades'
                    WHERE 1=1
                    AND SZSTUME_PIDM = c.pidm  --'010007241'--'010302086'--'010007241'
                    AND SZSTUME_MDLE_ID = c.user_moodle_id
                    AND SZSTUME_TERM_NRC = c.term_nrc
                    AND SZSTUME_NO_REGLA = c.regla
                    AND SZSTUME_START_DATE = c.start_date;
                 vl_error :='Registro actualizado';
                 Exception
                 When others then
                 vl_error := 'Error al actualizar grade SZSTUME '||sqlerrm||' Near of Line...6591';
                 END;
              COMMIT;

             ELSIF vl_ind = 0 THEN

             Null;

             END IF;



        END LOOP;
   EXCEPTION
   WHEN OTHERS THEN
   vl_error := sqlerrm||': Error general Near of Line...6598';
   END;
   Return(vl_error);
 END f_update_sync_docentes;



FUNCTION f_update_tmp_sync_docentes (p_stat in number, p_no_regla in number,  p_start_date in varchar2, p_process in varchar2) Return Varchar2
     IS

   vl_return varchar(50);

    BEGIN


        IF  p_stat IN (1, 2,3) and p_no_regla IS NOT NULL AND p_start_date IS NOT NULL THEN

          vl_return:= p_stat;

           BEGIN
            UPDATE TMP_SYNC_STATUS SET  STAT_IND = p_stat, PROCESS = p_process
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_start_date;
           EXCEPTION
           WHEN OTHERS THEN
           vl_return:=0;
           return(vl_return);
           END;
           COMMIT;

        ELSIF p_stat = 4 and p_no_regla IS NOT NULL AND p_start_date IS NOT NULL THEN

          vl_return:= p_stat;

           BEGIN
            UPDATE TMP_SYNC_STATUS SET  STAT_IND = p_stat, PROCESS = p_process
            WHERE 1=1
            AND REGLA = p_no_regla
            AND START_DATE = p_start_date;
           EXCEPTION
           WHEN OTHERS THEN
           vl_return:=0;
           return(vl_return);
           END;
           COMMIT;

        ELSIF p_stat = 0 THEN

            vl_return:= p_stat;

        END IF;
       return(vl_return);

     END f_update_tmp_sync_docentes;



   FUNCTION f_update_intermedia_docentes (P_MATRICULA varchar, p_no_regla in number, p_fecha_inicio in date, p_grupo in varchar2, p_secuencia in number) Return Varchar2
   IS

      vl_error Varchar2(200):= 'Exito';

   Begin
                 BEGIN

                       Update SZSTUME
                       set SZSTUME_PTRM = '2'
                       Where SZSTUME_ID = P_MATRICULA
                       And SZSTUME_TERM_NRC = p_grupo
                       And SZSTUME_SEQ_NO = p_secuencia
                       And SZSTUME_NO_REGLA  = p_no_regla
                       And  trunc (SZSTUME_START_DATE) = p_fecha_inicio;

                      Return(vl_error);
                      Commit;
                 EXCEPTION
                    WHEN OTHERS THEN  vl_error := sqlerrm||': Error al actualizar el estatus de la calificacion xxx';
                    Return(vl_error);
                 END;

   END f_update_intermedia_docentes;

-- FIN FUNCIONONES ACTUAL UTILIZADO PARA SINCRONIZAR CALIFICACIONES CON MOODLE--

   FUNCTION  f_docentes_matinscr (P_MATRICULA varchar) RETURN PKG_DASHBOARD_DOCENTES.cursor_out_materasinsc
           AS
                c_out_matinsc PKG_DASHBOARD_DOCENTES.cursor_out_materasinsc;

  BEGIN
       open c_out_matinsc
                 FOR  select
                           SZSTUME_SUBJ_CODE clave_materia ,
                           SZTMACF_SUBJDES nom_materia,
                           SZSTUME_START_DATE fecha_ini
                            from  SZSTUME
                            join SPRIDEN ON SPRIDEN_pidm=SZSTUME_PIDM  and SPRIDEN_CHANGE_IND is null
                            join SIBINST on SIBINST_pidm = SPRIDEN_pidm and SIBINST_FCST_CODE not in ('BA', 'IN')
                            join SZTMACF on SZSTUME_SUBJ_CODE=SZTMACF_SUBJ 
                            where 1=1
                            AND SPRIDEN_id=P_MATRICULA
                            and SZSTUME_TERM_NRC_COMP is  NULL
                            and SZSTUME_GRDE_CODE_FINAL=0 
                            and SZSTUME_PTRM is NULL
                            order by SZTMACF_SERIACION;
             RETURN (c_out_matinsc);

  END; 
  
Procedure descargar_calif as

RetVal varchar(50):='Exito';

cursor c1 is
 select *
 from szstume 
 where 1=1
 and SZSTUME_NO_REGLA=1
 and trunc (sysdate) >= to_date ((trunc (SZSTUME_START_DATE)+30));
 
      begin
            for x in c1  loop
             
              RetVal := BANINST1.PKG_DASHBOARD_DOCENTES.F_PREPARA_SYNC_DOCENTES ( x.SZSTUME_NO_REGLA, x.SZSTUME_START_DATE );
              COMMIT; 
             end loop;
       end;
-----
------
FUNCTION f_reconocimiento_docentes(P_MATRICULA in varchar2, p_nivel in varchar2) RETURN PKG_DASHBOARD_DOCENTES.r_out
           AS
                rec_out PKG_DASHBOARD_DOCENTES.r_out;
  
  VL_TOPE DATE;    
  VL_FEC_M2 DATE;

BEGIN 


        BEGIN 


        SELECT ADD_MONTHS (MAX (SZTGPME_START_DATE), -4)
            INTO VL_FEC_M2
          FROM SZSGNME
               LEFT JOIN SZTGPME
                  ON     SZTGPME_NO_REGLA = SZSGNME_NO_REGLA
                     AND SZTGPME_TERM_NRC = SZSGNME_TERM_NRC
                     AND SZTGPME_LEVL_CODE = p_nivel
                     AND SZTGPME_PTRM_CODE IN ('L1E', 'L2A','M1A', 'M0B', 'O3D')
         WHERE 1 = 1 AND SZSGNME_NO_REGLA <> 99;
         
                                 
        SELECT TO_DATE(DIA||TO_CHAR(MES,'MM')||AÑO,'DD,MM,YYYY')
                INTO VL_TOPE 
                FROM (
                SELECT distinct  
                             TO_CHAR(VL_FEC_M2,'YYYY')-1 AÑO,
                             TO_DATE(to_char(VL_FEC_M2,'MM'),'MM') MES   ,                  
                             '01'DIA 
                             FROM SZSGNME      
                            LEFT JOIN SZTGPME ON SZTGPME_NO_REGLA=SZSGNME_NO_REGLA  AND SZTGPME_TERM_NRC=SZSGNME_TERM_NRC
                                  AND SZTGPME_LEVL_CODE=p_nivel
                             WHERE 1=1
                             and SZSGNME_NO_REGLA<>99);                                 
        END;

 IF p_nivel='LI' THEN     
              open rec_out FOR
              SELECT distinct  
                             spriden_first_name||' '||replace(spriden_last_name,'/',' ') NOMBRE,
                             SZSGNME_NO_REGLA REGLA,
                             SZTGPME_SUBJ_CRSE MATERIA,
                             (select SCRSYLN_LONG_COURSE_TITLE
                               from SCRSYLN
                               where 1=1
                               and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB=SZTGPME_SUBJ_CRSE) NOMBRE_MATE,
                             SUBSTR(SZTGPME_TERM_NRC,-2,2)GRUPO, 
--                             SZTGPME_TERM_NRC_COMP PERIODO,
                             SZTGPME_START_DATE FECHA_PERIODO,
                             SZTGPME_PTRM_CODE PARTE_DE_PERIODO,
                             (select ZSTPARA_PARAM_DESC
                               from ZSTPARA
                               where 1=1
                               and ZSTPARA_MAPA_ID='PTRM_BIMESTRE'
                               and substr(SZTGPME_TERM_NRC_COMP,-2,2)=ZSTPARA_PARAM_ID
                               and SZTGPME_PTRM_CODE=ZSTPARA_PARAM_VALOR)FECHA,
                             to_char(SZTGPME_START_DATE,'YYYY')AÑO,
                             (select SPBPERS_SEX from SPBPERS WHERE SPBPERS_PIDM =SPRIDEN_PIDM) SEXO
             FROM SZSGNME      
            LEFT JOIN SZTGPME ON SZTGPME_NO_REGLA=SZSGNME_NO_REGLA  AND SZTGPME_TERM_NRC=SZSGNME_TERM_NRC
                  AND SZTGPME_LEVL_CODE=p_nivel
                 JOIN SPRIDEN ON  SPRIDEN_PIDM=SZSGNME_PIDM 
                AND SPRIDEN_ID=P_MATRICULA
            LEFT JOIN SOBPTRM ON SOBPTRM_TERM_CODE=SZTGPME_TERM_NRC_COMP and SOBPTRM_PTRM_CODE=SZTGPME_PTRM_CODE
                                 and SOBPTRM_PTRM_CODE=SZSGNME_PTRM
             WHERE 1=1
             and SZSGNME_NO_REGLA<>99
             AND SZSGNME_NO_REGLA < (WITH ranked_data AS (
                                    SELECT DISTINCT a1.sztalgo_no_regla,
                                           DENSE_RANK() OVER (ORDER BY a1.sztalgo_no_regla DESC) AS rank 
                                    FROM sztalgo a1, SZTGPME b1
                                    WHERE   a1.SZTALGO_LEVL_CODE=b1.sZTGPME_LEVL_CODE
                                        AND A1.SZTALGO_CAMP_CODE=b1.SZTGPME_CAMP_CODE
                                        and a1.SZTALGO_PTRM_CODE in ('L1E','L2A') 
                                          AND a1.SZTALGO_ESTATUS_CERRADO = 'S'
                                          AND SZTALGO_FECHA_NEW >= VL_TOPE
                                            )
                                            SELECT SZTALGO_NO_REGLA
                                            FROM ranked_data
                                            WHERE rank = 3 )                                       
--                       and SZSGNME_PIDM=18098   
                        AND SZTGPME_START_DATE>=VL_TOPE  
                        AND SZTGPME_PTRM_CODE NOT IN ('L3A', 'L3B', 'L3C', 'L3D')
                       ORDER BY 6 DESC;
                       
            RETURN (rec_out);
             
  ELSIF p_nivel='MA' THEN
       open rec_out FOR
              SELECT distinct  
                             spriden_first_name||' '||replace(spriden_last_name,'/',' ') NOMBRE,
                             SZSGNME_NO_REGLA REGLA,
                             SZTGPME_SUBJ_CRSE MATERIA,
                             (select SCRSYLN_LONG_COURSE_TITLE
                               from SCRSYLN
                               where 1=1
                               and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB=SZTGPME_SUBJ_CRSE) NOMBRE_MATE,
                             SUBSTR(SZTGPME_TERM_NRC,-2,2)GRUPO, 
--                             SZTGPME_TERM_NRC_COMP PERIODO,
                             SZTGPME_START_DATE FECHA_PERIODO,
                             SZTGPME_PTRM_CODE PARTE_DE_PERIODO,
                             (select ZSTPARA_PARAM_DESC
                               from ZSTPARA
                               where 1=1
                               and ZSTPARA_MAPA_ID='PTRM_BIMESTRE'
                               and substr(SZTGPME_TERM_NRC_COMP,-2,2)=ZSTPARA_PARAM_ID
                               and SZTGPME_PTRM_CODE=ZSTPARA_PARAM_VALOR)FECHA,
                             to_char(SZTGPME_START_DATE,'YYYY')AÑO,
                             (select SPBPERS_SEX from SPBPERS WHERE SPBPERS_PIDM =SPRIDEN_PIDM) SEXO
             FROM SZSGNME      
            LEFT JOIN SZTGPME ON SZTGPME_NO_REGLA=SZSGNME_NO_REGLA  AND SZTGPME_TERM_NRC=SZSGNME_TERM_NRC
                  AND SZTGPME_LEVL_CODE=p_nivel
                 JOIN SPRIDEN ON  SPRIDEN_PIDM=SZSGNME_PIDM 
                AND SPRIDEN_ID=P_MATRICULA
            LEFT JOIN SOBPTRM ON SOBPTRM_TERM_CODE=SZTGPME_TERM_NRC_COMP and SOBPTRM_PTRM_CODE=SZTGPME_PTRM_CODE
                                 and SOBPTRM_PTRM_CODE=SZSGNME_PTRM
             WHERE 1=1
             and SZSGNME_NO_REGLA NOT  IN (99,1)          
              AND SZSGNME_NO_REGLA < (WITH ranked_data AS (
                                    SELECT DISTINCT a1.sztalgo_no_regla,
                                           DENSE_RANK() OVER (ORDER BY a1.sztalgo_no_regla DESC) AS rank 
                                    FROM sztalgo a1, SZTGPME b1
                                    WHERE   a1.SZTALGO_LEVL_CODE=b1.sZTGPME_LEVL_CODE
                                        AND A1.SZTALGO_CAMP_CODE=b1.SZTGPME_CAMP_CODE
                                        and a1.SZTALGO_PTRM_CODE in ('M0B','M1A', 'M0A', 'M0C') 
                                          AND a1.SZTALGO_ESTATUS_CERRADO = 'S'
                                          AND SZTALGO_FECHA_NEW >= VL_TOPE
                                            )
                                            SELECT SZTALGO_NO_REGLA
                                            FROM ranked_data
                                            WHERE rank = 3 )                                       
--                       and SZSGNME_PIDM=18098   
                        AND SZTGPME_START_DATE>=VL_TOPE  
                        AND SZTGPME_PTRM_CODE NOT IN ('M3A', 'M3B')
                       ORDER BY 6 DESC;
                       
            RETURN (rec_out); 
  ELSIF p_nivel='DO' THEN
         open rec_out FOR
              SELECT distinct  
                             spriden_first_name||' '||replace(spriden_last_name,'/',' ') NOMBRE,
                             SZSGNME_NO_REGLA REGLA,
                             SZTGPME_SUBJ_CRSE MATERIA,
                             (select SCRSYLN_LONG_COURSE_TITLE
                               from SCRSYLN
                               where 1=1
                               and SCRSYLN_SUBJ_CODE||SCRSYLN_CRSE_NUMB=SZTGPME_SUBJ_CRSE) NOMBRE_MATE,
                             SUBSTR(SZTGPME_TERM_NRC,-2,2)GRUPO, 
--                             SZTGPME_TERM_NRC_COMP PERIODO,
                             SZTGPME_START_DATE FECHA_PERIODO,
                             SZTGPME_PTRM_CODE PARTE_DE_PERIODO,
                             (select ZSTPARA_PARAM_DESC
                               from ZSTPARA
                               where 1=1
                               and ZSTPARA_MAPA_ID='PTRM_BIMESTRE'
                               and substr(SZTGPME_TERM_NRC_COMP,-2,2)=ZSTPARA_PARAM_ID
                               and SZTGPME_PTRM_CODE=ZSTPARA_PARAM_VALOR)FECHA,
                             to_char(SZTGPME_START_DATE,'YYYY')AÑO,
                             (select SPBPERS_SEX from SPBPERS WHERE SPBPERS_PIDM =SPRIDEN_PIDM) SEXO
             FROM SZSGNME      
            LEFT JOIN SZTGPME ON SZTGPME_NO_REGLA=SZSGNME_NO_REGLA  AND SZTGPME_TERM_NRC=SZSGNME_TERM_NRC
                  AND SZTGPME_LEVL_CODE=p_nivel
                 JOIN SPRIDEN ON  SPRIDEN_PIDM=SZSGNME_PIDM 
              AND SPRIDEN_ID=P_MATRICULA
            LEFT JOIN SOBPTRM ON SOBPTRM_TERM_CODE=SZTGPME_TERM_NRC_COMP and SOBPTRM_PTRM_CODE=SZTGPME_PTRM_CODE
                                 and SOBPTRM_PTRM_CODE=SZSGNME_PTRM
             WHERE 1=1
             and SZSGNME_NO_REGLA<>99
                 AND SZSGNME_NO_REGLA < (WITH ranked_data AS (
                                    SELECT DISTINCT a1.sztalgo_no_regla,
                                           DENSE_RANK() OVER (ORDER BY a1.sztalgo_no_regla DESC) AS rank 
                                    FROM sztalgo a1, SZTGPME b1
                                    WHERE   a1.SZTALGO_LEVL_CODE=b1.sZTGPME_LEVL_CODE
                                        AND A1.SZTALGO_CAMP_CODE=b1.SZTGPME_CAMP_CODE
                                        and a1.SZTALGO_PTRM_CODE in ('O3D') 
                                          AND a1.SZTALGO_ESTATUS_CERRADO = 'S'
                                          AND SZTALGO_FECHA_NEW >= VL_TOPE
                                            )
                                            SELECT SZTALGO_NO_REGLA
                                            FROM ranked_data
                                            WHERE rank = 2 )                                       
--                       and SZSGNME_PIDM=18098   
                        AND SZTGPME_START_DATE>=VL_TOPE  
                       ORDER BY 6 DESC;
                       
            RETURN (rec_out); 
     END IF;       
Exception when Others then
     
 --vl_mensaje:='No cuentas con RECONOCIMIENTOS';
      
      Return (rec_out);
      
END f_reconocimiento_docentes;
      
END;
/

DROP PUBLIC SYNONYM PKG_DASHBOARD_DOCENTES;

CREATE OR REPLACE PUBLIC SYNONYM PKG_DASHBOARD_DOCENTES FOR BANINST1.PKG_DASHBOARD_DOCENTES;
