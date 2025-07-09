DROP PACKAGE BODY BANINST1.PKG_INCONCERT_UNI;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_INCONCERT_UNI IS



procedure p_integra_inconcert_uni is


/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */
 vl_pago number:=0;
 vl_pago_minimo number:=0;
 vl_sp number:=0;
 vl_existe number:=0;
 vl_campo varchar2(200):= null;
 
t_servicio  varchar2(100):= null;
t_serv_desc varchar2(250):= null;
t_estatus varchar2(250):= null;
t_fecha_Captura date:= null;
t_pago varchar2(250):= null;
vl_error varchar2(500):= null;

BEGIN

EXECUTE IMMEDIATE 'ALTER SESSION ENABLE PARALLEL DML';  ---- Se activa el paralelismo 


         Begin
                     for c in (

                                    select distinct a.matricula, a.programa, a.estatus, a.sp
                                    from TZTPROG_INCR a
                                   -- join nivel_riesgo b on b.matricula = a.matricula 
                                    Where 1= 1
                                    And a.estatus not in ('CP')
                                    And a.sp = (select max (a1.sp)
                                                         from TZTPROG_INCR a1
                                                         Where a.pidm = a1.pidm
                                                         and a1.campus||a1.nivel not in ( 'UTSID', 'INIEC')
                                                           And a.programa = a1.programa
                                                          And a.estatus = a1.estatus
                                                            )
                                    And a.campus in  ('GLO', 'FIL','IND','VIE','INA','GAS','PER','COL','ECU','UTL','UTS', 'USA','ARG', 'DOM','GUA','PAN','CHI', 'SAL', 'BOL', 'PAR', 'COE',
                                                      'ESP','NIC','HON','INT','COS','URU'
                                                    )
                                    order by a.estatus desc, a.sp , a.matricula asc 
                                  


                     ) loop

                        vl_existe:=0;
                           Begin
                                    Select count(1)
                                              Into vl_existe
                                    from SZTECRM_UNI a
                                    where a.matricula = c.matricula
                                    And a.programa = c.programa;
                           Exception
                            When Others then
                                vl_existe:=0;
                           End;

                          If vl_existe = 0 then
                             vl_error:= null;
                          
                            --dbms_output.put_line('No Existe' ||c.matricula ||'*'||c.programa );

                                BEGIN
                                    INSERT /*+ APPEND */  INTO SZTECRM_UNI
                                    SELECT  DISTINCT
                                        TZTPROG_INCR.pidm,
                                        TZTPROG_INCR.matricula,
                                        SUBSTR(SPRIDEN.SPRIDEN_LAST_NAME, 1, INSTR(SPRIDEN.SPRIDEN_LAST_NAME, '/') - 1) AS Paterno,
                                        SUBSTR(SPRIDEN.SPRIDEN_LAST_NAME, INSTR(SPRIDEN.SPRIDEN_LAST_NAME, '/') + 1, 150) AS Materno,
                                        SPRIDEN.SPRIDEN_FIRST_NAME AS Nombre,
                                        TZTPROG_INCR.campus,
                                        TZTPROG_INCR.nivel,
                                        TZTPROG_INCR.ESTATUS_D AS estatus,
                                        TZTPROG_INCR.programa,
                                        pkg_utilerias.f_modalidad(TZTPROG_INCR.programa, TZTPROG_INCR.ctlg) AS Modalidad,
                                        DECODE(SUBSTR(pkg_utilerias.f_calcula_rate(TZTPROG_INCR.pidm, TZTPROG_INCR.programa), LENGTH(pkg_utilerias.f_calcula_rate(TZTPROG_INCR.pidm, TZTPROG_INCR.programa)) - 1, 1), 'A', '15', 'B', '30') AS Fecha_Corte,
                                        TRUNC(TZTPROG_INCR.fecha_inicio) AS Fecha_Inicio,
                                        (SELECT /*+ PARALLEL(SZTHITA, 8) */ DISTINCT MAX(SZTHITA_E_CURSO)
                                         FROM szthita
                                         WHERE 1 = 1
                                         AND SZTHITA_PIDM = TZTPROG_INCR.pidm
                                         AND SZTHITA_STUDY = TZTPROG_INCR.sp) AS Materias_Inscritas,
                                        (SELECT /*+ PARALLEL(SZTHITA, 8) */ DISTINCT MAX(SZTHITA_APROB)
                                         FROM szthita
                                         WHERE 1 = 1
                                         AND SZTHITA_PIDM = TZTPROG_INCR.pidm
                                         AND SZTHITA_STUDY = TZTPROG_INCR.sp) AS Materias_Aprobadas,
                                        NVL((SELECT /*+ PARALLEL(SZTHITA, 8) */ DISTINCT MAX(SZTHITA_AVANCE)
                                             FROM szthita
                                             WHERE 1 = 1
                                             AND SZTHITA_PIDM = TZTPROG_INCR.pidm
                                             AND SZTHITA_STUDY = TZTPROG_INCR.sp), 0) AS Avance_Curricular,
                                        SUBSTR(pkg_utilerias.f_calcula_jornada(TZTPROG_INCR.pidm, TZTPROG_INCR.sp, TZTPROG_INCR.nivel, pkg_utilerias.f_periodo_materias(TZTPROG_INCR.pidm, TZTPROG_INCR.fecha_inicio, TZTPROG_INCR.sp)),
                                               LENGTH(pkg_utilerias.f_calcula_jornada(TZTPROG_INCR.pidm, TZTPROG_INCR.sp, TZTPROG_INCR.nivel, pkg_utilerias.f_periodo_materias(TZTPROG_INCR.pidm, TZTPROG_INCR.fecha_inicio, TZTPROG_INCR.sp))), 1) AS Jornada,
                                        TRUNC((SELECT /*+ PARALLEL(SARADAP, 8) PARALLEL(SARAPPD, 8) */ DISTINCT MAX(SARAPPD.SARAPPD_APDC_DATE)
                                               FROM saradap
                                               JOIN sarappd ON SARAPPD.SARAPPD_PIDM = SARADAP.SARADAP_PIDM AND SARAPPD.SARAPPD_TERM_CODE_ENTRY = SARADAP.SARADAP_TERM_CODE_ENTRY AND SARAPPD.SARAPPD_APPL_NO = SARADAP.SARADAP_APPL_NO
                                               WHERE SARADAP.saradap_pidm = TZTPROG_INCR.pidm
                                               AND SARADAP.SARADAP_PROGRAM_1 = TZTPROG_INCR.programa
                                               AND SARAPPD.SARAPPD_APDC_CODE = 35)) AS Fecha_Desicion,
                                        NVL((SELECT /*+ PARALLEL(SPREMRG, 8) */ DECODE(COUNT(1), '0', 'SinFacturacion', '1', 'ConFacturacion')
                                             FROM SPREMRG
                                             WHERE 1 = 1
                                             AND SPREMRG.SPREMRG_pidm = TZTPROG_INCR.pidm), 'SinFacturacion') AS Factura,
                                        NVL(PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(TZTPROG_INCR.pidm), 0) AS Saldo_Total,
                                        NVL(PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(TZTPROG_INCR.pidm), 0) AS Saldo_Dia,
                                        ROUND(NVL(PKG_REPORTES_1.f_dias_atraso(TZTPROG_INCR.pidm), 0)) AS Dias_atraso,
                                        ROUND(NVL(PKG_REPORTES_1.f_dias_atraso(TZTPROG_INCR.pidm), 0) / 30) AS Meses_atraso,
                                        NVL(PKG_REPORTES_1.f_mora(TZTPROG_INCR.pidm), 0) AS Mora,
                                        (SELECT /*+ PARALLEL(TBRACCD, 8) PARALLEL(TZTNCD, 8) */ COUNT(*)
                                         FROM tbraccd, TZTNCD
                                         WHERE tbraccd.tbraccd_detail_code = TZTNCD.TZTNCD_CODE
                                         AND TZTNCD.TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                         AND tbraccd.tbraccd_pidm = TZTPROG_INCR.pidm) AS Depositos,
                                        0,
                                        NULL,
                                        SYSDATE,
                                        TZTPROG_INCR.sp,
                                        pkg_utilerias.f_servicio_social(TZTPROG_INCR.pidm) AS Servicio_Social,
                                        (SELECT /*+ PARALLEL(TBBESTU, 8) */ DISTINCT MAX(SUBSTR(TBBESTU.TBBESTU_EXEMPTION_CODE, 4, 3))
                                         FROM TBBESTU
                                         WHERE TBBESTU.TBBESTU_PIDM = TZTPROG_INCR.pidm
                                         AND TZTPROG_INCR.nivel = DECODE(SUBSTR(TBBESTU.TBBESTU_EXEMPTION_CODE, 1, 2), '20', 'MA', '10', 'LI', '90', 'DO', '10', 'BA')
                                         AND TBBESTU.TBBESTU_TERM_CODE = (SELECT MAX(TBBESTU_A1.TBBESTU_TERM_CODE)
                                                                           FROM TBBESTU TBBESTU_A1
                                                                           WHERE TBBESTU.TBBESTU_PIDM = TBBESTU_A1.TBBESTU_PIDM
                                                                           AND SUBSTR(TBBESTU.TBBESTU_EXEMPTION_CODE, 1, 2) = SUBSTR(TBBESTU_A1.TBBESTU_EXEMPTION_CODE, 1, 2))) AS Beca,
                                        'ADMITIDO' AS desicion,
                                        NULL,
                                        PKG_UTILERIAS.f_escuela(TZTPROG_INCR.programa) AS Desc_Escuela,
                                        PKG_UTILERIAS.f_programa_desc(TZTPROG_INCR.programa) AS Desc_Programa,
                                        PKG_UTILERIAS.f_Jornada_desc(pkg_utilerias.f_calcula_jornada(TZTPROG_INCR.pidm, TZTPROG_INCR.sp, TZTPROG_INCR.nivel, pkg_utilerias.f_periodo_materias(TZTPROG_INCR.pidm, TZTPROG_INCR.fecha_inicio, TZTPROG_INCR.sp))) AS Desc_Jornada,
                                        PKG_UTILERIAS.f_periodo_desc(TZTPROG_INCR.MATRICULACION) AS Desc_Periodo,
                                        TZTPROG_INCR.matricula || TZTPROG_INCR.programa || TZTPROG_INCR.sp,
                                        pkg_utilerias.f_celular(TZTPROG_INCR.pidm, 'CELU') AS Celular,
                                        pkg_utilerias.f_celular(TZTPROG_INCR.pidm, 'RESI') AS Residencia,
                                        PKG_INCONCERT.f_genero(TZTPROG_INCR.pidm) AS Genero,
                                        TO_DATE(pkg_utilerias.f_fecha_nac(TZTPROG_INCR.pidm), 'dd/mm/rrrr') AS Fecha_Nac,
                                        PKG_INCONCERT.f_nacionalidad(TZTPROG_INCR.pidm) AS Nacionalidad,
                                        NVL(TRIM(pkg_utilerias.f_correo(TZTPROG_INCR.pidm, 'PRIN')), NVL(TRIM(pkg_utilerias.f_correo(TZTPROG_INCR.pidm, 'UCAM')), TRIM(pkg_utilerias.f_correo(TZTPROG_INCR.pidm, 'UTLX')))) AS Correo_Principal,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NULL,
                                        NVL(TZTPROG_INCR.FECHA_PRIMERA, TZTPROG_INCR.FECHA_INICIO) AS Primer_Materia,
                                        TRIM(pkg_utilerias.f_cadena_etiqueta(TZTPROG_INCR.pidm)) AS etiquetas,
                                        (SELECT /*+ PARALLEL(SPBPERS, 8) */ DISTINCT SPBPERS.SPBPERS_SSN
                                         FROM SPBPERS
                                         WHERE 1 = 1
                                         AND SPBPERS.SPBPERS_pidm = TZTPROG_INCR.pidm
                                         AND SPBPERS.SPBPERS_SSN IS NOT NULL) AS NSS,
                                        0,
                                        NULL,
                                        pkg_utilerias.f_correo(TZTPROG_INCR.pidm, 'ALTE') AS correo_Alterno,
                                        pkg_inconcert.f_fecha_pago(TZTPROG_INCR.pidm) AS Fecha_pago,
                                        pkg_inconcert.f_fecha_pago_ultima(TZTPROG_INCR.pidm) AS Fecha_Ultimo_Pago,
                                        pkg_inconcert.f_pago_col(TZTPROG_INCR.pidm) AS Estatus_Pago,
                                        pkg_inconcert.f_monto_col_pago(TZTPROG_INCR.pidm) AS Monto_pago,
                                        pkg_inconcert.f_col_cargo_mes(TZTPROG_INCR.pidm) AS Monto_Mensual,
                                        pkg_inconcert.f_col_primer_pago(TZTPROG_INCR.pidm) AS Monto_primer_pago,
                                        pkg_inconcert.f_numero_pago(TZTPROG_INCR.pidm) AS Numero_Depositos,
                                        TZTPROG_INCR.TIPO_INGRESO_DESC AS Tipo_Ingreso,
                                        pkg_inconcert.f_fecha_complemento(TZTPROG_INCR.pidm) AS Fecha_complemento,
                                        stvSTYP.stvSTYP_desc AS Tipo_alumno,
                                        TZTPROG_INCR.FECHA_MOV AS Fecha_Estatus,
                                        NULL,
                                        PKG_INCONCERT_UNI.dias_segundo_pago(TZTPROG_INCR.pidm, TZTPROG_INCR.fecha_inicio) AS Dias_segundo_col,
                                        PKG_INCONCERT_UNI.fecha_segundo_pago(TZTPROG_INCR.pidm, TZTPROG_INCR.fecha_inicio) AS Fecha_segundo_col,
                                        PKG_INCONCERT_UNI.fecha_inicio_nive(TZTPROG_INCR.pidm) AS Fecha_Inicio_NIVE,
                                        PKG_INCONCERT_UNI.Estatus_nive(TZTPROG_INCR.pidm) AS Estatus_NIVE,
                                        PKG_INCONCERT_UNI.fecha_fin_nive(TZTPROG_INCR.pidm) AS Fecha_Fin_NIVE,
                                        pkg_utilerias.f_celular(TZTPROG_INCR.pidm, 'AUTO') AS Tel_nivel,
                                        PKG_INCONCERT_UNI.Materias_NP(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Materias_NP,
                                        PKG_INCONCERT_UNI.Materias_rep(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Materias_rep,
                                        PKG_INCONCERT_UNI.tipo_nivelacion(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS TIPO_NIVELACION,
                                        pkg_utilerias.f_tipo_etiqueta(TZTPROG_INCR.pidm, 'EUTL') AS colaborador_fam,
                                        PKG_INCONCERT_UNI.año_egreso(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS año_egreso,
                                        pkg_utilerias.f_tipo_etiqueta(TZTPROG_INCR.pidm, 'EUTL') AS titulo_cero,
                                        PKG_INCONCERT_UNI.aprocrifos(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS apocrifo,
                                        PKG_INCONCERT_UNI.egel(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Estatus_Egel,
                                        PKG_INCONCERT_UNI.Certif_dig(TZTPROG_INCR.pidm, TZTPROG_INCR.nivel) AS certificado_dig,
                                        PKG_INCONCERT_UNI.Acta_nac_or(TZTPROG_INCR.pidm, TZTPROG_INCR.nivel) AS Acta_Nac_or,
                                        PKG_INCONCERT_UNI.Certif_dig(TZTPROG_INCR.pidm, TZTPROG_INCR.nivel) AS certificado_DIg_ANt,
                                        PKG_INCONCERT_UNI.Certif_dig_LIC(TZTPROG_INCR.pidm) AS certificado_DIg_LIC,
                                        PKG_INCONCERT_UNI.equivalencia(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS equivalencia,
                                        PKG_INCONCERT_UNI.convalidacion(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS convalidacion,
                                        PKG_INCONCERT_UNI.Certi_parcial_dig(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Certif_Parcial_Dig,
                                        PKG_INCONCERT_UNI.Diplo_Interm_dig(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Diploma_intermedia_Dig,
                                        PKG_INCONCERT_UNI.Diplo_Int_dig_pago(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Pago_Diploma_intermedio,
                                        PKG_INCONCERT_UNI.Diplo_master_dig(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Diploma_Master_Dig,
                                        PKG_INCONCERT_UNI.Constancia_dig_pago(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Constancia_Dig_Pago,
                                        PKG_INCONCERT_UNI.Apostillado_dig(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Apostillado_Dig,
                                        PKG_INCONCERT_UNI.Constancia_progra_dig(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Constancia_progra_dig,
                                        PKG_INCONCERT_UNI.Envio_paqueteria(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Envio_paqueteria,
                                        PKG_INCONCERT_UNI.colegiatura_final(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Colegiatura_final,
                                        PKG_INCONCERT_UNI.Convalidacion_USA(TZTPROG_INCR.pidm, TZTPROG_INCR.sp) AS Convalidacion_USA,
                                        PKG_INCONCERT_UNI.master_maestria(TZTPROG_INCR.pidm, TZTPROG_INCR.sp, TZTPROG_INCR.campus, TZTPROG_INCR.nivel) AS master_maestria,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT BLOQUE_SEG FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS BLOQUE_SEG,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT NIVEL_RIESGO FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS NIVEL_RIESGO,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT SEMAFORO FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS SEMAFORO,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT TUTOR FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS TUTOR,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT SUPERVISOR FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS SUPERVISOR,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT LINEA_NEGOCIO FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS LINEA_NEGOCIO,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT MODALIDAD FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS MODALIDAD_2,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT ESTRATEGIA_1 FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS ESTRATEGIA_1,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT ESTRATEGIA_2 FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS ESTRATEGIA_2,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT ESTRATEGIA_3 FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS ESTRATEGIA_3,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT RIESGO_PERMANENCIA FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS RIESGO_PERMANENCIA,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT FASE_1 FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS FASE_1,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT FASE_2 FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS FASE_2,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT NR_NIVELACION FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS NR_NIVELACION,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT CLAVE_MATERIA_NIVE FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS CLAVE_MATERIA_NIVE,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT MODALIDAD_EVA_NIVE FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS MODALIDAD_EVA_NIVE,
                                        (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT EGEL_PLAN_ESTUDIO FROM nivel_riesgo WHERE nivel_riesgo.matricula = TZTPROG_INCR.matricula) AS EGEL_PLAN_ESTUDIO,
                                        '1' FLAG_hubspot,
                                        ceil((sysdate-TZTPROG_INCR.fecha_inicio) / 7) NO_SEMANA,
                                        null,
                                        null
                                    FROM TZTPROG_INCR /*+ PARALLEL(TZTPROG_INCR, 8) */
                                    JOIN spriden /*+ PARALLEL(SPRIDEN, 8) */ ON SPRIDEN.spriden_pidm = TZTPROG_INCR.pidm AND SPRIDEN.spriden_change_ind IS NULL
                                    JOIN stvSTYP /*+ PARALLEL(STVSTYP, 8) */ ON stvSTYP.stvSTYP_code = TZTPROG_INCR.SGBSTDN_STYP_CODE
                                    WHERE 1 = 1
                                    AND TZTPROG_INCR.estatus NOT IN ('CP')
                                    AND TZTPROG_INCR.sp = (SELECT MAX(TZTPROG_INCR_A1.sp)
                                                            FROM TZTPROG_INCR TZTPROG_INCR_A1 /*+ PARALLEL(TZTPROG_INCR_A1, 8) */
                                                            WHERE TZTPROG_INCR.pidm = TZTPROG_INCR_A1.pidm
                                                            AND TZTPROG_INCR_A1.campus || TZTPROG_INCR_A1.nivel NOT IN ('UTSID', 'INIEC')
                                                            AND TZTPROG_INCR_A1.programa = TZTPROG_INCR.programa
                                                            AND TZTPROG_INCR.estatus = TZTPROG_INCR_A1.estatus)
                                    AND TZTPROG_INCR.matricula = c.matricula
                                    AND TZTPROG_INCR.programa = c.programa;

                                    COMMIT;

                                    Exception
                                     When Others then
                                     vl_error:= sqlerrm;
                                        Begin
                                            Insert into migra.tmp_inconcert values (c.matricula, c.programa, vl_error);
                                            Commit;
                                        End;
                                    -- dbms_output.put_line('Error al insertar Matricula' ||c.matricula ||'*'||c.programa||'*'||sqlerrm );
                                    End;

                          Else -----> Actualiza los cambios en la tabla de CRM
                          
                            --dbms_output.put_line('Entra para Actualizar' ||c.matricula ||'*'||c.programa );
                           Begin
                            
                                For cx in (

                                            SELECT /*+ PARALLEL(8) */ DISTINCT a.pidm,
                                                   a.matricula,
                                                   substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1) Paterno,
                                                   substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150) Materno,
                                                   SPRIDEN_FIRST_NAME Nombre,
                                                   a.campus,
                                                   a.nivel,
                                                   a.ESTATUS_D estatus,
                                                   a.programa,
                                                   pkg_utilerias.f_modalidad(a.programa, a.ctlg) Modalidad,
                                                   decode (substr (pkg_utilerias.f_calcula_rate(a.pidm, a.programa), length (pkg_utilerias.f_calcula_rate(a.pidm, a.programa))-1 ,1),'A','15','B', '30') Fecha_Corte,
                                                   trunc (a.fecha_inicio) Fecha_Inicio,
                                                   (SELECT /*+ PARALLEL(SZTHITA, 8) */ DISTINCT max(SZTHITA_E_CURSO)
                                                    FROM szthita
                                                    WHERE 1= 1
                                                      AND SZTHITA_PIDM = a.pidm
                                                      AND SZTHITA_STUDY = a.sp) Materias_Inscritas,
                                                   (SELECT /*+ PARALLEL(SZTHITA, 8) */ DISTINCT max (SZTHITA_APROB)
                                                    FROM szthita
                                                    WHERE 1= 1
                                                      AND SZTHITA_PIDM = a.pidm
                                                      AND SZTHITA_STUDY = a.sp) Materias_Aprobadas,
                                                   nvl ((SELECT /*+ PARALLEL(SZTHITA, 8) */ DISTINCT max (SZTHITA_AVANCE)
                                                         FROM szthita
                                                         WHERE 1= 1
                                                           AND SZTHITA_PIDM = a.pidm
                                                           AND SZTHITA_STUDY = a.sp),0) Avance_Curricular,
                                                   substr (pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel, pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp)),
                                                           length (pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel, pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp))) ,1
                                                          ) Jornada,
                                                   TRunc( (SELECT /*+ PARALLEL(SARADAP, 8) PARALLEL(SARAPPD, 8) */ DISTINCT max (SARAPPD_APDC_DATE)
                                                           FROM saradap
                                                           JOIN sarappd ON SARAPPD_PIDM = SARADAP_PIDM AND SARAPPD_TERM_CODE_ENTRY = SARADAP_TERM_CODE_ENTRY AND SARAPPD_APPL_NO = SARADAP_APPL_NO
                                                           WHERE saradap_pidm = a.pidm
                                                             AND SARADAP_PROGRAM_1 = a.programa
                                                             AND SARAPPD_APDC_CODE =35)) Fecha_Desicion,
                                                   Nvl ((SELECT /*+ PARALLEL(SPREMRG, 8) */ decode (count(1),'0', 'SinFacturacion', '1', 'ConFacturacion')
                                                         FROM SPREMRG
                                                         WHERE 1=1
                                                           AND SPREMRG_pidm = a.pidm),'SinFacturacion') Factura,
                                                   nvl (PKG_DASHBOARD_ALUMNO.f_dashboard_saldototal(a.pidm),0) Saldo_Total,
                                                   nvl (PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(a.pidm),0) Saldo_Dia,
                                                   round(nvl (PKG_REPORTES_1.f_dias_atraso(a.pidm),0)) Dias_atraso,
                                                   round(nvl (PKG_REPORTES_1.f_dias_atraso(a.pidm),0) / 30) Meses_atraso,
                                                   nvl (PKG_REPORTES_1.f_mora(a.pidm),0) Mora,
                                                   (SELECT /*+ PARALLEL(TBRACCD, 8) PARALLEL(TZTNCD, 8) */ count(*)
                                                    FROM tbraccd, TZTNCD
                                                    WHERE tbraccd_detail_code = TZTNCD_CODE
                                                      AND TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion')
                                                      AND tbraccd_pidm = a.pidm) Depositos,
                                                   pkg_utilerias.f_servicio_social(a.pidm) Servicio_Social,
                                                   (
                                                    SELECT /*+ PARALLEL(TBBESTU, 8) */ DISTINCT max (substr (ax.TBBESTU_EXEMPTION_CODE, 4,3)) Beca
                                                    FROM TBBESTU ax
                                                    WHERE ax.TBBESTU_PIDM = a.pidm AND a.nivel = decode (substr (ax.TBBESTU_EXEMPTION_CODE,1,2),'20', 'MA', '10', 'LI', '90','DO', '10', 'BA')
                                                      AND ax.TBBESTU_TERM_CODE = (SELECT max (a1.TBBESTU_TERM_CODE)
                                                                                  FROM TBBESTU a1
                                                                                  WHERE ax.TBBESTU_PIDM = a1.TBBESTU_PIDM
                                                                                    AND substr (ax.TBBESTU_EXEMPTION_CODE,1,2) = substr (a1.TBBESTU_EXEMPTION_CODE,1,2)
                                                                                 )
                                                   ) Beca,
                                                   'ADMITIDO' Desicion,
                                                   PKG_UTILERIAS.f_escuela(a.programa) Desc_Escuela,
                                                   PKG_UTILERIAS.f_programa_desc(a.programa) Desc_Programa,
                                                   PKG_UTILERIAS.f_Jornada_desc(pkg_utilerias.f_calcula_jornada (a.pidm, a.sp, a.nivel, pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp))) Desc_Jornada,
                                                   PKG_UTILERIAS.f_periodo_desc(pkg_utilerias.f_periodo_materias (a.pidm, a.fecha_inicio, a.sp)) Periodo_desc,
                                                   pkg_utilerias.f_celular(a.pidm, 'CELU') MOVIL,
                                                   pkg_utilerias.f_celular(a.pidm, 'RESI') TELEFONO_CASA,
                                                   PKG_INCONCERT.f_genero(a.pidm) GENERO,
                                                   to_date (pkg_utilerias.f_fecha_nac(a.pidm),'dd/mm/rrrr') FECHA_NACIMIENTO,
                                                   PKG_INCONCERT.f_nacionalidad(a.pidm) NACIONALIDAD,
                                                   nvl (trim (pkg_utilerias.f_correo(a.pidm, 'PRIN')), nvl (trim (pkg_utilerias.f_correo(a.pidm, 'UCAM')),trim (pkg_utilerias.f_correo(a.pidm, 'UTLX')) )) CORREO_ELECTRONICO,
                                                   nvl (a.FECHA_PRIMERA,a.FECHA_INICIO) Primer_Materia,
                                                   trim (pkg_utilerias.f_cadena_etiqueta(a.pidm)) etiquetas,
                                                   (SELECT /*+ PARALLEL(SPBPERS, 8) */ DISTINCT SPBPERS_SSN
                                                    FROM SPBPERS
                                                    WHERE 1=1
                                                      AND SPBPERS_pidm = a.pidm
                                                      AND SPBPERS_SSN IS NOT NULL) NSS,
                                                   pkg_utilerias.f_correo(a.pidm, 'ALTE') correo_Alterno,
                                                   pkg_inconcert.f_fecha_pago(a.pidm) Fecha_pago,
                                                   pkg_inconcert.f_fecha_pago_ultima(a.pidm) Fecha_Ultimo_Pago,
                                                   pkg_inconcert.f_pago_col(a.pidm) Estatus_Pago,
                                                   pkg_inconcert.f_monto_col_pago(a.pidm) Monto_pago,
                                                   pkg_inconcert.f_col_cargo_mes(a.pidm) Monto_Mensual,
                                                   pkg_inconcert.f_col_primer_pago(a.pidm) Monto_primer_pago,
                                                   pkg_inconcert.f_numero_pago(a.pidm) Numero_Depositos,
                                                   a.TIPO_INGRESO_DESC Tipo_Ingreso,
                                                   pkg_inconcert.f_fecha_complemento(a.pidm) Fecha_complemento,
                                                   a.sp,
                                                   stvSTYP_desc Tipo_alumno,
                                                   a.FECHA_MOV Fecha_Estatus,
                                                   PKG_INCONCERT_UNI.dias_segundo_pago(a.pidm, a.fecha_inicio) Dias_segundo_col,
                                                   PKG_INCONCERT_UNI.fecha_segundo_pago(a.pidm, a.fecha_inicio) FECHA_SEGUNDA_COL,
                                                   PKG_INCONCERT_UNI.fecha_inicio_nive(a.pidm) FECHA_INI_NIVE,
                                                   PKG_INCONCERT_UNI.Estatus_nive(a.pidm) Estatus_NIVE,
                                                   PKG_INCONCERT_UNI.fecha_fin_nive(a.pidm) Fecha_Fin_NIVE,
                                                   pkg_utilerias.f_celular(a.pidm, 'AUTO') TEL_NIVE,
                                                   PKG_INCONCERT_UNI.Materias_NP(a.pidm, a.sp) MATERIAS_NP,
                                                   PKG_INCONCERT_UNI.Materias_rep (a.pidm, a.sp) MATERIAS_REP,
                                                   PKG_INCONCERT_UNI.tipo_nivelacion(a.pidm, a.sp) TIPO_NIVELACION,
                                                   pkg_utilerias.f_tipo_etiqueta(a.pidm, 'EUTL') COLABORADOR_FAM,
                                                   PKG_INCONCERT_UNI.año_egreso(a.pidm, a.sp) AÑO_EGRESO,
                                                   pkg_utilerias.f_tipo_etiqueta(a.pidm, 'EUTL') TITULO_CERO,
                                                   PKG_INCONCERT_UNI.aprocrifos(a.pidm, a.sp) APOCRIFOS,
                                                   PKG_INCONCERT_UNI.egel(a.pidm, a.sp) ESTATUS_EGEL,
                                                   PKG_INCONCERT_UNI.Certif_dig(a.pidm, a.nivel) certificado_dig,
                                                   PKG_INCONCERT_UNI.Acta_nac_or(a.pidm, a.nivel) ACTA_NAC_OR,
                                                   PKG_INCONCERT_UNI.Certif_dig(a.pidm, a.nivel) CERTIFICADO_DIG_ANT,
                                                   PKG_INCONCERT_UNI.Certif_dig_LIC(a.pidm) CERTIFICADO_DIG_LIC,
                                                   PKG_INCONCERT_UNI.equivalencia(a.pidm, a.sp) EQUIVALENCIA,
                                                   PKG_INCONCERT_UNI.convalidacion(a.pidm, a.sp) CONVALIDACION,
                                                   PKG_INCONCERT_UNI.Certi_parcial_dig(a.pidm, a.sp) CERTIFICADO_PAR_DIG,
                                                   PKG_INCONCERT_UNI.Diplo_Interm_dig(a.pidm, a.sp) DIPLOMA_INTER_DIG,
                                                   PKG_INCONCERT_UNI.Diplo_Int_dig_pago(a.pidm, a.sp) PAGO_DIP_INT_DIG,
                                                   PKG_INCONCERT_UNI.Diplo_master_dig(a.pidm, a.sp) DIPLOMA_MASTER_DIG,
                                                   PKG_INCONCERT_UNI.Constancia_dig_pago(a.pidm, a.sp) CONSTANCIA_DIG_PAGO,
                                                   PKG_INCONCERT_UNI.Apostillado_dig(a.pidm, a.sp) APOSTILLADO_DIG,
                                                   PKG_INCONCERT_UNI.Constancia_progra_dig(a.pidm, a.sp) CONSTANCIA_PROGRA_DIG,
                                                   PKG_INCONCERT_UNI.Envio_paqueteria(a.pidm, a.sp) ENVIO_PAQUETERIA,
                                                   PKG_INCONCERT_UNI.colegiatura_final(a.pidm, a.sp) Colegiatura_final,
                                                   PKG_INCONCERT_UNI.Convalidacion_USA(a.pidm, a.sp) Convalidacion_USA,
                                                   PKG_INCONCERT_UNI.master_maestria (a.pidm, a.sp, a.campus, a.nivel) master_maestria,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT BLOQUE_SEG FROM nivel_riesgo WHERE matricula = a.matricula) BLOQUE_SEG,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT NIVEL_RIESGO FROM nivel_riesgo WHERE matricula = a.matricula) NIVEL_RIESGO,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT SEMAFORO FROM nivel_riesgo WHERE matricula = a.matricula) SEMAFORO,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT TUTOR FROM nivel_riesgo WHERE matricula = a.matricula) TUTOR,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT SUPERVISOR FROM nivel_riesgo WHERE matricula = a.matricula) SUPERVISOR,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT LINEA_NEGOCIO FROM nivel_riesgo WHERE matricula = a.matricula) LINEA_NEGOCIO,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT MODALIDAD FROM nivel_riesgo WHERE matricula = a.matricula) MODALIDAD_2,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT ESTRATEGIA_1 FROM nivel_riesgo WHERE matricula = a.matricula) ESTRATEGIA_1,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT ESTRATEGIA_2 FROM nivel_riesgo WHERE matricula = a.matricula) ESTRATEGIA_2,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT ESTRATEGIA_3 FROM nivel_riesgo WHERE matricula = a.matricula) ESTRATEGIA_3,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT RIESGO_PERMANENCIA FROM nivel_riesgo WHERE matricula = a.matricula) RIESGO_PERMANENCIA,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT FASE_1 FROM nivel_riesgo WHERE matricula = a.matricula) FASE_1,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT FASE_2 FROM nivel_riesgo WHERE matricula = a.matricula) FASE_2,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT NR_NIVELACION FROM nivel_riesgo WHERE matricula = a.matricula) NR_NIVELACION,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT CLAVE_MATERIA_NIVE FROM nivel_riesgo WHERE matricula = a.matricula) CLAVE_MATERIA_NIVE,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT MODALIDAD_EVA_NIVE FROM nivel_riesgo WHERE matricula = a.matricula) MODALIDAD_EVA_NIVE,
                                                   (SELECT /*+ PARALLEL(NIVEL_RIESGO, 8) */ DISTINCT EGEL_PLAN_ESTUDIO FROM nivel_riesgo WHERE matricula = a.matricula) EGEL_PLAN_ESTUDIO,
                                                   '0' FLAG_hubspot,
                                                   ceil((sysdate - a.fecha_inicio) / 7) NO_SEMANA
                                            FROM TZTPROG_INCR a /*+ PARALLEL(TZTPROG_INCR, 8) */
                                            JOIN spriden b /*+ PARALLEL(SPRIDEN, 8) */ ON b.spriden_pidm = a.pidm AND b.spriden_change_ind IS NULL
                                            JOIN stvSTYP /*+ PARALLEL(STVSTYP, 8) */ ON stvSTYP_code = A.SGBSTDN_STYP_CODE
                                            WHERE 1= 1
                                              AND a.estatus NOT IN ('CP')
                                              AND a.sp = (SELECT max (a1.sp)
                                                          FROM TZTPROG_INCR a1 /*+ PARALLEL(TZTPROG_INCR, 8) */
                                                          WHERE a.pidm = a1.pidm
                                                            AND a1.campus||a1.nivel NOT IN ( 'UTSID','INIEC')
                                                            AND a1.programa = a.programa
                                                            AND a.estatus = a1.estatus
                                                         )
                                              AND a.matricula =c.matricula
                                              AND a.programa = c.programa
                                        

                            ) loop

                          ---------------------- Bloque para actualizar por cada uno de los campos de la tabla --------------
                                --dbms_output.put_line('Recupero datos ' || cx.matricula ||cx.paterno ||'*'||vl_campo );

                                Begin
                                        Select paterno
                                            into vl_campo
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
                                                set a.MATERIAS_APROBADAS = cx.MATERIAS_APROBADAS,
                                                     a.estatus_envio = 0,
                                                     a.estatus_envio_ee = 0,
                                                     a.fecha_actualiza = sysdate,
                                                     a.OBSERVACIONES = 'Se actualizo Aprobadas',
                                                     a.OBSERVACIONES_ee = 'Se actualizo Aprobadas'
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                        --dbms_output.put_line('Entra para CORREO_ELECTRONICO ' || cx.matricula|| '*'||cx.CORREO_ELECTRONICO ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                        --dbms_output.put_line('Entra para Fecha_Primera ' || cx.matricula|| '*'||cx.Primer_Materia ||'*'||vl_campo );
                                        Begin
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                      --dbms_output.put_line('Entra para actualizar etiquetas ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||(cx.ETIQUETAS) );
                                        Begin
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                --dbms_output.put_line('Entra para NSS ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||(cx.NSS) );
                         
                                If trim (cx.NSS) = trim (vl_campo) then
                                    null;
                                   -- dbms_output.put_line('No hace nada NSS' );
                                ElsIf trim (cx.NSS) is null then
                                    null;
                                   -- dbms_output.put_line('No hace nada NSS' );
                                Else
                                
                                --dbms_output.put_line('Entra Actualizar NSS' );
                                        Begin
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                        Update sztecrm_uni a
                                            set a.CORREO_ALTERNO = cx.correo_Alterno
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo Correo Alterno',
                                                a.OBSERVACIONES_ee = 'Se actualizo Correo Alterno'
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
                                         From sztecrm_uni a
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
                                        Update sztecrm_uni a
                                            set a.FECHA_PAGO = cx.FECHA_PAGO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo FECHA_PAGO',
                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_PAGO'
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
                                         From sztecrm_uni a
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
                                        Update sztecrm_uni a
                                            set a.FECHA_ULTIMO_PAGO = cx.FECHA_ULTIMO_PAGO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo FECHA_ULTIMO_PAGO',
                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_ULTIMO_PAGO'
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
                                         From sztecrm_uni a
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
                                        Update sztecrm_uni a
                                            set a.ESTATUS_PAGO = cx.ESTATUS_PAGO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo ESTATUS_PAGO',
                                                a.OBSERVACIONES_ee = 'Se actualizo ESTATUS_PAGO'
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
                                         From sztecrm_uni a
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
                                        Update sztecrm_uni a
                                            set a.MONTO_PAGO = cx.MONTO_PAGO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo MONTO_PAGO',
                                                a.OBSERVACIONES_ee = 'Se actualizo ESTATUS_PAGO'
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
                                         From sztecrm_uni a
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
                                        Update sztecrm_uni a
                                            set a.MONTO_MENSUAL = cx.MONTO_MENSUAL
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo MONTO_MENSUAL',
                                                a.OBSERVACIONES_ee = 'Se actualizo MONTO_MENSUAL'
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
                                         From sztecrm_uni a
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
                                        Update sztecrm_uni a
                                            set a.MONTO_PRIMER_PAGO = cx.MONTO_PRIMER_PAGO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo MONTO_PRIMER_PAGO',
                                                a.OBSERVACIONES_ee = 'Se actualizo MONTO_PRIMER_PAGO'
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
                                         From sztecrm_uni a
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
                                        Update sztecrm_uni a
                                            set a.NUMERO_DEPOSITOS = cx.NUMERO_DEPOSITOS
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo NUMERO_DEPOSITOS',
                                                a.OBSERVACIONES_ee = 'Se actualizo NUMERO_DEPOSITOS'
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
                                         From sztecrm_uni a
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
                                  --dbms_output.put_line('Entra para TIPO_INGRESO ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.TIPO_INGRESO );
                                
                                    Begin
                                        Update sztecrm_uni a
                                            set a.TIPO_INGRESO = cx.TIPO_INGRESO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo TIPO_INGRESO',
                                                a.OBSERVACIONES_ee = 'Se actualizo TIPO_INGRESO'
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
                                         From sztecrm_uni a
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
                                --dbms_output.put_line('Entra para FECHA_COMPLEMENTO ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.FECHA_COMPLEMENTO );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.FECHA_COMPLEMENTO = cx.FECHA_COMPLEMENTO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo FECHA_COMPLEMENTO',
                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_COMPLEMENTO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                                                                                                                                           
                                 
                                 
                           ------------------------------------- Study_Path -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.sp)
                                            into vl_campo
                                         From sztecrm_uni a
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
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.sp = cx.sp
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo SP',
                                                a.OBSERVACIONES_ee = 'Se actualizo SP'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                      
                                 
                                 ----------------------------------------------------------------------------------------------
                                ----------------------------------------------------------------------------------------------

                         -------------------------------------Tipo de ingreso -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.TIPO_ALUMNO)
                                            into vl_campo
                                         From sztecrm_UNI a
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
                                 --dbms_output.put_line('Entra para Tipo de ingreso 1 ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.TIPO_ALUMNO );
                                       Begin
                                            Update sztecrm_UNI a
                                                set a.TIPO_ALUMNO = trim (cx.TIPO_ALUMNO),
                                                     a.estatus_envio_EE = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES_EE = 'Se actualizo Tipo Alumno'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;
                                ElsIf trim (cx.TIPO_ALUMNO) != vl_campo and  trim (cx.TIPO_ALUMNO) is not null  then
                               --dbms_output.put_line('Entra para Tipo de ingreso 2' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.TIPO_ALUMNO );
                                       Begin
                                            Update sztecrm_UNI a
                                                set a.TIPO_ALUMNO = trim (cx.TIPO_ALUMNO),
                                                     a.estatus_envio_EE = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES_EE = 'Se actualizo Tipo Alumno'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;
                                Else
                               --dbms_output.put_line('Entra para Tipo de ingreso 3' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.TIPO_ALUMNO );
                                       Begin
                                            Update sztecrm_UNI a
                                                set a.TIPO_ALUMNO = trim (cx.TIPO_ALUMNO),
                                                     a.estatus_envio_EE = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES_EE = 'Se actualizo Tipo Alumno'
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
                                         From sztecrm_UNI a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                --dbms_output.put_line('Entra para Fecha de Estatus ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||(cx.FECHA_ESTATUS) );
                         
                                If trim (cx.FECHA_ESTATUS) = trim (vl_campo) then
                                    null;
                                    --dbms_output.put_line('No hace nada Fecha de Estatus' );
                                ElsIf trim (cx.FECHA_ESTATUS) is null and  vl_campo is not null  then
                                 --  dbms_output.put_line('TIPO_ALUMNO Entra1' );
                                       Begin
                                            Update sztecrm_UNI a
                                                set a.FECHA_ESTATUS = trim (cx.FECHA_ESTATUS),
                                                     a.estatus_envio_EE = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES_EE = 'Se actualizo Fecha de Estatus'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;
                                ElsIf trim (cx.FECHA_ESTATUS) != vl_campo and  trim (cx.FECHA_ESTATUS) is not null  then
                                --dbms_output.put_line('Fecha de Estatus Entra2' );
                                       Begin
                                            Update sztecrm_UNI a
                                                set a.FECHA_ESTATUS = trim (cx.FECHA_ESTATUS),
                                                     a.estatus_envio_EE = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES_EE = 'Se actualizo Fecha de Estatus'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                            null;
                                       End;
                                Else
                                    --dbms_output.put_line('Fecha de Estatus Entra3' );
                                       Begin
                                            Update sztecrm_UNI a
                                                set a.FECHA_ESTATUS = trim (cx.FECHA_ESTATUS),
                                                     a.estatus_envio_EE = 0,
                                                     a.fecha_actualiza = sysdate,
                                                    a.OBSERVACIONES_EE = 'Se actualizo Fecha de Estatus'
                                             where  a.matricula = cx.matricula
                                            And a.programa = cx.programa;
                                       Exception
                                        When Others then
                                           null;
                                       End;



                                End if;
                                 Commit;   
                                 
--------------------------------------------------------------------- Actualizacion SFTP EE ---------------------------------------

                           ------------------------------------- DIAS_SEGUNDO_COL -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.DIAS_SEGUNDO_COL)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.DIAS_SEGUNDO_COL) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.DIAS_SEGUNDO_COL) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.DIAS_SEGUNDO_COL = cx.DIAS_SEGUNDO_COL
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo DIAS_SEGUNDO_COL',
                                                a.OBSERVACIONES_ee = 'Se actualizo DIAS_SEGUNDO_COL'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                      
                                                                  
                           ------------------------------------- FECHA_SEGUNDA_COL -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.FECHA_SEGUNDA_COL)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_SEGUNDA_COL) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_SEGUNDA_COL) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.FECHA_SEGUNDA_COL = cx.FECHA_SEGUNDA_COL
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo FECHA_SEGUNDA_COL',
                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_SEGUNDA_COL'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                  


                          ------------------------------------- FECHA_INI_NIVE -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.FECHA_INI_NIVE)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_INI_NIVE) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_INI_NIVE) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.FECHA_INI_NIVE = cx.FECHA_INI_NIVE
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo FECHA_INI_NIVE',
                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_INI_NIVE'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;    


                          ------------------------------------- ESTATUS_NIVE -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.ESTATUS_NIVE)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ESTATUS_NIVE) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ESTATUS_NIVE) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.ESTATUS_NIVE = cx.ESTATUS_NIVE
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo ESTATUS_NIVE',
                                                a.OBSERVACIONES_ee = 'Se actualizo ESTATUS_NIVE'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;    
 
                          ------------------------------------- FECHA_FIN_NIVE -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.FECHA_FIN_NIVE)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FECHA_FIN_NIVE) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FECHA_FIN_NIVE) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.FECHA_FIN_NIVE = cx.FECHA_FIN_NIVE
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo FECHA_FIN_NIVE',
                                                a.OBSERVACIONES_ee = 'Se actualizo FECHA_FIN_NIVE'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;    


                          ------------------------------------- TEL_NIVE -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.TEL_NIVE)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.TEL_NIVE) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.TEL_NIVE) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.TEL_NIVE = cx.TEL_NIVE
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo TEL_NIVE',
                                                a.OBSERVACIONES_ee = 'Se actualizo TEL_NIVE'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;    

                          ------------------------------------- MATERIAS_NP -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.MATERIAS_NP)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.MATERIAS_NP) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.MATERIAS_NP) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.MATERIAS_NP = cx.MATERIAS_NP
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo MATERIAS_NP',
                                                a.OBSERVACIONES_ee = 'Se actualizo MATERIAS_NP'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                          ------------------------------------- MATERIAS_REP -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.MATERIAS_REP)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.MATERIAS_REP) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.MATERIAS_REP) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.MATERIAS_REP = cx.MATERIAS_REP
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo MATERIAS_REP',
                                                a.OBSERVACIONES_ee = 'Se actualizo MATERIAS_REP'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                          ------------------------------------- TIPO_NIVELACION -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.TIPO_NIVELACION)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.TIPO_NIVELACION) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.TIPO_NIVELACION) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.TIPO_NIVELACION = cx.TIPO_NIVELACION
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo TIPO_NIVELACION',
                                                a.OBSERVACIONES_ee = 'Se actualizo TIPO_NIVELACION'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                          ------------------------------------- COLABORADOR_FAM -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.COLABORADOR_FAM)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.COLABORADOR_FAM) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.COLABORADOR_FAM) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.COLABORADOR_FAM = cx.COLABORADOR_FAM
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo COLABORADOR_FAM',
                                                a.OBSERVACIONES_ee = 'Se actualizo COLABORADOR_FAM'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                          ------------------------------------- AÑO_EGRESO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.AÑO_EGRESO)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.AÑO_EGRESO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.AÑO_EGRESO) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.AÑO_EGRESO = cx.AÑO_EGRESO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo AÑO_EGRESO',
                                                a.OBSERVACIONES_ee = 'Se actualizo AÑO_EGRESO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                          ------------------------------------- TITULO_CERO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.TITULO_CERO)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.TITULO_CERO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.TITULO_CERO) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.TITULO_CERO = cx.TITULO_CERO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo TITULO_CERO',
                                                a.OBSERVACIONES_ee = 'Se actualizo TITULO_CERO'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                        ------------------------------------- APOCRIFOS -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.APOCRIFOS)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.APOCRIFOS) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.APOCRIFOS) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.APOCRIFOS = cx.APOCRIFOS
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo APOCRIFOS',
                                                a.OBSERVACIONES_ee = 'Se actualizo APOCRIFOS'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                        ------------------------------------- ESTATUS_EGEL -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.ESTATUS_EGEL)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ESTATUS_EGEL) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ESTATUS_EGEL) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.ESTATUS_EGEL = cx.ESTATUS_EGEL
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo ESTATUS_EGEL',
                                                a.OBSERVACIONES_ee = 'Se actualizo ESTATUS_EGEL'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                        ------------------------------------- CERTIFICADO_DIG -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CERTIFICADO_DIG)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CERTIFICADO_DIG) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CERTIFICADO_DIG) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CERTIFICADO_DIG = cx.CERTIFICADO_DIG
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CERTIFICADO_DIG',
                                                a.OBSERVACIONES_ee = 'Se actualizo CERTIFICADO_DIG'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                       ------------------------------------- ACTA_NAC_OR -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.ACTA_NAC_OR)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ACTA_NAC_OR) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ACTA_NAC_OR) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.ACTA_NAC_OR = cx.ACTA_NAC_OR
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo ACTA_NAC_OR',
                                                a.OBSERVACIONES_ee = 'Se actualizo ACTA_NAC_OR'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                       ------------------------------------- CERTIFICADO_DIG_ANT -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CERTIFICADO_DIG_ANT)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CERTIFICADO_DIG_ANT) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CERTIFICADO_DIG_ANT) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CERTIFICADO_DIG_ANT = cx.CERTIFICADO_DIG_ANT
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CERTIFICADO_DIG_ANT',
                                                a.OBSERVACIONES_ee = 'Se actualizo CERTIFICADO_DIG_ANT'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                       ------------------------------------- CERTIFICADO_DIG_LIC -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CERTIFICADO_DIG_LIC)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CERTIFICADO_DIG_LIC) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CERTIFICADO_DIG_LIC) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CERTIFICADO_DIG_LIC = cx.CERTIFICADO_DIG_LIC
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CERTIFICADO_DIG_LIC',
                                                a.OBSERVACIONES_ee = 'Se actualizo CERTIFICADO_DIG_LIC'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                       ------------------------------------- EQUIVALENCIA -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.EQUIVALENCIA)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.EQUIVALENCIA) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.EQUIVALENCIA) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.EQUIVALENCIA = cx.EQUIVALENCIA
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo EQUIVALENCIA',
                                                a.OBSERVACIONES_ee = 'Se actualizo EQUIVALENCIA'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                       ------------------------------------- CONVALIDACION -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CONVALIDACION)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CONVALIDACION) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CONVALIDACION) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CONVALIDACION = cx.CONVALIDACION
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CONVALIDACION',
                                                a.OBSERVACIONES_ee = 'Se actualizo CONVALIDACION'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                       ------------------------------------- CERTIFICADO_PAR_DIG -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CERTIFICADO_PAR_DIG)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CERTIFICADO_PAR_DIG) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CERTIFICADO_PAR_DIG) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CERTIFICADO_PAR_DIG = cx.CERTIFICADO_PAR_DIG
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CERTIFICADO_PAR_DIG',
                                                a.OBSERVACIONES_ee = 'Se actualizo CERTIFICADO_PAR_DIG'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                       ------------------------------------- DIPLOMA_INTER_DIG -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.DIPLOMA_INTER_DIG)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.DIPLOMA_INTER_DIG) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.DIPLOMA_INTER_DIG) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.DIPLOMA_INTER_DIG = cx.DIPLOMA_INTER_DIG
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo DIPLOMA_INTER_DIG',
                                                a.OBSERVACIONES_ee = 'Se actualizo DIPLOMA_INTER_DIG'
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                       ------------------------------------- PAGO_DIP_INT_DIG -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.PAGO_DIP_INT_DIG)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.PAGO_DIP_INT_DIG) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.PAGO_DIP_INT_DIG) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.PAGO_DIP_INT_DIG = cx.PAGO_DIP_INT_DIG
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo PAGO_DIP_INT_DIG',
                                                a.OBSERVACIONES_ee = 'Se actualizo PAGO_DIP_INT_DIG '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                       ------------------------------------- DIPLOMA_MASTER_DIG -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.DIPLOMA_MASTER_DIG)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.DIPLOMA_MASTER_DIG) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.DIPLOMA_MASTER_DIG) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.DIPLOMA_MASTER_DIG = cx.DIPLOMA_MASTER_DIG
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo DIPLOMA_MASTER_DIG',
                                                a.OBSERVACIONES_ee = 'Se actualizo DIPLOMA_MASTER_DIG '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                      ------------------------------------- CONSTANCIA_DIG_PAGO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CONSTANCIA_DIG_PAGO)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CONSTANCIA_DIG_PAGO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CONSTANCIA_DIG_PAGO) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CONSTANCIA_DIG_PAGO = cx.CONSTANCIA_DIG_PAGO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CONSTANCIA_DIG_PAGO',
                                                a.OBSERVACIONES_ee = 'Se actualizo CONSTANCIA_DIG_PAGO '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                      ------------------------------------- APOSTILLADO_DIG -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.APOSTILLADO_DIG)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.APOSTILLADO_DIG) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.APOSTILLADO_DIG) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.APOSTILLADO_DIG = cx.APOSTILLADO_DIG
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo APOSTILLADO_DIG',
                                                a.OBSERVACIONES_ee = 'Se actualizo APOSTILLADO_DIG '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- CONSTANCIA_PROGRA_DIG -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CONSTANCIA_PROGRA_DIG)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CONSTANCIA_PROGRA_DIG) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CONSTANCIA_PROGRA_DIG) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CONSTANCIA_PROGRA_DIG = cx.CONSTANCIA_PROGRA_DIG
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CONSTANCIA_PROGRA_DIG',
                                                a.OBSERVACIONES_ee = 'Se actualizo CONSTANCIA_PROGRA_DIG '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- ENVIO_PAQUETERIA -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.ENVIO_PAQUETERIA)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ENVIO_PAQUETERIA) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ENVIO_PAQUETERIA) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.ENVIO_PAQUETERIA = cx.ENVIO_PAQUETERIA
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo ENVIO_PAQUETERIA',
                                                a.OBSERVACIONES_ee = 'Se actualizo ENVIO_PAQUETERIA '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                     ------------------------------------- tipo_nivelacion -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.tipo_nivelacion)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.tipo_nivelacion) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.tipo_nivelacion) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.tipo_nivelacion = cx.tipo_nivelacion
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo tipo_nivelacion',
                                                a.OBSERVACIONES_ee = 'Se actualizo tipo_nivelacion '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- COLEGIATURA_FINAL -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.COLEGIATURA_FINAL)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.COLEGIATURA_FINAL) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.COLEGIATURA_FINAL) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.COLEGIATURA_FINAL = cx.COLEGIATURA_FINAL
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo COLEGIATURA_FINAL',
                                                a.OBSERVACIONES_ee = 'Se actualizo COLEGIATURA_FINAL '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- CONVALIDACION_USA -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CONVALIDACION_USA)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CONVALIDACION_USA) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CONVALIDACION_USA) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CONVALIDACION_USA = cx.CONVALIDACION_USA
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CONVALIDACION_USA',
                                                a.OBSERVACIONES_ee = 'Se actualizo CONVALIDACION_USA '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                     ------------------------------------- MASTER_MAESTRIA -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.MASTER_MAESTRIA)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.MASTER_MAESTRIA) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.MASTER_MAESTRIA) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.MASTER_MAESTRIA = cx.MASTER_MAESTRIA
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo MASTER_MAESTRIA',
                                                a.OBSERVACIONES_ee = 'Se actualizo MASTER_MAESTRIA '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- BLOQUE_SEG -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.BLOQUE_SEG)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.BLOQUE_SEG) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.BLOQUE_SEG) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.BLOQUE_SEG = cx.BLOQUE_SEG
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo BLOQUE_SEG',
                                                a.OBSERVACIONES_ee = 'Se actualizo BLOQUE_SEG '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- NIVEL_RIESGO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.NIVEL_RIESGO)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.NIVEL_RIESGO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.NIVEL_RIESGO) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.NIVEL_RIESGO = cx.NIVEL_RIESGO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo NIVEL_RIESGO',
                                                a.OBSERVACIONES_ee = 'Se actualizo NIVEL_RIESGO '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 


                     ------------------------------------- SEMAFORO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.SEMAFORO)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.SEMAFORO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.SEMAFORO) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.SEMAFORO = cx.SEMAFORO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.FLAG_HUBSPOT = '1',
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo SEMAFORO',
                                                a.OBSERVACIONES_ee = 'Se actualizo SEMAFORO '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- TUTOR -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.TUTOR)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.TUTOR) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.TUTOR) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.TUTOR = cx.TUTOR
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo TUTOR',
                                                a.OBSERVACIONES_ee = 'Se actualizo TUTOR '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- SUPERVISOR -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.SUPERVISOR)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.SUPERVISOR) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.SUPERVISOR) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.SUPERVISOR = cx.SUPERVISOR
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo SUPERVISOR',
                                                a.OBSERVACIONES_ee = 'Se actualizo SUPERVISOR '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- LINEA_NEGOCIO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.LINEA_NEGOCIO)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.LINEA_NEGOCIO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.LINEA_NEGOCIO) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.LINEA_NEGOCIO = cx.LINEA_NEGOCIO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo LINEA_NEGOCIO',
                                                a.OBSERVACIONES_ee = 'Se actualizo LINEA_NEGOCIO '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- MODALIDAD_2 -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.MODALIDAD_2)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.MODALIDAD_2) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.MODALIDAD_2) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.MODALIDAD_2 = cx.MODALIDAD_2
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo MODALIDAD_2',
                                                a.OBSERVACIONES_ee = 'Se actualizo MODALIDAD_2 '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- ESTRATEGIA_1 -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.ESTRATEGIA_1)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ESTRATEGIA_1) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ESTRATEGIA_1) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.ESTRATEGIA_1 = cx.ESTRATEGIA_1
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo ESTRATEGIA_1',
                                                a.OBSERVACIONES_ee = 'Se actualizo ESTRATEGIA_1 '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- ESTRATEGIA_2 -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.ESTRATEGIA_2)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ESTRATEGIA_2) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ESTRATEGIA_2) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.ESTRATEGIA_2 = cx.ESTRATEGIA_2
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo ESTRATEGIA_2',
                                                a.OBSERVACIONES_ee = 'Se actualizo ESTRATEGIA_2 '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- ESTRATEGIA_3 -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.ESTRATEGIA_3)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.ESTRATEGIA_3) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.ESTRATEGIA_3) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.ESTRATEGIA_3 = cx.ESTRATEGIA_3
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo ESTRATEGIA_3',
                                                a.OBSERVACIONES_ee = 'Se actualizo ESTRATEGIA_3 '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- RIESGO_PERMANENCIA -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.RIESGO_PERMANENCIA)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.RIESGO_PERMANENCIA) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.RIESGO_PERMANENCIA) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.RIESGO_PERMANENCIA = cx.RIESGO_PERMANENCIA
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo RIESGO_PERMANENCIA',
                                                a.OBSERVACIONES_ee = 'Se actualizo RIESGO_PERMANENCIA '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                     ------------------------------------- FASE_1 -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.FASE_1)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FASE_1) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FASE_1) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.FASE_1 = cx.FASE_1
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo FASE_1',
                                                a.OBSERVACIONES_ee = 'Se actualizo FASE_1 '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                    ------------------------------------- FASE_2 -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.FASE_2)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.FASE_2) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.FASE_2) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.FASE_2 = cx.FASE_2
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo FASE_2',
                                                a.OBSERVACIONES_ee = 'Se actualizo FASE_2 '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                    ------------------------------------- NR_NIVELACION -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.NR_NIVELACION)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.NR_NIVELACION) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.NR_NIVELACION) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.NR_NIVELACION = cx.NR_NIVELACION
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo NR_NIVELACION',
                                                a.OBSERVACIONES_ee = 'Se actualizo NR_NIVELACION '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 

                    ------------------------------------- CLAVE_MATERIA_NIVE -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.CLAVE_MATERIA_NIVE)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.CLAVE_MATERIA_NIVE) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.CLAVE_MATERIA_NIVE) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.CLAVE_MATERIA_NIVE = cx.CLAVE_MATERIA_NIVE
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo CLAVE_MATERIA_NIVE',
                                                a.OBSERVACIONES_ee = 'Se actualizo CLAVE_MATERIA_NIVE '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit; 
                                 
                    ------------------------------------- MODALIDAD_EVA_NIVE -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.MODALIDAD_EVA_NIVE)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.MODALIDAD_EVA_NIVE) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.MODALIDAD_EVA_NIVE) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.MODALIDAD_EVA_NIVE = cx.MODALIDAD_EVA_NIVE
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo MODALIDAD_EVA_NIVE',
                                                a.OBSERVACIONES_ee = 'Se actualizo MODALIDAD_EVA_NIVE '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                  
                                 
                    ------------------------------------- EGEL_PLAN_ESTUDIO -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.EGEL_PLAN_ESTUDIO)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.EGEL_PLAN_ESTUDIO) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.EGEL_PLAN_ESTUDIO) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.EGEL_PLAN_ESTUDIO = cx.EGEL_PLAN_ESTUDIO
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo EGEL_PLAN_ESTUDIO',
                                                a.OBSERVACIONES_ee = 'Se actualizo EGEL_PLAN_ESTUDIO '
                                         where  a.matricula = cx.matricula
                                        And a.programa = cx.programa;
                                   Exception
                                    When Others then
                                        null;
                                   End;

                                End if;
                                 Commit;                                  

                                 
                    ------------------------------------- NO_SEMANA -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select trim (a.NO_SEMANA)
                                            into vl_campo
                                         From sztecrm_uni a
                                         Where 1= 1
                                         And a.matricula = cx.matricula
                                         And a.programa = cx.programa;
                                Exception
                                    When Others then
                                        vl_campo:= null;
                                End;

                                If trim (cx.NO_SEMANA) = trim (vl_campo) then
                                    null;
                                ElsIf trim (cx.NO_SEMANA) is null then
                                    null;
                                Else
                                --dbms_output.put_line('Entra para Study_Path ' || cx.matricula|| '*'||cx.programa ||'*'||vl_campo||'*'||cx.sp );
                                    Begin
                                        Update sztecrm_uni a
                                            set a.NO_SEMANA = cx.NO_SEMANA
                                                 ,a.estatus_envio = 0,
                                                 a.estatus_envio_ee = 0,
                                                 a.FLAG_HUBSPOT ='1',
                                                 a.fecha_actualiza = sysdate,
                                                a.OBSERVACIONES = 'Se actualizo NO_SEMANA',
                                                a.OBSERVACIONES_ee = 'Se actualizo NO_SEMANA '
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
                                join sztecrm_uni x on x.MATRICULA = t.matricula and x.programa = t.programa
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
                                                and t1.campus||t1.nivel not in ( 'UTSID','INIEC')
                                                And t.estatus = t1.estatus
                                                )
                                      
                                  
                     ) Loop
                    
                    
                          -------------------------------------Servicio SSb -------------------------------------------------
                                vl_campo:= null;
                                Begin
                                        Select SERVICIO
                                            into vl_campo
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                                         From sztecrm_uni a
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
                                            Update sztecrm_uni a
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
                            from SZTECRM_uni a
                            where 1= 1 
                           -- And matricula in ('010613079', '010611818') ---> Actualizar Matricula 
                            and a.FECHA_DESICION is null
                            
                    
                   ) loop
                   
                    If cx.Fecha_Desicion is not null then 

                        Begin 
                            Update SZTECRM_uni
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

