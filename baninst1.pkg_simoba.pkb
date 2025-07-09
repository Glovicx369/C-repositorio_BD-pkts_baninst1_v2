DROP PACKAGE BODY BANINST1.PKG_SIMOBA;

CREATE OR REPLACE PACKAGE BODY BANINST1."PKG_SIMOBA" IS
  -- Author  : glovicx
  -- Created : 05.Oct.2015
  -- Purpose : PKT con todas las utilerias que utiliza para el desarrollo V2  simoba.


---++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 /* Global cursor declarations for package */
curr_release                VARCHAR2 (10)           := '8.5.4.4';
err_message                 msg_rectype;

msg_text                     VARCHAR2 (100)  ;
VHEADER                     VARCHAR2 (100)  ;
division                        varchar2(1);

lv_pidm                    VARCHAR2(12);

vmsjerror     varchar2(1000);


soap_request             varchar2(30000);
soap_respond           varchar2(30000);
  http_req                  utl_http.req;
  http_resp                 utl_http.resp;
  resp                       XMLType;
  i                             integer;
vnumero   number;
vdescp     varchar2(60);
vperiodo   varchar2(15);
vmonto    number;
vpidm     number;
vmoneda  varchar2(4);
vglobal1    varchar2(100);
vglobal2    varchar2(100);
vglobal3    varchar2(100);
vglb_currency    varchar2(4);


  CTX     DBMS_XMLGEN.ctxHandle;
 resultar CLOB;
  l_xmltype XMLTYPE;

cursor c_deuda(p_empno  varchar2)  is
select  TB.TBRACCD_TRAN_NUMBER  Num,  BB.TBBDETC_DESC descripcion,   trunc(TB.TBRACCD_EFFECTIVE_DATE) periodo, TB.TBRACCD_AMOUNT monto, TBRACCD_CURR_CODE moneda
from tbraccd tb, tbbdetc bb
where tbraccd_pidm =  p_empno
and TB.TBRACCD_DETAIL_CODE  = BB.TBBDETC_DETAIL_CODE
and TBRACCD_TRAN_NUMBER_PAID is null
and TBRACCD_BALANCE   <> 0
and TBBDETC_TYPE_IND = 'C'
and    trunc(TBRACCD_EFFECTIVE_DATE)   <     pkg_simoba.get_Add_Month(sysdate,1) -----aqui va el numero de mese que deseamos sumar al sysdate en este caso es 1(uno) un mes
order by periodo;

cursor c_general (p_empno  varchar2)   is
SELECT SPRIDEN_ID , SPRIDEN_PIDM, SPRIDEN_LAST_NAME,SPRIDEN_FIRST_NAME ,LV.STVLEVL_DESC,  D.SGBSTDN_TERM_CODE_EFF , VT.STVTERM_DESC
                                     FROM SPRIDEN  s, sgbstdn d, STVLEVL LV, STVTERM VT
                                     WHERE SPRIDEN_ID IS NOT  NULL
                                     and   S.SPRIDEN_PIDM  = D.SGBSTDN_PIDM
                                     AND D.SGBSTDN_LEVL_CODE = LV.STVLEVL_CODE
                                     AND  D.SGBSTDN_TERM_CODE_EFF IN (SELECT MAX(SGBSTDN_TERM_CODE_EFF) FROM SGBSTDN DD
                                                                                               WHERE D.SGBSTDN_PIDM=DD.SGBSTDN_PIDM)
                                     AND  D.SGBSTDN_TERM_CODE_EFF = VT.STVTERM_CODE
                                     and SPRIDEN_PIDM = p_empno  ;
-- FUNCTION   back_vars (var1  varchar2  DEFAULT NULL , var2   varchar2  DEFAULT NULL , var3  varchar2 DEFAULT NULL  )
--         RETURN varchar2
--    IS
--      salida  varchar2(2):= 'ok';
--    BEGIN
--
--    vglobal1  :=var1 ;
--    vglobal2  :=var2 ;
--    vglobal3  :=var3 ;
--
--
--    RETURN TRUNC(salida);
--end;


 FUNCTION   get_Add_Month (
      STARTDATE           DATE,
      MONTHS_TO_ADD      NUMBER
    )
        RETURN DATE
    IS
        MY_ADD_MONTH_RESULT DATE;
    BEGIN

        SELECT ORACLES_ADD_MONTH_RESULT + NET_DAYS_TO_ADJUST INTO MY_ADD_MONTH_RESULT FROM
        (
            SELECT T.*,CASE WHEN SUBSTRACT_DAYS > ADD_DAYS THEN ADD_DAYS - SUBSTRACT_DAYS ELSE 0 END AS NET_DAYS_TO_ADJUST FROM
            (
                SELECT T.*,EXTRACT(DAY FROM ORACLES_ADD_MONTH_RESULT) AS SUBSTRACT_DAYS FROM
                (
                    SELECT ADD_MONTHS(STARTDATE,MONTHS_TO_ADD) AS ORACLES_ADD_MONTH_RESULT,EXTRACT(DAY FROM STARTDATE) AS ADD_DAYS FROM DUAL
                )T
            )T
        )T;
        RETURN TRUNC(MY_ADD_MONTH_RESULT);
    END get_Add_Month;


PROCEDURE sp_dispList (vpuser  varchar2 DEFAULT NULL )
IS
   lv_webpay_header_tab       TB_WEBPAY_HEADER.webpay_header_tab;
   lv_pidm                              spriden.spriden_pidm%TYPE;

   lv_ApiKey                 varchar2(30):='6u39nqhq8ftd0hlvnjfs66eh8c~';
   lv_merchantId          varchar2(10):='500238';
   lv_shmd5                 varchar2(200);
--?ApiKey~merchantId~referenceCode~amount~currency?.

--
-- Validate the user.
 lv_url                  VARCHAR2(2000);
  lv_msgNotXMLHTTP        VARCHAR2(100);
  lv_msgProblemRequest    VARCHAR2(100);
  lv_msgInvalidData       VARCHAR2(100);

BEGIN
  lv_url := lower(owa_util.get_cgi_env('REQUEST_PROTOCOL'));
  lv_url := lv_url || '://';
  lv_url := lv_url || owa_util.get_cgi_env('HTTP_HOST');

  lv_msgNotXMLHTTP     := G$_NLS.Get('xxx','SQL','Cannot create an XMLHTTP instance.');
  lv_msgProblemRequest := G$_NLS.Get('xxx','SQL','There was a problem with the request.');
  lv_msgInvalidData    := G$_NLS.Get('xxx','SQL','Additional data is not recognized.');

 division := '';
      -- Validate CHAR/VARCHAR2 post variables
      twbksecr.p_chk_parms_05(vpuser);

      IF NOT twbkwbis.f_validuser (lv_pidm)
      THEN
  ---    HTP.P(' PUEBAS  EN IF .. ');
         RETURN;
      END IF;

 -- twbkwbis.p_opendoc(NAME=>'bwskoacc.P_ViewAR', title_text=> 'texto titulo',header_disp1=>'header numero 1' ,header_text=>'textoooo new '   );
-- twbkwbis.p_opendoc ('pkg_simoba.P_DispList');
 bwckfrmt.p_open_doc('pkg_simoba.sp_dispList','<br>', 'Seguro con Paypal ');
  twbkwbis.p_dispinfo ('pkg_simoba.sp_dispListt');

----esta linea es temporal  solo para probar fuera del SSB  hay que habilitar la instruccion de arriba y quitar esta


--lv_pidm  :=   vpuser;
--lv_pidm := fget_pidm ( vpuser);

