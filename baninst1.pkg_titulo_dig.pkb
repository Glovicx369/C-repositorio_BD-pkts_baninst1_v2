DROP PACKAGE BODY BANINST1.PKG_TITULO_DIG;
--------------------------------------se agrega esta linea para probar el versionamiento de GITHUB 08.07.2025
CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_TITULO_DIG   AS
-----PROCESO PARA GENERAR LOS TITULOS ELECTRONICOS
---- GLOVICX 17/06/2019--


cursor c_parametros(p_valor  varchar2, p_desc varchar2 ) is
select --ZSTPARA_PARAM_VALOR  as valor, 
        ZSTPARA_PARAM_DESC  as descr,
        ZSTPARA_PARAM_ID    as idv
from zstpara  z
where ZSTPARA_MAPA_ID = 'CERT_DIGITAL'
and  ZSTPARA_PARAM_VALOR  = p_valor
and  z.ZSTPARA_PARAM_DESC  = nvl(p_desc, z.ZSTPARA_PARAM_DESC ) 
order by 1;


cursor c_parametros2(p_mapa varchar2, p_valor  varchar2, p_desc varchar2 ) is
select --ZSTPARA_PARAM_VALOR  as valor, 
        ZSTPARA_PARAM_DESC  as descr,
        ZSTPARA_PARAM_ID    as idv
from zstpara  z
where ZSTPARA_MAPA_ID = p_mapa --'CERT_DIGITAL'
and  ZSTPARA_PARAM_VALOR  = p_valor
and  z.ZSTPARA_PARAM_DESC  = nvl(p_desc, z.ZSTPARA_PARAM_DESC ) 
order by 1;

--------------ESTOS SON LOS NUEVO CURSORES PARA TITULO DIG--
-------este cursor es todos los alumnos que ya tienen su certificado digital entonces ya pueden sacar su titulo digital
cursor c_certificados( pprograma varchar2, ppidm number) is
select f.SZTTIDI_PIDM_TITULO  as pidm , 
       f.SZTTIDI_PROGRAM   as programa,
      regexp_replace(REGEXP_REPLACE(SPBPERS_LEGAL_NAME,'[^a-z_A-Z ]'), '( ){2,}', ' ' ) nombre_alum
From SZTTIDI F  , SPBPERS sp
    where 1=1  
    and    F.SZTTIDI_PIDM_TITULO  =  SP.SPBPERS_PIDM
    and    F.SZTTIDI_ACTIVY_IND   = 1
    and    F.SZTTIDI_PROGRAM      = pprograma --nvl(pprograma, F.SZTTIDI_PROGRAM_CERTIF)
    and    F.SZTTIDI_PIDM_TITULO  = ppidm -- NVL(ppidm,F.SZTTIDI_PIDM_CERTIF)
    order by 1 desc ;
-----------------------

vsello CLOB;
vsello1 CLOB;
vdetcert clob;
v_firma  clob;

salida           UTL_FILE.FILE_TYPE  ;
nom_archivo      varchar2(40);
directorio       varchar2(90);
salida_dat       varchar2(32000);
Salida_dat1     varchar2(32000);

l_xmltype        XMLTYPE;


vpidm                number;
--vmsjerror          varchar2(1000);
vxml_inicio            varchar2(200);
vxml_respon            varchar2(10000);

v_folio_ctrl    number; ---varchar2(8);
v_folio_ctrl2   varchar2(8);

v_idinstituto   VARCHAR2(12);
--v_idcargo       number;
v_curp_resp      varchar2(20);
v_curp_resp1      varchar2(20);
v_nombre_resp     varchar2(50);
v_nombre_resp1     varchar2(50);
v_curp_alumn     varchar2(20);
--v_materno_alumn    varchar2(80);
v_materno_alumn2    varchar2(80);
v_paterno_alumn   varchar2(80);
v_nombre_alumn     varchar2(50);

---------------------------------------
matricula  spriden.spriden_id%type;

ppidm        number; --:=59308; ----parametro de entrada  del procedimento
pprograma    varchar2(15) ;   ----parametro de entrada del procedimiento

--vvalor   varchar2(30);
vdescr    varchar2(100);
vidv     varchar2(10);
vnombre_inst   varchar2(100);

v_cargo       varchar2(30);
v_cargo1       varchar2(20);
v_carrera      varchar2(80);


v_no_apelld   number;

vxml_tag1    varchar2(5000);
vxml_tag1_1  varchar2(5000);
vxml_tag_2  varchar2(5000);
vxml_tag_3  varchar2(5000);
vxml_tag_4  varchar2(5000);
vxml_tag_5  varchar2(5000);
vxml_tag_6  varchar2(5000);
vxml_fin    varchar2(30);
--
---
v_id_cargo         varchar2(3);
v_id_cargo1        varchar2(3);
v_entidad_fed      varchar2(50);
v_identidad_fed    varchar2(5);
v_fund_ss          varchar2(100);
v_idfund_ss        varchar2(3);
---
v_ss_ok             number;
v_fech_exam_prof    VARCHAR2(14); -- date;
v_modalidad_titu    varchar2(100);
v_idmodalidad_titu  varchar2(100);
v_fecha_exp          date; -- VARCHAR2(14); --:=to_date(sysdate, 'YYYY-MM-DD');
v_fecha_exp2          VARCHAR2(14);
--
v_ant_fech_term     VARCHAR2(14);--date;
v_ant_fech_ini      VARCHAR2(14); --date;
v_ant_entidad_fed   varchar2(50);
v_ant_identidad_fed varchar2(8);
v_ant_tipo_est    varchar2(50);
v_ant_idtipo_est  varchar2(8);
v_procedencia     varchar2(200);
vn_art_ss         varchar2(3);

v_apellido2_resp2  varchar2(100);
v_apellido1_resp2  varchar2(100);
v_apellido2_resp   varchar2(100);
v_apellido2_resp1  varchar2(100);
v_apellido1_resp1  varchar2(100);
--v_apellido2_resp1  varchar2(100);

vno_respon        VARCHAR2(20);
vno_respon1       VARCHAR2(20);
v_responable      clob;
v_responable1     clob;
v_titulo          varchar2(20);
v_titulo1         varchar2(20);
--v_apellido1_resp  varchar2(100);
v_email_alumno    varchar2(80);
vid_carrera       varchar2(15);
v_reconocimi      varchar2(50);
v_idreconocimi    varchar2(3);
v_fecha_termino   VARCHAR2(14);
v_fecha_ini       VARCHAR2(14);
vxml_total        clob;
v_rvoe           varchar2(20);
vconta           NUMBER:=0;
vgrado          varchar2(8); 
p_representate    number;
---  esta es la fecha global que se usa para sacar el max de fecha y pasa de un proceso a otro
vfech_docu    date; --varchar2(14);
-- fechas globales de titulo y certy glovicx 03.07.2024
vfecha_certy  date;
vfecha_titu   date;

function encode_base64(base in varchar2) return varchar2 is
 resultado varchar2(32000);
  RESULTADO3 CLOB;
begin
   resultado := utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(trim(base))));
   
----dbms_output.put_line('Encode '||RESULTADO3  );  

return ( resultado );
end encode_base64;

function decode_base64(base in varchar2) return varchar2 is
 resultado varchar2(32000);

begin
  
  resultado :=  utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(base)));

--resultado := utl_encode.text_encode( base ,'WE8ISO8859P1', UTL_ENCODE.BASE64);

----dbms_output.put_line('Encode '||resultado  );  

return ( resultado );
end decode_base64;

procedure p_archivo_xml ( pcadena in clob, ppidalumno in varchar2, pprograma  in varchar2 ) is
salida         UTL_FILE.FILE_TYPE  ;
nom_archivo    varchar2(150);
directorio     varchar2(90);
mserr          varchar2(2000);
--text_raw      RAW (32767);
text            VARCHAR2 (32767); 
text_raw        RAW (32767); 
filehandler     UTL_FILE.file_type; 
vgrado          varchar2(8);
  
begin
null;
 
-------validamos si el programa es de licenciatura entonces al nombre le agrega una "T" pero si es maestria se le agrega una "G" de grado-- glovicx 29/10/2019
vgrado := substr(pprograma,4,2);
----dbms_output.put_line(' recupera el nivel   '||vgrado); 

 text := trim(pcadena); 

 if vgrado = 'LI'  then
 --dbms_output.put_line(' recupera el nivel 2  '||vgrado);  
 nom_archivo := 'XMLT'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.xml';
 
 elsif vgrado in ( 'MA', 'DO')  then
 nom_archivo := 'XMLG'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.xml';
 --dbms_output.put_line(' recupera el nivel 2  '||vgrado||'-'|| ppidalumno); 
 end if;
 
 
--convert it to raw encoded text 
 --text_raw := UTL_I18N.string_to_raw (text, 'UTF8');  -------text es mi cadena AL32UTF8
  text_raw := UTL_I18N.string_to_raw (trim(text), 'AL32UTF8'); 
-- open the file with the nchar for new encoding in the Directory BBSIS 
 filehandler := UTL_FILE.fopen_nchar ('ARCHXML', nom_archivo, 'w', 32767); 
-- write the bom section 
 --UTL_FILE.put_nchar (filehandler, UTL_I18N.raw_to_nchar (bom_raw, 'UTF8')); 
 -- Now. write out the rest of our text retrieved from Oracle with its UTF8 encoding 
 --UTL_FILE.put_nchar (filehandler, UTL_I18N.raw_to_nchar (text_raw, 'UTF8'));
  UTL_FILE.put_nchar (filehandler, UTL_I18N.raw_to_nchar (trim(text_raw), 'AL32UTF8')); 
 -- Close the unicode (UTF8) encoded text file 
 UTL_FILE.fclose (filehandler); 

   --UTL_FILE.PUT_LINE(salida,'\n');
    UTL_FILE.fclose(filehandler);
 IF utl_file.is_open(filehandler) THEN
     utl_file.fclose_all;
     --dbms_output.put_line('Closed All');
   END IF;
 
 
 
update SZTTIDI
set SZTTIDI_XML_IND = 1
where SZTTIDI_PIDM_TITULO  = nvl(fget_pidm(ppidalumno),SZTTIDI_PIDM_TITULO )
and  SZTTIDI_PROGRAM = pprograma;


end p_archivo_xml;

procedure p_genera_dgair ( pcadena in clob, ppidalumno in varchar2, pprograma in varchar2 ) is
salida         UTL_FILE.FILE_TYPE  ;
nom_archivo    varchar2(150);
directorio     varchar2(90);
mserr          varchar2(2000);
  
  
begin
null;
 

-------validamos si el programa es de licenciatura entonces al nombre le agrega una "T" pero si es maestria se le agrega una "G" de grado-- glovicx 29/10/2019
vgrado := substr(pprograma,4,2);
----dbms_output.put_line(' recupera el nivel 1 '||vgrado); 


if vgrado = 'LI'  then 
----dbms_output.put_line(' recupera el nivel 2  '||vgrado); 
 nom_archivo := 'DgairT'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.txt';
 elsif vgrado in ( 'MA', 'DO')   then
 ----dbms_output.put_line(' recupera el nivel3   '||vgrado); 
nom_archivo := 'DgairG'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.txt';
----nom_archivo :=  'DgairG'||vgrado; 
 end if;

 ----dbms_output.put_line(' salida archivo DGAIR-------  '|| ppidalumno); 
----nom_archivo := 'DgairT'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.txt';
-- --dbms_output.put_line(' nomnbrev  archivo DGAIR-------  '|| nom_archivo); 
 salida := UTL_FILE.fopen('ARCHXML',nom_archivo, 'W', 32767);
 
 ----dbms_output.put_line(' salida open  '); 
  UTL_FILE.PUT_LINE(salida, trim(pcadena));
   --UTL_FILE.PUT_LINE(salida,'\n');
    UTL_FILE.fclose(salida);
 IF utl_file.is_open(salida) THEN
     utl_file.fclose_all;
    -- --dbms_output.put_line('Closed All');
   END IF;
 

end p_genera_dgair;

procedure p_genera_dgair2 ( pcadena in clob, ppidalumno in varchar2 , pprograma in varchar2) is
salida         UTL_FILE.FILE_TYPE  ;
nom_archivo    varchar2(150);
directorio     varchar2(90);
mserr          varchar2(2000);
  
  
begin
null;
 
vgrado := substr(pprograma,4,2);
----dbms_output.put_line(' recupera el nivel 1  '||vgrado); 

if vgrado = 'LI'  then 
----dbms_output.put_line(' recupera el nivel 2  '||vgrado); 
 nom_archivo := 'DgairT2'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.txt';
 elsif vgrado in ( 'MA', 'DO')  then
-- --dbms_output.put_line(' recupera el nivel 3  '||vgrado); 
nom_archivo := 'DgairG2'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.txt';
 end if;
 
 ----dbms_output.put_line(' salida archivo DGAIR-------  '|| ppidalumno); 
--nom_archivo := 'DgairT2'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.txt';
-- --dbms_output.put_line(' nomnbrev  archivo DGAIR-------  '|| nom_archivo); 
 salida := UTL_FILE.fopen('ARCHXML',nom_archivo, 'W', 32767);
 
 ----dbms_output.put_line(' salida open  '); 
  UTL_FILE.PUT_LINE(salida, trim(pcadena));
   --UTL_FILE.PUT_LINE(salida,'\n');
    UTL_FILE.fclose(salida);
 IF utl_file.is_open(salida) THEN
     utl_file.fclose_all;
     --dbms_output.put_line('Closed All');
   END IF;
 

end p_genera_dgair2;


Procedure P_inicio (ppidm in  number, pprograma in varchar2, p_representate in number, PMODO NUMBER DEFAULT 0  )  Is