--                    Else
--                        Begin 
--                            Update SZTECRM_uni
--                            set ESTATUS ='SIN ESTATUS'
--                            Where pidm = cx.pidm
--                            And   FECHA_DESICION is null; 
--                        Exception
--                            When OThers then 
--                                null;
--                        End;            
                    
                    
                    End if;

                 End Loop;     
                 Commit;  
                   
        End;


        PKG_INCONCERT_uni.p_quita_duplicados_uni;
        Commit;
         
end p_integra_inconcert_uni;



Procedure p_quita_duplicados_uni
as
Begin
  
        Begin                                    
            delete SZTECRM_UNI
            where 1=1
            and (matricula, programa ) not in (Select matricula, programa
                                               from TZTPROG_INCR
                                              )
            and estatus is null;
            Commit;
        Exception
                When Others then 
                    null;
        End;    

        Begin                                    
            delete SZTECRM_UNI
            where 1=1
            and (matricula, programa ) not in (Select matricula, programa
                                               from TZTPROG_INCR
                                              );
            Commit;
        Exception
                When Others then 
                    null;
        End; 


 
        For cx in (
        
                    select count(*), matricula
                    from SZTECRM_uni
                    group by  matricula
                    having count(*) > 1        
                            
        
        
        
        ) loop   --------> Grupo de Registros duplicados
        
        
                For cx2 in (
                
                            select *
                            from SZTECRM_uni a
                            where a.matricula = cx.matricula
                            and a.sp = (select max (a1.sp)
                                    from SZTECRM_uni a1
                                    where a1.matricula = a.matricula
                                   )              
                
                ) loop
                
                        Begin ----> Se borra el minimo registro 
                        
                            Delete SZTECRM_uni a
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
                    from SZTECRM_uni
                    group by  matricula
                    having count(*) > 1        
                            
        
        
        
        ) loop   --------> Grupo de Registros duplicados
        
        
                For cx2 in (
                
                            select *
                            from SZTECRM_uni a
                            where a.matricula = cx.matricula
                            and trunc (a.FECHA_INICIO) = (select min (trunc(a1.FECHA_INICIO))
                                                            from SZTECRM_uni a1
                                                            where a1.matricula = a.matricula
                                                           )              
                
                ) loop
                
                        Begin ----> Se borra el minimo registro 
                        
                            Delete SZTECRM_uni a
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
        

