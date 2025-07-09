DROP PACKAGE BODY BANINST1.PKG_CERTIFICADO_DIG;

CREATE OR REPLACE PACKAGE BODY BANINST1.PKG_CERTIFICADO_DIG   AS
/*   se modifico para pruebas sep  vic 07/08/2018 */
vsello CLOB;
vdetcert clob;
v_firma  clob;

salida           UTL_FILE.FILE_TYPE  ;
nom_archivo      varchar2(40);
directorio       varchar2(90);
salida_dat       varchar2(32000);
l_xmltype        XMLTYPE;

soap_request           varchar2(5000);
soap_respond           varchar2(5000);
vxml_inicio            varchar2(200);
vxml_respon            varchar2(10000);
vxml_entidad           varchar2(5000);
vxml_expedicion        varchar2(5000);
vxml_alumno            varchar2(5000);
vxml_califica          varchar2(5000);
vxml_fin               varchar2(60);
vxml_califica2         varchar2(5000);
vxml_califica3          clob;
vxml_total             clob;
    
v_nivel            varchar2(2)   DEFAULT NULL;
v_campus           varchar2(6)   DEFAULT NULL;
v_prog             varchar2(14)  DEFAULT NULL;
v_moneda           varchar2(4)   DEFAULT NULL;
vpidm              number;
vmsjerror          varchar2(1000);

v_no_cert      varchar2(1000);
v_cert_resp    varchar2(3000);
v_sello        varchar2(3000);
v_folio_ctrl   number;
v_tipo_cert    number;
v_ent_fed      varchar2(2);
v_idcamp       varchar2(8);
v_idinstituto   number;
v_idcargo       number;
v_curp_resp      varchar2(20);
v_materno_resp   varchar2(80);
v_paterno_resp    varchar2(80);
v_nombre_resp     varchar2(50);
v_fec_exp       varchar2(30);
v_numero        number;
v_cve_plan      number;
v_tipo_perd      number;
v_idcarrera      number;
v_curp_alumn     varchar2(20);
v_materno_alumn    varchar2(80);
v_materno_alumn2    varchar2(80);
v_paterno_alumn   varchar2(80);
v_nombre_alumn     varchar2(50);
v_fech_nac_alumn   varchar2(30);
v_genero          varchar2(20);
v_id_genero        number;
v_nu_control      varchar2(12);
v_idexp            varchar2(3);
v_fecha            varchar2(20);
v_tipo_certificado  number;
v_promedio        float;
v_promedio2        VARCHAR2(7);
v_asignadas       number;
v_total_mat       float;
v_observ          number;
v_califica        avance1.calif%type; ---varchar2(6);
v_ciclo            varchar2(10);
v_id_materia      varchar2(8);
v_avances         number;
---------------------------------------
matricula  spriden.spriden_id%type;
nombre    VARCHAR2(200);
Programa  VARCHAR2(90);
estatus   VARCHAR2(60);
per       number; -- avance1.per%type;
area       avance1.area%type;
nombre_area avance1.nombre_area%type;
materia    VARCHAR2(60);
nombre_mat VARCHAR2(80);
califica  avance1.calif%type;
ord        number; -- avance1.per%type;
tipo      VARCHAR2(80);
n_area    VARCHAR2(90);
hoja      number ; --avance1.per%type;
aprobadas_curr number;
no_aprobadas_curr  number;
curso_curr    number;
por_cursar_curr number;
total_curr   number;
avance_curr  number;
aprobadas_tall number;
no_aprobadas_tall  number;
curso_tall  number;
por_cursar_tall number;
total_tall   number;
ppidm        number; --:=59308; ----parametro de entrada  del procedimento
pprograma    varchar2(15) ;   ----parametro de entrada del procedimiento
v_calificaciones     varchar2(9000);
v_fech_exp           varchar2(20);
pindica       number; 
ptipo         number;
------------------------------------------------------------------NUEVA VERSION CAMBIO DE TABLA-----------------------
cursor c_alumnos(pprograma  varchar2, ppidm number ) is
select f.SZTRECE_PIDM_CERTIF  as pidm , 
 f.SZTRECE_PROGRAM_CERTIF   as programa
, PE.SPBPERS_SEX  SEXO
 From SZTRECE F , SPBPERS PE 
where F.SZTRECE_PIDM_CERTIF  = PE.SPBPERS_PIDM
and F.SZTRECE_PROGRAM_CERTIF   = pprograma
---IF pindica = 3 then-----ENTONCES ES UN REPROCESO
and SZTRECE_XML_IND  = (SELECT DECODE(pindica,3,'NOT NULL',2,'is null', 1,'is null' ) FROM DUAL  )-----cero significa que aun no se genera su archivo xml
and F.SZTRECE_PIDM_CERTIF   = NVL(ppidm, F.SZTRECE_PIDM_CERTIF )
order by 1 desc ;

cursor c_alumnos2(pprograma  varchar2, ppidm number ) is
select f.SZTRECE_PIDM_CERTIF  as pidm , 
 f.SZTRECE_PROGRAM_CERTIF   as programa
, PE.SPBPERS_SEX  SEXO
 From SZTRECE F , SPBPERS PE 
where F.SZTRECE_PIDM_CERTIF  = PE.SPBPERS_PIDM
and F.SZTRECE_PROGRAM_CERTIF   = pprograma

--and SZTRECE_XML_IND  is null-----TRES SIGNIFOCA QUE ES REPROCESO Y GENERA LOS DOS ARCHIVOS
and F.SZTRECE_PIDM_CERTIF   = NVL(ppidm, F.SZTRECE_PIDM_CERTIF )
order by 1 desc ;
 

cursor c_parametros(p_valor  varchar2, p_desc varchar2 ) is
select --ZSTPARA_PARAM_VALOR  as valor, 
        ZSTPARA_PARAM_DESC  as descr,
        ZSTPARA_PARAM_ID    as idv