v_no_apelld2   number;
v_encode64    varchar2(10000);
v_fecha_exp_titu  varchar2(14);
vno_cedula    varchar2(20);
v_nivel     varchar(5);
vextranjero   varchar2(25);


begin
null;

--
--dbms_output.put_line('paso 1   ' || ppidm || '--' || pprograma );


--open c_parametros('CARGOS', 'DIRECTOR');
--fetch c_parametros  into   vdescr,  vidv;
--v_id_cargo := vidv;
--v_cargo := vdescr;
----dbms_output.put_line('>>>>CARgos DIRECTOR  '||v_id_cargo || ' - '|| v_cargo);
--close c_parametros;

open c_parametros('CARGOS', 'RECTOR');
fetch c_parametros  into   vdescr,  vidv;
v_id_cargo1 := vidv;
v_cargo1 := vdescr;
--dbms_output.put_line('>>>>CARgos RECTOR  '||v_id_cargo1 || ' - '|| v_cargo1);
close c_parametros;



open c_parametros('ENTIDAD_FED', 'CIUDAD DE M…XICO');
fetch c_parametros  into   vdescr,  vidv;
v_identidad_fed := vidv;
v_entidad_fed := vdescr;
--dbms_output.put_line('>>>>ENtidad fed  '||v_identidad_fed || ' - '|| v_entidad_fed);
close c_parametros;

--open c_parametros('INSTITUCIONES', null);
--fetch c_parametros  into   vdescr,  vidv;
--v_idinstituto := vidv;
--vnombre_inst := vdescr;
----dbms_output.put_line('>>>>INstituto   '||v_idinstituto || ' - '|| vnombre_inst);
--close c_parametros;
--

   SELECT ZSTPARA_PARAM_DESC  ------obtienen el nuevo nobre de institucion  
     INTO (vnombre_inst)
   FROM ZSTPARA 
    WHERE ZSTPARA_MAPA_ID = 'TITULO_DIGITAL'
     AND ZSTPARA_PARAM_VALOR =  'INSTITUTO'
      AND ZSTPARA_PARAM_SEC  = 24;
      
   SELECT ZSTPARA_PARAM_DESC-------------obtiene el nuevo id de instituto 
     INTO v_idinstituto
   FROM ZSTPARA 
    WHERE ZSTPARA_MAPA_ID = 'TITULO_DIGITAL'
     AND ZSTPARA_PARAM_VALOR =  'INSTITUTO'
      AND ZSTPARA_PARAM_SEC  = 25;
      


open c_parametros2('TITULO_DIGITAL','RECONOCIMIENTO', 'RVOE FEDERAL');  ----VALIDAR CON LAURA SI TITULOS SOLO LOS EXPIDE sep ENTONCES ES CIUDAD DE MEXICO PERO SI LO HACE SEGEM ES MEXIC
fetch c_parametros2  into   vdescr,  vidv;
v_idreconocimi := vidv;
v_reconocimi := vdescr;
--dbms_output.put_line('>>>>RECONOCIMIENTO  '||v_idreconocimi || ' - '|| v_reconocimi);
close c_parametros2;
--
-- reiniciamos las variables---
vdescr :='';
vidv   :='';

open c_parametros2('TITULO_DIGITAL','MODALIDAD', 'OTRO');  
fetch c_parametros2  into   vdescr,  vidv;
v_idmodalidad_titu := vidv;
v_modalidad_titu := vdescr;
--dbms_output.put_line('>>>>MODALIDAD TITULACION  '||v_idmodalidad_titu || ' - '|| v_modalidad_titu);
close c_parametros2;



-------------------------selecciona los datos del director---- esta seccio va desaparecer ya que hay ajustes en el xml solo el recto aparece glovicx 15.06.2023
/*
BEGIN
SELECT SZTREDC_NOMBRE, SZTREDC_PATERNO, SZTREDC_MATERNO, SZTREDC_CURP, SZTREDC_NO_CERTIFICADO,SZTREDC_CVE_FIRMA , TRIM(SZTREDC_TITULO), 
z.ZSTPARA_PARAM_ID id_rep,
z.ZSTPARA_PARAM_DESC cargo
INTO   v_nombre_resp,  v_apellido1_resp2,  v_apellido2_resp,  v_curp_resp,  vno_respon, v_responable , v_titulo,
v_id_cargo,v_cargo 
FROM  SZTREDC CE,zstpara z
WHERE  1=1   
and  z.ZSTPARA_MAPA_ID = 'CERT_DIGITAL'
and   z.ZSTPARA_PARAM_VALOR  = 'CARGOS'
and  ce.SZTREDC_IDCARGO  = z.ZSTPARA_PARAM_ID
and  CE.SZTREDC_IDCARGO = p_representate 
AND SZTREDC_ESTATUS = 1;

--dbms_output.PUT_LINE('RESPONSABLE 1:: '||v_id_cargo || '-'|| v_nombre_resp);
exception when others then
vno_respon:='';
v_responable:='';
--dbms_output.put_line('>>>>eRROR en recupera el cargo DIRECTOR  '||v_id_cargo );
END;
*/

BEGIN
--v_id_cargo1 :=2 ;-- ESTE ES PARA EL RECTOR POR DEFAULT 
----------------esta seccion es para el rector----
SELECT SZTREDC_NOMBRE, SZTREDC_PATERNO, SZTREDC_MATERNO, SZTREDC_CURP, SZTREDC_NO_CERTIFICADO,SZTREDC_CVE_FIRMA ,TRIM(SZTREDC_TITULO) 
INTO   v_nombre_resp1,  v_apellido1_resp1,  v_apellido2_resp1,  v_curp_resp1,  vno_respon1, v_responable1 , v_titulo1
FROM  SZTREDC CE
WHERE 1=1
and  CE.SZTREDC_IDCARGO = v_id_cargo1
 AND SZTREDC_ESTATUS = 1 ;

--dbms_output.PUT_LINE('RESPONSABLE 2:: '||v_id_cargo1 || '-'|| v_nombre_resp1);

exception when others then
vno_respon1:='';
v_responable1:='';
--dbms_output.put_line('>>>>eRROR en recupera el cargo  RECTOR  '||v_id_cargo1 );
END;

--dbms_output.put_line('>>SELLO FERTIFI  '||v_responable );
--dbms_output.put_line('>>firma ERTIFI  '||vno_respon );

matricula := F_GetSpridenID(ppidm);
--dbms_output.put_line('paso 2   ' || ppidm || '--' || pprograma||'***'|| matricula );
--
--
v_folio_ctrl  :=0;

FOR  jump in c_certificados(pprograma, ppidm  )  loop
  
--dbms_output.put_line('paso 2_A   ' || ppidm || '--' || pprograma||'***'|| matricula );

vpidm:= JUMP.PIDM;


       begin
        
           select MAX(SZTTIDI_FOLIO_CONTROL)+1
                into  v_folio_ctrl
                from SZTTIDI ;     
         --dbms_output.put_line('el numero de folio es:: '||  v_folio_ctrl);
          
            if v_folio_ctrl = 0 then 
                --select lPAD(NVL(max(SZTTIDI_FOLIO_CONTROL),100)+1,6,'0')+1
                  select MAX(SZTTIDI_FOLIO_CONTROL)+1
                into  v_folio_ctrl
                from SZTTIDI ;
             end if;
              
             v_folio_ctrl2 := LPAD(v_folio_ctrl,6,'0');
             --dbms_output.put_line('el numero de folio3 es:: '||  v_folio_ctrl2);   

        vxml_inicio:='<?xml version="1.0" encoding="UTF-8"?>';

                   
        vxml_respon :='
        <TituloElectronico xsi:schemaLocation="https://www.siged.sep.gob.mx/titulos/ schema.xsd" folioControl="'||v_folio_ctrl2||'"
        version="1.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="https://www.siged.sep.gob.mx/titulos/">';
                      
              
        exception when others  then
               v_folio_ctrl := 1;
               
        end;
        
 BEGIN
            ---------------esta consulta es para sacar el numero del articulo del sericio social ----
            SELECT distinct REGEXP_SUBSTR(SGRCOOP_EMPL_CONTACT_TITLE,'[0-9]+') no_art
            INTO vn_art_ss
            FROM SGRCOOP gp
            where GP.SGRCOOP_PIDM = jump.pidm ;
            
   EXCEPTION WHEN OTHERS THEN 
            vn_art_ss := 'NO';
   END;
            
           --dbms_output.put_line('paso servicio soc   ' || ppidm || '--' || pprograma||'***'|| vn_art_ss );
            -------segundaparte del servicio soc  buca en el catalogo-----
            BEGIN
                                            
               select ZSTPARA_PARAM_SEC, ZSTPARA_PARAM_DESC -- ZSTPARA_PARAM_VALOR,ZSTPARA_PARAM_ID
                into   v_idfund_ss  , v_fund_ss
                 from zstpara  z
                  where z.ZSTPARA_MAPA_ID = 'TITULO_DIGITAL'
                   and   z.ZSTPARA_PARAM_VALOR = 'SERVICIO_SOC'
                  and   z.ZSTPARA_PARAM_ID like ( '%'||vn_art_ss||'%' );
                       
                
                       
            --------si entra a estaentencia es que si encuentra el SS y lo valido
            v_ss_ok := 1; --si cumplio con SS
           EXCEPTION WHEN OTHERS THEN 
            v_idfund_ss :='';
            v_fund_ss   := '';
            v_ss_ok     :=0;
            
           END;
           --dbms_output.put_line('>>8 ');
          ---- aqui va una modificaciÛn para el curp en los para los extranjeros glovicx 16.04.2024
        begin
           
           select 'EXTRANJERO'
             INTO  vextranjero
              from SZVCAMP p
                where 1=1
                and P.SZVCAMP_COUNTRY != 'MEX'
                and P.SZVCAMP_CAMP_ALT_CODE  = substr(matricula,1,2) ;
                
        EXCEPTION WHEN OTHERS  THEN
           vextranjero := 'NULL';
               
         END;
        
        IF vextranjero = 'EXTRANJERO' THEN 
          v_curp_alumn := 'EXTRANJERO';
          
          
         ELSE
        
           BEGIN
                
                SELECT upper(GORADID_ADDITIONAL_ID)
            INTO  v_curp_alumn
            FROM GORADID
                 WHERE GORADID_PIDM = PPIDM 
            AND GORADID_ADID_CODE = 'CURP';
                 
             EXCEPTION
                WHEN OTHERS
                THEN
                   v_curp_alumn := 'ERROR';
            END;

                       
        END IF;
       

                       
            BEGIN
               SELECT  GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES
                 INTO  v_email_alumno
               FROM GOREMAL
                WHERE  GOREMAL_PIDM = jump.pidm
                  AND  GOREMAL_EMAL_CODE = ('PRIN')
                  and GOREMAL_STATUS_IND = 'A';
            EXCEPTION WHEN OTHERS THEN
            --v_email_alumno:= 'ERROR';
                  BEGIN
                   SELECT  GOREMAL_EMAIL_ADDRESS EMAIL_ADRRES
                     INTO  v_email_alumno
                   FROM GOREMAL
                    WHERE  GOREMAL_PIDM = jump.pidm
                      AND ( GOREMAL_EMAL_CODE = ('ALTE')
                        OR  GOREMAL_EMAL_CODE = ('INST') )
                      --and GOREMAL_STATUS_IND = 'A'
                      and rownum <2
                      ;
                      
                  EXCEPTION WHEN OTHERS THEN
                          v_email_alumno := 'NO existe' ; 
                  
                   END;
              
            
            
            END;
              --dbms_output.put_line('paso EMAIL  ' || ppidm || '--' || pprograma||'***'|| v_email_alumno );
           ------------------------recvupera los datos de la carrera----
        begin           
         
         SELECT UPPER(ZP.SZTPRGM_DESC) ,  SZTDTEC_ID_CERTIFICA, SZTDTEC_NUM_RVOE
        into  v_carrera, vid_carrera, v_rvoe
        from sztdtec zt, saturn.SZTPRGM zp
        where 1=1
        and ZT.SZTDTEC_PROGRAM  = ZP.SZTPRGM_CODE
        and  SZTDTEC_CAMP_CODE  = substr(pprograma,1,3) --   'UTL'UTLLIIAFED
        and   SZTDTEC_PROGRAM    = pprograma
        --and  SZTDTEC_STATUS  = 'ACTIVO'
       -- and SZTDTEC_ID_CARRERA  = ( select max (zz.SZTDTEC_ID_CARRERA)  from sztdtec zz where  zz.SZTDTEC_PROGRAM = zt.SZTDTEC_PROGRAM  )
        and  SZTDTEC_TERM_CODE = (select distinct SORLCUR_TERM_CODE_CTLG from sorlcur cu 
                                   where sorlcur_pidm = jump.pidm  
                                   and  SORLCUR_LMOD_CODE = 'LEARNER' 
                                    and  SORLCUR_CACT_CODE  = 'ACTIVE'  and  SORLCUR_PROGRAM = pprograma
                                    and  SORLCUR_TERM_CODE  = ( Select max(SORLCUR_TERM_CODE)  from sorlcur dd where DD.SORLCUR_PIDM =cu.sorlcur_pidm
                                                                   and  DD.SORLCUR_PROGRAM  = CU.SORLCUR_PROGRAM  and dd.SORLCUR_LMOD_CODE = 'LEARNER' 
                                                                     and  dd.SORLCUR_CACT_CODE  = 'ACTIVE'   ) ) ;
         exception when others then
            v_carrera :='';
            vid_carrera:='';
           --dbms_output.put_line('>>ERROR en sztdtec para sacr prohrama '|| pprograma ||'***'||jump.pidm||'++'|| sqlerrm ); 
         end;
   --dbms_output.put_line('pasocodigo carrera  ' || vid_carrera || '--' || v_rvoe||'***'|| v_carrera );