End p_quita_duplicados_uni;


Function dias_segundo_pago (p_pidm in number, p_Fecha_ini in date) return number

as

--------------- Funcion para calcular los dias que faltan para la fecha de pago de la segunda colegiatura del bimestre con base a la fecha de inicio

        l_dias number;

Begin
            Begin

                    select  trunc (max (TBRACCD_EFFECTIVE_DATE)) - trunc (sysdate) Dias
                        Into l_dias
                    from tbraccd a
                    where tbraccd_pidm = p_pidm
                    and TBRACCD_FEED_DATE = p_Fecha_ini
                    and tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          );

            EXCEPTION WHEN OTHERS THEN
                  l_dias:=0;
            END;

        If l_dias < 0 then 
          l_dias:=0;
        End if;

        return(l_dias);

End dias_segundo_pago;


Function fecha_segundo_pago (p_pidm in number, p_Fecha_ini in date) return date

as

--------------- Funcion para calcular los dias que faltan para la fecha de pago de la segunda colegiatura del bimestre con base a la fecha de inicio

        l_dias date;

Begin
            Begin

                    select  trunc (max (TBRACCD_EFFECTIVE_DATE))   Dias
                        Into l_dias
                    from tbraccd a
                    where tbraccd_pidm = p_pidm
                    and TBRACCD_FEED_DATE = p_Fecha_ini
                    and tbraccd_detail_code in (select TZTNCD_CODE
                                                            from TZTNCD, tbbdetc
                                                            Where TZTNCD_CONCEPTO ='Venta'
                                                            And TZTNCD_CODE = TBBDETC_DETAIL_CODE
                                                            And TBBDETC_DCAT_CODE ='COL'
                                                          );

            EXCEPTION WHEN OTHERS THEN
                  l_dias:=null;
            END;

        return(l_dias);