from zstpara  z
where ZSTPARA_MAPA_ID = 'CERT_DIGITAL'
and  ZSTPARA_PARAM_VALOR  = p_valor
and  z.ZSTPARA_PARAM_DESC  = nvl(p_desc, z.ZSTPARA_PARAM_DESC ) 
order by 1;

vvalor   varchar2(30);
vdescr    varchar2(100);
vidv     varchar2(10);
vnombre_inst   varchar2(100);
v_intidad_fed   varchar2(100);
v_pcampus     varchar2(5);
p_valor     varchar2(20);
v_cargo       varchar2(20);
v_carrera      varchar2(50);
vtipoPeriodo     varchar2(30);
v_ncarrera     varchar2(120);
v_tipoCE     varchar2(20);
PTIPO_CERT     varchar2(10);
v_IDgenero     NUMBER;
v_tipoper      varchar2(14);
v_no_apelld   number;



function encode_base64(base in varchar2) return varchar2 is
 resultado varchar2(32000);

begin
   resultado := utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(trim(base))));

dbms_output.put_line('Encode '||resultado  );  

return ( resultado );
end encode_base64;

function decode_base64(base in varchar2) return varchar2 is
 resultado varchar2(32000);

begin
  
  resultado :=  utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw(base)));

--resultado := utl_encode.text_encode( base ,'WE8ISO8859P1', UTL_ENCODE.BASE64);

dbms_output.put_line('Encode '||resultado  );  

return ( resultado );
end decode_base64;

function encript_base64(base in varchar2) return varchar2 is
 

BEGIN

null;

end encript_base64;


Procedure P_genera_xml (ppidm in  number, pprograma  in  varchar2)  Is
v_cur       SYS_REFCURSOR;

maco_mat   number;
begin
null;

 
v_calificaciones := '';----inicaliza la variable 
vxml_califica3  := '';----inicaliza la variable 

matricula:='';
nombre :='';
Programa  :='';
estatus :='';
per :='';
area:='';
nombre_area:='';
materia :='';
nombre_mat:='';
califica:='';
ord :='';
tipo :='';
n_area:='';
hoja:='';
aprobadas_curr :='';
no_aprobadas_curr:='';
curso_curr :='';
por_cursar_curr :='';
total_curr:='';
avance_curr :='';
aprobadas_tall:='';
no_aprobadas_tall:='';
curso_tall :='';
por_cursar_tall :='';
total_tall :='';
maco_mat  :=0;

--dbms_output.put_line('antes de mandar el proceso dasboar_alumno');
 
 --v_cur := BANINST1.f_avcu_cert_dig ( vpidm,v_prog );
 v_cur := BANINST1.PKG_DASHBOARD_ALUMNO.F_DASHBOARD_AVCU_OUT ( vpidm,v_prog, substr (user,1,9) );
--dbms_output.put_line('despues de mandar el proceso dasboar_alumno'); 
 LOOP
    FETCH v_cur INTO  
 matricula,
nombre ,
Programa  ,
estatus ,
per ,
area,
nombre_area, 
materia ,
nombre_mat,
califica, 
ord , 
tipo ,
n_area, 
hoja,
aprobadas_curr ,
no_aprobadas_curr,
curso_curr ,
por_cursar_curr ,
total_curr,
avance_curr ,
aprobadas_tall,
no_aprobadas_tall,
curso_tall ,
por_cursar_tall ,
total_tall ;
  
 EXIT WHEN v_cur%NOTFOUND;
 
 begin
----------------en esta tabla estan las materias que son de equivalencia o revalidacion son muy pocas.
--select decode(count(1),1,70,100)
--INTO   v_observ
--from SHRTRCR
--where (trim(SHRTRCR_TRANS_COURSE_NAME)||trim(SHRTRCR_TRANS_COURSE_NUMBERS)) = materia
--and  SHRTRCR_PIDM  = vpidm;
 select decode(count(1),1,70,100)
     into v_observ
        from  shrtrce
        where  shrtrce_pidm=vpidm
        and (shrtrce_subj_code||shrtrce_crse_numb) = materia;


exception when others then
v_observ:='';
end;
---------------------SI LA MATERIA ES 70 O EQUIVALENCIA  ENTONCES LA RECALCULA SU PERIODO O CICLO----
--------validamos que la materia traiga un punto  si es asi vamos a maco a hacer el cambio---
 maco_mat := instr(materia,'.',1);
 
 ---dbms_output.put_line(' materia MACOOO  '|| maco_mat ); 
 
    if maco_mat > 0  then 
        select distinct SZTMACO_MATPADRE
        into materia 
        from sztmaco t
        where t. SZTMACO_MATHIJO = materia
        ;

    end if;



---dbms_output.put_line ('estoy en antes de id_materi' || materia );
IF  v_observ = 70 THEN 
BEGIN

SELECT SUBSTR(SGRSCMT_COMMENT_TEXT,10,4)
        INTO v_ciclo
FROM SGRSCMT MT
WHERE SGRSCMT_PIDM = vpidm  ----FGET_PIDM('010003935')
AND   SGRSCMT_TERM_CODE  = (SELECT MAX(SGRSCMT_TERM_CODE) FROM SGRSCMT GG WHERE GG.SGRSCMT_PIDM=MT.SGRSCMT_PIDM );
EXCEPTION  WHEN OTHERS THEN 
v_ciclo := '000000';

END;
------------busca el ID de la materia  para las que son equvalencias-------
begin
select distinct SCBCRSE_CONT_HR_HIGH
       INTO v_id_materia
from scbcrse bs
where  (SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB) = materia;
exception when others then 
v_id_materia:='ERR';
v_ciclo:='';
end;


---dbms_output.put_line ('estoy en materias calcula 70 ' || materia );

ELSE   ------------***********     ES UNA MATERIA   ORDINARIA = 100
  
 -- dbms_output.put_line ('estoy en materias calcula 100 ' || materia );