--          
            BEGIN
               
          select DISTINCT to_char(SZTCEDU_TFECHA_TERM, 'YYYY-MM-DD') as fech_term_antecedent,
                to_char(SZTCEDU_TFECHA_INI,'YYYY-MM-DD') fecha_ini , 
                   SZTCEDU_TID_ENTFED,
                   ENTIDAD, 
                   --SZTCEDU_TID_ENTFED, 
                   SZTCEDU_TIPO_PROD, 
                   ZSTPARA_PARAM_DESC, 
                   trim(SZTCEDU_TESCUELA_PROD),
                   to_char(SZTCEDU_FECHA_TERMINO,'YYYY-MM-DD')   as fecha_term_carrera 
                  ,to_char(SZTCEDU_FECHA_IMP_TITULO,'YYYY-MM-DD') as fecha_emisintitulo
                  ,SZTCEDU_NUMERO_CEDULA 
                INTO v_ant_fech_term, 
                     v_ant_fech_ini, 
                     v_ant_identidad_fed, 
                     v_ant_entidad_fed, 
                     v_ant_idtipo_est, 
                     v_ant_tipo_est, 
                     v_procedencia,
                     v_fecha_termino
                     , v_fecha_exp_titu
                     ,vno_cedula
                from SZTCEDU u, SATURN.sztenti e ,zstpara  z 
                where  1=1
                 AND  U.SZTCEDU_TID_ENTFED = E.ID_ENTI
                 and  u.SZTCEDU_PROGRAMA  = pprograma
                 and  u.SZTCEDU_PIDM    = jump.pidm
                 AND  Z.ZSTPARA_MAPA_ID = 'TITULO_DIGITAL' --p_mapa
                 and  Z.ZSTPARA_PARAM_VALOR  = 'ANTECEDENTE'
                 and  Z.ZSTPARA_PARAM_ID = to_char(SZTCEDU_TIPO_PROD); 
                 
                --dbms_output.put_line('antecedente:::'|| v_ant_fech_term||'-'||v_ant_fech_ini||'-'||v_ant_identidad_fed||'-'||
                     --  v_ant_entidad_fed||'-'||v_ant_idtipo_est||'-'||v_ant_tipo_est||'-'||v_procedencia  );
          exception when others then
           v_ant_fech_term :='';
           v_ant_fech_ini :='';
           v_ant_identidad_fed :='';
           v_ant_entidad_fed :='';
           v_ant_idtipo_est :='';
           v_ant_tipo_est :='';
           v_procedencia :='';
           
           
           --dbms_output.put_line('>>ERROR EN SZTCEDU PARA OBTENER FECHA TERMINO CARRERA:: '|| pprograma ||'***'||jump.pidm ||sqlerrm); 
         end;
         -----asigan cedula si es licenciatura o maestria----
         if  substr(pprograma,4,2) = 'LI'  then    --UTLLIIAFED
         
         vno_cedula :=null;
         --dbms_output.put_line('numero de cedula '|| vno_cedula  );
         
         elsif substr(pprograma,4,2) = 'MA'  then
          ----------si es maestria entonces debe recuperar el numero de cedula
         null;
           v_ss_ok     :=0;  -----en este caso las maestrias no tienen servicio soc. por eso por default lleva cero,  esto lo mando "paty guzman de SEP" glovicx 12-11-2019
         
             BEGIN
               select SZTCEDU_NUMERO_CEDULA 
                 into  vno_cedula 
                 FROM sztcedu
                 where SZTCEDU_PIDM = jump.pidm
                   and SZTCEDU_PROGRAMA  = pprograma;
             EXCEPTION WHEN OTHERS THEN
               vno_cedula :='NA';
             END;
                  --  --dbms_output.put_line('numero de cedula_MA '|| vno_cedula  );
         end if;
         
         
         -------------------calcula fgecha inicio de la carrera en utel-----
         
            begin                        
               select distinct to_char(STVTERM_START_DATE, 'YYYY-MM-DD')
                INTO v_fecha_ini
                from sfrstcr f, stvterm t
                where  sfrstcr_pidm =  jump.pidm
                and F.SFRSTCR_TERM_CODE  = T.STVTERM_CODE
                and F.SFRSTCR_TERM_CODE  = (select min(Ff.SFRSTCR_TERM_CODE)  from sfrstcr ff where  ff.sfrstcr_pidm = f.sfrstcr_pidm ) 
                and exists( select 1 from sgbstdn where SGBSTDN_PIDM = sfrstcr_pidm and  SGBSTDN_STST_CODE  = 'EG')  ;    
              
                --v_fecha_ini  := '';
                
            exception when others then
              v_fecha_ini  := '';
            end; 
         
        --dbms_output.put_line('FECHA INICIAL '|| v_fecha_ini  );
         
    v_fecha_exp := trunc(SYSDATE)-2;
     -- --dbms_output.put_line('FECHA expedicion_1_:: '|| v_fecha_exp  );
  
    v_fecha_exp2 := to_char(v_fecha_exp, 'YYYY-MM-DD') ;
    v_ant_fech_ini  := null;  -- eta la vamos a dejar siempre nula por regla de negocio elizabeth
     
     BEGIN
           SELECT DISTINCT
           substr(TRANSLATE(UPPER(S.SPRIDEN_LAST_NAME),
                     '·ÈÌÛ˙¡…Õ”⁄¸‹',
                     'aeiouAEIOUuU'), 1, INSTR(S.SPRIDEN_LAST_NAME,'/')-1)  paterno  ,       
            substr(TRANSLATE(UPPER(S.SPRIDEN_LAST_NAME),
                                 '·ÈÌÛ˙¡…Õ”⁄¸‹',
                                 'aeiouAEIOUuU'),INSTR(S.SPRIDEN_LAST_NAME,'/')+1 )  materno  ,       
           REGEXP_REPLACE(
                       TRANSLATE(UPPER(S.SPRIDEN_FIRST_NAME),
                                 '·ÈÌÛ˙¡…Õ”⁄¸‹',
                                 'aeiouAEIOUuU'),
                       '[^a-z_A-Z0-9 ]', ' '
                       ) AS nombre                
                  /* ,TO_CHAR (sp.SPBPERS_BIRTH_DATE, 'YYYY-MM-DD')
                   || 'T'
                   || TO_CHAR (sp.SPBPERS_BIRTH_DATE, 'HH24:MI:SS')
                      AS fech_nac,
                   S.SPRIDEN_ID,
                   sorlcur_CAMP_CODE,
                   sorlcur_LEVL_CODE  */
              INTO v_paterno_alumn,
                   v_materno_alumn2,
                   v_nombre_alumn
                   /*v_fech_nac_alumn,
                   v_nu_control,
                   v_campus,
                   v_nivel */
              FROM spriden s, spbpers sp, sorlcur sc
                 WHERE  spriden_pidm =  jump.pidm
                   AND S.SPRIDEN_PIDM = SP.SPBPERS_PIDM
                   AND S.SPRIDEN_PIDM = Sc.Sorlcur_PIDM
                   and Sc.sorlcur_PROGRAM  =  pprograma
                   AND S.SPRIDEN_CHANGE_IND IS NULL;
      EXCEPTION
            WHEN OTHERS
            THEN
               v_materno_alumn2 := '';
               v_nombre_alumn := '';
               
      END;

     
      /*             ---------separa  los apellidos an dos-----
            v_no_apelld  := instr(jump.nombre_alum, ' ');
            v_paterno_alumn  := substr(jump.nombre_alum,1,v_no_apelld-1);
          --  --dbms_output.put_line( ' paterno  ' || v_paterno_alumn || '-'|| v_no_apelld);
           
            v_no_apelld2 := instr(jump.nombre_alum, ' ',1,2);
            v_materno_alumn2 := substr(jump.nombre_alum, v_no_apelld+1,v_no_apelld2-v_no_apelld-1  );

         --   --dbms_output.put_line( ' MATERNO  ' || v_materno_alumn2 || '-'|| v_no_apelld);
            v_nombre_alumn   := substr(jump.nombre_alum, v_no_apelld2+1,50);
           
          --  --dbms_output.put_line( ' NOMBRE  ' || v_nombre_alumn || '-'|| v_no_apelld2);
      
     v_paterno_alumn := replace(v_paterno_alumn, '/',' ');----con esto quitamos las diagonales de los apellidos 
     v_materno_alumn2:= replace(v_materno_alumn2, '/',' ');----con esto quitamos las diagonales de los apellidos
       */               
        ----dbms_output.put_line('REPROCESOOO XML   '||  vpidm );
vxml_tag_2 :='
<Institucion cveInstitucion="'||v_idinstituto||'" nombreInstitucion="'||vnombre_inst||'"/>';
vxml_tag_3 :='
<Carrera cveCarrera="'||vid_carrera||'" nombreCarrera="'||v_carrera||'" fechaInicio="'||v_fecha_ini||'" fechaTerminacion="'||v_fecha_termino||'" idAutorizacionReconocimiento="'||v_idreconocimi||'" autorizacionReconocimiento="'||v_reconocimi||'" numeroRvoe="'||v_rvoe||'"/>';

vxml_tag_4 :='
<Profesionista curp="'||v_curp_alumn||'" nombre="'||trim(v_nombre_alumn)||'" primerApellido="'||trim(v_paterno_alumn)||'" segundoApellido="'||trim(v_materno_alumn2)||'" correoElectronico="'||v_email_alumno||'"/>';

vxml_tag_5 :='
<Expedicion fechaExpedicion="'||v_fecha_exp2||'" idModalidadTitulacion="'||v_idmodalidad_titu||'" modalidadTitulacion="'||v_modalidad_titu||'" fechaExencionExamenProfesional="'||v_fecha_exp_titu||'" cumplioServicioSocial="'||v_ss_ok||'" idFundamentoLegalServicioSocial="'||v_idfund_ss||'" fundamentoLegalServicioSocial="'||v_fund_ss||'" idEntidadFederativa="'||v_identidad_fed||'" entidadFederativa="'||v_entidad_fed||'"/>';

IF vno_cedula is not null THEN
vxml_tag_6 :='
<Antecedente institucionProcedencia="'||v_procedencia||'" idTipoEstudioAntecedente="'||v_ant_idtipo_est||'" tipoEstudioAntecedente="'||v_ant_tipo_est||'" idEntidadFederativa="'|| v_ant_identidad_fed||'" entidadFederativa="'||v_ant_entidad_fed||'" fechaTerminacion="'||v_ant_fech_term||'" noCedula="'||vno_cedula||'"/>';
ELSE
vxml_tag_6 :='
<Antecedente institucionProcedencia="'||v_procedencia||'" idTipoEstudioAntecedente="'||v_ant_idtipo_est||'" tipoEstudioAntecedente="'||v_ant_tipo_est||'" idEntidadFederativa="'|| v_ant_identidad_fed||'" entidadFederativa="'||v_ant_entidad_fed||'" fechaTerminacion="'||v_ant_fech_term||'"/>';
END IF;

----------------------------se debe de genrar dos veces para cada uno de los representantes-------
Salida_dat := ('||'||'1.0'||'|'||v_folio_ctrl2||'|'||v_curp_resp1||'|'||v_id_cargo1||'|'||v_cargo1||'|'||v_titulo1);
--Salida_dat := (Salida_dat||'|'||v_curp_resp1||'|'||v_id_cargo1||'|'||v_cargo||'|'||v_titulo1);
Salida_dat := (Salida_dat||'|'||v_idinstituto||'|'||vnombre_inst||'|'||vid_carrera||'|'||v_carrera||'|'||v_fecha_ini||'|'||v_fecha_termino);
Salida_dat := (Salida_dat||'|'||v_idreconocimi||'|'||v_reconocimi||'|'||v_rvoe||'|'||v_curp_alumn||'|'||trim(v_nombre_alumn)||'|'||trim(v_paterno_alumn)||'|'||trim(v_materno_alumn2)||'|'||v_email_alumno);
Salida_dat := (Salida_dat||'|'||v_fecha_exp2||'|'||v_idmodalidad_titu||'|'||v_modalidad_titu||'||'||v_fecha_exp_titu||'|'||v_ss_ok||'|'||v_idfund_ss||'|'||v_fund_ss||'|'||v_identidad_fed||'|'||v_entidad_fed);
Salida_dat := (Salida_dat||'|'||v_procedencia||'|'||v_ant_idtipo_est||'|'||v_ant_tipo_est||'|'||v_ant_identidad_fed||'|'||v_ant_entidad_fed||'||'||v_ant_fech_term||'|'||vno_cedula||'||');
 

-----dbms_output.PUT_LINE(' SALIDAUNO:: '|| Salida_dat);

--v_encode64 := encode_base64(trim(Salida_dat));
--v_encode64  := encript_base64(salida_dat);  ---nuevo 29oct 2018
--vsello   := v_encode64;
vdetcert := v_firma ; 
    
    
/* aqui genera el archivo fisico dgair  para cada alumno  */
--vxml_tag1 :='<FirmaResponsables>'||'
--              <FirmaResponsable certificadoResponsable="'|| trim(v_responable) ||'"
--              noCertificadoResponsable="'|| trim(vno_respon) ||'"
--              sello="'||trim(vsello)||'"
--              abrTitulo="'||v_titulo||'" cargo="'||v_cargo||'" idCargo="'||v_id_cargo||'" curp="'||v_curp_resp||'" segundoApellido="'||v_apellido2_resp||'" primerApellido="'||v_apellido1_resp2||'" nombre="'||v_nombre_resp||'"/>';
--vxml_tag1 := vxml_tag1||'
--</FirmaResponsables>';


