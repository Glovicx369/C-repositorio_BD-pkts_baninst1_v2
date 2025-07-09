DROP PACKAGE BODY BANINST1.PKG_SABANA;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_SABANA
AS
    PROCEDURE P_INSERTA_SABANA
    IS
    
    ppidm number;
    
    BEGIN
    
        DELETE SZTSABANA;
        COMMIT;

      
           for c in (
                With 
                materias as (
                 select distinct  sfrstcr_pidm as pidm,  F.SFRSTCR_TERM_CODE AS PERIODO, F.SFRSTCR_PTRM_CODE AS P_PERIODO
                             ,B.SSBSECT_CRN AS CRN, B.SSBSECT_PTRM_START_DATE AS INICIO, B.ssbsect_ptrm_end_date AS FIN, F.SFRSTCR_RSTS_CODE AS ESTATUS,                      
                              B.ssbsect_seq_numb AS SECUENCIA, B.SSBSECT_SUBJ_CODE||B.SSBSECT_CRSE_NUMB as materia
                             ,B.SSBSECT_CRSE_TITLE as mate_desc      
                      from ssbsect b, sfrstcr f
                             where 1=1
                               and B.SSBSECT_PTRM_START_DATE >= trunc(sysdate) -30
                                --and sfrstcr_pidm = j.SZTSABANA_PIDM
                                and ssbsect_term_code = sfrstcr_term_code 
                                and SSBSECT_PTRM_CODE  = SFRSTCR_PTRM_CODE  
                                and ssbsect_crn        = sfrstcr_crn 
                              --  and ssbsect_subj_code||ssbsect_crse_numb like (j.SZTSABANA_CLV_MATERIA||'%')
                               and SFRSTCR_TERM_CODE  = ( select max(SFRSTCR_TERM_CODE) from  sfrstcr ff 
                                                          where ff.sfrstcr_pidm = f.sfrstcr_pidm 
                                                            and  substr(ff.SFRSTCR_TERM_CODE,5,1) != 8    )  
                )
                ,correo_principal as (
                            select Distinct
                                a.GOREMAL_PIDM Pidm,
                                a.GOREMAL_EMAIL_ADDRESS correo,
                                max(a.GOREMAL_SURROGATE_ID)
                            from GOREMAL a
                            Where a.goremal_emal_code='PRIN' 
                            and a.goremal_status_ind='A'
                            -- and  a.GOREMAL_PIDM = jump.pidm
                            and a.GOREMAL_SURROGATE_ID = (select max (a1.GOREMAL_SURROGATE_ID)
                                                                                from GOREMAL a1
                                                                                Where a.GOREMAL_PIDM = a1.GOREMAL_PIDM
                                                                                And a.goremal_emal_code = a1.goremal_emal_code
                                                                                And a.goremal_status_ind = a1.goremal_status_ind)
                            group by a.GOREMAL_PIDM, a.GOREMAL_EMAIL_ADDRESS            
                            ),
                           telefono_celular as (
                            Select distinct 
                                a.SPRTELE_PIDM pidm,
                                a.SPRTELE_PHONE_AREA || a.SPRTELE_PHONE_NUMBER Telefono,
                                max(a.SPRTELE_SURROGATE_ID)
                            from SPRTELE a
                            Where a.SPRTELE_TELE_CODE = 'CELU'
                         --   and a.SPRTELE_PIDM = jump.pidm
                            And a.SPRTELE_SURROGATE_ID = (select max (a1.SPRTELE_SURROGATE_ID)
                                                                            from SPRTELE a1
                                                                            where a.SPRTELE_PIDM = a1.SPRTELE_PIDM
                                                                            And a.SPRTELE_TELE_CODE= a1.SPRTELE_TELE_CODE)
                            group by a.SPRTELE_PIDM, a.SPRTELE_PHONE_AREA || a.SPRTELE_PHONE_NUMBER
                            ),
                        gestores  as ( select SZTGEST_MATERIA,
                                        SZTGEST_IDRM,
                                        SZTGEST_NOMBRERM,
                                        SZTGEST_EMAILRM,
                                        SZTGEST_IDREV,
                                        SZTGEST_NOMBREREV,
                                        SZTGEST_EMAILREV,
                                        SZTGEST_NOM_MATERIA,
                                        SZTGEST_GRUPO,
                                        SZTGEST_MATRICULAPROF,
                                        SZTGEST_NOMBREPROF,
                                        SZTGEST_APELLIDOSPROF,
                                        SZTGEST_CORREOPROF,
                                        SZTGEST_CLAVE
                                        From SZTGEST
                                        )   
                select distinct
                spr.SPRIDEN_PIDM pidm,            
                szt.SZTSUPER_CUATRI_CURR cuatrimestre,
                SPR.SPRIDEN_ID  matricula,         
                --szt.SZTSUPER_CLV_MAT materia,
                m.materia as materia,
                spr.SPRIDEN_FIRST_NAME nombre,
                spr.SPRIDEN_LAST_NAME apellidos,   
                    c.correo,
                    d.telefono,                     
                (select spd.SPRADDR_STAT_CODE
                            from SPRADDR spd
                            where 1=1
                            and spd.SPRADDR_PIDM =  spr.SPRIDEN_PIDM
                            and spd.SPRADDR_ATYP_CODE =  'RE'    
                            ) estado,
                (select spd.SPRADDR_City
                            from SPRADDR spd
                            where 1=1
                            and spd.SPRADDR_PIDM =  spr.SPRIDEN_PIDM
                            and spd.SPRADDR_ATYP_CODE =  'RE'    
                            ) ciudad,
                (select spb.SPBPERS_SEX 
                        from SPBPERS spb
                        where 1=1
                        and spb.SPBPERS_PIDM  =  spr.spriden_pidm 
                        ) genero,
                (select spb.SPBPERS_BIRTH_DATE 
                        from SPBPERS spb
                        where 1=1
                        and spb.SPBPERS_PIDM  =  spr.spriden_pidm 
                        ) fecha_nacimiento,
                -- tdn.SGBSTDN_STST_CODE estado_alumno_programa,
                (select smr.SZTMAUR_SZTURMD_ID                                              
                    from SZTMAUR smr
                    where 1=1
                    and smr.SZTMAUR_MACO_PADRE like szt.SZTSUPER_CLV_MAT||'%' 
                    and SZTMAUR_ACTIVO = 'S'
                    and rownum=1
                    ) aula,
                 PKG_REPORTES.f_cargo_vencidos (spr.spriden_pidm) Numero_Cargo_Vencidos,
                (select distinct REPLACE(gor.GORADID_ADDITIONAL_ID,',','')                                            
                       from GORADID gor
                       where 1=1
                       and gor.GORADID_ADID_CODE = 'SALM'
                       and gor.GORADID_PIDM = spr.spriden_pidm
                ) salario_mensual,  
                   szt.SZTSUPER_GRUPO grupo,           
                    nvl(szt.SZTSUPER_ASIGNATURA, m.mate_desc ) asignatura,
                    szt.SZTSUPER_TUTOR tutor,
                    szt.SZTSUPER_SUPERVISOR supervisor,
                    szt.SZTSUPER_EMAIL_TUTOR correo_tutor,
                    szt.SZTSUPER_CLAVE clave,
                    g.SZTGEST_IDRM as id_gestor,
                    g.SZTGEST_NOMBRERM  nom_gestor,
                    g.SZTGEST_EMAILRM as correo_gestor,
                    g.SZTGEST_MATRICULAPROF as id_profesor,
                    g.SZTGEST_NOMBREPROF ||g.SZTGEST_APELLIDOSPROF  as nombre_profesor,   
                    g.SZTGEST_CORREOPROF as correo_profesor,
                    cc.sorlcur_camp_code   campus,
                    cc.sorlcur_levl_code  nivel,
                    cc.sorlcur_program   programa, 
                 (select distinct dtc.SZTDTEC_PROGRAMA_COMP
                    from  SZTDTEC dtc
                       where 1=1
                       and dtc.SZTDTEC_PROGRAM =cc.SORLCUR_PROGRAM                                                                 
                    ) nombre_programa 
                    ,PKG_ACADEMICO_FINANCIEROREPORT.f_Estado_programa(spr.spriden_pidm,CC.SORLCUR_PROGRAM  ) Estado_alumno_programa             
                     ,(select  NVL(STVSTYP_DESC, 'NA') from STVSTYP where tdn.SGBSTDN_STYP_CODE=STVSTYP_CODE) TIPO
                     ,PKG_REPORTES.f_mora  (spr.spriden_pidm) Mora
                     ,PKG_REPORTES.f_saldototal (spr.spriden_pidm) Saldo_Total
                     ,BANINST1.Fvalid_documentos(spr.spriden_pidm) as documentos
                          , m.estatus
                          , M.INICIO
                          , M.FIN
                          , M.P_PERIODO
                          , M.SECUENCIA
                          , M.PERIODO
                          , M.CRN
                from sztsuper szt, spriden spr, sgbstdn tdn, sorlcur cc, correo_principal c, telefono_celular d,gestores g,materias m
                where 1=1
                and spr.spriden_pidm  = nvl( ppidm,spr.spriden_pidm )
                and szt.sztsuper_id(+) = spr.spriden_iD
                and spr.spriden_change_ind IS NULL
                and tdn.sgbstdn_pidm = spr.spriden_pidm
                and tdn.sgbstdn_pidm = cc.sorlcur_pidm
                and  cc.SORLCUR_LMOD_CODE = 'LEARNER'
                --   And cur.SORLCUR_ROLL_IND = 'Y'
                --   And cur.SORLCUR_CACT_CODE = 'ACTIVE'
                And cc.SORLCUR_LEVL_CODE = 'LI'
                and cc.SORLCUR_LEVL_CODE = TDN.SGBSTDN_LEVL_CODE
                --and tdn.SGBSTDN_STYP_CODE IN ('C','N','R', 'D')
                 And spr.spriden_pidm = c.Pidm (+)
                 And spr.spriden_pidm = d.Pidm (+)
                 --And a.spriden_pidm = g.Pidm (+)
                 and szt.SZTSUPER_CLAVE = g.SZTGEST_CLAVE (+)
                 and szt.SZTSUPER_GRUPO = g.SZTGEST_GRUPO (+)
                 and spr.spriden_pidm = m.pidm
                 and szt.SZTSUPER_CLV_MAT(+) like (m.materia||'%')
                 --and rownum < 20
                And cc.SORLCUR_SEQNO = (select max (aa1.SORLCUR_SEQNO)
                                       from SORLCUR aa1
                                       Where cc.sorlcur_pidm = aa1.sorlcur_pidm
                                       And cc.SORLCUR_PROGRAM = aa1.SORLCUR_PROGRAM
                                       And cc.SORLCUR_LMOD_CODE =  aa1.SORLCUR_LMOD_CODE
                                       And cc.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE)  
                and TDN.SGBSTDN_TERM_CODE_EFF = (select max(tdn2.sgbstdn_term_code_eff)
                                                        from sgbstdn tdn2
                                                        where tdn2.sgbstdn_pidm =  tdn.sgbstdn_pidm
                                                          and   tdn2.SGBSTDN_LEVL_CODE = tdn.SGBSTDN_LEVL_CODE
                                                  )                                  
            ORDER BY 3,4 desc
        )LOOP
                       
               ---         dbms_output.put_line('Pidm '||c.pidm); 
             begin           
                      INSERT INTO SZTSABANA (  
                                        SZTSABANA_PIDM,
                                        SZTSABANA_CUATRI,
                                        SZTSABANA_MATRICULA,
--                                                        SZTSABANA_BIMESTREC1, 
                                        SZTSABANA_CRN,
                                        SZTSABANA_PERIODO,
                                        SZTSABANA_P_PERIODO,
                                        SZTSABANA_CICLO_INGRESO,
                                        SZTSABANA_CLV_MATERIA,
                                        SZTSABANA_NOMBRE_ALU,
                                        SZTSABANA_APELLIDOS_ALU,
                                        SZTSABANA_INICIO_CLASES,
                                        SZTSABANA_STATUS_MAT,
                                        SZTSABANA_SEQNO_MAT,
                                        SZTSABANA_CORREO_ALU,
                                        SZTSABANA_TEL_ALU,
                                        SZTSABANA_ESTADO,
                                        SZTSABANA_CIUDAD,
                                        SZTSABANA_CAMPUS,
                                        SZTSABANA_NIVEL,
                                        SZTSABANA_PROGRAMA,
                                        SZTSABANA_GENERO,
                                        SZTSABANA_FECHA_NACALU,
                                        SZTSABANA_EDO_ALU_PROG,
                                        SZTSABANA_AULA,
                                        SZTSABANA_PAGOS_VENCIDOS,
                                        SZTSABANA_SALARIO_MES,
                                        SZTSABANA_NOM_PROGRAM,
                                        SZTSABANA_GRUPO,
                                        SZTSABANA_ASIGNATURA,
                                        SZTSABANA_TUTOR,
                                        SZTSABANA_SUPERVISOR,
                                        SZTSABANA_CORREO_TUTOR,
                                        SZTSABANA_CLAVE,
                                        SZTSABANA_ID_GESTOR,
                                        SZTSABANA_GESTOR,
                                        SZTSABANA_CORREO_GESTOR,
                                        SZTSABANA_ID_PROFESOR,
                                        SZTSABANA_PROFESOR,
                                        SZTSABANA_CORREO_PROFESOR,
                                        sztsabana_estatus_prog,
                                        SZTSABANA_MORAS,
                                        SZTSABANA_ADEUDO,
                                        SZTSABANA_DOCUMENTOS,
                                        SZTSABANA_HORA_EXTRAC,
                                        SZTSABANA_INICIO_PERIODO,
                                        SZTSABANA_FIN_PERIODO                                                                                                                                      
                            )
                  VALUES(
                                        c.pidm,
                                        c.cuatrimestre,
                                        c.matricula,
--                                                        c.bimestre_c1,
                                        c.crn,
                                        c.periodo,
                                        c.p_periodo,
                                        c.periodo,
                                        c.materia,
                                        c.nombre,
                                        c.apellidos,
                                        c.inicio,
                                        c.estatus,
                                        c.secuencia,
                                        c.correo,
                                        c.telefono,
                                        c.estado,
                                        c.ciudad,
                                        c.campus,
                                        c.nivel,
                                        c.programa,
                                        c.genero,
                                        c.fecha_nacimiento,
                                        c.estado_alumno_programa,
                                        c.aula,
                                        c.Numero_Cargo_Vencidos,
                                        c.salario_mensual,
                                        c.nombre_programa,
                                        c.grupo,
                                        c.asignatura,
                                        c.tutor,
                                        c.supervisor,
                                        c.correo_tutor,
                                        c.clave,
                                        c.id_gestor,
                                        c.nom_gestor,
                                        c.correo_gestor,
                                        c.id_profesor,
                                        c.nombre_profesor,
                                        c.correo_profesor,
                                        c.tipo,
                                        c.mora,
                                        c.Saldo_Total,
                                        c.documentos,
                                        sysdate,
                                         c.inicio,
                                        c.fin
                                                     
                                       );
                 exception when others then 
                 dbms_output.put_line('no se pudo insertar el regstro '); 
                end;
                        
        commit;    
                        
      END LOOP;                                                     
                                                         
               
         BEGIN PKG_SABANA.P_MORAS; END;  commit;   
            
    END;