begin
----------de aqui toma el numero de materia segun sep para certificados
select  distinct SCBCRSE_CONT_HR_HIGH, 
       --SHRTCKN_TERM_CODE
       ( SELECT distinct SUBSTR(STVTERM_DESC,1,6)
                    FROM STVTERM WHERE STVTERM_CODE = CK.SHRTCKN_TERM_CODE )  AS TERM
       INTO v_id_materia , v_ciclo
from scbcrse bs, SHRTCKN ck
where  (SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB) = materia
and  bs.SCBCRSE_SUBJ_CODE  = ck.SHRTCKN_SUBJ_CODE
and  bs.SCBCRSE_CRSE_NUMB  = ck.SHRTCKN_CRSE_NUMB
and  SHRTCKN_PIDM  = vpidm;

exception when others  then
--dbms_output.put_line ('no  se encontro materias ESTOY EN EXCEPTION XXX  '  );

        begin
        
        select distinct max(SCBCRSE_CONT_HR_HIGH)
               INTO v_id_materia
        from scbcrse bs
        where  (SCBCRSE_SUBJ_CODE||SCBCRSE_CRSE_NUMB) = materia;
        
        exception when others then 
        v_id_materia:='ERR';
        v_ciclo:='';
        end;


       begin
     ---   dbms_output.put_line ('estoy en materias ciclo1 ' || materia );
         select distinct  ( SELECT SUBSTR(STVTERM_DESC,1,6)
                    FROM STVTERM WHERE STVTERM_CODE = B.SSBSECT_TERM_CODE )  AS TERM
           INTO v_ciclo   
           from SFRSTCR f, ssbsect b
            where F.SFRSTCR_CRN = B.SSBSECT_CRN
            and  F.SFRSTCR_TERM_CODE  = B.SSBSECT_TERM_CODE
            and  F.SFRSTCR_PIDM = vpidm
            and SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB = materia
            order by SFRSTCR_RSTS_CODE,SSBSECT_SUBJ_CODE||SSBSECT_CRSE_NUMB
            ;

        exception when others then 
          begin
           ---  dbms_output.put_line ('estoy en materias ciclo2 ' || materia );
            select distinct SORLCUR_TERM_CODE_CTLG  
             INTO v_ciclo
             from sorlcur so
             where  sorlcur_pidm = vpidm
             and  sorlcur_program = pprograma
             and  SORLCUR_LMOD_CODE = 'LEARNER'
             and  SORLCUR_CACT_CODE  = 'ACTIVE'
             and SORLCUR_TERM_CODE  in ( select max(SORLCUR_TERM_CODE) from sorlcur s1
                                           where s1.sorlcur_pidm = vpidm
                                             and  s1.sorlcur_program = pprograma
                                             and  s1.SORLCUR_LMOD_CODE = 'LEARNER'
                                             and  s1.SORLCUR_CACT_CODE  = 'ACTIVE'
                                                  ) ;
            exception when others then 
                v_ciclo:='';
            end;
            
        end;

end;



END IF;

v_califica := califica;

--v_califica := to_number(v_califica);
v_califica :=  substr(califica, 1, instr(califica,'.')-1);


--dbms_output.PUT_LINE(' este es  CALIFICACIONxx '||v_califica);
-----------------valida que sea materia decreditos es decir excluimos a las materias cursor propedeuticos-----
IF materia like ('%HE%')  or materia like ('%HB%') OR     materia like ('%SESO%') or califica is null  then 
null;

else
------------------------------carga los valors nuevos----
/*vxml_califica2 :='
<Asignatura  idAsignatura="'||v_id_materia||'" ciclo="'||v_ciclo||'" calificacion="'||v_califica|| '"  idObservaciones="'||v_observ||'"'||
' nombre="'||nombre_mat||'" claveAsignatura="' || materia ||'"'||
'  />';
*/

---------nuevo arreglo de los tags  del xml-----
--<Asignatura nombre="'||nombre_mat||'" claveAsignatura="' || materia||'" idObservaciones="'||v_observ||'" calificacion="'||v_califica||'" ciclo="'||v_ciclo|| '" idAsignatura="'||v_id_materia||'"/>';
vxml_califica2 :='
  <Asignatura nombre="'||nombre_mat||'" claveAsignatura="' || materia||'" idObservaciones="'||v_observ||'" calificacion="'||v_califica||'" ciclo="'||v_ciclo||'" idAsignatura="'||v_id_materia||'"/>';
--<Asignatura nombre="'||nombre_mat||'" idAsignatura="'||v_id_materia||'" ciclo="'||v_ciclo||'" calificacion="'||v_califica||'" idObservaciones="'||v_observ||'" claveAsignatura="' || materia||'"/>';
--v_calificaciones := v_calificaciones ||'|'||v_id_materia||'|'||v_ciclo||'|'||v_califica;
v_calificaciones := v_calificaciones ||v_id_materia||'|'||v_ciclo||'|'||v_califica||'|';

vxml_califica3 := vxml_califica3|| vxml_califica2;
 -- v_asignadas := v_asignadas +1;
 -- v_total_mat := v_total_mat + 1;
 dbms_output.put_line(vxml_califica2 );
 end if;

 END LOOP;
  CLOSE v_cur;

 exception when others then
 dbms_output.put_line('salida ' || vxml_califica3 );
   raise_application_error (-20002,'ERROR en genera AVCU '|| sqlerrm);
null;

 
end P_genera_xml;

procedure p_genera_dgair ( pcadena in clob, ppidalumno in varchar2, pprograma  in varchar2 ) is
salida         UTL_FILE.FILE_TYPE  ;
nom_archivo    varchar2(150);
directorio     varchar2(90);
mserr          varchar2(2000);
  
  
begin
null;
 
 --dbms_output.put_line(' salida archivo DGAIR-------  '|| ppidalumno); 
