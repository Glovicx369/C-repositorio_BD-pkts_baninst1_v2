DROP PACKAGE BODY BANINST1.PKG_SWTMDAC;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_SWTMDAC" is 
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 -- Author : glovicx
 -- Created : 02.Nov.2015
 -- Purpose : Pkt con las Utilerias para la administracion del
 ----- Modulo Descuentos Accesorios
 ----se hizo el cambio para sp_aplica_descuento_PV  que inserte el descuento en la tabla de paso
 -- se agrega la funcion para descuentos masivos  dia 12/05/2020  glovicx
---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
cursor c_valida_desc ( p_pidm number, p_detail_code varchar2 , effectiv_date date ) is
select distinct nvl(SWTMDAC_SEC_PIDM,0) , SWTMDAC_PERCENT_DESC, SWTMDAC_AMOUNT_DESC, SWTMDAC_DETAIL_CODE_ACC,SWTMDAC_NUM_REAPPLICATION,SWTMDAC_APPLICATION_INDICATOR
from SWTMDAC ws
where SWTMDAC_pidm = p_pidm
and SWTMDAC_DETAIL_CODE_ACC = p_detail_code
and SWTMDAC_MASTER_IND = 'Y'
and to_char(trunc(effectiv_date))  between trunc(SWTMDAC_EFFECTIVE_DATE_INI) and trunc(nvl(SWTMDAC_EFFECTIVE_DATE_FIN, SWTMDAC_EFFECTIVE_DATE_INI))
and ws.SWTMDAC_NUM_REAPPLICATION > SWTMDAC_APPLICATION_INDICATOR
AND ws.SWTMDAC_SEQNO_SERV is null
and ws.SWTMDAC_SEC_PIDM   = (select min(SWTMDAC_SEC_PIDM)  from SWTMDAC ww where ww.SWTMDAC_pidm =  ws.SWTMDAC_pidm
                                                and ww.SWTMDAC_DETAIL_CODE_ACC = ws.SWTMDAC_DETAIL_CODE_ACC 
                                                and ww.SWTMDAC_MASTER_IND = 'Y'
                                                and to_char(trunc(effectiv_date))  between trunc(SWTMDAC_EFFECTIVE_DATE_INI) and trunc(nvl(SWTMDAC_EFFECTIVE_DATE_FIN, SWTMDAC_EFFECTIVE_DATE_INI))
                                                and ww.SWTMDAC_NUM_REAPPLICATION > ww.SWTMDAC_APPLICATION_INDICATOR
                                                AND  ww.SWTMDAC_SEQNO_SERV is null ) ;



vs_regreso number:=0;

function f_valida (p_pidm number , p_detail_code varchar2, effectiv_date date) return varchar2
is
/*
f_verifica_descuento( pidm , detail_code, effective_date )
El sistema debe buscar en la tabla de descuentos, si existe un descuento para:
? El alumno ( Pidm )
? El Código de Detalle ( detail_code )
? Que este activo
? Que el intervalo de fechas sea nulo o la transacción este dentro de este intervalo: (effective_date dentro del intervalos de fechas )
? Que no este aplicado ( indicador de Aplicación menor que el No-de-reaplicaciones definido en la regla)

 Si se encuentra un descuento se retorna el No de Descuento.
 Si no se encuentra se retorna Cero.
*/

vs_null number:=0;
vs_null1 varchar2(30);
vs_null2 varchar2(30);
vs_null3 varchar2(30);
vl_error varchar2(2500);

begin
--
--select nvl(SWTMDAC_SEC_PIDM,0) into vs_regreso
--from SWTMDAC
--where SWTMDAC_pidm = p_pidm
--and SWTMDAC_DETAIL_CODE_ACC = p_detail_code
--and SWTMDAC_MASTER_IND = 'Y'
--and trunc(effectiv_date) between trunc(SWTMDAC_EFFECTIVE_DATE_INI) and trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
--and SWTMDAC_APPLICATION_INDICATOR <= SWTMDAC_NUM_REAPPLICATION;
vs_regreso :=0;
open c_valida_desc(p_pidm,p_detail_code,effectiv_date ) ;
fetch c_valida_desc into vs_regreso, vs_null,vs_null,vs_null1,vs_null2,vs_null3 ;-----las varibles vs_null en este momento no me importa manejarlas pero son necesp_sarias bajarlas
close c_valida_desc;


------aqui la logica de comparacion es diferente al cursor por que espero que no se cumpla para ponerle var = 0
--IF vs_null2 <= vs_null3 THEN
--vs_regreso := 0;
--END IF;
--dbms_output.put_line ( ' regresa valor funcion ' ||vs_regreso);

return vs_regreso ;

Return vl_error;
exception 
when others then
    vl_error :='Error PKG_SWTMDAC.f_valida '||sqlerrm; --modificado de  vs_regreso:=0
    Return vl_error;
--INSERT INTO TWPASO VALUES ('ERROR FUNCION SWTMDAC', SYSDATE, NULL, vs_regreso); COMMIT;
end f_valida;



--procedure sp_aplica_descuento (p_pidm number, p_num_desc number, p_num_tran number, p_detail_code varchar2, p_monto number, p_term_code varchar2 , p_detalle_desc varchar2 ) is
--/*
--Registrar el Crédito insertando el registro en la tabla TBRACCD (vic)
-- ( Usar API tb_receivable.p_create )
-- -PIDM
-- -Código de Detalle de Descuento (de la regla)
-- -Fecha Efectiva igual a la fecha_efectiva
-- - TBRACCD_SRCE_CODE con valor ‘W’ ( nuevo valor en TTVSRCE )
-- -Referencia para aplicar el pago
-- -TBRACCD_TRAN_NUMBER_PAID igual a No_de_transaccion del cargo orig
-- -Referencias cruzadas:
-- -TBRACCD_CROSSREF_NUMBER indicar el No_consecutivo_de_Descuento
-- - Monto del descuento (preguntar a David el parámetro y demás que se requieran)
--Parámetros de entrada:
-- -alumno ( pidm )
-- -No_de_descuento
-- -No_de_transaccion del cargo original
-- -Código_de_detalle del cargo original
-- -Monto_del_Cargo
-- -Fecha_Efectiva
--
--CRAETED VIC..
--
--LAST MODIFY: 02 -NOV- 2015
--*/
--
--p_detail_desc varchar2(100);
--p_detail_co varchar2(6);
--
--
--p_num_tran_MAX NUMBER:=0;
--v_moneda      varchar2(5);
--begin
----dbms_output.put_line ( ' Aplica descuento  num tran del parametro  ' ||p_num_tran);
----p_detail_desc := 'codigo de descuento' ;
--
--
------este max sirve en todos loscasos pero en especial cuando ejecutas el lanza_insert por que ahilo tengo que calcular
--SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0)+ 1  N_TRAN
--INTO p_num_tran_MAX
--FROM TBRACCD
--WHERE TBRACCD_PIDM = p_pidm;
----;
-----------------------VOY A CALCULAR LA MONEDA QUE TIENE EL DESCUENTO --------
--SELECT TVRDCTX_CURR_CODE
--INTO v_moneda
--FROM TAISMGR.TVRDCTX
--WHERE TVRDCTX_DETC_CODE  = p_detail_code;
--
--IF  v_moneda  IS NULL  THEN
--v_moneda  := 'MXN';
--END IF;
--
--
--select  nvl(SWTMDAC_DETAIL_CODE_DESC,'DESC')     INTO  p_detail_co
--from SWTMDAC
--where SWTMDAC_PIDM  = p_pidm
--and  SWTMDAC_DETAIL_CODE_ACC  = p_detail_code
--and  SWTMDAC_SEC_PIDM   = p_num_desc;
--
--if p_detail_co  is null then
--p_detail_co  := 'DESC';
--end if;
--
--
--/* SE AGREGO PARA OBTENER CODIGO DE DETALLE DE DESCUENTO DEL CODIGO DE DETALLE DE PRODUCTO*/
----select pkg_swtmdac.f_obten_codigo_descuento(p_detail_code) 
----into p_detail_co
----from dual;
--
--SELECT TBBDETC_DESC INTO p_detail_desc FROM TAISMGR.TBBDETC WHERE TBBDETC_DETAIL_CODE = p_detail_co;
--
--
---- dbms_output.put_line ( ' calcula el maxico del pidm ' || p_num_tran_MAX);
--------se hace el insert en el edocta estos son tipo pago por que son descuentos que se hacen a los accesorios de comprados por un alumno por eso los montos van en negativo esto fue checado con David torres.--
--if p_num_tran_MAX = p_num_tran then
--p_num_tran_MAX := p_num_tran_MAX+1;
--
--end if;
----
----dbms_output.put_line ( ' variables de inserta  MAX  y param >>  ' || p_num_tran_MAX || '    NUM_TRAN_PARAM   ' ||  p_num_tran );
-- INSERT INTO TBRACCD 
-- (TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_USER, TBRACCD_ENTRY_DATE, TBRACCD_AMOUNT, TBRACCD_BALANCE,TBRACCD_EFFECTIVE_DATE, TBRACCD_DESC, 
--TBRACCD_ACTIVITY_DATE, TBRACCD_TRANS_DATE, TBRACCD_DATA_ORIGIN, TBRACCD_CREATE_SOURCE,TBRACCD_SRCE_CODE , TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER,TBRACCD_CROSSREF_NUMBER, TBRACCD_CURR_CODE )
-- --TBRACCD_ACTIVITY_DATE, TBRACCD_TRANS_DATE, TBRACCD_DATA_ORIGIN, TBRACCD_CREATE_SOURCE,TBRACCD_SRCE_CODE , TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER,TBRACCD_CROSSREF_NUMBER, TBRACCD_CURR_CODE )
-- VALUES 
-- (p_pidm, p_num_tran_max, p_term_code, p_detail_co, 'SistemaV2', SYSDATE, p_monto, (p_monto)*-1 , sysdate, p_detail_desc, sysdate, sysdate, 'BANNER','MDAC', 'T' , 'Y',0 ,p_num_desc, v_moneda );
--
---- (p_pidm, p_num_tran_max, p_term_code, p_detail_co, USER, SYSDATE, p_monto, (p_monto)*-1 , sysdate, p_detail_desc, sysdate, sysdate, 'BANNER','MDAC', 'W' , 'Y',0 ,p_num_tran,p_num_desc, v_moneda );
----- INSERT DE PRUEBA SOBRE OTRA TABLA
----INSERT INTO TWPASO
----VALUES( 'TRIGGER -TBRA ', p_pidm, p_num_tran, p_detail_code);
--
--
-----dbms_output.put_line ( ' actualiza  la tabla swtmdac  >>  ' || p_pidm || '  detalle  ' ||p_detail_code || '  secuencia  '||p_num_desc); 
--UPDATE  saturn.SWTMDAC
--SET SWTMDAC_APPLICATION_INDICATOR = SWTMDAC_APPLICATION_INDICATOR +1
-- , SWTMDAC_APPLICATION_DATE = SYSDATE
-- ,SWTMDAC_FLAG = NULL
-- WHERE SWTMDAC_pidm = p_pidm
--and SWTMDAC_DETAIL_CODE_ACC = p_detail_code
--and SWTMDAC_SEC_PIDM = p_num_desc;
--
--
-------- Se direcciona el pago del descuento  -------
--
--  update tbraccd
--  set TBRACCD_TRAN_NUMBER_PAID = p_num_tran_max
--  Where tbraccd_pidm = p_pidm
--  And TBRACCD_TRAN_NUMBER = p_num_tran;
--
----COMMIT;
--
--end sp_aplica_descuento;


--SE GENRA LA FUNCI? PARA PODER CACHAR EL ERROR--

--FUNCTION sp_aplica_descuento (p_pidm number, p_num_desc number, p_num_tran number, p_detail_code varchar2, p_monto number, p_term_code varchar2 , p_detalle_desc varchar2 )Return varchar2 
--is
--/*
--Registrar el Crédito insertando el registro en la tabla TBRACCD (vic)
-- ( Usar API tb_receivable.p_create )
-- -PIDM
-- -Código de Detalle de Descuento (de la regla)
-- -Fecha Efectiva igual a la fecha_efectiva
-- - TBRACCD_SRCE_CODE con valor ‘W’ ( nuevo valor en TTVSRCE )
-- -Referencia para aplicar el pago
-- -TBRACCD_TRAN_NUMBER_PAID igual a No_de_transaccion del cargo orig
-- -Referencias cruzadas:
-- -TBRACCD_CROSSREF_NUMBER indicar el No_consecutivo_de_Descuento
-- - Monto del descuento (preguntar a David el parámetro y demás que se requieran)
--Parámetros de entrada:
-- -alumno ( pidm )
-- -No_de_descuento
-- -No_de_transaccion del cargo original
-- -Código_de_detalle del cargo original
-- -Monto_del_Cargo
-- -Fecha_Efectiva
--
--CRAETED VIC..
--
--LAST MODIFY: 02 -NOV- 2015
--*/
--
--p_detail_desc varchar2(100);
--p_detail_co varchar2(6);
--p_num_tran_MAX NUMBER:=0;
--v_moneda      varchar2(5);
--vl_error  varchar2(2500):=null;
--begin
----dbms_output.put_line ( ' Aplica descuento  num tran del parametro  ' ||p_num_tran);
----p_detail_desc := 'codigo de descuento' ;
--
--
------este max sirve en todos loscasos pero en especial cuando ejecutas el lanza_insert por que ahilo tengo que calcular
--SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0)+ 1  N_TRAN
--INTO p_num_tran_MAX
--FROM TBRACCD
--WHERE TBRACCD_PIDM = p_pidm;
----;
-----------------------VOY A CALCULAR LA MONEDA QUE TIENE EL DESCUENTO --------
--SELECT TVRDCTX_CURR_CODE
--INTO v_moneda
--FROM TAISMGR.TVRDCTX
--WHERE TVRDCTX_DETC_CODE  = p_detail_code;
--
--IF  v_moneda  IS NULL  THEN
--v_moneda  := 'MXN';
--END IF;
--
--
--select  nvl(SWTMDAC_DETAIL_CODE_DESC,'DESC')     INTO  p_detail_co
--from SWTMDAC
--where SWTMDAC_PIDM  = p_pidm
--and  SWTMDAC_DETAIL_CODE_ACC  = p_detail_code
--and  SWTMDAC_SEC_PIDM   = p_num_desc;
--
--if p_detail_co  is null then
--p_detail_co  := 'DESC';
--end if;
--
--
--/* SE AGREGO PARA OBTENER CODIGO DE DETALLE DE DESCUENTO DEL CODIGO DE DETALLE DE PRODUCTO*/
----select pkg_swtmdac.f_obten_codigo_descuento(p_detail_code) 
----into p_detail_co
----from dual;
--
--SELECT TBBDETC_DESC INTO p_detail_desc FROM TAISMGR.TBBDETC WHERE TBBDETC_DETAIL_CODE = p_detail_co;
--
--
----dbms_output.put_line ( ' calcula el maxico del pidm ' || p_num_tran_MAX);
--------se hace el insert en el edocta estos son tipo pago por que son descuentos que se hacen a los accesorios de comprados por un alumno por eso los montos van en negativo esto fue checado con David torres.--
--if p_num_tran_MAX = p_num_tran then
--p_num_tran_MAX := p_num_tran_MAX+1;
--
--end if;
----
----dbms_output.put_line ( ' variables de inserta  MAX  y param >>  ' || p_num_tran_MAX || '    NUM_TRAN_PARAM   ' ||  p_num_tran );
-- INSERT INTO TBRACCD 
-- (TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_USER, TBRACCD_ENTRY_DATE, TBRACCD_AMOUNT, TBRACCD_BALANCE,TBRACCD_EFFECTIVE_DATE, TBRACCD_DESC, 
--TBRACCD_ACTIVITY_DATE, TBRACCD_TRANS_DATE, TBRACCD_DATA_ORIGIN, TBRACCD_CREATE_SOURCE,TBRACCD_SRCE_CODE , TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER,TBRACCD_CROSSREF_NUMBER, TBRACCD_CURR_CODE )
-- --TBRACCD_ACTIVITY_DATE, TBRACCD_TRANS_DATE, TBRACCD_DATA_ORIGIN, TBRACCD_CREATE_SOURCE,TBRACCD_SRCE_CODE , TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER,TBRACCD_CROSSREF_NUMBER, TBRACCD_CURR_CODE )
-- VALUES 
-- (p_pidm, p_num_tran_max, p_term_code, p_detail_co, 'SistemaV2', SYSDATE, p_monto, (p_monto)*-1 , sysdate, p_detail_desc, sysdate, sysdate, 'BANNER','MDAC', 'T' , 'Y',0 ,p_num_desc, v_moneda );
--
---- (p_pidm, p_num_tran_max, p_term_code, p_detail_co, USER, SYSDATE, p_monto, (p_monto)*-1 , sysdate, p_detail_desc, sysdate, sysdate, 'BANNER','MDAC', 'W' , 'Y',0 ,p_num_tran,p_num_desc, v_moneda );
----- INSERT DE PRUEBA SOBRE OTRA TABLA
----INSERT INTO TWPASO
----VALUES( 'TRIGGER -TBRA ', p_pidm, p_num_tran, p_detail_code);
--
--
-----dbms_output.put_line ( ' actualiza  la tabla swtmdac  >>  ' || p_pidm || '  detalle  ' ||p_detail_code || '  secuencia  '||p_num_desc); 
--UPDATE  saturn.SWTMDAC
--SET SWTMDAC_APPLICATION_INDICATOR = SWTMDAC_APPLICATION_INDICATOR +1
-- , SWTMDAC_APPLICATION_DATE = SYSDATE
-- ,SWTMDAC_FLAG = NULL
-- WHERE SWTMDAC_pidm = p_pidm
--and SWTMDAC_DETAIL_CODE_ACC = p_detail_code
--and SWTMDAC_SEC_PIDM = p_num_desc;
--
--
-------- Se direcciona el pago del descuento  -------
--
--  update tbraccd
--  set TBRACCD_TRAN_NUMBER_PAID = p_num_tran_max
--  Where tbraccd_pidm = p_pidm
--  And TBRACCD_TRAN_NUMBER = p_num_tran;
--
----COMMIT;
--
--Return vl_error;
--Exception when others then
--    vl_error:='Error PKG_SWTMDAC.sp_aplica_descuento' ||sqlerrm;
--    Return vl_error;
--
--end sp_aplica_descuento;