--HTP.P(' PUEBAS ');


 HTP.P('
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
    <HEAD>
        <TITLE> Pagos Online </TITLE>'    );

HTP.P(' <BODY  "  > ');

  -------------------aqui manda el pkt de informacion basica header---------------------
  pkg_simoba.get_alumn(lv_pidm);



htp.p('</table>  <br><br>');---no quitar esta etiqueta por que se descuadra el formato de los datos

twbkfrmt.p_printspacer ();


twbkfrmt.P_PrintBold ('Formas de Pago'   );

twbkfrmt.p_printspacer ();


HTP.P(' <br>
<script type="text/javascript" >

 function Eventos()  {
  alert("inicio asigno eventos");
  //frmAction.submit.onclick=pagos();
}


  function Pagos(pidm,monto) {
   var  frm_Action     = document.getElementById ("frmAction");
   var  frm_elemonto = document.getElementById("p_monto");
   var frm_typou  = document.getElementById("pagosu");
   var frm_typop  = document.getElementById("pagosp");
   var frm_moneda  = document.getElementById("moneda");
   var frm_ntran  = document.getElementById("ntran");

    //  alert(" Estoy en funcion pagos" + frm_moneda.value +" ntran " + frm_ntran.value );

   vtrans  = frm_ntran.value;
   vmonto =  frm_elemonto.value;
   vtypou  = frm_typou.checked;
   vtypop  = frm_typop.checked;
   vmoneda  = frm_moneda.value;

if(vmoneda==null){ vmoneda="MXN";  }


//--?ApiKey~merchantId~referenceCode~amount~currency?.


  if(vtypou==true)
{
               document.frmLanzar.action = "https://stg.gateway.payulatam.com/ppp-web-gateway/";
               //document.frmLanzar.referenceCode.value =  "'||lv_pidm||'" ;
               frmLanzar.amount.value =  vmonto  ;
               document.frmLanzar.currency.value =vmoneda;
               document.frmLanzar.description.value ="Pago Colegiaturas/Accesorios";
             // alert(" Estoy en funcion pagos" + frmLanzar.referenceCode.value );

var    lv_shmd5  = "'||lv_ApiKey||lv_merchantId||'"+"~"+frmLanzar.referenceCode.value+"~"+frmLanzar.amount.value+"~"+document.frmLanzar.currency.value;

    var resp =lv_shmd5;
  //alert(" Estoy en variable    "   + resp );

 makeServiceDescRequest(lv_shmd5);  // LANZO EL LLAMADO PARA EJECUTAR UN PROCESO PLSQL CON VARIBLES DE JAVASCRIPT

        //   alert(" valor de la firma "+  frmLanzar.signature.vale);
               document.frmLanzar.submit();
 }

  if(vtypop==true)
{
alert(" Aqui ejecuta la opcion paypal falta por pagar "  +vmonto);
}

 } //  end funcion pagos

 function makeServiceDescRequest(lv_shmd5) {
         //
         // This javascript function makes the connection
         // to the server to execute a script
         //
           if (window.XMLHttpRequest) {
             // code for IE7+, Firefox, Chrome, Opera, Safari
             xmlHttp=new XMLHttpRequest();
           }
           else {
             // code for IE6, IE5
             xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");
           }
 alert("en la funcion "+ lv_shmd5);

           url = ''' || lv_url || twbkwbis.f_cgibin || 'pkg_simoba.sp_getmd5?in_string=''' || ';  //  EN ESTA LIGA MANDO EJECUTAR EL PKT.PROCESO DEBE ESTAR DADO DE ALTA EN MENU- SSB
           url = url.concat(lv_shmd5);// LE CONCATENO LA VARIABLEO LAS VARIABLES SI CON MAS DE 1 SE PONE  CADA UNA

           xmlHttp.onreadystatechange = function() { setServiceDesc(xmlHttp); };
           xmlHttp.open(''POST'', url, true);
           xmlHttp.send(null);
         }  //end function makeRequest(url)

   function setServiceDesc(httpRequest)  //  ESTA FUNCION RECUPERA LA RESPUESTA DE LA EJECUCION DEL PKT ANTERIOR RECOJE LA SALIDA
         {
           //
           // This function collects the response from the server
           // and puts it into a form variable
           //
           if (httpRequest.readyState == 4) {
            // if (httpRequest.status == 200) {
               if ( httpRequest.responseText ) {
                 try {
                       // get query response delimited text
                       xmlDoc=httpRequest.responseText;    //   EN ESTA LINEA RECUPERA LA SALIDA Y LA ASIGNA A LA VARIABLE
                       // set the comment item text
                       // document.getElementById("signature").innerHTML=xmlDoc;
                       document.frmLanzar.signature.value =xmlDoc;   //  LE PASAMOS EL VALOR DE LA VARIABLE AL OBJETO DEL FORMULARIO
                 } catch(e){
                       alert("errorHappendHere:" + e);
                 }
               }
               else {
                 //  document.getElementById("signature").innerHTML="";
                  document.frmLanzar.signature.value ="";
               }
          //   }
           //  else {
           //        alert(httpRequest.status);
           //        alert("02: ["+httpRequest.status+"] ' || lv_msgProblemRequest || '");
           //  }
           }
         }  //end function setServiceDesc(httpRequest)
    ');

  htp.p('</script>' );



  ----------------------------------------------aqui empiza la parte de generar el from para que sea enviado ---------------------------


htp.p('   <br>
     <table border="2" cellpadding="1" cellspacing="1" width="100%" >
   <form name="frmAction" method="post"    id="frmAction" >
                <input type="hidden" name="p_alumn" value="'||lv_pidm||'">
               <Bold> Monto A pagar: </bold>
             <input type="text" name="p_monto" id="p_monto"  value=""  >
             <br>
             <input type="radio" name="pagos"  id="pagosp"   > <img src="https://www.paypalobjects.com/webstatic/mktg/logo-center/logotipo_paypal_tarjetas.jpg" border="0" width=100, height=70 />
              <input type="radio" name="pagos" id="pagosu"   > <img src="http://www.payulatam.com/logos/logo.php?l=147=55f07ca76501f" alt="PayU Latam" border="0" resizable=yes, width=100, height=50    />
             <br>
             <input type="button" value="Enviar" onclick="Pagos( );" / >
        </form>



 ');




   -------------------------------------------esta esla parte de pruebas de lanzar un XML de los datos-------
htp.p('
<table border="0" cellpadding="0" cellspacing="1" width="100%" >
   <form name="frmdat" method="post">
    <input type="hidden" name="p_var_gbl"  ID="p_var_gbl"   value=""  >
    </form>
 ');




 HTP.P( ' <table border="0" cellpadding="1" cellspacing="1" width="100%" >
 <td class="tdfont7" valign="top" align="left">
  <form name="frmLanzar" id="frmLanzar"  method="post" action="https://stg.gateway.payulatam.com/ppp-web-gateway/"   target="new" >
  <input name="merchantId"    type="hidden"  value="500238"   >
  <input name="accountId"     type="hidden"  value="500538" >
  <input name="description"   type="hidden"  value=""  >   <!-- variable detalle del pago -->
  <input name="referenceCode"  id="referenceCode"    type="hidden"  value="" >          <!-- variable cosecutivo pidm+ntransaccion  -->
  <input name="amount"           type="hidden"      value=""   >    <!-- variable monto a pagar -->
  <input name="tax"                 type="hidden"  value="0"  >
  <input name="taxReturnBase" type="hidden"  value="0" >
  <input name="currency"         type="hidden"  value="" >   <!-- variable moneda default MNX -->
  <input name="signature"   id ="signature"    type="hidden"  value=""  > <!-- variable signature -->
  <input name="test"               type="hidden"  value=" TRUE" >
  <input name="buyerEmail"     type="hidden"  value="test@test.com" > <!-- variable email Alumno -->
  <input name="responseUrl"   type="hidden"  value="http://www.test.com/response" >
  <input name="confirmationUrl"    type="hidden"  value="http://www.test.com/confirmation" >

</form>
     ');


      ---esta debe ser la ultima lenea es la version
 twbkwbis.p_closedoc (curr_release);

 htp.p('</boby> </html> ' );

EXCEPTION
WHEN OTHERS THEN
   --  error_page(SQLERRM)        ;
  vmsjerror  :=   SQLERRM;
--insert into twpaso(valor1,valor2,valor3)  values('Error pago_ini ','revisar en  ', substr(vmsjerror,1,99)); commit;

END sp_dispList;


PROCEDURE get_alumn (p_id  IN  SPRIDEN.SPRIDEN_PIDM%TYPE  DEFAULT NULL) IS

vnumero   number;
vdescp     varchar2(60);
vperiodo   varchar2(15);
vmonto    number;
monto_total   number;

BEGIN
 -- OWA_UTIL.mime_header('text/xml');


htp.p('<html>');
htp.p('<body><br>');

 HTP.P( ' <table border="2" cellpadding="1" cellspacing="1" width="90%" >
         <td class="tdfont7" valign="top" align="left">
     ');


HTP.P('
 <script type="text/javascript">

var montototal = 0;

 function Suma(ntran,monto)  {
// alert(" estoy en sumas montos "+ ntran + monto );
       montototal = monto ;

Envio(montototal);
 Ntran(ntran);
return montototal;
}

function Resta(ntran,monto)  {
//  alert(" estoy en restas montos"+ monto );
       montototal =  monto;

Envio(montototal);
 Ntransubs(ntran);
return montototal;

}

');

------------en esta funcion Envio le estoy pasando el valor de lo que tengo en la variable montototal producto de las sumas y las restas segun sea el caso
------------lo interesante es por medio de la instruccion 2 me traigo todo el elemento aun que sea de otro frame en otro proceso como es este caso
------------desppues lo unico que hago es asignarle el valor que ya tengo en la variable. con esto podemos pasar valores entre diferentes frames en diferentes proceso
HTP.P('
function Envio(importe)
{
//alert(" estoy en Envio "+ importe );
var  frm_Action = document.getElementById ("frmLanzar");
var  frm_element_monto = document.getElementById("p_monto");
   //  document.frm_Action.frm_element_monto.value=importe;
      frm_element_monto.value=importe;

}

var array = [];

function Ntran(ntran)
{

var  frm_Action = document.getElementById ("frmAction");
var  frm_element_reference = document.getElementById("referenceCode");
   //  document.frm_Action.frm_element_monto.value=importe;

array2 = array.concat(ntran);
//alert(" estoy en reference2  "+ array2);

array.push(ntran);
//alert(" estoy en push  "+ array);


 //var transac  = transac +"-"+ ntran;
 var reference  = '||p_id ||' +"-"+ array;

  // alert(" estoy en reference-OK  "+ reference);
 frm_element_reference.value=reference;

}

function Ntransubs(ntran)
{

var  frm_Action = document.getElementById ("frmAction");
var  frm_element_reference = document.getElementById("referenceCode");
   //  document.frm_Action.frm_element_monto.value=importe;

var quitar = ntran;

//alert(" estoy en Ntransubs  "+ array);

 ////tengo que buscar la posicion de numero quitar dentro del array para quitarla con splice()

 var contador=0;
 var encontrado=0;
for( contador=0; contador < array.length; contador++ )
{
     if( array[contador] == ntran) {
         encontrado = contador;
         alert(" posicion de arreglo "+ encontrado)
         break;
    }
}
 //   aqui va quitar la opcion del arreglo con esta instruccion
 array.splice(encontrado, 1);

 // alert(" ya se quito la refer "+ array);

 var reference  = '||p_id ||' +"-"+ array;

 // alert(" estoy en reference-OK  "+ reference);
 frm_element_reference.value=reference;
}

 ');

 htp.p(' </script>' );


           twbkfrmt.P_PrintBold ( 'Datos del Alumno'  );
  FOR cur_rec IN   c_general (p_id )  LOOP

HTP.print( '<table border="0" cellpadding="0" cellspacing="0" width="80%"     >
      <form name="frmDatos" method="post">
<tr>   <td class="tdfont5" valign="top" align="left"><small>  Matricula: </small>  </td><td> <small>'  ||(cur_rec.SPRIDEN_ID)||' </small></td></tr>
<tr>   <td class="tdfont5" valign="top" align="left" ><small>Apellidos:  </small>  </td><td> <small>'  ||(cur_rec.SPRIDEN_LAST_NAME)||' </small> </td></tr>
<tr>   <td class="tdfont5" valign="top" align="left" ><small>Nombre:  </small>  </td><td> <small>'    ||(cur_rec.SPRIDEN_FIRST_NAME)||' </small> </td></tr>
<tr>   <td class="tdfont7" valign="top" align="left" ><small>Nivel:   </small> </td><td> <small> '        ||(cur_rec.STVLEVL_DESC)||' </small> </td></tr>
<tr>   <td class="tdfont7" valign="top" align="left" ><small>Periodo:    </small>  </td><td> <small>'    ||(cur_rec.SGBSTDN_TERM_CODE_EFF)||' -- '||(cur_rec.STVTERM_DESC)||' </small> </td></tr>
 </form> </TABLE>
');


END LOOP;

 HTP.P('
   <td class="tdfont7" valign="top" align="left">');
      twbkfrmt.P_PrintBold ( '     Adeudos del Alumno   --------------------   Fecha Venc.  ------------  Importe'      );

HTP.p( ' <table border="0" cellpadding="0" cellspacing="0" width="90%"     >    ');                                                                                                                                                                                                                                                           ---   to_char( sal, '$9,999.99' )
HTP.P( '  <form name="frmCursor" id="frmCursor"  method="post">  ');

for cur_deu in c_deuda (p_id )  loop
vglb_currency  := cur_deu.moneda;

------esta es toda una linea que se va repetir n-veces segun traiga datos el cursor
--<small> '||(cur_deu.Num)||' <input type="hidden"id="ntran" name="ntran"  value="'||(cur_deu.Num)||'"  /></small>
HTP.P( '
<td  valign="top" align="left" width="10%">
<TD width="45%"> <small>'||(cur_deu.descripcion)||' <input type="hidden"id="vdesc" name="vdesc"  value="'||(cur_deu.descripcion)||'"  /></small>
<TD width="30%"> <small> '||(cur_deu.periodo) || '</small> <TD width="45%"> <small> '||(to_char(cur_deu.monto,'$99,999.99') ) || ' </small>
<td>  <input type="checkbox" name="checa" id="checa"  value=""onclick="if(this.checked){Suma( '||(cur_deu.Num)||','||cur_deu.monto||');}else if(!this.checked){Resta( '||(cur_deu.Num)||','||cur_deu.monto||');}" >
 <input type="hidden" id="moneda" name="moneda" value="'||cur_deu.moneda||'" >   </td>
 <tr>');
     -- ' </small> <td>  <input type="checkbox" name="colores"  value=""  onclick=" Suma( '||cur_deu.monto||');"  /  >    </td>
--onCheck=
--if(this.checked){eval(this.getAttribute('onCheck'));}
--<label>||(cur_deu.Num)|| <input type="hidden"id="Name" name="Name" /></label>

end loop;

HTP.P( '  </tr>  </form> </table>');



htp.p('<br></body></html>');
HTP.print(' ');


EXCEPTION
  WHEN OTHERS THEN
  --   error_page(SQLERRM||'Error vicx')        ;

null;
END get_alumn;

-- PROCEDURE sp_products(cur_products  OUT pkg_simoba.products_type)   is
--/*
--este proceso sirve para generar el listado de detalle de pago para PAYPAL-----
--
--*/
--
--begin
--
-- open cur_products    for     select   TBBDETC_DETAIL_CODE, TBBDETC_DESC, TBBDETC_AMOUNT
--                                        from tbbdetc
--                                            where TBBDETC_TYPE_IND  = 'P'
--                                            AND  TBBDETC_DESC  LIKE ('#%');
                                                 ---and TBBDETC_DESC  like ('%SELECT%')  se le quito esta opcion para que trajera todo


--null;
-- end sp_products;

FUNCTION  f_products   return pkg_simoba.products_type  is
/*
este proceso sirve para generar el listado de detalle de pago para PAYPAL-----

*/
cur_products pkg_simoba.products_type;
begin

open cur_products    for     select   TBBDETC_DETAIL_CODE, TBBDETC_DESC, TBBDETC_AMOUNT
                                        from tbbdetc
                                            where TBBDETC_TYPE_IND  = 'P'
                                                  AND  TBBDETC_DESC  LIKE ('#%');


null;

return (cur_products);
end f_products;

--PROCEDURE sp_cuotas ( p_matricula varchar2 , p_nivel  varchar2 , p_campus varchar2 , p_prog varchar2 , p_moneda varchar2  ) IS
--/*
--PROCESO PARA ENVIO DE CUOTAS VENCIDAS A PAYPAL--
--
--
--*/
--v_nivel            varchar2(2)    DEFAULT NULL;
--v_campus        varchar2(6)   DEFAULT NULL;
--v_prog             varchar2(14) DEFAULT NULL;
--v_moneda        varchar2(4)   DEFAULT NULL;
-- l_http_request   UTL_HTTP.req;
--  l_http_response  UTL_HTTP.resp;
--  l_response       t_response;
--
----***********************este cursor genera el xml pero SIN el encabezado****************
-------------------------------revisar lo de las fecha debe enviar solo loa trazado al dia de hoy y un mes despues de hoy en una sumatoria--------
------------------la cve de dcat_ind   hay que cambiarla por el otro filtro que se puso en pkg_resa donde obtenemos el catalogo-----
--cursor c_deuda_venc (vpidm varchar2 ,v_nivel  varchar2 , v_campus  varchar2 , v_prog varchar2 , v_moneda  varchar2 ) is
--     select     dbms_xmlgen.getxmltype ('
--select   BB.TBBDETC_DESC descripcion,  sum(TB.TBRACCD_AMOUNT) monto_total
--from Tbraccd tb, tbbdetc bb, sgbstdn gn
--where tbraccd_pidm = '||vpidm ||'
--and TB.TBRACCD_DETAIL_CODE  = BB.TBBDETC_DETAIL_CODE
--and TB.TBRACCD_PIDM  = GN.SGBSTDN_PIDM
--and GN.SGBSTDN_LEVL_CODE  = ''' || v_nivel|| '''
--and GN.SGBSTDN_CAMP_CODE  = ''' || v_campus|| '''
--and gn.SGBSTDN_PROGRAM_1  = ''' ||v_prog|| '''
--and TB.TBRACCD_CURR_CODE =  ''' || v_moneda|| '''
--and TBRACCD_TRAN_NUMBER_PAID is null
--and TBRACCD_BALANCE   <> 0
--and TBBDETC_TYPE_IND = ''C''
--and    trunc(TBRACCD_EFFECTIVE_DATE)   <     pkg_simoba.get_Add_Month(sysdate,1)
--group by BB.TBBDETC_DESC ') as xmlresult  from dual;
--
--
--
--BEGIN
--
--v_nivel         :=  P_nivel;
--v_campus    := p_campus;
--v_prog        :=  p_prog;
--v_moneda   := p_moneda;
--
--begin
--   select SP.SPRIDEN_PIDM   into  lv_pidm
--   from spriden sp
--   where SP.SPRIDEN_ID  = TO_CHAR( p_matricula);
--exception
--when others then
--lv_pidm  :=   lv_pidm;
--end;
--
--
--
--soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>
--<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
--<SOAP-ENV:Body>  ';
--
--   select SP.SPRIDEN_PIDM   into  vpidm
--   from spriden sp
--   where SP.SPRIDEN_ID  = TO_CHAR( p_matricula);
--
--open c_deuda_venc(lv_pidm,v_nivel,v_campus,v_prog, v_moneda  ) ;
--fetch c_deuda_venc  into l_xmltype;
--close c_deuda_venc;
--
--
--dbms_output.put_line(l_xmltype.getClobVal);
--fnc_Obtiene_parcialidad_total
--resultar := (l_xmltype.getClobVal);
--
--HTP.P( soap_request);
--htp.p(resultar);
--
--HTP.P( '</SOAP-ENV:Body>
--</SOAP-ENV:Envelope>');
--
--
--EXCEPTION
--  WHEN OTHERS THEN
--   vmsjerror  :=   SQLERRM;
--
--dbms_output.put_line(vmsjerror);
--
--END sp_cuotas;


PROCEDURE sp_cuotas_mes  ( p_matricula varchar2 , p_nivel  varchar2 , p_campus varchar2 , p_prog varchar2 , p_moneda varchar2 default null , p_back   varchar2 default null   )   is


v_nivel            varchar2(2)    DEFAULT NULL;
v_campus        varchar2(6)   DEFAULT NULL;
v_prog             varchar2(14) DEFAULT NULL;
v_moneda        varchar2(4)   DEFAULT NULL;
vsalida             varchar2(1)  ;
vperiodo           varchar2(12);


cursor c_cuota_mes(lv_pidm  varchar2, v_nivel  varchar2 , v_campus  varchar2 , v_prog varchar2 , v_moneda  varchar2 )  is
select     dbms_xmlgen.getxmltype ('
select  TB.TBRACCD_TRAN_NUMBER  Num,   TB.TBRACCD_DETAIL_CODE, BB.TBBDETC_DESC descripcion,   trunc(TB.TBRACCD_EFFECTIVE_DATE) fecha_limite, TB.TBRACCD_BALANCE monto, TBRACCD_CURR_CODE moneda, TBRACCD_TERM_CODE  periodo
from Tbraccd tb, tbbdetc bb, saradap gn
where  TB.TBRACCD_DETAIL_CODE  = BB.TBBDETC_DETAIL_CODE
and TB.TBRACCD_PIDM  = GN.Saradap_PIDM
and  tbraccd_pidm = '||lv_pidm ||'
and  TBRACCD_DETAIL_CODE   in ( select   TBBDETC_DETAIL_CODE  from tbbdetc  where TBBDETC_TYPE_IND  = ''C''    )
and TBRACCD_BALANCE  <> 0
and GN.Saradap_LEVL_CODE  = ''' || v_nivel|| '''
and GN.Saradap_CAMP_CODE  = ''' || v_campus|| '''
and gn.Saradap_PROGRAM_1  = ''' ||v_prog|| '''
and (upper(TB.TBRACCD_CURR_CODE) = '''||v_moneda||''')
and TBRACCD_TRAN_NUMBER_PAID is null
and   to_chAr(TBRACCD_EFFECTIVE_DATE, ''mm'')   in (SELECT EXTRACT(MONTH FROM SYSDATE) FROM DUAL)
order by periodo
 ') as xmlresult  from dual;


begin

begin

lv_pidm :=   BANINST1.fget_pidm( p_matricula);

exception
when others then
lv_pidm  :=   lv_pidm;
end;


v_nivel         :=  P_nivel;
v_campus    := p_campus;
v_prog        :=  p_prog;
v_moneda   := p_moneda;

soap_request:= '<?xml version = "1.0" encoding = "UTF-8"?>
<SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
<SOAP-ENV:Body>  ';

Open c_cuota_mes(lv_pidm,v_nivel,v_campus,v_prog, v_moneda  );
fetch c_cuota_mes  into l_xmltype;
 if c_cuota_mes%Notfound then
    close c_cuota_mes;

--    comenta esta validacion
---insert into twpaso values('tbraccd NOFOUND', vsalida, null,null); commit;
    return;
  end if;

close c_cuota_mes;

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


end sp_cuotas_mes;

PROCEDURE  sp_getmd5 ( in_string  varchar2)   is

  cln_md5raw raw(2000);
  out_raw raw(16);

begin



  cln_md5raw := utl_raw.cast_to_raw(in_string);
  dbms_obfuscation_toolkit.md5(input=>cln_md5raw,checksum=>out_raw);
  -- return hex version (32 length)

  -- twbkfrmt.p_printtext(rawtohex(replace(out_raw, chr(10), '<br>')),null);

   htp.p(rawtohex(out_raw));
  --return rawtohex(out_raw);

---  insert into twpaso values('entro cryto', 'getMD5',in_string,out_raw); commit;


EXCEPTION WHEN OTHERS THEN
  HTP.P('NOVALID');


end sp_getmd5 ;


function f_periodo  (p_matricula  varchar2, p_programa  varchar2, p_campus  varchar2, p_nivel varchar2) return varchar2 is


lv_pidm          number:=0;
vs_periodo     varchar2(15);

begin

lv_pidm :=   BANINST1.fget_pidm( p_matricula);

select   GS.SGBSTDN_TERM_CODE_EFF   INTO  vs_periodo
from   sgbstdn gs
where GS.SGBSTDN_PIDM  = lv_pidm
and  GS.SGBSTDN_LEVL_CODE  =  p_nivel
and  GS.SGBSTDN_CAMP_CODE  =  p_campus
and  GS.SGBSTDN_PROGRAM_1   =  p_programa;


return(vs_periodo);

end;


Function  sp_reference(  p_pidm  number, p_tran_num  number, p_tex varchar2) Return Varchar2 is

v_seq_num   number:=0;
vcount         number:=0;
vcount2         number:=0;
p_tex2         varchar2(4000);
conta           number:=0;
ptex3          varchar2(4000);
perror        varchar2(4000);
verror        varchar2(4000);
begin

--select    nvl(max(TBRACDT_SEQ_NUMBER),0)   into v_seq_num
--from TBRACDT
--where TBRACDT_PIDM          = p_pidm
--and  TBRACDT_TRAN_NUMBER  = p_tran_num;



--ptex3 :=   pkg_simoba.pformato(p_tex);

select translate (p_tex,'\',' ') into ptex3 from dual;


select length (ptex3)  into vcount  from dual;

v_seq_num  := 0;

vcount2   := ceil (vcount / 60);
conta     := 1;

for x  in  1..vcount2  loop


p_tex2  := substr(ptex3,(conta),60) ;

select    nvl(max(TBRACDT_SEQ_NUMBER),0) +1  into v_seq_num
from TBRACDT
where TBRACDT_PIDM          = p_pidm
and  TBRACDT_TRAN_NUMBER  = p_tran_num;


insert into TBRACDT
(  TBRACDT_PIDM,
TBRACDT_TRAN_NUMBER,
TBRACDT_SEQ_NUMBER,
TBRACDT_PRINT_IND,
TBRACDT_ACTIVITY_DATE,
TBRACDT_TEXT,
--TBRACDT_SURROGATE_ID,
--TBRACDT_VERSION,
TBRACDT_USER_ID,
TBRACDT_DATA_ORIGIN
--TBRACDT_VPDI_CODE
) VALUES (
p_pidm,
p_tran_num,
v_seq_num,
'Y',
sysdate,
p_tex2,
'Sistemav2',
'Simoba'
);

commit;

conta  :=  conta + 60;
end loop;
verror:='EXITO';

Return verror;

EXCEPTION WHEN OTHERS THEN
    perror := p_pidm||'*'||p_tran_num||'*'||p_tex2||'*'||ptex3;
  verror:= perror ||'*'||sqlerrm;
 -- insert into borrame values (perror, verror);
Return 'Se presento el Error en la Funcion sp_reference '||  verror;

end sp_reference;



--FUNCION GENERADA PARA OBTENER EL PIDM DESDE UNA  REFERENCIA
--            *Si no encuentra lareferencia o esta es incorrceta en el PIDM  se retorna Null--

FUNCTION get_pidm_reference(p_reference in varchar2)Return number --vl_pidm out number) Return varchar2
is
 vl_pidm number;


BEGIN

select unique GORADID_PIDM
    into vl_pidm
    from GORADID
  Where GORADID_ADDITIONAL_ID = p_reference;

Return vl_pidm;

Exception
When No_data_found then
   vl_pidm := Null;
      Return vl_pidm;

 end get_pidm_reference;

FUNCTION pformato (string IN VARCHAR2) RETURN VARCHAR2
AS
    encoded VARCHAR2(32767);
    type  array_t IS varray(3) OF VARCHAR2(15);
    array array_t := array_t('AL32UTF8', 'WE8MSWIN1252', 'WE8ISO8859P1');
BEGIN
    FOR I IN 1..array.count LOOP
        encoded := CASE array(i)
            WHEN 'AL32UTF8' THEN string
            ELSE CONVERT(string, 'AL32UTF8', array(i))
        END;
        IF instr(
            rawtohex(
                utl_raw.cast_to_raw(
                    utl_i18n.raw_to_char(utl_raw.cast_to_raw(encoded), 'utf8')
                )
            ),
            'EFBFBD'
        ) = 0 THEN
            RETURN encoded;
        END IF;
    END LOOP;
    RAISE VALUE_ERROR;
END;

FUNCTION fn_insrt_pago  (p_matricula IN  varchar2,
                         P_periodo  in varchar2,
                         P_monto in FLOAT ,
                         P_code_detail  IN   varchar2 ,
                         p_effec_date IN date,
                         p_origin IN varchar2,
                         p_payment_id  IN  varchar2,
                         p_moneda in  varchar2,
                         p_trans   number default null ,
                         p_document_number in varchar2,
                         v_salida out  varchar2,
                         vs_prospecto  out varchar2,
                         vs_item out varchar2,
                         p_seqno number default null) Return pkg_simoba.salida_type

is

lv_tran_num    number;
lv_surrogate   number;
lv_desc          varchar2(100);
v_prospecto    varchar2(9):='False' ;
v_item          varchar2(9):='False' ;
v_countp       number:=0;
v_monto       number:=0;
v_monto2     number:=0;
v_moneda     varchar2(4);
v_trans         number;
vmsjer6ror    varchar2(400);
lv_Error        varchar2(2500):= null;
VL_DOM       VARCHAR2(50);
VL_TIP       VARCHAR2(5);
VL_RESPUESTA      VARCHAR2(500);
VL_CODE_DETAIL    VARCHAR2(4);
VL_PAGO_UNICO     VARCHAR2(500);
VL_CAMP           VARCHAR2(2);

cur pkg_simoba.salida_type;


--insert into twpaso values('tbraccd', 'pruebs 1 ', lv_pidm, SYSDATE); commit;
BEGIN


lv_pidm :=  fget_pidm (p_matricula);
VL_CODE_DETAIL:= P_CODE_DETAIL;
VL_CAMP :=  SUBSTR(p_matricula,1,2);


        IF VL_CAMP = '40' AND SUBSTR(P_CODE_DETAIL,1,2) != '40' THEN

          BEGIN
             SELECT ZSTPARA_PARAM_VALOR
               INTO VL_CODE_DETAIL
               FROM ZSTPARA
              WHERE ZSTPARA_MAPA_ID = 'PAGO_BOOT'
                    AND ZSTPARA_PARAM_ID = P_CODE_DETAIL;
          EXCEPTION
          WHEN OTHERS THEN
          VL_CODE_DETAIL:= P_CODE_DETAIL;
          END;

        END IF;

  ------------------------------------tenemos que validar de alguna forma el monto a pagar  pero debe funcionar para el primer pago y los pagos regulares------------------------
        BEGIN
          SELECT sum( TBRACCD_AMOUNT)
          INTO   v_monto
          FROM  TBRACCD
          WHERE TBRACCD_PIDM =   lv_pidm
          ---and   TBRACCD_TRAN_NUMBER = 1
          and  TBRACCD_DETAIL_CODE   in ( select  TBBDETC_DETAIL_CODE  from tbbdetc  where TBBDETC_TYPE_IND = 'P');
        EXCEPTION WHEN OTHERS THEN v_monto:=0;
        END;

        BEGIN
            SELECT sum( TBRACCD_AMOUNT)
          INTO   v_monto2
          FROM  TBRACCD
          WHERE TBRACCD_PIDM =   lv_pidm
          and   TBRACCD_TRAN_NUMBER = 1
          and  TBRACCD_DETAIL_CODE   in ( select  TBBDETC_DETAIL_CODE  from tbbdetc  where TBBDETC_TYPE_IND = 'C');
        EXCEPTION WHEN OTHERS THEN v_monto2:=0;
        END;

        BEGIN
        select   TBBDETC_DESC
         into  lv_desc
           from tbbdetc
           where    TBBDETC_DETAIL_CODE  = VL_CODE_DETAIL;
        EXCEPTION WHEN OTHERS THEN lv_desc:='SIN DESCRIPCION';
        END;

-----------------------------valida si es un prospecto  si o si ya es un alumno regular------------------
        BEGIN
        select  nvl(count(*),0)   into  v_countp
        from saradap
        where saradap_pidm = lv_pidm;
        EXCEPTION WHEN OTHERS THEN v_countp:=0;
        END;

        BEGIN
        SELECT TVRDCTX_CURR_CODE
            INTO  v_moneda
        FROM TAISMGR.TVRDCTX
        WHERE  TVRDCTX_DETC_CODE  = VL_CODE_DETAIL ;
        Exception
         when   others then
           v_moneda    := 'MXN';
        end;

        if p_trans = 0 then
            v_trans := null;
        else
            v_trans :=  p_trans;
        end if ;

      --  insert into twpaso values('tbraccd', lv_tran_num, P_MONTO, v_trans); commit;

--- campos
--effectiive date _>>>> dia que el alumno hizo el pago en el banco o como fuera su opcion de pago
--entry_date _>>>>> dia en el que fue registrado el pago en banner en este insert es un sisdate
----payment_id Y TBRACCD_DOCUMENT_NUMBER >>  la referencia de pago  que regreso el banco   SI ES MUY GRANDE SE REGISTRA EN 2 CAMPOS

        begin
        SELECT  NVL(MAX (TBRACCD_TRAN_NUMBER),0) +1
        INTO   lv_tran_num
          FROM  TBRACCD
          WHERE TBRACCD_PIDM =   lv_pidm ;
        EXCEPTION WHEN OTHERS THEN lv_tran_num:=1;
        END;

        Begin
            INSERT INTO  TBRACCD
            ( TBRACCD_AMOUNT  ,TBRACCD_BALANCE   ,  TBRACCD_ACTIVITY_DATE ,TBRACCD_USER   , TBRACCD_PIDM ,    TBRACCD_TRAN_NUMBER
            , TBRACCD_TERM_CODE , TBRACCD_DETAIL_CODE, TBRACCD_ENTRY_DATE,TBRACCD_EFFECTIVE_DATE, TBRACCD_SRCE_CODE,TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER, TBRACCD_DESC,  TBRACCD_TRANS_DATE,TBRACCD_CREATE_SOURCE,
             TBRACCD_DATA_ORIGIN, TBRACCD_DOCUMENT_NUMBER, TBRACCD_PAYMENT_ID  ,TBRACCD_CURR_CODE , TBRACCD_TRAN_NUMBER_PAID,TBRACCD_CROSSREF_NUMBER )
            VALUES ( P_MONTO, P_MONTO*-1,  SYSDATE, 'SistemaV2',  lv_pidm, lv_tran_num  ,  P_PERIODO, VL_CODE_DETAIL, sysdate, trunc(p_effec_date),'T', 'Y', 0, lv_desc , p_effec_date, p_origin, p_origin, p_document_number, p_payment_id,  v_moneda, v_trans,p_seqno  );
        Exception
        When Others then
           lv_Error := 'Se presento el Error al Insertar Tbraccd'||sqlerrm;
        End;

        If lv_Error is  null then

            v_salida:=lv_tran_num; ------Esta es la var num_tran de salida
            IF  v_countp  >   0  then
            v_prospecto  :=  'True';  ---  SI se  encontro alumno es un prospecto
            else
            v_prospecto  :=  'False';  ----NO se encontro alumno es una persona
            end if;

            vs_prospecto  := v_prospecto;

            If  v_monto >= 1000  or v_monto >=  v_monto2  and substr (p_matricula,1,2) != '46' then
             v_item  := 'True';
            Elsif   v_monto >=  v_monto2  and substr (p_matricula,1,2) = '46' then
               v_item  := 'True';
             else
             v_item  := 'False';
            end if;
             vs_item  := v_item;

             lv_Error:='Exito';
        End if;

        BEGIN

            SELECT TBBDETC_DESC
            INTO VL_DOM
            FROM TBBDETC
            WHERE TBBDETC_DESC LIKE ('%DOM')
            AND TBBDETC_DCAT_CODE ='CSH'
            AND TBBDETC_DETAIL_CODE = VL_CODE_DETAIL
            ;

            VL_TIP:='PAGO';

        EXCEPTION
        WHEN NO_DATA_FOUND THEN

            BEGIN

                SELECT TBBDETC_DESC
                INTO VL_DOM
                FROM TBBDETC
                WHERE TBBDETC_DESC = 'DESCUENTO POR DOMICILIACION'
                AND TBBDETC_DETAIL_CODE = VL_CODE_DETAIL
                ;

                VL_TIP:='DESC';

            EXCEPTION
            WHEN OTHERS THEN
            VL_DOM:=NULL;
            VL_TIP:=NULL;
            END;

        END;

        IF VL_DOM IS NOT NULL AND P_ORIGIN NOT LIKE '%MANU' THEN

            VL_RESPUESTA:= PKG_SIMOBA.F_PAGOS_AMARRE (LV_PIDM,LV_TRAN_NUM,VL_TIP);

        END IF;

        BEGIN /* se ejecuta proceso de pago unico para dispercion bancaria */
          VL_PAGO_UNICO:= PKG_FINANZAS_REZA.F_APLICA_PUNI_SIU ( LV_PIDM);
        END;

      open cur for select v_salida, vs_prospecto, vs_item, lv_Error from dual;
      Return (cur);

EXCEPTION
  WHEN OTHERS THEN
  vmsjer6ror  :=   SQLERRM;
  lv_Error := 'Se presento un Error General'||sqlerrm;
      open cur for select v_salida, vs_prospecto, vs_item, lv_Error from dual;
      Return (cur);
--  htp.p( vmsjerror);
end;


FUNCTION insrt_tzconcdr(p_pidm in  number, p_tran_numb in number, p_payment_id in varchar2, p_amount in number, p_detail_code in varchar2, p_tran_date in varchar2)Return Varchar2
is

vl_msje varchar(250):='Exito';

    begin
        insert into TZCONDR values(p_pidm, p_tran_numb, p_payment_id, p_amount, p_detail_code,to_date( p_tran_date,'dd/mm/yyyy'));
        commit;
        return vl_msje;
    exception when others then
    vl_msje:='Error en insrt_tzconcdr'||sqlerrm;
    return vl_msje;

end insrt_tzconcdr;


FUNCTION fnc_Obtiene_parcialidad (p_pidm in number) RETURN pkg_simoba.parcialidad_out

---- Esta funcion obtiene la parcialidad mas antigua que tenga saldo para realizar el cobro de la domiciliacion
As
    c_parcialidad_out pkg_simoba.parcialidad_out;


       v_error varchar(250):='Exito';

    Begin

                        begin
                               Open c_parcialidad_out
                               For
                                    select   distinct spriden_pidm PIDM,  TBRACCD_BALANCE p_amount , TBRACCD_EFFECTIVE_DATE p_venc_date , c.tbraccd_detail_code p_detail_code , TBRACCD_DESC p_desc
                                    from tbbdetc a, spriden b, tbraccd c
                                    WHERE a.TBBDETC_DCAT_CODE = 'COL'
                                    and b.spriden_pidm = p_pidm
                                    and substr (b.spriden_id, 1, 2 )  = substr (a.tbbdetc_detail_code, 1, 2)
                                    and  a.TBBDETC_DESC like 'PARCIALIDAD%'
                                    and b.spriden_pidm = c.tbraccd_pidm
                                    And a.tbbdetc_detail_code = c.tbraccd_detail_code
                                    and b.spriden_change_ind is null
                                    And c.TBRACCD_BALANCE >0
                                    And c.TBRACCD_EFFECTIVE_DATE  <= sysdate
                                    And c.TBRACCD_EFFECTIVE_DATE = (select min (c1.TBRACCD_EFFECTIVE_DATE)
                                                                                            from TBRACCD c1
                                                                                            Where c.tbraccd_pidm = c1.tbraccd_pidm
                                                                                            And c.tbraccd_detail_code = c1.tbraccd_detail_code
                                                                                            And c1.TBRACCD_BALANCE >0);
                        Exception
                        When Others then
                        null;
                        End;

                        RETURN (c_parcialidad_out);

    Exception
        when Others then
        v_error:='Se presento el Error:= '||sqlerrm;
                       open c_parcialidad_out for select null, null,  null, null, v_error from dual;
                                RETURN (c_parcialidad_out);

    End fnc_Obtiene_parcialidad;


FUNCTION FNC_OBTIENE_PARCIALIDAD_TOTAL (P_PIDM IN NUMBER) RETURN VARCHAR IS

---- Esta funcion obtiene los conceptos mas antiguos de parcialidad, intereses y accesorios  mas antigua que tenga saldo para realizar el cobro de la domiciliacion
---- Se modifica funci n para traer los conceptos vencidos en el mes en curso y se cambia el tipo de retorno a varchar --- reza 14/10/2019

VL_COLEGIATURA      NUMBER;
VL_COMPLEMENTO      NUMBER;
VL_PAGOS            NUMBER;
VL_RETORNA          VARCHAR2(500);
VL_EXISTE           NUMBER;
VL_PAID             NUMBER;
vl_favor            NUMBER;
vl_sobra            NUMBER;


BEGIN

     Begin
     
        select sum (TBRACCD_BALANCE) *-1
            Into vl_favor
        FROM TBRACCD
        join tbbdetc on tbbdetc_detail_code = tbraccd_detail_code and TBBDETC_TYPE_IND = 'P'
        WHERE TBRACCD_PIDM = P_PIDM;   
     Exception
        When Others then 
          vl_favor:=0;  
     End;
            



     IF TO_NUMBER(TO_CHAR(SYSDATE,'dd')) IN (1,2,3) THEN

        BEGIN
                select sum (x.P_AMOUNT)
                      INTO VL_COLEGIATURA
                from (
                  SELECT DISTINCT
                           SUM (TBRACCD_BALANCE) P_AMOUNT
                      FROM TBBDETC A, SPRIDEN B, TBRACCD C
                     WHERE     1 = 1
                           AND A.TBBDETC_TYPE_IND = 'C'
                           AND A.TBBDETC_DCAT_CODE IN ('COL')
                           AND B.SPRIDEN_PIDM = P_PIDM
                           AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                           AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                           AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                           AND C.TBRACCD_BALANCE != 0
                           AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                           AND B.SPRIDEN_CHANGE_IND IS NULL
                  GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                  union
                    SELECT DISTINCT
                           SUM (TBRACCD_BALANCE) P_AMOUNT
                      FROM TBBDETC A, SPRIDEN B, TBRACCD C
                     WHERE     1 = 1
                           AND A.TBBDETC_TYPE_IND = 'C'
                           AND B.SPRIDEN_PIDM = P_PIDM
                           AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                           AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                           AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                           AND C.TBRACCD_BALANCE != 0
                           AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                           AND B.SPRIDEN_CHANGE_IND IS NULL
                           And substr (C.TBRACCD_DETAIL_CODE,3,2) in ( select distinct STVPAQT_DETAIL_CODE
                                                                                                from SZTALIA
                                                                                                join STVPAQT  on STVPAQT_ADID_CODE = SZTALIA_CODE
                                                                                              )
                  GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                  ) x  ;

       EXCEPTION
       WHEN OTHERS THEN
       VL_COLEGIATURA:=0;
       END;

       BEGIN
            SELECT DISTINCT
                   SUM (TBRACCD_BALANCE) P_AMOUNT
              INTO VL_COMPLEMENTO
              FROM TBBDETC A, SPRIDEN B, TBRACCD C
             WHERE     1 = 1
                   AND A.TBBDETC_TYPE_IND = 'C'
                   AND SUBSTR (A.TBBDETC_DETAIL_CODE, 3, 2) IN (     select distinct ZSTPARA_PARAM_VALOR
                                                                                                   from ZSTPARA
                                                                                                   where ZSTPARA_MAPA_ID = 'COD_DOMICILIACI'
                                                                                            )
                   AND B.SPRIDEN_PIDM = P_PIDM
                   AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                   AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                   AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                   AND C.TBRACCD_BALANCE > 0
                   AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                   AND B.SPRIDEN_CHANGE_IND IS NULL
          GROUP BY SPRIDEN_PIDM;

       EXCEPTION
       WHEN OTHERS THEN
       VL_COMPLEMENTO:=0;
       END;

       BEGIN
            SELECT DISTINCT
                   SUM (TBRACCD_BALANCE) P_AMOUNT
              INTO VL_PAGOS
              FROM TBBDETC A, SPRIDEN B, TBRACCD C
             WHERE     1 = 1
                   AND B.SPRIDEN_PIDM = P_PIDM
                   AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                   AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                   AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                   AND C.TBRACCD_BALANCE != 0
                   AND A.TBBDETC_DCAT_CODE NOT IN ('TUI','DSP','LPC')
                   AND A.TBBDETC_DESC NOT LIKE 'DSI COLE %'
                   AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                   AND B.SPRIDEN_CHANGE_IND IS NULL
          GROUP BY SPRIDEN_PIDM;

       EXCEPTION
       WHEN OTHERS THEN
       VL_PAGOS:=0;
       END;

       IF VL_PAGOS < (VL_COLEGIATURA+VL_COMPLEMENTO) THEN
          IF VL_PAGOS <= VL_COMPLEMENTO THEN
             If vl_favor > 0 then 
                If vl_favor >= VL_PAGOS then 
                    VL_PAGOS:=0;
                Elsif vl_favor < VL_PAGOS then
                   VL_PAGOS := VL_PAGOS - vl_favor;
                End if;
             End if;
             VL_RETORNA:= 0||','||VL_PAGOS;
          ELSE
             If vl_favor > 0 then 
                If vl_favor >= VL_PAGOS then
                   VL_PAGOS:=0;
                Elsif vl_favor < VL_PAGOS then
                   VL_PAGOS := VL_PAGOS - vl_favor;
                End if;
             End if;          
            VL_RETORNA:= VL_PAGOS||','||0;
          END IF;
       ELSE
            If vl_favor = VL_COLEGIATURA then 
               vl_sobra:= 0;
               VL_COLEGIATURA:=0;
            Elsif vl_favor > vl_colegiatura then 
               vl_sobra:= vl_favor - vl_colegiatura;
                VL_COLEGIATURA:=0;
            Elsif vl_favor < vl_colegiatura then 
               vl_sobra:= 0;
                VL_COLEGIATURA:=VL_COLEGIATURA -vl_favor;
            End if;    
            If VL_COMPLEMENTO > 0 then
                If vl_sobra =VL_COMPLEMENTO then 
                    VL_COMPLEMENTO:=0;
                ElsIf vl_sobra > VL_COMPLEMENTO then 
                    VL_COMPLEMENTO:=0;  
                ElsIf vl_sobra < VL_COMPLEMENTO then 
                    VL_COMPLEMENTO:=VL_COMPLEMENTO - vl_sobra;
                End if;  
            End if;                             
            VL_RETORNA:= VL_COLEGIATURA||','||VL_COMPLEMENTO;
       END IF;

           BEGIN

               Select max (x.transaccion)
                         INTO VL_PAID
                from  (
                  SELECT NVL(A.TBRACCD_TRAN_NUMBER_PAID,0) transaccion
              FROM TBRACCD A
              WHERE 1= 1
              And A.TBRACCD_PIDM = P_PIDM
              AND A.TBRACCD_TRAN_NUMBER =( SELECT MAX(TBRACCD_TRAN_NUMBER)
                                              FROM TBBDETC A, SPRIDEN B, TBRACCD C
                                             WHERE     1 = 1
                                                   AND A.TBBDETC_TYPE_IND = 'C'
                                                   AND A.TBBDETC_DCAT_CODE IN ('COL')
                                                   AND B.SPRIDEN_PIDM = P_PIDM
                                                   AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                                                   AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                                                   AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                                                   AND C.TBRACCD_BALANCE != 0
                                                   AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                                                   AND B.SPRIDEN_CHANGE_IND IS NULL)
                  union
                    SELECT NVL(A.TBRACCD_TRAN_NUMBER_PAID,0) transaccion
              FROM TBRACCD A
              WHERE 1= 1
              And A.TBRACCD_PIDM = P_PIDM
              AND A.TBRACCD_TRAN_NUMBER =( SELECT MAX(TBRACCD_TRAN_NUMBER)
                                                                    FROM TBBDETC A, SPRIDEN B, TBRACCD C
                                                                    WHERE     1 = 1
                                                                    AND A.TBBDETC_TYPE_IND = 'C'
                                                                       AND B.SPRIDEN_PIDM = P_PIDM
                                                                    AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                                                                    AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                                                                    AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                                                                    AND C.TBRACCD_BALANCE != 0
                                                                    AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                                                                    AND B.SPRIDEN_CHANGE_IND IS NULL
                                                                    )
                   And substr (a.TBRACCD_DETAIL_CODE,3,2) in ( select distinct STVPAQT_DETAIL_CODE
                                                                                        from SZTALIA
                                                                                        join STVPAQT  on STVPAQT_ADID_CODE = SZTALIA_CODE
                                                                                      )
                ) x;

           EXCEPTION
           WHEN OTHERS THEN
           VL_COLEGIATURA:=0;
           END;

           BEGIN

                SELECT COUNT(*)
                INTO VL_EXISTE
                FROM TBRACCD,TBBDETC
                WHERE 1=1
                AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
                AND TBBDETC_DCAT_CODE = 'CSH'
                AND TBRACCD_PIDM = P_PIDM
                AND TBBDETC_DESC LIKE '%DOM'
                AND TBRACCD_TRAN_NUMBER = VL_PAID;

           END;

           IF VL_EXISTE > 0 THEN
           VL_RETORNA:= 0||','||0;
           END IF;

    ELSE

       BEGIN


               select sum (x.P_AMOUNT)
                      INTO VL_COLEGIATURA
                from (
                  SELECT DISTINCT
                           SUM (TBRACCD_BALANCE) P_AMOUNT
                      FROM TBBDETC A, SPRIDEN B, TBRACCD C
                     WHERE     1 = 1
                           AND A.TBBDETC_TYPE_IND = 'C'
                           AND A.TBBDETC_DCAT_CODE IN ('COL')
                           AND B.SPRIDEN_PIDM = P_PIDM
                           AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                           AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                           AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                           AND C.TBRACCD_BALANCE != 0
                           AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                           AND B.SPRIDEN_CHANGE_IND IS NULL
                  GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                  union
                    SELECT DISTINCT
                           SUM (TBRACCD_BALANCE) P_AMOUNT
                      FROM TBBDETC A, SPRIDEN B, TBRACCD C
                     WHERE     1 = 1
                           AND A.TBBDETC_TYPE_IND = 'C'
                           AND B.SPRIDEN_PIDM = P_PIDM
                           AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                           AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                           AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                           AND C.TBRACCD_BALANCE != 0
                           AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                           AND B.SPRIDEN_CHANGE_IND IS NULL
                           And substr (C.TBRACCD_DETAIL_CODE,3,2) in ( select distinct STVPAQT_DETAIL_CODE
                                                                                                from SZTALIA
                                                                                                join STVPAQT  on STVPAQT_ADID_CODE = SZTALIA_CODE
                                                                                              )
                  GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                  ) x  ;


       EXCEPTION
       WHEN OTHERS THEN
       VL_COLEGIATURA:=0;
       END;

       BEGIN
            SELECT DISTINCT
                   SUM (TBRACCD_BALANCE) P_AMOUNT
              INTO VL_COMPLEMENTO
              FROM TBBDETC A, SPRIDEN B, TBRACCD C
             WHERE     1 = 1
                   AND A.TBBDETC_TYPE_IND = 'C'
                   AND SUBSTR (A.TBBDETC_DETAIL_CODE, 3, 2) IN (     select distinct ZSTPARA_PARAM_VALOR
                                                                                                   from ZSTPARA
                                                                                                   where ZSTPARA_MAPA_ID = 'COD_DOMICILIACI'
                                                                                            )
                   AND B.SPRIDEN_PIDM = P_PIDM
                   AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                   AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                   AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                   AND C.TBRACCD_BALANCE > 0
                   AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
    --               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) <= LAST_DAY (TRUNC (SYSDATE))
    --               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT   TRUNC (SYSDATE)- (  TO_NUMBER (TO_CHAR (TRUNC (SYSDATE), 'DD'))- 1)FROM DUAL)
                   AND B.SPRIDEN_CHANGE_IND IS NULL
          GROUP BY SPRIDEN_PIDM;

       EXCEPTION
       WHEN OTHERS THEN
       VL_COMPLEMENTO:=0;
       END;

       BEGIN
            SELECT SUM (TBRACCD_BALANCE) P_AMOUNT
              INTO VL_PAGOS
              FROM TBBDETC A, SPRIDEN B, TBRACCD C
             WHERE     1 = 1
                   AND B.SPRIDEN_PIDM = P_PIDM
                   AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                   AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                   AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                   AND C.TBRACCD_BALANCE != 0
                   AND A.TBBDETC_DCAT_CODE NOT IN ('TUI','DSP','LPC')
                   AND A.TBBDETC_DESC NOT LIKE 'DSI COLE %'
                   AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
                  -- AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) <= LAST_DAY (TRUNC (SYSDATE))
                   AND B.SPRIDEN_CHANGE_IND IS NULL
          GROUP BY SPRIDEN_PIDM;

       EXCEPTION
       WHEN OTHERS THEN
       VL_PAGOS:=0;
       END;

       IF VL_PAGOS < (VL_COLEGIATURA+VL_COMPLEMENTO) THEN
          IF VL_PAGOS <= VL_COMPLEMENTO THEN
             If vl_favor > 0 then 
                If vl_favor >= VL_PAGOS then 
                    VL_PAGOS:=0;
                Elsif vl_favor < VL_PAGOS then
                   VL_PAGOS := VL_PAGOS - vl_favor;
                End if;
             End if;
             VL_RETORNA:= 0||','||VL_PAGOS;
          ELSE
             If vl_favor > 0 then 
                If vl_favor >= VL_PAGOS then
                   VL_PAGOS:=0;
                Elsif vl_favor < VL_PAGOS then
                   VL_PAGOS := VL_PAGOS - vl_favor;
                End if;
             End if;          
            VL_RETORNA:= VL_PAGOS||','||0;
          END IF;
       ELSE
            If vl_favor = VL_COLEGIATURA then 
               vl_sobra:= 0;
               VL_COLEGIATURA:=0;
            Elsif vl_favor > vl_colegiatura then 
               vl_sobra:= vl_favor - vl_colegiatura;
                VL_COLEGIATURA:=0;
            Elsif vl_favor < vl_colegiatura then 
               vl_sobra:= 0;
                VL_COLEGIATURA:=VL_COLEGIATURA -vl_favor;
            End if;    
            If VL_COMPLEMENTO > 0 then
                If vl_sobra =VL_COMPLEMENTO then 
                    VL_COMPLEMENTO:=0;
                ElsIf vl_sobra > VL_COMPLEMENTO then 
                    VL_COMPLEMENTO:=0;  
                ElsIf vl_sobra < VL_COMPLEMENTO then 
                    VL_COMPLEMENTO:=VL_COMPLEMENTO - vl_sobra;
                End if;   
            End if;                             
            VL_RETORNA:= VL_COLEGIATURA||','||VL_COMPLEMENTO;
       END IF;

       BEGIN

              Select max (x.transaccion)
                         INTO VL_PAID
                from  (
                  SELECT NVL(A.TBRACCD_TRAN_NUMBER_PAID,0) transaccion
              FROM TBRACCD A
              WHERE 1= 1
              And A.TBRACCD_PIDM = P_PIDM
              AND A.TBRACCD_TRAN_NUMBER =( SELECT MAX(TBRACCD_TRAN_NUMBER)
                                              FROM TBBDETC A, SPRIDEN B, TBRACCD C
                                             WHERE     1 = 1
                                                   AND A.TBBDETC_TYPE_IND = 'C'
                                                   AND A.TBBDETC_DCAT_CODE IN ('COL')
                                                   AND B.SPRIDEN_PIDM = P_PIDM
                                                   AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                                                   AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                                                   AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                                                   AND C.TBRACCD_BALANCE != 0
                                                   AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))
    --                                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) <= LAST_DAY (TRUNC (SYSDATE))
    --                                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT   TRUNC (SYSDATE)- (  TO_NUMBER (TO_CHAR (TRUNC (SYSDATE), 'DD'))- 1)FROM DUAL)
                                                   AND B.SPRIDEN_CHANGE_IND IS NULL)
                  union
                    SELECT NVL(A.TBRACCD_TRAN_NUMBER_PAID,0) transaccion
              FROM TBRACCD A
              WHERE 1= 1
              And A.TBRACCD_PIDM = P_PIDM
              AND A.TBRACCD_TRAN_NUMBER =( SELECT MAX(TBRACCD_TRAN_NUMBER)
                                                                    FROM TBBDETC A, SPRIDEN B, TBRACCD C
                                                                    WHERE     1 = 1
                                                                    AND A.TBBDETC_TYPE_IND = 'C'
                                                                       AND B.SPRIDEN_PIDM = P_PIDM
                                                                    AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                                                                    AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                                                                    AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                                                                    AND C.TBRACCD_BALANCE != 0
                                                                    AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between trunc (sysdate, 'MM') and TRUNC(LAST_DAY(SYSDATE))                                                                
    --                                                                AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) <= LAST_DAY (TRUNC (SYSDATE))
    --                                                                AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT   TRUNC (SYSDATE)- (  TO_NUMBER (TO_CHAR (TRUNC (SYSDATE), 'DD'))- 1)FROM DUAL)
                                                                    AND B.SPRIDEN_CHANGE_IND IS NULL
                                                                    )
                   And substr (a.TBRACCD_DETAIL_CODE,3,2) in ( select distinct STVPAQT_DETAIL_CODE
                                                                                        from SZTALIA
                                                                                        join STVPAQT  on STVPAQT_ADID_CODE = SZTALIA_CODE
                                                                                      )
                ) x;

       EXCEPTION
       WHEN OTHERS THEN
       VL_PAID:=0;
       END;

       BEGIN

            SELECT COUNT(*)
            INTO VL_EXISTE
            FROM TBRACCD,TBBDETC
            WHERE 1=1
            AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
            AND TBBDETC_DCAT_CODE = 'CSH'
            AND TBRACCD_PIDM = P_PIDM
            AND TBBDETC_DESC LIKE '%DOM'
            AND TBRACCD_TRAN_NUMBER = VL_PAID;

       END;

       IF VL_EXISTE > 0 THEN
       VL_RETORNA:= 0||','||0;
       END IF;

    END IF;

 RETURN(VL_RETORNA);

END FNC_OBTIENE_PARCIALIDAD_TOTAL;

FUNCTION fn_insrt_pago_siu  (p_matricula IN  varchar2,  P_monto in FLOAT , P_code_detail  IN   varchar2 ,  p_effec_date IN varchar2, p_origin IN varchar2, p_payment_id  IN  varchar2,
                                          p_moneda in  varchar2,  p_document_number in varchar2,p_folio in varchar2 ) Return varchar2

is

lv_tran_num    number;
lv_surrogate   number;
lv_desc          varchar2(100);
v_prospecto    varchar2(9):='False' ;
v_item          varchar2(9):='False' ;
v_countp       number:=0;
v_monto       number:=0;
v_monto2     number:=0;
v_moneda     varchar2(4);
vmsjer6ror    varchar2(400);
lv_Error        varchar2(2500):= 'EXITO';
lv_camp varchar2(2);
lv_periodo varchar2(6);

vl_seq_number1 varchar2(70):=null;
vl_seq_number2 varchar2(70):=null;
v_study     number;

--insert into twpaso values('tbraccd', 'pruebs 1 ', lv_pidm, SYSDATE); commit;
BEGIN

lv_camp:= substr(P_MATRICULA,1,2);
lv_periodo:= fget_periodo_general(lv_camp,P_EFFEC_DATE);
lv_pidm :=  fget_pidm (p_matricula);

  ------------------------------------tenemos que validar de alguna forma el monto a pagar  pero debe funcionar para el primer pago y los pagos regulares------------------------
        BEGIN
          SELECT sum( TBRACCD_AMOUNT)
          INTO   v_monto
          FROM  TBRACCD
          WHERE TBRACCD_PIDM =   lv_pidm
          ---and   TBRACCD_TRAN_NUMBER = 1
          and  TBRACCD_DETAIL_CODE   in ( select  TBBDETC_DETAIL_CODE  from tbbdetc  where TBBDETC_TYPE_IND = 'P');
        EXCEPTION WHEN OTHERS THEN v_monto:=0;
        END;

        BEGIN
            SELECT sum( TBRACCD_AMOUNT)
          INTO   v_monto2
          FROM  TBRACCD
          WHERE TBRACCD_PIDM =   lv_pidm
          and   TBRACCD_TRAN_NUMBER = 1
          and  TBRACCD_DETAIL_CODE   in ( select  TBBDETC_DETAIL_CODE  from tbbdetc  where TBBDETC_TYPE_IND = 'C');
        EXCEPTION WHEN OTHERS THEN v_monto2:=0;
        END;

        BEGIN
        select   TBBDETC_DESC
         into  lv_desc
           from tbbdetc
           where    TBBDETC_DETAIL_CODE  = P_CODE_DETAIL;
        EXCEPTION WHEN OTHERS THEN lv_desc:='SIN DESCRIPCION';
        END;

-----------------------------valida si es un prospecto  si o si ya es un alumno regular------------------
        BEGIN
        select  nvl(count(*),0)   into  v_countp
        from saradap
        where saradap_pidm = lv_pidm;
        EXCEPTION WHEN OTHERS THEN v_countp:=0;
        END;

        BEGIN
        SELECT TVRDCTX_CURR_CODE
            INTO  v_moneda
        FROM TAISMGR.TVRDCTX
        WHERE  TVRDCTX_DETC_CODE  = P_code_detail ;
        Exception
         when   others then
           v_moneda    := 'MXN';
        end;




        vl_seq_number1:= substr(p_payment_id,1,60);
        vl_seq_number2:= substr(p_payment_id,61,121);


        begin
        SELECT  NVL(MAX (TBRACCD_TRAN_NUMBER),0) +1
        INTO   lv_tran_num
          FROM  TBRACCD
          WHERE TBRACCD_PIDM =   lv_pidm ;
        EXCEPTION WHEN OTHERS THEN lv_tran_num:=1;
        END;


/*    +++++++  calcula el study_path  para insertarlo en tbraccd            vic 09/may/2018      */
begin
select distinct SORLCUR_APPL_KEY_SEQNO
 into  v_study
from sorlcur c
where c.sorlcur_pidm = lv_pidm
and  c.SORLCUR_SEQNO  = ( select max(SORLCUR_SEQNO) from sorlcur c2
                        where c2.sorlcur_pidm = c.sorlcur_pidm
                        and  c2.SORLCUR_LMOD_CODE = 'LEARNER'
                        and  c2.SORLCUR_CACT_CODE =  'ACTIVE'  );
exception when others then
v_study := 1;

end;


        Begin

          INSERT INTO  TBRACCD
            ( TBRACCD_AMOUNT  ,TBRACCD_BALANCE   ,  TBRACCD_ACTIVITY_DATE ,TBRACCD_USER   , TBRACCD_PIDM ,    TBRACCD_TRAN_NUMBER
            , TBRACCD_TERM_CODE , TBRACCD_DETAIL_CODE, TBRACCD_ENTRY_DATE,TBRACCD_EFFECTIVE_DATE, TBRACCD_SRCE_CODE,TBRACCD_ACCT_FEED_IND, TBRACCD_SESSION_NUMBER, TBRACCD_DESC,  TBRACCD_TRANS_DATE,TBRACCD_CREATE_SOURCE,
             TBRACCD_DATA_ORIGIN, TBRACCD_DOCUMENT_NUMBER, TBRACCD_PAYMENT_ID  ,TBRACCD_CURR_CODE , TBRACCD_TRAN_NUMBER_PAID,TBRACCD_STSP_KEY_SEQUENCE)
            VALUES ( P_MONTO, P_MONTO*-1,  SYSDATE, p_origin,  lv_pidm, lv_tran_num  ,  lv_periodo, P_CODE_DETAIL, sysdate, trunc(sysdate),'T', 'Y', 0, lv_desc , to_date(p_effec_date, 'dd/mm/rrrr'), 'Manual', 'PAGMAN', SUBSTR(p_folio,1,8), null,  v_moneda, null ,v_study );

        Exception
        When Others then
           lv_Error := 'Se presento el Error al Insertar Tbraccd'||sqlerrm;
        End;

        If lv_Error = 'EXITO'  then
        --------------------aqui metenmos la segunda parte  de proceso-----------------no hubo fallos en tbraccd-----
          BEGIN

                    if vl_seq_number1 is not null and vl_seq_number2 IS NULL THEN
                            dbms_output.put_line( 'inicia 3 '||vl_seq_number2 );

                                Insert into TBRACDT
                                     Values
                                           (lv_pidm,--tbracdt_pidm
                                            lv_tran_num,--tbracdt_tran_number
                                            1, ---(select nvl(max(tbracdt_seq_number),0)+1 from TBRACDT where TBRACDT_PIDM = lv_pidm and tbracdt_tran_number = vl_secuencia),--tbracdt_seq_number
                                            vl_seq_number1,--tbracdt_text
                                            'Y', --tbracdt_print_ind
                                            SYSDATE, ---tbracdt_activity_date
                                            NULL,--TBRACDT_SURROGATE_ID
                                            NULL,--TBRACDT_VERSION
                                            p_origin, --tbracdt_user_id
                                            'MANUAL',--TBRACDT_DATA_ORIGIN
                                            NULL);---TBRACDT_VPDI_CODE
                                Insert into TBRACDT
                                     Values
                                           (lv_pidm,--tbracdt_pidm
                                            lv_tran_num,--tbracdt_tran_number
                                            2,--tbracdt_seq_number
                                            p_folio,--tbracdt_text
                                            'Y', --tbracdt_print_ind
                                            SYSDATE, ---tbracdt_activity_date
                                            NULL,--TBRACDT_SURROGATE_ID
                                            NULL,--TBRACDT_VERSION
                                            p_origin, --tbracdt_user_id
                                            'MANUAL',--TBRACDT_DATA_ORIGIN
                                            NULL);---TBRACDT_VPDI_CODE

                    ELSIF vl_seq_number1 is not null and vl_seq_number2 IS NOT NULL THEN
                           dbms_output.put_line( 'inicia 4 '||vl_seq_number1 );
                                Insert into TBRACDT
                                     Values
                                           (lv_pidm,--tbracdt_pidm
                                            lv_tran_num,--tbracdt_tran_number
                                             1, -- (select nvl(max(tbracdt_seq_number),0)+1 from TBRACDT where TBRACDT_PIDM = lv_pidm and tbracdt_tran_number = vl_secuencia), --tbracdt_seq_number
                                            vl_seq_number1,--tbracdt_text
                                            'Y', --tbracdt_print_ind
                                            SYSDATE, ---tbracdt_activity_date
                                            NULL,--TBRACDT_SURROGATE_ID
                                            NULL,--TBRACDT_VERSION
                                            p_origin, --tbracdt_user_id
                                            'MANUAL',--TBRACDT_DATA_ORIGIN
                                            NULL);---TBRACDT_VPDI_CODE
                          dbms_output.put_line(' tbracdt 1 '|| lv_pidm||'-'||'-'|| 1  );
                                Insert into TBRACDT
                                     Values
                                           (lv_pidm,--tbracdt_pidm
                                            lv_tran_num,--tbracdt_tran_number
                                            2,--tbracdt_seq_number
                                            p_folio,--tbracdt_text
                                            'Y', --tbracdt_print_ind
                                            SYSDATE, ---tbracdt_activity_date
                                            NULL,--TBRACDT_SURROGATE_ID
                                            NULL,--TBRACDT_VERSION
                                            p_origin, --tbracdt_user_id
                                            'MANUAL',--TBRACDT_DATA_ORIGIN
                                            NULL);---TBRACDT_VPDI_CODE
                           dbms_output.put_line(' tbracdt 2 '|| lv_pidm||'-'|| 2  );

                    END IF;
            Commit;
          Exception
            when Others then
            lv_Error:='Se presento el Error insertar TBRACDT:= '||sqlerrm;

            dbms_output.put_line( lv_Error);

          End;

          BEGIN

            INSERT INTO PAGOS_MANUALES
                                VALUES(lv_pidm,
                                            lv_tran_num,
                                            lv_periodo,
                                            P_CODE_DETAIL,
                                            p_origin,
                                            SYSDATE,
                                            P_MONTO,
                                            to_date(p_effec_date, 'dd/mm/rrrr'),
                                            lv_desc,
                                            SYSDATE,
                                            p_document_number,
                                            'PAGMAN',
                                            'Manual',
                                            p_folio);

          EXCEPTION
          WHEN OTHERS THEN
          RAISE_APPLICATION_ERROR (-20002,'Contando '||sqlerrm);

          END;

        End if;

      Return lv_Error;

EXCEPTION
  WHEN OTHERS THEN
  vmsjer6ror  :=   SQLERRM;
  lv_Error := 'Se presento un Error General'||sqlerrm;
      Return lv_Error;

            dbms_output.put_line( lv_Error);

end fn_insrt_pago_siu;


FUNCTION F_PAGOS_AMARRE (P_PIDM NUMBER,P_TRAN NUMBER,P_TIP VARCHAR2) RETURN VARCHAR2 IS

VL_ERROR VARCHAR2(500):='EXITO';

BEGIN

    IF P_TIP = 'PAGO' THEN

        IF TO_NUMBER(TO_CHAR(SYSDATE,'dd')) IN (1,2,3) THEN

            BEGIN

                   FOR CARGOS IN (

                       SELECT DISTINCT TBRACCD_PIDM,TBRACCD_TRAN_NUMBER
                        FROM TBBDETC A, SPRIDEN B, TBRACCD C
                        WHERE A.TBBDETC_TYPE_IND = 'C'
                        AND A.TBBDETC_DCAT_CODE IN ('COL','INT')
                        AND B.SPRIDEN_PIDM = P_PIDM
                        AND SUBSTR (B.SPRIDEN_ID, 1, 2 )  = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                        AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                        AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                        AND C.TBRACCD_BALANCE >0
                        AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE-3))
                        AND TO_DATE(TRUNC(C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE-3) - (TO_NUMBER(TO_CHAR(SYSDATE-3,'DD')) - 1) FROM DUAL)
                        AND B.SPRIDEN_CHANGE_IND IS NULL
                        UNION
                        SELECT DISTINCT TBRACCD_PIDM,TBRACCD_TRAN_NUMBER
                        FROM TBBDETC A, SPRIDEN B, TBRACCD C
                        WHERE A.TBBDETC_TYPE_IND = 'C'
                        AND SUBSTR(A.TBBDETC_DETAIL_CODE,3,2) = 'XH'
                        AND B.SPRIDEN_PIDM = P_PIDM
                        AND SUBSTR (B.SPRIDEN_ID, 1, 2 )  = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                        AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                        AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                        AND C.TBRACCD_BALANCE >0
                        AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE-3))
                        AND TO_DATE(TRUNC(C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE-3) - (TO_NUMBER(TO_CHAR(SYSDATE-3,'DD')) - 1) FROM DUAL)
                        AND B.SPRIDEN_CHANGE_IND IS NULL

                 )LOOP

                  UPDATE TBRACCD
                  SET TBRACCD_TRAN_NUMBER_PAID = P_TRAN
                  WHERE TBRACCD_PIDM = P_PIDM
                  AND TBRACCD_TRAN_NUMBER = CARGOS.TBRACCD_TRAN_NUMBER;

                  UPDATE TVRACCD
                  SET TVRACCD_TRAN_NUMBER_PAID = P_TRAN
                  WHERE TVRACCD_PIDM = P_PIDM
                  AND TVRACCD_ACCD_TRAN_NUMBER = CARGOS.TBRACCD_TRAN_NUMBER;

                 END LOOP;

            EXCEPTION
            WHEN OTHERS THEN
            NULL;
            END;


        ELSE

            BEGIN

                   FOR CARGOS IN (

                       SELECT DISTINCT TBRACCD_PIDM,TBRACCD_TRAN_NUMBER
                        FROM TBBDETC A, SPRIDEN B, TBRACCD C
                        WHERE A.TBBDETC_TYPE_IND = 'C'
                        AND A.TBBDETC_DCAT_CODE IN ('COL','INT')
                        AND B.SPRIDEN_PIDM = P_PIDM
                        AND SUBSTR (B.SPRIDEN_ID, 1, 2 )  = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                        AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                        AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                        AND C.TBRACCD_BALANCE >0
                        AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE))
                        AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) >= (SELECT TRUNC(SYSDATE) - (TO_NUMBER(TO_CHAR(SYSDATE,'DD')) - 1) FROM DUAL)
                        AND B.SPRIDEN_CHANGE_IND IS NULL
                        UNION
                        SELECT DISTINCT TBRACCD_PIDM,TBRACCD_TRAN_NUMBER
                        FROM TBBDETC A, SPRIDEN B, TBRACCD C
                        WHERE A.TBBDETC_TYPE_IND = 'C'
                        AND SUBSTR(A.TBBDETC_DETAIL_CODE,3,2) = 'XH'
                        AND B.SPRIDEN_PIDM = P_PIDM
                        AND SUBSTR (B.SPRIDEN_ID, 1, 2 )  = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                        AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                        AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                        AND C.TBRACCD_BALANCE >0
                        AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE))
                        AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) >= (SELECT TRUNC(SYSDATE) - (TO_NUMBER(TO_CHAR(SYSDATE,'DD')) - 1) FROM DUAL)
                        AND B.SPRIDEN_CHANGE_IND IS NULL

                 )LOOP

                  UPDATE TBRACCD
                  SET TBRACCD_TRAN_NUMBER_PAID = P_TRAN
                  WHERE TBRACCD_PIDM = P_PIDM
                  AND TBRACCD_TRAN_NUMBER = CARGOS.TBRACCD_TRAN_NUMBER;

                  UPDATE TVRACCD
                  SET TVRACCD_TRAN_NUMBER_PAID = P_TRAN
                  WHERE TVRACCD_PIDM = P_PIDM
                  AND TVRACCD_ACCD_TRAN_NUMBER = CARGOS.TBRACCD_TRAN_NUMBER;

                 END LOOP;

            EXCEPTION
            WHEN OTHERS THEN
            NULL;
            END;


        END IF;

    ELSIF P_TIP = 'DESC' THEN

        IF TO_NUMBER(TO_CHAR(SYSDATE,'dd')) IN (1,2,3) THEN

           BEGIN

              UPDATE TBRACCD
              SET TBRACCD_TRAN_NUMBER_PAID = (SELECT TBRACCD_TRAN_NUMBER
                                                FROM TBRACCD C
                                                WHERE C.TBRACCD_PIDM = P_PIDM
                                                AND C.TBRACCD_BALANCE >0
                                                AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE-3))
                                                AND TO_DATE(TRUNC(C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE-3) - (TO_NUMBER(TO_CHAR(SYSDATE-3,'DD')) - 1) FROM DUAL)
                                                AND C.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                              FROM TBBDETC
                                                                              WHERE TBBDETC_DCAT_CODE = 'COL'
                                                                              AND TBBDETC_DESC != 'COLEGIATURA EXTRAORDINARIO')
                                                AND C.TBRACCD_TRAN_NUMBER = (SELECT MAX (C1.TBRACCD_TRAN_NUMBER)
                                                                              FROM TBRACCD C1
                                                                              WHERE C1.TBRACCD_PIDM = C.TBRACCD_PIDM
                                                                              AND C1.TBRACCD_BALANCE >0
                                                                              AND TRUNC(C1.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE-3))
                                                                              AND TO_DATE(TRUNC(C1.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE-3) - (TO_NUMBER(TO_CHAR(SYSDATE-3,'DD')) - 1) FROM DUAL)
                                                                              AND C1.TBRACCD_DETAIL_CODE = C.TBRACCD_DETAIL_CODE))
              WHERE TBRACCD_PIDM = P_PIDM
              AND TBRACCD_TRAN_NUMBER = P_TRAN
              ;

           EXCEPTION
           WHEN OTHERS THEN
           NULL;
           END;

           BEGIN

              UPDATE TVRACCD
              SET TVRACCD_TRAN_NUMBER_PAID = (SELECT TBRACCD_TRAN_NUMBER
                                                FROM TBRACCD C
                                                WHERE C.TBRACCD_PIDM = P_PIDM
                                                AND C.TBRACCD_BALANCE >0
                                                AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE-3))
                                                AND TO_DATE(TRUNC(C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE-3) - (TO_NUMBER(TO_CHAR(SYSDATE-3,'DD')) - 1) FROM DUAL)
                                                AND C.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                              FROM TBBDETC
                                                                              WHERE TBBDETC_DCAT_CODE = 'COL'
                                                                              AND TBBDETC_DESC != 'COLEGIATURA EXTRAORDINARIO')
                                                AND C.TBRACCD_TRAN_NUMBER = (SELECT MAX (C1.TBRACCD_TRAN_NUMBER)
                                                                              FROM TBRACCD C1
                                                                              WHERE C1.TBRACCD_PIDM = C.TBRACCD_PIDM
                                                                              AND C1.TBRACCD_BALANCE >0
                                                                              AND TRUNC(C1.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE-3))
                                                                              AND TO_DATE(TRUNC(C1.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE-3) - (TO_NUMBER(TO_CHAR(SYSDATE-3,'DD')) - 1) FROM DUAL)
                                                                              AND C1.TBRACCD_DETAIL_CODE = C.TBRACCD_DETAIL_CODE))
              WHERE TVRACCD_PIDM = P_PIDM
              AND TVRACCD_ACCD_TRAN_NUMBER = P_TRAN
              ;

           EXCEPTION
           WHEN OTHERS THEN
           NULL;
           END;

        ELSE

           BEGIN

              UPDATE TBRACCD
              SET TBRACCD_TRAN_NUMBER_PAID = (SELECT TBRACCD_TRAN_NUMBER
                                            FROM TBRACCD C
                                            WHERE C.TBRACCD_PIDM = P_PIDM
                                            AND C.TBRACCD_BALANCE >0
                                            AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE))
                                            AND TO_DATE(TRUNC(C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE) - (TO_NUMBER(TO_CHAR(SYSDATE,'DD')) - 1) FROM DUAL)
                                            AND C.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                          FROM TBBDETC
                                                                          WHERE TBBDETC_DCAT_CODE = 'COL'
                                                                          AND TBBDETC_DESC != 'COLEGIATURA EXTRAORDINARIO')
                                            AND C.TBRACCD_TRAN_NUMBER = (SELECT MAX (C1.TBRACCD_TRAN_NUMBER)
                                                                          FROM TBRACCD C1
                                                                          WHERE C1.TBRACCD_PIDM = C.TBRACCD_PIDM
                                                                          AND C1.TBRACCD_BALANCE >0
                                                                          AND TRUNC(C1.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE))
                                                                          AND TO_DATE(TRUNC(C1.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE) - (TO_NUMBER(TO_CHAR(SYSDATE,'DD')) - 1) FROM DUAL)
                                                                          AND C1.TBRACCD_DETAIL_CODE = C.TBRACCD_DETAIL_CODE))
              WHERE TBRACCD_PIDM = P_PIDM
              AND TBRACCD_TRAN_NUMBER = P_TRAN
              ;

           EXCEPTION
           WHEN OTHERS THEN
           NULL;
           END;

           BEGIN

              UPDATE TVRACCD
              SET TVRACCD_TRAN_NUMBER_PAID = (SELECT TBRACCD_TRAN_NUMBER
                                                FROM TBRACCD C
                                                WHERE C.TBRACCD_PIDM = P_PIDM
                                                AND C.TBRACCD_BALANCE >0
                                                AND TRUNC(C.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE))
                                                AND TO_DATE(TRUNC(C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE) - (TO_NUMBER(TO_CHAR(SYSDATE,'DD')) - 1) FROM DUAL)
                                                AND C.TBRACCD_DETAIL_CODE IN (SELECT TBBDETC_DETAIL_CODE
                                                                              FROM TBBDETC
                                                                              WHERE TBBDETC_DCAT_CODE = 'COL'
                                                                              AND TBBDETC_DESC != 'COLEGIATURA EXTRAORDINARIO')
                                                AND C.TBRACCD_TRAN_NUMBER = (SELECT MAX (C1.TBRACCD_TRAN_NUMBER)
                                                                              FROM TBRACCD C1
                                                                              WHERE C1.TBRACCD_PIDM = C.TBRACCD_PIDM
                                                                              AND C1.TBRACCD_BALANCE >0
                                                                              AND TRUNC(C1.TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE))
                                                                              AND TO_DATE(TRUNC(C1.TBRACCD_EFFECTIVE_DATE)) >= (SELECT TRUNC(SYSDATE) - (TO_NUMBER(TO_CHAR(SYSDATE,'DD')) - 1) FROM DUAL)
                                                                              AND C1.TBRACCD_DETAIL_CODE = C.TBRACCD_DETAIL_CODE))
              WHERE TVRACCD_PIDM = P_PIDM
              AND TVRACCD_ACCD_TRAN_NUMBER = P_TRAN
              ;

           EXCEPTION
           WHEN OTHERS THEN
           NULL;
           END;

        END IF;


    END IF;


