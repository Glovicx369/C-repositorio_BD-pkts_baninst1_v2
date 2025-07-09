DROP PACKAGE BODY BANINST1.PKG_FINANZAS_REPORTES;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_FINANZAS_REPORTES 
IS PROCEDURE sp_intereses 
IS 
BEGIN
   execute immediate('TRUNCATE TABLE  migra.cargos_aplicados ');
Commit;
Insert into
   migra.cargos_aplicados 
   select distinct
      spriden_id matricula,
      TBBDETC_DCAT_CODE categoria,
      TBRACCD_DETAIL_CODE concepto,
      tbraccd_amount monto,
      TZTNCD_CONCEPTO tipo,
      TRATO,
      TBRACCD_TRAN_NUMBER secuencia,
      TBRACCD_EFFECTIVE_DATE FECHA_VENCIMIENTO,
      0,
      TBBDETC_DESC DESCRIPCION,
      TBRACCD_BALANCE Balance 
   from
      tbraccd 
      join  TZTNCD  on TZTNCD_CODE = TBRACCD_DETAIL_CODE 
         And TZTNCD_CONCEPTO = 'Interes' 
      join  spriden  on spriden_pidm = tbraccd_pidm 
         and spriden_change_ind is null 
      join   tbbdetc  on tbbdetc_detail_code = tbraccd_detail_code;
commit;
END
;
PROCEDURE sp_colegiaturas IS 
Begin
   execute immediate('TRUNCATE TABLE  migra.cargos_aplicados ');
Commit;
Insert into
    migra.cargos_aplicados  
   select distinct
      spriden_id matricula,
      TBBDETC_DCAT_CODE categoria,
      TBRACCD_DETAIL_CODE concepto,
      tbraccd_amount monto,
      TZTNCD_CONCEPTO tipo,
      TRATO,
      TBRACCD_TRAN_NUMBER secuencia,
      TBRACCD_EFFECTIVE_DATE FECHA_VENCIMIENTO,
      0,
      TBBDETC_DESC DESCRIPCION,
      TBRACCD_BALANCE Balance 
   from
      tbraccd 
      join  TZTNCD  on TZTNCD_CODE = TBRACCD_DETAIL_CODE 
      join  spriden  on spriden_pidm = tbraccd_pidm 
         and spriden_change_ind is null 
      join  tbbdetc  on tbbdetc_detail_code = tbraccd_detail_code 
         and TBBDETC_DCAT_CODE in  (  'COL' );
commit;
END
;
PROCEDURE sp_notasdebito IS 
Begin
   execute immediate('TRUNCATE TABLE  migra.cargos_aplicados ');
Commit;
Insert into
    migra.cargos_aplicados  
   select distinct
      spriden_id matricula,
      TBBDETC_DCAT_CODE categoria,
      TBRACCD_DETAIL_CODE concepto,
      tbraccd_amount monto,
      TZTNCD_CONCEPTO tipo,
      TRATO,
      TBRACCD_TRAN_NUMBER secuencia,
      TBRACCD_EFFECTIVE_DATE FECHA_VENCIMIENTO,
      0,
      TBBDETC_DESC DESCRIPCION,
      TBRACCD_BALANCE Balance 
   from
      tbraccd 
      join  TZTNCD  on TZTNCD_CODE = TBRACCD_DETAIL_CODE 
      join  spriden  on spriden_pidm = tbraccd_pidm 
         and spriden_change_ind is null 
      join   tbbdetc on tbbdetc_detail_code = tbraccd_detail_code 
         and TBBDETC_DCAT_CODE in ('ABC','ACC','ENV','SER','CCC','OTG', 'VTA');
                                                
commit;
end
;
END
PKG_FINANZAS_REPORTES;
/

DROP PUBLIC SYNONYM PKG_FINANZAS_REPORTES;

CREATE OR REPLACE PUBLIC SYNONYM PKG_FINANZAS_REPORTES FOR BANINST1.PKG_FINANZAS_REPORTES;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_FINANZAS_REPORTES TO PUBLIC;