End fecha_segundo_pago;



Function fecha_inicio_nive (p_pidm in number) return date

as

--------------- Funcion para calcular los dias que faltan para la fecha de pago de la segunda colegiatura del bimestre con base a la fecha de inicio

        l_fecha date;

Begin
            Begin

                select distinct max (SSBSECT_PTRM_START_DATE)
                    Into l_fecha
                from sfrstcr
                join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                join SVRSVPR on SVRSVPR_pidm = sfrstcr_pidm and SFRSTCR_STRD_SEQNO = SVRSVPR_PROTOCOL_SEQ_NO
                where 1=1
                and sfrstcr_pidm = p_pidm 
                and substr (SFRSTCR_TERM_CODE, 5,1) = 8
                and SFRSTCR_RSTS_CODE ='RE'
                and SFRSTCR_GRDE_CODE is null
                order by 1;

            EXCEPTION WHEN OTHERS THEN
                  l_fecha:=null;
            END;

        return(l_fecha);

End fecha_inicio_nive;

Function fecha_fin_nive (p_pidm in number) return date

as

--------------- Funcion para calcular los dias que faltan para la fecha de pago de la segunda colegiatura del bimestre con base a la fecha de inicio

        l_fecha date;

Begin
            Begin

                select max (x.SSBSECT_PTRM_END_DATE)
                    Into l_fecha
                from (
                select distinct max (SSBSECT_PTRM_START_DATE), SSBSECT_PTRM_END_DATE
                from sfrstcr
                join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                join SVRSVPR on SVRSVPR_pidm = sfrstcr_pidm and SFRSTCR_STRD_SEQNO = SVRSVPR_PROTOCOL_SEQ_NO
                join SVVSRVS on SVVSRVS_CODE = SVRSVPR_SRVS_CODE
                where 1=1
                and sfrstcr_pidm = p_pidm 
                and substr (SFRSTCR_TERM_CODE, 5,1) = 8
                and SFRSTCR_RSTS_CODE ='RE'
                and SFRSTCR_GRDE_CODE is null
                group by SSBSECT_PTRM_END_DATE
                ) x
                order by 1;

            EXCEPTION WHEN OTHERS THEN
                  l_fecha:=null;
            END;

        return(l_fecha);