RETURN(VL_ERROR);

END F_PAGOS_AMARRE;

FUNCTION F_AMARRE_VENCIDO (P_PIDM NUMBER,P_TRAN_ORIGEN NUMBER,P_TRAN_APLICA NUMBER) RETURN VARCHAR2 IS

VL_ERROR VARCHAR2(500):= NULL;


BEGIN

   BEGIN

    UPDATE TBRACCD
    SET TBRACCD_TRAN_NUMBER_PAID = P_TRAN_ORIGEN
    WHERE TBRACCD_PIDM = P_PIDM
    AND TBRACCD_TRAN_NUMBER = P_TRAN_APLICA;

    UPDATE TVRACCD
    SET TVRACCD_TRAN_NUMBER_PAID = P_TRAN_ORIGEN
    WHERE TVRACCD_PIDM = P_PIDM
    AND TVRACCD_ACCD_TRAN_NUMBER = P_TRAN_APLICA;

    VL_ERROR:= 'EXITO';

   EXCEPTION
   WHEN OTHERS THEN
   VL_ERROR:= 'ERROR AL ACTUALIZAR';
   END;

   RETURN (VL_ERROR);

END F_AMARRE_VENCIDO;

FUNCTION F_VAL_UNICO (P_PIDM NUMBER) RETURN VARCHAR2 IS