----- este TAG desaparece ya que pertenece al director y ya no va salir glovicx 15.06.2023 nuevo requerimento

vxml_tag1 :='
<FirmaResponsables> ';
/*
<FirmaResponsable certificadoResponsable="'|| trim(v_responable) ||'"
noCertificadoResponsable="'|| trim(vno_respon) ||'"
sello1="'||trim('x')||'"
abrTitulo="'||TRIM(v_titulo)||'" cargo="'||v_cargo||'" idCargo="'||v_id_cargo||'" curp="'||v_curp_resp||'" segundoApellido="'||v_apellido2_resp||'" primerApellido="'||v_apellido1_resp2||'" nombre="'||v_nombre_resp||'"/>';
*/
----------------------------aqui esta el segundo representante-------------------
Salida_dat1 := ('||'||'1.0'||'|'||v_folio_ctrl2||'|'||v_curp_resp1||'|'||v_id_cargo1||'|'||v_cargo1||'|'||v_titulo1);
--Salida_dat1 := (Salida_dat1||'|'||v_curp_resp1||'|'||v_id_cargo1||'|'||v_cargo1||'|'||v_titulo1);
Salida_dat1 := (Salida_dat1||'|'||v_idinstituto||'|'||vnombre_inst||'|'||vid_carrera||'|'||v_carrera||'|'||v_fecha_ini||'|'||v_fecha_termino);
Salida_dat1 := (Salida_dat1||'|'||v_idreconocimi||'|'||v_reconocimi||'|'||v_rvoe||'|'||v_curp_alumn||'|'||trim(v_nombre_alumn)||'|'||trim(v_paterno_alumn)||'|'||trim(v_materno_alumn2)||'|'||v_email_alumno);
Salida_dat1 := (Salida_dat1||'|'||v_fecha_exp2||'|'||v_idmodalidad_titu||'|'||v_modalidad_titu||'||'||v_fecha_exp_titu||'|'||v_ss_ok||'|'||v_idfund_ss||'|'||v_fund_ss||'|'||v_identidad_fed||'|'||v_entidad_fed);
Salida_dat1 := (Salida_dat1||'|'||v_procedencia||'|'||v_ant_idtipo_est||'|'||v_ant_tipo_est||'|'||v_ant_identidad_fed||'|'||v_ant_entidad_fed||'|'||v_ant_fech_ini||'|'||v_ant_fech_term||'|'||vno_cedula||'||');
 

---.PUT_LINE(' SALIDAUNO_1:: '|| Salida_dat1);

---v_encode64 := encode_base64(trim(Salida_dat1));
--v_encode64  := encript_base64(salida_dat);  ---nuevo 29oct 2018
--vsello1   := v_encode64;
vdetcert := v_firma ; 
-------------------------aqui hace la selecion de quitar el segundo apellido del rector si viene vacio cambia de tag--glovicx es por error que nos comento PATY de profesiones 24/10/2019
if v_apellido2_resp1 is null  then 
vxml_tag1_1 :='
<FirmaResponsable certificadoResponsable="'|| trim(v_responable1) ||'"
noCertificadoResponsable="'|| trim(vno_respon1) ||'"
sello2="'||trim('x')||'"
abrTitulo="'||trim(v_titulo1)||'" cargo="'||v_cargo1||'" idCargo="'||v_id_cargo1||'" curp="'||v_curp_resp1||'" primerApellido="'||v_apellido1_resp1||'" nombre="'||v_nombre_resp1||'"/>';     

else
vxml_tag1_1 :='
<FirmaResponsable certificadoResponsable="'|| trim(v_responable1) ||'"
noCertificadoResponsable="'|| trim(vno_respon1) ||'"
sello2="'||trim('x')||'"
abrTitulo="'||trim(v_titulo1)||'" cargo="'||v_cargo1||'" idCargo="'||v_id_cargo1||'" curp="'||v_curp_resp1||'" segundoApellido="'||v_apellido2_resp1||'" primerApellido="'||v_apellido1_resp1||'" nombre="'||v_nombre_resp1||'"/>';              
end if;
              
 vxml_tag1_1 := vxml_tag1_1 || '
</FirmaResponsables>';



vxml_fin := '
</TituloElectronico>';
vxml_total := vxml_inicio || vxml_respon || vxml_tag1 ||vxml_tag1_1|| vxml_tag_2 || vxml_tag_3|| vxml_tag_4||vxml_tag_5||vxml_tag_6 || vxml_fin;

begin
vconta := 0;
update SZTTIDI
   SET   SZTTIDI_CHAIN_DAT = trim(salida_dat)
         ,SZTTIDI_CHAIN_DAT2 = trim(Salida_dat1)
         , SZTTIDI_CHAIN_XML = vxml_total
        -- , SZTTIDI_ACTIVITY_DATE = sysdate
          ,SZTTIDI_FOLIO_CONTROL = v_folio_ctrl
          , SZTTIDI_SELLO  = trim('x')
          , SZTTIDI_SELLO2  = trim('x')
          , SZTTIDI_DET_TITULO   =  v_responable
          ,SZTTIDI_ID            =  matricula --F_GetSpridenID(ppidm);
          ,SZTTIDI_XML_IND        = 1
          ,SZTTIDI_IDRESPONSABLE = p_representate 
          ,SZTTIDI_VAL_FIRMA      =  1  --  nace como 1 por que ya solo lleva una sola firma
where 1=1 
AND  SZTTIDI_PIDM_TITULO  = ppidm
and  SZTTIDI_PROGRAM       = pprograma
AND  SZTTIDI_MODO         = PMODO;
    vconta := sql%rowcount;
--dbms_output.put_line('ACTUALIZA REGS>>9 '||vconta  );
 --INSERT INTO TWPASOW(VALOR1,VALOR2,VALOR3,VALOR4, VALOR5) VALUES('SII ACTUALIZA SZTTIDI_XX:  ',vconta,ppidm,pprograma, SYSDATE  ) ; COMMIT;
COMMIT;
exception when others then
vconta  := 0;
end;


----dbms_output.put_line('paso LOOOP 999****   ' || ppidm || '--' || pprograma );

end loop;


exception when others then 
dbms_output.put_line('error gral de tidi ****   ' || ppidm || '--' || pprograma||'-'|| sqlerrm );
--raise_application_error (-20002,'Error general del proceso  '||sqlerrm);      
end P_inicio;

function  f_cuenta_firmas return number 
   IS
  -- vconta  number:=0;
   
   
   begin
    
   ---------para saber si hay certificados para firmar
      
       select count(*)
       into vconta
          from SZTTIDI zt
            where SZTTIDI_VAL_FIRMA !=2 -- ya fue revisado esta listo para encriptar 
           -- and ZT.SZTTIDI_XML_IND = 1 --ya fue revisado elxml
            ;
       return (vconta); 
   exception when others then
     vconta := 0;
     --return (vconta);         
            
  END f_cuenta_firmas;
  
 function  f_sel_titulos return  BANINST1.PKG_TITULO_DIG.firmas_type
   IS
   vconta  number:=0;
    c_id_firmas BANINST1.PKG_TITULO_DIG.firmas_type;
     vl_error    varchar2(500);
   ---------para saber si hay certificados para firmar
      
 begin
 
        open c_id_firmas for  
          select  datos.representante, datos.matricula, datos.programa, datos.fecha, datos.usuario, datos.firma, ff.SZTTIDI_CHAIN_DAT,ff.SZTTIDI_CHAIN_DAT2,
                        datos.cve_program, datos.pidm
         from (
              select DISTINCT  DC.SZTREDC_TITULO||'-'||DC.SZTREDC_NOMBRE representante, sf.SZTTIDI_ID matricula, 
                TT.SZTDTEC_PROGRAMA_COMP programa 
                , sf.SZTTIDI_ACTIVITY_DATE fecha, sf.SZTTIDI_USER  usuario, sf.SZTTIDI_VAL_FIRMA firma
                         , SF.SZTTIDI_PROGRAM cve_program, 
                         SF.SZTTIDI_PIDM_TITULO pidm
                    from SZTTIDI sf, SZTREDC dc, sztdtec tt
                where 1=1
                    and  sf.SZTTIDI_IDRESPONSABLE = dc.SZTREDC_IDCARGO
                    and  sf.SZTTIDI_VAL_FIRMA != 2 -- ya fue revisado esta listo para encriptar 
                    and  sf.SZTTIDI_XML_IND   != 2 --ya fue revisado elxml
                    and  SF.SZTTIDI_PROGRAM  = TT.SZTDTEC_PROGRAM
                     and  DC.SZTREDC_ESTATUS = 1
                    and  sf.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and sf.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and sf.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  )
                     
                ) datos, SZTTIDI ff
                      where 1=1
                            and datos.matricula = ff.SZTTIDI_ID
                            and datos.cve_program   = ff.SZTTIDI_PROGRAM
                    and  ff.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and ff.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and ff.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  )
              order by firma desc,  ff.SZTTIDI_ACTIVITY_DATE desc;

       return c_id_firmas;
    Exception
            When others  then 
               ---vl_error := 'PKG_SERV_SIU_ERROR.c_id_firmas: ' || sqlerrm;
           return c_id_firmas;
        
  END f_sel_titulos;
  
  function f_update_sello (ppidm number, pprog varchar2, psello clob  ) return varchar2
   IS
   vconta  number:=0;
    c_id_firmas BANINST1.PKG_TITULO_DIG.firmas_type;
    VXML      CLOB;
   VDATOS    CLOB;
   VREGESA   VARCHAR2(10);
   VMATRICULA  VARCHAR2(15);
   vl_error    varchar2(500);
   
   ---------para saber hacer la firma de los representantes
      
 begin
 
         UPDATE SZTTIDI z
            SET  --z.SZTTIDI_ACTIVITY_DATE = SYSDATE,
                 z.SZTTIDI_SELLO       = TRIM (psello),
                 z.SZTTIDI_XML_IND     = 1,
                 z.SZTTIDI_VAL_FIRMA   = 1
          WHERE 1=1    
                and z.SZTTIDI_PIDM_TITULO = ppidm
                AND z.SZTTIDI_PROGRAM = pprog
                and z.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  );
           
          COMMIT;
            
            -----------------------AQUI HAY QUE METER LA GENERACION DE LOS ARCHIVOS --- SE SUPONE QUE SI LLEGO AQUI
        ---------------- ES POR QUE YA FUE REVISADO Y YA LO FIRMO EL REPRESENTANTE--------------- 
         VREGESA :=   BANINST1.PKG_TITULO_DIG.f_complete_xml1 (ppidm , pprog ) ;
      IF VREGESA = 'EXITO' THEN    
         begin
            select Z.SZTTIDI_chain_xml XMLS,
                   Z.SZTTIDI_CHAIN_DAT DATOS,
                   Z.SZTTIDI_ID IDS
               INTO VXML, VDATOS, VMATRICULA
              FROM  SZTTIDI z
                WHERE  Z.SZTTIDI_PIDM_TITULO    = ppidm
                 AND   Z.SZTTIDI_PROGRAM = pprog
                 and   z.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  );
         
         exception when others then
           VXML    := NULL;
           VDATOS  := NULL;
         end;  
         DBMS_LOCK.SLEEP (2);
          -- BANINST1.PKG_TITULO_DIG.p_genera_dgair (TRIM (VDATOS), VMATRICULA,pprog);
          -- DBMS_LOCK.SLEEP (5);   ESTE SOLO SE HACE EN LA SEGUNDA FORMA---
          -- BANINST1.PKG_TITULO_DIG.p_archivo_xml (TRIM(VXML), VMATRICULA, pprog);
        
         
         return('EXITO' );
      END IF;
       
         
    Exception
            When others  then 
               vl_error := 'PKG_SERV_SIU_ERROR.c_id_firmas: ' || sqlerrm;
           return ('error'||sqlerrm);
          -- insert into twpasow ( valor1, valor6) values('error firma1', substr(vl_error,1,499)); commit;
        
  END f_update_sello;
 
 
  function f_update_sello2 (ppidm number, pprog varchar2, psello clob  ) return varchar2
   IS
   vconta  number:=0;
    c_id_firmas BANINST1.PKG_TITULO_DIG.firmas_type;
     VXML      CLOB;
   VDATOS    CLOB;
   VREGESA   VARCHAR2(10);
   VMATRICULA  VARCHAR2(15);
    vl_error    varchar2(500);
   ---------para saber si hay certificados para firmar
      
 begin
 
         UPDATE SZTTIDI z
            SET  --z.SZTTIDI_ACTIVITY_DATE = SYSDATE,
                 z.SZTTIDI_SELLO2       = TRIM (psello),
                 z.SZTTIDI_XML_IND     = 2,
                 z.SZTTIDI_VAL_FIRMA   = 2
           WHERE 1=1    
               and z.SZTTIDI_PIDM_TITULO = ppidm
               AND z.SZTTIDI_PROGRAM = pprog
               and z.SZTTIDI_MODO  =  (select NVL(MAX(t2.SZTTIDI_MODO), 0) 
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  );
          vconta := sql%rowcount;
       COMMIT;
            
            -----------------------AQUI HAY QUE METER LA GENERACION DE LOS ARCHIVOS --- SE SUPONE QUE SI LLEGO AQUI
        ---------------- ES POR QUE YA FUE REVISADO Y YA LO FIRMO EL REPRESENTANTE--------------- 
         VREGESA :=   BANINST1.PKG_TITULO_DIG.f_complete_xml2 (ppidm , pprog ) ;
         
      IF VREGESA = 'EXITO' THEN    
         begin
            select Z.SZTTIDI_chain_xml XMLS,
                   Z.SZTTIDI_CHAIN_DAT2 DATOS,
                   Z.SZTTIDI_ID IDS
                INTO VXML, VDATOS, VMATRICULA
              FROM  SZTTIDI z
                WHERE 1=1  
                 and   Z.SZTTIDI_PIDM_TITULO    = ppidm
                 AND   Z.SZTTIDI_PROGRAM = pprog
                 and   z.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  );
         
         exception when others then
           VXML    := NULL;
           VDATOS  := NULL;
         end;  
         
         DBMS_LOCK.SLEEP (2);
          -- BANINST1.PKG_TITULO_DIG.p_genera_dgair2 (TRIM (VDATOS), VMATRICULA,pprog);
           DBMS_LOCK.SLEEP (2);
          -- BANINST1.PKG_TITULO_DIG.p_archivo_xml (TRIM(VXML), VMATRICULA, pprog);
        
      return('EXITO' );
      
        END IF;    
         
    Exception
            When others  then 
               vl_error := 'PKG_SERV_SIU_ERROR.c_id_firmas: ' || sqlerrm;
           return ('error'||sqlerrm);
          -- insert into twpasow ( valor1, valor6) values('error firma1', substr(vl_error,1,499)); commit;
        
  END f_update_sello2;
   