FUNCTION sp_lanza_descuento(p_pidm number, p_num_desc number, p_porcentaje number default null, p_detail_code varchar2, p_monto number default null, p_term_code varchar2 , p_detalle_desc varchar2 ) Return Varchar2 
is
/*
autor glovicx..
fecha 06_nov_2015
este proceso se encarga de insertar un registro tipo descuento en la tabla de tbraccd este caso es cuando el trigger no lo pudo hacer de forma automatica 
por que no existia cuando se ejecuto el trigger.
busca cual es el ultimo cargo insertado en tbraccd y si no tiene su respectivo descuento en caso que no este entonces lo inserta


*/


vn_tran              number:=0;
vn_monto         number:=0;
v_calculo           number:=0;
vv_porcet           number:=0;
lv_periodo          varchar2(15);
vl_error            varchar2(2500):=null;  
p_exito varchar2(100);
begin


select tr.ntran, tbraccd_amount monto ,dd.TBRACCD_TERM_CODE  
iNTO vn_tran, vn_monto, lv_periodo
 from (
select min(TBRACCD_TRAN_NUMBER) as ntran
from tbraccd TT
where TBRACCD_PIDM = p_pidm 
--and TBRACCD_TERM_CODE = p_term_code
and TBRACCD_DETAIL_CODE = p_detail_code
and TBRACCD_SRCE_CODE <> 'W'
and TBRACCD_TRAN_NUMBER NOT IN ( SELECT TBRACCD_TRAN_NUMBER_PAID 
                                                         FROM TBRACCD CC 
                                                         WHERE CC.TBRACCD_PIDM = p_pidm
                                                         AND TBRACCD_SRCE_CODE = 'W' ) ) tr, tbraccd dd
 where tr. ntran = dd.TBRACCD_TRAN_NUMBER 
 and TBRACCD_PIDM = p_pidm 
--and TBRACCD_TERM_CODE = p_term_code
and TBRACCD_DETAIL_CODE = p_detail_code
and TBRACCD_SRCE_CODE <> 'W' ;

--dbms_output.put_line ( ' lanza DESCUENTOS   ' || vn_tran ||'--'|| vn_monto );


IF vn_tran > 0 then 


------ calcula el monto a descontar si es porcentaje o monto fijo 
 IF p_porcentaje > 0 THEN
 vv_porcet := (p_porcentaje/100);
 
 v_calculo := vn_monto * vv_porcet ;

 
 else 
 ---v_calculo := :new.tbraccd_amount - v_amount;

 v_calculo := p_monto;

 end if;
--dbms_output.put_line ( ' ejecuta aplica_descUENTOS  ' || v_calculo ||'--'|| vn_monto );

 BANINST1.pkg_swtmdac.sp_aplica_descuento (p_pidm , p_num_desc , vn_tran , p_detail_code , v_calculo , lv_periodo , p_detalle_desc, null, p_exito );

commit;
end if;

Return vl_error;

Exception when others then
 vl_error:='Error pkg_swtmdac.sp_lanza_descuento '||sqlerrm;
 Return vl_error;
end sp_lanza_descuento;

FUNCTION sp_crea_desc(p_pidm number, p_mind varchar2, p_detcode_acc varchar2, p_percent number DEFAULT NULL, p_amount number DEFAULT NULL, p_detcode_desc varchar2,p_date_ini date, p_date_fin date, p_replica number, p_user varchar2, p_usr_rol varchar2 ) Return Varchar2 
is
/*
este proceso se encarga de insertar en la tabla de administracion de descuentos llamada SWTMDAC el descuento pertinente solicitado por un alumno
este proceso solo ingresa la informacion requerida y la administracion se lleva acabo en V2. SIU Solicitud de Ingreso

*/
vnum_max number:=0;
vdesc   varchar2(4);
VL_FECHA_INI DATE;
vl_error varchar2(2500):= 'EXITO';
vseq_no     number:=0;


BEGIN
-- se inicializa la variable a ceros 
vnum_max := 0;

begin
select nvl(max(SWTMDAC_SEC_PIDM),0) 
into vnum_max
from SWTMDAC
where SWTMDAC_PIDM = p_pidm;

exception when others then
vnum_max := 0;
end;

--EL CODIGO DE DETALLE YA ES ENVIADO DESDE  EL SISTEMA--
 Begin 
            select pkg_swtmdac.f_obten_codigo_descuento(p_detcode_acc) 
            Into vdesc
            from dual;
            
 Exception
 When Others then 
 vdesc:=null;
 End;

-----valida que no se guarden 2 veces el mismo secno--- glovicx 02/07/2020

        begin
              select count(1)
                 into vseq_no
               from SWTMDAC w
               where w.SWTMDAC_PIDM = p_pidm
                and W.SWTMDAC_SEQNO_SERV  = vnum_max;
                
         Exception   When Others then 
         vseq_no:=null;
         End;

    if vseq_no > 0 then 
    vnum_max := vnum_max + 1;
    end if;

  IF TRIM(p_user) = 'sistema' THEN  
  
  
  
        BEGIN
                SELECT SORLCUR_START_DATE+15
                INTO VL_FECHA_INI
                from SORLCUR a,SARADAP 
                where a.SORLCUR_LMOD_CODE = 'ADMISSIONS'
                and a.SORLCUR_ROLL_IND  = 'N'
                And a.SORLCUR_SEQNO = (select max (a1.SORLCUR_SEQNO)
                                                         from SORLCUR a1
                                                         Where a1.sorlcur_pidm = a.sorlcur_pidm
                                                         And a1.SORLCUR_LMOD_CODE = a.SORLCUR_LMOD_CODE
                                                         AND a1.SORLCUR_ROLL_IND = a.SORLCUR_ROLL_IND)
                AND SARADAP_PIDM = a.SORLCUR_PIDM  
                and SARADAP_APPL_NO = a.SORLCUR_KEY_SEQNO
                and SARADAP_PIDM = p_pidm;
        EXCEPTION
        WHEN OTHERS THEN        
        VL_FECHA_INI:= p_date_fin+100;       
        END;
  
  
    
    
       INSERT INTO SWTMDAC
                (SWTMDAC_PIDM,
                SWTMDAC_SEC_PIDM,
                SWTMDAC_MASTER_IND,
                SWTMDAC_DETAIL_CODE_ACC,
                SWTMDAC_PERCENT_DESC,
                SWTMDAC_AMOUNT_DESC,
                SWTMDAC_DETAIL_CODE_DESC,
                SWTMDAC_EFFECTIVE_DATE_INI,
                SWTMDAC_EFFECTIVE_DATE_FIN,
                SWTMDAC_NUM_REAPPLICATION,
                SWTMDAC_USER,
                SWTMDAC_USR_ROLE,
                SWTMDAC_ACTIVITY_DATE,
                SWTMDAC_APPLICATION_INDICATOR,
                SWTMDAC_APPLICATION_DATE,
                SWTMDAC_FLAG
                --,SWTMDAC_SEQNO_SERV
                 )
         VALUES(p_pidm ,
                vnum_max+1, 
                p_mind , 
                p_detcode_acc , 
                p_percent , 
                p_amount , 
                p_detcode_desc ,
                p_date_ini , 
                VL_FECHA_INI , 
                p_replica , 
                p_user , 
                p_usr_rol, 
                sysdate, 
                0,
                null, 
                'Y'
                --,PNOSEQ 
                );
                
  ELSE 
  
      INSERT INTO SWTMDAC
                (SWTMDAC_PIDM,
                SWTMDAC_SEC_PIDM,
                SWTMDAC_MASTER_IND,
                SWTMDAC_DETAIL_CODE_ACC,
                SWTMDAC_PERCENT_DESC,
                SWTMDAC_AMOUNT_DESC,
                SWTMDAC_DETAIL_CODE_DESC,
                SWTMDAC_EFFECTIVE_DATE_INI,
                SWTMDAC_EFFECTIVE_DATE_FIN,
                SWTMDAC_NUM_REAPPLICATION,
                SWTMDAC_USER,
                SWTMDAC_USR_ROLE,
                SWTMDAC_ACTIVITY_DATE,
                SWTMDAC_APPLICATION_INDICATOR,
                SWTMDAC_APPLICATION_DATE,
                SWTMDAC_FLAG
                --,SWTMDAC_SEQNO_SERV 
                )
         VALUES(p_pidm ,
                vnum_max+1, 
                p_mind , 
                p_detcode_acc , 
                p_percent , 
                p_amount , 
                p_detcode_desc ,
                p_date_ini , 
                p_date_fin , 
                p_replica , 
                p_user , 
                p_usr_rol, 
                sysdate, 
                0,
                null, 
                'Y'
                --PNOSEQ
                 );
  
                
  END IF;
  
commit;

Return vl_error;
    Exception when others then
    vl_error:='Error PKG_STMDAC.sp_crea_desc '||sqlerrm;
    Return vl_error;

end sp_crea_desc;


FUNCTION sp_actualiza_desc ( p_pidm number, p_mind varchar2, p_detcode_acc varchar2, p_percent number DEFAULT NULL, p_amount number DEFAULT NULL, p_date_ini date default null, p_date_fin date default null, p_replica number default null, p_sec_num number default null ) Return Varchar2
is
/* 
autor n: glovicx
fecha 09 nov 2015

Actualiza los campos de una configuracion generada para un descuento este proceso lo pueden hacer los encargados del sistema.


*/

    vl_error Varchar2(2500):=Null;
    
begin

IF p_percent is null and p_amount is null then 

null;
htp.p('No pueden ir Nulos los campos porcentaje ó cantidad ');

else
update SWTMDAC ad
SET SWTMDAC_MASTER_IND = p_mind ,
--SWTMDAC_DETAIL_CODE_ACC,
SWTMDAC_PERCENT_DESC = nvl(p_percent,0) ,
SWTMDAC_AMOUNT_DESC = nvl(p_amount , 0), 
--SWTMDAC_DETAIL_CODE_DESC,
SWTMDAC_EFFECTIVE_DATE_INI = nvl (p_date_ini , ad.SWTMDAC_EFFECTIVE_DATE_INI),
SWTMDAC_EFFECTIVE_DATE_FIN = nvl(p_date_fin ,ad.SWTMDAC_EFFECTIVE_DATE_FIN),
SWTMDAC_NUM_REAPPLICATION = nvl(p_replica , ad.SWTMDAC_NUM_REAPPLICATION),
---SWTMDAC_LAST_DATE,
--SWTMDAC_USER,
--SWTMDAC_USR_ROLE,
SWTMDAC_ACTIVITY_DATE = sysdate ,
SWTMDAC_APPLICATION_INDICATOR = 0
--SWTMDAC_APPLICATION_DATE = 
where swtmdac_pidm = p_pidm 
and SWTMDAC_DETAIL_CODE_ACC = p_detcode_acc
and (SWTMDAC_SEC_PIDM = p_sec_num or p_sec_num is null);
end if;

commit;

Return vl_error;
Exception 
    When others then
        vl_error:='Errpr PKG_STWMDAC_1.sp_actualiza_desc '||sqlerrm;
        Return vl_error;


end sp_actualiza_desc;


FUNCTION  sp_cancela_desc ( p_pidm number, p_detcode_acc varchar2, p_sec_num number default null ) Return Varchar2 
is
/* 
autor n: glovicx
fecha 09 nov 2015

Actualiza los campos de una configuracion generada para un descuento este proceso lo pueden hacer los encargados del sistema.
*/
    vl_error Varchar2(2500) := Null;
begin

update SWTMDAC ad
 SET SWTMDAC_MASTER_IND = 'N' ,
 --SWTMDAC_DETAIL_CODE_ACC,
 --SWTMDAC_PERCENT_DESC = nvl(p_percent,0) ,
 --SWTMDAC_AMOUNT_DESC = nvl(p_amount , 0), 
 --SWTMDAC_DETAIL_CODE_DESC,
 --SWTMDAC_EFFECTIVE_DATE_INI = nvl (p_date_ini , ad.SWTMDAC_EFFECTIVE_DATE_INI),
 --SWTMDAC_EFFECTIVE_DATE_FIN = nvl(p_date_fin ,ad.SWTMDAC_EFFECTIVE_DATE_FIN),
 --SWTMDAC_NUM_REAPPLICATION = nvl(p_replica , ad.SWTMDAC_NUM_REAPPLICATION),
 ---SWTMDAC_LAST_DATE,
 SWTMDAC_USER  = USER
 --SWTMDAC_USR_ROLE,
 ,SWTMDAC_FLAG         = ''
 ,SWTMDAC_ACTIVITY_DATE = sysdate,
 SWTMDAC_APPLICATION_INDICATOR = 9,
 SWTMDAC_APPLICATION_DATE = sysdate