VL_EXISTE   NUMBER;
VL_SALDO    NUMBER;
VL_RESP     NUMBER;
VL_DOM      NUMBER;

 BEGIN

  IF TO_NUMBER(TO_CHAR(SYSDATE,'dd')) IN (1,2,3) THEN

    BEGIN

        select sum (x.balance) 
            Into VL_SALDO
        from (
            SELECT SUM(TBRACCD_BALANCE) balance
           -- INTO VL_SALDO
            FROM TBRACCD
            WHERE TBRACCD_PIDM = P_PIDM
            AND TRUNC(TBRACCD_EFFECTIVE_DATE) between TRUNC(SYSDATE, 'MM') and TRUNC(last_Day(SYSDATE))
            union
                    SELECT SUM(TBRACCD_BALANCE) balance
          --  INTO VL_SALDO
            FROM TBRACCD
            WHERE TBRACCD_PIDM = P_PIDM
            AND TRUNC(TBRACCD_EFFECTIVE_DATE) <= TRUNC(SYSDATE)
            ) x;

    EXCEPTION
    WHEN OTHERS THEN
    VL_SALDO:=0;
    END;

    IF VL_SALDO <= 0 THEN

     VL_RESP:= 0;

    ELSE

     VL_RESP:= 1;

    END IF;

  ELSE

    BEGIN

        SELECT SUM(TBRACCD_BALANCE)
        INTO VL_SALDO
        FROM TBRACCD
        WHERE TBRACCD_PIDM = P_PIDM
        AND TRUNC(TBRACCD_EFFECTIVE_DATE) <= LAST_DAY(TRUNC(SYSDATE));

    EXCEPTION
    WHEN OTHERS THEN
    VL_SALDO:=0;
    END;

    IF VL_SALDO <= 0 THEN

     VL_RESP:= 0;

    ELSE

     VL_RESP:= 1;

    END IF;

  END IF;


    BEGIN

        SELECT COUNT(*)
        INTO VL_DOM
        FROM TBRACCD,TBBDETC
        WHERE 1=1
        AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
        AND TBBDETC_DCAT_CODE = 'CSH'
        AND TBRACCD_PIDM = P_PIDM
        AND TBBDETC_DESC LIKE '%DOM'
        AND TBRACCD_CREATE_SOURCE NOT LIKE '%MANU'
        AND TRUNC(TBRACCD_EFFECTIVE_DATE) BETWEEN TRUNC(SYSDATE-4) AND TRUNC(SYSDATE)
        ;

    END;

    IF VL_DOM > 0 THEN

     VL_RESP:= 0;

    END IF;

  RETURN(VL_RESP);

 END F_VAL_UNICO;

 FUNCTION F_BORRA_ESC(P_PIDM IN NUMBER)RETURN VARCHAR2 IS

