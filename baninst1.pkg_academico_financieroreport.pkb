DROP PACKAGE BODY BANINST1.PKG_ACADEMICO_FINANCIEROREPORT;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_ACADEMICO_FINANCIEROREPORT IS
Procedure sp_Academico_Financiero
is
cursor c_spriden is
select s.spriden_pidm pidm 
from spriden s, sorlcur c
where 1=1
and S.SPRIDEN_CHANGE_IND is null
and  S.SPRIDEN_PIDM = C.SORLCUR_PIDM
--AND  S.SPRIDEN_PIDM =652
and  C.SORLCUR_SEQNO = ( select max ( cc.SORLCUR_SEQNO ) from sorlcur cc where c.SORLCUR_PIDM = cc.SORLCUR_PIDM );


   BEGIN
     delete TZTCRTE
     where TZTCRTE_TIPO_REPORTE = 'Academico_Financiero';
     Commit;
            
     
      for  jump in c_spriden loop  
       begin  
         For acafin in (
         With    avances_curr as (
            select SZTHITA_PIDM pidm,
            SZTHITA_ID  id,
            SZTHITA_CAMP  campus,
            SZTHITA_LEVL  nivel,
            SZTHITA_PROG  programa,
            SZTHITA_N_PROG nomb_prog,
            SZTHITA_STATUS  estatus,
            SZTHITA_APROB aprobadas,
            SZTHITA_REPROB reprobadas,
            SZTHITA_E_CURSO en_curso,
            SZTHITA_X_CURSAR por_cursar,
            SZTHITA_TOT_MAT  tot_mate,
            SZTHITA_AVANCE  avances,
            SZTHITA_PROMEDIO  promedios,
            SZTHITA_PER_CATALOGO  term_ctlg
            from SZTHITA
            ),
            Incobrable as (
            select distinct 
            TZTMORA_PIDM PIDM,
            case 
                when TZTMORA_dias between 1 and 30 then 
                         .0
                when TZTMORA_dias between 31 and 60 then 
                         .5
                when TZTMORA_dias between 61 and 90 then 
                        .10
                when TZTMORA_dias between 91 and 120 then 
                        .20
                when TZTMORA_dias between 121 and 150 then 
                        .30
                when TZTMORA_dias between 151 and 180 then 
                        .60
                when TZTMORA_dias > 180 then 
                        .85
            End as Incobrable
            from TZTMORA)
            select distinct a.spriden_pidm usuario_id, 
                                a.spriden_id Matricula,
                                nvl(k.campus, PP.SARADAP_CAMP_CODE ) campus,
                                nvl(k.Nivel,PP.SARADAP_LEVL_CODE )   Nivel_Code,
                                --k.nivel Nivel_Academico,
                                ( select STVLEVL_DESC from stvlevl where STVLEVL_CODE = k.Nivel ) Nivel_Academico,
                                a.SPRIDEN_LAST_NAME ||' '||SPRIDEN_FIRST_NAME Nombre,
                                nvl (trim (pkg_utilerias.f_correo(a.spriden_pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.spriden_pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.spriden_pidm, 'UTLX')) )) Correo_Principal,
                                pkg_utilerias.f_correo(a.spriden_pidm, 'ALTE') Correo_Alterno,
                                pkg_utilerias.f_celular(a.spriden_pidm, 'RESI') Telefono_Casa,
                                pkg_utilerias.f_celular(a.spriden_pidm, 'CELU') Telefono_Celular,
                                PKG_REPORTES_1.f_saldototal (a.spriden_pidm) Saldo_Total,
                                PKG_REPORTES_1.f_saldodia (a.spriden_pidm) Saldo_Vencido,
                                PKG_REPORTES_1.f_cargo_vencidos (a.spriden_pidm) Numero_Cargo_Vencido,
                                PKG_REPORTES_1.f_fecha_pago_vieja (a.spriden_pidm) Primer_fecha_limite_de_pago,
                                PKG_REPORTES_1.f_fecha_pago_alta (a.spriden_pidm) Ultima_fecha_limite_de_pago,
                                PKG_REPORTES_1.f_dias_atraso  (a.spriden_pidm) Dias_Atraso,
                                trunc (PKG_REPORTES_1.f_dias_atraso  (a.spriden_pidm) / 30 )  Meses_Atraso,
                                PKG_REPORTES_1.f_mora  (a.spriden_pidm) Mora,
                                PKG_REPORTES_1.f_cargo_total_futuro (a.spriden_pidm) Total_montos_Prox,
                                PKG_REPORTES_1.f_saldocorte (a.spriden_pidm) Saldo_Prox,
                                PKG_REPORTES_1.f_cargo_Numero_futuro (a.spriden_pidm) Numero_Cargos_Proximos,
                                to_date (PKG_REPORTES_1.f_fechacorte (a.spriden_pidm), 'dd/mm/rrrr') Prox_Fecha_Limite_Pag,
                                to_date (PKG_REPORTES_1.f_fechacorte (a.spriden_pidm),'dd/mm/rrrr' )  - trunc (sysdate) Num_Dias_Prox_Pago,
                                PKG_REPORTES_1.f_pago_total (a.spriden_pidm)  Suma_depositos,
                                PKG_REPORTES_1.f_num_total_pago (a.spriden_pidm)  Numero_Depositos,
                                (PKG_REPORTES_1.f_saldodia (a.spriden_pidm) * h.Incobrable) Monto_Incobrable,
                                case 
                                when h.Incobrable = .0 then 
                                         '0%'
                                when h.Incobrable = .5 then 
                                         '5%'
                                when h.Incobrable = .10 then 
                                         '10%'
                                when h.Incobrable = .20 then 
                                         '20%'
                                when h.Incobrable = .30 then 
                                         '30%'
                                when h.Incobrable = .60 then 
                                         '60%'
                                when h.Incobrable = .85 then 
                                         '85%'
                            End as Provision_Incobrable,
                                null Ultimo_Acceso_Plataforma,
                                null Rango_dias_acceso_plataforma,
                                PKG_REPORTES_1.f_jornada (a.spriden_pidm)   Jornada_Plan,
                                PKG_REPORTES_1.f_no_materia (a.spriden_pidm) Carga_Academica
                               , k.aprobadas Materias_Aprobadas
                               , k.avances   Avance_Curricular
                               , k.promedios  promedios  
                                ,to_date (PKG_REPORTES_1.f_fecha_Matriculacion (a.spriden_pidm), 'dd/mm/rrrr') Fecha_Matriculacion
                                ,PKG_REPORTES_1.f_periodo_inicial (a.spriden_pidm) Ciclo_Inicial
                                ,PKG_ACADEMICO_FINANCIEROREPORT.f_Estado_programa(a.spriden_pidm,k.programa) Estado_alumno_programa
                                ,nvl(k.programa, PP.SARADAP_PROGRAM_1)  Programa_Code
                                ,( select distinct SZTDTEC_PROGRAMA_COMP
                                from SZTDTEC a
                                where 1= 1
                                and a.SZTDTEC_TERM_CODE = (select max (a1.SZTDTEC_TERM_CODE)
                                                       from SZTDTEC a1
                                                       Where a.SZTDTEC_PROGRAM = a1.SZTDTEC_PROGRAM)
                                and SZTDTEC_PROGRAM = nvl(k.programa, PP.SARADAP_PROGRAM_1)    
                                And SZTDTEC_CAMP_CODE = nvl(k.campus, PP.SARADAP_CAMP_CODE )
                                ) Nombre_Programa 
                                ,nvl (PKG_REPORTES_1.f_Descuento (a.spriden_pidm), 0) Descuento
                               , pkg_utilerias.f_referencia(a.spriden_pidm) Referencia_Bancaria
                                ,(SELECT DISTINCT STVSTYP_DESC FROM STVSTYP WHERE STVSTYP_CODE =PP.SARADAP_STYP_CODE )  TIPO_INGRESO
                                ,A.SPRIDEN_CREATE_FDMN_CODE  ID_ALUMNO
                                , (select distinct  NVL( case when GORADID_ADID_CODE = 'INBE' then 'INBEC'
                                        when GORADID_ADID_CODE = 'NOMR' then 'NO MOLESTAR'
                                        when GORADID_ADID_CODE = 'RECU' then 'D.R.A'
                                        when GORADID_ADID_CODE = 'IZZI' then 'IZZI'
                                        else Null
                                     end, 'NA') as Etiqueta1
                                     from goradid dd
                                     where  a.spriden_pidm = dd.GORADID_PIDM 
                                     and dd.GORADID_ADID_CODE in ('INBE', 'NOMR', 'RECU', 'IZZI')
                                     and  rownum < 2
                                   ) etiqueta
                   from spriden a, saradap pp,  avances_curr k,  Incobrable h
            Where A.SPRIDEN_CHANGE_IND is null 
              And a.spriden_pidm =  jump.pidm
              and a.spriden_pidm =  PP.SARADAP_PIDM
              and PP.SARADAP_APPL_NO  = ( select max(PP.SARADAP_APPL_NO)  from saradap pp1 where PP.SARADAP_PIDM = pp1.SARADAP_PIDM )  
                And a.spriden_pidm = k.Pidm (+)
                And a.spriden_pidm = h.Pidm (+)
                order by 1
              
            )loop

                Insert into TZTCRTE values (acafin.usuario_id, 
                                                        acafin.Matricula,
                                                        acafin.Campus,
                                                        acafin.Nivel_Code,
                                                        acafin.Nivel_Academico,
                                                        acafin.Nombre,
                                                        acafin.Correo_Principal,
                                                        acafin.Correo_Alterno,
                                                        acafin.Telefono_Casa,
                                                        acafin.Telefono_Celular,
                                                        acafin.Saldo_Total,
                                                        acafin.Saldo_Vencido,
                                                        acafin.Numero_Cargo_Vencido,
                                                        acafin.Primer_fecha_limite_de_pago,
                                                        acafin.Ultima_fecha_limite_de_pago,
                                                        acafin.Dias_Atraso,
                                                        acafin.Meses_Atraso,
                                                        acafin.Mora,
                                                        acafin.Total_montos_Prox,
                                                        acafin.Saldo_Prox,
                                                        acafin.Numero_Cargos_Proximos,
                                                        acafin.Prox_Fecha_Limite_Pag,
                                                        acafin.Num_Dias_Prox_Pago,
                                                        acafin.Suma_depositos,
                                                        acafin.Numero_Depositos,
                                                        acafin.Monto_Incobrable,
                                                        acafin.Provision_Incobrable,
                                                        acafin.Ultimo_Acceso_Plataforma,
                                                        acafin.Rango_dias_acceso_plataforma,
                                                        acafin.Jornada_Plan,
                                                        acafin.Carga_Academica, --campo27
                                                        acafin.Materias_Aprobadas, --campo28
                                                        acafin.Avance_Curricular,  --campo29
                                                        acafin.promedios, --campo30
                                                        acafin.Fecha_Matriculacion,
                                                        acafin.Ciclo_Inicial,
                                                        acafin.Estado_alumno_programa,
                                                        acafin.Programa_Code,
                                                        acafin.Nombre_Programa,
                                                        acafin.Descuento,
                                                        acafin.Referencia_Bancaria,--campo37
                                                        acafin.TIPO_INGRESO,   ---campo 38
                                                        acafin.ID_ALUMNO,     ---campo39
                                                        acafin.Etiqueta,    ----campo40
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        null,
                                                        sysdate,
                                                        'Academico_Financiero'
                                                        );
             commit;
            End loop;
            
            
          
        End;
      
      end loop;    
      commit;
     exception when others then 
     null;
     
     ---dbms_output.put_line(sqlerrm);
     
      
    END;
    
    