where swtmdac_pidm = p_pidm 
 and SWTMDAC_DETAIL_CODE_ACC = p_detcode_acc
 and (SWTMDAC_SEC_PIDM = p_sec_num or p_sec_num is null);
commit;

Return vl_error;
Exception when others then
       vl_error:='Error pkg_swtmdac.sp_cancela_desc '||sqlerrm;
        Return vl_error;    

end sp_cancela_desc;



function f_periodo ( p_pidm varchar2, p_code_detail varchar2, p_monto number) return varchar2
 is

vs_periodo varchar2(500):=Null;

begin

select TBRACCD_TERM_CODE into vs_periodo
from tbraccd
where TBRACCD_PIDM = p_pidm 
and TBRACCD_DETAIL_CODE = p_code_detail 
and TBRACCD_AMOUNT = p_monto;

return (vs_periodo);

exception 
when others then
vs_periodo := 'Error PKG_SWTMDAC.f_periodo '||sqlerrm;
Return vs_periodo; --se modific?? vs_periodo :='0000'

end f_periodo;


  function f_obten_codigo_descuento( code_detail varchar2 ) return varchar2 is
    dsc_code_detail varchar2(500);
    vl_error varchar2(2500):=Null;
  begin
    
     For c in ( SELECT ZSTPARA_PARAM_VALOR 
                FROM SATURN.ZSTPARA 
                WHERE ZSTPARA_MAPA_ID = 'DESCUENTO' 
                AND ZSTPARA_PARAM_ID = code_detail ) loop
                
               dsc_code_detail:= c.ZSTPARA_PARAM_VALOR;
              
     End loop;    
    return (dsc_code_detail);
    Return vl_error;
    Exception When others then
        vl_error:='Error PKG_SWTMDAC.f_obten_codigo_descuento '||sqlerrm;
        Return vl_error;   
    
  end  f_obten_codigo_descuento;

PROCEDURE SP_APLICA_DESCUENTO (P_PIDM NUMBER, P_NUM_DESC NUMBER, P_NUM_TRAN NUMBER, P_DETAIL_CODE VARCHAR2, P_MONTO NUMBER, P_TERM_CODE VARCHAR2 , P_DETALLE_DESC VARCHAR2, P_TRANSNUM NUMBER, P_EXITO OUT VARCHAR2 ) 
IS
/*
Se sobre carga el procedimiento para enviar el crossfererence desde el  trigger por peticiones del SSB vmrl.
Registrar el Cr?to insertando el registro en la tabla TBRACCD (vic)
 ( Usar API tb_receivable.p_create )
 -PIDM
 -C??o de Detalle de Descuento (de la regla)
 -Fecha Efectiva igual a la fecha_efectiva
 - TBRACCD_SRCE_CODE con valor ?W? ( nuevo valor en TTVSRCE )
 -Referencia para aplicar el pago
 -TBRACCD_TRAN_NUMBER_PAID igual a No_de_transaccion del cargo orig
 -Referencias cruzadas:
 -TBRACCD_CROSSREF_NUMBER indicar el No_consecutivo_de_Descuento
 - Monto del descuento (preguntar a David el par?tro y dem?que se requieran)
Par?tros de entrada:
 -alumno ( pidm )
 -No_de_descuento
 -No_de_transaccion del cargo original
 -C??o_de_detalle del cargo original
 -Monto_del_Cargo
 -Fecha_Efectiva

CRAETED VIC..

LAST MODIFY: 02 -NOV- 2015
las modify glovicx 26/06/2020  se agrega bitacora
las modify reza 28/05/2021 se agrega orden
*/

P_DETAIL_DESC VARCHAR2(100);
P_DETAIL_CO VARCHAR2(6);
P_NUM_TRAN_MAX NUMBER:=0;
V_MONEDA      VARCHAR2(5);
VL_ERROR_INSERTA VARCHAR(200):=NULL;
VL_ERROR_ACTUALIZA VARCHAR(200):=NULL;

VC_FUERA_RANGO NUMBER;
VL_ERROR VARCHAR2(2500):='EXITO';
VUSUARIO  VARCHAR2(20);
VID          VARCHAR2(14);
VL_ORDEN        NUMBER;
vl_monto_aplica number;

BEGIN
--dbms_output.put_line ( ' Aplica descuento  num tran del parametro  ' ||p_num_tran);
--p_detail_desc := 'codigo de descuento' ;

    vl_monto_aplica:= round(P_MONTO);

   If substr (P_DETAIL_CODE,3,2) not in ( 'QI', 'NA') then  ---- Se valida que el descuento no corresponda a la venta de UTELX por paquete fijo o SSB ---Victor Ramirez 

        ----este max sirve en todos loscasos pero en especial cuando ejecutas el lanza_insert por que ahilo tengo que calcular
        BEGIN
            SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0)+ 1  N_TRAN
                    INTO P_NUM_TRAN_MAX
            FROM TBRACCD
            WHERE TBRACCD_PIDM = P_PIDM;
        EXCEPTION
        WHEN OTHERS THEN 
                P_NUM_TRAN_MAX := 1;
        END;


        --;
        ---------------------VOY A CALCULAR LA MONEDA QUE TIENE EL DESCUENTO --------
        BEGIN 
            SELECT TVRDCTX_CURR_CODE
                INTO V_MONEDA
            FROM TAISMGR.TVRDCTX
            WHERE TVRDCTX_DETC_CODE  = P_DETAIL_CODE;
        EXCEPTION
        WHEN OTHERS THEN 
        V_MONEDA  := 'MXN';
        END;

        IF  V_MONEDA  IS NULL  THEN
        V_MONEDA  := 'MXN';
        END IF;

        /* SE AGREGO PARA OBTENER CODIGO DE DETALLE DE DESCUENTO DEL CODIGO DE DETALLE DE PRODUCTO*/

        BEGIN 
                SELECT  NVL(SWTMDAC_DETAIL_CODE_DESC,'DESC')  , NVL(SWTMDAC_USER,USER) 
                  INTO  P_DETAIL_CO,VUSUARIO
                FROM SWTMDAC
                WHERE SWTMDAC_PIDM  = P_PIDM
                AND  SWTMDAC_DETAIL_CODE_ACC  = P_DETAIL_CODE
                AND  SWTMDAC_SEC_PIDM   = P_NUM_DESC;
        EXCEPTION 
        WHEN OTHERS THEN 
            P_DETAIL_CO := 'DESC';
        END;        

        IF P_DETAIL_CO  IS NULL THEN
        P_DETAIL_CO  := 'DESC';
        END IF;




        IF P_DETAIL_CO IS NOT NULL THEN 

            BEGIN
                SELECT TBBDETC_DESC 
                    INTO P_DETAIL_DESC 
                FROM TAISMGR.TBBDETC 
                WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CO
                AND TBBDETC_TYPE_IND = 'P';
            EXCEPTION 
            WHEN OTHERS THEN 
                P_DETAIL_DESC := NULL;
            END;

            IF P_DETAIL_DESC IS NOT NULL THEN
                        --dbms_output.put_line ( ' calcula el maxico del pidm ' || p_num_tran_MAX);
                        ------se hace el insert en el edocta estos son tipo pago por que son descuentos que se hacen a los accesorios de comprados por un alumno por eso los montos van en negativo esto fue checado con David torres.--
                IF P_NUM_TRAN_MAX = P_NUM_TRAN THEN
                        
                  P_NUM_TRAN_MAX := P_NUM_TRAN_MAX+1;

                END IF;
                
        --        BEGIN
        --          SELECT TBRACCD_RECEIPT_NUMBER
        --            INTO VL_ORDEN
        --            FROM TBRACCD
        --           WHERE     TBRACCD_PIDM = P_PIDM
        --                 AND TBRACCD_TRAN_NUMBER = P_NUM_TRAN;
        --        END;

                BEGIN 
                --dbms_output.put_line ( ' variables de inserta  MAX  y param nuevo>>  ' || p_num_tran_MAX || '    NUM_TRAN_PARAM   ' ||  p_num_tran );
                 INSERT INTO TBRACCD 
                 (TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_USER, TBRACCD_ENTRY_DATE, TBRACCD_AMOUNT, TBRACCD_BALANCE,
                  TBRACCD_EFFECTIVE_DATE, TBRACCD_DESC,TBRACCD_RECEIPT_NUMBER, TBRACCD_ACTIVITY_DATE, TBRACCD_TRANS_DATE, TBRACCD_DATA_ORIGIN, TBRACCD_CREATE_SOURCE,
                  TBRACCD_SRCE_CODE , TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER,TBRACCD_CROSSREF_NUMBER, TBRACCD_CURR_CODE,TBRACCD_TRAN_NUMBER_PAID )
                 VALUES 
                 (P_PIDM, P_NUM_TRAN_MAX, P_TERM_CODE, P_DETAIL_CO, VUSUARIO/*'SistemaV2'*/, SYSDATE, vl_monto_aplica, (vl_monto_aplica)*-1 , TRUNC(SYSDATE), P_DETAIL_DESC,VL_ORDEN, SYSDATE, SYSDATE, 'PKG_SWTMDAC','AD', 'T' , 'Y',0 ,NVL(P_TRANSNUM,P_NUM_DESC), V_MONEDA,
                 P_NUM_TRAN );
                         
                EXCEPTION
                WHEN OTHERS THEN  
                    VL_ERROR:= ' Errror al Insertar >>  ' || SQLERRM;
                END;

                    
                    P_EXITO:= VL_ERROR;
               BEGIN
                SELECT F_GETSPRIDENID(P_PIDM)
                    INTO VID
                  FROM DUAL;
               EXCEPTION WHEN OTHERS THEN
               VID := 'no_entro';
               END;
                  
               IF P_EXITO = 'EXITO' THEN
                     
                  BEGIN
                     
                      UPDATE  TBITSIU
                      SET  P_SWTDAC   = 'Y',
                           VALOR_SWTD =( 'param_swmtdac '|| P_DETAIL_CO||'-'||P_DETAIL_DESC||'-'||P_TERM_CODE||'-'|| V_MONEDA||'-'||P_NUM_DESC ),
                           VALOR17  = P_EXITO||'swtmdac'
                       WHERE PIDM = P_PIDM
                       AND   SEQNO = P_TRANSNUM
                       AND   MONTO = vl_monto_aplica;
                
                   EXCEPTION WHEN OTHERS THEN
                    VL_ERROR := SQLERRM;
                   END;    
                   
                   BEGIN
                     UPDATE  SATURN.SWTMDAC WT
                        SET SWTMDAC_SEQNO_SERV  = P_TRANSNUM, 
                          SWTMDAC_APPLICATION_INDICATOR = 1,
                          SWTMDAC_ACTIVITY_DATE     = SYSDATE
                          -- SWTMDAC_APPLICATION_DATE      = sysdate
                       WHERE WT.SWTMDAC_PIDM = P_PIDM
                         -- and WT.SWTMDAC_DETAIL_CODE_ACC = p_detail_co
                          AND WT.SWTMDAC_SEC_PIDM    = P_NUM_DESC
                          AND  WT.SWTMDAC_SEQNO_SERV  IS NULL;
                          
                    EXCEPTION WHEN OTHERS THEN
                    VL_ERROR := SQLERRM;
                    DBMS_OUTPUT.PUT_LINE('ERROR EN ACTUALIZAR NO DE SERVICIO EN SWTMDAC');
                   END;   
                         
                ELSE
                
                 BEGIN
                     
                      UPDATE  TBITSIU
                      SET  P_SWTDAC   = 'Y',
                           VALOR_SWTD =( 'NO ENCUENTRA AD_SWMTDAC '|| P_DETAIL_CO||'-'||P_DETAIL_DESC||'-'||P_TERM_CODE||'-'|| V_MONEDA ),
                           VALOR17  = P_EXITO||'swtmdac'
                       WHERE PIDM = P_PIDM
                       AND   SEQNO = P_TRANSNUM
                       AND   MONTO = vl_monto_aplica;
                
                   EXCEPTION WHEN OTHERS THEN
                    VL_ERROR := SQLERRM;
                   END;     
                      
                END IF;   
                   
            END IF;
        END IF;

   End if;

END SP_APLICA_DESCUENTO;



--FUNCION CREADA PARA CACHAR EL ERROR

FUNCTION sp_aplica_descuento (p_pidm number, p_num_desc number, p_num_tran number, p_detail_code varchar2, p_monto number, p_term_code varchar2 , p_detalle_desc varchar2, p_transnum number, p_paymnent varchar2 default null,P_STUDY NUMBER )Return varchar2
 is
/*
Se sobre carga el procedimiento para enviar el crossfererence desde el  trigger por peticiones del SSB vmrl.
Registrar el Crédito insertando el registro en la tabla TBRACCD (vic)
 ( Usar API tb_receivable.p_create )
 -PIDM
 -Código de Detalle de Descuento (de la regla)
 -Fecha Efectiva igual a la fecha_efectiva
 - TBRACCD_SRCE_CODE con valor ‘W’ ( nuevo valor en TTVSRCE )
 -Referencia para aplicar el pago
 -TBRACCD_TRAN_NUMBER_PAID igual a No_de_transaccion del cargo orig
 -Referencias cruzadas:
 -TBRACCD_CROSSREF_NUMBER indicar el No_consecutivo_de_Descuento
 - Monto del descuento (preguntar a David el parámetro y demás que se requieran)
Parámetros de entrada:
 -alumno ( pidm )
 -No_de_descuento
 -No_de_transaccion del cargo original
 -Código_de_detalle del cargo original
 -Monto_del_Cargo
 -Fecha_Efectiva

CRAETED VIC..

LAST MODIFY: 02 -NOV- 2015
se le hacen algunos ajustes al proceso para cerrar los flujos ESTA ES LA QUE SE OCUPA DESDE EL TRIGGER DE TBRACCD YA TAMBIEN SE MODIFICO EL TRIGGER
-- PARA QUE MANDE LLAMARA ESTA FUNCION GLOVICX 31/05/021

*/


P_DETAIL_DESC       VARCHAR2(100);
P_DETAIL_CO         VARCHAR2(6);
P_NUM_TRAN_MAX      NUMBER:=0;
V_MONEDA            VARCHAR2(5);
VL_ERROR_INSERTA    VARCHAR(200):=NULL;
VL_ERROR_ACTUALIZA VARCHAR(200):=NULL;

VC_FUERA_RANGO  NUMBER;
VL_ERROR        VARCHAR2(2500):='EXITO';
VUSUARIO        VARCHAR2(20);
VID             VARCHAR2(14);
P_EXITO         VARCHAR2(1000);

BEGIN

--p_detail_desc := 'codigo de descuento' ;


        ----este max sirve en todos loscasos pero en especial cuando ejecutas el lanza_insert por que ahilo tengo que calcular
        BEGIN
            SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0)+ 1  N_TRAN
                    INTO P_NUM_TRAN_MAX
            FROM TBRACCD
            WHERE TBRACCD_PIDM = P_PIDM;
        EXCEPTION
        WHEN OTHERS THEN 
                P_NUM_TRAN_MAX := 1;
        END;


--;
        ---------------------VOY A CALCULAR LA MONEDA QUE TIENE EL DESCUENTO --------
        BEGIN 
            SELECT TVRDCTX_CURR_CODE
                INTO V_MONEDA
            FROM TAISMGR.TVRDCTX
            WHERE TVRDCTX_DETC_CODE  = P_DETAIL_CODE;
        EXCEPTION
        WHEN OTHERS THEN 
        V_MONEDA  := 'MXN';
        END;

        IF  V_MONEDA  IS NULL  THEN
        V_MONEDA  := 'MXN';
        END IF;