VL_ENTRA    NUMBER;
VL_DELETE   NUMBER;
VL_ERROR    VARCHAR2(5):='NO';
/*

Funcion encargada de validar si existe descuento de escalonado en el mes en curso para no aplicar el descuento por domiciliacion
Autor   JREZAOLI fecha 22/11/2019

*/

BEGIN

  BEGIN
    SELECT COUNT(*)
      INTO VL_ENTRA
      FROM GORADID
     WHERE      1=1
            AND GORADID_ADID_CODE = 'ESCA'
            AND GORADID_PIDM = P_PIDM;
  END;

  IF VL_ENTRA > 0 THEN

    BEGIN
        SELECT COUNT(*)
          INTO VL_DELETE
          FROM TZFACCE
         WHERE    1=1
              AND TZFACCE_PIDM = P_PIDM
              AND SUBSTR(TZFACCE_DETAIL_CODE,3,2) = 'M3'
              AND LAST_DAY(TRUNC(TZFACCE_EFFECTIVE_DATE)) >= LAST_DAY(TRUNC(SYSDATE));

    END;

    IF VL_DELETE = 0 THEN

     VL_ERROR:='SI';

     DELETE GORADID
      WHERE    1=1
           AND GORADID_ADID_CODE = 'ESCA'
           AND GORADID_PIDM = P_PIDM;

    END IF;

  ELSE
   VL_ERROR:='SI';
  END IF;

  COMMIT;

  RETURN(VL_ERROR);

END F_BORRA_ESC;

FUNCTION F_NUEVO_DOMICILIADO (P_PIDM IN NUMBER) RETURN VARCHAR IS

/* Esta funcion obtiene los conceptos de el cobro de la domiciliacion al sysdate
   autor: jrezaoli
  fecha: 06/11/2020
*/

VL_COLEGIATURA      NUMBER;
VL_COMPLEMENTO      NUMBER;
VL_PAGOS            NUMBER;
VL_RETORNA          VARCHAR2(500);
VL_EXISTE           NUMBER;
VL_PAID             NUMBER;