FUNCTION  P_XML_DATOS  ( ppidm number, pprogrms  varchar2  )  RETURN BANINST1.PKG_TITULO_DIG.xml_type
 is
-- esta funciÛn es para ver un XML y cadenas en SIU x matricula es la primer pantalla edicion titulos
 vconta  number:=0;
    C_XML_DATOS BANINST1.PKG_TITULO_DIG.xml_type;
    
begin
          open C_XML_DATOS for  
                            select ti.SZTTIDI_ID, ti.SZTTIDI_PROGRAM, ti.SZTTIDI_CHAIN_DAT, ti.SZTTIDI_CHAIN_XML, ti.SZTTIDI_CHAIN_DAT2
                            from SZTTIDI ti
                            where 1=1
                            and ti.SZTTIDI_PIDM_TITULO = nvl(ppidm, ti.SZTTIDI_PIDM_TITULO)
                            and ti.SZTTIDI_PROGRAM     = nvl( pprogrms, ti.SZTTIDI_PROGRAM)
                            and Ti.SZTTIDI_MODO     =  (select MAX(t2.SZTTIDI_MODO)  
                                                         from szttidi t2
                            where 1=1
                                                            and ti.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                            and ti.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  )
                            order by 1;


RETURN C_XML_DATOS;

end p_xml_datos;

FUNCTION  P_XML_UPDATE  ( ppidm number, pprogrms  varchar2 , PDGAIR CLOB, PXML CLOB, PDGAIR2 CLOB, puser varchar2 )  RETURN VARCHAR2
 is

 vconta  number:=0;
 --   C_XML_DATOS BANINST1.PKG_CERTIFICADO_DIG_2_0.xml_type;
 -------se agregael parametro de user para saber quien lo esta modificando--- glovicx 09/10/209
    
begin
         
            UPDATE SZTTIDI z
            SET z.SZTTIDI_CHAIN_DAT   = PDGAIR,
                z.SZTTIDI_CHAIN_DAT2  = PDGAIR2,
                z.SZTTIDI_CHAIN_XML   = PXML,
                z.SZTTIDI_XML_IND     = 1,
                z.SZTTIDI_VAL_FIRMA   = 1    --  se actualiza a 1  por que ya solo lleva una sola firma
               -- z.SZTTIDI_ACTIVITY_DATE = SYSDATE,
               -- z.SZTTIDI_USER          = puser
             WHERE 1=1
                 and z.SZTTIDI_PIDM_TITULO = ppidm --nvl(ppidm, SZTTIDI_PIDM_TITULO)
                 and z.SZTTIDI_PROGRAM  = pprogrms
                 and z.SZTTIDI_MODO  =  (select NVL(MAX(t2.SZTTIDI_MODO),0)  
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  );

                               
COMMIT;

RETURN 'EXITO';
EXCEPTION WHEN OTHERS THEN 
RETURN 'EXITO'|| SQLERRM;

end P_XML_UPDATE;  
 
function f_complete_xml1 (ppidm number, pprogram varchar2  ) return varchar2 is

 vsello1       CLOB;

begin

  SELECT  REPLACE (z.SZTTIDI_chain_xml, 'sello1="x"', 'sello="'||trim(Z.SZTTIDI_sello)||'"'  )  modifica_xml
into  vsello1
FROM SZTTIDI z
    WHERE 1=1 
    and  Z.SZTTIDI_PIDM_TITULO = ppidm
    and  Z.SZTTIDI_PROGRAM     = pprogram 
    and  z.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                                   from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  );

--insert into twpasow(valor1, valor6) values('XML_titulo1',substr(vsello1,1,499));
  Begin
update SZTTIDI Z
     set Z.SZTTIDI_chain_xml = vsello1
         --Z.SZTTIDI_ACTIVITY_DATE = sysdate
    WHERE 1=1 
    and  Z.SZTTIDI_PIDM_TITULO = ppidm
    and  Z.SZTTIDI_PROGRAM  = pprogram
    and  z.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  ) ;
commit;
  exception when others then
     dbms_output.put_line('error en update tidi v1.1::. '|| sqlerrm);
  end;  
RETURN ('EXITO');

EXCEPTION WHEN OTHERS THEN
RETURN('ERROR_XML');

end f_complete_xml1;


function f_complete_xml2 (ppidm number, pprogram varchar2  ) return varchar2 is

 vsello2       CLOB;

begin

SELECT  REPLACE (SZTTIDI_chain_xml, 'sello2="x"', 'sello="'||trim(Z.SZTTIDI_sello2)||'"'  )  modifica_xml
into  vsello2
FROM SZTTIDI z
WHERE 1=1 
and  Z.SZTTIDI_PIDM_TITULO = ppidm
and  Z.SZTTIDI_PROGRAM      = pprogram 
and  z.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  );

--insert into twpasow(valor1, valor6) values('XML_titulo2',substr(vsello1,1,499));
begin
update SZTTIDI Z
 set Z.SZTTIDI_chain_xml = vsello2
     --Z.SZTTIDI_ACTIVITY_DATE = sysdate
WHERE 1=1 
and  Z.SZTTIDI_PIDM_TITULO = ppidm
and  Z.SZTTIDI_PROGRAM  = pprogram
and  z.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  ) ;

commit;

exception when others then
DBMS_OUTPUT.PUT_LINE('error en update tidi v2.2:  '|| sqlerrm);
end;


RETURN ('EXITO');

EXCEPTION WHEN OTHERS THEN
RETURN('ERROR_XML');

end f_complete_xml2;
function f_VALIDA_sello2 (ppidm number, pprog varchar2  ) return varchar2
   IS
   vconta  number:=0;
    VVARCLOB    CLOB:='x';
   VREGESA   VARCHAR2(10);
   VMATRICULA  VARCHAR2(15);
   
   ---------para saber si hay certificados para firmar
      
 begin
  
            select SZTTIDI_VAL_FIRMA ---dbms_lob.substr( SZTTIDI_SELLO2, 1, 1 )
                INTO vconta
              FROM  SZTTIDI z
                WHERE 1=1  
                 and  Z.SZTTIDI_PIDM_TITULO    = ppidm -- fget_pidm('010000158')
                 AND   Z.SZTTIDI_PROGRAM        = pprog --'UTLLICFFED'
                 and   z.SZTTIDI_VAL_FIRMA  = 1  
                 and   z.SZTTIDI_MODO  =  (select MAX(t2.SZTTIDI_MODO)  
                                               from szttidi t2
                                                 where 1=1
                                                   and z.SZTTIDI_PIDM_TITULO = t2.SZTTIDI_PIDM_TITULO
                                                   and z.SZTTIDI_PROGRAM    = t2.SZTTIDI_PROGRAM  ) ----ya lo firmo el director
               ;
            vconta := sql%rowcount;
      
         IF VCONTA = 1 THEN
           
           -- insert into twpasow (valor1, valor2, valor3) values('titulacion',vconta, ppidm);
         --commit;
         RETURN('EXITO');
           ELSE
          --  insert into twpasow (valor1, valor2, valor3) values('titulacion2',vconta, ppidm);
         --commit; 
           RETURN('ERROR');
         END IF;
        
  Exception
            When others  then 
               ---vl_error := 'PKG_SERV_SIU_ERROR.c_id_firmas: ' || sqlerrm;
          
           --  insert into twpasow (valor1, valor2, valor3) values('titulacion3',vconta, ppidm);
         commit;
         return ('error'||sqlerrm);
  END f_VALIDA_sello2;
  

FUNCTION F_PROC_TITULO (PPIDM NUMBER, PPROGRAMA VARCHAR2 )  RETURN PKG_TITULO_DIG.Ftitulo_type IS

Fproc_out    SYS_REFCURSOR;
VSALIDA      VARCHAR2(300);
Vnivel       varchar2(4);
vsaldo       number:= 0;
vcertificado varchar2 (6);
vdoctos      number:= 0;
vcurd        varchar2(4):= 'CURD';
vcolf        number:= 0;
vseqno       number:= 0;
vcamp        varchar2(4);
vcodtl       varchar2(4);
vcert_elab   varchar2(1):= 'N';
VCERT_AUT    varchar2(1):= 'N';
VSSO         varchar2(1):= 'N';
VTITULO_ELB  varchar2(1):= 'N';
VTINV        varchar2(1):= 'N';
VALTITU      varchar2(6);
VVTG         varchar2(1):= 'N';
VTIT_AUTEN   varchar2(1):= 'N';
VCETD        varchar2(1):= 'N';
VACUD        varchar2(1):= 'N';
vdoc_entregados  varchar2(1):= 'N';
VAPOS       NUMBER;
VENIN       varchar2(1):= 'N';
vapostille  varchar2(1):= 'N';
VDOC_ENVIADOS varchar2(1):= 'N'; 
vdoctosx  varchar2(1):= 'N';
vsaldox   varchar2(15):= 'N';
vcolfx    varchar2(1):= 'N';
vtipo_ingreso varchar2(4);
Vtiau         varchar2(1):= 'N';
Vdoen         varchar2(1):= 'N';  
vestatus      varchar2(15);
vporcentaje   number:=0;
VFECH_EGRE    varchar2(20);
vfech_pago    varchar2(20);
vfech_colf    varchar2(20);
vcountf       number:= 0;
vtran_colf    number:= 0;
vavance       varchar2(20);
VSP           NUMBER:=0;
vfecha_ss     date;
VAPOSTI       varchar2(1):= 'N';

BEGIN

/*
1ER proceso de titulaciÛn este proceso sirve para mostrar en SIU por medio de etiquetas en que etapata va su proceso de
  titulaciÛn. x alumno.
-documentos
-adeudo
-colf
-- buscamos los documentos 
-CURP(CURD) DICTAMINADO, 
-CERTIFICADO DE BACHILLERATO (CTBD),
 LICENCIATURA(CTLD), 
 MAESTRÕA(CMTD) con estatus de Dictaminado
*/

---iniciamos las variables
vdoctosx := 'N';
vsaldox  := 'N';
vcolfx   := 'N';
vcert_elab := 'N';
VCERT_AUT := 'N';
VSSO  := 'N';
VTITULO_ELB := 'N';
VTIT_AUTEN  := 'N';
vdoc_entregados := 'N';
vapostille  := 'N';
vdoc_enviados  := 'N';
Vtiau := 'N';
vporcentaje := 0;
vestatus   :='';
vfech_pago  :='';
vfech_colf  :='';
vcountf     := 0;
vtran_colf  := 0;
vavance     := '0%';
VSP         := 0;
--vfecha_ss   :='';



