DROP PACKAGE BODY BANINST1.PKG_SOLSERV;

CREATE OR REPLACE PACKAGE BODY BANINST1.pkg_solserv is
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 -- Author : glovicx
 -- Created : 25.Nov.2015
 -- Purpose : Pkt con las Utilerias para la administracion del
 ----- pago mediante el SSB  las solicitudes del servicio
 -----se le agregaron estas 3 columnas el insert de tbra van nulas para que el trigger de reza llene estos campos---
 ---glovicx  27 oct 2018
 --nueva modificacion  26/03/2020  glovicx
 --nuevo cambio   12/05/2020    glovicx
 --se anexa  la bitacora de descuentos para tener mas control glovicx 16/07/2020 glovicx..
 -- se agrega el nuevo cursor para los accesorios que tengan un envio internacional los pueda separar glovicx 28/07/2021
---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

vmsjerror           varchar2(2000); 
curr_release        VARCHAR2 (10) := '8.5.4.4';
err_num             varchar2(250);
err_msg             varchar2(250);
vsalida             VARCHAR(100);
vid_u               VARCHAR2(9);
vpidm               INTEGER(8);
p_pidm              INTEGER(8);
vpidm2              INTEGER(8);
vstatus             varchar2(18);
vnum_sal            NUMBER(3);
vlast_acces         VARCHAR2(50); 
vperiodo            VARCHAR2(15); 
vdocu               VARCHAR2(5); 
VESTUD              VARCHAR(10);
VFACULT             VARCHAR(10);
VEMPLOY             VARCHAR(10);
VALUMNI             VARCHAR(10);
VFINANC             VARCHAR(10);
VFRIEND             VARCHAR(10);
VFINAID             VARCHAR(10);
vnombre             VARCHAR2(250); 
vapellidos          VARCHAR2(250); 
vmail               VARCHAR(50);
vid                 INTEGER(8);
vcamp               varchar2(4);
vurl_env            varchar2(3000);
vseq_p              number:=0;

procedure  sp_simoba  ( p_protocol_seq_num_in  IN  SVRSVPR.SVRSVPR_PROTOCOL_SEQ_NO%TYPE DEFAULT NULL,
                              p_return_url           IN  VARCHAR2  DEFAULT NULL,
                              p_message              IN  VARCHAR2  DEFAULT NULL,
                              p_pidm                    IN VARCHAR2
                            ) is  


vl_ruta        varchar2(250);
vl_puerto    varchar2(250);
vl_instancia varchar2(250);
vl_pagos     varchar2(250);
vl_admi       varchar2(250); 