BEGIN

   BEGIN
        SELECT DISTINCT
               SUM (TBRACCD_BALANCE) P_AMOUNT
          INTO VL_COLEGIATURA
          FROM TBBDETC A, SPRIDEN B, TBRACCD C
         WHERE     1 = 1
               AND A.TBBDETC_TYPE_IND = 'C'
               AND A.TBBDETC_DCAT_CODE IN ('COL')
               AND B.SPRIDEN_PIDM = P_PIDM
               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
               AND C.TBRACCD_BALANCE != 0
               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) <= TRUNC (SYSDATE)
               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT   TRUNC (SYSDATE)- (  TO_NUMBER (TO_CHAR (TRUNC (SYSDATE), 'DD'))- 1)FROM DUAL)
               AND B.SPRIDEN_CHANGE_IND IS NULL
      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE;

   EXCEPTION
   WHEN OTHERS THEN
   VL_COLEGIATURA:=0;
   END;

   BEGIN
        SELECT DISTINCT
               SUM (TBRACCD_BALANCE) P_AMOUNT
          INTO VL_COMPLEMENTO
          FROM TBBDETC A, SPRIDEN B, TBRACCD C
         WHERE     1 = 1
               AND A.TBBDETC_TYPE_IND = 'C'
               AND SUBSTR (A.TBBDETC_DETAIL_CODE, 3, 2) IN ('XH','X2','QI')
               AND B.SPRIDEN_PIDM = P_PIDM
               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
               AND C.TBRACCD_BALANCE > 0
               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) <= TRUNC (SYSDATE)
               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT   TRUNC (SYSDATE)- (  TO_NUMBER (TO_CHAR (TRUNC (SYSDATE), 'DD'))- 1)FROM DUAL)
               AND B.SPRIDEN_CHANGE_IND IS NULL
      GROUP BY SPRIDEN_PIDM;

   EXCEPTION
   WHEN OTHERS THEN
   VL_COMPLEMENTO:=0;
   END;

   BEGIN
        SELECT SUM (TBRACCD_BALANCE) P_AMOUNT
          INTO VL_PAGOS
          FROM TBBDETC A, SPRIDEN B, TBRACCD C
         WHERE     1 = 1
               AND B.SPRIDEN_PIDM = P_PIDM
               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
               AND C.TBRACCD_BALANCE != 0
               AND A.TBBDETC_DCAT_CODE NOT IN ('TUI','DSP','LPC')
               AND A.TBBDETC_DESC NOT LIKE 'DSI COLE %'
               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) <= TRUNC (SYSDATE)
               AND B.SPRIDEN_CHANGE_IND IS NULL
      GROUP BY SPRIDEN_PIDM;

   EXCEPTION
   WHEN OTHERS THEN
   VL_PAGOS:=0;
   END;

   IF VL_PAGOS < (VL_COLEGIATURA+VL_COMPLEMENTO) THEN

      IF VL_PAGOS <= VL_COMPLEMENTO THEN

        VL_RETORNA:= 0||','||VL_PAGOS;

      ELSE

        VL_RETORNA:= VL_PAGOS||','||0;

      END IF;

   ELSE

    VL_RETORNA:= VL_COLEGIATURA||','||VL_COMPLEMENTO;

   END IF;

   BEGIN

        SELECT NVL(A.TBRACCD_TRAN_NUMBER_PAID,0)
          INTO VL_PAID
          FROM TBRACCD A
          WHERE A.TBRACCD_PIDM = P_PIDM
           AND A.TBRACCD_TRAN_NUMBER =( SELECT MAX(TBRACCD_TRAN_NUMBER)
                                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                                         WHERE     1 = 1
                                               AND A.TBBDETC_TYPE_IND = 'C'
                                               AND A.TBBDETC_DCAT_CODE IN ('COL')
                                               AND B.SPRIDEN_PIDM = P_PIDM
                                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                                               AND C.TBRACCD_BALANCE != 0
                                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) <= TRUNC (SYSDATE)
                                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) >= (SELECT   TRUNC (SYSDATE)- (  TO_NUMBER (TO_CHAR (TRUNC (SYSDATE), 'DD'))- 1)FROM DUAL)
                                               AND B.SPRIDEN_CHANGE_IND IS NULL);
   EXCEPTION
   WHEN OTHERS THEN
   VL_PAID:=0;
   END;

   BEGIN

        SELECT COUNT(*)
        INTO VL_EXISTE
        FROM TBRACCD,TBBDETC
        WHERE 1=1
        AND TBRACCD_DETAIL_CODE = TBBDETC_DETAIL_CODE
        AND TBBDETC_DCAT_CODE = 'CSH'
        AND TBRACCD_PIDM = P_PIDM
        AND TBBDETC_DESC LIKE '%DOM'
        AND TBRACCD_TRAN_NUMBER = VL_PAID;

   END;

   IF VL_EXISTE > 0 THEN
   VL_RETORNA:= 0||','||0;
   END IF;

 RETURN(VL_RETORNA);

END F_NUEVO_DOMICILIADO;

FUNCTION F_PAGO_ANTICIPADO (P_PIDM NUMBER, P_MONTO NUMBER, P_ORIGEN VARCHAR2 )RETURN VARCHAR2 IS

MONTO_MENOR    EXCEPTION;

VL_SALDO            NUMBER;
VL_ERROR            VARCHAR2(900):='EXITO';
VL_VIGENCIA         NUMBER;
VL_PORCENTAJE       NUMBER;
VL_PERIODO          VARCHAR2(11);
VL_FECHA_INICO      DATE;
VL_FECHA_PARC       DATE;
VL_STUDY            NUMBER;
VL_PARTE            VARCHAR2(4);
VL_FOLIO            NUMBER;
VL_PAID             NUMBER;
VL_TRANS            NUMBER;
VL_MONTO_PARC       NUMBER;
VL_CODIGO           VARCHAR2(4);
VL_DESC             VARCHAR2(40);
VL_SECUENCIA        NUMBER;
VL_MONTO            NUMBER;
VL_VALIDA_PAGO      NUMBER;


 BEGIN

   IF P_MONTO <= 0 THEN
    RAISE MONTO_MENOR;
   END IF;

   BEGIN
     SELECT TBRACCD_TERM_CODE,
            TBRACCD_FEED_DATE,
            TBRACCD_EFFECTIVE_DATE,
            TBRACCD_STSP_KEY_SEQUENCE,
            TBRACCD_PERIOD,
            TBRACCD_RECEIPT_NUMBER,
            TBRACCD_TRAN_NUMBER,
            TBRACCD_AMOUNT
       INTO VL_PERIODO,
            VL_FECHA_INICO,
            VL_FECHA_PARC,
            VL_STUDY,
            VL_PARTE,
            VL_FOLIO,
            VL_TRANS,
            VL_MONTO_PARC
       FROM TBRACCD
      WHERE TBRACCD_PIDM = P_PIDM
            AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
            AND TBRACCD_DOCUMENT_NUMBER IS NULL
            AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE));
   EXCEPTION
   WHEN OTHERS THEN
     BEGIN
       SELECT TBRACCD_TERM_CODE,
              TBRACCD_FEED_DATE,
              TBRACCD_EFFECTIVE_DATE,
              TBRACCD_STSP_KEY_SEQUENCE,
              TBRACCD_PERIOD,
              TBRACCD_RECEIPT_NUMBER,
              TBRACCD_TRAN_NUMBER,
              TBRACCD_AMOUNT
         INTO VL_PERIODO,
              VL_FECHA_INICO,
              VL_FECHA_PARC,
              VL_STUDY,
              VL_PARTE,
              VL_FOLIO,
              VL_TRANS,
              VL_MONTO_PARC
         FROM TBRACCD
        WHERE TBRACCD_PIDM = P_PIDM --258643
              AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
              AND TBRACCD_DOCUMENT_NUMBER IS NULL
              AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1));
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR AL CALCULAR VIGENCIA = '||SQLERRM;
     END;
   END;

   IF LAST_DAY(TRUNC(SYSDATE)) = LAST_DAY(VL_FECHA_PARC) THEN
     VL_PAID:= VL_TRANS;
   END IF;

   IF SUBSTR(VL_PERIODO,1,2) IN ('01','02') AND P_ORIGEN = 'PAY_CODE' THEN
     BEGIN
       SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
         INTO VL_CODIGO,VL_DESC
         FROM TBBDETC
        WHERE TBBDETC_DETAIL_CODE = SUBSTR(VL_PERIODO,1,2)||'VF';
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR AL CALCULAR CODIGO DE DETALLE = '||SQLERRM;
     END;

   ELSIF SUBSTR(VL_PERIODO,1,2) IN ('01','02') AND P_ORIGEN = 'PAYCASH' THEN

     BEGIN
       SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
         INTO VL_CODIGO,VL_DESC
         FROM TBBDETC
        WHERE TBBDETC_DETAIL_CODE = SUBSTR(VL_PERIODO,1,2)||'Y5';
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR AL CALCULAR CODIGO DE DETALLE = '||SQLERRM;
     END;

   ELSE

     BEGIN
       SELECT TBBDETC_DETAIL_CODE,TBBDETC_DESC
         INTO VL_CODIGO,VL_DESC
         FROM TBBDETC
        WHERE TBBDETC_DETAIL_CODE = SUBSTR(VL_PERIODO,1,2)||'VA';
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR:='ERROR AL CALCULAR CODIGO DE DETALLE = '||SQLERRM;
     END;

   END IF;

   IF VL_ERROR = 'EXITO' THEN

     BEGIN
       SELECT MAX(TBRACCD_TRAN_NUMBER)+1
         INTO VL_SECUENCIA
         FROM TBRACCD WHERE TBRACCD_PIDM = P_PIDM;
     END;
    dbms_output.put_line( 'aqui inserta = ');
     BEGIN
       INSERT
         INTO TBRACCD (  TBRACCD_PIDM
                       , TBRACCD_TRAN_NUMBER
                       , TBRACCD_TRAN_NUMBER_PAID
                       , TBRACCD_TERM_CODE
                       , TBRACCD_DETAIL_CODE
                       , TBRACCD_USER
                       , TBRACCD_ENTRY_DATE
                       , TBRACCD_AMOUNT
                       , TBRACCD_BALANCE
                       , TBRACCD_EFFECTIVE_DATE
                       , TBRACCD_FEED_DATE
                       , TBRACCD_DESC
                       , TBRACCD_SRCE_CODE
                       , TBRACCD_ACCT_FEED_IND
                       , TBRACCD_ACTIVITY_DATE
                       , TBRACCD_SESSION_NUMBER
                       , TBRACCD_TRANS_DATE
                       , TBRACCD_CURR_CODE
                       , TBRACCD_DATA_ORIGIN
                       , TBRACCD_CREATE_SOURCE
                       , TBRACCD_STSP_KEY_SEQUENCE
                       , TBRACCD_PERIOD
                       , TBRACCD_USER_ID
                       , TBRACCD_RECEIPT_NUMBER)
       VALUES(P_PIDM,                       -- TBRACCD_PIDM
              VL_SECUENCIA,                 -- TBRACCD_TRAN_NUMBER
              VL_PAID,                      -- TBRACCD_TRAN_NUMBER_PAID
              VL_PERIODO,                   -- TBRACCD_TERM_CODE
              VL_CODIGO,                    -- TBRACCD_DETAIL_CODE
              USER,                         -- TBRACCD_USER
              SYSDATE,                      -- TBRACCD_ENTRY_DATE
              NVL(ROUND(P_MONTO),0),       -- TBRACCD_AMOUNT
              NVL(ROUND(P_MONTO),0)*-1,    -- TBRACCD_BALANCE
              SYSDATE,                      -- TBRACCD_EFFECTIVE_DATE
              VL_FECHA_INICO,               -- TBRACCD_FEED_DATE
              VL_DESC,                      -- TBRACCD_DESC
              'T',                          -- TBRACCD_SRCE_CODE
              'Y',                          -- TBRACCD_ACCT_FEED_IND
              SYSDATE,                      -- TBRACCD_ACTIVITY_DATE
              0,                            -- TBRACCD_SESSION_NUMBER
              SYSDATE,                      -- TBRACCD_TRANS_DATE
              'MXN',                        -- TBRACCD_CURR_CODE
              'PAGO ANTICIPA',              -- TBRACCD_DATA_ORIGIN
              'PAGO ANTICIPA',              -- TBRACCD_CREATE_SOURCE
              VL_STUDY,                     -- TBRACCD_STSP_KEY_SEQUENCE
              VL_PARTE,                     -- TBRACCD_PERIOD
              USER,                         -- TBRACCD_USER_ID
              VL_FOLIO                      -- TBRACCD_RECEIPT_NUMBER
              );
     EXCEPTION
     WHEN OTHERS THEN
     VL_ERROR :='Error al insertar en TBRACCD'||SQLERRM;
     END;

   END IF;

     DBMS_OUTPUT.PUT_LINE('FINAL = '||VL_ERROR );

  COMMIT;
  RETURN(VL_ERROR);
 EXCEPTION
 WHEN MONTO_MENOR THEN
 VL_ERROR:='MONTO MENOR O IGUAL A CERO';
 RETURN(VL_ERROR);
 END F_PAGO_ANTICIPADO;

FUNCTION F_CURSOR_PANTI (P_PIDM NUMBER) RETURN PKG_SIMOBA.SALDO_PANTI AS

CURSOR_PANTI PKG_SIMOBA.SALDO_PANTI;

 BEGIN
   BEGIN
    OPEN CURSOR_PANTI
     FOR
            SELECT ((PARCIALIDAD_MES-ROUND(PARCIALIDAD_MES*PORCENTAJE,0))+SALDO_ACCESORIOS+SALDO_VENCIDO) SALDO_COBRAR,
                   PARCIALIDAD_MES,
                   SALDO_ACCESORIOS,
                   SALDO_VENCIDO,
                   ROUND(PARCIALIDAD_MES * PORCENTAJE * Libre_De_P3W4,0) DESCUENTO
            FROM (
                 SELECT DISTINCT
                        NVL((SELECT SUM(TBRACCD_BALANCE)
                               FROM TBRACCD
                              WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                    AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                    AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE))),0)PARCIALIDAD_MES,
                        NVL((SELECT SUM(TBRACCD_BALANCE)
                               FROM TBRACCD
                              WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                    AND TBRACCD_CREATE_SOURCE != 'TZFEDCA (PARC)'
                                    AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE))),0)SALDO_ACCESORIOS,
                        NVL((SELECT SUM(TBRACCD_BALANCE)
                               FROM TBRACCD
                              WHERE     TBRACCD_PIDM = A.TBRACCD_PIDM
                                    AND TBRACCD_EFFECTIVE_DATE <= SYSDATE-((to_char(sysdate,'DD'))-1)),0)SALDO_VENCIDO,
                        NVL((SELECT SUBSTR(ZSTPARA_PARAM_ID,16,2)/100
                               FROM ZSTPARA
                              WHERE     ZSTPARA_MAPA_ID ='PAGO_ANTICI'
                                    AND SUBSTR(ZSTPARA_PARAM_ID,1,2) = SUBSTR(A.TBRACCD_TERM_CODE,1,2)
                                    AND TO_NUMBER(TO_CHAR(TRUNC(SYSDATE),'DD')) BETWEEN ZSTPARA_PARAM_DESC AND ZSTPARA_PARAM_VALOR
                                    AND SUBSTR(ZSTPARA_PARAM_ID,13,2) = (CASE TO_CHAR(A.TBRACCD_EFFECTIVE_DATE,'DD')
                                                                              WHEN '27' THEN '30'
                                                                              WHEN '28' THEN '30'
                                                                              WHEN '29' THEN '30'
                                                                              ELSE  TO_CHAR(A.TBRACCD_EFFECTIVE_DATE,'DD')
                                                                          END)),0)PORCENTAJE,
                            -- Verifica que no tenga descuento aplicados P3, W4 --> OMS 22/Nov/2023
                            (SELECT DECODE (Tiene_Promociones, 0, 1, 0) Libre_De_P3W4
                               FROM (SELECT Count(*) Tiene_Promociones
                                       FROM TBRACCD
                                      WHERE TBRACCD_PIDM = A.TBRACCD_PIDM
                                        AND TBRACCD_DETAIL_CODE IN (SELECT a.ZSTPARA_PARAM_ID FROM ZSTPARA a WHERE ZSTPARA_MAPA_ID ='EXCLUIR_PAGOA')
                                   --   AND SUBSTR (TBRACCD_DETAIL_CODE,3,2) IN ('P3', 'W4','MD','MG')
                                   --   AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                        AND LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE)) )) Libre_De_P3W4
                   FROM TBRACCD A
                  WHERE     A.TBRACCD_PIDM = P_PIDM
                        AND A.TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                        AND (    LAST_DAY(A.TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE))
                              OR LAST_DAY(A.TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1)))
                        AND A.TBRACCD_EFFECTIVE_DATE = (SELECT MAX(TBRACCD_EFFECTIVE_DATE)
                                                          FROM TBRACCD
                                                         WHERE TBRACCD_PIDM = A.TBRACCD_PIDM
                                                                AND TBRACCD_CREATE_SOURCE = 'TZFEDCA (PARC)'
                                                                AND (    LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(TRUNC(SYSDATE))
                                                                      OR LAST_DAY(TBRACCD_EFFECTIVE_DATE) = LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE),-1))))
            )WHERE 1=1;
     RETURN(CURSOR_PANTI);
   END;

 END F_CURSOR_PANTI;


FUNCTION F_VAL_SALDO (P_PIDM NUMBER) RETURN VARCHAR2 IS

VL_SALDO    NUMBER;

  BEGIN
    BEGIN

        SELECT SUM(TBRACCD_BALANCE)
        INTO VL_SALDO
        FROM TBRACCD A
        WHERE TBRACCD_PIDM = P_PIDM
        AND TRUNC(TBRACCD_EFFECTIVE_DATE) <= TRUNC(SYSDATE)
        AND TBRACCD_TRAN_NUMBER NOT IN (SELECT TBRACCD_TRAN_NUMBER
                                        FROM TBRACCD
                                        WHERE TBRACCD_PIDM=A.TBRACCD_PIDM
                                        AND TBRACCD_CREATE_SOURCE = 'TZFEDCA(PARC)'
                                        AND LAST_DAY(TRUNC(TBRACCD_EFFECTIVE_DATE))=LAST_DAY(TRUNC(SYSDATE)));

    END;
    RETURN(VL_SALDO);
  END F_VAL_SALDO;
  
------------------------- Esta funcion genera la aplicacion de pagos por detalle de cargo para el nuevo modelo del dashboard de pagos -----------

Function  f_aplica_pago(p_pidm in number,
                                p_cargo in number,  --- Secuencia del Cargo
                                p_pago in number,   --- Secuencia del Pago 
                                p_monto in number) return varchar2   --- Monto cel pago