nom_archivo := 'Dgair'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.txt';
-- dbms_output.put_line(' nomnbrev  archivo DGAIR-------  '|| nom_archivo); 
 salida := UTL_FILE.fopen('ARCHXML',nom_archivo, 'W', 32767);
 
 --dbms_output.put_line(' salida open  '); 
  UTL_FILE.PUT_LINE(salida, trim(pcadena));
   --UTL_FILE.PUT_LINE(salida,'\n');
    UTL_FILE.fclose(salida);
 IF utl_file.is_open(salida) THEN
     utl_file.fclose_all;
     dbms_output.put_line('Closed All');
   END IF;
 

end p_genera_dgair;

procedure p_archivo_xml ( pcadena in clob, ppidalumno in varchar2, pprograma  in varchar2 ) is
salida         UTL_FILE.FILE_TYPE  ;
nom_archivo    varchar2(150);
directorio     varchar2(90);
mserr          varchar2(2000);
--text_raw      RAW (32767);
text VARCHAR2 (32767); 
text_raw RAW (32767); 
filehandler UTL_FILE.file_type; 
  
begin
null;
 
 text := trim(pcadena); 
 nom_archivo := 'XML'||'_'|| ppidalumno||'_'||to_char(sysdate,'DDMMYYYY')|| to_char(sysdate,'HH24MISS')|| '.xml';
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
     dbms_output.put_line('Closed All');
   END IF;
 
update SZTRECE
set SZTRECE_XML_IND = 1
where SZTRECE_PIDM_CERTIF  = vpidm
and  SZTRECE_PROGRAM_CERTIF = pprograma;


end p_archivo_xml;


procedure p_archivo_xml2 ( pcadena in clob, ppidalumno in varchar2, pprograma  in varchar2 ) is
salida         UTL_FILE.FILE_TYPE  ;
nom_archivo    varchar2(150);
directorio     varchar2(90);
mserr          varchar2(2000);
  
  
begin
null;
 
 --dbms_output.put_line(' salida archivo DGAIR-------  '|| ppidalumno); 
nom_archivo := 'XML2'||'_'|| ppidalumno||'_'|| to_char(sysdate,'HH24MISS')||'.xml';
-- dbms_output.put_line(' nomnbrev  archivo DGAIR-------  '|| nom_archivo); 
 salida := UTL_FILE.fopen('ARCHXML',nom_archivo, 'W', 32767);
  --dbms_output.put_line(' salida open  '); 
  UTL_FILE.PUT_LINE(salida, vxml_inicio);
UTL_FILE.PUT_LINE(salida, vxml_respon);
UTL_FILE.PUT_LINE(salida, vxml_entidad);
UTL_FILE.PUT_LINE(salida, soap_request);
UTL_FILE.PUT_LINE(salida, soap_respond);
UTL_FILE.PUT_LINE(salida, vxml_alumno);
UTL_FILE.PUT_LINE(salida, vxml_expedicion);
UTL_FILE.PUT_LINE(salida, vxml_califica);
UTL_FILE.PUT_LINE(salida, vxml_califica3);
UTL_FILE.PUT_LINE(salida, vxml_fin);     
   --UTL_FILE.PUT_LINE(salida,'\n');
    UTL_FILE.fclose(salida);
 IF utl_file.is_open(salida) THEN
     utl_file.fclose_all;
     dbms_output.put_line('Closed All');
   END IF;
 


end p_archivo_xml2;


Procedure P_inicio (ppidm in  number, pprograma in varchar2, pindica number, ptipo IN  number)  Is


v_no_apelld2   number;
v_encode64    varchar2(10000);
begin
null;

--
dbms_output.put_line('paso 1   ' || ppidm || '--' || pprograma );


vxml_inicio:= '<?xml version="1.0" encoding="UTF-8"?>';

vxml_fin :=   '
 </Asignaturas>'; 
vxml_fin :=vxml_fin ||' 
</Dec>' ;


open c_parametros('ENTIDAD_FED', 'CIUDAD DE MEXICO');
fetch c_parametros  into   vdescr,  vidv;
v_ent_fed := vidv;
v_intidad_fed := vdescr;
--dbms_output.put_line('>>>>ENtidad fed  '||v_ent_fed || ' - '|| v_intidad_fed);
close c_parametros;

open c_parametros('CAMPUS', null);
fetch c_parametros  into   vdescr,  vidv;
v_idcamp := vidv;
v_pcampus := vdescr;
--dbms_output.put_line('>>>>CAMpus   '||v_idcamp || ' - '|| v_pcampus);
close c_parametros;

open c_parametros('INSTITUCIONES', null);
fetch c_parametros  into   vdescr,  vidv;
v_idinstituto := vidv;
vnombre_inst := vdescr;
--dbms_output.put_line('>>>>INstituto   '||v_idinstituto || ' - '|| vnombre_inst);
close c_parametros;

open c_parametros('CARGOS', 'DIRECTOR');
fetch c_parametros  into   vdescr,  vidv;
v_idcargo := vidv;
v_cargo := vdescr;
--dbms_output.put_line('>>>>CARgos   '||v_idcargo || ' - '|| v_cargo);
close c_parametros;

IF  ptipo  = 2 then  
PTIPO_CERT  := 'TOTAL';
else 
PTIPO_CERT  := 'PARCIAL';
end if;   --ptipoC;  ---este valor viene de una valiable externa que el operador escoje si es tipo total o parcial

open c_parametros('CATALOGO_TIPO_CERTIFICACION', PTIPO_CERT);
fetch c_parametros  into   vdescr,  vidv;
v_tipo_certificado := vidv;
v_tipoCE := vdescr;
--dbms_output.put_line('>>>>TIPO certificacion   '||v_tipo_certificado || ' - '|| v_tipoCE);
close c_parametros;


---open c_alumnos ;

dbms_output.put_line('paso 3   '||  vpidm );
--fetch c_alumnos  into vpidm,v_prog,v_nivel, v_avances  ;
--close c_alumnos; 
v_idcarrera :='';