/* SE AGREGO PARA OBTENER CODIGO DE DETALLE DE DESCUENTO DEL CODIGO DE DETALLE DE PRODUCTO*/

        BEGIN 
                SELECT  NVL(SWTMDAC_DETAIL_CODE_DESC,'DESC')  , NVL(SWTMDAC_USER,USER) 
                  INTO  P_DETAIL_CO,VUSUARIO
                FROM SWTMDAC
                WHERE SWTMDAC_PIDM  = P_PIDM
                AND  SWTMDAC_DETAIL_CODE_ACC  = P_DETAIL_CODE
                AND  SWTMDAC_SEC_PIDM   = P_NUM_DESC;
        EXCEPTION 
        WHEN OTHERS THEN 
            P_DETAIL_CO := 'DESC';
        END;        

    IF P_DETAIL_CO  IS NULL THEN
    P_DETAIL_CO  := 'DESC';
    END IF;

IF P_DETAIL_CO IS NOT NULL THEN 

    BEGIN
        SELECT TBBDETC_DESC 
            INTO P_DETAIL_DESC 
        FROM TAISMGR.TBBDETC 
        WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CO
        AND TBBDETC_TYPE_IND = 'P';
    EXCEPTION 
    WHEN OTHERS THEN 
        P_DETAIL_DESC := NULL;
    END;

    IF P_DETAIL_DESC IS NOT NULL THEN
--                dbms_output.put_line ( ' calcula el maxico del pidm ' || p_num_tran_MAX);
                ------se hace el insert en el edocta estos son tipo pago por que son descuentos que se hacen a los accesorios de comprados por un alumno por eso los montos van en negativo esto fue checado con David torres.--
        IF P_NUM_TRAN_MAX = P_NUM_TRAN THEN
                
          P_NUM_TRAN_MAX := P_NUM_TRAN_MAX+1;

        END IF;

        BEGIN 
--        dbms_output.put_line ( ' variables de inserta  MAX  y param nuevo>>  ' || p_num_tran_MAX || '    NUM_TRAN_PARAM   ' ||  p_num_tran );
         INSERT INTO TBRACCD 
         (TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_USER, TBRACCD_ENTRY_DATE, TBRACCD_AMOUNT, TBRACCD_BALANCE,TBRACCD_EFFECTIVE_DATE, TBRACCD_DESC, 
         TBRACCD_ACTIVITY_DATE, TBRACCD_TRANS_DATE, TBRACCD_DATA_ORIGIN, TBRACCD_CREATE_SOURCE,TBRACCD_SRCE_CODE , TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER,TBRACCD_CROSSREF_NUMBER, TBRACCD_CURR_CODE,
         TBRACCD_TRAN_NUMBER_PAID,TBRACCD_STSP_KEY_SEQUENCE )
         VALUES 
         (P_PIDM, P_NUM_TRAN_MAX, P_TERM_CODE, P_DETAIL_CO, VUSUARIO/*'SistemaV2'*/, SYSDATE, P_MONTO, (P_MONTO)*-1 , TRUNC(SYSDATE), P_DETAIL_DESC, SYSDATE, SYSDATE, 'PKG_SWTMDAC','AD', 'T' , 'Y',0 ,NVL(P_TRANSNUM,P_NUM_DESC), V_MONEDA,
         P_NUM_TRAN,P_STUDY );
                 
        EXCEPTION
        WHEN OTHERS THEN  
            VL_ERROR:= ' Errror al Insertar >>  ' || SQLERRM;
        END;

            
            P_EXITO:= VL_ERROR;
       BEGIN
        SELECT F_GETSPRIDENID(P_PIDM)
            INTO VID
          FROM DUAL;
       EXCEPTION WHEN OTHERS THEN
       VID := 'no_entro';
       END;
          
       IF P_EXITO = 'EXITO' THEN
             
--          BEGIN
--             
--              UPDATE  TBITSIU
--              SET  P_SWTDAC   = 'Y',
--                   VALOR_SWTD =( 'param_swmtdac '|| P_DETAIL_CO||'-'||P_DETAIL_DESC||'-'||P_TERM_CODE||'-'|| V_MONEDA||'-'||P_NUM_DESC ),
--                   VALOR17  = P_EXITO||'swtmdac'
--               WHERE PIDM = P_PIDM
--               AND   SEQNO = P_TRANSNUM
--               AND   MONTO = P_MONTO;
--        
--           EXCEPTION WHEN OTHERS THEN
--            VL_ERROR := SQLERRM;
--           END;    
           
           BEGIN
             UPDATE  SATURN.SWTMDAC WT
                SET SWTMDAC_SEQNO_SERV  = P_TRANSNUM, 
                  SWTMDAC_APPLICATION_INDICATOR = 1,
                  SWTMDAC_ACTIVITY_DATE     = SYSDATE
                  -- SWTMDAC_APPLICATION_DATE      = sysdate
               WHERE WT.SWTMDAC_PIDM = P_PIDM
                 -- and WT.SWTMDAC_DETAIL_CODE_ACC = p_detail_co
                  AND WT.SWTMDAC_SEC_PIDM    = P_NUM_DESC
                  AND  WT.SWTMDAC_SEQNO_SERV  IS NULL;
                  
            EXCEPTION WHEN OTHERS THEN
            VL_ERROR := SQLERRM;
--            DBMS_OUTPUT.PUT_LINE('ERROR EN ACTUALIZAR NO DE SERVICIO EN SWTMDAC');
           END;   
                 
        ELSE
        
--         BEGIN
--             
--              UPDATE  TBITSIU
--              SET  P_SWTDAC   = 'Y',
--                   VALOR_SWTD =( 'NO ENCUENTRA AD_SWMTDAC '|| P_DETAIL_CO||'-'||P_DETAIL_DESC||'-'||P_TERM_CODE||'-'|| V_MONEDA ),
--                   VALOR17  = P_EXITO||'swtmdac'
--               WHERE PIDM = P_PIDM
--               AND   SEQNO = P_TRANSNUM
--               AND   MONTO = P_MONTO;
--        
--           EXCEPTION WHEN OTHERS THEN
--            VL_ERROR := SQLERRM;
--           END;     
              null;
        END IF;   
           
    END IF;
 END IF;

Return vl_error;

Exception when others then
    vl_error:='Error PKG_SWTMDAC.sp_aplica_descuento '||sqlerrm;
    Return vl_error;
end sp_aplica_descuento;

FUNCTION fn_cancela_cartera_segunda_sol(p_pidm in number, p_term_code_entry in Varchar2) Return Varchar2

is

vl_msje Varchar2(200):='Procedimiento cancela_cartera_segunda_sol exitoso';
vl_max number:=0;

BEGIN

if p_pidm is null or p_term_code_entry is null then

    vl_msje:='Parametro nulo';

else

    begin

        for pagoppl in (
        
        select TBRAPPL_PIDM, TBRAPPL_PAY_TRAN_NUMBER, TBRAPPL_CHG_TRAN_NUMBER, TBRAPPL_AMOUNT, TBRAPPL_DIRECT_PAY_TYPE
                        from tbrappl , tbraccd
                        Where TBRAPPL_PIDM = p_pidm
                        And TBRAPPL_PIDM=TBRACCD_PIDM AND TBRAPPL_PAY_TRAN_NUMBER=TBRACCD_TRAN_NUMBER AND TBRACCD_TERM_CODE=p_term_code_entry
                        And TBRAPPL_REAPPL_IND is null 
                        
                        )  
        loop                                                            
        gb_common.p_set_context('TB_RECEIVABLE','PROCESS','APPLPMNT-FORCE','N');
        tv_application.p_unapply_by_tran_number( p_pidm => pagoppl.TBRAPPL_PIDM,
                                                 p_pay_tran_number    => pagoppl.TBRAPPL_PAY_TRAN_NUMBER,
                                                 p_unapply_direct_pay => pagoppl.TBRAPPL_DIRECT_PAY_TYPE);   
                                                                                                                              
                                                                                                                          
        End Loop pagoppl;

    end;

    begin

        for f in (
        
        select TBRACCD_PIDM, 
                        TBRACCD_TRAN_NUMBER,
                        TBRACCD_TERM_CODE,
                        TBRACCD_DETAIL_CODE,
                        TBRACCD_USER,
                        TBRACCD_ENTRY_DATE,
                        TBRACCD_AMOUNT*-1 AMOUNT,
                        TBRACCD_BALANCE BALANCE,
                        TBRACCD_EFFECTIVE_DATE,
                        TBRACCD_BILL_DATE,
                        TBRACCD_DUE_DATE,
                        TBRACCD_DESC,
                        TBRACCD_RECEIPT_NUMBER,
                        TBRACCD_TRAN_NUMBER_PAID,
                        TBRACCD_CROSSREF_PIDM,
                        TBRACCD_CROSSREF_NUMBER,
                        TBRACCD_CROSSREF_DETAIL_CODE,
                        TBRACCD_SRCE_CODE,
                        TBRACCD_ACCT_FEED_IND,
                        SYSDATE FECHA,
                        TBRACCD_SESSION_NUMBER,
                        TBRACCD_CSHR_END_DATE,
                        TBRACCD_CRN,
                        TBRACCD_CROSSREF_SRCE_CODE,
                        TBRACCD_LOC_MDT,
                        TBRACCD_LOC_MDT_SEQ,
                        TBRACCD_RATE,
                        TBRACCD_UNITS,
                        TBRACCD_DOCUMENT_NUMBER,
                        TBRACCD_TRANS_DATE,
                        TBRACCD_PAYMENT_ID,
                        TBRACCD_INVOICE_NUMBER,
                        TBRACCD_STATEMENT_DATE,
                        TBRACCD_INV_NUMBER_PAID,
                        TBRACCD_CURR_CODE,
                        TBRACCD_EXCHANGE_DIFF,
                        TBRACCD_FOREIGN_AMOUNT,
                        TBRACCD_LATE_DCAT_CODE,
                        TBRACCD_FEED_DATE,
                        TBRACCD_FEED_DOC_CODE,
                        TBRACCD_ATYP_CODE,
                        TBRACCD_ATYP_SEQNO,
                        TBRACCD_CARD_TYPE_VR,
                        TBRACCD_CARD_EXP_DATE_VR,
                        TBRACCD_CARD_AUTH_NUMBER_VR,
                        TBRACCD_CROSSREF_DCAT_CODE,
                        TBRACCD_ORIG_CHG_IND,
                        TBRACCD_CCRD_CODE,
                        TBRACCD_MERCHANT_ID,
                        TBRACCD_TAX_REPT_YEAR,
                        TBRACCD_TAX_REPT_BOX,
                        TBRACCD_TAX_AMOUNT,
                        TBRACCD_TAX_FUTURE_IND,
                        TBRACCD_DATA_ORIGIN,
                        TBRACCD_CREATE_SOURCE,
                        TBRACCD_CPDT_IND,
                        TBRACCD_AIDY_CODE,
                        TBRACCD_STSP_KEY_SEQUENCE,
                        TBRACCD_PERIOD,
                        TBRACCD_USER_ID 
                        from tbraccd, tbbdetc
                        where tbraccd_pidm=p_pidm 
                        and tbraccd_term_code=p_term_code_entry
                        and     tbraccd_detail_code=tbbdetc_detail_code 
                        and  tbbdetc_dcat_code!='CSH'
                        
                        ) loop
                        
                vl_max:=0;        
                        
         Begin
         
          select max(nvl (tbraccd_tran_number,0)+1)
          Into vl_max
          from tbraccd  
          where tbraccd_pidm = f.TBRACCD_PIDM;
        end;

        insert into TBRACCD values (f.TBRACCD_PIDM,
                                    vl_max,
                                    f.TBRACCD_TERM_CODE,
                                    f.TBRACCD_DETAIL_CODE,
                                    f.TBRACCD_USER,
                                    f.TBRACCD_ENTRY_DATE,
                                    f.AMOUNT,
                                    0,
                                    f.TBRACCD_EFFECTIVE_DATE,
                                    f.TBRACCD_BILL_DATE,
                                    f.TBRACCD_DUE_DATE,
                                    f.TBRACCD_DESC,
                                    f.TBRACCD_RECEIPT_NUMBER,
                                    f.TBRACCD_TRAN_NUMBER,
                                    f.TBRACCD_CROSSREF_PIDM,
                                    f.TBRACCD_CROSSREF_NUMBER,
                                    f.TBRACCD_CROSSREF_DETAIL_CODE,
                                    f.TBRACCD_SRCE_CODE,
                                    f.TBRACCD_ACCT_FEED_IND,
                                    SYSDATE,
                                    f.TBRACCD_SESSION_NUMBER,
                                    f.TBRACCD_CSHR_END_DATE,
                                    f.TBRACCD_CRN,
                                    f.TBRACCD_CROSSREF_SRCE_CODE,
                                    f.TBRACCD_LOC_MDT,
                                    f.TBRACCD_LOC_MDT_SEQ,
                                    f.TBRACCD_RATE,
                                    f.TBRACCD_UNITS,
                                    f.TBRACCD_DOCUMENT_NUMBER,
                                    f.TBRACCD_TRANS_DATE,
                                    f.TBRACCD_PAYMENT_ID,
                                    f.TBRACCD_INVOICE_NUMBER,
                                    f.TBRACCD_STATEMENT_DATE,
                                    f.TBRACCD_INV_NUMBER_PAID,
                                    f.TBRACCD_CURR_CODE,
                                    f.TBRACCD_EXCHANGE_DIFF,
                                    f.TBRACCD_FOREIGN_AMOUNT,
                                    f.TBRACCD_LATE_DCAT_CODE,
                                    f.TBRACCD_FEED_DATE,
                                    f.TBRACCD_FEED_DOC_CODE,
                                    f.TBRACCD_ATYP_CODE,
                                    f.TBRACCD_ATYP_SEQNO,
                                    f.TBRACCD_CARD_TYPE_VR,
                                    f.TBRACCD_CARD_EXP_DATE_VR,
                                    f.TBRACCD_CARD_AUTH_NUMBER_VR,
                                    f.TBRACCD_CROSSREF_DCAT_CODE,
                                    f.TBRACCD_ORIG_CHG_IND,
                                    f.TBRACCD_CCRD_CODE,
                                    f.TBRACCD_MERCHANT_ID,
                                    f.TBRACCD_TAX_REPT_YEAR,
                                    f.TBRACCD_TAX_REPT_BOX,
                                    f.TBRACCD_TAX_AMOUNT,
                                    f.TBRACCD_TAX_FUTURE_IND,
                                    f.TBRACCD_DATA_ORIGIN,
                                    f.TBRACCD_CREATE_SOURCE,
                                    f.TBRACCD_CPDT_IND,
                                    f.TBRACCD_AIDY_CODE,
                                    f.TBRACCD_STSP_KEY_SEQUENCE,
                                    f.TBRACCD_PERIOD,
                                    NULL,
                                    NULL,
                                    f.TBRACCD_USER_ID,
                                    NULL);
                                    
                                  Begin  
                                      Update tbraccd
                                      set tbraccd_balance = 0
                                      where tbraccd_pidm = f.tbraccd_pidm
                                      And tbraccd_tran_number = f.tbraccd_tran_number;
                                  Exception
                                  When Others then 
                                   vl_msje := 'Error al actualizar el concepto origen '||sqlerrm;
                                  End;
                                    
        end loop;            
    end;
      