End fecha_fin_nive;

Function Estatus_nive (p_pidm in number) return varchar2

as

--------------- Funcion para calcular los dias que faltan para la fecha de pago de la segunda colegiatura del bimestre con base a la fecha de inicio

        l_estatus varchar2(50);

Begin
            Begin

                    select x.SVVSRVS_desc
                        Into l_estatus
                    from (
                    select distinct max (SSBSECT_PTRM_START_DATE), SVVSRVS_desc
                    from sfrstcr
                    join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                    join SVRSVPR on SVRSVPR_pidm = sfrstcr_pidm and SFRSTCR_STRD_SEQNO = SVRSVPR_PROTOCOL_SEQ_NO
                    join SVVSRVS on SVVSRVS_CODE = SVRSVPR_SRVS_CODE
                    where 1=1
                    and sfrstcr_pidm = p_pidm 
                    and substr (SFRSTCR_TERM_CODE, 5,1) = 8
                    and SFRSTCR_RSTS_CODE ='RE'
                    and SFRSTCR_GRDE_CODE is null
                    group by SVVSRVS_desc
                    ) x
                    order by 1;

            EXCEPTION WHEN OTHERS THEN
                  l_estatus:=null;
            END;

        return(l_estatus);

End Estatus_nive;

Function Materias_NP (p_pidm in number, p_sp in number) return number
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_materias number:=0;