Function  f_Estado_programa (p_pidm in number,p_programa varchar2  ) RETURN  varchar2 

Is     

    vl_estatus varchar2(50);

    Begin

           select  distinct  STVSTST_DESC
            Into vl_estatus
            from sorlcur c , sgbstdn a, spriden b, stvSTST d
            where c.SORLCUR_LMOD_CODE = 'LEARNER'
            And c.SORLCUR_SEQNO in (select max ( c1.SORLCUR_SEQNO)
                                                      from SORLCUR c1
                                                      where c.sorlcur_pidm = c1.sorlcur_pidm
                                                      and c.SORLCUR_LMOD_CODE =  c1.SORLCUR_LMOD_CODE
                                                      and C.SORLCUR_PROGRAM=C1.SORLCUR_PROGRAM
                                                      )
            and c.sorlcur_pidm = a.sgbstdn_pidm
            and c.sorlcur_program = a.sgbstdn_program_1         
            and a.SGBSTDN_TERM_CODE_EFF in (select max (a1.SGBSTDN_TERM_CODE_EFF)
                                                                        from SGBSTDN a1
                                                                        Where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
                                                                        And a.sgbstdn_program_1 = a1.sgbstdn_program_1)                                 
            and b.spriden_pidm = a.sgbstdn_pidm
            and a.SGBSTDN_STST_CODE = stvSTST_code
            and b.spriden_change_ind is null                                                                   
            and b.spriden_pidm =p_pidm
            and C.SORLCUR_PROGRAM=p_programa;

            
           Return (vl_estatus);
    Exception 
    when Others then 
        vl_estatus :=null;
      Return (vl_estatus);
     -- DBMS_OUTPUT.PUT_LINE(sqlerrm);
    END f_Estado_programa;         
    
 Procedure sp_Academico_Financiero_Nw