--busacmos el nivel----
   begin
      select distinct s.SGBSTDN_LEVL_CODE, s.SGBSTDN_CAMP_CODE, s.SGBSTDN_ADMT_CODE, 
                   --decode(s.SGBSTDN_STST_CODE,'MA','Matriculado', 'Egresado') estatus, 
                   upper(s.SGBSTDN_STST_CODE) estatus,
                    H.SZTHITA_AVANCE avances,
                   ( select pkg_utilerias.f_fecha_egreso(ppidm,H.SZTHITA_STUDY ) from dual ),
                      H.SZTHITA_STUDY                     
       INTO  vnivel, vcamp, vtipo_ingreso, vestatus, vporcentaje, VFECH_EGRE, VSP
        from  sgbstdn s, szthita h
          where 1=1
            and s.SGBSTDN_PIDM      = ppidm
            and s.SGBSTDN_STST_CODE in ( 'EG', 'MA')
            and s.SGBSTDN_PROGRAM_1  = PPROGRAMA 
            and s.SGBSTDN_PIDM      = H.SZTHITA_PIDM
            and s.SGBSTDN_CAMP_CODE = H.SZTHITA_CAMP
            and S.SGBSTDN_PROGRAM_1 = H.SZTHITA_PROG
            and s.SGBSTDN_TERM_CODE_EFF = (select max(s2.SGBSTDN_TERM_CODE_EFF)
                                             from  sgbstdn s2
                                               where 1=1
                                                 and s.SGBSTDN_PIDM  = s2.SGBSTDN_PIDM 
                                                 and  S.SGBSTDN_PROGRAM_1 =  S2.SGBSTDN_PROGRAM_1     );
            
     exception when others then
      vsalida := 'error en nivel: '|| sqlerrm;   
      vnivel  := '';
      vcamp   := '';
      vtipo_ingreso  := ''; 
      vestatus   := '';
      vporcentaje := '';
      VFECH_EGRE  := 'NA';
      VSP         := 0;
      
     
     --DBMS_OUTPUT.PUT_LINE('eRROR:: '|| vsalida);
     end;
     
    --DBMS_OUTPUT.PUT_LINE('despues de estatus new:: '||vnivel||'.'|| vcamp||'.'|| vtipo_ingreso||'-'||vestatus||'-'||vporcentaje||'-'||VFECH_EGRE   );
     IF  vestatus = 'EG'  then
      null;
      else
       VFECH_EGRE := '';
      end if;  
      ----- la fecha de egeresado solo es para estatus EG  si trae otro estatus entonces va vacia regla de betzy 13.06.24
      
   
   -- se manda el % de avance tal como lo pide betzy regla 11 jun 024 glovicx 
       vavance := vporcentaje;
   
   ---- nueva regla si el alumno es status MA y su avance es 90% entonces dejo que vea las etiquetas de documetos,adeudo y colf glovicx 26.04.2024
   
   IF (vestatus = 'MA'  and  vporcentaje >= 90)  OR vestatus = 'EG' then
   
                
        ----- buscamos si se compro y se pago el accesorio COLF en SIU.  se hace la distincion del programa por que puede tener mas de 1 prog diferente 
            begin
               
              select distinct NVL((max(V.SVRSVPR_PROTOCOL_SEQ_NO  )),0), NVL(v.SVRSVPR_ACCD_TRAN_NUMBER,0)
                INTO vseqno , vtran_colf
                 from svrsvpr v,SVRSVAD VA
                  where 1=1
                    and V.SVRSVPR_PROTOCOL_SEQ_NO = VA.SVRSVAD_PROTOCOL_SEQ_NO
                    ANd V.SVRSVPR_SRVC_CODE  = 'COLF'
                    and v.SVRSVPR_SRVS_CODE NOT IN ('CA','AC', 'AN')
                    and v.SVRSVPR_ACCD_TRAN_NUMBER is not null
                    and v.SVRSVPR_PIDM =  ppidm 
                    and va.SVRSVAD_ADDL_DATA_SEQ = 1  --- es elpregunta del  programa
                    and va. SVRSVAD_ADDL_DATA_CDE  = pprograma 
                    group by v.SVRSVPR_ACCD_TRAN_NUMBER
                    ;


               
            exception when others then
              vsalida := 'error en COLF: '|| sqlerrm;
              vseqno  := 0; 
              vtran_colf  := 0 ;
              DBMS_OUTPUT.PUT_LINE('eRROR NOHAY COMPRA de COLF:: '|| vsalida||'-'||vseqno);
              
            end;
        
           
      IF vseqno >  0 then  --- quire decir que si se compro el accesorio y buscamos la fecha de pago
           --  DBMS_OUTPUT.PUT_LINE('DESPUES  COLF AUTO SERV '|| vseqno||'-'|| vcolf );
             
            BEGIN
                   
               select distinct Sum(T2.TBRACCD_BALANCE ),  MAX(trunc(t2.TBRACCD_ENTRY_DATE))
                INTO vcolf , vfech_colf
                 from TBRACCD t2
                  where 1=1
                    and  t2.TBRACCD_PIDM = ppidm
                    and  T2.TBRACCD_TRAN_NUMBER_PAID  = vtran_colf
                    order by 2 desc;

                  
            exception when others then
              vsalida := 'error en COLFxx  : '|| sqlerrm;
              vcolf   := 1; -- mayor de cero No esta pagado o no existe ningun reg asociado al accesorio
              vfech_colf := '';
            end;
         
         vcolfx     :=  'Y';-- se AGREGA LA ETIQUETA DE COLF
        -- DBMS_OUTPUT.PUT_LINE('DESPUES  COLF x AUTOSERV. '||  vfech_colf||'-'|| vcolfx );
      else   --si no entonces buscamos si se compro x paquete la COLF
      
          BEGIN
            select distinct NVL(Sum(T2.TBRACCD_BALANCE ),1), MAX(trunc(t2.TBRACCD_ENTRY_DATE))
             INTO vcolf , vfech_colf
               from TBRACCD t2
                where 1=1
                and  t2.TBRACCD_PIDM = PPIDM
                and t2.TBRACCD_STSP_KEY_SEQUENCE = VSP  --ajuste glovicx 16.08.2024
                --and  T2.TBRACCD_DETAIL_CODE = substr(F_GetSpridenID(ppidm),1,2)||'OT'
                and  T2.TBRACCD_DETAIL_CODE in ( SELECT DISTINCT ZSTPARA_PARAM_VALOR -- se cambio x este parametrizador por que hay muchos codigos detalles glovicx 26.07.24
                                                   FROM zstpara
                                                      WHERE     1 = 1
                                                      AND ZSTPARA_MAPA_ID = 'CODIGO_TITULA')

                order by 2 desc;
          exception when others then
              vsalida := 'error en COLFxx  : '|| sqlerrm;
              vcolf   := 1; -- mayor de cero No esta pagado o no existe ningun reg asociado al accesorio
              vfech_colf := '';
          
          END;      
          
          
        --  DBMS_OUTPUT.PUT_LINE('DESPUES  COLF x PAQUETE antes'||  vfech_colf||'-'|| vcolfx );
               IF vcolf > 0  then
                 vcolfx     :=  'N';-- se AGREGA LA ETIQUETA DE COLF
               else
                vcolfx     :=  'Y';-- se AGREGA LA ETIQUETA DE COLF
               end if;
               
         
         --    DBMS_OUTPUT.PUT_LINE('DESPUES  COLF x PAQUETE  despues '||  vfech_colf||'-'|| vcolfx );
      end IF;
            
        
      
          ---- busca adeudo----
           begin
               vsaldo:= NVL(BANINST1.PKG_TITULO_DIG.F_BALANCE_ADEUDO(PPIDM, VSP, VNIVEL),0);
           
              
            exception when others then
              vsalida := 'error en adeudo: '|| sqlerrm;
            end;
         
                --DBMS_OUTPUT.PUT_LINE('saldooo :: '|| vsaldo);
        
          
           IF vsaldo = 0 THEN
             vsaldox    :=  'Y';
             ------ si saldo es cero entonces buscamos la fecha del ultimo pago y la mandamos al cursos
              begin
              
                select distinct MAX(TBRACCD_EFFECTIVE_DATE) fecha_pago
                     INTO vfech_pago
                       from tbraccd a
                      join TZTNCD b on b.TZTNCD_CODE  = a.TBRACCD_DETAIL_CODE and b.TZTNCD_CONCEPTO in ('Poliza', 'Deposito', 'Nota Distribucion')
                      where 1=1
                       and A.TBRACCD_PIDM = ppidm;
              
               exception when others then
               vfech_pago := '';
               
              end;
             
           ELSE  --esta regla se hizo para mostrar el saldo del adeudo en la etiqueta 
                 vsaldox    :=  'N'||' $ '|| vsaldo ;
                 vfech_pago := '';
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE SALDO, '|| vsaldox );
                    
           end if;  
          
          
                  
              -------AQUI MANDAMOS A TRAER LA ETIQUETA DOCU
              
             vdoctosx:=  PKG_TITULO_DIG.F_REGLA_DOCU (PPIDM, VCAMP, VNIVEL , vtipo_ingreso , 'DOCU');
              
              -- DBMS_OUTPUT.PUT_LINE('SALIENDO DE LA FUNCION--DOCU; '|| vdoctosx || '  fecha maxima: '||vfech_docu );
               
   ELSE
    --------  AQUI ENTRAN TODOS LOS QUE SON MA Y MENOS DE 90%
   -- DBMS_OUTPUT.PUT_LINE('SALIENDO DE LA FUNCION--DOCU-NO CUMPLE % y MA'|| vdoctosx  );
    vsaldox  :=  'N';
    vcolfx   :=  'N';
    vdoctosx :=  'N';
    
    END IF;    
    
    
     IF  vdoctosx = 'Y' and vsaldox = 'Y' and vcolfx  = 'Y' then
         --si cumple con los 3 entonces crea etiqueta
       vcert_elab := 'Y';  --- etiqueta certificado elaborado
       
     end if;
      
      -------AQUI MANDAMOS A TRAER LA ETIQUETA CERA
     
       VCETD:=  PKG_TITULO_DIG.F_REGLA_DOCU (PPIDM, VCAMP, VNIVEL , vtipo_ingreso , 'CERA');
      
       --DBMS_OUTPUT.PUT_LINE('SALIENDO DE LA FUNCION CERA '|| VCETD|| 'fcerty'||vfecha_certy   );
            
    IF VCETD = 'Y' and vcert_elab = 'Y'  THEN 
       VCERT_AUT := 'Y'; --- ETIQUETA CERTIFICADO AUTENTIFICADO
    END if;
    
   --dbms_output.put_line('salida 2xx '||  VCETD||'-'||Vnivel||'-'||vcamp||'-'||vcert_elab  );