end if;
commit;
Return vl_msje;
Exception
When others then
vl_msje:='Error general en la funcion'||sqlerrm;
Rollback;
END;

----------------------------------------------------------------------------------------------------------------------

FUNCTION sp_aplica_descuento_PV (p_pidm number, p_num_desc number, p_num_tran number, p_detail_code varchar2, p_monto number, p_term_code varchar2 , p_detalle_desc varchar2, p_transnum number, p_paymnent varchar2 default null, p_user varchar2)Return varchar2
 is
/*
Se sobre carga el procedimiento para enviar el crossfererence desde el  trigger por peticiones del SSB vmrl.
Registrar el Crédito insertando el registro en la tabla TBRACCD (vic)
 ( Usar API tb_receivable.p_create )
 -PIDM
 -Código de Detalle de Descuento (de la regla)
 -Fecha Efectiva igual a la fecha_efectiva
 - TBRACCD_SRCE_CODE con valor ‘W’ ( nuevo valor en TTVSRCE )
 -Referencia para aplicar el pago
 -TBRACCD_TRAN_NUMBER_PAID igual a No_de_transaccion del cargo orig
 -Referencias cruzadas:
 -TBRACCD_CROSSREF_NUMBER indicar el No_consecutivo_de_Descuento
 - Monto del descuento (preguntar a David el parámetro y demás que se requieran)
Parámetros de entrada:
 -alumno ( pidm )
 -No_de_descuento
 -No_de_transaccion del cargo original
 -Código_de_detalle del cargo original
 -Monto_del_Cargo
 -Fecha_Efectiva

CRAETED VIC..

LAST MODIFY: 02 -NOV- 2015
last modify 25/02/2020 se modifico el insert en la tabla de paso por que antes no lo hacia y en el portal de pagos no se veia reflejado el descuento.
glovicx 25/02/2020
*/

p_detail_desc varchar2(100);
p_detail_co varchar2(6);
p_num_tran_MAX NUMBER:=0;
v_moneda      varchar2(5);
vl_error varchar2(2500):='EXITO';
vl_error_inserta varchar(200):=Null;
vl_error_actualiza varchar(200):=Null;

vc_fuera_rango NUMBER:=0;
vno_seqno      number:=0;
vmaxPV         number:=0;
vdtl_tbra     varchar2(4);

begin
--dbms_output.put_line ( ' Aplica descuento  num tran del parametro  ' ||p_num_tran);
--p_detail_desc := 'codigo de descuento' ;

If p_detail_code is null then 
   vl_error := 'No existe configuracion de descuento para este accesorio';
Else   