--IF pindica = 3 then-----ENTONCES ES UN REPROCESO
FOR  jump in c_alumnos2(pprograma, ppidm  )  loop

--dbms_output.put_line('REPROCESOOO XML   '||  vpidm );

--ELSE

--FOR  jump in c_alumnos(pprograma, ppidm  )  loop
--END IF;

vpidm := jump.pidm;
v_prog := jump.programa;
--v_nivel := jump.nivel;
--v_avances := jump.avances;
--v_curp_alumn := jump.curp_alum;
v_genero     := jump.sexo;
--v_campus     := jump.campus;

--------------CALCULA EL FOLIO CONTROL CONSECUTIVO POR CADA ALUMNO---  
v_folio_ctrl := 0;  ---- REVISAR QUE VALOR BEBE TENER SIEMPRE EL MISMO O VARIA

begin
SELECT NVL(MAX(SZTRECE_FOLIO_CONTROL),0) + 1
INTO  v_folio_ctrl      
from SZTRECE;
end;

dbms_output.put_line(' pidm ajecutando  '|| jump.pidm|| '--'|| v_prog );

begin
select DISTINCT SPBPERS_LEGAL_NAME ,--upper(S.SPRIDEN_LAST_NAME) , UPPER(S.SPRIDEN_FIRST_NAME),
 to_char(sp.SPBPERS_BIRTH_DATE, 'YYYY-MM-DD')||'T'||to_char(sp.SPBPERS_BIRTH_DATE, 'HH24:MI:SS') as fech_nac
       ,S.SPRIDEN_ID  , SB.SGBSTDN_CAMP_CODE
into   v_materno_alumn  , v_fech_nac_alumn,v_nu_control, v_campus
from spriden s, spbpers sp, sgbstdn sb
where spriden_pidm = vpidm
and  S.SPRIDEN_PIDM = SP.SPBPERS_PIDM
and  S.SPRIDEN_PIDM =  SB.SGBSTDN_PIDM
AND  S.SPRIDEN_CHANGE_IND IS NULL
;


exception when others then
v_materno_alumn  := '';
v_nombre_alumn   := '';
v_fech_nac_alumn  := '';
v_nu_control    := '';

----vmsjerr  :=   SQLERRM;
  vmsjerror := 'Se presento un Error Spriden>  '||sqlerrm;
  dbms_output.put_line(vmsjerror);

end;

BEGIN
SELECt GORADID_ADDITIONAL_ID
INTO v_curp_alumn
FROM GORADID
WHERE GORADID_PIDM  = PPIDM
AND GORADID_ADID_CODE = 'CURP';
EXCEPTION WHEN OTHERS THEN
v_curp_alumn:= 'ERROR';
END;


if v_genero = 'M' then 
v_genero := 'HOMBRE';
ELSE 
v_genero := 'MUJER';
END IF;


open c_parametros('CATALOGO_GENERO', v_genero);
fetch c_parametros  into   vdescr,  vidv;
v_IDgenero := vidv;
--v_tipoCE := vdescr;
----dbms_output.put_line('>>>>GENero  '||v_genero || ' - '|| v_IDgenero);
close c_parametros;

-----------------------calcula el promraga para certificado---

begin
select distinct zt.SZTDTEC_NUM_RVOE as numrvoe, zt.SZTDTEC_ID_CERTIFICA as id_cert, to_char(ZT.SZTDTEC_FECHA_RVOE, 'YYYY-MM-DD')||'T'||to_char(ZT.SZTDTEC_FECHA_RVOE, 'HH24:MI:SS') as fech_rvoe, SZTDTEC_CLVE_RVOE as cveplan
      -- , decode(SZTDTEC_PERIODICIDAD,1,'BIMESTRAL', 2,'CUATRIMESTRAL',3,'SEMESTRAL',4,'ANUAL') PERIODICIDAD
     , SZTDTEC_PERIODICIDAD_SEP ID_PER
      , decode(SZTDTEC_PERIODICIDAD_SEP,91,'SEMESTRE', 92,'BIMESTRE',93,'CUATRISEMESTRE',94,'TETRAMESTRE',260,'TRIMESTRE',261,'MODULAR',262,'ANUAL' ) PERIODICIDAD
       ,SZTDTEC_PROGRAMA_COMP,  SZTDTEC_ID_CARRERA
into v_numero, v_carrera, v_fec_exp, v_cve_plan, v_tipo_perd,vtipoPeriodo  ,v_ncarrera,v_idcarrera
from sztdtec zt
where SZTDTEC_CAMP_CODE  = v_campus
and   SZTDTEC_PROGRAM    = v_prog
--and  SZTDTEC_STATUS  = 'ACTIVO'
and  SZTDTEC_TERM_CODE = (select SORLCUR_TERM_CODE_CTLG from sorlcur cu 
                           where sorlcur_pidm = vpidm  and  SORLCUR_LMOD_CODE = 'LEARNER' 
                            and  SORLCUR_CACT_CODE  = 'ACTIVE'  and  SORLCUR_PROGRAM = v_prog
                            and  SORLCUR_TERM_CODE  = ( Select max(SORLCUR_TERM_CODE)  from sorlcur dd where DD.SORLCUR_PIDM =cu.sorlcur_pidm
                                                           and  DD.SORLCUR_PROGRAM  = CU.SORLCUR_PROGRAM  and dd.SORLCUR_LMOD_CODE = 'LEARNER' 
                                                             and  dd.SORLCUR_CACT_CODE  = 'ACTIVE'   ) ) ;


dbms_output.put_line('>>> PROGgrama ' ||v_numero||'-'|| v_carrera||'-'|| v_fec_exp||'-'|| v_cve_plan||'-'|| v_tipoper||'-'||v_ncarrera||'-'||v_idcarrera);
exception when others then
v_numero := '';
v_carrera  := '';
v_fec_exp   := '';
v_idcarrera :='';
end;