--- OBTENEMOS EL SS PARA lIC Y UTL
  -- IF  Vnivel = 'LI' AND vcamp = 'UTL' AND VCERT_AUT = 'Y' then
    IF  Vnivel = 'LI' AND vcamp = 'UTL'  THEN  -- SE CAMBIA LA REGLA DEL SS NUEVA REGLA GLOVICX 30.04.2024
   --dbms_output.put_line('salida 2ZZ '|| VCERT_AUT );
   
       BEGIN
            select distinct 'Y', SHRNCRS_NCST_DATE
              INTO VSSO, vfecha_ss
                from SHRNCRS R
                where 1=1
                AND R.SHRNCRS_PIDM = PPIDM
                AND R.SHRNCRS_NCST_CODE = 'AP'
                AND R.SHRNCRS_NCRQ_CODE = 'SS';
       exception when others then
       VSSO := 'N';
       vfecha_ss := '';
         --dbms_output.put_line('ERROR EN SERVICIO SOCIAL'|| VSSO );
       END;
       --dbms_output.put_line('fecha de EN SERVICIO SOCIAL'|| vfecha_ss );
       
       IF VSSO = 'Y'  and VCERT_AUT = 'Y' THEN  -- SI CUMPLE CON SERVICIO SOCIAL ENTONCES CREA ETIQETA
          VTITULO_ELB  := 'Y';   ---- ETIQUETA ELABORACI”N DE TITULO
          --dbms_output.put_line(' TITULO ELABORACION  salida 3 '||  VTITULO_ELB );
       END IF;
       
       --dbms_output.put_line('salida 3 '||  sqlerrm );
       
   ELSIF  vcamp != 'UTL' AND VCERT_AUT = 'Y'  THEN
       --- PARA TODOS LOS CAMPUS QUE NO SON UTEL NO LLEVAN SSO  
             VTITULO_ELB  := 'Y';   ---- ETIQUETA ELABORACI”N DE TITULO
   
   ELSIF Vnivel IN ('MA','DO') AND vcamp = 'UTL' AND VCERT_AUT = 'Y'  THEN
            --para maestrias campus = utl
            VTITULO_ELB  := 'Y';   ---- ETIQUETA ELABORACI”N DE TITULO
    
   END IF;
   --dbms_output.put_line('salida 2-A '||  VCETD||'-'||Vnivel||'-'||vcamp||'-'||VCERT_AUT  );

  IF  Vnivel != 'LI' AND vcamp != 'UTL' AND VCERT_AUT = 'Y'  THEN -- REGLA PARA MAESTRIAS Y DOCTORADOS CAMPUS INTERNACIONALES 
          
           begin   ---- buscamos el Trabajo de InvestigaciÛn VALIDADO / 
              select 'Y'
                INTO VTINV
                from SARCHKL sk
                where 1=1
                and sk.SARCHKL_ADMR_CODE in ('TINV')
                and  sk.SARCHKL_CKST_CODE  like ('%VALIDADO%')
                and sk.SARCHKL_PIDM = ppidm
                and sk.SARCHKL_APPL_NO = (Select max (k2.SARCHKL_APPL_NO) 
                                            from SARCHKL k2
                                              where 1=1
                                                and sk.SARCHKL_PIDM = k2.SARCHKL_PIDM
                                                and sk.SARCHKL_ADMR_CODE = k2.SARCHKL_ADMR_CODE
                                            );
              
            exception when others then
              VTINV  := 'N';
              vsalida  := 'error en trabajo de investigacion: '|| sqlerrm;
              --dbms_output.put_line('ERROR salida 4a '||  vsalida );
            end;
            --dbms_output.put_line('salida 4A TRABAJO INVESTIGACION   '||  VTINV );
            
            
         IF VTINV = 'Y'   THEN
             VTITULO_ELB  := 'Y';   ---- ETIQUETA ELABORACI”N DE TITULO
            --dbms_output.put_line('salida ETIQUETA ELABORACI”N DE TITULO   '||  VTITULO_ELB );
         END IF;
         
         

  END IF;
  
     
   
     ---- buscamos la validacion del tiutlo o grado(TIUD,GRMD )   
      -------AQUI MANDAMOS A TRAER LA ETIQUETA TIAU
     
       VVTG:=  PKG_TITULO_DIG.F_REGLA_DOCU (PPIDM, VCAMP, VNIVEL , vtipo_ingreso , 'TIAU');
      
      -- DBMS_OUTPUT.PUT_LINE('SALIENDO DE LA FUNCION TIAU '|| VVTG ||'-fechaitu '||vfecha_titu  );
     
        
       --IF  VVTG = 'Y'  and VTITULO_ELB = 'Y' THEN
       IF  VVTG = 'Y'   THEN
               
           VTIT_AUTEN := 'Y';      ----  ETIQUETA  ìTITULO AUTENTICADOî
           
           ----- SI TIENE ESTA ETIQUETA ENTONCES NUEVA REGLA DICE QUE HAY QUE PONER COMO "YES", TODAS LAS DEMAS ETIQUETAS PASADAS
          
           vdoctosx   := 'Y';  
           vsaldox    := 'Y'; 
           vcolfx     := 'Y'; 
           vcert_elab := 'Y'; 
           VCERT_AUT  := 'Y';
           VSSO       := 'Y'; 
           VTITULO_ELB := 'Y'; 
            
                
       END IF;
       
       
       
       
       
       IF  vcamp = 'UTL' AND VTIT_AUTEN = 'Y' then
         /*
             begin   ---- buscamos el TITULO O GRADO VALIDADO / 
              select 'Y'
                INTO VACUD
                from SARCHKL sk
                where 1=1
                and sk.SARCHKL_ADMR_CODE = 'ACUD'
                and sk.SARCHKL_CKST_CODE  like ('%VALIDADO%')
                and sk.SARCHKL_PIDM = ppidm;
              
            exception when others then
              VACUD  := 'N';
              vsalida  := 'error en trabajo de investigacion: '|| sqlerrm;
                dbms_output.put_line('salida 5 '||  vsalida );
            end;
            */
            -------AQUI MANDAMOS A TRAER LA ETIQUETA DOFI
     
          VACUD:=  PKG_TITULO_DIG.F_REGLA_DOCU (PPIDM, VCAMP, VNIVEL , vtipo_ingreso , 'DOFI');
      
      -- DBMS_OUTPUT.PUT_LINE('SALIENDO DE LA FUNCION DOFI '|| VACUD ||' fchetitu '||vfecha_titu );
     
            
            
            IF VACUD = 'Y'  THEN
             vdoc_entregados := 'Y'; -- documentos entregados fisicamente 
            END IF;
            
            
       ELSIF  vcamp != 'UTL' AND VTIT_AUTEN = 'Y' then
       
       --------VALIDAMOS QUE TENGAN EL APOSTILLE 
          
           BEGIN
               
            select sum(datos.sumtotal) SUMX,DECODE(sum(DATOS.CONTADOR),0,'N','Y') VALIDA  
                INTO VAPOS , VAPOSTI
              from (
                 select distinct NVL(sum(t.TBRACCD_BALANCE),0) sumtotal, COUNT(1) CONTADOR
                 from tbraccd t
                 where 1=1
                 and t.tbraccd_pidm = PPIDM
                 and  T.TBRACCD_DETAIL_CODE in (select distinct b.TBBDETC_DETAIL_CODE
                                                from TBBDETC b
                                                where 1=1
                                                and b.TBBDETC_DESC like ('%APOST%')
                                                and b.TBBDETC_TYPE_IND = 'C') 
                 and t.TBRACCD_CROSSREF_NUMBER  in (select Max (V.SVRSVPR_PROTOCOL_SEQ_NO)
                                                    from SVRSVPR  v
                                                    WHERE 1=1
                                                    ANd  V.SVRSVPR_SRVC_CODE  IN  ('APOS')
                                                    and  v.SVRSVPR_SRVS_CODE  =  ('PA')
                                                    and  v.SVRSVPR_PIDM = t.tbraccd_pidm
                                                    )
                 AND (T.TBRACCD_DOCUMENT_NUMBER != 'WCANCE'
                 OR T.TBRACCD_DOCUMENT_NUMBER IS NULL)
                  union
                  select distinct NVL(sum(t.TBRACCD_BALANCE),0) sumtotal, COUNT(1) CONTADOR
                   from tbraccd t
                 where 1=1
                 and t.tbraccd_pidm = PPIDM
                 and t.TBRACCD_CROSSREF_NUMBER is  null
                 and T.TBRACCD_DETAIL_CODE in (select distinct b.TBBDETC_DETAIL_CODE
                                                from TBBDETC b
                                                where 1=1
                                                and b.TBBDETC_DESC like ('%APOST%')
                                                and b.TBBDETC_TYPE_IND = 'C') 
                  ) datos; 
                   
                   
            exception when others then
              VAPOS  := 1;
              VAPOSTI := 'N';
              vsalida  := 'error en trabajo de investigacion: '|| sqlerrm;
               --dbms_output.put_line('salida 6 '||  vsalida );
            end;
       
             if vapos = 0 and VAPOSTI = 'Y' then 
             
             vapostille := 'Y'; --etiqueta proceso de apostillas
             end if;
               --dbms_output.put_line('salida apostille '||VAPOS  );
               
             begin   ---- buscamos el envio de documentos / 
             
                              
                select DECODE(sum(datos.sumtotal),0,'Y','N') VALIDA
                INTO VENIN
                from (
                   select distinct NVL(sum(t.TBRACCD_BALANCE),0) sumtotal
                    from tbraccd t
                    where 1=1
                    and t.tbraccd_pidm = ppidm
                    and  T.TBRACCD_DETAIL_CODE in (select distinct b.TBBDETC_DETAIL_CODE
                                                    from TBBDETC b
                                                    where 1=1
                                                    and b.TBBDETC_DESC like ('%ENVIO INTER%')
                                                    and b.TBBDETC_TYPE_IND = 'C') 
                    and t.TBRACCD_CROSSREF_NUMBER  in (select Max (V.SVRSVPR_PROTOCOL_SEQ_NO)
                                                        from SVRSVPR  v
                                                        WHERE 1=1
                                                        ANd  V.SVRSVPR_SRVC_CODE  IN  ('ENIN')
                                                        and  v.SVRSVPR_SRVS_CODE  =  ('PA')
                                                        and  v.SVRSVPR_PIDM = t.tbraccd_pidm
                                                        )
                    AND (T.TBRACCD_DOCUMENT_NUMBER != 'WCANCE'
                    OR T.TBRACCD_DOCUMENT_NUMBER IS NULL)
                union
                 select distinct NVL(sum(t.TBRACCD_BALANCE),0) sumtotal
                       from tbraccd t
                    where 1=1
                    and t.tbraccd_pidm = ppidm
                    and t.TBRACCD_CROSSREF_NUMBER is  null
                    and T.TBRACCD_DETAIL_CODE in (select distinct b.TBBDETC_DETAIL_CODE
                                                    from TBBDETC b
                                                    where 1=1
                                                    and b.TBBDETC_DESC like ('%ENVIO INTER%')
                                                    and b.TBBDETC_TYPE_IND = 'C') 
                 ) datos ;


              
            exception when others then
              VENIN  := 'N';
              vsalida  := 'error en envio internacional: '|| sqlerrm;
               --dbms_output.put_line('salida 7 '||  vsalida );
            end;
       ----- mandamos el DOEN--  
         -------AQUI MANDAMOS A TRAER LA ETIQUETA DOEN
     
         Vdoen:=  PKG_TITULO_DIG.F_REGLA_DOCU (PPIDM, VCAMP, VNIVEL , vtipo_ingreso , 'DOEN');
      
       --DBMS_OUTPUT.PUT_LINE('SALIENDO DE LA FUNCION DOEN y envio internacional '|| Vdoen ||'-'||VENIN );
     
           
       
       
        
         IF VENIN = 'Y' and Vdoen = 'Y' then
             vdoc_enviados := 'Y' ; --etiquta documentos enviados
         end if;
             --DBMS_OUTPUT.PUT_LINE('ETIQUETA DE DOCUMENTOS ENVIADOS:  ' ||vdoc_enviados );         
       
       END IF;
       
  
  
  begin 
   select decode(vestatus,'MA','Matriculado', 'Egresado') 
    into vestatus
     from dual;
   exception when others then
   null;
   end;  
  
 -- dbms_output.put_line('fecha antes de salida cursor '|| VFECH_EGRE||'-'|| vfech_docu||'-'||vfech_pago||' fcerty '|| vfecha_certy ||' ftitu '||vfecha_titu  );
  
  
open Fproc_out
              FOR
                select distinct vavance   avances,
                         vestatus estatus,
                         --to_char(VFECH_EGRE, 'DD/MM/YYYY')  fecha_estatus,
                          VFECH_EGRE   fecha_estatus,
                         vdoctosx documentos, 
                         --to_char(vfech_docu, 'DD/MM/YYYY') fecha_docu,
                         vfech_docu fecha_docu,
                         vsaldox  NO_Adeudo,
                         --to_char(vfech_pago, 'DD/MM/YYYY')  fecha_pago,
                         vfech_pago  fecha_pago,
                         vcolfx   Accesorio,
                         vfech_colf fecha_acce,
                         vcert_elab certif_elaborado,
                         VCERT_AUT certif_autentificado,
                         vfecha_certy fecha_certi,
                         VSSO  servicio_soc,
                         vfecha_ss  fecha_ss,
                         VTITULO_ELB elabora_titulo,
                         VTIT_AUTEN  titulo_autentificado,
                         vfecha_titu  fecha_titu,
                         vdoc_entregados docu_entregados_fis,
                         vapostille  apostille,
                         vdoc_enviados  docu_enviados
               from dual;

--COMMIT;
vfech_docu := ''; -- vacia la variable global.

RETURN Fproc_out;

exception when others then
null;
VSALIDA := sqlerrm;
dbms_output.put_line('salida gral procedure campo de titulaciÛn:  '||vsalida  );

END F_PROC_TITULO;


FUNCTION F_REGLA_DOCU (PPIDM NUMBER, PCAMPUS VARCHAR2, PNIVEL VARCHAR2, PTIPO VARCHAR2, PREGLA VARCHAR2) RETURN VARCHAR2 IS

VDOCTOS_DOCU varchar2(40);
NUM_DOCU     number:= 0;
indicedig    number:= 1;
vdoctos      number:= 0;
vcve_docto   varchar2(8):= NULL;
vsts_docu    varchar2(40);
vsalida      VARCHAR2(900):= 'EXITO';
vdoctosx  varchar2(1):= 'N';
vtot_doc   number := 0;
VCETD  varchar2(1):= 'N';
VVTG      varchar2(1):= 'N';
VACUD     varchar2(1):= 'N';
Vdoen      varchar2(1):= 'N';
vfechav1   date; --varchar2(14);
vfechatmp  date := '01/01/1900'; --varchar2(14);