Begin
            Begin

                    select count(x.materia)
                        Into l_materias
                    from (
                    select distinct SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB materia
                    from sfrstcr
                    join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                    where 1=1
                    --and sfrstcr_pidm = 1362 
                    and SFRSTCR_RSTS_CODE ='RE'
                    and SFRSTCR_GRDE_CODE ='NP'
                    and sfrstcr_pidm = p_pidm 
                    and SFRSTCR_STSP_KEY_SEQUENCE = p_sp
                    minus
                    select distinct SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB materia
                    from sfrstcr
                    join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                    where 1=1
                    --and sfrstcr_pidm = 1362 
                    and SFRSTCR_RSTS_CODE ='RE'
                    and SFRSTCR_GRDE_CODE !='NP'
                    and sfrstcr_pidm = p_pidm 
                    and SFRSTCR_STSP_KEY_SEQUENCE = p_sp
                    order by 1 desc
                    ) x;

            EXCEPTION WHEN OTHERS THEN
                  l_materias:=0;
            END;

        return(l_materias);

End Materias_NP;

Function Materias_rep (p_pidm in number, p_sp in number) return number
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_materias number:=0;

Begin
            Begin

                    select x.materia
                        Into l_materias
                    from (
                    select distinct  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB materia
                    from sfrstcr
                    join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                    join shrgrde on  shrgrde_code = SFRSTCR_GRDE_CODE and SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE and SHRGRDE_PASSED_IND ='N'
                    where 1=1
                    and sfrstcr_pidm = p_pidm 
                    and SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                    and SFRSTCR_RSTS_CODE ='RE'
                    and SFRSTCR_GRDE_CODE is not null
                    and SFRSTCR_GRDE_CODE not in ('NP')
                    and substr (SFRSTCR_TERM_CODE, 5, 1) not in ('9')
                    minus
                    select distinct  SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB materia
                    from sfrstcr
                    join ssbsect on SSBSECT_TERM_CODE = SFRSTCR_TERM_CODE and SSBSECT_CRN = SFRSTCR_CRN
                    join shrgrde on  shrgrde_code = SFRSTCR_GRDE_CODE and SHRGRDE_LEVL_CODE = SFRSTCR_LEVL_CODE and SHRGRDE_PASSED_IND ='Y'
                    where 1=1
                    and sfrstcr_pidm = p_pidm 
                    and SFRSTCR_STSP_KEY_SEQUENCE= p_sp
                    and SFRSTCR_RSTS_CODE ='RE'
                    and SFRSTCR_GRDE_CODE is not null
                    and SFRSTCR_GRDE_CODE not in ('NP')
                    and substr (SFRSTCR_TERM_CODE, 5, 1) not in ('9')
                    ) x;


            EXCEPTION WHEN OTHERS THEN
                  l_materias:=0;
            END;

        return(l_materias);