BEGIN
SELECT  trim(SZTRECE_DET_CERTIFICA), trim(SZTRECE_SELLO), SZTREDC_NOMBRE, SZTREDC_PATERNO, SZTREDC_MATERNO, SZTREDC_CURP,SZTREDC_NO_CERTIFICADO,SZTREDC_CVE_FIRMA 
INTO   vdetcert, vsello,  v_nombre_resp, v_paterno_resp, v_materno_resp, v_curp_resp, v_no_cert, v_firma 
FROM SZTRECE CR, SZTREDC CE
WHERE SZTRECE_PIDM_CERTIF = vpidm
AND   SZTRECE_PROGRAM_CERTIF = v_prog
AND CR.SZTRECE_IDRESPONSABLE = CE.SZTREDC_IDRESPONSABLE
;

exception when others then
v_no_cert:='';
vsello:='';
vdetcert:='';


END;

v_tipo_cert   := 5; ---- REVISAR QUE VALOR BEBE TENER SIEMPRE EL MISMO O VARIA
----v_nu_control  := 9999; SE SACA DE ID DE SPRIDEN CONSULTA DE ARRIBA 

--dbms_output.put_line ( 'paso aqui 1 ');
--vxml_entidad := '<Ipes idEntidadFederativa="'||v_ent_fed||'" entidadFederativa="'||v_intidad_fed ||'" campus="'||v_pcampus||'" idCampus="'||v_idcamp||'" idNombreInstitucion="'|| v_idinstituto||'"  nombreInstitucion="'|| vnombre_inst||'">' ;  
--------------se cambio el orden    paa SEP---
vxml_entidad := '
 <Ipes   nombreInstitucion="'|| vnombre_inst||'" idNombreInstitucion="'|| v_idinstituto||'" idCampus="'||v_idcamp||'" campus="'||v_pcampus||'" entidadFederativa="'||v_intidad_fed ||'" idEntidadFederativa="'||v_ent_fed||'">' ;
--soap_request := '<Responsable idCargo="'||v_idcargo ||'" curp="'||v_curp_resp||'" segundoApellido="'||v_materno_resp||'" primerApellido="'||v_paterno_resp||'" nombre="'||v_nombre_resp||'"/>'||     
soap_request:='
 <Responsable nombre="'||v_nombre_resp||'" primerApellido="'||v_paterno_resp|| '" segundoApellido="'||v_materno_resp||'" curp="'||trim(v_curp_resp)||'"  idCargo="'||v_idcargo ||'"/>'||
--dbms_output.put_line ( 'paso aqui 2 ');
'
</Ipes>';

v_fech_exp := to_char(sysdate, 'YYYY-MM-DD')||'T'||'00:00:00';
--vxml_expedicion:='
--<Expedicion idLugarExpedicion="'||v_ent_fed||'" fecha="'|| v_fech_exp ||'" idTipoCertificacion="'||v_tipo_certificado||'" tipoCertificacion="'||v_tipoCE||  '"/>';
--dbms_output.put_line ( 'paso aqui 3 ');
dbms_output.put_line( ' alumno ' || v_materno_alumn);
vxml_expedicion:='
 <Expedicion tipoCertificacion="'||v_tipoCE||'" idTipoCertificacion="'||v_tipo_certificado||'" fecha="'|| v_fech_exp ||'" idLugarExpedicion="'||v_ent_fed|| '"/>';


---------separa  los apellidos an dos-----
v_no_apelld  := instr(v_materno_alumn, ' ');
v_paterno_alumn  := substr(v_materno_alumn,1,v_no_apelld-1);
dbms_output.put_line( ' paterno  ' || v_paterno_alumn || '-'|| v_no_apelld);
v_no_apelld2 := instr(v_materno_alumn, ' ',1,2);
v_materno_alumn2 := substr(v_materno_alumn, v_no_apelld+1,v_no_apelld2-v_no_apelld-1  );

dbms_output.put_line( ' MATERNO  ' || v_materno_alumn2 || '-'|| v_no_apelld);
v_nombre_alumn   := substr(v_materno_alumn, v_no_apelld2+1,50);
dbms_output.put_line( ' NOMBRE  ' || v_nombre_alumn || '-'|| v_no_apelld2);

--vxml_respon :='<Dec xmlns="https://www.siged.sep.gob.mx/certificados/" noCertificadoResponsable="' || v_no_cert ||'"
-- certificadoResponsable="' || vdetcert ||'"
-- sello="'||vsello|| '"folioControl="'||v_folio_ctrl||'" tipoCertificado="'||v_tipo_cert||'" version="1.0">';
v_total_mat:= BANINST1.PKG_DATOS_ACADEMICOS.TOTAL_MATE1 ( vpidm,v_prog );
v_promedio := BANINST1.PKG_DATOS_ACADEMICOS.promedio1 ( vpidm,  v_prog  );-----hay que ver como se eejcuta par que no salgan los mensajes de este proceso
--nvl(v_promedio,9.999);

--select decode(v_promedio,0,9.99) into v_promedio from dual;   -----quitar esta sentencia al pasar a prod y revisar materias asignadas es lo mismo que total  vic
--SELECT  TO_CHAR(v_promedio, '99.9')
--into v_promedio2
--   FROM DUAL;
 

SELECT  substr(v_promedio,1,3)
into v_promedio2
   FROM DUAL;    
    


Salida_dat := (''||'|'||''||'|'||'1.0'||'|'||v_tipo_cert||'|'||v_idinstituto||'|'||v_idcamp||'|'||v_ent_fed||'|'||v_curp_resp||'|'||
   v_idcargo||'|'||v_numero||'|'||v_fec_exp||'|'||v_idcarrera||'|'||v_tipo_perd||'|'||v_cve_plan||'|'||v_nu_control||'|'||v_curp_alumn||'|'||
   v_nombre_alumn||'|'||v_paterno_alumn||'|'||v_materno_alumn2||'|'||v_IDgenero||'|'||v_fech_nac_alumn||'|'||''||'|'||''||'|'||v_tipo_certificado||'|'||
   v_fech_exp||'|'||v_ent_fed||'|'||v_total_mat||'|'||v_total_mat||'|'||v_promedio2||'|'||v_calificaciones||'|');

