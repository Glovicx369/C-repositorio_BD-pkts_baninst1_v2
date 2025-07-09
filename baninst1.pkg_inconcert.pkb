DROP PACKAGE BODY BANINST1.PKG_INCONCERT;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_INCONCERT IS



procedure p_integra_inconcert is


/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */
 vl_pago number:=0;
 vl_pago_minimo number:=0;
 vl_sp number:=0;
 vl_existe number:=0;
 vl_campo varchar2(100):= null;
 
t_servicio  varchar2(100):= null;
t_serv_desc varchar2(250):= null;
t_estatus varchar2(250):= null;
t_fecha_Captura date:= null;
t_pago varchar2(250):= null;

BEGIN


 ------------------------------- Este proceso se debera de encender cuando se libere la integracion de CRM ------------------------------
         Begin
                 EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.TZTPROG_FREE';
                COMMIT;
         Exception
         When Others then
            null;
         End;

         Begin
                 insert into tztprog_free
                 select a.*
                 from TZTPROG_INCR a
                 where 1= 1
                 And pidm in (select SGRSCMT_PIDM
                 from SGRSCMT
                 where SGRSCMT_COMMENT_TEXT like '%FREEMI%')
                 And a.sp = (select max (a1.sp)
                 from TZTPROG_INCR a1
                 Where a.pidm = a1.pidm
                 And a.estatus = a1.estatus
                 )
                 union
                 select distinct a.*
                 from TZTPROG_INCR a
                 join goradid b on b.goradid_pidm = a.pidm and b.GORADID_ADID_CODE in ( Select ZSTPARA_PARAM_VALOR
                 from ZSTPARA
                 where 1= 1
                 -- And ZSTPARA_PARAM_VALOR = 'FREE'
                 And ZSTPARA_MAPA_ID = 'FREEMIUM_ADID'
                 )
                 Where 1= 1
                 And a.sp = (select max (a1.sp)
                 from TZTPROG_INCR a1
                 Where a.pidm = a1.pidm
                 And a.estatus = a1.estatus
                 ) ;
                 Exception
                 When Others then
                 null;
         End;



         Begin


                 For cx in (

                 select distinct PIDM, matricula
                 from tztprog_free

                 ) loop


                 ----------- Se obtiene el monto para el primer pago ----------------
                 vl_pago_minimo:=0;
                 vl_pago:=0;
                 vl_sp :=0;
                 Begin

                 select distinct TZFACCE_AMOUNT, TZFACCE_STUDY
                 Into vl_pago_minimo, vl_sp
                 from TZFACCE
                 where 1= 1
                 And TZFACCE_PIDM = cx.pidm
                 And TZFACCE_DETAIL_CODE = 'PRIM'
                 and TZFACCE_FLAG = 0;

                 Exception
                 When Others then
                 vl_pago_minimo :=0;
                 vl_sp :=1;
                 End;

                 Begin

                 select nvl (sum (a3.tbraccd_amount), 0) Monto
                 Into vl_pago
                 from tbraccd a3
                 Where a3.tbraccd_pidm = cx.pidm
                 And a3.TBRACCD_STSP_KEY_SEQUENCE = vl_sp
                 And a3.tbraccd_detail_code in (select TZTNCD_CODE
                 from TZTNCD
                 Where TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                 );

                 Exception
                 When Others then
                 vl_pago:=0;
                 End;



                 If vl_pago >= vl_pago_minimo then

                         Begin
                         Delete tztprog_free
                         Where pidm = cx.pidm;
                         Exception
                         When Others then
                         null;
                         End;
                 End if;


         End Loop;
         Commit;
         End;



         Begin
                     for c in (

                                    select distinct a.matricula, a.programa, a.estatus, a.sp
                                    from TZTPROG_INCR a
                                    Where 1= 1
                                    And a.estatus not in ('CP')
                                    And a.sp = (select max (a1.sp)
                                                         from TZTPROG_INCR a1
                                                         Where a.pidm = a1.pidm
                                                         and a1.campus||a1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                                                           And a.programa = a1.programa
                                                          And a.estatus = a1.estatus
                                                            )
                                    And (a.matricula, a.sp) not in (select b.matricula, b.sp
                                                                                from tztprog_free b)
                                    And a.campus in  ('GLO', 'FIL','IND','VIE','INA','GAS','PER','COL','ECU','UTL','UTS', 'USA','ARG', 'DOM','GUA','PAN','CHI', 'SAL', 'BOL', 'PAR', 'COE',
                                                      'ESP','NIC','HON','INT','COS','URU'
                                                    )
                              ---      and fecha_inicio = '04/07/2022'
                              ---     And matricula in ('010778279', '010778280', '010778281')  ----"Pon aqui la matricula Fernando"
                                    order by a.estatus, a.sp , 1 asc 
                                  


                     ) loop

                        vl_existe:=0;
                           Begin
                                    Select count(1)
                                              Into vl_existe
                                    from SZTECRM a
                                    where a.matricula = c.matricula
                                    And a.programa = c.programa;
                           Exception
                            When Others then
                                vl_existe:=0;
                           End;

                          If vl_existe = 0 then
                          
                            -- dbms_output.put_line('No Existe' ||c.matricula ||'*'||c.programa );

                                    Begin
                                         insert into SZTECRM
                                         select distinct a.pidm,
                                         a.matricula,
                                         substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1) Paterno ,
                                         substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150) Materno,
                                         SPRIDEN_FIRST_NAME Nombre,
                                         a.campus,
                                         a.nivel,
                                         a.ESTATUS_D estatus,
                                         a.programa,
                                         pkg_utilerias.f_modalidad(a.programa, a.ctlg) Modalidad,
                                         decode (substr (pkg_utilerias.f_calcula_rate(a.pidm, a.programa), length (pkg_utilerias.f_calcula_rate(a.pidm, a.programa))-1 ,1),'A','15','B', '30')  Fecha_Corte ,
                                         trunc (a.fecha_inicio) Fecha_Inicio,
                                           (select distinct max (SZTHITA_E_CURSO)
                                            from szthita
                                            where 1= 1
                                            and SZTHITA_PIDM = a.pidm
                                            and SZTHITA_STUDY = a.sp ) Materias_Inscritas,
                                           (select distinct max (SZTHITA_APROB)
                                            from szthita
                                            where 1= 1
                                            and SZTHITA_PIDM = a.pidm
                                            and SZTHITA_STUDY = a.sp ) Materias_Aprobadas,
                                            nvl ((select distinct max(SZTHITA_AVANCE)
                                            from szthita
                                            where 1= 1
                                            and SZTHITA_PIDM = a.pidm
                                            and SZTHITA_STUDY = a.sp ),0) Avance_Curricular,
                                             substr (pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel,  pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp) ),
                                                    length (pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel,  pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp))) ,1
                                                    ) Jornada,
                                           trunc( (   select distinct max (SARAPPD_APDC_DATE)
                                                from saradap
                                                join sarappd on SARAPPD_PIDM = SARADAP_PIDM and SARAPPD_TERM_CODE_ENTRY =  SARADAP_TERM_CODE_ENTRY and SARAPPD_APPL_NO = SARADAP_APPL_NO
                                                where saradap_pidm = a.pidm
                                                --And SARADAP_LEVL_CODE
                                                And SARADAP_PROGRAM_1 = a.programa
                                                and SARAPPD_APDC_CODE =35     ) ) Fecha_Desicion,
                                               Nvl ((  select decode (count(1),'0', 'SinFacturacion', '1', 'ConFacturacion')
                                                from SPREMRG
                                                where 1=1
                                                and SPREMRG_pidm = a.pidm),'SinFacturacion')  Factura,
                                                nvl (PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(a.pidm),0) Saldo_Total,
                                                nvl (PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(a.pidm),0) Saldo_Dia,
                                                round (nvl (PKG_REPORTES_1.f_dias_atraso(a.pidm),0)) Dias_atraso,
                                                round(nvl (PKG_REPORTES_1.f_dias_atraso(a.pidm),0) / 30) Meses_atraso,
                                                nvl (PKG_REPORTES_1.f_mora(a.pidm),0) Mora,
                                                (select count(*)
                                                from tbraccd, TZTNCD
                                                where tbraccd_detail_code = TZTNCD_CODE
                                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                And tbraccd_pidm = a.pidm)  Depositos,
                                         0,
                                         null,
                                         sysdate,
                                         a.sp,
                                         pkg_utilerias.f_servicio_social(a.pidm) Servicio_Social,
                                         (
                                            select distinct max (substr (ax.TBBESTU_EXEMPTION_CODE, 4,3)) Beca
                                            from TBBESTU ax
                                            where ax.TBBESTU_PIDM = a.pidm  and a.nivel =  decode (substr (ax.TBBESTU_EXEMPTION_CODE,1,2),'20', 'MA', '10', 'LI', '90','DO', '10', 'BA')
                                            and ax.TBBESTU_TERM_CODE = (select max (a1.TBBESTU_TERM_CODE)
                                                                                             from TBBESTU a1
                                                                                             Where ax.TBBESTU_PIDM = a1.TBBESTU_PIDM
                                                                                             and substr (ax.TBBESTU_EXEMPTION_CODE,1,2) = substr (a1.TBBESTU_EXEMPTION_CODE,1,2)
                                                                                             )
                                           )  Beca,
                                           'ADMITIDO' desicion,
                                           null,
                                            PKG_UTILERIAS.f_escuela(a.programa) Desc_Escuela,
                                            PKG_UTILERIAS.f_programa_desc(a.programa) Desc_Programa,
                                            PKG_UTILERIAS.f_Jornada_desc(pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel,  pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp))) Desc_Jornada,
                                            PKG_UTILERIAS.f_periodo_desc(a.MATRICULACION) Desc_Periodo,
                                            a.matricula||a.programa||a.sp,
                                            pkg_utilerias.f_celular(a.pidm, 'CELU') Celular,
                                            pkg_utilerias.f_celular(a.pidm, 'RESI') Residencia,
                                            PKG_INCONCERT.f_genero(a.pidm) Genero,
                                            to_date (pkg_utilerias.f_fecha_nac(a.pidm),'dd/mm/rrrr') Fecha_Nac,
                                            PKG_INCONCERT.f_nacionalidad(a.pidm) Nacionalidad,
                                             nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) Correo_Principal,
                                             null,
                                             null,
                                             null,
                                             null,
                                             null,
                                         nvl (a.FECHA_PRIMERA,a.FECHA_INICIO) Primer_Materia,
                                         trim (pkg_utilerias.f_cadena_etiqueta(a.pidm)) etiquetas , 
                                         (select distinct SPBPERS_SSN
                                            from SPBPERS
                                            where 1=1
                                            And  SPBPERS_pidm = a.pidm
                                            And SPBPERS_SSN is not null)  NSS ,
                                            0, 
                                            NULL,
                                            pkg_utilerias.f_correo(a.pidm, 'ALTE') correo_Alterno, ---> Correo Alternativo
                                            pkg_inconcert.f_fecha_pago(a.pidm) Fecha_pago, ---> Fecha_Pago
                                            pkg_inconcert.f_fecha_pago_ultima(a.pidm) Fecha_Ultimo_Pago, ---> Fecha_ultimo_pago
                                            pkg_inconcert.f_pago_col(a.pidm) Estatus_Pago, ---> Estatus_pago 
                                            pkg_inconcert.f_monto_col_pago(a.pidm) Monto_pago, ---> Monto_pago
                                            pkg_inconcert.f_col_cargo_mes(a.pidm) Monto_Mensual, ---> Monto_Mensual
                                            pkg_inconcert.f_col_primer_pago(a.pidm) Monto_primer_pago, ---> Monto_primer_pago
                                            pkg_inconcert.f_numero_pago(a.pidm) Numero_Depositos, ---> Numero de depositos
                                            a.TIPO_INGRESO_DESC Tipo_Ingreso, ---> Tipo_Ingreso
                                            pkg_inconcert.f_fecha_complemento(a.pidm) Fecha_complemento, ---> Fecha_complemento
                                            stvSTYP_desc Tipo_alumno,   --------> Tipo Alumno
                                             a.FECHA_MOV Fecha_Estatus,  -------> Fecha Estatus
                                             null   --> FECHA_ACTUALIZACION                                             
                                         from TZTPROG_INCR a
                                         join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
                                         join stvSTYP on stvSTYP_code = A.SGBSTDN_STYP_CODE
                                         where 1= 1
                                         And a.estatus not in ('CV', 'CP')
                                         And a.sp = (select max (a1.sp)
                                                             from TZTPROG_INCR a1
                                                             Where a.pidm = a1.pidm
                                                             and a1.campus||a1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                                                             And a1.programa = a.programa
                                                         --    And trunc (a.fecha_inicio) = trunc (a1.fecha_inicio)
                                                             And a.estatus = a1.estatus
                                                             )
                                      And a.matricula = c.matricula
                                         And a.programa = c.programa
                                         Order by 1 desc ;
                                        Commit;

                                    Exception
                                     When Others then
                                     null;
                                  --   dbms_output.put_line('Error al insertar Matricula' ||c.matricula ||'*'||c.programa||'*'||sqlerrm );
                                    End;

                          Else -----> Actualiza los cambios en la tabla de CRM
                          
                             dbms_output.put_line('Entra para Actualizar' ||c.matricula ||'*'||c.programa );
                           Begin
                            
                                For cx in (

                                         select distinct a.pidm,
                                         a.matricula,
                                         substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1) Paterno ,
                                         substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150) Materno,
                                         SPRIDEN_FIRST_NAME Nombre,
                                         a.campus,
                                         a.nivel,
                                         a.ESTATUS_D estatus,
                                         a.programa,
                                         pkg_utilerias.f_modalidad(a.programa, a.ctlg) Modalidad,
                                         decode (substr (pkg_utilerias.f_calcula_rate(a.pidm, a.programa), length (pkg_utilerias.f_calcula_rate(a.pidm, a.programa))-1 ,1),'A','15','B', '30')  Fecha_Corte ,
                                         trunc (a.fecha_inicio) Fecha_Inicio,
                                         (select distinct max(SZTHITA_E_CURSO)
                                            from szthita
                                            where 1= 1
                                            and SZTHITA_PIDM = a.pidm
                                            and SZTHITA_STUDY = a.sp ) Materias_Inscritas,
                                          (select distinct max (SZTHITA_APROB)
                                            from szthita
                                            where 1= 1
                                            and SZTHITA_PIDM = a.pidm
                                            and SZTHITA_STUDY = a.sp ) Materias_Aprobadas,
                                            nvl ((select distinct max (SZTHITA_AVANCE)
                                            from szthita
                                            where 1= 1
                                            and SZTHITA_PIDM = a.pidm
                                            and SZTHITA_STUDY = a.sp ),0) Avance_Curricular,
                                            substr (pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel,  pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp) ),
                                                    length (pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel,  pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp))) ,1
                                                    ) Jornada,
                                             TRunc( (   select distinct max (SARAPPD_APDC_DATE)
                                                from saradap
                                                join sarappd on SARAPPD_PIDM = SARADAP_PIDM and SARAPPD_TERM_CODE_ENTRY =  SARADAP_TERM_CODE_ENTRY and SARAPPD_APPL_NO = SARADAP_APPL_NO
                                                where saradap_pidm = a.pidm
                                                --And SARADAP_LEVL_CODE
                                                And SARADAP_PROGRAM_1 = a.programa
                                                and SARAPPD_APDC_CODE =35     ) ) Fecha_Desicion,
                                               Nvl ((  select decode (count(1),'0', 'SinFacturacion', '1', 'ConFacturacion')
                                                from SPREMRG
                                                where 1=1
                                                and SPREMRG_pidm = a.pidm),'SinFacturacion')  Factura,
                                                nvl (PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(a.pidm),0) Saldo_Total,
                                                nvl (PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(a.pidm),0) Saldo_Dia,
                                                round(nvl (PKG_REPORTES_1.f_dias_atraso(a.pidm),0)) Dias_atraso,
                                                round(nvl (PKG_REPORTES_1.f_dias_atraso(a.pidm),0) / 30) Meses_atraso,
                                                nvl (PKG_REPORTES_1.f_mora(a.pidm),0) Mora,
                                                (select count(*)
                                                from tbraccd, TZTNCD
                                                where tbraccd_detail_code = TZTNCD_CODE
                                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                And tbraccd_pidm = a.pidm)  Depositos,
                                                 pkg_utilerias.f_servicio_social(a.pidm) Servicio_Social,
                                                 (
                                                    select distinct max (substr (ax.TBBESTU_EXEMPTION_CODE, 4,3)) Beca
                                                    from TBBESTU ax
                                                    where ax.TBBESTU_PIDM = a.pidm  and a.nivel =  decode (substr (ax.TBBESTU_EXEMPTION_CODE,1,2),'20', 'MA', '10', 'LI', '90','DO', '10', 'BA')
                                                    and ax.TBBESTU_TERM_CODE = (select max (a1.TBBESTU_TERM_CODE)
                                                                                                     from TBBESTU a1
                                                                                                     Where ax.TBBESTU_PIDM = a1.TBBESTU_PIDM
                                                                                                     and substr (ax.TBBESTU_EXEMPTION_CODE,1,2) = substr (a1.TBBESTU_EXEMPTION_CODE,1,2)
                                                                                                     )
                                                   )  Beca ,
                                                   'ADMITIDO' Desicion,
                                            PKG_UTILERIAS.f_escuela(a.programa) Desc_Escuela,
                                            PKG_UTILERIAS.f_programa_desc(a.programa) Desc_Programa,
                                            PKG_UTILERIAS.f_Jornada_desc(pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel,  pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp))) Desc_Jornada,
                                            PKG_UTILERIAS.f_periodo_desc(pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp)) Periodo_desc,
                                            pkg_utilerias.f_celular(a.pidm, 'CELU') MOVIL,
                                            pkg_utilerias.f_celular(a.pidm, 'RESI') TELEFONO_CASA,
                                            PKG_INCONCERT.f_genero(a.pidm) GENERO,
                                            to_date (pkg_utilerias.f_fecha_nac(a.pidm),'dd/mm/rrrr') FECHA_NACIMIENTO,
                                            PKG_INCONCERT.f_nacionalidad(a.pidm) NACIONALIDAD,
                                             nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) CORREO_ELECTRONICO,
                                             nvl (a.FECHA_PRIMERA,a.FECHA_INICIO) Primer_Materia,
                                             trim (pkg_utilerias.f_cadena_etiqueta(a.pidm)) etiquetas,
                                            (select distinct SPBPERS_SSN
                                                    from SPBPERS
                                                    where 1=1
                                                    And  SPBPERS_pidm = a.pidm
                                                    And SPBPERS_SSN is not null)  NSS,
                                            pkg_utilerias.f_correo(a.pidm, 'ALTE') correo_Alterno, ---> Correo Alternativo
                                            pkg_inconcert.f_fecha_pago(a.pidm) Fecha_pago, ---> Fecha_Pago
                                            pkg_inconcert.f_fecha_pago_ultima(a.pidm) Fecha_Ultimo_Pago, ---> Fecha_ultimo_pago
                                            pkg_inconcert.f_pago_col(a.pidm) Estatus_Pago, ---> Estatus_pago 
                                            pkg_inconcert.f_monto_col_pago(a.pidm) Monto_pago, ---> Monto_pago
                                            pkg_inconcert.f_col_cargo_mes(a.pidm) Monto_Mensual, ---> Monto_Mensual
                                            pkg_inconcert.f_col_primer_pago(a.pidm) Monto_primer_pago, ---> Monto_primer_pago
                                            pkg_inconcert.f_numero_pago(a.pidm) Numero_Depositos, ---> Numero de depositos
                                            a.TIPO_INGRESO_DESC Tipo_Ingreso, ---> Tipo_Ingreso
                                            pkg_inconcert.f_fecha_complemento(a.pidm) Fecha_complemento, ---> Fecha_complemento       
                                            a.sp,
                                            stvSTYP_desc Tipo_alumno,
                                            a.FECHA_MOV Fecha_Estatus                                                                                                                                                                                        
                                         from TZTPROG_INCR a
                                         join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
                                         join stvSTYP on stvSTYP_code = SGBSTDN_STYP_CODE
                                         where 1= 1
                                         And a.estatus not in ('CP')
                                         And a.sp = (select max (a1.sp)
                                                             from TZTPROG_INCR a1
                                                             Where a.pidm = a1.pidm
                                                             and a1.campus||a1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                                                             And a1.programa = a.programa
                                                      --       And trunc (a.fecha_inicio) = trunc (a1.fecha_inicio)
                                                             And a.estatus = a1.estatus
                                                             )
                                      And a.matricula =c.matricula
                                         And a.programa = c.programa
                                           order by a.pidm , a.sp desc

                            ) loop

                          ---------------------- Bloque para actualizar por cada uno de los campos de la tabla --------------
                                --dbms_output.put_line('Recupero datos ' || cx.matricula ||cx.paterno ||'*'||vl_campo );

                                Begin
                                        Select paterno
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;
                    
                                --dbms_output.put_line('Entra para Paterno ' || cx.matricula ||cx.paterno ||'*'||vl_campo );
                
                                If cx.paterno = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para Paterno ' || cx.matricula ||cx.paterno ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.paterno = cx.paterno,
                                                     a.estatus_envio = 0,
                                                     a.ESTATUS_ENVIO_EE = 0,
                                                     a.OBSERVACIONES_ee = 'Se actualizo Paterno',
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Paterno'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                           --------------- Materno-----------
                                vl_campo:= null;
                                Begin
                                        Select materno
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.materno = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para materno ' || cx.matricula|| '*' ||cx.materno ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.materno = cx.materno,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Materno',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Materno'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                           --------------- Nombre-----------
                                vl_campo:= null;
                                Begin
                                        Select nombre
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;



                                If cx.nombre = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para nombre ' || cx.matricula|| '*' ||cx.nombre ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.nombre = cx.nombre,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Nombre',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Nombre'
                                             where a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                           --------------- Estatus-----------
                                vl_campo:= null;
                                Begin
                                        Select estatus
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.estatus = vl_campo then 
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para estatus ' || cx.matricula|| '*' ||cx.estatus ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.estatus = cx.estatus,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Estatus',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Estatus'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                           --------------- modalidad-----------
                                vl_campo:= null;
                                Begin
                                        Select modalidad
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.modalidad = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para modalidad ' || cx.matricula|| '*'||cx.modalidad ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.modalidad = cx.modalidad,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Modalidad',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Modalidad'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                          --------------- Fecha Corte-----------
                                vl_campo:= null;
                                Begin
                                        Select fecha_corte
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;
                                

                                If cx.fecha_corte = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para fecha_corte '|| cx.matricula|| '*' ||cx.fecha_corte ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.fecha_corte = cx.fecha_corte,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Fecha Corte',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Fecha Corte'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                          --------------- FECHA_INICIO-----------
                                vl_campo:= null;
                                Begin
                                        Select FECHA_INICIO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.FECHA_INICIO = vl_campo then
                                   null;
                                Else
                                  --dbms_output.put_line('Entra para FECHA_INICIO ' || cx.matricula|| '*'||cx.FECHA_INICIO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.FECHA_INICIO = cx.FECHA_INICIO,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Fecha_Inicio',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Fecha_Inicio'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                        --------------- MATERIAS_INSCRITAS-----------
                                vl_campo:= null;
                                Begin
                                        Select MATERIAS_INSCRITAS
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

 
                                If cx.MATERIAS_INSCRITAS = vl_campo then
                                    null;
                                Else
                                  --dbms_output.put_line('Entra para MATERIAS_INSCRITAS '|| cx.matricula|| '*' ||cx.MATERIAS_INSCRITAS ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.MATERIAS_INSCRITAS = cx.MATERIAS_INSCRITAS,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Inscritas',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Inscritas'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;


                        --------------- MATERIAS_APROBADAS-----------
                                vl_campo:= null;
                                Begin
                                        Select MATERIAS_APROBADAS
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.MATERIAS_APROBADAS = vl_campo then
                                   null;
                                Else
                                  --dbms_output.put_line('Entra para MATERIAS_APROBADAS '|| cx.matricula|| '*' ||cx.MATERIAS_APROBADAS ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.MATERIAS_APROBADAS = cx.MATERIAS_APROBADAS,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Aprobadas',
                                                     a.OBSERVACIONES = 'Se actualizo Aprobadas'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                        --------------- AVANCE_CURRICULAR-----------
                                vl_campo:= null;
                                Begin
                                        Select AVANCE_CURRICULAR
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.AVANCE_CURRICULAR = vl_campo then
                                  null;
                                Else
                                 --dbms_output.put_line('Entra para AVANCE_CURRICULAR ' || cx.matricula|| '*'||cx.AVANCE_CURRICULAR ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.AVANCE_CURRICULAR = cx.AVANCE_CURRICULAR,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Avance Currcular',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Avance Currcular'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;


                                                --------------- JORNADA-----------
                                vl_campo:= null;
                                Begin
                                        Select JORNADA
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.JORNADA = vl_campo then
                                    null;
                                Else
                                 --dbms_output.put_line('Entra para JORNADA ' || cx.matricula|| '*'||cx.JORNADA ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.JORNADA = cx.JORNADA,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Jornada',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Jornada'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                        --------------- FECHA_DESICION-----------
                                vl_campo:= null;
                                Begin
                                        Select FECHA_DESICION
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.FECHA_DESICION = vl_campo then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para FECHA_DESICION '|| cx.matricula|| '*' ||cx.FECHA_DESICION ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.FECHA_DESICION = cx.FECHA_DESICION,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Desicion',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Desicion'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                        --------------- FACTURA-----------
                                vl_campo:= null;
                                Begin
                                        Select FACTURA
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.FACTURA = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para FACTURA ' || cx.matricula|| '*'||cx.FACTURA ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.FACTURA = cx.FACTURA,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Factura',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Factura'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                        --------------- SALDO_TOTAL-----------
                                vl_campo:= null;
                                Begin
                                        Select SALDO_TOTAL
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.SALDO_TOTAL = vl_campo then
                                    null;
                                Else
                                   --dbms_output.put_line('Entra para SALDO_TOTAL '|| cx.matricula|| '*' ||cx.SALDO_TOTAL ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.SALDO_TOTAL = cx.SALDO_TOTAL,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Saldo Total',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Saldo Total'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                        --------------- SALDO_DIA-----------
                                vl_campo:= null;
                                Begin
                                        Select SALDO_DIA
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.SALDO_DIA = vl_campo then
                                    null;
                                Else
                                 --dbms_output.put_line('Entra para SALDO_DIA ' || cx.matricula|| '*'||cx.SALDO_DIA ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.SALDO_DIA = cx.SALDO_DIA,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Saldo Dia',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Saldo Dia'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                        --------------- DIAS_ATRASO-----------
                                vl_campo:= null;
                                Begin
                                        Select DIAS_ATRASO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.DIAS_ATRASO = vl_campo then
                                       null;
                                Else
                                 --dbms_output.put_line('Entra para DIAS_ATRASO ' || cx.matricula|| '*'||cx.DIAS_ATRASO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.DIAS_ATRASO = cx.DIAS_ATRASO,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Dias Atraso',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Dias Atraso'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                       --------------- MESES_ATRASO-----------
                                vl_campo:= null;
                                Begin
                                        Select MESES_ATRASO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.MESES_ATRASO = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para MESES_ATRASO '|| cx.matricula|| '*' ||cx.MESES_ATRASO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.MESES_ATRASO = cx.MESES_ATRASO,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Meses Atraso',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Meses Atraso'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                       --------------- MORA-----------
                                vl_campo:= null;
                                Begin
                                        Select MORA
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.MORA = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para MORA '|| cx.matricula|| '*' ||cx.MORA ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.MORA = cx.MORA,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 1,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Mora',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Mora'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                       --------------- DEPOSITOS-----------
                                vl_campo:= null;
                                Begin
                                        Select DEPOSITOS
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.DEPOSITOS = vl_campo then
                                   null;
                                Else
                                 --dbms_output.put_line('Entra para DEPOSITOS '|| cx.matricula|| '*' ||cx.DEPOSITOS ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.DEPOSITOS = cx.DEPOSITOS,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Depositos',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Depositos'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;

                                                                      --------------- Servicio Social-----------
                                vl_campo:= null;
                                Begin
                                        Select SERVICIO_SOCIAL
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;


                                If cx.SERVICIO_SOCIAL = vl_campo then
                                    null;
                                Else
                                 --dbms_output.put_line('Entra para SERVICIO_SOCIAL '|| cx.matricula|| '*' ||cx.SERVICIO_SOCIAL ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.SERVICIO_SOCIAL = cx.SERVICIO_SOCIAL,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Servicio Social',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Servicio Social'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;


                                                                      ----------Beca----------
                                vl_campo:= null;
                                Begin
                                        Select BECA
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.BECA = vl_campo then
                                    null;
                                Else
                                        --dbms_output.put_line('Entra para BECA ' || cx.matricula|| '*'||cx.BECA ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.BECA = cx.BECA,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Beca',
                                                    a.OBSERVACIONES_ee = 'Se actualizo Beca'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;
                                 

                           -------------------------------------Movil -------------------------------------------------
                           --dbms_output.put_line('Entra para Movil ' || cx.matricula|| '*'||cx.MOVIL ||'*'||vl_campo );
                                vl_campo:= null;
                                Begin
                                        Select MOVIL
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                --dbms_output.put_line('Entra para recuperer Movil ' || cx.matricula|| '*'||cx.MOVIL ||'*'||vl_campo );
                         
                                If  (vl_campo) = (cx.MOVIL)  then
                                    null;
                                Else
                                        --dbms_output.put_line('Entra para Movil xxx ' || cx.matricula|| '*'||cx.MOVIL ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.MOVIL = cx.MOVIL,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo el Movil',
                                                    a.OBSERVACIONES_ee = 'Se actualizo el Movil'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                                 
                                 
                           -------------------------------------TELEFONO_CASA -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select TELEFONO_CASA
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.TELEFONO_CASA = vl_campo then
                                    null;
                                Else
                                        --dbms_output.put_line('Entra para Telefono Casa ' || cx.matricula|| '*'||cx.TELEFONO_CASA ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.TELEFONO_CASA = cx.TELEFONO_CASA,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo el Telefono Casa',
                                                    a.OBSERVACIONES_ee = 'Se actualizo el Telefono Casa'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;    
                                 
                           -------------------------------------GENERO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select GENERO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.GENERO = vl_campo then
                                    null;
                                Else
                                        --dbms_output.put_line('Entra para GENERO ' || cx.matricula|| '*'||cx.GENERO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.GENERO = cx.GENERO,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo el Genero',
                                                    a.OBSERVACIONES_ee = 'Se actualizo el Genero'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;    

                          -------------------------------------FECHA_NACIMIENTO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select FECHA_NACIMIENTO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.FECHA_NACIMIENTO = vl_campo then
                                   null;
                                Else
                                        --dbms_output.put_line('Entra para FECHA_NACIMIENTO ' || cx.matricula|| '*'||cx.FECHA_NACIMIENTO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.FECHA_NACIMIENTO = cx.FECHA_NACIMIENTO,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo la fecha de Nacimiento',
                                                    a.OBSERVACIONES_ee = 'Se actualizo la fecha de Nacimiento'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;    
                                 
                           
                          -------------------------------------NACIONALIDAD -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (NACIONALIDAD)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If trim (cx.NACIONALIDAD) = trim (vl_campo) then
                                    null;
                                Elsif trim (cx.NACIONALIDAD) is null then 
                                    null;
                                Else
                                        --dbms_output.put_line('Entra para NACIONALIDAD ' || cx.matricula|| '*'||cx.NACIONALIDAD ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.NACIONALIDAD = cx.NACIONALIDAD,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo la nacionalidad',
                                                    a.OBSERVACIONES_ee = 'Se actualizo la nacionalidad'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;        
                                                            
                                 
                          -------------------------------------CORREO_ELECTRONICO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select CORREO_ELECTRONICO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.CORREO_ELECTRONICO = vl_campo then
                                    null;
                                Else
                                       -- dbms_output.put_line('Entra para CORREO_ELECTRONICO ' || cx.matricula|| '*'||cx.CORREO_ELECTRONICO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.CORREO_ELECTRONICO = cx.CORREO_ELECTRONICO,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo el correo electronico',
                                                    a.OBSERVACIONES_ee = 'Se actualizo el correo electronico'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                                     
                                 
                                 
                         -------------------------------------Primer fecha de Materia Inscrita -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select FECHA_PRIMERA
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.Primer_Materia = vl_campo then
                                    null;
                                Else
                                        dbms_output.put_line('Entra para Fecha_Primera ' || cx.matricula|| '*'||cx.Primer_Materia ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.FECHA_PRIMERA = cx.Primer_Materia,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Fecha_primera Inscripcion',
                                                    a.OBSERVACIONES_ee = 'Se actualizo Fecha_primera Inscripcion'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                                     
                     
                         -------------------------------------Etiquetas Generadas -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (ETIQUETAS)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         --  dbms_output.put_line('Entra para etiquetas ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||(cx.ETIQUETAS) );
                           
                                If trim (cx.etiquetas) = trim (vl_campo) then
                                    null;
                                   -- dbms_output.put_line('No hace nada etiquetas' );
                                ElsIf trim (cx.etiquetas) is null then 
                                    null;
                                  --  dbms_output.put_line('No hace nada etiquetas' );
                               
                                Else
                                     --  dbms_output.put_line('Entra para actualizar etiquetas ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||(cx.ETIQUETAS) );
                                        Begin
                                            Update sztecrm a
                                                set a.ETIQUETAS = cx.ETIQUETAS,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Etiquetas',
                                                    a.OBSERVACIONES_ee = 'Se actualizo Etiquetas'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                                     
                                 
                              
                                 
                                 
                         -------------------------------------Etiquetas NSS -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (NSS)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                              --  dbms_output.put_line('Entra para NSS ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||(cx.NSS) );
                         
                                If trim (cx.NSS) = trim (vl_campo) then
                                    null;
                                   -- dbms_output.put_line('No hace nada NSS' );
                                ElsIf trim (cx.NSS) is null then
                                    null;
                                   -- dbms_output.put_line('No hace nada NSS' );
                                Else
                                
                               -- dbms_output.put_line('Entra Actualizar NSS' );
                                        Begin
                                            Update sztecrm a
                                                set a.NSS = cx.NSS,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo NSS',
                                                    a.OBSERVACIONES_ee = 'Se actualizo NSS'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                                     
                                 

                         ------------------------------------- Correo Alterno  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (CORREO_ALTERNO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.correo_Alterno) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.correo_Alterno) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.CORREO_ALTERNO = cx.correo_Alterno
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo Correo Alterno',
--                                                a.OBSERVACIONES_ee = 'Se actualizo Correo Alterno'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                 
                         
                         ------------------------------------- Fecha_pago  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (FECHA_PAGO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_PAGO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_PAGO) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.FECHA_PAGO = cx.FECHA_PAGO
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo FECHA_PAGO',
--                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_PAGO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                              
                         
                         ------------------------------------- FECHA_ULTIMO_PAGO  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (FECHA_ULTIMO_PAGO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_ULTIMO_PAGO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_ULTIMO_PAGO) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.FECHA_ULTIMO_PAGO = cx.FECHA_ULTIMO_PAGO
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo FECHA_ULTIMO_PAGO',
--                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_ULTIMO_PAGO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;     
                                 
  
                           ------------------------------------- ESTATUS_PAGO  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (ESTATUS_PAGO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ESTATUS_PAGO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ESTATUS_PAGO) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.ESTATUS_PAGO = cx.ESTATUS_PAGO
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo ESTATUS_PAGO',
--                                                a.OBSERVACIONES_ee = 'Se actualizo ESTATUS_PAGO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                    
                                
                           ------------------------------------- MONTO_PAGO  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (MONTO_PAGO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.MONTO_PAGO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.MONTO_PAGO) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.MONTO_PAGO = cx.MONTO_PAGO
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo MONTO_PAGO',
--                                                a.OBSERVACIONES_ee = 'Se actualizo ESTATUS_PAGO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;        
                                 
                                 
                           ------------------------------------- MONTO_MENSUAL  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (MONTO_MENSUAL)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.MONTO_MENSUAL) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.MONTO_MENSUAL) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.MONTO_MENSUAL = cx.MONTO_MENSUAL
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo MONTO_MENSUAL',
--                                                a.OBSERVACIONES_ee = 'Se actualizo MONTO_MENSUAL'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;        
                                         
                                 
                           ------------------------------------- MONTO_PRIMER_PAGO  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (MONTO_PRIMER_PAGO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.MONTO_PRIMER_PAGO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.MONTO_PRIMER_PAGO) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.MONTO_PRIMER_PAGO = cx.MONTO_PRIMER_PAGO
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo MONTO_PRIMER_PAGO',
--                                                a.OBSERVACIONES_ee = 'Se actualizo MONTO_PRIMER_PAGO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;        
                                 
                                 
                           ------------------------------------- NUMERO_DEPOSITOS  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (NUMERO_DEPOSITOS)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.NUMERO_DEPOSITOS) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.NUMERO_DEPOSITOS) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.NUMERO_DEPOSITOS = cx.NUMERO_DEPOSITOS
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo NUMERO_DEPOSITOS',
--                                                a.OBSERVACIONES_ee = 'Se actualizo NUMERO_DEPOSITOS'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;              
                                 
                                 
                           ------------------------------------- TIPO_INGRESO  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (TIPO_INGRESO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.TIPO_INGRESO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.TIPO_INGRESO) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.TIPO_INGRESO = cx.TIPO_INGRESO
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo TIPO_INGRESO',
--                                                a.OBSERVACIONES_ee = 'Se actualizo TIPO_INGRESO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;        
                                 
                           ------------------------------------- FECHA_COMPLEMENTO  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (FECHA_COMPLEMENTO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_COMPLEMENTO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_COMPLEMENTO) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.FECHA_COMPLEMENTO = cx.FECHA_COMPLEMENTO
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo FECHA_COMPLEMENTO',
--                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_COMPLEMENTO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                                                                                                                                           
                                 
                                 
                           ------------------------------------- Study Path -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.sp)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.sp) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.sp) is null then
                                    null;
                                Else
                                    Begin
                                        Update sztecrm a
                                            set a.sp = cx.sp
--                                                 ,a.estatus_envio = 0,
--                                                 a.estatus_envio_ee = 0,
--                                                 a.fecha_actualiza = sysdate,
--                                                a.OBSERVACIONES = 'Se actualizo SP',
--                                                a.OBSERVACIONES_ee = 'Se actualizo SP'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                      
                                 
                                 ----------------------------------------------------------------------------------------------

                         -------------------------------------Tipo de ingreso -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (TIPO_ALUMNO)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                               -- dbms_output.put_line('Entra para Tipo de ingreso ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||(cx.TIPO_ALUMNO) );
                         
                                If trim (cx.TIPO_ALUMNO) = trim (vl_campo) then
                                    null;
                                  --  dbms_output.put_line('No hace nada TIPO_ALUMNO' );
                                ElsIf trim (cx.TIPO_ALUMNO) is null and  vl_campo is not null  then
                                 --  dbms_output.put_line('TIPO_ALUMNO Entra1' );
                                       Begin
                                            Update sztecrm a
                                                set a.TIPO_ALUMNO = trim (cx.TIPO_ALUMNO),
                                                     a.estatus_envio = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Tipo Alumno'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;
                                ElsIf trim (cx.TIPO_ALUMNO) != vl_campo and  trim (cx.TIPO_ALUMNO) is not null  then
                               -- dbms_output.put_line('TIPO_ALUMNO Entra2' );
                                       Begin
                                            Update sztecrm a
                                                set a.TIPO_ALUMNO = trim (cx.TIPO_ALUMNO),
                                                     a.estatus_envio = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Tipo Alumno'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;
                                Else
                               -- dbms_output.put_line('TIPO_ALUMNO Entra3' );
                                       Begin
                                            Update sztecrm a
                                                set a.TIPO_ALUMNO = trim (cx.TIPO_ALUMNO),
                                                     a.estatus_envio = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Tipo Alumno'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                           null;
                                       End;



                                End if;
                                 Commit;     
                                 
                                 
                         -------------------------------------Fecha de Estatus  -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.FECHA_ESTATUS)
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                dbms_output.put_line('Entra para Fecha de Estatus ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||(cx.FECHA_ESTATUS) );
                         
                                If trim (cx.FECHA_ESTATUS) = trim (vl_campo) then
                                    null;
                                    dbms_output.put_line('No hace nada Fecha de Estatus' );
                                ElsIf trim (cx.FECHA_ESTATUS) is null and  vl_campo is not null  then
                                 --  dbms_output.put_line('TIPO_ALUMNO Entra1' );
                                       Begin
                                            Update sztecrm a
                                                set a.FECHA_ESTATUS = trim (cx.FECHA_ESTATUS),
                                                     a.estatus_envio = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Fecha de Estatus'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;
                                ElsIf trim (cx.FECHA_ESTATUS) != vl_campo and  trim (cx.FECHA_ESTATUS) is not null  then
                                dbms_output.put_line('Fecha de Estatus Entra2' );
                                       Begin
                                            Update sztecrm a
                                                set a.FECHA_ESTATUS = trim (cx.FECHA_ESTATUS),
                                                     a.estatus_envio = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Fecha de Estatus'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;
                                Else
                                    dbms_output.put_line('Fecha de Estatus Entra3' );
                                       Begin
                                            Update sztecrm a
                                                set a.FECHA_ESTATUS = trim (cx.FECHA_ESTATUS),
                                                     a.estatus_envio = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo Fecha de Estatus'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                           null;
                                       End;



                                End if;
                                 Commit;   

                                 
                                 
                                 

                            End Loop;
                                Commit;
                           Exception
                            When Others then 
                             --dbms_output.put_line('Erorr general Alumnos:'||c.matricula ||'*'||c.programa||'*'||sqlerrm);
                             null;
                           End;

                          End if;

                     End loop;
                Commit;


         Commit;
       --  dbms_output.put_line('Termina sin Error:');

         Exception
         When Others then
            null;
         --  dbms_output.put_line('Erorr general Alumnos:'||sqlerrm);
         End;
         
         
   
         
         Begin 
         
                    For cx in (

                                    
                                with pagos as (
                                Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_EFFECTIVE_DATE, tbraccd_desc
                                from tbrappl, tbraccd, TZTNCD
                                Where 1= 1 
                                And TBRACCD_PIDM = tbrappl_pidm
                                And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                                And tbraccd_detail_code =  TZTNCD_CODE
                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                And TBRAPPL_REAPPL_IND is null
                                --And trunc (TBRACCD_EFFECTIVE_DATE) between '01/11/2021' and '30/11/2021'
                                group by tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_EFFECTIVE_DATE, tbraccd_desc
                                )
                                select  T.PIDM PIDM,   
                                    T.MATRICULA MATRICULA, 
                                    T.PROGRAMA PROGRAMA, 
                                    V.SVRSVPR_PROTOCOL_SEQ_NO SEQNO,
                                    trunc (v.SVRSVPR_RECEPTION_DATE) Fecha_Servicio,
                                    V.SVRSVPR_SRVC_CODE Accesorio, 
                                    SVVSRVC_DESC Descripcion,
                                    SVVSRVS_DESC Descrip_Estatus,
                                    v.SVRSVPR_PROTOCOL_AMOUNT Monto_Cargo,
                                    c.monto Monto_Pagado,
                                    v.SVRSVPR_ACCD_TRAN_NUMBER Secuencia_cargo
                                from SVRSVPR  v 
                                join TZTPROG_INCR t on t.pidm = v.SVRSVPR_PIDM
                                join SPRIDEN S on S.SPRIDEN_PIDM = V.SVRSVPR_PIDM 
                                join SVVSRVC on SVVSRVC_CODE = v.SVRSVPR_SRVC_CODE
                                join SVVSRVS on SVVSRVS_CODE  = v.SVRSVPR_SRVS_CODE
                                join SVRSVAD on SVRSVAD_PROTOCOL_SEQ_NO =  v.SVRSVPR_PROTOCOL_SEQ_NO
                                join sztecrm x on x.MATRICULA = t.matricula and x.programa = t.programa
                                left join pagos  c on tbrappl_pidm = V.SVRSVPR_PIDM  and c.TBRAPPL_CHG_TRAN_NUMBER= v.SVRSVPR_ACCD_TRAN_NUMBER
                                WHERE 1=1
                               --- And t.matricula = '010017225'  ------> Poner Matriculas
                                and  S.SPRIDEN_CHANGE_IND  is null
                                AND v.SVRSVPR_SRVS_CODE    IN ( 'PA', 'CL', 'AC','CA')
                                and V.SVRSVPR_SRVC_CODE in (select  distinct ZSTPARA_PARAM_ID
                                                                                    from ZSTPARA
                                                                                    where ZSTPARA_MAPA_ID = 'CERTIFICA_1SS'
                                                                                )
                                And v.SVRSVPR_PROTOCOL_SEQ_NO in (Select max (v1.SVRSVPR_PROTOCOL_SEQ_NO)
                                                                                        from SVRSVPR v1
                                                                                        Where v1.SVRSVPR_PIDM = v.SVRSVPR_PIDM
                                                                                        And v1.SVRSVPR_SRVS_CODE = v.SVRSVPR_SRVS_CODE
                                                                                       )
                                And  trim (SVRSVAD_ADDL_DATA_CDE) = t.programa                                            
                                and v.SVRSVPR_ACCD_TRAN_NUMBER > 0                                                       
                                And t.sp = (select max (t1.sp)
                                                from TZTPROG_INCR t1
                                                Where t.pidm = t1.pidm
                                                and t1.campus||t1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                                                And t.estatus = t1.estatus
                                                )
                                      
                                  
                     ) Loop
                    
                    
                          -------------------------------------Servicio SSb -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select SERVICIO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.accesorio = vl_campo then
                                    null;
                                Else
                                       -- dbms_output.put_line('Entra para CORREO_ELECTRONICO ' || cx.matricula|| '*'||cx.CORREO_ELECTRONICO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.SERVICIO = cx.accesorio,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo el servicio',
                                                    a.OBSERVACIONES_ee = 'Se actualizo el servicio'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                                     
                    
                          -------------------------------------Descripcion Servicio SSb -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select DESC_SERVICIO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.descripcion = vl_campo then
                                    null;
                                Else
                                       -- dbms_output.put_line('Entra para CORREO_ELECTRONICO ' || cx.matricula|| '*'||cx.CORREO_ELECTRONICO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.DESC_SERVICIO = cx.descripcion,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo la Descrip del servicio',
                                                    a.OBSERVACIONES_ee = 'Se actualizo la Descrip del servicio'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                          
                    
                         -------------------------------------Descripcion Estatus SSb -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select ESTATUS_SBB
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.descrip_estatus = vl_campo then
                                    null;
                                ElsIf cx.descrip_estatus is null then
                                    null;
                                Else
                                       -- dbms_output.put_line('Entra para CORREO_ELECTRONICO ' || cx.matricula|| '*'||cx.CORREO_ELECTRONICO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.ESTATUS_SBB = cx.descrip_estatus,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo el estatus del servicio',
                                                    a.OBSERVACIONES_ee = 'Se actualizo el estatus del servicio'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                          

                        -------------------------------------Fecha Servicio SSb -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select FECHA_SERVICIO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.FECHA_SERVICIO = vl_campo then
                                    null;
                                Else
                                       -- dbms_output.put_line('Entra para CORREO_ELECTRONICO ' || cx.matricula|| '*'||cx.CORREO_ELECTRONICO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.FECHA_SERVICIO = cx.FECHA_SERVICIO,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo la fecha del servicio',
                                                    a.OBSERVACIONES_ee = 'Se actualizo la fecha del servicio'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                          
                    
                    
                       -------------------------------------Pago SSb -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select PAGO
                                            into vl_campo
                                         From sztecrm a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                         
                                If cx.monto_pagado = vl_campo then
                                    null;
                                Else
                                       -- dbms_output.put_line('Entra para CORREO_ELECTRONICO ' || cx.matricula|| '*'||cx.CORREO_ELECTRONICO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm a
                                                set a.PAGO = cx.monto_pagado,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES = 'Se actualizo el pago del servicio',
                                                    a.OBSERVACIONES_ee = 'Se actualizo el pago del servicio'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;

                                End if;
                                 Commit;                          
                    
                    
                    End loop;
         
         
         End;
         
 
        Begin 

                For cx in (

                            Select pidm, matricula,estatus,
                            trunc( (   select distinct max (SARAPPD_APDC_DATE)
                                        from saradap
                                        join sarappd on SARAPPD_PIDM = SARADAP_PIDM and SARAPPD_TERM_CODE_ENTRY =  SARADAP_TERM_CODE_ENTRY and SARAPPD_APPL_NO = SARADAP_APPL_NO
                                        where saradap_pidm = a.pidm
                                        And SARADAP_LEVL_CODE = a.nivel
                                        and SARAPPD_APDC_CODE  in ('35', '53')     ) ) Fecha_Desicion
                            from SZTECRM a
                            where 1= 1 
                           -- And matricula in ('010613079', '010611818') ---> Actualizar Matricula 
                            and a.FECHA_DESICION is null
                            
                    
                   ) loop
                   
                    If cx.Fecha_Desicion is not null then 

                        Begin 
                            Update SZTECRM
                            set FECHA_DESICION = cx.Fecha_Desicion,
                                ESTATUS_ENVIO = 0,
                                ESTATUS_ENVIO_ee = 0,
                                OBSERVACIONES = 'Se Actualizo Fecha_Desicion',
                                OBSERVACIONES_ee = 'Se Actualizo Fecha_Desicion'
                            Where pidm = cx.pidm
                            And   FECHA_DESICION is null; 
                        Exception
                            When OThers then 
                                null;
                        End;

                    Else
                        Begin 
                            Update SZTECRM
                            set ESTATUS ='SIN ESTATUS'
                            Where pidm = cx.pidm
                            And   FECHA_DESICION is null; 
                        Exception
                            When OThers then 
                                null;
                        End;            
                    
                    
                    End if;

                 End Loop;     
                 Commit;  
                   
        End;


        PKG_INCONCERT.p_quita_duplicados;
        Commit;
         
end p_integra_inconcert;




procedure p_cargatztprog_incr is

/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */
 vl_pago number:=0;
 vl_pago_minimo number:=0;
 vl_sp number:=0;

BEGIN


EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.TZTPROG_INCR';
COMMIT;


Begin

    Update sgbstdn
    set SGBSTDN_STST_CODE ='MA'
    Where SGBSTDN_STST_CODE ='AS';
Exception
    When Others then
        null;
End;



 insert into migra.TZTPROG_INCR
select distinct b.spriden_pidm pidm,
 b.spriden_id Matricula,
 a.SGBSTDN_STST_CODE Estatus,
 STVSTST_DESC Estatus_D,
 a.SGBSTDN_STYP_CODE,
 f.sorlcur_camp_code Campus,
 f.sorlcur_levl_code Nivel ,
 a.sgbstdn_program_1 programa,
 SMRPRLE_PROGRAM_DESC Nombre,
 f.SORLCUR_KEY_SEQNO sp,
 trunc (SGBSTDN_ACTIVITY_DATE) Fecha_Mov,
 f.SORLCUR_TERM_CODE_CTLG ctlg,
 nvl ( f.SORLCUR_TERM_CODE_MATRIC,SORLCUR_TERM_CODE_ADMIT )  Matriculacion,
 b.SPRIDEN_CREATE_FDMN_CODE,
 f.SORLCUR_START_DATE fecha_inicio
 ,sysdate as fecha_carga,
 f.sorlcur_ADMT_CODE,
 STVADMT_DESC
 from sgbstdn a, spriden b, STVSTYP, stvSTST, smrprle, sorlcur f, stvADMT
 where 1= 1
-- And a.sgbstdn_camp_code = 'UTL'
-- and a.sgbstdn_levl_code = 'LI'
and a.SGBSTDN_STYP_CODE = STVSTYP_CODE
 and a.sgbstdn_pidm = b.spriden_pidm
 and b.spriden_change_ind is null
 and a.SGBSTDN_STST_CODE = STVSTST_CODE
 And a.sgbstdn_program_1 = SMRPRLE_PROGRAM
 and a.SGBSTDN_STST_CODE != 'CP'
 And nvl (f.sorlcur_ADMT_CODE,'RE') = stvADMT_code
 and a.SGBSTDN_TERM_CODE_EFF = ( select max (a1.SGBSTDN_TERM_CODE_EFF)
 from sgbstdn a1
 where a.sgbstdn_pidm = a1.sgbstdn_pidm
 And a.sgbstdn_camp_code = a1.sgbstdn_camp_code
 and a.sgbstdn_levl_code = a1.sgbstdn_levl_code
 and a.sgbstdn_program_1 = a1.sgbstdn_program_1
 )
and f.sorlcur_pidm = a.sgbstdn_pidm
And f.sorlcur_program = a.sgbstdn_program_1
and f.SORLCUR_LMOD_CODE = 'LEARNER'
and f.SORLCUR_SEQNO = (select max (f1.SORLCUR_SEQNO)
 from sorlcur f1
 Where f.sorlcur_pidm = f1.sorlcur_pidm
 and f.sorlcur_camp_code = f1.sorlcur_camp_code
 and f.sorlcur_levl_code = f1.sorlcur_levl_code
 and f.SORLCUR_LMOD_CODE = f1.SORLCUR_LMOD_CODE
 And f.SORLCUR_PROGRAM = f1.SORLCUR_PROGRAM )
--and f.sorlcur_pidm = 460
UNION
select distinct b.spriden_pidm pidm,
b.spriden_id matricula,
nvl (c.ESTATUS, decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' )) Estatus,
stvSTST_desc TIPO_ALUMNO,
a.SORLCUR_STYP_CODE ,
a.sorlcur_camp_code CAMPUS,
a.sorlcur_levl_code NIVEL,
a.sorlcur_program Programa,
SMRPRLE_PROGRAM_DESC Nombre,
a.SORLCUR_KEY_SEQNO sp,
trunc (a.SORLCUR_ACTIVITY_DATE) Fecha_Mov,
a.SORLCUR_TERM_CODE_CTLG ctlg,
nvl (a.SORLCUR_TERM_CODE_MATRIC,SORLCUR_TERM_CODE_ADMIT)  Matriculacion,
b.SPRIDEN_CREATE_FDMN_CODE,
 a.SORLCUR_START_DATE fecha_inicio,
 sysdate as fecha_carga,
a.sorlcur_ADMT_CODE,
STVADMT_DESC
from sorlcur a
join spriden b on b.spriden_pidm = a.sorlcur_pidm and spriden_change_ind is null
left join migra.ESTATUS_REPORTE c on c.SPRIDEN_PIDM =a.sorlcur_pidm and c.PROGRAMAS = a.SORLCUR_PROGRAM
join SMRPRLE on SMRPRLE_PROGRAM = a.SORLCUR_PROGRAM
join stvADMT on stvADMT_code = nvl (a.sorlcur_ADMT_CODE,'RE')
left join stvSTST on stvSTST_code = nvl (c.ESTATUS, decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' ))
where 1= 1
and a.SORLCUR_LMOD_CODE = 'LEARNER'
--and a.SORLCUR_CACT_CODE != 'CHANGE'
--and a.SGBSTDN_STST_CODE != 'CP'
and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
 from sorlcur a1
 Where a.sorlcur_pidm = a1.sorlcur_pidm
 and a.sorlcur_camp_code = a1.sorlcur_camp_code
 and a.sorlcur_levl_code = a1.sorlcur_levl_code
 and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
 And a.SORLCUR_PROGRAM = a1.SORLCUR_PROGRAM )
and (a.sorlcur_camp_code, a.sorlcur_levl_code, a.SORLCUR_PROGRAM) not in (select sgbstdn_camp_code, sgbstdn_levl_code, ax.sgbstdn_program_1
 from sgbstdn ax
 Where ax.sgbstdn_pidm = a.sorlcur_pidm);

 --and a.sorlcur_pidm = 460;
commit;


-----------------------------------------------------------Se actualiza la fecha de movimientos ---------------------------------------------------------------------------
 ----------------se modifica 17/07/2019 para realizara actualizacion de la fecha de movimiento--------------------------------------
 Begin

 For c in (

 Select distinct pidm, sp, nvl (fecha_inicio, '04/03/2017' ) fecha_inicio, campus||nivel campus, FECHA_MOV
 from TZTPROG_INCR
 where 1= 1
 --CAMPUS||nivel = 'ULTLI'
 --and fecha_mov is null

 ) loop

 If c.fecha_inicio < '04/03/2017' and c.campus != 'UTLLI' then

 Begin
 Update TZTPROG_INCR
 set FECHA_MOV = '04/03/2017'
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 ElsIf c.fecha_inicio >= '04/03/2017' and c.fecha_mov is null then

 Begin
 Update TZTPROG_INCR
 set FECHA_MOV = c.fecha_inicio
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 End if;

 Commit;
 End Loop;
 End;

 Update TZTPROG_INCR
 set FECHA_MOV = '03/04/2017'
 Where FECHA_MOV is null;
 Commit;


 ---- Se actualiza la fecha de la primera inscripcion ----------


 begin


 for c in (
 select *
 from TZTPROG_INCR
 where 1 = 1
 -- and rownum <= 50
 )loop



 Begin


 Update TZTPROG_INCR
 set FECHA_PRIMERA = (
 select min (x.fecha_inicio) --, rownum
 from (
 SELECT DISTINCT
 min (SSBSECT_PTRM_START_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
 FROM SFRSTCR a, SSBSECT b
 WHERE a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
 AND a.SFRSTCR_CRN = b.SSBSECT_CRN
 AND a.SFRSTCR_RSTS_CODE = 'RE'
 AND b.SSBSECT_PTRM_START_DATE =
 (SELECT min (b1.SSBSECT_PTRM_START_DATE)
 FROM SSBSECT b1
 WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
 AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
 and sfrstcr_pidm = c.pidm
 AND SFRSTCR_STSP_KEY_SEQUENCE = c.sp
 GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
 order by 1,3 asc
 ) x
 )
 Where pidm = c.pidm
 And sp = c.sp;

 exception when others then

 null;
 end;

 end loop;
 Commit;

 end;

---------- Pone el tipoo de estatus desercion para todos las bajas

Begin

    For cx in (

                    select *
                    from TZTPROG_INCR
                    where 1= 1
                    and estatus in ('BT','BD','CM','CV','BI')
                    and SGBSTDN_STYP_CODE !='D'


     ) loop

        Begin
            Update TZTPROG_INCR
            set SGBSTDN_STYP_CODE ='D'
            where pidm = cx.pidm
            And estatus = cx.estatus
            And programa = cx.programa
            And SGBSTDN_STYP_CODE = cx.SGBSTDN_STYP_CODE;
       Exception
        When Others then
            null;
       End;


     End Loop;

     Commit;

End;


                                           
Begin 

    For cx in (
                                         
                select distinct a.matricula, a.programa, b.SGBSTDN_STYP_CODE, pidm, a.estatus
                from   TZTPROG_INCR a  
                left join sgbstdn b on  b.SGBSTDN_PIDM  = a.pidm 
                                                        and b.SGBSTDN_TERM_CODE_EFF = (select max (b1.SGBSTDN_TERM_CODE_EFF)
                                                             from SGBSTDN b1
                                                             Where b.SGBSTDN_PIDM = b1.SGBSTDN_PIDM)
                where a.SGBSTDN_STYP_CODE is null                                   

               ) loop
               
               Begin 
                       Update TZTPROG_INCR
                       set SGBSTDN_STYP_CODE = cx.SGBSTDN_STYP_CODE
                       Where matricula = cx.matricula
                       And programa = cx.programa;
                Exception
                When Others then 
                    null;
                End;
                        
            End Loop;
            Commit;
End;                        




                
 Begin 

    For cx in (               
                
                select distinct a.matricula, a.programa, a.pidm, a.estatus, decode (estatus,'BT', 'D', 'DB','D','CP','D','MA','C','CV','D','EG','C','CV', 'D','BI','D')  SGBSTDN_STYP_CODE
                from   TZTPROG_INCR a  
                where a.SGBSTDN_STYP_CODE is null                                   

               ) loop
               
               Begin 
                       Update TZTPROG_INCR
                       set SGBSTDN_STYP_CODE = cx.SGBSTDN_STYP_CODE
                       Where matricula = cx.matricula
                       And programa = cx.programa;
                Exception
                When Others then 
                    null;
                End;
                        
            End Loop;
            Commit;
End;                




end p_cargatztprog_incr;



Function f_genero (p_pidm in number) return varchar2  is

--vl_fecha_ini date;
vl_salida varchar2(5000):= 'EXITO';


BEGIN

            Begin

                    select distinct  decode (SPBPERS_SEX, 'F', 'F', 'M', 'M', null, 'M') Sexo
                           Into vl_salida
                    from SPBPERS
                    where  SPBPERS_pidm = p_pidm;


            Exception
            When Others then
              vl_salida := null;
            End;

        return vl_salida;

Exception
    When Others then
      vl_salida :=null;
     return vl_salida;
END f_genero;


Function  f_nacionalidad (p_pidm in number) return varchar2
as

    vl_nacionalidad varchar2(250) := null;

    Begin

                Begin

                            select distinct
                                case
                                    when SPBPERS_CITZ_CODE = 'EX' then 'EX'
                                    when SPBPERS_CITZ_CODE = 'ME' then 'ME'
                                    when SPBPERS_CITZ_CODE = 'ER' then 'EX'
                                    when SPBPERS_CITZ_CODE = 'EN' then 'EX'
                                    else null
                                end as Nacionalidad
                                Into vl_nacionalidad
                            from SPBPERS
                            where 1 = 1
                                and SPBPERS_PIDM = p_pidm;

                Exception
                    When Others then
                        vl_nacionalidad := ' ';
                End;

               Return (vl_nacionalidad);

    Exception
        when Others then
         vl_nacionalidad := ' ';
          Return (vl_nacionalidad);
    End f_nacionalidad;


PROCEDURE P_INCONCERT_SSB(p_pidm in number, p_programa in varchar2, 
                                                                               p_servicio out varchar2, p_serv_desc out varchar2, 
                                                                               p_estatus out varchar2, p_fecha_Captura out date, 
                                                                               p_pago out varchar2) IS

BEGIN

              For cx in (
              
                                with pagos as (
                                Select sum (TBRAPPL_AMOUNT) monto, tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_EFFECTIVE_DATE, tbraccd_desc
                                from tbrappl, tbraccd, TZTNCD
                                Where 1= 1 
                                And TBRACCD_PIDM = tbrappl_pidm
                                And TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER
                                And tbraccd_detail_code =  TZTNCD_CODE
                                And TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                And TBRAPPL_REAPPL_IND is null
                                --And trunc (TBRACCD_EFFECTIVE_DATE) between '01/11/2021' and '30/11/2021'
                                group by tbrappl_pidm, TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_EFFECTIVE_DATE, tbraccd_desc
                                )
                                select  T.PIDM PIDM,   
                                    T.MATRICULA MATRICULA, 
                                    T.PROGRAMA PROGRAMA, 
                                    V.SVRSVPR_PROTOCOL_SEQ_NO SEQNO,
                                    trunc (v.SVRSVPR_RECEPTION_DATE) Fecha_Servicio,
                                    V.SVRSVPR_SRVC_CODE Accesorio, 
                                    SVVSRVC_DESC Descripcion,
                                    SVVSRVS_DESC Descrip_Estatus,
                                    v.SVRSVPR_PROTOCOL_AMOUNT Monto_Cargo,
                                    c.monto Monto_Pagado,
                                    v.SVRSVPR_ACCD_TRAN_NUMBER Secuencia_cargo
                                from SVRSVPR  v 
                                join tztprog t on t.pidm = v.SVRSVPR_PIDM
                                join SPRIDEN S on S.SPRIDEN_PIDM = V.SVRSVPR_PIDM 
                                join SVVSRVC on SVVSRVC_CODE = v.SVRSVPR_SRVC_CODE
                                join SVVSRVS on SVVSRVS_CODE  = v.SVRSVPR_SRVS_CODE
                                join SVRSVAD on SVRSVAD_PROTOCOL_SEQ_NO =  v.SVRSVPR_PROTOCOL_SEQ_NO
                                left join pagos  c on tbrappl_pidm = V.SVRSVPR_PIDM  and c.TBRAPPL_CHG_TRAN_NUMBER= v.SVRSVPR_ACCD_TRAN_NUMBER
                                WHERE 1=1
                                and  S.SPRIDEN_CHANGE_IND  is null
                                AND v.SVRSVPR_SRVS_CODE    IN ( 'PA', 'CL', 'AC','CA')
                                and V.SVRSVPR_SRVC_CODE in (select  distinct ZSTPARA_PARAM_ID
                                                                                    from ZSTPARA
                                                                                    where ZSTPARA_MAPA_ID = 'CERTIFICA_1SS'
                                                                                )
                                And v.SVRSVPR_PROTOCOL_SEQ_NO in (Select max (v1.SVRSVPR_PROTOCOL_SEQ_NO)
                                                                                        from SVRSVPR v1
                                                                                        Where v1.SVRSVPR_PIDM = v.SVRSVPR_PIDM
                                                                                        And v1.SVRSVPR_SRVS_CODE = v.SVRSVPR_SRVS_CODE
                                                                                       )
                                And  trim (SVRSVAD_ADDL_DATA_CDE) = t.programa                                            
                                and v.SVRSVPR_ACCD_TRAN_NUMBER > 0                                                       
                                And t.sp = (select max (t1.sp)
                                                from tztprog t1
                                                Where t.pidm = t1.pidm
                                                and t1.campus||t1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                                                And t.estatus = t1.estatus
                                                )
                                and t.pidm = p_pidm
                                And t.programa = p_programa           
               
               ) loop
               
                    Begin 
                            p_servicio := cx.accesorio;
                            p_serv_desc := cx.descripcion;
                            p_estatus := cx.descrip_estatus;
                            p_fecha_Captura := cx.fecha_servicio;
                            p_pago := cx.monto_pagado;              
                    Exception
                        When Others then
                            null;
                    End;
               
               
           End loop; 


   EXCEPTION
     WHEN NO_DATA_FOUND THEN
                p_servicio := null;
                p_serv_desc := null;
                p_estatus := null;
                p_fecha_Captura := null;
                p_pago := null;   
     WHEN OTHERS THEN
       -- Consider logging the error and then re-raise
       RAISE;
END P_INCONCERT_SSB;


Function  f_fecha_pago (p_pidm in number) return date

as


    vl_fecha_pago date := null;

    Begin

                Begin

                    select distinct trunc (TBRACCD_EFFECTIVE_DATE)
                        Into vl_fecha_pago
                    from tbraccd x
                    where x.tbraccd_pidm = p_pidm
                    And x.TBRACCD_CREATE_SOURCE ='TZFEDCA (PARC)'    
                    And x.TBRACCD_EFFECTIVE_DATE between TRUNC(SYSDATE, 'MM') and LAST_DAY(TRUNC(SYSDATE));

                Exception
                    When Others then
                        vl_fecha_pago := null;
                End;

                If vl_fecha_pago is null then 
                
                    Begin
                        select distinct max (trunc (TBRACCD_EFFECTIVE_DATE))
                            Into vl_fecha_pago
                        from tbraccd x
                        where x.tbraccd_pidm = p_pidm
                        And x.TBRACCD_CREATE_SOURCE ='TZFEDCA (PARC)';                     
                    Exception
                        When Others then
                            vl_fecha_pago := null;
                    End;

                End if;
                
               Return (vl_fecha_pago);

Exception
    when Others then
     vl_fecha_pago :=null;
      Return (vl_fecha_pago);
End f_fecha_pago;
    
    

Function  f_fecha_pago_ultima (p_pidm in number) return date

as


    vl_fecha_pago date := null;

    Begin

           Begin
                select  max (a.TBRACCD_EFFECTIVE_DATE) 
                    Into vl_fecha_pago
                from tbraccd a
                where a.tbraccd_pidm = p_pidm  
                And a.tbraccd_detail_code in (select TZTNCD_CODE
                                            from TZTNCD    
                                            Where TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')                            
                                           )
                And a.TBRACCD_TRAN_NUMBER in (select b.TBRAPPL_PAY_TRAN_NUMBER
                                               from tbrappl b
                                               Where 1=1
                                               And b.tbrappl_pidm = p_pidm
                                               And b.TBRAPPL_REAPPL_IND is null
                                               And TBRAPPL_CHG_TRAN_NUMBER in (select TBRACCD_TRAN_NUMBER
                                                                                from tbraccd
                                                                                where tbraccd_pidm = p_pidm 
                                                                                And tbraccd_detail_code in (select TZTNCD_CODE
                                                                                                             from TZTNCD    
                                                                                                             Where TZTNCD_CONCEPTO IN ('Venta'))
                                                                                And TBRACCD_CREATE_SOURCE ='TZFEDCA (PARC)'
                                                                                )
                                             );
            Exception
                When Others then 
                  vl_fecha_pago:= null; 
            End;                   
                
        Return (vl_fecha_pago);

Exception
    when Others then
     vl_fecha_pago :=null;
      Return (vl_fecha_pago);
End f_fecha_pago_ultima;   



Function  f_pago_col (p_pidm in number) return varchar2

as

    vl_pago varchar2(2) := null;
    vl_saldo number:=0;
    vl_seq number:=0;

Begin

                Begin

                    select TBRACCD_TRAN_NUMBER
                        Into vl_seq
                    from tbraccd x
                    where x.tbraccd_pidm = p_pidm
                    And x.TBRACCD_CREATE_SOURCE ='TZFEDCA (PARC)'    
                    And x.TBRACCD_EFFECTIVE_DATE between TRUNC(SYSDATE, 'MM') and LAST_DAY(TRUNC(SYSDATE));

                Exception
                    When Others then
                        vl_seq := null;
                End;

                Begin
                    Select nvl (sum (TBRAPPL_AMOUNT), 0) monto 
                        Into vl_saldo
                    from tbrappl
                    Where 1=1
                    And TBRAPPL_PIDM = p_pidm
                    And TBRAPPL_REAPPL_IND is null
                    And TBRAPPL_CHG_TRAN_NUMBER = vl_seq
                    And TBRAPPL_PAY_TRAN_NUMBER in (select TBRACCD_TRAN_NUMBER
                                                    from tbraccd 
                                                    Where tbraccd_pidm = p_pidm
                                                    And tbraccd_detail_code in (select TZTNCD_CODE
                                                                                from TZTNCD    
                                                                                Where TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                                               )
                                                    );
                    
                
                Exception
                    When Others then 
                     vl_saldo:=0;
                End;


                If vl_saldo  > 0 then
                    vl_pago := 'S';
                Elsif vl_saldo = 0 then
                    vl_pago := 'N';
                End if; 
                
               Return (vl_pago);

Exception
    when Others then
     vl_pago :='N';
      Return (vl_pago);
End f_pago_col;


Function  f_monto_col_pago (p_pidm in number) return number

as

    vl_saldo number:=0;
    vl_seq number:=0;

Begin

                Begin

                    select TBRACCD_TRAN_NUMBER
                        Into vl_seq
                    from tbraccd x
                    where x.tbraccd_pidm = p_pidm
                    And x.TBRACCD_CREATE_SOURCE ='TZFEDCA (PARC)'    
                    And x.TBRACCD_EFFECTIVE_DATE between TRUNC(SYSDATE, 'MM') and LAST_DAY(TRUNC(SYSDATE));

                Exception
                    When Others then
                        vl_seq := null;
                End;

                Begin
                    Select nvl (sum (TBRAPPL_AMOUNT), 0) monto 
                        Into vl_saldo
                    from tbrappl
                    Where 1=1
                    And TBRAPPL_PIDM = p_pidm
                    And TBRAPPL_REAPPL_IND is null
                    And TBRAPPL_CHG_TRAN_NUMBER = vl_seq
                    And TBRAPPL_PAY_TRAN_NUMBER in (select TBRACCD_TRAN_NUMBER
                                                    from tbraccd 
                                                    Where tbraccd_pidm = p_pidm
                                                    And tbraccd_detail_code in (select TZTNCD_CODE
                                                                                from TZTNCD    
                                                                                Where TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                                               )
                                                    );
                    
                
                Exception
                    When Others then 
                     vl_saldo:=0;
                End;

                
               Return (vl_saldo);

Exception
    when Others then
     vl_saldo :=0;
      Return (vl_saldo);
End f_monto_col_pago;


Function  f_col_cargo_mes (p_pidm in number) return number 
as

    vl_saldo number:=0;
    vl_seq number:=0;

Begin

                Begin

                    select TBRACCD_AMOUNT 
                        Into vl_saldo
                    from tbraccd x
                    where x.tbraccd_pidm = p_pidm
                    And x.TBRACCD_CREATE_SOURCE ='TZFEDCA (PARC)'    
                    And x.TBRACCD_EFFECTIVE_DATE between TRUNC(SYSDATE, 'MM') and LAST_DAY(TRUNC(SYSDATE));

                Exception
                    When Others then
                        vl_saldo := 0;
                End;
                
               Return (vl_saldo);

Exception
    when Others then
     vl_saldo :=0;
      Return (vl_saldo);
End f_col_cargo_mes;


Function  f_col_primer_pago (p_pidm in number) return number
As

    vl_saldo number:=0;
    vl_seq number:=0;

Begin

                Begin

                    select min (TBRACCD_TRAN_NUMBER)
                        Into vl_seq
                    from tbraccd x
                    where x.tbraccd_pidm = p_pidm
                    And x.TBRACCD_CREATE_SOURCE ='TZFEDCA (PARC)';    


                Exception
                    When Others then
                        vl_seq := null;
                End;

                Begin
                    Select nvl (sum (TBRAPPL_AMOUNT), 0) monto 
                        Into vl_saldo
                    from tbrappl
                    Where 1=1
                    And TBRAPPL_PIDM = p_pidm
                    And TBRAPPL_REAPPL_IND is null
                    And TBRAPPL_CHG_TRAN_NUMBER = vl_seq
                    And TBRAPPL_PAY_TRAN_NUMBER in (select TBRACCD_TRAN_NUMBER
                                                    from tbraccd 
                                                    Where tbraccd_pidm = p_pidm
                                                    And tbraccd_detail_code in (select TZTNCD_CODE
                                                                                from TZTNCD    
                                                                                Where TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                                               )
                                                    );
                    
                
                Exception
                    When Others then 
                     vl_saldo:=0;
                End;

                
               Return (vl_saldo);

Exception
    when Others then
     vl_saldo :=0;
      Return (vl_saldo);
End f_col_primer_pago;

Function  f_numero_pago (p_pidm in number) return number
as
    vl_saldo number:=0;
    vl_seq number:=0;

Begin 

        Begin 
        
            select count (*)
                Into vl_saldo
            from tbraccd 
            Where tbraccd_pidm = p_pidm
            And tbraccd_detail_code in (select TZTNCD_CODE
                                        from TZTNCD    
                                        Where TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                       );
        Exception
            When others then 
              vl_saldo:=0;  
        End;
         
        Return (vl_saldo);

Exception
    when Others then
     vl_saldo :=0;
      Return (vl_saldo);

End f_numero_pago;

Function  f_fecha_complemento (p_pidm in number) return date 
As 

vl_fecha_comp date := null;

Begin

        Begin
        
                    select max (trunc (TBRACCD_EFFECTIVE_DATE))
                        Into vl_fecha_comp
                    from tbraccd x
                    where x.tbraccd_pidm = p_pidm
                    And tbraccd_detail_code in ( select CODIGO
                                                 from TZTINC
                                               );        
        Exception
            When others then 
                vl_fecha_comp:= null;
        end;
        
        Return (vl_fecha_comp);

Exception
    when Others then
     vl_fecha_comp :=null;
      Return (vl_fecha_comp);


End f_fecha_complemento;

Procedure p_quita_duplicados
as
Begin
   
        For cx in (
        
                    select count(*), matricula
                    from SZTECRM
                    group by  matricula
                    having count(*) > 1        
                            
        
        
        
        ) loop   --------> Grupo de Registros duplicados
        
        
                For cx2 in (
                
                            select *
                            from SZTECRM a
                            where a.matricula = cx.matricula
                            and a.sp = (select max (a1.sp)
                                    from SZTECRM a1
                                    where a1.matricula = a.matricula
                                   )              
                
                ) loop
                
                        Begin ----> Se borra el minimo registro 
                        
                            Delete SZTECRM a
                            where a.matricula = cx2.matricula
                            And a.campus = cx2.campus
                            And a.nivel = cx2.nivel
                            and a.sp != cx2.sp; 
                        Exception
                            When Others then 
                                null;
                        End;
                
                        Commit;
                
                End Loop;
        
        
        End loop;
        
        
        For cx in (
        
                    select count(*), matricula
                    from SZTECRM
                    group by  matricula
                    having count(*) > 1        
                            
        
        
        
        ) loop   --------> Grupo de Registros duplicados
        
        
                For cx2 in (
                
                            select *
                            from SZTECRM a
                            where a.matricula = cx.matricula
                            and trunc (a.FECHA_INICIO) = (select min (trunc(a1.FECHA_INICIO))
                                                            from SZTECRM a1
                                                            where a1.matricula = a.matricula
                                                           )              
                
                ) loop
                
                        Begin ----> Se borra el minimo registro 
                        
                            Delete SZTECRM a
                            where a.matricula = cx2.matricula
                            And a.campus = cx2.campus
                            And a.nivel = cx2.nivel
                            and trunc (a.FECHA_INICIO) = trunc (cx2.FECHA_INICIO); 
                        Exception
                            When Others then 
                                null;
                        End;
                
                        Commit;
                
                End Loop;
        
        
        End loop;        
        

End;

END PKG_INCONCERT;
/

DROP PUBLIC SYNONYM PKG_INCONCERT;

CREATE OR REPLACE PUBLIC SYNONYM PKG_INCONCERT FOR BANINST1.PKG_INCONCERT;