----este max sirve en todos loscasos pero en especial cuando ejecutas el lanza_insert por que ahilo tengo que calcular
        Begin
                    SELECT nvl(MAX(TBRACCD_TRAN_NUMBER),0)+ 1  N_TRAN
                            INTO p_num_tran_MAX
                    FROM TBRACCD
                    WHERE TBRACCD_PIDM = p_pidm;
        Exception 
        When Others then 
        vl_error := 'Error al obtener valor maximo' ||sqlerrm;
        End;

        ---------------------VOY A CALCULAR LA MONEDA QUE TIENE EL DESCUENTO --------
        Begin 
                SELECT TVRDCTX_CURR_CODE
                INTO v_moneda
                FROM TAISMGR.TVRDCTX
                WHERE TVRDCTX_DETC_CODE  = p_detail_code;
        Exception 
        When Others then 
        v_moneda  := 'MXN'; 
        End;


        Begin 
            SELECT TBBDETC_DESC 
                INTO p_detail_desc 
             FROM TAISMGR.TBBDETC 
            WHERE TBBDETC_DETAIL_CODE = p_detail_code
            AND TBBDETC_TYPE_IND = 'P'
            ;
        Exception 
        When Others then 
        vl_error := 'Error al obtener descripcin del codigo de detalle' ||sqlerrm;
        End;

 IF p_detail_desc  IS NOT NULL THEN

 -- dbms_output.put_line ( ' calcula el maxico del pidm ' || p_num_tran_MAX);
        if p_num_tran_MAX = p_num_tran then
        p_num_tran_MAX := p_num_tran_MAX+1;
        end if;
        -----------se obtienen los datos del numero de servicio del autoservicio que esta creando su descuento GLOVICX 04/feb/ 2020
        ---------en teoria debe estar como activo 
         begin
                
              select tt.TBRACCD_CROSSREF_NUMBER, TT.TBRACCD_DETAIL_CODE
                into vno_seqno, vdtl_tbra
                from tbraccd tt
                where 1=1 
                AND tbraccd_pidm = p_pidm
                AND TBRACCD_TRAN_NUMBER  = p_num_tran  ;
                
            Exception
            When Others then  
            vno_seqno  := 1;
            vl_error :=' No se encontro un servicio para asignar  ' || sqlerrm ;        
         
         end;
         
       --  insert into twpasow(valor1, valor2, valor3, valor4, valor5, VALOR6 )
       --  values('estoy en SWTMDAC', p_pidm,  p_detail_code, vno_seqno, p_transnum , p_num_tran);
        -- commit;
         
        Begin 

         INSERT INTO TBRACCD 
         (TBRACCD_PIDM, TBRACCD_TRAN_NUMBER, TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_USER, TBRACCD_ENTRY_DATE, TBRACCD_AMOUNT, TBRACCD_BALANCE,TBRACCD_EFFECTIVE_DATE, TBRACCD_DESC, 
         TBRACCD_ACTIVITY_DATE, TBRACCD_TRANS_DATE, TBRACCD_DATA_ORIGIN, TBRACCD_CREATE_SOURCE,TBRACCD_SRCE_CODE , TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER,TBRACCD_CROSSREF_NUMBER, TBRACCD_CURR_CODE,
         TBRACCD_TRAN_NUMBER_PAID, TBRACCD_PAYMENT_ID)
         VALUES 
         --(p_pidm, p_num_tran_max, p_term_code, p_detail_code, p_user, SYSDATE, p_monto, (p_monto)*-1 , trunc(sysdate), p_detail_desc, sysdate, sysdate, 'PKG_SWTMDAC','AD', 'T' , 'Y',0 ,nvl(p_transnum,p_num_desc), v_moneda, --glovicx 04/02/2020
            (p_pidm, p_num_tran_max, p_term_code, p_detail_code, p_user, SYSDATE, p_monto, (p_monto)*-1 , trunc(sysdate), p_detail_desc, sysdate, sysdate, 'PKG_SWTMDAC','AD', 'T' , 'Y',0 ,nvl(vno_seqno,p_num_desc), v_moneda,
          p_num_tran, p_paymnent);
         
        Exception
        When Others then  
            vl_error :=' Errror al Insertar el descuento>>  ' || sqlerrm ;
        End;

  ---------------aqui se hace el insert en la tabla SWTMDAC ya que hoy en dia no se hace ese insert y es necesario
  -----------para que elportal de pagos ya presente el descuento desde la pantalla 
  --------- modify glovicx 19/02/2020
        
        begin
          select nvl(max(SWTMDAC_SEC_PIDM),0)+1
           into vmaxPV
           from SWTMDAC
           where SWTMDAC_PIDM = p_pidm;
         exception when others then
         vmaxPV := 1;
         
       end;    
  
       begin
       
            insert into SWTMDAC (  SWTMDAC_PIDM,
                                SWTMDAC_SEC_PIDM,
                                SWTMDAC_MASTER_IND,
                                SWTMDAC_DETAIL_CODE_ACC,
                              --  SWTMDAC_PERCENT_DESC,
                                SWTMDAC_AMOUNT_DESC,
                                SWTMDAC_DETAIL_CODE_DESC,
                                SWTMDAC_EFFECTIVE_DATE_INI,
                                SWTMDAC_EFFECTIVE_DATE_FIN,
                                SWTMDAC_NUM_REAPPLICATION,
                              --  SWTMDAC_LAST_DATE,
                                SWTMDAC_USER,
                                SWTMDAC_USR_ROLE,
                                SWTMDAC_ACTIVITY_DATE,
                                SWTMDAC_APPLICATION_INDICATOR,
                                SWTMDAC_APPLICATION_DATE,
                                SWTMDAC_FLAG ,
                                SWTMDAC_SEQNO_SERV)
                                values( p_pidm,vmaxPV, 'Y',vdtl_tbra,p_monto,p_detail_code,sysdate,sysdate,1
                                        ,'descuento_PV', 2, sysdate, 0,sysdate, 'Y' ,vno_seqno );

 --         insert into twpasow(valor1, valor2, valor3, valor4, valor5) 
 --         values('descuento_PV_1',p_pidm,p_monto,p_detail_code , vdtl_tbra );
       
       exception when others then
       vl_error:= ' Errror al INSERTAR en  SWTMDAC  >>  ' || sqlerrm ;
 --        insert into twpasow(valor1, valor2, valor3) values('descuento_PV',p_pidm,p_monto  );
       end;

    Begin 
            UPDATE  saturn.SWTMDAC
            SET SWTMDAC_APPLICATION_INDICATOR = SWTMDAC_APPLICATION_INDICATOR +1
             , SWTMDAC_APPLICATION_DATE = SYSDATE
             --,SWTMDAC_FLAG = NULL RLS20171204
             WHERE SWTMDAC_pidm = p_pidm
            and SWTMDAC_DETAIL_CODE_DESC = p_detail_code
            and SWTMDAC_SEC_PIDM = p_num_desc;
    Exception
    When Others then 
    vl_error:= ' Errror al Actualizar SWTMDAC  >>  ' || sqlerrm ;
    End;

                Select COUNT(*)
                Into vc_fuera_rango
                from SWTMDAC
                Where SWTMDAC_PIDM = p_pidm
                And SWTMDAC_DETAIL_CODE_ACC = p_detail_code
                and SWTMDAC_MASTER_IND = 'Y'
                And SWTMDAC_SEC_PIDM = p_num_desc
                and to_char(trunc(SYSDATE))  between trunc(SWTMDAC_EFFECTIVE_DATE_INI) and trunc(nvl(SWTMDAC_EFFECTIVE_DATE_FIN, SWTMDAC_EFFECTIVE_DATE_INI))
                and SWTMDAC_NUM_REAPPLICATION >=  SWTMDAC_APPLICATION_INDICATOR;
                

 END IF;

If vl_error = 'EXITO' then
   commit;
else 
 rollback;
End if;


End if;


Return vl_error;


Exception when others then
    vl_error:='Error PKG_SWTMDAC.sp_aplica_descuento '||sqlerrm;
    Return vl_error;
end sp_aplica_descuento_PV;



FUNCTION sp_verifica_existencia_ACCS (p_detail_code varchar2 )Return varchar2
 is
/*
verifica la existencia del concepto  de descuento en ZSTPARA en el agrupador  DESC_ACCS_V2

CRAETED OCT..

creacion : 011 -OCT- 2017
*/

p_detail_co varchar2(6);
vl_error varchar2(2500):='EXITO';

begin

        Begin 
                select  count(1)
                Into p_detail_co
                from ZSTPARA
                where ZSTPARA_MAPA_ID='DESC_ACCS_V2' 
                AND ZSTPARA_PARAM_ID=p_detail_code;
        Exception
        when Others then
         vl_error  := 'FALLO';
        End;
       
      If p_detail_co = '0'  then 
         vl_error := 'FALLO';
      End if;
        

 Return vl_error;

Exception
when Others then 
  vl_error :='Error General '||sqlerrm;
End sp_verifica_existencia_ACCS;

FUNCTION sp_verifica_existencia_IMPT (p_detail_code varchar2 )Return varchar2
 is
/*
verifica la existencia del concepto  de descuento en ZSTPARA en el agrupador  DESC_IMPT_V2

CRAETED OCT..

creacion : 011 -OCT- 2017
*/

p_detail_co varchar2(6);
vl_error varchar2(2500):='EXITO';

begin

        Begin 
                select  count(1)
                Into p_detail_co
                from ZSTPARA
                where ZSTPARA_MAPA_ID='DESC_IMPT_V2' 
                AND ZSTPARA_PARAM_ID=p_detail_code;
        Exception
        when Others then
         vl_error  := 'FALLO';
        End;
       
      If p_detail_co = '0'  then 
         vl_error := 'FALLO';
      End if;
        

 Return vl_error;

Exception
when Others then 
  vl_error :='Error General '||sqlerrm;



end sp_verifica_existencia_IMPT;

FUNCTION FN_INSRT_DSI  (P_MATRICULA IN  VARCHAR2, 
                        P_PERIODO  IN VARCHAR2,  
                        P_MONTO IN FLOAT , 
                        P_CODE_DETAIL  IN   VARCHAR2,
                        p_porcentaje IN NUMBER DEFAULT NULL
                         ) RETURN VARCHAR2
                                          
IS

VL_ENTRA NUMBER;
VL_DESC_DSI VARCHAR2(35);
VL_STUDY NUMBER;
VL_ERROR VARCHAR2(500):= 'EXITO';


BEGIN

    FOR X IN (
    
         SELECT SORLCUR_PIDM,SORLCUR_LEVL_CODE,SORLCUR_CAMP_CODE,SORLCUR_PROGRAM,SORLCUR_KEY_SEQNO
         FROM SORLCUR A 
         WHERE A.SORLCUR_LMOD_CODE = 'ADMISSIONS'
         AND A.SORLCUR_ROLL_IND  = 'N'
         AND A.SORLCUR_KEY_SEQNO = (SELECT MAX (A1.SORLCUR_KEY_SEQNO)
                                    FROM SORLCUR A1
                                    WHERE A1.SORLCUR_PIDM = A.SORLCUR_PIDM
                                    AND A1.SORLCUR_LMOD_CODE = A.SORLCUR_LMOD_CODE
                                    AND A1.SORLCUR_ROLL_IND = A.SORLCUR_ROLL_IND)
         AND A.SORLCUR_PIDM = FGET_PIDM(P_MATRICULA) 

                                    
  )LOOP  
  
    IF X.SORLCUR_KEY_SEQNO IS NULL THEN
    
        VL_STUDY:=1;
        
    ELSE
    
        VL_STUDY:= X.SORLCUR_KEY_SEQNO;
        
    END IF;
  
    BEGIN
    
         SELECT COUNT(TZTDMTO_DESC_CODE)
         INTO VL_ENTRA
         FROM TZTDMTO
         WHERE TZTDMTO_PIDM = X.SORLCUR_PIDM
         AND TZTDMTO_NIVEL = X.SORLCUR_LEVL_CODE
         AND TZTDMTO_CAMP_CODE = X.SORLCUR_CAMP_CODE
         AND TZTDMTO_PROGRAMA = X.SORLCUR_PROGRAM
         AND TZTDMTO_STUDY_PATH = VL_STUDY
         AND TZTDMTO_TERM_CODE = P_PERIODO
         ;
         
    EXCEPTION
    WHEN OTHERS THEN
    VL_ENTRA:= 0;     
    END;                                  
                                    
    IF VL_ENTRA = 0 THEN
    
        BEGIN
        
            SELECT TBBDETC_DESC
            INTO VL_DESC_DSI
            FROM TBBDETC
            WHERE TBBDETC_DETAIL_CODE = P_CODE_DETAIL
            ;
        
        END;

        BEGIN
        
            INSERT 
            INTO TZTDMTO 
            VALUES(P_MATRICULA, 
            X.SORLCUR_PIDM, 
            X.SORLCUR_CAMP_CODE,
            X.SORLCUR_LEVL_CODE, 
            X.SORLCUR_PROGRAM, 
            P_PERIODO,
            P_CODE_DETAIL, 
            NULL, 
            P_MONTO, 
            VL_STUDY, 
            1, 
            SYSDATE, 
            VL_DESC_DSI,
            p_porcentaje);                      -- OMS 11/Sep/2023 (Se agrego una nueva columna (TZTDMTO_PORCENTAJE_ECONTINUA)
        EXCEPTION
        WHEN OTHERS THEN
        VL_ERROR:= 'ERROR AL INSERTAR EN TZTDMTO  '||SQLERRM;    
        END;
    
    ELSE
    
        UPDATE TZTDMTO
        SET TZTDMTO_MONTO = P_MONTO,
            TZTDMTO_PORCENTAJE_ECONTINUA = p_porcentaje
        WHERE TZTDMTO_PIDM = X.SORLCUR_PIDM
        AND TZTDMTO_NIVEL = X.SORLCUR_LEVL_CODE
        AND TZTDMTO_CAMP_CODE = X.SORLCUR_CAMP_CODE
        AND TZTDMTO_PROGRAMA = X.SORLCUR_PROGRAM
        AND TZTDMTO_STUDY_PATH = VL_STUDY
        AND TZTDMTO_TERM_CODE = P_PERIODO 
        ;

    
    END IF;

    

  END LOOP;

COMMIT;

RETURN VL_ERROR;

END FN_INSRT_DSI;

FUNCTION F_APLICA_MASIVO (P_PIDM        NUMBER, 
                          P_NUM_TRAN    NUMBER, ---TBRACCD_TRAN_NUMBER
                          P_DETAIL_CODE VARCHAR2, --C?IGO ACCESORIO
                          P_MONTO       NUMBER,  
                          P_USER        VARCHAR2,
                          P_ARCHIVO     VARCHAR2,
                          P_VIGENCIA    DATE,
                          P_FOLIO       VARCHAR2 )RETURN VARCHAR2
 IS
/*
Funci??reada para realizar los ajustes massivos enviados desde SIU
CRAETED Reza..
LAST MODIFY: 16/03/2021 -- SE AGREGA FUNCIONALIDAD PARA APLICAR DISTRIBUCION DE SALDOS 
*/

VL_DETAIL_DESC      VARCHAR2(100);
VL_NUM_TRAN_MAX     NUMBER:=0;
V_MONEDA            VARCHAR2(5);
VL_ERROR            VARCHAR2(2500):= 'No existe el numero de transaccion '||P_NUM_TRAN;
VL_TIPO             VARCHAR2(2);
VL_PERIODO          VARCHAR2(7);
VL_DETAIL_INS       VARCHAR2(5);
VL_SUMA             NUMBER;
VL_MONTO_ORIG       NUMBER;
VL_COD_CORRECTO     VARCHAR2(5);
VL_CSH              NUMBER;
VL_CAMPUS           VARCHAR2(2);
Vm_Contador         NUMBER;
vl_monto_aplica     number;

 BEGIN

    vl_monto_aplica:= round(p_monto);											

   VL_PERIODO:= FGET_PERIODO_GENERAL(SUBSTR(P_DETAIL_CODE,1,2),TO_CHAR(SYSDATE,'DD/MM/YYYY'));

   IF P_VIGENCIA IS NULL AND P_FOLIO IS NULL THEN

     IF P_NUM_TRAN IS NOT NULL THEN

         FOR X IN ( 

                   SELECT*
                     FROM TBRACCD
                    WHERE     TBRACCD_PIDM = P_PIDM
                          AND TBRACCD_TRAN_NUMBER = P_NUM_TRAN

       )LOOP 

         VL_ERROR:= NULL;
         VL_DETAIL_INS:= NULL;
         VL_NUM_TRAN_MAX:=NULL;
         VL_DETAIL_DESC:= NULL;
         VL_TIPO:=NULL;
         VL_SUMA:=NULL;

         -- Valida si es la versi n 2 del proceso
         IF SUBSTR (P_ARCHIVO,3,2) = 'V2' THEN
            VL_DETAIL_INS := P_DETAIL_CODE;

         ELSE
            -- Version 1 del proceso
            BEGIN
               SELECT ZSTPARA_PARAM_VALOR
                 INTO VL_DETAIL_INS
                 FROM ZSTPARA
                WHERE ZSTPARA_MAPA_ID = 'MAS_AJUSTE'
                  AND SUBSTR(ZSTPARA_PARAM_ID,1,4) = P_ARCHIVO       -- 'BECA'
                  AND SUBSTR(ZSTPARA_PARAM_ID,5,4) = P_DETAIL_CODE;  -- OMS 20/Junio/2024

             EXCEPTION 
                 WHEN OTHERS THEN 
                     VL_DETAIL_INS := NULL;   -- OMS 1/Julio/2024
              END;
         END IF; -- Valida version 2 del proceso
         DBMS_OUTPUT.PUT_LINE('Entra 1 --- '||VL_DETAIL_INS);

         IF VL_DETAIL_INS IS NULL THEN
           VL_ERROR:= 'No hay configuraci??n SZFPARA para Archivo '||P_ARCHIVO||' y C??o detalle '||P_DETAIL_CODE;
         ELSE

           BEGIN
             SELECT NVL(SUM (TBRACCD_AMOUNT),0)
               INTO VL_SUMA
               FROM TBRACCD A
              WHERE     A.TBRACCD_PIDM = P_PIDM
                    AND A.TBRACCD_TRAN_NUMBER IN (SELECT A1.TBRACCD_TRAN_NUMBER
                                                    FROM TBRACCD A1
                                                   WHERE     A1.TBRACCD_PIDM = A.TBRACCD_PIDM
                                                         AND A1.TBRACCD_TRAN_NUMBER_PAID = P_NUM_TRAN);
           EXCEPTION
           WHEN OTHERS THEN
           VL_SUMA:=0;                                    
           END;

           BEGIN
             SELECT TBRACCD_AMOUNT
               INTO VL_MONTO_ORIG
               FROM TBRACCD A
              WHERE     A.TBRACCD_PIDM = P_PIDM
                    AND A.TBRACCD_TRAN_NUMBER = P_NUM_TRAN;
           EXCEPTION
           WHEN OTHERS THEN
           VL_MONTO_ORIG:=0;                                    
           END;

           BEGIN
             SELECT TBRACCD_DETAIL_CODE
               INTO VL_COD_CORRECTO
               FROM TBRACCD A
              WHERE     A.TBRACCD_PIDM = P_PIDM
                    AND A.TBRACCD_TRAN_NUMBER = P_NUM_TRAN;                   
           EXCEPTION
           WHEN OTHERS THEN
           VL_COD_CORRECTO:= NULL;                                    
           END;

           IF VL_COD_CORRECTO != P_DETAIL_CODE AND SUBSTR (P_ARCHIVO,3,2) != 'V2' THEN       -- OMS 02/Julio/2024

             VL_ERROR:= 'C??o incorrecto, C??o Edo Cuenta = '||VL_COD_CORRECTO||', C??o de ajuste = '||P_DETAIL_CODE;

           ELSIF SUBSTR (P_ARCHIVO,3,2) = 'V2' OR VL_COD_CORRECTO = P_DETAIL_CODE THEN      -- OMS 02/Julio/2024

           DBMS_OUTPUT.PUT_LINE('Entra 2 --- '||VL_SUMA||'-----'||P_MONTO||'------'||VL_MONTO_ORIG);

             IF (VL_SUMA+P_MONTO) > VL_MONTO_ORIG THEN

             VL_ERROR:= 'El monto total de ajustes es mayor al original, Total Ajustes = '||(VL_SUMA+P_MONTO)||', Monto Transaccion = '||VL_MONTO_ORIG;

             ELSE

               BEGIN
                 SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0)+ 1
                   INTO VL_NUM_TRAN_MAX
                   FROM TBRACCD
                  WHERE TBRACCD_PIDM = P_PIDM;             
               EXCEPTION 
               WHEN OTHERS THEN 
               VL_ERROR := 'Error al obtener valor maximo' ||SQLERRM;
               END;

               BEGIN 
                 SELECT TVRDCTX_CURR_CODE
                   INTO V_MONEDA
                   FROM TAISMGR.TVRDCTX
                  WHERE TVRDCTX_DETC_CODE  = VL_DETAIL_INS;         
               EXCEPTION 
               WHEN OTHERS THEN 
               V_MONEDA  := 'MXN'; 
               END;

               BEGIN 
                 SELECT TBBDETC_DESC,TBBDETC_TYPE_IND
                   INTO VL_DETAIL_DESC,VL_TIPO 
                   FROM TBBDETC 
                  WHERE TBBDETC_DETAIL_CODE = VL_DETAIL_INS;         
               EXCEPTION 
               WHEN OTHERS THEN 
               VL_ERROR := 'Error al obtener descripcin del codigo de detalle 01 ' ||SQLERRM;
               END;

               PKG_FINANZAS.P_DESAPLICA_PAGOS (P_PIDM, P_NUM_TRAN) ;

               DBMS_OUTPUT.PUT_LINE('Entra VL_PERIODO --- '||VL_PERIODO||' - '||VL_TIPO);

               IF VL_TIPO = 'P' THEN

                 BEGIN 

                  INSERT INTO TBRACCD 
                              (TBRACCD_PIDM, 
                              TBRACCD_TRAN_NUMBER, 
                              TBRACCD_TERM_CODE, 
                              TBRACCD_DETAIL_CODE, 
                              TBRACCD_USER, 
                              TBRACCD_ENTRY_DATE, 
                              TBRACCD_AMOUNT, 
                              TBRACCD_BALANCE,
                              TBRACCD_EFFECTIVE_DATE, 
                              TBRACCD_DESC, 
                              TBRACCD_ACTIVITY_DATE, 
                              TBRACCD_TRANS_DATE, 
                              TBRACCD_DATA_ORIGIN, 
                              TBRACCD_CREATE_SOURCE,
                              TBRACCD_SRCE_CODE , 
                              TBRACCD_ACCT_FEED_IND, 
                              TBRACCD_SESSION_NUMBER,
                              TBRACCD_CROSSREF_NUMBER, 
                              TBRACCD_CURR_CODE,
                              TBRACCD_TRAN_NUMBER_PAID, 
                              TBRACCD_DOCUMENT_NUMBER,
                              TBRACCD_FEED_DATE,
                              TBRACCD_STSP_KEY_SEQUENCE,
                              TBRACCD_PERIOD,
                              TBRACCD_RECEIPT_NUMBER)
                  VALUES 
                         (P_PIDM, 
                          VL_NUM_TRAN_MAX, 
                          VL_PERIODO, 
                          VL_DETAIL_INS, 
                          P_USER, 
                          SYSDATE, 
                          vl_monto_aplica, 
                          (vl_monto_aplica)*-1 , 
                          TRUNC(SYSDATE), 
                          VL_DETAIL_DESC, 
                          SYSDATE, 
                          SYSDATE, 
                          'MASIVOS',
                          'AD', 
                          'T' , 
                          'Y',
                          0 ,
                          NULL, 
                          V_MONEDA,
                          P_NUM_TRAN, 
                          'MASIVO',
                          X.TBRACCD_FEED_DATE,
                          X.TBRACCD_STSP_KEY_SEQUENCE,
                          X.TBRACCD_PERIOD,
                          X.TBRACCD_RECEIPT_NUMBER);

                 EXCEPTION
                 WHEN OTHERS THEN  
                     VL_ERROR :=' Errror al Insertar el descuento>>  ' || SQLERRM ;
                 END;

               ELSIF VL_TIPO = 'C' THEN

                 BEGIN 

                  INSERT INTO TBRACCD 
                              (TBRACCD_PIDM, 
                              TBRACCD_TRAN_NUMBER, 
                              TBRACCD_TERM_CODE, 
                              TBRACCD_DETAIL_CODE, 
                              TBRACCD_USER, 
                              TBRACCD_ENTRY_DATE, 
                              TBRACCD_AMOUNT, 
                              TBRACCD_BALANCE,
                              TBRACCD_EFFECTIVE_DATE, 
                              TBRACCD_DESC, 
                              TBRACCD_ACTIVITY_DATE, 
                              TBRACCD_TRANS_DATE, 
                              TBRACCD_DATA_ORIGIN, 
                              TBRACCD_CREATE_SOURCE,
                              TBRACCD_SRCE_CODE , 
                              TBRACCD_ACCT_FEED_IND, 
                              TBRACCD_SESSION_NUMBER,
                              TBRACCD_CROSSREF_NUMBER, 
                              TBRACCD_CURR_CODE,
                              TBRACCD_TRAN_NUMBER_PAID, 
                              TBRACCD_DOCUMENT_NUMBER,
                              TBRACCD_FEED_DATE,
                              TBRACCD_STSP_KEY_SEQUENCE,
                              TBRACCD_PERIOD,
                              TBRACCD_RECEIPT_NUMBER)
                  VALUES 
                         (P_PIDM, 
                          VL_NUM_TRAN_MAX, 
                          VL_PERIODO, 
                          VL_DETAIL_INS, 
                          P_USER, 
                          SYSDATE, 
                          vl_monto_aplica, 
                          vl_monto_aplica, 
                          TRUNC(SYSDATE), 
                          VL_DETAIL_DESC, 
                          SYSDATE, 
                          SYSDATE, 
                          'MASIVOS',
                          'AD', 
                          'T' , 
                          'Y',
                          0 ,
                          NULL, 
                          V_MONEDA,
                          P_NUM_TRAN, 
                          'MASIVO',
                          X.TBRACCD_FEED_DATE,
                          X.TBRACCD_STSP_KEY_SEQUENCE,
                          X.TBRACCD_PERIOD,
                          X.TBRACCD_RECEIPT_NUMBER);

                 EXCEPTION
                 WHEN OTHERS THEN  
                     VL_ERROR :=' Errror al Insertar el descuento>>  ' || SQLERRM ;
                 END;

               END IF;

               DBMS_OUTPUT.PUT_LINE('Entra VL_ERROR --- '||VL_ERROR);

             END IF; 

           END IF;

         END IF;

          DBMS_OUTPUT.PUT_LINE('FINAL VL_ERROR --- '||VL_ERROR);

       END LOOP;


     ELSIF P_NUM_TRAN IS NULL THEN

       BEGIN
         SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0)+ 1
           INTO VL_NUM_TRAN_MAX
           FROM TBRACCD WHERE TBRACCD_PIDM = P_PIDM;           
       EXCEPTION 
       WHEN OTHERS THEN 
       VL_ERROR := 'Error al obtener valor maximo' ||SQLERRM;
       END;

       BEGIN 
         SELECT TVRDCTX_CURR_CODE
           INTO V_MONEDA
           FROM TAISMGR.TVRDCTX WHERE TVRDCTX_DETC_CODE  = P_DETAIL_CODE;       
       EXCEPTION 
       WHEN OTHERS THEN 
       V_MONEDA  := 'MXN'; 
       END;

       BEGIN 
         SELECT TBBDETC_DESC,TBBDETC_TYPE_IND
           INTO VL_DETAIL_DESC,VL_TIPO 
           FROM TBBDETC WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CODE;                    
       EXCEPTION 
       WHEN OTHERS THEN 
       VL_ERROR := 'Error al obtener descripcin del codigo de detalle 02 ' ||SQLERRM;
       END;

       BEGIN 
         SELECT COUNT(*)
           INTO VL_CSH 
           FROM TBBDETC 
           WHERE TBBDETC_DETAIL_CODE = P_DETAIL_CODE
           AND (TBBDETC_DESC LIKE 'S %' OR TBBDETC_DESC LIKE 'H %');                    
       EXCEPTION 
       WHEN OTHERS THEN 
       VL_ERROR := 'Error al obtener descripcin del codigo de detalle 03 ' ||SQLERRM;
       END;

       IF VL_CSH > 0 THEN 

        VL_ERROR:= 'No se pueden aplicar ajustes tipo CSH de forma masiva';

       ELSE 

        VL_ERROR:= NULL;

         IF VL_TIPO = 'P' THEN

           BEGIN 

            INSERT INTO TBRACCD 
                        (TBRACCD_PIDM, 
                        TBRACCD_TRAN_NUMBER, 
                        TBRACCD_TERM_CODE, 
                        TBRACCD_DETAIL_CODE, 
                        TBRACCD_USER, 
                        TBRACCD_ENTRY_DATE, 
                        TBRACCD_AMOUNT, 
                        TBRACCD_BALANCE,
                        TBRACCD_EFFECTIVE_DATE, 
                        TBRACCD_DESC, 
                        TBRACCD_ACTIVITY_DATE, 
                        TBRACCD_TRANS_DATE, 
                        TBRACCD_DATA_ORIGIN, 
                        TBRACCD_CREATE_SOURCE,
                        TBRACCD_SRCE_CODE , 
                        TBRACCD_ACCT_FEED_IND, 
                        TBRACCD_SESSION_NUMBER,
                        TBRACCD_CROSSREF_NUMBER, 
                        TBRACCD_CURR_CODE,
                        TBRACCD_TRAN_NUMBER_PAID, 
                        TBRACCD_DOCUMENT_NUMBER,
                        TBRACCD_FEED_DATE,
                        TBRACCD_STSP_KEY_SEQUENCE,
                        TBRACCD_PERIOD,
                        TBRACCD_RECEIPT_NUMBER)
            VALUES 
                   (P_PIDM, 
                    VL_NUM_TRAN_MAX, 
                    VL_PERIODO, 
                    P_DETAIL_CODE, 
                    P_USER, 
                    SYSDATE, 
                    vl_monto_aplica,  
                    (vl_monto_aplica)*-1 , 
                    TRUNC(SYSDATE), 
                    VL_DETAIL_DESC, 
                    SYSDATE, 
                    SYSDATE, 
                    'MASIVOS',
                    'AD', 
                    'T' , 
                    'Y',
                    0 ,
                    NULL, 
                    V_MONEDA,
                    NULL, 
                    'MASIVO',
                    NULL,
                    NULL,
                    NULL,
                    NULL);

           EXCEPTION
           WHEN OTHERS THEN  
               VL_ERROR :=' Errror al Insertar el descuento>>  ' || SQLERRM ;
           END;


         ELSIF VL_TIPO = 'C' THEN

           BEGIN 

            INSERT INTO TBRACCD 
                        (TBRACCD_PIDM, 
                        TBRACCD_TRAN_NUMBER, 
                        TBRACCD_TERM_CODE, 
                        TBRACCD_DETAIL_CODE, 
                        TBRACCD_USER, 
                        TBRACCD_ENTRY_DATE, 
                        TBRACCD_AMOUNT, 
                        TBRACCD_BALANCE,
                        TBRACCD_EFFECTIVE_DATE, 
                        TBRACCD_DESC, 
                        TBRACCD_ACTIVITY_DATE, 
                        TBRACCD_TRANS_DATE, 
                        TBRACCD_DATA_ORIGIN, 
                        TBRACCD_CREATE_SOURCE,
                        TBRACCD_SRCE_CODE , 
                        TBRACCD_ACCT_FEED_IND, 
                        TBRACCD_SESSION_NUMBER,
                        TBRACCD_CROSSREF_NUMBER, 
                        TBRACCD_CURR_CODE,
                        TBRACCD_TRAN_NUMBER_PAID, 
                        TBRACCD_DOCUMENT_NUMBER,
                        TBRACCD_FEED_DATE,
                        TBRACCD_STSP_KEY_SEQUENCE,
                        TBRACCD_PERIOD,
                        TBRACCD_RECEIPT_NUMBER)
            VALUES 
                   (P_PIDM, 
                    VL_NUM_TRAN_MAX, 
                    VL_PERIODO, 
                    P_DETAIL_CODE, 
                    P_USER, 
                    SYSDATE, 
                    vl_monto_aplica, 
                    vl_monto_aplica, 
                    TRUNC(SYSDATE), 
                    VL_DETAIL_DESC, 
                    SYSDATE, 
                    SYSDATE, 
                    'MASIVOS',
                    'AD', 
                    'T' , 
                    'Y',
                    0 ,
                    NULL, 
                    V_MONEDA,
                    NULL, 
                    'MASIVO',
                    NULL,
                    NULL,
                    NULL,
                    NULL);

           EXCEPTION
           WHEN OTHERS THEN  
               VL_ERROR :=' Errror al Insertar el descuento>>  ' || SQLERRM ;
           END;

         END IF;


       END IF;

       DBMS_OUTPUT.PUT_LINE('Entra VL_ERROR --- '||VL_ERROR);


     END IF;

   ELSIF P_VIGENCIA IS NOT NULL AND P_FOLIO IS NOT NULL THEN

     VL_ERROR:=NULL; 

     BEGIN
       SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0)+ 1
         INTO VL_NUM_TRAN_MAX
         FROM TBRACCD WHERE TBRACCD_PIDM = P_PIDM;           
     EXCEPTION 
     WHEN OTHERS THEN 
     VL_ERROR := 'Error al obtener valor maximo' ||SQLERRM;
     END;

     BEGIN
       SELECT SUBSTR(SPRIDEN_ID,1,2)
         INTO VL_CAMPUS
         FROM SPRIDEN
        WHERE     SPRIDEN_CHANGE_IND IS NULL
              AND SPRIDEN_PIDM = P_PIDM;
     EXCEPTION
     WHEN OTHERS THEN
     VL_CAMPUS:='00';  
     END;

     BEGIN 
       SELECT TVRDCTX_CURR_CODE
         INTO V_MONEDA
         FROM TAISMGR.TVRDCTX WHERE TVRDCTX_DETC_CODE  = VL_CAMPUS||SUBSTR(P_DETAIL_CODE,3,2);       
     EXCEPTION 
     WHEN OTHERS THEN 
     V_MONEDA  := 'MXN'; 
     END;

     BEGIN 
       SELECT TBBDETC_DESC,TBBDETC_TYPE_IND
         INTO VL_DETAIL_DESC,VL_TIPO 
         FROM TBBDETC WHERE TBBDETC_DETAIL_CODE = VL_CAMPUS||SUBSTR(P_DETAIL_CODE,3,2);                    
     EXCEPTION 
     WHEN OTHERS THEN 
     VL_ERROR := 'Error al obtener descripcin del codigo de detalle 04 ' ||SQLERRM;
     END;

     BEGIN 
       SELECT COUNT(*)
         INTO VL_CSH 
         FROM TBBDETC 
        WHERE      TBBDETC_DETAIL_CODE = VL_CAMPUS||SUBSTR(P_DETAIL_CODE,3,2)
              AND (TBBDETC_DESC LIKE 'S %' OR TBBDETC_DESC LIKE 'H %')
              AND TBBDETC_DETAIL_CODE NOT IN (SELECT DISTINCT TZTNCD_CODE
                                            FROM TZTNCD
                                           WHERE TZTNCD_CONCEPTO = 'Nota Distribucion'
                                                 AND OPERA = 'RESTA'
                                                 AND TZTNCD_DESCP LIKE '%EFECTIVO%');                    
     EXCEPTION 
     WHEN OTHERS THEN 
     VL_ERROR := 'Error al obtener descripcin del codigo de detalle 05' ||SQLERRM;
     END;

     IF VL_CSH > 0 THEN 

      VL_ERROR:= 'No se pueden aplicar ajustes tipo CSH de forma masiva';

     ELSE 

       IF VL_TIPO IS NULL THEN 
           VL_ERROR := 'Error al obtener descripcin del codigo de detalle, no existe! ' ||SQLERRM;
       ELSIF VL_TIPO = 'P' THEN

         BEGIN 

          INSERT INTO TBRACCD 
                      (TBRACCD_PIDM, 
                      TBRACCD_TRAN_NUMBER, 
                      TBRACCD_TERM_CODE, 
                      TBRACCD_DETAIL_CODE, 
                      TBRACCD_USER, 
                      TBRACCD_ENTRY_DATE, 
                      TBRACCD_AMOUNT, 
                      TBRACCD_BALANCE,
                      TBRACCD_EFFECTIVE_DATE, 
                      TBRACCD_DESC, 
                      TBRACCD_ACTIVITY_DATE, 
                      TBRACCD_TRANS_DATE, 
                      TBRACCD_DATA_ORIGIN, 
                      TBRACCD_CREATE_SOURCE,
                      TBRACCD_SRCE_CODE , 
                      TBRACCD_ACCT_FEED_IND, 
                      TBRACCD_SESSION_NUMBER,
                      TBRACCD_CROSSREF_NUMBER, 
                      TBRACCD_CURR_CODE,
                      TBRACCD_TRAN_NUMBER_PAID, 
                      TBRACCD_DOCUMENT_NUMBER,
                      TBRACCD_FEED_DATE,
                      TBRACCD_STSP_KEY_SEQUENCE,
                      TBRACCD_PERIOD,
                      TBRACCD_RECEIPT_NUMBER)
          VALUES 
                 (P_PIDM, 
                  VL_NUM_TRAN_MAX, 
                  VL_PERIODO, 
                  VL_CAMPUS||SUBSTR(P_DETAIL_CODE,3,2), 
                  P_USER, 
                  SYSDATE, 
                  vl_monto_aplica, 
                  (vl_monto_aplica)*-1 , 
                  TRUNC(SYSDATE), 
                  VL_DETAIL_DESC, 
                  SYSDATE, 
                  P_VIGENCIA, 
                  'MASIVOS',
                  'AD', 
                  'T' , 
                  'Y',
                  0 ,
                  NULL, 
                  V_MONEDA,
                  NULL, 
                  P_FOLIO,
                  NULL,
                  NULL,
                  NULL,
                  NULL);

         EXCEPTION
         WHEN OTHERS THEN  
             VL_ERROR :=' Errror al Insertar el descuento>>  ' || SQLERRM ;
         END;

       ELSIF VL_TIPO = 'C' THEN

         BEGIN 


          INSERT INTO TBRACCD 
                      (TBRACCD_PIDM, 
                      TBRACCD_TRAN_NUMBER, 
                      TBRACCD_TERM_CODE, 
                      TBRACCD_DETAIL_CODE, 
                      TBRACCD_USER, 
                      TBRACCD_ENTRY_DATE, 
                      TBRACCD_AMOUNT, 
                      TBRACCD_BALANCE,
                      TBRACCD_EFFECTIVE_DATE, 
                      TBRACCD_DESC, 
                      TBRACCD_ACTIVITY_DATE, 
                      TBRACCD_TRANS_DATE, 
                      TBRACCD_DATA_ORIGIN, 
                      TBRACCD_CREATE_SOURCE,
                      TBRACCD_SRCE_CODE , 
                      TBRACCD_ACCT_FEED_IND, 
                      TBRACCD_SESSION_NUMBER,
                      TBRACCD_CROSSREF_NUMBER, 
                      TBRACCD_CURR_CODE,
                      TBRACCD_TRAN_NUMBER_PAID, 
                      TBRACCD_DOCUMENT_NUMBER,
                      TBRACCD_FEED_DATE,
                      TBRACCD_STSP_KEY_SEQUENCE,
                      TBRACCD_PERIOD,
                      TBRACCD_RECEIPT_NUMBER)
          VALUES 
                 (P_PIDM, 
                  VL_NUM_TRAN_MAX, 
                  VL_PERIODO, 
                  VL_CAMPUS||SUBSTR(P_DETAIL_CODE,3,2), 
                  P_USER, 
                  SYSDATE, 
                  vl_monto_aplica, 
                  vl_monto_aplica, 
                  TRUNC(SYSDATE), 
                  VL_DETAIL_DESC, 
                  SYSDATE, 
                  P_VIGENCIA, 
                  'MASIVOS',
                  'AD', 
                  'T' , 
                  'Y',
                  0 ,
                  NULL, 
                  V_MONEDA,
                  NULL, 
                  P_FOLIO,
                  NULL,
                  NULL,
                  NULL,
                  NULL);

         EXCEPTION
         WHEN OTHERS THEN  
             VL_ERROR :=' Errror al Insertar el descuento>>  ' || SQLERRM ;
         END;

       END IF;
     END IF; 
   END IF;

   IF VL_ERROR IS NULL THEN
     VL_ERROR:= 'EXITO';         
     COMMIT;            
   ELSE                 
     ROLLBACK;            
   END IF;

   DBMS_OUTPUT.PUT_LINE('FINAL VL_ERROR --- '||VL_ERROR);
 RETURN VL_ERROR;

 EXCEPTION WHEN OTHERS THEN
 VL_ERROR:='Error PKG_SWTMDAC.sp_aplica_descuento '||SQLERRM;
 RETURN VL_ERROR;
 END F_APLICA_MASIVO;