BEGIN
   ---- en base a los parametrizadores de los documentos buscamos que doctos necesita segun su campus nivel tipo ingreso glovicx 26.01.2024
   
   --DBMS_OUTPUT.PUT_LINE('INICIO NUEVA FUNCION:: '|| PPIDM||'.'|| PCAMPUS||'.'|| PNIVEL||'.'|| PTIPO||'.'||PREGLA||'-'||vfech_docu );  
 
   LOOP
                --- loop para buscar y separar los ducumentos que vienen en el agrupador en la misma lÌnea 
     BEGIN
            
       select '''' ||REPLACE(ZSTPARA_PARAM_VALOR,',',''',''' )||'''' doctos
            ,REGEXP_COUNT(ZSTPARA_PARAM_VALOR, ',')+1 num_doc
            ,regexp_substr(ZSTPARA_PARAM_VALOR,'[^,]+',1,indicedig) cve_docto
          INTO VDOCTOS_DOCU, NUM_DOCU,vcve_docto
            from zstpara
            where 1=1
            and ZSTPARA_MAPA_ID = 'DOCU_EGRE'
            and SUBSTR(ZSTPARA_PARAM_DESC,1,INSTR(ZSTPARA_PARAM_DESC,',',1)-1) = PCAMPUS
            and SUBSTR(ZSTPARA_PARAM_DESC,INSTR(ZSTPARA_PARAM_DESC,',',1)+1,2)  = PNIVEL
            and (SUBSTR(ZSTPARA_PARAM_DESC,8,2)  = PTIPO
               or SUBSTR(ZSTPARA_PARAM_DESC,8,2) IS NULL)
            and ZSTPARA_PARAM_ID = PREGLA
           -- and rownum < 2
            order by 1 ;
            
     exception when others then
      vsalida := 'Error en parametrizador DOCU_EGRE-DOCU : '|| sqlerrm;  
      VDOCTOS_DOCU := 'NA' ;
      NUM_DOCU     := 0 ;
      vcve_docto   := NULL ;
      
     DBMS_OUTPUT.PUT_LINE('eRROR en la busqueda de los documentos:: '|| vsalida);
     
     
     END;
        
        exit when vcve_docto is null;
        
        
    --DBMS_OUTPUT.PUT_LINE('despues de docu_egre:: '|| VDOCTOS_DOCU ||','||NUM_DOCU||'.'||vcve_docto||'---'||PREGLA );
    
    -- se busca luego el estatus de los doocumentos segun parametrizador 2
      BEGIN
          select ZSTPARA_PARAM_VALOR
            INTO vsts_docu
                from zstpara
                where 1=1
                and ZSTPARA_MAPA_ID = 'ESTA_DOCU'
                and SUBSTR(ZSTPARA_PARAM_ID,1,INSTR(ZSTPARA_PARAM_ID,',',1)-1) = PCAMPUS
                and SUBSTR(ZSTPARA_PARAM_ID,INSTR(ZSTPARA_PARAM_ID,',',1)+1,2)  = PNIVEL
                and ZSTPARA_PARAM_DESC  = vcve_docto;

        exception when others then
      vsts_docu  := 'NA';
      vsalida := 'Error en parametrizador DOCU- ESTA_DOCU : '|| sqlerrm;  
      END;
    
     --DBMS_OUTPUT.PUT_LINE('despues de esta_docu :: '|| vsts_docu||'_'||vcve_docto );
    
    
    ---busca documentos---  aqui debe traer el contador 2 para ser valido 
    begin  
       select distinct NVL(count(*),0), MAX(trunc(SARCHKL_SOURCE_DATE))
         INTO vdoctos, vfechav1
          from SARCHKL sk
           where 1=1
            and UPPER(sk.SARCHKL_ADMR_CODE) = UPPER(vcve_docto)
            and UPPER(sk.SARCHKL_CKST_CODE) = UPPER(vsts_docu)
            and sk.SARCHKL_PIDM = ppidm
            and sk.SARCHKL_APPL_NO = (Select max (k2.SARCHKL_APPL_NO) 
                                        from SARCHKL k2
                                          where 1=1
                                            and sk.SARCHKL_PIDM = k2.SARCHKL_PIDM
                                            and sk.SARCHKL_ADMR_CODE = k2.SARCHKL_ADMR_CODE
                                        )
            group by SARCHKL_SOURCE_DATE;
      
    exception when others then
      vdoctos  := 0;
      vfechav1 := '';
      vsalida  := 'error en sarchkl: '|| sqlerrm;
    end;
    
     -------aqui vamos a sacar la fecha de los certificados y titulos nuev aregla betzy 01.07.2024
     --LICENCIATURA: CETD MAESTRÕA: CMTD DOCTORADO: CTDD
     -- LICENCIATURA: TIUD MAESTRÕA:TIUD, GRMD DOCTORADO: GRDD
     
    if vcve_docto in ('CETD','CMTD','CTDD')   then
    vfecha_certy := vfechav1;
    --dbms_output.put_line('aqui entro a LICEN: '|| vfecha_certy );
    elsif vcve_docto in ('GRMD','GRDD', 'TIUD')   then
    vfecha_titu := vfechav1;
   -- dbms_output.put_line('aqui entro a GRADOO: '|| vfecha_titu );
    end if;
    
    
    
    --DBMS_OUTPUT.PUT_LINE('DESPUES DE DOCUMENTO_ SARCHKL  '||indicedig||'--+'||vcve_docto||'-'||vsts_docu||'_'|| vdoctos||'-'||vfechav1 );
    -----aqui buscamos la fecha m·s alta pero solo para DOCU  glovicx 09.05.2024
    IF  PREGLA = 'DOCU' then
      
      IF vfechav1 is not null then 
       
        --vfechatmp :=  to_char(vfechav1,'dd/mm/yyyy');
       
        DBMS_OUTPUT.PUT_LINE('DEntro Compara fechas :  '||vfech_docu||'--'||vfechatmp||'--'|| vfechav1  );
         ----- buscamos la fecha maxima  29.04.2024  glovicx 
       IF vfech_docu is null then
         
        --vfech_docu :=  to_char(vfechav1,'dd/mm/yyyy');
        vfech_docu := vfechav1;
        --DBMS_OUTPUT.PUT_LINE('DEntro fecha_docu null :  '||vfech_docu||'--'||vfechatmp||'--'|| vfechav1  );
       else
         --DBMS_OUTPUT.PUT_LINE('DEntro ELSEEE de fecha_docu :  '||vfech_docu||'--'||vfechatmp||'--'|| vfechav1  );
            IF vfechav1 >  vfechatmp  then
            
               --vfech_docu := to_char(vfechav1,'dd/mm/yyyy');
               vfech_docu := vfechav1;
               
                 --DBMS_OUTPUT.PUT_LINE('DEntro de max fechaXXX:  '||vfech_docu||'-'||vfechatmp||'-'|| vfechav1  ); 
             end if;
       end if;   
        vfechatmp := vfechav1;
      END IF; 
    
    END IF;
      
      
      --  exit when vcve_docto is null;
        
     --DBMS_OUTPUT.PUT_LINE('DESPUES DE DOCUMENTO_ SARCHKLXX2  '||indicedig);
      indicedig:=indicedig +1;
     vtot_doc := vtot_doc + vdoctos;
       
      --DBMS_OUTPUT.PUT_LINE('paso11: DENTRO del  LOOP: '||  indicedig ||' SUMA > ' || vtot_doc||'-'||NUM_DOCU||'.'||PREGLA ||'->'||vcve_docto ||'+'|| vsts_docu);
 


   end loop;
------ AQUI TENEMOS QUE IR EVALUANDO CADA UNA DE LAS ETIQUETAS DEL PARA Y REGRESANDO Y/N SEG⁄N SEA EL CASO.
 --DBMS_OUTPUT.PUT_LINE('paso33: CERRANDO LOOP: '||  indicedig ||' SUMA >' || vtot_doc||'-'||NUM_DOCU||'.'||PREGLA ||'->'||vcve_docto ||'+'|| vsts_docu);
 
 
 IF PREGLA = 'DOCU'  THEN 
   --DBMS_OUTPUT.PUT_LINE('DENTRO DE la validacion de DOCU, '||PREGLA||'-'|| vtot_doc||'.'|| NUM_DOCU);
   
          IF vtot_doc >= NUM_DOCU   THEN
            vdoctosx  := 'Y'; 
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la validacion de DOCUMENTOs, '|| vdoctosx );
             
             RETURN vdoctosx;
          
           ELSE  
             vdoctosx  := 'N'; 
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la NO CUMPLE DOCUMENTOs, '|| vdoctosx );
             
             RETURN vdoctosx;
          end if;
       ---no SE CUMPLE LAS REGLAS
        
          
   ELSIF  PREGLA = 'CERA'  THEN    
     NULL;
       --DBMS_OUTPUT.PUT_LINE('DENTRO DE la validacion de CERA-X1 , '|| VCETD );
       
           IF vtot_doc >= NUM_DOCU   THEN
            VCETD  := 'Y'; 
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la validacion de CERA-X2 , '|| VCETD );
             
             RETURN VCETD;
             
            ELSE
              VCETD  := 'N'; 
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la validacion de CERA-X2 , '|| VCETD );
             
             RETURN VCETD;
             
          end if;
         
         
     
   ELSIF  PREGLA = 'TIAU'  THEN
     NULL;
        IF vtot_doc >= NUM_DOCU   THEN
           VVTG := 'Y' ;
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la validacion de TIAU , '|| VVTG );
             
             RETURN VVTG;
          ELSE
           VVTG := 'N' ;
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE  NO ENCUENTRA de TIAU , '|| VVTG );
             
             RETURN VVTG;
           
          end if;

    
     
   ELSIF  PREGLA = 'DOFI'  THEN
     NULL;
         IF vtot_doc >= NUM_DOCU   THEN
           VACUD := 'Y' ;
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la validacion de DOFI , '|| VACUD );
             
             RETURN VACUD;
          ELSE
          VACUD := 'N' ;
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la NO ENCUENTRA  de DOFI , '|| VACUD );
             
             RETURN VACUD;   
          end if;

     
     
   ELSIF  PREGLA = 'DOEN'  THEN
    NULL;
       IF vtot_doc >= NUM_DOCU   THEN
           Vdoen := 'Y' ;
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la validacion de DOENX , '|| Vdoen );
             
             RETURN Vdoen;
         ELSE
          Vdoen := 'N' ;
            
             --DBMS_OUTPUT.PUT_LINE('DENTRO DE la NO ENCUENTRE de DOENX , '|| Vdoen );
             
             RETURN Vdoen;  
          end if;

  ELSE
  NULL;
 END IF;
 
 return vsalida;
 
 
exception when others then
 
 vsalida  := 'eRROR gral en f_regla_docu '|| sqlerrm;
 DBMS_OUTPUT.PUT_LINE('::'|| vsalida );
 RETURN vsalida;
  
END F_REGLA_DOCU;



FUNCTION F_BALANCE_ADEUDO (PPIDM NUMBER, PSP NUMBER, PNIVEL VARCHAR2) RETURN NUMBER IS

--  ESTA FUNCI”N SE HIZO PARA CAMBIAR LA OTRA VERSI”N YA QUE ESTA TOMA EL ADEUDO X STUDY PATH GLOVICX 13-06-2024
VSALDO  NUMBER := 0;
vsalida   VARCHAR2(300);

BEGIN
 
 SELECT  SUM(DATOS.BALANCE) BALANCE
  INTO VSALDO
  FROM (
  select sum(nvl (tbraccd_balance, 0)) balance
            from tbraccd, TBBDETC
            Where tbraccd_pidm = PPIDM
            And TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
            And TRUNC(TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate) 
            AND TBRACCD_STSP_KEY_SEQUENCE = PSP ) datos
   where 1=1;
            ---- se quito esta parte por instruciones de Betzy 20.05.2025-- glovicx 
   /* union
        select sum(nvl (tbraccd_balance, 0)) balance
        from tbraccd
         Where tbraccd_pidm = PPIDM
        And TRUNC(TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate)
        and tbraccd_detail_code in ( select distinct codigo
                                       from TZTINC
                                       where 1=1
                                        and nivel = pnivel
                                        and substr(CODIGO,1,2) = substr(F_GetSpridenID(ppidm),1,2 ) )
         AND TBRACCD_STSP_KEY_SEQUENCE = PSP ) DATOS; 
      */

/*
 SELECT  SUM(DATOS.BALANCE) BALANCE
  INTO VSALDO
  FROM (
  select sum(nvl (tbraccd_balance, 0)) balance
        from tbraccd
        join TBBDETC on TBBDETC_DETAIL_CODE = TBRACCD_DETAIL_CODE
        join TZTNCD on TZTNCD_CODE = TBRACCD_DETAIL_CODE and TZTNCD_CONCEPTO in ('Venta','Interes')
    Where tbraccd_pidm = PPIDM
        And TRUNC(TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate)
        AND TBRACCD_STSP_KEY_SEQUENCE = PSP
    union
        select sum(nvl (tbraccd_balance, 0)) balance
        from tbraccd
         Where tbraccd_pidm = PPIDM
        And TRUNC(TBRACCD_EFFECTIVE_DATE) <= trunc(sysdate)
        and tbraccd_detail_code in ( select distinct codigo
                                       from TZTINC
                                       where 1=1
                                        and nivel = pnivel
                                        and substr(CODIGO,1,2) = substr(F_GetSpridenID(ppidm),1,2 ) )
         AND TBRACCD_STSP_KEY_SEQUENCE = PSP ) DATOS; 

*/

--- estas funciones me las paso Vic Ramirez para sacar el saldo al dia o saldo total
--        SELECT  PKG_DASHBOARD_ALUMNO.f_dashboard_saldodia(PPIDM) Saldo_Total
--          INTO VSALDO  
--          from dual;
            
       IF VSALDO < 0 then  -- ajuste se hace para que no mande saldos a favor -999 glovicx 16.05.2025
           VSALDO := 0;
         end if;


RETURN VSALDO;

exception when others then
 
 vsalida  := 'error en adeudo: '|| sqlerrm;
 DBMS_OUTPUT.PUT_LINE('eRROR gral en f_regla_docu'|| vsalida );
 
 RETURN vsalida;
 

END F_BALANCE_ADEUDO ;

FUNCTION F_INSERTA_REGS (PRESPONSABLE NUMBER, PPIDM NUMBER,PPROGRAM VARCHAR2, PACTIVY_IND NUMBER default 1, PUSER VARCHAR2,PMODO NUMBER )  
RETURN VARCHAR2
IS

-- ESTA FUNCION  es para insertar el nuevo xml o el regenerado xml de los certificados de esta forma se puede llevar 
--  una bitacora de regeneraciones glovicx 06.08,2024
VMATRICULA   VARCHAR2(16);
VSALIDA      VARCHAR2(300):= 'EXITO';


BEGIN

VMATRICULA := F_GetSpridenID(PPIDM);

  begin
    
    insert into saturn.SZTTIDI
        (SZTTIDI_IDRESPONSABLE,
        SZTTIDI_PIDM_titulo,
        SZTTIDI_PROGRAM,
        SZTTIDI_ACTIVY_IND,
         SZTTIDI_ACTIVITY_DATE,
        SZTTIDI_USER,
        SZTTIDI_ID,
        SZTTIDI_XML_IND,
        SZTTIDI_VAL_FIRMA,
        SZTTIDI_MODO,
        SZTTIDI_FECHA_BANNER )
        values(PRESPONSABLE, PPIDM, PPROGRAM, PACTIVY_IND, sysdate, PUSER,VMATRICULA,1,0, PMODO, sysdate );
    
 
    --message('Guardando pidm  '|| :SZTTIDI.SZTTIDI_PIDM_TITULO );
  exception when others  then
     -- Message( ' Los registros ya estan guardados  '||:SZTTIDI.SZTTIDI_ACTIVY_IND ||'--'||:SZTTIDI.SZTTIDI_PIDM_TITULO );
     -- message(sqlerrm);
      VSALIDA := 'Error en Insert SZTTIDI: '|| SQLERRM;
      
  end;


COMMIT;

  RETURN (VSALIDA);
                    
EXCEPTION WHEN OTHERS THEN 
VSALIDA := 'ERROR GRAL AL INSERTAR EN ZTTIDI' || SQLERRM;

END F_INSERTA_REGS;






BEGIN

P_inicio (ppidm, pprograma, p_representate  ); 
null;
exception when others then
null;

raise_application_error (-20002,'Error general del proceso  '||sqlerrm);      

end PKG_TITULO_DIG;
/

DROP PUBLIC SYNONYM PKG_TITULO_DIG;

CREATE OR REPLACE PUBLIC SYNONYM PKG_TITULO_DIG FOR BANINST1.PKG_TITULO_DIG;


GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO CONSULTA;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN_BI;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN_EAFIT;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN_UMD;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN1;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN2;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN3;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN4;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN5;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SIU_CONN6;

GRANT EXECUTE ON BANINST1.PKG_TITULO_DIG TO SPOTLIGHT_USER;