End Materias_rep;


Function año_egreso (p_pidm in number, p_sp in number) return date

as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_año date:=null;

Begin
            Begin

                    select distinct FECHA_MOV
                        Into l_año
                    from tztprog a
                    where 1=1
                    and a.pidm = p_pidm
                    and a.sp = p_sp
                    and a.estatus ='EG';


            EXCEPTION WHEN OTHERS THEN
                  l_año:=null;
            END;

        return(l_año);

End año_egreso;


Function aprocrifos (p_pidm in number, p_sp in number) return varchar2

as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(5):=null;

Begin
            Begin
                select distinct GORADID_ADID_CODE
                    Into l_etiqueta
                from goradid
                where 1=1
                and GORADID_PIDM = p_pidm 
                And GORADID_ADID_CODE in ( 'DAPO', 'SOSD');
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End aprocrifos;

Function egel (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio ='EGEL';
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End egel;


Function Certif_dig (p_pidm in number, p_nivel in varchar2) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                        select SARCHKL_CKST_CODE Documento
                            into l_etiqueta
                        from SARCHKL
                        join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_levl_code = p_nivel
                                                                                               and SARADAP_APPL_NO = SARCHKL_APPL_NO
                        join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
                        where 1=1
                        And SARCHKL_PIDM = p_pidm
                        And SARCHKL_ADMR_CODE in ('CBLD', 'CTLD', 'CTMD');
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Certif_dig;

Function Acta_nac_or (p_pidm in number, p_nivel in varchar2) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                        select SARCHKL_CKST_CODE Documento
                            into l_etiqueta
                        from SARCHKL
                        join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_levl_code = p_nivel
                                                                                               and SARADAP_APPL_NO = SARCHKL_APPL_NO
                        join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
                        where 1=1
                        And SARCHKL_PIDM = p_pidm
                        And SARCHKL_ADMR_CODE in ('ACNO');
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Acta_nac_or;

Function Certif_dig_LIC (p_pidm in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                        select SARCHKL_CKST_CODE Documento
                            into l_etiqueta
                        from SARCHKL
                        join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_levl_code = 'LI'
                                                                                               and SARADAP_APPL_NO = SARCHKL_APPL_NO
                        join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
                        where 1=1
                        And SARCHKL_PIDM = p_pidm
                        And SARCHKL_ADMR_CODE in ('CTLD');
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Certif_dig_LIC;


Function equivalencia (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio ='EQUI';
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End equivalencia;


Function convalidacion (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio ='REVA';
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End convalidacion;

Function Certi_parcial_dig (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio in ('CEPL', 'CEPM', 'CEPD');
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Certi_parcial_dig;

Function Diplo_Interm_dig (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio in ('TIPR','DPIN');   
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Diplo_Interm_dig;

Function Diplo_Int_dig_pago (p_pidm in number, p_sp in number) return date 
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta date:=null;

Begin


       Begin 
                
            For cx in (
            
                        select distinct *
                        from SZRVSSB a
                        join TZTPROG_INCR b on b.matricula = a.matricula 
                        where 1=1
                        And b.pidm = p_pidm 
                        And b.SP = p_sp
                        and cod_servicio in ('TIPR','DPIN')
                    
            ) loop

                Begin 
                
                    Select distinct max (b.TBRACCD_EFFECTIVE_DATE)
                        Into l_etiqueta
                    from tbrappl
                    join tbraccd b on b.tbraccd_pidm = tbrappl_pidm and b.TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER And b.tbraccd_detail_code in (select TZTNCD_CODE
                                                                                                                                                        from TZTNCD    
                                                                                                                                                        Where TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion'))
                    where 1=1
                    and tbrappl_pidm = cx.pidm 
                    And TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    And TBRAPPL_CHG_TRAN_NUMBER = cx.TRANSACCION
                    and TBRAPPL_REAPPL_IND is null;
                Exception   
                    When Others then 
                       l_etiqueta:= null;
                End;


            end loop;

        End;

        return(l_etiqueta);

End Diplo_Int_dig_pago;

Function Diplo_master_dig (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio in ('DIMA');   
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Diplo_master_dig;

Function Constancia_dig_pago (p_pidm in number, p_sp in number) return date 
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta date:=null;

Begin


       Begin 
                
            For cx in (
            
                        select distinct *
                        from SZRVSSB a
                        join TZTPROG_INCR b on b.matricula = a.matricula 
                        where 1=1
                        And b.pidm = p_pidm 
                        And b.SP = p_sp
                        and cod_servicio in ('AVCU','COES','CNPA','HIAC')
                    
            ) loop

                Begin 
                
                    Select distinct max (b.TBRACCD_EFFECTIVE_DATE)
                        Into l_etiqueta
                    from tbrappl
                    join tbraccd b on b.tbraccd_pidm = tbrappl_pidm and b.TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER And b.tbraccd_detail_code in (select TZTNCD_CODE
                                                                                                                                                        from TZTNCD    
                                                                                                                                                        Where TZTNCD_CONCEPTO IN ('Poliza', 'Deposito', 'Nota Distribucion'))
                    where 1=1
                    and tbrappl_pidm = cx.pidm 
                    And TBRACCD_STSP_KEY_SEQUENCE = p_sp
                    And TBRAPPL_CHG_TRAN_NUMBER = cx.TRANSACCION
                    and TBRAPPL_REAPPL_IND is null;
                Exception   
                    When Others then 
                       l_etiqueta:= null;
                End;


            end loop;

        End;

        return(l_etiqueta);

End Constancia_dig_pago;

Function Apostillado_dig (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio in ('APOS');   
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Apostillado_dig;


Function Constancia_progra_dig (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio in ('CEAP');   
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Constancia_progra_dig;

Function Envio_paqueteria (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio in ('ENIN');   
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End Envio_paqueteria;

Function tipo_nivelacion (p_pidm in number, p_sp in number) return varchar2

as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(100):=null;

Begin
            Begin
                select distinct  decode (substr (a.tbraccd_detail_code,3,2),'56', 'NIVELACION ACADEMICA MAE B', 'BK', 'NIVELACION ACADEMICA MAE A ' , '59', 'NIVELACION ACADEMICA LIC C', 'QD', 'NIVELACION ACADEMICA LIC B', 'NW', 'NIVELACION ACADEMICA LIC A') Nivelacion
                Into l_etiqueta
                from tbraccd a
                where 1=1
                and a.tbraccd_pidm = p_pidm
                and a.TBRACCD_STSP_KEY_SEQUENCE = p_sp
                And a.TBRACCD_TRAN_NUMBER = (select max (a1.TBRACCD_TRAN_NUMBER)
                                            from tbraccd a1
                                            Where a.tbraccd_pidm = a1.tbraccd_pidm
                                            And a.TBRACCD_STSP_KEY_SEQUENCE = a1.TBRACCD_STSP_KEY_SEQUENCE
                                            And a.tbraccd_detail_code = a1.tbraccd_detail_code
                                            )
                And substr (a.tbraccd_detail_code,3,2) in ('56','BK','56','BK','59','QD','NW');

            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End tipo_nivelacion;

Function colegiatura_final (p_pidm in number, p_sp in number) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(100):=null;

Begin
            Begin
                select  decode (GORADID_ADID_CODE, 'TIIN', 'PAGADO', 'TIIM', 'PAGADO', 'TIID', 'PAGADO', 'TDEL', 'ACTIVO', 'TDEM', 'ACTIVO', 'TDED', 'ACTIVO','TPAL', 'CONCLUIDO', 'TPAM', 'CONCLUIDO', 'TPAD', 'CONCLUIDO', 'TPPL', 'ACTIVO', 'TPPM', 'ACTIVO', 'TPPD', 'ACTIVO') ETIQUETA
                Into l_etiqueta
                from goradid
                where 1=1
                And goradid_pidm = p_pidm
                and substr (GORADID_ADDITIONAL_ID, length (GORADID_ADDITIONAL_ID) , 1) = p_sp 
                and GORADID_ADID_CODE in (
                'TIIN','TIIM','TIID','TDEL','TDEM','TDED','TPAL','TPAM','TPAD','TPPL','TPPM','TPPD');

            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);

End colegiatura_final;


Function Convalidacion_USA (p_pidm in number, p_sp in number) return varchar2

as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;

Begin
            Begin
                select distinct a.ESTATUS_SOLC
                    Into l_etiqueta
                from SZRVSSB a
                join TZTPROG_INCR b on b.matricula = a.matricula 
                where 1=1
                And b.pidm = p_pidm 
                And b.SP = p_sp
                and cod_servicio in ('CONV');   
            EXCEPTION WHEN OTHERS THEN
                  l_etiqueta:=null;
            END;

        return(l_etiqueta);



End Convalidacion_USA;


Function master_maestria (p_pidm in number, p_sp in number, p_campus in varchar2, p_nivel in varchar2) return varchar2
as

--------------- Funcion que regresa el numero de materias con estatus de NP

        l_etiqueta varchar2(50):=null;
        l_existe number:=0;

Begin
        l_etiqueta:= null;
        l_existe:=0;
        If p_campus ='UTL' and  p_nivel ='MA' then   
            
            Begin
                    with maestria as (
                                        select pidm, SPRIDEN_FIRST_NAME||SPRIDEN_LAST_NAME nombre, matricula, campus, nivel, programa, sp, estatus
                                        from tztprog
                                        join spriden on spriden_PIDM = pidm and spriden_change_ind is null
                                        where 1=1
                                        and campus ='UTL'
                                        and nivel ='MA')
                    select distinct count(*)--distinct c.pidm, b.SPRIDEN_FIRST_NAME||b.SPRIDEN_LAST_NAME nombre, a.matricula, c.matricula, a.campus, a.nivel, a.programa, c.campus, c.nivel, c.programa, c.sp, c.estatus
                        Into l_existe
                    from tztprog a
                    join spriden b on spriden_PIDM = pidm and spriden_change_ind is null
                    join maestria c on c.nombre = b.SPRIDEN_FIRST_NAME||b.SPRIDEN_LAST_NAME
                    where 1=1
                    and a.campus ='UTS'
                    and a.nivel ='MS'
                    and a.estatus ='BD'
                    And c.pidm = p_pidm
                    and c.sp = p_sp;  
            EXCEPTION WHEN OTHERS THEN
                  l_existe:=0;
            END;
            
        End if;

        If l_existe >= 1 then 
           l_etiqueta:='MA';
        Else
            l_etiqueta:=null;
        End if;
        return(l_etiqueta);



End master_maestria;

Procedure limpia_tabla as

Begin 

    Begin 
        EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.NIVEL_RIESGO';
        Commit;
    
    Exception
            When Others then
                null;
    End;


End limpia_tabla;

Procedure Inserta_nivel_Riesgo (P_MATRICULA in varchar2,          
  P_BLOQUE_SEG  in varchar2,
  P_NIVEL_RIESGO  in varchar2,
  P_SEMAFORO in varchar2,
  P_TUTOR in varchar2,
  P_SUPERVISOR in varchar2,
  P_LINEA_NEGOCIO in varchar2,
  P_MODALIDAD in varchar2,
  P_ESTRATEGIA_1 in varchar2,
  P_ESTRATEGIA_2 in varchar2,
  P_ESTRATEGIA_3 in varchar2,
  P_RIESGO_PERMANENCIA in varchar2,
  P_FASE_1 in varchar2,
  P_FASE_2 in varchar2,
  P_NR_NIVELACION in varchar2,
  P_CLAVE_MATERIA_NIVE in varchar2,
  P_MODALIDAD_EVA_NIVE in varchar2,
  P_EGEL_PLAN_ESTUDIO in varchar2) 
as

l_existe number:=0;

Begin

    l_existe :=0;
    
    Begin
    
        Select count(1)
            Into l_existe
        from migra.nivel_riesgo
        where matricula = P_MATRICULA;
    Exception
        When Others then 
            l_existe:=0;
    End;

    If l_existe =0 then 

        Begin
            Insert into migra.nivel_riesgo values (P_MATRICULA,          
                                              P_BLOQUE_SEG ,
                                              P_NIVEL_RIESGO,
                                              P_SEMAFORO,
                                              P_TUTOR,
                                              P_SUPERVISOR,
                                              P_LINEA_NEGOCIO,
                                              P_MODALIDAD,
                                              P_ESTRATEGIA_1,
                                              P_ESTRATEGIA_2,
                                              P_ESTRATEGIA_3,
                                              P_RIESGO_PERMANENCIA,
                                              P_FASE_1,
                                              P_FASE_2,
                                              P_NR_NIVELACION,
                                              P_CLAVE_MATERIA_NIVE,
                                              P_MODALIDAD_EVA_NIVE,
                                              P_EGEL_PLAN_ESTUDIO);
            Commit;                                  
        Exception
            When Others then 
            null;
        End;
    
    End if;

End Inserta_nivel_Riesgo;


END PKG_INCONCERT_uni;
/

DROP PUBLIC SYNONYM PKG_INCONCERT_UNI;

CREATE OR REPLACE PUBLIC SYNONYM PKG_INCONCERT_UNI FOR BANINST1.PKG_INCONCERT_UNI;