FUNCTION  fn_desc_pre_vta_masivos ( pmatricula varchar2, p_code_serv varchar2, p_percent number, p_amount  number,  
                                                      pfecha_ini varchar2, pfecha_fin varchar2,pnuevo varchar2
                                                       )   RETURN VARCHAR2  is


/*   este proceso se encarga de crear los registros de los descuentos por alumno pero del proceso que viene de siu de forma masiva es decir en siu suben un archivo 
layout y para cada alumno que venga en el archivo va insertando su descuento UNICAMENTE PRE-VENTA NIVELACION.. modify glovicx 27/04/2020 
*/
vnum_max        number:=0;
vdesc           varchar2(10);
VL_FECHA_INI     varchar2(60);
vl_error        varchar2(2500):= 'EXITO';
p_mind          varchar2(1) := 'Y';
p_detcode_acc2  VARCHAR2(6);
VNIVEL          VARCHAR2(6);
p_replica       number:=1; 
p_user          varchar2(30) := 'pmasivo' ;
p_usr_rol       number := 2;
vcode_desc2     varchar2(16);
VSALIDA2         varchar2(200):='EXITO';
vseq_no         number:= 0;
vestatus        varchar2(2);

BEGIN

--VL_FECHA_INI :=  to_char(pfecha_ini,'DD/MM/YYYY' );

dbms_output.put_line(' cambia las fech ainicial  '||   VL_FECHA_INI || '-'|| pfecha_fin || '-->>' ||pfecha_ini );

------desde aqui valida que no vengan porcentaje y monto llenos  
IF p_percent < 1 AND p_percent > 99 THEN
VSALIDA2:= 'SOLO APLICAR DESCUENTO PORCENTAJE DE 1-99%';
ELSE

