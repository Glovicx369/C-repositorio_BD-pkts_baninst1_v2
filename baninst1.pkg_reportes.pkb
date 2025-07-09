DROP PACKAGE BODY BANINST1.PKG_REPORTES;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_REPORTES IS

PROCEDURE sp_pagos_con_referencia
IS

 vl_cadena varchar2(500);

 BEGIN

 --execute immediate('TRUNCATE TABLE tszpaco');

 EXECUTE IMMEDIATE 'TRUNCATE TABLE BANINST1.TZTPACO';
 --delete tszpaco;
  Commit;

 for c in (
 select distinct TBRACCD_PIDM pidm,
 spriden_id Matricula,
 SPRIDEN_LAST_NAME ||' '||SPRIDEN_FIRST_NAME Nombre,
 GORADID_ADDITIONAL_ID Referencia,
 GOREMAL_EMAIL_ADDRESS Correo,
 TBRACCD_TRAN_NUMBER secuencia_Banner,
 TBRACCD_PAYMENT_ID id_pago,
 TBRACCD_AMOUNT Monto,
 TRUNC (TBRACCD_TRANS_DATE) Fecha_Pago,
 TRUNC (TBRACCD_ENTRY_DATE) Fecha_Registro,
 TBRACCD_DETAIL_CODE codigo,
 tbbdetc_desc descrip
 from tbbdetc, spriden, goradid, GOREMAL a, tbraccd
 Where TBRACCD_DETAIL_CODE = tbbdetc_detail_code
 And TBRACCD_DETAIL_CODE in (select a1.tbbdetc_detail_code
 from tbbdetc a1
 Where TBBDETC_DCAT_CODE = 'CSH')
 And TBRACCD_AMOUNT >0
 And spriden_pidm = TBRACCD_PIDM
 and SPRIDEN_CHANGE_IND is null
 And goradid_pidm = spriden_pidm (+)
 and GORADID_ADID_CODE like 'REF%'
 And a.GOREMAL_PIDM = spriden_pidm (+)
 And a.GOREMAL_SURROGATE_ID = (select max (GOREMAL_SURROGATE_ID)
 from GOREMAL a1
 Where a1.GOREMAL_PIDM = a.GOREMAL_PIDM
 And a1.GOREMAL_EMAIL_ADDRESS like '%@%')
 ORDER BY 9 DESC
 ) loop

 vl_cadena := null;
 for cadena in (Select TBRACDT_TEXT, TBRACDT_SEQ_NUMBER
 from TBRACDT
 where TBRACDT_PIDM = c.pidm
 and TBRACDT_TRAN_NUMBER = c.secuencia_Banner
 order by 2 ) loop

 vl_cadena := vl_cadena || cadena.TBRACDT_TEXT;
 --dbms_output.put_line('cadena' ||vl_cadena );
 End loop;

 Insert into tszpaco values (c.pidm,
 c.matricula,
 c.nombre,
 c.referencia,
 c.correo,
 c.secuencia_banner,
 c.id_pago,
 c.monto,
 c.fecha_pago,
 c.fecha_registro,
 c.codigo,
 c.descrip,
 vl_cadena);

 end loop;
 commit;
 END;


PROCEDURE sp_moras
IS

 BEGIN

 Begin
 --execute immediate('TRUNCATE TABLE TZTMORA');
  EXECUTE IMMEDIATE 'TRUNCATE TABLE TAISMGR.TZTMORA';
 --delete TZTMORA;
 Commit;

 For mora in (

 select distinct c.TBRACCD_PIDM pidm,
 b.spriden_id Matricula,
 b.SPRIDEN_LAST_NAME ||' '||b.SPRIDEN_FIRST_NAME Nombre,
 c.TBRACCD_Balance Saldo,
 TRUNC (c.TBRACCD_EFFECTIVE_DATE) Fecha_cargo,
 ceil ((sysdate) - TRUNC (c.TBRACCD_EFFECTIVE_DATE)) dias ,
 c.TBRACCD_DETAIL_CODE codigo,
 a.tbbdetc_desc descrip,
 a.TBBDETC_DCAT_CODE
 from tbbdetc a, spriden b, tbraccd c
 Where c.TBRACCD_DETAIL_CODE = a.tbbdetc_detail_code
 And c.TBRACCD_DETAIL_CODE in (select a1.tbbdetc_detail_code
 from tbbdetc a1
 Where a.TBBDETC_TYPE_IND = a1.TBBDETC_TYPE_IND)
 and a.TBBDETC_TYPE_IND = 'C'
 And c.TBRACCD_AMOUNT >0
 And c.tbraccd_balance > 0
 And b.spriden_pidm = TBRACCD_PIDM
 and b.SPRIDEN_CHANGE_IND is null
 ORDER BY 1, 9 DESC


 ) loop

 Insert into TZTMORA values (mora.pidm,
 mora.matricula,
 mora.nombre,
 mora.saldo,
 mora.fecha_cargo,
 mora.dias,
 mora.descrip,
 null);

 End Loop;

 End;


 Begin

 for estat in (select distinct b.sgbstdn_pidm pidm, b.SGBSTDN_STST_CODE estatus
 from TZTMORA a, sgbstdn b
 Where a.TZTMORA_PIDM = b.sgbstdn_pidm
 And b.SGBSTDN_TERM_CODE_EFF = (select max ( b1.SGBSTDN_TERM_CODE_EFF)
 from SGBSTDN b1
 where b.sgbstdn_pidm = b1.sgbstdn_pidm) ) loop

 Update TZTMORA
 set TZTMORA_ESTATUS = estat.estatus
 where TZTMORA_PIDM= estat.pidm;
 End Loop;
 Commit;

 End;


 Begin
 For act in ( select distinct TZTMORA_pidm pidm, TZTMORA_DIAS dias
 from TZTMORA a
 where a.TZTMORA_DIAS = (select max (a1.TZTMORA_DIAS)
 from TZTMORA a1
 where a.TZTMORA_pidm = a1.TZTMORA_pidm)
 order by 1) loop

 Update TZTMORA
 set TZTMORA_DIAS = act.dias
 where TZTMORA_pidm = act.pidm;
 End Loop;
 Commit;
 End;

 END;


PROCEDURE sp_moras_col
IS

 BEGIN

 Begin
 --execute immediate('TRUNCATE TABLE TZTMORA_col');
   EXECUTE IMMEDIATE 'TRUNCATE TABLE TAISMGR.TZTMORA_COL';
 --delete TZTMORA_col;
 Commit;

 For mora in (

 select distinct c.TBRACCD_PIDM pidm,
 b.spriden_id Matricula,
 b.SPRIDEN_LAST_NAME ||' '||b.SPRIDEN_FIRST_NAME Nombre,
 c.TBRACCD_Balance Saldo,
 TRUNC (c.TBRACCD_EFFECTIVE_DATE) Fecha_cargo,
 ceil ((sysdate) - TRUNC (c.TBRACCD_EFFECTIVE_DATE)) dias ,
 c.TBRACCD_DETAIL_CODE codigo,
 a.tbbdetc_desc descrip,
 a.TBBDETC_DCAT_CODE
 from tbbdetc a, spriden b, tbraccd c
 Where c.TBRACCD_DETAIL_CODE = a.tbbdetc_detail_code
 And c.TBRACCD_DETAIL_CODE in (select a1.tbbdetc_detail_code
 from tbbdetc a1
 Where a.TBBDETC_TYPE_IND = a1.TBBDETC_TYPE_IND)
 and a.TBBDETC_TYPE_IND = 'C'
 and a.TBBDETC_DCAT_CODE = 'COL'
 And c.TBRACCD_AMOUNT >0
 And c.tbraccd_balance > 0
 And b.spriden_pidm = TBRACCD_PIDM
 and b.SPRIDEN_CHANGE_IND is null
 ORDER BY 1, 9 DESC


 ) loop

 Insert into TZTMORA_col values (mora.pidm,
 mora.matricula,
 mora.nombre,
 mora.saldo,
 mora.fecha_cargo,
 mora.dias,
 mora.descrip,
 null);

 End Loop;

 End;


 Begin

 for estat in (select distinct b.sgbstdn_pidm pidm, b.SGBSTDN_STST_CODE estatus
 from TZTMORA_col a, sgbstdn b
 Where a.TZTMORA_PIDM = b.sgbstdn_pidm
 And b.SGBSTDN_TERM_CODE_EFF = (select max ( b1.SGBSTDN_TERM_CODE_EFF)
 from SGBSTDN b1
 where b.sgbstdn_pidm = b1.sgbstdn_pidm) ) loop

 Update TZTMORA_col
 set TZTMORA_ESTATUS = estat.estatus
 where TZTMORA_PIDM= estat.pidm;
 End Loop;
 Commit;

 End;


 Begin
 For act in ( select distinct TZTMORA_pidm pidm, TZTMORA_DIAS dias
 from TZTMORA_col a
 where a.TZTMORA_DIAS = (select max (a1.TZTMORA_DIAS)
 from TZTMORA_col a1
 where a.TZTMORA_pidm = a1.TZTMORA_pidm)
 order by 1) loop

 Update TZTMORA_col
 set TZTMORA_DIAS = act.dias
 where TZTMORA_pidm = act.pidm;
 End Loop;
 Commit;
 End;

 END;

Function f_saldototal (p_pidm in number) return varchar2

Is

vl_monto number:=0;
vl_moneda varchar2(10);

 Begin
 select sum(nvl (tbraccd_balance, 0)) balance
 Into vl_monto
 from tbraccd
 Where tbraccd_pidm = p_pidm; --39423
 Return (vl_monto);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_monto :=0;
 Return (vl_monto);
 --Return(vl_moneda);
 END f_saldototal;


Function f_saldodia (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
 Begin

 select sum(nvl (tbraccd_balance, 0)) balance
 Into vl_monto
 from tbraccd, TBBDETC
 Where tbraccd_pidm = p_pidm
 And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
-- And TBBDETC_TYPE_IND = 'C'
 And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate); --39423

 Return (vl_monto);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_monto :=0;
 vl_moneda:=Null;
 Return (vl_monto);
 -- Return(vl_moneda);
 END f_saldodia;



Function f_cargo_vencidos (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
 Begin



 select count (*) cargos
 Into vl_monto
 from tbraccd, TBBDETC
 Where tbraccd_pidm = p_pidm
 And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 And TBBDETC_TYPE_IND = 'C'
 And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate) --39423
 And tbraccd_balance > 0;

 Return (vl_monto);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_monto :=0;
 vl_moneda:=Null;
 Return (vl_monto);
 -- Return(vl_moneda);
 END f_cargo_vencidos;


Function f_fecha_pago_vieja (p_pidm in number ) return varchar2

is

vl_fecha varchar2(10);

Begin
 select distinct min (TBRACCD_EFFECTIVE_DATE)
 Into vl_fecha
 from tbraccd, TBBDETC
 Where tbraccd_pidm = p_pidm
 And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 And TBBDETC_TYPE_IND = 'C'
 And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate) --39423
 And tbraccd_balance > 0;

 Return (vl_fecha);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_fecha:=Null;
 Return (vl_fecha);
 -- Return(vl_moneda);
 END f_fecha_pago_vieja;

Function f_fecha_pago_alta (p_pidm in number ) return varchar2

is

vl_fecha varchar2(10);

Begin
 select distinct max (TBRACCD_EFFECTIVE_DATE)
 Into vl_fecha
 from tbraccd, TBBDETC
 Where tbraccd_pidm = p_pidm
 And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 And TBBDETC_TYPE_IND = 'C'
 And TBRACCD_EFFECTIVE_DATE <= trunc(sysdate) --39423
 And tbraccd_balance > 0;

 Return (vl_fecha);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_fecha:=Null;
 Return (vl_fecha);
 -- Return(vl_moneda);
 END f_fecha_pago_alta;

Function f_dias_atraso (p_pidm in number ) return varchar2

is

vl_dias varchar2(10);

Begin

 select distinct TZTMORA_DIAS
 Into vl_dias
 from tbraccd, TZTMORA
 Where tbraccd_pidm = TZTMORA_pidm
 and TZTMORA_DIAS >= 1
 And tbraccd_pidm = p_pidm;

 Return (vl_dias);
 Exception
 when Others then
 vl_dias:=Null;
 Return (vl_dias);
 -- Return(vl_moneda);
 END f_dias_atraso;


 Function f_mora (p_pidm in number ) return varchar2

is

vl_Mora varchar2(10);

Begin



select distinct case
 when TZTMORA_dias between 1 and 30 then
 'Mora1'
 when TZTMORA_dias between 31 and 60 then
 'Mora2'
 when TZTMORA_dias between 61 and 90 then
 'Mora3'
 when TZTMORA_dias between 91 and 120 then
 'Mora4'
 when TZTMORA_dias between 121 and 150 then
 'Mora5'
when TZTMORA_dias between 151 and 180 then
 'Mora6'
 when TZTMORA_dias > 180 then
 'Mora7'
 End as Mora
 Into vl_Mora
from TZTMORA
Where TZTMORA_PIDM = p_pidm;

 Return (vl_Mora);
 Exception
 when Others then
 vl_Mora:=Null;
 Return (vl_Mora);
 -- Return(vl_moneda);
 END f_mora;

Function f_cargo_total_futuro (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
 Begin



 select sum (tbraccd_balance)
 Into vl_monto
 from tbraccd, TBBDETC
 Where tbraccd_pidm = p_pidm
 And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 And TBBDETC_TYPE_IND = 'C'
 And TBRACCD_EFFECTIVE_DATE > trunc(sysdate) --39423
 And tbraccd_balance > 0;

 Return (vl_monto);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_monto :=0;
 Return (vl_monto);
 -- Return(vl_moneda);
 END f_cargo_total_futuro;


Function f_saldocorte (p_pidm in number ) RETURN varchar2

As


vl_vencimiento number;
vl_fecha varchar2(10);
vl_monto number:=0;
vl_moneda varchar2(10);
vl_mes varchar2(2);
 v_error varchar2(4000);
 vl_vence varchar2(10);
 vl_secuencia number:=0;


 Begin

 Begin
 select distinct to_number (decode (substr (sgbstdn_rate_code, 4, 1), 'A', 15, 'B', '30', 'C', '10')) vencimiento
 Into vl_vencimiento
 from sgbstdn
 Where sgbstdn_pidm = p_pidm;
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

 If vl_mes = '02' and vl_vencimiento = '30' then
 vl_vencimiento := '28';
 End if;

 vl_vence := (vl_fecha||'/'|| vl_vencimiento);



 BEGIN

 select min (TBRACCD_TRAN_NUMBER), nvl (a.tbraccd_balance, 0)
 into vl_secuencia, vl_monto
 from tbraccd a
 where a.tbraccd_pidm = p_pidm
 And a.tbraccd_balance > 0
 And trunc (a.TBRACCD_EFFECTIVE_DATE) > to_date (vl_vence,'rrrr/mm/dd')
 group by a.tbraccd_balance;

 Exception
 When Others then
 vl_monto :=0;
 vl_secuencia :=0;

 End;
 RETURN (vl_monto);
 Exception
 when Others then
 vl_monto :=0;

 RETURN (vl_monto);
 End f_saldocorte;


Function f_cargo_Numero_futuro (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
 Begin



 select count (*)
 Into vl_monto
 from tbraccd, TBBDETC
 Where tbraccd_pidm = p_pidm
 And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 And TBBDETC_TYPE_IND = 'C'
 And TBRACCD_EFFECTIVE_DATE > trunc(sysdate) --39423
 And tbraccd_balance > 0;

 Return (vl_monto);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_monto :=0;
 Return (vl_monto);
 -- Return(vl_moneda);
 END f_cargo_Numero_futuro;


Function f_fechacorte (p_pidm in number ) RETURN varchar2

As


vl_vencimiento number;
vl_fecha varchar2(10);
vl_monto varchar2(10);
vl_moneda varchar2(10);
vl_mes varchar2(2);
 v_error varchar2(4000);
 vl_vence varchar2(10);
 vl_secuencia number:=0;


 Begin

 Begin
 select distinct to_number (decode (substr (sgbstdn_rate_code, 4, 1), 'A', 15, 'B', '30', 'C', '10')) vencimiento
 Into vl_vencimiento
 from sgbstdn
 Where sgbstdn_pidm = p_pidm;
 Exception
 When Others then
 vl_vencimiento := 30;
 End;


 dbms_output.put_line('rate:'||vl_vencimiento);

 Begin
 select to_char (sysdate,'YYYY/MM')
 Into vl_fecha
 from dual;
 End;


 dbms_output.put_line('vl_fecha:'||vl_fecha);

 Begin
 select to_char (sysdate,'MM')
 Into vl_mes
 from dual;
 End;

 dbms_output.put_line('vl_mes:'||vl_mes);

 If vl_mes = '02' and vl_vencimiento = '30' then
 vl_vencimiento := '28';
 End if;

 vl_vence := (vl_fecha||'/'|| vl_vencimiento);


 dbms_output.put_line('vl_vence:'||vl_vence);


 BEGIN

 select min (TBRACCD_TRAN_NUMBER), trunc (TBRACCD_EFFECTIVE_DATE)
 into vl_secuencia, vl_monto
 from tbraccd a
 where a.tbraccd_pidm = p_pidm
 And a.tbraccd_balance > 0
 And trunc (a.TBRACCD_EFFECTIVE_DATE) = to_date (vl_vence,'rrrr/mm/dd')
 group by a.TBRACCD_EFFECTIVE_DATE;





 Exception
 When Others then
 vl_monto :=null;
 vl_secuencia :=0;

 End;

 dbms_output.put_line('vl_monto:'||vl_monto);
 dbms_output.put_line('vl_secuencia:'||vl_secuencia);

 RETURN (vl_monto);
 Exception
 when Others then
 vl_monto :=null;

 RETURN (vl_monto);
 End f_fechacorte;


Function f_pago_total (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
 Begin



 select sum (TBRACCD_AMOUNT)
 Into vl_monto
 from tbraccd, TBBDETC
 Where tbraccd_pidm = p_pidm
 And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 And TBBDETC_TYPE_IND = 'P'
 and TBBDETC_DCAT_CODE = 'CSH'
 and TBRACCD_TRAN_NUMBER NOT IN
 -- Para los cargos negativos que se matan asi mismos
 (SELECT TBRACCD_TRAN_NUMBER
 FROM TBRACCD, TBBDETC
 WHERE TBRACCD_PIDM = p_pidm
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
 WHERE TBRACCD_PIDM = p_pidm
 AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 AND TBBDETC_TYPE_IND = 'C'
 AND TBRACCD_AMOUNT < 0
 )
-- UNION
-- SELECT TBRACCD_TRAN_NUMBER_PAID
-- FROM TBRACCD, TBBDETC
-- WHERE TBRACCD_PIDM = :p_pidm
-- AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
-- AND TBBDETC_TYPE_IND = 'C'
-- AND TBRACCD_AMOUNT < 0
 );
 -- And TBRACCD_EFFECTIVE_DATE > trunc(sysdate) --39423
 -- And tbraccd_balance > 0;

 Return (vl_monto);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_monto :=0;
 Return (vl_monto);
 -- Return(vl_moneda);
 END f_pago_total;


Function f_num_total_pago (p_pidm in number ) return varchar2

is

vl_monto number:=0;
vl_moneda varchar2(10);
 Begin



 select count(*)
 Into vl_monto
 from tbraccd, TBBDETC
 Where tbraccd_pidm = p_pidm
 And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 And TBBDETC_TYPE_IND = 'P'
 and TBBDETC_DCAT_CODE = 'CSH'
 and TBRACCD_TRAN_NUMBER NOT IN
 -- Para los cargos negativos que se matan asi mismos
 (SELECT TBRACCD_TRAN_NUMBER
 FROM TBRACCD, TBBDETC
 WHERE TBRACCD_PIDM = p_pidm
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
 WHERE TBRACCD_PIDM = p_pidm
 AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
 AND TBBDETC_TYPE_IND = 'C'
 AND TBRACCD_AMOUNT < 0
 )
-- UNION
-- SELECT TBRACCD_TRAN_NUMBER_PAID
-- FROM TBRACCD, TBBDETC
-- WHERE TBRACCD_PIDM = :p_pidm
-- AND TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
-- AND TBBDETC_TYPE_IND = 'C'
-- AND TBRACCD_AMOUNT < 0
 );
 -- And TBRACCD_EFFECTIVE_DATE > trunc(sysdate) --39423
 -- And tbraccd_balance > 0;

 Return (vl_monto);
 --Return(vl_moneda);
 Exception
 when Others then
 vl_monto :=0;
 Return (vl_monto);
 -- Return(vl_moneda);
 END f_num_total_pago;


 Function f_jornada (p_pidm in number ) RETURN varchar2
 Is

vl_Jornada varchar2 (10);


 Begin

 select DISTINCT b.SGRSATT_ATTS_CODE
 Into vl_Jornada
 from SORLCUR a
 left outer join SGRSATT b on a.SORLCUR_PIDM = b.SGRSATT_PIDM
 and b.SGRSATT_STSP_KEY_SEQUENCE = a.SORLCUR_KEY_SEQNO
 and b.SGRSATT_TERM_CODE_EFF = a.SORLCUR_TERM_CODE
 And regexp_like (b.SGRSATT_ATTS_CODE, '^[0-9]')
 And b.SGRSATT_VERSION in (Select max (b1.SGRSATT_VERSION)
 from SGRSATT b1
 where b.SGRSATT_PIDM = b1.SGRSATT_PIDM
 And b.SGRSATT_TERM_CODE_EFF = b1.SGRSATT_TERM_CODE_EFF
 And b.SGRSATT_ATTS_CODE = b1.SGRSATT_ATTS_CODE)
 left outer join sgbstdn c on a.SORLCUR_PIDM = c.sgbstdn_pidm
 and a.sorlcur_program = c.sgbstdn_program_1
 and C.SGBSTDN_TERM_CODE_EFF in (select max (c1.SGBSTDN_TERM_CODE_EFF)
 from SGBSTDN c1
 Where c.sgbstdn_pidm = c1.sgbstdn_pidm)
 where a.SORLCUR_LMOD_CODE = 'LEARNER'
 And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
 from SORLCUR a1
 where a.SORLCUR_pidm = a1.SORLCUR_pidm
 And a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
 and a.sorlcur_pidm = p_pidm;


 Return (vl_Jornada);
 Exception
 when Others then
 vl_Jornada :=null;
 Return (vl_Jornada);
 END f_jornada;




Function f_no_materia (p_pidm in number ) RETURN varchar2

Is

vl_Jornada number:=0;

 Begin
 SELECT DISTINCT count (1)
 Into vl_Jornada
 FROM ssbsect a , SFRSTCR b
 WHERE a.SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE
 AND b.SFRSTCR_CRN = a.SSBSECT_CRN
 AND b.SFRSTCR_GRDE_CODE IS NULL
 AND b.SFRSTCR_RSTS_CODE = 'RE'
 And b.SFRSTCR_TERM_CODE = (select max (b1.SFRSTCR_TERM_CODE)
 from SFRSTCR b1
 Where b.SFRSTCR_pidm = b1.SFRSTCR_pidm)
 AND b.SFRSTCR_PIDM = p_pidm;


 Return (vl_Jornada);
 Exception
 when Others then
 vl_Jornada :=null;
 Return (vl_Jornada);
 END f_no_materia;

 Function f_fecha_Matriculacion (p_pidm in number ) RETURN varchar2

 Is

 vl_fecha_matricula varchar2(10);

 Begin

 Select b.STVTERM_START_DATE
 Into vl_fecha_matricula
 from sorlcur a, stvterm b
 where a.SORLCUR_LMOD_CODE = 'ADMISSIONS'
 And a.SORLCUR_SEQNO in (select min (a1.SORLCUR_SEQNO)
 from SORLCUR a1
 Where a.sorlcur_pidm = a1.sorlcur_pidm
 and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
 And a.SORLCUR_TERM_CODE_MATRIC = b.STVTERM_CODE
 And a.sorlcur_pidm = p_pidm;

 Return (vl_fecha_matricula);
 Exception
 when Others then
 vl_fecha_matricula :=null;
 Return (vl_fecha_matricula);
 END f_fecha_Matriculacion;

 Function f_periodo_inicial (p_pidm in number ) RETURN varchar2
 Is

 vl_periodo_inicial varchar2(10);

 Begin
 SELECT DISTINCT SFRSTCR_TERM_CODE
 Into vl_periodo_inicial
 FROM ssbsect a , SFRSTCR b
 WHERE a.SSBSECT_TERM_CODE = b.SFRSTCR_TERM_CODE
 AND b.SFRSTCR_CRN = a.SSBSECT_CRN
 And b.SFRSTCR_TERM_CODE = (select min (b1.SFRSTCR_TERM_CODE)
 from SFRSTCR b1
 Where b.SFRSTCR_pidm = b1.SFRSTCR_pidm)
 AND b.SFRSTCR_PIDM = p_pidm;


 Return (vl_periodo_inicial);
 Exception
 when Others then
 vl_periodo_inicial :=null;
 Return (vl_periodo_inicial);
 END f_periodo_inicial;

Function f_Estado_programa (p_pidm in number ) RETURN varchar2

Is

 vl_estatus varchar2(50);

 Begin

 select distinct STVSTST_DESC
 Into vl_estatus
 from sorlcur c , sgbstdn a, spriden b, stvSTST d
 where c.SORLCUR_LMOD_CODE = 'LEARNER'
 And c.SORLCUR_SEQNO in (select max ( c1.SORLCUR_SEQNO)
 from SORLCUR c1
 where c.sorlcur_pidm = c1.sorlcur_pidm
 and c.SORLCUR_LMOD_CODE = c1.SORLCUR_LMOD_CODE
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
 and b.spriden_pidm = p_pidm;


 Return (vl_estatus);
 Exception
 when Others then
 vl_estatus :=null;
 Return (vl_estatus);
 END f_Estado_programa;

 Function f_Descuento (p_pidm in number ) RETURN varchar2
 Is

 vl_descuento varchar2(10);
 Begin

 Select b.TBREDET_PERCENT
 Into vl_descuento
 from TBBESTU a, TBREDET b
 where a.TBBESTU_EXEMPTION_CODE = b.TBREDET_EXEMPTION_CODE
 and a.TBBESTU_TERM_CODE = b.TBREDET_TERM_CODE
 and a.TBBESTU_TERM_CODE in (select max (a1.TBBESTU_TERM_CODE)
 from TBBESTU a1
 Where a.TBBESTU_PIDM = a1.TBBESTU_PIDM)
 and a.TBBESTU_PIDM = p_pidm;

 Return (vl_descuento);
 Exception
 when Others then
 vl_descuento :=null;
 Return (vl_descuento);


 End f_Descuento;

Procedure sp_Consulta_Cartera
---nueva version 01/07/2019--
is


 Begin

 Begin

 delete TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Cartera_Relacion_cargo_cargo';
 Commit;

 FOR cartera in (
 Select distinct t.pidm pidm,
 t.matricula Matricula,
 T.CAMPUS Campus,
 t.nivel Nivel,
 ss.spriden_first_name||' '||ss.spriden_last_name Estudiante,
 t.estatus Estatus_Code ,
 TS.STVSTST_DESC Estatus,
 -- TV.STVSTYP_CODE,
 TV.STVSTYP_DESC tipo,
 t.programa Programa,
 ( select pr.SMRPRLE_PROGRAM_DESC from SMRPRLE pr where pr.SMRPRLE_PROGRAM = t.programa ) Desc_Programa,
 b.TBRACCD_AMOUNT Monto_Origen ,
 b.tbraccd_balance Balance_Origen,
 b.TBRACCD_DETAIL_CODE Codigo_Origen,
 c.TBBDETC_DESC Descripcion_Origen ,
 c.TBBDETC_DCAT_CODE Categoria_origen,
 b.tbraccd_term_code Periodo_origen,
 trunc (b.TBRACCD_EFFECTIVE_DATE) Fecha_Efectiva_origen,
 b.TBRACCD_TRAN_NUMBER Seq_origen,
 -- ppl.cargo,
 iva.TVRTAXD_TAX_AMOUNT IVA
 -- 'NUEVO INGRESO' TIPO,
 , saracmt_comment_text clave_canal
 , ( select geo.STVGEOD_DESC
 from STVGEOD geo
 where lpad (trim (substr (cr.SARACMT_COMMENT_TEXT, 1, 2)), 2, '0') = geo.STVGEOD_CODE ) canal_final
 , ppl.monto Monto_pagado
 , ppl.pago Seq_pagado
 ,ccd.codigo codigo_pagado
 ,ccd.descrip descripcion_pago
 ,(select TBBDETC_DCAT_CODE from tbbdetc where tbbdetc_detail_code = ccd.codigo) as categoria_Pago
 ,trunc (ccd.fecha_pago) fecha_pagado
 ,ccd.fecha_captura fecha_captura
 ,ccd.usuario_id usuario_id
 , 'Cargo' Tipo_Movimiento
 , 'Relacion con Pagos -->' Dependencia
 from tztprog t, tbraccd b,tbbdetc c , TVRTAXD iva,spriden ss , STVSTST ts, STVSTYP tv,SARACMT cr
 , ( select TBRAPPL_PIDM pidm, TBRAPPL_PAY_TRAN_NUMBER Pago, TBRAPPL_CHG_TRAN_NUMBER Cargo, TBRAPPL_AMOUNT Monto, TBRAPPL_ACTIVITY_DATE fecha
 from tbrappl
 where TBRAPPL_REAPPL_IND is null
 ) ppl
 ,(
 select distinct
 TBRACCD_pidm pidm,
 TBRAPPL_CHG_TRAN_NUMBER seq_pago,
 TBRACCD_DETAIL_CODE Codigo,
 TBRACCD_DESC DESCRIP,
 TBRACCD_EFFECTIVE_DATE FECHA_PAGO,
 TBRACCD_ENTRY_DATE fecha_captura,
 TBRACCD_USER usuario_id
 , TBRACCD_TRAN_NUMBER, TBRACCD_TRAN_NUMBER_PAID, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_PAY_TRAN_NUMBER
 from TBRACCD
 left outer join TBRAPPL on TBRACCD_PIDM = TBRAPPL_PIDM and TBRAPPL_REAPPL_IND is null
 and TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
 left join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
 --where TBRACCD_PIDM = 4
 where TBBDETC_TYPE_IND = 'C'
 ) ccd
 where T.PIDM = B.TBRACCD_PIDM
 And b.tbraccd_amount is not null
 And b.tbraccd_detail_code = c.TBBDETC_DETAIL_CODE
 and T.PIDM = SS.SPRIDEN_PIDM(+)
 and SS.SPRIDEN_CHANGE_IND is null
 and T.ESTATUS=STVSTST_CODE
 and T.SGBSTDN_STYP_CODE=STVSTYP_CODE
 And b.TBRACCD_PIDM = iva.TVRTAXD_PIDM (+)
 and B.TBRACCD_TRAN_NUMBER = iva.TVRTAXD_ACCD_TRAN_NUMBER(+)
 and b.TBRACCD_PIDM = Ppl.PIDM(+)
 AND b.TBRACCD_TRAN_NUMBER = Ppl.Cargo(+)
 and b.TBRACCD_PIDM = ccd.pidm
 and B.TBRACCD_TRAN_NUMBER = ccd.seq_pago
 and b.tbraccd_detail_code in (select TBBDETC_DETAIL_CODE
 from tbbdetc
 where TBBDETC_DCAT_CODE in ('AAC', 'ABC', 'ACC', 'ACL', 'AJC',
 'APR', 'ARA', 'ARP', 'CCC',
 'CSD', 'DAL', 'DEV', 'ENV', 'INS', 'INT', 'INU',
 'OTG', 'PYG', 'SEG', 'SER',
 'TAX', 'TUI', 'VTA', 'COL')
 -- where TBBDETC_DCAT_CODE = 'COL'
 And (substr (TBBDETC_DETAIL_CODE, 1, 2 ) = substr (tbraccd_term_code, 1, 2)
 or TBBDETC_DETAIL_CODE = 'PLPA')
 and TBBDETC_DETC_ACTIVE_IND = 'Y'
 )
 and T.PIDM = cr.saracmt_pidm(+)
 and T.MATRICULACION = cr.saracmt_term_code(+)
 and cr.saracmt_orig_code='CANF'
 and cr.SARACMT_TERM_CODE in ( select max(SARACMT_TERM_CODE) from SARACMT sa
 Where sa.SARACMT_PIDM = cr.SARACMT_PIDM
 -- And sa.SARACMT_TERM_CODE = cr.SARACMT_TERM_CODE
 -- And sa.SARACMT_APPL_NO = cr.SARACMT_APPL_NO
 And sa.saracmt_orig_code='CANF')
 and cr.SARACMT_SEQNO in (select max (cmt.SARACMT_SEQNO)
 from SARACMT cmt
 Where cmt.SARACMT_PIDM = cr.SARACMT_PIDM
 And cmt.SARACMT_TERM_CODE = cr.SARACMT_TERM_CODE
 -- And cmt.SARACMT_APPL_NO = cr.SARACMT_APPL_NO
 And cmt.saracmt_orig_code=cr.saracmt_orig_code )
 --and t.pidm = 4
 UNION
 Select distinct t.pidm pidm,
 t.matricula Matricula,
 T.CAMPUS Campus,
 t.nivel Nivel,
 ss.spriden_first_name||' '||ss.spriden_last_name Estudiante,
 t.estatus Estatus_Code ,
 TS.STVSTST_DESC Estatus,
 -- TV.STVSTYP_CODE,
 TV.STVSTYP_DESC tipo,
 t.programa Programa,
 ( select pr.SMRPRLE_PROGRAM_DESC from SMRPRLE pr where pr.SMRPRLE_PROGRAM = t.programa ) Desc_Programa,
 b.TBRACCD_AMOUNT Monto_Origen ,
 b.tbraccd_balance Balance_Origen,
 b.TBRACCD_DETAIL_CODE Codigo_Origen,
 c.TBBDETC_DESC Descripcion_Origen ,
 c.TBBDETC_DCAT_CODE Categoria_origen,
 b.tbraccd_term_code Periodo_origen,
 trunc (b.TBRACCD_EFFECTIVE_DATE) Fecha_Efectiva_origen,
 b.TBRACCD_TRAN_NUMBER Seq_origen,
 --ppl.cargo,
 iva.TVRTAXD_TAX_AMOUNT IVA
 -- 'NUEVO INGRESO' TIPO,
 , saracmt_comment_text clave_canal
 , ( select geo.STVGEOD_DESC
 from STVGEOD geo
 where lpad (trim (substr (cr.SARACMT_COMMENT_TEXT, 1, 2)), 2, '0') = geo.STVGEOD_CODE ) canal_final
 , ppl.monto Monto_pagado
 , ppl.pago Seq_pagado
 ,ccd.codigo codigo_pagado
 ,ccd.descrip descripcion_pago
 ,(select TBBDETC_DCAT_CODE from tbbdetc where tbbdetc_detail_code = ccd.codigo) as categoria_Pago
 ,trunc (ccd.fecha_pago) fecha_pagado
 ,ccd.fecha_captura fecha_captura
 ,ccd.usuario_id usuario_id
 , 'Pago' Tipo_Movimiento
 , 'Relacion con Pagos -->' Dependencia
 from tztprog t, tbraccd b,tbbdetc c , TVRTAXD iva,spriden ss , STVSTST ts, STVSTYP tv,SARACMT cr
 , ( select TBRAPPL_PIDM pidm, TBRAPPL_PAY_TRAN_NUMBER Pago, TBRAPPL_CHG_TRAN_NUMBER Cargo, TBRAPPL_AMOUNT Monto, TBRAPPL_ACTIVITY_DATE fecha
 from tbrappl
 where TBRAPPL_REAPPL_IND is null
 ) ppl
 ,(
 select distinct
 TBRACCD_pidm pidm,
 TBRAPPL_CHG_TRAN_NUMBER seq_pago,
 TBRACCD_DETAIL_CODE Codigo,
 TBRACCD_DESC DESCRIP,
 TBRACCD_EFFECTIVE_DATE FECHA_PAGO,
 TBRACCD_ENTRY_DATE fecha_captura,
 TBRACCD_USER usuario_id
 , TBRACCD_TRAN_NUMBER, TBRACCD_TRAN_NUMBER_PAID, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_PAY_TRAN_NUMBER
 from TBRACCD
 left outer join TBRAPPL on TBRACCD_PIDM = TBRAPPL_PIDM and TBRAPPL_REAPPL_IND is null
 and TBRACCD_TRAN_NUMBER = TBRAPPL_PAY_TRAN_NUMBER
 left join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
 --where TBRACCD_PIDM = 4
 where TBBDETC_TYPE_IND = 'P'

 ) ccd
 where T.PIDM = B.TBRACCD_PIDM
 And b.tbraccd_amount is not null
 And b.tbraccd_detail_code = c.TBBDETC_DETAIL_CODE
 and T.PIDM = SS.SPRIDEN_PIDM(+)
 and SS.SPRIDEN_CHANGE_IND is null
 and T.ESTATUS=STVSTST_CODE
 and T.SGBSTDN_STYP_CODE=STVSTYP_CODE
 And b.TBRACCD_PIDM = iva.TVRTAXD_PIDM (+)
 and B.TBRACCD_TRAN_NUMBER = iva.TVRTAXD_ACCD_TRAN_NUMBER(+)
 and b.TBRACCD_PIDM = Ppl.PIDM(+)
 AND b.TBRACCD_TRAN_NUMBER = Ppl.Cargo(+)
 and b.TBRACCD_PIDM = ccd.pidm
 and B.TBRACCD_TRAN_NUMBER = ccd.seq_pago
 and b.tbraccd_detail_code in (select TBBDETC_DETAIL_CODE
 from tbbdetc
 where TBBDETC_DCAT_CODE in ('AAC', 'ABC', 'ACC', 'ACL', 'AJC',
 'APR', 'ARA', 'ARP', 'CCC',
 'CSD', 'DAL', 'DEV', 'ENV', 'INS', 'INT', 'INU',
 'OTG', 'PYG', 'SEG', 'SER',
 'TAX', 'TUI', 'VTA', 'COL')
 -- where TBBDETC_DCAT_CODE = 'COL'
 And (substr (TBBDETC_DETAIL_CODE, 1, 2 ) = substr (tbraccd_term_code, 1, 2)
 or TBBDETC_DETAIL_CODE = 'PLPA')
 and TBBDETC_DETC_ACTIVE_IND = 'Y'
 )
 and T.PIDM = cr.saracmt_pidm(+)
 and T.MATRICULACION = cr.saracmt_term_code(+)
 and cr.saracmt_orig_code='CANF'
 and cr.SARACMT_TERM_CODE in ( select max(SARACMT_TERM_CODE) from SARACMT sa
 Where sa.SARACMT_PIDM = cr.SARACMT_PIDM
 -- And sa.SARACMT_TERM_CODE = cr.SARACMT_TERM_CODE
 -- And sa.SARACMT_APPL_NO = cr.SARACMT_APPL_NO
 And sa.saracmt_orig_code='CANF')
 and cr.SARACMT_SEQNO in (select max (cmt.SARACMT_SEQNO)
 from SARACMT cmt
 Where cmt.SARACMT_PIDM = cr.SARACMT_PIDM
 And cmt.SARACMT_TERM_CODE = cr.SARACMT_TERM_CODE
 -- And cmt.SARACMT_APPL_NO = cr.SARACMT_APPL_NO
 And cmt.saracmt_orig_code=cr.saracmt_orig_code )
 --and t.pidm = 4
 )loop
 Insert into TZTCRTE values (cartera.pidm,
 cartera.matricula,
 cartera.campus,
 cartera.nivel,
 cartera.estatus_code,
 cartera.estatus,
 cartera.programa,
 cartera.desc_programa,
 cartera.tipo,
 cartera.clave_canal,
 cartera.canal_final,
 cartera.Tipo_Movimiento,
 cartera.Monto_origen,
 cartera.Balance_origen,
 cartera.codigo_origen,
 cartera.Descripcion_Origen,
 cartera.Categoria_origen,
 cartera.Periodo_origen,
 cartera.Fecha_Efectiva_origen,
 cartera.Seq_origen,
 cartera.IVa,
 cartera.Dependencia,
 cartera.Monto_pagado,
 cartera.Seq_pagado,
 cartera.codigo_pagado,
 cartera.descripcion_pago,
 cartera.categoria_Pago,
 cartera.fecha_pagado,
 null, --cartera.vacio,
 cartera.fecha_captura,
 cartera.usuario_id,
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
 'Cartera_Relacion_cargo_cargo'
 );

 End Loop;
 commit;
 End;

 END;

Procedure sp_pagos_facturacion is

Begin

 Begin
 delete TZTCRTE
 where TZTCRTE_TIPO_REPORTE in ( 'Pago_Facturacion', 'Facturacion');
 Commit;
 Exception
 When others then
 null;
 End;

 Begin
 For c in (

 with colegiatura as (
 Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbraccd_desc desc_cargo, TBBDETC_DCAT_CODE Categ_Col
 from tbraccd a, tbbdetc b
 where a.tbraccd_detail_code = tbbdetc_detail_code
 ),
 curp as (select GORADID_PIDM PIDM,
 GORADID_ADDITIONAL_ID CURP
 from GORADID
 where GORADID_ADID_CODE = 'CURP')
 select DISTINCT
 tbraccd_pidm pidm ,
 spriden_id as Matricula,
 s.SPREMRG_LAST_NAME as Nombre,
 saradap_camp_code as Campus,
 SARADAP_LEVL_CODE as Nivel,
 s.SPREMRG_MI as RFC,
 s.SPREMRG_STREET_LINE1 || ' ' ||s.SPREMRG_STREET_LINE2 || ' ' ||s.SPREMRG_STREET_LINE3 as Dom_Fiscal,
 s.SPREMRG_CITY as Ciudad,
 s.SPREMRG_ZIP as CP,
 s.SPREMRG_NATN_CODE as Pais,
 tbraccd_detail_code as Tipo_Deposito,
 tbraccd_desc as Descripcion,
 tbraccd_amount as Monto,
 TBRACCD_TRAN_NUMBER as Transaccion,
 trunc ( TBRACCD_TRANS_DATE) as Fecha_Pago,
 GORADID_ADDITIONAL_ID as REFERENCIA,
 GORADID_ADID_CODE as Referencia_Tipo,
 GOREMAL_EMAIL_ADDRESS as EMAIL,
 nvl (TBRAPPL_AMOUNT,tbraccd_amount) as Monto_pagado,
 nvl (TBRAPPL_CHG_TRAN_NUMBER,TBRACCD_TRAN_NUMBER) as secuencia_pago,
 colegiatura.desc_cargo descripcion_pago,
 colegiatura.Categ_Col,
 max (s.SPREMRG_PRIORITY) Prioridad,
 curp.CURP,
 SARADAP_DEGC_CODE_1 Grado,
 s.SPREMRG_LAST_NAME Razon_social,
 SPRIDEN_LAST_NAME||' '||SPRIDEN_FIRST_NAME Nombre_alumno,
 SARADAP_PROGRAM_1 Programa,
 SZTDTEC_NUM_RVOE RVOE_num,
 SZTDTEC_CLVE_RVOE RVOE_clave
 from SPREMRG s
 left join SPRIDEN on s.SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
 left join TBRACCD on s.SPREMRG_PIDM = TBRACCD_PIDM
 left join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
 join SARADAP on s.SPREMRG_PIDM = SARADAP_PIDM
 join SZTDTEC on saradap_camp_code = SZTDTEC_CAMP_CODE
 and SARADAP_PROGRAM_1 = SZTDTEC_PROGRAM
 and SARADAP_TERM_CODE_CTLG_1 = SZTDTEC_TERM_CODE
 left join GORADID on s.SPREMRG_PIDM = GORADID_PIDM and GORADID_ADID_CODE in ('REFH','REFS')
 left join GOREMAL on s.SPREMRG_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
 left outer join tbrappl on spriden_pidm = tbrappl_pidm and TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
 left outer join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
 left outer join curp on SPRIDEN_PIDM = curp.PIDM
 where
 s.SPREMRG_MI is not NULL
 -- And SPREMRG_pidm = 40684
 and TBBDETC_TYPE_IND = 'P'
 and TBBDETC_DCAT_CODE = 'CSH'
 and to_number (s.SPREMRG_PRIORITY) in (select max(to_number (s1.SPREMRG_PRIORITY))
 FROM SPREMRG s1
 where s.SPREMRG_PIDM = s1.SPREMRG_PIDM
 --and SPREMRG_PRIORITY = s1.SPREMRG_PRIORITY
 )
 and SARADAP_APST_CODE = 'A'
 GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, saradap_camp_code, SARADAP_LEVL_CODE, SPREMRG_MI,
 SPREMRG_STREET_LINE1 || ' ' ||SPREMRG_STREET_LINE2 || ' ' || SPREMRG_STREET_LINE3, SPREMRG_CITY, SPREMRG_ZIP, SPREMRG_NATN_CODE,
 tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, trunc ( TBRACCD_TRANS_DATE), GORADID_ADDITIONAL_ID,
 GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
 curp.CURP, SARADAP_DEGC_CODE_1, SPRIDEN_LAST_NAME, SPRIDEN_FIRST_NAME, SARADAP_PROGRAM_1, SZTDTEC_NUM_RVOE, SZTDTEC_CLVE_RVOE
 ) loop

 Insert into TZTCRTE values (c.pidm,
 c.matricula,
 c.campus,
 c.nivel,
 c.nombre,
 c.rfc,
 c.dom_fiscal,
 c.ciudad,
 c.cp,
 c.pais,
 c.tipo_deposito,
 c.descripcion,
 c.monto,
 c.transaccion,
 c.fecha_pago,
 c.referencia,
 c.referencia_tipo,
 c.email,
 c.monto_pagado,
 c.secuencia_pago,
 c.descripcion_pago,
 c.Categ_Col,
 c.Prioridad,
 c.CURP,
 c.Grado,
 c.Razon_social,
 c.Nombre_alumno,
 c.Programa,
 c.RVOE_num,
 c.RVOE_clave,
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
 'Pago_Facturacion'
 );




 End Loop;
 Commit;

 For c in (
 with intereses as (
 select distinct
 TZTCRTE_PIDM Pidm,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO17 as Intereses,
 sum (TZTCRTE_CAMPO15) as Monto_intereses,
 TZTCRTE_CAMPO18 as Categoria,
 TZTCRTE_CAMPO10 as Secuencia
 from TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
 and TZTCRTE_CAMPO18 = 'INT'
 group by
 TZTCRTE_PIDM,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO17,
 TZTCRTE_CAMPO18,
 TZTCRTE_CAMPO10
 ),
 accesorios as (
 select distinct
 TZTCRTE_PIDM Pidm,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO17 as accesorios,
 sum (TZTCRTE_CAMPO15) as Monto_accesorios,
 TZTCRTE_CAMPO18 as Categoria,
 TZTCRTE_CAMPO10 as Secuencia
 from TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
 and TZTCRTE_CAMPO18 in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
 group by
 TZTCRTE_PIDM,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO17,
 TZTCRTE_CAMPO18,
 TZTCRTE_CAMPO10
 ),
 colegiatura as (
 select distinct
 TZTCRTE_PIDM Pidm,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO17 as colegiatura,
 sum (TZTCRTE_CAMPO15) as Monto_colegiatura,
 TZTCRTE_CAMPO18 as Categoria,
 TZTCRTE_CAMPO10 as Secuencia
 from TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
 and TZTCRTE_CAMPO18 in ('COL')
 group by
 TZTCRTE_PIDM,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO17,
 TZTCRTE_CAMPO18,
 TZTCRTE_CAMPO10
 ),
 otros as (
 select distinct
 TZTCRTE_PIDM Pidm,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO17 as otros,
 sum (TZTCRTE_CAMPO15) as Monto_otros,
 TZTCRTE_CAMPO18 as Categoria,
 TZTCRTE_CAMPO10 as Secuencia
 from TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
 and TZTCRTE_CAMPO18 not in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL', 'VTA', 'TUI')
 group by
 TZTCRTE_PIDM,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO17,
 TZTCRTE_CAMPO18,
 TZTCRTE_CAMPO10
 )
 select distinct
 TZTCRTE_pidm as pidm,
 TZTCRTE_CAMPO1 as Nombre,
 TZTCRTE_CAMPO2 as RFC,
 TZTCRTE_CAMPO3 as Dom_Fiscal,
 TZTCRTE_CAMPO4 as Ciudad,
 TZTCRTE_CAMPO5 as CP,
 TZTCRTE_CAMPO6 as Pais,
 TZTCRTE_CAMPO7 as Tipo_Deposito,
 TZTCRTE_CAMPO8 as Descripcion,
 TZTCRTE_CAMPO9 as Monto,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_ID as Matricula,
 TZTCRTE_CAMPO10 as Transaccion,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO12 as REFERENCIA,
 TZTCRTE_CAMPO13 as Referencia_Tipo,
 TZTCRTE_CAMPO14 as EMAIL,
 e.Colegiatura,
 e.Monto_colegiatura,
 b.intereses,
 b.Monto_intereses,
 c.accesorios,
 c.Monto_accesorios,
 d.otros,
 d.monto_otros,
 TZTCRTE_CAMPO20 as Curp,
 TZTCRTE_CAMPO21 as Grado,
 TZTCRTE_CAMPO22 as Razon_social,
 TZTCRTE_CAMPO23 as Nombre_alumno,
 TZTCRTE_CAMPO24 as Programa,
 TZTCRTE_CAMPO25 as RVOE_num,
 TZTCRTE_CAMPO26 as RVOE_clave
 from TZTCRTE, intereses b, accesorios c, otros d, colegiatura e
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion'
 --and TZTCRTE_CAMP = :MC_CAMPUS
 --and TZTCRTE_LEVL = :MC_NIVEL
 --and to_date(TZTCRTE_CAMPO11,'dd/mm/rrrr') BETWEEN to_date(:Fecha_Inicio, 'dd/mm/rrrr') and to_date(:Fecha_Fin, 'dd/mm/rrrr')
 --And TZTCRTE_ID = '010041922'
 and TZTCRTE_CAMPO18 in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL')
 --and TZTCRTE_CAMPO18 = 'COL' (+)
 and TZTCRTE_PIDM = e.pidm (+)
 and TZTCRTE_LEVL = e.nivel (+)
 and TZTCRTE_CAMP = e.campus (+)
 and TZTCRTE_CAMPO11 = e.Fecha_Pago (+)
 And TZTCRTE_CAMPO10 = e.secuencia (+)
 and TZTCRTE_PIDM = b.pidm (+)
 and TZTCRTE_LEVL = b.nivel (+)
 and TZTCRTE_CAMP = b.campus (+)
 and TZTCRTE_CAMPO11 = b.Fecha_Pago (+)
 And TZTCRTE_CAMPO10 = b.secuencia (+)
 and TZTCRTE_PIDM = c.pidm (+)
 and TZTCRTE_LEVL = c.nivel (+)
 and TZTCRTE_CAMP = c.campus (+)
 and TZTCRTE_CAMPO11 = c.Fecha_Pago (+)
 And TZTCRTE_CAMPO10 = c.secuencia (+)
 and TZTCRTE_PIDM = d.pidm (+)
 and TZTCRTE_LEVL = d.nivel (+)
 and TZTCRTE_CAMP = d.campus (+)
 and TZTCRTE_CAMPO11 = d.Fecha_Pago (+)
 And TZTCRTE_CAMPO10 = d.secuencia (+)
 --and TZTCRTE_PIDM = 16589
 group by TZTCRTE_pidm,
 TZTCRTE_CAMPO1,
 TZTCRTE_CAMPO2,
 TZTCRTE_CAMPO3,
 TZTCRTE_CAMPO4,
 TZTCRTE_CAMPO5,
 TZTCRTE_CAMPO6,
 TZTCRTE_CAMPO7,
 TZTCRTE_CAMPO8,
 TZTCRTE_CAMPO9,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_ID,
 TZTCRTE_CAMPO10,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO12,
 TZTCRTE_CAMPO13,
 TZTCRTE_CAMPO14,
 e.Colegiatura,
 e.Monto_colegiatura,
 b.intereses,
 b.Monto_intereses,
 c.accesorios,
 c.Monto_accesorios,
 d.otros,
 d.monto_otros,
 TZTCRTE_CAMPO20,
 TZTCRTE_CAMPO21,
 TZTCRTE_CAMPO22,
 TZTCRTE_CAMPO23,
 TZTCRTE_CAMPO24,
 TZTCRTE_CAMPO25,
 TZTCRTE_CAMPO26
 order by TZTCRTE_ID, TZTCRTE_CAMPO11, TZTCRTE_CAMPO10 ) loop

 Insert into TZTCRTE values (c.pidm,
 c.matricula,--
 c.campus,--
 c.nivel,--
 c.nombre,--
 c.rfc,--
 c.dom_fiscal,--
 c.ciudad, --
 c.cp, --
 c.pais,--
 c.tipo_deposito,--
 c.descripcion,--
 c.monto,--
 c.transaccion,--
 c.fecha_pago,--
 c.referencia,--
 c.referencia_tipo,--
 c.email,--
 c.colegiatura,
 c.monto_colegiatura,
 c.intereses,
 c.monto_intereses,
 c.accesorios,
 c.monto_accesorios,
 c.otros,
 c.monto_otros,
 c.CURP,
 c.Grado,
 c.Razon_social,
 c.Nombre_alumno,
 c.Programa,
 c.RVOE_num,
 c.RVOE_clave,
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
 'Facturacion'
 );

 End loop;


 End;

End sp_pagos_facturacion;

--PROCEDURE sp_detallealumnos
--
--is
--
-- Begin
--
-- delete SZTHIST;
-- commit;
--
-- For alumno in (
-- select distinct b.spriden_id ID, a.SORLCUR_PIDM pidm, a.SORLCUR_LMOD_CODE lmod_code, a.SORLCUR_KEY_SEQNO seqno, a.sorlcur_program programa,
-- a.sorlcur_levl_code nivel, a.sorlcur_camp_code campus, SORLCUR_TERM_CODE_ADMIT Periodo_Matric, a.SORLCUR_ROLL_IND roll_ind, a.SORLCUR_CACT_CODE cact_code,
-- a.SORLCUR_TERM_CODE_CTLG term_code_ctlg,
-- (select pkg_datos_academicos.avance1(b.spriden_pidm, a.sorlcur_program) from dual) avance,
-- (select pkg_datos_academicos.promedio1(b.spriden_pidm, a.sorlcur_program) from dual) promedio,
-- 0 avance_1,
-- 0 promedio_1,
-- (select pkg_datos_academicos.total_mate(a.sorlcur_program, b.spriden_pidm) from dual) total_materia,
-- trunc (a.SORLCUR_ACTIVITY_DATE) FECHA_MOV
-- from sorlcur a, spriden b
-- where a.SORLCUR_LMOD_CODE = 'LEARNER'
-- and a.SORLCUR_SEQNO = (select min (a1.SORLCUR_SEQNO)
-- from SORLCUR a1
-- Where a.sorlcur_pidm = a1.sorlcur_pidm
-- And a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
-- And a.sorlcur_program = a1.sorlcur_program)
-- and a.sorlcur_pidm = b.spriden_pidm
-- and b.SPRIDEN_CHANGE_IND is null
--
-- ) loop
--
--
-- For materia in (
-- select COUNT (*)numero , SSBSECT_TERM_CODE periodo, SSBSECT_PTRM_CODE pperiodo, SSBSECT_PTRM_START_DATE fecha_inicio, SFRSTCR_pidm pidm
-- from SFRSTCR, SSBSECT
-- where SFRSTCR_pidm = alumno.pidm
-- and SFRSTCR_STSP_KEY_SEQUENCE = alumno.seqno
-- And SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
-- And SFRSTCR_CRN = SSBSECT_CRN
-- group by SSBSECT_TERM_CODE, SSBSECT_PTRM_CODE, SSBSECT_PTRM_START_DATE, SFRSTCR_pidm
-- order by 2, 3
--
-- ) loop
--
-- Begin
-- Insert into SZTHIST values ( alumno.pidm,
-- alumno.id,
-- alumno.campus,
-- alumno.nivel,
-- null,
-- null,
-- alumno.programa,
-- materia.periodo,
-- null,
-- null,
-- materia.pperiodo,
-- materia.fecha_inicio,
-- nvl (alumno.Periodo_Matric, materia.periodo),
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- alumno.seqno,
-- null,
-- alumno.avance,
-- alumno.promedio,
-- alumno.fecha_mov,
-- NULL,
-- alumno.total_materia,
-- alumno.term_code_ctlg,
-- null,
-- null,
-- null,
-- null
-- );
-- Commit;
-- Exception
-- When Others then
-- null;
-- End;
-- End loop materia;
--
--
-- For materia_st in (
-- select distinct COUNT (*)numero , SSBSECT_TERM_CODE periodo, SSBSECT_PTRM_CODE pperiodo, SSBSECT_PTRM_START_DATE fecha_inicio,
-- case when SFRSTCR_RSTS_CODE = 'RE' then
-- 'Inscritas'
-- end as Altas,
-- case when SFRSTCR_RSTS_CODE != 'RE' then
-- 'Bajas'
-- end as baja
-- from SFRSTCR, SSBSECT
-- where SFRSTCR_pidm = alumno.pidm
-- and SFRSTCR_STSP_KEY_SEQUENCE = alumno.seqno
-- And SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
-- And SFRSTCR_CRN = SSBSECT_CRN
-- group by SSBSECT_TERM_CODE, SSBSECT_PTRM_CODE, SSBSECT_PTRM_START_DATE,SFRSTCR_RSTS_CODE
-- order by 2,4 )
-- loop
-- If materia_st.Altas is not null then
-- Begin
-- Update SZTHIST
-- set SZTHIST_MATERIAS_AC = materia_st.numero,
-- SZTHIST_STST_CODE = 'MA'
-- where SZTHIST_PIDM = alumno.pidm
-- And SZTHIST_PROGRAM = alumno.programa
-- And SZTHIST_TERM_CODE = materia_st.periodo
-- And SZTHIST_PTRM_CODE = materia_st.pperiodo;
-- End;
--
-- Elsif materia_st.baja is not null then
-- Begin
-- Update SZTHIST
-- set SZTHIST_MATERIAS_bj = materia_st.numero
-- where SZTHIST_PIDM = alumno.pidm
-- And SZTHIST_PROGRAM = alumno.programa
-- And SZTHIST_TERM_CODE = materia_st.periodo
-- And SZTHIST_PTRM_CODE = materia_st.pperiodo;
-- End;
-- End if;
--
-- End Loop materia_st;
--
-- Begin
-- update SZTHIST a
-- set a.SZTHIST_STYP_CODE = 'N'
-- where a.SZTHIST_PIDM = alumno.pidm
-- And a.SZTHIST_CAMP_CODE = alumno.campus
-- And a.SZTHIST_LEVL_CODE = alumno.nivel
-- And a.SZTHIST_PROGRAM = alumno.programa
-- and a.SZTHIST_TERM_CODE = (select min (a1.SZTHIST_TERM_CODE)
-- from SZTHIST a1
-- where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
-- And a.SZTHIST_CAMP_CODE = a1.SZTHIST_CAMP_CODE
-- And a.SZTHIST_LEVL_CODE = a1.SZTHIST_LEVL_CODE
-- And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
-- Commit;
-- Exception
-- When Others then
-- null;
-- End;
--
--
-- Begin
-- update SZTHIST a
-- set a.SZTHIST_STYP_CODE = 'C'
-- where a.SZTHIST_PIDM = alumno.pidm
-- And a.SZTHIST_CAMP_CODE = alumno.campus
-- And a.SZTHIST_LEVL_CODE = alumno.nivel
-- And a.SZTHIST_PROGRAM = alumno.programa
-- And SZTHIST_STYP_CODE is null;
--
-- Commit;
-- Exception
-- When Others then
-- null;
-- End;
--
--
-- for bajas in ( select distinct a.SZTHIST_TERM_CODE, sum (a.SZTHIST_MATERIAS_BJ) baja
-- from SZTHIST a
-- where a.SZTHIST_PIDM = alumno.pidm
-- And a.SZTHIST_CAMP_CODE = alumno.campus
-- And a.SZTHIST_LEVL_CODE = alumno.nivel
-- And a.SZTHIST_PROGRAM = alumno.programa
-- And a.SZTHIST_STST_CODE is null
-- group by a.SZTHIST_TERM_CODE
-- order by 1 asc )
-- loop
--
--
-- If bajas.baja >= 1 then
-- null;
--
-- Begin
-- update SZTHIST a
-- set a.SZTHIST_STST_CODE = 'BI'
-- where a.SZTHIST_PIDM = alumno.pidm
-- And a.SZTHIST_CAMP_CODE = alumno.campus
-- And a.SZTHIST_LEVL_CODE = alumno.nivel
-- And a.SZTHIST_PROGRAM = alumno.programa
-- And a.SZTHIST_STST_CODE is null;
-- Commit;
-- Exception
-- When Others then
-- null;
-- End;
--
-- End if;
-- Commit;
-- End loop bajas;
--
--
-- for alta in (
--
-- select distinct SZTHIST_TERM_CODE, sum (SZTHIST_MATERIAS_AC) altas
-- from SZTHIST a
-- where a.SZTHIST_PIDM = alumno.pidm
-- And a.SZTHIST_CAMP_CODE = alumno.campus
-- And a.SZTHIST_LEVL_CODE = alumno.nivel
-- And a.SZTHIST_PROGRAM = alumno.programa
-- And a.SZTHIST_STST_CODE is null
-- group by SZTHIST_TERM_CODE
-- order by 1 asc
--
-- ) loop
--
-- If alta.altas >= 1 then
--
-- Begin
-- update SZTHIST a
-- set a.SZTHIST_STST_CODE = 'MA'
-- where a.SZTHIST_PIDM = alumno.pidm
-- And a.SZTHIST_CAMP_CODE = alumno.campus
-- And a.SZTHIST_LEVL_CODE = alumno.nivel
-- And a.SZTHIST_PROGRAM = alumno.programa
-- And a.SZTHIST_STST_CODE is null;
-- Commit;
-- Exception
-- When Others then
-- null;
-- End;
--
-- End if;
-- Commit;
-- End loop alta;
--
--
-- -------------------- Registra el Canal de Venta ----------------------
-- For canal in (Select distinct SARACMT_COMMENT_TEXT canal
-- from saracmt
-- where SARACMT_PIDM = alumno.pidm
-- And SARACMT_APPL_NO = alumno.seqno
-- And SARACMT_ORIG_CODE = 'CANF' )
-- Loop
--
-- Update SZTHIST
-- set SZTHIST_CANAL = canal.canal
-- Where SZTHIST_PIDM = alumno.pidm
-- And SZTHIST_KEY_SEQNO = alumno.seqno;
-- End Loop canal;
--
-- -------------------- Registra el vendedor ----------------------
-- For vendedor in (Select distinct SARACMT_COMMENT_TEXT vendedor
-- from saracmt
-- where SARACMT_PIDM = alumno.pidm
-- And SARACMT_APPL_NO = alumno.seqno
-- And SARACMT_ORIG_CODE = 'VENF' )
-- Loop
--
-- Update SZTHIST
-- set SZTHIST_VENDEDOR = vendedor.vendedor
-- Where SZTHIST_PIDM = alumno.pidm
-- And SZTHIST_KEY_SEQNO = alumno.seqno;
-- End Loop vendedor;
--
--
--
--
--
-- End loop alumno;
--
-- Commit;
--
--
--
-- For alumno_no in (
--
-- select distinct b.spriden_id ID, a.SORLCUR_PIDM pidm, a.SORLCUR_LMOD_CODE , a.SORLCUR_KEY_SEQNO study, a.sorlcur_program programa,
-- a.sorlcur_levl_code nivel, a.sorlcur_camp_code campus , SORLCUR_START_DATE fecha_inicio, SORLCUR_TERM_CODE_MATRIC Periodo_Matric,
-- a.SORLCUR_TERM_CODE_CTLG,
-- (select pkg_datos_academicos.avance1(b.spriden_pidm, a.sorlcur_program) from dual) avance,
-- (select pkg_datos_academicos.promedio1(b.spriden_pidm, a.sorlcur_program) from dual) promedio,
-- null avance_1,
-- null promedio_1,
-- (select pkg_datos_academicos.total_mate(a.sorlcur_program, b.spriden_pidm) from dual) total_materia,
-- trunc (a.SORLCUR_ACTIVITY_DATE) FECHA_MOV
-- from sorlcur a, spriden b
-- where a.SORLCUR_LMOD_CODE = 'LEARNER'
-- and a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
-- from SORLCUR a1
-- Where a.sorlcur_pidm = a1.sorlcur_pidm
-- And a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE
-- And a.sorlcur_program = a1.sorlcur_program)
-- and a.sorlcur_pidm = b.spriden_pidm
-- and b.SPRIDEN_CHANGE_IND is null
-- And a.SORLCUR_PIDM not in (select SZTHIST_pidm
-- from SZTHIST
-- Where SZTHIST_CAMP_CODE = a.sorlcur_camp_code
-- And SZTHIST_LEVL_CODE = a.sorlcur_levl_code
-- And SZTHIST_PROGRAM = a.sorlcur_program
-- )
-- order by 1
--
-- ) loop
--
--
-- For estatus in (
--
-- select a.SGBSTDN_PIDM Pidm , b.spriden_id Id, a.SGBSTDN_CAMP_CODE campus, a.SGBSTDN_LEVL_CODE nivel, SGBSTDN_STST_CODE Estatus,
-- a.SGBSTDN_STYP_CODE Tipo, a.SGBSTDN_PROGRAM_1 Programa,
-- a.SGBSTDN_TERM_CODE_EFF Periodo, a.SGBSTDN_TERM_CODE_ADMIT, a.sgbstdn_rate_code rate
-- from sgbstdn a, spriden b
-- where a.SGBSTDN_PIDM = b.spriden_pidm
-- And SPRIDEN_CHANGE_IND is null
-- And a.SGBSTDN_PIDM = alumno_no.pidm
-- And a.SGBSTDN_CAMP_CODE = alumno_no.campus
-- And a.SGBSTDN_LEVL_CODE = alumno_no.nivel
-- and a.SGBSTDN_PROGRAM_1 = alumno_no.programa
-- And a.SGBSTDN_TERM_CODE_EFF =(select max(a1.SGBSTDN_TERM_CODE_EFF)
-- from SGBSTDN a1
-- where a.SGBSTDN_PIDM = a1.SGBSTDN_PIDM
-- And a.SGBSTDN_CAMP_CODE = a1.SGBSTDN_CAMP_CODE
-- And a.SGBSTDN_LEVL_CODE = a1.SGBSTDN_LEVL_CODE
-- and a.SGBSTDN_PROGRAM_1 = a1.SGBSTDN_PROGRAM_1)
--
-- ) Loop
--
--
-- Begin
-- Insert into SZTHIST values ( estatus.pidm,
-- estatus.id,
-- estatus.campus,
-- estatus.nivel,
-- estatus.estatus,
-- estatus.tipo,
-- estatus.programa,
-- estatus.periodo,
-- null,
-- null,
-- null,
-- alumno_no.fecha_inicio,
-- nvl (alumno_no.Periodo_Matric, estatus.periodo),
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- estatus.rate,
-- null,
-- alumno_no.study,
-- null,
-- alumno_no.avance,
-- alumno_no.promedio,
-- alumno_no.FECHA_MOV,
-- NULL,
-- alumno_no.total_materia,
-- alumno_no.SORLCUR_TERM_CODE_CTLG,
-- null,
-- null,
-- null,
-- null
-- );
-- Commit;
-- Exception
-- When Others then
-- null;
-- End;
-- End loop estatus;
--
-- For canal in (Select distinct SARACMT_COMMENT_TEXT canal
-- from saracmt
-- where SARACMT_PIDM = alumno_no.pidm
-- And SARACMT_APPL_NO = alumno_no.study
-- And SARACMT_ORIG_CODE = 'CANF' )
-- Loop
--
-- Update SZTHIST
-- set SZTHIST_CANAL = canal.canal
-- Where SZTHIST_PIDM = alumno_no.pidm
-- And SZTHIST_KEY_SEQNO = alumno_no.study;
-- End Loop canal;
--
-- -------------------- Registra el vendedor ----------------------
-- For vendedor in (Select distinct SARACMT_COMMENT_TEXT vendedor
-- from saracmt
-- where SARACMT_PIDM = alumno_no.pidm
-- And SARACMT_APPL_NO = alumno_no.study
-- And SARACMT_ORIG_CODE = 'VENF' )
-- Loop
--
-- Update SZTHIST
-- set SZTHIST_VENDEDOR = vendedor.vendedor
-- Where SZTHIST_PIDM = alumno_no.pidm
-- And SZTHIST_KEY_SEQNO = alumno_no.study;
-- End Loop vendedor;
--
--
--
-- Commit;
-- End loop alumno_no;
--
--
-- for estatus_final in (
--
-- select distinct a.SZTHIST_PIDM PIDM , b.SORLCUR_CACT_CODE ESTATUS, a.SZTHIST_PROGRAM PROGRAMA, SZTHIST_STST_CODE ESTATUS_ANT, trunc (SORLCUR_ACTIVITY_DATE) fecha_act, c.SGBSTDN_STST_CODE
-- from SZTHIST a, sorlcur b, sgbstdn c
-- where a.SZTHIST_PIDM = sorlcur_pidm
-- and b.SORLCUR_LMOD_CODE = 'LEARNER'
-- And a.SZTHIST_PROGRAM = b.sorlcur_program
-- and b.SORLCUR_SEQNO = (select max (b1.SORLCUR_SEQNO)
-- from SORLCUR b1
-- Where b.sorlcur_pidm = b1.sorlcur_pidm
-- And b.SORLCUR_LMOD_CODE = b1.SORLCUR_LMOD_CODE
-- And b.sorlcur_program = b1.sorlcur_program)
-- and b.sorlcur_pidm = c.sgbstdn_pidm
-- And b.sorlcur_program = c.sgbstdn_program_1
-- and c.sgbstdn_term_code_eff in (select max (c1.sgbstdn_term_code_eff)
-- from sgbstdn c1
-- where c.sgbstdn_pidm = c1.sgbstdn_pidm
-- And c.sgbstdn_program_1 = c1.sgbstdn_program_1)
--
-- ) loop
--
-- If estatus_final.ESTATUS = 'INACTIVE' And estatus_final.SGBSTDN_STST_CODE IN ('AS', 'PR', 'MA') Then
-- Update SZTHIST a
-- set SZTHIST_STST_CODE = estatus_final.SGBSTDN_STST_CODE,
-- SZTHIST_MOVIMIENTO = estatus_final.fecha_act
-- where a.SZTHIST_PIDM = estatus_final.PIDM
-- And SZTHIST_PROGRAM = estatus_final.programa
-- And SZTHIST_TERM_CODE = (select max (a1.SZTHIST_TERM_CODE)
-- from SZTHIST a1
-- where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
-- And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
-- ElsIf estatus_final.ESTATUS = 'INACTIVE' And estatus_final.SGBSTDN_STST_CODE not IN ('AS', 'PR', 'MA', 'EG') Then
-- Update SZTHIST a
-- set SZTHIST_STST_CODE = estatus_final.SGBSTDN_STST_CODE,
-- SZTHIST_MOVIMIENTO = estatus_final.fecha_act
-- where a.SZTHIST_PIDM = estatus_final.PIDM
-- And SZTHIST_PROGRAM = estatus_final.programa
-- And SZTHIST_TERM_CODE = (select max (a1.SZTHIST_TERM_CODE)
-- from SZTHIST a1
-- where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
-- And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
-- Elsif estatus_final.ESTATUS = 'ACTIVE' And estatus_final.SGBSTDN_STST_CODE IN ('AS', 'PR', 'MA', 'EG') Then
-- Update SZTHIST a
-- set SZTHIST_STST_CODE = estatus_final.SGBSTDN_STST_CODE,
-- SZTHIST_MOVIMIENTO = estatus_final.fecha_act
-- where a.SZTHIST_PIDM = estatus_final.PIDM
-- And SZTHIST_PROGRAM = estatus_final.programa
-- And SZTHIST_TERM_CODE = (select max (a1.SZTHIST_TERM_CODE)
-- from SZTHIST a1
-- where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
-- And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
-- Elsif estatus_final.ESTATUS = 'ACTIVE' And estatus_final.SGBSTDN_STST_CODE NOT IN ('AS', 'PR', 'MA', 'EG') Then
-- Update SZTHIST a
-- set SZTHIST_STST_CODE = estatus_final.SGBSTDN_STST_CODE,
-- SZTHIST_MOVIMIENTO = estatus_final.fecha_act
-- where a.SZTHIST_PIDM = estatus_final.PIDM
-- And SZTHIST_PROGRAM = estatus_final.programa
-- And SZTHIST_TERM_CODE = (select max (a1.SZTHIST_TERM_CODE)
-- from SZTHIST a1
-- where a.SZTHIST_PIDM = a1.SZTHIST_PIDM
-- And a.SZTHIST_PROGRAM = a1.SZTHIST_PROGRAM);
--
-- End if;
-- Commit;
-- End Loop estatus_final;
--
-- For muestra in ( select distinct SZTHIST_PIDM pidm , SZTHIST_CAMP_CODE campus, SZTHIST_LEVL_CODE nivel , SZTHIST_PROGRAM programa, SZTHIST_KEY_SEQNO study
-- from SZTHIST )
-- loop
-- For rate in (select distinct a.sgbstdn_rate_code rate, a.sgbstdn_pidm pidm, a.sgbstdn_camp_code campus, a.sgbstdn_levl_code nivel
-- from sgbstdn a
-- Where a.sgbstdn_pidm = muestra.pidm
-- And a.sgbstdn_camp_code = muestra.campus
-- And a.sgbstdn_levl_code = muestra.nivel
-- And a.sgbstdn_term_code_eff = (select max ( a1.sgbstdn_term_code_eff)
-- from sgbstdn a1
-- Where a.sgbstdn_pidm = a1.sgbstdn_pidm
-- And a.sgbstdn_levl_code = a1.sgbstdn_levl_code) )
-- loop
--
-- Update SZTHIST
-- set SZTHIST_RATE_CODE = rate.rate
-- where SZTHIST_PIDM = rate.pidm
-- and SZTHIST_CAMP_CODE = rate.campus
-- And SZTHIST_LEVL_CODE = rate.nivel;
--
--
-- End Loop rate;
--
-- for jornada in ( Select SGRSATT_ATTS_CODE Jornada, SGRSATT_PIDM pidm , SGRSATT_STSP_KEY_SEQUENCE study
-- from SGRSATT
-- Where substr (SGRSATT_ATTS_CODE, 1,1) in ( '1', '2', '3', '4', '5', '6', '7', '8', '9')
-- And SGRSATT_PIDM = muestra.pidm
-- ) loop
--
--
-- Update SZTHIST
-- set SZTHIST_ATTS_CODE = Jornada.Jornada
-- where SZTHIST_PIDM = jornada.pidm
-- And SZTHIST_KEY_SEQNO = jornada.study;
--
-- End Loop Jornada;
--
-- Commit;
-- End Loop muestra;
--
--
-- End;

--Procedure sp_Academico_Financiero
--
--is
--cursor c_spriden is
--select s.spriden_pidm pidm
--from spriden s, sorlcur c
--where 1=1
--and S.SPRIDEN_CHANGE_IND is null
--and S.SPRIDEN_PIDM = C.SORLCUR_PIDM
--and C.SORLCUR_SEQNO = ( select max ( cc.SORLCUR_SEQNO ) from sorlcur cc where c.SORLCUR_PIDM = cc.SORLCUR_PIDM );
--
--
-- BEGIN
--
-- delete TZTCRTE
-- where TZTCRTE_TIPO_REPORTE = 'Academico_Financiero';
-- Commit;
--
--
-- for jump in c_spriden loop
-- Begin
--
--
-- For acafin in (
-- With correo_principal as (
-- select Distinct
-- GOREMAL_PIDM Pidm,
-- GOREMAL_EMAIL_ADDRESS,
-- max(GOREMAL_SURROGATE_ID)
-- from GOREMAL
-- Where goremal_emal_code='PRIN' and goremal_status_ind='A'
-- and GOREMAL_PIDM = jump.pidm
-- group by GOREMAL_PIDM, GOREMAL_EMAIL_ADDRESS
-- ),
-- correo_alterno as (
-- select Distinct
-- GOREMAL_PIDM Pidm,
-- GOREMAL_EMAIL_ADDRESS,
-- max(GOREMAL_SURROGATE_ID)
-- from GOREMAL
-- Where goremal_emal_code='ALTE' and goremal_status_ind='A'
-- and GOREMAL_PIDM = jump.pidm
-- group by GOREMAL_PIDM, GOREMAL_EMAIL_ADDRESS
-- ),
-- telefono_casa as (
-- Select distinct
-- SPRTELE_PIDM pidm,
-- SPRTELE_PHONE_AREA || SPRTELE_PHONE_NUMBER Telefono,
-- max(SPRTELE_SURROGATE_ID)
-- from SPRTELE
-- Where SPRTELE_TELE_CODE = 'RESI'
-- and SPRTELE_PIDM = jump.pidm
-- group by SPRTELE_PIDM, SPRTELE_PHONE_AREA || SPRTELE_PHONE_NUMBER
-- ),
-- telefono_celular as (
-- Select distinct
-- SPRTELE_PIDM pidm,
-- SPRTELE_PHONE_AREA || SPRTELE_PHONE_NUMBER Telefono,
-- max(SPRTELE_SURROGATE_ID)
-- from SPRTELE
-- Where SPRTELE_TELE_CODE = 'CELU'
-- and SPRTELE_PIDM = jump.pidm
-- group by SPRTELE_PIDM, SPRTELE_PHONE_AREA || SPRTELE_PHONE_NUMBER
-- ),
-- curricula as (
-- Select
-- a.sorlcur_pidm pidm,
-- a.sorlcur_camp_code campus,
-- a.sorlcur_levl_code Nivel_Code,
-- b.STVLEVL_DESC nivel,
-- a.sorlcur_program programa,
-- a.SORLCUR_TERM_CODE_CTLG periodo_catalogo,
-- c.SZTDTEC_PROGRAMA_COMP Nombre_Programa
-- -- max(a.SORLCUR_SURROGATE_ID) ------------------se lo quitaria
-- from sorlcur a, stvlevl b, sztdtec c
-- where a.SORLCUR_LMOD_CODE = 'LEARNER'
-- and a.sorlcur_pidm = jump.pidm
-- --And a.SORLCUR_CACT_CODE = 'ACTIVE'
-- And b.stvlevl_code = a.sorlcur_levl_code
-- And a.sorlcur_program = c.SZTDTEC_PROGRAM
-- And a.SORLCUR_TERM_CODE_CTLG = c.SZTDTEC_TERM_CODE
-- And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
-- from SORLCUR a1
-- Where a.sorlcur_pidm = a1.sorlcur_pidm
-- and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
-- -- group by a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code, b.STVLEVL_DESC, a.sorlcur_program, a.SORLCUR_TERM_CODE_CTLG, c.SZTDTEC_PROGRAMA_COMP
-- ),
---- matricula as (
---- Select
---- a.sorlcur_pidm pidm,
---- a.sorlcur_camp_code campus,
---- a.sorlcur_levl_code nivel,
---- a.sorlcur_program programa,
---- a.SORLCUR_TERM_CODE_CTLG periodo_catalogo,
---- max(a.SORLCUR_SURROGATE_ID) ----------se lo quitaria
---- from sorlcur a
---- where a.SORLCUR_LMOD_CODE = 'LEARNER'
---- and a.sorlcur_pidm = jump.pidm
---- And a.SORLCUR_SEQNO in (select max (a1.SORLCUR_SEQNO)
---- from SORLCUR a1
---- Where a.sorlcur_pidm = a1.sorlcur_pidm
---- and a.SORLCUR_LMOD_CODE = a1.SORLCUR_LMOD_CODE)
---- group by a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code, a.sorlcur_program, a.SORLCUR_TERM_CODE_CTLG
---- ),
-- Referencia as (
-- select
-- GORADID_PIDM PIDM,
-- GORADID_ADDITIONAL_ID Referencias,
-- max(GORADID_SURROGATE_ID)
-- FROM GORADID
-- where GORADID_ADID_CODE like 'REF%'
-- and goradid_pidm = jump.pidm
-- group by GORADID_PIDM, GORADID_ADDITIONAL_ID
-- ),
-- Incobrable as (
-- select distinct
-- TZTMORA_PIDM PIDM,
-- case
-- when TZTMORA_dias between 1 and 30 then
-- .0
-- when TZTMORA_dias between 31 and 60 then
-- .5
-- when TZTMORA_dias between 61 and 90 then
-- .10
-- when TZTMORA_dias between 91 and 120 then
-- .20
-- when TZTMORA_dias between 121 and 150 then
-- .30
-- when TZTMORA_dias between 151 and 180 then
-- .60
-- when TZTMORA_dias > 180 then
-- .85
-- End as Incobrable
-- from TZTMORA)
-- select distinct a.spriden_pidm usuario_id,
-- a.spriden_id Matricula,
-- f.campus Campus,
-- f.Nivel_Code Nivel_Code,
-- f.nivel Nivel_Academico,
-- a.SPRIDEN_LAST_NAME ||' '||SPRIDEN_FIRST_NAME Nombre,
-- b.GOREMAL_EMAIL_ADDRESS Correo_Principal,
-- c.GOREMAL_EMAIL_ADDRESS Correo_Alterno,
-- d.Telefono Telefono_Casa,
-- e.Telefono Telefono_Celular,
-- BANINST1.PKG_REPORTES.f_saldototal (a.spriden_pidm) Saldo_Total,
-- BANINST1.PKG_REPORTES.f_saldodia (a.spriden_pidm) Saldo_Vencido,
-- PKG_REPORTES.f_cargo_vencidos (a.spriden_pidm) Numero_Cargo_Vencido,
-- PKG_REPORTES.f_fecha_pago_vieja (a.spriden_pidm) Primer_fecha_limite_de_pago,
-- PKG_REPORTES.f_fecha_pago_alta (a.spriden_pidm) Ultima_fecha_limite_de_pago,
-- PKG_REPORTES.f_dias_atraso (a.spriden_pidm) Dias_Atraso,
-- trunc (PKG_REPORTES.f_dias_atraso (a.spriden_pidm) / 30 ) Meses_Atraso,
-- PKG_REPORTES.f_mora (a.spriden_pidm) Mora,
-- PKG_REPORTES.f_cargo_total_futuro (a.spriden_pidm) Total_montos_Prox,
-- PKG_REPORTES.f_saldocorte (a.spriden_pidm) Saldo_Prox,
-- PKG_REPORTES.f_cargo_Numero_futuro (a.spriden_pidm) Numero_Cargos_Proximos,
-- to_date (PKG_REPORTES.f_fechacorte (a.spriden_pidm), 'dd/mm/rrrr') Prox_Fecha_Limite_Pag,
-- to_date (PKG_REPORTES.f_fechacorte (a.spriden_pidm),'dd/mm/rrrr' ) - trunc (sysdate) Num_Dias_Prox_Pago,
-- PKG_REPORTES.f_pago_total (a.spriden_pidm) Suma_depositos,
-- PKG_REPORTES.f_num_total_pago (a.spriden_pidm) Numero_Depositos,
-- (PKG_REPORTES.f_saldodia (a.spriden_pidm) * h.Incobrable) Monto_Incobrable,
-- case
-- when h.Incobrable = .0 then
-- '0%'
-- when h.Incobrable = .5 then
-- '5%'
-- when h.Incobrable = .10 then
-- '10%'
-- when h.Incobrable = .20 then
-- '20%'
-- when h.Incobrable = .30 then
-- '30%'
-- when h.Incobrable = .60 then
-- '60%'
-- when h.Incobrable = .85 then
-- '85%'
-- End as Provision_Incobrable,
-- null Ultimo_Acceso_Plataforma,
-- null Rango_dias_acceso_plataforma,
-- PKG_REPORTES.f_jornada (a.spriden_pidm) Jornada_Plan,
-- PKG_REPORTES.f_no_materia (a.spriden_pidm) Carga_Academica,
-- pkg_datos_academicos.acreditadas1(a.spriden_pidm ,f.programa ) Materias_Aprobadas,
-- pkg_datos_academicos.avance1(a.spriden_pidm ,f.programa ) Avance_Curricular,
-- pkg_datos_academicos.promedio1(a.spriden_pidm ,f.programa ) Promedio,
-- to_date (PKG_REPORTES.f_fecha_Matriculacion (a.spriden_pidm), 'dd/mm/rrrr') Fecha_Matriculacion,
-- PKG_REPORTES.f_periodo_inicial (a.spriden_pidm) Ciclo_Inicial,
-- PKG_REPORTES.f_Estado_programa (a.spriden_pidm) Estado_alumno_programa,
-- f.programa Programa_Code,
-- f.Nombre_Programa Nombre_Programa,
-- nvl (PKG_REPORTES.f_Descuento (a.spriden_pidm), 0) Descuento,
-- g.referencias Referencia_Bancaria
-- from spriden a, correo_principal b, correo_alterno c, telefono_casa d, telefono_celular e, curricula f, Referencia g, Incobrable h
-- Where A.SPRIDEN_CHANGE_IND is null
-- and a.spriden_pidm = jump.pidm
-- And a.spriden_pidm = b.Pidm (+)
-- And a.spriden_pidm = c.Pidm (+)
-- And a.spriden_pidm = d.Pidm (+)
-- And a.spriden_pidm = e.Pidm (+)
-- And a.spriden_pidm = f.Pidm (+)
-- And a.spriden_pidm = g.Pidm (+)
-- And a.spriden_pidm = h.Pidm (+)
-- order by 1
--
-- )loop
--
-- Insert into TZTCRTE values (acafin.usuario_id,
-- acafin.Matricula,
-- acafin.Campus,
-- acafin.Nivel_Code,
-- acafin.Nivel_Academico,
-- acafin.Nombre,
-- acafin.Correo_Principal,
-- acafin.Correo_Alterno,
-- acafin.Telefono_Casa,
-- acafin.Telefono_Celular,
-- acafin.Saldo_Total,
-- acafin.Saldo_Vencido,
-- acafin.Numero_Cargo_Vencido,
-- acafin.Primer_fecha_limite_de_pago,
-- acafin.Ultima_fecha_limite_de_pago,
-- acafin.Dias_Atraso,
-- acafin.Meses_Atraso,
-- acafin.Mora,
-- acafin.Total_montos_Prox,
-- acafin.Saldo_Prox,
-- acafin.Numero_Cargos_Proximos,
-- acafin.Prox_Fecha_Limite_Pag,
-- acafin.Num_Dias_Prox_Pago,
-- acafin.Suma_depositos,
-- acafin.Numero_Depositos,
-- acafin.Monto_Incobrable,
-- acafin.Provision_Incobrable,
-- acafin.Ultimo_Acceso_Plataforma,
-- acafin.Rango_dias_acceso_plataforma,
-- acafin.Jornada_Plan,
-- acafin.Carga_Academica,
-- acafin.Materias_Aprobadas,
-- acafin.Avance_Curricular,
-- acafin.Promedio,
-- acafin.Fecha_Matriculacion,
-- acafin.Ciclo_Inicial,
-- acafin.Estado_alumno_programa,
-- acafin.Programa_Code,
-- acafin.Nombre_Programa,
-- acafin.Descuento,
-- acafin.Referencia_Bancaria,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- null,
-- sysdate,
-- 'Academico_Financiero'
-- );
-- commit;
-- End loop;
--
--
--
-- End;
-- end loop;
-- END;


Procedure sp_Hist_Acad_Compac
--------se modifico este reporte el dis de hoy 15/03/2019 ---glovicx
is

 BEGIN
 Begin

 delete TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Historial_Academico_Compactado';
 Commit;

 for c in (
 select x.pidm, x.Matricula,x.campus, x.nivel, x.nombre,x.Programa, x.Nombre_Programa, x.Estatus, x.Aprobadas, x.Reprobadas, x.En_Curso, x.Por_Cursar, x.Total,
 CASE WHEN (to_number (x.avances)) > 100
 THEN 100
 ELSE (to_number (x.avances))
 END avance
 from (
 select distinct spriden_pidm pidm,
 SPRIDEN_ID as Matricula,
 nvl( K.SZTHITA_CAMP, C.SORLCUR_CAMP_CODE) campus,
 NVL(K.SZTHITA_LEVL, C.SORLCUR_LEVL_CODE ) NIVEL,
 replace(SPRIDEN_LAST_NAME,'/',' ') || ' ' || SPRIDEN_FIRST_NAME as Nombre,
 NVL(k.SZTHITA_PROG, C.SORLCUR_PROGRAM) programa,
 NVL(k.SZTHITA_N_PROG,(SELECT DISTINCT z.SZTDTEC_PROGRAMA_COMP
                                        FROM SZTDTEC Z
                                        WHERE Z.SZTDTEC_PROGRAM = C.SORLCUR_PROGRAM
                                        AND z.SZTDTEC_CAMP_CODE=C.SORLCUR_CAMP_CODE
                                         And z.SZTDTEC_TERM_CODE = c.SORLCUR_TERM_CODE_CTLG
                                        )) Nombre_Programa,
 k.SZTHITA_STATUS estatus,
 k.SZTHITA_APROB aprobadas,
 k.SZTHITA_REPROB reprobadas,
 k.SZTHITA_E_CURSO en_curso,
 k.SZTHITA_X_CURSAR por_cursar,
 k.SZTHITA_TOT_MAT total,
 k.SZTHITA_AVANCE avances
 from SPRIDEN a, SZTHITA k, sorlcur c
 where a.SPRIDEN_CHANGE_IND is null
 And C.SORLCUR_PIDM = k.SZTHITA_PIDM(+)
 and C.SORLCUR_PIDM = a.SPRIDEN_PIDM
 and C.SORLCUR_SEQNO = ( select max ( cc.SORLCUR_SEQNO ) from sorlcur cc where c.SORLCUR_PIDM = cc.SORLCUR_PIDM )
 order by pidm
 )x
 ) loop

 Insert into TZTCRTE values (c.pidm,
 c.Matricula,
 c.campus,
 c.nivel,
 c.Nombre,
 c.Programa,
 c.Nombre_Programa,
 c.Estatus,
 c.Aprobadas,
 c.Reprobadas,
 c.En_Curso,
 c.Por_Cursar,
 c.Total,
 c.avance,
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
 trunc(sysdate),
 'Historial_Academico_Compactado'
 );

 End loop;
 commit;
 End;

 END;

FUNCTION p_fecha_max (p_pidm in number) Return varchar2
is
--vl_fecha_ini date;
vl_salida varchar2(250):= 'EXITO';
vl_fecha varchar2(25):= null;

BEGIN

 Begin



 select max (x.fecha_inicio) --, rownum
 into vl_fecha
 from (
 SELECT DISTINCT
 MAX (SSBSECT_PTRM_END_DATE) fecha_inicio, SFRSTCR_pidm pidm,b.SSBSECT_TERM_CODE Periodo
 FROM SFRSTCR a, SSBSECT b
 WHERE a.SFRSTCR_TERM_CODE = b.SSBSECT_TERM_CODE
 AND a.SFRSTCR_CRN = b.SSBSECT_CRN
 AND a.SFRSTCR_RSTS_CODE = 'RE'
 AND b.SSBSECT_PTRM_END_DATE =
 (SELECT MAX (b1.SSBSECT_PTRM_END_DATE)
 FROM SSBSECT b1
 WHERE b.SSBSECT_TERM_CODE = b1.SSBSECT_TERM_CODE
 AND b.SSBSECT_CRN = b1.SSBSECT_CRN)
 and SFRSTCR_pidm = p_pidm
 GROUP BY SFRSTCR_pidm, b.SSBSECT_TERM_CODE
 order by 1,3 asc
 ) x
 order by 1 asc;






 Exception
 When Others then
 vl_fecha := '01/01/1900';
 End;

 return vl_fecha;

Exception
When Others then
 vl_fecha := '01/01/1900';
 return vl_fecha;
END p_fecha_max;


Procedure sp_pagos_facturacion_dia is

Begin

 Begin
 delete TZTCRTE
 where TZTCRTE_TIPO_REPORTE in ( 'Pago_Facturacion_dia', 'Facturacion_dia');
 Commit;
 Exception
 When others then
 null;
 End;


 Begin
 For c in (

 with colegiatura as (
 Select a.tbraccd_pidm pidm, TBRACCD_TRAN_NUMBER secuencia, tbraccd_desc desc_cargo, TBBDETC_DCAT_CODE Categ_Col
 from tbraccd a, tbbdetc b
 where a.tbraccd_detail_code = tbbdetc_detail_code
 ),
 curp as (select GORADID_PIDM PIDM,
 GORADID_ADDITIONAL_ID CURP
 from GORADID
 where GORADID_ADID_CODE = 'CURP')
 select DISTINCT
 tbraccd_pidm pidm ,
 spriden_id as Matricula,
 SPREMRG_LAST_NAME as Nombre,
 saradap_camp_code as Campus,
 SARADAP_LEVL_CODE as Nivel,
 SPREMRG_MI as RFC,
 SPREMRG_STREET_LINE1 || ' ' ||SPREMRG_STREET_LINE2 || ' ' || SPREMRG_STREET_LINE3 as Dom_Fiscal,
 SPREMRG_CITY as Ciudad,
 SPREMRG_ZIP as CP,
 SPREMRG_NATN_CODE as Pais,
 tbraccd_detail_code as Tipo_Deposito,
 tbraccd_desc as Descripcion,
 tbraccd_amount as Monto,
 TBRACCD_TRAN_NUMBER as Transaccion,
 trunc ( TBRACCD_TRANS_DATE) as Fecha_Pago,
 GORADID_ADDITIONAL_ID as REFERENCIA,
 GORADID_ADID_CODE as Referencia_Tipo,
 GOREMAL_EMAIL_ADDRESS as EMAIL,
 TBRAPPL_AMOUNT as Monto_pagado,
 TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
 colegiatura.desc_cargo descripcion_pago,
 colegiatura.Categ_Col,
 min(SPREMRG_PRIORITY) Prioridad,
 curp.CURP,
 SARADAP_DEGC_CODE_1 Grado,
 SPREMRG_LAST_NAME Razon_social
 from SPREMRG
 left join SPRIDEN on SPREMRG_PIDM = SPRIDEN_PIDM and SPRIDEN.SPRIDEN_CHANGE_IND IS NULL
 left join TBRACCD on SPREMRG_PIDM = TBRACCD_PIDM and trunc (TBRACCD_EFFECTIVE_DATE) = trunc (sysdate)
 left join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
 left join SARADAP on SPREMRG_PIDM = SARADAP_PIDM
 left join GORADID on SPREMRG_PIDM = GORADID_PIDM and GORADID_ADID_CODE in ('REFH','REFS')
 left join GOREMAL on SPREMRG_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
 left outer join tbrappl on spriden_pidm = tbrappl_pidm and TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
 left outer join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
 left outer join curp on SPRIDEN_PIDM = curp.PIDM
 where
 SPREMRG_MI is not NULL
 and TBBDETC_TYPE_IND = 'P'
 and TBBDETC_DCAT_CODE = 'CSH'
 and SPREMRG_PRIORITY in (select MIN(s1.SPREMRG_PRIORITY)
 FROM SPREMRG s1
 where SPREMRG_PIDM = s1.SPREMRG_PIDM
 and SPREMRG_PRIORITY = s1.SPREMRG_PRIORITY)
 GROUP BY tbraccd_pidm, spriden_id, SPREMRG_LAST_NAME, saradap_camp_code, SARADAP_LEVL_CODE, SPREMRG_MI,
 SPREMRG_STREET_LINE1 || ' ' ||SPREMRG_STREET_LINE2 || ' ' || SPREMRG_STREET_LINE3, SPREMRG_CITY, SPREMRG_ZIP, SPREMRG_NATN_CODE,
 tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, trunc ( TBRACCD_TRANS_DATE), GORADID_ADDITIONAL_ID,
 GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
 curp.CURP, SARADAP_DEGC_CODE_1
 union
 select DISTINCT
 tbraccd_pidm pidm ,
 spriden_id as Matricula,
 null as Nombre,
 saradap_camp_code as Campus,
 SARADAP_LEVL_CODE as Nivel,
 null as RFC,
 null as Dom_Fiscal,
 null as Ciudad,
 null as CP,
 null as Pais,
 tbraccd_detail_code as Tipo_Deposito,
 tbraccd_desc as Descripcion,
 tbraccd_amount as Monto,
 TBRACCD_TRAN_NUMBER as Transaccion,
 trunc ( TBRACCD_TRANS_DATE) as Fecha_Pago,
 GORADID_ADDITIONAL_ID as REFERENCIA,
 GORADID_ADID_CODE as Referencia_Tipo,
 GOREMAL_EMAIL_ADDRESS as EMAIL,
 TBRAPPL_AMOUNT as Monto_pagado,
 TBRAPPL_CHG_TRAN_NUMBER as secuencia_pago,
 colegiatura.desc_cargo descripcion_pago,
 colegiatura.Categ_Col,
 null Prioridad,
 curp.CURP,
 SARADAP_DEGC_CODE_1 Grado,
 null Razon_social
 from SPRIDEN
 left join TBRACCD on SPRIDEN_PIDM = TBRACCD_PIDM and trunc (TBRACCD_EFFECTIVE_DATE) = trunc (sysdate)
 left join TBBDETC on TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
 left join SARADAP on SPRIDEN_PIDM = SARADAP_PIDM
 left join GORADID on SPRIDEN_PIDM = GORADID_PIDM and GORADID_ADID_CODE in ('REFH','REFS')
 left join GOREMAL on SPRIDEN_PIDM = GOREMAL_PIDM and GOREMAL_EMAL_CODE in ('PRIN')
 left outer join tbrappl on spriden_pidm = tbrappl_pidm and TBRAPPL_PAY_TRAN_NUMBER = TBRACCD_TRAN_NUMBER and TBRAPPL_REAPPL_IND is null
 left outer join colegiatura on spriden_pidm = colegiatura.pidm and colegiatura.secuencia = TBRAPPL_chg_TRAN_NUMBER
 left outer join curp on SPRIDEN_PIDM = curp.PIDM
 where 1= 1
 and TBBDETC_TYPE_IND = 'P'
 and TBBDETC_DCAT_CODE = 'CSH'
 And spriden_pidm not in (select SPREMRG_pidm from SPREMRG)
 GROUP BY tbraccd_pidm, spriden_id,
 saradap_camp_code, SARADAP_LEVL_CODE,
 tbraccd_detail_code, tbraccd_desc, tbraccd_amount, TBRACCD_TRAN_NUMBER, trunc ( TBRACCD_TRANS_DATE), GORADID_ADDITIONAL_ID,
 GORADID_ADID_CODE, GOREMAL_EMAIL_ADDRESS, TBRAPPL_AMOUNT, TBRAPPL_CHG_TRAN_NUMBER, colegiatura.desc_cargo, colegiatura.Categ_Col,
 curp.CURP, SARADAP_DEGC_CODE_1
 ) loop

 Insert into TZTCRTE values (c.pidm,
 c.matricula,
 c.campus,
 c.nivel,
 c.nombre,
 c.rfc,
 c.dom_fiscal,
 c.ciudad,
 c.cp,
 c.pais,
 c.tipo_deposito,
 c.descripcion,
 c.monto,
 c.transaccion,
 c.fecha_pago,
 c.referencia,
 c.referencia_tipo,
 c.email,
 c.monto_pagado,
 c.secuencia_pago,
 c.descripcion_pago,
 c.Categ_Col,
 c.Prioridad,
 c.CURP,
 c.Grado,
 c.Razon_social,
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
 'Pago_Facturacion_dia'
 );




 End Loop;
 Commit;

 For c in (
 with intereses as (
 select distinct
 TZTCRTE_PIDM Pidm,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO17 as Intereses,
 sum (TZTCRTE_CAMPO15) as Monto_intereses,
 TZTCRTE_CAMPO18 as Categoria,
 TZTCRTE_CAMPO10 as Secuencia
 from TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
 and TZTCRTE_CAMPO18 = 'INT'
 group by
 TZTCRTE_PIDM,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO17,
 TZTCRTE_CAMPO18,
 TZTCRTE_CAMPO10
 ),
 accesorios as (
 select distinct
 TZTCRTE_PIDM Pidm,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO17 as accesorios,
 sum (TZTCRTE_CAMPO15) as Monto_accesorios,
 TZTCRTE_CAMPO18 as Categoria,
 TZTCRTE_CAMPO10 as Secuencia
 from TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
 and TZTCRTE_CAMPO18 in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'VTA')
 group by
 TZTCRTE_PIDM,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO17,
 TZTCRTE_CAMPO18,
 TZTCRTE_CAMPO10
 ),
 colegiatura as (
 select distinct
 TZTCRTE_PIDM Pidm,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO17 as colegiatura,
 sum (TZTCRTE_CAMPO15) as Monto_colegiatura,
 TZTCRTE_CAMPO18 as Categoria,
 TZTCRTE_CAMPO10 as Secuencia
 from TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
 and TZTCRTE_CAMPO18 in ('COL')
 group by
 TZTCRTE_PIDM,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO17,
 TZTCRTE_CAMPO18,
 TZTCRTE_CAMPO10
 ),
 otros as (
 select distinct
 TZTCRTE_PIDM Pidm,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO17 as otros,
 sum (TZTCRTE_CAMPO15) as Monto_otros,
 TZTCRTE_CAMPO18 as Categoria,
 TZTCRTE_CAMPO10 as Secuencia
 from TZTCRTE
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
 and TZTCRTE_CAMPO18 not in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL', 'VTA', 'TUI')
 group by
 TZTCRTE_PIDM,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO17,
 TZTCRTE_CAMPO18,
 TZTCRTE_CAMPO10
 )
 select distinct
 TZTCRTE_pidm as pidm,
 TZTCRTE_CAMPO1 as Nombre,
 TZTCRTE_CAMPO2 as RFC,
 TZTCRTE_CAMPO3 as Dom_Fiscal,
 TZTCRTE_CAMPO4 as Ciudad,
 TZTCRTE_CAMPO5 as CP,
 TZTCRTE_CAMPO6 as Pais,
 TZTCRTE_CAMPO7 as Tipo_Deposito,
 TZTCRTE_CAMPO8 as Descripcion,
 TZTCRTE_CAMPO9 as Monto,
 TZTCRTE_LEVL as Nivel,
 TZTCRTE_CAMP as Campus,
 TZTCRTE_ID as Matricula,
 TZTCRTE_CAMPO10 as Transaccion,
 TZTCRTE_CAMPO11 as Fecha_Pago,
 TZTCRTE_CAMPO12 as REFERENCIA,
 TZTCRTE_CAMPO13 as Referencia_Tipo,
 TZTCRTE_CAMPO14 as EMAIL,
 e.Colegiatura,
 e.Monto_colegiatura,
 b.intereses,
 b.Monto_intereses,
 c.accesorios,
 c.Monto_accesorios,
 d.otros,
 d.monto_otros,
 TZTCRTE_CAMPO20 as Curp,
 TZTCRTE_CAMPO21 as Grado,
 TZTCRTE_CAMPO22 as Razon_social
 from TZTCRTE, intereses b, accesorios c, otros d, colegiatura e
 where TZTCRTE_TIPO_REPORTE = 'Pago_Facturacion_dia'
 --and TZTCRTE_CAMP = :MC_CAMPUS
 --and TZTCRTE_LEVL = :MC_NIVEL
 --and to_date(TZTCRTE_CAMPO11,'dd/mm/rrrr') BETWEEN to_date(:Fecha_Inicio, 'dd/mm/rrrr') and to_date(:Fecha_Fin, 'dd/mm/rrrr')
 --And TZTCRTE_ID = '010041922'
 and TZTCRTE_CAMPO18 in ('ABC','ACC','ACL','CCC','ENV','OTG','SEG','SER', 'FIN','DAL', 'INT', 'COL')
 --and TZTCRTE_CAMPO18 = 'COL' (+)
 and TZTCRTE_PIDM = e.pidm (+)
 and TZTCRTE_LEVL = e.nivel (+)
 and TZTCRTE_CAMP = e.campus (+)
 and TZTCRTE_CAMPO11 = e.Fecha_Pago (+)
 And TZTCRTE_CAMPO10 = e.secuencia (+)
 and TZTCRTE_PIDM = b.pidm (+)
 and TZTCRTE_LEVL = b.nivel (+)
 and TZTCRTE_CAMP = b.campus (+)
 and TZTCRTE_CAMPO11 = b.Fecha_Pago (+)
 And TZTCRTE_CAMPO10 = b.secuencia (+)
 and TZTCRTE_PIDM = c.pidm (+)
 and TZTCRTE_LEVL = c.nivel (+)
 and TZTCRTE_CAMP = c.campus (+)
 and TZTCRTE_CAMPO11 = c.Fecha_Pago (+)
 And TZTCRTE_CAMPO10 = c.secuencia (+)
 and TZTCRTE_PIDM = d.pidm (+)
 and TZTCRTE_LEVL = d.nivel (+)
 and TZTCRTE_CAMP = d.campus (+)
 and TZTCRTE_CAMPO11 = d.Fecha_Pago (+)
 And TZTCRTE_CAMPO10 = d.secuencia (+)
 --and TZTCRTE_PIDM = 16589
 group by TZTCRTE_pidm,
 TZTCRTE_CAMPO1,
 TZTCRTE_CAMPO2,
 TZTCRTE_CAMPO3,
 TZTCRTE_CAMPO4,
 TZTCRTE_CAMPO5,
 TZTCRTE_CAMPO6,
 TZTCRTE_CAMPO7,
 TZTCRTE_CAMPO8,
 TZTCRTE_CAMPO9,
 TZTCRTE_LEVL,
 TZTCRTE_CAMP,
 TZTCRTE_ID,
 TZTCRTE_CAMPO10,
 TZTCRTE_CAMPO11,
 TZTCRTE_CAMPO12,
 TZTCRTE_CAMPO13,
 TZTCRTE_CAMPO14,
 e.Colegiatura,
 e.Monto_colegiatura,
 b.intereses,
 b.Monto_intereses,
 c.accesorios,
 c.Monto_accesorios,
 d.otros,
 d.monto_otros,
 TZTCRTE_CAMPO20,
 TZTCRTE_CAMPO21,
 TZTCRTE_CAMPO22
 order by TZTCRTE_ID, TZTCRTE_CAMPO11, TZTCRTE_CAMPO10 ) loop

 Insert into TZTCRTE values (c.pidm,
 c.matricula,--
 c.campus,--
 c.nivel,--
 c.nombre,--
 c.rfc,--
 c.dom_fiscal,--
 c.ciudad, --
 c.cp, --
 c.pais,--
 c.tipo_deposito,--
 c.descripcion,--
 c.monto,--
 c.transaccion,--
 c.fecha_pago,--
 c.referencia,--
 c.referencia_tipo,--
 c.email,--
 c.colegiatura,
 c.monto_colegiatura,
 c.intereses,
 c.monto_intereses,
 c.accesorios,
 c.monto_accesorios,
 c.otros,
 c.monto_otros,
 c.CURP,
 c.Grado,
 c.Razon_social,
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
 'Facturacion_dia'
 );

 End loop;


 End;

End sp_pagos_facturacion_dia;

procedure p_cargatztprog is

/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */
 vl_pago number:=0;
 vl_pago_minimo number:=0;
 vl_sp number:=0;

BEGIN


EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.TZTPROG';
COMMIT;


Begin

    Update sgbstdn
    set SGBSTDN_STST_CODE ='MA'
    Where SGBSTDN_STST_CODE ='AS';
Exception
    When Others then
        null;
End;



 insert into migra.tztprog
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
 from tztprog
 where 1= 1
 --CAMPUS||nivel = 'ULTLI'
 --and fecha_mov is null

 ) loop

 If c.fecha_inicio < '04/03/2017' and c.campus != 'UTLLI' then

 Begin
 Update tztprog
 set FECHA_MOV = '04/03/2017'
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 ElsIf c.fecha_inicio >= '04/03/2017' and c.fecha_mov is null then

 Begin
 Update tztprog
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

 Update tztprog
 set FECHA_MOV = '03/04/2017'
 Where FECHA_MOV is null;
 Commit;


 ---- Se actualiza la fecha de la primera inscripcion ----------


 begin


 for c in (
 select *
 from tztprog
 where 1 = 1
 -- and rownum <= 50
 )loop



 Begin


 Update tztprog
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
                    from tztprog
                    where 1= 1
                    and estatus in ('BT','BD','CM','CV','BI')
                    and SGBSTDN_STYP_CODE !='D'


     ) loop

        Begin
            Update tztprog
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



 /*

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
                 from tztprog a
                 where 1= 1
                 And pidm in (select SGRSCMT_PIDM
                 from SGRSCMT
                 where SGRSCMT_COMMENT_TEXT like '%FREEMI%')
                 And a.sp = (select max (a1.sp)
                 from tztprog a1
                 Where a.pidm = a1.pidm
                 And a.estatus = a1.estatus
                 )
                 union
                 select distinct a.*
                 from tztprog a
                 join goradid b on b.goradid_pidm = a.pidm and b.GORADID_ADID_CODE in ( Select ZSTPARA_PARAM_VALOR
                 from ZSTPARA
                 where 1= 1
                 -- And ZSTPARA_PARAM_VALOR = 'FREE'
                 And ZSTPARA_MAPA_ID = 'FREEMIUM_ADID'
                 )
                 Where 1= 1
                 And a.sp = (select max (a1.sp)
                 from tztprog a1
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

                      select distinct a.matricula, a.programa
                     from tztprog a
                     Where 1= 1
                     And a.estatus not in ('CP')
                     And a.sp = (select max (a1.sp)
                                             from tztprog a1
                                             Where a.pidm = a1.pidm
                                             and a1.campus||a1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                                              And trunc (a.fecha_inicio) = trunc (a1.fecha_inicio)
                                              And a.estatus = a1.estatus
                                                )
                     And (a.matricula, a.sp) not in (select b.matricula, b.sp
                     from tztprog_free b)
                     And (a.matricula, a.programa) not in (select b.matricula, b.carrera
                     from SZTECRM b)

                     ) loop

                     Begin
                     insert into SZTECRM
                     select distinct a.pidm,
                     a.matricula,
                     substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1) Paterno ,
                     substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150) Materno,
                     SPRIDEN_FIRST_NAME Nombre,
                     campus, nivel, estatus,
                     pkg_utilerias.f_correo(a.pidm, 'PRIN') Correo,
                     a.programa carrera,
                     pkg_utilerias.f_genero(a.pidm) Genero,
                     pkg_utilerias.f_nacionalidad(a.pidm) Nacionalidad,
                     pkg_utilerias.f_nss(a.pidm) NSS,
                     pkg_utilerias.f_etiqueta(a.pidm, 'CURP') Curp,
                     pkg_utilerias.f_fecha_nac(a.pidm) Fecha_Nac,
                     pkg_utilerias.f_ocupacion(a.pidm) Ocupacion,
                     pkg_utilerias.f_nombre_empresa(a.pidm) Nombre_Empresa,
                     pkg_utilerias.f_celular(a.pidm,'CELU') Tel_Celular,
                     pkg_utilerias.f_celular(a.pidm,'RESI') Tel_Casa,
                     pkg_utilerias.f_celular(a.pidm,'OFIC') Tel_Oficina,
                     pkg_utilerias.f_celular(a.pidm,'ALTE') Tel_Alterno,
                     pkg_utilerias.f_calle(a.pidm) calle ,
                     pkg_utilerias.f_colonia(a.pidm) Colonia ,
                     substr (pkg_utilerias.f_cp(a.pidm),1,5) CP,
                     pkg_utilerias.f_municipio(a.pidm) Municipio,
                     pkg_utilerias.f_estado(a.pidm) Estado,
                     pkg_utilerias.f_pais(a.pidm) Pais,
                     nvl (pkg_utilerias.f_fecha_primera(a.pidm, a.sp), pkg_utilerias.f_fecha_primera_sin_estatus(a.pidm, a.sp)) Fecha_Inscripcion,
                     pkg_utilerias.f_periodo_inscripcion(a.pidm, a.sp) Periodo_Inscripcion,
                     ----------------------------------------------------------------------------
                     pkg_utilerias.f_edad(a.pidm) Edad,
                     pkg_utilerias.f_lugar_nacimiento(a.pidm) Lugar_Nacimiento,
                     pkg_utilerias.f_tipo_puesto(a.pidm) Tipo_Puesto,
                     pkg_utilerias.f_Salario_Mensual(a.pidm) Salario_Mensual,
                     pkg_utilerias.f_esc_procedencia(a.pidm) Escuela_Procedencia,
                     NULL,
                     NULL,
                     NULL,
                     pkg_utilerias.f_jornada(a.pidm, a.sp) Jornada
                     from tztprog a
                     join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
                     where 1= 1
                     --and SGBSTDN_STYP_CODE in ('N')
                     And a.estatus not in ('CV')
                     And a.sp = (select max (a1.sp)
                     from tztprog a1
                     Where a.pidm = a1.pidm
                     and a1.campus||a1.nivel not in ( 'UTSID', 'UTSEC','INIEC')
                     And trunc (a.fecha_inicio) = trunc (a1.fecha_inicio)
                     And a.estatus = a1.estatus
                     )
                     And a.matricula = c.matricula
                     And a.programa = c.programa
                     Order by 1 desc ;




                     Exception
                     When Others then
                     dbms_output.put_line('Alumnos:' ||sqlerrm);
                     End;

                     Commit;
                     End loop;

         Commit;

         Exception
         When Others then
         dbms_output.put_line('Alumnos:'||sqlerrm);
         End;
         */

end p_cargatztprog;

procedure p_cargatztprog_all is


/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */


Begin

        EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.TZTPROG_ALL';
         COMMIT;

 insert into migra.tztprog_all
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
 f.SORLCUR_TERM_CODE_MATRIC Matriculacion,
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
-- and a.SGBSTDN_STST_CODE != 'CP'
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
 And f.SORLCUR_PROGRAM = f1.SORLCUR_PROGRAM
 aND f.SORLCUR_TERM_CODE_CTLG = f1.SORLCUR_TERM_CODE_CTLG)
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
a.SORLCUR_TERM_CODE_MATRIC Matriculacion,
b.SPRIDEN_CREATE_FDMN_CODE,
 a.SORLCUR_START_DATE fecha_inicio,
 sysdate as fecha_carga,
a.sorlcur_ADMT_CODE,
STVADMT_DESC
from sorlcur a
join spriden b on b.spriden_pidm = a.sorlcur_pidm and spriden_change_ind is null
left join migra.ESTATUS_REPORTE c on c.SPRIDEN_PIDM =a.sorlcur_pidm and c.PROGRAMAS = a.SORLCUR_PROGRAM
join SMRPRLE on SMRPRLE_PROGRAM = a.SORLCUR_PROGRAM
join stvADMT on stvADMT_code = NVL (a.sorlcur_ADMT_CODE,'RE')
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
 And a.SORLCUR_PROGRAM = a1.SORLCUR_PROGRAM
 And a.SORLCUR_TERM_CODE_CTLG = a1.SORLCUR_TERM_CODE_CTLG )
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
 from tztprog_all
 where 1= 1
 --CAMPUS||nivel = 'ULTLI'
 --and fecha_mov is null

 ) loop

 If c.fecha_inicio < '04/03/2017' and c.campus != 'UTLLI' then

 Begin
 Update tztprog_all
 set FECHA_MOV = '04/03/2017'
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 ElsIf c.fecha_inicio >= '04/03/2017' and c.fecha_mov is null then

 Begin
 Update tztprog_all
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

 Update tztprog_all
 set FECHA_MOV = '03/04/2017'
 Where FECHA_MOV is null;
 Commit;


 ---- Se actualiza la fecha de la primera inscripcion ----------


 begin


 for c in (
 select *
 from tztprog_all
 where 1 = 1
 -- and rownum <= 50
 )loop



 Begin


 Update tztprog_all
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


 Begin


 For c in (

 select count(*), matricula, PROGRAMA, ESTATUS
 from tztprog_all
 where 1= 1
 -- And matricula = '010001108'
 And ESTATUS = 'MA'
 group by matricula,PROGRAMA, ESTATUS
 having count(*) > 1

 ) Loop

 Begin
 update tztprog_all a
 set a.estatus = 'BT',
 a.estatus_d = 'BAJA TEMPORAL',
 a.SGBSTDN_STYP_CODE = 'D'
 Where a.matricula = c.matricula
 And a.programa = c.programa
 And a.ESTATUS = c.ESTATUS
 And a.sp = (select min (a1.sp)
 from tztprog_all a1
 Where a.matricula = a1.matricula
 And a.programa = a1.programa
 And a.ESTATUS = a1.ESTATUS);
 Exception
 When Others then
 null;
 End;


 End Loop;
 Commit;
 End;




 Begin


 For c in (

 select count(*), matricula, PROGRAMA, ESTATUS
 from tztprog_all
 where 1= 1
 -- And matricula = '010001108'
 And ESTATUS = 'EG'
 group by matricula,PROGRAMA, ESTATUS
 having count(*) > 1

 ) Loop

 Begin
 update tztprog_all a
 set a.estatus = 'BT',
 a.estatus_d = 'BAJA TEMPORAL',
 a.SGBSTDN_STYP_CODE = 'D'
 Where a.matricula = c.matricula
 And a.programa = c.programa
 And a.ESTATUS = c.ESTATUS
 And a.sp = (select min (a1.sp)
 from tztprog_all a1
 Where a.matricula = a1.matricula
 And a.programa = a1.programa
 And a.ESTATUS = a1.ESTATUS);
 Exception
 When Others then
 null;
 End;


 End Loop;
 Commit;
 End;




 end;

---------- Pone el tipoo de estatus desercion para todos las bajas

Begin

    For cx in (

                    select *
                    from tztprog_all
                    where 1= 1
                    and estatus in ('BT','BD','CM','CV','BI')
                    and SGBSTDN_STYP_CODE !='D'


     ) loop

        Begin
            Update tztprog_all
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


 end p_cargatztprog_all;

 Procedure p_tutoria is

 Begin

 begin
 Delete szttuto;
 Commit;

 Exception
 when others then
 null;
 End;


 Begin

 Insert into szttuto
 with materia as (
 select distinct sfrstcr_pidm pidm, trunc (SSBSECT_PTRM_START_DATE) Fecha_Inicio, SSBSECT_PTRM_END_DATE Fecha_Termino, SFRSTCR_PTRM_CODE Pperiodo
 from sfrstcr, ssbsect
 Where SFRSTCR_TERM_CODE = SSBSECT_TERM_CODE
 And SFRSTCR_CRN = SSBSECT_CRN
 And SFRSTCR_RSTS_CODE ='RE'
 )
 select
 a.campus,
 a.nivel,
 a.matricula,
 REPLACE (TRANSLATE (b.SPRIDEN_LAST_NAME, 'Ã¡Ã©Ã­Ã³ÃºÃÃ?ÃÃ?Ã?', 'aeiouAEIOU'),'/', ' ') Apellidos,
 b.SPRIDEN_FIRST_NAME Nombre,
 a.fecha_inicio,
 c.Fecha_Termino ,
 a.estatus_d Estatus,
 nvl (a.SGBSTDN_STYP_CODE,'C') Tipo_Alumno,
 case
 When substr (pkg_utilerias.f_calcula_rate(a.pidm, a.programa),length (pkg_utilerias.f_calcula_rate(a.pidm, a.programa))-1,1) = 'A' then
 '15'
 When substr (pkg_utilerias.f_calcula_rate(a.pidm, a.programa),length (pkg_utilerias.f_calcula_rate(a.pidm, a.programa))-1,1) = 'B' then
 '30'
 End Pago,
 c.pperiodo
 from tztprog a
 join spriden b on b.spriden_pidm = a.pidm
 left join materia c on c.pidm = a.pidm and c.Fecha_Inicio = a.fecha_inicio
 where 1= 1
 And a.estatus = 'MA'
 And a.sp = (select max (a1.sp)
 from tztprog a1
 Where a.matricula = a1.matricula
 And a.estatus = a1.estatus
 )
 order by 1, 2, 3;
 Commit;

 Exception
 When Others then
 null;

 End;

 Commit;

 End;


Procedure sp_rep_hiac ( ppmatricula varchar2 ,pprograma varchar2) is

 v_cur SYS_REFCURSOR;
 -------------------
 matricula spriden.spriden_id%TYPE;
 nombre VARCHAR2 (200);
 Programa VARCHAR2 (150);
 estatus VARCHAR2 (60);
 per varchar2(5); -- avance1.per%type;
 area avance1.area%TYPE;
 nombre_area avance1.nombre_area%TYPE;
 materia VARCHAR2 (60);
 nombre_mat VARCHAR2 (80);
 califica avance1.calif%TYPE;
 ord NUMBER; -- avance1.per%type;
 tipo VARCHAR2 (80);
 n_area VARCHAR2 (90);
 hoja NUMBER; --avance1.per%type;
 aprobadas_curr NUMBER;
 no_aprobadas_curr NUMBER;
 curso_curr NUMBER;
 por_cursar_curr NUMBER;
 total_curr NUMBER;
 avance_curr varchar2(5);
 aprobadas_tall NUMBER;
 pperiodo varchar2(12);
 pletra varchar2(6);
 ppromedio varchar2(6);
 pcreditos varchar2(6); ----18
 pevaluacion varchar2(14);
 no_aprobadas varchar2(1);
 pcuenta number:= 0;
 verror varchar2(800);
 PDESC varchar2(100);
 PVALOR varchar2(1000);
 PPIDM number:=0;
 v_avance number:=0;
 v_promedio number:=0;

begin
NULL;
 matricula := '';
 nombre := '';
 Programa := '';
 estatus := '';
 per := '';
 area := '';
 nombre_area := '';
 materia := '';
 nombre_mat := '';
 califica := '';
 avance_curr := '';
 no_aprobadas := '';
 pperiodo := '';
 pletra := '';
 ppromedio := '';
 pcreditos := '';
 pevaluacion := '';

begin
select fget_pidm(ppmatricula)
into PPIDM
from dual;
exception when others then
null;
--PPIDM
end;

begin
select pkg_datos_academicos.avance1(PPIDM , pprograma)
into v_avance
from dual;
exception when others then
null;
end;


begin
select BANINST1.pkg_datos_academicos.promedio1(PPIDM, pprograma)
into v_promedio
from dual;
exception when others then
null;
end;

dbms_output.put_line('El pidm es: '|| PPIDM );

DELETE SZTAVCU ZT
WHERE ZT.SZTAVCU_PIDM = PPIDM;
COMMIT;



 -- Call the function
 v_cur := baninst1.pkg_dashboard_alumno.f_dashboard_hiac_out(pidm =>PPIDM ,
 prog => PPROGRAMA );
 -- v_cur := pkg_dashboard_alumno.f_dashboard_avcu_out(PPIDM , PPROGRAMA ,'vvic' ) ;
dbms_output.put_line('despues de mandar el proceso dashboar_alumno:: '||ppidm ||'-'||PPROGRAMA );

 LOOP
 FETCH v_cur
 INTO nombre, --1
 matricula, --2
 Programa, --3
 per, --7
-- area, --8
 nombre_area, --9
 materia, --10
 nombre_mat, --11
 pperiodo, --12
 califica, ---13
 pletra, --14
 avance_curr, --15
 ppromedio , -- 16
 no_aprobadas, ----17
 pcreditos, ----18
 pevaluacion ---19
 ;

 EXIT WHEN v_cur%NOTFOUND;
 dbms_output.put_line( 'variables'|| matricula||'-'||
 nombre||'-'||
 Programa||'-'||
 estatus||'-'||
 per||'-'||
 area||'-'||
 nombre_area||'-'||
 materia||'-'||
 nombre_mat||'-'||
 pperiodo||'-'||
 califica||'-'||
 pletra||'-'||
 avance_curr||'-'||
 ppromedio||'-'||
 no_aprobadas||'-'||
 pcreditos||'-'||
 pevaluacion ); ---19


 BEGIN

 select ZSTPARA_PARAM_DESC,ZSTPARA_PARAM_VALOR
 INTO PDESC, PVALOR
 from zstpara
 where ZSTPARA_MAPA_ID like('%HISTORIAL_ACADE%');

 EXCEPTION WHEN OTHERS THEN
 PDESC :='';
 PVALOR:='';
 DBMS_OUTPUT.put_line ('salida_ZSTPARA ' ||verror );
 END;

 if substr(nombre_area,1,2) in ('11','12') then
 nombre_area:= substr(nombre_area,1,2)||'.CUATRIMESTRE';
 DBMS_OUTPUT.put_line ('salida_CUATRIMESTRE:: ' ||nombre_area );
 end if;


 begin
 ---------------AQUI VA EL INSERT A LA TABLA
 INSERT INTO SZTAVCU( SZTAVCU_PIDM,
 SZTAVCU_MATRICULA,
 SZTAVCU_NOMBRE,
 SZTAVCU_PROGRAMA,
 SZTAVCU_PROGRAMA_DESC,
 SZTAVCU_ESTATUS,
 SZTAVCU_PER,
 SZTAVCU_AREA,
 SZTAVCU_NOMBRE_AREA,
 SZTAVCU_MATERIA,
 SZTAVCU_NOMBRE_MAT,
 SZTAVCU_PERIODO,
 SZTAVCU_CALIF,
 SZTAVCU_LETRA,
 SZTAVCU_AVANCE_CURR,
 SZTAVCU_PROMEDIO,
 SZTAVCU_NO_APROBADA,
 SZTAVCU_CREDITOS,
 SZTAVCU_EVALUACION,
 SZTAVCU_ACTIVITY_DATE,
 SZTAVCU_FIRMANTE,
 SZTAVCU_TEXTO,
 SZTAVCU_USER
 )
 VALUES( ppidm,
 matricula, --1
 nombre, --2
 pprograma,
 Programa, --3
 null,---NA
 per, --7
 to_number(trim(per)), --8
 replace(nombre_area,' ',''), --9
 --nombre_area, --' ',''), --9
 materia, --10
 nombre_mat, --11
 pperiodo, --12
 califica, ---13
 pletra, --14
 v_avance, --15
 v_promedio, -- 16
 no_aprobadas, ----17
 pcreditos, ----18
 pevaluacion, ---19
 SYSDATE,
 PDESC,
 PVALOR,
 USER
 );

 pcuenta := sql%rowcount;
 null;
 commit;
 EXCEPTION WHEN OTHERS THEN
 verror := SQLERRM;
 DBMS_OUTPUT.put_line ('salida1 ' ||verror );
 -- raise_application_error (-20002, 'ERROR en genera HIAC ' || verror);
 end;

 EXIT WHEN v_cur%NOTFOUND;
 END LOOP;


 IF V_CUR%ISOPEN THEN
 CLOSE v_cur;
 END IF;

 EXCEPTION
 WHEN OTHERS
 THEN
 DBMS_OUTPUT.put_line ('salida2 ' || SQLERRM);
 -- raise_application_error (-20002, 'ERROR en genera AVCU ' || SQLERRM);
 NULL;

end sp_rep_hiac;

FUNCTION f_alumnos_out (p_matricula in varchar2) RETURN PKG_REPORTES.cursor_out
 AS
 c_out PKG_REPORTES.cursor_out;

 BEGIN
 open c_out
 FOR

select substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1) ||' '|| substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150) Apellidos ,
 SPRIDEN_FIRST_NAME Nombre,
 a.matricula,
 STVLEVL_DESC Nivel,
 a.programa||' '||a.nombre carrera,
 SZVCAMP_DESC Campus,
 PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(a.pidm) Saldo,
  STVSTST_DESC estatus,
 STVADMT_DESC Tipo_Ingreso,
 nvl (c.SZTHITA_AVANCE,0) Porcentaje_Avance,
 nvl (c.SZTHITA_APROB,0) Materias_Aprobadas,
 nvl (c.SZTHITA_REPROB,0) Materias_Reprobadas,
 nvl (c.SZTHITA_PROMEDIO,0) Promedio,
 PKG_SERV_SIU.F_PRECIO_MATERIA_NIVE ( a.pidm, a.nivel, a.programa) Costo_Nivelacion,
 pkg_utilerias.f_correo(a.pidm, 'PRIN') Correo,
 pkg_utilerias.f_genero(a.pidm) Genero,
 pkg_utilerias.f_nacionalidad(a.pidm) Nacionalidad,
 pkg_utilerias.f_nss(a.pidm) NSS,
 pkg_utilerias.f_etiqueta(a.pidm, 'CURP') Curp,
 pkg_utilerias.f_fecha_nac(a.pidm) Fecha_Nac,
 pkg_utilerias.f_ocupacion(a.pidm) Ocupacion,
 pkg_utilerias.f_nombre_empresa(a.pidm) Nombre_Empresa,
 pkg_utilerias.f_celular(a.pidm,'CELU') Tel_Celular,
 pkg_utilerias.f_celular(a.pidm,'RESI') Tel_Casa,
 pkg_utilerias.f_celular(a.pidm,'OFIC') Tel_Oficina,
 pkg_utilerias.f_celular(a.pidm,'ALTE') Tel_Alterno,
 nvl (pkg_utilerias.f_fecha_primera(a.pidm, a.sp),
 pkg_utilerias.f_fecha_primera_sin_estatus(a.pidm, a.sp)) Fecha_Inscripcion,
 pkg_utilerias.f_periodo_inscripcion(a.pidm, a.sp) Periodo_Inscripcion,
 ----------------------------------------------------------------------------
 pkg_utilerias.f_edad(a.pidm) Edad,
 pkg_utilerias.f_tipo_puesto(a.pidm) Tipo_Puesto,
 pkg_utilerias.f_Salario_Mensual(a.pidm) Salario_Mensual,
 pkg_utilerias.f_esc_procedencia(a.pidm) Escuela_Procedencia,
 upper (pkg_utilerias.f_paquete_programa(a.pidm, a.programa)) Paquete_Venta,
 pkg_utilerias.f_moneda(a.pidm) Moneda,
 pkg_utilerias.f_servicio_social(a.pidm)Servicio_Social,
 FECHA_MOV  Fecha_Egreso,
 pkg_utilerias.f_fecha_ultima(a.pidm, a.sp) Ultima_Materia,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CTBO') CTBO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CPLO') CPLO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'FT6O') FT6O,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'IDED') IDED,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'TECD') TECD,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'ACNO') ACNO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'DICD') DICD,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'DICO') DICO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'REVD') REVD,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'REVO') REVO,
 ---------------------------------------------------------------------------------------------------------
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CTLO') CTLO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CEMO') CEMO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CEPD') CEPD,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'FESD') FESD,
 ---------------------------------------------------------------------------------------------------------
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CTMO') CTMO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CEGD') CEGD,
 -------------------------------------------------
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CETD') CETD,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CETO') CETO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'TIUD') TIUD,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'TIUO') TIUO,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CMTD') CMTD,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'GRMD') GRMD,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'GRMO') GRMO
 from tztprog_all a
 join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
 left join SZTHITA c on c.SZTHITA_PIDM = a.pidm and c.SZTHITA_PROG = a.PROGRAMA
 join stvlevl on STVLEVL_CODE = a.nivel
 join szvcamp on SZVCAMP_CAMP_CODE = a.campus
 join stvSTST on STVSTST_CODE = a.estatus
 join stvADMT on STVADMT_CODE = a.TIPO_INGRESO
 where 1= 1
 And a.estatus not in ('CV')
 And a.sp = (select max (a1.sp)
 from tztprog_all a1
 Where a.pidm = a1.pidm
 And a.PROGRAMA = a1.PROGRAMA
 )
 And a.matricula = P_matricula
  Order by 3 desc;

 RETURN (c_out);

 END f_alumnos_out;


FUNCTION f_alumnos_pago_out (p_matricula in varchar2) RETURN PKG_REPORTES.cursor_out_pago
 AS
 c_out_pago PKG_REPORTES.cursor_out_pago;

 BEGIN
 open c_out_pago
                     FOR
                    select distinct SZTPAGO_MEDIO
                    from SZTPAGO, szvcamp, tztprog
                    where SZTPAGO_CAMP_CODE = SZVCAMP_CAMP_CODE
                    And CAMPUS = SZTPAGO_CAMP_CODE
                    And matricula = p_matricula;


                     RETURN (c_out_pago);

 END f_alumnos_pago_out;



FUNCTION f_alumnos_escol_out (p_matricula in varchar2) RETURN PKG_REPORTES.cursor_out
 AS
 c_out PKG_REPORTES.cursor_out;

 BEGIN
 open c_out
 FOR

select substr (b.SPRIDEN_LAST_NAME, 1, INSTR(b.SPRIDEN_LAST_NAME,'/')-1) ||' '|| substr (b.SPRIDEN_LAST_NAME, INSTR(b.SPRIDEN_LAST_NAME,'/')+1,150) Apellidos ,
 SPRIDEN_FIRST_NAME Nombre,
 a.matricula,
 STVLEVL_DESC Nivel,
 a.programa||' '||a.nombre carrera,
 SZVCAMP_DESC Campus,
 PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(a.pidm) Saldo,
  STVSTST_DESC estatus,
 STVADMT_DESC Tipo_Ingreso,
 nvl (c.SZTHITA_AVANCE,0) Porcentaje_Avance,
 nvl (c.SZTHITA_APROB,0) Materias_Aprobadas,
 nvl (c.SZTHITA_REPROB,0) Materias_Reprobadas,
 nvl (c.SZTHITA_PROMEDIO,0) Promedio,
 PKG_SERV_SIU.F_PRECIO_MATERIA_NIVE ( a.pidm, a.nivel, a.programa) Costo_Nivelacion,
 pkg_utilerias.f_correo(a.pidm, 'PRIN') Correo,
 pkg_utilerias.f_genero(a.pidm) Genero,
 pkg_utilerias.f_nacionalidad(a.pidm) Nacionalidad,
 pkg_utilerias.f_nss(a.pidm) NSS,
 pkg_utilerias.f_etiqueta(a.pidm, 'CURP') Curp,
 pkg_utilerias.f_fecha_nac(a.pidm) Fecha_Nac,
 pkg_utilerias.f_ocupacion(a.pidm) Ocupacion,
 pkg_utilerias.f_nombre_empresa(a.pidm) Nombre_Empresa,
 pkg_utilerias.f_celular(a.pidm,'CELU') Tel_Celular,
 pkg_utilerias.f_celular(a.pidm,'RESI') Tel_Casa,
 pkg_utilerias.f_celular(a.pidm,'OFIC') Tel_Oficina,
 pkg_utilerias.f_celular(a.pidm,'ALTE') Tel_Alterno,
 nvl (pkg_utilerias.f_fecha_primera(a.pidm, a.sp),
 pkg_utilerias.f_fecha_primera_sin_estatus(a.pidm, a.sp)) Fecha_Inscripcion,
 pkg_utilerias.f_periodo_inscripcion(a.pidm, a.sp) Periodo_Inscripcion,
 ----------------------------------------------------------------------------
 pkg_utilerias.f_edad(a.pidm) Edad,
 pkg_utilerias.f_tipo_puesto(a.pidm) Tipo_Puesto,
 pkg_utilerias.f_Salario_Mensual(a.pidm) Salario_Mensual,
 pkg_utilerias.f_esc_procedencia(a.pidm) Escuela_Procedencia,
 upper (pkg_utilerias.f_paquete_programa(a.pidm, a.programa)) Paquete_Venta,
 pkg_utilerias.f_moneda(a.pidm) Moneda,
 pkg_utilerias.f_servicio_social(a.pidm)Servicio_Social,
 --FECHA_MOV  Fecha_Egreso,
 --pkg_utilerias.f_fecha_ultima(a.pidm, a.sp) Ultima_Materia,
 pkg_utilerias.f_fecha_egreso(a.pidm, a.sp)Fecha_Egreso,
 pkg_utilerias.f_fecha_ultima_miperfil(a.pidm, a.sp) Ultima_Materia,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CTBO') Cert_Total_Bach_Or,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CPLO') Cert_Par_Lic_Or,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'FT6O') Fot_Tit_6_M,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'IDED') Doc_Iden_DIg,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'TECD') Term_Cond,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'ACNO') Acta_Nac_Or,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'DICD') Dict_SEP_Dig,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'DICO') Dict_SEP,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'REVD') Reval_Dig,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'REVO') Reval_OR,
 ---------------------------------------------------------------------------------------------------------
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CTLO') Cert_Tot_Lic_Or,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CEMO') Cert_Par_MAE_Or,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CEPD') Ced_Prof_Dig,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'FESD') Foto_est_Sol_Dig,
 ---------------------------------------------------------------------------------------------------------
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CTMO') Cert_Tot_Mae_Or,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CEGD') Ced_Grad_Dig,
  pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CETD') Cert_Tol_Utl_Dig,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CETO') Cert_Tol_Utl_Ori,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'TIUD') Tit_Utl_Dig,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'TIUO') Tit_Utl_Ori,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'CMTD') Cert_Tol_Mae_Dig,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'GRMD') Grad_Utl_Dig,
 pkg_utilerias.f_documento_nivel(a.pidm, a.nivel, 'GRMO') Grad_Utl_Org
 from tztprog a
 join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
 left join SZTHITA c on c.SZTHITA_PIDM = a.pidm and c.SZTHITA_PROG = a.PROGRAMA
 join stvlevl on STVLEVL_CODE = a.nivel
 join szvcamp on SZVCAMP_CAMP_CODE = a.campus
 join stvSTST on STVSTST_CODE = a.estatus
 join stvADMT on STVADMT_CODE = a.TIPO_INGRESO
 where 1= 1
 And a.estatus not in ('CV', 'CP')
 And a.sp = (select max (a1.sp)
 from tztprog_all a1
 Where a.pidm = a1.pidm
 And a.PROGRAMA = a1.PROGRAMA
 )
 And a.matricula = p_matricula
 Order by 3 desc;

 RETURN (c_out);

 END f_alumnos_escol_out;

FUNCTION f_alumnosa_out (p_pidm in number) RETURN PKG_REPORTES.cursor_aluout
           AS
                c_aluout PKG_REPORTES.cursor_aluout;

            BEGIN
                          open c_aluout
                            FOR
                                          with mayor as (
                                                      select distinct SORLFOS_PIDM, SORLFOS_LCUR_SEQNO, SORLFOS_SEQNO, SORLFOS_LFST_CODE, SORLFOS_MAJR_CODE, STVMAJR_NAME_LARGE, s.sorlcur_program
                                                                                   from sorlfos, stvmajr, sorlcur s
                                                                                   where SORLFOS_LFST_CODE = 'MAJOR'
                                                                                   and STVMAJR_CODE = SORLFOS_MAJR_CODE
                                                                                    and s.sorlcur_lmod_code='LEARNER'
                                                                                    and s.SORLCUR_CACT_CODE  != 'CHANGE'
                                                                                    and s.SORLCUR_PIDM    = SORLFOS_PIDM
                                                                                    and s.SORLCUR_SEQNO = SORLFOS_LCUR_SEQNO
                                                                                    and s.sorlcur_pidm= p_pidm
                                                                                    and s.sorlcur_seqno in (select max(sorlcur_seqno) from sorlcur ss
                                                                                                                   where  s.sorlcur_pidm=ss.sorlcur_pidm
                                                                                                                   and s.sorlcur_program=ss.sorlcur_program
                                                                                                                   and s.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                                                                                   )
                                                           ),
                                        menor1 as (
                                                           select distinct a.SORLFOS_PIDM, a.SORLFOS_LCUR_SEQNO, a.SORLFOS_SEQNO, a.SORLFOS_LFST_CODE, a.SORLFOS_MAJR_CODE, STVMAJR_NAME_LARGE, s.sorlcur_program
                                                                                   from sorlfos a, stvmajr, sorlcur s
                                                                                   where a.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                   and STVMAJR_CODE = a.SORLFOS_MAJR_CODE
                                                                                    and s.sorlcur_lmod_code='LEARNER'
                                                                                    and s.SORLCUR_CACT_CODE  != 'CHANGE'
                                                                                    and s.sorlcur_pidm= p_pidm
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
                                                           select distinct c.SORLFOS_PIDM, c.SORLFOS_LCUR_SEQNO, c.SORLFOS_SEQNO, c.SORLFOS_LFST_CODE, c.SORLFOS_MAJR_CODE, STVMAJR_NAME_LARGE, p.sorlcur_program
                                                                                   from sorlfos c, stvmajr, sorlcur p
                                                                                   where c.SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                   and STVMAJR_CODE = c.SORLFOS_MAJR_CODE
                                                                                    and  p.sorlcur_pidm= p_pidm
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
                                                                                                                                               and  n.sorlcur_pidm=p_pidm
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
                                                           select       sgbstdn_pidm pidm,
                                                                           sgbstdn_stst_code Estatus_final,
                                                                           stvstst_desc Estatus,
                                                                           sgbstdn_program_1 Clave_Carrera,
                                                                           sgbstdn_program_1||'|'||sztdtec_programa_comp ||'|'||(select   SORLCUR_TERM_CODE_CTLG  from sorlcur s   where s.sorlcur_pidm= p_pidm
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
                                                                         a.STVMAJR_NAME_LARGE Descripcion_Mayor,
                                                                         b.SORLFOS_MAJR_CODE Area_Menor_1,
                                                                         b.STVMAJR_NAME_LARGE Descripcion_Salida_1,
                                                                         c.SORLFOS_MAJR_CODE Area_Menor_2,
                                                                         c.STVMAJR_NAME_LARGE Descripcion_Salida_2
                                                            from sgbstdn x, sztdtec, stvstst, stvstyp , mayor a, menor1 b, menor2 c
                                                                        where  sgbstdn_pidm = p_pidm
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
                                                            select distinct s.sorlcur_pidm pidm,
                                                                     null Estatus_final,
                                                                     decode(s.sorlcur_cact_code,'ACTIVE','ACTIVO', 'INACTIVE','INACTIVO', 'CHANGE', 'CAMBIO PROGRAMA') Estatus,
                                                                     s.sorlcur_program Clave_Carrera,
                                                                     s.sorlcur_program||' '||sztdtec_programa_comp||'|'||SORLCUR_TERM_CODE_CTLG Carrera,    -- cambio para agregar periodo catalogo
                                                                     s.sorlcur_camp_code Campus,
                                                                     smrprle_levl_code nivel,
                                                                     null  tipo_inscripcion, '  ' inscripcion_desc,
                                                                     a.SORLFOS_MAJR_CODE Area_Mayor,
                                                                     a.STVMAJR_NAME_LARGE Descripcion_Mayor,
                                                                     b.SORLFOS_MAJR_CODE Area_Menor_1,
                                                                     b.STVMAJR_NAME_LARGE Descripcion_Salida_1,
                                                                     c.SORLFOS_MAJR_CODE Area_Menor_2,
                                                                     c.STVMAJR_NAME_LARGE Descripcion_Salida_2
                                                            from sorlcur s,  sztdtec, smrprle, mayor a, menor1 b, menor2 c
                                                                        where s.sorlcur_pidm= p_pidm
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

                        RETURN (c_aluout);

            END f_alumnosa_out;

procedure p_niri as





Begin


         Begin
                 EXECUTE IMMEDIATE 'TRUNCATE TABLE SATURN.SZRNIRI';
                COMMIT;
         Exception
         When Others then
            null;
         End;



                for cx1 in (

                SELECT DISTINCT matricula,
                  Estudiante,
                  Estatus_Code,
                  Estatus,
                  Campus,
                  Nivel,
                  Programa,
                  FECHA_ACTIVIDAD,
                  fechainicio,
                  TIPO,
                  Tipo_Ingreso,
                  fecha_registro,
                  clave_canal,
                  canal_final,
                  fecha_nac,
                  correo,
                   Etiqueta,
                  pago,
                  saldo,
                  decision,
                  Usuario_Decision,
                  TRUNC (Fecha_Decision) Fecha_Decision,
                  TRUNC (Fecha_Inscripcion) Fecha_Inscripcion,
                  Periodo_Matriculacion,
                  Estatus_Solicitud,
                  COMENTARIO,
                   FECHA_CREACION,
                  parte
    FROM (WITH decision1
                  AS (
                    SELECT distinct
                    p.saradap_pidm PIDM,
                    p.saradap_program_1 PROGRAMA,
                    d.sarappd_apdc_code decision,
                    d.sarappd_user usuario,
                    d.sarappd_activity_date fecha_des,
                    p.saradap_term_code_entry periodo,
                    p.saradap_curr_rule_1 currule,
                    d.sarappd_appl_no
                    FROM sarappd d,saradap p
                    WHERE 1=1
                    AND d.sarappd_pidm=p.saradap_pidm
                    AND d.sarappd_appl_no=p.saradap_appl_no
                    and d.sarappd_term_code_entry=p.saradap_term_code_entry
                    And p.SARADAP_APST_CODE in ('A', 'R')
                    AND d.sarappd_seq_no = (select max(pp.sarappd_seq_no)
                                                FROM sarappd pp
                                                WHERE d.sarappd_pidm=pp.sarappd_pidm
                                                and d.sarappd_term_code_entry =pp.sarappd_term_code_entry
                                                And d.SARAPPD_APPL_NO = pp.SARAPPD_APPL_NO)
                    and d.sarappd_appl_no = (select max(ppl.sarappd_appl_no)
                                                FROM sarappd ppl
                                                WHERE d.sarappd_pidm=ppl.sarappd_pidm
                                                and d.sarappd_term_code_entry =ppl.sarappd_term_code_entry
                                                And d.SARAPPD_APPL_NO = ppl.SARAPPD_APPL_NO
                     --And p.SARADAP_APPL_NO = ppl.SARAPPD_SEQ_NO
                     )
                    )
          SELECT DISTINCT
                 b.spriden_id Matricula,
                 b.spriden_first_name || ' ' || spriden_last_name Estudiante,
                 a.ESTATUS Estatus_Code,
                 a.ESTATUS_D Estatus,
                 a.CAMPUS Campus,
                 a.NIVEL Nivel,
                 a.PROGRAMA || ' ' || a.NOMBRE Programa,
                 a.FECHA_MOV FECHA_ACTIVIDAD,
                 a.FECHA_INICIO fechainicio,
                 STVSTYP_DESC TIPO,
                 a.TIPO_INGRESO_DESC Tipo_Ingreso,
                 a.FECHA_MOV fecha_registro,
                 pkg_utilerias.f_canal_venta(a.pidm,'CANF')    clave_canal,
                 NVL (pkg_utilerias.f_canal_venta(a.pidm,'COES'), 'COMENTARIO') COMENTARIO,
                 NVL (geo.STVGEOD_DESC, 'CALL CENTER PROFESIONAL') canal_final,
                 SPBPERS_BIRTH_DATE fecha_nac,
                 pkg_utilerias.f_correo(a.pidm,'PRIN')correo,
                 'Validado' pago,
                 des.decision decision,
                 des.usuario usuario_decision,
                 des.fecha_des fecha_Decision,
                 a.FECHA_MOV Fecha_Inscripcion,
                 a.MATRICULACION Periodo_Matriculacion,
                 (SELECT SUM (TBRACCD_BALANCE)
                    FROM TBRACCD
                   WHERE TBRACCD_PIDM = a.pidm)
                    saldo,
                 NULL Estatus_Solicitud,
                 SPRADDR_STREET_LINE1 Direccion,
                 SPRADDR_STREET_LINE3 Colonia,
                 STVCNTY_DESC Localidad,
                 STVSTAT_DESC Estado,
                 STVNATN_NATION Pais,
                 CASE
                    WHEN GORADID_ADID_CODE = 'INBE' THEN 'INBEC'
                    WHEN GORADID_ADID_CODE = 'NOMR' THEN 'NO MOLESTAR'
                    WHEN GORADID_ADID_CODE = 'ESCA' THEN 'ESCALONADO'
                    WHEN GORADID_ADID_CODE = 'INBC' THEN 'ALUMNO INBEC'
                 WHEN GORADID_ADID_CODE = 'FREE' THEN 'FREEMIUM'
                    ELSE NULL
                 END
                    AS Etiqueta,
                 STVMRTL_DESC Estado_Civil,
                 CASE
                    WHEN SPBPERS_SEX = 'F' THEN 'Femenino'
                    WHEN SPBPERS_SEX = 'M' THEN 'Masculino'
                    ELSE 'No_Disponible'
                 END
                    AS Sexo,
                    pkg_utilerias.f_Salario_Mensual( a.pidm)  Ingreso_Mensual,
                 (SELECT DISTINCT MAX (SARACMT_COMMENT_TEXT)
                    FROM SARACMT
                   WHERE SARACMT_PIDM = SPRIDEN_PIDM
                         AND SARACMT_ORIG_CODE IN ('EGTL', 'EGEX', 'EGRE'))
                    Estatus_egreso,
                 pkg_utilerias.f_bienvenida_obs(a.pidm, a.campus, a.nivel) Observaciones,
                 pkg_utilerias.f_bienvenida_curso(a.pidm, a.campus, a.nivel)  CURSO,
                 pkg_utilerias.f_bienvenida_fecha(a.pidm, a.campus, a.nivel)  FECHA_ENROLAMIENTO,
                 TRUNC(b.SPRIDEN_CREATE_DATE) FECHA_CREACION,
                 'parte1' parte
            FROM MIGRA.TZTPROG_DEV a--tztprog a
                 JOIN spriden b
                    ON b.spriden_pidm = a.pidm AND b.spriden_change_ind IS NULL
                 JOIN decision1 des
                    ON des.pidm = a.pidm
                 LEFT OUTER JOIN STVGEOD geo
                    ON LPAD (TRIM (SUBSTR (pkg_utilerias.f_canal_venta(a.pidm,'CANF') , 1, 2)),2,'0') = geo.STVGEOD_CODE
                 JOIN STVSTYP
                    ON a.SGBSTDN_STYP_CODE = STVSTYP_CODE
                 LEFT OUTER JOIN SPBPERS
                    ON spbpers_pidm = spriden_pidm
                 LEFT OUTER JOIN STVMRTL
                    ON SPBPERS_MRTL_CODE = STVMRTL_CODE
                 LEFT OUTER JOIN SPRADDR
                    ON SPRADDR_pidm = spriden_pidm AND SPRADDR_ATYP_CODE = 'RE'
                 LEFT JOIN STVCNTY
                    ON SPRADDR_CNTY_CODE = STVCNTY_CODE
                 LEFT JOIN STVSTAT
                    ON SPRADDR_STAT_CODE = STVSTAT_CODE
                 LEFT JOIN STVNATN
                    ON SPRADDR_NATN_CODE = STVNATN_CODE
                 LEFT OUTER JOIN GORADID
                    ON a.pidm = GORADID_PIDM
                       AND GORADID_ADID_CODE IN ('INBE', 'NOMR','ESCA', 'INBC', 'FREE')
           WHERE 1 = 1
--                  And a.pidm = cx.pidm
--                  And a.campus = cx.campus
--                  And a.nivel  = cx.nivel
      UNION
          SELECT DISTINCT
                 b.spriden_id Matricula,
                 b.spriden_first_name || ' ' || b.spriden_last_name Estudiante,
                 NULL Estatus_Code,
                 NULL Estatus,
                 SZVCAMP_CAMP_CODE Campus,
                 a.SORLCUR_LEVL_CODE Nivel,
                 a.SORLCUR_PROGRAM || ' ' || c.SMRPRLE_PROGRAM_DESC Programa,
                 a.SORLCUR_ACTIVITY_DATE FECHA_ACTIVIDAD,
                 a.SORLCUR_START_DATE fechainicio,
                 'NUEVO INGRESO' TIPO,
                 STVADMT_DESC Tipo_Ingreso,
                 s.saradap_appl_date fecha_registro,
                 pkg_utilerias.f_canal_venta(a.sorlcur_pidm,'CANF')    clave_canal,
                 NVL (pkg_utilerias.f_canal_venta(a.sorlcur_pidm,'COES'), 'COMENTARIO') COMENTARIO,
                 NVL (geo.STVGEOD_DESC, 'CALL CENTER PROFESIONAL') canal_final,
                 spbpers_birth_date fecha_nac,
                 pkg_utilerias.f_correo(a.sorlcur_pidm,'PRIN')correo,
                 sarchkl_ckst_code pago,
                 pkg_utilerias.f_sarappd_decision(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no) decision,
                 pkg_utilerias.f_sarappd_user_decision(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no) usuario_decision,
                 pkg_utilerias.f_sarappd_fecha_decision(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no) fecha_Decision,
                 pkg_utilerias.f_sarappd_fecha_decision(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no) Fecha_Inscripcion,
                 pkg_utilerias.f_sarappd_periodo_matric(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no)Periodo_Matriculacion,
                 (SELECT SUM (TBRACCD_BALANCE)
                    FROM TBRACCD
                   WHERE TBRACCD_PIDM = sorlcur_pidm)
                    saldo,
                 NULL Estatus_Solicitud,
                 SPRADDR_STREET_LINE1 Direccion,
                 SPRADDR_STREET_LINE3 Colonia,
                 STVCNTY_DESC Localidad,
                 STVSTAT_DESC Estado,
                 STVNATN_NATION Pais,
                 CASE
                    WHEN GORADID_ADID_CODE = 'INBE' THEN 'INBEC'
                    WHEN GORADID_ADID_CODE = 'NOMR' THEN 'NO MOLESTAR'
                    WHEN GORADID_ADID_CODE = 'ESCA' THEN 'ESCALONADO'
                    WHEN GORADID_ADID_CODE = 'INBC' THEN 'ALUMNO INBEC'
                 WHEN GORADID_ADID_CODE = 'FREE' THEN 'FREEMIUM'
                    ELSE NULL
                 END
                    AS Etiqueta,
                 STVMRTL_DESC Estado_Civil,
                 CASE
                    WHEN SPBPERS_SEX = 'F' THEN 'Femenino'
                    WHEN SPBPERS_SEX = 'M' THEN 'Masculino'
                    ELSE 'No_Disponible'
                 END
                    AS Sexo,
                    pkg_utilerias.f_Salario_Mensual( a.SORLCUR_PIDM)  Ingreso_Mensual,
                 (SELECT DISTINCT MAX (SARACMT_COMMENT_TEXT)
                    FROM SARACMT
                   WHERE SARACMT_PIDM = SPRIDEN_PIDM
                         AND SARACMT_ORIG_CODE IN ('EGTL', 'EGEX', 'EGRE'))
                    Estatus_egreso,
                 pkg_utilerias.f_bienvenida_obs(a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code) Observaciones,
                 pkg_utilerias.f_bienvenida_curso(a.sorlcur_pidm,a.sorlcur_camp_code, a.sorlcur_levl_code)  CURSO,
                 pkg_utilerias.f_bienvenida_fecha(a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code)  FECHA_ENROLAMIENTO,
                 TRUNC(b.SPRIDEN_CREATE_DATE) FECHA_CREACION,
                 'parte2' parte
            FROM sorlcur a
                 JOIN spriden b
                    ON b.spriden_pidm = a.sorlcur_pidm
                       AND b.spriden_change_ind IS NULL
                 JOIN SMRPRLE c
                    ON c.SMRPRLE_PROGRAM = A.SORLCUR_PROGRAM
                 JOIN SZVCAMP
                    ON szvcamp_camp_alt_code =
                          SUBSTR (a.sorlcur_term_code, 1, 2)
                 LEFT OUTER JOIN SARADAP s
                       ON  s.saradap_pidm = sorlcur_pidm
                       AND s.saradap_term_code_entry = a.sorlcur_term_code
                       AND s.SARADAP_PROGRAM_1 = a.sorlcur_program
                       AND s.SARADAP_APPL_NO IN  (SELECT MAX (ss.SARADAP_APPL_NO)
                                                                     FROM saradap ss
                                                                    WHERE s.saradap_pidm = ss.saradap_pidm
                                                                    AND s.saradap_program_1 = ss.saradap_program_1)
                 JOIN STVADMT ON s.SARADAP_ADMT_CODE = STVADMT_CODE
                 LEFT OUTER JOIN STVGEOD geo   ON LPAD (TRIM (SUBSTR (pkg_utilerias.f_canal_venta(a.sorlcur_pidm,'CANF') , 1, 2)),2,'0') = geo.STVGEOD_CODE
                 LEFT OUTER JOIN SPBPERS  ON spbpers_pidm = spriden_pidm
                 LEFT OUTER JOIN STVMRTL  ON SPBPERS_MRTL_CODE = STVMRTL_CODE
                 LEFT OUTER JOIN SPRADDR  ON SPRADDR_pidm = spriden_pidm AND SPRADDR_ATYP_CODE = 'RE'
                 LEFT JOIN STVCNTY  ON SPRADDR_CNTY_CODE = STVCNTY_CODE
                 LEFT JOIN STVSTAT   ON SPRADDR_STAT_CODE = STVSTAT_CODE
                 LEFT JOIN STVNATN  ON SPRADDR_NATN_CODE = STVNATN_CODE
                 LEFT OUTER JOIN GORADID
                    ON a.SORLCUR_PIDM = GORADID_PIDM
                       AND GORADID_ADID_CODE IN ('INBE', 'NOMR','ESCA', 'INBC', 'FREE')
                 LEFT OUTER JOIN SARCHKL
                    ON     sarchkl_pidm = saradap_pidm
                       AND sarchkl_term_code_entry = saradap_term_code_entry
                       AND sarchkl_appl_no = saradap_appl_no
                       AND sarchkl_admr_code = 'PAGD'
           WHERE  1=1
--                And   a.sorlcur_pidm =  cx.pidm
--                 And  a.sorlcur_camp_code = cx.campus
--                 And a.sorlcur_levl_code = cx.nivel
--                 And a.SORLCUR_CURRENT_CDE = 'Y'
--                 AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                 AND a.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                 AND a.SORLCUR_SEQNO = (SELECT MAX (SORLCUR_SEQNO)
                                                           FROM SORLCUR aa1
                                                          WHERE     a.sorlcur_pidm = aa1.sorlcur_pidm
                                                                And a.sorlcur_camp_code = aa1.sorlcur_camp_code
                                                                And a.sorlcur_levl_code = aa1.sorlcur_levl_code
                                                                AND a.SORLCUR_LMOD_CODE = aa1.SORLCUR_LMOD_CODE
                                                                AND a.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE
                                                                AND a.sorlcur_program = aa1.sorlcur_program)
                 AND a.sorlcur_pidm NOT IN  (SELECT sgbstdn_pidm
                                                               FROM sgbstdn
                                                              WHERE sgbstdn_levl_code = a.sorlcur_levl_code
                                                              And sgbstdn_program_1 =a.sorlcur_program)
          UNION                        -------------- > Bloque para reingresos
          SELECT DISTINCT
                 b.spriden_id Matricula,
                 b.spriden_first_name || ' ' || b.spriden_last_name Estudiante,
                 NULL Estatus_Code,
                 NULL Estatus,
                 SZVCAMP_CAMP_CODE Campus,
                 a.SORLCUR_LEVL_CODE Nivel,
                 a.SORLCUR_PROGRAM || ' ' || c.SMRPRLE_PROGRAM_DESC Programa,
                 a.SORLCUR_ACTIVITY_DATE FECHA_ACTIVIDAD,
                 a.SORLCUR_START_DATE fechainicio,
                 'REINGRESO' TIPO,
                 STVADMT_DESC Tipo_Ingreso,
                 s.saradap_appl_date fecha_registro,
                 pkg_utilerias.f_canal_venta_reingreso(a.sorlcur_pidm,'CANF')    clave_canal,
                 NVL (pkg_utilerias.f_canal_venta(a.sorlcur_pidm,'COES'), 'COMENTARIO') COMENTARIO,
                 NVL (geo.STVGEOD_DESC, 'CALL CENTER PROFESIONAL') canal_final,
                 spbpers_birth_date fecha_nac,
                 pkg_utilerias.f_correo(a.sorlcur_pidm,'PRIN')correo,
                 sarchkl_ckst_code pago,
                 pkg_utilerias.f_sarappd_decision(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no) decision,
                 pkg_utilerias.f_sarappd_user_decision(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no) usuario_decision,
                 pkg_utilerias.f_sarappd_fecha_decision(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no) fecha_Decision,
                 pkg_utilerias.f_sarappd_fecha_decision(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no) Fecha_Inscripcion,
                 pkg_utilerias.f_sarappd_periodo_matric(s.saradap_pidm,s.saradap_term_code_entry,s.saradap_appl_no)Periodo_Matriculacion,
                 (SELECT SUM (TBRACCD_BALANCE)
                    FROM TBRACCD
                   WHERE TBRACCD_PIDM = sorlcur_pidm)
                    saldo,
                 NULL Estatus_Solicitud,
                 SPRADDR_STREET_LINE1 Direccion,
                 SPRADDR_STREET_LINE3 Colonia,
                 STVCNTY_DESC Localidad,
                 STVSTAT_DESC Estado,
                 STVNATN_NATION Pais,
                 CASE
                    WHEN GORADID_ADID_CODE = 'INBE' THEN 'INBEC'
                    WHEN GORADID_ADID_CODE = 'NOMR' THEN 'NO MOLESTAR'
                    WHEN GORADID_ADID_CODE = 'ESCA' THEN 'ESCALONADO'
                    WHEN GORADID_ADID_CODE = 'INBC' THEN 'ALUMNO INBEC'
                 WHEN GORADID_ADID_CODE = 'FREE' THEN 'FREEMIUM'
                    ELSE NULL
                 END
                    AS Etiqueta,
                 STVMRTL_DESC Estado_Civil,
                 CASE
                    WHEN SPBPERS_SEX = 'F' THEN 'Femenino'
                    WHEN SPBPERS_SEX = 'M' THEN 'Masculino'
                    ELSE 'No_Disponible'
                 END
                    AS Sexo,
                  pkg_utilerias.f_Salario_Mensual( a.SORLCUR_PIDM)  Ingreso_Mensual,
                 (SELECT DISTINCT MAX (SARACMT_COMMENT_TEXT)
                    FROM SARACMT
                   WHERE SARACMT_PIDM = SPRIDEN_PIDM
                         AND SARACMT_ORIG_CODE IN ('EGTL', 'EGEX', 'EGRE'))
                    Estatus_egreso,
                 pkg_utilerias.f_bienvenida_obs(a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code) Observaciones,
                 pkg_utilerias.f_bienvenida_curso(a.sorlcur_pidm,a.sorlcur_camp_code, a.sorlcur_levl_code)  CURSO,
                 pkg_utilerias.f_bienvenida_fecha(a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code)  FECHA_ENROLAMIENTO,
                 TRUNC(b.SPRIDEN_CREATE_DATE) FECHA_CREACION,
                'parte3' parte
            FROM sorlcur a
                 JOIN spriden b
                    ON b.spriden_pidm = a.sorlcur_pidm
                       AND b.spriden_change_ind IS NULL
                 JOIN SMRPRLE c
                    ON c.SMRPRLE_PROGRAM = A.SORLCUR_PROGRAM
                 JOIN SZVCAMP
                    ON szvcamp_camp_alt_code =
                          SUBSTR (a.sorlcur_term_code, 1, 2)
                 JOIN SARADAP s
                    ON     saradap_pidm = sorlcur_pidm
                       AND s.saradap_term_code_entry = a.sorlcur_term_code
                       AND s.SARADAP_PROGRAM_1 = a.sorlcur_program
                       AND s.SARADAP_APPL_NO IN
                              (SELECT MAX (ss.SARADAP_APPL_NO)
                                 FROM saradap ss
                                WHERE s.saradap_pidm = ss.saradap_pidm
                                      AND s.saradap_program_1 =
                                             ss.saradap_program_1)
                 JOIN STVADMT
                    ON s.SARADAP_ADMT_CODE = STVADMT_CODE
                 LEFT OUTER JOIN STVGEOD geo
                    ON LPAD (TRIM (SUBSTR (pkg_utilerias.f_canal_venta_reingreso(a.sorlcur_pidm,'CANF') , 1, 2)),2,'0') = geo.STVGEOD_CODE
                 LEFT OUTER JOIN SPBPERS
                    ON spbpers_pidm = spriden_pidm
                 LEFT OUTER JOIN STVMRTL
                    ON SPBPERS_MRTL_CODE = STVMRTL_CODE
                 LEFT OUTER JOIN SPRADDR
                    ON SPRADDR_pidm = spriden_pidm AND SPRADDR_ATYP_CODE = 'RE'
                 LEFT JOIN STVCNTY
                    ON SPRADDR_CNTY_CODE = STVCNTY_CODE
                 LEFT JOIN STVSTAT
                    ON SPRADDR_STAT_CODE = STVSTAT_CODE
                 LEFT JOIN STVNATN
                    ON SPRADDR_NATN_CODE = STVNATN_CODE
                 LEFT OUTER JOIN GORADID
                    ON a.SORLCUR_PIDM = GORADID_PIDM
                       AND GORADID_ADID_CODE IN ('INBE', 'NOMR','ESCA', 'INBC', 'FREE')
                 LEFT OUTER JOIN SARCHKL
                    ON     sarchkl_pidm = saradap_pidm
                       AND sarchkl_term_code_entry = saradap_term_code_entry
                       AND sarchkl_appl_no = saradap_appl_no
                       AND sarchkl_admr_code = 'PAGD'
           WHERE 1 = 1
--                  And a.sorlcur_pidm =  cx.pidm
--                 And a.sorlcur_camp_code = cx.campus
--                 And a.sorlcur_levl_code = cx.nivel
                 And  a.SORLCUR_CURRENT_CDE = 'Y'
                 AND a.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                 AND a.SORLCUR_CACT_CODE = 'ACTIVE'
                 AND a.SORLCUR_SEQNO =
                        (SELECT MAX (SORLCUR_SEQNO)
                           FROM SORLCUR aa1
                          WHERE     a.sorlcur_pidm = aa1.sorlcur_pidm
                                 And a.sorlcur_camp_code = aa1.sorlcur_camp_code
                                 And a.sorlcur_levl_code = aa1.sorlcur_levl_code
                                AND a.SORLCUR_LMOD_CODE = aa1.SORLCUR_LMOD_CODE
                                AND a.SORLCUR_CACT_CODE = aa1.SORLCUR_CACT_CODE
                                AND a.sorlcur_program = aa1.sorlcur_program)
                 AND a.sorlcur_pidm IN  (SELECT pidm
                                                       FROM tztprog
                                                      WHERE ESTATUS NOT IN ('MA', 'EG')
                                                      And SGBSTDN_STYP_CODE ='RE'
                                                       AND programa = a.sorlcur_program)
          UNION
          SELECT DISTINCT
                 b.spriden_id Matricula,
                 b.spriden_first_name || ' ' || spriden_last_name Estudiante,
                 'CP' Estatus_Code,
                 'CAMBIO DE PROGRAMA' Estatus,
                 SZVCAMP_CAMP_CODE Campus,
                 a.SORLCUR_LEVL_CODE Nivel,
                 a.SORLCUR_PROGRAM || ' ' || c.SMRPRLE_PROGRAM_DESC Programa,
                 a.SORLCUR_ACTIVITY_DATE FECHA_ACTIVIDAD,
                 a.SORLCUR_START_DATE fechainicio,
                 STVSTYP_DESC TIPO,
                 STVADMT_DESC Tipo_Ingreso,
                 SGBSTDN_ACTIVITY_DATE fecha_registro,
                 pkg_utilerias.f_canal_venta_reingreso(a.sorlcur_pidm,'CANF')    clave_canal,
                 NVL (pkg_utilerias.f_canal_venta(a.sorlcur_pidm,'COES'), 'COMENTARIO') COMENTARIO,
                 NVL (geo.STVGEOD_DESC, 'CALL CENTER PROFESIONAL') canal_final,
                 SPBPERS_BIRTH_DATE fecha_nac,
                 pkg_utilerias.f_correo(a.sorlcur_pidm,'PRIN')correo,
                 'Validado' pago,
                 des.decision decision,
                 des.usuario usuario_decision,
                 des.fecha_des fecha_Decision,
                 NVL (SGBSTDN_ACTIVITY_DATE, d.SGBSTDN_ACTIVITY_DATE)
                    Fecha_Inscripcion,
                 NVL (d.SGBSTDN_TERM_CODE_MATRIC, d.SGBSTDN_TERM_CODE_ADMIT)
                    Periodo_Matriculacion,
                 (SELECT SUM (TBRACCD_BALANCE)
                    FROM TBRACCD
                   WHERE TBRACCD_PIDM = sorlcur_pidm)
                    saldo,
                 NULL Estatus_Solicitud,
                 SPRADDR_STREET_LINE1 Direccion,
                 SPRADDR_STREET_LINE3 Colonia,
                 STVCNTY_DESC Localidad,
                 STVSTAT_DESC Estado,
                 STVNATN_NATION Pais,
                 CASE
                    WHEN GORADID_ADID_CODE = 'INBE' THEN 'INBEC'
                    WHEN GORADID_ADID_CODE = 'NOMR' THEN 'NO MOLESTAR'
                    WHEN GORADID_ADID_CODE = 'ESCA' THEN 'ESCALONADO'
                    WHEN GORADID_ADID_CODE = 'INBC' THEN 'ALUMNO INBEC'
                 WHEN GORADID_ADID_CODE = 'FREE' THEN 'FREEMIUM'
                    ELSE NULL
                 END
                    AS Etiqueta,
                 STVMRTL_DESC Estado_Civil,
                 CASE
                    WHEN SPBPERS_SEX = 'F' THEN 'Femenino'
                    WHEN SPBPERS_SEX = 'M' THEN 'Masculino'
                    ELSE 'No_Disponible'
                 END
                    AS Sexo,
                    pkg_utilerias.f_Salario_Mensual( a.SORLCUR_PIDM)  Ingreso_Mensual,
                 (SELECT DISTINCT MAX (SARACMT_COMMENT_TEXT)
                    FROM SARACMT
                   WHERE SARACMT_PIDM = SPRIDEN_PIDM
                         AND SARACMT_ORIG_CODE IN ('EGTL', 'EGEX', 'EGRE'))
                    Estatus_egreso,
                 pkg_utilerias.f_bienvenida_obs(a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code) Observaciones,
                 pkg_utilerias.f_bienvenida_curso(a.sorlcur_pidm,a.sorlcur_camp_code, a.sorlcur_levl_code)  CURSO,
                 pkg_utilerias.f_bienvenida_fecha(a.sorlcur_pidm, a.sorlcur_camp_code, a.sorlcur_levl_code)  FECHA_ENROLAMIENTO,
                 TRUNC(b.SPRIDEN_CREATE_DATE) FECHA_CREACION,
                 'parte4' parte
            FROM sorlcur a
                 JOIN spriden b
                    ON b.spriden_pidm = a.sorlcur_pidm
                       AND b.spriden_change_ind IS NULL
                 JOIN sgbstdn d
                    ON d.sgbstdn_pidm = spriden_pidm
                 JOIN decision1 des
                    ON     des.pidm = a.sorlcur_pidm
                       AND a.sorlcur_program = des.programa
                       AND a.sorlcur_curr_rule = des.currule
                       AND a.sorlcur_term_code = des.periodo
                       AND d.sgbstdn_term_code_eff =
                              (SELECT DISTINCT MAX (A1.sgbstdn_term_code_eff)
                                 FROM sgbstdn A1
                                WHERE 1 = 1
                                      AND d.sgbstdn_pidm = a1.sgbstdn_pidm
                                      AND d.sgbstdn_program_1 =
                                             a1.sgbstdn_program_1
                                      AND d.sgbstdn_term_code_ctlg_1 =
                                             a1.sgbstdn_term_code_ctlg_1)
                 JOIN SMRPRLE c
                    ON c.SMRPRLE_PROGRAM = A.SORLCUR_PROGRAM
                 JOIN STVSTST
                    ON d.sgbstdn_stst_code = STVSTST_CODE
                 JOIN SZVCAMP
                    ON szvcamp_camp_alt_code =   SUBSTR (a.sorlcur_term_code, 1, 2)
                 JOIN STVADMT
                    ON a.SORLCUR_ADMT_CODE = STVADMT_CODE
                 LEFT OUTER JOIN STVGEOD geo
                    ON LPAD (TRIM (SUBSTR (pkg_utilerias.f_canal_venta(a.sorlcur_pidm,'CANF') , 1, 2)),2,'0') = geo.STVGEOD_CODE
                 JOIN STVSTYP
                    ON d.SGBSTDN_STYP_CODE = STVSTYP_CODE
                 LEFT OUTER JOIN SPBPERS
                    ON spbpers_pidm = spriden_pidm
                 LEFT OUTER JOIN STVMRTL
                    ON SPBPERS_MRTL_CODE = STVMRTL_CODE
                 LEFT OUTER JOIN SPRADDR
                    ON SPRADDR_pidm = spriden_pidm AND SPRADDR_ATYP_CODE = 'RE'
                 LEFT JOIN STVCNTY
                    ON SPRADDR_CNTY_CODE = STVCNTY_CODE
                 LEFT JOIN STVSTAT
                    ON SPRADDR_STAT_CODE = STVSTAT_CODE
                 LEFT JOIN STVNATN
                    ON SPRADDR_NATN_CODE = STVNATN_CODE
                 LEFT OUTER JOIN GORADID
                    ON a.SORLCUR_PIDM = GORADID_PIDM
                       AND GORADID_ADID_CODE IN ('INBE', 'NOMR','ESCA', 'INBC', 'FREE')
           WHERE 1= 1
--              And a.sorlcur_pidm =  cx.pidm
--              And  a.sorlcur_camp_code = cx.campus
--              And a.sorlcur_levl_code = cx.nivel
              And a.SORLCUR_CACT_CODE = 'CHANGE'
              AND a.SORLCUR_CURRENT_CDE = 'Y'
              AND a.sorlcur_pidm = d.sgbstdn_pidm
              AND a.sorlcur_program = d.sgbstdn_program_1
              AND a.sorlcur_term_code_ctlg = d.sgbstdn_term_code_ctlg_1
              AND a.sorlcur_levl_code = d.sgbstdn_levl_code
              AND a.sorlcur_curr_rule = d.sgbstdn_curr_rule_1
              AND a.sorlcur_seqno =
                        (SELECT DISTINCT MAX (c1.sorlcur_seqno)
                           FROM sorlcur c1
                          WHERE     1 = 1
                                AND a.sorlcur_pidm = c1.sorlcur_pidm
                                And a.sorlcur_camp_code = c1.sorlcur_camp_code
                                And a.sorlcur_levl_code = c1.sorlcur_levl_code
                                AND a.sorlcur_lmod_code = c1.sorlcur_lmod_code
                                AND a.sorlcur_program = c1.sorlcur_program)
          UNION
          SELECT TZTPAGO_ID Matricula,
                 b.spriden_first_name || ' ' || spriden_last_name Estudiante,
                 NULL Estatus_Code,
                 NULL Estatus,
                 TZTPAGO_CAMP Campus,
                 TZTPAGO_LEVL Nivel,
                 NULL Programa,
                 NULL FECHA_ACTIVIDAD,
                 TZTPAGO_FECHA_INI fechainicio,
                 'PROSPECTO' TIPO,
                 NULL Tipo_Ingreso,
                 NULL fecha_registro,
                 TZTPAGO_CANAL clave_canal,
                 NULL COMENTARIO,
                 NULL canal_final,
                 NULL fecha_nac,
                 TZTPAGO_EMAIL correo,
                 TZTPAGO_STAT_DOCTO pago,
                 NULL decision,
                 NULL usuario_decision,
                 NULL fecha_Decision,
                 NULL Fecha_Inscripcion,
                 TZTPAGO_TERM_CODE Periodo_Matriculacion,
                 (SELECT SUM (TBRACCD_BALANCE)
                    FROM TBRACCD
                   WHERE TBRACCD_PIDM = spriden_pidm)
                    saldo,
                 TZTPAGO_STAT_SOLIC Estatus_Solicitud,
                 NULL Direccion,
                 NULL Colonia,
                 NULL Localidad,
                 NULL Estado,
                 NULL Pais,
                 NULL Etiqueta,
                 NULL Estado_Civil,
                 NULL Sexo,
                 NULL Saldo_Mensual,
                 (SELECT DISTINCT MAX (SARACMT_COMMENT_TEXT)
                    FROM SARACMT
                   WHERE SARACMT_PIDM = SPRIDEN_PIDM
                         AND SARACMT_ORIG_CODE IN ('EGTL', 'EGEX', 'EGRE'))
                    Estatus_egreso,
                 NULL OBSERVACIONES,
                 NULL CURSO,
                 NULL FECHA_ENROLAMIENTO,
                 NULL FECHA_CREACION,
                 'parte5' parte
            FROM TZTPAGO, SPRIDEN b
           WHERE     SPRIDEN_ID = TZTPAGO_ID
                 AND SPRIDEN_CHANGE_IND IS NULL
                 AND spriden_pidm NOT IN (SELECT saradap_pidm FROM saradap)
                 
                 UNION
           
            --Caty 10/10/2023
            --Se agrega para que inserte los registros con pago sin cargo (saldo a favor)
        SELECT  DISTINCT
                 b.spriden_id Matricula,
                 b.spriden_first_name || ' ' || spriden_last_name Estudiante,
                 NULL Estatus_Code,
                 NULL Estatus,
                 SZVCAMP_CAMP_CODE Campus,
                 c.nivel Nivel,
                 c.programa Programa,
                 NULL FECHA_ACTIVIDAD,
               /*  case when to_number(substr(C.FECHA_INICIO_CLASES,1,4))> 1900 and C.FECHA_INICIO_CLASES is not null then
                 to_date(substr(C.FECHA_INICIO_CLASES,1,4)||'/'||substr(C.FECHA_INICIO_CLASES,6,2)||'/'||substr(C.FECHA_INICIO_CLASES,9,2),'yyyy/mm/dd') 
                 else null end*/
                 null fechainicio,                  
                 'PROSPECTO' TIPO,
                 NULL Tipo_Ingreso,
                 NULL fecha_registro,
                 NULL clave_canal,
                 NULL COMENTARIO,
                 NULL canal_final,
                 case when to_number(substr(C.FECHA_DE_NACIMIENTO,1,4))> 1900 and C.FECHA_DE_NACIMIENTO is not null then
                 to_date(substr(C.FECHA_DE_NACIMIENTO,1,4)||'/'||substr(C.FECHA_DE_NACIMIENTO,6,2)||'/'||substr(C.FECHA_DE_NACIMIENTO,9,2),'yyyy/mm/dd') 
                 else null end
                 fecha_nac,
                 NULL correo,
                 NULL pago,
                 NULL decision,
                 NULL usuario_decision,
                 NULL fecha_Decision,
                 NULL Fecha_Inscripcion,
                NULL Periodo_Matriculacion,
                 (SELECT SUM (TBRACCD_BALANCE)
                    FROM TBRACCD
                   WHERE TBRACCD_PIDM = spriden_pidm)
                    saldo,
                 NULL Estatus_Solicitud,
                 NULL Direccion,
                 NULL Colonia,
                 NULL Localidad,
                 NULL Estado,
                 NULL Pais,
                 NULL Etiqueta,
                 NULL Estado_Civil,
                 NULL Sexo,
                 NULL Saldo_Mensual,
                 (SELECT DISTINCT MAX (SARACMT_COMMENT_TEXT)
                    FROM SARACMT
                   WHERE SARACMT_PIDM = SPRIDEN_PIDM
                         AND SARACMT_ORIG_CODE IN ('EGTL', 'EGEX', 'EGRE'))
                    Estatus_egreso,
                 NULL OBSERVACIONES,
                 NULL CURSO,
                 NULL FECHA_ENROLAMIENTO,
                 NULL FECHA_CREACION,
                 'parte6' parte         
           from tbraccd a
           join spriden b on b.SPRIDEN_PIDM = a.TBRACCD_PIDM --AND SPRIDEN_PIDm =fget_pidm('480000661')
           left join SZRAINS1 c on b.SPRIDEN_ID = c.MATRICULA 
          left join SZVCAMP on SZVCAMP_CAMP_ALT_CODE=substr(TBRACCD_DETAIL_CODE,1,2)
           WHERE 1=1
                 and a.TBRACCD_DETAIL_CODE in (select TZTNCD_CODE from TZTNCD where TZTNCD_CONCEPTO in ('Poliza', 'Deposito', 'Nota Distribucion') )
                 and a.tbraccd_effective_date in (select max(d.tbraccd_effective_date)
                                                    from tbraccd d
                                                    where a.tbraccd_pidm=d.tbraccd_pidm
                                                     and d.TBRACCD_DETAIL_CODE=a.TBRACCD_DETAIL_CODE
                                                  )
                 and b.SPRIDEN_CHANGE_IND IS NULL
                 AND b.spriden_pidm NOT IN (SELECT saradap_pidm FROM saradap)             
                 and b.spriden_pidm not in (select fget_pidm(tztpago_id) from taismgr.tztpago)
                 AND  C.estatus_inscripcion='PROSPECTO'
                    /* and b.SPRIDEN_id in (
                     '470006617',
'480000661',
'470006992',
'470006997',
'470007095',
'470007350',
'470007046',
'480000709',
'480000713',
'470007474')*/
                     
          
            
                and b.spriden_last_name not like '%identificar%'
                and b.spriden_last_name not like '%Identificar%'
                and b.spriden_last_name not like '%reclasificar%'          
                 
                        )
           WHERE 1 = 1
      --  AND MATRICULA =  cx.matricula


                ) loop

                          Begin
                                    Insert into szrniri values (cx1.MATRICULA,
                                                                        cx1.ESTUDIANTE,
                                                                        cx1.ESTATUS_CODE,
                                                                        cx1.ESTATUS,
                                                                        cx1.CAMPUS,
                                                                        cx1.NIVEL,
                                                                        cx1.PROGRAMA,
                                                                        cx1.FECHA_ACTIVIDAD,
                                                                        cx1.FECHAINICIO,
                                                                        cx1.TIPO,
                                                                        cx1.TIPO_INGRESO,
                                                                        cx1.FECHA_REGISTRO,
                                                                        cx1.CLAVE_CANAL,
                                                                        cx1.CANAL_FINAL,
                                                                        cx1.FECHA_NAC,
                                                                        cx1.CORREO,
                                                                        cx1.ETIQUETA,
                                                                        cx1.PAGO,
                                                                        cx1.SALDO,
                                                                        cx1.DECISION,
                                                                        cx1.USUARIO_DECISION,
                                                                        cx1.FECHA_DECISION,
                                                                        cx1.FECHA_INSCRIPCION,
                                                                        cx1.PERIODO_MATRICULACION,
                                                                        cx1.ESTATUS_SOLICITUD,
                                                                        cx1.COMENTARIO,
                                                                        cx1.FECHA_CREACION,
                                                                        cx1.PARTE ,
                                                                        sysdate) ;

                          Exception
                            When Others then
                                null;
                          End;

                          Commit;

                End Loop cx1;



End p_niri;

 function f_avcert_pipe(pidm number, prog varchar2) RETURN t_tab PIPELINED
    is
    l_row  t_certificado;
    BEGIN

        for c in (    ---  TODA LA FUNCION ENTRA EN UN FOR
                    select distinct  /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                    spriden_id matricula, spriden_first_name||' '||replace(spriden_last_name,'/',' ') nombre ,
                                    sztdtec_programa_comp programa,
                                    stvstst_desc estatus,
                                    TO_NUMBER (SUBSTR (smrarul_area, 9, 2)) per,
                                    smrpaap_area area,
                                    case when sorlcur_levl_code='MA' then
                                        case when
                                          substr(smrarul_crse_numb_low,-1)='B' then
                                           smrarul_subj_code||substr(smrarul_crse_numb_low,1,(length(smrarul_crse_numb_low)-1))
                                         when
                                          substr(smrarul_crse_numb_low,-1)='S' then
                                           smrarul_subj_code||substr(smrarul_crse_numb_low,1,length((smrarul_crse_numb_low)-1))
                                         when
                                          substr(smrarul_crse_numb_low,-1)='Z' then
                                           smrarul_subj_code||substr(smrarul_crse_numb_low,1,length((smrarul_crse_numb_low)-1))
                                         when
                                          substr(smrarul_crse_numb_low,-1)='.' then
                                           smrarul_subj_code||substr(smrarul_crse_numb_low,1,length((smrarul_crse_numb_low)-1))
                                         else
                                          smrarul_subj_code||smrarul_crse_numb_low
                                        end
                                    else
                                       smrarul_subj_code||smrarul_crse_numb_low
                                    end materia,
--                                    smrarul_subj_code||smrarul_crse_numb_low materia,
                                    scrsyln_long_course_title nombre_mat,
                                    smracaa_rule regla,
                                     case when
                                          substr(SMRPAAP_AREA,-2) in  (SELECT distinct min(substr(a.ZSTPARA_PARAM_VALOR,-2)) FROM ZSTPARA a
                                                                               WHERE a.ZSTPARA_MAPA_ID='AREAS_PROFESION'
                                                                                 AND a.ZSTPARA_PARAM_ID=prog
                                                                                 AND a.ZSTPARA_PARAM_DESC=SMRPAAP_TERM_CODE_EFF
                                                                                 AND ZSTPARA_PARAM_VALOR IN (select smriemj_area from smriemj
                                                                                                              where smriemj_majr_code in (select unique SORLFOS_MAJR_CODE
                                                                                                                                         from  sorlcur cu, sorlfos ss
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
                                                                                                                                          and SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                          and sorlcur_program   =prog
                                                                                                                                       )
                                                                                          )
                                                                     )
                                         then 'Ãrea de concentraciÃ³n Major '||lower((SELECT SUBSTR(AREA,3,199) FROM
                                                                              (select substr(UPPER(b.sztdtec_programa_comp),
                                                                              (select  ("Posicion EN"-1) from (select instr(UPPER(a.sztdtec_programa_comp), ' EN',1,1) as  "Posicion EN"  from sztdtec a
                                                                                                           where (instr(UPPER(a.sztdtec_programa_comp), 'EN',1,1))>0 and a.SZTDTEC_PROGRAM=prog
                                                                                                           and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG) )
                                                                                   ) area
                                                                              from sztdtec b
                                                                              where b.SZTDTEC_PROGRAM=prog
                                                                              and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                                                              )))
                                     when substr(SMRPAAP_AREA,-2) NOT IN  (SELECT distinct min(substr(a.ZSTPARA_PARAM_VALOR,-2)) FROM ZSTPARA a
                                                                           WHERE a.ZSTPARA_MAPA_ID='AREAS_PROFESION'
                                                                             AND a.ZSTPARA_PARAM_ID=prog
                                                                             AND a.ZSTPARA_PARAM_DESC=SMRPAAP_TERM_CODE_EFF)

                                          AND SMRPAAP_AREA IN (select smriecc_area from smriecc
                                                                where smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE from  sorlcur cu, sorlfos ss
                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                    and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                    and cu.sorlcur_pidm=pidm
                                                                                                    and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                    and SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                    and SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                    and sorlcur_program   =prog
                                                                                                  )
                                                               )
                                          then 'Ãrea de concentraciÃ³n Menor '||lower((SELECT SUBSTR(AREA,3,199) FROM
                                                                              (select substr(UPPER(b.sztdtec_programa_comp),
                                                                              (select  ("Posicion EN"-1) from (select instr(UPPER(a.sztdtec_programa_comp), ' EN',1,1) as  "Posicion EN"  from sztdtec a
                                                                                                           where (instr(UPPER(a.sztdtec_programa_comp), 'EN',1,1))>0 and a.SZTDTEC_PROGRAM=prog
                                                                                                           and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG) )
                                                                                   ) area
                                                                              from sztdtec b
                                                                              where b.SZTDTEC_PROGRAM=prog
                                                                              and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                                                              )))
                                       else
                                         'Ãrea de Comun '||lower((SELECT SUBSTR(AREA,3,199) FROM
                                                                              (select substr(UPPER(b.sztdtec_programa_comp),
                                                                              (select  ("Posicion EN"-1) from (select instr(UPPER(a.sztdtec_programa_comp), ' EN',1,1) as  "Posicion EN"  from sztdtec a
                                                                                                           where (instr(UPPER(a.sztdtec_programa_comp), 'EN',1,1))>0 and a.SZTDTEC_PROGRAM=prog
                                                                                                           and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG) )
                                                                                   ) area
                                                                              from sztdtec b
                                                                              where b.SZTDTEC_PROGRAM=prog
                                                                              and SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                                                              )))
                                     end n_area,
                                     case when
                                          substr(SMRPAAP_AREA,-2) in  (SELECT distinct min(substr(a.ZSTPARA_PARAM_VALOR,-2)) FROM ZSTPARA a
                                                                               WHERE a.ZSTPARA_MAPA_ID='AREAS_PROFESION'
                                                                                 AND a.ZSTPARA_PARAM_ID=prog
                                                                                 AND a.ZSTPARA_PARAM_DESC=SMRPAAP_TERM_CODE_EFF
                                                                                 AND ZSTPARA_PARAM_VALOR IN (select smriemj_area from smriemj
                                                                                                              where smriemj_majr_code in (select unique SORLFOS_MAJR_CODE
                                                                                                                                         from  sorlcur cu, sorlfos ss
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
                                                                                                                                          and SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                                                          and sorlcur_program   =prog
                                                                                                                                       )
                                                                                          )
                                                                     )
                                         then 'Obligatoria'
                                     when substr(SMRPAAP_AREA,-2) NOT IN  (SELECT distinct min(substr(a.ZSTPARA_PARAM_VALOR,-2)) FROM ZSTPARA a
                                                                           WHERE a.ZSTPARA_MAPA_ID='AREAS_PROFESION'
                                                                             AND a.ZSTPARA_PARAM_ID=prog
                                                                             AND a.ZSTPARA_PARAM_DESC=SMRPAAP_TERM_CODE_EFF)

                                          AND SMRPAAP_AREA IN (select smriecc_area from smriecc
                                                                where smriecc_majr_code_conc in (select unique SORLFOS_MAJR_CODE from  sorlcur cu, sorlfos ss
                                                                                                  where cu.sorlcur_pidm= Ss.SORLfos_PIDM
                                                                                                    and cu.SORLCUR_SEQNO  = ss.SORLFOS_LCUR_SEQNO
                                                                                                    and cu.sorlcur_pidm=pidm
                                                                                                    and SORLCUR_LMOD_CODE = 'LEARNER'
                                                                                                    and SORLFOS_LFST_CODE = 'CONCENTRATION'
                                                                                                    and SORLCUR_CACT_CODE=SORLFOS_CACT_CODE
                                                                                                    and sorlcur_program   =prog
                                                                                                  )
                                                               )
                                          then 'Optativa'
                                       else
                                         'Obligatoria'
                                     end tipo_asig,
                                     case when substr(smrarul_area,9,2) in ('01') then 'Primer Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('02') then 'Segundo Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('03') then 'Tercer Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('04') then 'Cuarto Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('05') then 'Quinto Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('06') then 'Sexto Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('07') then 'Septimo Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('08') then 'Octavo Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('09') then 'Noveno Cuatrimestre'
                                          when substr(smrarul_area,9,2) in ('10') then 'Decimo Cuatrimestre'
                                          when substr(smrpaap_area,9,2) in ('11') then 'Onceavo Cuatrimestre'
                                          when substr(smrpaap_area,9,2) in ('12') then 'Doceavo Cuatrimestre'
                                      else smralib_area_desc
                                     end   nombre_area
                                    from smrpaap s, smrarul, sgbstdn y, sorlcur so, spriden, sztdtec, stvstst, smralib,smracaa,scrsyln, zstpara,smbagen,
                                    (
                                               select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                 w.shrtckn_subj_code subj, w.shrtckn_crse_numb code,
                                                 shrtckg_grde_code_final CALIF, decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, shrtckg_final_grde_chg_date fecha
                                                from shrtckn w,shrtckg, shrgrde, smrprle
                                                where shrtckn_pidm=pidm
                                                and     shrtckg_pidm=w.shrtckn_pidm
                                                and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001','L3HE401','L3HE402','L3HE403','L3HE404')
                                                and     shrtckg_tckn_seq_no=w.shrtckn_seq_no
                                                and     shrtckg_term_code=w.shrtckn_term_code
                                                and     smrprle_program=prog
                                                and     shrgrde_levl_code=smrprle_levl_code
                                                and     shrgrde_code=shrtckg_grde_code_final
                                                and     decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))   -- anadido para sacar la calificacion mayor  OLC
                                                                  in (select max(decode(shrtckg_grde_code_final,'NA',4,'NP',4,'AC',6,to_number(shrtckg_grde_code_final))) from shrtckn ww, shrtckg zz
                                                                          where w.shrtckn_pidm=ww.shrtckn_pidm
                                                                             and  w.shrtckn_subj_code=ww.shrtckn_subj_code  and w.shrtckn_crse_numb=ww.shrtckn_crse_numb
                                                                             and  ww.shrtckn_pidm=zz.shrtckg_pidm and ww.shrtckn_seq_no=zz.shrtckg_tckn_seq_no and ww.shrtckn_term_code=zz.shrtckg_term_code)
                                                and     SHRTCKN_SUBJ_CODE||SHRTCKN_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                        and shrtckn_pidm in (select spriden_pidm from spriden where spriden_id=ZSTPARA_PARAM_ID))
                                                union
                                                select shrtrce_subj_code subj, shrtrce_crse_numb code,
                                                shrtrce_grde_code  CALIF, 'EQ'  ST_MAT, trunc(shrtrce_activity_date) fecha
                                                from  shrtrce
                                                where  shrtrce_pidm=pidm
                                                and     SHRTRCE_SUBJ_CODE||SHRTRCE_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001','L3HE401','L3HE402','L3HE403','L3HE404')
                                                union
                                                select SHRTRTK_SUBJ_CODE_INST subj, SHRTRTK_CRSE_NUMB_INST code,
                                                /*nvl(SHRTRTK_GRDE_CODE_INST,0)*/  '0' CALIF, 'EQ'  ST_MAT, trunc(SHRTRTK_ACTIVITY_DATE) fecha
                                                from  SHRTRTK
                                                where  SHRTRTK_PIDM=pidm
                                                union
                                                select ssbsect_subj_code subj, ssbsect_crse_numb code, '101' CALIF, 'EC'  ST_MAT, trunc(sfrstcr_rsts_date)+120 fecha
                                                from sfrstcr, smrprle, ssbsect, spriden
                                                where  smrprle_program=prog
                                                and     sfrstcr_pidm=pidm  and sfrstcr_grde_code is null and sfrstcr_rsts_code='RE'
                                                and     SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001','SESO1001','L3HE401','L3HE402','L3HE403','L3HE404')
                                                and     spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                and    ssbsect_term_code=sfrstcr_term_code
                                                and    ssbsect_crn=sfrstcr_crn
                                                union
                                                select /*+ INDEX(IDX_SHRGRDE_TWO_)*/
                                                 ssbsect_subj_code subj, ssbsect_crse_numb code, sfrstcr_grde_code CALIF,  decode (shrgrde_passed_ind,'Y','AP','N','NA') ST_MAT, trunc(sfrstcr_rsts_date)/*+120*/  fecha
                                                from sfrstcr, smrprle, ssbsect, spriden, shrgrde
                                                where  smrprle_program=prog
                                                and    sfrstcr_pidm=pidm  and sfrstcr_grde_code is not null
                                                and    sfrstcr_pidm not in (select shrtckn_pidm from shrtckn where sfrstcr_term_code=shrtckn_term_code and shrtckn_crn=sfrstcr_crn)
                                                and    SFRSTCR_RSTS_CODE!='DD'
                                                and    spriden_pidm=sfrstcr_pidm and spriden_change_ind is null
                                                and    SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001','SESO1001','L3HE401','L3HE402','L3HE403','L3HE404')
                                                and    SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB not in (select ZSTPARA_PARAM_VALOR from ZSTPARA
                                                                                                     where ZSTPARA_MAPA_ID='NOVER_MAT_DASHB'
                                                                                                       and sfrstcr_pidm in (select spriden_pidm from spriden
                                                                                                                             where spriden_id=ZSTPARA_PARAM_ID))
                                                and    ssbsect_term_code=sfrstcr_term_code
                                                and    ssbsect_crn=sfrstcr_crn
                                                and    shrgrde_levl_code=smrprle_levl_code
                                                and    shrgrde_code=sfrstcr_grde_code
                                   ) k
                                  where   spriden_pidm=pidm  and spriden_change_ind is null
                                    and   sorlcur_pidm= spriden_pidm
                                    and   SORLCUR_LMOD_CODE = 'LEARNER'
                                    and   SORLCUR_SEQNO in (select max(SORLCUR_SEQNO) from sorlcur ss
                                                             where so.SORLCUR_PIDM=ss.sorlcur_pidm
                                                               and so.sorlcur_lmod_code=ss.sorlcur_lmod_code
                                                               and ss.sorlcur_program =prog)
                                   and     smrpaap_program=prog
                                   AND     smrpaap_term_code_eff = SORLCUR_TERM_CODE_CTLG
                                   and     smrpaap_area=SMBAGEN_AREA
                                   and     SMBAGEN_ACTIVE_IND='Y'
                                   and     SMRPAAP_TERM_CODE_EFF=SMBAGEN_TERM_CODE_EFF
                                   and     smrpaap_area=smrarul_area
                                   and     sgbstdn_pidm=spriden_pidm
                                   and     sgbstdn_program_1=smrpaap_program
                                   and     sgbstdn_term_code_eff in (select max(sgbstdn_term_code_eff) from sgbstdn x
                                                                      where x.sgbstdn_pidm=y.sgbstdn_pidm
                                                                        and x.sgbstdn_program_1=y.sgbstdn_program_1)
                                   and     sztdtec_program=sgbstdn_program_1 and sztdtec_status='ACTIVO'  and  SZTDTEC_CAMP_CODE=SORLCUR_CAMP_CODE  --- **** nuevo CAPP ****
                                   and     SZTDTEC_TERM_CODE=SORLCUR_TERM_CODE_CTLG
                                   and     SMRARUL_TERM_CODE_EFF=SMRACAA_TERM_CODE_EFF
                                   and     stvstst_code=sgbstdn_stst_code
                                   and     smralib_area=smrpaap_area
                                   AND     smracaa_area = smrarul_area
                                   AND     smracaa_rule = smrarul_key_rule
                                   and     SMRACAA_TERM_CODE_EFF=SORLCUR_TERM_CODE_CTLG
                                   and     SMRARUL_SUBJ_CODE||SMRARUL_CRSE_NUMB_LOW not in ('L1HB401','L1HB402','L1HB403','L1HB404','L1HB405','L1HP401','UTEL001','SESO1001','L3HE401','L3HE402','L3HE403','L3HE404')
                                   and     k.subj=smrarul_subj_code and k.code=smrarul_crse_numb_low
                                   and     scrsyln_subj_code=smrarul_subj_code and scrsyln_crse_numb=smrarul_crse_numb_low
                                   and     zstpara_mapa_id(+)='MAESTRIAS_BIM' and zstpara_param_id(+)=sgbstdn_program_1 and zstpara_param_desc(+)=SORLCUR_TERM_CODE_CTLG
                                   order by PER,regla
                 )loop

                    l_row.MATRICULA    :=c.MATRICULA;
                    l_row.NOMBRE       :=c.NOMBRE;
                    l_row.PROGRAMA     :=c.PROGRAMA;
                    l_row.ESTATUS      :=c.ESTATUS;
                    l_row.PER          :=c.PER;
                    l_row.AREA         :=c.AREA;
                    l_row.MATERIA      :=c.MATERIA;
                    l_row.NOMBRE_MAT   :=c.NOMBRE_MAT;
                    l_row.REGLA        :=c.REGLA;
                    l_row.N_AREA       :=c.N_AREA;
                    l_row.TIPO_ASIG    :=c.TIPO_ASIG;
                    l_row.NOMBRE_AREA  :=c.NOMBRE_AREA;
                    PIPE ROW (l_row);

                 end loop;


    end;


procedure p_tztprog_prono is

/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */
 vl_pago number:=0;
 vl_pago_minimo number:=0;
 vl_sp number:=0;

BEGIN


EXECUTE IMMEDIATE 'TRUNCATE TABLE SATURN.TZTPROGM';
COMMIT;



 insert into saturn.tztprogM
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

 Select distinct pidm, sp, nvl (fecha_inicio, to_date('04/03/2017','dd/mm/yyyy' ) ) fecha_inicio, campus||nivel campus, FECHA_MOV
 from tztprogm
 where 1= 1
 --CAMPUS||nivel = 'ULTLI'
 --and fecha_mov is null

 ) loop

 If c.fecha_inicio < to_date('04/03/2017','dd/mm/yyyy' ) and c.campus != 'UTLLI' then

 Begin
 Update tztprogm
 set FECHA_MOV = to_date('04/03/2017','dd/mm/yyyy' )
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 ElsIf c.fecha_inicio >= to_date('04/03/2017','dd/mm/yyyy' ) and c.fecha_mov is null then

 Begin
 Update tztprogm
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

 Update tztprogm
 set FECHA_MOV = to_date('04/03/2017','dd/mm/yyyy' )
 Where FECHA_MOV is null;
 Commit;


 ---- Se actualiza la fecha de la primera inscripcion ----------


 begin


 for c in (
 select *
 from tztprogm
 where 1 = 1
 -- and rownum <= 50
 )loop



 Begin


 Update tztprogm
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
                    from tztprogm
                    where 1= 1
                    and estatus in ('BT','BD','CM','CV','BI')
                    and SGBSTDN_STYP_CODE !='D'


     ) loop

        Begin
            Update tztprogm
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


end p_tztprog_prono;

function f_doc_recoleccion(p_pidm number, c_campus varchar2,n_nivel varchar2,t_ingre varchar2, p_prog varchar2) return varchar2
   is

indice  number:=1;
valid   number:=0;
total   number:=0;
docto   varchar2(200);
retorno varchar2(200):='RECOLECCION';

begin

 loop

  begin
  select regexp_substr(ZSTPARA_PARAM_VALOR,'[^,]+',1,indice) into docto from zstpara
      where ZSTPARA_MAPA_ID='DOCU_RECOLE'
      and ZSTPARA_PARAM_ID=c_campus
      and SUBSTR(ZSTPARA_PARAM_DESC,1,2)=n_nivel
      AND SUBSTR(ZSTPARA_PARAM_DESC,4,2)=t_ingre;
  Exception
    When Others then
       DBMS_OUTPUT.PUT_LINE('ERROR: AL BUSCAR DOCUMENTOS EN AGRUPADOR  "DOCU_RECOLE" ');
       retorno:='SIN AGRUPADOR EN DOCU_RECOLE';
       indice:=100;
       exit;
  end;

  begin
      select SUM(CASE WHEN SARCHKL_CKST_CODE='VALIDADO' THEN 1 ELSE 0 END) into valid
         from SARCHKL
         join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_prog
                         and SARADAP_APPL_NO = SARCHKL_APPL_NO
         join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
       where SARCHKL_PIDM = p_pidm
         And SARCHKL_ADMR_CODE =docto;
  Exception
    When Others then
       DBMS_OUTPUT.PUT_LINE('ERROR: AL BUSCAR DOCUMENTOS DEL ALUMNO ');
       retorno:='SIN DOCUMENTOS DEL ALUMNO';
       indice:=100;
       exit;
   end;

     total:=total+NVL(valid,0);

  exit when docto is null;

  indice:=indice+1;

 end loop;

--       dbms_output.put_line('documento '||docto||'  '||VALID||'  INDICE '||indice||' TOTAL  '||TOTAL);

   IF total=indice-1 THEN
    retorno:='COMPLETO';
   END IF;

   return(retorno);

   indice:=0;
   valid:=0;
   total:=0;
   docto:=NULL;

--      dbms_output.put_line('Resulta  '||retorno);

end;

function f_doc_recoleccion_f(p_pidm number, c_campus varchar2,n_nivel varchar2,t_ingre varchar2, p_prog varchar2) return varchar2
   is

indice  number:=1;
valid   number:=0;
devue   number:=0;
prest   number:=0;
total1  number:=0;
total2  number:=0;
total3  number:=0;
docto   varchar2(200);
retorno varchar2(200):='RECOLECCION';

begin

 loop

  begin
  select regexp_substr(ZSTPARA_PARAM_VALOR,'[^,]+',1,indice) into docto from zstpara
      where ZSTPARA_MAPA_ID='DOCU_RECOLE'
      and ZSTPARA_PARAM_ID=c_campus
      and SUBSTR(ZSTPARA_PARAM_DESC,1,2)=n_nivel
      AND SUBSTR(ZSTPARA_PARAM_DESC,4,2)=t_ingre;
  Exception
    When Others then
       DBMS_OUTPUT.PUT_LINE('ERROR: AL BUSCAR DOCUMENTOS EN AGRUPADOR  "DOCU_RECOLE" ');
       retorno:='SIN AGRUPADOR EN DOCU_RECOLE';
       indice:=100;
       exit;
  end;

  begin
      select SUM(CASE WHEN SARCHKL_CKST_CODE='VALIDADO' THEN 1 ELSE 0 END) into valid
         from SARCHKL
         join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_prog
                         and SARADAP_APPL_NO = SARCHKL_APPL_NO
         join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
       where SARCHKL_PIDM = p_pidm
         And SARCHKL_ADMR_CODE =docto;

  Exception
    When Others then
       DBMS_OUTPUT.PUT_LINE('ERROR: AL BUSCAR DOCUMENTOS DEL ALUMNO ');
       retorno:='SIN DOCUMENTOS DEL ALUMNO';
       indice:=100;
       exit;
   end;

     total1:=total1+NVL(valid,0);

  exit when docto is null;

  indice:=indice+1;

 end loop;

        select SUM(CASE WHEN SARCHKL_CKST_CODE='DEVUELTO' THEN 1 ELSE 0 END) into devue
         from SARCHKL
         join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_prog
                         and SARADAP_APPL_NO = SARCHKL_APPL_NO
         join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
       where SARCHKL_PIDM = p_pidm
         And SARCHKL_ADMR_CODE IN ('CTBO','CTLO','CTMO');

       select SUM(CASE WHEN SARCHKL_CKST_CODE='PRESTAMO' THEN 1 ELSE 0 END) into prest
         from SARCHKL
         join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_prog
                         and SARADAP_APPL_NO = SARCHKL_APPL_NO
         join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
       where SARCHKL_PIDM = p_pidm
         And SARCHKL_ADMR_CODE IN ('CTBO','CTLO','CTMO');

     total2:=total2+NVL(devue,0);
     total3:=total3+NVL(prest,0);

--       dbms_output.put_line('documento '||docto||'  '||VALID||'  INDICE '||indice||' total1  '||total1);

   IF total1=indice-1 THEN
    retorno:='COMPLETO';
   ELSE
    retorno:='RECOLECCION';
   END IF;

   IF total2>=1 THEN
    retorno:='DEVUELTO';
   END IF;

   IF total3>=1 THEN
    retorno:='PRESTAMO';
   END IF;

 return(retorno);

   indice:=0;
   valid:=0;
   devue:=0;
   prest:=0;
   total1:=0;
   total2:=0;
   total3:=0;
   docto:=NULL;

--      dbms_output.put_line('Resulta  '||retorno);

end;

function f_doc_recoleccion_d(p_pidm number, c_campus varchar2,n_nivel varchar2,t_ingre varchar2, p_prog varchar2) return varchar2
   is

indice  number:=1;
valid   number:=0;
devue   number:=0;
prest   number:=0;
total1  number:=0;
total2  number:=0;
total3  number:=0;
docto   varchar2(200);
retorno varchar2(200):='RECOLECCION';

begin

 loop

  begin
  select regexp_substr(ZSTPARA_PARAM_VALOR,'[^,]+',1,indice) into docto from zstpara
      where ZSTPARA_MAPA_ID='DOCU_RECOLE2'
      and ZSTPARA_PARAM_ID=c_campus
      and SUBSTR(ZSTPARA_PARAM_DESC,1,2)=n_nivel
      AND SUBSTR(ZSTPARA_PARAM_DESC,4,2)=t_ingre;
  Exception
    When Others then
       DBMS_OUTPUT.PUT_LINE('ERROR: AL BUSCAR DOCUMENTOS EN AGRUPADOR  "DOCU_RECOLE" ');
       retorno:='SIN AGRUPADOR EN DOCU_RECOLE';
       indice:=100;
       exit;
  end;

  begin
      select SUM(CASE WHEN SARCHKL_CKST_CODE='VALIDADO' THEN 1 ELSE 0 END) into valid
         from SARCHKL
         join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_prog
                         and SARADAP_APPL_NO = SARCHKL_APPL_NO
         join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
       where SARCHKL_PIDM = p_pidm
         And SARCHKL_ADMR_CODE =docto;

  Exception
    When Others then
       DBMS_OUTPUT.PUT_LINE('ERROR: AL BUSCAR DOCUMENTOS DEL ALUMNO ');
       retorno:='SIN DOCUMENTOS DEL ALUMNO';
       indice:=100;
       exit;
   end;

     total1:=total1+NVL(valid,0);

  exit when docto is null;

  indice:=indice+1;

 end loop;

        select SUM(CASE WHEN SARCHKL_CKST_CODE='DEVUELTO' THEN 1 ELSE 0 END) into devue
         from SARCHKL
         join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_prog
                         and SARADAP_APPL_NO = SARCHKL_APPL_NO
         join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
       where SARCHKL_PIDM = p_pidm
         And SARCHKL_ADMR_CODE IN ('CTBD','CTLD','CTMD');

       select SUM(CASE WHEN SARCHKL_CKST_CODE='PRESTAMO' THEN 1 ELSE 0 END) into prest
         from SARCHKL
         join saradap on saradap_pidm = SARCHKL_PIDM and SARADAP_PROGRAM_1 = p_prog
                         and SARADAP_APPL_NO = SARCHKL_APPL_NO
         join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = '35' and SARAPPD_APPL_NO = SARADAP_APPL_NO
       where SARCHKL_PIDM = p_pidm
         And SARCHKL_ADMR_CODE IN ('CTBD','CTLD','CTMD');

     total2:=total2+NVL(devue,0);
     total3:=total3+NVL(prest,0);

--       dbms_output.put_line('documento '||docto||'  '||VALID||'  INDICE '||indice||' total1  '||total1);

   IF total1=indice-1 THEN
    retorno:='COMPLETO';
   ELSE
    retorno:='RECOLECCION';
   END IF;

   IF total2>=1 THEN
    retorno:='DEVUELTO';
   END IF;

   IF total3>=1 THEN
    retorno:='PRESTAMO';
   END IF;

 return(retorno);

   indice:=0;
   valid:=0;
   devue:=0;
   prest:=0;
   total1:=0;
   total2:=0;
   total3:=0;
   docto:=NULL;

--      dbms_output.put_line('Resulta  '||retorno);

end;


procedure p_estatus_gral as


Begin


         Begin
                 EXECUTE IMMEDIATE 'TRUNCATE TABLE SATURN.SZREGRL';
                COMMIT;
         Exception
         When Others then
            null;
         End;



                for cx1 in (

  SELECT DISTINCT matricula,
                  Estudiante,
                  Estatus_Code,
                  Estatus,
                  Campus,
                  Nivel,
                  Programa,
                  trunc (FECHA_ACTIVIDAD) fecha_actividad,
                  TRUNC (fechainicio) Fecha_Inicio,
                  TIPO,
                  Tipo_Ingreso,
                  trunc (fecha_registro) fecha_registro ,
                  clave_canal,
                  canal_final,
                  TRUNC (fecha_nac) Fecha_Nac,
                  correo,
                  pago,
                  saldo,
                  decision,
                  Usuario_Decision,
                  TRUNC (Fecha_Decision) Fecha_Decision,
                  TRUNC (Fecha_Inscripcion) Fecha_Inscripcion,
                  Periodo_Matriculacion,
                  Estatus_Solicitud,
                  (      select 
                                distinct GORADID_ADDITIONAL_ID 
                          from goradid 
                          where goradid_pidm=fget_pidm(matricula) and 
                                GORADID_ADID_CODE='SOSD' AND
                                GORADID_ACTIVITY_DATE IN (SELECT MAX(GORADID_ACTIVITY_DATE) FROM GORADID G
                                                           WHERE G.goradid_pidm=fget_pidm(matricula) and 
                                                                 G.GORADID_ADID_CODE='SOSD')
                  )Estatus_SOSD
from (
 with decision1 as  (
SELECT DISTINCT p.saradap_pidm PIDM,
                p.saradap_program_1 PROGRAMA,
                d.sarappd_apdc_code decision,
                d.sarappd_user usuario,
                d.sarappd_activity_date fecha_des,
                p.saradap_term_code_entry periodo,
                p.saradap_curr_rule_1 currule,
                d.sarappd_appl_no
  FROM sarappd d, saradap p
 WHERE     1 = 1
       AND d.sarappd_pidm = p.saradap_pidm
       AND d.sarappd_appl_no = p.saradap_appl_no
       AND d.sarappd_term_code_entry = p.saradap_term_code_entry
       AND p.SARADAP_APST_CODE IN ('A', 'R')
       AND d.sarappd_seq_no =
              (SELECT MAX (pp.sarappd_seq_no)
                 FROM sarappd pp
                WHERE d.sarappd_pidm = pp.sarappd_pidm
                      AND d.sarappd_term_code_entry =
                             pp.sarappd_term_code_entry
                      AND d.SARAPPD_APPL_NO = pp.SARAPPD_APPL_NO)
       AND d.sarappd_appl_no = (SELECT MAX (ppl.sarappd_appl_no)
                                  FROM sarappd ppl
                                 WHERE d.sarappd_pidm = ppl.sarappd_pidm--And p.SARADAP_APPL_NO = ppl.SARAPPD_SEQ_NO
           )
                    )
SELECT DISTINCT
                        b.spriden_id Matricula,
                        b.spriden_first_name||' '||spriden_last_name Estudiante,
                        a.ESTATUS Estatus_Code ,
                        a.ESTATUS_D Estatus,
                        a.CAMPUS Campus,
                        a.NIVEL Nivel,
                        a.PROGRAMA ||' '|| a.NOMBRE Programa ,
                        a.FECHA_MOV FECHA_ACTIVIDAD,
                        a.FECHA_INICIO fechainicio,
                        STVSTYP_DESC TIPO,
                        a.TIPO_INGRESO_DESC Tipo_Ingreso,
                        a.FECHA_MOV fecha_registro,
                        nvl (vend.saracmt_comment_text, '05') clave_canal,
                        nvl(geo.STVGEOD_DESC, 'CALL CENTER PROFESIONAL' )canal_final,
                        SPBPERS_BIRTH_DATE fecha_nac,
                        GOREMAL_EMAIL_ADDRESS correo,
                        'Validado' pago,
                        des.decision decision,
                        des.usuario usuario_decision,
                        des.fecha_des fecha_Decision,
                        nvl (d.SGBSTDN_ACTIVITY_DATE, d.SGBSTDN_ACTIVITY_DATE)  Fecha_Inscripcion,
                        a.MATRICULACION Periodo_Matriculacion,
                        case
                        when SPRTELE_PRIMARY_IND = 'Y' then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                        when SPRTELE_PRIMARY_IND = 'N' then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                        when SPRTELE_PRIMARY_IND is null then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                         end as Celular,
                        (SELECT SUM(TBRACCD_BALANCE) FROM TBRACCD WHERE TBRACCD_PIDM = a.pidm) saldo,
                        null Estatus_Solicitud,
                        SPRADDR_STREET_LINE1 Direccion,
                        SPRADDR_STREET_LINE3 Colonia,
                        STVCNTY_DESC Localidad,
                        STVSTAT_DESC Estado,
                        STVNATN_NATION Pais,
                        case when GORADID_ADID_CODE = 'INBE' then 'INBEC'
                        when GORADID_ADID_CODE = 'NOMR' then 'NO MOLESTAR'
                        when GORADID_ADID_CODE = 'INBC' then 'ALUMNO INBEC'
                        WHEN GORADID_ADID_CODE = 'FREE' THEN 'FREEMIUM 15 DIAS'
                        WHEN GORADID_ADID_CODE = 'FR30' THEN 'FREEMIUM 30 DIAS'
                        when GORADID_ADID_CODE = 'EXAL' THEN 'EXPEDIENTE ENVIADO A ALIANZA'
                        else Null
                        end as Etiqueta,
                        STVMRTL_DESC Estado_Civil,
                        case when SPBPERS_SEX = 'F' then 'Femenino'
                                when SPBPERS_SEX = 'M' then 'Masculino'
                                else 'No_Disponible'
                        end as Sexo,
                        pkg_utilerias.f_Salario_Mensual( a.pidm)  Ingreso_Mensual,
                        (select distinct SARACMT_COMMENT_TEXT
                            from SARACMT sarax
                            where sarax.SARACMT_PIDM = SPRIDEN_PIDM
                            and sarax.SARACMT_ORIG_CODE in ('EGTL', 'EGEX', 'EGRE')
                            and sarax.SARACMT_APPL_NO = des.sarappd_appl_no
                            And sarax.SARACMT_SEQNO = (select max (sarax1.SARACMT_SEQNO)
                                                                    from SARACMT sarax1
                                                                    Where sarax.SARACMT_PIDM = sarax1.SARACMT_PIDM
                                                                    And sarax.SARACMT_APPL_NO = sarax1.SARACMT_APPL_NO)
                            ) Estatus_egreso,
                        SZTBNDA_OBS OBSERVACIONES,
                        SZTBNDA_CRSE_SUBJ CURSO,
                        SZTBNDA_ACTIVITY_DATE FECHA_ENROLAMIENTO
--                        'parte1' parte
from MIGRA.TZTPROG_DEV a--tztprog a
join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
left join sgbstdn d on  d.sgbstdn_pidm=spriden_pidm
And d.SGBSTDN_CAMP_CODE = a.campus
And d.SGBSTDN_LEVL_CODE = a.nivel
and d.SGBSTDN_TERM_CODE_EFF = (select max(d1.SGBSTDN_TERM_CODE_EFF)
                                                        from sgbstdn d1
                                                        Where d.sgbstdn_pidm = d1.sgbstdn_pidm
                                                        And d.SGBSTDN_CAMP_CODE = d1.SGBSTDN_CAMP_CODE
                                                        And d.SGBSTDN_LEVL_CODE = d1.SGBSTDN_LEVL_CODE
                                                        And d.SGBSTDN_PROGRAM_1 = d1.SGBSTDN_PROGRAM_1)
left join decision1 des on des.pidm=a.pidm
left outer join SARACMT vend  ON vend.saracmt_pidm = a.pidm
                                             and vend.saracmt_orig_code='CANF'
                                             and VEND.SARACMT_APPL_NO=(select max (cmt.SARACMT_APPL_NO)
                                                                                            from SARACMT cmt
                                                                                             Where cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                                            And cmt.saracmt_orig_code='CANF')
                                             and vend.SARACMT_SEQNO in  (select max (cmt.SARACMT_SEQNO)
                                                                                            from SARACMT cmt
                                                                                             Where cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                                            And cmt.saracmt_orig_code='CANF')
left outer join STVGEOD geo on lpad (trim (substr (vend.SARACMT_COMMENT_TEXT, 1, 2)), 2, '0') = geo.STVGEOD_CODE
join STVSTYP on a.SGBSTDN_STYP_CODE=STVSTYP_CODE
left outer join SPBPERS on spbpers_pidm=spriden_pidm
left outer join STVMRTL on SPBPERS_MRTL_CODE = STVMRTL_CODE
left outer join GOREMAL gore on gore.goremal_pidm=spriden_pidm
        and gore.goremal_emal_code='PRIN'
        and gore.goremal_status_ind='A'
        And gore.GOREMAL_SURROGATE_ID = (select max (gore1.GOREMAL_SURROGATE_ID)
                                                                  from GOREMAL gore1
                                                                  Where gore.goremal_pidm = gore1.goremal_pidm
                                                                   and gore.goremal_emal_code= gore1.goremal_emal_code
                                                                   and gore.goremal_status_ind= gore1.goremal_status_ind
                                                                   )
left outer join SPRADDR on SPRADDR_pidm=spriden_pidm and SPRADDR_ATYP_CODE = 'RE'
left join STVCNTY on SPRADDR_CNTY_CODE = STVCNTY_CODE
left join STVSTAT on SPRADDR_STAT_CODE = STVSTAT_CODE
left join STVNATN on SPRADDR_NATN_CODE = STVNATN_CODE
left outer join GORADID on a.pidm = GORADID_PIDM AND GORADID_ADID_CODE in ('INBE', 'NOMR', 'INBC', 'FREE', 'FR30')
left outer join sprtele tele  on a.pidm = tele.sprtele_pidm
                     AND tele.SPRTELE_TELE_CODE = 'CELU'
                     And tele.SPRTELE_SURROGATE_ID = (select max (tele1.SPRTELE_SURROGATE_ID)
                                                                              from SPRTELE tele1
                                                                              Where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                              And  tele.SPRTELE_TELE_CODE =  tele1.SPRTELE_TELE_CODE)
left join SZTBNDA on a.pidm = SZTBNDA_PIDM
    and a.nivel = SZTBNDA_LEVL_CODE
    and a.campus = SZTBNDA_CAMP_CODE
    and SZTBNDA_STAT_IND=1
    and SZTBNDA_SEQ_NO=(SELECT MAX(da.SZTBNDA_SEQ_NO)
                                    FROM SZTBNDA da
                                   WHERE 1=1
                                     AND sztbnda_pidm=da.sztbnda_pidm
                                     AND sztbnda_levl_code=da.sztbnda_levl_code
                                     AND sztbnda_camp_code=da.sztbnda_camp_code)
Where  1= 1
union
Select distinct
                      b.spriden_id Matricula,
                      b.spriden_first_name||' '||b.spriden_last_name Estudiante,
                      a.estatus Estatus_Code ,
                      a.estatus_d Estatus,
                      a.campus Campus,
                      a.nivel Nivel,
                      a.programa ||' '|| a.nombre Programa,
                      a.FECHA_MOV FECHA_ACTIVIDAD,
                      a.fecha_inicio fechainicio,
                      STVSTYP_DESC TIPO,
                      a.TIPO_INGRESO_DESC Tipo_Ingreso,
                      s.saradap_appl_date fecha_registro,
                       nvl (vend.saracmt_comment_text, '05') clave_canal,
                        nvl(geo.STVGEOD_DESC, 'CALL CENTER PROFESIONAL' )canal_final,
                     spbpers_birth_date fecha_nac,
                     goremal_email_address correo,
                     sarchkl_ckst_code pago,
                     sarappd_apdc_code decision,
                     sarappd_user usuario_decision,
                     sarappd_apdc_date fecha_Decision,
                     sarappd_apdc_date Fecha_Inscripcion,
                     a.MATRICULACION Periodo_Matriculacion,
                     case
                        when SPRTELE_PRIMARY_IND = 'Y' then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                        when SPRTELE_PRIMARY_IND = 'N' then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                        when SPRTELE_PRIMARY_IND is null then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                         end as Celular,
                     (SELECT SUM(TBRACCD_BALANCE) FROM TBRACCD WHERE TBRACCD_PIDM = a.pidm) saldo,
                     null Estatus_Solicitud,
                     SPRADDR_STREET_LINE1 Direccion,
                     SPRADDR_STREET_LINE3 Colonia,
                     STVCNTY_DESC Localidad,
                     STVSTAT_DESC Estado,
                     STVNATN_NATION Pais,
                     case when GORADID_ADID_CODE = 'INBE' then 'INBEC'
                     when GORADID_ADID_CODE = 'NOMR' then 'NO MOLESTAR'
                     when GORADID_ADID_CODE = 'INBC' then 'ALUMNO INBEC'
                     WHEN GORADID_ADID_CODE = 'FREE' THEN 'FREEMIUM 15 DIAS'
                     WHEN GORADID_ADID_CODE = 'FR30' THEN 'FREEMIUM 30 DIAS'
                     when GORADID_ADID_CODE = 'EXAL' THEN 'EXPEDIENTE ENVIADO A ALIANZA'
                     else Null
                     end as Etiqueta,
                     STVMRTL_DESC Estado_Civil,
                    case when SPBPERS_SEX = 'F' then 'Femenino'
                            when SPBPERS_SEX = 'M' then 'Masculino'
                            else 'No_Disponible'
                    end as Sexo,
                   pkg_utilerias.f_Salario_Mensual( a.pidm)  Ingreso_Mensual,
                    (select distinct SARACMT_COMMENT_TEXT
                            from SARACMT sarax
                            where sarax.SARACMT_PIDM = SPRIDEN_PIDM
                            and sarax.SARACMT_ORIG_CODE in ('EGTL', 'EGEX', 'EGRE')
                            And sarax.SARACMT_SEQNO = (select max (sarax1.SARACMT_SEQNO)
                                                                    from SARACMT sarax1
                                                                    Where sarax.SARACMT_PIDM = sarax1.SARACMT_PIDM
                                                                    And sarax.SARACMT_APPL_NO = sarax1.SARACMT_APPL_NO)
                            ) Estatus_egreso,
                    SZTBNDA_OBS OBSERVACIONES,
                    SZTBNDA_CRSE_SUBJ CURSO,
                    SZTBNDA_ACTIVITY_DATE FECHA_ENROLAMIENTO
--                    'parte2' parte
from MIGRA.TZTPROG_DEV a--tztprog a
join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
left outer join SARADAP s on saradap_pidm=a.pidm
        and s.saradap_term_code_entry=a.matriculacion
        and s.SARADAP_PROGRAM_1 = a.programa
        and s.SARADAP_APPL_NO in (select max(ss.SARADAP_APPL_NO)
                                                  from saradap ss
                                                     where s.saradap_pidm=ss.saradap_pidm
                                                       and s.saradap_program_1=ss.saradap_program_1)
join STVADMT on s.SARADAP_ADMT_CODE = STVADMT_CODE
left outer join SARACMT vend  ON vend.saracmt_pidm = s.saradap_pidm
                                             and vend.saracmt_orig_code='CANF'
                                             and VEND.SARACMT_APPL_NO=(select max (cmt.SARACMT_APPL_NO)
                                                                                            from SARACMT cmt
                                                                                             Where cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                                            And cmt.saracmt_orig_code='CANF')
                                             and vend.SARACMT_SEQNO in  (select max (cmt.SARACMT_SEQNO)
                                                                                            from SARACMT cmt
                                                                                             Where cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                                            And cmt.saracmt_orig_code='CANF')
left outer join STVGEOD geo on lpad (trim (substr (vend.SARACMT_COMMENT_TEXT, 1, 2)), 2, '0') = geo.STVGEOD_CODE
join STVSTYP on a.SGBSTDN_STYP_CODE=STVSTYP_CODE
left outer join SPBPERS on spbpers_pidm=spriden_pidm
left outer join STVMRTL on SPBPERS_MRTL_CODE = STVMRTL_CODE
left outer join GOREMAL gore on gore.goremal_pidm=spriden_pidm
        and gore.goremal_emal_code='PRIN'
        and gore.goremal_status_ind='A'
        And gore.GOREMAL_SURROGATE_ID = (select max (gore1.GOREMAL_SURROGATE_ID)
                                                                  from GOREMAL gore1
                                                                  Where gore.goremal_pidm = gore1.goremal_pidm
                                                                   and gore.goremal_emal_code= gore1.goremal_emal_code
                                                                   and gore.goremal_status_ind= gore1.goremal_status_ind
                                                                   )
left outer join SPRADDR on SPRADDR_pidm=spriden_pidm and SPRADDR_ATYP_CODE = 'RE'
left join STVCNTY on SPRADDR_CNTY_CODE = STVCNTY_CODE
left join STVSTAT on SPRADDR_STAT_CODE = STVSTAT_CODE
left join STVNATN on SPRADDR_NATN_CODE = STVNATN_CODE
left outer join GORADID on a.PIDM = GORADID_PIDM AND GORADID_ADID_CODE in ('INBE', 'NOMR', 'INBC', 'FREE', 'FR30')
left outer join  SARCHKL on sarchkl_pidm=saradap_pidm and sarchkl_term_code_entry=saradap_term_code_entry and sarchkl_appl_no=saradap_appl_no
                                                                                                          and sarchkl_admr_code='PAGD'
left outer join SARAPPD ss on sarappd_pidm=saradap_pidm and sarappd_term_code_entry=saradap_term_code_entry and sarappd_appl_no=saradap_appl_no
                                                                                            and SARAPPD_SEQ_NO =(select max(SARAPPD_SEQ_NO)
                                                                                            from SARAPPD s
                                                                                            where ss.sarappd_pidm = s.sarappd_pidm
                                                                                            and ss.SARAPPD_TERM_CODE_ENTRY = s.SARAPPD_TERM_CODE_ENTRY
                                                                                            and ss.SARAPPD_APPL_NO = s.SARAPPD_APPL_NO)
left outer join sprtele tele  on a.pidm = tele.sprtele_pidm
                     AND tele.SPRTELE_TELE_CODE = 'CELU'
                     And tele.SPRTELE_SURROGATE_ID = (select max (tele1.SPRTELE_SURROGATE_ID)
                                                                              from SPRTELE tele1
                                                                              Where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                              And  tele.SPRTELE_TELE_CODE =  tele1.SPRTELE_TELE_CODE)
left join SZTBNDA on a.PIDM = SZTBNDA_PIDM
      and a.nivel = SZTBNDA_LEVL_CODE
      and a.campus = SZTBNDA_CAMP_CODE
      and SZTBNDA_STAT_IND=1
      and SZTBNDA_SEQ_NO=(SELECT MAX(da.SZTBNDA_SEQ_NO)
                                    FROM SZTBNDA da
                                   WHERE 1=1
                                     AND sztbnda_pidm=da.sztbnda_pidm
                                     AND sztbnda_levl_code=da.sztbnda_levl_code
                                     AND sztbnda_camp_code=da.sztbnda_camp_code)
Where a.pidm not in (select sgbstdn_pidm from sgbstdn where sgbstdn_levl_code=a.nivel)
union
Select distinct
                        b.spriden_id Matricula,
                        b.spriden_first_name||' '||spriden_last_name Estudiante,
                        a.estatus Estatus_Code ,
                        a.estatus_d Estatus,
                        SZVCAMP_CAMP_CODE Campus,
                        a.nivel Nivel,
                        a.programa ||' '|| a.nombre Programa ,
                        a.FECHA_MOV FECHA_ACTIVIDAD,
                        a.fecha_inicio fechainicio,
                        STVSTYP_DESC TIPO,
                        a.TIPO_INGRESO_DESC Tipo_Ingreso,
                        SGBSTDN_ACTIVITY_DATE fecha_registro,
                        nvl (vend.saracmt_comment_text, '05') clave_canal,
                        nvl(geo.STVGEOD_DESC, 'CALL CENTER PROFESIONAL' )canal_final,
                        SPBPERS_BIRTH_DATE fecha_nac,
                        GOREMAL_EMAIL_ADDRESS correo,
                        'Validado' pago,
                        des.decision decision,
                        des.usuario usuario_decision,
                        des.fecha_des fecha_Decision,
                        nvl (SGBSTDN_ACTIVITY_DATE, d.SGBSTDN_ACTIVITY_DATE)  Fecha_Inscripcion,
                        a.MATRICULACION Periodo_Matriculacion,
                        case
                        when SPRTELE_PRIMARY_IND = 'Y' then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                        when SPRTELE_PRIMARY_IND = 'N' then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                        when SPRTELE_PRIMARY_IND is null then
                                 (SPRTELE_PHONE_AREA||SPRTELE_PHONE_NUMBER)
                         end as Celular,
                        (SELECT SUM(TBRACCD_BALANCE) FROM TBRACCD WHERE TBRACCD_PIDM = a.pidm) saldo,
                        null Estatus_Solicitud,
                        SPRADDR_STREET_LINE1 Direccion,
                        SPRADDR_STREET_LINE3 Colonia,
                        STVCNTY_DESC Localidad,
                        STVSTAT_DESC Estado,
                        STVNATN_NATION Pais,
                        case when GORADID_ADID_CODE = 'INBE' then 'INBEC'
                        when GORADID_ADID_CODE = 'NOMR' then 'NO MOLESTAR'
                        when GORADID_ADID_CODE = 'INBC' then 'ALUMNO INBEC'
                        WHEN GORADID_ADID_CODE = 'FREE' THEN 'FREEMIUM 15 DIAS'
                        WHEN GORADID_ADID_CODE = 'FR30' THEN 'FREEMIUM 30 DIAS'
                        when GORADID_ADID_CODE = 'EXAL' THEN 'EXPEDIENTE ENVIADO A ALIANZA'
                        else Null
                        end as Etiqueta,
                        STVMRTL_DESC Estado_Civil,
                        case when SPBPERS_SEX = 'F' then 'Femenino'
                                when SPBPERS_SEX = 'M' then 'Masculino'
                                else 'No_Disponible'
                        end as Sexo,
                        pkg_utilerias.f_Salario_Mensual( a.pidm)  Ingreso_Mensual,
                              (select distinct SARACMT_COMMENT_TEXT
                            from SARACMT sarax
                            where sarax.SARACMT_PIDM = SPRIDEN_PIDM
                            and sarax.SARACMT_ORIG_CODE in ('EGTL', 'EGEX', 'EGRE')
                            and sarax.SARACMT_APPL_NO = des.sarappd_appl_no
                            And sarax.SARACMT_SEQNO = (select max (sarax1.SARACMT_SEQNO)
                                                                    from SARACMT sarax1
                                                                    Where sarax.SARACMT_PIDM = sarax1.SARACMT_PIDM
                                                                    And sarax.SARACMT_APPL_NO = sarax1.SARACMT_APPL_NO)
                            ) Estatus_egreso,
                        SZTBNDA_OBS OBSERVACIONES,
                        SZTBNDA_CRSE_SUBJ CURSO,
                        SZTBNDA_ACTIVITY_DATE FECHA_ENROLAMIENTO
--                        'parte3' parte
from MIGRA.TZTPROG_DEV a --tztprog a
join spriden b on b.spriden_pidm = a.pidm and b.spriden_change_ind is null
join sgbstdn d on  d.sgbstdn_pidm=spriden_pidm
And d.SGBSTDN_CAMP_CODE = a.campus
And d.SGBSTDN_LEVL_CODE = a.nivel
and d.SGBSTDN_TERM_CODE_EFF = (select max(d1.SGBSTDN_TERM_CODE_EFF)
                                                                                                                                from sgbstdn d1
                                                                                                                                Where d.sgbstdn_pidm = d1.sgbstdn_pidm
                                                                                                                                And d.SGBSTDN_CAMP_CODE = d1.SGBSTDN_CAMP_CODE
                                                                                                                                And d.SGBSTDN_LEVL_CODE = d1.SGBSTDN_LEVL_CODE
                                                                                                                                And d.SGBSTDN_PROGRAM_1 = d1.SGBSTDN_PROGRAM_1)
join decision1 des on des.pidm=a.pidm
and a.programa=des.programa
and a.matriculacion=des.periodo
AND d.sgbstdn_term_code_eff = (SELECT DISTINCT MAX (A1.sgbstdn_term_code_eff)
                           FROM sgbstdn A1
                           WHERE 1=1
                           AND d.sgbstdn_pidm= a1.sgbstdn_pidm
                           and d.sgbstdn_program_1= a1.sgbstdn_program_1
                           AND d.sgbstdn_term_code_ctlg_1 = a1.sgbstdn_term_code_ctlg_1
                           )
join STVSTST on d.sgbstdn_stst_code=STVSTST_CODE
join SZVCAMP on szvcamp_camp_alt_code=substr(a.matriculacion,1,2)
left outer join SARACMT vend  ON vend.saracmt_pidm = a.pidm
                                             and vend.saracmt_orig_code='CANF'
                                             and VEND.SARACMT_APPL_NO=(select max (cmt.SARACMT_APPL_NO)
                                                                                            from SARACMT cmt
                                                                                             Where cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                                            And cmt.saracmt_orig_code='CANF')
                                             and vend.SARACMT_SEQNO in  (select max (cmt.SARACMT_SEQNO)
                                                                                            from SARACMT cmt
                                                                                             Where cmt.SARACMT_PIDM = vend.SARACMT_PIDM
                                                                                            And cmt.saracmt_orig_code='CANF')
left outer join STVGEOD geo on lpad (trim (substr (vend.SARACMT_COMMENT_TEXT, 1, 2)), 2, '0') = geo.STVGEOD_CODE
join STVSTYP on a.SGBSTDN_STYP_CODE=STVSTYP_CODE
left outer join SPBPERS on spbpers_pidm=spriden_pidm
left outer join STVMRTL on SPBPERS_MRTL_CODE = STVMRTL_CODE
left outer join GOREMAL gore on gore.goremal_pidm=spriden_pidm
        AND gore.goremal_emal_code='PRIN'
        AND gore.goremal_status_ind='A'
        AND gore.GOREMAL_SURROGATE_ID = (select max (gore1.GOREMAL_SURROGATE_ID)
                                                                  from GOREMAL gore1
                                                                  Where gore.goremal_pidm = gore1.goremal_pidm
                                                                   and gore.goremal_emal_code= gore1.goremal_emal_code
                                                                   and gore.goremal_status_ind= gore1.goremal_status_ind
                                                                   )
left outer join SPRADDR on SPRADDR_pidm=spriden_pidm and SPRADDR_ATYP_CODE = 'RE'
left join STVCNTY on SPRADDR_CNTY_CODE = STVCNTY_CODE
left join STVSTAT on SPRADDR_STAT_CODE = STVSTAT_CODE
left join STVNATN on SPRADDR_NATN_CODE = STVNATN_CODE
left outer join GORADID on a.PIDM = GORADID_PIDM AND GORADID_ADID_CODE in ('INBE', 'NOMR', 'INBC', 'FREE', 'FR30')
left outer join sprtele tele  on a.pidm = tele.sprtele_pidm
                     AND tele.SPRTELE_TELE_CODE = 'CELU'
                     And tele.SPRTELE_SURROGATE_ID = (select max (tele1.SPRTELE_SURROGATE_ID)
                                                                              from SPRTELE tele1
                                                                              Where tele.sprtele_pidm = tele1.sprtele_pidm
                                                                              And  tele.SPRTELE_TELE_CODE =  tele1.SPRTELE_TELE_CODE)
left join SZTBNDA on a.PIDM = SZTBNDA_PIDM
        AND a.nivel = sztbnda_levl_code
        AND a.campus = sztbnda_camp_code
        AND sztbnda_stat_ind=1
        AND sztbnda_seq_no=(SELECT MAX(da.sztbnda_seq_no)
                                    FROM sztbnda da
                                   WHERE 1=1
                                     AND sztbnda_pidm=da.sztbnda_pidm
                                     AND sztbnda_levl_code=da.sztbnda_levl_code
                                     AND sztbnda_camp_code=da.sztbnda_camp_code)
Where  a.pidm=d.sgbstdn_pidm
and a.programa=d.sgbstdn_program_1
and a.ctlg=d.sgbstdn_term_code_ctlg_1
AND a.nivel = d.sgbstdn_levl_code
union
select TZTPAGO_ID Matricula,
          b.spriden_first_name||' '||spriden_last_name Estudiante,
          null Estatus_Code ,
          null Estatus,
          TZTPAGO_CAMP Campus,
          TZTPAGO_LEVL Nivel,
          null Programa,
          null FECHA_ACTIVIDAD,
          TZTPAGO_FECHA_INI fechainicio ,
          'PROSPECTO' TIPO,
          null Tipo_Ingreso,
          null fecha_registro,
          TZTPAGO_CANAL clave_canal,
          null canal_final,
          null fecha_nac,
          TZTPAGO_EMAIL correo,
          TZTPAGO_STAT_DOCTO pago,
          null decision,
          null usuario_decision,
          null fecha_Decision,
          null  Fecha_Inscripcion,
          TZTPAGO_TERM_CODE Periodo_Matriculacion,
          null Celular,
          (SELECT SUM(TBRACCD_BALANCE) FROM TBRACCD WHERE TBRACCD_PIDM = spriden_pidm) saldo,
          TZTPAGO_STAT_SOLIC Estatus_Solicitud,
          Null Direccion,
          Null Colonia,
          Null Localidad,
          Null Estado,
          Null Pais,
          Null Etiqueta,
          Null Estado_Civil,
          Null Sexo,
          Null Saldo_Mensual,
                                  (select distinct SARACMT_COMMENT_TEXT
                            from SARACMT sarax
                            where sarax.SARACMT_PIDM = SPRIDEN_PIDM
                            and sarax.SARACMT_ORIG_CODE in ('EGTL', 'EGEX', 'EGRE')
                            And sarax.SARACMT_SEQNO = (select max (sarax1.SARACMT_SEQNO)
                                                                    from SARACMT sarax1
                                                                    Where sarax.SARACMT_PIDM = sarax1.SARACMT_PIDM
                                                                    And sarax.SARACMT_APPL_NO = sarax1.SARACMT_APPL_NO)
                            ) Estatus_egreso,
          Null OBSERVACIONES,
          Null CURSO,
          Null FECHA_ENROLAMIENTO
--          'parte4' parte
from TZTPAGO, SPRIDEN b
WHERE SPRIDEN_ID = TZTPAGO_ID
And SPRIDEN_CHANGE_IND is null
and spriden_pidm not in (select saradap_pidm
                                from saradap)
)
WHERE 1= 1
--AND MATRICULA IN ('010017225')
order by 1 desc



                ) loop

                          Begin
                                    Insert into saturn.SZREGRL values (cx1.MATRICULA,
                                                                        cx1.ESTUDIANTE,
                                                                        cx1.ESTATUS_CODE,
                                                                        cx1.ESTATUS,
                                                                        cx1.CAMPUS,
                                                                        cx1.NIVEL,
                                                                        cx1.PROGRAMA,
                                                                        cx1.FECHA_ACTIVIDAD,
                                                                        cx1.FECHA_INICIO,
                                                                        cx1.TIPO,
                                                                        cx1.TIPO_INGRESO,
                                                                        cx1.FECHA_REGISTRO,
                                                                        cx1.CLAVE_CANAL,
                                                                        cx1.CANAL_FINAL,
                                                                        cx1.FECHA_NAC,
                                                                        cx1.CORREO,
                                                                        cx1.PAGO,
                                                                        cx1.SALDO,
                                                                        cx1.DECISION,
                                                                        cx1.USUARIO_DECISION,
                                                                        cx1.FECHA_DECISION,
                                                                        cx1.FECHA_INSCRIPCION,
                                                                        cx1.PERIODO_MATRICULACION,
                                                                        cx1.ESTATUS_SOLICITUD,
                                                                        cx1.ESTATUS_SOSD);
                          Exception
                            When Others then
                                null;
                          End;

                          Commit;

                End Loop cx1;

                commit;



End p_estatus_gral;

FUNCTION f_alum_Certif_out (p_matricula in varchar2) RETURN PKG_REPORTES.cursor_out_cert
 AS
 c_out_cert PKG_REPORTES.cursor_out_cert;

 BEGIN
 open c_out_cert
 FOR

select tp.matricula  as matricula,
        SZTRECE_PROGRAM_CERTIF as cve_programa
        ,( SELECT DISTINCT TT.SZTDTEC_PROGRAMA_COMP  FROM SZTDTEC TT WHERE 1=1 AND  TT.SZTDTEC_PROGRAM = SZTRECE_PROGRAM_CERTIF  ) PROGRAMA
        ,decode(SZTRECE_VAL_FIRMA,0,'Iniciado',1,'Proceso',2,'Generado') as estatus
        ,SZTRECE_FOLIO_CONTROL Folio
        , trunc(SZTRECE_ACTIVITY_DATE) as fecha_creacion
        ,tp.campus   as campus
        ,tp.nivel  as nivel
        , tp.estatus as estatus_alumno
          ,'Certificado' as tipo
     --   ,zt.SZTRECE_PIDM_CERTIF
from sztrece zt
,TZTPROG TP
WHERE     1=1
 AND ZT.SZTRECE_PIDM_CERTIF = TP.PIDM
 AND  ZT.SZTRECE_PROGRAM_CERTIF = TP.PROGRAMA
 and zt.SZTRECE_ID =p_matricula
UNION
select  tp.matricula  as matricula,
            SZTTIDI_PROGRAM as cve_programa
        ,( SELECT DISTINCT TT.SZTDTEC_PROGRAMA_COMP  FROM SZTDTEC TT WHERE 1=1 AND  TT.SZTDTEC_PROGRAM = SZTTIDI_PROGRAM  ) PROGRAMA
        ,decode(SZTTIDI_VAL_FIRMA,0,'Iniciado',1,'Proceso',2,'Generado') as estatus
        ,SZTTIDI_FOLIO_CONTROL Folio
        , trunc(SZTTIDI_ACTIVITY_DATE) as fecha_creacion
        ,tp.campus   as campus
        ,tp.nivel  as nivel
        , tp.estatus as estatus_alumno
          ,'Titulo' as tipo
from SZTTIDI zt
,TZTPROG TP
WHERE     1=1
 AND ZT.SZTTIDI_PIDM_TITULO = TP.PIDM
 AND  ZT.SZTTIDI_PROGRAM = TP.PROGRAMA
 and zt.SZTTIDI_ID = p_matricula
ORDER BY 1,2;

 RETURN (c_out_cert);

 END f_alum_Certif_out;


FUNCTION f_alum_Exped_out (p_matricula in varchar2) RETURN PKG_REPORTES.cursor_out_exped
 AS
 c_out_exped PKG_REPORTES.cursor_out_exped;

 BEGIN
 open c_out_exped
 FOR

-- nueva version glovicx 04.08.022
--nueva version de reporte recoleccion glovicx 04/08/022
SELECT  DISTINCT
          NVL(tz.Campus,'NA')Campus,
          NVL(tz.Nivel,'NA')Nivel,
          NVL(tz.Matricula,'NA')Matricula,
             nvl((select max( SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACNO')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Acta_Orig,
                   nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACNO')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Acta_Orig,
                        nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPLO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Parcial,
                        nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPLO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certificado_Parcial,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL ,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Compromiso_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Compromiso_Orig,
                   nvl((select MAX(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Autentic_Certi_Bach_Orig,
                   nvl((select MAX(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') F_Carta_Aut_Certi_Bach_Orig,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Protes_Decir_Verdad_Orig,
                    nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Car_Prot_Decir_Verd_Orig,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CRDO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Responsiva_Orig,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CRDO')
                         and SARCHKL_PIDM =tz.pidm
                             AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Responsiva_Orig,
                   nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_De_Secundaria_Orig,
                    nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certif_De_Sec_Orig,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBO')
                          and SARCHKL_PIDM =tz.pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Total_Bachillerat_Orig,
                   nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Bach_Orig,
                   nvl((select max( SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLO')
                        and SARCHKL_PIDM =tz.pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                      AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certif_Tot_Lic_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLO')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_Orig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Maes_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Maes_Orig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTEO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Especial_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTEO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Especial_Orig,
                      nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Lic_AP_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_AP__Orig,
                     nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Diploma_Titu_Orig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Diploma_Titu_Orig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQIO')
                        and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Equivalencia_De_Estudios_Orig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQIO')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Equiv_De_Estudios_Orig,
                    nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO4O')
                          and SARCHKL_PIDM =tz.pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Infantil_4_BN_M,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO4O')
                        and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Infantil_4_BN_M,
                    nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO6O')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Infantil_6_BN_M,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FO6O')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Infantil_6_BN_M,
                    nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FCOO')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Fotografias_Cert_4_Ova_Creden,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FCOO')
                          and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Foto_Cert_4_Ova_Creden,
                    nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FT6O')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Fotografias_Titulo_6_b_n,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FT6O')
                          and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Fotografias_Titulo_6_b_n,
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILO')
                          and SARCHKL_PIDM =tz.pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Formato_Inscripcion_Alumn_Orig,
                     nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILO')
                           and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Form_Inscr_Alumn_Orig,
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLO')
                        and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Constancia_Laboral_Original,
                     nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLO')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Const_Laboral_Orig,
                     nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACND')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Acta_De_Nacimiento_Digital,
                    nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('ACND')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Acta_De_Nac_Digital,
                   nvl((select  max(SARCHKL_CKST_CODE)
                         from SARCHKL,SARAPPD
                         where SARCHKL_ADMR_CODE in ('CALD')
                           and SARCHKL_PIDM =tz.pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Autentic_Certi_Ba_Dig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CALD')
                        and SARCHKL_PIDM =tz.pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Car_Auten_Certi_Ba_Dig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAMD')
                        and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Motivos_Digital,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAMD')
                         and SARCHKL_PIDM =tz.pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Motivos_Digital,
                   nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Protes_Decir_Verdad_Dig,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CPVD')
                         and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cart_Prot_Decir_Verd_Dig,
                   nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Constancia_Laboral_Digital,
                   nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('COLD')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Const_Lab_Dig,
                  nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACD')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Carta_Compromiso,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CACD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Carta_Comp,
                  nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESD')
                         and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_De_Secundaria_Dig,
                  nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CESD')
                         and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_De_Secundaria_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBD')
                       and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Cert_Total_Bachillerat_Dig,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTBD')
                         and SARCHKL_PIDM =tz.pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Bach_Dig,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLD')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Total_Lic_Dig,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTLD')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Certificado_Tot_Lic_Dig,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Certificado_Total_Maestria_Dig,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTMD')
                        and SARCHKL_PIDM =tz.pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Total_Maestria_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTED')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Especial_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTED')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Especial_Dig,
                      nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Tot_Lic_AP_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTAD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Tot_Lic_AP__Dig,
                     nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cert_Diploma_Titu_Dig,
                     nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CTTD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cert_Diploma_Titu_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PAGD')
                        and SARCHKL_PIDM =tz.pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Pago,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PAGD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Pago,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CUGD')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Ultimo_Grado_De_Estud,
                 nvl((select max (to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CUGD')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Ultimo_Grado_De_Estud,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEGD')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cedula_De_Grado_Digital,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEGD')
                        and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cedula_De_Grado_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEPD')
                         and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Cedula_Profesional_Digital,
                  nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CEPD')
                         and SARCHKL_PIDM =tz.pidm
                            AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Cedula_Profesional_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CODD')
                         and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Comprobante_De_Domicilio,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CODD')
                         and SARCHKL_PIDM =tz.pidm
                         AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Comp_De_Dom,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CURD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') CURP,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CURD')
                        and SARCHKL_PIDM =tz.pidm
                           AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_CURP,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('TITD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Titulo_Digital,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('TITD')
                         and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Titulo_Digital,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('GRAD')
                          and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Grado_Digital,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('GRAD')
                        and SARCHKL_PIDM =tz.pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Grado_Digital,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQUD')
                         and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Equivalencia_De_Estudios_Dig,
                 nvl((select max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('EQUD')
                         and SARCHKL_PIDM =tz.pidm
                          AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Equiv_De_Estudios_Dig,
                 nvl((select  max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILD')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Formato_Inscripcion_Alumn_Dig,
                 nvl((select  max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('FILD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Formato_Inscr_Alumn_Dig,
                 nvl((select  max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('IDOD')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Identificacion_Oficial,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('IDOD')
                        and SARCHKL_PIDM =tz.pidm
                       AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Identificacion_Oficial,
                 nvl((select max (SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('PRED')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Predictamen_De_Equivalencia,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL, SARAPPD
                        where SARCHKL_ADMR_CODE in ('PRED')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Predictamen_De_Equiv,
                 nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('SOAD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA') Solicitud_De_Admision,
                 nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('SOAD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Solicitud_De_Admision,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAPO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Carta_Poder,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('CAPO')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01') Fecha_Solicitud_Carta_Poder,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Revalidacion_Org,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRO')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dic_Rev_Org,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRV')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Revalidacion_Dig,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DIRV')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dict_Reval_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICD')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Sep_Dig,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICD')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dict_Sep_Dig,
                  nvl((select max(SARCHKL_CKST_CODE)
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICO')
                         and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), 'NA')Dictamen_Sep_Original,
                  nvl((select max( to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                        from SARCHKL,SARAPPD
                        where SARCHKL_ADMR_CODE in ('DICO')
                        and SARCHKL_PIDM =tz.pidm
                        AND SARAPPD_PIDM = SARCHKL_PIDM
                        AND SARAPPD_APPL_NO = SARCHKL_APPL_NO), '1900/01/01')Fech_Dictamen_Sep_Ori
       from tztprog_all tz
        LEFT OUTER JOIN SARAPPD ss  ON  TZ.PIDM  = SS.SARAPPD_PIDM
        LEFT OUTER JOIN SARADAP dd  ON  TZ.PIDM  = DD.SARADAP_PIDM  and TZ.CAMPUS=DD.SARADAP_CAMP_CODE and TZ.NIVEL=DD.SARADAP_LEVL_CODE
                      and sS.SARAPPD_APPL_NO = dD.SARADAP_APPL_NO
        LEFT OUTER JOIN SPRIDEN SP  ON  TZ.PIDM  = SP.SPRIDEN_PIDM  AND sp.SPRIDEN_CHANGE_IND   IS NULL
        LEFT OUTER JOIN STVSTYP  y  ON  TZ.SGBSTDN_STYP_CODE  = Y.STVSTYP_CODE
       where 1=1
       and tz.Estatus != 'CP'
       and TZ.NIVEL   = DD.SARADAP_LEVL_CODE
       and TZ.CAMPUS  = dd.SARADAP_CAMP_CODE
       and tz.ctlg   =  dd.SARADAP_TERM_CODE_CTLG_1
       AND SS.SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                       FROM SARAPPD s, saradap d
                                         WHERE 1=1
                                           and S.SARAPPD_PIDM            = D.SARADAP_PIDM
                                           and S.SARAPPD_TERM_CODE_ENTRY = D.SARADAP_TERM_CODE_ENTRY
                                           and S.SARAPPD_APPL_NO         = D.SARADAP_APPL_NO
                                           and ss.sarappd_pidm            = s.sarappd_pidm
                                           and TZ.NIVEL                 = D.SARADAP_LEVL_CODE
                                           )
           and tz.matricula = P_matricula;


 RETURN (c_out_exped);

 END f_alum_Exped_out;


FUNCTION f_alum_Certif_out_mp (p_matricula in varchar2) RETURN PKG_REPORTES.cursor_out_cert_mp
 AS
 c_out_cert_mp PKG_REPORTES.cursor_out_cert_mp;

 BEGIN
 open c_out_cert_mp
 FOR

select tp.matricula  as matricula,
        SZTRECE_PROGRAM_CERTIF as cve_programa
        ,( SELECT DISTINCT TT.SZTDTEC_PROGRAMA_COMP  FROM SZTDTEC TT WHERE 1=1 AND  TT.SZTDTEC_PROGRAM = SZTRECE_PROGRAM_CERTIF  ) PROGRAMA
        ,decode(SZTRECE_VAL_FIRMA,0,'Iniciado',1,'Proceso',2,'Generado') as estatus
        ,SZTRECE_FOLIO_CONTROL Folio
        , trunc(SZTRECE_ACTIVITY_DATE) as fecha_creacion
        ,tp.campus   as campus
        ,STVLEVL_DESC  as nivel
        , tp.estatus as estatus_alumno
          ,'Certificado' as tipo
     --   ,zt.SZTRECE_PIDM_CERTIF
from sztrece zt
,TZTPROG TP
,stvlevl
WHERE     1=1
 AND ZT.SZTRECE_PIDM_CERTIF = TP.PIDM
 AND  ZT.SZTRECE_PROGRAM_CERTIF = TP.PROGRAMA
 and zt.SZTRECE_ID =p_matricula
 And tp.nivel = STVLEVL_CODE
UNION
select  tp.matricula  as matricula,
            SZTTIDI_PROGRAM as cve_programa
        ,( SELECT DISTINCT TT.SZTDTEC_PROGRAMA_COMP  FROM SZTDTEC TT WHERE 1=1 AND  TT.SZTDTEC_PROGRAM = SZTTIDI_PROGRAM  ) PROGRAMA
        ,decode(SZTTIDI_VAL_FIRMA,0,'Iniciado',1,'Proceso',2,'Generado') as estatus
        ,SZTTIDI_FOLIO_CONTROL Folio
        , trunc(SZTTIDI_ACTIVITY_DATE) as fecha_creacion
        ,tp.campus   as campus
        ,STVLEVL_DESC  as nivel
        , tp.estatus as estatus_alumno
          ,'Titulo' as tipo
from SZTTIDI zt
,TZTPROG TP
,stvlevl
WHERE     1=1
 AND ZT.SZTTIDI_PIDM_TITULO = TP.PIDM
 AND  ZT.SZTTIDI_PROGRAM = TP.PROGRAMA
  And tp.nivel = STVLEVL_CODE
 and zt.SZTTIDI_ID = p_matricula
ORDER BY 1,2;

 RETURN (c_out_cert_mp);

 END f_alum_Certif_out_mp;



 procedure p_Acad_Finan_Cons as

 Begin

         Begin
                 EXECUTE IMMEDIATE 'TRUNCATE TABLE TAISMGR.TZRACFI';
                COMMIT;
         Exception
         When Others then
            null;
         End;


        For cx in (

                        SELECT distinct
                              nvl(TZTCRTE_AF_ID, 'NA') matricula,
                              nvl(TZTCRTE_AF_CAMP, 'NA' ) campus,
                              nvl(TZTCRTE_AF_LEVL, 'NA' ) nivel,
                              nvl(SG.SGBSTDN_RATE_CODE , 'NA' ) rate,
                              nvl(TZTCRTE_AF_CAMPO1, 'NA') desc_lvl,
                              nvl(TZTCRTE_AF_CAMPO2,'NA' ) nombre,
                              nvl(TZTCRTE_AF_CAMPO3, 'NA') mail_prin,
                              nvl(TZTCRTE_AF_CAMPO4,'NA') mail_sec,
                              nvl(TZTCRTE_AF_CAMPO5,'NA')  telf_casa,
                              nvl(TZTCRTE_AF_CAMPO6,'NA') telf_cel,
                              nvl(TZTCRTE_AF_CAMPO7,0)  saldo_total,
                              nvl(TZTCRTE_AF_CAMPO8,0)  saldo_vencido,
                              nvl(TZTCRTE_AF_CAMPO9, 0)  numero_cargo_vencido,
                              nvl(TZTCRTE_AF_CAMPO10, '01/01/1900') primer_fecha_limite_de_pago,
                              nvl(TZTCRTE_AF_CAMPO11,'01/01/1900')  ultima_fecha_limite_de_pago,
                              nvl(TZTCRTE_AF_CAMPO12, '0') dias_atraso,
                              nvl(TZTCRTE_AF_CAMPO13,'0')  meses_atraso,
                              nvl(TZTCRTE_AF_CAMPO14,'0')  mora,
                              nvl(TZTCRTE_AF_CAMPO15,'0')  total_montos_prox,
                              nvl(TZTCRTE_AF_CAMPO16,'0')   saldo_prox,
                              nvl(TZTCRTE_AF_CAMPO17,'0')  numero_cargos_proximos,
                                nvl(TZTCRTE_AF_CAMPO18,'01/01/1900')   prox_fecha_limite_pag,
                                nvl(TZTCRTE_AF_CAMPO19,'0')  num_dias_prox_pago,
                                nvl(TZTCRTE_AF_CAMPO20,'0')  suma_depositos,
                                nvl(TZTCRTE_AF_CAMPO21,'0')  numero_depositos,
                                nvl(TZTCRTE_AF_CAMPO22,'0')  monto_incobrable,
                                nvl(TZTCRTE_AF_CAMPO23,'0')  provision_incobrable,
                                nvl(TZTCRTE_AF_CAMPO24,'NA')  ultimo_acceso_plataforma,
                                nvl(TZTCRTE_AF_CAMPO25,'0')  rango_dias_acceso_plataforma,
                                nvl(TZTCRTE_AF_CAMPO26,'0')  jornada_plan,
                                nvl(TZTCRTE_AF_CAMPO27,'0')  carga_academica,
                                nvl(TZTCRTE_AF_CAMPO28,'0')  materias_aprobadas,
                                nvl(TZTCRTE_AF_CAMPO29,'0')  avance_curricular,
                                nvl(TZTCRTE_AF_CAMPO30,'0')  promedios,
                                nvl(TZTCRTE_AF_CAMPO31,'01/01/1900')  fecha_matriculacion,
                                nvl(TZTCRTE_AF_CAMPO32,'0')  ciclo_inicial,
                                nvl(TZTCRTE_AF_CAMPO33,'NA')estado_alumno,
                                nvl(TZTCRTE_AF_CAMPO34, 'NA')programa_code,
                                nvl(TZTCRTE_AF_CAMPO35,'0')   nombre_programa,
                                nvl(TZTCRTE_AF_CAMPO36,'0')   descuento,
                                nvl(TZTCRTE_AF_CAMPO37,'0')   referencia_bancaria,
                            nvl(TZTCRTE_AF_CAMPO38,'0') tipo_ingreso, ---campo 38
                            nvl(TZTCRTE_AF_CAMPO40,'NA') etiqueta,  ----COLUMA40
                                nvl(TZTCRTE_AF_TIPO_REPORTE,'0')   nom_reporte,
                                    CASE
                            when c.GORADID_ADID_CODE = 'INBE' then 'INBEC'
                            when c.GORADID_ADID_CODE = 'INBC' then 'INBEC'
                            when c.GORADID_ADID_CODE = 'EUTL' then 'EMPLEADO'
                            when c.GORADID_ADID_CODE = 'FUTL' then 'FAMILIAR'
                            when c.GORADID_ADID_CODE = 'FR30' then 'FREEMIUM'
                            when c.GORADID_ADID_CODE = 'FR60' then 'FREEMIUM'
                            when c.GORADID_ADID_CODE = 'FREE' then 'FREEMIUM'
                            else null
                            END ETIQUETA2
                           from TZTCRTE_AF e
                            left join sgbstdn sg on sg.sgbstdn_pidm = e.TZTCRTE_AF_PIDM and sg.sgbstdn_program_1 = e.TZTCRTE_AF_CAMPO34
                               and sg.sgbstdn_term_code_eff =(select max(b.sgbstdn_term_code_eff)
                                                                                from sgbstdn b
                                                                                where b.sgbstdn_pidm = sg.sgbstdn_pidm)
                           left join GORADID c on e.TZTCRTE_AF_PIDM = c.GORADID_PIDM
                            and c.GORADID_ADID_CODE in ('INBE', 'INBC', 'EUTL', 'FUTL', 'FR30', 'FR60', 'FREE')
                           where e.TZTCRTE_AF_TIPO_REPORTE = 'Academico_Financiero'
                          -- and e.TZTCRTE_AF_ID = '010017225'

            ) loop

                        Begin
                                Insert into TZRACFI values ( cx.matricula,
                                                                          cx.campus,
                                                                          cx.nivel,
                                                                          cx.rate,
                                                                          cx.desc_lvl,
                                                                          cx.nombre,
                                                                          cx.mail_prin,
                                                                          cx.mail_sec,
                                                                          cx.telf_casa,
                                                                          cx.telf_cel,
                                                                          cx.saldo_total,
                                                                          cx.saldo_vencido,
                                                                          cx.numero_cargo_vencido,
                                                                          cx.primer_fecha_limite_de_pago,
                                                                          cx.ultima_fecha_limite_de_pago,
                                                                          cx.dias_atraso,
                                                                          cx.meses_atraso,
                                                                          cx.mora,
                                                                          cx.total_montos_prox,
                                                                          cx.saldo_prox,
                                                                          cx.numero_cargos_proximos,
                                                                          cx.prox_fecha_limite_pag,
                                                                          cx.num_dias_prox_pago,
                                                                          cx.suma_depositos,
                                                                          cx.numero_depositos,
                                                                          cx.monto_incobrable,
                                                                          cx.provision_incobrable,
                                                                          cx.ultimo_acceso_plataforma,
                                                                          cx.rango_dias_acceso_plataforma,
                                                                          cx.jornada_plan,
                                                                          cx.carga_academica,
                                                                          cx.materias_aprobadas,
                                                                          cx.avance_curricular,
                                                                          cx.promedios,
                                                                          cx.fecha_matriculacion,
                                                                          cx.ciclo_inicial,
                                                                          cx.estado_alumno,
                                                                          cx.programa_code,
                                                                          cx.nombre_programa,
                                                                          cx.descuento,
                                                                          cx.referencia_bancaria,
                                                                          cx.tipo_ingreso,
                                                                          cx.etiqueta,
                                                                          cx.nom_reporte,
                                                                          cx.etiqueta2);
                        Exception
                            When Others then
                                null;
                        End;



            End loop;
            commit;


 End p_Acad_Finan_Cons;



 procedure p_Hist_Comp as

  Begin

         Begin
                 EXECUTE IMMEDIATE 'TRUNCATE TABLE saturn.SZRHICO';
                COMMIT;
         Exception
         When Others then
            null;
         End;

         Begin

                insert into SZRHICO
                SELECT
                    TZTCRTE_CAMP Campus,
                    TZTCRTE_LEVL Nivel,
                    TZTCRTE_CAMPO2 Programa,
                    CTLG PERIODO_CATALOGO,
                    TZTCRTE_ID Matricula,
                    TZTCRTE_CAMPO1 Nombre,
                    TZTCRTE_CAMPO3 Nombre_Programa,
                    TZTCRTE_CAMPO4 Estatus,
                    TZTCRTE_CAMPO5 Aprobadas,
                    TZTCRTE_CAMPO6 Reprobadas,
                    TZTCRTE_CAMPO7 En_Curso,
                    TZTCRTE_CAMPO8 Por_Cursar,
                    TZTCRTE_CAMPO9 Total,
                    TZTCRTE_CAMPO10 Avance
                from TZTCRTE, MIGRA.TZTPROG_DEV
                where 1=1
                AND TZTCRTE_PIDM = TZTPROG_DEV.PIDM
                And TZTCRTE_CAMPO2 = programa
                and TZTCRTE_TIPO_REPORTE = 'Historial_Academico_Compactado';
         Exception
            When others then
                null;
         End;
         Commit;

End p_Hist_Comp;


procedure p_SSBV as

Begin

             EXECUTE IMMEDIATE 'TRUNCATE TABLE saturn.SZRVSSB';
            commit;


            Begin

                      For cx in (

                          SELECT
                          NVL(Cod_Servicio,'NA')Cod_Servicio,
                          NVL(Servicio,'NA')Servicio,
                          NVL(SEQ_NO,0)SEQ_NO,
                          NVL(Matricula,0)Matricula,
                          NVL(Nombre,'NA')Nombre,
                          NVL(estado,'NA')estado,
                          NVL(programa,'NA')programa,
                          NVL(nivel,'NA')nivel,
                          UPPER(NVL(PAGO, 'NA')) Estatus_solc,
                          NVL(Cod_Entrega,'NA')Cod_Entrega,
                          NVL(Entrega,'NA')Entrega,
                          NVL(TO_CHAR(Fecha_Captura,'YYYY/MM/DD'),1900/01/01) Fecha_Captura,
                          NVL(TO_CHAR(Fecha_Entrega_Estimada,'YYYY/MM/DD'),1900/01/01)Fecha_Entrega_Estimada,
                          NVL(TO_CHAR(Fecha_Entrega,'YYYY/MM/DD'),1900/01/01)Fecha_Entrega,
                          NVL(UPPER(Pago),'NA')Pago,
                        -- NVL(Tipo_Solicitud,'NA')Tipo_Solicitud,
                          NVL(Regla_Servicio,0)Regla_Servicio,
                          NVL(TO_CHAR(Fecha_Status,'YYYY/MM/DD'),1900/01/01)Fecha_Status,
                          NVL(Monto,0)Monto,
                          NVL(Cod_Origen,0)Cod_Origen,
                          NVL(Transaccion,0)Transaccion,
                          NVL(Cod_Canal,'NA')Cod_Canal,
                          NVL(Canal,'NA')Canal,
                          NVL(Copias,0)Copias,
                          NVL(Campus,'NA')Campus,
                          NVL(Usuario,'NA')Usuario,
                          NVL(Porcentaje,0)Porcentaje,    --agregada
                          NVL(MontoDescuento,0)MontoDescuento --agregada
                        -- ,pidm
                      FROM
                              ( SELECT
                                          svrsvpr_srvc_code cod_servicio,
                                          svvsrvc_desc servicio,
                                          svrsvpr_protocol_seq_no seq_no,
                                          spriden_id matricula,
                                        replace( spriden_last_name,'/', ' ') ||' '|| spriden_first_name nombre,
                                          svrsvpr_srvs_code cod_estatus,
                                          svvsrvs_desc estatus,
                                          svrsvpr_wsso_code cod_entrega,
                                          stvwsso_desc entrega,
                                          svrsvpr_reception_date fecha_captura,
                                          svrsvpr_estimated_date fecha_entrega_estimada,
                                          svrsvpr_delivery_date fecha_entrega,
                                            case when  decode(SVRSVPR_SRVS_CODE,'PA','PAGADO','CA','CANCELADO','AC','ACTIVO' ) =  upper( (select f_valida_pago_accesorio (SPRIDEN_PIDM,SVRSVPR_ACCD_TRAN_NUMBER  ) from dual )) then
                                              (select f_valida_pago_accesorio (SPRIDEN_PIDM,SVRSVPR_ACCD_TRAN_NUMBER  ) from dual )
                                              ELSE
                                                decode(SVRSVPR_SRVS_CODE,'PA','PAGADO','CA','CANCELADO','AC','ACTIVO','CL', 'CONCLUIDO',SVRSVPR_SRVS_CODE  )
                                            end   as pago,
                                        -- svrsvpr_rqst_code tipo_solicitud,
                                          svrsvpr_rsrv_seq_no regla_servicio,
                                          svrsvpr_status_date fecha_status,
                                          svrsvpr_protocol_amount monto,
                                          svrsvpr_orig_code cod_origen,
                                          svrsvpr_accd_tran_number transaccion,
                                          svrsvpr_chnl_code cod_canal,
                                          svvchnl_desc canal,
                                          svrsvpr_copies copias,
                                          zt.campus  campus,
                                          svrsvpr_user_id usuario
                                        , SWTMDAC_PERCENT_DESC porcentaje,
                                          SWTMDAC_AMOUNT_DESC MontoDescuento
                                        ,zt.nivel nivel
                                        ,( select distinct SZTDTEC_PROGRAM||'-'|| SZTDTEC_PROGRAMA_COMP from sztdtec
                                            where SZTDTEC_PROGRAM =  zt.programa
                                              and  SZTDTEC_TERM_CODE = ZT.CTLG
                                              and rownum < 2
                                              ) programa
                                          ,( select  distinct   st.STVSTST_DESC from STVSTST st
                                                  where STVSTST_CODE = zt.estatus ) as estado
                                          ,svrsvpr_pidm pidm
                      FROM svrsvpr
                      LEFT JOIN spriden ON svrsvpr_pidm = spriden_pidm AND spriden_change_ind IS NULL
                      LEFT OUTER JOIN svvsrvc ON svrsvpr_srvc_code = svvsrvc_code
                      LEFT OUTER JOIN svvsrvs ON svrsvpr_srvs_code = svvsrvs_code
                      LEFT OUTER JOIN stvwsso ON svrsvpr_wsso_code = stvwsso_code
                      LEFT OUTER JOIN svvchnl ON svrsvpr_chnl_code = svvchnl_code
                      LEFT OUTER JOIN swtmdac ON svrsvpr_pidm = SWTMDAC_PIDM    and svrsvpr_protocol_seq_no =  SWTMDAC_SEQNO_SERV   and  SWTMDAC_APPLICATION_INDICATOR != 9  --agregada
                    --  LEFT OUTER JOIN tztprog zt  ON svrsvpr_pidm = zt.pidm  and zt.sp = ( select max(sp)  from tztprog tt where tt.pidm = zt.pidm )
                      LEFT OUTER JOIN MIGRA.TZTPROG_DEV zt  ON svrsvpr_pidm = zt.pidm  and zt.sp = ( select max(sp)  from MIGRA.TZTPROG_DEV tt where tt.pidm = zt.pidm )
                      WHERE 1=1
                      AND SVRSVPR_ACCD_TRAN_NUMBER > 0
                      )
                      WHERE 1=1


                 ) loop

                             Insert into SZRVSSB values (cx.COD_SERVICIO,
                                                                      cx.SERVICIO,
                                                                      cx.SEQ_NO,
                                                                      cx.matricula,
                                                                      cx.nombre,
                                                                      cx.estado,
                                                                      cx.programa,
                                                                      cx.nivel,
                                                                      cx.estatus_solc,
                                                                      cx.cod_entrega,
                                                                      cx.entrega,
                                                                      cx.fecha_captura,
                                                                      cx.fecha_entrega_estimada,
                                                                      cx.fecha_entrega,
                                                                      cx.pago,
                                                                      cx.regla_servicio,
                                                                      cx.fecha_status,
                                                                      cx.monto,
                                                                      cx.cod_origen,
                                                                      cx.transaccion,
                                                                      cx.cod_canal,
                                                                      cx.canal,
                                                                      cx.copias,
                                                                      cx.campus,
                                                                      cx.usuario,
                                                                      cx.porcentaje,
                                                                      cx.montodescuento
                                                                      );
                 End loop;

            Exception
                When Others then
                    null;
            End;
            Commit;

End p_SSBV;


PROCEDURE P_DOCTOS_RECOLECCION as--  ESTE proceso es nuevo para el reporte de documentos recoleccion se ejecuta mediante job glovicx 17.01.2023
--proceso de llenado de estatus de documentos nueva version glovicx 11.01.2023

--parametros
p_pidm number;
c_campus varchar2(4);
n_nivel varchar2(4);
t_ingre varchar2(14);
p_prog varchar2(14);

indice  number:=1;
indicedig  number:=1;
valid   number:=0;
vdevuelto   number:=0;
prest   number:=0;
total1  number:=0;
total2  number:=0;
total3  number:=0;
docto   varchar2(200);
doctodig   varchar2(200);
retorno varchar2(200):='NORECIBIDO';
retornod varchar2(200):='NORECIBIDO';
pmatricula varchar2(14):= null;
vcodigos     varchar2(100);
vcodigosdig    varchar2(100);
VCOUNTE    NUMBER:=0;
VSALIDA    VARCHAR2(300);
vstring1      VARCHAR2(2000);
vstring2      VARCHAR2(2000);
vstring3      VARCHAR2(500);
ncount     number:=0;
vestatus   varchar2(20);
ncontador  number:= 0;

TYPE DocCurTyp IS REF CURSOR;
    doc_cv   DocCurTyp;
    doc_cv2   DocCurTyp;

begin

DELETE FROM SZTEMPD;

------------esta seccion es para dumentos originales ------
FOR JUMP IN (

/*select   G.SGBSTDN_PIDM as pidm , g.SGBSTDN_CAMP_CODE as campus,
   g.SGBSTDN_LEVL_CODE as nivel, g.SGBSTDN_PROGRAM_1 as programa, g.SGBSTDN_ADMT_CODE as TIPO_INGRESO, ss.SARADAP_APPL_NO sp
from sgbstdn g, spriden p, saradap ss, sarappd dd
where 1=1
and G.SGBSTDN_PIDM = P.SPRIDEN_PIDM
and P.SPRIDEN_CHANGE_IND is null
and g.SGBSTDN_STST_CODE != 'CP'
and g.SGBSTDN_CAMP_CODE !='UTS'
and g.SGBSTDN_LEVL_CODE in ('LI','MA','DO')
and G.SGBSTDN_PIDM  = ss.saradap_pidm
and dd.SARAPPD_APPL_NO = ss.SARADAP_APPL_NO
and ss.saradap_pidm = dd.SARAPPD_PIDM
and g.SGBSTDN_PROGRAM_1 =  SS.SARADAP_PROGRAM_1
and dd.SARAPPD_APDC_CODE = '35'
--and  G.SGBSTDN_PIDM   = 168
and g.SGBSTDN_TERM_CODE_EFF = (select max(SGBSTDN_TERM_CODE_EFF) from sgbstdn f
                                                                                where 1=1
                                                                                and f.SGBSTDN_PIDM = g.SGBSTDN_PIDM
                                                                                and  f.SGBSTDN_CAMP_CODE= g.SGBSTDN_CAMP_CODE
                                                                                and  f.SGBSTDN_LEVL_CODE =  g.SGBSTDN_LEVL_CODE
                                                                                and  f.SGBSTDN_PROGRAM_1  = g.SGBSTDN_PROGRAM_1 )
order by 1*/

select   G.PIDM as pidm, 
         g.campus as campus,
         g.nivel as nivel,
         g.programa as programa,
         g.tipo_ingreso as TIPO_INGRESO,
         ss.SARADAP_APPL_NO sp
from tztprog_all g, spriden p, saradap ss, sarappd dd
where 1=1
and G.PIDM = P.SPRIDEN_PIDM
and P.SPRIDEN_CHANGE_IND is null
and g.estatus != 'CP'
and g.campus !='UTS'
and g.nivel in ('LI','MA','DO')
and G.PIDM  = ss.saradap_pidm
and dd.SARAPPD_APPL_NO = ss.SARADAP_APPL_NO
and ss.saradap_pidm = dd.SARAPPD_PIDM
and g.programa=  SS.SARADAP_PROGRAM_1
and dd.SARAPPD_APDC_CODE = '35'
and dd.SARAPPD_ACTIVITY_DATE in ( select max(sp.SARAPPD_ACTIVITY_DATE)
                                    from SARAPPD sp
                                    where g.PIDM  = sp.SARAPPD_PIDM                                                              
                                    and dd.SARAPPD_SEQ_NO = sp.SARAPPD_SEQ_NO                                 
                                )
--and  G.PIDM   = 731599--fget_pidm('010000454')

order by 1

   )   loop
p_pidm := jump.pidm;
-- dBMS_OUTPUT.PUT_LINE('pasoWWW: : inicio loop Originales  '||p_pidm);

indice := 1;

     LOOP

           --   DBMS_OUTPUT.PUT_LINE('pasxxx: : inicio loop Originales  '||  jump.pidm||'-'||jump.campus||'-'||jump.nivel||'-'|| jump.programa||'-'||jump.TIPO_INGRESO||'-'||jump.sp ||'-'||indice  );

          begin
          select regexp_substr(ZSTPARA_PARAM_VALOR,'[^,]+',1,indice)
             into docto
             from zstpara
              where ZSTPARA_MAPA_ID='DOCU_RECOLE'
              and ZSTPARA_PARAM_ID               = jump.campus
              and SUBSTR(ZSTPARA_PARAM_DESC,1,2)= jump.nivel
              AND SUBSTR(ZSTPARA_PARAM_DESC,4,2)=jump.TIPO_INGRESO    ;
          Exception
            When Others then
              docto := '';
                --retorno:=substr(sqlerrm,1,200);
               --   DBMS_OUTPUT.PUT_LINE('detalle:  '||docto);
                --  DBMS_OUTPUT.PUT_LINE('ERROR: AL BUSCAR DOCUMENTOS EN AGRUPADOR  "DOCU_RECOLE" ');
             --  retorno:='SIN AGRUPADOR EN DOCU_RECOLE';
               --indice:=100;
              -- exit;
          end;


        -- DBMS_OUTPUT.PUT_LINE('paso1:  ZPARA ORIGINAL:   '||  docto ||'-'|| jump.TIPO_INGRESO ||'-'|| jump.programa|| '-'|| jump.pidm||'-->'|| indice  );

         exit when docto is null;
         docto := ''''||docto||'''';
         vcodigos := vcodigos||','|| docto;
          indice:=indice+1;

          -- DBMS_OUTPUT.PUT_LINE('paso3:  VALIDADO ORIGINAL: '||  valid ||' SUMA >' || total1 ||'indice:' || indice||'-codigos--'||vcodigos);


      end loop;

      vcodigos := SUBSTR(vcodigos,2);

        --DBMS_OUTPUT.PUT_LINE('paso5: doctos  '|| vcodigos);
     IF vcodigos is not null then
        BEGIN ----- HAY QUE CAMBIAR X EXCEUTE IMMEDIATE
          vstring1:='
            select  count (SARCHKL_ADMR_CODE)
              from SARCHKL KL
            join saradap on saradap_pidm = KL.SARCHKL_PIDM and SARADAP_PROGRAM_1 = '''|| jump.programa ||'''
               join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = ''35'' and SARAPPD_APPL_NO = SARADAP_APPL_NO
            where 1=1
            and KL.SARCHKL_PIDM = :ppidm' ||   '
            and KL.SARCHKL_CKST_CODE=''VALIDADO'''|| '
            and kl.SARCHKL_ADMR_CODE in ('|| vcodigos||' )
             and kl.SARCHKL_APPL_NO = ' || jump.sp ;



         EXCEPTION WHEN OTHERS THEN
          VSALIDA := SQLERRM;
              DBMS_OUTPUT.PUT_LINE('ERROR EN SARKL: CUANTOS VALIDOS   '|| vstring1);
        END;

      -- DBMS_OUTPUT.PUT_LINE('paso5XX:  CADENA ORIGINAL '|| vstring1);


        OPEN doc_cv FOR vstring1  USING  jump.pidm;
        LOOP
            FETCH doc_cv INTO ncount;
             -- procesamiento
          --   retorno := 'NORECIBIDO';  --  esta etiqueta es para cuando el cursor no encuentra NADA en validado
          EXIT WHEN doc_cv%NOTFOUND;
         -- DBMS_OUTPUT.PUT_LINE('paso loop doctos  ORIGL  '||ncount||'-'||vestatus );


            if ncount = 0 or ncount is null  then
            retorno := 'NORECIBIDO';
            --DBMS_OUTPUT.PUT_LINE('paso loop doctos  DIGITAx1L::  '||ncount||'-'||indicedig );
           elsif  ncount >= indice-1 THEN
            retorno:='COMPLETO';
           ELSE
            retorno:='RECOLECCION';

           END IF;


           ---- aqui validamos si existe un devuelto o en prestamo
           begin
                 select count(SARCHKL_ADMR_CODE)
                      into vdevuelto
                         from SARCHKL
                       where 1=1
                       and SARCHKL_PIDM = jump.pidm
                       and SARCHKL_APPL_NO = jump.sp
                         and SARCHKL_CKST_CODE  in ( 'DEVUELTO', 'PRESTAMO')
                         And SARCHKL_ADMR_CODE IN ('CTBO','CTLO','CTMO');
            exception when others then
              vdevuelto := 0;
            end;

            IF vdevuelto >=1 THEN
                retorno:='DEVUE/PREST';
             END IF;

           --DBMS_OUTPUT.PUT_LINE('estatus final doctos ORIG   '||jump.pidm||'-'|| jump.programa  ||ncount||'-'||indice||'-'|| retorno );




        END LOOP;


                    BEGIN
                   INSERT INTO SATURN.SZTEMPD (  SZT_PIDM, SZT_CAMPUS, SZT_PROGRAMA, SZT_ESTATUS, SZT_ACTIVITY_DATE, SZT_USER, SZT_BANDERA )
                                  values(jump.pidm, jump.campus, jump.programa,retorno, sysdate, user,'O'   );
                EXCEPTION WHEN OTHERS THEN
                  vsalida := sqlerrm;
                  dbms_output.put_line('error al insertar en SZTEMPD '|| vsalida   );
                END;

        CLOSE doc_cv;
   end if;

                                        ----------------------digitales-----------------
       docto:=NULL;
       doctodig:=NULL;
       retornod := null;
       ncount :=0;
       vcodigos  :=null;

  LOOP

     --DBMS_OUTPUT.PUT_LINE('pasoXXX: : inicio loop digitales  '||  jump.pidm||'-'||jump.campus||'-'||jump.nivel||'-'|| jump.programa||'-'||jump.TIPO_INGRESO||'-'||indicedig  );

                  begin
                  select regexp_substr(ZSTPARA_PARAM_VALOR,'[^,]+',1,indicedig)
                     into doctodig
                     from zstpara
                      where ZSTPARA_MAPA_ID='DOCU_RECOLE2'
                      and ZSTPARA_PARAM_ID               = jump.campus
                      and SUBSTR(ZSTPARA_PARAM_DESC,1,2)= jump.nivel
                      AND SUBSTR(ZSTPARA_PARAM_DESC,4,2)= jump.TIPO_INGRESO    ;
                  Exception
                    When Others then
                            doctodig  := '';
                        --retorno:=substr(sqlerrm,1,200);
                         -- DBMS_OUTPUT.PUT_LINE('detalle:  '||retorno);
                       --   DBMS_OUTPUT.PUT_LINE('ERROR: AL BUSCAR DOCUMENTOS EN AGRUPADOR  "DOCU_RECOLE" ');
                     --  retorno:='SIN AGRUPADOR EN DOCU_RECOLE';
                       --indice:=100;
                      -- exit;
                  end;


                  --DBMS_OUTPUT.PUT_LINE('paso11:  ZPARAdigital :   '||  doctodig ||'-'|| jump.TIPO_INGRESO ||'-'|| jump.programa|| '-'|| jump.pidm||'-->'|| indiceDIG  );

                  exit when doctodig is null;


                  doctodig := ''''||doctodig||'''';
                  vcodigosdig := vcodigosdig||','|| doctodig;
                  indicedig:=indicedig+1;

                 -- DBMS_OUTPUT.PUT_LINE('paso33:  digital VALIDADO: '||  valid ||' SUMA >' || total1 ||'indice:' || indicedig||'-codigos--'||vcodigosdig);


                 end loop;

                        vcodigosdig := SUBSTR(vcodigosdig,2);

                      --  DBMS_OUTPUT.PUT_LINE('paso55:  DOCTOS digital '|| vcodigosdig);
    IF vcodigosdig is not null then
         BEGIN ----- HAY QUE CAMBIAR X EXCEUTE IMMEDIATE
          vstring2:='
            select  count (SARCHKL_ADMR_CODE)
              from SARCHKL KL
            join saradap on saradap_pidm = KL.SARCHKL_PIDM and SARADAP_PROGRAM_1 = '''|| jump.programa ||'''
              join sarappd on sarappd_pidm = SARCHKL_PIDM and SARAPPD_APDC_CODE = ''35'' and SARAPPD_APPL_NO = SARADAP_APPL_NO
            where KL.SARCHKL_PIDM = :ppidm' || '
              and KL.SARCHKL_CKST_CODE=''VALIDADO'''|| '
             and kl.SARCHKL_ADMR_CODE in ('|| vcodigosdig||' )
              and kl.SARCHKL_APPL_NO = ' || jump.sp  ;

         EXCEPTION WHEN OTHERS THEN
          VSALIDA := SQLERRM;
                   DBMS_OUTPUT.PUT_LINE('ERROR EN SARKL: CUANTOS VALIDOS   '|| VSALIDA);
        END;
                             --  DBMS_OUTPUT.PUT_LINE('paso66:  CADENA digital '|| vstring2);

      OPEN doc_cv2 FOR vstring2  USING  jump.pidm;
            LOOP
                FETCH doc_cv2 INTO ncount;
                   --   retornod := 'NORECIBIDO';  --  esta etiqueta es para cuando el cursor no encuentra NADA en validado
                 EXIT WHEN doc_cv2%NOTFOUND;
                -- procesamiento

        --DBMS_OUTPUT.PUT_LINE('paso loop doctos  DIGITAL::  '||ncount||'-'||indicedig );
          if ncount = 0 or ncount is null  then
            retornod := 'NORECIBIDO';
            --DBMS_OUTPUT.PUT_LINE('paso loop doctos  DIGITAx1L::  '||ncount||'-'||indicedig );
           elsif   ncount >= indicedig-1 THEN
            retornod:='COMPLETO';
            --  DBMS_OUTPUT.PUT_LINE('paso loop doctos  DIGITALx2::  '||ncount||'-'||indicedig );
           ELSE
            retornod:='RECOLECCION';
            --  dBMS_OUTPUT.PUT_LINE('paso loop doctos  DIGITALx3::  '||ncount||'-'||indicedig );
           END IF;


           ---- aqui validamos si existe un devuelto o en prestamo
           begin
                 select count(SARCHKL_ADMR_CODE)
                      into vdevuelto
                         from SARCHKL
                       where 1=1
                       and SARCHKL_PIDM = jump.pidm
                       and SARCHKL_APPL_NO = jump.sp
                         and SARCHKL_CKST_CODE  in ( 'DEVUELTO', 'PRESTAMO')
                         And SARCHKL_ADMR_CODE IN ('CTBD','CTLD','CTMD');
            exception when others then
              vdevuelto := 0;
            end;

            IF vdevuelto >=1 THEN
                retornod:='DEVUE/PREST';
             END IF;

       --   DBMS_OUTPUT.PUT_LINE('Estatus final  doctos DIGITALES   '||jump.pidm||'-'|| jump.programa  ||ncount||'-'||indicedig||'-'|| retorno );


    END LOOP;

         BEGIN
           INSERT INTO SATURN.SZTEMPD (  SZT_PIDM, SZT_CAMPUS, SZT_PROGRAMA, SZT_ESTATUS, SZT_ACTIVITY_DATE, SZT_USER, SZT_BANDERA )
                   values(jump.pidm, jump.campus, jump.programa,retornod, sysdate, user,'D'   );
           null;
        EXCEPTION WHEN OTHERS THEN
          vsalida := sqlerrm;

        END;

    CLOSE doc_cv2;
  end if; -- nuevo if cadena doctos nula

--DBMS_OUTPUT.PUT_LINE('alumno paso ok  '||p_pidm||'-'||retorno||'-'||retornoD );
--  DBMS_OUTPUT.PUT_LINE('paso66: CUANTOS VALIDOS  digital  '||vstring1);
indice:=1;
indicedig:=1;
valid:=0;
vdevuelto:=0;
prest:=0;
total1:=0;
total2:=0;
total3:=0;
docto:=NULL;
doctodig:=NULL;
vcodigosdig := null;
retornoD := null;
retorno  := null;
vcodigos  := null;
commit;

ncontador := ncontador +1;

END LOOP;-- CURSOR INICIAL

DBMS_OUTPUT.PUT_LINE('contador general de vueltas '||ncontador );
 EXCEPTION WHEN OTHERS THEN
DBMS_OUTPUT.PUT_LINE('error x1:  CADENA pidm '||p_pidm );
DBMS_OUTPUT.PUT_LINE('error x2:  CADENA ORIGINAL '|| vstring1);
DBMS_OUTPUT.PUT_LINE('error x3:  CADENA ORIGINAL2 '|| vstring2);
vsalida := sqlerrm;
DBMS_OUTPUT.PUT_LINE('error x4:  de oracle '|| vsalida);

end P_DOCTOS_RECOLECCION;


procedure p_Mat_Parte_Periodo as
/*creado 09/01/2024
Reporte Materias inscritas por parte de periodo
Catalina Almeida
*/
Begin


         Begin
                 EXECUTE IMMEDIATE 'TRUNCATE TABLE SATURN.SZRMATPERI';
                COMMIT;
         Exception
         When Others then
            null;
         End;
         
          for cx1 in (
          
          
          SELECT distinct
                   NVL (datos.matricula,'NA' ) matricula,
                   NVL (datos.estudiante,'NA')  estudiante,
                   NVL (datos.estatus,'NA' ) cve_estatus,
                   NVL (datos.estatus_desc,'NA' ) estatus,
                   NVL (datos.tipo,'NA' ) tipo,
                   NVL (datos.campus,'NA' ) campus,
                   NVL (datos.nivel, 'NA' ) nivel,
                   NVL (datos.code_prog,'NA') code_prog,
                   NVL (datos.programa,'NA' ) programa,
                   NVL (datos.Periodo,'NA')Periodo,
                   NVL (datos.fecha_inicio_periodo, '01/01/1990' ) fecha_inicio_periodo,
                   NVL (datos.fecha_fin_periodo, '01/01/1990' ) fecha_fin_periodo,
                   NVL (datos.crn,'NA') CRN,
                   NVL (datos.parte_periodo, 'NA') parte_periodo,
                   NVL (datos.materia, 'NA') materia_crn,
                   NVL (datos.materia_padre, 'NA') materia_padre,
                   NVL (datos.grupo, 'NA') grupo,
                   NVL (datos.nombre_materia, 'NA') nombre_materia,
                   NVL (datos.estatus_mat, 'NA') estatus_mat,
                   NVL (datos.calificacion, 0) calificacion,
                   NVL (datos.nombre_prof, 'NA') nombre_prof,
                   NVL (datos.materia_legal, 'NA') materia_legal,
                   study_path
            FROM 
            ( 
            SELECT DISTINCT tz.pidm,
                   tz.matricula, 
                   s.spriden_last_name||s.spriden_first_name AS estudiante,
                   tz.estatus, 
                   (SELECT DISTINCT stvstst_desc  
                             FROM stvstst
                             WHERE tz.estatus = stvstst_code   ) estatus_desc,
                   NVL((SELECT  stvstyp_desc 
                               FROM stvstyp y 
                               WHERE y.stvstyp_code=tz.sgbstdn_styp_code ),'NA') tipo,
                   tz.campus, 
                   tz.nivel, 
                   tz.programa code_prog, 
                   tz.nombre AS programa ,
                   b.ssbsect_term_code periodo,
                   b.ssbsect_ptrm_start_date fecha_inicio_periodo,
                   b.ssbsect_ptrm_end_date fecha_fin_periodo,
                   f.sfrstcr_crn crn,
                   b.ssbsect_ptrm_code parte_periodo,
                   b.ssbsect_subj_code || ssbsect_crse_numb materia,
                   get_materia_padre(ssbsect_subj_code || ssbsect_crse_numb) materia_padre,
                   ssbsect_seq_numb grupo,
                   ssbsect_crse_title nombre_materia,
                   sfrstcr_rsts_code estatus_mat,
                   sfrstcr_grde_code calificacion,
                   (SELECT    bb.spriden_id|| ' '|| bb.spriden_first_name|| ' '|| bb.spriden_last_name
                             FROM sirasgn s, spriden bb
                            WHERE     sirasgn_term_code = ssbsect_term_code
                              AND sirasgn_crn = ssbsect_crn
                              AND sirasgn_primary_ind = 'Y'
                              AND sirasgn_surrogate_id IN (SELECT MAX (sirasgn_surrogate_id)
                                                                 FROM sirasgn ss
                                                                WHERE s.sirasgn_term_code =ss.sirasgn_term_code
                                                                  AND s.sirasgn_crn = ss.sirasgn_crn
                                                                  AND s.sirasgn_primary_ind =ss.sirasgn_primary_ind)
                              AND bb.spriden_pidm = sirasgn_pidm
                              AND bb.spriden_change_ind IS NULL) nombre_prof,
                   (SELECT    MAX (xt.scrtext_text)
                             FROM sztmaco, scrtext xt
                            WHERE sztmaco_matpadre = (xt.scrtext_subj_code || xt.scrtext_crse_numb)
                              AND scrtext_text = xt.scrtext_text
                              AND ssbsect_subj_code || ssbsect_crse_numb = xt.scrtext_subj_code || xt.scrtext_crse_numb)materia_legal,
                              f.sfrstcr_stsp_key_sequence study_path  
            FROM migra.TZTPROG_ALL_MATP tz, spriden s, sfrstcr f, ssbsect b 
            WHERE tz.pidm = s.spriden_pidm(+)
              AND s.spriden_change_ind IS NULL
              AND tz.pidm = f.sfrstcr_pidm
              AND tz.sp (+) =  f.sfrstcr_stsp_key_sequence
              AND f.sfrstcr_term_code= b.ssbsect_term_code
              AND f.sfrstcr_crn=b.ssbsect_crn 
             -- And tz.matricula ='010232814'
              union 
            SELECT DISTINCT spriden_pidm pidm,
                   spriden_id matricula, 
                   s.spriden_last_name||s.spriden_first_name AS estudiante,
                    decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' ) estatus, 
                   (SELECT DISTINCT stvstst_desc  
                             FROM stvstst
                             WHERE decode (SORLCUR_CACT_CODE,'INACTIVE', 'BT', 'ACTIVE', 'MA', 'CHANGE', 'CP' ) = stvstst_code   )  estatus_desc,
                   null tipo,
                   sfrstcr_camp_code campus, 
                   SFRSTCR_LEVL_CODE nivel,
                   SORLCUR_PROGRAM code_prog, 
                   (select SMRPRLE_PROGRAM_DESC from SMRPRLE where SMRPRLE_PROGRAM = SORLCUR_PROGRAM ) programa ,
                   b.ssbsect_term_code periodo,
                   b.ssbsect_ptrm_start_date fecha_inicio_periodo,
                   b.ssbsect_ptrm_end_date fecha_fin_periodo,
                   f.sfrstcr_crn crn,
                   b.ssbsect_ptrm_code parte_periodo,
                   b.ssbsect_subj_code || ssbsect_crse_numb materia,
                   get_materia_padre(ssbsect_subj_code || ssbsect_crse_numb) materia_padre,
                   ssbsect_seq_numb grupo,
                   ssbsect_crse_title nombre_materia,
                   sfrstcr_rsts_code estatus_mat,
                   sfrstcr_grde_code calificacion,
                   (SELECT    bb.spriden_id|| ' '|| bb.spriden_first_name|| ' '|| bb.spriden_last_name
                             FROM sirasgn s, spriden bb
                            WHERE     sirasgn_term_code = ssbsect_term_code
                              AND sirasgn_crn = ssbsect_crn
                              AND sirasgn_primary_ind = 'Y'
                              AND sirasgn_surrogate_id IN (SELECT MAX (sirasgn_surrogate_id)
                                                                 FROM sirasgn ss
                                                                WHERE s.sirasgn_term_code =ss.sirasgn_term_code
                                                                  AND s.sirasgn_crn = ss.sirasgn_crn
                                                                  AND s.sirasgn_primary_ind =ss.sirasgn_primary_ind)
                              AND bb.spriden_pidm = sirasgn_pidm
                              AND bb.spriden_change_ind IS NULL) nombre_prof,
                   (SELECT    MAX (xt.scrtext_text)
                             FROM sztmaco, scrtext xt
                            WHERE sztmaco_matpadre = (xt.scrtext_subj_code || xt.scrtext_crse_numb)
                              AND scrtext_text = xt.scrtext_text
                              AND ssbsect_subj_code || ssbsect_crse_numb = xt.scrtext_subj_code || xt.scrtext_crse_numb)materia_legal,
                              f.sfrstcr_stsp_key_sequence study_path  
            FROM  spriden s, sfrstcr f, ssbsect b , sorlcur
            WHERE 1=1
              AND s.spriden_change_ind IS NULL
              AND spriden_pidm = f.sfrstcr_pidm
              and spriden_pidm = sorlcur_pidm 
              And SORLCUR_KEY_SEQNO = sfrstcr_stsp_key_sequence
              And SORLCUR_CACT_CODE = 'INACTIVE'
              AND f.sfrstcr_stsp_key_sequence not in (select sp 
                                                      from TZTPROG_ALL_MATP
                                                      where pidm = spriden_pidm )
              AND f.sfrstcr_term_code= b.ssbsect_term_code
              AND f.sfrstcr_crn=b.ssbsect_crn 
            --  And spriden_id ='010232814'      
              ) datos
              WHERE 1=1
             --  AND DATOS.MATRICULA='010000077'
              GROUP BY
                datos.matricula,
                datos.estudiante,
                datos.estatus,
                datos.estatus_desc,
                datos.tipo,
                datos.campus,
                datos.nivel,
                datos.code_prog,
                datos.programa,
                datos.Periodo,
                datos.fecha_inicio_periodo,
                datos.fecha_fin_periodo,
                datos.crn,
                datos.parte_periodo,
                datos.materia,
                datos.materia_padre,
                datos.grupo,
                datos.nombre_materia,
                datos.estatus_mat,
                datos.calificacion,
                datos.nombre_prof,
                datos.materia_legal,
                datos.STUDY_PATH
        ORDER BY 1 asc,4 asc, 13 ASC ,10 asc
              
              
                ) loop

                          Begin
                                    Insert into saturn.szrmatperi
                                    (
                                        MATRICULA,
                                        ESTUDIANTE,
                                        CVE_ESTATUS,
                                        ESTATUS,
                                        TIPO,
                                        CAMPUS,
                                        NIVEL,
                                        CODE_PROG,
                                        PROGRAMA,
                                       -- CATALOGO,
                                        PERIODO,
                                        FECHA_INICIO,
                                        CRN,
                                        PARTE_PERIODO,
                                        MATERIA,
                                        MATERIA_PADRE,
                                        GRUPO,
                                        NOMBRE_MATERIA,
                                        ESTATUS_MAT,
                                        CALIFICACION,
                                        NOMBRE_PROF,
                                        MATERIA_LEGAL,
                                        STUDY_PATH,
                                        FECHA_FIN
                                    
                                    )
                                    values
                                    (
                                       cx1.matricula,
                                       cx1.estudiante,
                                       cx1.cve_estatus,
                                       cx1.estatus,
                                       cx1.tipo,
                                       cx1.campus,
                                       cx1.nivel,
                                       cx1.code_prog,
                                       cx1.programa,
                                       cx1.Periodo,
                                       cx1.fecha_inicio_periodo,
                                       cx1.CRN,
                                       cx1.parte_periodo,
                                       cx1.materia_crn,
                                       cx1.materia_padre,
                                       cx1.grupo,
                                       cx1.nombre_materia,
                                       cx1.estatus_mat,
                                       cx1.calificacion,
                                       cx1.nombre_prof,
                                       cx1.materia_legal,
                                       cx1.study_path,
                                       cx1.fecha_fin_periodo
                                    )
                                   

                                    ;
                          Exception
                            When Others then
                                null;
                          End;

                          Commit;

                End Loop cx1;
                                    


end p_Mat_Parte_Periodo;


procedure p_cargatztprog_all_MATP is


/* Formatted on 08/05/2019 12:24:05 p.m. (QP5 v5.215.12089.38647) */


Begin

        EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.TZTPROG_ALL_MATP';
         COMMIT;

 insert into migra.TZTPROG_ALL_MATP
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
 f.SORLCUR_TERM_CODE_MATRIC Matriculacion,
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
-- and a.SGBSTDN_STST_CODE != 'CP'
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
 And f.SORLCUR_PROGRAM = f1.SORLCUR_PROGRAM
 aND f.SORLCUR_TERM_CODE_CTLG = f1.SORLCUR_TERM_CODE_CTLG)
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
a.SORLCUR_TERM_CODE_MATRIC Matriculacion,
b.SPRIDEN_CREATE_FDMN_CODE,
 a.SORLCUR_START_DATE fecha_inicio,
 sysdate as fecha_carga,
a.sorlcur_ADMT_CODE,
STVADMT_DESC
from sorlcur a
join spriden b on b.spriden_pidm = a.sorlcur_pidm and spriden_change_ind is null
left join migra.ESTATUS_REPORTE c on c.SPRIDEN_PIDM =a.sorlcur_pidm and c.PROGRAMAS = a.SORLCUR_PROGRAM
join SMRPRLE on SMRPRLE_PROGRAM = a.SORLCUR_PROGRAM
join stvADMT on stvADMT_code = NVL (a.sorlcur_ADMT_CODE,'RE')
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
 And a.SORLCUR_PROGRAM = a1.SORLCUR_PROGRAM
 And a.SORLCUR_TERM_CODE_CTLG = a1.SORLCUR_TERM_CODE_CTLG )
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
 from TZTPROG_ALL_MATP
 where 1= 1
 --CAMPUS||nivel = 'ULTLI'
 --and fecha_mov is null

 ) loop

 If c.fecha_inicio < '04/03/2017' and c.campus != 'UTLLI' then

 Begin
 Update TZTPROG_ALL_MATP
 set FECHA_MOV = '04/03/2017'
 Where pidm = c.pidm
 And sp = c.sp;
 Exception
 When Others then
 null;
 End;

 ElsIf c.fecha_inicio >= '04/03/2017' and c.fecha_mov is null then

 Begin
 Update TZTPROG_ALL_MATP
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

 Update TZTPROG_ALL_MATP
 set FECHA_MOV = '03/04/2017'
 Where FECHA_MOV is null;
 Commit;


 ---- Se actualiza la fecha de la primera inscripcion ----------


 begin


 for c in (
 select *
 from TZTPROG_ALL_MATP
 where 1 = 1
 -- and rownum <= 50
 )loop



 Begin


 Update TZTPROG_ALL_MATP
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


 Begin


 For c in (

 select count(*), matricula, PROGRAMA, ESTATUS
 from TZTPROG_ALL_MATP
 where 1= 1
 -- And matricula = '010001108'
 And ESTATUS = 'MA'
 group by matricula,PROGRAMA, ESTATUS
 having count(*) > 1

 ) Loop

 Begin
 update TZTPROG_ALL_MATP a
 set a.estatus = 'BT',
 a.estatus_d = 'BAJA TEMPORAL',
 a.SGBSTDN_STYP_CODE = 'D'
 Where a.matricula = c.matricula
 And a.programa = c.programa
 And a.ESTATUS = c.ESTATUS
 And a.sp = (select min (a1.sp)
 from TZTPROG_ALL_MATP a1
 Where a.matricula = a1.matricula
 And a.programa = a1.programa
 And a.ESTATUS = a1.ESTATUS);
 Exception
 When Others then
 null;
 End;


 End Loop;
 Commit;
 End;




 Begin


 For c in (

 select count(*), matricula, PROGRAMA, ESTATUS
 from TZTPROG_ALL_MATP
 where 1= 1
 -- And matricula = '010001108'
 And ESTATUS = 'EG'
 group by matricula,PROGRAMA, ESTATUS
 having count(*) > 1

 ) Loop

 Begin
 update TZTPROG_ALL_MATP a
 set a.estatus = 'BT',
 a.estatus_d = 'BAJA TEMPORAL',
 a.SGBSTDN_STYP_CODE = 'D'
 Where a.matricula = c.matricula
 And a.programa = c.programa
 And a.ESTATUS = c.ESTATUS
 And a.sp = (select min (a1.sp)
 from TZTPROG_ALL_MATP a1
 Where a.matricula = a1.matricula
 And a.programa = a1.programa
 And a.ESTATUS = a1.ESTATUS);
 Exception
 When Others then
 null;
 End;


 End Loop;
 Commit;
 End;




 end;

---------- Pone el tipoo de estatus desercion para todos las bajas

Begin

    For cx in (

                    select *
                    from TZTPROG_ALL_MATP
                    where 1= 1
                    and estatus in ('BT','BD','CM','CV','BI')
                    and SGBSTDN_STYP_CODE !='D'


     ) loop

        Begin
            Update TZTPROG_ALL_MATP
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


 end p_cargatztprog_all_MATP;

 
 procedure p_carga_caps is
 begin
 
 DECLARE 
 V_SALIDA VARCHAR(500);
  --iNSERTA LOS QUE NO ESTAN EN SZRCAPS
  
  ----- Caty 7/11/2024
  ----- Alimenta tabla SZRCAPS, Diplomas DPLO 
  
  begin
    for cx1 in (
                     Select distinct 
                            spriden_id Matricula,
                            INITCAP (spriden_first_name) NOMBRE_ALUMNO, 
                            INITCAP (replace(spriden_last_name,'/',' ')) APELLIDOS_ALUMNO,
                            SGBSTDN_STYP_CODE TIPO_ALUMNO,            
                            FECHA_INICIO,  
                            FECHA_INICIO+120 FECHA_FIN,
                            CASE 
                                WHEN TO_DATE(SYSDATE,'DD/MM/YYYY')< TO_DATE(FECHA_INICIO,'DD/MM/YYYY') THEN 'NO DISPONIBLE'
                                WHEN  TO_DATE(SYSDATE,'DD/MM/YYYY') BETWEEN TO_DATE(FECHA_INICIO,'DD/MM/YYYY') AND TO_DATE(FECHA_INICIO+120,'DD/MM/YYYY') THEN 'ACTIVO'
                            ELSE 'VENCIDO'
                            END ESTATUS,                                       
                            SZTQRDI_PROGRAMA COD_PROGRAMA, 
                            SZTDTEC_PROGRAMA_COMP DESCRIPCION,
                            SZTDTEC_NUM_RVOE RVOE,
                            DECODE(pkg_utilerias.f_genero(PIDM),'Femenino','MUJER','HOMBRE')GENERO_SEX,
                           (select STVCOLL_DESC from SMRPRLE, STVCOLL where 1=1 and SMRPRLE_COLL_CODE = STVCOLL_CODE and SMRPRLE_PROGRAM = programa) facultad,
                            (select pkg_utilerias.f_correo (pidm, 'PRIN') FROM DUAL) CORREO_PRINC
                            ,(select pkg_utilerias.f_celular (pidm, 'CELU' ) FROM DUAL) CELULAR
                            , null RINDIO, --1=Rindió 0=No rindió
                            NIVEL,
                            pkg_utilerias.f_ocupacion(pidm) OCUPACION,
                            (SELECT DISTINCT STVNATN_NATION FROM SPRADDR, STVNATN WHERE 1=1 AND SPRADDR_NATN_CODE = STVNATN_CODE AND SPRADDR_PIDM = PIDM and SPRADDR_ATYP_CODE = 'RE') PAIS,
                            pkg_utilerias.f_edad(pidm) EDAD,  
                            case when nivel='LI' THEN
                              'Momento_'||decode(SZTQRDI_ETIQUETA,'DIL1','uno','DIL2','dos','DIL3','tres') 
                              WHEN NIVEL='MA' OR NIVEL='MS' THEN
                              'Momento_'||decode(SZTQRDI_ETIQUETA,'DIM1','uno','DIM2','dos','DIM3','tres')
                              WHEN NIVEL='DO'  THEN
                              'Momento_'||decode(SZTQRDI_ETIQUETA,'DID1','uno','DID2','dos','DID3','tres')
                            END  
                              MOMENTO,
                            SZTQRDI_AVANCE AVANCE_CURRI, 
                            NVL(SZTQRDI_ENVIADO_QR,'N') PAGO,           
                            SZTQRDI_DIPLOMA DIPLOMA,
                            SZTQRDI_ETIQUETA ETIQUETA,
                            SZTQRDI_CODE_ACCESORIO ACCESORIO,
                            TBRACCD_AMOUNT COSTO,
                            TBRACCD_TRAN_NUMBER TRANSACCION,
                            TBRACCD_CURR_CODE DIVISA,
                            TBRACCD_RECEIPT_NUMBER REFERENCIA_PAGO,
                           -- BANINST1.PKG_QR_DIG.F_curso_actual(PIDM, PROGRAMA, NIVEL, CAMPUS)BIMESTRE,
                            BANINST1.PKG_UTILERIAS.f_calcula_bimestres(PIDM,SP)BIMESTRE,
                            substr(SZTQRDI_ETIQUETA,4,1)+1 ireport,
                            ''AREA,
                             SMRPRLE_DEGC_CODE||'/'||STVDEGC_DESC GRADO,
                             TBRACCD_DETAIL_CODE CODIGO_DIPLOMA
                        from sztqrdi
                            join spriden on SZTQRDI_PIDM = spriden_pidm                           
                            join tztprog a on SZTQRDI_PIDM = a.PIDM 
                            join sztdtec on SZTDTEC_PROGRAM = a.PROGRAMA and a.ctlg = SZTDTEC_TERM_CODE
                            join SMRPRLE on SMRPRLE_PROGRAM= a.programa
                            join STVDEGC on SMRPRLE_DEGC_CODE=STVDEGC_CODE
                            left join tbraccd on SZTQRDI_TRANS_CARGO=TBRACCD_TRAN_NUMBER and TBRACCD_pidm=SZTQRDI_PIDM
                            where 1=1
                              and spriden_change_ind is null
                           --   AND ESTATUS = 'MA'
                              AND A.CAMPUS in ('COL','ECU','GUA','BOL','PAR','DOM','ESP','ARG','URU','PAN','USA','CHI','SAL','UTL','PER')
                              and SZTQRDI_PROGRAMA=a.programa
                         --   and a.SGBSTDN_STYP_CODE = 'C'
                          --  and a.FECHA_INICIO > '01/10/2023' --Cambiar a FECHA_PRIMERA -- REVISAR
                            --  and a.FECHA_PRIMERA >= '23/10/2023'
                              and a.sp = (select max (a1.sp)
                                              from tztprog a1
                                              where 1=1
                                              and a1.pidm = a.pidm
                                              and a1.programa = a.programa
                                              AND a1.ctlg= a.ctlg
                                              )
                              and a.matricula||a.programa||SZTQRDI_ETIQUETA not in (select c.matricula||c.cod_programa||c.etiqueta 
                                                                    from SATURN.szrcaps c 
                                                                where 
                                                                a.matricula=c.matricula 
                                                                and a.programa=c.cod_programa 
                                                                and c.etiqueta=SZTQRDI_ETIQUETA
                                                              )                                                              
                     UNION                          
                          Select distinct
                                spriden_id Matricula,
                                 INITCAP (spriden_first_name) NOMBRE_ALUMNO, 
                                 INITCAP (replace(spriden_last_name,'/',' ')) APELLIDOS_ALUMNO,
                                SGBSTDN_STYP_CODE TIPO_ALUMNO,
                                FECHA_INICIO,
                                FECHA_INICIO+120 FECHA_FIN,
                                CASE 
                                    WHEN TO_DATE(SYSDATE,'DD/MM/YYYY')< TO_DATE(FECHA_INICIO,'DD/MM/YYYY') THEN 'NO DISPONIBLE'
                                    WHEN  TO_DATE(SYSDATE,'DD/MM/YYYY') BETWEEN TO_DATE(FECHA_INICIO,'DD/MM/YYYY') AND TO_DATE(FECHA_INICIO+120,'DD/MM/YYYY') THEN 'ACTIVO'
                                ELSE 'VENCIDO'
                                END ESTATUS, 
                                PROGRAMA COD_PROGRAMA,
                                SZTDTEC_PROGRAMA_COMP DESCRIPCION,
                                SZTDTEC_NUM_RVOE RVOE,
                                DECODE(pkg_utilerias.f_genero(PIDM),'Femenino','MUJER','HOMBRE')GENERO_SEX,
                                (select STVCOLL_DESC from SMRPRLE, STVCOLL where 1=1 and SMRPRLE_COLL_CODE = STVCOLL_CODE and SMRPRLE_PROGRAM = a.programa) facultad,
                                pkg_utilerias.f_correo (a.pidm, 'PRIN') CORREO_PRINC,
                                pkg_utilerias.f_celular (A.pidm, 'CELU' ) CELULAR,
                                null RINDIO,  --1=Rindió 0=No rindió --Falta ws
                                NIVEL Nivel,  
                                pkg_utilerias.f_ocupacion (A.pidm) OCUPACION,
                                (SELECT DISTINCT STVNATN_NATION FROM SPRADDR, STVNATN WHERE 1=1 AND SPRADDR_NATN_CODE = STVNATN_CODE AND SPRADDR_PIDM = A.PIDM and SPRADDR_ATYP_CODE = 'RE') PAIS,
                                pkg_utilerias.f_edad (A.pidm) EDAD,
                                'Momento_cero' MOMENTO,
                                '0'AVANCE_CURRI,
                                'Y'PAGO,
                                '' DIPLOMA,           
                                DECODE(a.NIVEL,'LI','DIL0','MA','DIM0','DO','DID0')ETIQUETA,
                                 'DPLO'ACCESORIO,
                                NULL COSTO,
                                NULL TRANSACCION,
                                NULL DIVISA,
                                NULL REFERENCIA_PAGO,
                                BANINST1.PKG_UTILERIAS.f_calcula_bimestres(PIDM,SP)BIMESTRE,
                                substr(DECODE(a.NIVEL,'LI','DIL0','MA','DIM0','DO','DID0'),4,1)+1 ireport,
                                ''AREA,
                                SMRPRLE_DEGC_CODE||'/'||STVDEGC_DESC GRADO,
                                NULL CODIGO_DIPLOMA
                            from tztprog a, spriden, sztdtec ,SMRPRLE,  STVDEGC
                            where 1=1
                            and a.PIDM = spriden_pidm
                            and spriden_change_ind is null
                            and a.PROGRAMA = SZTDTEC_PROGRAM
                            and a.ctlg = SZTDTEC_TERM_CODE
                            and  SMRPRLE_PROGRAM= a.programa
                            and SMRPRLE_DEGC_CODE=STVDEGC_CODE                           
                --            and SPRIDEN_ID = '010710160'
                            and a.estatus = 'MA'
                            AND A.CAMPUS in ('COL','ECU','GUA','BOL','PAR','DOM','ESP','ARG','URU','PAN','USA','CHI','SAL','UTL','PER')
                            and a.SGBSTDN_STYP_CODE = 'N'
                            and a.FECHA_PRIMERA >= '23/10/2023'
                            and a.sp = (select max (a1.sp)
                                              from tztprog a1
                                              where 1=1
                                              and a1.pidm = a.pidm
                                              and a1.programa = a.programa)
                            and a.matricula||a.programa||DECODE(a.NIVEL,'LI','DIL0','MA','DIM0','DO','DID0') not in (select c.matricula||c.cod_programa||c.etiqueta
                                                                from SATURN.szrcaps c 
                                                                where a.matricula=c.matricula 
                                                                and a.programa=c.cod_programa 
                                                                and DECODE(a.NIVEL,'LI','DIL0','MA','DIM0','DO','DID0')=c.etiqueta
                                                                )
                                                                                             
                    UNION                                    
                         Select distinct
                                spriden_id Matricula,
                                 INITCAP (spriden_first_name) NOMBRE_ALUMNO, 
                                 INITCAP (replace(spriden_last_name,'/',' ')) APELLIDOS_ALUMNO,
                                SGBSTDN_STYP_CODE TIPO_ALUMNO,
                                FECHA_INICIO,
                                FECHA_INICIO+120 FECHA_FIN,
                                CASE 
                                    WHEN TO_DATE(SYSDATE,'DD/MM/YYYY')< TO_DATE(FECHA_INICIO,'DD/MM/YYYY') THEN 'NO DISPONIBLE'
                                    WHEN  TO_DATE(SYSDATE,'DD/MM/YYYY') BETWEEN TO_DATE(FECHA_INICIO,'DD/MM/YYYY') AND TO_DATE(FECHA_INICIO+120,'DD/MM/YYYY') THEN 'ACTIVO'
                                ELSE 'VENCIDO'
                                END ESTATUS, 
                                PROGRAMA COD_PROGRAMA,
                                SZTDTEC_PROGRAMA_COMP DESCRIPCION,
                                SZTDTEC_NUM_RVOE RVOE,
                                DECODE(pkg_utilerias.f_genero(PIDM),'Femenino','MUJER','HOMBRE')GENERO_SEX,
                                (select STVCOLL_DESC from SMRPRLE, STVCOLL where 1=1 and SMRPRLE_COLL_CODE = STVCOLL_CODE and SMRPRLE_PROGRAM = a.programa) facultad,
                                pkg_utilerias.f_correo (a.pidm, 'PRIN') CORREO_PRINC,
                                pkg_utilerias.f_celular (A.pidm, 'CELU' ) CELULAR,
                                null RINDIO,  --1=Rindió 0=No rindió --Falta ws
                                NIVEL Nivel,  
                                pkg_utilerias.f_ocupacion (A.pidm) OCUPACION,
                                (SELECT DISTINCT STVNATN_NATION FROM SPRADDR, STVNATN WHERE 1=1 AND SPRADDR_NATN_CODE = STVNATN_CODE AND SPRADDR_PIDM = A.PIDM and SPRADDR_ATYP_CODE = 'RE') PAIS,
                                pkg_utilerias.f_edad (A.pidm) EDAD,
                                'Momento_cero' MOMENTO,
                                '0'AVANCE_CURRI,
                                'Y'PAGO,
                                '' DIPLOMA,           
                                DECODE(a.NIVEL,'LI','DIL0','MA','DIM0','DO','DID0')ETIQUETA,
                                 'DPLO'ACCESORIO,
                                NULL COSTO,
                                NULL TRANSACCION,
                                NULL DIVISA,
                                NULL REFERENCIA_PAGO,
                                BANINST1.PKG_UTILERIAS.f_calcula_bimestres(PIDM,SP)BIMESTRE,
                                substr(DECODE(a.NIVEL,'LI','DIL0','MA','DIM0','DO','DID0'),4,1)+1 ireport,
                                ''AREA,
                                SMRPRLE_DEGC_CODE||'/'||STVDEGC_DESC GRADO,
                                NULL CODIGO_DIPLOMA
                            from tztprog a, spriden, sztdtec ,SMRPRLE,  STVDEGC, szthita
                            where 1=1
                            and a.PIDM = spriden_pidm
                            and spriden_change_ind is null
                            and a.PROGRAMA = SZTDTEC_PROGRAM
                            and a.ctlg = SZTDTEC_TERM_CODE
                            and  SMRPRLE_PROGRAM= a.programa
                            and SMRPRLE_DEGC_CODE=STVDEGC_CODE                           
                --            and SPRIDEN_ID = '010710160'
                            and a.estatus = 'MA'
                            AND A.CAMPUS in ('COL','ECU','GUA','BOL','PAR','DOM','ESP','ARG','URU','PAN','USA','CHI','SAL','UTL','PER')
                            and a.SGBSTDN_STYP_CODE = 'R'
                            and a.FECHA_PRIMERA >= '23/10/2023'
                            and SZTHITA_PIDM = a.PIDM
                            and SZTHITA_PROG = a.programa 
                            and SZTHITA_AVANCE = 0
                            and a.sp = (select max (a1.sp)
                                              from tztprog a1
                                              where 1=1
                                              and a1.pidm = a.pidm
                                              and a1.programa = a.programa)
                            and a.matricula||a.programa||DECODE(a.NIVEL,'LI','DIL0','MA','DIM0','DO','DID0') not in (select c.matricula||c.cod_programa||c.etiqueta
                                                                from SATURN.szrcaps c 
                                                                where a.matricula=c.matricula 
                                                                and a.programa=c.cod_programa 
                                                                and DECODE(a.NIVEL,'LI','DIL0','MA','DIM0','DO','DID0')=c.etiqueta
                                                                )
                                                                            
                 ) loop

                          Begin
                                    Insert into SATURN.SZRCAPS
                                    (
                                        MATRICULA, 
                                        NOMBRE_ALUMNO,
                                        APELLIDOS_ALUMNO,
                                        TIPO_ALUMNO, 
                                        FECHA_INICIO,
                                        FECHA_FIN,
                                        COD_PROGRAMA, 
                                        DESCRIPCION, 
                                        RVOE, 
                                        GENERO_SEX, 
                                        FACULTAD, 
                                        CORREO_PRINC, 
                                        CELULAR, 
                                        RINDIO, 
                                        NIVEL, 
                                        OCUPACION, 
                                        PAIS, 
                                        EDAD, 
                                        MOMENTO,
                                        FECHA_INSERT,
                                        DIPLOMA,
                                        ETIQUETA,
                                        ACCESORIO,
                                        PAGO,
                                        AVANCE_CURR,
                                        ESTADO_DIAGNOSTICO,
                                        COSTO,
                                        NUM_TRANSACCION,
                                        DIVISA,
                                        REFERENCIA_PAGO,
                                        BIMESTRE,
                                        IREPORT,
                                        AREA,
                                        GRADO,
                                        CODIGO_DIPLOMA,
                                        PIDM                                    
                                    )
                                    values
                                    (
                                        CX1.MATRICULA, 
                                        CX1.NOMBRE_ALUMNO,
                                        CX1.APELLIDOS_ALUMNO,
                                        CX1.TIPO_ALUMNO, 
                                        to_char(CX1.FECHA_INICIO,'dd/mm/yyyy'),
                                        to_char(CX1.FECHA_FIN,'dd/mm/yyyy'),
                                        CX1.COD_PROGRAMA, 
                                        CX1.DESCRIPCION, 
                                        CX1.RVOE, 
                                        CX1.GENERO_SEX, 
                                        CX1.FACULTAD, 
                                        CX1.CORREO_PRINC, 
                                        CX1.CELULAR, 
                                        CX1.RINDIO, 
                                        CX1.NIVEL, 
                                        CX1.OCUPACION, 
                                        CX1.PAIS, 
                                        CX1.EDAD, 
                                        CX1.MOMENTO,
                                        TO_char(SYSDATE,'dd/mm/yyyy'),
                                        CX1.DIPLOMA,
                                        CX1.ETIQUETA,
                                        CX1.ACCESORIO,
                                        CX1.PAGO,
                                        CX1.AVANCE_CURRI,
                                        CX1.ESTATUS,
                                        CX1.COSTO,
                                        CX1.TRANSACCION,
                                        CX1.DIVISA,
                                        CX1.REFERENCIA_PAGO,
                                        CX1.BIMESTRE,
                                        CX1.IREPORT,
                                        CX1.AREA,
                                        CX1.GRADO,
                                        CX1.CODIGO_DIPLOMA,
                                        FGET_PIDM(CX1.MATRICULA)
                                    )                                  
                                    ;
                          Exception
                            When Others then
                                null;
                          End;
                          
                          V_SALIDA:= PKG_UTILERIAS.F_Genera_Etiqueta(fget_pidm(cx1.matricula),cx1.etiqueta, cx1.etiqueta, 'BANINST1');
                          
                          IF(V_SALIDA='EXITO') THEN                          
                            Commit;
                          END IF;
                            
                End Loop cx1;                                                                                  
                 
    end;
    
    
    begin
             -----Actualiza el campo pago en los diplomas enviados   
            For c in (   
            
            --select  SZTQRDI_PIDM,SZTQRDI_ENVIADO_QR,SZTQRDI_ETIQUETA from sztqrdi where SZTQRDI_ENVIADO_QR='Y'
            
            select PIDM,ETIQUETA from szrcaps where PAGO='N' and pidm||ETIQUETA in (select  SZTQRDI_PIDM||SZTQRDI_ETIQUETA from sztqrdi where SZTQRDI_ENVIADO_QR='Y') 
            
            )loop
            
            update SZRCAPS set PAGO='Y' WHERE PIDM=c.PIDM AND ETIQUETA=c.ETIQUETA;
    
    end loop;
            commit;
    end;
    
    
 end  p_carga_caps;
 
 procedure p_actualiza_zsrcaps(p_matricula in varchar2, p_tipo_envio in varchar2, p_programa in varchar2, p_etiqueta in varchar2, p_rVoe in varchar2, p_tipoalumno in varchar2)
 is
 begin
 
  ----- Caty 7/11/2024
  ----- Actualiza fecha de las matriculas que fueron enviadas a Proveedor o moodle, Diplomas DPLO 
 
         --Moodle
        if(p_tipo_envio='M') then
          
            begin
            
                update saturn.szrcaps set UPDATE_MOODLE=to_char(sysdate,'dd/mm/yyyy') 
                where 
                    matricula = p_matricula 
                AND cod_programa=p_programa 
                AND etiqueta = p_etiqueta
                AND rVoe = p_rVoe
                AND TIPO_ALUMNO= p_tipoalumno
                and UPDATE_MOODLE IS NULL 
                                                       ;
                commit; 
              /*  Exception
                When Others then
                    null;*/
            end;                                              
        end if;   
        
        --Proveedor
        if(p_tipo_envio='P') then
              
            begin
            
                update saturn.szrcaps set UPDATE_PROVEEDOR=to_char(sysdate,'dd/mm/yyyy') 
                where   
                    matricula = p_matricula 
                AND cod_programa=p_programa 
                AND etiqueta = p_etiqueta
                AND rVoe = p_rVoe
                AND TIPO_ALUMNO= p_tipoalumno
                and UPDATE_PROVEEDOR IS NULL;
                                                        
                commit; 
                
            /*    Exception
                    When Others then
                    null;*/
            end;                                              
        end if;   


-- end;
 
 end p_actualiza_zsrcaps;
 
 
FUNCTION f_caps(p_matricula in varchar2 DEFAULT NULL, p_etiqueta in varchar2 DEFAULT NULL, p_noenviado_m in varchar2 DEFAULT NULL, p_noenviado_p in varchar2 DEFAULT NULL) RETURN PKG_REPORTES.cursor_c_caps
 AS
 c_out_caps PKG_REPORTES.cursor_c_caps;

 BEGIN
 
        --Obtiene cursor y Marca registros que se enviaron 
        --S es para que envie todos los nulos al proveedor o moodle 
        -- si no lleva esos parámetros se van todos los registros sin excepción o la matricula indicada
        
       IF p_noenviado_m = 'S' THEN       
        open c_out_caps
                FOR
                 
                    select distinct 
                                MATRICULA,
                                NOMBRE_ALUMNO,
                                APELLIDOS_ALUMNO,
                                TIPO_ALUMNO,
                                FECHA_INICIO,
                                FECHA_FIN,                                
                                COD_PROGRAMA,
                                DESCRIPCION,
                                RVOE,
                                GENERO_SEX,
                                FACULTAD,
                                CORREO_PRINC,
                                CELULAR,
                                RINDIO,
                                NIVEL,
                                OCUPACION,
                                PAIS,
                                EDAD,
                                MOMENTO,
                                UPDATE_MOODLE,
                                UPDATE_PROVEEDOR,                              
                                DIPLOMA,
                                ETIQUETA,
                                ACCESORIO,
                                PAGO,
                                AVANCE_CURR,
                                ESTADO_DIAGNOSTICO,
                                COSTO,
                                NUM_TRANSACCION,
                                DIVISA,
                                REFERENCIA_PAGO,
                                BIMESTRE,
                                IREPORT,
                                AREA,
                                GRADO,
                                CODIGO_DIPLOMA
                    from SATURN.SZRCAPS
                    where 1=1
                      AND matricula     = DECODE(p_matricula,null,matricula,p_matricula)
                      AND etiqueta      = DECODE(p_etiqueta,null,etiqueta,p_etiqueta)
                      AND UPDATE_MOODLE IS NULL
                              
                    ;     
              
                
              elsIF p_noenviado_p = 'S' THEN       
                open c_out_caps
                        FOR
                         
                            select distinct 
                                        MATRICULA,
                                        NOMBRE_ALUMNO,
                                        APELLIDOS_ALUMNO,
                                        TIPO_ALUMNO,
                                        FECHA_INICIO,
                                        FECHA_FIN,                                
                                        COD_PROGRAMA,
                                        DESCRIPCION,
                                        RVOE,
                                        GENERO_SEX,
                                        FACULTAD,
                                        CORREO_PRINC,
                                        CELULAR,
                                        RINDIO,
                                        NIVEL,
                                        OCUPACION,
                                        PAIS,
                                        EDAD,
                                        MOMENTO,
                                        UPDATE_MOODLE,
                                        UPDATE_PROVEEDOR,                              
                                        DIPLOMA,
                                        ETIQUETA,
                                        ACCESORIO,
                                        PAGO,
                                        AVANCE_CURR,
                                        ESTADO_DIAGNOSTICO,
                                        COSTO,
                                        NUM_TRANSACCION,
                                        DIVISA,
                                        REFERENCIA_PAGO,
                                        BIMESTRE,
                                        IREPORT,
                                        AREA,
                                        GRADO,
                                        CODIGO_DIPLOMA
                            from SATURN.SZRCAPS
                            where 1=1
                              AND matricula     = DECODE(p_matricula,null,matricula,p_matricula)
                              AND etiqueta      = DECODE(p_etiqueta,null,etiqueta,p_etiqueta)
                              AND UPDATE_PROVEEDOR IS NULL
                                      
                            ;     
                            
                     
                
                  else 
                    open c_out_caps
                            FOR
                             
                                select distinct 
                                            MATRICULA,
                                            NOMBRE_ALUMNO,
                                            APELLIDOS_ALUMNO,                               
                                            TIPO_ALUMNO,
                                            FECHA_INICIO,
                                            FECHA_FIN,                                
                                            COD_PROGRAMA,
                                            DESCRIPCION,
                                            RVOE,
                                            GENERO_SEX,
                                            FACULTAD,
                                            CORREO_PRINC,
                                            CELULAR,
                                            RINDIO,
                                            NIVEL,
                                            OCUPACION,
                                            PAIS,
                                            EDAD,
                                            MOMENTO,
                                            UPDATE_MOODLE,
                                            UPDATE_PROVEEDOR,                              
                                            DIPLOMA,
                                            ETIQUETA,
                                            ACCESORIO,
                                            PAGO,
                                            AVANCE_CURR,
                                            ESTADO_DIAGNOSTICO,
                                            COSTO,
                                            NUM_TRANSACCION,
                                            DIVISA,
                                            REFERENCIA_PAGO,
                                            BIMESTRE,
                                            IREPORT,
                                            AREA,
                                            GRADO,
                                            CODIGO_DIPLOMA                                           
                                from SATURN.SZRCAPS
                                where 1=1
                                  AND matricula     = DECODE(p_matricula,null,matricula,p_matricula)
                                  AND etiqueta      = DECODE(p_etiqueta,null,etiqueta,p_etiqueta)
                                 
                                          
                                ;     
                    
                END IF;
                                              
       

         RETURN (c_out_caps);

 END f_caps;


Procedure p_recoleccion_new as 

Begin


begin 


   EXECUTE IMMEDIATE 'TRUNCATE TABLE MIGRA.RECOLECCION';


    For cx in (

                 SELECT  DISTINCT
                 tz.sp,
                 tz.pidm,
                NVL(tz.Campus,'NA')Campus,
                NVL(tz.Nivel,'NA')Nivel,
                nvl(tz.CTLG, 'NA')  periodo_de_catalogo,
                NVL(tz.Programa,'NA')Programa,
                NVL(replace(tz.nombre,',', ' '),'NA')Descripcion_programa,
                NVL(tz.Matricula,'NA')Matricula,
                NVL(replace(replace( sp.SPRIDEN_LAST_NAME||' '||sp.SPRIDEN_FIRST_NAME,'/',' '),',',' '  ),'NA')nombre,
                NVL(y.STVSTYP_DESC, 'NA') TIPO_DE_INGRESO,
                NVL((select st.STVSTST_DESC
                         from STVSTST st
                         where 1=1
                         AND ST.STVSTST_CODE = tz.Estatus), 'NA')  Estatus,
                    NVL(GORADID_ADID_CODE,'NA')ETIQUETA_EXAL,
                    NVL(GORADID_ADDITIONAL_ID,'NA')IDENTIFICACION_ADICIONAL,
                    '35' Decision,
                --pkg_utilerias.f_sarappd_decision(SARADAP_PIDM, SARADAP_TERM_CODE_ENTRY, SARADAP_APPL_NO) Decision,
                 NVL(TO_CHAR(tz.Fecha_Inicio,'YYYY/MM/DD'),'1900/01/01')Fecha_Inicio,
                 NVL((SELECT  MAX (gore.goremal_email_address)
                                                     FROM goremal gore
                                                    WHERE gore.goremal_pidm=spriden_pidm 
                                                      AND gore.goremal_emal_code = 'PRIN'
                                                      AND gore.goremal_status_ind = 'A'
                                                      AND gore.goremal_surrogate_id =(SELECT  MAX (gore1.goremal_surrogate_id)
                                                                                              FROM goremal gore1
                                                                                             WHERE 1=1
                                                                                               AND gore.goremal_pidm =gore1.goremal_pidm
                                                                                               AND gore.goremal_emal_code =gore1.goremal_emal_code
                                                                                               AND gore.goremal_status_ind =gore1.goremal_status_ind)) , 'NA') Email,
                  NVL((select distinct max(SARACMT_COMMENT_TEXT )
                      FROM SARACMT 
                     WHERE SARACMT_PIDM = SPRIDEN_PIDM 
                       AND SARACMT_ORIG_CODE in ('EGTL', 'EGEX', 'EGRE')),'NA') Estatus_egreso,
                       TZ.TIPO_INGRESO_DESC estatus_ingreso,
                  NVL(  (select DISTINCT  max(SZT_ESTATUS)
                          from sztempd
                          where 1=1
                          and SZT_PIDM = tz.pidm
                          and SZT_BANDERA = 'O'
                          and SZT_PROGRAMA = tz.Programa), 'NA') documentos_fisicos,
                     NVL(  (select DISTINCT  max(SZT_ESTATUS)
                          from sztempd
                          where 1=1
                          and SZT_PIDM = tz.pidm
                          and SZT_BANDERA = 'D'
                          and SZT_PROGRAMA = tz.Programa),'NA') documentos_digitales,
                     NVL((select distinct trunc(a1.SARCHKL_RECEIVE_DATE) from SARCHKL a1 where SARCHKL_PIDM = TZ.PIDM --and SARCHKL_CKST_CODE!='NORECIBIDO'
                                                                     and trunc(a1.SARCHKL_RECEIVE_DATE)  = (select distinct max(trunc(a2.SARCHKL_RECEIVE_DATE)) from SARCHKL a2 
                                                                                                               where  a2.SARCHKL_PIDM = a1.SARCHKL_PIDM )),'01/01/1900') fecha_maxima
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('ACNO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Acta_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('ACNO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Acta_Orig  
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CPLO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Certificado_Parcial,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CPLO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Certificado_Parcial
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CACO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Compromiso_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CACO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Carta_Compromiso_Orig   
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CALO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Autentic_Certi_Bach_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CALO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') F_Carta_Aut_Certi_Bach_Orig   
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CPVO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Protes_Decir_Verdad_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CPVO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Car_Prot_Decir_Verd_Orig   
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CRDO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Responsiva_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CRDO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Carta_Responsiva_Orig   
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CESO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Certificado_De_Secundaria_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CESO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Certif_De_Sec_Orig   
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTBO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Total_Bachillerat_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTBO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Total_Bach_Orig   
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTLO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Certif_Tot_Lic_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTLO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Tot_Lic_Orig   
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTMO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Tot_Maes_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTMO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Tot_Maes_Orig
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTEO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Tot_Especial_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTEO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Tot_Especial_Orig
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTAO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Tot_Lic_AP_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTAO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Tot_Lic_AP__Orig
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTTO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Diploma_Titu_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTTO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Diploma_Titu_Orig
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('EQIO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Equivalencia_De_Estudios_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('EQIO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Equiv_De_Estudios_Orig
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FO4O')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Fotografias_Infantil_4_BN_M,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FO4O')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Foto_Infantil_4_BN_M
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FO6O')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Fotografias_Infantil_6_BN_M,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FO6O')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Foto_Infantil_6_BN_M
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FCOO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Fotografias_Cert_4_Ova_Creden,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FCOO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Foto_Cert_4_Ova_Creden
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FT6O')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Fotografias_Titulo_6_b_n,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FT6O')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Fotografias_Titulo_6_b_n
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FILO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Formato_Inscripcion_Alumn_Orig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FILO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Form_Inscr_Alumn_Orig
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('COLO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Constancia_Laboral_Original,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('COLO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Const_Laboral_Orig
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('ACND')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Acta_De_Nacimiento_Digital,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('ACND')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Acta_De_Nac_Digital
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CALD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Autentic_Certi_Ba_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CALD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Car_Auten_Certi_Ba_Dig
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CAMD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Motivos_Digital,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CAMD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Carta_Motivos_Digital
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CPVD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Protes_Decir_Verdad_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CPVD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cart_Prot_Decir_Verd_Dig
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('COLD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Constancia_Laboral_Digital,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('COLD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Const_Lab_Dig
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CACD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Compromiso,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CACD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Carta_Comp
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CESD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Certificado_De_Secundaria_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CESD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_De_Secundaria_Dig
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTBD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Total_Bachillerat_Dig,
                              nvl((select s.SZT_TIPO_DOC 
                              from SZTDOCST s
                              where s.SZT_ADMR_CODE='CTBD' 
                              and s.szt_pidm=tz.pidm
                              and s.SZT_ACTIVITY=(
                              select distinct max(s.SZT_ACTIVITY)
                              from SZTDOCST ss
                              where 
                                  ss.SZT_ADMR_CODE='CTBD' 
                               and ss.szt_pidm=s.szt_pidm)), 'NA') Clasif_Cert_Total_Bachille_Dig, 
                         nvl((select  distinct(replace(k.SARCHKL_COMMENT,'\"',''))
                              from SARCHKL k
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where k.SARCHKL_ADMR_CODE in ('CTBD')
                              and k.SARCHKL_PIDM =tz.pidm
                              --and  k.SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              and k.SARCHKL_SURROGATE_ID =(select max(sh.SARCHKL_SURROGATE_ID)  
                                                                from SARCHKL sh 
                                                              where sh.SARCHKL_ADMR_CODE = k.SARCHKL_ADMR_CODE
                                                              and sh.SARCHKL_PIDM =k.SARCHKL_PIDM
                              )), 'NA') Coment_Cert_Total_Bachille_Dig,       
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTBD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Total_Bach_Dig
                       , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CPLD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Parcial_Lic_Dig,
                        nvl((select s.SZT_TIPO_DOC 
                              from SZTDOCST s
                              where s.SZT_ADMR_CODE='CPLD' 
                              and s.szt_pidm=tz.pidm
                              and s.SZT_ACTIVITY=(
                              select distinct max(s.SZT_ACTIVITY)
                              from SZTDOCST ss
                              where 
                                  ss.SZT_ADMR_CODE='CPLD' 
                              and ss.szt_pidm=s.szt_pidm)),'NA')Clasif_Cert_Parcial_Lic_Dig,      
                        nvl((select  distinct(replace(k.SARCHKL_COMMENT,'\"',''))
                              from SARCHKL k
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where k.SARCHKL_ADMR_CODE in ('CPLD')
                              and k.SARCHKL_PIDM =tz.pidm
                              --and  k.SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              and k.SARCHKL_SURROGATE_ID =(select max(sh.SARCHKL_SURROGATE_ID)  
                                                                from SARCHKL sh 
                                                              where sh.SARCHKL_ADMR_CODE = k.SARCHKL_ADMR_CODE
                                                              and sh.SARCHKL_PIDM =k.SARCHKL_PIDM
                              )
                               ), 'NA') Coment_Cert_Parcial_Lic_Dig,                    
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CPLD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Parcial_Lic_Dig   
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTLD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Certificado_Total_Lic_Dig,
                              nvl((select s.SZT_TIPO_DOC 
                              from SZTDOCST s
                              where s.SZT_ADMR_CODE='CTLD' 
                              and s.szt_pidm=tz.pidm
                              and s.SZT_ACTIVITY=(
                              select distinct max(s.SZT_ACTIVITY)
                              from SZTDOCST ss
                              where 
                                  ss.SZT_ADMR_CODE='CTLD' 
                              and ss.szt_pidm=s.szt_pidm)),'NA')Clasif_Cert_Total_Lic_Dig,         
                          nvl((select  distinct(replace(k.SARCHKL_COMMENT,'\"',''))
                              from SARCHKL k
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where k.SARCHKL_ADMR_CODE in ('CTLD')
                              and k.SARCHKL_PIDM =tz.pidm
                              --and  k.SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              and k.SARCHKL_SURROGATE_ID =(select max(sh.SARCHKL_SURROGATE_ID)  
                                                                from SARCHKL sh 
                                                              where sh.SARCHKL_ADMR_CODE = k.SARCHKL_ADMR_CODE
                                                              and sh.SARCHKL_PIDM =k.SARCHKL_PIDM
                              )), 'NA') coment_Cert_Total_Lic_Dig,        
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTLD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Certificado_Tot_Lic_Dig
                           , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTMD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Certificado_Total_Maestria_Dig,
                          nvl((select s.SZT_TIPO_DOC 
                              from SZTDOCST s
                              where s.SZT_ADMR_CODE='CTMD' 
                              and s.szt_pidm=tz.pidm
                              and s.SZT_ACTIVITY=(
                              select distinct max(s.SZT_ACTIVITY)
                              from SZTDOCST ss
                              where 
                                  ss.SZT_ADMR_CODE='CTMD' 
                              and ss.szt_pidm=s.szt_pidm)),'NA')Clasif_Cert_Total_Maestria_Dig,                 
                          nvl((select  distinct(replace(k.SARCHKL_COMMENT,'\"',''))
                              from SARCHKL k
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where k.SARCHKL_ADMR_CODE in ('CTMD')
                              and k.SARCHKL_PIDM =tz.pidm
                           --   and  k.SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              and k.SARCHKL_SURROGATE_ID =(select max(sh.SARCHKL_SURROGATE_ID)  
                                                                from SARCHKL sh 
                                                              where sh.SARCHKL_ADMR_CODE = k.SARCHKL_ADMR_CODE
                                                              and sh.SARCHKL_PIDM =k.SARCHKL_PIDM
                              )), 'NA') Coment_Cert_Total_Maestria_Dig,             
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTMD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Total_Maestria_Dig
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTED')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Tot_Especial_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTED')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Tot_Especial_Dig
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTAD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Tot_Lic_AP_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTAD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Tot_Lic_AP__Dig
                          , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTTD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cert_Diploma_Titu_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CTTD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cert_Diploma_Titu_Dig
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('PAGD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Pago,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('PAGD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Pago
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CUGD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Ultimo_Grado_De_Estud,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CUGD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Ultimo_Grado_De_Estud
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CEGD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cedula_De_Grado_Digital,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CEGD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cedula_De_Grado_Dig
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CEPD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Cedula_Profesional_Digital,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CEPD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Cedula_Profesional_Dig
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CODD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Comprobante_De_Domicilio,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CODD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Comp_De_Dom
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CURD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') curp,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CURD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Curp
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('TITD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Titulo_Digital,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('TITD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Titulo_Digital
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('GRAD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Grado_Digital,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('GRAD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Grado_Digital
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('EQUD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Equivalencia_De_Estudios_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('EQUD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Equiv_De_Estudios_Dig
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FILD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Formato_Inscripcion_Alumn_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FILD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Formato_Inscr_Alumn_Dig
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('IDOD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Identificacion_Oficial,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('IDOD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Identificacion_Oficial
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('PRED')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Predictamen_De_Equivalencia,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('PRED')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Predictamen_De_Equiv
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('SOAD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Solicitud_De_Admision,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('SOAD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Solicitud_De_Admision
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CAPO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Carta_Poder,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('CAPO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Carta_Poder
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('ACSD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Antecedente_Cert_Secu_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('(ACSD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Antec_Cert_Sec_Dig        
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('DIRO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Dictamen_Revalidacion_Org,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('DIRO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fech_Dic_Rev_Org
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('DIRV')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Dictamen_Revalidacion_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('DIRV')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fech_Dict_Reval_Dig
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('DICD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Dictamen_Sep_Dig,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('DICD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fech_Dict_Sep_Dig
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('DICO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Dictamen_Sep_Original,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('DICO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fech_Dictamen_Sep_Ori
                        , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FESD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Foto_Estudiante_Solici_Digital,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('FESD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fecha_Est_Sol_Dig  
                      , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('OVAD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Ofi_Validac_Anteced_Acad_Di,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('OVAD')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fech_Ofi_Validac_Anteced_Acad_Di 
                         , nvl((select distinct MAX( SARCHKL_CKST_CODE)
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('OVAO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), 'NA') Ofi_Validac_Anteced_Acad_Fi,
                         nvl((select distinct max(to_char(SARCHKL_SOURCE_DATE, 'yyyy/mm/dd'))
                              from SARCHKL
                              join SARCHKB on SARCHKB_ADMR_CODE = SARCHKL_ADMR_CODE and SARCHKB_CAMP_CODE =tz.campus and  SARCHKB_LEVL_CODE =tz.nivel
                              where SARCHKL_ADMR_CODE in ('OVAO')
                              and SARCHKL_PIDM =tz.pidm
                              --and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO
                              ), '1900/01/01') Fech_Ofi_Validac_Anteced_Acad_Fi      
            from tztprog_all tz
            JOIN SPRIDEN SP  ON  SP.SPRIDEN_PIDM = TZ.PIDM  AND sp.SPRIDEN_CHANGE_IND   IS NULL
--            left JOIN SARADAP dd  ON  DD.SARADAP_PIDM = TZ.PIDM  and tz.campus = TZ.CAMPUS  and tz.nivel = TZ.NIVEL and dd.SARADAP_PROGRAM_1 = tz.programa  ---------- 
--                       And dd.SARADAP_APPL_NO = (select max (dd1.SARADAP_APPL_NO)
--                                        from saradap dd1
--                                       Where dd.saradap_pidm = dd1.saradap_pidm
--                                       And dd.saradap_program_1 = dd1.saradap_program_1
--                                      -- and SARADAP_APST_CODE='A'
--                                       )
            left JOIN STVSTYP  y  ON  Y.STVSTYP_CODE =  TZ.SGBSTDN_STYP_CODE   
            left JOIN GORADID GR ON GR.GORADID_PIDM=TZ.PIDM AND GR.GORADID_ADID_CODE='EXAL' AND GORADID_ACTIVITY_DATE IN(select distinct max(GORADID_ACTIVITY_DATE)  ------
              FROM GORADID GRR
              WHERE GRR.GORADID_PIDM=tz.pidm
              AND  GRR.GORADID_ADID_CODE='EXAL') 
             where 1=1
--             And tz.matricula ='010001042'
             order by 2,3,6,1
             
        ) loop
        
        
                Begin
                    Insert into recoleccion values  (  cx.SP  ,
                                          cx.PIDM                              ,
                                          cx.CAMPUS                            ,
                                          cx.NIVEL                             ,
                                          cx.PERIODO_DE_CATALOGO               ,
                                          cx.PROGRAMA                          ,
                                          cx.DESCRIPCION_PROGRAMA              ,
                                          cx.MATRICULA                         ,
                                          cx.NOMBRE                            ,
                                          cx.TIPO_DE_INGRESO                   ,
                                          cx.ESTATUS                           ,
                                          cx.ETIQUETA_EXAL                     ,
                                          cx.IDENTIFICACION_ADICIONAL          ,
                                          cx.DECISION                          ,
                                          cx.FECHA_INICIO                      ,
                                          cx.EMAIL                             ,
                                          cx.ESTATUS_EGRESO                    ,
                                          cx.ESTATUS_INGRESO                   ,
                                          cx.DOCUMENTOS_FISICOS                ,
                                          cx.DOCUMENTOS_DIGITALES              ,
                                          cx.FECHA_MAXIMA                      ,
                                          cx.ACTA_ORIG                         ,
                                          cx.FECHA_ACTA_ORIG                   ,
                                          cx.CERTIFICADO_PARCIAL               ,
                                          cx.FECHA_CERTIFICADO_PARCIAL         ,
                                          cx.CARTA_COMPROMISO_ORIG             ,
                                          cx.FECHA_CARTA_COMPROMISO_ORIG       ,
                                          cx.CARTA_AUTENTIC_CERTI_BACH_ORIG    ,
                                          cx.F_CARTA_AUT_CERTI_BACH_ORIG       ,
                                          cx.CARTA_PROTES_DECIR_VERDAD_ORIG    ,
                                          cx.FECHA_CAR_PROT_DECIR_VERD_ORIG    ,
                                          cx.CARTA_RESPONSIVA_ORIG             ,
                                          cx.FECHA_CARTA_RESPONSIVA_ORIG       ,
                                          cx.CERTIFICADO_DE_SECUNDARIA_ORIG    ,
                                          cx.FECHA_CERTIF_DE_SEC_ORIG          ,
                                          cx.CERT_TOTAL_BACHILLERAT_ORIG       ,
                                          cx.FECHA_CERT_TOTAL_BACH_ORIG        ,
                                          cx.CERTIF_TOT_LIC_ORIG               ,
                                          cx.FECHA_CERT_TOT_LIC_ORIG           ,
                                          cx.CERT_TOT_MAES_ORIG                ,
                                          cx.FECHA_CERT_TOT_MAES_ORIG          ,
                                          cx.CERT_TOT_ESPECIAL_ORIG            ,
                                          cx.FECHA_CERT_TOT_ESPECIAL_ORIG      ,
                                          cx.CERT_TOT_LIC_AP_ORIG              ,
                                          cx.FECHA_CERT_TOT_LIC_AP__ORIG       ,
                                          cx.CERT_DIPLOMA_TITU_ORIG            ,
                                          cx.FECHA_CERT_DIPLOMA_TITU_ORIG      ,
                                          cx.EQUIVALENCIA_DE_ESTUDIOS_ORIG     ,
                                          cx.FECHA_EQUIV_DE_ESTUDIOS_ORIG      ,
                                          cx.FOTOGRAFIAS_INFANTIL_4_BN_M       ,
                                          cx.FECHA_FOTO_INFANTIL_4_BN_M        ,
                                          cx.FOTOGRAFIAS_INFANTIL_6_BN_M       ,
                                          cx.FECHA_FOTO_INFANTIL_6_BN_M        ,
                                          cx.FOTOGRAFIAS_CERT_4_OVA_CREDEN     ,
                                          cx.FECHA_FOTO_CERT_4_OVA_CREDEN      ,
                                          cx.FOTOGRAFIAS_TITULO_6_B_N          ,
                                          cx.FECHA_FOTOGRAFIAS_TITULO_6_B_N    ,
                                          cx.FORMATO_INSCRIPCION_ALUMN_ORIG    ,
                                          cx.FECHA_FORM_INSCR_ALUMN_ORIG       ,
                                          cx.CONSTANCIA_LABORAL_ORIGINAL       ,
                                          cx.FECHA_CONST_LABORAL_ORIG          ,
                                          cx.ACTA_DE_NACIMIENTO_DIGITAL        ,
                                          cx.FECHA_ACTA_DE_NAC_DIGITAL         ,
                                          cx.CARTA_AUTENTIC_CERTI_BA_DIG       ,
                                          cx.FECHA_CAR_AUTEN_CERTI_BA_DIG      ,
                                          cx.CARTA_MOTIVOS_DIGITAL             ,
                                          cx.FECHA_CARTA_MOTIVOS_DIGITAL       ,
                                          cx.CARTA_PROTES_DECIR_VERDAD_DIG     ,
                                          cx.FECHA_CART_PROT_DECIR_VERD_DIG    ,
                                          cx.CONSTANCIA_LABORAL_DIGITAL        ,
                                          cx.FECHA_CONST_LAB_DIG               ,
                                          cx.CARTA_COMPROMISO                  ,
                                          cx.FECHA_CARTA_COMP                  ,
                                          cx.CERTIFICADO_DE_SECUNDARIA_DIG     ,
                                          cx.FECHA_CERT_DE_SECUNDARIA_DIG      ,
                                          cx.CERT_TOTAL_BACHILLERAT_DIG        ,
                                          cx.CLASIF_CERT_TOTAL_BACHILLE_DIG    ,
                                          cx.COMENT_CERT_TOTAL_BACHILLE_DIG    ,
                                          cx.FECHA_CERT_TOTAL_BACH_DIG         ,
                                          cx.CERT_PARCIAL_LIC_DIG              ,
                                          cx.CLASIF_CERT_PARCIAL_LIC_DIG       ,
                                          cx.COMENT_CERT_PARCIAL_LIC_DIG       ,
                                          cx.FECHA_CERT_PARCIAL_LIC_DIG        ,
                                          cx.CERTIFICADO_TOTAL_LIC_DIG         ,
                                          cx.CLASIF_CERT_TOTAL_LIC_DIG         ,
                                          cx.COMENT_CERT_TOTAL_LIC_DIG         ,
                                          cx.FECHA_CERTIFICADO_TOT_LIC_DIG     ,
                                          cx.CERTIFICADO_TOTAL_MAESTRIA_DIG    ,
                                          cx.CLASIF_CERT_TOTAL_MAESTRIA_DIG    ,
                                          cx.COMENT_CERT_TOTAL_MAESTRIA_DIG    ,
                                          cx.FECHA_CERT_TOTAL_MAESTRIA_DIG     ,
                                          cx.CERT_TOT_ESPECIAL_DIG             ,
                                          cx.FECHA_CERT_TOT_ESPECIAL_DIG       ,
                                          cx.CERT_TOT_LIC_AP_DIG               ,
                                          cx.FECHA_CERT_TOT_LIC_AP__DIG        ,
                                          cx.CERT_DIPLOMA_TITU_DIG             ,
                                          cx.FECHA_CERT_DIPLOMA_TITU_DIG       ,
                                          cx.PAGO                              ,
                                          cx.FECHA_PAGO                        ,
                                          cx.ULTIMO_GRADO_DE_ESTUD             ,
                                          cx.FECHA_ULTIMO_GRADO_DE_ESTUD       ,
                                          cx.CEDULA_DE_GRADO_DIGITAL           ,
                                          cx.FECHA_CEDULA_DE_GRADO_DIG         ,
                                          cx.CEDULA_PROFESIONAL_DIGITAL        ,
                                          cx.FECHA_CEDULA_PROFESIONAL_DIG      ,
                                          cx.COMPROBANTE_DE_DOMICILIO          ,
                                          cx.FECHA_COMP_DE_DOM                 ,
                                          cx.CURP                              ,
                                          cx.FECHA_CURP                        ,
                                          cx.TITULO_DIGITAL                    ,
                                          cx.FECHA_TITULO_DIGITAL              ,
                                          cx.GRADO_DIGITAL                     ,
                                          cx.FECHA_GRADO_DIGITAL               ,
                                          cx.EQUIVALENCIA_DE_ESTUDIOS_DIG      ,
                                          cx.FECHA_EQUIV_DE_ESTUDIOS_DIG       ,
                                          cx.FORMATO_INSCRIPCION_ALUMN_DIG     ,
                                          cx.FECHA_FORMATO_INSCR_ALUMN_DIG     ,
                                          cx.IDENTIFICACION_OFICIAL            ,
                                          cx.FECHA_IDENTIFICACION_OFICIAL      ,
                                          cx.PREDICTAMEN_DE_EQUIVALENCIA       ,
                                          cx.FECHA_PREDICTAMEN_DE_EQUIV        ,
                                          cx.SOLICITUD_DE_ADMISION             ,
                                          cx.FECHA_SOLICITUD_DE_ADMISION       ,
                                          cx.CARTA_PODER                       ,
                                          cx.FECHA_CARTA_PODER                 ,
                                          cx.ANTECEDENTE_CERT_SECU_DIG         ,
                                          cx.FECHA_ANTEC_CERT_SEC_DIG          ,
                                          cx.DICTAMEN_REVALIDACION_ORG         ,
                                          cx.FECH_DIC_REV_ORG                  ,
                                          cx.DICTAMEN_REVALIDACION_DIG         ,
                                          cx.FECH_DICT_REVAL_DIG               ,
                                          cx.DICTAMEN_SEP_DIG                  ,
                                          cx.FECH_DICT_SEP_DIG                 ,
                                          cx.DICTAMEN_SEP_ORIGINAL             ,
                                          cx.FECH_DICTAMEN_SEP_ORI             ,
                                          cx.FOTO_ESTUDIANTE_SOLICI_DIGITAL    ,
                                          cx.FECHA_EST_SOL_DIG                 ,
                                          cx.OFI_VALIDAC_ANTECED_ACAD_DI       ,
                                          cx.FECH_OFI_VALIDAC_ANTECED_ACAD_DI  ,
                                          cx.OFI_VALIDAC_ANTECED_ACAD_FI       ,
                                          cx.FECH_OFI_VALIDAC_ANTECED_ACAD_FI  
                                        );
                Exception
                    When Others then
                        null;
                End;
                Commit;
        
        End loop CX;
    
    End;
        
        

Begin 
    
        For cx in (
    
                    select distinct count(*), campus, nivel, pidm 
                    from recoleccion
                    where 1=1
                    --And estatus ='CAMBIO DE PROGRAMA'
                   -- and pidm = 109998
                    group by campus, nivel, pidm
                    having count(*) > 1


        ) loop
        
                Begin
                    
                
                   For cx2 in (
                                select *
                                from recoleccion
                                where pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                
                    ) loop
                    
                    If cx2.IDENTIFICACION_ADICIONAL not in ('NA') then 
                        Begin
                            Update recoleccion
                            set IDENTIFICACION_ADICIONAL = cx2.IDENTIFICACION_ADICIONAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;
                    
                    If cx2.DOCUMENTOS_FISICOS not in ('NA') then 
                        Begin
                            Update recoleccion
                            set DOCUMENTOS_FISICOS = cx2.DOCUMENTOS_FISICOS
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                    

                    If cx2.DOCUMENTOS_DIGITALES not in ('NA') then 
                        Begin
                            Update recoleccion
                            set DOCUMENTOS_DIGITALES = cx2.DOCUMENTOS_DIGITALES
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    
                    
                    If cx2.ACTA_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set ACTA_ORIG = cx2.ACTA_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;     
  
                    If cx2.FECHA_ACTA_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set FECHA_ACTA_ORIG = cx2.FECHA_ACTA_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                     

                    If cx2.CERTIFICADO_PARCIAL not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CERTIFICADO_PARCIAL = cx2.CERTIFICADO_PARCIAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                                            

                    If cx2.FECHA_CERTIFICADO_PARCIAL not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CERTIFICADO_PARCIAL = cx2.FECHA_CERTIFICADO_PARCIAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  
                    
                    If cx2.CARTA_COMPROMISO_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CARTA_COMPROMISO_ORIG = cx2.CARTA_COMPROMISO_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      
                    
                    If cx2.FECHA_CARTA_COMPROMISO_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CARTA_COMPROMISO_ORIG = cx2.FECHA_CARTA_COMPROMISO_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                         
                    
                   If cx2.CARTA_AUTENTIC_CERTI_BACH_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CARTA_AUTENTIC_CERTI_BACH_ORIG = cx2.CARTA_AUTENTIC_CERTI_BACH_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                         

                   If cx2.F_CARTA_AUT_CERTI_BACH_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set F_CARTA_AUT_CERTI_BACH_ORIG = cx2.F_CARTA_AUT_CERTI_BACH_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    
                    
                   If cx2.CARTA_PROTES_DECIR_VERDAD_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CARTA_PROTES_DECIR_VERDAD_ORIG = cx2.CARTA_PROTES_DECIR_VERDAD_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;     
                      
                    If cx2.FECHA_CAR_PROT_DECIR_VERD_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CAR_PROT_DECIR_VERD_ORIG = cx2.FECHA_CAR_PROT_DECIR_VERD_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;     
                    
                    If cx2.CARTA_RESPONSIVA_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CARTA_RESPONSIVA_ORIG = cx2.CARTA_RESPONSIVA_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                                        

                    If cx2.FECHA_CARTA_RESPONSIVA_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CARTA_RESPONSIVA_ORIG = cx2.FECHA_CARTA_RESPONSIVA_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if; 
                    
                    If cx2.CERTIFICADO_DE_SECUNDARIA_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CERTIFICADO_DE_SECUNDARIA_ORIG = cx2.CERTIFICADO_DE_SECUNDARIA_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    
                    
                    If cx2.FECHA_CERTIF_DE_SEC_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CERTIF_DE_SEC_ORIG = cx2.FECHA_CERTIF_DE_SEC_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                              

                    If cx2.CERT_TOTAL_BACHILLERAT_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CERT_TOTAL_BACHILLERAT_ORIG = cx2.CERT_TOTAL_BACHILLERAT_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;      

                    If cx2.FECHA_CERT_TOTAL_BACH_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOTAL_BACH_ORIG = cx2.FECHA_CERT_TOTAL_BACH_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;      

                    If cx2.CERTIF_TOT_LIC_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CERTIF_TOT_LIC_ORIG = cx2.CERTIF_TOT_LIC_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;     

                    If cx2.FECHA_CERT_TOT_LIC_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOT_LIC_ORIG = cx2.FECHA_CERT_TOT_LIC_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    

                    If cx2.CERT_TOT_MAES_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CERT_TOT_MAES_ORIG = cx2.CERT_TOT_MAES_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;   
                    
                    If cx2.FECHA_CERT_TOT_MAES_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOT_MAES_ORIG = cx2.FECHA_CERT_TOT_MAES_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    
                    
                    If cx2.CERT_TOT_ESPECIAL_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CERT_TOT_ESPECIAL_ORIG = cx2.CERT_TOT_ESPECIAL_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;     
                    
                    If cx2.FECHA_CERT_TOT_ESPECIAL_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOT_ESPECIAL_ORIG = cx2.FECHA_CERT_TOT_ESPECIAL_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                                             

                    If cx2.CERT_TOT_LIC_AP_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CERT_TOT_LIC_AP_ORIG = cx2.CERT_TOT_LIC_AP_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;      

                    If cx2.FECHA_CERT_TOT_LIC_AP__ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOT_LIC_AP__ORIG = cx2.FECHA_CERT_TOT_LIC_AP__ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;   

                    If cx2.CERT_DIPLOMA_TITU_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set CERT_DIPLOMA_TITU_ORIG = cx2.CERT_DIPLOMA_TITU_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;   
                    
                    If cx2.FECHA_CERT_DIPLOMA_TITU_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_CERT_DIPLOMA_TITU_ORIG = cx2.FECHA_CERT_DIPLOMA_TITU_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                       

                    If cx2.EQUIVALENCIA_DE_ESTUDIOS_ORIG not in ('NA') then 
                        Begin
                            Update recoleccion
                            set EQUIVALENCIA_DE_ESTUDIOS_ORIG = cx2.EQUIVALENCIA_DE_ESTUDIOS_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;   

                    If cx2.FECHA_EQUIV_DE_ESTUDIOS_ORIG not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_EQUIV_DE_ESTUDIOS_ORIG = cx2.FECHA_EQUIV_DE_ESTUDIOS_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;   
                    
                    If cx2.FOTOGRAFIAS_INFANTIL_4_BN_M not in ('NA') then 
                        Begin
                            Update recoleccion
                            set FOTOGRAFIAS_INFANTIL_4_BN_M = cx2.FOTOGRAFIAS_INFANTIL_4_BN_M
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if; 
                    
                    If cx2.FECHA_FOTO_INFANTIL_4_BN_M not in ('1900/01/01') then 
                        Begin
                            Update recoleccion
                            set FECHA_FOTO_INFANTIL_4_BN_M = cx2.FECHA_FOTO_INFANTIL_4_BN_M
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                           

                    If cx2.FOTOGRAFIAS_INFANTIL_6_BN_M not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set FOTOGRAFIAS_INFANTIL_6_BN_M = cx2.FOTOGRAFIAS_INFANTIL_6_BN_M
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;   
                   
                    If cx2.FECHA_FOTO_INFANTIL_6_BN_M not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_FOTO_INFANTIL_6_BN_M = cx2.FECHA_FOTO_INFANTIL_6_BN_M
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FOTOGRAFIAS_CERT_4_OVA_CREDEN not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set FOTOGRAFIAS_CERT_4_OVA_CREDEN = cx2.FOTOGRAFIAS_CERT_4_OVA_CREDEN
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  
                    
                    If cx2.FECHA_FOTO_CERT_4_OVA_CREDEN not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_FOTO_CERT_4_OVA_CREDEN = cx2.FECHA_FOTO_CERT_4_OVA_CREDEN
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                            
                    
                    If cx2.FOTOGRAFIAS_TITULO_6_B_N not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set FOTOGRAFIAS_TITULO_6_B_N = cx2.FOTOGRAFIAS_TITULO_6_B_N
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;      
                    
                    If cx2.FECHA_FOTOGRAFIAS_TITULO_6_B_N not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_FOTOGRAFIAS_TITULO_6_B_N = cx2.FECHA_FOTOGRAFIAS_TITULO_6_B_N
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                         
                    
                    If cx2.FORMATO_INSCRIPCION_ALUMN_ORIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set FORMATO_INSCRIPCION_ALUMN_ORIG = cx2.FORMATO_INSCRIPCION_ALUMN_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                       
                    
                    If cx2.FECHA_FORM_INSCR_ALUMN_ORIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_FORM_INSCR_ALUMN_ORIG = cx2.FECHA_FORM_INSCR_ALUMN_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                       

                    If cx2.CONSTANCIA_LABORAL_ORIGINAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CONSTANCIA_LABORAL_ORIGINAL = cx2.CONSTANCIA_LABORAL_ORIGINAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;   
                    
                    If cx2.FECHA_CONST_LABORAL_ORIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CONST_LABORAL_ORIG = cx2.FECHA_CONST_LABORAL_ORIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                       
                        
                    If cx2.ACTA_DE_NACIMIENTO_DIGITAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set ACTA_DE_NACIMIENTO_DIGITAL = cx2.ACTA_DE_NACIMIENTO_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    
                    
                    If cx2.FECHA_ACTA_DE_NAC_DIGITAL not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_ACTA_DE_NAC_DIGITAL = cx2.FECHA_ACTA_DE_NAC_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                           

                    If cx2.CARTA_AUTENTIC_CERTI_BA_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CARTA_AUTENTIC_CERTI_BA_DIG = cx2.CARTA_AUTENTIC_CERTI_BA_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                    If cx2.FECHA_CAR_AUTEN_CERTI_BA_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CAR_AUTEN_CERTI_BA_DIG = cx2.FECHA_CAR_AUTEN_CERTI_BA_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                    If cx2.CARTA_MOTIVOS_DIGITAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CARTA_MOTIVOS_DIGITAL = cx2.CARTA_MOTIVOS_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                    If cx2.FECHA_CARTA_MOTIVOS_DIGITAL not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CARTA_MOTIVOS_DIGITAL = cx2.FECHA_CARTA_MOTIVOS_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                    If cx2.CARTA_PROTES_DECIR_VERDAD_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CARTA_PROTES_DECIR_VERDAD_DIG = cx2.CARTA_PROTES_DECIR_VERDAD_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                    If cx2.FECHA_CART_PROT_DECIR_VERD_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CART_PROT_DECIR_VERD_DIG = cx2.FECHA_CART_PROT_DECIR_VERD_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                    If cx2.CONSTANCIA_LABORAL_DIGITAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CONSTANCIA_LABORAL_DIGITAL = cx2.CONSTANCIA_LABORAL_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                    If cx2.FECHA_CONST_LAB_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CONST_LAB_DIG = cx2.FECHA_CONST_LAB_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;         

                    If cx2.CARTA_COMPROMISO not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CARTA_COMPROMISO = cx2.CARTA_COMPROMISO
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;         

                    If cx2.FECHA_CARTA_COMP not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CARTA_COMP = cx2.FECHA_CARTA_COMP
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;         

                    If cx2.CERTIFICADO_DE_SECUNDARIA_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CERTIFICADO_DE_SECUNDARIA_DIG = cx2.CERTIFICADO_DE_SECUNDARIA_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;         

                    If cx2.FECHA_CERT_DE_SECUNDARIA_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CERT_DE_SECUNDARIA_DIG = cx2.FECHA_CERT_DE_SECUNDARIA_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    

                   If cx2.CERT_TOTAL_BACHILLERAT_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CERT_TOTAL_BACHILLERAT_DIG = cx2.CERT_TOTAL_BACHILLERAT_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;         

                    If cx2.CLASIF_CERT_TOTAL_BACHILLE_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CLASIF_CERT_TOTAL_BACHILLE_DIG = cx2.CLASIF_CERT_TOTAL_BACHILLE_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    

                    If cx2.COMENT_CERT_TOTAL_BACHILLE_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set COMENT_CERT_TOTAL_BACHILLE_DIG = cx2.COMENT_CERT_TOTAL_BACHILLE_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CERT_TOTAL_BACH_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOTAL_BACH_DIG = cx2.FECHA_CERT_TOTAL_BACH_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CERT_PARCIAL_LIC_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CERT_PARCIAL_LIC_DIG = cx2.CERT_PARCIAL_LIC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CLASIF_CERT_PARCIAL_LIC_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CLASIF_CERT_PARCIAL_LIC_DIG = cx2.CLASIF_CERT_PARCIAL_LIC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.COMENT_CERT_PARCIAL_LIC_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set COMENT_CERT_PARCIAL_LIC_DIG = cx2.COMENT_CERT_PARCIAL_LIC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CERT_PARCIAL_LIC_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CERT_PARCIAL_LIC_DIG = cx2.FECHA_CERT_PARCIAL_LIC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CERTIFICADO_TOTAL_LIC_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CERTIFICADO_TOTAL_LIC_DIG = cx2.CERTIFICADO_TOTAL_LIC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CLASIF_CERT_TOTAL_LIC_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CLASIF_CERT_TOTAL_LIC_DIG = cx2.CLASIF_CERT_TOTAL_LIC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.COMENT_CERT_TOTAL_LIC_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set COMENT_CERT_TOTAL_LIC_DIG = cx2.COMENT_CERT_TOTAL_LIC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CERTIFICADO_TOT_LIC_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CERTIFICADO_TOT_LIC_DIG = cx2.FECHA_CERTIFICADO_TOT_LIC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CERTIFICADO_TOTAL_MAESTRIA_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CERTIFICADO_TOTAL_MAESTRIA_DIG = cx2.CERTIFICADO_TOTAL_MAESTRIA_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CLASIF_CERT_TOTAL_MAESTRIA_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CLASIF_CERT_TOTAL_MAESTRIA_DIG = cx2.CLASIF_CERT_TOTAL_MAESTRIA_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.COMENT_CERT_TOTAL_MAESTRIA_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set COMENT_CERT_TOTAL_MAESTRIA_DIG = cx2.COMENT_CERT_TOTAL_MAESTRIA_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CERT_TOTAL_MAESTRIA_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOTAL_MAESTRIA_DIG = cx2.FECHA_CERT_TOTAL_MAESTRIA_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CERT_TOT_ESPECIAL_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CERT_TOT_ESPECIAL_DIG = cx2.CERT_TOT_ESPECIAL_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CERT_TOT_ESPECIAL_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOT_ESPECIAL_DIG = cx2.FECHA_CERT_TOT_ESPECIAL_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CERT_TOT_LIC_AP_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CERT_TOT_LIC_AP_DIG = cx2.CERT_TOT_LIC_AP_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CERT_TOT_LIC_AP__DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CERT_TOT_LIC_AP__DIG = cx2.FECHA_CERT_TOT_LIC_AP__DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CERT_DIPLOMA_TITU_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CERT_DIPLOMA_TITU_DIG = cx2.CERT_DIPLOMA_TITU_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CERT_DIPLOMA_TITU_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CERT_DIPLOMA_TITU_DIG = cx2.FECHA_CERT_DIPLOMA_TITU_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.PAGO not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set PAGO = cx2.PAGO
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  
                    
                    If cx2.FECHA_PAGO not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_PAGO = cx2.FECHA_PAGO
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  
                    
                    If cx2.ULTIMO_GRADO_DE_ESTUD not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set ULTIMO_GRADO_DE_ESTUD = cx2.ULTIMO_GRADO_DE_ESTUD
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_ULTIMO_GRADO_DE_ESTUD not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_ULTIMO_GRADO_DE_ESTUD = cx2.FECHA_ULTIMO_GRADO_DE_ESTUD
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;        
                    
                    If cx2.CEDULA_DE_GRADO_DIGITAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CEDULA_DE_GRADO_DIGITAL = cx2.CEDULA_DE_GRADO_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                        

                    If cx2.FECHA_CEDULA_DE_GRADO_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CEDULA_DE_GRADO_DIG = cx2.FECHA_CEDULA_DE_GRADO_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.CEDULA_PROFESIONAL_DIGITAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CEDULA_PROFESIONAL_DIGITAL = cx2.CEDULA_PROFESIONAL_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CEDULA_PROFESIONAL_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CEDULA_PROFESIONAL_DIG = cx2.FECHA_CEDULA_PROFESIONAL_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.COMPROBANTE_DE_DOMICILIO not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set COMPROBANTE_DE_DOMICILIO = cx2.COMPROBANTE_DE_DOMICILIO
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_COMP_DE_DOM not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_COMP_DE_DOM = cx2.FECHA_COMP_DE_DOM
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                   If cx2.CURP not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CURP = cx2.CURP
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CURP not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CURP = cx2.FECHA_CURP
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                   If cx2.TITULO_DIGITAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set TITULO_DIGITAL = cx2.TITULO_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_TITULO_DIGITAL not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_TITULO_DIGITAL = cx2.FECHA_TITULO_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  
                    

                   If cx2.GRADO_DIGITAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set GRADO_DIGITAL = cx2.GRADO_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_GRADO_DIGITAL not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_GRADO_DIGITAL = cx2.FECHA_GRADO_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                  If cx2.EQUIVALENCIA_DE_ESTUDIOS_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set EQUIVALENCIA_DE_ESTUDIOS_DIG = cx2.EQUIVALENCIA_DE_ESTUDIOS_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_EQUIV_DE_ESTUDIOS_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_EQUIV_DE_ESTUDIOS_DIG = cx2.FECHA_EQUIV_DE_ESTUDIOS_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      


                 If cx2.FORMATO_INSCRIPCION_ALUMN_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set FORMATO_INSCRIPCION_ALUMN_DIG = cx2.FORMATO_INSCRIPCION_ALUMN_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_FORMATO_INSCR_ALUMN_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_FORMATO_INSCR_ALUMN_DIG = cx2.FECHA_FORMATO_INSCR_ALUMN_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      


                 If cx2.IDENTIFICACION_OFICIAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set IDENTIFICACION_OFICIAL = cx2.IDENTIFICACION_OFICIAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_IDENTIFICACION_OFICIAL not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_IDENTIFICACION_OFICIAL = cx2.FECHA_IDENTIFICACION_OFICIAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                      

                 If cx2.PREDICTAMEN_DE_EQUIVALENCIA not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set PREDICTAMEN_DE_EQUIVALENCIA = cx2.PREDICTAMEN_DE_EQUIVALENCIA
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_PREDICTAMEN_DE_EQUIV not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_PREDICTAMEN_DE_EQUIV = cx2.FECHA_PREDICTAMEN_DE_EQUIV
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;       

                 If cx2.SOLICITUD_DE_ADMISION not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set SOLICITUD_DE_ADMISION = cx2.SOLICITUD_DE_ADMISION
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_SOLICITUD_DE_ADMISION not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_SOLICITUD_DE_ADMISION = cx2.FECHA_SOLICITUD_DE_ADMISION
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;    

                 If cx2.CARTA_PODER not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set CARTA_PODER = cx2.CARTA_PODER
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_CARTA_PODER not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_CARTA_PODER = cx2.FECHA_CARTA_PODER
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if; 

                 If cx2.ANTECEDENTE_CERT_SECU_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set ANTECEDENTE_CERT_SECU_DIG = cx2.ANTECEDENTE_CERT_SECU_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_ANTEC_CERT_SEC_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_ANTEC_CERT_SEC_DIG = cx2.FECHA_ANTEC_CERT_SEC_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if; 


                 If cx2.DICTAMEN_REVALIDACION_ORG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set DICTAMEN_REVALIDACION_ORG = cx2.DICTAMEN_REVALIDACION_ORG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECH_DIC_REV_ORG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECH_DIC_REV_ORG = cx2.FECH_DIC_REV_ORG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if; 

                If cx2.DICTAMEN_REVALIDACION_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set DICTAMEN_REVALIDACION_DIG = cx2.DICTAMEN_REVALIDACION_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECH_DICT_REVAL_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECH_DICT_REVAL_DIG = cx2.FECH_DICT_REVAL_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if; 


                If cx2.DICTAMEN_SEP_DIG not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set DICTAMEN_SEP_DIG = cx2.DICTAMEN_SEP_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECH_DICT_SEP_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECH_DICT_SEP_DIG = cx2.FECH_DICT_SEP_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if; 

                If cx2.DICTAMEN_SEP_ORIGINAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set DICTAMEN_SEP_ORIGINAL = cx2.DICTAMEN_SEP_ORIGINAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECH_DICTAMEN_SEP_ORI not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECH_DICTAMEN_SEP_ORI = cx2.FECH_DICTAMEN_SEP_ORI
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if; 
                    
                If cx2.FOTO_ESTUDIANTE_SOLICI_DIGITAL not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set FOTO_ESTUDIANTE_SOLICI_DIGITAL = cx2.FOTO_ESTUDIANTE_SOLICI_DIGITAL
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECHA_EST_SOL_DIG not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECHA_EST_SOL_DIG = cx2.FECHA_EST_SOL_DIG
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;      
                    
                If cx2.OFI_VALIDAC_ANTECED_ACAD_DI not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set OFI_VALIDAC_ANTECED_ACAD_DI = cx2.OFI_VALIDAC_ANTECED_ACAD_DI
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECH_OFI_VALIDAC_ANTECED_ACAD_DI not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECH_OFI_VALIDAC_ANTECED_ACAD_DI = cx2.FECH_OFI_VALIDAC_ANTECED_ACAD_DI
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;       
                    
                If cx2.OFI_VALIDAC_ANTECED_ACAD_FI not in ('NA') then  ---------****
                        Begin
                            Update recoleccion
                            set OFI_VALIDAC_ANTECED_ACAD_FI = cx2.OFI_VALIDAC_ANTECED_ACAD_FI
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;  

                    If cx2.FECH_OFI_VALIDAC_ANTECED_ACAD_FI not in ('1900/01/01') then  ---------****
                        Begin
                            Update recoleccion
                            set FECH_OFI_VALIDAC_ANTECED_ACAD_FI = cx2.FECH_OFI_VALIDAC_ANTECED_ACAD_FI
                            where  pidm = cx.pidm
                                And campus = cx.campus
                                And nivel = cx.nivel
                                ;
                        Exception
                            When Others then
                                null;
                        End;
                    End if;                                                     

                    End loop cx2;
                
                End;
        
        
        
        End loop;
        Commit;
  End;    
    

End p_recoleccion_new;

PROCEDURE p_egresados IS

 V_SALIDA VARCHAR(500);
  
  begin
  
    EXECUTE IMMEDIATE 'TRUNCATE TABLE SATURN.SZREGRESADOS';
    COMMIT;
    
    for cx1 in (
                SELECT  distinct
                               MATRICULA,
                               NOMBRE,
                               CORREO_PRINCIPAL,
                               pkg_utilerias.f_celular (fget_pidm(MATRICULA), 'CELU' )CELULAR,
                               PROGRAMA,
                               CAMPUS,
                               NIVEL,
                               TIPO_INGRESO,
                               CASE WHEN MONTO_ADEUDO<=0 THEN 'SIN ADEUDO'
                                   WHEN MONTO_ADEUDO>0 THEN 'CON ADEUDO'
                               END  ESTATUS_FINANCIERO,
                               MONTO_ADEUDO,
                               MONTO_INCOBRABLE,
                               MONTO_CONDONADO,
                               ESTATUS,
                               AVANCE_CURRICULAR,
                               HISTORIAL_ACADEMICO,
                               PAGO_APOSTILLA,
                               PAGO_CPA,
                               SERVICIO_SOCIAL,
                               CASE WHEN COLEGIATURA_FINAL='PAGADO' AND (TITULACION_CERO>=1 OR TITULACION_INCLUIDA>=1) THEN 'TITULACION_INCLUIDA'
                                   WHEN  COLEGIATURA_FINAL='PAGADO' AND (TITULACION_CERO=0 AND TITULACION_INCLUIDA=0) THEN 'PAGADO'
                                   ELSE 'SIN_PAGO'
                               END COLEGIATURA_FINAL,
                               ESTATUS_CPA,
                               ESTATUS_APOSTILLA,
                               CASE WHEN NUM_DOCS_CONTROL=NUM_DOCS_CONTROL_VALIDADO THEN 'COMPLETO'
                               ELSE 'INCOMPLETO'
                               END ESTATUS_DOCUMENTOS,
                               CERT_TOTAL_BACHI_DI,
                               CERT_TOTAL_LIC_DI,                            
                               CERT_TOTAL_MAE_DI,
                               CURP,
                               IDENTIFICACION_OF,
                               ENVIO_INTERNACIONAL,                             
                               CERTIFICADO_UTEL_LI,
                               CERTIFICADO_UTEL_MA,
                               CERTIFICADO_UTEL_DO,
                               TITULO_UTEL_LI,
                               TITULO_UTEL_MA,
                               TITULO_UTEL_DO,
                               ACUSE_DIGITAL,                          
                               NVL(substr(FOLIO_TD,2,6),'NA')FOLIO_TD,                       
                               case when PROCESO_TITULACION = 'VALIDADO' THEN 'TITULADO'
                                   WHEN PROCESO_CERTIFICADO = 'VALIDADO' THEN 'PROCESO DE CERTIFICADO'
                                   WHEN PROCESO_TITULACION != 'VALIDADO' AND PROCESO_CERTIFICADO != 'VALIDADO' THEN 'EGRESADO'
                                   END ESTATUS_TITULACION,                    
                              NVL((SELECT DISTINCT SFBETRM_RGRE_CODE FROM SFBETRM WHERE SFBETRM_RGRE_CODE='DA'  and SFBETRM_PIDM=fget_pidm(MATRICULA)),'NA')CODIGO_RAZON_DA,
                              NVL((select DISTINCT GORADID_ADID_CODE from goradid where GORADID_ADID_CODE='NOMR' and goradid_pidm=fget_pidm(MATRICULA) ),'NA')Etiqueta_NOMR,
                              NVL((SELECT DISTINCT SFBETRM_RGRE_CODE FROM SFBETRM WHERE SFBETRM_RGRE_CODE='FI'  and SFBETRM_PIDM=fget_pidm(MATRICULA)),'NA')CODIGO_RAZON_FI
                FROM(   
                          select distinct
                                           b.spriden_id matricula,                                           
                                           b.spriden_first_name||replace(b.spriden_last_name,'/',' ') Nombre,                                           
                                           pkg_utilerias.f_correo(a.pidm,'PRIN')Correo_principal,                                           
                                           a.PROGRAMA ||' | '|| a.NOMBRE   Programa,                                            
                                           a.campus campus,                                           
                                           a.nivel nivel,                                           
                                           a.tipo_ingreso_desc Tipo_ingreso,                                           
                                           '' Estatus_Financiero,                                           
                                           PKG_REPORTES_1.f_saldodia (a.pidm) Monto_adeudo,                                           
                                           (
                                               select sum(TBRACCD_AMOUNT) from tbraccd 
                                               join tbbdetc on TBBDETC_DETAIL_CODE=tbraccd_DETAIL_CODE
                                               where tbraccd_pidm=a.pidm and tbbdetc_dcat_code in ('INC')
                                           )Monto_Incobrable,
                                           (
                                               
                                               select sum(TBRACCD_AMOUNT) from tbraccd 
                                               join tbbdetc on TBBDETC_DETAIL_CODE=tbraccd_DETAIL_CODE
                                               where tbraccd_pidm=a.pidm and tbbdetc_dcat_code in ('CDN','CON')
                                           )Monto_Condonado,                                           
                                           a.estatus estatus,                                           
                                           SZTHITA_AVANCE avance_curricular,                                           
                                           SZTHITA_AVANCE Historial_academico, 
                                          case when substr(ap.tbraccd_detail_code,3,2) in ('VM','FX','Z0','Z9','VO','S5','VN','FY')  and ap.tbraccd_balance = 0 then 'PAGADO'
                                          ELSE 'PENDIENTE'
                                          END  pago_apostilla,                                          
                                          case when substr(cp.tbraccd_detail_code,3,2) in ('WC')  and cp.tbraccd_balance = 0 then 'PAGADO'
                                          ELSE 'PENDIENTE'
                                          END  pago_cpa,                                                             
                                          (SELECT  
                                               CASE WHEN  d.spriden_id=(SELECT distinct max (d.spriden_id)
                                                         FROM  spriden d, shrncrs s, sgrcoop op
                                                         WHERE d.spriden_pidm=d.spriden_pidm
                                                         AND d.spriden_pidm=s.shrncrs_pidm
                                                         AND d.spriden_pidm=op.sgrcoop_pidm
                                                         AND op.sgrcoop_empl_code is not null
                                                         AND op.sgrcoop_copc_code='SS'
                                                         AND sgrcoop_empl_contact_title is not null
                                                         AND s.shrncrs_ncrq_code='SS'
                                                         AND S.SHRNCRS_ACTIVITY_DATE >'01/01/0001'    
                                                         AND S.SHRNCRS_NCST_CODE='AP'
                                                         AND S.SHRNCRS_NCST_DATE>'01/01/0001'  
                                                         and d.spriden_pidm = a.pidm   
                                                         AND S.SHRNCRS_SEQ_NO=OP.SGRCOOP_SEQ_NO                                
                                                         and op.SGRCOOP_LEVL_CODE = a.nivel
                                                         and d.SPRIDEN_CHANGE_IND is null
                                                       )
                                                       THEN 'LIBERADO'
                                                         WHEN  d.spriden_id=(SELECT distinct MAX(d.spriden_id)
                                                         FROM  spriden d, shrncrs s, sgrcoop op
                                                         WHERE d.spriden_pidm=spriden_pidm
                                                         AND spriden_pidm=s.shrncrs_pidm
                                                         AND SPRIDEN_PIDM=OP.SGRCOOP_PIDM
                                                         AND OP.SGRCOOP_EMPL_CODE IS NOT NULL 
                                                         AND op.sgrcoop_copc_code='SS'
                                                         AND SGRCOOP_EMPL_CONTACT_TITLE IS NOT NULL
                                                         AND s.shrncrs_ncrq_code='SS'
                                                         AND S.SHRNCRS_ACTIVITY_DATE IS NOT NULL 
                                                         and d.spriden_pidm = a.pidm   
                                                         AND S.SHRNCRS_SEQ_NO=OP.SGRCOOP_SEQ_NO                                     
                                                         and op.SGRCOOP_LEVL_CODE = a.nivel
                                                         and d.SPRIDEN_CHANGE_IND is null
                                                       )   
                                                     THEN 'CONCLUIDO'
                                                         WHEN  d.spriden_id=(SELECT distinct MAX(spriden_id)
                                                         FROM  spriden , shrncrs s,sgrcoop op
                                                         WHERE d.spriden_pidm=spriden_pidm                                 
                                                           AND SPRIDEN_PIDM=OP.SGRCOOP_PIDM                                  
                                                           and d.spriden_pidm = a.pidm                                    
                                                           and op.SGRCOOP_LEVL_CODE = a.nivel
                                                           and d.SPRIDEN_CHANGE_IND is null
                                                       )
                                                         THEN 'EN PROCESO'
                                                   ELSE  'NO INICIADO'
                                                   END estatus_del_servicio_social
                                                   from spriden d
                                                   where 1=1
                                                   and D.SPRIDEN_PIDM=a.pidm
                                                 and d.SPRIDEN_CHANGE_IND is null
                                   )Servicio_social,
                                  case when substr(co.tbraccd_detail_code,3,2) in ('OR','HU','HH','TP','WV','TR','WT','WU','TQ','06','OT')  and co.tbraccd_balance = 0 then 'PAGADO'
                                       ELSE 'PENDIENTE'
                                    END  Colegiatura_Final,                                  
                                 (SELECT COUNT(GORADID_ADDITIONAL_ID )
                                     FROM GORADID
                                     WHERE GORADID_PIDM=A.PIDM
                                     AND GORADID_ADID_CODE='CFSC')TITULACION_CERO,
                                 (SELECT COUNT(GORADID_ADDITIONAL_ID )
                                       FROM GORADID
                                       WHERE GORADID_PIDM=A.PIDM
                                       AND GORADID_ADID_CODE='TIIN')TITULACION_INCLUIDA,
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('CEAD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')Estatus_CPA,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('APOS')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')Estatus_APOSTILLA,                                       
                                   NVL(( SELECT COUNT(*) FROM
                                   (
                                       select 
                                       regexp_substr(( select distinct ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID='DOCU_EGRE' AND ZSTPARA_PARAM_ID='DOCU' and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL||','||a.TIPO_INGRESO),'[^,]+', 1, level) VALORES_PARAM
                                       from dual
                                       connect by 
                                       regexp_substr(( select distinct ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID='DOCU_EGRE' AND ZSTPARA_PARAM_ID='DOCU' and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL||','||a.TIPO_INGRESO), '[^,]+', 1, level) is not null
                                       )),0)NUM_DOCS_CONTROL,                                   
                                   NVL(( SELECT COUNT(*) FROM
                                       SARCHKL
                                       where SARCHKL_ADMR_CODE in
                                       (
                                       select 
                                       regexp_substr(( select distinct ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID='DOCU_EGRE' AND ZSTPARA_PARAM_ID='DOCU' and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL||','||a.TIPO_INGRESO),'[^,]+', 1, level) VALORES_PARAM
                                       from dual
                                       connect by 
                                       regexp_substr(( select distinct ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID='DOCU_EGRE' AND ZSTPARA_PARAM_ID='DOCU' and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL||','||a.TIPO_INGRESO), '[^,]+', 1, level) is not null
                                       )
                                       and SARCHKL_CKST_CODE='VALIDADO'
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO),0)NUM_DOCS_CONTROL_VALIDADO,                                              
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('CTBD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERT_TOTAL_BACHI_DI,                                    
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('CTLD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERT_TOTAL_LIC_DI,                                        
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('CTMD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERT_TOTAL_MAE_DI,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('CURD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CURP,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('IDOD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')IDENTIFICACION_OF,                              
                                  case when substr(en.tbraccd_detail_code,3,2) in ('UA','UB','UC','UF','UD') and en.tbraccd_balance = 0 then 'PAGADO'
                                     ELSE 'SIN PAGO'
                                     END ENVIO_INTERNACIONAL,                                   
                                   NVL(( SELECT MAX(SARCHKL_CKST_CODE) FROM
                                       SARCHKL
                                       where SARCHKL_ADMR_CODE in
                                                               ( select DISTINCT(ZSTPARA_PARAM_VALOR)
                                                                 from zstpara 
                                                                 where ZSTPARA_MAPA_ID='DOCU_EGRE' 
                                                                    AND ZSTPARA_PARAM_ID='TIAU' 
                                                                    and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL                                       
                                                               )
                                       and SARCHKL_CKST_CODE='VALIDADO'
                                       and SARCHKL_PIDM =a.pidm
                                       and SARCHKL_APPL_NO = dD.SARADAP_APPL_NO),'NA') PROCESO_TITULACION,                                       
                                    NVL(( SELECT MAX(SARCHKL_CKST_CODE) FROM
                                       SARCHKL
                                       where SARCHKL_ADMR_CODE in
                                                               ( select DISTINCT(ZSTPARA_PARAM_VALOR)
                                                                 from zstpara 
                                                                 where ZSTPARA_MAPA_ID='DOCU_EGRE' 
                                                                    AND ZSTPARA_PARAM_ID='CERA' 
                                                                    and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL                                       
                                                               )
                                       and SARCHKL_CKST_CODE='VALIDADO'
                                       and SARCHKL_PIDM =a.pidm
                                       and SARCHKL_APPL_NO = dD.SARADAP_APPL_NO),'NA') PROCESO_CERTIFICADO,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('CETD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERTIFICADO_UTEL_LI,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('CMTD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERTIFICADO_UTEL_MA,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('CTDD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERTIFICADO_UTEL_DO,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('TITD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')TITULO_UTEL_LI,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('TIUD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')TITULO_UTEL_MA,                                   
                                   nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('TIMD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')TITULO_UTEL_DO,                                   
                                    nvl((select MAX( SARCHKL_CKST_CODE)
                                       from SARCHKL
                                       where SARCHKL_ADMR_CODE in ('ACUD')
                                       and SARCHKL_PIDM =a.pidm
                                       and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')ACUSE_DIGITAL,                                   
                                   (SELECT 
                                           dbms_lob.substr(SZTTIDI_CHAIN_DAT,8,6) 
                                       FROM SZTTIDI
                                       where  SZTTIDI_ID=a.MATRICULA
                                       AND    SZTTIDI_PROGRAM= a.programa
                                       and    SZTTIDI_ACTIVITY_DATE in (select max(sz.SZTTIDI_ACTIVITY_DATE)
                                                                        from SZTTIDI sz
                                                                        where
                                                                            sz.SZTTIDI_ID=a.MATRICULA
                                                                        AND
                                                                            sz.SZTTIDI_PROGRAM= a.programa)                                      
                                       ) Folio_TD--,                                          
                       from tztprog_all a
                       join spriden b on b.spriden_pidm=a.pidm and spriden_change_ind is null --and A.MATRICULA='280268246'-- AND A.MATRICULA='280268246'  --280250137
                       left join szthita c on a.pidm= c.SZTHITA_PIDM and a.programa = c.SZTHITA_PROG and a.sp = SZTHITA_STUDY 
                       left join tbraccd ap on    ap.tbraccd_pidm=a.pidm and ap.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                       and substr(ap.tbraccd_detail_code,3,2) in ('VM','FX','Z0','Z9','VO','87','S5','VN','FY')
                                       and ap.TBRACCD_STSP_KEY_SEQUENCE=a.sp
                                       and ap.TBRACCD_ENTRY_DATE=(  select max(tb.TBRACCD_ENTRY_DATE) from tbraccd tb
                                                                       where 
                                                                           tb.tbraccd_pidm=a.pidm 
                                                                       and tb.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                                                       and substr(tb.tbraccd_detail_code,3,2) in ('VM','FX','Z0','Z9','S5','VN','FY','VO','87')
                                                                    )
                       left join tbraccd cp on    cp.tbraccd_pidm=a.pidm and cp.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                       and substr(cp.tbraccd_detail_code,3,2) in ('WC','YE')
                                       and cp.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                       and cp.TBRACCD_ENTRY_DATE=(  select max(tb.TBRACCD_ENTRY_DATE) from tbraccd tb
                                                                       where 
                                                                           tb.tbraccd_pidm=a.pidm 
                                                                       and tb.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                                                       and substr(tb.tbraccd_detail_code,3,2) in ('WC','YE')
                                                                    )
                       left join tbraccd en on    en.tbraccd_pidm=a.pidm and en.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                       and substr(en.tbraccd_detail_code,3,2) in ('UA','UB','UC','UF','UD','PT')
                                       and en.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                       and en.TBRACCD_ENTRY_DATE=(  select max(tb.TBRACCD_ENTRY_DATE) from tbraccd tb
                                                                       where 
                                                                           tb.tbraccd_pidm=a.pidm 
                                                                       and tb.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                                                       and substr(tb.tbraccd_detail_code,3,2) in ('UA','UB','UC','UF','UD','PT')
                                                                    )                   
                       left join tbraccd co on  co.tbraccd_pidm=a.pidm and co.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                     and substr(co.tbraccd_detail_code,3,2) in ('OR','HU','HH','TP','WV','TR','WT','WU','TQ','06','OT','MY')
                                     and co.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                     and co.TBRACCD_ENTRY_DATE=(  select max(tb.TBRACCD_ENTRY_DATE) from tbraccd tb
                                                                     where 
                                                                         tb.tbraccd_pidm=a.pidm 
                                                                     and tb.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                                                     and substr(tb.tbraccd_detail_code,3,2) in ('OR','HU','HH','TP','WV','TR','WT','WU','TQ','06','OT','MY')
                                                                 )                                                                        
                       left join sztposs ss on     a.pidm = SS.SZTPOSS_PIDM and a.programa = SS.SZTPOSS_PROGRAM                                            
                       left join sgrcoop op on ( OP.sgrcoop_pidm = b.SPRIDEN_PIDM  
                                                AND OP.SGRCOOP_SEQ_NO   = ( select  max (op2.SGRCOOP_SEQ_NO)   FROM sgrcoop op2
                                                                           WHERE 1=1
                                                                           AND op2.sgrcoop_pidm= op.sgrcoop_pidm )) 
                       left join SHRNCRS sh on SH.SHRNCRS_PIDM =   b.SPRIDEN_PIDM    
                       LEFT JOIN svrsvpr   ON svrsvpr_pidm = a.pidm  and SVRSVPR_SRVC_CODE in ('COLF','COFU') 
                                           and SVRSVPR_ACTIVITY_DATE in
                                                   (select
                                                           max(sv.SVRSVPR_ACTIVITY_DATE) 
                                                           from SVRSVPR sv
                                                           where
                                                           sv.SVRSVPR_pidm=a.pidm
                                                           and SV.SVRSVPR_SRVC_CODE in ('COLF','COFU') 
                                                   )
                       LEFT  JOIN SARAPPD ss  ON  a.PIDM  = SS.SARAPPD_PIDM  
                       LEFT  JOIN SARADAP dd  ON  a.PIDM  = DD.SARADAP_PIDM  and a.CAMPUS=DD.SARADAP_CAMP_CODE and a.NIVEL=DD.SARADAP_LEVL_CODE 
                                             and sS.SARAPPD_APPL_NO = dD.SARADAP_APPL_NO   and dd.SARADAP_PROGRAM_1=a.programa
                                             AND dd.SARADAP_ACTIVITY_DATE in (select max(ddd.SARADAP_ACTIVITY_DATE)
                                                                               from saradap ddd
                                                                               where a.PIDM=DDd.SARADAP_PIDM
                                                                               and a.CAMPUS=DDd.SARADAP_CAMP_CODE and a.NIVEL=DDd.SARADAP_LEVL_CODE 
                                                                               and ddd.SARADAP_PROGRAM_1=a.programa
                                                                               and sS.SARAPPD_APPL_NO = dDd.SARADAP_APPL_NO 
                                                                                  ) 
                       where 
                       a.estatus='EG'
                       -- and a.pidm=145294
                       --AND A.PIDM=71196
                       and a.tipo_ingreso in ('RE','EQ','DT','RV')                       
                       and a.NIVEL   = DD.SARADAP_LEVL_CODE
                       and a.CAMPUS  = dd.SARADAP_CAMP_CODE  
                       --and a.ctlg   =  nvl(dd.SARADAP_TERM_CODE_CTLG_1,a.ctlg  )
                       and ss.SARAPPD_APDC_CODE = '35'
                       AND ss.sarappd_term_code_entry = dd.saradap_term_code_entry
                       and dd.SARADAP_APPL_NO in (select max(s.SARADAP_APPL_NO)
                                                                      from saradap s
                                                                         where dd.saradap_pidm=s.saradap_pidm
                                                                           and dd.saradap_program_1=s.saradap_program_1)
                       AND ss.SARAPPD_SEQ_NO = (SELECT MAX (SARAPPD_SEQ_NO)
                                                   FROM SARAPPD s, saradap d
                                                           WHERE 1=1
                                                           and S.SARAPPD_PIDM            = D.SARADAP_PIDM
                                                           and S.SARAPPD_TERM_CODE_ENTRY = D.SARADAP_TERM_CODE_ENTRY
                                                           and S.SARAPPD_APPL_NO         = D.SARADAP_APPL_NO
                                                           and ss.sarappd_pidm            = s.sarappd_pidm
                                                           and a.NIVEL                 = D.SARADAP_LEVL_CODE
                                                           and d.SARADAP_PROGRAM_1=a.programa
                                                           and SS.SARAPPD_ACTIVITY_DATE in ( select max(sp.SARAPPD_ACTIVITY_DATE)
                                                                                           from SARAPPD sp
                                                                                           where a.PIDM  = sp.SARAPPD_PIDM                                                              
                                                                                           and sS.SARAPPD_SEQ_NO = sp.SARAPPD_SEQ_NO   
                                                                                           and Sp.SARAPPD_APPL_NO  = D.SARADAP_APPL_NO
                                                                                           )
                                                           )     
                      --and A.CAMPUS in ($campus)
                      --AND A.NIVEL in ($nivel)
              --         AND A.MATRICULA='010000240'
   -------   
   UNION   
   -------
   select distinct
                       b.spriden_id matricula,                       
                       b.spriden_first_name||replace(b.spriden_last_name,'/',' ') Nombre,                       
                       pkg_utilerias.f_correo(a.pidm,'PRIN')Correo_principal,                       
                       a.PROGRAMA ||' | '|| a.NOMBRE   Programa,                        
                       a.campus campus,                       
                       a.nivel nivel,                       
                       a.tipo_ingreso_desc Tipo_ingreso,                       
                       '' Estatus_Financiero,                       
                       PKG_REPORTES_1.f_saldodia (a.pidm) Monto_adeudo,                       
                       (
                           select sum(TBRACCD_AMOUNT) from tbraccd 
                           join tbbdetc on TBBDETC_DETAIL_CODE=tbraccd_DETAIL_CODE
                           where tbraccd_pidm=a.pidm and tbbdetc_dcat_code in ('INC')
                       )Monto_Incobrable,
                       (                           
                           select sum(TBRACCD_AMOUNT) from tbraccd 
                           join tbbdetc on TBBDETC_DETAIL_CODE=tbraccd_DETAIL_CODE
                           where tbraccd_pidm=a.pidm and tbbdetc_dcat_code in ('CDN','CON')
                       )Monto_Condonado,                       
                       a.estatus estatus,                       
                       SZTHITA_AVANCE avance_curricular,                       
                       SZTHITA_AVANCE Historial_academico,                       
                      case when substr(ap.tbraccd_detail_code,3,2) in ('VM','FX','Z0','Z9','VO','S5','VN','FY')  and ap.tbraccd_balance = 0 then 'PAGADO'
                        ELSE 'PENDIENTE'
                      END  pago_apostilla,                      
                      case when substr(cp.tbraccd_detail_code,3,2) in ('WC')  and cp.tbraccd_balance = 0 then 'PAGADO'
                        ELSE 'PENDIENTE'
                      END  pago_cpa,                                         
                      (SELECT  
                           CASE WHEN  d.spriden_id=(SELECT distinct max (d.spriden_id)
                                     FROM  spriden d, shrncrs s, sgrcoop op
                                     WHERE d.spriden_pidm=d.spriden_pidm
                                     AND d.spriden_pidm=s.shrncrs_pidm
                                     AND d.spriden_pidm=op.sgrcoop_pidm
                                     AND op.sgrcoop_empl_code is not null
                                     AND op.sgrcoop_copc_code='SS'
                                     AND sgrcoop_empl_contact_title is not null
                                     AND s.shrncrs_ncrq_code='SS'
                                     AND S.SHRNCRS_ACTIVITY_DATE >'01/01/0001'    
                                     AND S.SHRNCRS_NCST_CODE='AP'
                                     AND S.SHRNCRS_NCST_DATE>'01/01/0001'  
                                     and d.spriden_pidm = a.pidm   
                                     AND S.SHRNCRS_SEQ_NO=OP.SGRCOOP_SEQ_NO                                
                                     and op.SGRCOOP_LEVL_CODE = a.nivel
                                     and d.SPRIDEN_CHANGE_IND is null
                                   )
                                   THEN 'LIBERADO'
                                     WHEN  d.spriden_id=(SELECT distinct MAX(d.spriden_id)
                                     FROM  spriden d, shrncrs s, sgrcoop op
                                     WHERE d.spriden_pidm=spriden_pidm
                                     AND spriden_pidm=s.shrncrs_pidm
                                     AND SPRIDEN_PIDM=OP.SGRCOOP_PIDM
                                     AND OP.SGRCOOP_EMPL_CODE IS NOT NULL 
                                     AND op.sgrcoop_copc_code='SS'
                                     AND SGRCOOP_EMPL_CONTACT_TITLE IS NOT NULL
                                     AND s.shrncrs_ncrq_code='SS'
                                     AND S.SHRNCRS_ACTIVITY_DATE IS NOT NULL 
                                     and d.spriden_pidm = a.pidm   
                                     AND S.SHRNCRS_SEQ_NO=OP.SGRCOOP_SEQ_NO                                     
                                     and op.SGRCOOP_LEVL_CODE = a.nivel
                                     and d.SPRIDEN_CHANGE_IND is null
                                   )   
                                 THEN 'CONCLUIDO'
                                     WHEN  d.spriden_id=(SELECT distinct MAX(spriden_id)
                                     FROM  spriden , shrncrs s,sgrcoop op
                                     WHERE d.spriden_pidm=spriden_pidm                                 
                                       AND SPRIDEN_PIDM=OP.SGRCOOP_PIDM                                  
                                       and d.spriden_pidm = a.pidm                                    
                                       and op.SGRCOOP_LEVL_CODE = a.nivel
                                       and d.SPRIDEN_CHANGE_IND is null
                                   )
                                     THEN 'EN PROCESO'
                               ELSE  'NO INICIADO'
                               END estatus_del_servicio_social
                               from spriden d
                               where 1=1
                               and D.SPRIDEN_PIDM=a.pidm
                             and d.SPRIDEN_CHANGE_IND is null
               )Servicio_social,
               case when substr(co.tbraccd_detail_code,3,2) in ('OR','HU','HH','TP','WV','TR','WT','WU','TQ','06','OT')  and co.tbraccd_balance = 0 then 'PAGADO'
                ELSE 'PENDIENTE'
               END  Colegiatura_Final,              
              (SELECT COUNT(GORADID_ADDITIONAL_ID )
                     FROM GORADID
                     WHERE GORADID_PIDM=A.PIDM
                     AND GORADID_ADID_CODE='CFSC')TITULACION_CERO,
              (SELECT COUNT(GORADID_ADDITIONAL_ID )
                   FROM GORADID
                   WHERE GORADID_PIDM=A.PIDM
                   AND GORADID_ADID_CODE='TIIN')TITULACION_INCLUIDA,     
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('CEAD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')Estatus_CPA,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('APOS')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')Estatus_APOSTILLA,
               NVL(( SELECT COUNT(*) FROM
                   (
                   select 
                   regexp_substr(( select distinct ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID='DOCU_EGRE' AND ZSTPARA_PARAM_ID='DOCU' and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL||','||a.TIPO_INGRESO),'[^,]+', 1, level) VALORES_PARAM
                   from dual
                   connect by 
                   regexp_substr(( select distinct ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID='DOCU_EGRE' AND ZSTPARA_PARAM_ID='DOCU' and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL||','||a.TIPO_INGRESO), '[^,]+', 1, level) is not null
                   )),0)NUM_DOCS_CONTROL,               
               NVL(( SELECT COUNT(*) FROM
                   SARCHKL
                   where SARCHKL_ADMR_CODE in
                   (
                   select 
                   regexp_substr(( select distinct ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID='DOCU_EGRE' AND ZSTPARA_PARAM_ID='DOCU' and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL||','||a.TIPO_INGRESO),'[^,]+', 1, level) VALORES_PARAM
                   from dual
                   connect by 
                   regexp_substr(( select distinct ZSTPARA_PARAM_VALOR from zstpara where ZSTPARA_MAPA_ID='DOCU_EGRE' AND ZSTPARA_PARAM_ID='DOCU' and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL||','||a.TIPO_INGRESO), '[^,]+', 1, level) is not null
                   )
                   and SARCHKL_CKST_CODE='VALIDADO'
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO),0)NUM_DOCS_CONTROL_VALIDADO,                      
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('CTBD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERT_TOTAL_BACHI_DI,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('CTLD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERT_TOTAL_LIC_DI,                    
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('CTMD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERT_TOTAL_MAE_DI,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('CURD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CURP,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('IDOD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')IDENTIFICACION_OF, 
               case when substr(en.tbraccd_detail_code,3,2) in ('UA','UB','UC','UF','UD') and en.tbraccd_balance = 0 then 'PAGADO'
                    ELSE 'SIN PAGO'
                 END ENVIO_INTERNACIONAL,               
               NVL(( SELECT MAX(SARCHKL_CKST_CODE) FROM
                   SARCHKL
                   where SARCHKL_ADMR_CODE in
                                           ( select DISTINCT(ZSTPARA_PARAM_VALOR)
                                             from zstpara 
                                             where ZSTPARA_MAPA_ID='DOCU_EGRE' 
                                                AND ZSTPARA_PARAM_ID='TIAU' 
                                                and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL                                       
                                           )
                   and SARCHKL_CKST_CODE='VALIDADO'
                   and SARCHKL_PIDM =a.pidm
                   and SARCHKL_APPL_NO = dD.SARADAP_APPL_NO),'NA') PROCESO_TITULACION,                   
                NVL(( SELECT MAX(SARCHKL_CKST_CODE) FROM
                   SARCHKL
                   where SARCHKL_ADMR_CODE in
                                           ( select DISTINCT(ZSTPARA_PARAM_VALOR)
                                             from zstpara 
                                             where ZSTPARA_MAPA_ID='DOCU_EGRE' 
                                                AND ZSTPARA_PARAM_ID='CERA' 
                                                and ZSTPARA_PARAM_DESC=a.CAMPUS||','||a.NIVEL                                       
                                           )
                   and SARCHKL_CKST_CODE='VALIDADO'
                   and SARCHKL_PIDM =a.pidm
                   and SARCHKL_APPL_NO = dD.SARADAP_APPL_NO),'NA') PROCESO_CERTIFICADO,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('CETD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERTIFICADO_UTEL_LI,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('CMTD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERTIFICADO_UTEL_MA,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('CTDD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')CERTIFICADO_UTEL_DO,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('TITD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')TITULO_UTEL_LI,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('TIUD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')TITULO_UTEL_MA,               
               nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('TIMD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')TITULO_UTEL_DO,               
                nvl((select MAX( SARCHKL_CKST_CODE)
                   from SARCHKL
                   where SARCHKL_ADMR_CODE in ('ACUD')
                   and SARCHKL_PIDM =a.pidm
                   and  SARCHKL_APPL_NO = dD.SARADAP_APPL_NO), 'NA')ACUSE_DIGITAL,               
               (SELECT 
                   dbms_lob.substr(SZTTIDI_CHAIN_DAT,8,6) 
                   FROM SZTTIDI
                   where   SZTTIDI_ID=a.MATRICULA
                   AND     SZTTIDI_PROGRAM= a.programa
                   and SZTTIDI_ACTIVITY_DATE in (select max(sz.SZTTIDI_ACTIVITY_DATE)
                                                  from SZTTIDI sz
                                                  where
                                                     sz.SZTTIDI_ID=a.MATRICULA
                                                  AND
                                                     sz.SZTTIDI_PROGRAM= a.programa)            
                   ) Folio_TD--,                   
   from tztprog_all a
   join spriden b on b.spriden_pidm=a.pidm and spriden_change_ind is null -- and A.MATRICULA='010010047'-- AND A.MATRICULA='280268246'  --280250137
   left join szthita c on a.pidm= c.SZTHITA_PIDM and a.programa = c.SZTHITA_PROG and a.sp = SZTHITA_STUDY 
   left join tbraccd ap on    ap.tbraccd_pidm=a.pidm and ap.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                   and substr(ap.tbraccd_detail_code,3,2) in ('VM','FX','Z0','Z9','VO','87','S5','VN','FY')
                   and ap.TBRACCD_STSP_KEY_SEQUENCE=a.sp
                   and ap.TBRACCD_ENTRY_DATE=(  select max(tb.TBRACCD_ENTRY_DATE) from tbraccd tb
                                                   where 
                                                       tb.tbraccd_pidm=a.pidm 
                                                   and tb.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                                   and substr(tb.tbraccd_detail_code,3,2) in ('VM','FX','Z0','Z9','S5','VN','FY','VO','87')
                                                )
   left join tbraccd cp on    cp.tbraccd_pidm=a.pidm and cp.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                   and substr(cp.tbraccd_detail_code,3,2) in ('WC','YE')
                   and cp.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                   and cp.TBRACCD_ENTRY_DATE=(  select max(tb.TBRACCD_ENTRY_DATE) from tbraccd tb
                                                   where 
                                                       tb.tbraccd_pidm=a.pidm 
                                                   and tb.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                                   and substr(tb.tbraccd_detail_code,3,2) in ('WC','YE')
                                                )
   left join tbraccd en on    en.tbraccd_pidm=a.pidm and en.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                   and substr(en.tbraccd_detail_code,3,2) in ('UA','UB','UC','UF','UD','PT')
                   and en.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                   and en.TBRACCD_ENTRY_DATE=(  select max(tb.TBRACCD_ENTRY_DATE) from tbraccd tb
                                                   where 
                                                       tb.tbraccd_pidm=a.pidm 
                                                   and tb.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                                   and substr(tb.tbraccd_detail_code,3,2) in ('UA','UB','UC','UF','UD','PT')
                                                )                   
   left join tbraccd co on  co.tbraccd_pidm=a.pidm and co.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                 and substr(co.tbraccd_detail_code,3,2) in ('OR','HU','HH','TP','WV','TR','WT','WU','TQ','06','OT','MY')
                 and co.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                 and co.TBRACCD_ENTRY_DATE=(  select max(tb.TBRACCD_ENTRY_DATE) from tbraccd tb
                                                 where 
                                                     tb.tbraccd_pidm=a.pidm 
                                                 and tb.TBRACCD_STSP_KEY_SEQUENCE=a.sp 
                                                 and substr(tb.tbraccd_detail_code,3,2) in ('OR','HU','HH','TP','WV','TR','WT','WU','TQ','06','OT','MY')
                                             )                                                                        
   left join sztposs ss on     a.pidm = SS.SZTPOSS_PIDM and a.programa = SS.SZTPOSS_PROGRAM                                            
   left join sgrcoop op on ( OP.sgrcoop_pidm = b.SPRIDEN_PIDM  
                            AND OP.SGRCOOP_SEQ_NO   = ( select  max (op2.SGRCOOP_SEQ_NO)   FROM sgrcoop op2
                                                       WHERE 1=1
                                                       AND op2.sgrcoop_pidm= op.sgrcoop_pidm )) 
   left join SHRNCRS sh on SH.SHRNCRS_PIDM =   b.SPRIDEN_PIDM    
   LEFT JOIN svrsvpr   ON svrsvpr_pidm = a.pidm  and SVRSVPR_SRVC_CODE in ('COLF','COFU') 
                       and SVRSVPR_ACTIVITY_DATE in
                               (select
                                       max(sv.SVRSVPR_ACTIVITY_DATE) 
                                       from SVRSVPR sv
                                       where
                                       sv.SVRSVPR_pidm=a.pidm
                                       and SV.SVRSVPR_SRVC_CODE in ('COLF','COFU') 
                               )
   LEFT  JOIN SARAPPD ss  ON  a.PIDM  = SS.SARAPPD_PIDM  
   LEFT  JOIN SARADAP dd  ON  a.PIDM  = DD.SARADAP_PIDM    and dd.SARADAP_PROGRAM_1 not in a.programa                                           
   where 
   a.estatus='EG'
   -- and a.pidm=145294
   --AND A.PIDM=71196
   and a.tipo_ingreso in ('RE','EQ','DT','RV')
   
   and a.NIVEL   = DD.SARADAP_LEVL_CODE
   and a.CAMPUS  = dd.SARADAP_CAMP_CODE  
   --and a.ctlg   =  nvl(dd.SARADAP_TERM_CODE_CTLG_1,a.ctlg  )
   and ss.SARAPPD_APDC_CODE = '35'
   AND ss.sarappd_term_code_entry = dd.saradap_term_code_entry
   AND ss.sarappd_appl_no = (SELECT MAX (ppl.sarappd_appl_no)
                                     FROM sarappd ppl
                                    WHERE ss.sarappd_pidm = ppl.sarappd_pidm And dd.SARADAP_APPL_NO = ppl.SARAPPD_APPL_NO
              ) 
 --  and A.CAMPUS in ($campus)
 -- AND A.NIVEL in ($nivel)
  -- AND A.MATRICULA='010000240'
  )   
   WHERE 1=1                           
                 ) loop

                          Begin
                                    Insert into SATURN.SZREGRESADOS
                                    (
                                        MATRICULA,
                                        NOMBRE,
                                        CORREO_ELECTRONICO,
                                        CELULAR,
                                        PROGRAMA,
                                        CAMPUS,
                                        NIVEL,
                                        TIPO_INGRESO,
                                        ESTATUS_FINANCIERO,
                                        MONTO_ADEUDO,
                                        MONTO_INCOBRABLE,
                                        MONTO_CONDONADO,
                                        ESTATUS,
                                        AVANCE_CURRICULAR,
                                        HISTORIAL_ACADEMICO,
                                        PAGO_APOSTILLA,
                                        PAGO_CPA,
                                        SERVICIO_SOCIAL,
                                        COLEGIATURA_FINAL,
                                        ESTATUS_CPA,
                                        ESTATUS_APOSTILLA,
                                        ESTATUS_DOCUMENTOS,
                                        CERT_TOTAL_BACHI_DI,
                                        CERT_TOTAL_LIC_DI,
                                        CERT_TOTAL_MAE_DI,
                                        CURP,
                                        IDENTIFICACION_OF,
                                        ENVIO_INTERNACIONAL,
                                        CERTIFICADO_UTEL_LI,
                                        CERTIFICADO_UTEL_MA,
                                        CERTIFICADO_UTEL_DO,
                                        TITULO_UTEL_LI,
                                        TITULO_UTEL_MA,
                                        TITULO_UTEL_DO,
                                        ACUSE_DIGITAL,
                                        FOLIO_TD,
                                        ESTATUS_TITULACION,
                                        CODIGO_RAZON_DA,
                                        ETIQUETA_NOMR,
                                        CODIGO_RAZON_FI,
                                        FECHA_INSERT                                    
                                    )
                                    values
                                    (  
                                        CX1.MATRICULA,
                                        CX1.NOMBRE,
                                        CX1.CORREO_PRINCIPAL,
                                        CX1.CELULAR,
                                        CX1.PROGRAMA,
                                        CX1.CAMPUS,
                                        CX1.NIVEL,
                                        CX1.TIPO_INGRESO,
                                        CX1.ESTATUS_FINANCIERO,
                                        CX1.MONTO_ADEUDO,
                                        CX1.MONTO_INCOBRABLE,
                                        CX1.MONTO_CONDONADO,
                                        CX1.ESTATUS,
                                        CX1.AVANCE_CURRICULAR,
                                        CX1.HISTORIAL_ACADEMICO,
                                        CX1.PAGO_APOSTILLA,
                                        CX1.PAGO_CPA,
                                        CX1.SERVICIO_SOCIAL,
                                        CX1.COLEGIATURA_FINAL,
                                        CX1.ESTATUS_CPA,
                                        CX1.ESTATUS_APOSTILLA,
                                        CX1.ESTATUS_DOCUMENTOS,
                                        CX1.CERT_TOTAL_BACHI_DI,
                                        CX1.CERT_TOTAL_LIC_DI,
                                        CX1.CERT_TOTAL_MAE_DI,
                                        CX1.CURP,
                                        CX1.IDENTIFICACION_OF,
                                        CX1.ENVIO_INTERNACIONAL,
                                        CX1.CERTIFICADO_UTEL_LI,
                                        CX1.CERTIFICADO_UTEL_MA,
                                        CX1.CERTIFICADO_UTEL_DO,
                                        CX1.TITULO_UTEL_LI,
                                        CX1.TITULO_UTEL_MA,
                                        CX1.TITULO_UTEL_DO,
                                        CX1.ACUSE_DIGITAL,
                                        CX1.FOLIO_TD,
                                        CX1.ESTATUS_TITULACION,
                                        CX1.CODIGO_RAZON_DA,
                                        CX1.ETIQUETA_NOMR,
                                        CX1.CODIGO_RAZON_FI,
                                        TRUNC(SYSDATE) 
                                    )
                                    ;
                         -- Exception
                        --    When Others then
                       --         null;
                          End;
                            
                End Loop cx1;      
                COMMIT;
                 
--  END;  
END p_egresados;


END PKG_REPORTES;
/

DROP PUBLIC SYNONYM PKG_REPORTES;

CREATE OR REPLACE PUBLIC SYNONYM PKG_REPORTES FOR BANINST1.PKG_REPORTES;