DBMS_OUTPUT.PUT_LINE(' SALIDAUNO:: '|| Salida_dat);


 ---------se cambia   para ser igual a sep---
 vxml_respon :='
<Dec  version="1.0"'||' tipoCertificado="'||v_tipo_cert||'" folioControl="'||v_folio_ctrl||'"
  sello="'||trim(vsello)||'"
  certificadoResponsable="'|| trim(vdetcert) ||'"
  noCertificadoResponsable="'|| trim(v_no_cert) ||'"
  xmlns="https://www.siged.sep.gob.mx/certificados/"' ||'>';

/*vxml_respon :='<Dec xmlns="https://www.siged.sep.gob.mx/certificados/" noCertificadoResponsable="' || v_no_cert ||'"
 certificadoResponsable="' || vdetcert ||'"
 sello="'||vsello|| '"
 folioControl="'||v_folio_ctrl||'" tipoCertificado="'||v_tipo_cert||'" version="1.0">';
*/
 
--dbms_output.put_line ( 'paso aqui 4 ');
soap_respond:= '
 <Rvoe  numero="'||v_numero||'" fechaExpedicion="'||v_fec_exp||'"/>'||'
 <Carrera  idCarrera="'||v_idcarrera||'" idTipoPeriodo="'||v_tipo_perd||'" clavePlan="'||v_cve_plan||'"/>';
--dbms_output.put_line ( 'paso aqui 5 ');

---------------------------se cambia el orden de xml----
--soap_respond:= '<Rvoe fechaExpedicion="'||v_fec_exp||'" numero="'||v_numero||'"/>'||
--'<Carrera clavePlan="'||v_cve_plan||'" idTipoPeriodo="'||v_tipo_perd||'" idCarrera="'||v_idcarrera||'"/>';

vxml_alumno:='
 <Alumno  numeroControl="'||v_nu_control||'" curp="'||v_curp_alumn||'"  nombre="'||v_nombre_alumn||'" primerApellido="'||trim(v_paterno_alumn)||'" segundoApellido="'||trim(v_materno_alumn2)|| '" idGenero="'||v_IDgenero ||'" fechaNacimiento="'||v_fech_nac_alumn ||'"/>';
--dbms_output.put_line ( 'paso aqui 6');
--vxml_alumno:='<Alumno curp="'||v_curp_alumn||'" segundoApellido="'||trim(v_materno_alumn2)||'" primerApellido="'||trim(v_paterno_alumn)||'"  nombre="'||v_nombre_alumn||'" fechaNacimiento="'||v_fech_nac_alumn ||'" idGenero="'||v_IDgenero ||'" numeroControl="'||v_nu_control|| '"/>';


  
   
dbms_output.put_line ( 'paso aqui 6.2'|| ' promediox ' || v_promedio2|| 'promedio orig '|| v_promedio );


vxml_califica := '
 <Asignaturas total="'||v_total_mat||'" asignadas="'||v_total_mat||'" promedio="'||trim(v_promedio2)||'">';
--vxml_califica := '<Asignaturas promedio="'||trim(v_promedio2)||'" asignadas="'||v_total_mat||'" total="'||v_total_mat||'">';


 dbms_output.put_line(vxml_inicio); 
 dbms_output.put_line(vxml_respon);
 dbms_output.put_line(vxml_entidad);
 dbms_output.put_line(soap_request);     
 dbms_output.put_line(soap_respond);
 dbms_output.put_line(vxml_alumno );
 dbms_output.put_line(vxml_expedicion );
 dbms_output.put_line(vxml_califica);

P_genera_xml( vpidm,v_prog) ;-----genera las variables de  

dbms_output.put_line(vxml_fin );


------------------------------------------inserta las cadenas xml y dat   para el certificado------------
--update SZTRECE
--   SET   SZTRECE_CHAIN_XML = vxml_inicio || vxml_respon || vxml_entidad|| soap_request ||soap_respond|| vxml_alumno || vxml_expedicion|| vxml_califica||vxml_califica3|| vxml_fin
--where SZTRECE_PIDM_CERTIF  = vpidm
--and  SZTRECE_PROGRAM_CERTIF  = v_prog;


dbms_output.put_line(''||'|'||''||'|'||'1.0'||'|'||v_tipo_cert||'|'||v_idinstituto||'|'||v_idcamp||'|'||v_ent_fed||'|'||v_curp_resp||'|'||
   v_idcargo||'|'||v_numero||'|'||v_fec_exp||'|'||v_idcarrera||'|'||v_tipo_perd||'|'||v_cve_plan||'|'||v_nu_control||'|'||v_curp_alumn||'|'||
   v_nombre_alumn||'|'||v_paterno_alumn||'|'||v_materno_alumn2||'|'||v_IDgenero||'|'||v_fech_nac_alumn||'|'||''||'|'||''||'|'||v_tipo_certificado||'|'||
   v_fech_exp||'|'||v_ent_fed||'|'||v_total_mat||'|'||v_total_mat||'|'||v_promedio2||'|'||v_calificaciones||'|');

-------perimero vaciamos la  variables antes de llenarla
salida_dat := '';

------------------esta linea genera toda la linea del archivo dgair  COMPLETO POR ALUMNO------- 
---  se puso numero de certificado del representante
salida_dat := ('|'||''||'|'||'1.0'||'|'||v_tipo_cert||'|'||v_idinstituto||'|'||v_idcamp||'|'||v_ent_fed||'|'||v_curp_resp||'|'||
   v_idcargo||'|'||v_numero||'|'||v_fec_exp||'|'||v_idcarrera||'|'||v_tipo_perd||'|'||v_cve_plan||'|'||v_nu_control||'|'||v_curp_alumn||'|'||
   upper(v_nombre_alumn)||'|'||upper(v_paterno_alumn)||'|'||upper(v_materno_alumn2)||'|'||v_IDgenero||'|'||v_fech_nac_alumn||'|'||''||'|'||''||'|'||v_tipo_certificado||'|'||
   v_fech_exp||'|'||v_ent_fed||'|'||v_total_mat||'|'||v_total_mat||'|'||v_promedio2||'|'||v_calificaciones||'|');
 