select nvl(max(SWTMDAC_SEC_PIDM),0) 
into vnum_max
from SWTMDAC
where SWTMDAC_PIDM = fget_pidm(pmatricula);


   Begin         
            select distinct nivel , estatus
            into VNIVEL, vestatus
            from tztprog tz
            where 1=1
            and tz.matricula = pmatricula
            and tz.sp         = ( select max( tt.sp)  from tztprog tt
                                             where 1=1
                                               and  tz.matricula = tt.matricula); 
                       
            Exception
            when Others then  
            VNIVEL := null;
            vestatus  := null;
            VSALIDA2  := SUBSTR('error al obtener la informacion de SORLCUR-key_seq_no ' ||pmatricula|| sqlerrm,1,200);
            End;


     --   if p_detcode_acc is null  then 
          begin
          /* select DISTINCT SVRRSSO_DETL_CODE
          INTO p_detcode_acc2
          FROM SVRRSSO
            WHERE  1=1
              AND( SVRRSSO_VPDI_CODE  = VNIVEL
                    OR SVRRSSO_VPDI_CODE IS NULL  )
              AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(PMATRICULA,1,2)
              and SVRRSSO_SRVC_CODE =  p_code_serv ;  */
              
            select distinct (SVRRSSO_DETL_CODE)
              INTO p_detcode_acc2
                FROM SVRRSSO o, SVRRSRV r
                WHERE  1=1
                AND o.SVRRSSO_SRVC_CODE     = R.SVRRSRV_SRVC_CODE
                and O.SVRRSSO_RSRV_SEQ_NO   = R.SVRRSRV_SEQ_NO
                AND  SUBSTR(SVRRSSO_DETL_CODE,1,2)  = SUBSTR(PMATRICULA,1,2)
                and SVRRSSO_SRVC_CODE =  p_code_serv
                and r.SVRRSRV_LEVL_CODE = VNIVEL
                and R.SVRRSRV_STST_CODE = vestatus
                ; 
              
              
              
              
              
           Exception
            when Others then  
            p_detcode_acc2 := '';
            VSALIDA2  := SUBSTR( 'error al obtener la informacion codigo detalle' ||pmatricula|| sqlerrm,1,200);
            End;
     --   else

       
      --  end if;

/*             
cuando el descuento es por porcentaje se usa este
EXC_ACCS_V2

y cuando es por monto es este otro

CDN_ACCS_V2
*/
               -- dbms_output.put_line(' calcula codigos de detalle1:  '|| p_detcode_acc2 ||' NIVEL '|| VNIVEL ||' SERV  '|| p_code_serv||' MONTO '||p_amount||' PORC '|| p_percent||' f_ini '||pfecha_ini || ' f_ fin '|| pfecha_fin );
            IF  p_percent > 0  and ( p_amount = 0) THEN
            null;
                begin
                select distinct  ZSTPARA_PARAM_VALOR
                   INTO vcode_desc2
                from zstpara
                where  ZSTPARA_MAPA_ID in ('EXC_ACCS_V2')
                   and ZSTPARA_PARAM_ID  = p_detcode_acc2 ; --'01NW' es el codigo del accesorio
                 Exception   when Others then  
                vcode_desc2 := '';
                dbms_output.put_line('ERROR: NO SE PUEDE codigo  '|| pmatricula || '-'|| p_detcode_acc2 ||'-'|| vcode_desc2 );
                VSALIDA2  := SUBSTR( 'error al obtener PARATRIZADOR 1   ' ||pmatricula||'--'|| p_detcode_acc2||'-'|| sqlerrm,1,200);
                End;
                
                
              --dbms_output.put_line('PORCENTAJE  codigos de detalle1AA:  '|| p_detcode_acc2 || '-'|| p_percent ||'-'|| p_amount );
            ELSIF p_amount  >  0 and (p_percent is null OR p_percent = 0) THEN
            null;
             --dbms_output.put_line('MONTO  codigos de detalle2:  '|| p_detcode_acc2 || '-'|| p_percent ||'-'|| p_amount );
                BEGIN
                select distinct  ZSTPARA_PARAM_VALOR
                   INTO vcode_desc2
                from zstpara
                where  ZSTPARA_MAPA_ID in ('CDN_ACCS_V2')
                   and ZSTPARA_PARAM_ID  = p_detcode_acc2;  --'01NW' es el codigo del accesorio
                  
                  
                 Exception   when Others then  
                vcode_desc2 := '';
                dbms_output.put_line('ERROR: NO SE PUEDE codigo  '|| pmatricula || '-'|| p_detcode_acc2 ||'-'|| vcode_desc2 );
                --VSALIDA2  := SUBSTR( 'error al obtener PARATRIZADOR 2' ||pmatricula|| sqlerrm,1,200);
                End;
                
            ELSE
              --dbms_output.put_line('ERROR: NO SE PUEDE DEFINIR MONTO O PORCENTAJE  '|| pmatricula || '-'|| p_percent ||'-'|| p_amount );
            vcode_desc2  := '';
               VSALIDA2  :=  SUBSTR('ERROR: NO SE PUEDE DEFINIR MONTO O PORCENTAJE  '|| pmatricula || '-'|| p_percent ||'-'|| p_amount,1,200);
            END IF;

      dbms_output.put_line('fechas:  '|| p_mind ||'--'||p_detcode_acc2 ||'--'||p_percent ||'--'|| p_amount ||'--'|| vcode_desc2 ||'--'||
                to_char(to_date(pfecha_ini,'DD/MM/YYYY' )) ||'--'||
                to_char(to_date(pfecha_fin, 'DD/MM/YYYY')) ||'--'||
                p_replica  ||'--'||
                p_user  ||'--'|| 
                p_usr_rol);
  
    -----valida que no se guarden 2 veces el mismo secno--- glovicx 02/07/2020

        begin
              select count(1)
                 into vseq_no
               from SWTMDAC w
               where w.SWTMDAC_PIDM =  fget_pidm(pmatricula)
                and W.SWTMDAC_SEQNO_SERV  = vnum_max;
                
         Exception   When Others then 
         vseq_no:=0;
         End;
  --DBMS_OUTPUT.PUT_LINE(' SALIDA7 :::'|| VSALIDA2 );
    if vseq_no > 0 then 
    vnum_max := vnum_max + 1;
    end if; 
    
      DBMS_OUTPUT.PUT_LINE(' SALIDA8 :::'|| p_detcode_acc2|| '-'|| vcode_desc2 );
    IF p_detcode_acc2 IS NOT NULL AND vcode_desc2 IS NOT NULL THEN 
    
      BEGIN
       INSERT INTO SWTMDAC
                (SWTMDAC_PIDM,
                SWTMDAC_SEC_PIDM,
                SWTMDAC_MASTER_IND,
                SWTMDAC_DETAIL_CODE_ACC,
                SWTMDAC_PERCENT_DESC,
                SWTMDAC_AMOUNT_DESC,
                SWTMDAC_DETAIL_CODE_DESC,
                SWTMDAC_EFFECTIVE_DATE_INI,
                SWTMDAC_EFFECTIVE_DATE_FIN,
                SWTMDAC_NUM_REAPPLICATION,
                SWTMDAC_USER,
                SWTMDAC_USR_ROLE,
                SWTMDAC_ACTIVITY_DATE,
                SWTMDAC_APPLICATION_INDICATOR,
                SWTMDAC_APPLICATION_DATE,
                SWTMDAC_FLAG
                --,SWTMDAC_SEQNO_SERV
                 )
         VALUES(fget_pidm(pmatricula) ,
                vnum_max+1, 
                p_mind , 
                p_detcode_acc2 , 
                p_percent , 
                round(p_amount) , 
                vcode_desc2 ,
                to_char(to_date(pfecha_ini,'DD/MM/YYYY' )), 
                to_char(to_date(pfecha_fin, 'DD/MM/YYYY')), 
                p_replica , 
                p_user , 
                p_usr_rol, 
                sysdate, 
                0,
                null, 
                'Y'
                --,PNOSEQ 
                );
                
      exception when others then
        VSALIDA2  :=  SUBSTR('ERROR EL INSERTAR SWTMDAC:>> '|| sqlerrm,1,200);
         dbms_output.put_line('error al insertar en swtmdac'|| sqlerrm);
      
      end;

  END IF;

END IF;
 -- DBMS_OUTPUT.PUT_LINE(' SALIDA9 :::'|| VSALIDA2|| sysdate );
---COMMIT;

    IF VSALIDA2 = 'EXITO'  THEN 
      --  DBMS_OUTPUT.PUT_LINE(' SALIDA EXITO SE INSERTA BIEN DESCUENTO');
   -- VSALIDA := VSALIDA2;
    COMMIT;
      RETURN (VSALIDA2);
    ELSE
     --DBMS_OUTPUT.PUT_LINE(' SALIDA ERROR  NO  INSERTA  DESCUENTO');
    --VSALIDA :=  VSALIDA2;
    ROLLBACK;
        RETURN (SQLERRM);
    END IF;

exception when others then 
 VSALIDA2  :=  SUBSTR('ERRORxx '|| sqlerrm,1,200);
DBMS_OUTPUT.PUT_LINE('  ERROR  gral  DESCUENTO'|| VSALIDA2); 
end fn_desc_pre_vta_masivos;




FUNCTION f_obtiene_importe_transaccion (p_matricula     IN VARCHAR2, p_transaccion IN NUMBER,
                                        p_codigo_ajuste IN VARCHAR,  p_tipo        IN VARCHAR2,
                                        p_descuento     IN NUMBER,
                                        p_codigo_cargo  IN VARCHAR2  DEFAULT NULL,
                                        p_domiciliado   IN BOOLEAN)  RETURN SYS_REFCURSOR IS
-- Descripcion: Obtiene el importe (tbraccd_amount) correspondiente a la matricula/transaccion de la cartera

-- Variables
   Vm_Registros     SYS_REFCURSOR;	                        -- Registros recuperados en la consulta

   Vm_Importe           TBRACCD.tbraccd_amount%TYPE;
   Vm_Importe_Original  TBRACCD.tbraccd_amount%TYPE;
   Vm_Codigo            TBRACCD.tbraccd_detail_code%TYPE;
   Vm_Tipo              TBBDETC.tbbdetc_type_ind%TYPE;
   Vm_Categoria         TBBDETC.tbbdetc_dcat_code%TYPE;
   Vm_Mensaje           VARCHAR2 (2000);
   Vm_Contador          NUMBER;
   Vm_No_Etiquetas      NUMBER;

BEGIN

   -- V lida que el concepto de ajuste, corresponda a un PAGO   
   BEGIN
      Vm_Mensaje := NULL;
      SELECT Count(*)
        INTO Vm_Contador
        FROM tbbdetc b
       WHERE tbbdetc_detail_code = p_codigo_ajuste
         AND tbbdetc_type_ind    = 'P';

    EXCEPTION
         WHEN OTHERS THEN Vm_Contador := 0;
    END;

    IF NVL (Vm_Contador,0) = 0 THEN 
       Vm_Importe := NULL;           Vm_Codigo    := NULL;                   
       Vm_Mensaje := 'El concepto de AJUSTE no corresponde a un PAGO';
    END IF; -- Aborta la ejecuci n de la funci n

   -- V lida que el concepto de AJUSTE corresponda al campus del alumno
   IF Vm_Mensaje IS NULL AND SUBSTR (p_matricula,1,2) != SUBSTR (p_codigo_ajuste,1,2) THEN
      Vm_Mensaje := 'Revisar el concepto de ajuste no corresponde al campus de la matricula';
   END IF;


   -- V lida que el alumno tenga la etiqueta de DOMICILIACION
   IF Vm_Mensaje IS NULL AND p_domiciliado THEN
      BEGIN
        SELECT Count(*)
          INTO Vm_No_Etiquetas
          FROM goradid a
         WHERE a.goradid_pidm       = fget_pidm (p_matricula)
           AND a.goradid_adid_code IN ('DOL7','DOMI','DO02','DO03','DO05','DO07','DO10');


        -- Tiene Etiqueta de domiciliaci n
        IF NVL (Vm_No_Etiquetas,0) = 0 THEN
           Vm_Mensaje := 'El alumno no tiene ETIQUETA de domiciliaci n asociada';
        END IF;

      EXCEPTION WHEN OTHERS THEN 
                Vm_Mensaje := 'El alumno no tiene ETIQUETA de domiciliaci n asociada';
      END;
   END IF;

   -- Obtiene los datos asociados a: Matricula/Concepto/Transaccion
   IF Vm_Mensaje IS NULL THEN
      BEGIN
        SELECT tbraccd_amount   Importe, tbraccd_detail_code Codigo,
               tbbdetc_type_ind Tipo,    tbbdetc_dcat_code Categoria,
               NULL Mensaje 
          INTO Vm_Importe, Vm_Codigo, Vm_Tipo, Vm_Categoria, Vm_Mensaje
          FROM tbraccd a, tbbdetc b, tztncd c
         WHERE tbraccd_pidm          = fget_pidm (p_matricula)
           AND tbraccd_tran_number   = p_transaccion
           AND tbraccd_amount       != 0
           AND tbbdetc_detail_code   = tbraccd_detail_code
           AND tbbdetc_type_ind      = 'C'
           AND tztncd_code           = tbraccd_detail_code
           AND UPPER (tztncd_concepto) IN ('VENTA', 'NOTA DEBITO', 'INTERES');

      EXCEPTION
         WHEN OTHERS THEN
              Vm_Importe := NULL;          Vm_Codigo    := NULL;                   
              Vm_Mensaje := 'ERROR: El concepto ORIGEN asociado a la transaccion '   || p_transaccion || 
                         ' no cumple con los requisitos: ' || p_matricula  ;--||
              IF LENGTH (p_matricula) != 9 THEN
                 Vm_Mensaje := Vm_Mensaje || ' (' || LENGTH (p_matricula) || ' Caracteres)';
              END IF;
      END;
   END IF; -- Mensaje IS NULL

   -- V lida condiciones del importe que se genera
   IF Vm_Mensaje IS NULL THEN
      Vm_Importe_Original := Vm_Importe;

      IF    UPPER (p_tipo) = 'MONTO'      THEN Vm_Importe := ROUND (p_descuento,0);
      ELSIF UPPER (p_tipo) = 'PORCENTAJE' THEN Vm_Importe := ROUND (Vm_Importe_Original * (p_Descuento/100),0);
      --ROUND (Vm_Importe_Original - (Vm_Importe_Original * (p_Descuento/100)),0); 
      ELSE  Vm_Mensaje    := 'Tipo de descuento INCORRECTO';
      END IF;

      -- V lida que no sea mayor que el importe Original
      IF Vm_Mensaje IS NULL THEN
         IF    Vm_Importe > Vm_Importe_Original OR Vm_Importe < 0 
                               THEN Vm_Mensaje := 'El importe/porcentaje calculado es MAYOR que el original del cargo';
         ELSIF Vm_Importe = 0  THEN Vm_Mensaje := 'El importe calculado es igual a CERO';
         END IF;
      END IF;
   END IF;

   --
   IF Vm_Mensaje IS NULL AND Vm_Codigo != p_codigo_cargo THEN
      Vm_Mensaje := 'El c digo de cargo del LAYOUT, no corresponde al c digo cargo de la CARTERA';
   END IF; -- C digo de cargo no corresponde al codigo del Layout


   -- Construye el cursor de salida  
   OPEN Vm_Registros FOR 
        SELECT Vm_Importe Vm_Importe, Vm_Codigo Vm_Codigo, Vm_Mensaje Vm_Mensaje
          FROM dual;

   RETURN Vm_Registros;

EXCEPTION 
   WHEN OTHERS THEN NULL;
        OPEN Vm_Registros FOR 
             SELECT Vm_Importe Vm_Importe, Vm_Codigo Vm_Codigo, Vm_Mensaje Vm_Mensaje
               FROM dual;

END f_obtiene_importe_transaccion;


END pkg_swtmdac;
/

DROP PUBLIC SYNONYM PKG_SWTMDAC;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SWTMDAC FOR BANINST1.PKG_SWTMDAC;


GRANT EXECUTE ON BANINST1.PKG_SWTMDAC TO CONSULTA;

GRANT EXECUTE ON BANINST1.PKG_SWTMDAC TO TAISMGR;