as

    vl_exito varchar2(250) := 'EXITO';

    Begin

            --------------- Se actualiza el balance del Cargo ---------------
               Begin
                    Update tbraccd
                    set tbraccd_balance = tbraccd_balance -p_monto
                    Where tbraccd_pidm = p_pidm
                    And  TBRACCD_TRAN_NUMBER = p_cargo;
               Exception
                When Others then 
                 vl_exito:= 'Error al actualizar Saldo del Cargo ' ||sqlerrm;
               End;


            --------------- Se actualiza el balance del Pago ---------------
               Begin
                    Update tbraccd
                    set tbraccd_balance = tbraccd_balance - (p_monto)*-1
                    Where tbraccd_pidm = p_pidm
                    And  TBRACCD_TRAN_NUMBER = p_pago;
               Exception
                When Others then 
                 vl_exito:= 'Error al actualizar Saldo del Pago ' ||sqlerrm;
               End;


               If  vl_exito = 'EXITO' then 
               
                    Begin 
                            Insert into tbrappl values(p_pidm, --TBRAPPL_PIDM
                                                       p_pago, -- TBRAPPL_PAY_TRAN_NUMBER
                                                       p_cargo, -- TBRAPPL_CHG_TRAN_NUMBER
                                                       p_monto, -- TBRAPPL_AMOUNT
                                                       'Y',     -- TBRAPPL_DIRECT_PAY_IND
                                                       null,     -- TBRAPPL_REAPPL_IND
                                                       user,     --TBRAPPL_USER,
                                                       'Y',    -- TBRAPPL_ACCT_FEED_IND
                                                       sysdate,  -- TBRAPPL_ACTIVITY_DATE
                                                       null,     -- TBRAPPL_FEED_DATE
                                                       null,    -- TBRAPPL_FEED_DOC_CODE
                                                       null,    -- TBRAPPL_CPDT_TRAN_NUMBER
                                                       'T',    -- TBRAPPL_DIRECT_PAY_TYPE
                                                       null,   -- TBRAPPL_INV_NUMBER_PAID
                                                       null,   -- TBRAPPL_SURROGATE_ID,
                                                       null,   -- TBRAPPL_VERSION
                                                       user,   -- TBRAPPL_USER_ID
                                                       'DASHBOARD',   -- TBRAPPL_DATA_ORIGIN
                                                       null);         --TBRAPPL_VPDI_CODE
                    Exception
                        When Others then 
                         vl_exito:= 'Error al Insertar PPL' ||sqlerrm;
                    End;
                    Commit;
                                               
               Else 
                rollback;
               End if;
               
               Return (vl_exito);

    Exception
        when Others then
         vl_exito := 'ERROR';
          Return (vl_exito);
    End f_aplica_pago;  
  
Function f_cargos_saldo_domiciliacion (p_pidm in number) Return varchar2  ------- Funcion que retorna los montos del mes en curso para aplicar descuento de domiciliacion y monto vencido sin descuento domiciliacion 
as 

vl_monto_mensual number:=0;
vl_monto_acumulado number:=0;
vl_acumulado varchar2(100):= null;

Begin 

        --------------- Recupera el monto para aplicar descuento por domiciliacion 
      Begin  
            vl_monto_mensual:=0;
            
        Select sum (x.monto)
            Into vl_monto_mensual
        from (
                Select sum (TBRACCD_BALANCE) monto, tbraccd_pidm pidm
                from tbraccd
                join tbbdetc on tbbdetc_detail_code = tbraccd_detail_code and TBBDETC_TYPE_IND ='C' and TBRACCD_BALANCE > 0 and TBBDETC_detc_active_ind = 'Y'   
                join TZTNCD  on TZTNCD_CODE = tbraccd_detail_code and TZTNCD_concepto     = 'Venta'    
                where 1=1
                AND TBBDETC_dcat_code   = 'COL'    
              --  and TBRACCD_DATA_ORIGIN = 'TZFEDCA (PARC)'
                And TBRACCD_EFFECTIVE_DATE between TRUNC(SYSDATE, 'MM') and LAST_DAY(TRUNC(SYSDATE))
                And tbraccd_pidm = p_pidm
                group by tbraccd_pidm
                union
                Select sum (TBRACCD_BALANCE) monto, tbraccd_pidm pidm
                 from tbraccd
                 where 1=1
                 and substr (tbraccd_detail_code,3,2)  in (Select ZSTPARA_PARAM_VALOR
                                                FROM ZSTPARA
                                                    WHERE 1=1
                                                    AND ZSTPARA_MAPA_ID='COD_DOMICILIACI'
                                            ) 
                And TBRACCD_EFFECTIVE_DATE between TRUNC(SYSDATE, 'MM') and LAST_DAY(TRUNC(SYSDATE))  
                and TBRACCD_BALANCE > 0   
                And tbraccd_pidm = p_pidm 
                group by tbraccd_pidm                      
        ) x ; 
    Exception
        When Others then 
        vl_monto_mensual:=0;
    End;


    Begin
         vl_monto_acumulado:=0;
         
        Select sum (tbraccd_balance) Monto
            Into vl_monto_acumulado
        from tbraccd a
        join tbbdetc on tbbdetc_detail_code = a.tbraccd_detail_code and TBBDETC_TYPE_IND ='C' and a.TBRACCD_BALANCE > 0 and TBBDETC_detc_active_ind = 'Y'   
        where 1=1
        And trunc (a.TBRACCD_EFFECTIVE_DATE) < trunc (sysdate)
        And a.tbraccd_pidm = p_pidm 
        And a.TBRACCD_TRAN_NUMBER Not in ( Select distinct TBRACCD_TRAN_NUMBER
                                            from tbraccd
                                            join tbbdetc on tbbdetc_detail_code = tbraccd_detail_code and TBBDETC_TYPE_IND ='C' and TBRACCD_BALANCE > 0 and TBBDETC_detc_active_ind = 'Y'   
                                            join TZTNCD  on TZTNCD_CODE = tbraccd_detail_code and TZTNCD_concepto     = 'Venta'    
                                            where 1=1
                                            AND TBBDETC_dcat_code   = 'COL'    
                                           -- and TBRACCD_DATA_ORIGIN = 'TZFEDCA (PARC)'
                                            And TBRACCD_EFFECTIVE_DATE between TRUNC(SYSDATE, 'MM') and LAST_DAY(TRUNC(SYSDATE))
                                            And tbraccd_pidm = p_pidm 
                                            union
                                            Select distinct TBRACCD_TRAN_NUMBER
                                             from tbraccd
                                             where 1=1
                                             and substr (tbraccd_detail_code,3,2)  in (Select ZSTPARA_PARAM_VALOR
                                                                            FROM ZSTPARA
                                                                                WHERE 1=1
                                                                                AND ZSTPARA_MAPA_ID='COD_DOMICILIACI'
                                                                        ) 
                                            And TBRACCD_EFFECTIVE_DATE between TRUNC(SYSDATE, 'MM') and LAST_DAY(TRUNC(SYSDATE))  
                                            and TBRACCD_BALANCE > 0    
                                            And tbraccd_pidm = p_pidm 
                                         );
    
    Exception
        When Others then 
         vl_monto_acumulado:=0;
    End;    
                                   

    vl_acumulado:= nvl (vl_monto_mensual,0) ||','|| nvl (vl_monto_acumulado,0);
    
    REturn vl_acumulado;
    


End f_cargos_saldo_domiciliacion;


FUNCTION FNC_OBTIENE_PARCIALIDAD_TOTAL_2 (P_PIDM IN NUMBER, p_dia in number) RETURN VARCHAR IS

---- Esta funcion obtiene los conceptos mas antiguos de parcialidad, intereses y accesorios  mas antigua que tenga saldo para realizar el cobro de la domiciliacion
---- Se modifica funci n para traer los conceptos vencidos en el mes en curso y se cambia el tipo de retorno a varchar --- reza 14/10/2019

VL_COLEGIATURA      NUMBER;
VL_COMPLEMENTO      NUMBER;
VL_COLEGIATURA_ANT      NUMBER;
VL_COMPLEMENTO_ANT      NUMBER;
VL_REMANENTE            NUMBER;
VL_PAGOS            NUMBER;
VL_RETORNA          VARCHAR2(500);
VL_EXISTE           NUMBER;
VL_PAID             NUMBER;
vl_favor            NUMBER;
vl_sobra            NUMBER;
vl_inicio_ant       date;
vl_fin_ant          date;
vl_monto_vta        number;
vl_monto_pgo        number;
vl_monto_fin        number;               
vl_dia              Number;

BEGIN

        --dbms_output.put_line('Inicia el proceso de Domiciliacion ');
    

    vl_inicio_ant := trunc (sysdate, 'MM');
    vl_fin_ant := TRUNC(LAST_DAY(SYSDATE));
    
    vl_dia:=TO_NUMBER(TO_CHAR(SYSDATE,'dd'));
    
    
--    If vl_dia in (8,9,10,13,14,15,28,29,30, 31) and p_dia in (8,9,10,13,14,15,28,29,30, 31 ) then   ---------------- Esto se prende para los dias donde se cobra antes Victor
--       vl_dia:= p_dia;
--    End if; 
    

 ----   vl_dia := 1;  -------------------------------------------> aqui se pone la fecha del mes a Simular --------------------------------------------------------------------------------------------------

      ---------------------- Recupera el saldo a favor del alumno de forma global    

     Begin
     
        select nvl (sum (TBRACCD_BALANCE) *-1,0)
            Into vl_favor
        FROM TBRACCD
        join tbbdetc on tbbdetc_detail_code = tbraccd_detail_code and TBBDETC_TYPE_IND = 'P'
        WHERE TBRACCD_PIDM = P_PIDM;   
     Exception
        When Others then 
          vl_favor:=0;  
     End;
            