--
--
    PROCEDURE P_MORAS
    IS
    BEGIN

        FOR C IN (
                            select 
                             z.SZTSABANA_MATRICULA matricula,
                                        NVL((SELECT DISTINCT              
                                           REPLACE(sum(SALDO_VENCIDO),',','.') SALDO_VENCIDO
                                        FROM
                                        (
                                        SELECT DISTINCT
                                             CUR.SORLCUR_CAMP_CODE campus,
                                             CUR.SORLCUR_LEVL_CODE nivel,
                                             CUR.SORLCUR_PROGRAM programa,
                                             CD.TBRACCD_BALANCE SALDO_VENCIDO,
                                             case when CD.TBRACCD_DESC like 'COLEGIATURA%'
                                             then 'COLEGIATURA'
                                                 when CD.TBRACCD_DESC like '%INTERES%'
                                             then 'INTERESES'
                                             else 'ACCESORIOS'
                                             end DESCRIPCION_SALDO,
                                             CD.TBRACCD_DESC DESCRIPCION_SAL,
                                             DEN.SPRIDEN_ID MATRICULA,
                                             DEN.SPRIDEN_LAST_NAME||DEN.SPRIDEN_FIRST_NAME NOMBRE,
                                             SGBSTDN_STST_CODE ESTATUS,
                                              case
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) < 0 then
                                                             'Mora0'
                                                     when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 1 and 30 then
                                                             'Mora1'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 31 and 60 then
                                                             'Mora2'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 61 and 90 then
                                                            'Mora3'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 91 and 120 then
                                                            'Mora4'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 121 and 150 then
                                                            'Mora5'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 151 and 180 then
                                                            'Mora6'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) > 181 then
                                                             'Mora7'
                                                    end as Tipo_Mora,
                                                    TBRACCD_EFFECTIVE_DATE FECHA
                                        FROM sorlcur cur,TBRACCD CD,SPRIDEN DEN,SGBSTDN TDN
                                        WHERE 1=1
                                        and CD.TBRACCD_PIDM =cur.sorlcur_pidm
                                        AND CD.TBRACCD_PIDM=den.SPRIDEN_PIDM
                                        AND CD.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                    FROM TBBDETC
                                                                    WHERE TBBDETC_TYPE_IND = 'C'
                                                                    and TBBDETC_dcat_code != 'TUI')
                                        AND CD.TBRACCD_PIDM=TDN.SGBSTDN_PIDM
                                        AND TDN.sgbstdn_PROGRAM_1 = CUR.sorlcur_program
                                        and cur.SORLCUR_LMOD_CODE = 'LEARNER'
                                        --and cur.SORLCUR_CACT_CODE = 'ACTIVE'
                                        AND cur.SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)
                                                                                from SORLCUR aa1
                                                                                Where cur.sorlcur_pidm = aa1.sorlcur_pidm
                                                                                And cur.SORLCUR_LMOD_CODE = aa1.SORLCUR_LMOD_CODE
                                                                                And cur.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE
                                                                                And cur.sorlcur_program=aa1.sorlcur_program)
                                        AND TDN.SGBSTDN_TERM_CODE_EFF=(SELECT MAX(TDN2.SGBSTDN_TERM_CODE_EFF)
                                                                      FROM SGBSTDN TDN2
                                                                      WHERE 1=1
                                                                      AND TDN2.SGBSTDN_PIDM=TDN.SGBSTDN_PIDM)
                                        AND CD.TBRACCD_BALANCE > 0
                                        AND CD.TBRACCD_EFFECTIVE_DATE<SYSDATE
                                        AND SPRIDEN_CHANGE_IND is null
                                        and TBRACCD_PIDM = SZTSABANA_PIDM 
                                        
                                        )), 0)adeudo,
                                        
                                  NVL((SELECT DISTINCT              
                                           Tipo_Mora
                                        FROM
                                        (
                                        SELECT DISTINCT
                                             CUR.SORLCUR_CAMP_CODE campus,
                                             CUR.SORLCUR_LEVL_CODE nivel,
                                             CUR.SORLCUR_PROGRAM programa,
                                             CD.TBRACCD_BALANCE SALDO_VENCIDO,
                                             case when CD.TBRACCD_DESC like 'COLEGIATURA%'
                                             then 'COLEGIATURA'
                                                 when CD.TBRACCD_DESC like '%INTERES%'
                                             then 'INTERESES'
                                             else 'ACCESORIOS'
                                             end DESCRIPCION_SALDO,
                                             CD.TBRACCD_DESC DESCRIPCION_SAL,
                                             DEN.SPRIDEN_ID MATRICULA,
                                             DEN.SPRIDEN_LAST_NAME||DEN.SPRIDEN_FIRST_NAME NOMBRE,
                                             SGBSTDN_STST_CODE ESTATUS,
                                              case
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) < 0 then
                                                             'Mora0'
                                                     when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 1 and 30 then
                                                             'Mora1'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 31 and 60 then
                                                             'Mora2'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 61 and 90 then
                                                            'Mora3'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 91 and 120 then
                                                            'Mora4'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 121 and 150 then
                                                            'Mora5'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) between 151 and 180 then
                                                            'Mora6'
                                                    when  (SYSDATE-(SELECT MIN(TBRACCD_EFFECTIVE_DATE)
                                                      FROM TBRACCD
                                                       WHERE 1=1
                                                       AND CD.TBRACCD_PIDM=TBRACCD_PIDM
                                                       AND TBRACCD_BALANCE > 0
                                                         )) > 181 then
                                                             'Mora7'
                                                    end as Tipo_Mora,
                                                    TBRACCD_EFFECTIVE_DATE FECHA
                                        FROM sorlcur cur,TBRACCD CD,SPRIDEN DEN,SGBSTDN TDN
                                        WHERE 1=1
                                        and CD.TBRACCD_PIDM =cur.sorlcur_pidm
                                        AND CD.TBRACCD_PIDM=den.SPRIDEN_PIDM
                                        AND CD.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                    FROM TBBDETC
                                                                    WHERE TBBDETC_TYPE_IND = 'C'
                                                                    and TBBDETC_dcat_code != 'TUI')
                                        AND CD.TBRACCD_PIDM=TDN.SGBSTDN_PIDM
                                        AND TDN.sgbstdn_PROGRAM_1 = CUR.sorlcur_program
                                        and cur.SORLCUR_LMOD_CODE = 'LEARNER'
                                        --and cur.SORLCUR_CACT_CODE = 'ACTIVE'
                                        AND cur.SORLCUR_SEQNO = (select max (SORLCUR_SEQNO)
                                                                                from SORLCUR aa1
                                                                                Where cur.sorlcur_pidm = aa1.sorlcur_pidm
                                                                                And cur.SORLCUR_LMOD_CODE = aa1.SORLCUR_LMOD_CODE
                                                                                And cur.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE
                                                                                And cur.sorlcur_program=aa1.sorlcur_program)
                                        AND TDN.SGBSTDN_TERM_CODE_EFF=(SELECT MAX(TDN2.SGBSTDN_TERM_CODE_EFF)
                                                                      FROM SGBSTDN TDN2
                                                                      WHERE 1=1
                                                                      AND TDN2.SGBSTDN_PIDM=TDN.SGBSTDN_PIDM)
                                        AND CD.TBRACCD_BALANCE > 0
                                        AND CD.TBRACCD_EFFECTIVE_DATE<SYSDATE
                                        AND SPRIDEN_CHANGE_IND is null
                                        and TBRACCD_PIDM = SZTSABANA_PIDM 
                                        
                                        )), 'Sin Mora')moras
                                        
                            from sztsabana z
                            where 1=1
                            ORDER BY 1
        )LOOP
                            
                           dbms_output.put_line('Matricula '||c.matricula); 
                            
                          UPDATE SZTSABANA
                          SET SZTSABANA_MORAS  =  c. moras,
                                 SZTSABANA_ADEUDO =  c.adeudo
                          WHERE SZTSABANA_MATRICULA = c.matricula;
                            
                        
                        END LOOP;                                                     
          commit;        
     END;
--
--    
END PKG_SABANA;
/

DROP PUBLIC SYNONYM PKG_SABANA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SABANA FOR BANINST1.PKG_SABANA;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_SABANA TO PUBLIC;