is



   BEGIN
   
        Begin 
             delete TZTCRTE_AF
             where TZTCRTE_AF_TIPO_REPORTE = 'Academico_Financiero';
             Commit;
        Exception
            When Others then 
                null;
        End;         
     
     
 For cx in (
     
                    select s.spriden_pidm pidm , substr (spriden_id,1,2) id
                    from spriden s, sorlcur c
                    where 1=1
                    and S.SPRIDEN_CHANGE_IND is null
                    and  S.SPRIDEN_PIDM = C.SORLCUR_PIDM
                  --  AND  S.SPRIDEN_PIDM =652
                    and  C.SORLCUR_SEQNO = ( select max ( cc.SORLCUR_SEQNO ) 
                                                                from sorlcur cc 
                                                                where c.SORLCUR_PIDM = cc.SORLCUR_PIDM )
                                                                
        ) loop                    


                     For acafin in (
                     
                     
                                     With   
                                         avances_curr as (
                                        select SZTHITA_PIDM pidm,
                                        SZTHITA_ID  id,
                                        SZTHITA_CAMP  campus,
                                        SZTHITA_LEVL  nivel,
                                        SZTHITA_PROG  programa,
                                        SZTHITA_N_PROG nomb_prog,
                                        SZTHITA_STATUS  estatus,
                                        SZTHITA_APROB aprobadas,
                                        SZTHITA_REPROB reprobadas,
                                        SZTHITA_E_CURSO en_curso,
                                        SZTHITA_X_CURSAR por_cursar,
                                        SZTHITA_TOT_MAT  tot_mate,
                                        SZTHITA_AVANCE  avances,
                                        SZTHITA_PROMEDIO  promedios,
                                        SZTHITA_PER_CATALOGO  term_ctlg
                                        from SZTHITA
                                        ),
                                        Incobrable as (
                                        select distinct 
                                        TZTMORA_PIDM PIDM,
                                        case 
                                            when TZTMORA_dias between 1 and 30 then 
                                                     .0
                                            when TZTMORA_dias between 31 and 60 then 
                                                     .5
                                            when TZTMORA_dias between 61 and 90 then 
                                                    .10
                                            when TZTMORA_dias between 91 and 120 then 
                                                    .20
                                            when TZTMORA_dias between 121 and 150 then 
                                                    .30
                                            when TZTMORA_dias between 151 and 180 then 
                                                    .60
                                            when TZTMORA_dias > 180 then 
                                                    .85
                                        End as Incobrable
                                        from TZTMORA)
                                        select distinct a.spriden_pidm usuario_id, 
                                                            a.spriden_id Matricula,
                                                            nvl(k.campus, PP.SARADAP_CAMP_CODE ) campus,
                                                            nvl(k.Nivel,PP.SARADAP_LEVL_CODE )   Nivel_Code,
                                                            ( select STVLEVL_DESC from stvlevl where STVLEVL_CODE = k.Nivel ) Nivel_Academico,
                                                            a.SPRIDEN_LAST_NAME ||' '||SPRIDEN_FIRST_NAME Nombre,
                                                            nvl (pkg_utilerias.f_correo(a.spriden_pidm, 'PRIN'), nvl (pkg_utilerias.f_correo(a.spriden_pidm, 'UCAM'),pkg_utilerias.f_correo(a.spriden_pidm, 'UTLX') )) Correo_Principal,    ----ALTE
                                                            pkg_utilerias.f_correo(a.spriden_pidm, 'ALTE') Correo_Alterno,
                                                            pkg_utilerias.f_celular(a.spriden_pidm, 'RESI') Telefono_Casa,
                                                            pkg_utilerias.f_celular(a.spriden_pidm, 'CELU') Telefono_Celular,
                                                            PKG_REPORTES_1.f_saldototal (a.spriden_pidm) Saldo_Total,
                                                            PKG_REPORTES_1.f_saldodia (a.spriden_pidm) Saldo_Vencido,
                                                            PKG_REPORTES_1.f_cargo_vencidos (a.spriden_pidm) Numero_Cargo_Vencido,
                                                            PKG_REPORTES_1.f_fecha_pago_vieja (a.spriden_pidm) Primer_fecha_limite_de_pago,
                                                            PKG_REPORTES_1.f_fecha_pago_alta (a.spriden_pidm) Ultima_fecha_limite_de_pago,
                                                            PKG_REPORTES_1.f_dias_atraso  (a.spriden_pidm) Dias_Atraso,
                                                            trunc (PKG_REPORTES_1.f_dias_atraso  (a.spriden_pidm) / 30 )  Meses_Atraso,
                                                            PKG_REPORTES_1.f_mora  (a.spriden_pidm) Mora,
                                                            PKG_REPORTES_1.f_cargo_total_futuro (a.spriden_pidm) Total_montos_Prox,
                                                         --   PKG_REPORTES_1.f_saldocorte (a.spriden_pidm) Saldo_Prox,    ---------------------------------*****
                                                            null Saldo_Prox,    ---------------------------------*****
                                                            PKG_REPORTES_1.f_cargo_Numero_futuro (a.spriden_pidm) Numero_Cargos_Proximos,
                                                            to_date (PKG_REPORTES_1.f_fechacorte (a.spriden_pidm), 'dd/mm/rrrr') Prox_Fecha_Limite_Pag,
                                                            to_date (PKG_REPORTES_1.f_fechacorte (a.spriden_pidm),'dd/mm/rrrr' )  - trunc (sysdate) Num_Dias_Prox_Pago,
                                                            PKG_REPORTES_1.f_pago_total (a.spriden_pidm)  Suma_depositos,
                                                            PKG_REPORTES_1.f_num_total_pago (a.spriden_pidm)  Numero_Depositos,
                                                            (PKG_REPORTES_1.f_saldodia (a.spriden_pidm) * h.Incobrable) Monto_Incobrable,
                                                            case 
                                                            when h.Incobrable = .0 then 
                                                                     '0%'
                                                            when h.Incobrable = .5 then 
                                                                     '5%'
                                                            when h.Incobrable = .10 then 
                                                                     '10%'
                                                            when h.Incobrable = .20 then 
                                                                     '20%'
                                                            when h.Incobrable = .30 then 
                                                                     '30%'
                                                            when h.Incobrable = .60 then 
                                                                     '60%'
                                                            when h.Incobrable = .85 then 
                                                                     '85%'
                                                        End as Provision_Incobrable,
                                                            null Ultimo_Acceso_Plataforma,
                                                            null Rango_dias_acceso_plataforma,
                                                            PKG_REPORTES_1.f_jornada (a.spriden_pidm)   Jornada_Plan,
                                                            PKG_REPORTES_1.f_no_materia (a.spriden_pidm) Carga_Academica
                                                           , k.aprobadas Materias_Aprobadas
                                                           , k.avances   Avance_Curricular
                                                           , k.promedios  promedios  
                                                            ,to_date (PKG_REPORTES_1.f_fecha_Matriculacion (a.spriden_pidm), 'dd/mm/rrrr') Fecha_Matriculacion
                                                            ,PKG_REPORTES_1.f_periodo_inicial (a.spriden_pidm) Ciclo_Inicial
                                                            ,PKG_ACADEMICO_FINANCIEROREPORT.f_Estado_programa(a.spriden_pidm,k.programa) Estado_alumno_programa
                                                            ,nvl(k.programa, PP.SARADAP_PROGRAM_1)  Programa_Code
                                                            ,nvl(k.nomb_prog, (select SMRPRLE_PROGRAM_DESC from smrprle where SMRPRLE_PROGRAM = PP.SARADAP_PROGRAM_1  )   )  Nombre_Programa
                                                            ,nvl (PKG_REPORTES_1.f_Descuento (a.spriden_pidm), 0) Descuento
                                                           , pkg_utilerias.f_referencia(a.spriden_pidm) Referencia_Bancaria
                                                            ,(SELECT DISTINCT STVSTYP_DESC FROM STVSTYP WHERE STVSTYP_CODE =PP.SARADAP_STYP_CODE )  TIPO_INGRESO
                                                            ,A.SPRIDEN_CREATE_FDMN_CODE  ID_ALUMNO
                                                            , (select distinct  NVL( case when GORADID_ADID_CODE = 'INBE' then 'INBEC'
                                                                    when GORADID_ADID_CODE = 'NOMR' then 'NO MOLESTAR'
                                                                    when GORADID_ADID_CODE = 'RECU' then 'D.R.A'
                                                                    when GORADID_ADID_CODE = 'IZZI' then 'IZZI'
                                                                    when GORADID_ADID_CODE = 'ENVA' then 'ENVA'
                                                                    else Null
                                                                 end, 'NA') as Etiqueta1
                                                                 from goradid dd
                                                                 where  a.spriden_pidm = dd.GORADID_PIDM 
                                                                 and dd.GORADID_ADID_CODE in ('INBE', 'NOMR', 'RECU', 'IZZI','ENVA')
                                                                 and  rownum < 2
                                                               ) etiqueta
                                               from spriden a, saradap pp, avances_curr k,  Incobrable h
                                        Where A.SPRIDEN_CHANGE_IND is null 
                                        and a.spriden_id not in (select a1.matricula from BORPRUE a1)---> quita las mtarias de prueba
                                          And a.spriden_pidm = cx.pidm
                                         and a.spriden_pidm =  PP.SARADAP_PIDM
                                          and PP.SARADAP_APPL_NO  = ( select max(PP.SARADAP_APPL_NO)  from saradap pp1 where PP.SARADAP_PIDM = pp1.SARADAP_PIDM )  
                                            And a.spriden_pidm = k.Pidm (+)
                                            And a.spriden_pidm = h.Pidm (+)
                                            order by 1
                                            
                                          
                )loop

                            Begin 
                                Insert into TZTCRTE_AF values (acafin.usuario_id, 
                                                                        acafin.Matricula,
                                                                        acafin.Campus,
                                                                        acafin.Nivel_Code,
                                                                        acafin.Nivel_Academico,
                                                                        acafin.Nombre,
                                                                        acafin.Correo_Principal,
                                                                        acafin.Correo_Alterno,
                                                                        acafin.Telefono_Casa,
                                                                        acafin.Telefono_Celular,
                                                                        acafin.Saldo_Total,
                                                                        acafin.Saldo_Vencido,
                                                                        acafin.Numero_Cargo_Vencido,
                                                                        acafin.Primer_fecha_limite_de_pago,
                                                                        acafin.Ultima_fecha_limite_de_pago,
                                                                        acafin.Dias_Atraso,
                                                                        acafin.Meses_Atraso,
                                                                        acafin.Mora,
                                                                        acafin.Total_montos_Prox,
                                                                        acafin.Saldo_Prox,  ---------------------------------------------
                                                                        acafin.Numero_Cargos_Proximos,
                                                                        acafin.Prox_Fecha_Limite_Pag,
                                                                        acafin.Num_Dias_Prox_Pago,
                                                                        acafin.Suma_depositos,
                                                                        acafin.Numero_Depositos,
                                                                        acafin.Monto_Incobrable,
                                                                        acafin.Provision_Incobrable,
                                                                        acafin.Ultimo_Acceso_Plataforma,
                                                                        acafin.Rango_dias_acceso_plataforma,
                                                                        acafin.Jornada_Plan,
                                                                        acafin.Carga_Academica, --campo27
                                                                        acafin.Materias_Aprobadas, --campo28
                                                                        acafin.Avance_Curricular,  --campo29
                                                                        acafin.promedios, --campo30
                                                                        acafin.Fecha_Matriculacion,
                                                                        acafin.Ciclo_Inicial,
                                                                        acafin.Estado_alumno_programa,
                                                                        acafin.Programa_Code,
                                                                        acafin.Nombre_Programa,
                                                                        acafin.Descuento,
                                                                        acafin.Referencia_Bancaria,--campo37
                                                                        acafin.TIPO_INGRESO,   ---campo 38
                                                                        acafin.ID_ALUMNO,     ---campo39
                                                                        acafin.Etiqueta,    ----campo40
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        null,
                                                                        sysdate,
                                                                        'Academico_Financiero'
                                                                        );
                                                                        
                          Exception
                            When Others then 
                                null;
                          End;

                End loop;
            
        End Loop;
                  
        For cx in (
        
                    select s.spriden_pidm pidm , substr (spriden_id,1,2) id
                    from spriden s
                    where 1=1
                    and S.SPRIDEN_CHANGE_IND is null
                    and substr (spriden_id,1,2) in ('40')

        ) Loop


                     For acafin in (
                     
                     
                                      With   
                                        Incobrable as (
                                        select distinct 
                                        TZTMORA_PIDM PIDM,
                                        case 
                                            when TZTMORA_dias between 1 and 30 then 
                                                     .0
                                            when TZTMORA_dias between 31 and 60 then 
                                                     .5
                                            when TZTMORA_dias between 61 and 90 then 
                                                    .10
                                            when TZTMORA_dias between 91 and 120 then 
                                                    .20
                                            when TZTMORA_dias between 121 and 150 then 
                                                    .30
                                            when TZTMORA_dias between 151 and 180 then 
                                                    .60
                                            when TZTMORA_dias > 180 then 
                                                    .85
                                        End as Incobrable
                                        from TZTMORA)
                                        select distinct a.spriden_pidm usuario_id, 
                                                            a.spriden_id Matricula,
                                                            'BOT' campus,
                                                            'EC'  Nivel_Code,
                                                            ( select STVLEVL_DESC from stvlevl where STVLEVL_CODE = 'EC' ) Nivel_Academico,
                                                            a.SPRIDEN_LAST_NAME ||' '||SPRIDEN_FIRST_NAME Nombre,
                                                            nvl (trim (pkg_utilerias.f_correo(a.spriden_pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.spriden_pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.spriden_pidm, 'UTLX')) )) Correo_Principal, 
                                                            pkg_utilerias.f_correo(a.spriden_pidm, 'ALTE') Correo_Alterno,
                                                            pkg_utilerias.f_celular(a.spriden_pidm, 'RESI') Telefono_Casa,
                                                            pkg_utilerias.f_celular(a.spriden_pidm, 'CELU') Telefono_Celular,
                                                            PKG_REPORTES_1.f_saldototal (a.spriden_pidm) Saldo_Total,
                                                            PKG_REPORTES_1.f_saldodia (a.spriden_pidm) Saldo_Vencido,
                                                            PKG_REPORTES_1.f_cargo_vencidos (a.spriden_pidm) Numero_Cargo_Vencido,
                                                            PKG_REPORTES_1.f_fecha_pago_vieja (a.spriden_pidm) Primer_fecha_limite_de_pago,
                                                            PKG_REPORTES_1.f_fecha_pago_alta (a.spriden_pidm) Ultima_fecha_limite_de_pago,
                                                            PKG_REPORTES_1.f_dias_atraso  (a.spriden_pidm) Dias_Atraso,
                                                            trunc (PKG_REPORTES_1.f_dias_atraso  (a.spriden_pidm) / 30 )  Meses_Atraso,
                                                            PKG_REPORTES_1.f_mora  (a.spriden_pidm) Mora,
                                                            PKG_REPORTES_1.f_cargo_total_futuro (a.spriden_pidm) Total_montos_Prox,
                                                         --   PKG_REPORTES_1.f_saldocorte (a.spriden_pidm) Saldo_Prox,    ---------------------------------*****
                                                            null Saldo_Prox,    ---------------------------------*****
                                                            PKG_REPORTES_1.f_cargo_Numero_futuro (a.spriden_pidm) Numero_Cargos_Proximos,
                                                            to_date (PKG_REPORTES_1.f_fechacorte (a.spriden_pidm), 'dd/mm/rrrr') Prox_Fecha_Limite_Pag,
                                                            to_date (PKG_REPORTES_1.f_fechacorte (a.spriden_pidm),'dd/mm/rrrr' )  - trunc (sysdate) Num_Dias_Prox_Pago,
                                                            PKG_REPORTES_1.f_pago_total (a.spriden_pidm)  Suma_depositos,
                                                            PKG_REPORTES_1.f_num_total_pago (a.spriden_pidm)  Numero_Depositos,
                                                            (PKG_REPORTES_1.f_saldodia (a.spriden_pidm) * h.Incobrable) Monto_Incobrable,
                                                            case 
                                                            when h.Incobrable = .0 then 
                                                                     '0%'
                                                            when h.Incobrable = .5 then 
                                                                     '5%'
                                                            when h.Incobrable = .10 then 
                                                                     '10%'
                                                            when h.Incobrable = .20 then 
                                                                     '20%'
                                                            when h.Incobrable = .30 then 
                                                                     '30%'
                                                            when h.Incobrable = .60 then 
                                                                     '60%'
                                                            when h.Incobrable = .85 then 
                                                                     '85%'
                                                        End as Provision_Incobrable,
                                                            null Ultimo_Acceso_Plataforma,
                                                            null Rango_dias_acceso_plataforma,
                                                            PKG_REPORTES_1.f_jornada (a.spriden_pidm)   Jornada_Plan,
                                                            PKG_REPORTES_1.f_no_materia (a.spriden_pidm) Carga_Academica
                                                           , null Materias_Aprobadas
                                                           , null   Avance_Curricular
                                                           , null  promedios  
                                                            ,to_date (PKG_REPORTES_1.f_fecha_Matriculacion (a.spriden_pidm), 'dd/mm/rrrr') Fecha_Matriculacion
                                                            ,PKG_REPORTES_1.f_periodo_inicial (a.spriden_pidm) Ciclo_Inicial
                                                            ,null  Estado_alumno_programa
                                                            ,'BOTECSEMCU'  Programa_Code
                                                            ,'BOTECSEMCU CURSO EDUCACION CONTINUA'  Nombre_Programa
                                                            ,nvl (PKG_REPORTES_1.f_Descuento (a.spriden_pidm), 0) Descuento
                                                           , pkg_utilerias.f_referencia(a.spriden_pidm) Referencia_Bancaria
                                                            ,'NUEVO INGRESO'  TIPO_INGRESO
                                                            ,A.SPRIDEN_CREATE_FDMN_CODE  ID_ALUMNO
                                                            , (select distinct  NVL( case when GORADID_ADID_CODE = 'INBE' then 'INBEC'
                                                                    when GORADID_ADID_CODE = 'NOMR' then 'NO MOLESTAR'
                                                                    when GORADID_ADID_CODE = 'RECU' then 'D.R.A'
                                                                    when GORADID_ADID_CODE = 'IZZI' then 'IZZI'
                                                                    when GORADID_ADID_CODE = 'ENVA' then 'ENVA'
                                                                    else Null
                                                                 end, 'NA') as Etiqueta1
                                                                 from goradid dd
                                                                 where  a.spriden_pidm = dd.GORADID_PIDM 
                                                                 and dd.GORADID_ADID_CODE in ('INBE', 'NOMR', 'RECU', 'IZZI', 'ENVA')
                                                                 and  rownum < 2
                                                               ) etiqueta
                                               from spriden a
                                              left join Incobrable h on h.Pidm =  a.spriden_pidm 
                                        Where A.SPRIDEN_CHANGE_IND is null 
                                        and a.spriden_id not in (select a1.matricula from BORPRUE a1)---> quita las mtarias de prueba
                                          And a.spriden_pidm = cx.pidm
                                            order by 2                                            
                                          
                   )loop

                                    Begin 
                                        Insert into TZTCRTE_AF values (acafin.usuario_id, 
                                                                                acafin.Matricula,
                                                                                acafin.Campus,
                                                                                acafin.Nivel_Code,
                                                                                acafin.Nivel_Academico,
                                                                                acafin.Nombre,
                                                                                acafin.Correo_Principal,
                                                                                acafin.Correo_Alterno,
                                                                                acafin.Telefono_Casa,
                                                                                acafin.Telefono_Celular,
                                                                                acafin.Saldo_Total,
                                                                                acafin.Saldo_Vencido,
                                                                                acafin.Numero_Cargo_Vencido,
                                                                                acafin.Primer_fecha_limite_de_pago,
                                                                                acafin.Ultima_fecha_limite_de_pago,
                                                                                acafin.Dias_Atraso,
                                                                                acafin.Meses_Atraso,
                                                                                acafin.Mora,
                                                                                acafin.Total_montos_Prox,
                                                                                acafin.Saldo_Prox,  ---------------------------------------------
                                                                                acafin.Numero_Cargos_Proximos,
                                                                                acafin.Prox_Fecha_Limite_Pag,
                                                                                acafin.Num_Dias_Prox_Pago,
                                                                                acafin.Suma_depositos,
                                                                                acafin.Numero_Depositos,
                                                                                acafin.Monto_Incobrable,
                                                                                acafin.Provision_Incobrable,
                                                                                acafin.Ultimo_Acceso_Plataforma,
                                                                                acafin.Rango_dias_acceso_plataforma,
                                                                                acafin.Jornada_Plan,
                                                                                acafin.Carga_Academica, --campo27
                                                                                acafin.Materias_Aprobadas, --campo28
                                                                                acafin.Avance_Curricular,  --campo29
                                                                                acafin.promedios, --campo30
                                                                                acafin.Fecha_Matriculacion,
                                                                                acafin.Ciclo_Inicial,
                                                                                acafin.Estado_alumno_programa,
                                                                                acafin.Programa_Code,
                                                                                acafin.Nombre_Programa,
                                                                                acafin.Descuento,
                                                                                acafin.Referencia_Bancaria,--campo37
                                                                                acafin.TIPO_INGRESO,   ---campo 38
                                                                                acafin.ID_ALUMNO,     ---campo39
                                                                                acafin.Etiqueta,    ----campo40
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                null,
                                                                                sysdate,
                                                                                'Academico_Financiero'
                                                                                );
                                                                                
                                  Exception
                                    When Others then 
                                        null;
                                  End;

                  End loop;
            
                  commit;                


      end loop;    
      
        Begin 

                For cx in (

                                select distinct TZTCRTE_AF_PIDM pidm
                                from TZTCRTE_AF
                                where TZTCRTE_AF_TIPO_REPORTE =  'Academico_Financiero'
                             --   and TZTCRTE_AF_ID = '010017225'
                                
                 ) loop
                            
                        Begin
                                Update TZTCRTE_AF
                                set TZTCRTE_AF_CAMPO16 = PKG_REPORTES_1.f_saldocorte( cx.pidm) 
                                where TZTCRTE_AF_PIDM = cx.pidm;
                        End;
                        
                        Commit;

                End loop;
                        
        End;      
      
      
   exception when others then 
     null;
   END;

    
    
     

    END PKG_ACADEMICO_FINANCIEROREPORT;
/

DROP PUBLIC SYNONYM PKG_ACADEMICO_FINANCIEROREPORT;

CREATE OR REPLACE PUBLIC SYNONYM PKG_ACADEMICO_FINANCIEROREPORT FOR BANINST1.PKG_ACADEMICO_FINANCIEROREPORT;