--      dbms_output.put_line('Recupera Saldo a Favor '||vl_favor);
--      dbms_output.put_line('Recupera Dias del mes '||vl_dia ||'Dia Domiciliacion '||p_dia);
     

     IF vl_dia IN (1,2,3) and p_dia not in (1,2,3) THEN  -----> hace la validacion para ver el saldo del mes anterior y la Dom no esta dentro tres primeros dias 
       -- dbms_output.put_line('Bloque 1 '||p_dia);
      
            VL_COLEGIATURA_ANT:=0;
            VL_REMANENTE:=0;
      
            BEGIN
                    select nvl (sum (x.P_AMOUNT),0)
                          INTO VL_COLEGIATURA_ANT
                    from (
                      SELECT DISTINCT
                               SUM (TBRACCD_BALANCE) P_AMOUNT
                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                         WHERE     1 = 1
                               AND A.TBBDETC_TYPE_IND = 'C'
                               AND A.TBBDETC_DCAT_CODE IN ('COL')
                               AND B.SPRIDEN_PIDM = P_PIDM
                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                               AND C.TBRACCD_BALANCE != 0
                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between ADD_MONTHS (vl_inicio_ant,-1)  and ADD_MONTHS (vl_fin_ant,-1)
                               AND B.SPRIDEN_CHANGE_IND IS NULL
                      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                      union
                        SELECT DISTINCT
                               nvl (SUM (TBRACCD_BALANCE),0) P_AMOUNT
                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                         WHERE     1 = 1
                               AND A.TBBDETC_TYPE_IND = 'C'
                               AND B.SPRIDEN_PIDM = P_PIDM
                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                               AND C.TBRACCD_BALANCE != 0
                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between ADD_MONTHS (vl_inicio_ant,-1)  and ADD_MONTHS (vl_fin_ant,-1)
                               AND B.SPRIDEN_CHANGE_IND IS NULL
                               And substr (C.TBRACCD_DETAIL_CODE,3,2) in ( select distinct STVPAQT_DETAIL_CODE
                                                                                                    from SZTALIA
                                                                                                    join STVPAQT  on STVPAQT_ADID_CODE = SZTALIA_CODE
                                                                                                  )
                      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                      ) x  ;
           EXCEPTION
           WHEN OTHERS THEN
            VL_COLEGIATURA_ANT:=0;
           END;
      
            
           VL_COMPLEMENTO_ANT:=0;
           BEGIN
                SELECT DISTINCT
                       nvl (SUM (TBRACCD_BALANCE),0) P_AMOUNT
                  INTO VL_COMPLEMENTO_ANT
                  FROM TBBDETC A, SPRIDEN B, TBRACCD C
                 WHERE     1 = 1
                       AND A.TBBDETC_TYPE_IND = 'C'
                       AND SUBSTR (A.TBBDETC_DETAIL_CODE, 3, 2) IN (select distinct ZSTPARA_PARAM_VALOR
                                                                    from ZSTPARA
                                                                    where ZSTPARA_MAPA_ID = 'COD_DOMICILIACI'
                                                                   )
                       AND B.SPRIDEN_PIDM = P_PIDM
                       AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                       AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                       AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                       AND C.TBRACCD_BALANCE > 0
                       AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between ADD_MONTHS (vl_inicio_ant,-1)  and ADD_MONTHS (vl_fin_ant,-1)
                       AND B.SPRIDEN_CHANGE_IND IS NULL
              GROUP BY SPRIDEN_PIDM;
           EXCEPTION
           WHEN OTHERS THEN
            VL_COMPLEMENTO_ANT:=0;
           END;      
      
            --dbms_output.put_line('Complemento mes Anterior '||VL_COMPLEMENTO_ANT);
          
          VL_REMANENTE:=0;

          If VL_COLEGIATURA_ANT > 0 then   -----------> Colegiatura Anteriorir
            If vl_favor > 0 then 
          
               If vl_favor = VL_COLEGIATURA_ANT then 
                  VL_COLEGIATURA_ANT:=0;
               ElsIf vl_favor > VL_COLEGIATURA_ANT then
                     VL_COLEGIATURA_ANT:=0;                  
                     VL_REMANENTE:= vl_favor - VL_COLEGIATURA_ANT;
               ElsIf vl_favor < VL_COLEGIATURA_ANT then
                     VL_COLEGIATURA_ANT:=VL_COLEGIATURA_ANT - vl_favor;                  
                     VL_REMANENTE:= 0;
               End if;
            Else 
                VL_REMANENTE:= 0;        
            End if;
          Elsif VL_COLEGIATURA_ANT =0 then 
                VL_COLEGIATURA_ANT:=0;
                VL_REMANENTE:=vl_favor;
          End if;

          If VL_COMPLEMENTO_ANT > 0 then 
                If VL_REMANENTE > 0 then 
                   If VL_COMPLEMENTO_ANT = VL_REMANENTE then
                      VL_COMPLEMENTO_ANT:=0;
                      VL_REMANENTE:=0;
                   Elsif VL_COMPLEMENTO_ANT > VL_REMANENTE then 
                         VL_COMPLEMENTO_ANT := VL_COMPLEMENTO_ANT -VL_REMANENTE ;
                         VL_REMANENTE :=0;
                    Elsif VL_COMPLEMENTO_ANT < VL_REMANENTE then
                          VL_COMPLEMENTO_ANT:=0;
                          VL_REMANENTE := VL_REMANENTE - VL_COMPLEMENTO_ANT;                  
                   End if;
                End if;
          Elsif VL_COMPLEMENTO_ANT =0 then 
              VL_COMPLEMENTO_ANT:=0;
          End if;

          VL_RETORNA:= VL_COLEGIATURA_ANT||','||VL_COMPLEMENTO_ANT;
            --dbms_output.put_line('RETURNO '||VL_COLEGIATURA_ANT ||'*'||VL_COMPLEMENTO_ANT);
            

    Elsif vl_dia IN (1,2,3) and p_dia in (1,2,3) THEN  -----> hace la validacion para ver el saldo del mes corriente y la Dom no esta dentro tres primeros dias 
          --  dbms_output.put_line('Bloque 2** '||p_dia);

            VL_COLEGIATURA:=0;
            VL_REMANENTE:=0;
      
            BEGIN
                    select nvl (sum (x.P_AMOUNT),0)
                          INTO VL_COLEGIATURA
                    from (
                      SELECT DISTINCT
                               SUM (TBRACCD_BALANCE) P_AMOUNT
                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                         WHERE     1 = 1
                               AND A.TBBDETC_TYPE_IND = 'C'
                               AND A.TBBDETC_DCAT_CODE IN ('COL')
                               AND B.SPRIDEN_PIDM = P_PIDM
                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                               AND C.TBRACCD_BALANCE != 0
                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between vl_inicio_ant and vl_fin_ant
                               AND B.SPRIDEN_CHANGE_IND IS NULL
                      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                      union
                        SELECT DISTINCT
                               nvl (SUM (TBRACCD_BALANCE),0) P_AMOUNT
                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                         WHERE     1 = 1
                               AND A.TBBDETC_TYPE_IND = 'C'
                               AND B.SPRIDEN_PIDM = P_PIDM
                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                               AND C.TBRACCD_BALANCE != 0
                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between vl_inicio_ant and vl_fin_ant
                               AND B.SPRIDEN_CHANGE_IND IS NULL
                               And substr (C.TBRACCD_DETAIL_CODE,3,2) in ( select distinct STVPAQT_DETAIL_CODE
                                                                                                    from SZTALIA
                                                                                                    join STVPAQT  on STVPAQT_ADID_CODE = SZTALIA_CODE
                                                                                                  )
                      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                      ) x  ;
           EXCEPTION
           WHEN OTHERS THEN
            VL_COLEGIATURA:=0;
           END;
      
       -- dbms_output.put_line('Colegiatura mes actual '||VL_COLEGIATURA);

            
           VL_COMPLEMENTO:=0;
           BEGIN
                SELECT DISTINCT
                       nvl (SUM (TBRACCD_BALANCE),0) P_AMOUNT
                  INTO VL_COMPLEMENTO
                  FROM TBBDETC A, SPRIDEN B, TBRACCD C
                 WHERE     1 = 1
                       AND A.TBBDETC_TYPE_IND = 'C'
                       AND SUBSTR (A.TBBDETC_DETAIL_CODE, 3, 2) IN (select distinct ZSTPARA_PARAM_VALOR
                                                                    from ZSTPARA
                                                                    where ZSTPARA_MAPA_ID = 'COD_DOMICILIACI'
                                                                   )
                       AND B.SPRIDEN_PIDM = P_PIDM
                       AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                       AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                       AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                       AND C.TBRACCD_BALANCE > 0
                       AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between vl_inicio_ant and vl_fin_ant
                       AND B.SPRIDEN_CHANGE_IND IS NULL
              GROUP BY SPRIDEN_PIDM;
           EXCEPTION
           WHEN OTHERS THEN
            VL_COMPLEMENTO:=0;
           END;    
            
         --  dbms_output.put_line('complemento mes actual '||VL_COMPLEMENTO);


            VL_COLEGIATURA_ANT:=0;
      
            BEGIN
                    select nvl (sum (x.P_AMOUNT),0)
                          INTO VL_COLEGIATURA_ANT
                    from (
                      SELECT DISTINCT
                               SUM (TBRACCD_BALANCE) P_AMOUNT
                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                         WHERE     1 = 1
                               AND A.TBBDETC_TYPE_IND = 'C'
                               AND A.TBBDETC_DCAT_CODE IN ('COL')
                               AND B.SPRIDEN_PIDM = P_PIDM
                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                               AND C.TBRACCD_BALANCE != 0
                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between ADD_MONTHS (vl_inicio_ant,-1)  and ADD_MONTHS (vl_fin_ant,-1)
                               AND B.SPRIDEN_CHANGE_IND IS NULL
                      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                      union
                        SELECT DISTINCT
                               nvl (SUM (TBRACCD_BALANCE),0) P_AMOUNT
                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                         WHERE     1 = 1
                               AND A.TBBDETC_TYPE_IND = 'C'
                               AND B.SPRIDEN_PIDM = P_PIDM
                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                               AND C.TBRACCD_BALANCE != 0
                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between ADD_MONTHS (vl_inicio_ant,-1)  and ADD_MONTHS (vl_fin_ant,-1)
                               AND B.SPRIDEN_CHANGE_IND IS NULL
                               And substr (C.TBRACCD_DETAIL_CODE,3,2) in ( select distinct STVPAQT_DETAIL_CODE
                                                                                                    from SZTALIA
                                                                                                    join STVPAQT  on STVPAQT_ADID_CODE = SZTALIA_CODE
                                                                                                  )
                      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                      ) x  ;
           EXCEPTION
           WHEN OTHERS THEN
            VL_COLEGIATURA_ANT:=0;
           END;
      
          --  dbms_output.put_line('Colegiatura mes Anterior '||VL_COLEGIATURA_ANT);
            
           VL_COMPLEMENTO_ANT:=0;
           BEGIN
                SELECT DISTINCT
                       nvl (SUM (TBRACCD_BALANCE),0) P_AMOUNT
                  INTO VL_COMPLEMENTO_ANT
                  FROM TBBDETC A, SPRIDEN B, TBRACCD C
                 WHERE     1 = 1
                       AND A.TBBDETC_TYPE_IND = 'C'
                       AND SUBSTR (A.TBBDETC_DETAIL_CODE, 3, 2) IN (select distinct ZSTPARA_PARAM_VALOR
                                                                    from ZSTPARA
                                                                    where ZSTPARA_MAPA_ID = 'COD_DOMICILIACI'
                                                                   )
                       AND B.SPRIDEN_PIDM = P_PIDM
                       AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                       AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                       AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                       AND C.TBRACCD_BALANCE > 0
                       AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between ADD_MONTHS (vl_inicio_ant,-1)  and ADD_MONTHS (vl_fin_ant,-1)
                       AND B.SPRIDEN_CHANGE_IND IS NULL
              GROUP BY SPRIDEN_PIDM;
           EXCEPTION
           WHEN OTHERS THEN
            VL_COMPLEMENTO_ANT:=0;
           END;     

          --  dbms_output.put_line('Complemento mes Anterior '||VL_COMPLEMENTO_ANT);
          
          VL_REMANENTE:=0;

          If VL_COLEGIATURA_ANT > 0 then   -----------> Colegiatura Anteriorir
            -- dbms_output.put_line('Recupera Colegiatura Anterior 1** '||VL_COLEGIATURA_ANT);
            If vl_favor > 0 then 
                  --  dbms_output.put_line('Recupera Saldo a favor 1** '||vl_favor);
               If vl_favor = VL_COLEGIATURA_ANT then 
                  VL_COLEGIATURA_ANT:=0;
                  VL_REMANENTE:=0;
                 -- dbms_output.put_line('Colegiatura Anteiror 2*** '||VL_COLEGIATURA_ANT);
               ElsIf vl_favor > VL_COLEGIATURA_ANT then
                     VL_COLEGIATURA_ANT:=0;                  
                     VL_REMANENTE:= vl_favor - VL_COLEGIATURA_ANT;
                    -- dbms_output.put_line('Colegiatura + Remanente Anteiror 2*** '||VL_REMANENTE);
               ElsIf vl_favor < VL_COLEGIATURA_ANT then
                     VL_COLEGIATURA_ANT:=VL_COLEGIATURA_ANT - vl_favor;                  
                     VL_REMANENTE:= 0;
                   --  dbms_output.put_line('Colegiatura + Remanente Anteiror 3*** '||VL_COLEGIATURA_ANT);
               End if;
            Else 
                VL_REMANENTE:= 0;
               -- dbms_output.put_line('Remanente en CERO 3*** '||VL_REMANENTE);        
            End if;
          Elsif VL_COLEGIATURA_ANT =0 then 
                VL_COLEGIATURA_ANT:=0;
                VL_REMANENTE:=vl_favor;
               -- dbms_output.put_line('Colegiautra en CERO *** '||VL_REMANENTE);  
          End if;

          If VL_COMPLEMENTO_ANT > 0 then
             --dbms_output.put_line('Complemento Anterior ***4 '||VL_COMPLEMENTO_ANT); 
                If VL_REMANENTE > 0 then
                  -- dbms_output.put_line('Remanente  Anterior ***4 '||VL_REMANENTE); 
                   If VL_COMPLEMENTO_ANT = VL_REMANENTE then
                      VL_COMPLEMENTO_ANT:=0;
                      VL_REMANENTE:=0;
                    --  dbms_output.put_line('Complemnto y remanente Anterior ***4 '||VL_REMANENTE); 
                   Elsif VL_COMPLEMENTO_ANT > VL_REMANENTE then 
                         VL_COMPLEMENTO_ANT := VL_COMPLEMENTO_ANT -VL_REMANENTE ;
                         VL_REMANENTE :=0;
                       --  dbms_output.put_line('Complemnto Menor y remanente Anterior ***4 '||VL_COMPLEMENTO_ANT); 
                    Elsif VL_COMPLEMENTO_ANT < VL_REMANENTE then
                          VL_COMPLEMENTO_ANT:=0;
                          VL_REMANENTE := VL_REMANENTE - VL_COMPLEMENTO_ANT;
                         -- dbms_output.put_line('Complemnto CERO  y remanente Saldo ***4 '||VL_REMANENTE);                   
                   End if;
                End if;
          Elsif VL_COMPLEMENTO_ANT =0 then 
              VL_COMPLEMENTO_ANT:=0;
             -- dbms_output.put_line('Complemnto CERO  y remanente Total ***4 '||VL_REMANENTE);   
          End if;


          If VL_COLEGIATURA > 0 then   -----------> Colegiatura Actual
              --dbms_output.put_line('Recupera Colegiatura 5** '||VL_COLEGIATURA);
            If VL_REMANENTE > 0 then
                    --dbms_output.put_line('Recupera Remanente 5** '||VL_REMANENTE); 
               If VL_REMANENTE = VL_COLEGIATURA then 
                  VL_COLEGIATURA:=0;
                  VL_REMANENTE:=0;
                    --dbms_output.put_line('Empeta a CERO Colegiatura 5** '||VL_REMANENTE);                   
               ElsIf VL_REMANENTE > VL_COLEGIATURA then
                     VL_COLEGIATURA:=0;                  
                     VL_REMANENTE:= VL_REMANENTE - VL_COLEGIATURA_ANT;
                     --dbms_output.put_line('Colegiatura y Remanente mayor 5** '||VL_REMANENTE);  
               ElsIf VL_REMANENTE < VL_COLEGIATURA then
                     VL_COLEGIATURA:=VL_COLEGIATURA - VL_REMANENTE;                  
                     VL_REMANENTE:= 0;
                     --dbms_output.put_line('Colegiatura y Remanente menor 5** '||VL_COLEGIATURA);
               End if;
            Else 
                VL_REMANENTE:= 0;        
            End if;
          Elsif VL_COLEGIATURA =0 then 
                VL_COLEGIATURA:=0;
          End if;

          If VL_COMPLEMENTO > 0 then 
                --dbms_output.put_line('Complemento Actual Mayor 5** '||VL_COMPLEMENTO);
                If VL_REMANENTE > 0 then
                    --dbms_output.put_line('Existe remanente Mayor 5** '||VL_REMANENTE); 
                   If VL_COMPLEMENTO = VL_REMANENTE then
                      VL_COMPLEMENTO:=0;
                      VL_REMANENTE:=0;
                      --dbms_output.put_line('Complemento igualdo a CERO  5** '||VL_COMPLEMENTO);
                   Elsif VL_COMPLEMENTO > VL_REMANENTE then 
                         VL_COMPLEMENTO := VL_COMPLEMENTO -VL_REMANENTE ;
                         VL_REMANENTE :=0;
                         --dbms_output.put_line('Complemento mayor a Remanente 5** '||VL_COMPLEMENTO);
                    Elsif VL_COMPLEMENTO < VL_REMANENTE then
                          VL_COMPLEMENTO:=0;
                          VL_REMANENTE := VL_REMANENTE - VL_COMPLEMENTO;
                          --dbms_output.put_line('Complemento menor  a Remanente 5** '||VL_REMANENTE);                  
                   End if;
                End if;
          Elsif VL_COMPLEMENTO =0 then 
              VL_COMPLEMENTO:=0;
          End if;

            
          VL_COLEGIATURA:= VL_COLEGIATURA + VL_COLEGIATURA_ANT;
          VL_COMPLEMENTO:= VL_COMPLEMENTO + VL_COMPLEMENTO_ANT;
           
           VL_RETORNA:= VL_COLEGIATURA||','||VL_COMPLEMENTO;
            --dbms_output.put_line('RETURNO '||VL_COLEGIATURA ||'*'||VL_COMPLEMENTO);

    Elsif vl_dia = p_dia and vl_dia not in (1,2,3) Or vl_dia > p_dia and vl_dia not in (1,2,3)  then
           -- dbms_output.put_line('Bloque 3 '||p_dia);
            
            VL_COLEGIATURA:=0;
            VL_REMANENTE:=0;
      
            BEGIN
                    select nvl (sum (x.P_AMOUNT),0)
                          INTO VL_COLEGIATURA
                    from (
                      SELECT DISTINCT
                               SUM (TBRACCD_BALANCE) P_AMOUNT
                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                         WHERE     1 = 1
                               AND A.TBBDETC_TYPE_IND = 'C'
                               AND A.TBBDETC_DCAT_CODE IN ('COL')
                               AND B.SPRIDEN_PIDM = P_PIDM
                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                               AND C.TBRACCD_BALANCE != 0
                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between vl_inicio_ant and vl_fin_ant
                               AND B.SPRIDEN_CHANGE_IND IS NULL
                      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                      union
                        SELECT DISTINCT
                               nvl (SUM (TBRACCD_BALANCE),0) P_AMOUNT
                          FROM TBBDETC A, SPRIDEN B, TBRACCD C
                         WHERE     1 = 1
                               AND A.TBBDETC_TYPE_IND = 'C'
                               AND B.SPRIDEN_PIDM = P_PIDM
                               AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                               AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                               AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                               AND C.TBRACCD_BALANCE != 0
                               AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between vl_inicio_ant and vl_fin_ant
                               AND B.SPRIDEN_CHANGE_IND IS NULL
                               And substr (C.TBRACCD_DETAIL_CODE,3,2) in ( select distinct STVPAQT_DETAIL_CODE
                                                                                                    from SZTALIA
                                                                                                    join STVPAQT  on STVPAQT_ADID_CODE = SZTALIA_CODE
                                                                                                  )
                      GROUP BY SPRIDEN_PIDM, TBBDETC_DCAT_CODE
                      ) x  ;
           EXCEPTION
           WHEN OTHERS THEN
            VL_COLEGIATURA:=0;
           END;
      
                --dbms_output.put_line(' Recupera la Colegiatura '||VL_COLEGIATURA);
            
           VL_COMPLEMENTO:=0;
           BEGIN
                SELECT DISTINCT
                       nvl (SUM (TBRACCD_BALANCE),0) P_AMOUNT
                  INTO VL_COMPLEMENTO
                  FROM TBBDETC A, SPRIDEN B, TBRACCD C
                 WHERE     1 = 1
                       AND A.TBBDETC_TYPE_IND = 'C'
                       AND SUBSTR (A.TBBDETC_DETAIL_CODE, 3, 2) IN (select distinct ZSTPARA_PARAM_VALOR
                                                                    from ZSTPARA
                                                                    where ZSTPARA_MAPA_ID = 'COD_DOMICILIACI'
                                                                   )
                       AND B.SPRIDEN_PIDM = P_PIDM
                       AND SUBSTR (B.SPRIDEN_ID, 1, 2) = SUBSTR (A.TBBDETC_DETAIL_CODE, 1, 2)
                       AND B.SPRIDEN_PIDM = C.TBRACCD_PIDM
                       AND A.TBBDETC_DETAIL_CODE = C.TBRACCD_DETAIL_CODE
                       AND C.TBRACCD_BALANCE > 0
                       AND TO_DATE (TRUNC (C.TBRACCD_EFFECTIVE_DATE)) between vl_inicio_ant and vl_fin_ant
                       AND B.SPRIDEN_CHANGE_IND IS NULL
              GROUP BY SPRIDEN_PIDM;
           EXCEPTION
           WHEN OTHERS THEN
            VL_COMPLEMENTO:=0;
           END;      
                
           --dbms_output.put_line(' Recupera la Complemento '||VL_COMPLEMENTO);
           --dbms_output.put_line(' Recupera Saldo a Favor '||vl_favor);


          VL_REMANENTE:=0;

          If VL_COLEGIATURA > 0 then   -----------> Colegiatura Anteriorir
            If vl_favor > 0 then 
               If vl_favor = VL_COLEGIATURA then 
                  VL_COLEGIATURA:=0;
                  VL_REMANENTE:=0;
               ElsIf vl_favor > VL_COLEGIATURA then
                     VL_COLEGIATURA:=0;                  
                     VL_REMANENTE:= vl_favor - VL_COLEGIATURA;
               ElsIf vl_favor < VL_COLEGIATURA then
                     VL_COLEGIATURA:=VL_COLEGIATURA - vl_favor;                  
                     VL_REMANENTE:= 0;
               End if;
            Else 
                VL_REMANENTE:= 0;        
            End if;
          Elsif VL_COLEGIATURA =0 then 
                VL_COLEGIATURA:=0;
                VL_REMANENTE:=vl_favor;
          End if;

          If VL_COMPLEMENTO > 0 then 
                If VL_REMANENTE > 0 then 
                   If VL_COMPLEMENTO = VL_REMANENTE then
                      VL_COMPLEMENTO:=0;
                      VL_REMANENTE:=0;
                   Elsif VL_COMPLEMENTO > VL_REMANENTE then 
                         VL_COMPLEMENTO := VL_COMPLEMENTO-VL_REMANENTE ;
                         VL_REMANENTE :=0;
                    Elsif VL_COMPLEMENTO < VL_REMANENTE then
                          VL_COMPLEMENTO:=0;
                          VL_REMANENTE := VL_REMANENTE - VL_COMPLEMENTO;                  
                   End if;
                End if;
          Elsif VL_COMPLEMENTO =0 then 
              VL_COMPLEMENTO:=0;
          End if;

           VL_RETORNA:= VL_COLEGIATURA||','||VL_COMPLEMENTO;     
           --dbms_output.put_line('RETURNO '||VL_COLEGIATURA ||'*'||VL_COMPLEMENTO);
      
    Elsif vl_dia != p_dia and vl_dia not in (1,2,3) then
            VL_RETORNA:= 0||','||0;
             --dbms_output.put_line('Bloque 4 '||p_dia);
            --dbms_output.put_line('RETURNO '|| '0' ||'*'||'0');

    End if;

 RETURN(VL_RETORNA);

END FNC_OBTIENE_PARCIALIDAD_TOTAL_2;


-- Funcion para encontrar el monto del cargo que se aplicara en la domiciliaci n de un alumno EGRESADO
FUNCTION f_Parcialidad_Egresado (p_pidm IN NUMBER, p_study_path IN VARCHAR2, p_moneda IN VARCHAR2) RETURN NUMBER IS
-- Descripcion: Obtiene la parcialidad correspondiente de un alumno EGRESADO con saldo pendiente
-- Autor......: Omar L. Meza Sol
-- Fecha......: 07/Junio/2024

-- Variables
   Vm_Saldo_TOTAL          NUMBER := 0; 
   Vm_Parcialidad_Egresado NUMBER := 0;

BEGIN
  -- Obtiene el Saldo Pendiente al d a
  BEGIN
     -- Saldo TOTAL
     Vm_Saldo_TOTAL := 0;

     SELECT SUM (NVL (tbraccd_balance, 0)) SALDO_TOTAL
       INTO Vm_Saldo_TOTAL
       FROM tbraccd
      WHERE tbraccd_pidm = p_pidm
        AND ( tbraccd_detail_code IN (SELECT z.TZTNCD_CODE
                                        FROM tztncd z, tbbdetc b
                                       WHERE z.TZTNCD_concepto         = 'Venta'    
                                         AND b.TBBDETC_detail_code     = z.TZTNCD_CODE   
                                         AND b.TBBDETC_type_ind        = 'C'     
                                         AND b.TBBDETC_detc_active_ind = 'Y'
                                         AND b.TBBDETC_dcat_code       = 'COL'    
                                         AND b.TBBDETC_taxt_code NOT IN ('GN','EC','CU','ES','ID','BA')                                 
                                   )
              OR
              SUBSTR (tbraccd_detail_code,3,2) IN (SELECT DISTINCT zstpara_param_id
                                                     FROM zstpara a
                                                    WHERE zstpara_mapa_id = 'COD_DOMICILIACI'
                                                  )
            );

  EXCEPTION
     WHEN OTHERS THEN 
          Vm_Saldo_TOTAL          := 0;
          Vm_Parcialidad_Egresado := 0;
  END;

  -- Tiene Saldo Pendiente ?
  IF Vm_Saldo_TOTAL > 0 THEN
     BEGIN
        -- Obtiene el monto de la parcialidad dependiendo de la divisa
        SELECT zstpara_param_valor
          INTO Vm_Parcialidad_Egresado
          FROM zstpara a
         WHERE zstpara_mapa_id  = 'EGRESADO_DOMICI'
           AND zstpara_param_id = p_moneda;

     EXCEPTION WHEN OTHERS THEN 
        Vm_Saldo_TOTAL          := 0;
        Vm_Parcialidad_Egresado := 0;
     END;

     -- Verifica que se haya encontrado la parcialidad de la Moneda
     IF Vm_Parcialidad_Egresado > 0 THEN
        -- Aplica el monto de la parcidalidad correspondiente
        IF Vm_Saldo_TOTAL < Vm_Parcialidad_Egresado
           THEN Vm_Parcialidad_Egresado := Vm_Saldo_TOTAL; 
        END IF;

     END IF;
  END IF;

  RETURN Vm_Parcialidad_Egresado;

END f_Parcialidad_Egresado;


end pkg_simoba;
/

DROP PUBLIC SYNONYM PKG_SIMOBA;

CREATE OR REPLACE PUBLIC SYNONYM PKG_SIMOBA FOR BANINST1.PKG_SIMOBA;


GRANT EXECUTE ON BANINST1.PKG_SIMOBA TO BAN_DEFAULT_Q;

GRANT EXECUTE ON BANINST1.PKG_SIMOBA TO BAN_DEFAULT_WEBPRIVS;

GRANT EXECUTE ON BANINST1.PKG_SIMOBA TO CONSULTA;

GRANT EXECUTE ON BANINST1.PKG_SIMOBA TO WWW_USER;
