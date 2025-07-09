DROP PACKAGE BODY BANINST1.PKG_FACTURACION;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FACTURACION IS

PROCEDURE sp_Datos_Facturacion
IS

----Se Arma el encazado de la factura DOC(+)-------------
vl_encabezado varchar2(4000):='DOC(+)';
vl_consecutivo number :=0;

-------------- LLenamos Folio y SErie ENC(+)
vl_serie_folio varchar2(2500):='ENC(+)';
vl_forma_pago varchar2(100):='99';
vl_condicion_pago varchar2(250):= 'Pago en una sola exhibición';
vl_tipo_cambio number:=1;
vl_tipo_moneda varchar2(10):= 'MXN';
vl_metodo_pago varchar2(10):= 'PUE';
vl_lugar_expedicion varchar2(10):= '53370';
vl_tipo_comprobante varchar2(5):= 'I';
vl_descuento varchar2(15):='0.00';
vl_total number(16,2);
vl_confirmacion varchar2(2);
vl_tipo_documento number:=1;
vl_subtotal number(16,2);


-------------------Entidad_receptor ENC_ERP(+)
vl_entidad_receptor varchar2(4000):='ENC_ERP(+)';

 
---------Envio por correo ENVIO_CFDI(+)
vl_envio_correo varchar2(4000):='ENVIO_CFDI(+)';
vl_enviar_xml varchar2(15):='TRUE';
vl_enviar_pdf varchar2(15):='TRUE';
vl_enviar_zip varchar2(15):='TRUE';


------Datos fiscales utel EMISOR(+)
vl_dfiscales_utel varchar2(4000):='EMISOR(+)';
vl_rfc_utel varchar2(15);
vl_razon_social_utel varchar2(250);
vl_regimen_fiscal varchar2(5):='601';
vl_id_emisor_sto number:=1;
vl_id_emisor_erp number:=1;


------Datos fiscales Alumno RECEPTOR(+)
vl_dfiscales_receptor varchar2(4000):='RECEPTOR(+)';
vl_referencia_dom_receptor varchar2(255):=' ';
--vl_id_tipo_receptor varchar2(25):='0';
--vl_id_receptor_sto varchar2(25):='0';
vl_estatus_registro varchar2(25):='1';
vl_uso_cfdi varchar2(25):='D10';
vl_residencia_fiscal varchar2(25);
vl_num_reg_id_trib varchar2(25);
--vl_id_receptor_erp varchar2(25);
--vl_id_receptor_padre varchar2(25);


------Datos fiscales Alumno DESTINATARIO(+)
vl_dfiscales_destinatario varchar2(4000):='RECEPTOR(+)';
vl_referencia_dom_destinatario varchar2(255):=' ';
vl_id_tipo_destinatario varchar2(25):='0';
vl_id_destinarario_sto varchar2(25):='0';


------Concepto L(+)
vl_info_concepto CLOB :='L(+)';
vl_num_linea number:=0;
vl_prod_serv varchar2(50);
vl_cantidad_concepto varchar2(10):='1';
vl_clave_unidad_concepto varchar2(10):='E48';
vl_unidad_concepto varchar2(50):='Unidad de servicio';
vl_importe_concepto number:=1;
vl_fecha_pago date;
vl_transaccion number :=0;


--Impuesto trasladado LIMPTRAS(+)
vl_impuesto varchar2(32000):='LIMPTRAS(+)';
vl_impuesto_cod varchar2(10):='002';
vl_tipo_factor_impuesto varchar2(15):='Tasa';
vl_tasa_cuota_impuesto varchar2(15);


--Impuesto retenido LIMPRET(+)
vl_impuesto_ret varchar2(4000):='LIMPRET(+)';
vl_base_impuesto_ret varchar2(25);
vl_impuesto_ret_cod varchar2(10):='002';
vl_tipo_factor_impuesto_ret varchar2(15):='Tasa';
vl_tasa_cuota_impuesto_ret varchar2(15);
vl_importe_impuesto_ret number(24,2);


--Info_impuestos_comprobante TOTIMP(+)
vl_info_impuestos varchar2(4000):='TOTIMP(+)';
vl_total_impret number(24,2);
vl_total_imptras number(24,2);


--Info_subtotal_imptras IMPTRAS(+)
vl_info_subtotal_imptras varchar2(4000):='IMPTRAS(+)';


--Info_subtotal_impret IMPRET(+)
vl_info_subtotal_impret varchar2(4000):='IMPRET(+)';

vl_error varchar2(2500):='EXITO';
vl_contador number:=0;
vl_existe number:=0;


--excedente
vl_pago_total number :=0;
vl_pago_total_faltante number :=0;
vl_pago_diferencia number :=0;
vl_clave_cargo varchar2(5):= null;
vl_descrip_cargo varchar2(90):= null;
vl_secuencia number:=0;


--Flex_Header FH(+)
vl_flex_header varchar2(4000):='FH(+)';
vl_folio_interno_cl_fh varchar2(50):='1';
vl_folio_interno_fh varchar2(255):='Folio_interno';
vl_razon_social_cl_fh varchar2(50):='2';
vl_razon_social_fh varchar2(255):='Razon_Social';
vl_metodo_pago_cl_fh varchar2(50):='3';
vl_metodo_pago_fh varchar2(255):='Metodo_de_pago';
vl_desc_metodo_pago_cl_fh varchar2(50):='4';
vl_desc_metodo_pago_fh varchar2(255):='Descripcion_de_metodo_de_pago';
vl_id_pago_cl_fh varchar2(50):='5';
vl_id_pago_pago_fh varchar2(255):='Id_pago';
vl_monto_cl_fh varchar2(50):='6';
vl_monto_fh varchar2(255):='Monto';
vl_nivel_cl_fh varchar2(50):='7';
vl_nivel_fh varchar2(255):='Nivel';
vl_campus_cl_fh varchar2(50):='8';
vl_campus_fh varchar2(255):='Campus';
vl_matricula_alumno_cl_fh varchar2(50):='9';
vl_matricula_alumno_fh varchar2(255):='Matricula_alumno';
vl_fecha_pago_cl_fh varchar2(50):='10';
vl_fecha_pago_fh varchar2(255):='Fecha_pago';
vl_referencia_cl_fh varchar2(50):='11';
vl_referencia_fh varchar2(255):='Referencia';
vl_referencia_tipo_cl_fh varchar2(50):='12';
vl_referencia_tipo_fh varchar2(255):='Referencia_tipo';
vl_int_pago_tardio_cl_fh varchar2(50):='13';
vl_int_pago_tardio_fh varchar2(255):='Interes_pago_tardio';
vl_valor_int_pag_tard_fh varchar2(255):= null;
vl_tipo_accesorio_cl_fh varchar2(50):='14';
vl_tipo_accesorio_fh varchar2(255):='Tipo_accesorio';
vl_monto_accesorio_cl_fh varchar2(50):='15';
vl_monto_accesorio_fh varchar2(255):='Monto_accesorio';
vl_otros_cl_fh varchar2(50):='16';
vl_otros_fh varchar2(255):='Colegiatura';
vl_valor_otros_fh varchar2(255):= null;
vl_monto_otros_cl_fh varchar2(50):='17';
vl_monto_otros_fh varchar2(255):='Monto_colegiatura';
vl_valor_monto_otros_fh varchar2(255):= null;
vl_nom_alumnos_cl_fh varchar2(50):='18';
vl_nom_alumnos_fh varchar2(255):='Nombre_alumno';
vl_curp_cl_fh varchar2(50):='19';
vl_curp_fh varchar2(255):='CURP';
vl_rfc_cl_fh varchar2(50):='20';
vl_rfc_fh varchar2(255):='RFC';
vl_grado_cl_fh varchar2(50):='21';
vl_grado_fh varchar2(255):='Grado';


------ Contadoor de registros
vn_commit  number :=0;

---- Manejo del IVA
vn_iva number:=0;


---- Tipo_Archivo
vl_tipo_archivo varchar2(50):='TXT';
vl_tipo_fact varchar2(50):='Con_D_facturacion';

--   
BEGIN
   FOR D_Fiscales
              IN (  WITH CURP AS (
                                            select 
                                                SPRIDEN_PIDM PIDM,
                                                GORADID_ADDITIONAL_ID CURP
                                              from SPRIDEN
                                              left join GORADID on SPRIDEN_PIDM = GORADID_PIDM
                                              where GORADID_ADID_CODE = 'CURP'
                                              )
                        SELECT DISTINCT SPREMRG_PIDM PIDM,
                                           SPRIDEN_ID MATRICULA,
                                           replace(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME Nombre_Alumno,
                                           SUBSTR(spriden_id,5) ID,
                                           SPREMRG_LAST_NAME Nombre,
                                           upper(SPREMRG_MI) RFC,
                                           REGEXP_SUBSTR(SPREMRG_STREET_LINE1, '[^#"]+', 1, 1) Calle,
                                           NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#[^#]*'),2), 0) Num_Ext,
                                           NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#Int[^*]*'),2), 0) Num_Int,
                                           SPREMRG_STREET_LINE3 Colonia,
                                           SPREMRG_CITY AS Municipio,
                                           SPREMRG_ZIP AS CP,                                               
                                           SPREMRG_STAT_CODE Estado,
                                           SPREMRG_NATN_CODE AS Pais,
                                           'acruzsol@utel.edu.mx' Email,
                                           --GOREMAL_EMAIL_ADDRESS Email,
                                            CASE
                                                 when GORADID_ADID_CODE = 'REFH' then
                                                 'BH'
                                                 when GORADID_ADID_CODE = 'REFS' then
                                                 'BS'
                                                 when GORADID_ADID_CODE = 'REFU' then
                                                 'UI'
                                            end Serie,
                                            SZVCAMP_CAMP_CODE Campus,
                                            GORADID_ADDITIONAL_ID Referencia,
                                            GORADID_ADID_CODE Ref_tipo,
                                            STVLEVL_DESC Nivel,
                                            CURP.CURP Curp,
                                            SARADAP_DEGC_CODE_1 Grado
                                      FROM SPREMRG
                                      left join SPRIDEN on SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                      left outer join SARADAP on SPREMRG_PIDM = SARADAP_PIDM
                                      left join STVLEVL on SARADAP_LEVL_CODE = STVLEVL_CODE
                                      left join GOREMAL on SPREMRG_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                                      left join GORADID on GORADID_PIDM = SPREMRG_PIDM 
                                                  and GORADID_ADID_CODE LIKE 'REF%'
                                      join SZVCAMP on szvcamp_camp_alt_code=substr(SPRIDEN_ID,1,2)
                                      left join CURP on SPREMRG_PIDM = CURP.PIDM
                                     WHERE SPREMRG_MI IS NOT NULL
                                           AND SPREMRG_PRIORITY IN
                                                  (SELECT MIN (s1.SPREMRG_PRIORITY)
                                                     FROM SPREMRG s1
                                                    WHERE SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                          AND SPREMRG_PRIORITY = s1.SPREMRG_PRIORITY)
                                       --and spriden_pidm = 1499
                                       and length(SPREMRG_MI) <=13
                                        and length(SPREMRG_MI) >=10
                                  ORDER BY SPREMRG_PIDM)
   LOOP
          
            vl_pago_total:=0;
            vn_commit :=0;
           For pago in (
                               with accesorios as(
                                                        select distinct
                                                          TZTCRTE_PIDM Pidm,
                                                          TZTCRTE_LEVL as Nivel,
                                                          TZTCRTE_CAMP as Campus,
                                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                                          TZTCRTE_CAMPO17 as accesorios,
                                                          to_char(sum (TZTCRTE_CAMPO15),'fm9999999990.00') as Monto_accesorios,
                                                          TZTCRTE_CAMPO18 as Categoria,
                                                          TZTCRTE_CAMPO10 as Secuencia
                                                        from TZTCRTE
                                                        where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
                                                               and TZTCRTE_CAMPO18 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                                                group by TZTCRTE_PIDM, TZTCRTE_LEVL, TZTCRTE_CAMP, TZTCRTE_CAMPO11, TZTCRTE_CAMPO17, TZTCRTE_CAMPO18, TZTCRTE_CAMPO10
                                                            )
                                    SELECT DISTINCT 
                                            TBRACCD_PIDM PIDM,
                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                            TBRACCD_DETAIL_CODE METODO_PAGO_CODE,
                                            TBRACCD_DESC METODO_PAGO,
                                            to_char (TBRACCD_EFFECTIVE_DATE,'RRRR-MM-DD"T"HH24:MI:SS') Fecha_pago,
                                            TBRACCD_PAYMENT_ID Id_pago,
                                            accesorios.accesorios tipo_accesorio,
                                            accesorios.Monto_accesorios monto_accesorio
                                            FROM TBRACCD
                                            LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                            LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                            left join accesorios on tbraccd_pidm = accesorios.Pidm
                                            and TBRACCD_TRAN_NUMBER = accesorios.secuencia
                                            WHERE TBBDETC_TYPE_IND = 'P'
                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                            AND TBRACCD_PIDM= D_Fiscales.pidm
                                             AND TRUNC (TBRACCD_EFFECTIVE_DATE) >= trunc(sysdate)
                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                            FROM TZTFACT
                                            WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                            ORDER BY TBRACCD_PIDM, 2 asc
                            ) 
            loop
                
                 If pago.MONTO_PAGADO like '-%' then
                    pago.MONTO_PAGADO := pago.MONTO_PAGADO * (-1);
                 End if;                                    
                 
                             vn_commit := vn_commit +1;
                                     
              vl_pago_total := pago.MONTO_PAGADO;
              vl_subtotal := pago.MONTO_PAGADO;

                                            
              vl_num_linea:=0;
                vl_rfc_utel:= null; 
                vl_razon_social_utel:= null; 
                vl_prod_serv := null;      
                 vl_consecutivo :=0;
              
                vl_encabezado :='DOC(+)';
                vl_entidad_receptor :='ENC_ERP(+)';
                vl_envio_correo :='ENVIO_CFDI(+)';
                vl_dfiscales_utel :='EMISOR(+)';
                vl_dfiscales_receptor :='RECEPTOR(+)';
                vl_dfiscales_destinatario := 'DESTINATARIO(+)';      
                
                    --Emisor_STO
                        If d_fiscales.serie = 'BH' then
                            vl_id_emisor_sto := 1;
                        Elsif d_fiscales.serie = 'BS' then
                            vl_id_emisor_sto := 2;
                        End if;
                        
                      --Emisor_ERP
                         If d_fiscales.serie = 'BH' then
                            vl_id_emisor_erp := 1;
                        Elsif d_fiscales.serie = 'BS' then
                            vl_id_emisor_erp := 2;
                        End if;

            --- Se obtiene el numero de consecutivo por empresa 
                    Begin

                    select nvl (max (TZTDFUT_FOLIO), 0)+1
                        Into  vl_consecutivo
                    from tztdfut
                    where TZTDFUT_SERIE = D_Fiscales.serie;
                    Exception
                    When Others then 
                        vl_consecutivo :=1;
                    End;

                   Begin
                        select 
                            TZTDFUT_RFC RFC,
                            TZTDFUT_RAZON_SOC RAZON_SOCIAL,
                            TZTDFUT_PROD_SERV_CODE
                        Into vl_rfc_utel, vl_razon_social_utel, vl_prod_serv
                        from TZTDFUT
                        where TZTDFUT_SERIE = D_Fiscales.serie;
                   exception
                   when others then
                        vl_error:= 'Error al Recuperer los datos Fiscales de la empresa ' ||sqlerrm;
                   End;




                ---- Se Arma el encazado de la factura DOC(+)-------------
                vl_encabezado := vl_encabezado ||vl_consecutivo||'|';
                
                --------Datos fiscales utel EMISOR(+)
                vl_dfiscales_utel := vl_dfiscales_utel||vl_rfc_utel||'|'||vl_razon_social_utel||'|'||vl_regimen_fiscal||'|'||vl_id_emisor_sto||'|'||vl_id_emisor_erp||'|';
                
                -----Se envia por correo ENVIO_CFDI(+)
                vl_envio_correo := vl_envio_correo||vl_enviar_xml||'|'||vl_enviar_pdf||'|'||vl_enviar_zip||'|'||D_Fiscales.Email||'|';
                
                ----------Datos de entidad del receptor ENC_ERP(+)
                vl_entidad_receptor := vl_entidad_receptor ||vl_consecutivo||'|';
                
                --------Datos fiscales alumno RECEPTOR(+)
                vl_dfiscales_receptor := vl_dfiscales_receptor||D_Fiscales.RFC||'|'||D_Fiscales.Nombre||'|'||vl_residencia_fiscal||'|'||vl_num_reg_id_trib||'|'||vl_uso_cfdi||'|'||D_Fiscales.ID||'|'||D_Fiscales.ID||'|'||D_Fiscales.Num_Ext||'|'||D_Fiscales.Calle||'|'||D_Fiscales.Num_Int||'|'||D_Fiscales.Colonia||'|'||D_Fiscales.Municipio||'|'||vl_referencia_dom_receptor||'|'||D_Fiscales.Municipio||'|'||D_Fiscales.Estado||'|'||D_Fiscales.Pais||'|'||D_Fiscales.CP||'|'||D_Fiscales.Email||'|'||D_Fiscales.ID||'|'||vl_estatus_registro||'|';

                --------Datos fiscales alumno DESTINATARIO(+)
                vl_dfiscales_destinatario := vl_dfiscales_destinatario||D_Fiscales.RFC||'|'||D_Fiscales.Nombre||'|'||vl_uso_cfdi||'|'||vl_id_destinarario_sto||'|'||D_Fiscales.Num_Ext||'|'||D_Fiscales.Calle||'|'||D_Fiscales.Num_Int||'|'||D_Fiscales.Colonia||'|'||D_Fiscales.Municipio||'|'||vl_referencia_dom_destinatario||'|'||D_Fiscales.Municipio||'|'||D_Fiscales.Estado||'|'||D_Fiscales.Pais||'|'||D_Fiscales.CP||'|'||D_Fiscales.Email||'|'||vl_id_tipo_destinatario||'|'||vl_estatus_registro||'|';

                                    
                                    

                        vl_serie_folio :='ENC(+)';
                        vl_info_concepto :='L(+)';
                        vl_impuesto :='LIMPTRAS(+)';
                        vl_impuesto_ret :='LIMPRET(+)';
                        vl_info_impuestos :='TOTIMP(+)';
                        vl_info_subtotal_imptras :='IMPTRAS(+)';
                        vl_info_subtotal_impret :='IMPRET(+)';
                        vl_flex_header :='FH(+)';
                                               
                        vl_fecha_pago := null;
                        vl_transaccion  :=0;
                        vl_total_impret :=0;
                        vl_total_imptras :=0;
                        vl_contador :=0;
                                

                               ---------------- LLenamos Folio y SErie ENC(+)------------------
                           --     vl_serie_folio := vl_serie_folio||d_fiscales.serie||'|'||vl_consecutivo||'|'||pago.Fecha_pago||'|'||vl_forma_pago||'|'||vl_condicion_pago||'|'||vl_tipo_cambio||'|'||vl_tipo_moneda||'|'||vl_metodo_pago||'|'||vl_lugar_expedicion||'|'||vl_tipo_comprobante||'|'||vl_subtotal||'|'||vl_descuento||'|'||pago.MONTO_PAGADO||'|'||vl_confirmacion||'|'||vl_tipo_documento||'|';

                        vl_pago_total_faltante:=0;
                        vl_secuencia :=0;
                        vn_iva :=0;

                               FOR Pagos_dia
                                        IN (
                                              with cargo as (
                                                        Select distinct tbraccd_pidm pidm, tbraccd_detail_code cargo, tbraccd_tran_number transa, tbraccd_desc descripcion 
                                                        from tbraccd),
                                                        iva as (
                                                        select distinct TVRACCD_PIDM pidm, TVRACCD_AMOUNT monto_iva, TVRACCD_ACCD_TRAN_NUMBER iva_tran
                                                        from tvraccd
                                                        where TVRACCD_DETAIL_CODE like 'IV%'
                                                        )
                                                        SELECT DISTINCT
                                                            TBRACCD_PIDM PIDM,
                                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                                            to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                                           nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                                            to_char(TBRACCD_EFFECTIVE_DATE, 'dd/mm/rrrr') Fecha_pago,
                                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                                            TBBDETC_DESC DESCRIPCION,
                                                            nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                                            nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                                            to_char(nvl (iva.monto_iva, 0),'fm9999999990.00') monto_iva,
                                                            iva.iva_tran iva_transaccion,
                                                            ROW_NUMBER() OVER(PARTITION BY TBRACCD_TRAN_NUMBER ORDER BY TBRACCD_EFFECTIVE_DATE) numero
                                                            FROM TBRACCD
                                                            LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                            LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                                            AND TBRAPPL_REAPPL_IND IS NULL
                                                            left join cargo on cargo.pidm = tbraccd_pidm
                                                            and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                                            left join iva on iva.pidm = TBRACCD_PIDM
                                                            and iva.iva_tran = TBRACCD_TRAN_NUMBER
                                                            WHERE     TBBDETC_TYPE_IND = 'P'
                                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                                            AND TBRACCD_PIDM= pago.pidm
                                                            And TBRACCD_TRAN_NUMBER = pago.TRANSACCION
                                                             AND TRUNC (TBRACCD_EFFECTIVE_DATE) >= trunc(sysdate)
                                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                    FROM TZTFACT
                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                                            ORDER BY TBRACCD_PIDM, 2,13 asc
                                         )
                         LOOP

                              vl_contador := vl_contador +1;
                              vl_pago_total_faltante := vl_pago_total_faltante + Pagos_dia.MONTO_PAGADO_CARGO;
                              vl_secuencia :=Pagos_dia.numero;
                              vn_iva :=  vn_iva + Pagos_dia.monto_iva;


                             BEGIN

                                select '01'
                                     INTO vl_forma_pago
                                from tbraccd a, spriden b
                                where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                              from tbbdetc
                                                                              where TBBDETC_DCAT_CODE = 'CSH'
                                                                               and TBBDETC_TYPE_IND = 'P')
                                   and tbraccd_pidm = spriden_pidm
                                   and spriden_change_ind is null
                                   AND spriden_pidm = Pagos_dia.PIDM
                                   AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                   and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                          FROM ZSTPARA
                                                                                          WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                          AND ZSTPARA_PARAM_ID = 'EFECTIVO');
                             
                             EXCEPTION           
                               WHEN OTHERS THEN NULL;
                                 vl_forma_pago:='99';
                                    BEGIN
                                     
                                     select '02'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                  FROM ZSTPARA
                                                                                                  WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                  AND ZSTPARA_PARAM_ID = 'CHEQUE');
                                     
                                     
                                     EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_forma_pago:='99';
                                         BEGIN

                                        select '03'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                  FROM ZSTPARA
                                                                                                  WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                  AND ZSTPARA_PARAM_ID = 'TRANSFERENCIA');

                                     EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_forma_pago:='99';
                                             BEGIN

                                            select '04'
                                            INTO vl_forma_pago
                                            from tbraccd a, spriden b
                                            where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                          from tbbdetc
                                                                                          where TBBDETC_DCAT_CODE = 'CSH'
                                                                                           and TBBDETC_TYPE_IND = 'P')
                                               and tbraccd_pidm = spriden_pidm
                                               and spriden_change_ind is null
                                               AND spriden_pidm = Pagos_dia.PIDM
                                               AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                               and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                      FROM ZSTPARA
                                                                                                      WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                      AND ZSTPARA_PARAM_ID = 'TARJETA_DE_CREDITO');
                                         
                                         EXCEPTION           
                                           WHEN OTHERS THEN NULL;
                                             vl_forma_pago:='99';
                                        END;
                                     END;
                                 END;
                         END;


                                If PAGOS_DIA.MONTO_PAGADO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO := PAGOS_DIA.MONTO_PAGADO * (-1);
                                End if;                                

                            
                            ------------------- Seteo ---------------
                           
                            vl_total :=PAGOS_DIA.MONTO_PAGADO;
                            vl_fecha_pago := PAGOS_DIA.Fecha_pago;
                            vl_transaccion :=PAGOS_DIA.TRANSACCION;



                            ----
                                If Pagos_dia.numero > 1 then 
                                    vl_info_concepto := vl_info_concepto ||'L(+)';
                                    vl_impuesto := vl_impuesto ||'LIMPTRAS(+)';
                                End if;
                                
                                   
                                If Pagos_dia.monto_iva > 0 then
                                    vl_tasa_cuota_impuesto := '0.160000';
                                Elsif Pagos_dia.monto_iva = 0 then
                                    vl_tasa_cuota_impuesto := '0.000000';
                                End if;
                                
                                
                                If PAGOS_DIA.MONTO_PAGADO_CARGO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO_CARGO := PAGOS_DIA.MONTO_PAGADO_CARGO * (-1);
                                End if;
                                
                                

                                --------Concepto L(+)
                                vl_info_concepto := vl_info_concepto||Pagos_dia.numero||'|'||vl_prod_serv||'|'||vl_cantidad_concepto||'|'||vl_clave_unidad_concepto||
                                                                                                                     '|'||vl_unidad_concepto||'|'||Pagos_dia.clave_cargo||'|'||Pagos_dia.DESCRIPCION_cargo||
                                                                                                                     '|'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||'|'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||
                                                                                                                     '|'||vl_descuento||'|'||chr(13);

                                --------Impuesto trasladado LIMPTRAS(+)
                                vl_impuesto := vl_impuesto ||Pagos_dia.numero||'|'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||'|'||vl_impuesto_cod||
                                                                                                        '|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||pagos_dia.monto_iva||'|'||chr(13);


                                 vl_info_concepto := vl_info_concepto||vl_impuesto;                                                                         
                                                                                                         
                                vl_total_imptras := vl_total_imptras + pagos_dia.monto_iva;
                                

                                --------Impuesto retenido LIMPRET(+)
                                
                                vl_total_impret := 0;                
                                --vl_total_impret := vl_total_impret + pagos_dia.monto_iva;
                             --   vl_impuesto_ret := vl_impuesto_ret  ||Pagos_dia.numero||'|'||PAGOS_DIA.MONTO_PAGADO_CARGO||'|'||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||pagos_dia.monto_iva||'|';
                            
                                
                                --DBMS_OUTPUT.PUT_LINE(vl_encabezado||'*'||vl_serie_folio||'*'||vl_entidad_receptor||'*'||vl_envio_correo||'*'||vl_dfiscales_utel||'*'||vl_dfiscales_receptor||'*'||vl_dfiscales_destinatario||'*'||vl_info_concepto||'*'||vl_impuesto||'*'||vl_impuesto_ret||'*'||vl_info_impuestos||'*'||vl_info_subtotal_imptras||'*'||vl_info_subtotal_impret||'*');
                                

                         END LOOP;
                      
                       vl_subtotal := vl_subtotal - vn_iva;
                       
                               
                       ---------------- LLenamos Folio y SErie ENC(+)------------------
                         vl_serie_folio := vl_serie_folio||d_fiscales.serie||'|'||vl_consecutivo||'|'||pago.Fecha_pago||
                                                                                                '|'||vl_forma_pago||'|'||vl_condicion_pago||'|'||vl_tipo_cambio||'|'||vl_tipo_moneda||
                                                                                                '|'||vl_metodo_pago||'|'||vl_lugar_expedicion||'|'||vl_tipo_comprobante||'|'||to_char(vl_subtotal, 'fm9999999990.00')||
                                                                                                '|'||vl_descuento||'|'||to_char(pago.MONTO_PAGADO, 'fm9999999990.00')||'|'||vl_confirmacion||'|'||vl_tipo_documento||'|';
                         
                        

                        
                        
                        vl_clave_cargo := null;
                        vl_descrip_cargo := null;
                        vl_secuencia := vl_secuencia +1;
                       
                         
                      If vl_pago_total >  vl_pago_total_faltante then 
                             vl_pago_diferencia :=    vl_pago_total -  vl_pago_total_faltante;
                             
                         If vl_secuencia > 1 then 
                                    vl_info_concepto := vl_info_concepto ||'L(+)';
                                    vl_impuesto := 'LIMPTRAS(+)';
                         End if;
                                
                                        Begin    
                                             Select TBBDETC_DETAIL_CODE, TBBDETC_DESC
                                               Into  vl_clave_cargo, vl_descrip_cargo
                                             from tbbdetc
                                             Where TBBDETC_DETAIL_CODE = substr (D_Fiscales.matricula, 1,2)||'NN'
                                             And TBBDETC_DCAT_CODE = 'COL';
                                         Exception
                                         when Others then 
                                             vl_clave_cargo := null;
                                              vl_descrip_cargo := null;
                                        End;
                                        
                                        If  vl_clave_cargo is not null and vl_descrip_cargo is not null then                              
                                                vl_info_concepto := vl_info_concepto||vl_secuencia  ||'|'||
                                                                                                        vl_prod_serv||'|'||
                                                                                                        vl_cantidad_concepto||'|'||
                                                                                                        vl_clave_unidad_concepto||'|'||
                                                                                                        vl_unidad_concepto||'|'||
                                                                                                        vl_clave_cargo||'|'||
                                                                                                        vl_descrip_cargo||'|'||
                                                                                                        to_char(vl_pago_diferencia,'fm9999999990.00')||'|'||
                                                                                                        to_char(vl_pago_diferencia,'fm9999999990.00')||'|'||vl_descuento||'|'||chr(13);

                                              If substr (D_Fiscales.matricula, 1,2) = '01' then 
                                                --------Impuesto trasladado LIMPTRAS(+)
                                                vl_impuesto := vl_impuesto ||vl_secuencia ||'|'||
                                                                                            vl_pago_diferencia||'|'||
                                                                                            vl_impuesto_cod||'|'||
                                                                                            vl_tipo_factor_impuesto||'|'||
                                                                                            vl_tasa_cuota_impuesto||'|'||
                                                                                            to_char(to_char(vl_pago_diferencia*(0/100)),'fm9999999990.00')||'|'||chr(13);
                                                vl_total_imptras := vl_total_imptras + to_char(vl_pago_diferencia*(0/100));                                          
                                                
                                                vl_info_concepto := vl_info_concepto||vl_impuesto;    
                                                
                                                vl_total_impret := 0;                

                                              End if;
                                               
                                       End if;
                                       
                                       
                      End if;
                      

                                     
                                 --vl_info_impuestos_comprobante TOTIMP(+)
                                        vl_info_impuestos := vl_info_impuestos||to_char(vl_total_impret,'fm9999999990.00')||'|'||to_char(vl_total_imptras,'fm9999999990.00')||'|';
                           
                                --Info_subtotal_imptras  IMPTRAS(+)
                                        vl_info_subtotal_imptras := vl_info_subtotal_imptras||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||to_char(vl_total_imptras,'fm9999999990.00')||'|';

                                               --Info_subtotal_impret IMPRET(+)
                                        vl_info_subtotal_impret := vl_info_subtotal_impret||vl_impuesto_cod||'|'||to_char(vl_total_impret,'fm9999999990.00')||'|';
                                        
                               --Flex_Header FH(+)
                                        vl_flex_header := vl_flex_header||vl_folio_interno_cl_fh||'|'||vl_folio_interno_fh||'|'||D_Fiscales.PIDM||'|'||chr(10)||
                                                                  vl_flex_header||vl_razon_social_cl_fh||'|'||vl_razon_social_fh||'|'||nvl(D_fiscales.Nombre, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_metodo_pago_cl_fh||'|'||vl_metodo_pago_fh||'|'||nvl(pago.METODO_PAGO_CODE, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_desc_metodo_pago_cl_fh||'|'||vl_desc_metodo_pago_fh||'|'||nvl(pago.METODO_PAGO, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_id_pago_cl_fh||'|'||vl_id_pago_pago_fh||'|'||nvl(pago.Id_pago, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_monto_cl_fh||'|'||vl_monto_fh||'|'||nvl(to_char(pago.MONTO_PAGADO,'fm9999999990.00'), '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_nivel_cl_fh||'|'||vl_nivel_fh||'|'||nvl(D_Fiscales.Nivel, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_campus_cl_fh||'|'||vl_campus_fh||'|'||nvl(D_fiscales.Campus, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_matricula_alumno_cl_fh||'|'||vl_matricula_alumno_fh||'|'||nvl(D_fiscales.MATRICULA, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_fecha_pago_cl_fh||'|'||vl_fecha_pago_fh||'|'||nvl(pago.Fecha_pago, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_referencia_cl_fh||'|'||vl_referencia_fh||'|'||nvl(D_fiscales.Referencia, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_referencia_tipo_cl_fh||'|'||vl_referencia_tipo_fh||'|'||nvl(D_fiscales.Ref_tipo, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_int_pago_tardio_cl_fh||'|'||vl_int_pago_tardio_fh||'|'||nvl(vl_valor_int_pag_tard_fh, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_tipo_accesorio_cl_fh||'|'||vl_tipo_accesorio_fh||'|'||nvl(pago.tipo_accesorio, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_monto_accesorio_cl_fh||'|'||vl_monto_accesorio_fh||'|'||nvl(pago.monto_accesorio, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_otros_cl_fh||'|'||vl_otros_fh||'|'||nvl(vl_valor_otros_fh, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_monto_otros_cl_fh||'|'||vl_monto_otros_fh||'|'||nvl(vl_valor_monto_otros_fh, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_nom_alumnos_cl_fh||'|'||vl_nom_alumnos_fh||'|'||nvl(D_Fiscales.Nombre_Alumno, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_curp_cl_fh||'|'||vl_curp_fh||'|'||nvl(D_Fiscales.Curp, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_rfc_cl_fh||'|'||vl_rfc_fh||'|'||nvl(D_Fiscales.RFC, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_grado_cl_fh||'|'||vl_grado_fh||'|'||nvl(D_Fiscales.Grado, '.')||'|';
                                                                  

                              
                                BEGIN
                                     INSERT INTO TZTFACT VALUES(
                                        D_Fiscales.PIDM
                                      , D_Fiscales.RFC
                                      , vl_total
                                      , 'FA'
                                      , NULL
                                      , NULL
                                      , sysdate
                                      ,vl_transaccion
                                      ,vl_encabezado||chr(10)||vl_serie_folio||chr(10)||vl_entidad_receptor||chr(10)||vl_envio_correo||
                                      chr(10)||vl_dfiscales_utel||chr(10)||vl_dfiscales_receptor||chr(10)||vl_flex_header||chr(10)||vl_info_concepto||
                                      --vl_impuesto||chr(10)||
                                      vl_info_impuestos||chr(10)||vl_info_subtotal_imptras||chr(10)||vl_info_subtotal_impret
                                      ,vl_consecutivo
                                      ,d_fiscales.serie
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,vl_tipo_archivo
                                      ,vl_tipo_fact
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL

                                 );
                                EXCEPTION
                                WHEN OTHERS THEN
                                 VL_ERROR := 'Se presento un error al insertar ' ||sqlerrm;
                                 --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
                                END;  


                                
                                  Begin
                                    
                                    Update tztdfut
                                    set TZTDFUT_FOLIO = vl_consecutivo
                                    Where TZTDFUT_SERIE = D_Fiscales.serie;
                                    Exception
                                    When Others then 
                                      VL_ERROR := 'Se presento un error al Actualizar ' ||sqlerrm;   
                                    End;
                         
                         If vn_commit >= 500 then 
                             commit;
                             vn_commit :=0;
                         End if;
                   
               
            End Loop Pago;
         
      END LOOP;

   commit;
   --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
Exception
    when Others then
     ROLLBACK;
     --DBMS_OUTPUT.PUT_LINE('Error General'||sqlerrm);
END;

PROCEDURE sp_Sin_Datos_Facturacion
IS

---- Se Arma el encazado de la factura DOC(+)-------------
vl_encabezado varchar2(4000):='DOC(+)';
vl_consecutivo number :=0;

-------------- LLenamos Folio y SErie ENC(+)
vl_serie_folio varchar2(2500):='ENC(+)';
vl_forma_pago varchar2(100);
vl_condicion_pago varchar2(250):= 'Pago en una sola exhibición';
vl_tipo_cambio number:=1;
vl_tipo_moneda varchar2(10):= 'MXN';
vl_metodo_pago varchar2(10):= 'PUE';
vl_lugar_expedicion varchar2(10):= '53370';
vl_tipo_comprobante varchar2(5):= 'I';
vl_descuento varchar2(15):='0.00';
vl_total number(16,2);
vl_confirmacion varchar2(2);
vl_tipo_documento number:=1;
vl_subtotal number(16,2);


-------------------Entidad_receptor ENC_ERP(+)
vl_entidad_receptor varchar2(4000):='ENC_ERP(+)';

 
---------Envio por correo ENVIO_CFDI(+)
vl_envio_correo varchar2(4000):='ENVIO_CFDI(+)';
vl_enviar_xml varchar2(15):='TRUE';
vl_enviar_pdf varchar2(15):='TRUE';
vl_enviar_zip varchar2(15):='TRUE';


------Datos fiscales utel EMISOR(+)
vl_dfiscales_utel varchar2(4000):='EMISOR(+)';
vl_rfc_utel varchar2(15);
vl_razon_social_utel varchar2(250);
vl_regimen_fiscal varchar2(5):='601';
vl_id_emisor_sto number:=1;
vl_id_emisor_erp number:=1;


------Datos fiscales Alumno RECEPTOR(+)
vl_dfiscales_receptor varchar2(4000):='RECEPTOR(+)';
vl_referencia_dom_receptor varchar2(255):=' ';
vl_nombre_rec varchar2(250):= 'Publico en General';
--vl_id_tipo_receptor varchar2(25):='0';
vl_id_receptor_sto varchar2(25):='1';
vl_estatus_registro varchar2(25):='1';
vl_uso_cfdi varchar2(25):='D10';
vl_residencia_fiscal varchar2(25);
vl_num_reg_id_trib varchar2(25);
vl_id_receptor_erp varchar2(25):='1';
vl_num_ext_receptor varchar2(250):= '159';
vl_calle_receptor varchar2(250):= 'Calzada De La Naranja';
vl_num_int_receptor varchar2(250):= 'Piso 4';
vl_colonia_receptor varchar2(250):= 'Fracc Ind Alce Blanco';
vl_municipio_receptor varchar2(250):= 'Naucalpan';
vl_ciudad_receptor varchar2(250):= 'Naucalpan';
vl_estado_receptor varchar2(250):= 'Edo Mex';
vl_pais_receptor varchar2(250):= 'Mexico';
vl_cp_receptor varchar2(250):= '53370';
--vl_id_receptor_padre varchar2(25);


------Datos fiscales Alumno DESTINATARIO(+)
vl_dfiscales_destinatario varchar2(4000):='RECEPTOR(+)';
vl_referencia_dom_destinatario varchar2(255):=' ';
vl_id_tipo_destinatario varchar2(25):='0';
vl_id_destinarario_sto varchar2(25):='0';


------Concepto L(+)
vl_info_concepto CLOB :='L(+)';
vl_num_linea number:=0;
vl_prod_serv varchar2(50);
vl_cantidad_concepto varchar2(10):='1';
vl_clave_unidad_concepto varchar2(10):='E48';
vl_unidad_concepto varchar2(50):='Servicio';
vl_importe_concepto number:=1;
vl_fecha_pago date;
vl_transaccion number :=0;


--Impuesto trasladado LIMPTRAS(+)
vl_impuesto varchar2(32000):='LIMPTRAS(+)';
vl_impuesto_cod varchar2(10):='002';
vl_tipo_factor_impuesto varchar2(15):='Tasa';
vl_tasa_cuota_impuesto varchar2(15);


--Impuesto retenido LIMPRET(+)
vl_impuesto_ret varchar2(4000):='LIMPRET(+)';
vl_base_impuesto_ret varchar2(25);
vl_impuesto_ret_cod varchar2(10):='002';
vl_tipo_factor_impuesto_ret varchar2(15):='Tasa';
vl_tasa_cuota_impuesto_ret varchar2(15);
vl_importe_impuesto_ret number(24,2);


--Info_impuestos_comprobante TOTIMP(+)
vl_info_impuestos varchar2(4000):='TOTIMP(+)';
vl_total_impret number(24,2);
vl_total_imptras number(24,2);


--Info_subtotal_imptras IMPTRAS(+)
vl_info_subtotal_imptras varchar2(4000):='IMPTRAS(+)';


--Info_subtotal_impret IMPRET(+)
vl_info_subtotal_impret varchar2(4000):='IMPRET(+)';
vl_error varchar2(2500):='EXITO';
vl_contador number:=0;
vl_existe number:=0;


--excedente
vl_pago_total number :=0;
vl_pago_total_faltante number :=0;
vl_pago_diferencia number :=0;
vl_clave_cargo varchar2(5):= null;
vl_descrip_cargo varchar2(90):= null;
vl_secuencia number:=0;


--Flex_Header FH(+)
vl_flex_header varchar2(4000):='FH(+)';
vl_folio_interno_cl_fh varchar2(50):='1';
vl_folio_interno_fh varchar2(255):='Folio_interno';
vl_razon_social_cl_fh varchar2(50):='2';
vl_razon_social_fh varchar2(255):='Razon_Social';
vl_metodo_pago_cl_fh varchar2(50):='3';
vl_metodo_pago_fh varchar2(255):='Metodo_de_pago';
vl_desc_metodo_pago_cl_fh varchar2(50):='4';
vl_desc_metodo_pago_fh varchar2(255):='Descripcion_de_metodo_de_pago';
vl_id_pago_cl_fh varchar2(50):='5';
vl_id_pago_pago_fh varchar2(255):='Id_pago';
vl_monto_cl_fh varchar2(50):='6';
vl_monto_fh varchar2(255):='Monto';
vl_nivel_cl_fh varchar2(50):='7';
vl_nivel_fh varchar2(255):='Nivel';
vl_campus_cl_fh varchar2(50):='8';
vl_campus_fh varchar2(255):='Campus';
vl_matricula_alumno_cl_fh varchar2(50):='9';
vl_matricula_alumno_fh varchar2(255):='Matricula_alumno';
vl_fecha_pago_cl_fh varchar2(50):='10';
vl_fecha_pago_fh varchar2(255):='Fecha_pago';
vl_referencia_cl_fh varchar2(50):='11';
vl_referencia_fh varchar2(255):='Referencia';
vl_referencia_tipo_cl_fh varchar2(50):='12';
vl_referencia_tipo_fh varchar2(255):='Referencia_tipo';
vl_m_int_pago_tardio_cl_fh varchar2(50):='13';
vl_m_int_pago_tardio_fh varchar2(255):='MontoInteresPagoTardio';
vl_m_valor_int_pag_tard_fh varchar2(255):= null;
vl_tipo_accesorio_cl_fh varchar2(50):='14';
vl_tipo_accesorio_fh varchar2(255):='Tipo_accesorio';
vl_monto_accesorio_cl_fh varchar2(50):='15';
vl_monto_accesorio_fh varchar2(255):='Monto_accesorio';
vl_cole_cl_fh varchar2(50):='16';
vl_cole_fh varchar2(255):='Colegiatura';
vl_valor_cole_fh varchar2(255):= null;
vl_monto_cole_cl_fh varchar2(50):='17';
vl_monto_cole_fh varchar2(255):='Monto_colegiatura';
vl_valor_monto_cole_fh varchar2(255):= null;
vl_nom_alumnos_cl_fh varchar2(50):='18';
vl_nom_alumnos_fh varchar2(255):='Nombre_alumno';
vl_curp_cl_fh varchar2(50):='19';
vl_curp_fh varchar2(255):='CURP';
vl_rfc_cl_fh varchar2(50):='20';
vl_rfc_fh varchar2(255):='RFC';
vl_grado_cl_fh varchar2(50):='21';
vl_grado_fh varchar2(255):='Grado';
vl_nota_cl_fh varchar2(50):='22';
vl_nota_fh varchar2(255):='Nota';
vl_valor_nota_fh varchar2(255):= null;
vl_int_pago_tardio_cl_fh varchar2(50):='23';
vl_int_pago_tardio_fh varchar2(255):='InteresPagoTardio';
vl_valor_int_pag_tard_fh varchar2(255):= null;


------ Contadoor de registros
vn_commit  number :=0;

---- Manejo del IVA
vn_iva number:=0;
vl_iva number :=0;


---- Tipo_Archivo
vl_tipo_archivo varchar2(50):='TXT';
vl_tipo_fact varchar2(50):='Sin_D_facturacion';


----Complemento IEDU(+)
vl_complemento varchar2(4000):='IEDU(+)';
vl_linea_comp varchar2(25):=1;
vl_version_comp varchar2(10):='1.0';
vl_nivel_comp varchar2(25):='Profesional Técnico';


vl_estatus_timbrado number :=0;
--   
BEGIN



   FOR Sin_D_Fiscales
              IN (  WITH CURP AS (
                                            select 
                                                SPRIDEN_PIDM PIDM,
                                                GORADID_ADDITIONAL_ID CURP
                                              from SPRIDEN
                                              left join GORADID on SPRIDEN_PIDM = GORADID_PIDM
                                              where GORADID_ADID_CODE = 'CURP'
                                              )
                        select distinct SPRIDEN_PIDM PIDM,
                                            SPRIDEN_ID MATRICULA,
                                            replace(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME Nombre_Alumno,
                                            SUBSTR(spriden_id,5) ID,
                                            SPREMRG_LAST_NAME Nombre,
                                            CASE
                                                 when SPREMRG_MI is null then
                                                 'XAXX010101000'
                                            end RFC,
                                            REGEXP_SUBSTR(SPREMRG_STREET_LINE1, '[^#"]+', 1, 1) Calle,
                                            NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#[^#]*'),2), 0) Num_Ext,
                                            NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#Int[^*]*'),2), 0) Num_Int,
                                            SPREMRG_STREET_LINE3 Colonia,
                                            SPREMRG_CITY AS Municipio,
                                            SPREMRG_ZIP AS CP,                                               
                                            SPREMRG_STAT_CODE Estado,
                                            SPREMRG_NATN_CODE AS Pais,
                                            'acruzsol@utel.edu.mx' Email,
                                            --GOREMAL_EMAIL_ADDRESS Email,
                                            CASE
                                                 when GORADID_ADID_CODE = 'REFH' then
                                                 'BH'
                                                 when GORADID_ADID_CODE = 'REFS' then
                                                 'BS'
                                                 when GORADID_ADID_CODE = 'REFU' then 
                                                  'UI'
                                            end Serie,
                                            SZVCAMP_CAMP_CODE Campus,
                                            GORADID_ADDITIONAL_ID Referencia,
                                            GORADID_ADID_CODE Ref_tipo,
                                            STVLEVL_DESC Nivel,
                                            CURP.CURP Curp,
                                            SARADAP_DEGC_CODE_1 Grado,
                                            SZTDTEC_NUM_RVOE RVOE_num,
                                            SZTDTEC_CLVE_RVOE RVOE_clave
                            from SPRIDEN
                            left join SPREMRG on SPRIDEN_PIDM = SPREMRG_PIDM
                            left outer join SARADAP on SPRIDEN_PIDM = SARADAP_PIDM
                            left join STVLEVL on SARADAP_LEVL_CODE = STVLEVL_CODE
                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                            left join GORADID on GORADID_PIDM = SPRIDEN_PIDM 
                                and GORADID_ADID_CODE LIKE 'REF%'
                            join SZVCAMP on szvcamp_camp_alt_code=substr(SPRIDEN_ID,1,2)
                            left join CURP on SPRIDEN_PIDM = CURP.PIDM
                            left outer join SZTDTEC on saradap_camp_code = SZTDTEC_CAMP_CODE
                            and SARADAP_PROGRAM_1 = SZTDTEC_PROGRAM
                            and SARADAP_TERM_CODE_CTLG_1 = SZTDTEC_TERM_CODE
                            WHERE SPRIDEN_PIDM not in (SELECT SPREMRG_PIDM
                            FROM SPREMRG)
                                          and SPRIDEN_ID not in (SELECT SPRIDEN_ID
                                                                       FROM SPRIDEN
                                                                       WHERE SPRIDEN_ID LIKE '%99000%')
--                            and spriden_pidm in (1300, 21834)
                            ORDER BY SPRIDEN_PIDM
                                  )
   LOOP
            vl_pago_total:=0;
            vn_commit :=0;
           For pago in (
                               with accesorios as(
                                                        select distinct
                                                          TZTCRTE_PIDM Pidm,
                                                          TZTCRTE_LEVL as Nivel,
                                                          TZTCRTE_CAMP as Campus,
                                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                                          TZTCRTE_CAMPO19 as accesorios,
                                                          to_char(sum (TZTCRTE_CAMPO20),'fm9999999990.00') as Monto_accesorios,
                                                          TZTCRTE_CAMPO15 as colegiaturas,
                                                          to_char(sum (TZTCRTE_CAMPO16),'fm9999999990.00') as Monto_colegiaturas,
                                                          TZTCRTE_CAMPO17 as intereses,
                                                          to_char(sum (TZTCRTE_CAMPO18),'fm9999999990.00') as Monto_intereses,                                                          
                                                          TZTCRTE_CAMPO26 as Categoria,
                                                          TZTCRTE_CAMPO10 as Secuencia
                                                        from TZTCRTE
                                                        where  TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
--                                                               and TZTCRTE_CAMPO26 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                                                group by TZTCRTE_PIDM, TZTCRTE_LEVL, TZTCRTE_CAMP, TZTCRTE_CAMPO11, TZTCRTE_CAMPO15, TZTCRTE_CAMPO17, TZTCRTE_CAMPO19, TZTCRTE_CAMPO26, TZTCRTE_CAMPO10
                                                                )
                                    SELECT DISTINCT 
                                            TBRACCD_PIDM PIDM,
                                            SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                            substr(TBRACCD_DETAIL_CODE,1,2) FORMA_PAGO,
                                            TBRACCD_DETAIL_CODE METODO_PAGO_CODE,
                                            TBRACCD_DESC METODO_PAGO,
                                            to_char (TBRACCD_EFFECTIVE_DATE,'RRRR-MM-DD"T"HH24:MI:SS') Fecha_pago,
                                            TBRACCD_PAYMENT_ID Id_pago,
                                            accesorios.accesorios tipo_accesorio,
                                            accesorios.Monto_accesorios monto_accesorio,
                                            accesorios.colegiaturas colegiaturas,
                                            accesorios.Monto_colegiaturas monto_colegiatura,
                                            accesorios.intereses intereses,
                                            accesorios.Monto_intereses monto_interes
                                    FROM TBRACCD
                                    left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                    LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                    LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                        AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                    left join accesorios on tbraccd_pidm = accesorios.Pidm
                                    and TBRACCD_TRAN_NUMBER = accesorios.secuencia
                                    WHERE TBBDETC_TYPE_IND = 'P'
                                        AND TBBDETC_DCAT_CODE = 'CSH'
                                        AND TBRACCD_PIDM= Sin_D_Fiscales.pidm
                                       AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                       and rownum = 1
                                        AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                    FROM TZTFACT
                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                    ORDER BY TBRACCD_PIDM, 2 asc
                                    )
            loop

             If pago.MONTO_PAGADO like '-%' then
                    pago.MONTO_PAGADO := pago.MONTO_PAGADO * (-1);
             End if;      
             
                                   
                vn_commit := vn_commit +1;
                vl_pago_total := pago.MONTO_PAGADO;
                vl_subtotal := pago.MONTO_PAGADO;
                
                 --DBMS_OUTPUT.PUT_LINE('SUBTOTAL ' ||vl_subtotal); 
                
                ------------------------   
                
                                            
                vl_num_linea:=0;
                vl_rfc_utel:= null; 
                vl_razon_social_utel:= null; 
                vl_prod_serv := null;      
                 vl_consecutivo :=0;
              
                vl_encabezado :='DOC(+)';
                vl_entidad_receptor :='ENC_ERP(+)';
                vl_envio_correo :='ENVIO_CFDI(+)';
                vl_dfiscales_utel :='EMISOR(+)';
                vl_dfiscales_receptor :='RECEPTOR(+)';
                vl_dfiscales_destinatario := 'DESTINATARIO(+)';     
                vl_complemento := 'IEDU(+)';

                
                      --Emisor_STO
                        If Sin_D_Fiscales.serie = 'BH' then
                            vl_id_emisor_sto := 1;
                        Elsif Sin_D_Fiscales.serie = 'BS' then
                            vl_id_emisor_sto := 2;
                        End if;
                        
                      --Emisor_ERP
                         If Sin_D_Fiscales.serie = 'BH' then
                            vl_id_emisor_erp := 1;
                        Elsif Sin_D_Fiscales.serie = 'BS' then
                            vl_id_emisor_erp := 2;
                        End if; 

            --- Se obtiene el numero de consecutivo por empresa 
                    Begin

                    select nvl (max (TZTDFUT_FOLIO), 0)+1
                        Into  vl_consecutivo
                    from tztdfut
                    where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                    Exception
                    When Others then 
                        vl_consecutivo :=1;
                    End;

                   Begin
                        select 
                            TZTDFUT_RFC RFC,
                            TZTDFUT_RAZON_SOC RAZON_SOCIAL,
                            TZTDFUT_PROD_SERV_CODE
                        Into vl_rfc_utel, vl_razon_social_utel, vl_prod_serv
                        from TZTDFUT
                        where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                   exception
                   when others then
                        vl_error:= 'Error al Recuperer los datos Fiscales de la empresa ' ||sqlerrm;
                   End;




                ---- Se Arma el encazado de la factura DOC(+)-------------
                vl_encabezado := vl_encabezado ||vl_consecutivo;
                
                --------Datos fiscales utel EMISOR(+)
                vl_dfiscales_utel := vl_dfiscales_utel||vl_rfc_utel||'|'||vl_razon_social_utel||'|'||vl_regimen_fiscal||'|'||vl_id_emisor_sto||'|'||vl_id_emisor_erp;
                
                -----Se envia por correo ENVIO_CFDI(+)
                vl_envio_correo := vl_envio_correo||vl_enviar_xml||'|'||vl_enviar_pdf||'|'||vl_enviar_zip||'|'||Sin_D_Fiscales.Email;
                
                ----------Datos de entidad del receptor ENC_ERP(+)
                vl_entidad_receptor := vl_entidad_receptor ||vl_consecutivo;
                
                --------Datos fiscales alumno RECEPTOR(+)
                vl_dfiscales_receptor := vl_dfiscales_receptor||Sin_D_Fiscales.RFC||'|'||vl_nombre_rec||'|'||vl_residencia_fiscal||'|'||vl_num_reg_id_trib||'|'||vl_uso_cfdi||'|'||vl_id_receptor_sto||'|'||vl_id_receptor_erp||'|'||vl_num_ext_receptor||'|'||vl_calle_receptor||'|'||vl_num_int_receptor||'|'||vl_colonia_receptor||'|'||vl_municipio_receptor||'|'||vl_referencia_dom_receptor||'|'||vl_ciudad_receptor||'|'||vl_estado_receptor||'|'||vl_pais_receptor||'|'||vl_cp_receptor||'|'||Sin_D_Fiscales.Email||'|'||Sin_D_Fiscales.ID||'|'||vl_estatus_registro;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
                --------Datos fiscales alumno DESTINATARIO(+)
                vl_dfiscales_destinatario := vl_dfiscales_destinatario||Sin_D_Fiscales.RFC||'|'||Sin_D_Fiscales.Nombre||'|'||vl_uso_cfdi||'|'||vl_id_destinarario_sto||'|'||Sin_D_Fiscales.Num_Ext||'|'||Sin_D_Fiscales.Calle||'|'||Sin_D_Fiscales.Num_Int||'|'||Sin_D_Fiscales.Colonia||'|'||Sin_D_Fiscales.Municipio||'|'||vl_referencia_dom_destinatario||'|'||Sin_D_Fiscales.Municipio||'|'||Sin_D_Fiscales.Estado||'|'||Sin_D_Fiscales.Pais||'|'||Sin_D_Fiscales.CP||'|'||Sin_D_Fiscales.Email||'|'||vl_id_tipo_destinatario||'|'||vl_estatus_registro;

                --------Complemento IEDU(+)
                vl_complemento := vl_complemento||vl_linea_comp||'|'||vl_version_comp||'|'||Sin_D_Fiscales.Nombre_Alumno||'|'||Sin_D_Fiscales.Curp||'|'||vl_nivel_comp||'|'||Sin_D_Fiscales.RVOE_num;
                                    

                            vl_serie_folio :='ENC(+)';
                            vl_info_concepto :='L(+)';
                            vl_impuesto :='LIMPTRAS(+)';
                            vl_impuesto_ret :='LIMPRET(+)';
                            vl_info_impuestos :='TOTIMP(+)';
                            vl_info_subtotal_imptras :='IMPTRAS(+)';
                            vl_info_subtotal_impret :='IMPRET(+)';
                            vl_flex_header :='FH(+)';
                                               
                            vl_fecha_pago := null;
                            vl_transaccion  :=0;
                            vl_total_impret :=0;
                            vl_total_imptras :=0;
                            vl_contador :=0;
                              

                               ---------------- LLenamos Folio y SErie ENC(+)------------------
                                --vl_serie_folio := vl_serie_folio||Sin_D_fiscales.serie||'|'||vl_consecutivo||'|'||pago.Fecha_pago||'|'||vl_forma_pago||'|'||vl_condicion_pago||'|'||vl_tipo_cambio||'|'||vl_tipo_moneda||'|'||vl_metodo_pago||'|'||vl_lugar_expedicion||'|'||vl_tipo_comprobante||'|'||vl_subtotal||'|'||vl_descuento||'|'||pago.MONTO_PAGADO||'|'||vl_confirmacion||'|'||vl_tipo_documento||'|';

                            vl_pago_total_faltante:=0;
                            vl_secuencia :=0;
                            vn_iva :=0;
                            vl_info_concepto := 'L(+)';
                            vl_impuesto :='LIMPTRAS(+)';
                            vl_iva :=0;

                               FOR Pagos_dia
                                        IN (
                                              with cargo as (
                                                                    select distinct 
                                                                        c.TVRACCD_PIDM PIDM, 
                                                                        c.TVRACCD_DETAIL_CODE cargo, 
                                                                       -- c.TVRACCD_TRAN_NUMBER transa, 
                                                                          c.TVRACCD_ACCD_TRAN_NUMBER transa, 
                                                                        c.TVRACCD_DESC descripcion, 
                                                                        to_char(c.TVRACCD_AMOUNT,'fm9999999990.00') MONTO_CARGO,
                                                                        Monto_Iv Monto_IVAS
                                                                    from TVRACCD c, TBBDETC a, (
                                                                                                                select distinct 
                                                                                                                        to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                                                from tvraccd i 
                                                                                                                    where 1=1
                                                                                                                    and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                                                ) monto_iva
                                                                    where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                                        and a.TBBDETC_TYPE_IND = 'C'
                                                                        and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                                        and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                                        and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
--                                                                        and c.TVRACCD_pidm = 25
                                                                    )
                                                        SELECT DISTINCT 
                                                            TBRACCD_PIDM PIDM,
                                                            SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                                            to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                                           nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                                            to_char(TBRACCD_EFFECTIVE_DATE, 'dd/mm/rrrr') Fecha_pago,
                                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                                            TBBDETC_DESC DESCRIPCION,
                                                           nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                                           nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                                           cargo.transa,
                                                    --        Monto_IVAS monto_iva,
                                                            ROW_NUMBER() OVER(PARTITION BY TBRACCD_TRAN_NUMBER ORDER BY TBRACCD_EFFECTIVE_DATE) numero
                                                        FROM TBRACCD
                                                        left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                                        LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                        LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                                            AND TBRAPPL_REAPPL_IND IS NULL
                                                        left join cargo on cargo.pidm = tbraccd_pidm
                                                           and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                                        WHERE     TBBDETC_TYPE_IND = 'P'
                                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                                            AND TBRACCD_PIDM= pago.pidm
                                                            And TBRACCD_TRAN_NUMBER = pago.TRANSACCION
                                                            AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                    FROM TZTFACT
                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                                --           AND TBRACCD_PIDM= 25 
                                                        ORDER BY TBRACCD_PIDM,13 asc
                                           )    
                          LOOP


                                 BEGIN
                                    
                                                select distinct  Monto_Iv Monto_IVAS
                                                    INTO vl_iva
                                                from TVRACCD c, TBBDETC a, (
                                                                                            select distinct 
                                                                                                    to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                            from tvraccd i 
                                                                                                where 1=1
                                                                                                and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                            ) monto_iva
                                                where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                    and a.TBBDETC_TYPE_IND = 'C'
                                                    and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                    and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                    and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
                                                    And  c.TVRACCD_PIDM= Pagos_dia.PIDM
                                                    and  c.TVRACCD_ACCD_TRAN_NUMBER = Pagos_dia.transa;
                                        
                                 EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_iva:='0.00';
                                 End;

                                    
                                  vl_contador := vl_contador +1;
                                  vl_pago_total_faltante := vl_pago_total_faltante + Pagos_dia.MONTO_PAGADO_CARGO;
                                  vl_secuencia :=Pagos_dia.numero;
                                  vn_iva :=  vn_iva + vl_iva;                                 


                                          --dbms_output.put_line('contadorxxxxx:'||vl_contador||' vl_pago_total_faltante:'||vl_pago_total_faltante||'*'||'vl_secuencia' ||'*'||vl_secuencia||'*' ||Pagos_dia.MONTO_PAGADO_CARGO);

                                          BEGIN
                                                     
                                                        select '01'
                                                        INTO vl_forma_pago
                                                        from tbraccd a, spriden b
                                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                      from tbbdetc
                                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                       and TBBDETC_TYPE_IND = 'P')
                                                           and tbraccd_pidm = spriden_pidm
                                                           and spriden_change_ind is null
                                                           AND spriden_pidm = Pagos_dia.PIDM
                                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                           AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                                           and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                    substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                  from TBRACCD a1
                                                                                                                  where a1.TBRACCD_DESC like '%EFEC%');
                                                     
                                               EXCEPTION           
                                                       WHEN OTHERS THEN NULL;
                                                         vl_forma_pago:='99';
                                                        BEGIN
                                                                     
                                                             select '02'
                                                            INTO vl_forma_pago
                                                            from tbraccd a, spriden b
                                                            where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                          from tbbdetc
                                                                                                          where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                           and TBBDETC_TYPE_IND = 'P')
                                                               and tbraccd_pidm = spriden_pidm
                                                               and spriden_change_ind is null
                                                               AND spriden_pidm = Pagos_dia.PIDM
                                                               AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                               AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                                               and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                        substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                      from TBRACCD a1
                                                                                                                      where a1.TBRACCD_DESC like '%CHEQUE%');
                                                             
                                                             
                                                         EXCEPTION           
                                                           WHEN OTHERS THEN NULL;
                                                             vl_forma_pago:='99';
                                                                BEGIN

                                                                        select '03'
                                                                        INTO vl_forma_pago
                                                                        from tbraccd a, spriden b
                                                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                                      from tbbdetc
                                                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                                       and TBBDETC_TYPE_IND = 'P')
                                                                           and tbraccd_pidm = spriden_pidm
                                                                           and spriden_change_ind is null
                                                                           AND spriden_pidm = Pagos_dia.PIDM
                                                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                                           AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                                                           and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                                    substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                                  from TBRACCD a1
                                                                                                                                  where a1.TBRACCD_DESC like '%TRANS%');
                                                                  
                                                                  EXCEPTION           
                                                                   WHEN OTHERS THEN NULL;
                                                                    Begin
                                                                        select '03'
                                                                        INTO vl_forma_pago
                                                                        from tbraccd a, spriden b
                                                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                                      from tbbdetc
                                                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                                       and TBBDETC_TYPE_IND = 'P')
                                                                           and tbraccd_pidm = spriden_pidm
                                                                           and spriden_change_ind is null
                                                                           AND spriden_pidm = Pagos_dia.PIDM
                                                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                                           AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                                                           and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                                    substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                                  from TBRACCD a1
                                                                                                                                  where a1.TBRACCD_DESC like '%RECLAS%');

                                                                EXCEPTION           
                                                                       WHEN OTHERS THEN NULL;

                                                                        BEGIN

                                                                        select '04'
                                                                        INTO vl_forma_pago
                                                                        from tbraccd a, spriden b
                                                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                                      from tbbdetc
                                                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                                       and TBBDETC_TYPE_IND = 'P')
                                                                           and tbraccd_pidm = spriden_pidm
                                                                           and spriden_change_ind is null
                                                                           AND spriden_pidm = Pagos_dia.PIDM
                                                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                                           AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                                                           and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                                    substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                                  from TBRACCD a1
                                                                                                                                  where a1.TBRACCD_DESC like '%TDC%');

                                                                         EXCEPTION           
                                                                           WHEN OTHERS THEN NULL;
                                                                             vl_forma_pago:='99';
                                                                        END;
                                                                        
                                                                END;
                                                                
                                                        END;
                                                        
                                               End;
                                               
                                            End;


                             If PAGOS_DIA.MONTO_PAGADO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO := PAGOS_DIA.MONTO_PAGADO * (-1);
                             End if; 
                            
                            ------------------- Seteo ---------------
                           
                            vl_total :=PAGOS_DIA.MONTO_PAGADO;
                            vl_fecha_pago := PAGOS_DIA.Fecha_pago;
                            vl_transaccion :=PAGOS_DIA.TRANSACCION;

                                
                            ----
                                If Pagos_dia.numero > 1 then 
                              --     dbms_output.put_line('Pagos_dia.numero:'||Pagos_dia.numero);

                                       vl_info_concepto :=  vl_info_concepto || 'L(+)';
                                       vl_impuesto := 'LIMPTRAS(+)';
                                    
                                   -- dbms_output.put_line('vl_info_concepto:'||vl_info_concepto ||'*'||'vl_impuesto:= '||vl_impuesto);
                                    
                                End if;
                                
                                
                                If vl_iva > 0 then
                                    vl_tasa_cuota_impuesto := '0.160000';
                                Elsif vl_iva = 0 then
                                    vl_tasa_cuota_impuesto := '0.000000';
                                End if;
                                
                                
                                If PAGOS_DIA.MONTO_PAGADO_CARGO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO_CARGO := PAGOS_DIA.MONTO_PAGADO_CARGO * (-1);
                                End if;
                                
                                                              
                                --------Concepto L(+)
                                vl_info_concepto := vl_info_concepto||Pagos_dia.numero||'|'||vl_prod_serv||'|'||vl_cantidad_concepto||'|'||vl_clave_unidad_concepto||'|'||vl_unidad_concepto||'|'||Pagos_dia.clave_cargo||'|'||Pagos_dia.DESCRIPCION_cargo||'|'||to_char((Pagos_dia.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'|'||to_char((Pagos_dia.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'|'||vl_descuento||chr(13);

                    --DBMS_OUTPUT.PUT_LINE('SUBTOTAL 222 ' ||vl_subtotal); 

                                     -- dbms_output.put_line('concepto***:'||vl_info_concepto );
                                --------Impuesto trasladado LIMPTRAS(+)
                                vl_impuesto := vl_impuesto ||Pagos_dia.numero||'|'||to_char((Pagos_dia.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'|'||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||vl_iva||chr(13);
                            --     dbms_output.put_line('inpuesto***:'||vl_impuesto );
                                
                               vl_info_concepto := vl_info_concepto||vl_impuesto;                                                                         
                                                                                                         
                                vl_total_imptras := vl_total_imptras + vl_iva;
                                

                                --------Impuesto retenido LIMPRET(+)
                                
                                vl_total_impret := 0;         
                                --vl_total_impret := vl_total_impret + pagos_dia.monto_iva;
                             --   vl_impuesto_ret := vl_impuesto_ret  ||Pagos_dia.numero||'|'||PAGOS_DIA.MONTO_PAGADO_CARGO||'|'||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||pagos_dia.monto_iva||'|';
                            
                                
                              --  DBMS_OUTPUT.PUT_LINE(vl_encabezado||'*'||vl_serie_folio||'*'||vl_entidad_receptor||'*'||vl_envio_correo||'*'||vl_dfiscales_utel||'*'||vl_dfiscales_receptor||'*'||vl_dfiscales_destinatario||'*'||vl_info_concepto||'*'||vl_impuesto||'*'||vl_impuesto_ret||'*'||vl_info_impuestos||'*'||vl_info_subtotal_imptras||'*'||vl_info_subtotal_impret||'*');

                         END LOOP Pagos_dia;

                        vl_subtotal := vl_subtotal - vn_iva;
                        
                      --  DBMS_OUTPUT.PUT_LINE('SUBTOTAL ' ||vl_subtotal); 
                        

                       ---------------- LLenamos Folio y SErie ENC(+)------------------
                         vl_serie_folio := vl_serie_folio||Sin_D_Fiscales.serie||'|'||vl_consecutivo||'|'||pago.Fecha_pago||'|'||vl_forma_pago||
                                                                                                       '|'||vl_condicion_pago||'|'||vl_tipo_cambio||'|'||vl_tipo_moneda||
                                                                                                       '|'||vl_metodo_pago||'|'||vl_lugar_expedicion||'|'||vl_tipo_comprobante||
                                                                                                       '|'||to_char(vl_subtotal, 'fm9999999990.00')||'|'||vl_descuento||
                                                                                                       '|'||to_char(pago.MONTO_PAGADO, 'fm9999999990.00')||'|'||vl_confirmacion||'|'||vl_tipo_documento;
                        
--                         If vl_secuencia > 1 then 
--                                    vl_info_concepto := vl_info_concepto ||'L(+)';
--                                    vl_impuesto :='LIMPTRAS(+)';
--                         End if;
                        
                        
                        vl_clave_cargo := null;
                        vl_descrip_cargo := null;
                        vl_secuencia := vl_secuencia +1;
                       
        --  DBMS_OUTPUT.PUT_LINE('Total del Monto '||vl_pago_total ||'*'||vl_pago_total_faltante);
                         
                      If vl_pago_total >  vl_pago_total_faltante then 
                             vl_pago_diferencia :=    vl_pago_total -  vl_pago_total_faltante;
                             
                     --    If vl_secuencia > 1 then 
                                    vl_info_concepto := vl_info_concepto;
                                    vl_impuesto :='LIMPTRAS(+)';
                      --   End if;
                                
                                        Begin    
                                             Select TBBDETC_DETAIL_CODE, TBBDETC_DESC
                                               Into  vl_clave_cargo, vl_descrip_cargo
                                             from tbbdetc
                                             Where TBBDETC_DETAIL_CODE = substr (Sin_D_Fiscales.matricula, 1,2)||'NN'
                                             And TBBDETC_DCAT_CODE = 'COL';
                                         Exception
                                         when Others then 
                                             vl_clave_cargo := null;
                                              vl_descrip_cargo := null;
                                        End;
                                       
                                        If  vl_clave_cargo is not null and vl_descrip_cargo is not null then                              
                                                vl_info_concepto := vl_info_concepto||vl_secuencia  ||'|'||
                                                                                                        vl_prod_serv||'|'||
                                                                                                        vl_cantidad_concepto||'|'||
                                                                                                        vl_clave_unidad_concepto||'|'||
                                                                                                        vl_unidad_concepto||'|'||
                                                                                                        vl_clave_cargo||'|'||
                                                                                                        vl_descrip_cargo||'|'||
                                                                                                        to_char(vl_pago_diferencia,'fm9999999990.00')||'|'||
                                                                                                        to_char(vl_pago_diferencia,'fm9999999990.00')||'|'||vl_descuento||chr(13);

                                              If substr (Sin_D_Fiscales.matricula, 1,2) = '01' then 
                                                --------Impuesto trasladado LIMPTRAS(+)
                                                vl_impuesto := vl_impuesto ||vl_secuencia ||'|'||
                                                                                            vl_pago_diferencia||'|'||
                                                                                            vl_impuesto_cod||'|'||
                                                                                            vl_tipo_factor_impuesto||'|'||
                                                                                            vl_tasa_cuota_impuesto||'|'||
                                                                                            to_char(to_char(vl_pago_diferencia*(0/100)),'fm9999999990.00')||chr(13);
                                                vl_total_imptras := vl_total_imptras + to_char(vl_pago_diferencia*(0/100));                                          
                                                
                                                vl_info_concepto := vl_info_concepto||vl_impuesto;    
                                                
                                                vl_total_impret := 0;                

                                              End if;
                                               
                                       End if;
                                       
                                       
                      End if;
                         
            --dbms_output.put_line('conceptoxxx:'||vl_info_concepto );

                         
                                 --vl_info_impuestos_comprobante TOTIMP(+)
                                        vl_info_impuestos := vl_info_impuestos||to_char(vl_total_impret,'fm9999999990.00')||'|'||to_char(vl_total_imptras,'fm9999999990.00');
                           
                                --Info_subtotal_imptras  IMPTRAS(+)
                                        vl_info_subtotal_imptras := vl_info_subtotal_imptras||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||to_char(vl_total_imptras,'fm9999999990.00');

                                               --Info_subtotal_impret IMPRET(+)
  --                                      vl_info_subtotal_impret := vl_info_subtotal_impret||vl_impuesto_cod||'|'||to_char(vl_total_impret,'fm9999999990.00');
                                        
                               --Flex_Header FH(+)
                                        vl_flex_header := vl_flex_header||vl_folio_interno_cl_fh||'|'||vl_folio_interno_fh||'|'||Sin_D_Fiscales.PIDM||chr(10)||
                                                                  vl_flex_header||vl_razon_social_cl_fh||'|'||vl_razon_social_fh||'|'||nvl(Sin_D_fiscales.Nombre, '.')||chr(10)||
                                                                  vl_flex_header||vl_metodo_pago_cl_fh||'|'||vl_metodo_pago_fh||'|'||nvl(pago.METODO_PAGO_CODE, '.')||chr(10)||
                                                                  vl_flex_header||vl_desc_metodo_pago_cl_fh||'|'||vl_desc_metodo_pago_fh||'|'||nvl(pago.METODO_PAGO, '.')||chr(10)||
                                                                  vl_flex_header||vl_id_pago_cl_fh||'|'||vl_id_pago_pago_fh||'|'||nvl(pago.Id_pago, '.')||chr(10)||
                                                                  vl_flex_header||vl_monto_cl_fh||'|'||vl_monto_fh||'|'||nvl(to_char(pago.MONTO_PAGADO,'fm9999999990.00'), '.')||chr(10)||
                                                                  vl_flex_header||vl_nivel_cl_fh||'|'||vl_nivel_fh||'|'||nvl(Sin_D_Fiscales.Nivel, '.')||chr(10)||
                                                                  vl_flex_header||vl_campus_cl_fh||'|'||vl_campus_fh||'|'||nvl(Sin_D_fiscales.Campus, '.')||chr(10)||
                                                                  vl_flex_header||vl_matricula_alumno_cl_fh||'|'||vl_matricula_alumno_fh||'|'||nvl(Sin_D_fiscales.MATRICULA, '.')||chr(10)||
                                                                  vl_flex_header||vl_fecha_pago_cl_fh||'|'||vl_fecha_pago_fh||'|'||nvl(pago.Fecha_pago, '.')||chr(10)||
                                                                  vl_flex_header||vl_referencia_cl_fh||'|'||vl_referencia_fh||'|'||nvl(Sin_D_fiscales.Referencia, '.')||chr(10)||
                                                                  vl_flex_header||vl_referencia_tipo_cl_fh||'|'||vl_referencia_tipo_fh||'|'||nvl(Sin_D_fiscales.Ref_tipo, '.')||chr(10)||
                                                                  vl_flex_header||vl_m_int_pago_tardio_cl_fh||'|'||vl_m_int_pago_tardio_fh||'|'||nvl(pago.monto_interes, '.')||chr(10)||
                                                                  vl_flex_header||vl_tipo_accesorio_cl_fh||'|'||vl_tipo_accesorio_fh||'|'||nvl(pago.tipo_accesorio, '.')||chr(10)||
                                                                  vl_flex_header||vl_monto_accesorio_cl_fh||'|'||vl_monto_accesorio_fh||'|'||nvl(pago.monto_accesorio, '.')||chr(10)||
                                                                  vl_flex_header||vl_cole_cl_fh||'|'||vl_cole_fh||'|'||nvl(pago.colegiaturas, '.')||chr(10)||
                                                                  vl_flex_header||vl_monto_cole_cl_fh||'|'||vl_monto_cole_fh||'|'||nvl(pago.monto_colegiatura, '.')||chr(10)||
                                                                  vl_flex_header||vl_nom_alumnos_cl_fh||'|'||vl_nom_alumnos_fh||'|'||nvl(Sin_D_Fiscales.Nombre_Alumno, '.')||chr(10)||
                                                                  vl_flex_header||vl_curp_cl_fh||'|'||vl_curp_fh||'|'||nvl(Sin_D_Fiscales.Curp, '.')||chr(10)||
                                                                  vl_flex_header||vl_rfc_cl_fh||'|'||vl_rfc_fh||'|'||nvl(Sin_D_Fiscales.RFC, '.')||chr(10)||
                                                                  vl_flex_header||vl_grado_cl_fh||'|'||vl_grado_fh||'|'||nvl(Sin_D_Fiscales.Grado, '.')||chr(10)||
                                                                  vl_flex_header||vl_nota_cl_fh||'|'||vl_nota_fh||'|'||nvl(vl_valor_nota_fh, '.')||chr(10)||
                                                                  vl_flex_header||vl_int_pago_tardio_cl_fh||'|'||vl_int_pago_tardio_fh||'|'||nvl(pago.intereses, '.');
                                                                  

                              
                                BEGIN
                                     INSERT INTO TZTFACT VALUES(
                                        Sin_D_Fiscales.PIDM
                                      , Sin_D_Fiscales.RFC
                                      , vl_total
                                      , 'FA'
                                      , NULL
                                      , NULL
                                      , sysdate
                                      ,vl_transaccion
                                      ,vl_encabezado||chr(10)||vl_serie_folio||chr(10)||vl_entidad_receptor||chr(10)||vl_envio_correo
                                      ||chr(10)||vl_dfiscales_utel||chr(10)||vl_dfiscales_receptor||chr(10)||vl_flex_header||chr(10)||vl_info_concepto||chr(10)
                                      --||vl_impuesto||chr(10)
                                      ||vl_info_impuestos||chr(10)||vl_info_subtotal_imptras||chr(10)||vl_complemento--||chr(10)||vl_info_subtotal_impret
                                      ,vl_consecutivo
                                      ,sin_d_fiscales.serie
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,vl_tipo_archivo
                                      ,vl_tipo_fact
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      
                                 );
                                 commit;
                                EXCEPTION
                                WHEN OTHERS THEN
                                 VL_ERROR := 'Se presento un error al insertar ' ||sqlerrm;
                                 --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
                                END;  


                                
                                  Begin
                                    
                                    Update tztdfut
                                    set TZTDFUT_FOLIO = vl_consecutivo
                                    Where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                                  Exception
                                    When Others then 
                                      VL_ERROR := 'Se presento un error al Actualizar ' ||sqlerrm;   
                                  End;
                         
                                 If vn_commit >= 500 then 
                                     commit;
                                     vn_commit :=0;
                                 End if;
                           
                                Commit;
            End Loop Pago;
         
      END LOOP;

   commit;
   --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
Exception
    when Others then
     ROLLBACK;
   --  DBMS_OUTPUT.PUT_LINE('Error General'||sqlerrm);
END;


FUNCTION f_facturacion_out RETURN PKG_FACTURACION.cursor_out 
           AS

           my_var long; 
           c_out PKG_FACTURACION.cursor_out;
                      
 BEGIN 


                      
                          open c_out            
                            FOR      
                            select TZTFACT_PIDM PIDM,
                                        TZTFACT_RFC RFC ,
                                        TZTFACT_TRAN_NUMBER TRAN,
                                        TZTFACT_TIPO_DOCTO T_DOCTO,
                                      DBMS_LOB.SUBSTR( TZTFACT_TEXT, length (TZTFACT_TEXT), 1) TXT
                                     --DBMS_lOB.SUBSTR( TZTFACT_TEXT, 3000, 1)  || DBMS_lOB.SUBSTR( TZTFACT_TEXT, 6000, 3001) TXT
                              from TZTFACT
                            where TZTFACT_TIPO = 'TXT'
                                and TZTFACT_RESPUESTA is null ;
                            

            RETURN (c_out);                 
                                                                    

END f_facturacion_out;


PROCEDURE sp_Respuesta_Factura(vn_pidm in number, vn_tran in number, vl_t_docto in varchar2, vn_respuesta in number, vl_error varchar2 )

  is 

  p_error varchar2(2500) := 'EXITO';
  
      BEGIN
                  Begin
                       Update TZTFACT
                       set TZTFACT_RESPUESTA = vn_respuesta
                                ,TZTFACT_ERROR = vl_error
                       where TZTFACT_PIDM = vn_pidm
                       and TZTFACT_TRAN_NUMBER = vn_tran
                       and TZTFACT_TIPO_DOCTO = vl_t_docto;
                       
                  Exception
                          when Others then
                              p_error:= 'Error en respuesta'||sqlerrm;
                  End;
     

          
      Exception 
      When Others then
         p_error := 'Se presento un Error General  ' ||sqlerrm;
      
    END sp_Respuesta_Factura;  
    
    
PROCEDURE sp_Datos_Facturacion_xml
IS

----Cabecero-----------
vl_cabecero varchar2(4000) :='<?xml version="1.0" encoding="UTF-8" ?>'; 
--'<?xml version="1.0" encoding="UTF-8"?>';

--Cabecero SOAP-------
vl_cabe_soap varchar2(4000) := '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:neon="http://neon.stoconsulting.com/NeonEmisionWS/NeonEmisionWS">';

--SOAP_Header------
vl_soap_header varchar2(4000) := '<soap:Header/>';
vl_soap_envelope varchar2(4000) := '</soap:Envelope>';

--SOAP_BOdy-------
vl_soap_body varchar2(4000) := '<soap:Body>';
vl_soap_body_cierre varchar2(4000) := '</soap:Body>';

--NEON_WS------
vl_neon_ws varchar2(4000) := '<neon:emitirWS>';
vl_neon_ws_cierre varchar2(4000) := '</neon:emitirWS>';

---- Se Arma el encazado de la factura <DOCUMENTOS>-------------
--vl_encabezado varchar2(4000):='<documentos>';
vl_consecutivo number :=0;
--vl_documentos_cierre varchar2(4000):='</documentos>';

-------------- LLenamos Folio y SErie <DOCUMENTO>
vl_serie_folio varchar2(2500):='<comprobante';
vl_forma_pago varchar2(100);
vl_condicion_pago varchar2(250):= 'Pago en una sola exhibicion';
vl_tipo_cambio number:=1;
vl_tipo_moneda varchar2(10):= 'MXN';
vl_metodo_pago varchar2(10):= 'PUE';
vl_lugar_expedicion varchar2(10):= '53370';
vl_tipo_comprobante varchar2(5):= 'I';
vl_descuento varchar2(15):='0.00';
vl_total number(16,2);
vl_confirmacion varchar2(2);
vl_tipo_documento number:=1;
vl_subtotal number(16,2);
vl_serie_folio_cierre varchar2(2500):='</comprobante>';
vl_serie_tag varchar2(250):='serie=';
vl_folio_tag varchar2(250):='folio=';
vl_fecha_tag varchar2(250):='fecha=';
vl_forma_pago_tag varchar2(250):='formaPago=';
vl_condiciones_pago_tag varchar2(250):='condicionesDePago=';
vl_tipo_cambio_tag varchar2(250):='tipoCambio=';
vl_moneda_tag varchar2(250):='moneda=';
vl_metodo_pago_tag varchar2(250):='metodoPago=';
vl_lugar_expedicion_tag varchar2(250):='lugarExpedicion=';
vl_tipo_comprobante_tag varchar2(250):='tipoComprobante=';
vl_subtotal_tag varchar2(250):='subTotal=';
vl_descuento_tag varchar2(250):='descuento=';
vl_total_tag varchar2(250):='total=';
vl_confirmacion_tag varchar2(250):='confirmacion=';
vl_tipo_comprobante_emi_tag varchar2(250):='tipoDocumento=';


-------------------Entidad_receptor <DOCUMENTO_ERP>
--vl_entidad_receptor varchar2(4000):='<documentoErp>';
--vl_entidad_receptor_cierre varchar2(4000):='</documentoErp>';
--vl_id_trx_erp_tag varchar2(250):='id_trx_erp=';

 
---------Envio por correo <ENVIO_CFDI>
vl_envio_correo varchar2(4000):='<envioCfdi';
vl_enviar_xml varchar2(15):='1';
vl_enviar_pdf varchar2(15):='1';
vl_enviar_zip varchar2(15):='1';
vl_xml_tag varchar2(250):='enviarXml=';
vl_pdf_tag varchar2(250):='enviarPdf=';
vl_zip_tag varchar2(250):='enviarZip=';
vl_email_tag varchar2(250):='emails=';
vl_envio_correo_cierre varchar2(4000):='/>';


------Datos fiscales utel <EMISOR>
vl_dfiscales_utel varchar2(4000):='<emisor';
vl_rfc_utel varchar2(15);
vl_razon_social_utel varchar2(250);
vl_regimen_fiscal varchar2(5):='601';
vl_id_emisor_sto number:=1;
vl_id_emisor_erp number:=1;
vl_dfiscales_utel_cierre varchar2(4000):='/>';
vl_rfc_tag varchar2(250):='rfc=';
vl_nombre_tag varchar2(250):='nombre=';
vl_regimen_fiscal_tag varchar2(250):='regimenFiscal=';
vl_id_emisor_sto_tag varchar2(250):='idEmisorSto=';
vl_id_emisor_erp_tag varchar2(250):='idEmisorErp=';


------Datos fiscales Alumno <RECEPTOR>
vl_dfiscales_receptor varchar2(4000):='<receptor';
vl_referencia_dom_receptor varchar2(255):=' ';
--vl_id_tipo_receptor varchar2(25):='0';
--vl_id_receptor_sto varchar2(25):='0';
vl_estatus_registro varchar2(25):='1';
vl_uso_cfdi varchar2(25):='D10';
vl_residencia_fiscal varchar2(25);
vl_num_reg_id_trib varchar2(25);
--vl_id_receptor_erp varchar2(25);
--vl_id_receptor_padre varchar2(25);
vl_cierre_receptor varchar2(4000):='/>';
vl_rfc_receptor_tag varchar2(250):='rfc=';
vl_nombre_receptor_tag varchar2(250):='nombre=';
vl_residencia_fiscal_tag varchar2(250):='residenciaFiscal=';
vl_num_reg_id_trib_tag varchar2(250):='numRegIdTrib=';
vl_uso_cfdi_tag varchar2(250):='usoCfdi=';
vl_id_receptor_sto_tag varchar2(250):='idReceptoSto=';
vl_id_receptor_erp_tag varchar2(250):='idReceptorErp=';
vl_numero_exterior_tag varchar2(250):='numeroExterior=';
vl_calle_tag varchar2(250):='calle=';
vl_numero_interior_tag varchar2(250):='numeroInterior=';
vl_colonia_tag varchar2(250):='colonia=';
vl_localidad_tag varchar2(250):='localidad=';
vl_referencia_tag varchar2(250):='referencia=';
vl_municipio_tag varchar2(250):='municipio=';
vl_estado_tag varchar2(250):='estado=';
vl_pais_tag varchar2(250):='pais=';
vl_codigo_postal_tag varchar2(250):='codigoPostal=';
vl_email_receptor_tag varchar2(250):='email=';
vl_id_tipo_receptor_tag varchar2(250):='idTipoReceptor=';
--vl_id_receptor_padre_tag varchar2(250):='id_receptor_padre=';
vl_estatus_registro_tag varchar2(250):='estatusRegistro=';
vl_id varchar2(25):='1';


------Datos fiscales Alumno <DESTINATARIO>
vl_dfiscales_destinatario varchar2(4000):='<destinatario>';
vl_referencia_dom_destinatario varchar2(255):=' ';
vl_id_tipo_destinatario varchar2(25):='0';
vl_id_destinarario_sto varchar2(25):='0';


-----Cabecera Conceptos
--vl_conceptos_cab varchar2(4000):='<conceptos>';
vl_conceptos_cierre varchar2(4000):='</conceptos>';

------Concepto <CONCEPTO>
vl_info_concepto CLOB :='<conceptos';
vl_num_linea number:=0;
vl_prod_serv varchar2(50);
vl_cantidad_concepto varchar2(10):='1';
vl_clave_unidad_concepto varchar2(10):='E48';
vl_unidad_concepto varchar2(50):='Servicio';
vl_importe_concepto number:=1;
vl_fecha_pago date;
vl_transaccion number :=0;
vl_info_concepto_cierre varchar2(4000) := '>';
vl_numero_linea_concepto_tag varchar2(250):='numeroLinea=';
vl_clave_prod_serv_tag varchar2(250):='claveProdServ=';
vl_cantidad_concepto_tag varchar2(250):='cantidad=';
vl_clave_unidad_concepto_tag varchar2(250):='claveUnidad=';
vl_unidad_concepto_tag varchar2(250):='unidad=';
vl_num_identificacion_tag varchar2(250):='numIdentificacion=';
vl_descripcion_concepto_tag varchar2(250):='descripcion=';
vl_valor_unitario_concepto_tag varchar2(250):='valorUnitario=';
vl_importe_concepto_tag varchar2(250):='importe=';
vl_descuento_concepto_tag varchar2(250):='descuento=';


----Cabecera Impuestos
vl_impuesto_cab varchar2(4000):='<impuestos>';
vl_impuestos_cierre varchar2(4000):='</impuestos>';
vl_impuestos_cierre1 varchar2(4000):='>';


--Impuesto trasladado <IMPUESTO>
vl_impuesto_tras_cab varchar2(4000):='<trasladados';
vl_impuesto varchar2(4000):='<impuesto>';
vl_impuesto_cod varchar2(10):='002';
vl_tipo_factor_impuesto varchar2(15):='Tasa';
vl_tasa_cuota_impuesto varchar2(15);
vl_impuesto_cierre varchar2(4000):='/>';
vl_impuesto_tras_cierre varchar2(4000):='</impuestos>';
vl_base_tag varchar2(250):='base=';
vl_impuesto_tag varchar2(250):='impuesto=';
vl_tipo_factor_tag varchar2(250):='tipoFactor=';
vl_tasa_o_cuota_tag varchar2(250):='tasaOCuota=';
vl_importe_tag varchar2(250):='importe=';


--Impuesto retenido <RETENIDOS>
vl_impuesto_ret_cab varchar2(4000):='<retenidos>';
vl_impuesto_ret varchar2(4000):='<impuesto>';
vl_base_impuesto_ret varchar2(25);
vl_impuesto_ret_cod varchar2(10):='002';
vl_tipo_factor_impuesto_ret varchar2(15):='Tasa';
vl_tasa_cuota_impuesto_ret varchar2(15);
vl_importe_impuesto_ret number(24,6);
vl_impuesto_ret_cierre varchar2(4000):='</retenidos>';


--Info_impuestos_comprobante <IMPUESTOS>
vl_info_impuestos varchar2(4000):='<impuestos';
vl_total_impret number(24,6);
vl_total_imptras number(24,6);
vl_info_impuestos_cierre varchar2(4000):='</impuestos>';
vl_totImpRet_tag varchar2(250):='totalImpuestosRetenidos=';
vl_totImpTras_tag varchar2(250):='totalImpuestosTrasladados=';


--Cabecera subtotales trasladados
vl_sub_imptras_cab varchar2(4000):='<trasladados>';
vl_sub_imptras_cierre varchar2(4000):='</trasladados>';


--Info_subtotal_imptras <IMPUESTO>
vl_info_subtotal_imptras varchar2(4000):='<trasladados';


--Cabecera subtotales retenidos
vl_sub_impret_cab varchar2(4000):='<retenidos>';
vl_sub_impret_cierre varchar2(4000):='</retenidos>';


--Info_subtotal_impret <IMPUESTO>
vl_info_subtotal_impret varchar2(4000):='<impuesto>';

vl_error varchar2(2500):='EXITO';
vl_contador number:=0;
vl_existe number:=0;


--Tipo_operacion---------
vl_tipo_operacion varchar2(4000):='<tipoOperacion>';
vl_valor_to varchar2(30):='asincrono';
vl_tipo_operacion_cierre varchar2(4000):='</tipoOperacion>';


--excedente
vl_pago_total number :=0;
vl_pago_total_faltante number :=0;
vl_pago_diferencia number :=0;
vl_clave_cargo varchar2(5):= null;
vl_descrip_cargo varchar2(90):= null;
vl_secuencia number:=0;


--Flex_Header FH(+)
vl_flex_headers_cab varchar2(4000):='<flexHeaders>';
vl_flex_header varchar2(4000):='<flexHeaders';
vl_folio_interno_cl_fh varchar2(50):='1';
vl_folio_interno_fh varchar2(255):='folioInterno';
vl_razon_social_cl_fh varchar2(50):='2';
vl_razon_social_fh varchar2(255):='razonSocial';
vl_metodo_pago_cl_fh varchar2(50):='3';
vl_metodo_pago_fh varchar2(255):='metodoDePago';
vl_desc_metodo_pago_cl_fh varchar2(50):='4';
vl_desc_metodo_pago_fh varchar2(255):='descripcionDeMetodoDePago';
vl_id_pago_cl_fh varchar2(50):='5';
vl_id_pago_pago_fh varchar2(255):='IdPago';
vl_monto_cl_fh varchar2(50):='6';
vl_monto_fh varchar2(255):='Monto';
vl_nivel_cl_fh varchar2(50):='7';
vl_nivel_fh varchar2(255):='Nivel';
vl_campus_cl_fh varchar2(50):='8';
vl_campus_fh varchar2(255):='Campus';
vl_matricula_alumno_cl_fh varchar2(50):='9';
vl_matricula_alumno_fh varchar2(255):='matriculaAlumno';
vl_fecha_pago_cl_fh varchar2(50):='10';
vl_fecha_pago_fh varchar2(255):='fechaPago';
vl_referencia_cl_fh varchar2(50):='11';
vl_referencia_fh varchar2(255):='Referencia';
vl_referencia_tipo_cl_fh varchar2(50):='12';
vl_referencia_tipo_fh varchar2(255):='ReferenciaTipo';
vl_m_int_pago_tardio_cl_fh varchar2(50):='13';
vl_m_int_pago_tardio_fh varchar2(255):='MontoInteresPagoTardio';
vl_m_valor_int_pag_tard_fh varchar2(255):= '.';
vl_tipo_accesorio_cl_fh varchar2(50):='14';
vl_tipo_accesorio_fh varchar2(255):='TipoAccesorio';
vl_monto_accesorio_cl_fh varchar2(50):='15';
vl_monto_accesorio_fh varchar2(255):='MontoAccesorio';
vl_cole_cl_fh varchar2(50):='16';
vl_cole_fh varchar2(255):='Colegiatura';
vl_valor_cole_fh varchar2(255):= '.';
vl_monto_cole_cl_fh varchar2(50):='17';
vl_monto_cole_fh varchar2(255):='MontoColegiatura';
vl_valor_monto_cole_fh varchar2(255):= '.';
vl_nom_alumnos_cl_fh varchar2(50):='18';
vl_nom_alumnos_fh varchar2(255):='NombreAlumno';
vl_curp_cl_fh varchar2(50):='19';
vl_curp_fh varchar2(255):='CURP';
vl_rfc_cl_fh varchar2(50):='20';
vl_rfc_fh varchar2(255):='RFC';
vl_grado_cl_fh varchar2(50):='21';
vl_grado_fh varchar2(255):='Grado';
vl_nota_cl_fh varchar2(50):='22';
vl_nota_fh varchar2(255):='Nota';
vl_valor_nota_fh varchar2(255):= '.';
vl_int_pago_tardio_cl_fh varchar2(50):='23';
vl_int_pago_tardio_fh varchar2(255):='InteresPagoTardio';
vl_valor_int_pag_tard_fh varchar2(255):= '.';
vl_flex_header_cierre varchar2(4000):='/>';
vl_flex_headers_cierre varchar2(4000):='</flexHeaders>';
vl_folio_int_cl_fh_tag varchar2(250):='clave=';
vl_folio_int_nom_fh_tag varchar2(250):='nombre=';
vl_folio_int_val_fh_tag varchar2(250):='valor=';
vl_raz_soc_cl_fh_tag varchar2(250):='clave=';
vl_raz_soc_nom_fh_tag varchar2(250):='nombre=';
vl_raz_soc_val_fh_tag varchar2(250):='valor=';
vl_met_pago_cl_fh_tag varchar2(250):='clave=';
vl_met_pago_nom_fh_tag varchar2(250):='nombre=';
vl_met_pago_val_fh_tag varchar2(250):='valor=';
vl_desc_met_pago_cl_fh_tag varchar2(250):='clave=';
vl_desc_met_pago_nom_fh_tag varchar2(250):='nombre=';
vl_desc_met_pago_val_fh_tag varchar2(250):='valor=';
vl_id_pago_cl_fh_tag varchar2(250):='clave=';
vl_id_pago_nom_fh_tag varchar2(250):='nombre=';
vl_id_pago_val_fh_tag varchar2(250):='valor=';
vl_monto_cl_fh_tag varchar2(250):='clave=';
vl_monto_nom_fh_tag varchar2(250):='nombre=';
vl_monto_val_fh_tag varchar2(250):='valor=';
vl_nivel_cl_fh_tag varchar2(250):='clave=';
vl_nivel_nom_fh_tag varchar2(250):='nombre=';
vl_nivel_val_fh_tag varchar2(250):='valor=';
vl_campus_cl_fh_tag varchar2(250):='clave=';
vl_campus_nom_fh_tag varchar2(250):='nombre=';
vl_campus_val_fh_tag varchar2(250):='valor=';
vl_mat_alumno_cl_fh_tag varchar2(250):='clave=';
vl_mat_alumno_nom_fh_tag varchar2(250):='nombre=';
vl_mat_alumno_val_fh_tag varchar2(250):='valor=';
vl_fecha_pago_cl_fh_tag varchar2(250):='clave=';
vl_fecha_pago_nom_fh_tag varchar2(250):='nombre=';
vl_fecha_pago_val_fh_tag varchar2(250):='valor=';
vl_referencia_cl_fh_tag varchar2(250):='clave=';
vl_referencia_nom_fh_tag varchar2(250):='nombre=';
vl_referencia_val_fh_tag varchar2(250):='valor=';
vl_referencia_tipo_cl_fh_tag varchar2(250):='clave=';
vl_referencia_tipo_nom_fh_tag varchar2(250):='nombre=';
vl_referencia_tipo_val_fh_tag varchar2(250):='valor=';
vl_m_int_pag_tard_cl_fh_tag varchar2(250):='clave=';
vl_m_int_pag_tard_nom_fh_tag varchar2(250):='nombre=';
vl_m_int_pag_tard_val_fh_tag varchar2(250):='valor=';
vl_tipo_accesorio_cl_fh_tag varchar2(250):='clave=';
vl_tipo_accesorio_nom_fh_tag varchar2(250):='nombre=';
vl_tipo_accesorio_val_fh_tag varchar2(250):='valor=';
vl_monto_accesorio_cl_fh_tag varchar2(250):='clave=';
vl_monto_accesorio_nom_fh_tag varchar2(250):='nombre=';
vl_monto_accesorio_val_fh_tag varchar2(250):='valor=';
vl_cole_cl_fh_tag varchar2(250):='clave=';
vl_cole_nom_fh_tag varchar2(250):='nombre=';
vl_cole_val_fh_tag varchar2(250):='valor=';
vl_monto_cole_cl_fh_tag varchar2(250):='clave=';
vl_monto_cole_nom_fh_tag varchar2(250):='nombre=';
vl_monto_cole_val_fh_tag varchar2(250):='valor=';
vl_nom_alumnos_cl_fh_tag varchar2(250):='clave=';
vl_nom_alumnos_nom_fh_tag varchar2(250):='nombre=';
vl_nom_alumnos_val_fh_tag varchar2(250):='valor=';
vl_curp_cl_fh_tag varchar2(250):='clave=';
vl_curp_nom_fh_tag varchar2(250):='nombre=';
vl_curp_val_fh_tag varchar2(250):='valor=';
vl_rfc_cl_fh_tag varchar2(250):='clave=';
vl_rfc_nom_fh_tag varchar2(250):='nombre=';
vl_rfc_val_fh_tag varchar2(250):='valor=';
vl_grado_cl_fh_tag varchar2(250):='clave=';
vl_grado_nom_fh_tag varchar2(250):='nombre=';
vl_grado_val_fh_tag varchar2(250):='valor=';
vl_nota_cl_fh_tag varchar2(250):='clave=';
vl_nota_nom_fh_tag varchar2(250):='nombre=';
vl_nota_val_fh_tag varchar2(250):='valor=';
vl_int_pag_tard_cl_fh_tag varchar2(250):='clave=';
vl_int_pag_tard_nom_fh_tag varchar2(250):='nombre=';
vl_int_pag_tard_val_fh_tag varchar2(250):='valor=';


------ Contadoor de registros
vn_commit  number :=0;

---- Manejo del IVA
vn_iva number:=0;
vl_iva number :=0;


---- Tipo_Archivo
vl_tipo_archivo varchar2(50):='XML';
vl_tipo_fact varchar2(50):='Con_D_facturacion';

----Complemento IEDU(+)
vl_complemento varchar2(4000):='<InstEducativas>';
vl_rvoe_comp varchar2(25):='<autrvoe>';
vl_rvoe_comp_cierre varchar2(25):='</autrvoe>';
vl_curp_comp varchar2(25):='<curp>';
vl_curp_comp_cierre varchar2(25):='</curp>';
vl_niveledu_comp varchar2(25):='<nivelEducativo>';
vl_niveledu_comp_cierre varchar2(25):='</nivelEducativo>';
vl_nomalum_comp varchar2(25):='<nombreAlumno>';
vl_nomalum_comp_cierre varchar2(25):='</nombreAlumno>';
vl_numlinea_comp varchar2(25):='<numeroLinea>';
vl_numlinea_comp_cierre varchar2(25):='</numeroLinea>';
vl_rfc_comp varchar2(25):='<rfcPago>';
vl_rfc_comp_cierre varchar2(25):='</rfcPago>';
vl_version_comp varchar2(25):='<version>';
vl_version_comp_cierre varchar2(25):='</version>';
vl_complemento_cierre varchar2(4000):='</InstEducativas>';
vl_d_linea_comp varchar2(25):=1;
vl_d_version_comp varchar2(10):='1.0';
vl_d_nivel_comp varchar2(25):='Profesional Técnico';

vl_estatus_timbrado number :=0;
--   
BEGIN
   FOR D_Fiscales
              IN (  WITH CURP AS (
                                            select 
                                                SPRIDEN_PIDM PIDM,
                                                GORADID_ADDITIONAL_ID CURP
                                              from SPRIDEN
                                              left join GORADID on SPRIDEN_PIDM = GORADID_PIDM
                                              where GORADID_ADID_CODE = 'CURP'
                                              )
                        SELECT DISTINCT SPREMRG_PIDM PIDM,
                                           SPRIDEN_ID MATRICULA,
                                           replace(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME Nombre_Alumno,
                                           SUBSTR(spriden_id,5) ID,
                                           SPREMRG_LAST_NAME Nombre,
                                           upper(SPREMRG_MI) RFC,
                                           REGEXP_SUBSTR(SPREMRG_STREET_LINE1, '[^#"]+', 1, 1) Calle,
                                           NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#[^#]*'),2), 0) Num_Ext,
                                           NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#Int[^*]*'),2), 0) Num_Int,
                                           SPREMRG_STREET_LINE3 Colonia,
                                           SPREMRG_CITY AS Municipio,
                                           SPREMRG_ZIP AS CP,                                               
                                           SPREMRG_STAT_CODE Estado,
                                           SPREMRG_NATN_CODE AS Pais,
                                           'oscar.gonzalez@utel.edu.mx' Email,
                                           --GOREMAL_EMAIL_ADDRESS Email,
                                            CASE
                                                 when GORADID_ADID_CODE = 'REFH' then
                                                 'BH'
                                                 when GORADID_ADID_CODE = 'REFS' then
                                                 'BS'
                                                 when GORADID_ADID_CODE = 'REFU' then 
                                                 'UI'
                                            end Serie,
                                            SZVCAMP_CAMP_CODE Campus,
                                            GORADID_ADDITIONAL_ID Referencia,
                                            GORADID_ADID_CODE Ref_tipo,
                                            STVLEVL_DESC Nivel,
                                            CURP.CURP Curp,
                                            b.SARADAP_DEGC_CODE_1 Grado,
                                            SZTDTEC_NUM_RVOE RVOE_num,
                                            SZTDTEC_CLVE_RVOE RVOE_clave
                                      FROM SPREMRG
                                      left join SPRIDEN on SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                      left outer join SARADAP b on SPREMRG_PIDM = b.SARADAP_PIDM
                                      left outer join SORLCUR c on SPREMRG_PIDM = SORLCUR_PIDM
                                      left join STVLEVL on b.SARADAP_LEVL_CODE = STVLEVL_CODE
                                      left join GOREMAL on SPREMRG_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                                      left join GORADID on GORADID_PIDM = SPREMRG_PIDM 
                                                  and GORADID_ADID_CODE LIKE 'REF%'
                                      join SZVCAMP on szvcamp_camp_alt_code=substr(SPRIDEN_ID,1,2)
                                      left join CURP on SPREMRG_PIDM = CURP.PIDM
                                      left outer join SZTDTEC on c.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                            and c.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                            and c.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                     WHERE SPREMRG_MI IS NOT NULL
                                           AND SPREMRG_PRIORITY IN
                                                  (SELECT MAX (s1.SPREMRG_PRIORITY)
                                                     FROM SPREMRG s1
                                                    WHERE SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                          AND SPREMRG_PRIORITY = s1.SPREMRG_PRIORITY)
                                            and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                            and c.SORLCUR_SEQNO IN (SELECT MAX(c.SORLCUR_SEQNO)
                                                                                     FROM SORLCUR c1
                                                                                     WHERE c.SORLCUR_PIDM = c1.SORLCUR_PIDM)
                                          and SPREMRG_MI is not null
--                                  and spriden_pidm = 25803
                                  ORDER BY SPREMRG_PIDM
                                  
                                  )
   LOOP
            vl_pago_total:=0;
            vn_commit :=0;
           For pago in (
                               with accesorios as(
                                                        select distinct
                                                          TZTCRTE_PIDM Pidm,
                                                          TZTCRTE_LEVL as Nivel,
                                                          TZTCRTE_CAMP as Campus,
                                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                                          TZTCRTE_CAMPO19 as accesorios,
                                                          to_char(sum (TZTCRTE_CAMPO20),'fm9999999990.00') as Monto_accesorios,
                                                          TZTCRTE_CAMPO15 as colegiaturas,
                                                          to_char(sum (TZTCRTE_CAMPO16),'fm9999999990.00') as Monto_colegiaturas,
                                                          TZTCRTE_CAMPO17 as intereses,
                                                          to_char(sum (TZTCRTE_CAMPO18),'fm9999999990.00') as Monto_intereses,                                                     
                                                          TZTCRTE_CAMPO26 as Categoria,
                                                          TZTCRTE_CAMPO10 as Secuencia
                                                        from TZTCRTE
                                                        where  TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
--                                                               and TZTCRTE_CAMPO26 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                                        group by TZTCRTE_PIDM, TZTCRTE_LEVL, TZTCRTE_CAMP, TZTCRTE_CAMPO11, TZTCRTE_CAMPO15, TZTCRTE_CAMPO17, TZTCRTE_CAMPO19, TZTCRTE_CAMPO26, TZTCRTE_CAMPO10
                                                            )
                                    SELECT DISTINCT 
                                            TBRACCD_PIDM PIDM,
                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                            substr(TBRACCD_DETAIL_CODE,1,2) FORMA_PAGO,
                                            TBRACCD_DETAIL_CODE METODO_PAGO_CODE,
                                            TBRACCD_DESC METODO_PAGO,
                                            to_char (TBRACCD_EFFECTIVE_DATE,'RRRR-MM-DD"T"HH24:MI:SS') Fecha_pago,
                                            TBRACCD_PAYMENT_ID Id_pago,
                                            accesorios.accesorios tipo_accesorio,
                                            accesorios.Monto_accesorios monto_accesorio,
                                            accesorios.colegiaturas colegiaturas,
                                            accesorios.Monto_colegiaturas monto_colegiatura,
                                            accesorios.intereses intereses,
                                            accesorios.Monto_intereses monto_interes
                                    FROM TBRACCD
                                    LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                           LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                    left join accesorios on tbraccd_pidm = accesorios.Pidm
--                                            and TBRACCD_TRAN_NUMBER = accesorios.secuencia
                                    WHERE TBBDETC_TYPE_IND = 'P'
                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                            AND TBRACCD_PIDM= D_Fiscales.pidm
                                            AND TRUNC (TBRACCD_EFFECTIVE_DATE) = accesorios.Fecha_Pago
                                             AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                              and rownum = 1
                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                        FROM TZTFACT
                                                                                                        WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                        ORDER BY TBRACCD_PIDM, 2 asc
                            )
            loop

             If pago.MONTO_PAGADO like '-%' then
                    pago.MONTO_PAGADO := pago.MONTO_PAGADO * (-1);
             End if;                            
             
             
                  vn_commit := vn_commit +1;
                  vl_pago_total := pago.MONTO_PAGADO;
                  vl_subtotal := pago.MONTO_PAGADO;
              
                vl_num_linea:=0;
                vl_rfc_utel:= null; 
                vl_razon_social_utel:= null; 
                vl_prod_serv := null;      
                 vl_consecutivo :=0;
                vl_complemento := '<InstEducativas>';

                --vl_encabezado :='<documentos>';
                --vl_entidad_receptor :='<documentoErp>';
                vl_envio_correo :='<envioCfdi';
                vl_dfiscales_utel :='<emisor';
                vl_dfiscales_receptor :='<receptor';
                vl_dfiscales_destinatario := '<destinatario>';
                
                     --Emisor_STO
                        If d_fiscales.serie = 'BH' then
                            vl_id_emisor_sto := 1;
                        Elsif d_fiscales.serie = 'BS' then
                            vl_id_emisor_sto := 2;
                        End if;
                        
                      --Emisor_ERP
                         If d_fiscales.serie = 'BH' then
                            vl_id_emisor_erp := 1;
                        Elsif d_fiscales.serie = 'BS' then
                            vl_id_emisor_erp := 2;
                        End if;
                        
                       --Nivel_Complemento
                         If d_fiscales.serie = 'BH' then
                            vl_d_nivel_comp := 'Profesional Técnico';
                        Elsif d_fiscales.serie = 'BS' then
                            vl_d_nivel_comp := Null;
                        End if;

            --- Se obtiene el numero de consecutivo por empresa 
                    Begin

                    select nvl (max (TZTDFUT_FOLIO), 0)+1
                        Into  vl_consecutivo
                    from tztdfut
                    where TZTDFUT_SERIE = D_Fiscales.serie;
                    Exception
                    When Others then 
                        vl_consecutivo :=1;
                    End;

                   Begin
                        select 
                            TZTDFUT_RFC RFC,
                            TZTDFUT_RAZON_SOC RAZON_SOCIAL,
                            TZTDFUT_PROD_SERV_CODE
                        Into vl_rfc_utel, vl_razon_social_utel, vl_prod_serv
                        from TZTDFUT
                        where TZTDFUT_SERIE = D_Fiscales.serie;
                   exception
                   when others then
                        vl_error:= 'Error al Recuperer los datos Fiscales de la empresa ' ||sqlerrm;
                   End;



                ----Cabecero xml--------
                vl_cabecero := vl_cabecero;

                ---- Se Arma el encazado de la factura <DOCUMENTOS>-------------
                --vl_encabezado := vl_encabezado ||vl_consecutivo;
                
                --------Datos fiscales utel <EMISOR>
                vl_dfiscales_utel := vl_dfiscales_utel||' '||vl_rfc_tag||'"'||vl_rfc_utel||'"'||' '||vl_nombre_tag||'"'||vl_razon_social_utel||'"'||' '||vl_regimen_fiscal_tag||'"'||vl_regimen_fiscal||'"'||' '||vl_id_emisor_sto_tag||'"'||vl_id_emisor_sto||'"'||' '||vl_id_emisor_erp_tag||'"'||vl_id_emisor_erp||'"'||' '||vl_dfiscales_utel_cierre;
                
                -----Se envia por correo <ENVIO_CFDI>
                vl_envio_correo := vl_envio_correo||' '||vl_xml_tag||'"'||vl_enviar_xml||'"'||' '||vl_pdf_tag||'"'||vl_enviar_pdf||'"'||' '||vl_zip_tag||'"'||vl_enviar_zip||'"'||' '||vl_email_tag||'"'||D_Fiscales.Email||'"'||' '||vl_envio_correo_cierre;
                
                ----------Datos de entidad del receptor <DOCUMENTO_ERP>
                --vl_entidad_receptor := vl_entidad_receptor||vl_id_trx_erp_tag||'"'||vl_consecutivo||'"';
                
                --------Datos fiscales alumno <RECEPTOR>
                vl_dfiscales_receptor := vl_dfiscales_receptor||' '||vl_rfc_receptor_tag||'"'||D_Fiscales.RFC||'"'||' '||vl_nombre_receptor_tag||'"'||D_Fiscales.Nombre||'"'||' '||vl_residencia_fiscal_tag||'"'||vl_residencia_fiscal||'"'||' '||vl_num_reg_id_trib_tag||'"'||vl_num_reg_id_trib||'"'||' '||vl_uso_cfdi_tag||'"'||vl_uso_cfdi||'"'||' '||vl_id_receptor_sto_tag||'"'||D_Fiscales.PIDM||'"'||' '||vl_id_receptor_erp_tag||'"'||D_Fiscales.PIDM||'"'||' '||vl_numero_exterior_tag||'"'||D_Fiscales.Num_Ext||'"'||' '||vl_calle_tag||'"'||D_Fiscales.Calle||'"'||' '||vl_numero_interior_tag||'"'||D_Fiscales.Num_Int||'"'||' '||vl_colonia_tag||'"'||D_Fiscales.Colonia||'"'||' '||vl_localidad_tag||'"'||D_Fiscales.Municipio||'"'||' '||vl_referencia_tag||'"'||vl_referencia_dom_receptor||'"'||' '||vl_municipio_tag||'"'||D_Fiscales.Municipio||'"'||' '||vl_estado_tag||'"'||D_Fiscales.Estado||'"'||' '||vl_pais_tag||'"'||D_Fiscales.Pais||'"'||' '||vl_codigo_postal_tag||'"'||D_Fiscales.CP||'"'||' '||vl_email_receptor_tag||'"'||D_Fiscales.Email||'"'||' '||vl_id_tipo_receptor_tag||'"'||D_Fiscales.ID||'"'||' '||vl_estatus_registro_tag||'"'||vl_estatus_registro||'"'||' '||vl_cierre_receptor;

                --------Datos fiscales alumno <DESTINATARIO>
                vl_dfiscales_destinatario := vl_dfiscales_destinatario||D_Fiscales.RFC||'|'||D_Fiscales.Nombre||'|'||vl_uso_cfdi||'|'||D_Fiscales.ID||'|'||D_Fiscales.ID||'|'||D_Fiscales.Num_Ext||'|'||D_Fiscales.Calle||'|'||D_Fiscales.Num_Int||'|'||D_Fiscales.Colonia||'|'||D_Fiscales.Municipio||'|'||vl_referencia_dom_destinatario||'|'||D_Fiscales.Municipio||'|'||D_Fiscales.Estado||'|'||D_Fiscales.Pais||'|'||D_Fiscales.CP||'|'||D_Fiscales.Email||'|'||D_Fiscales.ID||'|'||vl_estatus_registro||'|';

                ----Complemento IEDU(+)
                vl_complemento := vl_complemento||chr(10)||chr(9)||
                                            vl_rvoe_comp||nvl(D_Fiscales.RVOE_clave, '.')||vl_rvoe_comp_cierre||chr(10)||chr(9)||
                                            vl_curp_comp||nvl(D_Fiscales.Curp, '.')||vl_curp_comp_cierre||chr(10)||chr(9)||
                                            vl_niveledu_comp||vl_d_nivel_comp||vl_niveledu_comp_cierre||chr(10)||chr(9)||
                                            vl_nomalum_comp||nvl(D_Fiscales.Nombre_Alumno, '.')||vl_nomalum_comp_cierre||chr(10)||chr(9)||
                                            vl_numlinea_comp||vl_d_linea_comp||vl_numlinea_comp_cierre||chr(10)||chr(9)||
                                            vl_rfc_comp||nvl(D_Fiscales.RFC, '.')||vl_rfc_comp_cierre||chr(10)||chr(9)||
                                            vl_version_comp||vl_d_version_comp||vl_version_comp_cierre||chr(10)||chr(9)||
                vl_complemento_cierre;

                                    

                            vl_serie_folio :='<comprobante';
                            vl_info_concepto :='<conceptos';
                            vl_impuesto :='<impuesto>';
                            vl_impuesto_ret :='<retenidos>';
                            vl_info_impuestos :='<impuestos';
                            vl_info_subtotal_imptras :='<trasladados';
                            vl_info_subtotal_impret :='<impuesto>';
                            vl_flex_header :='<flexHeaders';
                                               
                            vl_fecha_pago := null;
                            vl_transaccion  :=0;
                            vl_total_impret :=0;
                            vl_total_imptras :=0;
                            vl_contador :=0;
                                    

                               ---------------- LLenamos Folio y SErie <DOCUMENTO>------------------
                                --vl_serie_folio := vl_serie_folio||' '||vl_serie_tag||'"'||d_fiscales.serie||'"'||' '||vl_folio_tag||'"'||vl_consecutivo||'"'||' '||vl_fecha_tag||'"'||pago.Fecha_pago||'"'||' '||vl_forma_pago_tag||'"'||vl_forma_pago||'"'||' '||vl_condiciones_pago_tag||'"'||vl_condicion_pago||'"'||' '||vl_tipo_cambio_tag||'"'||vl_tipo_cambio||'"'||' '||vl_moneda_tag||'"'||vl_tipo_moneda||'"'||' '||vl_metodo_pago_tag||'"'||vl_metodo_pago||'"'||' '||vl_lugar_expedicion_tag||'"'||vl_lugar_expedicion||'"'||' '||vl_tipo_comprobante_tag||'"'||vl_tipo_comprobante||'"'||' '||vl_subtotal_tag||'"'||vl_subtotal||'"'||' '||vl_descuento_tag||'"'||vl_descuento||'"'||' '||vl_total_tag||'"'||pago.MONTO_PAGADO||'"'||' '||vl_confirmacion_tag||'"'||vl_confirmacion||'"'||' '||vl_tipo_comprobante_emi_tag||'"'||vl_tipo_documento||'"'||' '||'>';

                        vl_pago_total_faltante:=0;
                        vl_secuencia :=0;
                        vn_iva :=0;
                        vl_iva :=0;

                               FOR Pagos_dia
                                        IN (
                                              with cargo as (
                                                                    select distinct 
                                                                        c.TVRACCD_PIDM PIDM, 
                                                                        c.TVRACCD_DETAIL_CODE cargo, 
                                                                       -- c.TVRACCD_TRAN_NUMBER transa, 
                                                                          c.TVRACCD_ACCD_TRAN_NUMBER transa, 
                                                                        c.TVRACCD_DESC descripcion, 
                                                                        to_char(c.TVRACCD_AMOUNT,'fm9999999990.00') MONTO_CARGO,
                                                                        Monto_Iv Monto_IVAS
                                                                    from TVRACCD c, TBBDETC a, (
                                                                                                                select distinct 
                                                                                                                        to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                                                from tvraccd i 
                                                                                                                    where 1=1
                                                                                                                    and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                                                ) monto_iva
                                                                    where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                                        and a.TBBDETC_TYPE_IND = 'C'
                                                                        and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                                        and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                                        and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
--                                                                        and c.TVRACCD_pidm = 25
                                                                    )
                                                        SELECT DISTINCT 
                                                            TBRACCD_PIDM PIDM,
                                                            SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                                            to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                                           nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                                            to_char(TBRACCD_EFFECTIVE_DATE, 'dd/mm/rrrr') Fecha_pago,
                                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                                            TBBDETC_DESC DESCRIPCION,
                                                           nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                                           nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                                           cargo.transa,
                                                    --        Monto_IVAS monto_iva,
                                                            ROW_NUMBER() OVER(PARTITION BY TBRACCD_TRAN_NUMBER ORDER BY TBRACCD_EFFECTIVE_DATE) numero
                                                        FROM TBRACCD
                                                        left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                                        LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                        LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                                            AND TBRAPPL_REAPPL_IND IS NULL
                                                        left join cargo on cargo.pidm = tbraccd_pidm
                                                           and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                                        WHERE     TBBDETC_TYPE_IND = 'P'
                                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                                            AND TBRACCD_PIDM= pago.pidm
                                                            And TBRACCD_TRAN_NUMBER = pago.TRANSACCION
                                                            AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                    FROM TZTFACT
                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                                --           AND TBRACCD_PIDM= 25 
                                                        ORDER BY TBRACCD_PIDM,13 asc
                                            )            
                         LOOP
                            
                            
                            BEGIN
                                    
                                                select distinct  Monto_Iv Monto_IVAS
                                                    INTO vl_iva
                                                from TVRACCD c, TBBDETC a, (
                                                                                            select distinct 
                                                                                                    to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                            from tvraccd i 
                                                                                                where 1=1
                                                                                                and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                            ) monto_iva
                                                where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                    and a.TBBDETC_TYPE_IND = 'C'
                                                    and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                    and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                    and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
                                                    And  c.TVRACCD_PIDM= Pagos_dia.PIDM
                                                    and  c.TVRACCD_ACCD_TRAN_NUMBER = Pagos_dia.transa;
                                        
                                 EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_iva:='0.00';
                                 End;
                            
                               --DBMS_OUTPUT.PUT_LINE('Monta IVA'||vl_iva);
                            
                                  vl_contador := vl_contador +1;
                                  vl_pago_total_faltante := vl_pago_total_faltante + Pagos_dia.MONTO_PAGADO_CARGO;
                                  vl_secuencia :=Pagos_dia.numero;
                                  vn_iva :=  vn_iva + vl_iva;


                                    BEGIN

                                        select '01'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                    substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                  from TBRACCD a1
                                                                                                  where a1.TBRACCD_DESC like '%EFEC%');
                                     
                                     EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_forma_pago:='99';
                                            BEGIN
                                             
                                                 select '02'
                                                INTO vl_forma_pago
                                                from tbraccd a, spriden b
                                                where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                              from tbbdetc
                                                                                              where TBBDETC_DCAT_CODE = 'CSH'
                                                                                               and TBBDETC_TYPE_IND = 'P')
                                                   and tbraccd_pidm = spriden_pidm
                                                   and spriden_change_ind is null
                                                   AND spriden_pidm = Pagos_dia.PIDM
                                                   AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                   and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                            substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                          from TBRACCD a1
                                                                                                          where a1.TBRACCD_DESC like '%CHEQUE%');
                                                 
                                                 
                                                 EXCEPTION           
                                                   WHEN OTHERS THEN NULL;
                                                     vl_forma_pago:='99';
                                                    BEGIN

                                                            select '03'
                                                            INTO vl_forma_pago
                                                            from tbraccd a, spriden b
                                                            where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                          from tbbdetc
                                                                                                          where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                           and TBBDETC_TYPE_IND = 'P')
                                                               and tbraccd_pidm = spriden_pidm
                                                               and spriden_change_ind is null
                                                               AND spriden_pidm = Pagos_dia.PIDM
                                                               AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                               and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                        substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                      from TBRACCD a1
                                                                                                                      where a1.TBRACCD_DESC like '%TRANS%');

                                                         EXCEPTION           
                                                           WHEN OTHERS THEN NULL;
                                                            Begin
                                                                select '03'
                                                                INTO vl_forma_pago
                                                                from tbraccd a, spriden b
                                                                where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                              from tbbdetc
                                                                                                              where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                               and TBBDETC_TYPE_IND = 'P')
                                                                   and tbraccd_pidm = spriden_pidm
                                                                   and spriden_change_ind is null
                                                                   AND spriden_pidm = Pagos_dia.PIDM
                                                                   AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                                   and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                            substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                          from TBRACCD a1
                                                                                                                          where a1.TBRACCD_DESC like '%RECLAS%');
                                                            Exception
                                                                When Others then                                                            

                                                                BEGIN

                                                                        select '04'
                                                                    INTO vl_forma_pago
                                                                    from tbraccd a, spriden b
                                                                    where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                                  from tbbdetc
                                                                                                                  where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                                   and TBBDETC_TYPE_IND = 'P')
                                                                       and tbraccd_pidm = spriden_pidm
                                                                       and spriden_change_ind is null
                                                                       AND spriden_pidm = Pagos_dia.PIDM
                                                                       AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                                       and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                                substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                              from TBRACCD a1
                                                                                                                              where a1.TBRACCD_DESC like '%TDC%');
                                                                     
                                                                     EXCEPTION           
                                                                       WHEN OTHERS THEN NULL;
                                                                         vl_forma_pago:='99';
                                                                END;
                                                            
                                                            END;   
                                                    END;
                                            END;
                                    END;


                                If PAGOS_DIA.MONTO_PAGADO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO := PAGOS_DIA.MONTO_PAGADO * (-1);
                                End if; 
                            
                            ------------------- Seteo ---------------
                           
                            vl_total :=PAGOS_DIA.MONTO_PAGADO;
                            vl_fecha_pago := PAGOS_DIA.Fecha_pago;
                            vl_transaccion :=PAGOS_DIA.TRANSACCION;



                            ----
                                If Pagos_dia.numero > 1 then 
                                    vl_info_concepto := vl_info_concepto||'<conceptos';
                                    vl_impuesto :='<impuesto>';
                                End if;
                                
                                
                                If vl_iva > 0 then
                                    vl_tasa_cuota_impuesto := '0.160000';
                                Elsif vl_iva = 0 then
                                    vl_tasa_cuota_impuesto := '0.000000';
                                End if;
                                
                                
                                If PAGOS_DIA.MONTO_PAGADO_CARGO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO_CARGO := PAGOS_DIA.MONTO_PAGADO_CARGO * (-1);
                                End if;
                                
                                ------Cabecera Conceptos
                                --vl_conceptos_cab := vl_conceptos_cab;

                                --------Concepto <CONCEPTO>
                                vl_info_concepto := vl_info_concepto||' '||vl_clave_prod_serv_tag||'"'||vl_prod_serv||'"'||' '||vl_cantidad_concepto_tag||'"'||vl_cantidad_concepto||'"'||' '||vl_clave_unidad_concepto_tag||'"'||vl_clave_unidad_concepto||'"'||' '||vl_unidad_concepto_tag||'"'||vl_unidad_concepto||'"'||' '||vl_num_identificacion_tag||'"'||Pagos_dia.clave_cargo||'"'||' '||vl_descripcion_concepto_tag||'"'||Pagos_dia.DESCRIPCION_cargo||'"'||' '||vl_valor_unitario_concepto_tag||'"'||to_char((PAGOS_DIA.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'"'||' '||vl_importe_concepto_tag||'"'||to_char((PAGOS_DIA.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'"'||' '||vl_descuento_concepto_tag||'"'||vl_descuento||'"'||vl_info_concepto_cierre;

                                ----Impuesto_trasladado_cabecera
                                vl_impuesto_tras_cab := vl_impuesto_tras_cab;
                                
                                --------Impuesto trasladado <IMPUESTO>
                                vl_impuesto := vl_impuesto_tras_cab ||' '||vl_base_tag||'"'||to_char((PAGOS_DIA.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'"'||' '||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||vl_importe_tag||'"'||vl_iva||'"'||vl_impuesto_cierre;

                                vl_info_concepto := vl_info_concepto||vl_impuesto_cab||vl_impuesto||vl_impuestos_cierre||vl_conceptos_cierre;                     
                                
                                                                                                                                         
                                vl_total_imptras := vl_total_imptras + vl_iva;
                                
                                ----Impuesto_trasladado_cierre
                                vl_impuesto_tras_cierre := vl_impuesto_tras_cierre;
                                

                                ------Impuesto_retenido_cabecera
                                --vl_impuesto_ret_cab := vl_impuesto_ret_cab;

                                --------Impuesto retenido <RETENIDOS>
                                
                                vl_total_impret := 0;                
                                --vl_total_impret := vl_total_impret + pagos_dia.monto_iva;
                             --   vl_impuesto_ret := vl_impuesto_ret  ||Pagos_dia.numero||'|'||PAGOS_DIA.MONTO_PAGADO_CARGO||'|'||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||pagos_dia.monto_iva||'|';


                                ------Impuesto_retenido_cierre
                                --vl_impuesto_ret_cierre := vl_impuesto_ret_cierre;
                           
                                --DBMS_OUTPUT.PUT_LINE(vl_encabezado||'*'||vl_serie_folio||'*'||vl_entidad_receptor||'*'||vl_envio_correo||'*'||vl_dfiscales_utel||'*'||vl_dfiscales_receptor||'*'||vl_dfiscales_destinatario||'*'||vl_info_concepto||'*'||vl_impuesto||'*'||vl_impuesto_ret||'*'||vl_info_impuestos||'*'||vl_info_subtotal_imptras||'*'||vl_info_subtotal_impret||'*');

                         END LOOP Pagos_dia;
                        
                        vl_subtotal := vl_subtotal - vn_iva;

                       ---------------- LLenamos Folio y SErie ENC(+)------------------
                         vl_serie_folio := vl_serie_folio||' '||vl_serie_tag||'"'||d_fiscales.serie||'"'||' '||vl_folio_tag||'"'||vl_consecutivo||'"'||
                                                                       ' '||vl_fecha_tag||'"'||pago.Fecha_pago||'"'||' '||vl_forma_pago_tag||'"'||vl_forma_pago||'"'||
                                                                       ' '||vl_condiciones_pago_tag||'"'||vl_condicion_pago||'"'||' '||vl_tipo_cambio_tag||'"'||vl_tipo_cambio||'"'||
                                                                       ' '||vl_moneda_tag||'"'||vl_tipo_moneda||'"'||' '||vl_metodo_pago_tag||'"'||vl_metodo_pago||'"'||
                                                                       ' '||vl_lugar_expedicion_tag||'"'||vl_lugar_expedicion||'"'||' '||vl_tipo_comprobante_tag||'"'||vl_tipo_comprobante||'"'||
                                                                       ' '||vl_subtotal_tag||'"'||to_char(vl_subtotal, 'fm9999999990.00')||'"'||' '||vl_descuento_tag||'"'||vl_descuento||'"'||' '||vl_total_tag||'"'||to_char(pago.MONTO_PAGADO, 'fm9999999990.00')||'"'||
                                                                       ' '||vl_confirmacion_tag||'"'||vl_confirmacion||'"'||' '||vl_tipo_comprobante_emi_tag||'"'||vl_tipo_documento||'"'||' '||'>';
                         
--                         If vl_secuencia > 1 then 
--                                    vl_info_concepto := vl_info_concepto ||'<conceptos';
--                                    vl_impuesto :='<impuesto>';
--                         End if;
                        
                        
                        vl_clave_cargo := null;
                        vl_descrip_cargo := null;
                        vl_secuencia := vl_secuencia +1;
                       
                         
                      If vl_pago_total >  vl_pago_total_faltante then 
                             vl_pago_diferencia :=    vl_pago_total -  vl_pago_total_faltante;
                             
--                         If vl_secuencia > 1 then 
                            vl_info_concepto := vl_info_concepto ||'<conceptos';
                            vl_impuesto :='<impuesto>';
--                         End if;
                                
                                        Begin    
                                             Select TBBDETC_DETAIL_CODE, TBBDETC_DESC
                                               Into  vl_clave_cargo, vl_descrip_cargo
                                             from tbbdetc
                                             Where TBBDETC_DETAIL_CODE = substr (D_Fiscales.matricula, 1,2)||'NN'
                                             And TBBDETC_DCAT_CODE = 'COL';
                                         Exception
                                         when Others then 
                                             vl_clave_cargo := null;
                                              vl_descrip_cargo := null;
                                        End;
                                       
                                        If  vl_clave_cargo is not null and vl_descrip_cargo is not null then                              
                                                vl_info_concepto := vl_info_concepto||' '||vl_clave_prod_serv_tag||'"'||vl_prod_serv||'"'||' '||
                                                                                                             vl_cantidad_concepto_tag||'"'||vl_cantidad_concepto||'"'||' '||
                                                                                                             vl_clave_unidad_concepto_tag||'"'||vl_clave_unidad_concepto||'"'||' '||
                                                                                                             vl_unidad_concepto_tag||'"'||vl_unidad_concepto||'"'||' '||
                                                                                                             vl_num_identificacion_tag||'"'||vl_clave_cargo||'"'||' '||
                                                                                                             vl_descripcion_concepto_tag||'"'||vl_descrip_cargo||'"'||' '||
                                                                                                             vl_valor_unitario_concepto_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                             vl_importe_concepto_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                             vl_descuento_concepto_tag||'"'||vl_descuento||'"'||
                                                                                                             vl_info_concepto_cierre;                                                                                                         

                                              If substr (D_Fiscales.matricula, 1,2) = '01' then 
                                                --------Impuesto trasladado LIMPTRAS(+)
                                                vl_impuesto := vl_impuesto_tras_cab ||' '||vl_base_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                               vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||
                                                                                                               vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||
                                                                                                               vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||
                                                                                                               vl_importe_tag||'"'||vl_pago_diferencia||'"'||
                                                                                                               vl_impuesto_cierre;
                                                                                                                                            
                                                vl_total_imptras := vl_total_imptras + to_char(vl_pago_diferencia*(0/100));                                          
                                                
                                                vl_info_concepto := vl_info_concepto||vl_info_subtotal_imptras;    
                                                
                                                vl_total_impret := 0;                

                                              End if;
                                               
                                       End if;
                                       
                                       
                      End if;
                      

                                     
                                 --vl_info_impuestos_comprobante <IMPUESTOS>
                                        vl_info_impuestos := vl_info_impuestos||' '||vl_totImpRet_tag||'"'||to_char(vl_total_impret,'fm9999999990.00')||'"'||' '||vl_totImpTras_tag||'"'||to_char(vl_total_imptras,'fm9999999990.00')||'"';
                                                                   
                                --Info_subtotal_imptras  <IMPUESTO>
                                        vl_info_subtotal_imptras := vl_info_subtotal_imptras||' '||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||vl_importe_tag||'"'||to_char(vl_total_imptras,'fm9999999990.00')||'"';

                                               --Info_subtotal_impret <IMPUESTO>
                                        vl_info_subtotal_impret := vl_info_subtotal_impret||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_importe_tag||'"'||to_char(vl_total_impret,'fm9999999990.00')||'"';

                                    --Flex_Header <FLEX_HEADER>
                                        vl_flex_header := vl_flex_header||' '||vl_folio_int_cl_fh_tag||'"'||vl_folio_interno_cl_fh||'"'||' '||vl_folio_int_nom_fh_tag||'"'||vl_folio_interno_fh||'"'||' '||vl_folio_int_val_fh_tag||'"'||D_Fiscales.PIDM||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_raz_soc_cl_fh_tag||'"'||vl_razon_social_cl_fh||'"'||' '||vl_raz_soc_nom_fh_tag||'"'||vl_razon_social_fh||'"'||' '||vl_raz_soc_val_fh_tag||'"'||nvl(D_fiscales.Nombre, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_met_pago_cl_fh_tag||'"'||vl_metodo_pago_cl_fh||'"'||' '||vl_met_pago_nom_fh_tag||'"'||vl_metodo_pago_fh||'"'||' '||vl_met_pago_val_fh_tag||'"'||nvl(pago.METODO_PAGO_CODE, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_desc_met_pago_cl_fh_tag||'"'||vl_desc_metodo_pago_cl_fh||'"'||' '||vl_desc_met_pago_nom_fh_tag||'"'||vl_desc_metodo_pago_fh||'"'||' '||vl_desc_met_pago_val_fh_tag||'"'||nvl(pago.METODO_PAGO, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_id_pago_cl_fh_tag||'"'||vl_id_pago_cl_fh||'"'||' '||vl_id_pago_nom_fh_tag||'"'||vl_id_pago_pago_fh||'"'||' '||vl_id_pago_val_fh_tag||'"'||' '||nvl(pago.Id_pago, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_cl_fh_tag||'"'||vl_monto_cl_fh||'"'||' '||vl_monto_nom_fh_tag||'"'||vl_monto_fh||'"'||' '||vl_monto_val_fh_tag||'"'||nvl(to_char(pago.MONTO_PAGADO,'fm9999999990.00'), '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_nivel_cl_fh_tag||'"'||vl_nivel_cl_fh||'"'||' '||vl_nivel_nom_fh_tag||'"'||vl_nivel_fh||'"'||' '||vl_nivel_val_fh_tag||'"'||nvl(D_Fiscales.Nivel, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_campus_cl_fh_tag||'"'||vl_campus_cl_fh||'"'||' '||vl_campus_nom_fh_tag||'"'||vl_campus_fh||'"'||' '||vl_campus_val_fh_tag||'"'||nvl(D_fiscales.Campus, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_mat_alumno_cl_fh_tag||'"'||vl_matricula_alumno_cl_fh||'"'||' '||vl_mat_alumno_nom_fh_tag||'"'||vl_matricula_alumno_fh||'"'||' '||vl_mat_alumno_val_fh_tag||'"'||nvl(D_fiscales.MATRICULA, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_fecha_pago_cl_fh_tag||'"'||vl_fecha_pago_cl_fh||'"'||' '||vl_fecha_pago_nom_fh_tag||'"'||vl_fecha_pago_fh||'"'||' '||vl_fecha_pago_val_fh_tag||'"'||nvl(pago.Fecha_pago, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_referencia_cl_fh_tag||'"'||vl_referencia_cl_fh||'"'||' '||vl_referencia_nom_fh_tag||'"'||vl_referencia_fh||'"'||' '||vl_referencia_val_fh_tag||'"'||nvl(D_fiscales.Referencia, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_referencia_tipo_cl_fh_tag||'"'||vl_referencia_tipo_cl_fh||'"'||' '||vl_referencia_tipo_nom_fh_tag||'"'||vl_referencia_tipo_fh||'"'||' '||vl_referencia_tipo_val_fh_tag||'"'||nvl(D_fiscales.Ref_tipo, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_m_int_pag_tard_cl_fh_tag ||'"'||vl_m_int_pago_tardio_cl_fh||'"'||' '||vl_m_int_pag_tard_nom_fh_tag||'"'||vl_m_int_pago_tardio_fh||'"'||' '||vl_m_int_pag_tard_val_fh_tag||'"'||nvl(pago.monto_interes, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_tipo_accesorio_cl_fh_tag||'"'||vl_tipo_accesorio_cl_fh||'"'||' '||vl_tipo_accesorio_nom_fh_tag||'"'||vl_tipo_accesorio_fh||'"'||' '||vl_tipo_accesorio_val_fh_tag||'"'||nvl(pago.tipo_accesorio, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_accesorio_cl_fh_tag||'"'||vl_monto_accesorio_cl_fh||'"'||' '||vl_monto_accesorio_nom_fh_tag||'"'||vl_monto_accesorio_fh||'"'||' '||vl_monto_accesorio_val_fh_tag||'"'||nvl(pago.monto_accesorio, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_cole_cl_fh_tag||'"'||vl_cole_cl_fh||'"'||' '||vl_cole_nom_fh_tag||'"'||vl_cole_fh||'"'||' '||vl_cole_val_fh_tag||'"'||nvl(pago.colegiaturas, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_cole_cl_fh_tag||'"'||vl_monto_cole_cl_fh||'"'||' '||vl_monto_cole_nom_fh_tag||'"'||vl_monto_cole_fh||'"'||' '||vl_monto_cole_val_fh_tag||'"'||nvl(pago.monto_colegiatura, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                   vl_flex_header||' '||vl_nom_alumnos_cl_fh_tag||'"'||vl_nom_alumnos_cl_fh||'"'||' '||vl_nom_alumnos_nom_fh_tag||'"'||vl_nom_alumnos_fh||'"'||' '||vl_nom_alumnos_val_fh_tag||'"'||nvl(D_Fiscales.Nombre_Alumno, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_curp_cl_fh_tag||'"'||vl_curp_cl_fh||'"'||' '||vl_curp_nom_fh_tag||'"'||vl_curp_fh||'"'||' '||vl_curp_val_fh_tag||'"'||nvl(D_Fiscales.Curp, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_rfc_cl_fh_tag||'"'||vl_rfc_cl_fh||'"'||' '||vl_rfc_nom_fh_tag||'"'||vl_rfc_fh||'"'||' '||vl_rfc_val_fh_tag||'"'||nvl(D_Fiscales.RFC, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_grado_cl_fh_tag||'"'||vl_grado_cl_fh||'"'||' '||vl_grado_nom_fh_tag||'"'||vl_grado_fh||'"'||' '||vl_grado_val_fh_tag||'"'||nvl(D_Fiscales.Grado, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_nota_cl_fh_tag||'"'||vl_nota_cl_fh||'"'||' '||vl_nota_nom_fh_tag||'"'||vl_nota_fh||'"'||' '||vl_nota_val_fh_tag||'"'||nvl(vl_valor_nota_fh, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_int_pag_tard_cl_fh_tag||'"'||vl_int_pago_tardio_cl_fh||'"'||' '||vl_int_pag_tard_nom_fh_tag||'"'||vl_int_pago_tardio_fh||'"'||' '||vl_int_pag_tard_val_fh_tag||'"'||nvl(pago.intereses, '.')||'"'||vl_flex_header_cierre;

                                                        --
                                                                                                        
                                BEGIN
                                     INSERT INTO TZTFACT VALUES(
                                        D_Fiscales.PIDM
                                      , D_Fiscales.RFC
                                      , vl_total
                                      , 'FA'
                                      , NULL
                                      , NULL
                                      , sysdate
                                      ,vl_transaccion
                                      ,NULL
                                      ,vl_consecutivo
                                      ,d_fiscales.serie
                                      ,NULL
                                      ,NULL
                                      ,vl_cabecero||chr(10)||vl_cabe_soap||chr(10)||vl_soap_header||chr(10)||chr(9)||vl_soap_body||chr(10)||chr(9)||chr(9)||vl_neon_ws||chr(10)||vl_serie_folio||chr(10)||
                                      vl_envio_correo||chr(10)||vl_dfiscales_utel||chr(10)||vl_dfiscales_receptor||chr(10)||chr(9)||vl_flex_header||chr(10)||chr(9)||vl_info_concepto||chr(10)||chr(9)||
                                      --vl_impuesto_cab||chr(10)||chr(9)||chr(9)||chr(9)||vl_impuesto||chr(10)||chr(9)||chr(9)||vl_impuestos_cierre||chr(10)||chr(9)||
                                      vl_info_impuestos||vl_impuestos_cierre1||CHR(10)||chr(9)||
                                      vl_info_subtotal_imptras||vl_impuesto_cierre||chr(10)||chr(9)||vl_info_impuestos_cierre||chr(10)||chr(9)||vl_complemento||chr(10)||chr(9)||vl_tipo_operacion||''||vl_valor_to||''||vl_tipo_operacion_cierre||chr(10)||
                                      vl_serie_folio_cierre||chr(10)||vl_neon_ws_cierre||chr(10)||chr(9)||vl_soap_body_cierre||chr(10)||vl_soap_envelope
                                      ,vl_tipo_archivo
                                      ,vl_tipo_fact
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL

                                 );
                                 commit;
                                EXCEPTION
                                WHEN OTHERS THEN
                                 VL_ERROR := 'Se presento un error al insertar ' ||sqlerrm;
                                END;  

                                
                                  Begin
                                    
                                    Update tztdfut
                                    set TZTDFUT_FOLIO = vl_consecutivo
                                    Where TZTDFUT_SERIE = D_Fiscales.serie;
                                    Exception
                                    When Others then 
                                      VL_ERROR := 'Se presento un error al Actualizar ' ||sqlerrm;   
                                    End;
                         
                         If vn_commit >= 500 then 
                             commit;
                             vn_commit :=0;
                         End if;
                   
               commit;
            End Loop Pago;
         
      END LOOP;

   commit;
   --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
Exception
    when Others then
     ROLLBACK;
     --DBMS_OUTPUT.PUT_LINE('Error General'||sqlerrm);
END;


PROCEDURE sp_Sin_Datos_Facturacion_xml
IS

----Cabecero-----------
vl_cabecero varchar2(4000) :='<?xml version="1.0" encoding="UTF-8" ?>';
--<?xml version=''1.0''  encoding="UTF-8" ?>;

--Cabecero SOAP-------
vl_cabe_soap varchar2(4000) := '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:neon="http://neon.stoconsulting.com/NeonEmisionWS/NeonEmisionWS">';

--SOAP_Header------
vl_soap_header varchar2(4000) := '<soap:Header/>';
vl_soap_envelope varchar2(4000) := '</soap:Envelope>';

--SOAP_BOdy-------
vl_soap_body varchar2(4000) := '<soap:Body>';
vl_soap_body_cierre varchar2(4000) := '</soap:Body>';

--NEON_WS------
vl_neon_ws varchar2(4000) := '<neon:emitirWS>';
vl_neon_ws_cierre varchar2(4000) := '</neon:emitirWS>';

---- Se Arma el encazado de la factura <DOCUMENTOS>-------------
--vl_encabezado varchar2(4000):='<documentos>';
vl_consecutivo number :=0;
--vl_documentos_cierre varchar2(4000):='</documentos>';

-------------- LLenamos Folio y SErie <DOCUMENTO>
vl_serie_folio varchar2(2500):='<comprobante';
vl_forma_pago varchar2(100):='99';
vl_condicion_pago varchar2(250):= 'Pago en una sola exhibicion';
vl_tipo_cambio number:=1;
vl_tipo_moneda varchar2(10):= 'MXN';
vl_metodo_pago varchar2(10):= 'PUE';
vl_lugar_expedicion varchar2(10):= '53370';
vl_tipo_comprobante varchar2(5):= 'I';
vl_descuento varchar2(15):='0.00';
vl_total number(16,2);
vl_confirmacion varchar2(2);
vl_tipo_documento number:=1;
vl_subtotal number(16,2);
vl_serie_folio_cierre varchar2(2500):='</comprobante>';
vl_serie_tag varchar2(250):='serie=';
vl_folio_tag varchar2(250):='folio=';
vl_fecha_tag varchar2(250):='fecha=';
vl_forma_pago_tag varchar2(250):='formaPago=';
vl_condiciones_pago_tag varchar2(250):='condicionesDePago=';
vl_tipo_cambio_tag varchar2(250):='tipoCambio=';
vl_moneda_tag varchar2(250):='moneda=';
vl_metodo_pago_tag varchar2(250):='metodoPago=';
vl_lugar_expedicion_tag varchar2(250):='lugarExpedicion=';
vl_tipo_comprobante_tag varchar2(250):='tipoComprobante=';
vl_subtotal_tag varchar2(250):='subTotal=';
vl_descuento_tag varchar2(250):='descuento=';
vl_total_tag varchar2(250):='total=';
vl_confirmacion_tag varchar2(250):='confirmacion=';
vl_tipo_comprobante_emi_tag varchar2(250):='tipoDocumento=';


-------------------Entidad_receptor <DOCUMENTO_ERP>
--vl_entidad_receptor varchar2(4000):='<documentoErp>';
--vl_entidad_receptor_cierre varchar2(4000):='</documentoErp>';
--vl_id_trx_erp_tag varchar2(250):='idTrxErp=';

 
---------Envio por correo <ENVIO_CFDI>
vl_envio_correo varchar2(4000):='<envioCfdi';
vl_enviar_xml varchar2(15):='1';
vl_enviar_pdf varchar2(15):='1';
vl_enviar_zip varchar2(15):='1';
vl_xml_tag varchar2(250):='enviarXml=';
vl_pdf_tag varchar2(250):='enviarPdf=';
vl_zip_tag varchar2(250):='enviarZip=';
vl_email_tag varchar2(250):='emails=';
vl_envio_correo_cierre varchar2(4000):='/>';


------Datos fiscales utel <EMISOR>
vl_dfiscales_utel varchar2(4000):='<emisor';
vl_rfc_utel varchar2(15);
vl_razon_social_utel varchar2(250);
vl_regimen_fiscal varchar2(5):='601';
vl_id_emisor_sto number:=1;
vl_id_emisor_erp number:=1;
vl_dfiscales_utel_cierre varchar2(4000):='/>';
vl_rfc_tag varchar2(250):='rfc=';
vl_nombre_tag varchar2(250):='nombre=';
vl_regimen_fiscal_tag varchar2(250):='regimenFiscal=';
vl_id_emisor_sto_tag varchar2(250):='idEmisorSto=';
vl_id_emisor_erp_tag varchar2(250):='idEmisorErp=';


------Datos fiscales Alumno <RECEPTOR>
vl_dfiscales_receptor varchar2(4000):='<receptor';
vl_referencia_dom_receptor varchar2(255):=' ';
--vl_id_tipo_receptor varchar2(25):='0';
--vl_id_receptor_sto varchar2(25):='0';
vl_estatus_registro varchar2(25):='1';
vl_uso_cfdi varchar2(25):='D10';
vl_residencia_fiscal varchar2(25);
vl_num_reg_id_trib varchar2(25);
--vl_id_receptor_erp varchar2(25);
--vl_id_receptor_padre varchar2(25);
vl_cierre_receptor varchar2(4000):='/>';
vl_rfc_receptor_tag varchar2(250):='rfc=';
vl_nombre_receptor_tag varchar2(250):='nombre=';
vl_residencia_fiscal_tag varchar2(250):='residenciaFiscal=';
vl_num_reg_id_trib_tag varchar2(250):='numRegIdTrib=';
vl_uso_cfdi_tag varchar2(250):='usoCfdi=';
vl_id_receptor_sto_tag varchar2(250):='idReceptoSto=';
vl_id_receptor_erp_tag varchar2(250):='idReceptorErp=';
vl_numero_exterior_tag varchar2(250):='numeroExterior=';
vl_calle_tag varchar2(250):='calle=';
vl_numero_interior_tag varchar2(250):='numeroInterior=';
vl_colonia_tag varchar2(250):='colonia=';
vl_localidad_tag varchar2(250):='localidad=';
vl_referencia_tag varchar2(250):='referencia=';
vl_municipio_tag varchar2(250):='municipio=';
vl_estado_tag varchar2(250):='estado=';
vl_pais_tag varchar2(250):='pais=';
vl_codigo_postal_tag varchar2(250):='codigoPostal=';
vl_email_receptor_tag varchar2(250):='email=';
vl_id_tipo_receptor_tag varchar2(250):='idTipoReceptor=';
--vl_id_receptor_padre_tag varchar2(250):='id_receptor_padre=';
vl_estatus_registro_tag varchar2(250):='estatusRegistro=';


------Datos fiscales Alumno <DESTINATARIO>
vl_dfiscales_destinatario varchar2(4000):='<destinatario>';
vl_referencia_dom_destinatario varchar2(255):=' ';
vl_id_tipo_destinatario varchar2(25):='0';
vl_id_destinarario_sto varchar2(25):='0';


-----Cabecera Conceptos
--vl_conceptos_cab varchar2(4000):='<conceptos>';
vl_conceptos_cierre varchar2(4000):='</conceptos>';


------Concepto <CONCEPTO>
vl_info_concepto CLOB :='<conceptos';
vl_num_linea number:=0;
vl_prod_serv varchar2(50);
vl_cantidad_concepto varchar2(10):='1';
vl_clave_unidad_concepto varchar2(10):='E48';
vl_unidad_concepto varchar2(50):='Servicio';
vl_importe_concepto number:=1;
vl_fecha_pago date;
vl_transaccion number :=0;
vl_info_concepto_cierre varchar2(4000) := '>';
vl_numero_linea_concepto_tag varchar2(250):='numeroLinea=';
vl_clave_prod_serv_tag varchar2(250):='claveProdServ=';
vl_cantidad_concepto_tag varchar2(250):='cantidad=';
vl_clave_unidad_concepto_tag varchar2(250):='claveUnidad=';
vl_unidad_concepto_tag varchar2(250):='unidad=';
vl_num_identificacion_tag varchar2(250):='numIdentificacion=';
vl_descripcion_concepto_tag varchar2(250):='descripcion=';
vl_valor_unitario_concepto_tag varchar2(250):='valorUnitario=';
vl_importe_concepto_tag varchar2(250):='importe=';
vl_descuento_concepto_tag varchar2(250):='descuento=';


----Cabecera Impuestos
vl_impuesto_cab varchar2(4000):='<impuestos>';
vl_impuestos_cierre varchar2(4000):='</impuestos>';
vl_impuestos_cierre1 varchar2(4000):='>';


--Impuesto trasladado <IMPUESTO>
vl_impuesto_tras_cab varchar2(4000):='<trasladados';
vl_impuesto varchar2(4000):='<impuesto';
vl_impuesto_cod varchar2(10):='002';
vl_tipo_factor_impuesto varchar2(15):='Tasa';
vl_tasa_cuota_impuesto varchar2(15);
vl_impuesto_cierre varchar2(4000):='/>';
vl_impuesto_tras_cierre varchar2(4000):='</impuestos>';
vl_base_tag varchar2(250):='base=';
vl_impuesto_tag varchar2(250):='impuesto=';
vl_tipo_factor_tag varchar2(250):='tipoFactor=';
vl_tasa_o_cuota_tag varchar2(250):='tasaOCuota=';
vl_importe_tag varchar2(250):='importe=';


--Impuesto retenido <RETENIDOS>
vl_impuesto_ret_cab varchar2(4000):='<retenidos>';
vl_impuesto_ret varchar2(4000):='<impuesto';
vl_base_impuesto_ret varchar2(25);
vl_impuesto_ret_cod varchar2(10):='002';
vl_tipo_factor_impuesto_ret varchar2(15):='Tasa';
vl_tasa_cuota_impuesto_ret varchar2(15);
vl_importe_impuesto_ret number(24,6);
vl_impuesto_ret_cierre varchar2(4000):='</retenidos>';


--Info_impuestos_comprobante <IMPUESTOS>
vl_info_impuestos varchar2(4000):='<impuestos';
vl_total_impret number(24,6);
vl_total_imptras number(24,6);
vl_info_impuestos_cierre varchar2(4000):='</impuestos>';
vl_totImpRet_tag varchar2(250):='totalImpuestosRetenidos=';
vl_totImpTras_tag varchar2(250):='totalImpuestosTrasladados=';


--Cabecera subtotales trasladados
vl_sub_imptras_cab varchar2(4000):='<trasladados>';
vl_sub_imptras_cierre varchar2(4000):='</trasladados>';


--Info_subtotal_imptras <IMPUESTO>
vl_info_subtotal_imptras varchar2(4000):='<trasladados';


--Cabecera subtotales retenidos
vl_sub_impret_cab varchar2(4000):='<retenidos>';
vl_sub_impret_cierre varchar2(4000):='</retenidos>';


--Info_subtotal_impret <IMPUESTO>
vl_info_subtotal_impret varchar2(4000):='<impuesto>';

vl_error varchar2(2500):='EXITO';
vl_contador number:=0;
vl_existe number:=0;


--Tipo_operacion---------
vl_tipo_operacion varchar2(4000):='<tipoOperacion>';
vl_valor_to varchar2(30):='sincrono';
vl_tipo_operacion_cierre varchar2(4000):='</tipoOperacion>';


--excedente
vl_pago_total number :=0;
vl_pago_total_faltante number :=0;
vl_pago_diferencia number :=0;
vl_clave_cargo varchar2(5):= null;
vl_descrip_cargo varchar2(90):= null;
vl_secuencia number:=0;


--Flex_Header FH(+)
vl_flex_headers_cab varchar2(4000):='<flexHeaders>';
vl_flex_header varchar2(4000):='<flexHeaders';
vl_folio_interno_cl_fh varchar2(50):='1';
vl_folio_interno_fh varchar2(255):='folioInterno';
vl_razon_social_cl_fh varchar2(50):='2';
vl_razon_social_fh varchar2(255):='razonSocial';
vl_metodo_pago_cl_fh varchar2(50):='3';
vl_metodo_pago_fh varchar2(255):='metodoDePago';
vl_desc_metodo_pago_cl_fh varchar2(50):='4';
vl_desc_metodo_pago_fh varchar2(255):='descripcionDeMetodoDePago';
vl_id_pago_cl_fh varchar2(50):='5';
vl_id_pago_pago_fh varchar2(255):='IdPago';
vl_monto_cl_fh varchar2(50):='6';
vl_monto_fh varchar2(255):='Monto';
vl_nivel_cl_fh varchar2(50):='7';
vl_nivel_fh varchar2(255):='Nivel';
vl_campus_cl_fh varchar2(50):='8';
vl_campus_fh varchar2(255):='Campus';
vl_matricula_alumno_cl_fh varchar2(50):='9';
vl_matricula_alumno_fh varchar2(255):='matriculaAlumno';
vl_fecha_pago_cl_fh varchar2(50):='10';
vl_fecha_pago_fh varchar2(255):='fechaPago';
vl_referencia_cl_fh varchar2(50):='11';
vl_referencia_fh varchar2(255):='Referencia';
vl_referencia_tipo_cl_fh varchar2(50):='12';
vl_referencia_tipo_fh varchar2(255):='ReferenciaTipo';
vl_int_pago_tardio_cl_fh varchar2(50):='13';
vl_int_pago_tardio_fh varchar2(255):='InteresPagoTardio';
vl_valor_int_pag_tard_fh varchar2(255):= '.';
vl_tipo_accesorio_cl_fh varchar2(50):='14';
vl_tipo_accesorio_fh varchar2(255):='TipoAccesorio';
vl_monto_accesorio_cl_fh varchar2(50):='15';
vl_monto_accesorio_fh varchar2(255):='MontoAccesorio';
vl_otros_cl_fh varchar2(50):='16';
vl_otros_fh varchar2(255):='Colegiatura';
vl_valor_otros_fh varchar2(255):= '.';
vl_monto_otros_cl_fh varchar2(50):='17';
vl_monto_otros_fh varchar2(255):='MontoColegiatura';
vl_valor_monto_otros_fh varchar2(255):= '.';
vl_nom_alumnos_cl_fh varchar2(50):='18';
vl_nom_alumnos_fh varchar2(255):='NombreAlumno';
vl_curp_cl_fh varchar2(50):='19';
vl_curp_fh varchar2(255):='CURP';
vl_rfc_cl_fh varchar2(50):='20';
vl_rfc_fh varchar2(255):='RFC';
vl_grado_cl_fh varchar2(50):='21';
vl_grado_fh varchar2(255):='Grado';
vl_flex_header_cierre varchar2(4000):='/>';
vl_flex_headers_cierre varchar2(4000):='</flexHeaders>';
vl_folio_int_cl_fh_tag varchar2(250):='clave=';
vl_folio_int_nom_fh_tag varchar2(250):='nombre=';
vl_folio_int_val_fh_tag varchar2(250):='valor=';
vl_raz_soc_cl_fh_tag varchar2(250):='clave=';
vl_raz_soc_nom_fh_tag varchar2(250):='nombre=';
vl_raz_soc_val_fh_tag varchar2(250):='valor=';
vl_met_pago_cl_fh_tag varchar2(250):='clave=';
vl_met_pago_nom_fh_tag varchar2(250):='nombre=';
vl_met_pago_val_fh_tag varchar2(250):='valor=';
vl_desc_met_pago_cl_fh_tag varchar2(250):='clave=';
vl_desc_met_pago_nom_fh_tag varchar2(250):='nombre=';
vl_desc_met_pago_val_fh_tag varchar2(250):='valor=';
vl_id_pago_cl_fh_tag varchar2(250):='clave=';
vl_id_pago_nom_fh_tag varchar2(250):='nombre=';
vl_id_pago_val_fh_tag varchar2(250):='valor=';
vl_monto_cl_fh_tag varchar2(250):='clave=';
vl_monto_nom_fh_tag varchar2(250):='nombre=';
vl_monto_val_fh_tag varchar2(250):='valor=';
vl_nivel_cl_fh_tag varchar2(250):='clave=';
vl_nivel_nom_fh_tag varchar2(250):='nombre=';
vl_nivel_val_fh_tag varchar2(250):='valor=';
vl_campus_cl_fh_tag varchar2(250):='clave=';
vl_campus_nom_fh_tag varchar2(250):='nombre=';
vl_campus_val_fh_tag varchar2(250):='valor=';
vl_mat_alumno_cl_fh_tag varchar2(250):='clave=';
vl_mat_alumno_nom_fh_tag varchar2(250):='nombre=';
vl_mat_alumno_val_fh_tag varchar2(250):='valor=';
vl_fecha_pago_cl_fh_tag varchar2(250):='clave=';
vl_fecha_pago_nom_fh_tag varchar2(250):='nombre=';
vl_fecha_pago_val_fh_tag varchar2(250):='valor=';
vl_referencia_cl_fh_tag varchar2(250):='clave=';
vl_referencia_nom_fh_tag varchar2(250):='nombre=';
vl_referencia_val_fh_tag varchar2(250):='valor=';
vl_referencia_tipo_cl_fh_tag varchar2(250):='clave=';
vl_referencia_tipo_nom_fh_tag varchar2(250):='nombre=';
vl_referencia_tipo_val_fh_tag varchar2(250):='valor=';
vl_int_pag_tard_cl_fh_tag varchar2(250):='clave=';
vl_int_pag_tard_nom_fh_tag varchar2(250):='nombre=';
vl_int_pag_tard_val_fh_tag varchar2(250):='valor=';
vl_tipo_accesorio_cl_fh_tag varchar2(250):='clave=';
vl_tipo_accesorio_nom_fh_tag varchar2(250):='nombre=';
vl_tipo_accesorio_val_fh_tag varchar2(250):='valor=';
vl_monto_accesorio_cl_fh_tag varchar2(250):='clave=';
vl_monto_accesorio_nom_fh_tag varchar2(250):='nombre=';
vl_monto_accesorio_val_fh_tag varchar2(250):='valor=';
vl_otros_cl_fh_tag varchar2(250):='clave=';
vl_otros_nom_fh_tag varchar2(250):='nombre=';
vl_otros_val_fh_tag varchar2(250):='valor=';
vl_monto_otros_cl_fh_tag varchar2(250):='clave=';
vl_monto_otros_nom_fh_tag varchar2(250):='nombre=';
vl_monto_otros_val_fh_tag varchar2(250):='valor=';
vl_nom_alumnos_cl_fh_tag varchar2(250):='clave=';
vl_nom_alumnos_nom_fh_tag varchar2(250):='nombre=';
vl_nom_alumnos_val_fh_tag varchar2(250):='valor=';
vl_curp_cl_fh_tag varchar2(250):='clave=';
vl_curp_nom_fh_tag varchar2(250):='nombre=';
vl_curp_val_fh_tag varchar2(250):='valor=';
vl_rfc_cl_fh_tag varchar2(250):='clave=';
vl_rfc_nom_fh_tag varchar2(250):='nombre=';
vl_rfc_val_fh_tag varchar2(250):='valor=';
vl_grado_cl_fh_tag varchar2(250):='clave=';
vl_grado_nom_fh_tag varchar2(250):='nombre=';
vl_grado_val_fh_tag varchar2(250):='valor=';


------ Contadoor de registros
vn_commit  number :=0;

---- Manejo del IVA
vn_iva number:=0;


---- Tipo_Archivo
vl_tipo_archivo varchar2(50):='XML';
vl_tipo_fact varchar2(50):='Sin_D_facturacion';

vl_estatus_timbrado number :=0;
--   
BEGIN
   FOR Sin_D_Fiscales
              IN (  WITH CURP AS (
                                            select 
                                                SPRIDEN_PIDM PIDM,
                                                GORADID_ADDITIONAL_ID CURP
                                              from SPRIDEN
                                              left join GORADID on SPRIDEN_PIDM = GORADID_PIDM
                                              where GORADID_ADID_CODE = 'CURP'
                                              )
                        select distinct SPRIDEN_PIDM PIDM,
                                            SPRIDEN_ID MATRICULA,
                                            replace(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME Nombre_Alumno,
                                            SUBSTR(spriden_id,5) ID,
                                            SPREMRG_LAST_NAME Nombre,
                                            CASE
                                                 when SPREMRG_MI is null then
                                                 'XAXX010101000'
                                            end RFC,
                                            REGEXP_SUBSTR(SPREMRG_STREET_LINE1, '[^#"]+', 1, 1) Calle,
                                            NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#[^#]*'),2), 0) Num_Ext,
                                            NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#Int[^*]*'),2), 0) Num_Int,
                                            SPREMRG_STREET_LINE3 Colonia,
                                            SPREMRG_CITY AS Municipio,
                                            SPREMRG_ZIP AS CP,                                               
                                            SPREMRG_STAT_CODE Estado,
                                            SPREMRG_NATN_CODE AS Pais,
                                            'acruzsol@utel.edu.mx' Email,
                                            --GOREMAL_EMAIL_ADDRESS Email,
                                            CASE
                                                 when GORADID_ADID_CODE = 'REFH' then
                                                 'BH'
                                                 when GORADID_ADID_CODE = 'REFS' then
                                                 'BS'
                                                 when GORADID_ADID_CODE = 'REFU' then 
                                                 'UI'
                                            end Serie,
                                            SZVCAMP_CAMP_CODE Campus,
                                            GORADID_ADDITIONAL_ID Referencia,
                                            GORADID_ADID_CODE Ref_tipo,
                                            STVLEVL_DESC Nivel,
                                            CURP.CURP Curp,
                                            SARADAP_DEGC_CODE_1 Grado
                            from SPRIDEN
                            left join SPREMRG on SPRIDEN_PIDM = SPREMRG_PIDM
                            left outer join SARADAP on SPREMRG_PIDM = SARADAP_PIDM
                            left join STVLEVL on SARADAP_LEVL_CODE = STVLEVL_CODE
                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                            left join GORADID on GORADID_PIDM = SPRIDEN_PIDM 
                                and GORADID_ADID_CODE LIKE 'REF%'
                            join SZVCAMP on szvcamp_camp_alt_code=substr(SPRIDEN_ID,1,2)
                            left join CURP on SPREMRG_PIDM = CURP.PIDM
                            WHERE SPRIDEN_PIDM not in (SELECT SPREMRG_PIDM
                            FROM SPREMRG)
                                          and SPRIDEN_ID not in (SELECT SPRIDEN_ID
                                                                       FROM SPRIDEN
                                                                       WHERE SPRIDEN_ID LIKE '%99000%')
                                       --and spriden_id ='020001218'
                                  ORDER BY SPRIDEN_PIDM)
   LOOP
          
            vl_pago_total:=0;
            vn_commit :=0;
           For pago in (
                               with accesorios as(
                                                        select distinct
                                                          TZTCRTE_PIDM Pidm,
                                                          TZTCRTE_LEVL as Nivel,
                                                          TZTCRTE_CAMP as Campus,
                                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                                          TZTCRTE_CAMPO17 as accesorios,
                                                          to_char(sum (TZTCRTE_CAMPO15),'fm9999999990.00') as Monto_accesorios,
                                                          TZTCRTE_CAMPO18 as Categoria,
                                                          TZTCRTE_CAMPO10 as Secuencia
                                                        from TZTCRTE
                                                        where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
                                                               and TZTCRTE_CAMPO18 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                                                group by TZTCRTE_PIDM, TZTCRTE_LEVL, TZTCRTE_CAMP, TZTCRTE_CAMPO11, TZTCRTE_CAMPO17, TZTCRTE_CAMPO18, TZTCRTE_CAMPO10
                                                                )
                                    SELECT DISTINCT 
                                            TBRACCD_PIDM PIDM,
                                            SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                            TBRACCD_DETAIL_CODE METODO_PAGO_CODE,
                                            TBRACCD_DESC METODO_PAGO,
                                            to_char (TBRACCD_EFFECTIVE_DATE,'RRRR-MM-DD"T"HH24:MI:SS') Fecha_pago,
                                            TBRACCD_PAYMENT_ID Id_pago,
                                            accesorios.accesorios tipo_accesorio,
                                            accesorios.Monto_accesorios monto_accesorio
                                    FROM TBRACCD
                                    left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                    LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                    LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                        AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                    left join accesorios on tbraccd_pidm = accesorios.Pidm
                                    and TBRACCD_TRAN_NUMBER = accesorios.secuencia
                                    WHERE TBBDETC_TYPE_IND = 'P'
                                        AND TBBDETC_DCAT_CODE = 'CSH'
                                        AND TBRACCD_PIDM= Sin_D_Fiscales.pidm
                                        AND TRUNC (TBRACCD_EFFECTIVE_DATE) >= sysdate
                                        AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                    FROM TZTFACT
                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                    ORDER BY TBRACCD_PIDM, 2 asc
                                    )
            loop
             
             If pago.MONTO_PAGADO like '-%' then
                    pago.MONTO_PAGADO := pago.MONTO_PAGADO * (-1);
             End if;                           
                                  vn_commit := vn_commit +1;  
                                                
                vl_pago_total := pago.MONTO_PAGADO;
                vl_subtotal := pago.MONTO_PAGADO;
                            
                                      
                vl_num_linea:=0;
                vl_rfc_utel:= null; 
                vl_razon_social_utel:= null; 
                vl_prod_serv := null;      
                vl_consecutivo :=0;
                  
                --vl_encabezado :='<documentos>';
                --vl_entidad_receptor :='<documentoErp>';
                vl_envio_correo :='<envioCfdi';
                vl_dfiscales_utel :='<emisor';
                vl_dfiscales_receptor :='<receptor';
                vl_dfiscales_destinatario := '<destinatario>';
                
                     --Emisor_STO
                        If Sin_D_Fiscales.serie = 'BH' then
                            vl_id_emisor_sto := 1;
                        Elsif Sin_D_Fiscales.serie = 'BS' then
                            vl_id_emisor_sto := 2;
                        End if;
                        
                      --Emisor_ERP
                         If Sin_D_Fiscales.serie = 'BH' then
                            vl_id_emisor_erp := 1;
                        Elsif Sin_D_Fiscales.serie = 'BS' then
                            vl_id_emisor_erp := 2;
                        End if;

            --- Se obtiene el numero de consecutivo por empresa 
                    Begin

                    select nvl (max (TZTDFUT_FOLIO), 0)+1
                        Into  vl_consecutivo
                    from tztdfut
                    where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                    Exception
                    When Others then 
                        vl_consecutivo :=1;
                    End;

                   Begin
                        select 
                            TZTDFUT_RFC RFC,
                            TZTDFUT_RAZON_SOC RAZON_SOCIAL,
                            TZTDFUT_PROD_SERV_CODE
                        Into vl_rfc_utel, vl_razon_social_utel, vl_prod_serv
                        from TZTDFUT
                        where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                   exception
                   when others then
                        vl_error:= 'Error al Recuperer los datos Fiscales de la empresa ' ||sqlerrm;
                   End;



                ----Cabecero xml--------
                vl_cabecero := vl_cabecero;

                ---- Se Arma el encazado de la factura <DOCUMENTOS>-------------
                --vl_encabezado := vl_encabezado ||vl_consecutivo;
                
                --------Datos fiscales utel <EMISOR>
                vl_dfiscales_utel := vl_dfiscales_utel||' '||vl_rfc_tag||'"'||vl_rfc_utel||'"'||' '||vl_nombre_tag||'"'||vl_razon_social_utel||'"'||' '||vl_regimen_fiscal_tag||'"'||vl_regimen_fiscal||'"'||' '||vl_id_emisor_sto_tag||'"'||vl_id_emisor_sto||'"'||' '||vl_id_emisor_erp_tag||'"'||vl_id_emisor_erp||'"'||' '||vl_dfiscales_utel_cierre;
                
                -----Se envia por correo <ENVIO_CFDI>
                vl_envio_correo := vl_envio_correo||' '||vl_xml_tag||'"'||vl_enviar_xml||'"'||' '||vl_pdf_tag||'"'||vl_enviar_pdf||'"'||' '||vl_zip_tag||'"'||vl_enviar_zip||'"'||' '||vl_email_tag||'"'||Sin_D_Fiscales.Email||'"'||' '||vl_envio_correo_cierre;
                
                ----------Datos de entidad del receptor <DOCUMENTO_ERP>
                --vl_entidad_receptor := vl_entidad_receptor||vl_id_trx_erp_tag||'"'||vl_consecutivo||'"'||vl_entidad_receptor_cierre;
                
                --------Datos fiscales alumno <RECEPTOR>
                vl_dfiscales_receptor := vl_dfiscales_receptor||' '||vl_rfc_receptor_tag||'"'||Sin_D_Fiscales.RFC||'"'||' '||vl_nombre_receptor_tag||'"'||pago.nombre_alumno||'"'||' '||vl_residencia_fiscal_tag||'"'||vl_residencia_fiscal||'"'||' '||vl_num_reg_id_trib_tag||'"'||vl_num_reg_id_trib||'"'||' '||vl_uso_cfdi_tag||'"'||vl_uso_cfdi||'"'||' '||vl_id_receptor_sto_tag||'"'||Sin_D_Fiscales.PIDM||'"'||' '||vl_id_receptor_erp_tag||'"'||Sin_D_Fiscales.ID||'"'||' '||vl_numero_exterior_tag||'"'||Sin_D_Fiscales.Num_Ext||'"'||' '||vl_calle_tag||'"'||Sin_D_Fiscales.Calle||'"'||' '||vl_numero_interior_tag||'"'||Sin_D_Fiscales.Num_Int||'"'||' '||vl_colonia_tag||'"'||Sin_D_Fiscales.Colonia||'"'||' '||vl_localidad_tag||'"'||Sin_D_Fiscales.Municipio||'"'||' '||vl_referencia_tag||'"'||vl_referencia_dom_receptor||'"'||' '||vl_municipio_tag||'"'||Sin_D_Fiscales.Municipio||'"'||' '||vl_estado_tag||'"'||Sin_D_Fiscales.Estado||'"'||' '||vl_pais_tag||'"'||Sin_D_Fiscales.Pais||'"'||' '||vl_codigo_postal_tag||'"'||Sin_D_Fiscales.CP||'"'||' '||vl_email_receptor_tag||'"'||Sin_D_Fiscales.Email||'"'||' '||vl_id_tipo_receptor_tag||'"'||Sin_D_Fiscales.ID||'"'||' '||vl_estatus_registro_tag||'"'||vl_estatus_registro||'"'||' '||vl_cierre_receptor;

                --------Datos fiscales alumno <DESTINATARIO>
                vl_dfiscales_destinatario := vl_dfiscales_destinatario||Sin_D_Fiscales.RFC||'|'||Sin_D_Fiscales.Nombre||'|'||vl_uso_cfdi||'|'||Sin_D_Fiscales.ID||'|'||Sin_D_Fiscales.ID||'|'||Sin_D_Fiscales.Num_Ext||'|'||Sin_D_Fiscales.Calle||'|'||Sin_D_Fiscales.Num_Int||'|'||Sin_D_Fiscales.Colonia||'|'||Sin_D_Fiscales.Municipio||'|'||vl_referencia_dom_destinatario||'|'||Sin_D_Fiscales.Municipio||'|'||Sin_D_Fiscales.Estado||'|'||Sin_D_Fiscales.Pais||'|'||Sin_D_Fiscales.CP||'|'||Sin_D_Fiscales.Email||'|'||Sin_D_Fiscales.ID||'|'||vl_estatus_registro||'|';

                                    
                                    

                            vl_serie_folio :='<comprobante';
                            vl_info_concepto :='<conceptos';
                            vl_impuesto :='<impuesto>';
                            vl_impuesto_ret :='<retenidos>';
                            vl_info_impuestos :='<impuestos';
                            vl_info_subtotal_imptras :='<impuesto';
                            vl_info_subtotal_impret :='<impuesto>';
                            vl_flex_header :='<flexHeaders';
                                               
                            vl_fecha_pago := null;
                            vl_transaccion  :=0;
                            vl_total_impret :=0;
                            vl_total_imptras :=0;
                            vl_contador :=0;
                                    

                               ---------------- LLenamos Folio y SErie <DOCUMENTO>------------------
                                --vl_serie_folio := vl_serie_folio||' '||vl_serie_tag||'"'||Sin_D_fiscales.serie||'"'||' '||vl_folio_tag||'"'||vl_consecutivo||'"'||' '||vl_fecha_tag||'"'||pago.Fecha_pago||'"'||' '||vl_forma_pago_tag||'"'||vl_forma_pago||'"'||' '||vl_condiciones_pago_tag||'"'||vl_condicion_pago||'"'||' '||vl_tipo_cambio_tag||'"'||vl_tipo_cambio||'"'||' '||vl_moneda_tag||'"'||vl_tipo_moneda||'"'||' '||vl_metodo_pago_tag||'"'||vl_metodo_pago||'"'||' '||vl_lugar_expedicion_tag||'"'||vl_lugar_expedicion||'"'||' '||vl_tipo_comprobante_tag||'"'||vl_tipo_comprobante||'"'||' '||vl_subtotal_tag||'"'||vl_subtotal||'"'||' '||vl_descuento_tag||'"'||vl_descuento||'"'||' '||vl_total_tag||'"'||pago.MONTO_PAGADO||'"'||' '||vl_confirmacion_tag||'"'||vl_confirmacion||'"'||' '||vl_tipo_comprobante_emi_tag||'"'||vl_tipo_documento||'"'||' '||'>';

                            vl_pago_total_faltante:=0;
                            vl_secuencia :=0;
                            vn_iva :=0;
                                
                               FOR Pagos_dia
                                        IN (
                                              with cargo as (
                                                                    Select distinct tbraccd_pidm pidm, tbraccd_detail_code cargo, tbraccd_tran_number transa, tbraccd_desc descripcion 
                                                                    from tbraccd),
                                                                    iva as (
                                                                    select distinct TVRACCD_PIDM pidm, TVRACCD_AMOUNT monto_iva, TVRACCD_ACCD_TRAN_NUMBER iva_tran
                                                                    from tvraccd
                                                                    where TVRACCD_DETAIL_CODE like 'IV%'
                                                                    )
                                                        SELECT DISTINCT 
                                                            TBRACCD_PIDM PIDM,
                                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                                            to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                                           nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                                            to_char(TBRACCD_EFFECTIVE_DATE, 'dd/mm/rrrr') Fecha_pago,
                                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                                            TBBDETC_DESC DESCRIPCION,
                                                            nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                                            nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                                            to_char(nvl (iva.monto_iva, 0),'fm9999999990.00') monto_iva,
                                                            iva.iva_tran iva_transaccion,
                                                            ROW_NUMBER() OVER(PARTITION BY TBRACCD_TRAN_NUMBER ORDER BY TBRACCD_EFFECTIVE_DATE) numero
                                                        FROM TBRACCD
                                                        LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                        LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                                            AND TBRAPPL_REAPPL_IND IS NULL
                                                        left join cargo on cargo.pidm = tbraccd_pidm
                                                            and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                                        left join iva on iva.pidm = TBRACCD_PIDM
                                                            and iva.iva_tran = TBRACCD_TRAN_NUMBER
                                                        WHERE     TBBDETC_TYPE_IND = 'P'
                                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                                            AND TBRACCD_PIDM= pago.pidm
                                                            And TBRACCD_TRAN_NUMBER = pago.TRANSACCION
                                                            AND TRUNC (TBRACCD_EFFECTIVE_DATE) >= trunc(sysdate)
                                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                                    FROM TZTFACT
                                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                                        ORDER BY TBRACCD_PIDM, 2,13 asc
                                           )    
                         LOOP

                              vl_contador := vl_contador +1;
                              vl_pago_total_faltante := vl_pago_total_faltante + Pagos_dia.MONTO_PAGADO_CARGO;
                              vl_secuencia :=Pagos_dia.numero;
                              vn_iva :=  vn_iva + Pagos_dia.monto_iva;


                             BEGIN
                             
                                select '01'
                                     INTO vl_forma_pago
                                from tbraccd a, spriden b
                                where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                              from tbbdetc
                                                                              where TBBDETC_DCAT_CODE = 'CSH'
                                                                               and TBBDETC_TYPE_IND = 'P')
                                   and tbraccd_pidm = spriden_pidm
                                   and spriden_change_ind is null
                                   AND spriden_pidm = Pagos_dia.PIDM
                                   AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                   and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                          FROM ZSTPARA
                                                                                          WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                          AND ZSTPARA_PARAM_ID = 'EFECTIVO');
                             
                             EXCEPTION           
                               WHEN OTHERS THEN NULL;
                                 vl_forma_pago:='99';
                                 BEGIN
                                     
                                     select '02'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                  FROM ZSTPARA
                                                                                                  WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                  AND ZSTPARA_PARAM_ID = 'CHEQUE');
                                     
                                     
                                 EXCEPTION           
                                   WHEN OTHERS THEN NULL;
                                     vl_forma_pago:='99';
                                     BEGIN

                                        select '03'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                  FROM ZSTPARA
                                                                                                  WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                  AND ZSTPARA_PARAM_ID = 'TRANSFERENCIA');

                                     EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_forma_pago:='99';
                                        BEGIN

                                        select '04'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                  FROM ZSTPARA
                                                                                                  WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                  AND ZSTPARA_PARAM_ID = 'TARJETA_DE_CREDITO');
                                                                                                  
                                        EXCEPTION           
                                            WHEN OTHERS THEN NULL;
                                                vl_forma_pago:='99';
                                        END;
                                     END;
                                 END;
                         END;

                            
                            If PAGOS_DIA.MONTO_PAGADO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO := PAGOS_DIA.MONTO_PAGADO * (-1);
                            End if; 
                            
                            ------------------- Seteo ---------------
                           
                            vl_total :=PAGOS_DIA.MONTO_PAGADO;
                            vl_fecha_pago := PAGOS_DIA.Fecha_pago;
                            vl_transaccion :=PAGOS_DIA.TRANSACCION;



                            ----
                             If Pagos_dia.numero > 1 then 
                                    vl_info_concepto := vl_info_concepto ||'<conceptos';
                                    vl_impuesto :='<impuesto>';
                             End if;
                                
                                
                                If Pagos_dia.monto_iva > 0 then
                                    vl_tasa_cuota_impuesto := '0.160000';
                                Elsif Pagos_dia.monto_iva = 0 then
                                    vl_tasa_cuota_impuesto := '0.000000';
                                End if;
                                
                                
                                If PAGOS_DIA.MONTO_PAGADO_CARGO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO_CARGO := PAGOS_DIA.MONTO_PAGADO_CARGO * (-1);
                                End if;
                                
                                ------Cabecera Conceptos
                                --vl_conceptos_cab := vl_conceptos_cab;

                                --------Concepto <CONCEPTO>
                                vl_info_concepto := vl_info_concepto||' '||vl_clave_prod_serv_tag||'"'||vl_prod_serv||'"'||' '||vl_cantidad_concepto_tag||'"'||vl_cantidad_concepto||'"'||' '||vl_clave_unidad_concepto_tag||'"'||vl_clave_unidad_concepto||'"'||' '||vl_unidad_concepto_tag||'"'||vl_unidad_concepto||'"'||' '||vl_num_identificacion_tag||'"'||Pagos_dia.clave_cargo||'"'||' '||vl_descripcion_concepto_tag||'"'||Pagos_dia.DESCRIPCION_cargo||'"'||' '||vl_valor_unitario_concepto_tag||'"'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||'"'||' '||vl_importe_concepto_tag||'"'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||'"'||' '||vl_descuento_concepto_tag||'"'||vl_descuento||'"'||vl_info_concepto_cierre||chr(13);

                                ----Impuesto_trasladado_cabecera
                                vl_impuesto_tras_cab := vl_impuesto_tras_cab;
                                
                                --------Impuesto trasladado <IMPUESTO>
                                vl_impuesto := vl_impuesto_tras_cab ||' '||vl_base_tag||'"'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||'"'||' '||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||vl_importe_tag||'"'||pagos_dia.monto_iva||'"'||vl_impuesto_cierre||chr(13);

                                 vl_info_concepto := vl_info_concepto||vl_impuesto||vl_conceptos_cierre;                                                               
                                                                                                         
                                vl_total_imptras := vl_total_imptras + pagos_dia.monto_iva;
                                
                                ----Impuesto_trasladado_cierre
                                vl_impuesto_tras_cierre := vl_impuesto_tras_cierre;


                                ------Impuesto_retenido_cabecera
                                --vl_impuesto_ret_cab := vl_impuesto_ret_cab;

                                --------Impuesto retenido <RETENIDOS>
                                
                                vl_total_impret := 0;                
                                --vl_total_impret := vl_total_impret + pagos_dia.monto_iva;
                                --vl_impuesto_ret := vl_impuesto_ret  ||Pagos_dia.numero||'|'||PAGOS_DIA.MONTO_PAGADO_CARGO||'|'||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||pagos_dia.monto_iva||'|';


                                --Impuesto_retenido_cierre
                                --vl_impuesto_ret_cierre := vl_impuesto_ret_cierre;
                           
                                --DBMS_OUTPUT.PUT_LINE(vl_encabezado||'*'||vl_serie_folio||'*'||vl_entidad_receptor||'*'||vl_envio_correo||'*'||vl_dfiscales_utel||'*'||vl_dfiscales_receptor||'*'||vl_dfiscales_destinatario||'*'||vl_info_concepto||'*'||vl_impuesto||'*'||vl_impuesto_ret||'*'||vl_info_impuestos||'*'||vl_info_subtotal_imptras||'*'||vl_info_subtotal_impret||'*');

                         END LOOP;
                        
                        vl_subtotal := vl_subtotal - vn_iva;

                       ---------------- LLenamos Folio y SErie ENC(+)------------------
                        vl_serie_folio := vl_serie_folio||' '||vl_serie_tag||'"'||Sin_D_fiscales.serie||'"'||' '||vl_folio_tag||'"'||vl_consecutivo||'"'||
                                                                      ' '||vl_fecha_tag||'"'||pago.Fecha_pago||'"'||' '||vl_forma_pago_tag||'"'||vl_forma_pago||'"'||
                                                                      ' '||vl_condiciones_pago_tag||'"'||vl_condicion_pago||'"'||' '||vl_tipo_cambio_tag||'"'||vl_tipo_cambio||'"'||
                                                                      ' '||vl_moneda_tag||'"'||vl_tipo_moneda||'"'||' '||vl_metodo_pago_tag||'"'||vl_metodo_pago||'"'||
                                                                      ' '||vl_lugar_expedicion_tag||'"'||vl_lugar_expedicion||'"'||' '||vl_tipo_comprobante_tag||'"'||vl_tipo_comprobante||'"'||
                                                                      ' '||vl_subtotal_tag||'"'||to_char(vl_subtotal, 'fm9999999990.00')||'"'||' '||vl_descuento_tag||'"'||vl_descuento||'"'||' '||vl_total_tag||'"'||to_char(pago.MONTO_PAGADO, 'fm9999999990.00')||'"'||
                                                                      ' '||vl_confirmacion_tag||'"'||vl_confirmacion||'"'||' '||vl_tipo_comprobante_emi_tag||'"'||vl_tipo_documento||'"'||' '||'>';

--                         If vl_secuencia > 1 then 
--                                    vl_info_concepto := vl_info_concepto ||'<conceptos';
--                                    vl_impuesto :='<impuesto>';
--                         End if;
                        
                        
                        vl_clave_cargo := null;
                        vl_descrip_cargo := null;
                        vl_secuencia := vl_secuencia +1;
                       
                         
                      If vl_pago_total >  vl_pago_total_faltante then 
                             vl_pago_diferencia :=    vl_pago_total -  vl_pago_total_faltante;
                             
                             If vl_secuencia > 1 then 
                                    vl_info_concepto := vl_info_concepto ||'<conceptos';
                                    vl_impuesto :='<impuesto>';
                             End if;
                                
                                        Begin    
                                             Select TBBDETC_DETAIL_CODE, TBBDETC_DESC
                                               Into  vl_clave_cargo, vl_descrip_cargo
                                             from tbbdetc
                                             Where TBBDETC_DETAIL_CODE = substr (Sin_D_Fiscales.matricula, 1,2)||'NN'
                                             And TBBDETC_DCAT_CODE = 'COL';
                                         Exception
                                         when Others then 
                                             vl_clave_cargo := null;
                                              vl_descrip_cargo := null;
                                        End;
                                       
                                        If  vl_clave_cargo is not null and vl_descrip_cargo is not null then                              
                                                vl_info_concepto := vl_info_concepto||' '||vl_clave_prod_serv_tag||'"'||vl_prod_serv||'"'||' '||
                                                                                                             vl_cantidad_concepto_tag||'"'||vl_cantidad_concepto||'"'||' '||
                                                                                                             vl_clave_unidad_concepto_tag||'"'||vl_clave_unidad_concepto||'"'||' '||
                                                                                                             vl_unidad_concepto_tag||'"'||vl_unidad_concepto||'"'||' '||
                                                                                                             vl_num_identificacion_tag||'"'||vl_clave_cargo||'"'||' '||
                                                                                                             vl_descripcion_concepto_tag||'"'||vl_descrip_cargo||'"'||' '||
                                                                                                             vl_valor_unitario_concepto_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                             vl_importe_concepto_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                             vl_descuento_concepto_tag||'"'||vl_descuento||'"'||
                                                                                                             vl_info_concepto_cierre||chr(13);                                                                                                         

                                              If substr (Sin_D_Fiscales.matricula, 1,2) = '01' then 
                                                --------Impuesto trasladado LIMPTRAS(+)
                                                vl_impuesto := vl_impuesto_tras_cab ||' '||vl_base_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                               vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||
                                                                                                               vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||
                                                                                                               vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||
                                                                                                               vl_importe_tag||'"'||vl_pago_diferencia||'"'||
                                                                                                               vl_impuesto_cierre||chr(13);
                                                                                                               
                                                vl_total_imptras := vl_total_imptras + to_char(vl_pago_diferencia*(0/100));                                          
                                                
                                                vl_info_concepto := vl_info_concepto||vl_impuesto;    
                                                
                                                vl_total_impret := 0;                

                                              End if;
                                               
                                       End if;
                                       
                                       
                      End if;   
                                  

                        
                                 --vl_info_impuestos_comprobante <IMPUESTOS>
                                        vl_info_impuestos := vl_info_impuestos||' '||vl_totImpRet_tag||'"'||to_char(vl_total_impret,'fm9999999990.00')||'"'||' '||vl_totImpTras_tag||'"'||to_char(vl_total_imptras,'fm9999999990.00')||'"';
                           
                                --Info_subtotal_imptras  <IMPUESTO>
                                        vl_info_subtotal_imptras := vl_info_subtotal_imptras||' '||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||vl_importe_tag||'"'||to_char(vl_total_imptras,'fm9999999990.00')||'"';

                                 --Info_subtotal_impret <IMPUESTO>
                                        vl_info_subtotal_impret := vl_info_subtotal_impret||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_importe_tag||'"'||to_char(vl_total_impret,'fm9999999990.00')||'"';
                                                  
                                 --Flex_Header <FLEX_HEADER>
                                        vl_flex_header := vl_flex_header||' '||vl_folio_int_cl_fh_tag||'"'||vl_folio_interno_cl_fh||'"'||' '||vl_folio_int_nom_fh_tag||'"'||vl_folio_interno_fh||'"'||' '||vl_folio_int_val_fh_tag||'"'||Sin_D_Fiscales.PIDM||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_raz_soc_cl_fh_tag||'"'||vl_razon_social_cl_fh||'"'||' '||vl_raz_soc_nom_fh_tag||'"'||vl_razon_social_fh||'"'||' '||vl_raz_soc_val_fh_tag||'"'||nvl(Sin_D_fiscales.Nombre, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_met_pago_cl_fh_tag||'"'||vl_metodo_pago_cl_fh||'"'||' '||vl_met_pago_nom_fh_tag||'"'||vl_metodo_pago_fh||'"'||' '||vl_met_pago_val_fh_tag||'"'||nvl(pago.METODO_PAGO_CODE, '..')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_desc_met_pago_cl_fh_tag||'"'||vl_desc_metodo_pago_cl_fh||'"'||' '||vl_desc_met_pago_nom_fh_tag||'"'||vl_desc_metodo_pago_fh||'"'||' '||vl_desc_met_pago_val_fh_tag||'"'||nvl(pago.METODO_PAGO, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_id_pago_cl_fh_tag||'"'||vl_id_pago_cl_fh||'"'||' '||vl_id_pago_nom_fh_tag||'"'||vl_id_pago_pago_fh||'"'||' '||vl_id_pago_val_fh_tag||'"'||' '||nvl(pago.Id_pago, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_cl_fh_tag||'"'||vl_monto_cl_fh||'"'||' '||vl_monto_nom_fh_tag||'"'||vl_monto_fh||'"'||' '||vl_monto_val_fh_tag||'"'||nvl(to_char(pago.MONTO_PAGADO,'fm9999999990.00'), '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_nivel_cl_fh_tag||'"'||vl_nivel_cl_fh||'"'||' '||vl_nivel_nom_fh_tag||'"'||vl_nivel_fh||'"'||' '||vl_nivel_val_fh_tag||'"'||nvl(Sin_D_Fiscales.Nivel, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_campus_cl_fh_tag||'"'||vl_campus_cl_fh||'"'||' '||vl_campus_nom_fh_tag||'"'||vl_campus_fh||'"'||' '||vl_campus_val_fh_tag||'"'||nvl(Sin_D_fiscales.Campus, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_mat_alumno_cl_fh_tag||'"'||vl_matricula_alumno_cl_fh||'"'||' '||vl_mat_alumno_nom_fh_tag||'"'||vl_matricula_alumno_fh||'"'||' '||vl_mat_alumno_val_fh_tag||'"'||nvl(Sin_D_fiscales.MATRICULA, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_fecha_pago_cl_fh_tag||'"'||vl_fecha_pago_cl_fh||'"'||' '||vl_fecha_pago_nom_fh_tag||'"'||vl_fecha_pago_fh||'"'||' '||vl_fecha_pago_val_fh_tag||'"'||nvl(pago.Fecha_pago, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_referencia_cl_fh_tag||'"'||vl_referencia_cl_fh||'"'||' '||vl_referencia_nom_fh_tag||'"'||vl_referencia_fh||'"'||' '||vl_referencia_val_fh_tag||'"'||nvl(Sin_D_fiscales.Referencia, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_referencia_tipo_cl_fh_tag||'"'||vl_referencia_tipo_cl_fh||'"'||' '||vl_referencia_tipo_nom_fh_tag||'"'||vl_referencia_tipo_fh||'"'||' '||vl_referencia_tipo_val_fh_tag||'"'||nvl(Sin_D_fiscales.Ref_tipo, '')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_int_pag_tard_cl_fh_tag||'"'||vl_int_pago_tardio_cl_fh||'"'||' '||vl_int_pag_tard_nom_fh_tag||'"'||vl_int_pago_tardio_fh||'"'||' '||vl_int_pag_tard_val_fh_tag||'"'||nvl(vl_valor_int_pag_tard_fh, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_tipo_accesorio_cl_fh_tag||'"'||vl_tipo_accesorio_cl_fh||'"'||' '||vl_tipo_accesorio_nom_fh_tag||'"'||vl_tipo_accesorio_fh||'"'||' '||vl_tipo_accesorio_val_fh_tag||'"'||nvl(pago.tipo_accesorio, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_accesorio_cl_fh_tag||'"'||vl_monto_accesorio_cl_fh||'"'||' '||vl_monto_accesorio_nom_fh_tag||'"'||vl_monto_accesorio_fh||'"'||' '||vl_monto_accesorio_val_fh_tag||'"'||nvl(pago.monto_accesorio, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_otros_cl_fh_tag||'"'||vl_otros_cl_fh||'"'||' '||vl_otros_nom_fh_tag||'"'||vl_otros_fh||'"'||' '||vl_otros_val_fh_tag||'"'||nvl(vl_valor_otros_fh, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_otros_cl_fh_tag||'"'||vl_monto_otros_cl_fh||'"'||' '||vl_monto_otros_nom_fh_tag||'"'||vl_monto_otros_fh||'"'||' '||vl_monto_otros_val_fh_tag||'"'||nvl(vl_valor_monto_otros_fh, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                   vl_flex_header||' '||vl_nom_alumnos_cl_fh_tag||'"'||vl_nom_alumnos_cl_fh||'"'||' '||vl_nom_alumnos_nom_fh_tag||'"'||vl_nom_alumnos_fh||'"'||' '||vl_nom_alumnos_val_fh_tag||'"'||nvl(Sin_D_Fiscales.Nombre_Alumno, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_curp_cl_fh_tag||'"'||vl_curp_cl_fh||'"'||' '||vl_curp_nom_fh_tag||'"'||vl_curp_fh||'"'||' '||vl_curp_val_fh_tag||'"'||nvl(Sin_D_Fiscales.Curp, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_rfc_cl_fh_tag||'"'||vl_rfc_cl_fh||'"'||' '||vl_rfc_nom_fh_tag||'"'||vl_rfc_fh||'"'||' '||vl_rfc_val_fh_tag||'"'||nvl(Sin_D_Fiscales.RFC, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_grado_cl_fh_tag||'"'||vl_grado_cl_fh||'"'||' '||vl_grado_nom_fh_tag||'"'||vl_grado_fh||'"'||' '||vl_grado_val_fh_tag||'"'||nvl(Sin_D_Fiscales.Grado, '.')||'"'||vl_flex_header_cierre;


                                BEGIN
                                     INSERT INTO TZTFACT VALUES(
                                        Sin_D_Fiscales.PIDM
                                      , Sin_D_Fiscales.RFC
                                      , vl_total
                                      , 'FA'
                                      , NULL
                                      , NULL
                                      , sysdate
                                      ,vl_transaccion
                                      ,NULL
                                      ,vl_consecutivo
                                      ,Sin_D_fiscales.serie
                                      ,NULL
                                      ,NULL
                                      ,vl_cabecero||chr(10)||vl_cabe_soap||chr(10)||vl_soap_header||chr(10)||chr(9)||vl_soap_body||chr(10)||chr(9)||chr(9)||vl_neon_ws||chr(10)||vl_serie_folio||chr(10)||
                                      vl_envio_correo||chr(10)||vl_dfiscales_utel||chr(10)||vl_dfiscales_receptor||chr(10)||chr(9)||vl_flex_header||chr(10)||chr(9)||vl_info_concepto||chr(10)||chr(9)||
                                      --vl_impuesto_cab||chr(10)||chr(9)||chr(9)||chr(9)||vl_impuesto||chr(10)||chr(9)||chr(9)||vl_impuestos_cierre||chr(10)||chr(9)||
                                      vl_info_impuestos||vl_impuestos_cierre1||CHR(10)||chr(9)||
                                      vl_info_subtotal_imptras||vl_impuesto_cierre||chr(10)||chr(9)||vl_info_impuestos_cierre||chr(10)||chr(9)||vl_tipo_operacion||''||vl_valor_to||''||vl_tipo_operacion_cierre||chr(10)||
                                      vl_serie_folio_cierre||chr(10)||vl_neon_ws_cierre||chr(10)||chr(9)||vl_soap_body_cierre||chr(10)||vl_soap_envelope
                                      ,vl_tipo_archivo
                                      ,vl_tipo_fact
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL

                                 );
                                EXCEPTION
                                WHEN OTHERS THEN
                                 VL_ERROR := 'Se presento un error al insertar ' ||sqlerrm;
                                END;  


                                
                                  Begin
                                    
                                    Update tztdfut
                                    set TZTDFUT_FOLIO = vl_consecutivo
                                    Where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                                    Exception
                                    When Others then 
                                      VL_ERROR := 'Se presento un error al Actualizar ' ||sqlerrm;   
                                    End;
                         
                         If vn_commit >= 500 then 
                             commit;
                             vn_commit :=0;
                         End if;
                   
               
            End Loop pago;
         
      END LOOP;

   commit;
   --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
Exception
    when Others then
     ROLLBACK;
     --DBMS_OUTPUT.PUT_LINE('Error General'||sqlerrm);
END;


FUNCTION f_Referencia_Pago (p_referencia in varchar2, p_user_id in varchar2) RETURN varchar2
IS

vl_consecutivo number :=0;
p_error varchar2(2500) := 'EXITO';


          BEGIN

                           Begin
                                                    
                                    select nvl (max (TZTREPA_SEQ_NUM), 0)+1
                                    Into  vl_consecutivo
                                    from TZTREPA;
                                                   
                           End;
                               
                              BEGIN
                                 INSERT INTO TZTREPA VALUES(
                                    vl_consecutivo,
                                    p_referencia,
                                    p_user_id);
                            Exception
                            when Others then
                            p_error:= 'Error al insertar datos: '||sqlerrm;
                            END;

                          commit;  

                    Return (p_error);
         end; 
          

FUNCTION f_pagos_referencia (p_referencia in varchar2, p_transaccion in number, p_monto in number, p_fecha_pago in varchar2, p_id_pago in varchar2, p_referencia_ni in varchar2) RETURN varchar2
IS

p_error varchar2(2500) := 'EXITO';

        BEGIN

                             Begin
                                 INSERT INTO TZTREMP VALUES(
                                  p_referencia,
                                  p_transaccion,
                                  p_monto,
                                  p_fecha_pago,
                                  p_id_pago,
                                  p_referencia_ni
                                  );
                            Exception
                            when Others then
                            p_error:= 'Error al insertar datos: '||sqlerrm;
                            END;

                          commit;  

                    Return (p_error);
    
        END;
        
        
FUNCTION f_act_tztdfut (p_consec in number default null, p_rfc in varchar2 default null, p_r_social in varchar2 default null, p_certificado in number default null, p_folio in number default null, p_serie in varchar2 default null, p_direccion_1 in varchar2 default null, p_direccion_2 in varchar2 default null, p_ciudad in varchar2 default null, p_estado in varchar2 default null, p_pais in varchar2 default null, p_cp in varchar2 default null, p_email in varchar2 default null, p_referencia in varchar2 default null, p_prod_serv in varchar2 default null) RETURN varchar2

  is 

  p_error varchar2(2500) := 'EXITO';
  
      BEGIN
                  Begin
                       Update TZTDFUT
                       set TZTDFUT_RFC = nvl(p_rfc, TZTDFUT_RFC),
                            TZTDFUT_RAZON_SOC = nvl(p_r_social, TZTDFUT_RAZON_SOC),
                            TZTDFUT_CERTIFICADO = nvl(p_certificado, TZTDFUT_CERTIFICADO),
                            TZTDFUT_FOLIO = nvl(p_folio, TZTDFUT_FOLIO),
                            TZTDFUT_SERIE = nvl(p_serie, TZTDFUT_SERIE),
                            TZTDFUT_STREET_LINE1 = nvl(p_direccion_1, TZTDFUT_STREET_LINE1),
                            TZTDFUT_STREET_LINE3 = nvl(p_direccion_2, TZTDFUT_STREET_LINE3),
                            TZTDFUT_CITY = nvl(p_ciudad, TZTDFUT_CITY),
                            TZTDFUT_STAT_CODE = nvl(p_estado, TZTDFUT_STAT_CODE),
                            TZTDFUT_NATN_CODE = nvl(p_pais, TZTDFUT_NATN_CODE),
                            TZTDFUT_ZIP = nvl(p_cp, TZTDFUT_ZIP),
                            TZTDFUT_EMAIL_ADDRESS = nvl(p_email, TZTDFUT_EMAIL_ADDRESS),
                            TZTDFUT_REFERENCIA = nvl(p_referencia, TZTDFUT_REFERENCIA),
                            TZTDFUT_PROD_SERV_CODE = nvl(p_prod_serv, TZTDFUT_PROD_SERV_CODE)
                        where TZTDFUT_CONSEC = p_consec;
                       
                  Exception
                          when Others then
                              p_error:= 'Error al actualizar datos: '||sqlerrm;
                  End;

         Return (p_error);
               
    END ;
    
    
FUNCTION f_ins_tztdfut (p_rfc in varchar2, p_r_social in varchar2, p_certificado in number, p_folio in number, p_serie in varchar2, p_direccion_1 in varchar2, p_direccion_2 in varchar2, p_ciudad in varchar2, p_estado in varchar2, p_pais in varchar2, p_cp in varchar2, p_email in varchar2, p_referencia in varchar2, p_prod_serv in varchar2) RETURN varchar2
IS 

vl_consecutivo number :=0;
p_error varchar2(2500) := 'EXITO';

        BEGIN

                    Begin
                                                    
                            select nvl (max (TZTDFUT_CONSEC), 0)+1
                            Into  vl_consecutivo
                            from TZTDFUT;
                                                   
                   End;
            
                      Begin
                           INSERT INTO TZTDFUT VALUES(
                                vl_consecutivo,
                                p_rfc,
                                p_r_social,
                                p_certificado,
                                p_folio,
                                p_serie,
                                p_direccion_1,
                                p_direccion_2,
                                p_ciudad,
                                p_estado,
                                p_pais,
                                p_cp,
                                p_email,
                                p_referencia,
                                p_prod_serv
                                );
                            Exception
                            when Others then
                            p_error:= 'Error al insertar datos: '||sqlerrm;
                            END;

                          commit;  

                    Return (p_error);

        END;          
        

FUNCTION f_del_tztdfut (p_rfc in varchar2 default null) RETURN varchar2

  is 

  p_error varchar2(2500) := 'EXITO';
  
      BEGIN
                  Begin
                       Delete TZTDFUT
                       where TZTDFUT_RFC = p_rfc;
                       
                  Exception
                          when Others then
                              p_error:= 'Error al borrar datos: '||sqlerrm;
                  End;

         Return (p_error);
               
    END ;
    
PROCEDURE sp_no_identificados
IS

---- Se Arma el encazado de la factura DOC(+)-------------
vl_encabezado varchar2(4000):='DOC(+)';
vl_consecutivo number :=0;

-------------- LLenamos Folio y SErie ENC(+)
vl_serie_folio varchar2(2500):='ENC(+)';
vl_forma_pago varchar2(100):='99';
vl_condicion_pago varchar2(250):= 'Pago en una sola exhibición';
vl_tipo_cambio number:=1;
vl_tipo_moneda varchar2(10):= 'MXN';
vl_metodo_pago varchar2(10):= 'PUE';
vl_lugar_expedicion varchar2(10):= '53370';
vl_tipo_comprobante varchar2(5):= 'I';
vl_descuento varchar2(15):='0.00';
vl_total number(16,2);
vl_confirmacion varchar2(2);
vl_tipo_documento number:=1;
vl_subtotal number(16,2);


-------------------Entidad_receptor ENC_ERP(+)
vl_entidad_receptor varchar2(4000):='ENC_ERP(+)';

 
---------Envio por correo ENVIO_CFDI(+)
vl_envio_correo varchar2(4000):='ENVIO_CFDI(+)';
vl_enviar_xml varchar2(15):='TRUE';
vl_enviar_pdf varchar2(15):='TRUE';
vl_enviar_zip varchar2(15):='TRUE';


------Datos fiscales utel EMISOR(+)
vl_dfiscales_utel varchar2(4000):='EMISOR(+)';
vl_rfc_utel varchar2(15);
vl_razon_social_utel varchar2(250);
vl_regimen_fiscal varchar2(5):='601';
vl_id_emisor_sto number:=1;
vl_id_emisor_erp number:=1;


------Datos fiscales Alumno RECEPTOR(+)
vl_dfiscales_receptor varchar2(4000):='RECEPTOR(+)';
vl_referencia_dom_receptor varchar2(255):=' ';
--vl_id_tipo_receptor varchar2(25):='0';
--vl_id_receptor_sto varchar2(25):='0';
vl_estatus_registro varchar2(25):='1';
vl_uso_cfdi varchar2(25):='D10';
vl_residencia_fiscal varchar2(25);
vl_num_reg_id_trib varchar2(25);
--vl_id_receptor_erp varchar2(25);
--vl_id_receptor_padre varchar2(25);


------Datos fiscales Alumno DESTINATARIO(+)
vl_dfiscales_destinatario varchar2(4000):='RECEPTOR(+)';
vl_referencia_dom_destinatario varchar2(255):=' ';
vl_id_tipo_destinatario varchar2(25):='0';
vl_id_destinarario_sto varchar2(25):='0';


------Concepto L(+)
vl_info_concepto CLOB :='L(+)';
vl_num_linea number:=0;
vl_prod_serv varchar2(50);
vl_cantidad_concepto varchar2(10):='1';
vl_clave_unidad_concepto varchar2(10):='E48';
vl_unidad_concepto varchar2(50):='Servicio';
vl_importe_concepto number:=1;
vl_fecha_pago date;
vl_transaccion number :=0;


--Impuesto trasladado LIMPTRAS(+)
vl_impuesto varchar2(32000):='LIMPTRAS(+)';
vl_impuesto_cod varchar2(10):='002';
vl_tipo_factor_impuesto varchar2(15):='Tasa';
vl_tasa_cuota_impuesto varchar2(15);


--Impuesto retenido LIMPRET(+)
vl_impuesto_ret varchar2(4000):='LIMPRET(+)';
vl_base_impuesto_ret varchar2(25);
vl_impuesto_ret_cod varchar2(10):='002';
vl_tipo_factor_impuesto_ret varchar2(15):='Tasa';
vl_tasa_cuota_impuesto_ret varchar2(15);
vl_importe_impuesto_ret number(24,2);


--Info_impuestos_comprobante TOTIMP(+)
vl_info_impuestos varchar2(4000):='TOTIMP(+)';
vl_total_impret number(24,2);
vl_total_imptras number(24,2);


--Info_subtotal_imptras IMPTRAS(+)
vl_info_subtotal_imptras varchar2(4000):='IMPTRAS(+)';


--Info_subtotal_impret IMPRET(+)
vl_info_subtotal_impret varchar2(4000):='IMPRET(+)';
vl_error varchar2(2500):='EXITO';
vl_contador number:=0;
vl_existe number:=0;


--excedente
vl_pago_total number :=0;
vl_pago_total_faltante number :=0;
vl_pago_diferencia number :=0;
vl_clave_cargo varchar2(5):= null;
vl_descrip_cargo varchar2(90):= null;
vl_secuencia number:=0;


--Flex_Header FH(+)
vl_flex_header varchar2(4000):='FH(+)';
vl_folio_interno_cl_fh varchar2(50):='1';
vl_folio_interno_fh varchar2(255):='Folio_interno';
vl_razon_social_cl_fh varchar2(50):='2';
vl_razon_social_fh varchar2(255):='Razon_Social';
vl_metodo_pago_cl_fh varchar2(50):='3';
vl_metodo_pago_fh varchar2(255):='Metodo_de_pago';
vl_desc_metodo_pago_cl_fh varchar2(50):='4';
vl_desc_metodo_pago_fh varchar2(255):='Descripcion_de_metodo_de_pago';
vl_id_pago_cl_fh varchar2(50):='5';
vl_id_pago_pago_fh varchar2(255):='Id_pago';
vl_monto_cl_fh varchar2(50):='6';
vl_monto_fh varchar2(255):='Monto';
vl_nivel_cl_fh varchar2(50):='7';
vl_nivel_fh varchar2(255):='Nivel';
vl_campus_cl_fh varchar2(50):='8';
vl_campus_fh varchar2(255):='Campus';
vl_matricula_alumno_cl_fh varchar2(50):='9';
vl_matricula_alumno_fh varchar2(255):='Matricula_alumno';
vl_fecha_pago_cl_fh varchar2(50):='10';
vl_fecha_pago_fh varchar2(255):='Fecha_pago';
vl_referencia_cl_fh varchar2(50):='11';
vl_referencia_fh varchar2(255):='Referencia';
vl_referencia_tipo_cl_fh varchar2(50):='12';
vl_referencia_tipo_fh varchar2(255):='Referencia_tipo';
vl_int_pago_tardio_cl_fh varchar2(50):='13';
vl_int_pago_tardio_fh varchar2(255):='Interes_pago_tardio';
vl_valor_int_pag_tard_fh varchar2(255):= null;
vl_tipo_accesorio_cl_fh varchar2(50):='14';
vl_tipo_accesorio_fh varchar2(255):='Tipo_accesorio';
vl_monto_accesorio_cl_fh varchar2(50):='15';
vl_monto_accesorio_fh varchar2(255):='Monto_accesorio';
vl_otros_cl_fh varchar2(50):='16';
vl_otros_fh varchar2(255):='Otros';
vl_valor_otros_fh varchar2(255):= null;
vl_monto_otros_cl_fh varchar2(50):='17';
vl_monto_otros_fh varchar2(255):='Monto_otros';
vl_valor_monto_otros_fh varchar2(255):= null;
vl_nom_alumnos_cl_fh varchar2(50):='18';
vl_nom_alumnos_fh varchar2(255):='Nombre_alumno';
vl_curp_cl_fh varchar2(50):='19';
vl_curp_fh varchar2(255):='CURP';
vl_rfc_cl_fh varchar2(50):='20';
vl_rfc_fh varchar2(255):='RFC';
vl_grado_cl_fh varchar2(50):='21';
vl_grado_fh varchar2(255):='Grado';


------ Contadoor de registros
vn_commit  number :=0;

---- Manejo del IVA
vn_iva number:=0;


---- Tipo_Archivo
vl_tipo_archivo varchar2(50):='TXT';
vl_tipo_fact varchar2(50):='No_identificados';

vl_estatus_timbrado number :=0;
--   
BEGIN
   FOR Sin_D_Fiscales
              IN (  WITH CURP AS (
                                            select 
                                                SPRIDEN_PIDM PIDM,
                                                GORADID_ADDITIONAL_ID CURP
                                              from SPRIDEN
                                              left join GORADID on SPRIDEN_PIDM = GORADID_PIDM
                                              where GORADID_ADID_CODE = 'CURP'
                                              )
                        select distinct SPRIDEN_PIDM PIDM,
                                            SPRIDEN_ID MATRICULA,
                                            replace(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME Nombre_Alumno,
                                            SUBSTR(spriden_id,5) ID,
                                            SPREMRG_LAST_NAME Nombre,
                                            CASE
                                                 when SPREMRG_MI is null then
                                                 'XAXX010101000'
                                            end RFC,
                                            REGEXP_SUBSTR(SPREMRG_STREET_LINE1, '[^#"]+', 1, 1) Calle,
                                            NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#[^#]*'),2), 0) Num_Ext,
                                            NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#Int[^*]*'),2), 0) Num_Int,
                                            SPREMRG_STREET_LINE3 Colonia,
                                            SPREMRG_CITY AS Municipio,
                                            SPREMRG_ZIP AS CP,                                               
                                            SPREMRG_STAT_CODE Estado,
                                            SPREMRG_NATN_CODE AS Pais,
                                            'acruzsol@utel.edu.mx' Email,
                                            --GOREMAL_EMAIL_ADDRESS Email,
                                            CASE
                                                 when GORADID_ADID_CODE = 'REFH' then
                                                 'BH'
                                                 when GORADID_ADID_CODE = 'REFS' then
                                                 'BS'
                                                 when GORADID_ADID_CODE = 'REFU' then 
                                                 'UI'
                                            end Serie,
                                            SZVCAMP_CAMP_CODE Campus,
                                            GORADID_ADDITIONAL_ID Referencia,
                                            GORADID_ADID_CODE Ref_tipo,
                                            STVLEVL_DESC Nivel,
                                            CURP.CURP Curp,
                                            SARADAP_DEGC_CODE_1 Grado
                            from SPRIDEN
                            left join SPREMRG on SPRIDEN_PIDM = SPREMRG_PIDM
                            left outer join SARADAP on SPREMRG_PIDM = SARADAP_PIDM
                            left join STVLEVL on SARADAP_LEVL_CODE = STVLEVL_CODE
                            left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                            left join GORADID on GORADID_PIDM = SPRIDEN_PIDM 
                                and GORADID_ADID_CODE LIKE 'REF%'
                            join SZVCAMP on szvcamp_camp_alt_code=substr(SPRIDEN_ID,1,2)
                            left join CURP on SPREMRG_PIDM = CURP.PIDM
                            WHERE SPRIDEN_PIDM not in (SELECT SPREMRG_PIDM
                            FROM SPREMRG)
                                          and SPRIDEN_ID in (SELECT SPRIDEN_ID
                                                                       FROM SPRIDEN
                                                                       WHERE SPRIDEN_ID LIKE '%99000%')
                                       --and spriden_id ='020001218'
                                  ORDER BY SPRIDEN_PIDM)
   LOOP
          
            vl_pago_total:=0;
            vn_commit :=0;
           For pago in (
                               with accesorios as(
                                                        select distinct
                                                          TZTCRTE_PIDM Pidm,
                                                          TZTCRTE_LEVL as Nivel,
                                                          TZTCRTE_CAMP as Campus,
                                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                                          TZTCRTE_CAMPO17 as accesorios,
                                                          to_char(sum (TZTCRTE_CAMPO15),'fm9999999990.00') as Monto_accesorios,
                                                          TZTCRTE_CAMPO18 as Categoria,
                                                          TZTCRTE_CAMPO10 as Secuencia
                                                        from TZTCRTE
                                                        where  TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
                                                               and TZTCRTE_CAMPO18 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                                                group by TZTCRTE_PIDM, TZTCRTE_LEVL, TZTCRTE_CAMP, TZTCRTE_CAMPO11, TZTCRTE_CAMPO17, TZTCRTE_CAMPO18, TZTCRTE_CAMPO10
                                                                )
                                    SELECT DISTINCT 
                                            TBRACCD_PIDM PIDM,
                                            SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                            TBRACCD_DETAIL_CODE METODO_PAGO_CODE,
                                            TBRACCD_DESC METODO_PAGO,
                                            to_char (TBRACCD_EFFECTIVE_DATE,'RRRR-MM-DD"T"HH24:MI:SS') Fecha_pago,
                                            TBRACCD_PAYMENT_ID Id_pago,
                                            accesorios.accesorios tipo_accesorio,
                                            accesorios.Monto_accesorios monto_accesorio
                                    FROM TBRACCD
                                    left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                    LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                    LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                        AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                        AND TBRAPPL_REAPPL_IND IS NULL
                                    left join accesorios on tbraccd_pidm = accesorios.Pidm
                                    and TBRACCD_TRAN_NUMBER = accesorios.secuencia
                                    WHERE TBBDETC_TYPE_IND = 'P'
                                        AND TBBDETC_DCAT_CODE = 'CSH'
                                        AND TBRACCD_PIDM= Sin_D_Fiscales.pidm
                                        AND TRUNC (TBRACCD_EFFECTIVE_DATE) >= trunc(sysdate)
                                        AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                    FROM TZTFACT
                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                    ORDER BY TBRACCD_PIDM, 2 asc
                                    )
            loop

             If pago.MONTO_PAGADO like '-%' then
                    pago.MONTO_PAGADO := pago.MONTO_PAGADO * (-1);
                 End if;                            
                                    vn_commit := vn_commit +1;
                                    
                vl_pago_total := pago.MONTO_PAGADO;
                vl_subtotal := pago.MONTO_PAGADO;

                                            
                vl_num_linea:=0;
                vl_rfc_utel:= null; 
                vl_razon_social_utel:= null; 
                vl_prod_serv := null;      
                 vl_consecutivo :=0;
              
                vl_encabezado :='DOC(+)';
                vl_entidad_receptor :='ENC_ERP(+)';
                vl_envio_correo :='ENVIO_CFDI(+)';
                vl_dfiscales_utel :='EMISOR(+)';
                vl_dfiscales_receptor :='RECEPTOR(+)';
                vl_dfiscales_destinatario := 'DESTINATARIO(+)';     
                
                
                      --Emisor_STO
                        If Sin_D_Fiscales.serie = 'BH' then
                            vl_id_emisor_sto := 1;
                        Elsif Sin_D_Fiscales.serie = 'BS' then
                            vl_id_emisor_sto := 2;
                        End if;
                        
                      --Emisor_ERP
                         If Sin_D_Fiscales.serie = 'BH' then
                            vl_id_emisor_erp := 1;
                        Elsif Sin_D_Fiscales.serie = 'BS' then
                            vl_id_emisor_erp := 2;
                        End if; 

            --- Se obtiene el numero de consecutivo por empresa 
                    Begin

                    select nvl (max (TZTDFUT_FOLIO), 0)+1
                        Into  vl_consecutivo
                    from tztdfut
                    where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                    Exception
                    When Others then 
                        vl_consecutivo :=1;
                    End;

                   Begin
                        select 
                            TZTDFUT_RFC RFC,
                            TZTDFUT_RAZON_SOC RAZON_SOCIAL,
                            TZTDFUT_PROD_SERV_CODE
                        Into vl_rfc_utel, vl_razon_social_utel, vl_prod_serv
                        from TZTDFUT
                        where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                   exception
                   when others then
                        vl_error:= 'Error al Recuperer los datos Fiscales de la empresa' ||sqlerrm;
                   End;




                ---- Se Arma el encazado de la factura DOC(+)-------------
                vl_encabezado := vl_encabezado ||vl_consecutivo||'|';
                
                --------Datos fiscales utel EMISOR(+)
                vl_dfiscales_utel := vl_dfiscales_utel||vl_rfc_utel||'|'||vl_razon_social_utel||'|'||vl_regimen_fiscal||'|'||vl_id_emisor_sto||'|'||vl_id_emisor_erp||'|';
                
                -----Se envia por correo ENVIO_CFDI(+)
                vl_envio_correo := vl_envio_correo||vl_enviar_xml||'|'||vl_enviar_pdf||'|'||vl_enviar_zip||'|'||Sin_D_Fiscales.Email||'|';
                
                ----------Datos de entidad del receptor ENC_ERP(+)
                vl_entidad_receptor := vl_entidad_receptor ||vl_consecutivo||'|';
                
                --------Datos fiscales alumno RECEPTOR(+)
                vl_dfiscales_receptor := vl_dfiscales_receptor||Sin_D_Fiscales.RFC||'|'||pago.nombre_alumno||'|'||vl_residencia_fiscal||'|'||vl_num_reg_id_trib||'|'||vl_uso_cfdi||'|'||Sin_D_Fiscales.ID||'|'||Sin_D_Fiscales.ID||'|'||Sin_D_Fiscales.Num_Ext||'|'||Sin_D_Fiscales.Calle||'|'||Sin_D_Fiscales.Num_Int||'|'||Sin_D_Fiscales.Colonia||'|'||Sin_D_Fiscales.Municipio||'|'||vl_referencia_dom_receptor||'|'||Sin_D_Fiscales.Municipio||'|'||Sin_D_Fiscales.Estado||'|'||Sin_D_Fiscales.Pais||'|'||Sin_D_Fiscales.CP||'|'||Sin_D_Fiscales.Email||'|'||Sin_D_Fiscales.ID||'|'||vl_estatus_registro||'|';

                --------Datos fiscales alumno DESTINATARIO(+)
                vl_dfiscales_destinatario := vl_dfiscales_destinatario||Sin_D_Fiscales.RFC||'|'||Sin_D_Fiscales.Nombre||'|'||vl_uso_cfdi||'|'||vl_id_destinarario_sto||'|'||Sin_D_Fiscales.Num_Ext||'|'||Sin_D_Fiscales.Calle||'|'||Sin_D_Fiscales.Num_Int||'|'||Sin_D_Fiscales.Colonia||'|'||Sin_D_Fiscales.Municipio||'|'||vl_referencia_dom_destinatario||'|'||Sin_D_Fiscales.Municipio||'|'||Sin_D_Fiscales.Estado||'|'||Sin_D_Fiscales.Pais||'|'||Sin_D_Fiscales.CP||'|'||Sin_D_Fiscales.Email||'|'||vl_id_tipo_destinatario||'|'||vl_estatus_registro||'|';

                                    
                                    

                            vl_serie_folio :='ENC(+)';
                            vl_info_concepto :='L(+)';
                            vl_impuesto :='LIMPTRAS(+)';
                            vl_impuesto_ret :='LIMPRET(+)';
                            vl_info_impuestos :='TOTIMP(+)';
                            vl_info_subtotal_imptras :='IMPTRAS(+)';
                            vl_info_subtotal_impret :='IMPRET(+)';
                            vl_flex_header :='FH(+)';
                                               
                            vl_fecha_pago := null;
                            vl_transaccion  :=0;
                            vl_total_impret :=0;
                            vl_total_imptras :=0;
                            vl_contador :=0;
                              

                               ---------------- LLenamos Folio y SErie ENC(+)------------------
                                --vl_serie_folio := vl_serie_folio||Sin_D_fiscales.serie||'|'||vl_consecutivo||'|'||pago.Fecha_pago||'|'||vl_forma_pago||'|'||vl_condicion_pago||'|'||vl_tipo_cambio||'|'||vl_tipo_moneda||'|'||vl_metodo_pago||'|'||vl_lugar_expedicion||'|'||vl_tipo_comprobante||'|'||vl_subtotal||'|'||vl_descuento||'|'||pago.MONTO_PAGADO||'|'||vl_confirmacion||'|'||vl_tipo_documento||'|';

                            vl_pago_total_faltante:=0;
                            vl_secuencia :=0;
                            vn_iva :=0;

                               FOR Pagos_dia
                                        IN (
                                              with cargo as (
                                                                    Select distinct tbraccd_pidm pidm, tbraccd_detail_code cargo, tbraccd_tran_number transa, tbraccd_desc descripcion 
                                                                    from tbraccd),
                                                                    iva as (
                                                                    select distinct TVRACCD_PIDM pidm, TVRACCD_AMOUNT monto_iva, TVRACCD_ACCD_TRAN_NUMBER iva_tran
                                                                    from tvraccd
                                                                    where TVRACCD_DETAIL_CODE like 'IV%'
                                                                    )
                                                        SELECT DISTINCT 
                                                            TBRACCD_PIDM PIDM,
                                                            SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                                            to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                                           nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                                            to_char(TBRACCD_EFFECTIVE_DATE, 'dd/mm/rrrr') Fecha_pago,
                                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                                            TBBDETC_DESC DESCRIPCION,
                                                            nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                                            nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                                            to_char(nvl (iva.monto_iva, 0),'fm9999999990.00') monto_iva,
                                                            iva.iva_tran iva_transaccion,
                                                            ROW_NUMBER() OVER(PARTITION BY TBRACCD_TRAN_NUMBER ORDER BY TBRACCD_EFFECTIVE_DATE) numero
                                                        FROM TBRACCD
                                                        left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                                        LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                        LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                                            AND TBRAPPL_REAPPL_IND IS NULL
                                                        left join cargo on cargo.pidm = tbraccd_pidm
                                                            and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                                        left join iva on iva.pidm = TBRACCD_PIDM
                                                            and iva.iva_tran = TBRACCD_TRAN_NUMBER
                                                        WHERE     TBBDETC_TYPE_IND = 'P'
                                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                                            AND TBRACCD_PIDM= pago.pidm
                                                            And TBRACCD_TRAN_NUMBER = pago.TRANSACCION
                                                            AND TRUNC (TBRACCD_EFFECTIVE_DATE) >= trunc(sysdate)
                                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                                    FROM TZTFACT
                                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                                        ORDER BY TBRACCD_PIDM, 2,13 asc
                                           )    
                         LOOP

                              vl_contador := vl_contador +1;
                              vl_pago_total_faltante := vl_pago_total_faltante + Pagos_dia.MONTO_PAGADO_CARGO;
                              vl_secuencia :=Pagos_dia.numero;
                              vn_iva :=  vn_iva + Pagos_dia.monto_iva;


                             BEGIN
                             
                                select '01'
                                     INTO vl_forma_pago
                                from tbraccd a, spriden b
                                where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                              from tbbdetc
                                                                              where TBBDETC_DCAT_CODE = 'CSH'
                                                                               and TBBDETC_TYPE_IND = 'P')
                                   and tbraccd_pidm = spriden_pidm
                                   and spriden_change_ind is null
                                   AND spriden_pidm = Pagos_dia.PIDM
                                   AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                   and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                          FROM ZSTPARA
                                                                                          WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                          AND ZSTPARA_PARAM_ID = 'EFECTIVO');
                             
                             EXCEPTION           
                               WHEN OTHERS THEN NULL;
                                 vl_forma_pago:='99';
                                 BEGIN
                                     
                                     select '02'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                  FROM ZSTPARA
                                                                                                  WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                  AND ZSTPARA_PARAM_ID = 'CHEQUE');
                                     
                                     
                                 EXCEPTION           
                                   WHEN OTHERS THEN NULL;
                                     vl_forma_pago:='99';
                                     BEGIN

                                        select '03'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                  FROM ZSTPARA
                                                                                                  WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                  AND ZSTPARA_PARAM_ID = 'TRANSFERENCIA');

                                     EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_forma_pago:='99';
                                        BEGIN

                                        select '04'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select  ZSTPARA_PARAM_VALOR
                                                                                                  FROM ZSTPARA
                                                                                                  WHERE ZSTPARA_MAPA_ID = 'FORMA_PAGO'
                                                                                                  AND ZSTPARA_PARAM_ID = 'TARJETA_DE_CREDITO');

                                         EXCEPTION           
                                           WHEN OTHERS THEN NULL;
                                             vl_forma_pago:='99';
                                        END;
                                     END;
                                 END;
                         END;

                             If PAGOS_DIA.MONTO_PAGADO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO := PAGOS_DIA.MONTO_PAGADO * (-1);
                                End if; 
                            
                            ------------------- Seteo ---------------
                           
                            vl_total :=PAGOS_DIA.MONTO_PAGADO;
                            vl_fecha_pago := PAGOS_DIA.Fecha_pago;
                            vl_transaccion :=PAGOS_DIA.TRANSACCION;



                            ----
                                If Pagos_dia.numero > 1 then 
                                    vl_info_concepto := vl_info_concepto ||'L(+)';
                                    vl_impuesto :='LIMPTRAS(+)';
                                End if;
                                
                                
                                If Pagos_dia.monto_iva > 0 then
                                    vl_tasa_cuota_impuesto := '0.160000';
                                Elsif Pagos_dia.monto_iva = 0 then
                                    vl_tasa_cuota_impuesto := '0.000000';
                                End if;
                                
                                
                                If PAGOS_DIA.MONTO_PAGADO_CARGO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO_CARGO := PAGOS_DIA.MONTO_PAGADO_CARGO * (-1);
                                End if;
                                
                                                              
                                --------Concepto L(+)
                                vl_info_concepto := vl_info_concepto||Pagos_dia.numero||'|'||vl_prod_serv||'|'||vl_cantidad_concepto||'|'||vl_clave_unidad_concepto||'|'||vl_unidad_concepto||'|'||Pagos_dia.clave_cargo||'|'||Pagos_dia.DESCRIPCION_cargo||'|'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||'|'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||'|'||vl_descuento||'|'||chr(13);

                                --------Impuesto trasladado LIMPTRAS(+)
                                vl_impuesto := vl_impuesto ||Pagos_dia.numero||'|'||to_char(PAGOS_DIA.MONTO_PAGADO_CARGO, 'fm9999999990.00')||'|'||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||pagos_dia.monto_iva||'|'||chr(13);
                                
                                
                               vl_info_concepto := vl_info_concepto||vl_impuesto;                                                                         
                                                                                                         
                                vl_total_imptras := vl_total_imptras + pagos_dia.monto_iva;
                                

                                --------Impuesto retenido LIMPRET(+)
                                
                                vl_total_impret := 0;         
                                --vl_total_impret := vl_total_impret + pagos_dia.monto_iva;
                             --   vl_impuesto_ret := vl_impuesto_ret  ||Pagos_dia.numero||'|'||PAGOS_DIA.MONTO_PAGADO_CARGO||'|'||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||pagos_dia.monto_iva||'|';
                            
                                
                                --DBMS_OUTPUT.PUT_LINE(vl_encabezado||'*'||vl_serie_folio||'*'||vl_entidad_receptor||'*'||vl_envio_correo||'*'||vl_dfiscales_utel||'*'||vl_dfiscales_receptor||'*'||vl_dfiscales_destinatario||'*'||vl_info_concepto||'*'||vl_impuesto||'*'||vl_impuesto_ret||'*'||vl_info_impuestos||'*'||vl_info_subtotal_imptras||'*'||vl_info_subtotal_impret||'*');

                         END LOOP;

                        vl_subtotal := vl_subtotal - vn_iva;
                        

                       ---------------- LLenamos Folio y SErie ENC(+)------------------
                         vl_serie_folio := vl_serie_folio||Sin_D_Fiscales.serie||'|'||vl_consecutivo||'|'||pago.Fecha_pago||'|'||vl_forma_pago||
                                                                                                       '|'||vl_condicion_pago||'|'||vl_tipo_cambio||'|'||vl_tipo_moneda||
                                                                                                       '|'||vl_metodo_pago||'|'||vl_lugar_expedicion||'|'||vl_tipo_comprobante||
                                                                                                       '|'||to_char(vl_subtotal, 'fm9999999990.00')||'|'||vl_descuento||
                                                                                                       '|'||to_char(pago.MONTO_PAGADO, 'fm9999999990.00')||'|'||vl_confirmacion||'|'||vl_tipo_documento||'|';
                        
--                         If vl_secuencia > 1 then 
--                                    vl_info_concepto := vl_info_concepto ||'L(+)';
--                                    vl_impuesto :='LIMPTRAS(+)';
--                         End if;
                        
                        
                        vl_clave_cargo := null;
                        vl_descrip_cargo := null;
                        vl_secuencia := vl_secuencia +1;
                       
                         
                      If vl_pago_total >  vl_pago_total_faltante then 
                             vl_pago_diferencia :=    vl_pago_total -  vl_pago_total_faltante;
                             
                         If vl_secuencia > 1 then 
                                    vl_info_concepto := vl_info_concepto ||'L(+)';
                                    vl_impuesto :='LIMPTRAS(+)';
                         End if;
                                
                                        Begin    
                                             Select TBBDETC_DETAIL_CODE, TBBDETC_DESC
                                               Into  vl_clave_cargo, vl_descrip_cargo
                                             from tbbdetc
                                             Where TBBDETC_DETAIL_CODE = substr (Sin_D_Fiscales.matricula, 1,2)||'NN'
                                             And TBBDETC_DCAT_CODE = 'COL';
                                         Exception
                                         when Others then 
                                             vl_clave_cargo := null;
                                              vl_descrip_cargo := null;
                                        End;
                                       
                                        If  vl_clave_cargo is not null and vl_descrip_cargo is not null then                              
                                                vl_info_concepto := vl_info_concepto||vl_secuencia  ||'|'||
                                                                                                        vl_prod_serv||'|'||
                                                                                                        vl_cantidad_concepto||'|'||
                                                                                                        vl_clave_unidad_concepto||'|'||
                                                                                                        vl_unidad_concepto||'|'||
                                                                                                        vl_clave_cargo||'|'||
                                                                                                        vl_descrip_cargo||'|'||
                                                                                                        to_char(vl_pago_diferencia,'fm9999999990.00')||'|'||
                                                                                                        to_char(vl_pago_diferencia,'fm9999999990.00')||'|'||vl_descuento||'|'||chr(13);

                                              If substr (Sin_D_Fiscales.matricula, 1,2) = '01' then 
                                                --------Impuesto trasladado LIMPTRAS(+)
                                                vl_impuesto := vl_impuesto ||vl_secuencia ||'|'||
                                                                                            vl_pago_diferencia||'|'||
                                                                                            vl_impuesto_cod||'|'||
                                                                                            vl_tipo_factor_impuesto||'|'||
                                                                                            vl_tasa_cuota_impuesto||'|'||
                                                                                            to_char(to_char(vl_pago_diferencia*(0/100)),'fm9999999990.00')||'|'||chr(13);
                                                vl_total_imptras := vl_total_imptras + to_char(vl_pago_diferencia*(0/100));                                          
                                                
                                                vl_info_concepto := vl_info_concepto||vl_impuesto;    
                                                
                                                vl_total_impret := 0;                

                                              End if;
                                               
                                       End if;
                                       
                                       
                      End if;
                         

                         
                                 --vl_info_impuestos_comprobante TOTIMP(+)
                                        vl_info_impuestos := vl_info_impuestos||to_char(vl_total_impret,'fm9999999990.00')||'|'||to_char(vl_total_imptras,'fm9999999990.00')||'|';
                           
                                --Info_subtotal_imptras  IMPTRAS(+)
                                        vl_info_subtotal_imptras := vl_info_subtotal_imptras||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||to_char(vl_total_imptras,'fm9999999990.00')||'|';

                                               --Info_subtotal_impret IMPRET(+)
                                        vl_info_subtotal_impret := vl_info_subtotal_impret||vl_impuesto_cod||'|'||to_char(vl_total_impret,'fm9999999990.00')||'|';
                                        
                               --Flex_Header FH(+)
                                        vl_flex_header := vl_flex_header||vl_folio_interno_cl_fh||'|'||vl_folio_interno_fh||'|'||Sin_D_Fiscales.PIDM||'|'||chr(10)||
                                                                  vl_flex_header||vl_razon_social_cl_fh||'|'||vl_razon_social_fh||'|'||nvl(Sin_D_fiscales.Nombre, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_metodo_pago_cl_fh||'|'||vl_metodo_pago_fh||'|'||nvl(pago.METODO_PAGO_CODE, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_desc_metodo_pago_cl_fh||'|'||vl_desc_metodo_pago_fh||'|'||nvl(pago.METODO_PAGO, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_id_pago_cl_fh||'|'||vl_id_pago_pago_fh||'|'||nvl(pago.Id_pago, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_monto_cl_fh||'|'||vl_monto_fh||'|'||nvl(to_char(pago.MONTO_PAGADO,'fm9999999990.00'), '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_nivel_cl_fh||'|'||vl_nivel_fh||'|'||nvl(Sin_D_Fiscales.Nivel, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_campus_cl_fh||'|'||vl_campus_fh||'|'||nvl(Sin_D_fiscales.Campus, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_matricula_alumno_cl_fh||'|'||vl_matricula_alumno_fh||'|'||nvl(Sin_D_fiscales.MATRICULA, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_fecha_pago_cl_fh||'|'||vl_fecha_pago_fh||'|'||nvl(pago.Fecha_pago, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_referencia_cl_fh||'|'||vl_referencia_fh||'|'||nvl(Sin_D_fiscales.Referencia, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_referencia_tipo_cl_fh||'|'||vl_referencia_tipo_fh||'|'||nvl(Sin_D_fiscales.Ref_tipo, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_int_pago_tardio_cl_fh||'|'||vl_int_pago_tardio_fh||'|'||nvl(vl_valor_int_pag_tard_fh, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_tipo_accesorio_cl_fh||'|'||vl_tipo_accesorio_fh||'|'||nvl(pago.tipo_accesorio, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_monto_accesorio_cl_fh||'|'||vl_monto_accesorio_fh||'|'||nvl(pago.monto_accesorio, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_otros_cl_fh||'|'||vl_otros_fh||'|'||nvl(vl_valor_otros_fh, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_monto_otros_cl_fh||'|'||vl_monto_otros_fh||'|'||nvl(vl_valor_monto_otros_fh, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_nom_alumnos_cl_fh||'|'||vl_nom_alumnos_fh||'|'||nvl(Sin_D_Fiscales.Nombre_Alumno, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_curp_cl_fh||'|'||vl_curp_fh||'|'||nvl(Sin_D_Fiscales.Curp, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_rfc_cl_fh||'|'||vl_rfc_fh||'|'||nvl(Sin_D_Fiscales.RFC, '.')||'|'||chr(10)||
                                                                  vl_flex_header||vl_grado_cl_fh||'|'||vl_grado_fh||'|'||nvl(Sin_D_Fiscales.Grado, '.')||'|';
                                                                  

                              
                                BEGIN
                                     INSERT INTO TZTFACT VALUES(
                                        Sin_D_Fiscales.PIDM
                                      , Sin_D_Fiscales.RFC
                                      , vl_total
                                      , 'FA'
                                      , NULL
                                      , NULL
                                      , sysdate
                                      ,vl_transaccion
                                      ,vl_encabezado||chr(10)||vl_serie_folio||chr(10)||vl_entidad_receptor||chr(10)||vl_envio_correo
                                      ||chr(10)||vl_dfiscales_utel||chr(10)||vl_dfiscales_receptor||chr(10)||vl_flex_header||chr(10)||vl_info_concepto||chr(10)
                                      --||vl_impuesto||chr(10)
                                      ||vl_info_impuestos||chr(10)||vl_info_subtotal_imptras||chr(10)||vl_info_subtotal_impret
                                      ,vl_consecutivo
                                      ,sin_d_fiscales.serie
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,vl_tipo_archivo
                                      ,vl_tipo_fact
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL
                                      ,NULL

                                 );
                                EXCEPTION
                                WHEN OTHERS THEN
                                 VL_ERROR := 'Se presento un error al insertar ' ||sqlerrm;
                                 --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
                                END;  


                                
                                  Begin
                                    
                                    Update tztdfut
                                    set TZTDFUT_FOLIO = vl_consecutivo
                                    Where TZTDFUT_SERIE = Sin_D_Fiscales.serie;
                                    Exception
                                    When Others then 
                                      VL_ERROR := 'Se presento un error al Actualizar ' ||sqlerrm;   
                                    End;
                         
                         If vn_commit >= 500 then 
                             commit;
                             vn_commit :=0;
                         End if;
                   
               
            End Loop Pago;
         
      END LOOP;

   commit;
   --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
Exception
    when Others then
     ROLLBACK;
     --DBMS_OUTPUT.PUT_LINE('Error General'||sqlerrm);
END;

PROCEDURE sp_Datos_Facturacion_xml_PB
IS

----Cabecero-----------
vl_cabecero varchar2(4000) :='<?xml version="1.0" encoding="UTF-8" ?>'; 
--'<?xml version="1.0" encoding="UTF-8"?>';

--Cabecero SOAP-------
vl_cabe_soap varchar2(4000) := '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:neon="http://neon.stoconsulting.com/NeonEmisionWS/NeonEmisionWS">';

--SOAP_Header------
vl_soap_header varchar2(4000) := '<soap:Header/>';
vl_soap_envelope varchar2(4000) := '</soap:Envelope>';

--SOAP_BOdy-------
vl_soap_body varchar2(4000) := '<soap:Body>';
vl_soap_body_cierre varchar2(4000) := '</soap:Body>';

--NEON_WS------
vl_neon_ws varchar2(4000) := '<neon:emitirWS>';
vl_neon_ws_cierre varchar2(4000) := '</neon:emitirWS>';

---- Se Arma el encazado de la factura <DOCUMENTOS>-------------
--vl_encabezado varchar2(4000):='<documentos>';
vl_consecutivo number :=0;
--vl_documentos_cierre varchar2(4000):='</documentos>';

-------------- LLenamos Folio y SErie <DOCUMENTO>
vl_serie_folio varchar2(2500):='<comprobante';
vl_forma_pago varchar2(100);
vl_condicion_pago varchar2(250):= 'Pago en una sola exhibicion';
vl_tipo_cambio number:=1;
vl_tipo_moneda varchar2(10):= 'MXN';
vl_metodo_pago varchar2(10):= 'PUE';
vl_lugar_expedicion varchar2(10):= '53370';
vl_tipo_comprobante varchar2(5):= 'I';
vl_descuento varchar2(15):='0.00';
vl_total number(16,2);
vl_confirmacion varchar2(2);
vl_tipo_documento number:=1;
vl_subtotal number(16,2);
vl_serie_folio_cierre varchar2(2500):='</comprobante>';
vl_serie_tag varchar2(250):='serie=';
vl_folio_tag varchar2(250):='folio=';
vl_fecha_tag varchar2(250):='fecha=';
vl_forma_pago_tag varchar2(250):='formaPago=';
vl_condiciones_pago_tag varchar2(250):='condicionesDePago=';
vl_tipo_cambio_tag varchar2(250):='tipoCambio=';
vl_moneda_tag varchar2(250):='moneda=';
vl_metodo_pago_tag varchar2(250):='metodoPago=';
vl_lugar_expedicion_tag varchar2(250):='lugarExpedicion=';
vl_tipo_comprobante_tag varchar2(250):='tipoComprobante=';
vl_subtotal_tag varchar2(250):='subTotal=';
vl_descuento_tag varchar2(250):='descuento=';
vl_total_tag varchar2(250):='total=';
vl_confirmacion_tag varchar2(250):='confirmacion=';
vl_tipo_comprobante_emi_tag varchar2(250):='tipoDocumento=';


-------------------Entidad_receptor <DOCUMENTO_ERP>
--vl_entidad_receptor varchar2(4000):='<documentoErp>';
--vl_entidad_receptor_cierre varchar2(4000):='</documentoErp>';
--vl_id_trx_erp_tag varchar2(250):='id_trx_erp=';

 
---------Envio por correo <ENVIO_CFDI>
vl_envio_correo varchar2(4000):='<envioCfdi';
vl_enviar_xml varchar2(15):='1';
vl_enviar_pdf varchar2(15):='1';
vl_enviar_zip varchar2(15):='1';
vl_xml_tag varchar2(250):='enviarXml=';
vl_pdf_tag varchar2(250):='enviarPdf=';
vl_zip_tag varchar2(250):='enviarZip=';
vl_email_tag varchar2(250):='emails=';
vl_envio_correo_cierre varchar2(4000):='/>';


------Datos fiscales utel <EMISOR>
vl_dfiscales_utel varchar2(4000):='<emisor';
vl_rfc_utel varchar2(15);
vl_razon_social_utel varchar2(250);
vl_regimen_fiscal varchar2(5):='601';
vl_id_emisor_sto number:=1;
vl_id_emisor_erp number:=1;
vl_dfiscales_utel_cierre varchar2(4000):='/>';
vl_rfc_tag varchar2(250):='rfc=';
vl_nombre_tag varchar2(250):='nombre=';
vl_regimen_fiscal_tag varchar2(250):='regimenFiscal=';
vl_id_emisor_sto_tag varchar2(250):='idEmisorSto=';
vl_id_emisor_erp_tag varchar2(250):='idEmisorErp=';


------Datos fiscales Alumno <RECEPTOR>
vl_dfiscales_receptor varchar2(4000):='<receptor';
vl_referencia_dom_receptor varchar2(255):=' ';
--vl_id_tipo_receptor varchar2(25):='0';
--vl_id_receptor_sto varchar2(25):='0';
vl_estatus_registro varchar2(25):='1';
vl_uso_cfdi varchar2(25):='D10';
vl_residencia_fiscal varchar2(25);
vl_num_reg_id_trib varchar2(25);
--vl_id_receptor_erp varchar2(25);
--vl_id_receptor_padre varchar2(25);
vl_cierre_receptor varchar2(4000):='/>';
vl_rfc_receptor_tag varchar2(250):='rfc=';
vl_nombre_receptor_tag varchar2(250):='nombre=';
vl_residencia_fiscal_tag varchar2(250):='residenciaFiscal=';
vl_num_reg_id_trib_tag varchar2(250):='numRegIdTrib=';
vl_uso_cfdi_tag varchar2(250):='usoCfdi=';
vl_id_receptor_sto_tag varchar2(250):='idReceptoSto=';
vl_id_receptor_erp_tag varchar2(250):='idReceptorErp=';
vl_numero_exterior_tag varchar2(250):='numeroExterior=';
vl_calle_tag varchar2(250):='calle=';
vl_numero_interior_tag varchar2(250):='numeroInterior=';
vl_colonia_tag varchar2(250):='colonia=';
vl_localidad_tag varchar2(250):='localidad=';
vl_referencia_tag varchar2(250):='referencia=';
vl_municipio_tag varchar2(250):='municipio=';
vl_estado_tag varchar2(250):='estado=';
vl_pais_tag varchar2(250):='pais=';
vl_codigo_postal_tag varchar2(250):='codigoPostal=';
vl_email_receptor_tag varchar2(250):='email=';
vl_id_tipo_receptor_tag varchar2(250):='idTipoReceptor=';
--vl_id_receptor_padre_tag varchar2(250):='id_receptor_padre=';
vl_estatus_registro_tag varchar2(250):='estatusRegistro=';
vl_id varchar2(25):='1';


------Datos fiscales Alumno <DESTINATARIO>
vl_dfiscales_destinatario varchar2(4000):='<destinatario>';
vl_referencia_dom_destinatario varchar2(255):=' ';
vl_id_tipo_destinatario varchar2(25):='0';
vl_id_destinarario_sto varchar2(25):='0';


-----Cabecera Conceptos
--vl_conceptos_cab varchar2(4000):='<conceptos>';
vl_conceptos_cierre varchar2(4000):='</conceptos>';

------Concepto <CONCEPTO>
vl_info_concepto CLOB :='<conceptos';
vl_num_linea number:=0;
vl_prod_serv varchar2(50);
vl_cantidad_concepto varchar2(10):='1';
vl_clave_unidad_concepto varchar2(10):='E48';
vl_unidad_concepto varchar2(50):='Servicio';
vl_importe_concepto number:=1;
vl_fecha_pago date;
vl_transaccion number :=0;
vl_info_concepto_cierre varchar2(4000) := '>';
vl_numero_linea_concepto_tag varchar2(250):='numeroLinea=';
vl_clave_prod_serv_tag varchar2(250):='claveProdServ=';
vl_cantidad_concepto_tag varchar2(250):='cantidad=';
vl_clave_unidad_concepto_tag varchar2(250):='claveUnidad=';
vl_unidad_concepto_tag varchar2(250):='unidad=';
vl_num_identificacion_tag varchar2(250):='numIdentificacion=';
vl_descripcion_concepto_tag varchar2(250):='descripcion=';
vl_valor_unitario_concepto_tag varchar2(250):='valorUnitario=';
vl_importe_concepto_tag varchar2(250):='importe=';
vl_descuento_concepto_tag varchar2(250):='descuento=';


----Cabecera Impuestos
vl_impuesto_cab varchar2(4000):='<impuestos>';
vl_impuestos_cierre varchar2(4000):='</impuestos>';
vl_impuestos_cierre1 varchar2(4000):='>';


--Impuesto trasladado <IMPUESTO>
vl_impuesto_tras_cab varchar2(4000):='<trasladados';
vl_impuesto varchar2(4000):='<impuesto>';
vl_impuesto_cod varchar2(10):='002';
vl_tipo_factor_impuesto varchar2(15):='Tasa';
vl_tasa_cuota_impuesto varchar2(15);
vl_impuesto_cierre varchar2(4000):='/>';
vl_impuesto_tras_cierre varchar2(4000):='</impuestos>';
vl_base_tag varchar2(250):='base=';
vl_impuesto_tag varchar2(250):='impuesto=';
vl_tipo_factor_tag varchar2(250):='tipoFactor=';
vl_tasa_o_cuota_tag varchar2(250):='tasaOCuota=';
vl_importe_tag varchar2(250):='importe=';


--Impuesto retenido <RETENIDOS>
vl_impuesto_ret_cab varchar2(4000):='<retenidos>';
vl_impuesto_ret varchar2(4000):='<impuesto>';
vl_base_impuesto_ret varchar2(25);
vl_impuesto_ret_cod varchar2(10):='002';
vl_tipo_factor_impuesto_ret varchar2(15):='Tasa';
vl_tasa_cuota_impuesto_ret varchar2(15);
vl_importe_impuesto_ret number(24,6);
vl_impuesto_ret_cierre varchar2(4000):='</retenidos>';


--Info_impuestos_comprobante <IMPUESTOS>
vl_info_impuestos varchar2(4000):='<impuestos';
vl_total_impret number(24,6);
vl_total_imptras number(24,6);
vl_info_impuestos_cierre varchar2(4000):='</impuestos>';
vl_totImpRet_tag varchar2(250):='totalImpuestosRetenidos=';
vl_totImpTras_tag varchar2(250):='totalImpuestosTrasladados=';


--Cabecera subtotales trasladados
vl_sub_imptras_cab varchar2(4000):='<trasladados>';
vl_sub_imptras_cierre varchar2(4000):='</trasladados>';


--Info_subtotal_imptras <IMPUESTO>
vl_info_subtotal_imptras varchar2(4000):='<trasladados';


--Cabecera subtotales retenidos
vl_sub_impret_cab varchar2(4000):='<retenidos>';
vl_sub_impret_cierre varchar2(4000):='</retenidos>';


--Info_subtotal_impret <IMPUESTO>
vl_info_subtotal_impret varchar2(4000):='<impuesto>';

vl_error varchar2(2500):='EXITO';
vl_contador number:=0;
vl_existe number:=0;


--Tipo_operacion---------
vl_tipo_operacion varchar2(4000):='<tipoOperacion>';
vl_valor_to varchar2(30):='sincrono';
vl_tipo_operacion_cierre varchar2(4000):='</tipoOperacion>';


--excedente
vl_pago_total number :=0;
vl_pago_total_faltante number :=0;
vl_pago_diferencia number :=0;
vl_clave_cargo varchar2(5):= null;
vl_descrip_cargo varchar2(90):= null;
vl_secuencia number:=0;


--Flex_Header FH(+)
vl_flex_headers_cab varchar2(4000):='<flexHeaders>';
vl_flex_header varchar2(4000):='<flexHeaders';
vl_folio_interno_cl_fh varchar2(50):='1';
vl_folio_interno_fh varchar2(255):='folioInterno';
vl_razon_social_cl_fh varchar2(50):='2';
vl_razon_social_fh varchar2(255):='razonSocial';
vl_metodo_pago_cl_fh varchar2(50):='3';
vl_metodo_pago_fh varchar2(255):='metodoDePago';
vl_desc_metodo_pago_cl_fh varchar2(50):='4';
vl_desc_metodo_pago_fh varchar2(255):='descripcionDeMetodoDePago';
vl_id_pago_cl_fh varchar2(50):='5';
vl_id_pago_pago_fh varchar2(255):='IdPago';
vl_monto_cl_fh varchar2(50):='6';
vl_monto_fh varchar2(255):='Monto';
vl_nivel_cl_fh varchar2(50):='7';
vl_nivel_fh varchar2(255):='Nivel';
vl_campus_cl_fh varchar2(50):='8';
vl_campus_fh varchar2(255):='Campus';
vl_matricula_alumno_cl_fh varchar2(50):='9';
vl_matricula_alumno_fh varchar2(255):='matriculaAlumno';
vl_fecha_pago_cl_fh varchar2(50):='10';
vl_fecha_pago_fh varchar2(255):='fechaPago';
vl_referencia_cl_fh varchar2(50):='11';
vl_referencia_fh varchar2(255):='Referencia';
vl_referencia_tipo_cl_fh varchar2(50):='12';
vl_referencia_tipo_fh varchar2(255):='ReferenciaTipo';
vl_m_int_pago_tardio_cl_fh varchar2(50):='13';
vl_m_int_pago_tardio_fh varchar2(255):='MontoInteresPagoTardio';
vl_m_valor_int_pag_tard_fh varchar2(255):= '.';
vl_tipo_accesorio_cl_fh varchar2(50):='14';
vl_tipo_accesorio_fh varchar2(255):='TipoAccesorio';
vl_monto_accesorio_cl_fh varchar2(50):='15';
vl_monto_accesorio_fh varchar2(255):='MontoAccesorio';
vl_cole_cl_fh varchar2(50):='16';
vl_cole_fh varchar2(255):='Colegiatura';
vl_valor_cole_fh varchar2(255):= '.';
vl_monto_cole_cl_fh varchar2(50):='17';
vl_monto_cole_fh varchar2(255):='MontoColegiatura';
vl_valor_monto_cole_fh varchar2(255):= '.';
vl_nom_alumnos_cl_fh varchar2(50):='18';
vl_nom_alumnos_fh varchar2(255):='NombreAlumno';
vl_curp_cl_fh varchar2(50):='19';
vl_curp_fh varchar2(255):='CURP';
vl_rfc_cl_fh varchar2(50):='20';
vl_rfc_fh varchar2(255):='RFC';
vl_grado_cl_fh varchar2(50):='21';
vl_grado_fh varchar2(255):='Grado';
vl_nota_cl_fh varchar2(50):='22';
vl_nota_fh varchar2(255):='Nota';
vl_valor_nota_fh varchar2(255):= '.';
vl_int_pago_tardio_cl_fh varchar2(50):='23';
vl_int_pago_tardio_fh varchar2(255):='InteresPagoTardio';
vl_valor_int_pag_tard_fh varchar2(255):= '.';
vl_flex_header_cierre varchar2(4000):='/>';
vl_flex_headers_cierre varchar2(4000):='</flexHeaders>';
vl_folio_int_cl_fh_tag varchar2(250):='clave=';
vl_folio_int_nom_fh_tag varchar2(250):='nombre=';
vl_folio_int_val_fh_tag varchar2(250):='valor=';
vl_raz_soc_cl_fh_tag varchar2(250):='clave=';
vl_raz_soc_nom_fh_tag varchar2(250):='nombre=';
vl_raz_soc_val_fh_tag varchar2(250):='valor=';
vl_met_pago_cl_fh_tag varchar2(250):='clave=';
vl_met_pago_nom_fh_tag varchar2(250):='nombre=';
vl_met_pago_val_fh_tag varchar2(250):='valor=';
vl_desc_met_pago_cl_fh_tag varchar2(250):='clave=';
vl_desc_met_pago_nom_fh_tag varchar2(250):='nombre=';
vl_desc_met_pago_val_fh_tag varchar2(250):='valor=';
vl_id_pago_cl_fh_tag varchar2(250):='clave=';
vl_id_pago_nom_fh_tag varchar2(250):='nombre=';
vl_id_pago_val_fh_tag varchar2(250):='valor=';
vl_monto_cl_fh_tag varchar2(250):='clave=';
vl_monto_nom_fh_tag varchar2(250):='nombre=';
vl_monto_val_fh_tag varchar2(250):='valor=';
vl_nivel_cl_fh_tag varchar2(250):='clave=';
vl_nivel_nom_fh_tag varchar2(250):='nombre=';
vl_nivel_val_fh_tag varchar2(250):='valor=';
vl_campus_cl_fh_tag varchar2(250):='clave=';
vl_campus_nom_fh_tag varchar2(250):='nombre=';
vl_campus_val_fh_tag varchar2(250):='valor=';
vl_mat_alumno_cl_fh_tag varchar2(250):='clave=';
vl_mat_alumno_nom_fh_tag varchar2(250):='nombre=';
vl_mat_alumno_val_fh_tag varchar2(250):='valor=';
vl_fecha_pago_cl_fh_tag varchar2(250):='clave=';
vl_fecha_pago_nom_fh_tag varchar2(250):='nombre=';
vl_fecha_pago_val_fh_tag varchar2(250):='valor=';
vl_referencia_cl_fh_tag varchar2(250):='clave=';
vl_referencia_nom_fh_tag varchar2(250):='nombre=';
vl_referencia_val_fh_tag varchar2(250):='valor=';
vl_referencia_tipo_cl_fh_tag varchar2(250):='clave=';
vl_referencia_tipo_nom_fh_tag varchar2(250):='nombre=';
vl_referencia_tipo_val_fh_tag varchar2(250):='valor=';
vl_m_int_pag_tard_cl_fh_tag varchar2(250):='clave=';
vl_m_int_pag_tard_nom_fh_tag varchar2(250):='nombre=';
vl_m_int_pag_tard_val_fh_tag varchar2(250):='valor=';
vl_tipo_accesorio_cl_fh_tag varchar2(250):='clave=';
vl_tipo_accesorio_nom_fh_tag varchar2(250):='nombre=';
vl_tipo_accesorio_val_fh_tag varchar2(250):='valor=';
vl_monto_accesorio_cl_fh_tag varchar2(250):='clave=';
vl_monto_accesorio_nom_fh_tag varchar2(250):='nombre=';
vl_monto_accesorio_val_fh_tag varchar2(250):='valor=';
vl_cole_cl_fh_tag varchar2(250):='clave=';
vl_cole_nom_fh_tag varchar2(250):='nombre=';
vl_cole_val_fh_tag varchar2(250):='valor=';
vl_monto_cole_cl_fh_tag varchar2(250):='clave=';
vl_monto_cole_nom_fh_tag varchar2(250):='nombre=';
vl_monto_cole_val_fh_tag varchar2(250):='valor=';
vl_nom_alumnos_cl_fh_tag varchar2(250):='clave=';
vl_nom_alumnos_nom_fh_tag varchar2(250):='nombre=';
vl_nom_alumnos_val_fh_tag varchar2(250):='valor=';
vl_curp_cl_fh_tag varchar2(250):='clave=';
vl_curp_nom_fh_tag varchar2(250):='nombre=';
vl_curp_val_fh_tag varchar2(250):='valor=';
vl_rfc_cl_fh_tag varchar2(250):='clave=';
vl_rfc_nom_fh_tag varchar2(250):='nombre=';
vl_rfc_val_fh_tag varchar2(250):='valor=';
vl_grado_cl_fh_tag varchar2(250):='clave=';
vl_grado_nom_fh_tag varchar2(250):='nombre=';
vl_grado_val_fh_tag varchar2(250):='valor=';
vl_nota_cl_fh_tag varchar2(250):='clave=';
vl_nota_nom_fh_tag varchar2(250):='nombre=';
vl_nota_val_fh_tag varchar2(250):='valor=';
vl_int_pag_tard_cl_fh_tag varchar2(250):='clave=';
vl_int_pag_tard_nom_fh_tag varchar2(250):='nombre=';
vl_int_pag_tard_val_fh_tag varchar2(250):='valor=';


------ Contadoor de registros
vn_commit  number :=0;

---- Manejo del IVA
vn_iva number:=0;
vl_iva number :=0;


---- Tipo_Archivo
vl_tipo_archivo varchar2(50):='XML';
vl_tipo_fact varchar2(50):='Con_D_facturacion';

----Complemento IEDU(+)
vl_complemento varchar2(4000):='<IEDU';
vl_linea_comp_tag varchar2(25):='linea=';
vl_linea_comp varchar2(25):=1;
vl_version_comp_tag varchar2(10):='version=';
vl_version_comp varchar2(10):='1.0';
vl_nivel_comp_tag varchar2(25):='nivel=';
vl_nivel_comp varchar2(25):='Profesional Técnico';
vl_nom_comp_tag varchar2(25):='nombre_alumno=';
vl_curp_comp_tag varchar2(25):='curp=';
vl_rvoe_comp_tag varchar2(25):='rvoe=';
vl_complemento_cierre varchar2(4000):='/>';  

----Estatus timbrado
vl_estatus_timbrado number :=0;

--   
BEGIN
   FOR D_Fiscales
              IN (  WITH CURP AS (
                                            select 
                                                SPRIDEN_PIDM PIDM,
                                                GORADID_ADDITIONAL_ID CURP
                                              from SPRIDEN
                                              left join GORADID on SPRIDEN_PIDM = GORADID_PIDM
                                              where GORADID_ADID_CODE = 'CURP'
                                              )
                        SELECT DISTINCT SPREMRG_PIDM PIDM,
                                           SPRIDEN_ID MATRICULA,
                                           replace(SPRIDEN_LAST_NAME, '/', ' ')||' '||SPRIDEN_FIRST_NAME Nombre_Alumno,
                                           SUBSTR(spriden_id,5) ID,
                                           SPREMRG_LAST_NAME Nombre,
                                           upper(SPREMRG_MI) RFC,
                                           REGEXP_SUBSTR(SPREMRG_STREET_LINE1, '[^#"]+', 1, 1) Calle,
                                           NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#[^#]*'),2), 0) Num_Ext,
                                           NVL(substr(regexp_substr(SPREMRG_STREET_LINE1, '#Int[^*]*'),2), 0) Num_Int,
                                           SPREMRG_STREET_LINE3 Colonia,
                                           SPREMRG_CITY AS Municipio,
                                           SPREMRG_ZIP AS CP,                                               
                                           SPREMRG_STAT_CODE Estado,
                                           SPREMRG_NATN_CODE AS Pais,
                                           'oscar.gonzalez@utel.edu.mx' Email,
                                           --GOREMAL_EMAIL_ADDRESS Email,
                                            CASE
                                                 when GORADID_ADID_CODE = 'REFH' then
                                                 'BH'
                                                 when GORADID_ADID_CODE = 'REFS' then
                                                 'BS'
                                                 when GORADID_ADID_CODE = 'REFU' then 
                                                 'UI'
                                            end Serie,
                                            SZVCAMP_CAMP_CODE Campus,
                                            GORADID_ADDITIONAL_ID Referencia,
                                            GORADID_ADID_CODE Ref_tipo,
                                            STVLEVL_DESC Nivel,
                                            CURP.CURP Curp,
                                            b.SARADAP_DEGC_CODE_1 Grado,
                                            SZTDTEC_NUM_RVOE RVOE_num,
                                            SZTDTEC_CLVE_RVOE RVOE_clave
                                      FROM SPREMRG
                                      left join SPRIDEN on SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                      left outer join SARADAP b on SPREMRG_PIDM = b.SARADAP_PIDM
                                      left outer join SORLCUR c on SPREMRG_PIDM = SORLCUR_PIDM
                                      left join STVLEVL on b.SARADAP_LEVL_CODE = STVLEVL_CODE
                                      left join GOREMAL on SPREMRG_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
                                      left join GORADID on GORADID_PIDM = SPREMRG_PIDM 
                                                  and GORADID_ADID_CODE LIKE 'REF%'
                                      join SZVCAMP on szvcamp_camp_alt_code=substr(SPRIDEN_ID,1,2)
                                      left join CURP on SPREMRG_PIDM = CURP.PIDM
                                      left outer join SZTDTEC on c.SORLCUR_CAMP_CODE = SZTDTEC_CAMP_CODE
                                            and c.SORLCUR_PROGRAM = SZTDTEC_PROGRAM
                                            and c.SORLCUR_TERM_CODE_CTLG = SZTDTEC_TERM_CODE
                                     WHERE SPREMRG_MI IS NOT NULL
                                           AND SPREMRG_PRIORITY IN
                                                  (SELECT MIN (s1.SPREMRG_PRIORITY)
                                                     FROM SPREMRG s1
                                                    WHERE SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                          AND SPREMRG_PRIORITY = s1.SPREMRG_PRIORITY)
                                            and c.SORLCUR_LMOD_CODE = 'LEARNER'
                                            and c.SORLCUR_SEQNO IN (SELECT MAX(c.SORLCUR_SEQNO)
                                                                                     FROM SORLCUR c1
                                                                                     WHERE c.SORLCUR_PIDM = c1.SORLCUR_PIDM)
                                          and SPREMRG_MI is not null
--                                  and spriden_pidm = 25803
                                  ORDER BY SPREMRG_PIDM
                                  
                                  )
   LOOP
            vl_pago_total:=0;
            vn_commit :=0;
           For pago in (
                               with accesorios as(
                                                        select distinct
                                                          TZTCRTE_PIDM Pidm,
                                                          TZTCRTE_LEVL as Nivel,
                                                          TZTCRTE_CAMP as Campus,
                                                          TZTCRTE_CAMPO11  as Fecha_Pago,
                                                          TZTCRTE_CAMPO19 as accesorios,
                                                          to_char(sum (TZTCRTE_CAMPO20),'fm9999999990.00') as Monto_accesorios,
                                                          TZTCRTE_CAMPO15 as colegiaturas,
                                                          to_char(sum (TZTCRTE_CAMPO16),'fm9999999990.00') as Monto_colegiaturas,
                                                          TZTCRTE_CAMPO17 as intereses,
                                                          to_char(sum (TZTCRTE_CAMPO18),'fm9999999990.00') as Monto_intereses,                                                     
                                                          TZTCRTE_CAMPO26 as Categoria,
                                                          TZTCRTE_CAMPO10 as Secuencia
                                                        from TZTCRTE
                                                        where  TZTCRTE_TIPO_REPORTE = 'Facturacion_dia'
--                                                               and TZTCRTE_CAMPO26 in  ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
                                                        group by TZTCRTE_PIDM, TZTCRTE_LEVL, TZTCRTE_CAMP, TZTCRTE_CAMPO11, TZTCRTE_CAMPO15, TZTCRTE_CAMPO17, TZTCRTE_CAMPO19, TZTCRTE_CAMPO26, TZTCRTE_CAMPO10
                                                            )
                                    SELECT DISTINCT 
                                            TBRACCD_PIDM PIDM,
                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                            substr(TBRACCD_DETAIL_CODE,1,2) FORMA_PAGO,
                                            TBRACCD_DETAIL_CODE METODO_PAGO_CODE,
                                            TBRACCD_DESC METODO_PAGO,
                                            to_char (TBRACCD_EFFECTIVE_DATE,'RRRR-MM-DD"T"HH24:MI:SS') Fecha_pago,
                                            TBRACCD_PAYMENT_ID Id_pago,
                                            accesorios.accesorios tipo_accesorio,
                                            accesorios.Monto_accesorios monto_accesorio,
                                            accesorios.colegiaturas colegiaturas,
                                            accesorios.Monto_colegiaturas monto_colegiatura,
                                            accesorios.intereses intereses,
                                            accesorios.Monto_intereses monto_interes
                                    FROM TBRACCD
                                    LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                           LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                    left join accesorios on tbraccd_pidm = accesorios.Pidm
--                                            and TBRACCD_TRAN_NUMBER = accesorios.secuencia
                                    WHERE TBBDETC_TYPE_IND = 'P'
                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                            AND TBRACCD_PIDM= D_Fiscales.pidm
                                            AND TRUNC (TBRACCD_EFFECTIVE_DATE) = accesorios.Fecha_Pago
                                             AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
--                                              and rownum = 1
                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                        FROM TZTFACT
                                                                                                        WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                        ORDER BY TBRACCD_PIDM, 2 asc
                            )
            loop

             If pago.MONTO_PAGADO like '-%' then
                    pago.MONTO_PAGADO := pago.MONTO_PAGADO * (-1);
             End if;                            
             
             
                  vn_commit := vn_commit +1;
                  vl_pago_total := pago.MONTO_PAGADO;
                  vl_subtotal := pago.MONTO_PAGADO;
              
                vl_num_linea:=0;
                vl_rfc_utel:= null; 
                vl_razon_social_utel:= null; 
                vl_prod_serv := null;      
                 vl_consecutivo :=0;

                --vl_encabezado :='<documentos>';
                --vl_entidad_receptor :='<documentoErp>';
                vl_envio_correo :='<envioCfdi';
                vl_dfiscales_utel :='<emisor';
                vl_dfiscales_receptor :='<receptor';
                vl_dfiscales_destinatario := '<destinatario>';
                
                     --Emisor_STO
                        If d_fiscales.serie = 'BH' then
                            vl_id_emisor_sto := 1;
                        Elsif d_fiscales.serie = 'BS' then
                            vl_id_emisor_sto := 2;
                        End if;
                        
                      --Emisor_ERP
                         If d_fiscales.serie = 'BH' then
                            vl_id_emisor_erp := 1;
                        Elsif d_fiscales.serie = 'BS' then
                            vl_id_emisor_erp := 2;
                        End if;
                        
                       --Nivel_Complemento
                         If d_fiscales.serie = 'BH' then
                            vl_nivel_comp := 'Profesional Técnico';
                        Elsif d_fiscales.serie = 'BS' then
                            vl_nivel_comp := Null;
                        End if;

            --- Se obtiene el numero de consecutivo por empresa 
                    Begin

                    select nvl (max (TZTDFUT_FOLIO), 0)+1
                        Into  vl_consecutivo
                    from tztdfut
                    where TZTDFUT_SERIE = D_Fiscales.serie;
                    Exception
                    When Others then 
                        vl_consecutivo :=1;
                    End;

                   Begin
                        select 
                            TZTDFUT_RFC RFC,
                            TZTDFUT_RAZON_SOC RAZON_SOCIAL,
                            TZTDFUT_PROD_SERV_CODE
                        Into vl_rfc_utel, vl_razon_social_utel, vl_prod_serv
                        from TZTDFUT
                        where TZTDFUT_SERIE = D_Fiscales.serie;
                   exception
                   when others then
                        vl_error:= 'Error al Recuperer los datos Fiscales de la empresa ' ||sqlerrm;
                   End;



                ----Cabecero xml--------
                vl_cabecero := vl_cabecero;

                ---- Se Arma el encazado de la factura <DOCUMENTOS>-------------
                --vl_encabezado := vl_encabezado ||vl_consecutivo;
                
                --------Datos fiscales utel <EMISOR>
                vl_dfiscales_utel := vl_dfiscales_utel||' '||vl_rfc_tag||'"'||vl_rfc_utel||'"'||' '||vl_nombre_tag||'"'||vl_razon_social_utel||'"'||' '||vl_regimen_fiscal_tag||'"'||vl_regimen_fiscal||'"'||' '||vl_id_emisor_sto_tag||'"'||vl_id_emisor_sto||'"'||' '||vl_id_emisor_erp_tag||'"'||vl_id_emisor_erp||'"'||' '||vl_dfiscales_utel_cierre;
                
                -----Se envia por correo <ENVIO_CFDI>
                vl_envio_correo := vl_envio_correo||' '||vl_xml_tag||'"'||vl_enviar_xml||'"'||' '||vl_pdf_tag||'"'||vl_enviar_pdf||'"'||' '||vl_zip_tag||'"'||vl_enviar_zip||'"'||' '||vl_email_tag||'"'||D_Fiscales.Email||'"'||' '||vl_envio_correo_cierre;
                
                ----------Datos de entidad del receptor <DOCUMENTO_ERP>
                --vl_entidad_receptor := vl_entidad_receptor||vl_id_trx_erp_tag||'"'||vl_consecutivo||'"';
                
                --------Datos fiscales alumno <RECEPTOR>
                vl_dfiscales_receptor := vl_dfiscales_receptor||' '||vl_rfc_receptor_tag||'"'||D_Fiscales.RFC||'"'||' '||vl_nombre_receptor_tag||'"'||D_Fiscales.Nombre||'"'||' '||vl_residencia_fiscal_tag||'"'||vl_residencia_fiscal||'"'||' '||vl_num_reg_id_trib_tag||'"'||vl_num_reg_id_trib||'"'||' '||vl_uso_cfdi_tag||'"'||vl_uso_cfdi||'"'||' '||vl_id_receptor_sto_tag||'"'||D_Fiscales.PIDM||'"'||' '||vl_id_receptor_erp_tag||'"'||D_Fiscales.PIDM||'"'||' '||vl_numero_exterior_tag||'"'||D_Fiscales.Num_Ext||'"'||' '||vl_calle_tag||'"'||D_Fiscales.Calle||'"'||' '||vl_numero_interior_tag||'"'||D_Fiscales.Num_Int||'"'||' '||vl_colonia_tag||'"'||D_Fiscales.Colonia||'"'||' '||vl_localidad_tag||'"'||D_Fiscales.Municipio||'"'||' '||vl_referencia_tag||'"'||vl_referencia_dom_receptor||'"'||' '||vl_municipio_tag||'"'||D_Fiscales.Municipio||'"'||' '||vl_estado_tag||'"'||D_Fiscales.Estado||'"'||' '||vl_pais_tag||'"'||D_Fiscales.Pais||'"'||' '||vl_codigo_postal_tag||'"'||D_Fiscales.CP||'"'||' '||vl_email_receptor_tag||'"'||D_Fiscales.Email||'"'||' '||vl_id_tipo_receptor_tag||'"'||D_Fiscales.ID||'"'||' '||vl_estatus_registro_tag||'"'||vl_estatus_registro||'"'||' '||vl_cierre_receptor;

                --------Datos fiscales alumno <DESTINATARIO>
                vl_dfiscales_destinatario := vl_dfiscales_destinatario||D_Fiscales.RFC||'|'||D_Fiscales.Nombre||'|'||vl_uso_cfdi||'|'||D_Fiscales.ID||'|'||D_Fiscales.ID||'|'||D_Fiscales.Num_Ext||'|'||D_Fiscales.Calle||'|'||D_Fiscales.Num_Int||'|'||D_Fiscales.Colonia||'|'||D_Fiscales.Municipio||'|'||vl_referencia_dom_destinatario||'|'||D_Fiscales.Municipio||'|'||D_Fiscales.Estado||'|'||D_Fiscales.Pais||'|'||D_Fiscales.CP||'|'||D_Fiscales.Email||'|'||D_Fiscales.ID||'|'||vl_estatus_registro||'|';

                ----Complemento IEDU(+)
                vl_complemento := vl_complemento||' '||vl_linea_comp_tag||'"'||vl_linea_comp||'"'||' '||vl_version_comp_tag||'"'||vl_version_comp||'"'||' '||vl_nom_comp_tag||'"'||D_Fiscales.Nombre_Alumno||'"'||' '||vl_curp_comp_tag||'"'||D_Fiscales.Curp||'"'||' '||vl_nivel_comp_tag||'"'||vl_nivel_comp||'"'||' '||vl_rvoe_comp_tag||'"'||D_Fiscales.RVOE_num||'"'||' '||vl_complemento_cierre;
                                    
                                    

                            vl_serie_folio :='<comprobante';
                            vl_info_concepto :='<conceptos';
                            vl_impuesto :='<impuesto>';
                            vl_impuesto_ret :='<retenidos>';
                            vl_info_impuestos :='<impuestos';
                            vl_info_subtotal_imptras :='<trasladados';
                            vl_info_subtotal_impret :='<impuesto>';
                            vl_flex_header :='<flexHeaders';
                                               
                            vl_fecha_pago := null;
                            vl_transaccion  :=0;
                            vl_total_impret :=0;
                            vl_total_imptras :=0;
                            vl_contador :=0;
                                    

                               ---------------- LLenamos Folio y SErie <DOCUMENTO>------------------
                                --vl_serie_folio := vl_serie_folio||' '||vl_serie_tag||'"'||d_fiscales.serie||'"'||' '||vl_folio_tag||'"'||vl_consecutivo||'"'||' '||vl_fecha_tag||'"'||pago.Fecha_pago||'"'||' '||vl_forma_pago_tag||'"'||vl_forma_pago||'"'||' '||vl_condiciones_pago_tag||'"'||vl_condicion_pago||'"'||' '||vl_tipo_cambio_tag||'"'||vl_tipo_cambio||'"'||' '||vl_moneda_tag||'"'||vl_tipo_moneda||'"'||' '||vl_metodo_pago_tag||'"'||vl_metodo_pago||'"'||' '||vl_lugar_expedicion_tag||'"'||vl_lugar_expedicion||'"'||' '||vl_tipo_comprobante_tag||'"'||vl_tipo_comprobante||'"'||' '||vl_subtotal_tag||'"'||vl_subtotal||'"'||' '||vl_descuento_tag||'"'||vl_descuento||'"'||' '||vl_total_tag||'"'||pago.MONTO_PAGADO||'"'||' '||vl_confirmacion_tag||'"'||vl_confirmacion||'"'||' '||vl_tipo_comprobante_emi_tag||'"'||vl_tipo_documento||'"'||' '||'>';

                        vl_pago_total_faltante:=0;
                        vl_secuencia :=0;
                        vn_iva :=0;
                        vl_iva :=0;

                               FOR Pagos_dia
                                        IN (
                                              with cargo as (
                                                                    select distinct 
                                                                        c.TVRACCD_PIDM PIDM, 
                                                                        c.TVRACCD_DETAIL_CODE cargo, 
                                                                       -- c.TVRACCD_TRAN_NUMBER transa, 
                                                                          c.TVRACCD_ACCD_TRAN_NUMBER transa, 
                                                                        c.TVRACCD_DESC descripcion, 
                                                                        to_char(c.TVRACCD_AMOUNT,'fm9999999990.00') MONTO_CARGO,
                                                                        Monto_Iv Monto_IVAS
                                                                    from TVRACCD c, TBBDETC a, (
                                                                                                                select distinct 
                                                                                                                        to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                                                from tvraccd i 
                                                                                                                    where 1=1
                                                                                                                    and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                                                ) monto_iva
                                                                    where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                                        and a.TBBDETC_TYPE_IND = 'C'
                                                                        and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                                        and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                                        and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
--                                                                        and c.TVRACCD_pidm = 25
                                                                    )
                                                        SELECT DISTINCT 
                                                            TBRACCD_PIDM PIDM,
                                                            SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                                            to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                                           nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                                            to_char(TBRACCD_EFFECTIVE_DATE, 'dd/mm/rrrr') Fecha_pago,
                                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                                            TBBDETC_DESC DESCRIPCION,
                                                           nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                                           nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                                           cargo.transa,
                                                    --        Monto_IVAS monto_iva,
                                                            ROW_NUMBER() OVER(PARTITION BY TBRACCD_TRAN_NUMBER ORDER BY TBRACCD_EFFECTIVE_DATE) numero
                                                        FROM TBRACCD
                                                        left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                                        LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                                        LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                                            AND TBRAPPL_REAPPL_IND IS NULL
                                                        left join cargo on cargo.pidm = tbraccd_pidm
                                                           and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                                        WHERE     TBBDETC_TYPE_IND = 'P'
                                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                                            AND TBRACCD_PIDM= pago.pidm
                                                            And TBRACCD_TRAN_NUMBER = pago.TRANSACCION
                                                            AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                                                                    FROM TZTFACT
                                                                                                    WHERE TBRACCD_PIDM = TZTFACT_PIDM)
                                                --           AND TBRACCD_PIDM= 25 
                                                        ORDER BY TBRACCD_PIDM,13 asc
                                            )            
                         LOOP
                            
                            
                            BEGIN
                                    
                                                select distinct  Monto_Iv Monto_IVAS
                                                    INTO vl_iva
                                                from TVRACCD c, TBBDETC a, (
                                                                                            select distinct 
                                                                                                    to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                            from tvraccd i 
                                                                                                where 1=1
                                                                                                and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                            ) monto_iva
                                                where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                    and a.TBBDETC_TYPE_IND = 'C'
                                                    and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                    and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                    and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
                                                    And  c.TVRACCD_PIDM= Pagos_dia.PIDM
                                                    and  c.TVRACCD_ACCD_TRAN_NUMBER = Pagos_dia.transa;
                                        
                                 EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_iva:='0.00';
                                 End;
                            
                               --DBMS_OUTPUT.PUT_LINE('Monta IVA'||vl_iva);
                            
                                  vl_contador := vl_contador +1;
                                  vl_pago_total_faltante := vl_pago_total_faltante + Pagos_dia.MONTO_PAGADO_CARGO;
                                  vl_secuencia :=Pagos_dia.numero;
                                  vn_iva :=  vn_iva + vl_iva;


                                    BEGIN

                                        select '01'
                                        INTO vl_forma_pago
                                        from tbraccd a, spriden b
                                        where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                      from tbbdetc
                                                                                      where TBBDETC_DCAT_CODE = 'CSH'
                                                                                       and TBBDETC_TYPE_IND = 'P')
                                           and tbraccd_pidm = spriden_pidm
                                           and spriden_change_ind is null
                                           AND spriden_pidm = Pagos_dia.PIDM
                                           AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                           and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                    substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                  from TBRACCD a1
                                                                                                  where a1.TBRACCD_DESC like '%EFEC%');
                                     
                                     EXCEPTION           
                                       WHEN OTHERS THEN NULL;
                                         vl_forma_pago:='99';
                                            BEGIN
                                             
                                                 select '02'
                                                INTO vl_forma_pago
                                                from tbraccd a, spriden b
                                                where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                              from tbbdetc
                                                                                              where TBBDETC_DCAT_CODE = 'CSH'
                                                                                               and TBBDETC_TYPE_IND = 'P')
                                                   and tbraccd_pidm = spriden_pidm
                                                   and spriden_change_ind is null
                                                   AND spriden_pidm = Pagos_dia.PIDM
                                                   AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                   and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                            substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                          from TBRACCD a1
                                                                                                          where a1.TBRACCD_DESC like '%CHEQUE%');
                                                 
                                                 
                                                 EXCEPTION           
                                                   WHEN OTHERS THEN NULL;
                                                     vl_forma_pago:='99';
                                                    BEGIN

                                                            select '03'
                                                            INTO vl_forma_pago
                                                            from tbraccd a, spriden b
                                                            where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                          from tbbdetc
                                                                                                          where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                           and TBBDETC_TYPE_IND = 'P')
                                                               and tbraccd_pidm = spriden_pidm
                                                               and spriden_change_ind is null
                                                               AND spriden_pidm = Pagos_dia.PIDM
                                                               AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                               and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                        substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                      from TBRACCD a1
                                                                                                                      where a1.TBRACCD_DESC like '%TRANS%');

                                                         EXCEPTION           
                                                           WHEN OTHERS THEN NULL;
                                                            Begin
                                                                select '03'
                                                                INTO vl_forma_pago
                                                                from tbraccd a, spriden b
                                                                where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                              from tbbdetc
                                                                                                              where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                               and TBBDETC_TYPE_IND = 'P')
                                                                   and tbraccd_pidm = spriden_pidm
                                                                   and spriden_change_ind is null
                                                                   AND spriden_pidm = Pagos_dia.PIDM
                                                                   AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                                   and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                            substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                          from TBRACCD a1
                                                                                                                          where a1.TBRACCD_DESC like '%RECLAS%');
                                                            Exception
                                                                When Others then                                                            

                                                                BEGIN

                                                                        select '04'
                                                                    INTO vl_forma_pago
                                                                    from tbraccd a, spriden b
                                                                    where tbraccd_detail_code in (select tbbdetc_detail_code   
                                                                                                                  from tbbdetc
                                                                                                                  where TBBDETC_DCAT_CODE = 'CSH'
                                                                                                                   and TBBDETC_TYPE_IND = 'P')
                                                                       and tbraccd_pidm = spriden_pidm
                                                                       and spriden_change_ind is null
                                                                       AND spriden_pidm = Pagos_dia.PIDM
                                                                       AND TBRACCD_TRAN_NUMBER = Pagos_dia.TRANSACCION
                                                                       and substr (tbraccd_detail_code, 3, 2) in (select distinct 
                                                                                                                                substr (a1.tbraccd_detail_code, 3, 2)
                                                                                                                              from TBRACCD a1
                                                                                                                              where a1.TBRACCD_DESC like '%TDC%');
                                                                     
                                                                     EXCEPTION           
                                                                       WHEN OTHERS THEN NULL;
                                                                         vl_forma_pago:='99';
                                                                END;
                                                            
                                                            END;   
                                                    END;
                                            END;
                                    END;


                                If PAGOS_DIA.MONTO_PAGADO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO := PAGOS_DIA.MONTO_PAGADO * (-1);
                                End if; 
                            
                            ------------------- Seteo ---------------
                           
                            vl_total :=PAGOS_DIA.MONTO_PAGADO;
                            vl_fecha_pago := PAGOS_DIA.Fecha_pago;
                            vl_transaccion :=PAGOS_DIA.TRANSACCION;



                            ----
                                If Pagos_dia.numero > 1 then 
                                    vl_info_concepto := vl_info_concepto||'<conceptos';
                                    vl_impuesto :='<impuesto>';
                                End if;
                                
                                
                                If vl_iva > 0 then
                                    vl_tasa_cuota_impuesto := '0.160000';
                                Elsif vl_iva = 0 then
                                    vl_tasa_cuota_impuesto := '0.000000';
                                End if;
                                
                                
                                If PAGOS_DIA.MONTO_PAGADO_CARGO like '-%' then
                                    PAGOS_DIA.MONTO_PAGADO_CARGO := PAGOS_DIA.MONTO_PAGADO_CARGO * (-1);
                                End if;
                                
                                ------Cabecera Conceptos
                                --vl_conceptos_cab := vl_conceptos_cab;

                                --------Concepto <CONCEPTO>
                                vl_info_concepto := vl_info_concepto||' '||vl_clave_prod_serv_tag||'"'||vl_prod_serv||'"'||' '||vl_cantidad_concepto_tag||'"'||vl_cantidad_concepto||'"'||' '||vl_clave_unidad_concepto_tag||'"'||vl_clave_unidad_concepto||'"'||' '||vl_unidad_concepto_tag||'"'||vl_unidad_concepto||'"'||' '||vl_num_identificacion_tag||'"'||Pagos_dia.clave_cargo||'"'||' '||vl_descripcion_concepto_tag||'"'||Pagos_dia.DESCRIPCION_cargo||'"'||' '||vl_valor_unitario_concepto_tag||'"'||to_char((PAGOS_DIA.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'"'||' '||vl_importe_concepto_tag||'"'||to_char((PAGOS_DIA.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'"'||' '||vl_descuento_concepto_tag||'"'||vl_descuento||'"'||vl_info_concepto_cierre;

                                ----Impuesto_trasladado_cabecera
                                vl_impuesto_tras_cab := vl_impuesto_tras_cab;
                                
                                --------Impuesto trasladado <IMPUESTO>
                                vl_impuesto := vl_impuesto_tras_cab ||' '||vl_base_tag||'"'||to_char((PAGOS_DIA.MONTO_PAGADO_CARGO - vn_iva), 'fm9999999990.00')||'"'||' '||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||vl_importe_tag||'"'||vl_iva||'"'||vl_impuesto_cierre;

                                vl_info_concepto := vl_info_concepto||vl_impuesto_cab||vl_impuesto||vl_impuestos_cierre||vl_conceptos_cierre;                     
                                
                                                                                                                                         
                                vl_total_imptras := vl_total_imptras + vl_iva;
                                
                                ----Impuesto_trasladado_cierre
                                vl_impuesto_tras_cierre := vl_impuesto_tras_cierre;
                                

                                ------Impuesto_retenido_cabecera
                                --vl_impuesto_ret_cab := vl_impuesto_ret_cab;

                                --------Impuesto retenido <RETENIDOS>
                                
                                vl_total_impret := 0;                
                                --vl_total_impret := vl_total_impret + pagos_dia.monto_iva;
                             --   vl_impuesto_ret := vl_impuesto_ret  ||Pagos_dia.numero||'|'||PAGOS_DIA.MONTO_PAGADO_CARGO||'|'||vl_impuesto_cod||'|'||vl_tipo_factor_impuesto||'|'||vl_tasa_cuota_impuesto||'|'||pagos_dia.monto_iva||'|';


                                ------Impuesto_retenido_cierre
                                --vl_impuesto_ret_cierre := vl_impuesto_ret_cierre;
                           
                                --DBMS_OUTPUT.PUT_LINE(vl_encabezado||'*'||vl_serie_folio||'*'||vl_entidad_receptor||'*'||vl_envio_correo||'*'||vl_dfiscales_utel||'*'||vl_dfiscales_receptor||'*'||vl_dfiscales_destinatario||'*'||vl_info_concepto||'*'||vl_impuesto||'*'||vl_impuesto_ret||'*'||vl_info_impuestos||'*'||vl_info_subtotal_imptras||'*'||vl_info_subtotal_impret||'*');

                         END LOOP Pagos_dia;
                        
                        vl_subtotal := vl_subtotal - vn_iva;

                       ---------------- LLenamos Folio y SErie ENC(+)------------------
                         vl_serie_folio := vl_serie_folio||' '||vl_serie_tag||'"'||d_fiscales.serie||'"'||' '||vl_folio_tag||'"'||vl_consecutivo||'"'||
                                                                       ' '||vl_fecha_tag||'"'||pago.Fecha_pago||'"'||' '||vl_forma_pago_tag||'"'||vl_forma_pago||'"'||
                                                                       ' '||vl_condiciones_pago_tag||'"'||vl_condicion_pago||'"'||' '||vl_tipo_cambio_tag||'"'||vl_tipo_cambio||'"'||
                                                                       ' '||vl_moneda_tag||'"'||vl_tipo_moneda||'"'||' '||vl_metodo_pago_tag||'"'||vl_metodo_pago||'"'||
                                                                       ' '||vl_lugar_expedicion_tag||'"'||vl_lugar_expedicion||'"'||' '||vl_tipo_comprobante_tag||'"'||vl_tipo_comprobante||'"'||
                                                                       ' '||vl_subtotal_tag||'"'||to_char(vl_subtotal, 'fm9999999990.00')||'"'||' '||vl_descuento_tag||'"'||vl_descuento||'"'||' '||vl_total_tag||'"'||to_char(pago.MONTO_PAGADO, 'fm9999999990.00')||'"'||
                                                                       ' '||vl_confirmacion_tag||'"'||vl_confirmacion||'"'||' '||vl_tipo_comprobante_emi_tag||'"'||vl_tipo_documento||'"'||' '||'>';
                         
--                         If vl_secuencia > 1 then 
--                                    vl_info_concepto := vl_info_concepto ||'<conceptos';
--                                    vl_impuesto :='<impuesto>';
--                         End if;
                        
                        
                        vl_clave_cargo := null;
                        vl_descrip_cargo := null;
                        vl_secuencia := vl_secuencia +1;
                       
                         
                      If vl_pago_total >  vl_pago_total_faltante then 
                             vl_pago_diferencia :=    vl_pago_total -  vl_pago_total_faltante;
                             
--                         If vl_secuencia > 1 then 
                            vl_info_concepto := vl_info_concepto ||'<conceptos';
                            vl_impuesto :='<impuesto>';
--                         End if;
                                
                                        Begin    
                                             Select TBBDETC_DETAIL_CODE, TBBDETC_DESC
                                               Into  vl_clave_cargo, vl_descrip_cargo
                                             from tbbdetc
                                             Where TBBDETC_DETAIL_CODE = substr (D_Fiscales.matricula, 1,2)||'NN'
                                             And TBBDETC_DCAT_CODE = 'COL';
                                         Exception
                                         when Others then 
                                             vl_clave_cargo := null;
                                              vl_descrip_cargo := null;
                                        End;
                                       
                                        If  vl_clave_cargo is not null and vl_descrip_cargo is not null then                              
                                                vl_info_concepto := vl_info_concepto||' '||vl_clave_prod_serv_tag||'"'||vl_prod_serv||'"'||' '||
                                                                                                             vl_cantidad_concepto_tag||'"'||vl_cantidad_concepto||'"'||' '||
                                                                                                             vl_clave_unidad_concepto_tag||'"'||vl_clave_unidad_concepto||'"'||' '||
                                                                                                             vl_unidad_concepto_tag||'"'||vl_unidad_concepto||'"'||' '||
                                                                                                             vl_num_identificacion_tag||'"'||vl_clave_cargo||'"'||' '||
                                                                                                             vl_descripcion_concepto_tag||'"'||vl_descrip_cargo||'"'||' '||
                                                                                                             vl_valor_unitario_concepto_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                             vl_importe_concepto_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                             vl_descuento_concepto_tag||'"'||vl_descuento||'"'||
                                                                                                             vl_info_concepto_cierre;                                                                                                         

                                              If substr (D_Fiscales.matricula, 1,2) = '01' then 
                                                --------Impuesto trasladado LIMPTRAS(+)
                                                vl_impuesto := vl_impuesto_tras_cab ||' '||vl_base_tag||'"'||to_char(vl_pago_diferencia, 'fm9999999990.00')||'"'||' '||
                                                                                                               vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||
                                                                                                               vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||
                                                                                                               vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||
                                                                                                               vl_importe_tag||'"'||vl_pago_diferencia||'"'||
                                                                                                               vl_impuesto_cierre;
                                                                                                                                            
                                                vl_total_imptras := vl_total_imptras + to_char(vl_pago_diferencia*(0/100));                                          
                                                
                                                vl_info_concepto := vl_info_concepto||vl_info_subtotal_imptras;    
                                                
                                                vl_total_impret := 0;                

                                              End if;
                                               
                                       End if;
                                       
                                       
                      End if;
                      

                                     
                                 --vl_info_impuestos_comprobante <IMPUESTOS>
                                        vl_info_impuestos := vl_info_impuestos||' '||vl_totImpRet_tag||'"'||to_char(vl_total_impret,'fm9999999990.00')||'"'||' '||vl_totImpTras_tag||'"'||to_char(vl_total_imptras,'fm9999999990.00')||'"';
                                                                   
                                --Info_subtotal_imptras  <IMPUESTO>
                                        vl_info_subtotal_imptras := vl_info_subtotal_imptras||' '||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_tipo_factor_tag||'"'||vl_tipo_factor_impuesto||'"'||' '||vl_tasa_o_cuota_tag||'"'||vl_tasa_cuota_impuesto||'"'||' '||vl_importe_tag||'"'||to_char(vl_total_imptras,'fm9999999990.00')||'"';

                                               --Info_subtotal_impret <IMPUESTO>
                                        vl_info_subtotal_impret := vl_info_subtotal_impret||vl_impuesto_tag||'"'||vl_impuesto_cod||'"'||' '||vl_importe_tag||'"'||to_char(vl_total_impret,'fm9999999990.00')||'"';

                                    --Flex_Header <FLEX_HEADER>
                                        vl_flex_header := vl_flex_header||' '||vl_folio_int_cl_fh_tag||'"'||vl_folio_interno_cl_fh||'"'||' '||vl_folio_int_nom_fh_tag||'"'||vl_folio_interno_fh||'"'||' '||vl_folio_int_val_fh_tag||'"'||D_Fiscales.PIDM||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_raz_soc_cl_fh_tag||'"'||vl_razon_social_cl_fh||'"'||' '||vl_raz_soc_nom_fh_tag||'"'||vl_razon_social_fh||'"'||' '||vl_raz_soc_val_fh_tag||'"'||nvl(D_fiscales.Nombre, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_met_pago_cl_fh_tag||'"'||vl_metodo_pago_cl_fh||'"'||' '||vl_met_pago_nom_fh_tag||'"'||vl_metodo_pago_fh||'"'||' '||vl_met_pago_val_fh_tag||'"'||nvl(pago.METODO_PAGO_CODE, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_desc_met_pago_cl_fh_tag||'"'||vl_desc_metodo_pago_cl_fh||'"'||' '||vl_desc_met_pago_nom_fh_tag||'"'||vl_desc_metodo_pago_fh||'"'||' '||vl_desc_met_pago_val_fh_tag||'"'||nvl(pago.METODO_PAGO, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_id_pago_cl_fh_tag||'"'||vl_id_pago_cl_fh||'"'||' '||vl_id_pago_nom_fh_tag||'"'||vl_id_pago_pago_fh||'"'||' '||vl_id_pago_val_fh_tag||'"'||' '||nvl(pago.Id_pago, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_cl_fh_tag||'"'||vl_monto_cl_fh||'"'||' '||vl_monto_nom_fh_tag||'"'||vl_monto_fh||'"'||' '||vl_monto_val_fh_tag||'"'||nvl(to_char(pago.MONTO_PAGADO,'fm9999999990.00'), '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_nivel_cl_fh_tag||'"'||vl_nivel_cl_fh||'"'||' '||vl_nivel_nom_fh_tag||'"'||vl_nivel_fh||'"'||' '||vl_nivel_val_fh_tag||'"'||nvl(D_Fiscales.Nivel, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_campus_cl_fh_tag||'"'||vl_campus_cl_fh||'"'||' '||vl_campus_nom_fh_tag||'"'||vl_campus_fh||'"'||' '||vl_campus_val_fh_tag||'"'||nvl(D_fiscales.Campus, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_mat_alumno_cl_fh_tag||'"'||vl_matricula_alumno_cl_fh||'"'||' '||vl_mat_alumno_nom_fh_tag||'"'||vl_matricula_alumno_fh||'"'||' '||vl_mat_alumno_val_fh_tag||'"'||nvl(D_fiscales.MATRICULA, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_fecha_pago_cl_fh_tag||'"'||vl_fecha_pago_cl_fh||'"'||' '||vl_fecha_pago_nom_fh_tag||'"'||vl_fecha_pago_fh||'"'||' '||vl_fecha_pago_val_fh_tag||'"'||nvl(pago.Fecha_pago, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_referencia_cl_fh_tag||'"'||vl_referencia_cl_fh||'"'||' '||vl_referencia_nom_fh_tag||'"'||vl_referencia_fh||'"'||' '||vl_referencia_val_fh_tag||'"'||nvl(D_fiscales.Referencia, '.')||'"'||' '||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_referencia_tipo_cl_fh_tag||'"'||vl_referencia_tipo_cl_fh||'"'||' '||vl_referencia_tipo_nom_fh_tag||'"'||vl_referencia_tipo_fh||'"'||' '||vl_referencia_tipo_val_fh_tag||'"'||nvl(D_fiscales.Ref_tipo, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_m_int_pag_tard_cl_fh_tag ||'"'||vl_m_int_pago_tardio_cl_fh||'"'||' '||vl_m_int_pag_tard_nom_fh_tag||'"'||vl_m_int_pago_tardio_fh||'"'||' '||vl_m_int_pag_tard_val_fh_tag||'"'||nvl(pago.monto_interes, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_tipo_accesorio_cl_fh_tag||'"'||vl_tipo_accesorio_cl_fh||'"'||' '||vl_tipo_accesorio_nom_fh_tag||'"'||vl_tipo_accesorio_fh||'"'||' '||vl_tipo_accesorio_val_fh_tag||'"'||nvl(pago.tipo_accesorio, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_accesorio_cl_fh_tag||'"'||vl_monto_accesorio_cl_fh||'"'||' '||vl_monto_accesorio_nom_fh_tag||'"'||vl_monto_accesorio_fh||'"'||' '||vl_monto_accesorio_val_fh_tag||'"'||nvl(pago.monto_accesorio, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_cole_cl_fh_tag||'"'||vl_cole_cl_fh||'"'||' '||vl_cole_nom_fh_tag||'"'||vl_cole_fh||'"'||' '||vl_cole_val_fh_tag||'"'||nvl(pago.colegiaturas, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_monto_cole_cl_fh_tag||'"'||vl_monto_cole_cl_fh||'"'||' '||vl_monto_cole_nom_fh_tag||'"'||vl_monto_cole_fh||'"'||' '||vl_monto_cole_val_fh_tag||'"'||nvl(pago.monto_colegiatura, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                   vl_flex_header||' '||vl_nom_alumnos_cl_fh_tag||'"'||vl_nom_alumnos_cl_fh||'"'||' '||vl_nom_alumnos_nom_fh_tag||'"'||vl_nom_alumnos_fh||'"'||' '||vl_nom_alumnos_val_fh_tag||'"'||nvl(D_Fiscales.Nombre_Alumno, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_curp_cl_fh_tag||'"'||vl_curp_cl_fh||'"'||' '||vl_curp_nom_fh_tag||'"'||vl_curp_fh||'"'||' '||vl_curp_val_fh_tag||'"'||nvl(D_Fiscales.Curp, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_rfc_cl_fh_tag||'"'||vl_rfc_cl_fh||'"'||' '||vl_rfc_nom_fh_tag||'"'||vl_rfc_fh||'"'||' '||vl_rfc_val_fh_tag||'"'||nvl(D_Fiscales.RFC, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_grado_cl_fh_tag||'"'||vl_grado_cl_fh||'"'||' '||vl_grado_nom_fh_tag||'"'||vl_grado_fh||'"'||' '||vl_grado_val_fh_tag||'"'||nvl(D_Fiscales.Grado, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_nota_cl_fh_tag||'"'||vl_nota_cl_fh||'"'||' '||vl_nota_nom_fh_tag||'"'||vl_nota_fh||'"'||' '||vl_nota_val_fh_tag||'"'||nvl(vl_valor_nota_fh, '.')||'"'||vl_flex_header_cierre||chr(10)||chr(9)||
                                                                  vl_flex_header||' '||vl_int_pag_tard_cl_fh_tag||'"'||vl_int_pago_tardio_cl_fh||'"'||' '||vl_int_pag_tard_nom_fh_tag||'"'||vl_int_pago_tardio_fh||'"'||' '||vl_int_pag_tard_val_fh_tag||'"'||nvl(pago.intereses, '.')||'"'||vl_flex_header_cierre;

                                                        --
                                                                                                        
                                BEGIN
                                     INSERT INTO TZTFACT VALUES(
                                        D_Fiscales.PIDM
                                      , D_Fiscales.RFC
                                      , vl_total
                                      , 'FM'
                                      , NULL
                                      , NULL
                                      , sysdate
                                      ,vl_transaccion
                                      ,NULL
                                      ,vl_consecutivo
                                      ,d_fiscales.serie
                                      ,NULL
                                      ,NULL
                                      ,vl_cabecero||chr(10)||vl_cabe_soap||chr(10)||vl_soap_header||chr(10)||chr(9)||vl_soap_body||chr(10)||chr(9)||chr(9)||vl_neon_ws||chr(10)||vl_serie_folio||chr(10)||
                                      vl_envio_correo||chr(10)||vl_dfiscales_utel||chr(10)||vl_dfiscales_receptor||chr(10)||chr(9)||vl_flex_header||chr(10)||chr(9)||vl_info_concepto||chr(10)||chr(9)||
                                      --vl_impuesto_cab||chr(10)||chr(9)||chr(9)||chr(9)||vl_impuesto||chr(10)||chr(9)||chr(9)||vl_impuestos_cierre||chr(10)||chr(9)||
                                      vl_info_impuestos||vl_impuestos_cierre1||CHR(10)||chr(9)||
                                      vl_info_subtotal_imptras||vl_impuesto_cierre||chr(10)||chr(9)||vl_info_impuestos_cierre||chr(10)||chr(9)||vl_complemento||chr(10)||chr(9)||vl_tipo_operacion||''||vl_valor_to||''||vl_tipo_operacion_cierre||chr(10)||
                                      vl_serie_folio_cierre||chr(10)||vl_neon_ws_cierre||chr(10)||chr(9)||vl_soap_body_cierre||chr(10)||vl_soap_envelope
                                      ,vl_tipo_archivo
                                      ,vl_tipo_fact
                                      ,pago.METODO_PAGO
                                      ,vl_estatus_timbrado
                                      ,D_Fiscales.RVOE_num
                                      ,to_char(vl_subtotal, 'fm9999999990.00')
                                      ,to_char(vl_total_imptras,'fm9999999990.00')
                                      ,vl_nivel_comp
                                      ,to_char(vl_fecha_pago , 'DD/MM/YYYY')
                                      ,nvl(D_Fiscales.Curp, '.')
                                      
                                 );
                                 commit;
                                EXCEPTION
                                WHEN OTHERS THEN
                                 VL_ERROR := 'Se presento un error al insertar ' ||sqlerrm;
                                END;  

                                
                                  Begin
                                    
                                    Update tztdfut
                                    set TZTDFUT_FOLIO = vl_consecutivo
                                    Where TZTDFUT_SERIE = D_Fiscales.serie;
                                    Exception
                                    When Others then 
                                      VL_ERROR := 'Se presento un error al Actualizar ' ||sqlerrm;   
                                    End;
                         
                         If vn_commit >= 500 then 
                             commit;
                             vn_commit :=0;
                         End if;
                   
               commit;
            End Loop Pago;
         
      END LOOP;

   commit;
   --DBMS_OUTPUT.PUT_LINE('Error'||VL_ERROR);
Exception
    when Others then
     ROLLBACK;
    -- DBMS_OUTPUT.PUT_LINE('Error General'||sqlerrm);
END;

FUNCTION f_factura_manual_out(pidm in number, trans in number) RETURN PKG_FACTURACION.fmanu_out 
           AS

           my_var long; 
           fm_out PKG_FACTURACION.fmanu_out;
                      
 BEGIN 


        Begin
                
                    For c in (select distinct c.SZTDTEC_NUM_RVOE, a.pidm
                                from tztprog a
                                join TZTFACT b on b.TZTFACT_PIDM = a.pidm and b.TZTFACT_TIPO_DOCTO = 'FM' and b.TZTFACT_RVOE is null
                                join SZTDTEC c on c.SZTDTEC_PROGRAM = a.programa  and c.SZTDTEC_TERM_CODE = a.CTLG and c.SZTDTEC_NUM_RVOE is not null
                                union
                                select  DISTINCT SZTDTEC_NUM_RVOE, SPRIDEN_PIDM
                                from spriden
                                join TZTFACT on TZTFACT_PIDM = SPRIDEN_PIDM AND SPRIDEN_CHANGE_IND IS NULL AND TZTFACT_TIPO_DOCTO = 'FM' and TZTFACT_RVOE is null 
                                join TAISMGR.TZTPAGOS_FACT on TZTPAGO_ID = SPRIDEN_ID AND TZTPAGO_STAT_INSCR != 'CANCELADA'
                                join SZTDTEC a on  a.SZTDTEC_PROGRAM = TZTPAGO_PROGRAMA and a.SZTDTEC_TERM_CODE = (select max (SZTDTEC_TERM_CODE) 
                                                                                                                     from SZTDTEC b 
                                                                                                                     where b.SZTDTEC_PROGRAM = a.SZTDTEC_PROGRAM)
                                and SZTDTEC_NUM_RVOE is not null
                    
                                              
                                             --   Where a.pidm = cc.TZTFACT_PIDM            
                       ) loop
                       
                               Begin
                                        Update TZTFACT
                                        set TZTFACT_RVOE = c.SZTDTEC_NUM_RVOE
                                        Where TZTFACT_PIDM =  c.PIDM
                                        and TZTFACT_TIPO_DOCTO = 'FM'
                                        and TZTFACT_RVOE is null;
                               Exception
                                When Others then 
                                    null;    
                               End;
                    End Loop;
                    Commit;

        End;




                          open fm_out            
                            FOR      
                            select TZTFACT_PIDM PIDM,
                                        TZTFACT_RFC RFC ,
                                        TZTFACT_TRAN_NUMBER TRAN,
                                            TZTFACT_TIPO_PAGO,
                                            TZTFACT_STST_TIMBRADO,
                                            TZTFACT_RVOE,
                                            TZTFACT_MONTO,
                                            TZTFACT_SUBT,
                                            TZTFACT_IVA,
                                            TZTFACT_FECHA_PROCESO,
                                            TZTFACT_NIVEL
                              from TZTFACT
                            where TZTFACT_TIPO_DOCTO = 'FM'
                                 and TZTFACT_STST_TIMBRADO is not null
                                 and TZTFACT_PIDM = pidm
                                 and TZTFACT_TRAN_NUMBER = trans
                                ;
                            

            RETURN (fm_out);                 
                                                                    

END f_factura_manual_out;


PROCEDURE sp_Resp_Factura_manual(vn_pidm in number,vn_resp_manu in number, vl_error varchar2, vn_trans number )

  is 

  p_error varchar2(2500) := 'EXITO';
  
      BEGIN
                  Begin
                       Update TZTFACT
                       set TZTFACT_STST_TIMBRADO = vn_resp_manu, TZTFACT_FECHA_PROCESO =sysdate
                       where TZTFACT_PIDM = vn_pidm
                        and TZTFACT_TRAN_NUMBER = vn_trans;
                       
                  Exception
                          when Others then
                              p_error:= 'Error en respuesta'||sqlerrm;
                  End;
     

          
      Exception 
      When Others then
         p_error := 'Se presento un Error General  ' ||sqlerrm;
      
    END sp_Resp_Factura_manual; 


PROCEDURE sp_Datos_Facturacion_Conceptos
IS

    Begin
        

            for conceptos in (
                                                          with cargo as (
                                                           select distinct 
                                                                c.TVRACCD_PIDM PIDM, 
                                                                c.TVRACCD_DETAIL_CODE cargo, 
                                                                c.TVRACCD_ACCD_TRAN_NUMBER transa, 
                                                                c.TVRACCD_DESC descripcion, 
                                                                to_char(c.TVRACCD_AMOUNT,'fm9999999990.00') MONTO_CARGO,
                                                                Monto_Iv Monto_IVAS
                                                           from TVRACCD c, TBBDETC a, (
                                                                                                         select distinct 
                                                                                                                to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                                         from tvraccd i 
                                                                                                         where 1=1
                                                                                                            and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                                         ) monto_iva
                                                           where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                                and a.TBBDETC_TYPE_IND = 'C'
                                                                and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                                and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                                and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
                                                           )
                                     SELECT DISTINCT 
                                            TBRACCD_PIDM PIDM,
                                            SPRIDEN_ID MATRICULA,
                                            SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                            TBRACCD_TRAN_NUMBER TRANSACCION,
                                            to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                            to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                            cargo.MONTO_CARGO SUBTOTAL,
                                            cargo.Monto_IVAS IVA,
                                            nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                            to_char(TBRACCD_EFFECTIVE_DATE, 'dd/mm/rrrr') Fecha_pago,
                                            TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                            TBBDETC_DESC DESCRIPCION,
                                            nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                            nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                            nvl(cargo.transa,0) transa,
                                            ROW_NUMBER() OVER(PARTITION BY TBRACCD_TRAN_NUMBER ORDER BY TBRACCD_EFFECTIVE_DATE) numero,
                                            upper(SPREMRG_MI) RFC,
                                            CASE
                                                 when GORADID_ADID_CODE = 'REFH' then
                                                 'BH'
                                                 when GORADID_ADID_CODE = 'REFS' then
                                                 'BS'
                                                 when GORADID_ADID_CODE = 'REFU' then 
                                                 'UI'
                                            end Serie,
                                            CASE 
                                            WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                            WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                            WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                            WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                            WHEN TBRACCD_DESC LIKE '%TARJETA CREDITO%'THEN '04'
                                            WHEN TBRACCD_DESC LIKE '%TARJETA DEBITO%'THEN '28'
                                            WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100' 
                                            ELSE '99' 
                                            END forma_pago
                                     FROM TBRACCD
                                     left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                     LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                     LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM
                                            AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
                                            AND TBRAPPL_REAPPL_IND IS NULL
                                     left join cargo on cargo.pidm = tbraccd_pidm
                                            and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                     left outer join SPREMRG on TBRACCD_PIDM = SPREMRG_PIDM
                                     left join GORADID on GORADID_PIDM = SPREMRG_PIDM 
                                                  and GORADID_ADID_CODE LIKE 'REF%'
                                     WHERE     TBBDETC_TYPE_IND = 'P'
                                            AND TBBDETC_DCAT_CODE = 'CSH'
                                            AND TRUNC (TBRACCD_EFFECTIVE_DATE) = trunc(sysdate)
                                             AND SPREMRG_PRIORITY IN
                                                      (SELECT MIN (s1.SPREMRG_PRIORITY)
                                                         FROM SPREMRG s1
                                                        WHERE SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                              AND SPREMRG_PRIORITY = s1.SPREMRG_PRIORITY)
                                             and length(SPREMRG_MI) <=13
                                          AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTCONC_TRAN_NUMBER
                                                                                                    FROM TZTCONC
                                                                                                    WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                      ORDER BY TBRACCD_PIDM,13 asc
                              
                              )LOOP

                                Insert into TZTCONC values (conceptos.PIDM,
                                                                          NULL,
                                                                          conceptos.clave_cargo,
                                                                          conceptos.Descripcion_cargo,
                                                                          conceptos.MONTO_PAGADO_CARGO,
                                                                          conceptos.SUBTOTAL,
                                                                          conceptos.IVA,
                                                                          conceptos.TRANSACCION,
                                                                          conceptos.Fecha_pago,
                                                                          conceptos.Serie,
                                                                          conceptos.RFC,
                                                                          'FM',
                                                                          conceptos.numero,
                                                                          conceptos.forma_pago,
                                                                          conceptos.transa,
                                                                          sysdate,
                                                                          USER ||'-'||'sp_Datos_Facturacion_Conceptos',
                                                                          Null,
                                                                          Null
                                                                         );
                                                                         
                              End LOOP;
                              
    End;

FUNCTION f_conceptos_out(pidm in number, transa in number) RETURN PKG_FACTURACION.concep_out

           AS

           my_var long; 
           conc_out PKG_FACTURACION.concep_out;
                      
 BEGIN 


                          open conc_out            
                            FOR      
                                    select 
                                        TZTCONC_PIDM PIDM,
                                        TZTCONC_FOLIO FOLIO,
                                        TZTCONC_CONCEPTO_CODE CONC_CODE,
                                        TZTCONC_CONCEPTO CONCEPTO,
                                        TZTCONC_MONTO MONTO,
                                        TZTCONC_SUBTOTAL SUBTOTAL,
                                        TZTCONC_IVA IVA,
                                        TZTCONC_TRAN_NUMBER TRANSACCION,
                                        TZTCONC_FECHA_CONC FECHA
                                    from TZTCONC
                                    where TZTCONC_TRAN_NUMBER = transa
                                        and TZTCONC_PIDM = pidm
--                                         and TZTCONC_FECHA_CONC = trunc(sysdate)
                                ;
                            

            RETURN (conc_out);                 
                                                                    

END f_conceptos_out;



PROCEDURE sp_conceptos_manual

is

VL_ERROR varchar2(250):= null;

    Begin

     FOR conceptos in (            
     SELECT PAGOS_FACT .*, ROW_NUMBER() OVER(PARTITION BY TRANSACCION ORDER BY TBRACCD_ACTIVITY_DATE) numero
     FROM (with cargo as (select 
                                                c.TVRACCD_PIDM PIDM, 
                                                c.TVRACCD_DETAIL_CODE cargo, 
                                                c.TVRACCD_ACCD_TRAN_NUMBER transa, 
                                                c.TVRACCD_DESC descripcion, 
                                                to_char(c.TVRACCD_AMOUNT,'fm9999999990.00') MONTO_CARGO,
                                                Monto_Iv Monto_IVAS
                                           from TVRACCD c, TBBDETC a, (select distinct to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                         from tvraccd i 
                                                                                         where 1=1
                                                                                         and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                         ) monto_iva
                                           where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                and a.TBBDETC_TYPE_IND = 'C'
                                                and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
                                                   )    
                                    SELECT DISTINCT
                                    TBRACCD_PIDM PIDM,
                                    SPRIDEN_ID MATRICULA,
                                    SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                    TBRACCD_TRAN_NUMBER TRANSACCION,
                                    to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                    to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                    cargo.MONTO_CARGO SUBTOTAL,
                                    cargo.Monto_IVAS IVA,
                                    nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                    to_char(TBRACCD_ENTRY_DATE, 'dd/mm/rrrr') Fecha_pago,
                                    TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                    TBBDETC_DESC DESCRIPCION,
                                    nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                    nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                    nvl(cargo.transa,0) transa,
                                    upper(SPREMRG_MI) RFC,
                                    CASE
                                         when GORADID_ADID_CODE = 'REFH' then
                                         'BH'
                                         when GORADID_ADID_CODE = 'REFS' then
                                         'BS'
                                         when GORADID_ADID_CODE = 'REFU' then 
                                         'UI'
                                    end Serie,
                                    TBRACCD_ACTIVITY_DATE,
                                    CASE 
                                    WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                    WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                    WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                    WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                    WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                    WHEN TBRACCD_DESC LIKE '%TARJETA CREDITO%'THEN '04'
                                    WHEN TBRACCD_DESC LIKE '%TARJETA DEBITO%'THEN '28'
                                    WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100' 
                                    ELSE '99' 
                                    END forma_pago
                             FROM TBRACCD
                             left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                             LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                             LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM  AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER AND TBRAPPL_REAPPL_IND IS NULL
                             left join cargo on cargo.pidm = tbraccd_pidm and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                             left outer join SPREMRG s on s.SPREMRG_PIDM = TBRACCD_PIDM
                             left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM and GORADID_ADID_CODE LIKE 'REF%'
                             WHERE TBBDETC_TYPE_IND = 'P'
                             AND TBBDETC_DCAT_CODE = 'CSH'
                             AND s.SPREMRG_PRIORITY IN (SELECT MIN (s1.SPREMRG_PRIORITY)
                                                      FROM SPREMRG s1
                                                      WHERE s1.SPREMRG_PIDM = s.SPREMRG_PIDM
                                                      AND s1.SPREMRG_PRIORITY = s.SPREMRG_PRIORITY)
                                     and length(s.SPREMRG_MI) <=13
                                  AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTCONC_TRAN_NUMBER
                                                              FROM TZTCONC
                                                              WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                             AND TRUNC (TBRACCD_ENTRY_DATE) = trunc(sysdate)
--                                AND TBRACCD_PIDM =  96381  --FGET_PIDM('010049440')
--                                AND TBRACCD_TRAN_NUMBER = 61 --transa
                                )PAGOS_FACT
    WHERE 1=1                            
                                  
                      )LOOP
                                    
                        Begin
                            Insert into TZTCONC values (conceptos.PIDM,
                                                                      NULL,
                                                                      conceptos.clave_cargo,
                                                                      conceptos.Descripcion_cargo,
                                                                      conceptos.MONTO_PAGADO_CARGO,
                                                                      conceptos.SUBTOTAL,
                                                                      conceptos.IVA,
                                                                      conceptos.TRANSACCION,
                                                                      conceptos.Fecha_pago,
                                                                      conceptos.Serie,
                                                                      conceptos.RFC,
                                                                      'FM',
                                                                      conceptos.numero,
                                                                      conceptos.forma_pago,
                                                                      conceptos.transa,
                                                                      sysdate,
                                                                      USER ||'-'||'sp_conceptos_manual',
                                                                      Null,
                                                                      Null
                                                                     );                                       
                        EXCEPTION
                            When Others then 
                            VL_ERROR := 'Error al Insertar' ||sqlerrm; 
                            --dbms_output.put_line('Error '||conceptos.PIDM||'+'||VL_ERROR ); 
                        END;  
                         commit;         
                                                             
                      End LOOP;

                              
    End sp_conceptos_manual;
    
PROCEDURE sp_factura_manual

is

VL_ERROR varchar2(250):= null;

        Begin
        
        
       
            for facman in(WITH CURP AS(select DISTINCT a.SPRIDEN_PIDM PIDM,
                        b.GORADID_ADDITIONAL_ID CURP
                        from SPRIDEN a
                        left join GORADID b on a.SPRIDEN_PIDM = b.GORADID_PIDM
                        where b.GORADID_ADID_CODE = 'CURP'),
                        IVA as(select TVRACCD_PIDM PIDM,
                                        TVRACCD_ACCD_TRAN_NUMBER ACCD_TRANS,
                                        TVRACCD_AMOUNT MONTO_IVA
                                        from TVRACCD, TBRAPPL
                                        where TVRACCD_PIDM = TBRAPPL_PIDM
                                        and TVRACCD_TRAN_NUMBER = TBRAPPL_CHG_TRAN_NUMBER
                                        and TVRACCD_DETAIL_CODE like 'IVA%'
                                                        )
                            SELECT DISTINCT TBRACCD_PIDM PIDM,
                                   upper(s.SPREMRG_MI) RFC,
                                   to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO,
                                   'FM' TIPO_DOCTO,
                                    ' ' ESTATUS_FACT,
                                    ' ' UUII,
                                    TBRACCD_ENTRY_DATE FECHA_PROCESO,
                                    TBRACCD_TRAN_NUMBER TRANSACCION,
                                    '0' TXT,
                                    0 FOLIO,
                                    CASE
                                         when d.GORADID_ADID_CODE = 'REFH' then
                                         'BH'
                                         when d.GORADID_ADID_CODE = 'REFS' then
                                         'BS'
                                         when GORADID_ADID_CODE = 'REFU' then 
                                         'UI'
                                    end SERIE,
                                    0 RESPUESTA,
                                    ' ' ERROR,
                                    '0' XML,
                                    ' ' TIPO,
                                    ' ' TIPO_FACT,
                                    TBRACCD_DESC TIPO_PAGO,
                                    ' ' STST_TIMBRADO,
                                    r.SZTDTEC_NUM_RVOE RVOE_NUM,
                                    to_char(nvl((TBRACCD_AMOUNT - IVA.MONTO_IVA), TBRACCD_AMOUNT),'fm9999999990.00') SUBTOTAL,
                                    to_char(nvl(IVA.MONTO_IVA, 0),'fm9999999990.00') IVA,
                                    CASE
                                         when GORADID_ADID_CODE = 'REFH' then
                                         'Profesional Técnico'
                                         when GORADID_ADID_CODE IN ('REFS', 'REFU') then
                                         ' '
                                    end NIVEL,
                                    to_char (TBRACCD_ENTRY_DATE,'RRRR-MM-DD') FECHA_PAGO,
                                    CURP.CURP CURP
                            FROM TBRACCD
                              left join IVA on TBRACCD_PIDM = IVA.PIDM and TBRACCD_TRAN_NUMBER = IVA.ACCD_TRANS
                              left join SPREMRG s on TBRACCD_PIDM = s.SPREMRG_PIDM
                              left join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                              left outer join SARADAP b on b.SARADAP_PIDM = s.SPREMRG_PIDM 
                              left outer join SORLCUR c on c.SORLCUR_PIDM = s.SPREMRG_PIDM 
                              left join GORADID d on d.GORADID_PIDM = s.SPREMRG_PIDM and d.GORADID_ADID_CODE LIKE 'REF%'
                              join SZVCAMP on szvcamp_camp_alt_code = substr(SPRIDEN_ID,1,2)
                              left join CURP on s.SPREMRG_PIDM = CURP.PIDM
                              join SZTDTEC r on r.SZTDTEC_CAMP_CODE = c.SORLCUR_CAMP_CODE and r.SZTDTEC_PROGRAM = c.SORLCUR_PROGRAM and r.SZTDTEC_TERM_CODE = c.SORLCUR_TERM_CODE_CTLG 
                              join TZTNCD on TZTNCD_CODE = tbraccd_detail_code and TZTNCD_CONCEPTO in ( 'Deposito', 'Poliza', 'Nota Distribucion')
                             WHERE s.SPREMRG_MI IS NOT NULL
                             AND c.SORLCUR_LMOD_CODE in ('LEARNER', 'ADMISSIONS')
                             AND TRUNC (TBRACCD_ENTRY_DATE) = trunc (sysdate) --'13/05/2019'
                             AND TBRACCD_AMOUNT > 0
                             AND c.SORLCUR_SEQNO = (SELECT MAX(c.SORLCUR_SEQNO)
                                                     FROM SORLCUR c1
                                                     WHERE c1.SORLCUR_PIDM = c.SORLCUR_PIDM
                                                     AND c1.SORLCUR_SEQNO =  c.SORLCUR_SEQNO
                                                     AND c1.SORLCUR_LMOD_CODE = c.SORLCUR_LMOD_CODE
                                                     AND c1.SORLCUR_PROGRAM = c.SORLCUR_PROGRAM
                                                     AND c1.SORLCUR_CAMP_CODE = c.SORLCUR_CAMP_CODE)                               
                            AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TZTFACT_TRAN_NUMBER
                                                            FROM TZTFACT
                                                            WHERE TBRACCD_PIDM = TZTFACT_PIDM)                                                                                               
                            AND s.SPREMRG_PRIORITY = (SELECT max(s1.SPREMRG_PRIORITY)
                                                    FROM SPREMRG s1
                                                    WHERE s1.SPREMRG_PIDM = s.SPREMRG_PIDM
                                                    AND s1.SPREMRG_RELT_CODE = s.SPREMRG_RELT_CODE
                                                     )
                         
                           --and spriden_pidm = 33506
                           ORDER BY fecha_pago


                        ) loop
                        
                        
                        BEGIN
                            INSERT INTO TZTFACT VALUES(
                                            facman.PIDM,
                                            facman.RFC,
                                            facman.MONTO,
                                            facman.TIPO_DOCTO,
                                            facman.ESTATUS_FACT,
                                            facman.UUII,
                                             facman.FECHA_PROCESO,
                                            facman.TRANSACCION,
                                            facman.TXT,
                                            facman.FOLIO,
                                            facman.SERIE,
                                            facman.RESPUESTA,
                                            facman.ERROR,
                                            facman.XML,
                                            facman.TIPO,
                                            facman.TIPO_FACT,
                                            facman.TIPO_PAGO,
                                            facman.STST_TIMBRADO,
                                            facman.RVOE_NUM,
                                            facman.SUBTOTAL,
                                            facman.IVA,
                                            facman.NIVEL,
                                            facman.FECHA_PAGO,
                                            facman.CURP

                                     );
                        EXCEPTION
                                    When Others then 
                                    VL_ERROR := 'Error al Insertar' ||sqlerrm; 
                           --   dbms_output.put_line('Error '||facman.PIDM||'+'||VL_ERROR ); 
                        END; 
                        
                          
                                    
        End LOOP;
        COMMIT;       

    End sp_factura_manual;
    
    
    FUNCTION F_SZTPAGOS_FACT_OUT (p_pidm in number) RETURN PKG_FACTURACION.cursor_SZTPAGOS_FACT_OUT
   
   AS 
   
   SZTPAGOS_FACT_OUT PKG_FACTURACION.cursor_SZTPAGOS_FACT_OUT;
   
   BEGIN
   
   open SZTPAGOS_FACT_OUT
   FOR
        SELECT a.SORLCUR_PIDM PIDM, 
        NULL Estatus_final, 
        NULL Estatus,  
        NULL Clave_Carrera, 
        a.SORLCUR_PROGRAM  CARRERA, 
        a.SORLCUR_CAMP_CODE CAMPUS, 
        a.SORLCUR_LEVL_CODE NIIVEL,
        NULL tipo_inscripcion,
        NULL inscripcion_desc,
        NULL Area_Mayor,
        NULL Descripcion_Mayor,
        NULL Area_Menor_1,
        NULL Descripcion_Salida_1,
        NULL Area_Menor_2,
        NULL Descripcion_Salida_2 
        from SORLCUR a
        WHERE 1=1
        AND a.SORLCUR_PIDM = p_pidm --230251
        AND a.SORLCUR_LMOD_CODE = 'LEARNER' 
        AND a.SORLCUR_CACT_CODE  != 'CHANGE'
        AND a.SORLCUR_ROLL_IND = 'Y'
        AND a.SORLCUR_TERM_CODE = (SELECT MAX (b.SORLCUR_TERM_CODE)
                             FROM SORLCUR b
                             WHERE 1=1
                             AND b.SORLCUR_PIDM = a.SORLCUR_PIDM
                             AND b.SORLCUR_LMOD_CODE = a.SORLCUR_LMOD_CODE
                             and b.SORLCUR_CACT_CODE= a.SORLCUR_CACT_CODE
                             AND b.SORLCUR_ROLL_IND = a.SORLCUR_ROLL_IND)
                             
        UNION                    
        SELECT a.SORLCUR_PIDM PIDM, 
        NULL Estatus_final, 
        NULL Estatus,  
        NULL Clave_Carrera, 
        a.SORLCUR_PROGRAM  CARRERA, 
        a.SORLCUR_CAMP_CODE CAMPUS, 
        a.SORLCUR_LEVL_CODE NIIVEL,
        NULL tipo_inscripcion,
        NULL inscripcion_desc,
        NULL Area_Mayor,
        NULL Descripcion_Mayor,
        NULL Area_Menor_1,
        NULL Descripcion_Salida_1,
        NULL Area_Menor_2,
        NULL Descripcion_Salida_2 
        from SORLCUR a
        WHERE 1=1
        AND a.SORLCUR_PIDM = p_pidm --230251
        AND a.SORLCUR_LMOD_CODE = 'ADMISSIONS' 
        AND a.SORLCUR_CACT_CODE  != 'CHANGE'
        AND a.SORLCUR_TERM_CODE = (SELECT MAX (b.SORLCUR_TERM_CODE)
                             FROM SORLCUR b
                             WHERE 1=1
                             AND b.SORLCUR_PIDM = a.SORLCUR_PIDM
                             AND b.SORLCUR_LMOD_CODE = a.SORLCUR_LMOD_CODE
                             and b.SORLCUR_CACT_CODE= a.SORLCUR_CACT_CODE);                                            
   RETURN (SZTPAGOS_FACT_OUT);
    
   END F_SZTPAGOS_FACT_OUT;

PROCEDURE  sp_refresh_conceptos_fac (p_pidm in number, p_tran_numb in number)  
IS
 VL_ERROR VARCHAR2(2500);
 vl_pidm NUMBER; 
 vl_tran NUMBER; 
 vl_fecha VARCHAR2(20); 
    
  BEGIN
        --DBMS_OUTPUT.PUT_LINE('ENTRA EL SELECT DE  TZTCONC CON '||p_pidm||' '||p_tran_numb);
    
        FOR c IN(
        SELECT TZTCONC_PIDM, TZTCONC_TRAN_NUMBER, TZTCONC_FECHA_CONC
        FROM TZTCONC a
        JOIN tztfact b ON b.TZTFACT_PIDM = TZTCONC_PIDM AND TZTCONC_TRAN_NUMBER = b.TZTFACT_TRAN_NUMBER AND b.TZTFACT_STST_TIMBRADO = ' ' AND TZTFACT_TIPO_DOCTO = 'FM' AND TZTFACT_PIDM = p_pidm --156234
                                   AND TZTCONC_TRAN_NUMBER = p_tran_numb
       )   
       
   LOOP

            BEGIN 
                DELETE TZTCONC
                WHERE TZTCONC_PIDM = c.TZTCONC_PIDM --vl_pidm
                AND TZTCONC_TRAN_NUMBER = c.TZTCONC_TRAN_NUMBER; --vl_tran;
                EXCEPTION
                WHEN OTHERS THEN 
                Null;
            END;         
            --COMMIT; 
            --DBMS_OUTPUT.PUT_LINE('Borró de TZTCONC'||c.TZTCONC_PIDM||' '||c.TZTCONC_TRAN_NUMBER );--||' '||vl_fecha);
            
           BEGIN
            SELECT TRUNC(TBRACCD_ENTRY_DATE) 
            INTO vl_fecha
            FROM TBRACCD
            WHERE 1=1
            AND TBRACCD_PIDM = p_pidm
            AND TBRACCD_TRAN_NUMBER = p_tran_numb
            ORDER BY TBRACCD_ENTRY_DATE DESC;
           END;  
    


        BEGIN

         FOR conceptos IN (     
                   
         SELECT PAGOS_FACT .*, ROW_NUMBER() OVER(PARTITION BY TRANSACCION ORDER BY TBRACCD_ACTIVITY_DATE) numero
         FROM (with cargo as (select 
                                                    c.TVRACCD_PIDM PIDM, 
                                                    c.TVRACCD_DETAIL_CODE cargo, 
                                                    c.TVRACCD_ACCD_TRAN_NUMBER transa, 
                                                    c.TVRACCD_DESC descripcion, 
                                                    to_char(c.TVRACCD_AMOUNT,'fm9999999990.00') MONTO_CARGO,
                                                    Monto_Iv Monto_IVAS
                                               from TVRACCD c, TBBDETC a, (select distinct to_char(nvl (i.TVRACCD_AMOUNT, 0),'fm9999999990.00') Monto_Iv, TVRACCD_PIDM ,TVRACCD_ACCD_TRAN_NUMBER
                                                                                             from tvraccd i 
                                                                                             where 1=1
                                                                                             and i.TVRACCD_DETAIL_CODE like 'IV%'
                                                                                             ) monto_iva
                                               where c.TVRACCD_DETAIL_CODE = a.TBBDETC_DETAIL_CODE
                                                    and a.TBBDETC_TYPE_IND = 'C'
                                                    and c.TVRACCD_DETAIL_CODE not like ('IVA%') 
                                                    and c.TVRACCD_pidm  = monto_iva.TVRACCD_PIDM (+)
                                                    and  c.TVRACCD_ACCD_TRAN_NUMBER =  monto_iva.TVRACCD_ACCD_TRAN_NUMBER (+)
                                                       )    
                                        SELECT DISTINCT
                                        TBRACCD_PIDM PIDM,
                                        SPRIDEN_ID MATRICULA,
                                        SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME nombre_alumno,
                                        TBRACCD_TRAN_NUMBER TRANSACCION,
                                        to_char(TBRACCD_AMOUNT,'fm9999999990.00') MONTO_PAGADO,
                                        to_char(nvl (TBRAPPL_AMOUNT, TBRACCD_AMOUNT),'fm9999999990.00')  MONTO_PAGADO_CARGO,
                                        cargo.MONTO_CARGO SUBTOTAL,
                                        cargo.Monto_IVAS IVA,
                                        nvl ( TBRAPPL_CHG_TRAN_NUMBER, TBRACCD_TRAN_NUMBER) CARGO_CUBIERTO,
                                        to_char(TBRACCD_ENTRY_DATE, 'dd/mm/rrrr') Fecha_pago,
                                        TBBDETC_DETAIL_CODE NUM_IDENTIFICACION,
                                        TBBDETC_DESC DESCRIPCION,
                                        nvl (cargo.cargo, substr (TBBDETC_DETAIL_CODE,1, 2)||'NM' ) clave_cargo,
                                        nvl (cargo.descripcion, 'PCOLEGIATURA') Descripcion_cargo,
                                        nvl(cargo.transa,0) transa,
                                        upper(SPREMRG_MI) RFC,
                                        CASE
                                             when GORADID_ADID_CODE = 'REFH' then
                                             'BH'
                                             when GORADID_ADID_CODE = 'REFS' then
                                             'BS'
                                             when GORADID_ADID_CODE = 'REFU' then
                                              'UI'
                                        end Serie,
                                        TBRACCD_ACTIVITY_DATE,
                                        CASE 
                                        WHEN TBRACCD_DESC LIKE '%EFEC%'THEN '01'
                                        WHEN TBRACCD_DESC LIKE '%CHEQUE%'THEN '02'
                                        WHEN TBRACCD_DESC LIKE '%TRANS%'THEN '03'
                                        WHEN TBRACCD_DESC LIKE '%RECLAS%'THEN '03'
                                        WHEN TBRACCD_DESC LIKE '%TDC%'THEN '04'
                                        WHEN TBRACCD_DESC LIKE '%TARJETA CREDITO%'THEN '04'
                                        WHEN TBRACCD_DESC LIKE '%TARJETA DEBITO%'THEN '28'
                                        WHEN TBRACCD_DESC LIKE '%POLIZA%'THEN '100' 
                                        ELSE '99' 
                                        END forma_pago
                                 FROM TBRACCD
                                 left join SPRIDEN on TBRACCD_PIDM = SPRIDEN_PIDM and SPRIDEN_CHANGE_IND is null
                                 LEFT JOIN TBBDETC ON TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                                 LEFT OUTER JOIN TBRAPPL ON TBRACCD_PIDM = TBRAPPL_PIDM  AND TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER AND TBRAPPL_REAPPL_IND IS NULL
                                 left join cargo on cargo.pidm = tbraccd_pidm and cargo.transa = TBRAPPL_CHG_TRAN_NUMBER
                                 left outer join SPREMRG s on s.SPREMRG_PIDM = TBRACCD_PIDM
                                 left join GORADID on GORADID_PIDM = s.SPREMRG_PIDM and GORADID_ADID_CODE LIKE 'REF%'
                                 WHERE TBBDETC_TYPE_IND = 'P'
                                 AND TBBDETC_DCAT_CODE = 'CSH'
                                 AND s.SPREMRG_MI is not null
                                 AND s.SPREMRG_MI is not null
                                 AND s.SPREMRG_RELT_CODE = 'I'
                                 AND to_number (s.SPREMRG_PRIORITY) IN (SELECT MAX (to_number (s1.SPREMRG_PRIORITY))
                                                                        FROM SPREMRG s1
                                                                        WHERE s.SPREMRG_PIDM = s1.SPREMRG_PIDM
                                                                          And s.SPREMRG_MI = s1.SPREMRG_MI
                                                                          AND s.SPREMRG_RELT_CODE = s1.SPREMRG_RELT_CODE)
                                         and length(s.SPREMRG_MI) <=13
                                      AND TBRACCD_TRAN_NUMBER not  IN (SELECT TZTCONC_TRAN_NUMBER
                                                                  FROM TZTCONC
                                                                  WHERE TBRACCD_PIDM = TZTCONC_PIDM)
                                 AND TRUNC (TBRACCD_ENTRY_DATE)  = vl_fecha --c.TZTCONC_FECHA_CONC --vl_fecha--C.TZTCONC_FECHA_CONC --between '09/06/2019' and '10/06/2019'
                                 AND TBRACCD_PIDM = p_pidm -- vl_pidm --156234 FGET_PIDM('010049440')
                                    --AND TBRACCD_TRAN_NUMBER = 61 --transa
                                    )PAGOS_FACT
        WHERE 1=1)
            
          LOOP                    
                                      
          --DBMS_OUTPUT.PUT_LINE('Recupera para insertar en TZTCONC de cursor concepto ' ||conceptos.PIDM||' '||conceptos.Descripcion_cargo||' '||conceptos.MONTO_PAGADO_CARGO||' '||conceptos.TRANSACCION||' '||conceptos.Fecha_pago);    
                BEGIN
                    INSERT INTO TZTCONC VALUES (conceptos.PIDM,
                                              NULL,
                                              conceptos.clave_cargo,
                                              conceptos.Descripcion_cargo,
                                              conceptos.MONTO_PAGADO_CARGO,
                                              conceptos.SUBTOTAL,
                                              conceptos.IVA,
                                              conceptos.TRANSACCION,
                                              conceptos.Fecha_pago,
                                              conceptos.Serie,
                                              conceptos.RFC,
                                              'FM',
                                              conceptos.numero,
                                              conceptos.forma_pago,
                                              conceptos.transa,
                                              sysdate,
                                              USER||'-'||'sp_refresh_conceptos_fac',
                                              Null,
                                              Null
                                             );                                       
                EXCEPTION
                WHEN OTHERS THEN 
                VL_ERROR := 'Error al Insertar' ||SQLERRM; 
                --dbms_output.put_line('Error '||conceptos.PIDM||'+'||VL_ERROR ); 
                END; 
             --DBMS_OUTPUT.PUT_LINE('Insertó en TZTCONC  ' ||conceptos.PIDM||' '||conceptos.Descripcion_cargo||' '||conceptos.MONTO_PAGADO_CARGO||' '||conceptos.TRANSACCION||' '||conceptos.Fecha_pago);                                    
          END LOOP;
        COMMIT;
     END;         
    END LOOP;
    COMMIT;                    
  END;  

END PKG_FACTURACION;
/

DROP PUBLIC SYNONYM PKG_FACTURACION;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FACTURACION FOR BANINST1.PKG_FACTURACION;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_FACTURACION TO PUBLIC;