------AQUI regresa la ultima vez que entro al sistema -----  
CURSOR C_ACESSO(vpidm VARCHAR2)   IS
---SELECT DBMS_XMLGEN.getXML ('
SELECT
    TO_CHAR (
        TWGBWSES_LAST_ACCESS,
        'DD-MON-YYYY HH24:MI:SS'
    ) AS ultimo_acceso,
    SP.SPRIDEN_FIRST_NAME,
    SP.SPRIDEN_LAST_NAME,
    SP.SPRIDEN_ID,
    SP.SPRIDEN_PIDM
FROM
    SPRIDEN SP
left join TWGBWSES WS on ws.TWGBWSES_PIDM = SP.SPRIDEN_PIDM
WHERE
    SP.SPRIDEN_PIDM = vpidm;
----' ||vpidm) as resultxm  from dual  ; 


lv_protocol_rec    sv_protocol.protocol_rec;
  lv_protocol_ref    sv_protocol.protocol_ref;
  
begin
-------------------esta parte es muy importante por que aqui trae el registro con todos los datos del alumno para hacer el pago de la tabla SVRSVPR 
if p_protocol_seq_num_in > 0 then
 lv_protocol_ref:= sv_protocol.f_query_one (p_protocol_seq_no => p_protocol_seq_num_in);
  FETCH lv_protocol_ref INTO lv_protocol_rec;
  CLOSE lv_protocol_ref;

vpidm   :=   lv_protocol_rec.r_pidm;  --------------------------regresar-----------------
vseq_p  := lv_protocol_rec.r_protocol_seq_no;

else
  
vpidm   :=   p_pidm;  --------------------------regresar-----------------
vseq_p  :=  p_protocol_seq_num_in ;

end if;

----------------------- Se toma el parametro para la URL -----------------------------
Begin
    select lower(ZSTPARA_PARAM_VALOR)
    Into vl_ruta
    from ZSTPARA
    where ZSTPARA_MAPA_ID = 'PAGOS_SSB'
    And ZSTPARA_PARAM_ID = 'SERVIDOR';
Exception
When Others then 
    vl_ruta :=0;
end;

----------------------- Se toma el parametro para el puerto -----------------------------
Begin
    select ZSTPARA_PARAM_VALOR
    Into vl_puerto
    from ZSTPARA
    where ZSTPARA_MAPA_ID = 'PAGOS_SSB'
    And ZSTPARA_PARAM_ID = 'PUERTO';
Exception
When Others then 
    vl_puerto :=0;
end;

----------------------- Se toma el parametro para el  dashboard de pagos-----------------------------
Begin
    select lower(ZSTPARA_PARAM_VALOR)
    Into vl_pagos
    from ZSTPARA
    where ZSTPARA_MAPA_ID = 'PAGOS_SSB'
    And ZSTPARA_PARAM_ID = 'DB_PAGOS';
Exception
When Others then 
    vl_pagos :=0;
end;

----------------------- Se toma el parametro para el  dashboard de admisiones -----------------------------
Begin
    select lower(ZSTPARA_PARAM_VALOR)
    Into vl_admi
    from ZSTPARA
    where ZSTPARA_MAPA_ID = 'PAGOS_SSB'
    And ZSTPARA_PARAM_ID = 'DB_ADMI';
Exception
When Others then 
    vl_admi :=0;
end;

----- Se busca el nombre de la instancia para la URL de Pagos -------
Begin
    Select GUBINST_INSTANCE_NAME
    Into vl_instancia
    from GUBINST;
Exception
When Others then 
    vl_instancia :=0;
End;




htp.p('<html>');
---------------en esta instruccion lanza al inicio al cargar la pagina la funcion lanza() para que mande el formulario---------
htp.p('<body onload="lanza()"><br>');


vurl_env :=vl_ruta||':'||vl_puerto||'/'||vl_instancia||'/pkg_solserv.sp_cuotas?pidm='|| vpidm||'&p_seq_protocol='||vseq_p ; 
--vurl_env := 'http://siusstes.scala.utel.edu.mx:9020/SEED/pkg_solserv.sp_cuotas?pidm='|| vpidm||'='||vseq_p ; 



-------aqui se declara la funcion java que sirve para pasar la informacion del from de paso al que se va lanzar se configura la accion  para donde va ir dirigido----

--- frmParams.action ="http://siusates.scala.utel.edu.mx/usuarios/autologin/";    se cambia para pruebas por laIP ------ Esta es la original line uno de la funcion lanza()

--            frmParams.action ="http://10.1.50.158/usuarios/autologin/";
-- http://10.1.47.199:8000/usuarios/autologin/

if p_protocol_seq_num_in > 0 then
HTP.P('
 <script type="text/javascript">




 function lanza(){
           frmParams.action ="'||vl_pagos||'";
             frmParams.vacesso.value = frmDatos.pacesso.value;
            frmParams.vnombre.value = frmDatos.pnombre.value;
            frmParams.vapellido.value = frmDatos.papellido.value;
            frmParams.vroles.value = frmDatos.proles.value;
           frmParams.vpidm2.value = frmDatos.ppidm2.value;
            frmParams.vid_usr.value = frmDatos.pid_usr.value;
            frmParams.vmail.value = frmDatos.pmail.value;
            frmParams.vcampus.value = frmDatos.pcampus.value;
            frmParams.vconcepto.value = frmDatos.pconcepto.value;
            frmParams.submit();
  }


</script>' );

else

HTP.P('
 <script type="text/javascript">




 function lanza(){
           frmParams.action ="'||vl_admi||'";
             frmParams.vacesso.value = frmDatos.pacesso.value;
            frmParams.vnombre.value = frmDatos.pnombre.value;
            frmParams.vapellido.value = frmDatos.papellido.value;
            frmParams.vroles.value = frmDatos.proles.value;
           frmParams.vpidm2.value = frmDatos.ppidm2.value;
            frmParams.vid_usr.value = frmDatos.pid_usr.value;
            frmParams.vmail.value = frmDatos.pmail.value;
            frmParams.vcampus.value = frmDatos.pcampus.value;
            frmParams.vterm.value = frmDatos.pterm.value;
            frmParams.submit();
  }


</script>' );
end if;

--htp.p('  se ejecuta de inmediato el proceso  '  || 
-- lv_protocol_rec.r_pidm ||'-'||
-- lv_protocol_rec.r_srvc_code ||'-'||
-- lv_protocol_rec.r_term_code ||'-'||
-- lv_protocol_rec.r_wsso_code ||'-'||
-- lv_protocol_rec.r_protocol_amount 
-- 
--   );
--------es esta parte carga el del cursor.  para deuda
open C_ACESSO(vpidm);
fetch C_ACESSO  into vlast_acces, vnombre, vapellidos,vid,vpidm2   ;
close C_ACESSO;



begin
      SELECT GOREMAL_EMAIL_ADDRESS
      into vmail
              FROM goremal
             WHERE  GOREMAL_PIDM = vpidm
             and  GOREMAL_EMAL_CODE  = 'PRIN';
  exception
          when others then
          vmail := 'N/A';
  
end;

begin

select SARADAP_CAMP_CODE
into  vcamp 
from saradap
where saradap_pidm = vpidm ;

exception
          when others then
          vcamp := 'N/A';
  
end;


vsalida :='STUDENT' ;


------------------------en este from se llena los valores con los datos que vamos aenviar despues  este from es de paso ------
if  p_protocol_seq_num_in > 0 then

 HTP.P( ' <table border="0" cellpadding="1" cellspacing="1" width="100%" >
      
  <form name="frmDatos"   method="post"   action="javascript:lanza">
  <input name="pacesso"    type="hidden"  value="  '|| vlast_acces ||'  "   >
  <input name="pnombre"     type="hidden"  value="'|| vnombre ||' " >
  <input name="papellido"   type="hidden"  value=" '|| vapellidos ||' "  >  
  <input name="proles" type="hidden"  value=" '|| vsalida ||' " >
  <input name="ppidm2" type="hidden"  value=" '|| vpidm2 ||' " >
  <input name="pid_usr" type="hidden"  value=" '|| vid ||' " >
  <input name="pmail" type="hidden"  value=" '|| vmail ||' " >
  <input name="pcampus" type="hidden"  value="  '|| vcamp ||'  " >
   <input name="pconcepto" type="hidden"  value="  '|| vurl_env ||'  " >
</form>
     ');

else

 HTP.P( ' <table border="0" cellpadding="1" cellspacing="1" width="100%" >
      
  <form name="frmDatos"   method="post"   action="javascript:lanza">
  <input name="pacesso"    type="hidden"  value="  '|| vlast_acces ||'  "   >
  <input name="pnombre"     type="hidden"  value="'|| vnombre ||' " >
  <input name="papellido"   type="hidden"  value=" '|| vapellidos ||' "  >  
  <input name="proles" type="hidden"  value=" '|| vsalida ||' " >
  <input name="ppidm2" type="hidden"  value=" '|| vpidm2 ||' " >
  <input name="pid_usr" type="hidden"  value=" '|| vid ||' " >
  <input name="pmail" type="hidden"  value=" '|| vmail ||' " >
  <input name="pcampus" type="hidden"  value="  '|| vcamp ||'  " >
   <input name="pterm" type="hidden"  value="  1  " >
</form>
     ');
end if;     
     --------------------------este el el from  que se va enviar   ya des pues al ejecutarse la funcion javascript------------------
     --target="_blank" 
     
if p_protocol_seq_num_in > 0 then

 HTP.P( '
<form name="frmParams" method="post"   target="_blank"  >
            <input type="hidden" name="vacesso">
            <input type="hidden" name="vnombre">
            <input type="hidden" name="vapellido">
            <input type="hidden" name="vroles">
            <input type="hidden" name="vpidm2">
            <input type="hidden" name="vid_usr">
            <input type="hidden" name="vmail">
            <input type="hidden" name="vcampus">
            <input type="hidden" name="vconcepto">
            
 </form>


     ');

else
     
 HTP.P( '
<form name="frmParams" method="post"   target="_blank"  >
            <input type="hidden" name="vacesso">
            <input type="hidden" name="vnombre">
            <input type="hidden" name="vapellido">
            <input type="hidden" name="vroles">
            <input type="hidden" name="vpidm2">
            <input type="hidden" name="vid_usr">
            <input type="hidden" name="vmail">
            <input type="hidden" name="vcampus">
            <input type="hidden" name="vterm">
            
 </form>


     ');
end if;
---insert into twpaso(valor1,valor2,valor3)  values('carga doctos 2 ','sp_login ', vnombre||','||vapellidos||','||VESTUD  ); commit;

 twbkwbis.p_closedoc (curr_release);
 
 

 htp.p('</body> </html> ' );
 
EXCEPTION 
WHEN OTHERS THEN
   --  error_page(SQLERRM)        ;
  vmsjerror  :=   SQLERRM;
end  sp_simoba;

PROCEDURE sp_cuotas_bck  ( pidm number  ,  p_seq_protocol number   )   is



lv_pidm        number:=0;

soap_request             varchar2(30000);
soap_respond           varchar2(30000);
 resp                       XMLType;
 conta_tbraccd         integer;
 
  resultar CLOB;
  l_xmltype XMLTYPE;
  p_detail_code    varchar2(5);
  vc_fuera_rango  number:=0;

 cursor c_cuota_mes(lv_pidm  number, lv_seq_p  number )  is
select     dbms_xmlgen.getxmltype (' 
 select TZRACCD_PIDM , 
 case when tbbdetc_dcat_code=''ENV'' and 
 (select count(*) from SWTMDAC
where SWTMDAC_pidm=''' || lv_pidm|| ''' and    SWTMDAC_MASTER_IND = ''Y'' and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
and    SWTMDAC_NUM_REAPPLICATION  >  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = ''Y''
and    ((SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0) or SWTMDAC_AMOUNT_DESC  > 0)
and    SWTMDAC_DETAIL_CODE_ACC in (select tzraccd_detail_code from tzraccd where tzraccd_crossref_number= ''' || lv_seq_p|| ''')) > 0
  then
 (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
   WHERE TBRACCD_PIDM = ''' || lv_pidm|| ''' ) + ROWNUM + 1
 else case when tbbdetc_dcat_code=''ENV''  then (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
                                                                         WHERE TBRACCD_PIDM = ''' || lv_pidm|| ''' ) + 2
        else  (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
                                                                         WHERE TBRACCD_PIDM = ''' || lv_pidm|| ''' ) + 1
        end
 end  TZRACCD_TRAN_NUMBER,
 TZRACCD_TERM_CODE, TZRACCD_DETAIL_CODE, 
case when SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0 then
        tzraccd_balance-(tzraccd_balance* (SWTMDAC_PERCENT_DESC/100))
       when SWTMDAC_AMOUNT_DESC is not null then
       tzraccd_balance-SWTMDAC_AMOUNT_DESC
else
      tzraccd_balance
end TZRACCD_BALANCE,
TZRACCD_EFFECTIVE_DATE, TZRACCD_CURR_CODE, TZRACCD_DOCUMENT_NUMBER
from tzraccd tb 
join  SVRSVPR vs on  TB.TZRACCD_PIDM  = VS.SVRSVPR_PIDM
and TB.TZRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
and VS.SVRSVPR_PROTOCOL_SEQ_NO  =    ''' || lv_seq_p|| '''
and  TB.TZRACCD_PIDM  =  ''' || lv_pidm|| '''   
join tbbdetc on    TB.tzraccd_detail_code=tbbdetc_detail_code and tbbdetc_type_ind=''C''
left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tzraccd_pidm and    SWTMDAC_DETAIL_CODE_ACC=TB.tzraccd_detail_code
and    SWTMDAC_MASTER_IND = ''Y'' and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
and    SWTMDAC_NUM_REAPPLICATION  >=  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = ''Y''
AND    SWTMDAC_SEQNO_SERV        =  TB.TZRACCD_CROSSREF_NUMBER
 ') as xmlresult  from dual;
 
 cursor c_cuota_mes1(lv_pidm  number, lv_seq_p  number )  is
select     dbms_xmlgen.getxmltype (' 
 select TBRACCD_PIDM , TBRACCD_TRAN_NUMBER , TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, 
case when SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0 then
        tbraccd_balance-(tbraccd_balance* (SWTMDAC_PERCENT_DESC/100))
       when SWTMDAC_AMOUNT_DESC is not null then
       tbraccd_balance-SWTMDAC_AMOUNT_DESC
else
      tbraccd_balance
end TBRACCD_BALANCE,
TBRACCD_EFFECTIVE_DATE, TBRACCD_CURR_CODE
from tbraccd tb 
join  SVRSVPR vs on  TB.TBRACCD_PIDM  = VS.SVRSVPR_PIDM
and TB.TBRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
and VS.SVRSVPR_PROTOCOL_SEQ_NO  =    ''' || lv_seq_p|| '''
and  TB.TBRACCD_PIDM  =  ''' || lv_pidm|| '''   
and    TB.tbraccd_detail_code in (select tbbdetc_detail_code from tbbdetc
                                            where tbbdetc_type_ind=''C'')
left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tbraccd_pidm and    SWTMDAC_DETAIL_CODE_ACC=TB.tbraccd_detail_code
and    SWTMDAC_MASTER_IND = ''Y'' and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
and    SWTMDAC_NUM_REAPPLICATION  >=  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = ''Y''
AND    SWTMDAC_SEQNO_SERV        =  TB.TBRACCD_CROSSREF_NUMBER
 order by TBRACCD_TRAN_NUMBER
 ') as xmlresult  from dual;
 
/*
select     dbms_xmlgen.getxmltype (' 
select TBRACCD_PIDM , TBRACCD_TRAN_NUMBER , TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_AMOUNT,TBRACCD_EFFECTIVE_DATE, TBRACCD_CURR_CODE
from tbraccd tb , SVRSVPR vs
where TB.TBRACCD_PIDM  = VS.SVRSVPR_PIDM
and TB.TBRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
and VS.SVRSVPR_PROTOCOL_SEQ_NO  = ''' || lv_seq_p|| '''
and  TB.TBRACCD_PIDM  =  ''' || lv_pidm|| '''   
 ') as xmlresult  from dual;
*/

begin

soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:Body>  ';

select count(*) into conta_tbraccd
from tbraccd
where tbraccd_pidm=pidm
and     tbraccd_crossref_number=p_seq_protocol;

if conta_tbraccd > 0 then
    Open c_cuota_mes1(pidm ,  p_seq_protocol );
    fetch c_cuota_mes1  into l_xmltype;
     if c_cuota_mes1%Notfound then
        close c_cuota_mes1;
        
    --    comenta esta validacion 
      insert into BANINST1.twpasoW(VALOR1, VALOR2, VALOR3, VALOR4,VALOR6)
       values('tbraccd NOFOUND_MES1', conta_tbraccd, pidm,p_seq_protocol,SUBSTR(l_xmltype,1,599)); commit;
        return;
      end if;

    close c_cuota_mes1;
else
    Open c_cuota_mes(pidm ,  p_seq_protocol );
    fetch c_cuota_mes  into l_xmltype;
     if c_cuota_mes%Notfound then
        close c_cuota_mes;
        
  --    comenta esta validacion 
      insert into BANINST1.twpasoW(VALOR1, VALOR2, VALOR3, VALOR4, VALOR6)
       values('tbraccd NOFOUND_CUOTA_NES', conta_tbraccd, pidm,p_seq_protocol,SUBSTR(l_xmltype,1,599)); commit;
       return;
      end if;

    close c_cuota_mes;
end if;
--------------------  se pasa este codigo del pkt de swdmac  pata que lo haga aca despues de porltal de pagos-----
                    begin 
                       select  TBRACCD_DETAIL_CODE 
                        into   p_detail_code
                         from tbraccd tb 
                        join  SVRSVPR vs on  TB.TBRACCD_PIDM  = VS.SVRSVPR_PIDM
                        and TB.TBRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
                        and VS.SVRSVPR_PROTOCOL_SEQ_NO  =  p_seq_protocol
                        and  TB.TBRACCD_PIDM  =  pidm  
                        and  TB.tbraccd_detail_code in (select tbbdetc_detail_code from tbbdetc
                                                                where tbbdetc_type_ind='C')
                        left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tbraccd_pidm and    SWTMDAC_DETAIL_CODE_ACC=TB.tbraccd_detail_code
                        and    SWTMDAC_MASTER_IND = 'Y' 
                        and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
                        and    SWTMDAC_NUM_REAPPLICATION  >=  SWTMDAC_APPLICATION_INDICATOR 
                        AND    SWTMDAC_FLAG = 'Y'
                        order by TBRACCD_TRAN_NUMBER;  
                     exception when others then
                      p_detail_code := '';
                      
                     end;    
                        
               IF vc_fuera_rango = 0 then ----------AQUI ES DONDE HAY QUE CAMBIAR
                       Begin 
                                UPDATE  saturn.SWTMDAC
                                SET SWTMDAC_FLAG = NULL 
                                 WHERE SWTMDAC_pidm = pidm
                                and SWTMDAC_DETAIL_CODE_ACC = p_detail_code
                               and SWTMDAC_SEC_PIDM = ( select max(SWTMDAC_SEC_PIDM )   from  SWTMDAC
                                                               Where SWTMDAC_PIDM = pidm
                                                                 and SWTMDAC_DETAIL_CODE_ACC =  p_detail_code
                                                                 AND    SWTMDAC_FLAG = 'Y'  );
                        Exception
                        When Others then 
                        -- vl_error_actualiza:=' Errror al Actualizar SWTMDAC_FLAG  >>  ' || sqlerrm;
                        null;
                        End;
           
                END IF;




if  l_xmltype  is not null  then 
dbms_output.put_line(l_xmltype.getClobVal);

resultar := (l_xmltype.getClobVal);

HTP.P( soap_request);
htp.p(resultar);
HTP.P( '</SOAP-ENV:Body>
</SOAP-ENV:Envelope>');

else
HTP.P( soap_request);
HTP.P('<ROW>0</ROW>');
HTP.P( '</SOAP-ENV:Body>
</SOAP-ENV:Envelope>');
--
--insert into twpaso values('tbraccd cero', vsalida, null,null); commit;
null;
end if;
EXCEPTION
  WHEN OTHERS THEN
   vmsjerror  :=   SQLERRM;

dbms_output.put_line('ERROR-GRAL'||vmsjerror);


end sp_cuotas_bck;


PROCEDURE sp_cuotas ( pidm number,  p_seq_protocol number   )   is

/*
SE grega cursor para los casos que tenga envio con costo ya que esto probocaba que se duplicara el saldoesto se libera con 
la COLF X NIVEL, glovicx 29/06/2021
*/

lv_pidm         number:=0;
soap_request    varchar2(30000);
soap_respond    varchar2(30000);
resp            XMLType;
conta_tbraccd   number;
conta_envio     number; 
resultar        CLOB;
l_xmltype       XMLTYPE;
p_detail_code   varchar2(5);
vc_fuera_rango  number:=0;
vseqno          number:=0;
VBITACORA       VARCHAR2(15);

 cursor c_cuota_mes(lv_pidm  number, lv_seq_p  number )  is
select     dbms_xmlgen.getxmltype (' 
 select TZRACCD_PIDM , 
 case when tbbdetc_dcat_code=''ENV'' and 
 (select count(*) from SWTMDAC
where SWTMDAC_pidm=''' || lv_pidm|| ''' and    SWTMDAC_MASTER_IND = ''Y'' and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
and    SWTMDAC_NUM_REAPPLICATION  >  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = ''Y''
and    ((SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0) or SWTMDAC_AMOUNT_DESC  > 0)
and    SWTMDAC_DETAIL_CODE_ACC in (select tzraccd_detail_code from tzraccd where tzraccd_crossref_number= ''' || lv_seq_p|| ''')) > 0
  then
 (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
   WHERE TBRACCD_PIDM = ''' || lv_pidm|| ''' ) + ROWNUM + 1
 else case when tbbdetc_dcat_code=''ENV''  then (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
                                                                         WHERE TBRACCD_PIDM = ''' || lv_pidm|| ''' ) + 2
        else  (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
                                                                         WHERE TBRACCD_PIDM = ''' || lv_pidm|| ''' ) + 1
        end
 end  TZRACCD_TRAN_NUMBER,
 TZRACCD_TERM_CODE, TZRACCD_DETAIL_CODE, 
case when SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0 then
        round (tzraccd_balance-(tzraccd_balance* (SWTMDAC_PERCENT_DESC/100)))
       when SWTMDAC_AMOUNT_DESC is not null then
       round(tzraccd_balance-SWTMDAC_AMOUNT_DESC)
else
       ( select round(sum(TZRACCD_BALANCE))
            from TZRACCD
            where 1=1
            and TZRACCD_PIDM = ''' || lv_pidm || '''
            and TZRACCD_CROSSREF_NUMBER =''' ||lv_seq_p || ''')
end TZRACCD_BALANCE,
TZRACCD_EFFECTIVE_DATE, TZRACCD_CURR_CODE, TZRACCD_DOCUMENT_NUMBER
from tzraccd tb 
join  SVRSVPR vs on  TB.TZRACCD_PIDM  = VS.SVRSVPR_PIDM
and TB.TZRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
and VS.SVRSVPR_PROTOCOL_SEQ_NO  =    ''' || lv_seq_p|| '''
and  TB.TZRACCD_PIDM  =  ''' || lv_pidm|| '''   
join tbbdetc on    TB.tzraccd_detail_code=tbbdetc_detail_code and tbbdetc_type_ind=''C''
left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tzraccd_pidm and    SWTMDAC_DETAIL_CODE_ACC=TB.tzraccd_detail_code
and    SWTMDAC_MASTER_IND = ''Y'' and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
and    SWTMDAC_NUM_REAPPLICATION  >=  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = ''Y''
AND    SWTMDAC_SEQNO_SERV        =  TB.TZRACCD_CROSSREF_NUMBER
 ') as xmlresult  from dual;
 
 cursor c_cuota_mes1(lv_pidm  number, lv_seq_p  number )  is
select     dbms_xmlgen.getxmltype (' 
 select TBRACCD_PIDM , TBRACCD_TRAN_NUMBER , TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, 
case when SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0 then
       round( tbraccd_balance-(tbraccd_balance* (SWTMDAC_PERCENT_DESC/100)))
       when SWTMDAC_AMOUNT_DESC is not null then
       round(tbraccd_balance-SWTMDAC_AMOUNT_DESC)
else
      ( select round(sum(TBRACCD_BALANCE))
            from tbraccd
            where 1=1
            and tbraccd_pidm = ''' || lv_pidm || '''
            and TBRACCD_CROSSREF_NUMBER =''' ||lv_seq_p || ''')
end TBRACCD_BALANCE,
TBRACCD_EFFECTIVE_DATE, TBRACCD_CURR_CODE
from tbraccd tb 
join  SVRSVPR vs on  TB.TBRACCD_PIDM  = VS.SVRSVPR_PIDM
and TB.TBRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
and VS.SVRSVPR_PROTOCOL_SEQ_NO  =    ''' || lv_seq_p|| '''
and  TB.TBRACCD_PIDM  =  ''' || lv_pidm|| '''   
and    TB.tbraccd_detail_code in (select tbbdetc_detail_code from tbbdetc
                                            where tbbdetc_type_ind=''C'')
left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tbraccd_pidm and    SWTMDAC_DETAIL_CODE_ACC=TB.tbraccd_detail_code
and    SWTMDAC_MASTER_IND = ''Y'' and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
and    SWTMDAC_NUM_REAPPLICATION  >=  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = ''Y''
AND    SWTMDAC_SEQNO_SERV        =  TB.TBRACCD_CROSSREF_NUMBER
 order by TBRACCD_TRAN_NUMBER
 ') as xmlresult  from dual;
 
---este curso es por si trae mas de un registro el cursor entonces el portal de pagos hace la sumatoria de todos glovicx 29/06/021
cursor c_cuota_mes2(lv_pidm number ,  lv_seq_p number ) IS
select     dbms_xmlgen.getxmltype (' 
select TBRACCD_PIDM , TBRACCD_TRAN_NUMBER , TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, 
case when SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0 then
       round( tbraccd_balance-(tbraccd_balance* (SWTMDAC_PERCENT_DESC/100)))
       when SWTMDAC_AMOUNT_DESC is not null then
       round(tbraccd_balance-SWTMDAC_AMOUNT_DESC)
else  
      ( select round( (TBRACCD_BALANCE))
            from tbraccd
            where 1=1
            and tbraccd_pidm =''' ||lv_pidm || '''  
            and TBRACCD_CROSSREF_NUMBER =''' ||lv_seq_p || ''' 
              AND    TBRACCD_DETAIL_CODE  in (select distinct(STVWSSO_CODE)
                                        from STVWSSO
                                        where 1=1
                                        and STVWSSO_CHRG > 0 )    )
            
end TBRACCD_BALANCE,
TBRACCD_EFFECTIVE_DATE, TBRACCD_CURR_CODE
from tbraccd tb 
join  SVRSVPR vs on  TB.TBRACCD_PIDM  = VS.SVRSVPR_PIDM
and TB.TBRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
and VS.SVRSVPR_PROTOCOL_SEQ_NO  =  ''' ||lv_seq_p || '''
and TB.TBRACCD_PIDM  =  ''' ||lv_pidm || '''
and TB.tbraccd_detail_code in (select tbbdetc_detail_code from tbbdetc
                                            where tbbdetc_type_ind=''C'')
AND tb.TBRACCD_DETAIL_CODE  in (select distinct(STVWSSO_CODE)
                                        from STVWSSO
                                        where 1=1
                                        and STVWSSO_CHRG > 0 )                                                                                       
left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tbraccd_pidm and    SWTMDAC_DETAIL_CODE_ACC=TB.tbraccd_detail_code
and    SWTMDAC_MASTER_IND = ''Y'' and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
and    SWTMDAC_NUM_REAPPLICATION  >=  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = ''Y''
AND    SWTMDAC_SEQNO_SERV        =  TB.TBRACCD_CROSSREF_NUMBER
UNION ALL
select TBRACCD_PIDM , TBRACCD_TRAN_NUMBER , TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, 
case when SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0 then
        round(tbraccd_balance-(tbraccd_balance* (SWTMDAC_PERCENT_DESC/100)))
       when SWTMDAC_AMOUNT_DESC is not null then
       round(tbraccd_balance-SWTMDAC_AMOUNT_DESC)
else  
      ( select round(sum (TBRACCD_BALANCE))
            from tbraccd
            where 1=1
            and tbraccd_pidm = ''' ||lv_pidm || ''' 
            and TBRACCD_CROSSREF_NUMBER =''' ||lv_seq_p || '''
              AND    TBRACCD_DETAIL_CODE not in (select distinct(STVWSSO_CODE)
                                        from STVWSSO
                                        where 1=1
                                        and STVWSSO_CHRG > 0 )    )
            
end TBRACCD_BALANCE,
TBRACCD_EFFECTIVE_DATE, TBRACCD_CURR_CODE
from tbraccd tb 
join  SVRSVPR vs on  TB.TBRACCD_PIDM  = VS.SVRSVPR_PIDM
and TB.TBRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
and VS.SVRSVPR_PROTOCOL_SEQ_NO  =   ''' ||lv_seq_p || '''
and TB.TBRACCD_PIDM  =  ''' ||lv_pidm || '''
and TB.tbraccd_detail_code in (select tbbdetc_detail_code from tbbdetc
                                            where tbbdetc_type_ind=''C'')
AND tb.TBRACCD_DETAIL_CODE  not in (select distinct(STVWSSO_CODE)
                                        from STVWSSO
                                        where 1=1
                                        and STVWSSO_CHRG > 0 )                                                                                       
left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tbraccd_pidm and    SWTMDAC_DETAIL_CODE_ACC=TB.tbraccd_detail_code
and    SWTMDAC_MASTER_IND = ''Y'' and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
and    SWTMDAC_NUM_REAPPLICATION  >=  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = ''Y''
AND    SWTMDAC_SEQNO_SERV        =  TB.TBRACCD_CROSSREF_NUMBER
 order by TBRACCD_TRAN_NUMBER
 ') as xmlresult  from dual;


begin

soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:Body>  ';

       begin
        select count(*) into conta_tbraccd
        from tbraccd
        where tbraccd_pidm=pidm
        and   tbraccd_crossref_number=p_seq_protocol;
       exception when others then
       conta_tbraccd := 0;
       end;
       
        begin
        select TBRACCD_BALANCE  into conta_envio
        from tbraccd
        where tbraccd_pidm=pidm
        and   tbraccd_crossref_number=p_seq_protocol
        and  TBRACCD_DETAIL_CODE  in (select distinct(STVWSSO_CODE)
                                        from STVWSSO
                                        where 1=1
                                        and STVWSSO_CHRG > 0 );
       exception when others then
       conta_envio := 0;
       end;

IF conta_envio > 0 then  ---esta opcion es para cuando si encuantra el envio con costo y no duplique el saldo glovicx 29/06/021
        
        Open c_cuota_mes2(pidm ,  p_seq_protocol );
         fetch c_cuota_mes2  into l_xmltype;
         if c_cuota_mes2%Notfound then
            close c_cuota_mes2;
            return;
          end if;
        VBITACORA := F_BITSIU(  F_GetSpridenID(pidm),PIDM,'SP_CUOTAS_MES2',p_seq_protocol,NULL,NULL,NULL,SYSDATE,NULL,NULL,NULL,NULL,NULL,
                                NULL,NULL,NULL,NULL,'c_cuota_mes2',NULL,NULL,NULL,NULL,NULL );
    close c_cuota_mes2;

ELSE

    IF conta_tbraccd > 0 then
            Open c_cuota_mes1(pidm ,  p_seq_protocol );
            fetch c_cuota_mes1  into l_xmltype;
                 if c_cuota_mes1%Notfound then
                    close c_cuota_mes1;
                    return;
                  end if;
            close c_cuota_mes1;
    else
            Open c_cuota_mes(pidm ,  p_seq_protocol );
            fetch c_cuota_mes  into l_xmltype;
                 if c_cuota_mes%Notfound then
                    close c_cuota_mes;
                    
                       return;
                  end if;
            close c_cuota_mes;
    END IF;  
       
end if;
                     ----se agrega esta nueva validacion para ver si ya el trigger de tbraccd le actualizo el no de servicio glovicx 16/04/2020
                     
                     begin
                       select 1, SW.SWTMDAC_DETAIL_CODE_ACC
                         INTO vseqno,p_detail_code
                          from SWTMDAC sw
                          where 1=1
                          and SWTMDAC_pidm = pidm
                            and SW.SWTMDAC_SEQNO_SERV = p_seq_protocol;
                     
                     
                      exception WHEN NO_DATA_FOUND THEN
                      vseqno := 0;
                      vmsjerror   := sqlerrm;
                      when others then
                      vseqno := 0;
                      vmsjerror   := sqlerrm;
                      dbms_output.put_line('error en busca descuento  '|| vmsjerror);
                      
                      
                     end;   
                     
               IF vseqno = 1 then ----------AQUI ES DONDEactualiza si lo encuntra se va directo sobre el 
                  
                  
                       Begin 
                          UPDATE  saturn.SWTMDAC
                            SET SWTMDAC_FLAG = NULL ,
                             SWTMDAC_APPLICATION_INDICATOR = 1,
                             SWTMDAC_APPLICATION_DATE      = sysdate
                                 WHERE SWTMDAC_pidm = pidm
                                and SWTMDAC_DETAIL_CODE_ACC = p_detail_code
                                 and SWTMDAC_SEQNO_SERV = p_seq_protocol;
                              
                        Exception
                        When Others then 
                               null;
                               vmsjerror   := sqlerrm;
                          dbms_output.put_line('error en UPDATE descuento  '|| vmsjerror);
                        End;
                        
--                              begin
--                             
--                              update  TBITSIU
--                              set  P_SOLVSERV   = 'Y',
--                                   VALOR_SOLVS =( 'param_solserv '|| p_seq_protocol||'-'||p_detail_code||'-'||vseqno ),
--                                   VALOR18  = 'exito_solserv'
--                               where PIDM = pidm
--                               and   SEQNO = p_seq_protocol
--                               --and   MONTO = p_monto
--                               ;
--                        
--                           exception when others then
--                            --vl_error := SQLERRM;
--                            null;
--                            vmsjerror   := sqlerrm;
--                            dbms_output.put_line('error en UPDATE TBITSIU  '|| vmsjerror);
--                           end;    
                        
                        
                        
                
           
                END IF;


if  l_xmltype  is not null  then 
dbms_output.put_line(l_xmltype.getClobVal);

resultar := (l_xmltype.getClobVal);

HTP.P( soap_request);
htp.p(resultar);
HTP.P( '</SOAP-ENV:Body>
</SOAP-ENV:Envelope>');

else
HTP.P( soap_request);
HTP.P('<ROW>0</ROW>');
HTP.P( '</SOAP-ENV:Body>
</SOAP-ENV:Envelope>');
--
--insert into twpaso values('tbraccd cero', vsalida, null,null); commit;
null;
end if;
EXCEPTION
  WHEN OTHERS THEN
   vmsjerror  :=   SQLERRM;
 --VBITACORA := F_BITSIU(  F_GetSpridenID(pidm),PIDM,'SP_CUOTAS_MES1',p_seq_protocol,NULL,NULL,NULL,SYSDATE,NULL,NULL,NULL,NULL,NULL,
  --                              NULL,NULL,NULL,NULL,'c_cuota_mes1',NULL,NULL,NULL,NULL,NULL );
       
dbms_output.put_line('ERROR-GRAL'||vmsjerror);


end sp_cuotas;






FUNCTION fn_credito (pidm number, ---> Pidm del Alumno 
                                  p_seq_protocol number, ---> clave del servicio que se desea dar a crédito
                                  p_credito varchar2)   ---> Constante 'C'
                                      Return Varchar2    Is
      vl_error varchar2(250);    
      vl_error_tbra varchar2(250);                             
   
   Begin 
   
        --    begin
        dbms_output.put_line('llama inserta_tbraccd'||pidm||' '||p_seq_protocol);
            vl_error_tbra:= inserta_tbraccd  ( pidm , p_seq_protocol );
        dbms_output.put_line('vl_error_tbra'||vl_error_tbra);
        --    end;
         
            Begin
                   Update tbraccd
                        set TBRACCD_MERCHANT_ID = p_credito
                   Where TBRACCD_PIDM = pidm
                   And TBRACCD_CROSSREF_NUMBER = p_seq_protocol;
                   Update svrsvpr
                        set svrsvpr_srvs_code='CR'
                    Where svrsvpr_protocol_seq_no=p_seq_protocol; 
                    dbms_output.put_line('Actualizó TBRACCD_MERCHANT_ID y svrsvpr_srvs_code=CR'||pidm||' '||p_seq_protocol||' '||p_credito);
                    vl_error:='Exito';
                    commit;
            Exception
            When Others then 
                vl_error := 'Se presento un error al actualizar en el paquete pkg_solserv.fn_credito' || sqlerrm;
                dbms_output.put_line('Error:'||sqlerrm);
                Return vl_error;
            End;
            
 --    if vl_error is null then
 --       if vl_error_tbra not like 'Exito%' then
 --          vl_error:=vl_error_tbra;
 --       end if;
 --    end if;
     Return vl_error;
   
   Exception
   When Others then 
        vl_error := 'Se presento un error General en el paquete pkg_solserv.fn_credito' || sqlerrm;
        Return vl_error;
   End;

FUNCTION inserta_tbraccd  ( pidm number  ,  p_seq_protocol number   )    Return Varchar2    Is

vl_error varchar2(250);                                 
-------------------------SELE AGREGARON LAS COLUMNAS STUDY, PTRM, FECHA_INI(TZRACCD_FEED_DATE ,TZRACCD_STSP_KEY_SEQUENCE ,TZRACCD_PERIOD)  A TBRA  GLOVICX 26 OCT 2018
begin
                   for c in (select TZRACCD_PIDM, TZRACCD_TERM_CODE, TZRACCD_DETAIL_CODE, TZRACCD_USER, TZRACCD_ENTRY_DATE, round(TZRACCD_AMOUNT) TZRACCD_AMOUNT , round(TZRACCD_BALANCE) TZRACCD_BALANCE, TZRACCD_EFFECTIVE_DATE, TZRACCD_DESC,
                                    TZRACCD_CROSSREF_NUMBER, TZRACCD_SRCE_CODE, TZRACCD_ACCT_FEED_IND, TZRACCD_SESSION_NUMBER, TZRACCD_DATA_ORIGIN, TZRACCD_MERCHANT_ID, TZRACCD_TRANS_DATE,
                                    TZRACCD_CURR_CODE, TZRACCD_FEED_DATE ,TZRACCD_STSP_KEY_SEQUENCE ,TZRACCD_PERIOD
                           from tzraccd
                           where tzraccd_pidm=pidm
                           and     tzraccd_crossref_number=p_seq_protocol
                           and     tzraccd_pidm not in (select tbraccd_pidm from tbraccd
                                                                    where tzraccd_crossref_number=tbraccd_crossref_number
                                                                    and     tzraccd_detail_code=tbraccd_detail_code
                                                                    ) order by tzraccd_tran_number) loop
                  Begin
                        insert into tbraccd (TBRACCD_PIDM, TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, TBRACCD_USER, TBRACCD_ENTRY_DATE, TBRACCD_AMOUNT, TBRACCD_BALANCE, TBRACCD_EFFECTIVE_DATE, 
                       TBRACCD_DESC,TBRACCD_CROSSREF_NUMBER, TBRACCD_SRCE_CODE, TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER, TBRACCD_DATA_ORIGIN, TBRACCD_TRAN_NUMBER, 
                       TBRACCD_ACTIVITY_DATE,TBRACCD_MERCHANT_ID, TBRACCD_TRANS_DATE, TBRACCD_CURR_CODE,TBRACCD_FEED_DATE ,TBRACCD_STSP_KEY_SEQUENCE,TBRACCD_PERIOD)
                       VALUES(c.TZRACCD_PIDM, c.TZRACCD_TERM_CODE, c.TZRACCD_DETAIL_CODE, c.TZRACCD_USER, c.TZRACCD_ENTRY_DATE, c.TZRACCD_AMOUNT, c.TZRACCD_BALANCE, c.TZRACCD_EFFECTIVE_DATE, 
                       c.TZRACCD_DESC, c.TZRACCD_CROSSREF_NUMBER, c.TZRACCD_SRCE_CODE, c.TZRACCD_ACCT_FEED_IND, c.TZRACCD_SESSION_NUMBER, c.TZRACCD_DATA_ORIGIN,
                      (select nvl(max(tbraccd_tran_number),0) +1 from tbraccd
                       where tbraccd_pidm=c.TZRACCD_PIDM), sysdate,c.TZRACCD_MERCHANT_ID,c.TZRACCD_TRANS_DATE, c.TZRACCD_CURR_CODE, C.TZRACCD_FEED_DATE ,C.TZRACCD_STSP_KEY_SEQUENCE ,C.TZRACCD_PERIOD);
                       vl_error:='Exito !!!';
                      Exception when others then
                        vl_error := 'Se presento un error al actualizar en tabla TBRACCD' || sqlerrm;
                        Return vl_error;   
                 End;            
                 end loop;
                 
                  commit;
                 dbms_output.put_line('ya paso por tbraccd');
                  begin
                      update svrsvpr set svrsvpr_accd_tran_number=(select min(tbraccd_tran_number) from tbraccd where tbraccd_pidm=pidm
                                                                                            and tbraccd_crossref_number=p_seq_protocol)
                      where svrsvpr_protocol_seq_no=p_seq_protocol;
                      dbms_output.put_line('ya actualizó svrsvpr');
                      Exception when others then
                        vl_error := 'Se presento un error al actualizar en tabla SVRSVPR' || sqlerrm;
                        dbms_output.put_line('error:'||sqlerrm);
                         Return vl_error; 
                 end;
                  commit;
Return vl_error;
End inserta_tbraccd;




FUNCTION  sol_siguiente (p_pidm in number, p_term_code in varchar2) Return Number
is

vl_siguiente number;

    begin

        begin    
                if p_pidm is null or p_term_code is null then
                    vl_siguiente:=0;
                else    
                
                Select nvl(max (saradap_appl_no), 0) +1 max
                into vl_siguiente
                from saradap, sarappd
                Where saradap_term_code_entry = p_term_code
                and saradap_pidm = p_pidm
                and saradap_pidm = sarappd_pidm
                and sarappd_apdc_code= '40';
                
              end if;
              exception when others then 
              vl_siguiente:=0;
              return (vl_siguiente);
              end;              
              return (vl_siguiente);   
end sol_siguiente;



FUNCTION  dec_cuarenta_pago(p_pidm in number, p_term_code in varchar2) Return Number
is
vl_msje Varchar2(250);
total_pago number(16,2);

begin  
   
     begin    
            
                if  p_pidm is null or p_term_code is null then
                    total_pago:=0;
                                        
                else
                
                   select  round(sum(tbraccd_balance))
                   into total_pago
                   from tbraccd, tbbdetc
                   where tbraccd_detail_code = tbbdetc_detail_code
                   and tbraccd_term_code = p_term_code
                   and tbbdetc_type_ind ='P'
                   and tbraccd_pidm = p_pidm;
                   
              end if;                                            
     exception when no_data_found then
     total_pago:=0;
     return (total_pago);
     end;          
    return (total_pago);    
  end dec_cuarenta_pago;   
  
function f_cuotas ( pidm in number,  p_seq_protocol in number )  return baninst1.pkg_solserv.mattbra_type
as

conta_tbraccd  number:=0;
lv_pidm        number;
lv_seq_p       number;
vl_error       varchar2(500);

CUR_campos    baninst1.pkg_solserv.mattbra_type;

begin
null;
lv_pidm     := pidm;
lv_seq_p    := p_seq_protocol;

select count(*) 
into conta_tbraccd
from tbraccd
where   tbraccd_pidm=lv_pidm
and     tbraccd_crossref_number=lv_seq_p;

if conta_tbraccd > 0 then

 open CUR_campos for   select TBRACCD_PIDM , TBRACCD_TRAN_NUMBER , TBRACCD_TERM_CODE, TBRACCD_DETAIL_CODE, 
                        case when SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0 then
                                tbraccd_balance-(tbraccd_balance* (SWTMDAC_PERCENT_DESC/100))
                               when SWTMDAC_AMOUNT_DESC is not null then
                               tbraccd_balance-SWTMDAC_AMOUNT_DESC
                        else
                              tbraccd_balance
                        end TBRACCD_BALANCE,
                        TBRACCD_EFFECTIVE_DATE, TBRACCD_CURR_CODE, TBRACCD_DOCUMENT_NUMBER
                        from tbraccd tb 
                        join  SVRSVPR vs on  TB.TBRACCD_PIDM  = VS.SVRSVPR_PIDM
                        and TB.TBRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
                        and VS.SVRSVPR_PROTOCOL_SEQ_NO  =  lv_seq_p
                        and  TB.TBRACCD_PIDM  =  lv_pidm  
                        and  TB.tbraccd_detail_code in (select tbbdetc_detail_code from tbbdetc
                                                                where tbbdetc_type_ind='C')
                        left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tbraccd_pidm and    SWTMDAC_DETAIL_CODE_ACC=TB.tbraccd_detail_code
                        and    SWTMDAC_MASTER_IND = 'Y' 
                        and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
                        and    SWTMDAC_NUM_REAPPLICATION  >  SWTMDAC_APPLICATION_INDICATOR 
                        AND SWTMDAC_FLAG = 'Y'
                        order by TBRACCD_TRAN_NUMBER;  

dbms_output.put_line('campos1');
else
  open CUR_campos for  select TZRACCD_PIDM , 
                             case when tbbdetc_dcat_code='ENV' and 
                             (select count(*) from SWTMDAC
                            where SWTMDAC_pidm= lv_pidm 
                            and    SWTMDAC_MASTER_IND = 'Y' 
                            and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
                            and    SWTMDAC_NUM_REAPPLICATION  >  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = 'Y'
                            and    ((SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0) or SWTMDAC_AMOUNT_DESC  > 0)
                            and    SWTMDAC_DETAIL_CODE_ACC in (select tzraccd_detail_code from tzraccd where tzraccd_crossref_number= lv_seq_p)) > 0
                              then
                             (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
                               WHERE TBRACCD_PIDM = lv_pidm ) + ROWNUM + 1
                             else case when tbbdetc_dcat_code='ENV'  then (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
                                                                                                     WHERE TBRACCD_PIDM =  lv_pidm ) + 2
                                    else  (SELECT NVL(MAX(TBRACCD_TRAN_NUMBER),0) FROM TBRACCD
                                                                                                     WHERE TBRACCD_PIDM =  lv_pidm ) + 1
                                    end
                             end  TZRACCD_TRAN_NUMBER,
                             TZRACCD_TERM_CODE, TZRACCD_DETAIL_CODE, 
                            case when SWTMDAC_PERCENT_DESC is not null and SWTMDAC_PERCENT_DESC > 0 then
                                    tzraccd_balance-(tzraccd_balance* (SWTMDAC_PERCENT_DESC/100))
                                   when SWTMDAC_AMOUNT_DESC is not null then
                                   tzraccd_balance-SWTMDAC_AMOUNT_DESC
                            else
                                  tzraccd_balance
                            end TZRACCD_BALANCE,
                            TZRACCD_EFFECTIVE_DATE, TZRACCD_CURR_CODE, TZRACCD_DOCUMENT_NUMBER
                            from tzraccd tb 
                            join  SVRSVPR vs on  TB.TZRACCD_PIDM  = VS.SVRSVPR_PIDM
                            and TB.TZRACCD_CROSSREF_NUMBER = VS.SVRSVPR_PROTOCOL_SEQ_NO
                            and VS.SVRSVPR_PROTOCOL_SEQ_NO  =  lv_seq_p
                            and  TB.TZRACCD_PIDM  =  lv_pidm  
                            join tbbdetc on    TB.tzraccd_detail_code=tbbdetc_detail_code and tbbdetc_type_ind='C'
                            left outer join  SWTMDAC on   SWTMDAC_pidm = TB.tzraccd_pidm and  SWTMDAC_DETAIL_CODE_ACC=TB.tzraccd_detail_code
                            and    SWTMDAC_MASTER_IND = 'Y' 
                            and    trunc(sysdate)  between  trunc(SWTMDAC_EFFECTIVE_DATE_INI)  and  trunc(SWTMDAC_EFFECTIVE_DATE_FIN)
                            and    SWTMDAC_NUM_REAPPLICATION  >  SWTMDAC_APPLICATION_INDICATOR AND SWTMDAC_FLAG = 'Y'
                             order by to_number(TZRACCD_DOCUMENT_NUMBER)
                             ;

dbms_output.put_line('campos');
null;
end if;

return CUR_campos;

 Exception
            When others  then 
               vl_error := 'PKG_SERV_SIU_ERROR.CUR_CAMPOS: ' || sqlerrm;
           return CUR_CAMPOS;
end f_cuotas;


end pkg_solserv;
/

DROP PUBLIC SYNONYM PKG_SOLSERV;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SOLSERV FOR BANINST1.PKG_SOLSERV;


GRANT EXECUTE ON BANINST1.PKG_SOLSERV TO CONSULTA;