vxml_total := vxml_inicio || vxml_respon || vxml_entidad|| soap_request ||soap_respond|| vxml_alumno || vxml_expedicion|| vxml_califica||vxml_califica3|| vxml_fin;

v_encode64 := encode_base64(trim(salida_dat));
--v_encode64  := encript_base64(salida_dat);  ---nuevo 29oct 2018
vsello   := v_encode64;
vdetcert := v_firma ; 

----dbms_output.put_line ( 'sello digital  '|| vsello );

update SZTRECE
   SET   SZTRECE_CHAIN_DAT = trim(salida_dat)
         , SZTRECE_CHAIN_XML = vxml_total
         , SZTRECE_ACTIVITY_DATE = sysdate
          ,SZTRECE_FOLIO_CONTROL = v_folio_ctrl
          , SZTRECE_SELLO  = trim(vsello)
          , SZTRECE_DET_CERTIFICA  =  vdetcert
          ,SZTRECE_ID            =  v_nu_control
where SZTRECE_PIDM_CERTIF  = vpidm
and  SZTRECE_PROGRAM_CERTIF  = v_prog;

/* aqui genera el archivo fisico dgair  para cada alumno  */
if pindica = 1  then 
p_genera_dgair ( trim(salida_dat), v_nu_control, v_prog );
elsif pindica = 2 then 
p_archivo_xml( vxml_total , v_nu_control, v_prog );
--p_archivo_xml2( vxml_total , v_nu_control, v_prog );
elsif pindica = 3 then 
--insert into twpaso (valor1,valor2,valor3) values ( 'inserta xml', sysdate, pindica); commit;
p_genera_dgair ( trim(salida_dat),v_nu_control,v_prog );
--p_archivo_xml2  ( vxml_total,v_nu_control,v_prog);

end if;

end loop;
commit;

end P_inicio;

Procedure P_consulta  (pprogram in varchar2 ) is

cursor certi is
select SZTRECE_PIDM_CERTIF,
SZTRECE_PROGRAM_CERTIF,
SZTRECE_ACTIVITY_DATE,
SZTRECE_CHAIN_XML,
SZTRECE_CHAIN_DAT,
SZTRECE_FOLIO_CONTROL
from Sztrece
where SZTRECE_PROGRAM_CERTIF = pprogram;




begin

HTP.P('<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
    <head>
        <title> Reporte DE CERTIFICADOS DIGITALES " </title>
    </head>
   <BODY>
   
   <body>
 <h1 >
 <center>
            Listado  de Baja de Alumnos   </h1>
 
       ');  
           
   -------------------------------------encabezado---------
--- DBMS_OUTPUT.PUT_LINE(' AQUI VOY 2 ');  
        
HTP.P('
      
   <table width="180%" border="1"  cellspacing="1">
  <tr>    
         <col align="left">'||
                 '<td width="3%" > ID    </td>'||
                '<td width="10%" > Nombre  </td>'||
                 '<td width="5%"> RUT  </td>'||
                 '<td width="5%"> Programa  </td>'||
                 '<td width="5%"> Descrpción  </td>'||
                 '<td width="3%"> % Aprobación  </td>'||
                 '<td width="3%"> Oportunidades  </td>'||
                 '<td width="3%"> Ponderado  </td>'||
                 '<td width="3%"> Baja Art.31  </td>'||
                 '<td width="3%"> Baja Art.32  </td>'||
                 '<td width="3%"> Baja Art.33  </td>
                 
     </tr>
     </table>
        ' );
--- DBMS_OUTPUT.PUT_LINE(' AQUI VOY 3 '); 
 FOR regRep IN certi  LOOP--mod 2306
   
 HTP.P('
     
   <table width="100%" border="0"   cellspacing="1">
  <tr>    
         <col align="left">'||
                '<td width="20%">'||regRep.SZTRECE_PIDM_CERTIF  ||'</td>'||
                '<td width="20%" >'|| regRep.SZTRECE_PROGRAM_CERTIF   ||'</td>'||
              --   '<td width="5%" >'|| vsRut ||'</td>'||
                 '<td width="20%"> '||RegRep.SZTRECE_ACTIVITY_DATE||'</td>'||                
                -- '<td width="5%">'||regRep.TZTRECE_ACTIVITY_DATE||'</td>'||
               --  '<td width="3%">'||regRep.TZTRECE_CHAIN_XML||'</td>'||--art31
              --   '<td width="3%">'||regRep.TZTRECE_CHAIN_DAT||'</td>'||--art32
                '<td width="20%">'||regRep.SZTRECE_FOLIO_CONTROL||'</td>'||-- art33
         --        '<td width="3%">'||regRep.baja31||'</td>'||
         --        '<td width="3%">'||regRep.baja32||'</td>'||
         ---        '<td width="3%">'||regRep.baja33||'</td>'||
                 '</tr>'||
            '</table>'
                );
 
 htp.p('</table>
 <tr>
  </body></html>');





end loop;
end P_consulta;



BEGIN

P_inicio (ppidm, pprograma, pindica, ptipo ); 
null;
exception when others then
null;

end PKG_CERTIFICADO_DIG;
/

DROP PUBLIC SYNONYM PKG_CERTIFICADO_DIG;

CREATE OR REPLACE PUBLIC SYNONYM PKG_CERTIFICADO_DIG FOR BANINST1.PKG_CERTIFICADO_DIG;


GRANT EXECUTE, DEBUG ON BANINST1.PKG_CERTIFICADO_DIG TO PUBLIC;
